## Offline — the game's rules, running in the client, for when there is no backend.
##
## 2026-09-21. This game was scored BROKEN on the play board: twelve interactions, one
## frame, "never left the title". The build was fine. It was served as static files with
## no backend, `/cards/state` answered nothing, and `home.gd` draws its roster from
## `state.scenarios` — so the screen had nothing on it to press. Every click landed on
## empty ground.
##
## Which is also how it ships. An itch download runs on a player's machine; a web build on
## a foreign host reaches the gateway or nothing. A game that needs a server we run in
## order to have a first screen is a game that is broken everywhere but our desk.
##
## So the backend stops being a precondition. `Api` probes it once at boot; if it answers,
## nothing here runs and the server stays the only authority, exactly as before. If it does
## not, every `/cards/*` call is served from here instead, against the same tables — the
## card faces, the reply lines, the scenario rows, the rank budgets and the economy numbers
## are EXPORTED from the Python that owns them by tools/export_offline.py, never retyped.
## This file is arithmetic over that export and nothing else.
##
## `tests/offline.tscn` replays a duel the Python played and compares it turn by turn, so
## a rule change in the backend that nobody re-exported fails a test rather than shipping
## as two games that disagree.
extends Node

const DATA := "res://assets/offline/data.json"
const SAVE := "user://offline.json"
const WEB_KEY := "stc_offline"

var data := {}
var by_id := {}                 # card id -> card dict
var scen_by_id := {}
var save := {}                  # the player: gold, energy, collection, affection, decks, duel
var active := false             # set by Api when the backend did not answer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f == null:
		push_error("offline data missing: run tools/export_offline.py")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("offline data unreadable")
		return
	data = parsed
	for c in data.get("cards", []):
		by_id[str(c["id"])] = c
	for s in data.get("scenarios", []):
		scen_by_id[str(s["id"])] = s
	_rng.randomize()
	_load()


# --- the player's file ---------------------------------------------------------------------
func _load() -> void:
	var raw := ""
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||\"\";}catch(e){return \"\";}})()" % JSON.stringify(WEB_KEY))
		raw = str(r) if r != null else ""
	elif FileAccess.file_exists(SAVE):
		var f := FileAccess.open(SAVE, FileAccess.READ)
		raw = f.get_as_text()
		f.close()
	var p = JSON.parse_string(raw) if raw != "" else null
	if typeof(p) == TYPE_DICTIONARY and p.has("collection"):
		save = p
	else:
		save = _fresh()
	# Fields added after a player's file was written must not crash the load.
	for k in _fresh():
		if not save.has(k):
			save[k] = _fresh()[k]


func _fresh() -> Dictionary:
	var coll := {}
	for k in data.get("starter", {}):
		coll[k] = int(data["starter"][k])
	var aff := {}
	for who in data.get("characters", {}):
		aff[who] = 0
	return {
		"gold": 0, "energy": int(_t("energy_pool", 15)),
		"energy_ts": Time.get_unix_time_from_system(),
		"collection": coll, "affection": aff, "decks": {}, "duel": null,
		"pulls": 0, "since_epic": 0, "daily_day": -1, "unlocked": [],
	}


func _store() -> void:
	var raw := JSON.stringify(save)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s);}catch(e){}})()"
			% [JSON.stringify(WEB_KEY), JSON.stringify(raw)])
		return
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f != null:
		f.store_string(raw)
		f.close()


func reset() -> void:
	save = _fresh()
	_store()


func _t(key: String, dflt: Variant) -> Variant:
	return data.get("tuning", {}).get(key, dflt)


## The day index, so "today's duel" rotates offline the way it does on the server.
func day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func _todays_scenario() -> String:
	var ids: Array = data.get("scenarios", []).map(func(s): return str(s["id"]))
	if ids.is_empty():
		return "closing_time"
	return str(ids[day_index() % ids.size()])


# --- energy ------------------------------------------------------------------------------
func _refill() -> void:
	var pool := int(_t("energy_pool", 15))
	var every := float(_t("energy_refill_s", 1200))
	if int(save["energy"]) >= pool:
		save["energy_ts"] = Time.get_unix_time_from_system()
		return
	var now := Time.get_unix_time_from_system()
	var gained := int((now - float(save["energy_ts"])) / every)
	if gained > 0:
		save["energy"] = min(pool, int(save["energy"]) + gained)
		save["energy_ts"] = now if int(save["energy"]) >= pool else float(save["energy_ts"]) + gained * every


