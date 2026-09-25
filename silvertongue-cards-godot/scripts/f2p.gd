## F2P — SUASION on Nutaku (autoload "F2P"). The glue between this client and the title
## server in ops/nutaku/suasion_f2p (the shared rails' /f2p/* plus SUASION's /suasion/*),
## reached through the reusable Nutaku client (autoload "Nutaku", scripts/nutaku_f2p.gd,
## copied from shared/godot/).
##
## Off the platform this is inert: `on()` is false unless NutakuGI exists in the page (or
## the desktop test flags are given), and Api keeps talking to /cards/* exactly as before.
## On the platform Api hands every call here, and this file answers in the /cards/* shapes
## the screens already read, so the duel, gacha and affection screens need no second copy.
##
## The server is the only authority. A duel is opened by the server (it fixes the deck and
## the seed); every play is sent with the whole card sequence so far and the server replays
## it and answers with her line; the win is recorded only by /suasion/duel/finish, which
## replays the sequence again from scratch.
extends Node

signal suasion_changed(su: Dictionary)

var su: Dictionary = {}              # last /suasion state
var stage_id := ""                   # the stage the campaign screen chose
var _attempt := ""
var _plays: Array = []
var _stage: Dictionary = {}
var _last_view: Dictionary = {}


func on() -> bool:
	return Nutaku.active


func boot() -> bool:
	if not on():
		return false
	var ok := await Nutaku.boot()
	if ok:
		Nutaku.state_path = "/suasion/state"
		await refresh()
		await strings()
	return ok


## Update packs and events are released by the server's clock, not by a client build
## (backend/campaign/packs). Their words may be newer than this build's table, so the
## server serves their translations and they are merged under what the build already has.
func strings() -> void:
	var c := Loc.code()
	if c == "en":
		return
	var r := await Nutaku.api("GET", "/suasion/strings?lang=" + c.uri_encode())
	if r["ok"] and typeof(r["body"].get("strings")) == TYPE_DICTIONARY:
		Loc.merge(c, r["body"]["strings"])


func refresh() -> Dictionary:
	var r := await Nutaku.api("GET", "/suasion/state")
	_adopt(r["body"])
	return su


func _adopt(body: Dictionary) -> void:
	if body.has("suasion") and typeof(body["suasion"]) == TYPE_DICTIONARY:
		su = body["suasion"]
		suasion_changed.emit(su)
	Api.last_economy = economy()
	Api.economy_changed.emit(Api.last_economy)


## The wallet in the shape main.gd's top bar reads. "Gold" on the bar is Nutaku's; what we
## show in its place is chips, and the tickets beside it.
func economy() -> Dictionary:
	var s: Dictionary = Nutaku.state
	var e: Dictionary = s.get("energy", {})
	var t: Dictionary = s.get("tokens", {})
	var g: Dictionary = su.get("gacha", {})
	return {"gold": int(t.get("chips", 0)), "chips": int(t.get("chips", 0)), "tickets": int(t.get("ticket", 0)),
		"energy": {"energy": int(e.get("now", 0)), "pool": int(e.get("max", 8)), "next_in_s": int(e.get("next_in_s", 0))},
		"daily_available": bool(su.get("daily_duel", {}).get("available", false)),
		"pull_price": {"1": int(g.get("pull_chips", 300)), "10": int(g.get("pull_chips", 300)) * 10},
		"pity": {"pulls": int(g.get("pulls", 0)), "epic_pity_in": int(g.get("pity_epic_every", 30)) - int(g.get("since_epic", 0)),
			"pull_credits": int(t.get("ticket", 0))}}


func stage(id: String) -> Dictionary:
	for ch in su.get("chapters", []):
		for s in ch.get("stages", []) + ch.get("last_call", {}).get("stages", []):
			if str(s.get("id", "")) == id:
				return s
	for e in su.get("events", []):
		for s in e.get("stages", []):
			if str(s.get("id", "")) == id:
				return s
	return {}