## The exact shape of shared/economy.py::summary() — `energy` is the nested dict from
## energy(), not an int. main.gd::render_wallet reads eco.energy.energy, so returning a
## flat number here would draw 0/15 forever and look like a bug in the bar.
func economy() -> Dictionary:
	_refill()
	var pool := int(_t("energy_pool", 15))
	var every := float(_t("energy_refill_s", 1200))
	var next_in := 0
	if int(save["energy"]) < pool:
		next_in = int(max(0.0, float(save["energy_ts"]) + every - Time.get_unix_time_from_system()))
	var pity_every := int(_t("pity_epic_every", 30))
	return {"user": "offline", "gold": int(save["gold"]),
			"energy": {"energy": int(save["energy"]), "pool": pool, "refill_s": int(every),
					   "duel_cost": int(_t("duel_cost", 3)), "next_in_s": next_in},
			"pity": {"pulls": int(save["pulls"]), "since_epic": int(save["since_epic"]),
					 "epic_pity_in": pity_every - int(save["since_epic"])},
			"daily_available": int(save.get("daily_day", -1)) != day_index(),
			"affection": save["affection"], "unlocks": save["unlocked"],
			"pull_price": _t("pull_price", {"1": 100, "10": 900}), "offline": true}


# --- the engine: decompose / advance, ported from persuasion_engine.py --------------------
## The five fork scenarios use only the keyword detectors and the length/digit rule; the
## parent's `ai` and `genie` branches are for scenarios this game does not contain, and
## porting dead branches is how a port drifts.
func decompose(message: String) -> Dictionary:
	var text := " ".join(message.split(" ", false)).strip_edges()
	var low := text.to_lower()
	var signals := []
	for name in data.get("common", {}):
		for needle in data["common"][name]:
			if low.find(str(needle).to_lower()) >= 0:
				signals.append(name)
				break
	var harms := []
	for name in data.get("negative", {}):
		for needle in data["negative"][name]:
			if low.find(str(needle).to_lower()) >= 0:
				harms.append(name)
				break
	# decompose(): a line of 45 characters or more, or one carrying a number, counts as
	# evidence on its own. The regex is the parent's, narrowed to what it actually matches.
	if text.length() >= 45 or RegEx.create_from_string(r"\b\d+(\.\d+)?").search(text) != null:
		if not signals.has("evidence"):
			signals.append("evidence")
	signals.sort()
	harms.sort()
	return {"signals": signals, "harms": harms}


func advance(previous: Dictionary, message: String, scenario: String, difficulty: String) -> Dictionary:
	var move := decompose(message)
	var evidence := {}
	for e in previous.get("evidence", []):
		evidence[e] = true
	for e in move["signals"]:
		evidence[e] = true
	var harms := {}
	for h in previous.get("harms", []):
		harms[h] = true
	for h in move["harms"]:
		harms[h] = true
	var turns := int(previous.get("turns", 0)) + 1
	var rule: Dictionary = data.get("rules", {}).get(scenario, {"paths": [["respect", "direct_request"]], "help": []})
	var path_progress := 0.0
	var path_complete := false
	for path in rule["paths"]:
		var hit := 0
		for s in path:
			if evidence.has(s):
				hit += 1
		path_progress = max(path_progress, float(hit) / float(max(1, path.size())))
		if hit == path.size():
			path_complete = true
	var support := 0
	for s in rule.get("help", []):
		if evidence.has(s):
			support += 1
	var penalty := harms.size()
	var required: int = {"gentle": 0, "silver": 1, "gold": 1}.get(difficulty, 1)
	var eligible: bool = path_complete and support >= required and penalty == 0
	var momentum := snappedf(clampf(path_progress * 0.72 + mini(support, 2) * 0.18 - penalty * 0.22, 0.0, 1.0), 0.01)
	var phase := "guarded"
	if eligible:
		phase = "breakthrough"
	elif momentum >= 0.68:
		phase = "wavering"
	elif momentum >= 0.3:
		phase = "engaged"
	var ev := evidence.keys(); ev.sort()
	var hm := harms.keys(); hm.sort()
	return {"turns": turns, "phase": phase, "momentum": momentum, "evidence": ev, "harms": hm,
			"last_move": move, "expert": str(rule.get("expert", "rapport")), "eligible": eligible,
			"cg": _plate(previous, phase, hm, scenario)}


const _PHASE_ORDER := {"guarded": 0, "engaged": 1, "wavering": 2, "breakthrough": 3}

## The parent's plate(): fires on a phase TRANSITION, never on sitting in a phase, and
## never at all once a coercion card has been played. It may not read turns or momentum.
func _plate(previous: Dictionary, phase: String, harms: Array, scenario: String) -> Array:
	if not harms.is_empty():
		return []
	var before: int = _PHASE_ORDER.get(str(previous.get("phase", "guarded")), 0)
	var after: int = _PHASE_ORDER.get(phase, 0)
	if after <= before:
		return []
	var out := []
	if before < 1 and after >= 1:
		out.append("cg1_%s" % scenario)
	if before < 2 and after >= 2:
		out.append("cg2_%s" % scenario)
	return out


# --- the duel ------------------------------------------------------------------------------
func card_public(cid: String) -> Dictionary:
	return by_id.get(cid, {"id": cid, "line": "", "rarity": "common", "cost": 1, "kind": "path",
						   "signals": [], "harms": [], "character": "house", "face": ""})


func _cost(cid: String) -> int:
	return int(card_public(cid).get("cost", 1))


func max_turns(difficulty: String) -> int:
	return int(_t("max_turns", {}).get(difficulty, 15))


func auto_deck(scenario: String) -> Array:
	var who := str(scen_by_id.get(scenario, {}).get("who", "mara"))
	var own := []
	var rest := []
	for cid in save["collection"]:
		if not by_id.has(cid):
			continue
		for _i in int(save["collection"][cid]):
			if str(by_id[cid].get("character", "")) == who:
				own.append(cid)
			else:
				rest.append(cid)
	var order := {"common": 0, "rare": 1, "epic": 2}
	own.sort_custom(func(a, b): return order.get(by_id[a]["rarity"], 0) > order.get(by_id[b]["rarity"], 0))
	var deck: Array = own + rest
	return deck.slice(0, int(_t("deck_size", 18)))


func _draw(d: Dictionary, n: int) -> void:
	for _i in n:
		if (d["deck"] as Array).is_empty() and not (d["discard"] as Array).is_empty():
			d["deck"] = (d["discard"] as Array).duplicate()
			(d["deck"] as Array).shuffle()
			d["discard"] = []
		if (d["deck"] as Array).is_empty():
			return
		(d["hand"] as Array).append((d["deck"] as Array).pop_front())


func new_duel(scenario: String, difficulty: String, deck_ids: Array, daily: bool = false) -> Dictionary:
	var deck := []
	for cid in deck_ids:
		if by_id.has(cid) and cid != "wild":
			deck.append(cid)
	deck = deck.slice(0, int(_t("deck_size", 18)))
	deck.shuffle()
	var d := {"scenario": scenario, "difficulty": difficulty, "deck": deck, "hand": [],
			  "discard": [], "state": {}, "nerve": int(_t("nerve_start", 1)),
			  "wild_left": int(_t("wild_per_duel", 1)), "over": false, "won": false,
			  "daily": daily, "log": []}
	_draw(d, int(_t("hand_size", 3)))
	return d


func duel_view(d: Dictionary) -> Dictionary:
	var st: Dictionary = d["state"]
	var rule: Dictionary = data.get("rules", {}).get(str(d["scenario"]), {})
	var hand := []
	for cid in d["hand"]:
		hand.append(card_public(cid))
	return {"scenario": d["scenario"], "difficulty": d["difficulty"],
			"turns": int(st.get("turns", 0)), "max_turns": max_turns(str(d["difficulty"])),
			"phase": str(st.get("phase", "guarded")), "momentum": float(st.get("momentum", 0.0)),
			"evidence": st.get("evidence", []), "harms": st.get("harms", []),
			"eligible": bool(st.get("eligible", false)), "hand": hand,
			"deck_left": (d["deck"] as Array).size(), "nerve": int(d["nerve"]),
			"nerve_cap": int(_t("nerve_cap", 3)), "wild_left": int(d["wild_left"]),
			"over": bool(d["over"]), "won": bool(d["won"]), "daily": bool(d["daily"]),
			"needs": {"paths": rule.get("paths", []), "help": rule.get("help", [])}}