# --- the duel, in /cards shapes ------------------------------------------------------------
const SCEN_OF := {"mara": "closing_time", "ines": "the_key", "yuenha": "life_model",
	"sanne": "house_rule", "teodora": "last_night", "celeste": "celeste",
	# update packs (backend/campaign/packs); a woman released after this build falls back to
	# her name from the server's bond table and the house art
	"odile": "radio", "hedda": "pilot", "roz": "market", "mireille": "sleeper", "dagny": "archive",
	"vesna": "ferry"}


func start(id: String, daily: bool = false) -> Dictionary:
	var body := {"daily": true} if daily else {"stage": id}
	var r := await Nutaku.api("POST", "/suasion/duel/start", body)
	_adopt(r["body"])
	if not r["ok"]:
		return {"error": _why(r)}
	var b: Dictionary = r["body"]
	_attempt = str(b["attempt_id"])
	_plays = []
	_stage = b["stage"]
	stage_id = str(_stage.get("id", id))
	_last_view = b["duel"]
	# Everything the server wrote is English; it is translated here, on arrival, so the duel
	# screen (shared with the off-platform build) draws what it is given.
	var intro := Loc.s(_stage.get("chapter_intro", ""))
	intro = (intro + "\n\n" if intro != "" else "") + Loc.s(_stage.get("intro", ""))
	return {"ok": true, "resumed": false, "duel": _view(b["duel"]), "opening": Loc.s(b.get("opening", "")),
		"scen": {"id": SCEN_OF.get(str(_stage["who"]), "closing_time"), "who": str(_stage["who"]),
			"name": Loc.s(_stage.get("name", "")), "goal": Loc.s(_stage.get("goal", "")), "story": intro,
			"title": Loc.s(_stage.get("title", "")), "mods": _stage.get("mods", {}),
			"boss": Loc.s(_stage.get("mods", {}).get("boss", ""))},
		"economy": economy()}


func play(card: String, text: String = "") -> Dictionary:
	var p := {"card": card}
	if card == "wild":
		p["text"] = text
	var trial := _plays.duplicate()
	trial.append(p)
	var r := await Nutaku.api("POST", "/suasion/duel/play", {"attempt_id": _attempt, "plays": trial})
	if not r["ok"]:
		var out := {"error": _why(r)}
		if r["body"].has("duel"):
			out["duel"] = _view(r["body"]["duel"])
		return out
	_plays = trial
	var b: Dictionary = r["body"]
	_last_view = b["duel"]
	var out := {"ok": true, "reply": Loc.s(b.get("reply", "")), "read": b.get("read", {}), "duel": _view(b["duel"]),
		"economy": economy()}
	if bool(b["duel"].get("over", false)):
		out["end"] = await _end(b)
	return out


func _end(b: Dictionary) -> Dictionary:
	var v: Dictionary = b["duel"]
	if bool(v.get("won", false)):
		var r := await Nutaku.api("POST", "/suasion/duel/finish", {"attempt_id": _attempt, "plays": _plays})
		_adopt(r["body"])
		if not r["ok"]:
			return {"won": false, "turns": int(v.get("turns", 0)), "beat": Loc.t("The server did not accept this duel: ") + Loc.s(_why(r)),
				"reward": {}, "harmed": false}
		var f: Dictionary = r["body"]
		var beat := Loc.s(f.get("win_text", ""))
		var cc = f.get("chapter_clear")
		if typeof(cc) == TYPE_DICTIONARY:
			beat += "\n\n" + Loc.s(cc.get("title", "")).to_upper() + "\n" + Loc.s(cc.get("outro", ""))
			# the chapter's missing Ledger page (the mystery thread): the chapter ends on it
			var pg = cc.get("page")
			if typeof(pg) == TYPE_DICTIONARY:
				beat += "\n\n" + Loc.s(pg.get("title", "")).to_upper() + "\n" + Loc.s(pg.get("text", ""))
		if f.has("marks"):
			beat += "\n\n" + Loc.t("+%d %s · %d in all") % [int(f["marks"]), _currency(str(f.get("event", ""))), int(f.get("marks_total", 0))]
		var scenes: Dictionary = f.get("bond_scenes", {})
		for k in scenes:
			if str(scenes[k]) != "":
				beat += "\n\n" + Loc.s(scenes[k])
		var drops: Array = f.get("drops", [])
		return {"won": true, "turns": int(f.get("turns", 0)), "beat": beat, "harmed": false, "daily": false,
			"stars": int(f.get("stars", 1)), "chapter_clear": cc, "bond_scenes": scenes,
			"reward": {"affection": int(f["bond"]["after"]), "affection_gain": int(f["bond"]["after"]) - int(f["bond"]["before"]),
				"gold": int(f.get("chips", 0)), "drop": drops[0] if not drops.is_empty() else {},
				"drops": drops, "cg_unlocked": f.get("cg_unlocked", []), "tier4_reached": false}}
	var r2 := await Nutaku.api("POST", "/suasion/duel/forfeit", {"attempt_id": _attempt})
	_adopt(r2["body"])
	var reason := str(v.get("reason", "turns"))
	var beat2 := Loc.s(r2["body"].get("lose_text", ""))
	if reason == "turns" and b.has("refusal") and b["refusal"] != null:
		beat2 = Loc.s(b["refusal"]) + "\n\n" + beat2
	return {"won": false, "turns": int(v.get("turns", 0)), "beat": beat2, "reward": {},
		"harmed": reason == "coercion", "reason": reason, "daily": false}