## One turn. Mirrors cards.play_card(): the engine is handed the card's printed LINE, never
## its declared signals, so a card can never claim something its line does not carry.
func play_card(d: Dictionary, card_id: String, wild_text: String = "") -> Dictionary:
	if bool(d["over"]):
		return {"error": "duel is over"}
	var st: Dictionary = d["state"]
	if int(st.get("turns", 0)) >= max_turns(str(d["difficulty"])):
		return {"error": "no turns left"}
	var line := ""
	var cost := 0
	var is_wild := card_id == "wild"
	if is_wild:
		if int(d["wild_left"]) <= 0:
			return {"error": "wild already played"}
		line = wild_text.strip_edges().substr(0, 400)
		if line == "":
			return {"error": "wild needs a line"}
		cost = 2
	else:
		if not (d["hand"] as Array).has(card_id):
			return {"error": "card not in hand"}
		line = str(card_public(card_id).get("line", ""))
		cost = _cost(card_id)
	if cost > int(d["nerve"]):
		return {"error": "needs %d nerve, have %d" % [cost, int(d["nerve"])]}

	var before := (st as Dictionary).duplicate(true)
	var phase_before := str(before.get("phase", "guarded"))
	var evidence_before: Array = before.get("evidence", [])
	var state := advance(before, line, str(d["scenario"]), str(d["difficulty"]))
	d["state"] = state
	d["nerve"] = min(int(_t("nerve_cap", 3)), int(d["nerve"]) - cost + int(_t("nerve_per_turn", 2)))

	if is_wild:
		d["wild_left"] = int(d["wild_left"]) - 1
	else:
		(d["hand"] as Array).erase(card_id)
		(d["discard"] as Array).append(card_id)
		_draw(d, 1)

	var move: Dictionary = state["last_move"]
	var kind := ""
	if not (move["harms"] as Array).is_empty():
		kind = "coercion"
	elif is_wild:
		kind = "wild"
	else:
		var fresh := false
		for s in move["signals"]:
			if not evidence_before.has(s):
				fresh = true
				break
		kind = card_public(card_id).get("kind", "path") if fresh else "stale"

	var won: bool = bool(state["eligible"]) and (state["harms"] as Array).is_empty()
	d["won"] = won
	d["over"] = won or int(state["turns"]) >= max_turns(str(d["difficulty"]))
	var cg: Array = (state["cg"] as Array).duplicate()
	if won:
		cg.append("cg3_%s" % str(d["scenario"]))
	(d["log"] as Array).append({"card": card_id, "kind": kind, "before": phase_before, "after": state["phase"]})
	return {"card": card_id, "line": line, "kind": kind, "phase_before": phase_before,
			"phase_after": state["phase"], "momentum": state["momentum"], "harms": state["harms"],
			"signals": move["signals"], "evidence": state["evidence"],
			"eligible": state["eligible"], "won": won, "over": d["over"],
			"turns": state["turns"], "max_turns": max_turns(str(d["difficulty"])),
			"cg": cg, "nerve": int(d["nerve"])}


# --- her line ------------------------------------------------------------------------------
## The reply table for this language. ja is a whole second table (data["replies_ja"]),
## keyed identically, and it is used ONLY when it actually has the scenario — so a
## partially exported translation shows English rather than nothing.
func _replies(scenario: String) -> Dictionary:
	if Loc.code().begins_with("ja"):
		var ja: Dictionary = data.get("replies_ja", {}).get(scenario, {})
		if not ja.is_empty():
			return ja
	var en: Dictionary = data.get("replies", {})
	return en.get(scenario, en.get("closing_time", {}))


func reply(scenario: String, before: String, after: String, kind: String, harmed_before: bool) -> String:
	var table: Dictionary = _replies(scenario)
	var lines := []
	if kind == "coercion" and not harmed_before:
		lines = table.get("coercion|first|*", [])
	elif harmed_before or kind == "coercion":
		lines = table.get("coercion|again|*", [])
	else:
		for key in ["%s|%s|%s" % [before, after, kind], "%s|%s|*" % [before, after],
					"*|%s|%s" % [after, kind], "*|%s|*" % after]:
			if table.has(key):
				lines = table[key]
				break
	if lines.is_empty():
		return "…"
	return str(lines[_rng.randi() % lines.size()])