func forfeit() -> Dictionary:
	if _attempt == "":
		return {"ok": true}
	var r := await Nutaku.api("POST", "/suasion/duel/forfeit", {"attempt_id": _attempt})
	_adopt(r["body"])
	_attempt = ""
	return {"ok": true}


## The server's view in the shape duel.gd renders, plus resolve (the campaign's bar).
func _view(v: Dictionary) -> Dictionary:
	var out := v.duplicate(true)
	out["scenario"] = SCEN_OF.get(str(_stage.get("who", "mara")), "closing_time")
	out["difficulty"] = str(_stage.get("difficulty", "silver"))
	out["daily"] = false
	return out


# --- gacha, deck, affection, plates -------------------------------------------------------------
func pull(n: int, banner: String = "") -> Dictionary:
	var t := int(Nutaku.state.get("tokens", {}).get("ticket", 0))
	var pay := "ticket" if t >= n else "chips"
	var rid := "%d-%d-%d" % [Time.get_ticks_usec(), randi(), n]
	var body := {"n": n, "pay": pay, "request_id": rid}
	if banner != "":
		body["banner"] = banner
	var r := await Nutaku.api("POST", "/suasion/gacha/pull", body)
	_adopt(r["body"])
	if not r["ok"]:
		return {"error": Loc.s(_why(r)) + (Loc.t(" — tickets are in the store") if int(r["status"]) == 402 else "")}
	return {"ok": true, "paid": pay, "cards": r["body"].get("cards", []), "economy": economy(),
		"banner": str(r["body"].get("banner", "") if r["body"].get("banner") != null else "")}


func deck(_scenario: String, auto: bool = false) -> Dictionary:
	var sid := _night_id()
	var r := await Nutaku.api("POST", "/suasion/deck", {"stage": sid, "auto": auto})
	var coll: Array = su.get("collection", [])
	var st := stage(sid)
	return {"collection": coll, "deck": r["body"].get("deck", []), "deck_size": int(r["body"].get("deck_size", 18)),
		# which cards can act tonight (server: duel.py "Live cards"); the deck screen marks the rest
		"live": r["body"].get("live", null), "wanted": r["body"].get("wanted", []),
		"night": Loc.s(st.get("title", "")), "night_who": Loc.s(F2P_NAMES.get(str(st.get("who", "")), "")),
		"scenario": _scenario, "wild": {"id": "wild", "rarity": "wild", "cost": 2, "character": "wild", "signals": [], "harms": []}}


## The night the deck screen is for: the one the campaign chose, else the player's frontier.
func _night_id() -> String:
	if stage_id != "":
		return stage_id
	var f := int(su.get("frontier", 0))
	for ch in su.get("chapters", []):
		for s in ch.get("stages", []):
			if int(s.get("index", -1)) == f:
				return str(s["id"])
	return "c1s01"


const F2P_NAMES := {"mara": "Mara", "ines": "Ines", "yuenha": "Yuen Ha", "sanne": "Sanne", "teodora": "Teodora",
	"celeste": "Celeste", "odile": "Odile", "hedda": "Hedda", "roz": "Roz", "mireille": "Mireille",
	"dagny": "Dagny", "vesna": "Jaspreet"}