func opening(scenario: String) -> String:
	var table: Dictionary = _replies(scenario)
	var l: Array = table.get("open|open|open", [])
	return str(l[0]) if not l.is_empty() else ""


func refusal_line(scenario: String) -> String:
	var table: Dictionary = _replies(scenario)
	var l: Array = table.get("refusal|*|*", [])
	return str(l[0]) if not l.is_empty() else ""


# --- the endpoints, by the same names Api uses ---------------------------------------------
func _ladder_keys(wins: int, scenario: String) -> Array:
	var out := []
	for pair in data.get("ladder", []):
		if wins >= int(pair[0]):
			out.append("%s_%s" % [str(pair[1]), scenario])
	return out


func _affection_view() -> Dictionary:
	var out := {}
	for who in data.get("characters", {}):
		var meta: Dictionary = data["characters"][who]
		var scen := str(meta["scenario"])
		var w := int(save["affection"].get(who, 0))
		var ladder := []
		var i := 0
		for pair in data.get("ladder", []):
			ladder.append({"at": int(pair[0]), "key": "%s_%s" % [str(pair[1]), scen],
						   "tier": i + 1, "earned": w >= int(pair[0]),
						   "placeholder": str(pair[1]) == "cg4"})
			i += 1
		out[who] = {"name": str(meta["name"]), "scenario": scen, "wins": w,
					"ladder": ladder, "unlocked": _ladder_keys(w, scen)}
	return out


## One locale -> text lookup, for every field the export writes as a dict of locales.
## Exact match, then the bare language ("zh" for "zh-Hant"), then English. English is the
## last resort in EVERY case and no other language is ever the fallback: STANDARD §7's
## rule is that a player is never shown a language they did not pick, and Floor 13 shipped
## ja whose story files held Chinese prose exactly by getting this wrong.
func _loc(by_loc: Dictionary, lang: String) -> String:
	if by_loc.has(lang):
		return str(by_loc[lang])
	var bare := lang.split("-")[0]
	if by_loc.has(bare):
		return str(by_loc[bare])
	return str(by_loc.get("en", ""))


func _scen_ui(s: Dictionary, lang: String) -> Dictionary:
	var row := {"id": s["id"], "who": s["who"], "name": s["name"], "stars": s["stars"],
				"needs": s["needs"]}
	for key in ["title", "character", "goal", "story", "cg1_caption", "cg2_caption", "cg3_caption"]:
		row[key] = _loc(s.get(key, {}), lang)
	return row


func state(lang: String = "en") -> Dictionary:
	var today := _todays_scenario()
	var scens := []
	for s in data.get("scenarios", []):
		scens.append(_scen_ui(s, lang))
	var d = save.get("duel")
	return {"player": "offline", "economy": economy(), "day": day_index() + 1, "offline": true,
			"daily": {"scenario": today, "who": str(scen_by_id.get(today, {}).get("who", "mara")),
					  "available": int(save.get("daily_day", -1)) != day_index()},
			"scenarios": scens, "affection": _affection_view(),
			"duel": duel_view(d) if d != null and not bool(d.get("over", false)) else null,
			"tuning": {"deck_size": int(_t("deck_size", 18)), "hand_size": int(_t("hand_size", 3)),
					   "max_turns": _t("max_turns", {}), "duel_cost": int(_t("duel_cost", 3))}}


func deck(scenario: String, auto: bool) -> Dictionary:
	var collection := []
	var ids: Array = save["collection"].keys()
	ids.sort()
	for cid in ids:
		if by_id.has(cid):
			var row: Dictionary = card_public(cid).duplicate()
			row["n"] = int(save["collection"][cid])
			collection.append(row)
	var chosen: Array = save["decks"].get(scenario, [])
	if auto or chosen.is_empty():
		chosen = auto_deck(scenario)
	return {"collection": collection, "deck": chosen, "scenario": scenario,
			"deck_size": int(_t("deck_size", 18)), "offline": true}