# --- events, auto-battle, the Ledger's pages ------------------------------------------------
func events() -> Array:
	return su.get("events", [])


func banners() -> Array:
	return su.get("banners", [])


func _currency(eid: String) -> String:
	for e in events():
		if str(e.get("id", "")) == eid:
			return Loc.s(e.get("currency", ""))
	return Loc.t("marks")


## Take a reward off an event's track.
func event_claim(eid: String, step: int) -> Dictionary:
	var r := await Nutaku.api("POST", "/suasion/event/claim", {"event": eid, "step": step})
	_adopt(r["body"])
	return {"ok": r["ok"], "error": "" if r["ok"] else Loc.s(_why(r)), "applied": r["body"].get("applied", {})}


## Auto-battle a stage already won, n times: the server opens, plays and replays each duel
## (suasion_economy.py /duel/auto) and answers with one summary per run.
func auto(id: String, n: int) -> Dictionary:
	var r := await Nutaku.api("POST", "/suasion/duel/auto", {"stage": id, "n": n})
	_adopt(r["body"])
	if not r["ok"]:
		return {"ok": false, "error": Loc.s(_why(r))}
	return {"ok": true, "runs": r["body"].get("runs", []), "won": int(r["body"].get("won", 0))}


func save_deck(_scenario: String, ids: Array) -> Dictionary:
	var sid := _night_id()
	var r := await Nutaku.api("POST", "/suasion/deck", {"stage": sid, "deck": ids})
	if not r["ok"]:
		return {"ok": false, "error": _why(r)}
	return {"ok": true, "deck": r["body"].get("deck", []), "dropped": int(r["body"].get("dropped", 0))}


func evolve(card: String) -> Dictionary:
	var r := await Nutaku.api("POST", "/suasion/evolve", {"card": card})
	_adopt(r["body"])
	return {"ok": r["ok"], "error": "" if r["ok"] else _why(r), "stars": int(r["body"].get("stars", 0))}


func affection() -> Dictionary:
	var out := {}
	for who in su.get("bond", {}):
		var b: Dictionary = su["bond"][who]
		var ladder := []
		var i := 0
		for step in b.get("ladder", []):
			i += 1
			ladder.append({"at": int(step["bond"]), "key": str(step["key"]), "tier": i, "earned": bool(step["earned"]),
				"placeholder": bool(step.get("placeholder", false))})
		out[who] = {"name": Loc.s(b.get("name", who)), "scenario": SCEN_OF.get(str(who), "celeste"), "wins": int(b.get("bond", 0)),
			"ladder": ladder, "unlocked": su.get("ladder_unlocked", [])}
	return {"affection": out}


func plate_texture(key: String) -> Texture2D:
	var path := "/suasion/cg/" + key
	if key.begins_with("scene:"):
		path = "/f2p/scene/" + key.substr(6)
	var buf := await Nutaku.bytes(path)
	if buf.is_empty():
		return null
	var img := Image.new()
	if img.load_webp_from_buffer(buf) != OK and img.load_png_from_buffer(buf) != OK:
		return null
	return ImageTexture.create_from_image(img)


func claim(kind: String, slot: int = -1) -> Dictionary:
	var r: Dictionary
	match kind:
		"daily":
			r = await Nutaku.api("POST", "/f2p/daily/claim")
		"mission":
			r = await Nutaku.api("POST", "/f2p/mission/claim", {"slot": slot})
		"bonus":
			r = await Nutaku.api("POST", "/f2p/mission/claim", {"bonus": true})
		"pass":
			r = await Nutaku.api("POST", "/suasion/pass/claim")
		_:
			return {"ok": false}
	await refresh()
	return {"ok": r["ok"], "error": "" if r["ok"] else _why(r), "applied": r["body"].get("applied", {})}


func buy(sku_id: String) -> Dictionary:
	var r := await Nutaku.buy(sku_id)
	await refresh()
	return r


func _why(r: Dictionary) -> String:
	var b: Dictionary = r.get("body", {})
	return str(b.get("reason", b.get("error", "server said %d" % int(r.get("status", 0)))))