func save_deck(scenario: String, ids: Array) -> Dictionary:
	var ok := []
	var left := {}
	for cid in save["collection"]:
		left[cid] = int(save["collection"][cid])
	for cid in ids:
		if by_id.has(cid) and int(left.get(cid, 0)) > 0:
			ok.append(cid)
			left[cid] = int(left[cid]) - 1
	if ok.size() < int(_t("hand_size", 3)):
		return {"ok": false, "error": "a deck needs at least %d owned cards" % int(_t("hand_size", 3))}
	save["decks"][scenario] = ok.slice(0, int(_t("deck_size", 18)))
	_store()
	return {"ok": true, "deck": save["decks"][scenario]}


func start(scenario: String, difficulty: String, daily: bool) -> Dictionary:
	var existing = save.get("duel")
	if existing != null and not bool(existing.get("over", false)):
		return {"ok": true, "resumed": true, "duel": duel_view(existing),
				"opening": opening(str(existing["scenario"])), "economy": economy(),
				"scen": _scen_ui(scen_by_id.get(str(existing["scenario"]), {}), Loc.code())}
	if not scen_by_id.has(scenario):
		return {"error": "unknown scenario"}
	if daily:
		if int(save.get("daily_day", -1)) == day_index():
			return {"error": "daily already played today"}
	else:
		_refill()
		var cost := int(_t("duel_cost", 3))
		if int(save["energy"]) < cost:
			return {"error": "not enough energy", "economy": economy()}
		if int(save["energy"]) >= int(_t("energy_pool", 15)):
			save["energy_ts"] = Time.get_unix_time_from_system()
		save["energy"] = int(save["energy"]) - cost
	var ids: Array = save["decks"].get(scenario, [])
	if ids.is_empty():
		ids = auto_deck(scenario)
	var d := new_duel(scenario, difficulty, ids, daily)
	save["duel"] = d
	_store()
	return {"ok": true, "resumed": false, "duel": duel_view(d), "opening": opening(scenario),
			"economy": economy(), "scen": _scen_ui(scen_by_id[scenario], Loc.code())}


func play(card: String, text: String) -> Dictionary:
	var d = save.get("duel")
	if d == null or bool(d.get("over", false)):
		return {"error": "no duel in progress"}
	var harmed_before: bool = not (d["state"].get("harms", []) as Array).is_empty()
	var read := play_card(d, card, text)
	if read.has("error"):
		return {"error": read["error"], "duel": duel_view(d)}
	var out := {"ok": true, "reply": reply(str(d["scenario"]), str(read["phase_before"]),
											str(read["phase_after"]), str(read["kind"]), harmed_before),
				"read": read, "duel": duel_view(d)}
	if bool(d["over"]):
		var scen := str(d["scenario"])
		var who := str(scen_by_id[scen]["who"])
		var reward := {}
		if bool(d["won"]):
			var before_wins := int(save["affection"].get(who, 0))
			var wins := before_wins + (2 if bool(d["daily"]) else 1)
			save["affection"][who] = wins
			var gold := int(_t("win_gold", {}).get(str(d["difficulty"]), 45))
			save["gold"] = int(save["gold"]) + gold
			var drop := _drop_for(scen)
			save["collection"][drop] = int(save["collection"].get(drop, 0)) + 1
			var fresh := []
			for k in _ladder_keys(wins, scen):
				if not _ladder_keys(before_wins, scen).has(k):
					fresh.append(k)
					if not (save["unlocked"] as Array).has(k):
						(save["unlocked"] as Array).append(k)
			var cg_unlocked := []
			for k in fresh:
				if not str(k).begins_with("cg4"):
					cg_unlocked.append(k)
			reward = {"affection": wins, "affection_gain": wins - before_wins, "gold": gold,
					  "drop": card_public(drop), "cg_unlocked": cg_unlocked,
					  "tier4_reached": fresh.any(func(k): return str(k).begins_with("cg4"))}
		elif (read["harms"] as Array).is_empty():
			out["refusal_line"] = refusal_line(scen)
		if bool(d["daily"]):
			save["daily_day"] = day_index()
		out["end"] = {"won": bool(d["won"]), "turns": int(read["turns"]),
					  "beat": _loc(scen_by_id[scen].get("closing_beat" if bool(d["won"]) else "refusal_beat", {}), Loc.code()),
					  "reward": reward, "harmed": not (read["harms"] as Array).is_empty(),
					  "daily": bool(d["daily"])}
		save["duel"] = null
	_store()
	out["economy"] = economy()
	return out


func forfeit() -> Dictionary:
	save["duel"] = null
	_store()
	return {"ok": true}


func daily(lang: String = "en") -> Dictionary:
	var today := _todays_scenario()
	return {"day": day_index() + 1, "scen": _scen_ui(scen_by_id.get(today, {}), lang),
			"solved_today": int(save.get("daily_day", -1)) == day_index(),
			"available": int(save.get("daily_day", -1)) != day_index(), "offline": true}


func _drop_for(scenario: String) -> String:
	var who := str(scen_by_id[scenario]["who"])
	var rarity := _weighted_rarity()
	var pool := []
	for cid in by_id:
		var c: Dictionary = by_id[cid]
		if str(c.get("character", "")) == who and str(c.get("rarity", "")) == rarity:
			pool.append(cid)
	if pool.is_empty():
		pool = by_id.keys()
	return str(pool[_rng.randi() % pool.size()])


func _weighted_rarity() -> String:
	var w: Dictionary = _t("gacha_weights", {"common": 70, "rare": 25, "epic": 5})
	var total := 0
	for k in w:
		total += int(w[k])
	# maxi(), not max(). `max()` is the Variant-returning builtin, so `randi() % max(...)`
	# has no inferred type and `var roll :=` is a PARSE ERROR — which does not fail the
	# export. This file shipped unparseable inside the web build: the Offline autoload
	# failed to instantiate, every /cards/* answer came back empty, and the game drew an
	# empty roster that twelve clicks landed on. The only place it was visible was the
	# browser console. See the note at the head of tests/parse.tscn.
	var roll := _rng.randi() % maxi(1, total)
	for k in ["common", "rare", "epic"]:
		roll -= int(w.get(k, 0))
		if roll < 0:
			return k
	return "common"


func pull(n: int) -> Dictionary:
	if n != 1 and n != 10:
		return {"error": "n must be 1 or 10"}
	var price := int(_t("pull_price", {}).get(str(n), 100 if n == 1 else 900))
	if int(save["gold"]) < price:
		return {"error": "not enough gold", "economy": economy()}
	save["gold"] = int(save["gold"]) - price
	var gacha: Dictionary = data.get("gacha", {})
	var got := []
	var rare_in_ten := false
	for i in n:
		var rarity := _weighted_rarity()
		var pity := ""
		if int(save["since_epic"]) + 1 >= int(_t("pity_epic_every", 30)) and gacha.has("epic"):
			rarity = "epic"
			pity = "epic"
		elif n == 10 and i == n - 1 and not rare_in_ten and gacha.has("rare"):
			rarity = "rare"
			pity = "rare"
		if rarity != "common":
			rare_in_ten = true
		save["since_epic"] = 0 if rarity == "epic" else int(save["since_epic"]) + 1
		save["pulls"] = int(save["pulls"]) + 1
		var pool: Array = gacha.get(rarity, gacha.get("common", []))
		var cid := str(pool[_rng.randi() % pool.size()])
		save["collection"][cid] = int(save["collection"].get(cid, 0)) + 1
		var row: Dictionary = card_public(cid).duplicate()
		row["pity"] = pity
		got.append(row)
	_store()
	return {"ok": true, "paid": price, "cards": got, "economy": economy(),
			"epic_pity_in": int(_t("pity_epic_every", 30)) - int(save["since_epic"])}


func affection() -> Dictionary:
	var ladder := []
	for pair in data.get("ladder", []):
		ladder.append({"at": int(pair[0]), "tier": str(pair[1])})
	return {"affection": _affection_view(), "ladder": ladder, "offline": true}


func dev_gold(amount: int) -> Dictionary:
	save["gold"] = int(save["gold"]) + amount
	_store()
	return {"ok": true, "economy": economy()}


func dev_energy() -> Dictionary:
	save["energy"] = int(_t("energy_pool", 15))
	save["energy_ts"] = Time.get_unix_time_from_system()
	_store()
	return {"ok": true, "economy": economy()}
