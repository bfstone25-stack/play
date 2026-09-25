extends Node
## F2P — FOLD: After Dark's side of the Nutaku free-to-play build. Autoloaded as "F2P".
##
## The reusable half is the "Nutaku" autoload (scripts/nutaku_f2p.gd, copied from
## shared/godot/nutaku_f2p.gd): the platform bridge and the economy API. This file is what
## only FOLD knows: that a level result is a string of folds ("U","D","L","R") and undos
## ("Z"); that an attempt has a move budget; which SKU refills candles or adds moves; and
## how the server's tiers map onto Tier and Save.
##
## Off the platform (itch, the ad track, desktop downloads) `on()` is false and every
## caller keeps its old behaviour. On it, the server is the authority: this file never
## decides a level is cleared, a scene is unlocked, or a candle exists.

signal attempt_changed
signal daily_requested       # the map's "Play today's board" (F2PUI.side)
signal event_requested       # the map's "Play" on the weekly event panel
signal hard_requested        # the map's "Play" on the hard-mode panel
signal crane_requested(who: String)   # the map's Cranes panel: reread a woman's opened folds

const SKU_REFILL := "candle_refill"
const SKU_CANDLE := "candle_1"
const SKU_MOVES := "moves_5"
const SKU_HINTS := "hint_3"
const SKU_UNDOS := "undo_5"
const SKU_STARTER := "starter"

var attempt := {}           # {id, level, budget, extra, actions, undos, replay}


func on() -> bool:
	return Nutaku.active


func _ready() -> void:
	Nutaku.state_changed.connect(_adopt)
	if on():
		Fold.load_extension()          # levels 202-800 exist on the platform only


## Boot the platform session once; everything else waits on this.
func ensure() -> bool:
	if not on():
		return false
	return await Nutaku.boot()


## Server state -> the game's own Tier layout and star table. The server wins: a local
## save cannot hold a level the server does not.
func _adopt(s: Dictionary) -> void:
	_state_at = Time.get_unix_time_from_system()
	if s.has("tiers"):
		Tier.configure(s["tiers"])
	if s.has("progress"):
		var done := {}
		var stars: Array = s["progress"].get("stars", [])
		for i in range(stars.size()):
			if int(stars[i]) > 0:
				done[str(i)] = int(stars[i])
		Save.set_v("fold_done", done)
	_watch_streak(s)


func energy() -> Dictionary:
	return Nutaku.state.get("energy", {})


func tokens(item: String) -> int:
	return int((Nutaku.state.get("tokens", {}) as Dictionary).get(item, 0))


func server_unlocked(id: String) -> bool:
	for t in Nutaku.state.get("tiers", []):
		var sc = t.get("scene")
		if typeof(sc) == TYPE_DICTIONARY and str(sc.get("id", "")) == id:
			return bool(t.get("unlocked", false))
	return false


## The server offers a tier's scene for gold only near the player's progress
## (config early_unlock_window); a far tier has no offer on the map or through the API.
func early_unlock(t: int) -> bool:
	for row in Nutaku.state.get("tiers", []):
		if int(row.get("tier", -1)) == t:
			return bool(row.get("early_unlock", false))
	return false


func tier_sku(t: int) -> String:
	return "scene_%02d" % (t + 1)


func price(sku_id: String) -> int:
	return int(Nutaku.sku(sku_id).get("price", 0))


## "4 / 5  ·  next in 3:12", or "∞ until …" on a pass.
func candle_text() -> String:
	var e := energy()
	if e.is_empty():
		return ""
	if bool(e.get("unlimited", false)):
		return I18n.t("candles_inf")
	var now := int(e.get("now", 0))
	var cap := int(e.get("max", 5))
	# Rewards can stack candles past the refill cap; "10/5" read as a bug on the map.
	var s := (I18n.t("candles") % [now, cap]) if now <= cap else (I18n.t("candles_over") % [now, cap])
	var nxt := float(e.get("next_in_s", 0))
	if nxt > 0:
		var left := maxf(0.0, nxt - (Time.get_unix_time_from_system() - _state_at))
		s += I18n.f("candle_next", _clock(left))
	return s


var _state_at := 0.0


static func _clock(sec: float) -> String:
	var s := int(sec)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


# ---- an attempt ---------------------------------------------------------------------

## Ask the server to open level `i`. {ok, status, reason}.
func begin(i: int) -> Dictionary:
	var r := await Nutaku.start_level(i)
	if not r["ok"]:
		attempt = {}
		return {"ok": false, "status": r["status"], "reason": str(r["body"].get("reason", ""))}
	var b: Dictionary = r["body"]
	attempt = {"id": str(b["attempt_id"]), "level": i, "budget": int(b["budget"]), "extra": 0,
		"actions": "", "undos": 0, "replay": bool(b.get("replay", false))}
	attempt_changed.emit()
	return {"ok": true}


func active_for(level: int) -> bool:
	return not attempt.is_empty() and int(attempt["level"]) == level


func on_move(d: Vector2i) -> void:
	if attempt.is_empty():
		return
	var ch := "U" if d.x < 0 else "D" if d.x > 0 else "L" if d.y < 0 else "R"
	attempt["actions"] = str(attempt["actions"]) + ch
	attempt_changed.emit()


func spent() -> int:
	if attempt.is_empty():
		return 0
	return str(attempt["actions"]).replace("Z", "").length()


func allowed() -> int:
	if attempt.is_empty():
		return 0
	return int(attempt["budget"]) + int(attempt["extra"])


func moves_left() -> int:
	return allowed() - spent()


func out_of_moves() -> bool:
	return not attempt.is_empty() and moves_left() <= 0


func free_undos() -> int:
	return 0 if bool(attempt.get("hard", false)) else 1


## One undo is free per attempt; more need a token spent on this attempt first.
func can_undo() -> bool:
	return not attempt.is_empty() and int(attempt["undos"]) < free_undos() + int(attempt.get("undos_bought", 0))


func on_undo() -> void:
	if attempt.is_empty():
		return
	attempt["actions"] = str(attempt["actions"]) + "Z"
	attempt["undos"] = int(attempt["undos"]) + 1
	attempt_changed.emit()


## Spend a token on this attempt: "undo" | "moves" | "hint". Buys the pack first when
## there is no token (the platform asks the player to confirm the gold). {ok, hint?}
func use(item: String) -> Dictionary:
	if attempt.is_empty():
		return {"ok": false, "reason": "no attempt"}
	if tokens(item) < 1:
		var sku: String = {"undo": SKU_UNDOS, "moves": SKU_MOVES, "hint": SKU_HINTS}[item]
		var p := await Nutaku.buy(sku)
		if str(p.get("status", "")) != "success":
			return {"ok": false, "reason": str(p.get("status", p.get("error", "payment failed"))), "payment": p}
	var r := await Nutaku.use_item(str(attempt["id"]), item, str(attempt["actions"]))
	if not r["ok"]:
		return {"ok": false, "reason": str(r["body"].get("reason", r["status"]))}
	if item == "moves":
		attempt["extra"] = int(attempt["extra"]) + int(r["body"].get("added_moves", 5))
	elif item == "undo":
		attempt["undos_bought"] = int(attempt.get("undos_bought", 0)) + 1
	attempt_changed.emit()
	return {"ok": true, "hint": r["body"].get("hint", {})}


## The solved board goes to the server as its action log.
## {ok, stars, unlocked, milestone, reason}; for the daily challenge also {rewarded, applied}
func finish(moves: int) -> Dictionary:
	if attempt.is_empty():
		return {"ok": false, "reason": "no attempt"}
	var daily := bool(attempt.get("daily", false))
	var ev := bool(attempt.get("event", false))
	var hd := bool(attempt.get("hard", false))
	var r: Dictionary
	if hd:
		r = await Nutaku.api("POST", "/f2p/hard/finish",
			{"attempt_id": str(attempt["id"]), "actions": str(attempt["actions"]), "moves": moves})
	elif daily or ev:
		r = await Nutaku.api("POST", "/f2p/challenge/finish" if daily else "/f2p/event/finish",
			{"attempt_id": str(attempt["id"]), "actions": str(attempt["actions"]), "moves": moves})
	else:
		r = await Nutaku.finish_level(str(attempt["id"]), str(attempt["actions"]), moves)
	attempt = {}
	if not r["ok"]:
		return {"ok": false, "reason": str(r["body"].get("reason", r["status"]))}
	var b: Dictionary = r["body"]
	if daily and typeof(b.get("challenge")) == TYPE_DICTIONARY:
		challenge = b["challenge"]
		_challenge_at = Time.get_unix_time_from_system()
	if ev and typeof(b.get("event")) == TYPE_DICTIONARY:
		event = b["event"]
		_event_at = Time.get_unix_time_from_system()
	if hd and typeof(b.get("hard")) == TYPE_DICTIONARY:
		hard = b["hard"]
	return {"ok": true, "stars": int(b.get("stars", 0)), "unlocked": b.get("unlocked", []),
		"milestone": b.get("milestone"), "rewarded": bool(b.get("rewarded", false)),
		"applied": b.get("applied", {}), "streak_bonus": b.get("streak_bonus", {}),
		"score": int(b.get("score", 0)), "first_clear": bool(b.get("first_clear", false)),
		"exclusive": b.get("exclusive", {}), "chapter_reward": b.get("chapter_reward", {})}


func give_up() -> void:
	if attempt.is_empty():
		return
	var id := str(attempt["id"])
	var daily := bool(attempt.get("daily", false))
	var ev := bool(attempt.get("event", false))
	var hd := bool(attempt.get("hard", false))
	attempt = {}
	if hd:
		await Nutaku.api("POST", "/f2p/hard/fail", {"attempt_id": id})
	elif daily:
		await Nutaku.api("POST", "/f2p/challenge/fail", {"attempt_id": id})
	elif ev:
		pass                          # an event attempt is free; the next start abandons it
	else:
		await Nutaku.fail_level(id)


# ---- the daily challenge (ops/nutaku/fold_f2p/daily.py) ----------------------------------

var challenge := {}          # the server's view: {day, number, date, level, goal, budget, claimed, streak, next_in_s, reward}
var _challenge_at := 0.0


func fetch_challenge() -> Dictionary:
	var r := await Nutaku.api("GET", "/f2p/challenge")
	if r["ok"]:
		challenge = r["body"].get("challenge", {})
		_challenge_at = Time.get_unix_time_from_system()
	return r


## Seconds to the next challenge (the same UTC reset as the login calendar), counted down
## locally from the server's figure.
func challenge_next_in() -> float:
	if challenge.is_empty():
		return 0.0
	return maxf(0.0, float(challenge.get("next_in_s", 0)) - (Time.get_unix_time_from_system() - _challenge_at))


func challenge_countdown() -> String:
	return _clock(challenge_next_in())


## Open today's challenge: the server sends the board, which plays as Fold.DAILY. It is
## free (no candle); the reward is paid once per day by the server.
func begin_daily() -> Dictionary:
	var r := await Nutaku.api("POST", "/f2p/challenge/start")
	if not r["ok"]:
		attempt = {}
		return {"ok": false, "status": r["status"], "reason": str(r["body"].get("reason", ""))}
	var b: Dictionary = r["body"]
	challenge = b["challenge"]
	_challenge_at = Time.get_unix_time_from_system()
	Fold.daily_level = challenge["level"]
	Juice.goals[Fold.DAILY] = challenge["goal"]
	attempt = {"id": str(b["attempt_id"]), "level": Fold.DAILY, "budget": int(challenge["budget"]), "extra": 0,
		"actions": "", "undos": 0, "replay": bool(challenge.get("claimed", false)), "daily": true}
	attempt_changed.emit()
	return {"ok": true}


## Deliver an unlocked scene's plate into user://unlocked/ through Unlock's own
## write-and-decode check, so the viewer and the map read it exactly as before.
func deliver(id: String) -> bool:
	if Unlock.ready_for(id):
		return true
	var data := await Nutaku.bytes("/f2p/scene/" + id.uri_encode())
	if data.size() <= 1024:
		return false
	return Unlock.write_delivered(id, data)


# ---- the Folding House and the weekly event (ops/nutaku/fold_f2p/house.py) ----------------

var house := {}              # {chapters, tiers: [{tier, stage}], standing, lanterns}
var event := {}              # {week, who, title, blurb, boards, cleared, exclusive_label, ends_in_s, ...}
var event_board := -1
var _event_at := 0.0


func fetch_house() -> Dictionary:
	var r := await Nutaku.api("GET", "/f2p/house")
	if r["ok"]:
		house = r["body"].get("house", {})
		_watch_house()
	return r


## The id of the chapter the player stands in (house.standing names it by title).
func current_chapter_id() -> String:
	var t := str((house.get("standing", {}) as Dictionary).get("chapter", ""))
	for c in house.get("chapters", []):
		if str(c.get("title", "")) == t:
			return str(c.get("id", ""))
	return ""


## Update-pack chapters the server lists but has not released: [{id, date, in_days}].
func coming_chapters() -> Array:
	var out := []
	for c in house.get("chapters", []):
		if str(c.get("status", "")) == "coming":
			out.append(c)
	return out


func fetch_event() -> Dictionary:
	var r := await Nutaku.api("GET", "/f2p/event")
	if r["ok"]:
		event = r["body"].get("event", {})
		_event_at = Time.get_unix_time_from_system()
	return r


func tier_stage(t: int) -> String:
	for row in house.get("tiers", []):
		if int(row["tier"]) == t:
			return str(row.get("stage", ""))
	return ""


## The chapter a tier belongs to, or {}.
func chapter_of(t: int) -> Dictionary:
	for c in house.get("chapters", []):
		if t >= int(c["first_tier"]) and t <= int(c["last_tier"]):
			return c
	return {}


func event_ends_text() -> String:
	if event.is_empty():
		return ""
	var s := maxf(0.0, float(event.get("ends_in_s", 0)) - (Time.get_unix_time_from_system() - _event_at))
	var d := int(s) / 86400
	return (I18n.f("days_short", d) if d > 0 else "") + _clock(fmod(s, 86400.0))


## The first open, uncleared board of this week's track (or the last open one).
func event_next_board() -> int:
	var last := 0
	for b in event.get("boards", []):
		if bool(b["open"]):
			last = int(b["board"])
			if not bool(b["cleared"]):
				return last
	return last


## Open an event board: the server sends it and it plays as Fold.EVENT, free of candles.
func begin_event(board: int) -> Dictionary:
	var r := await Nutaku.api("POST", "/f2p/event/start", {"board": board})
	if not r["ok"]:
		attempt = {}
		return {"ok": false, "status": r["status"], "reason": str(r["body"].get("reason", ""))}
	var b: Dictionary = r["body"]
	event = b["event"]
	_event_at = Time.get_unix_time_from_system()
	event_board = board
	var bd: Dictionary = b["board"]
	Fold.daily_level = bd["level"]
	if bd.has("goal"):
		Juice.goals[Fold.EVENT] = bd["goal"]
	else:
		Juice.goals.erase(Fold.EVENT)
	attempt = {"id": str(b["attempt_id"]), "level": Fold.EVENT, "budget": int(bd["budget"]), "extra": 0,
		"actions": "", "undos": 0, "replay": bool(bd.get("cleared", false)), "event": true}
	attempt_changed.emit()
	return {"ok": true}


func daily_leaderboard() -> Dictionary:
	return await Nutaku.api("GET", "/f2p/challenge/leaderboard")


# ---- hard mode (ops/nutaku/fold_f2p/hard.py) ----------------------------------------------

var hard := {}               # {chapters: [{id, title, open, boards: [{level, par, budget, cleared, stars}], cleared, total, reward_claimed}], cleared_total, per_n, per_n_reward, chapter_reward}
var hard_level := -1         # the base level whose hard board is being played


func fetch_hard() -> Dictionary:
	var r := await Nutaku.api("GET", "/f2p/hard")
	if r["ok"]:
		hard = r["body"].get("hard", {})
	return r


## Chapters whose hard boards are open (the chapter is done on the server).
func hard_open_chapters() -> Array:
	var out := []
	for c in hard.get("chapters", []):
		if bool(c.get("open", false)):
			out.append(c)
	return out


## The next uncleared hard board of the first open chapter that has one, or -1.
func hard_next() -> int:
	for c in hard_open_chapters():
		for b in c.get("boards", []):
			if not bool(b.get("cleared", false)):
				return int(b["level"])
	return -1


## The chapter row a hard level belongs to, or {}.
func hard_chapter_of(level: int) -> Dictionary:
	for c in hard.get("chapters", []):
		for b in c.get("boards", []):
			if int(b["level"]) == level:
				return c
	return {}


## Open a hard board: the server sends the rotated board, which plays as Fold.HARD. Free
## (no candle), no tokens, no undo; the budget is the server's (par + 2).
func begin_hard(level: int) -> Dictionary:
	var r := await Nutaku.api("POST", "/f2p/hard/start", {"level": level})
	if not r["ok"]:
		attempt = {}
		return {"ok": false, "status": r["status"], "reason": str(r["body"].get("reason", ""))}
	var b: Dictionary = r["body"]
	hard_level = int(b.get("level", level))
	Fold.daily_level = b["board"]
	Juice.goals.erase(Fold.HARD)
	var row := {}
	for bd in hard_chapter_of(hard_level).get("boards", []):
		if int(bd["level"]) == hard_level:
			row = bd
	attempt = {"id": str(b["attempt_id"]), "level": Fold.HARD, "budget": int(b["budget"]), "extra": 0,
		"actions": "", "undos": 0, "replay": bool(row.get("cleared", false)), "hard": true}
	attempt_changed.emit()
	return {"ok": true}


# ---- what Coco has to say about the account (scripts/companion.gd) --------------------------
#
# Server facts that deserve a line, noticed where the state arrives and said by the board
# (game.gd) at the next level start, one per start. A slot with no clips yet is dropped
# (the voice render rewrites lines.json later). Save keys: coco_streak_seen, coco_streak_lost,
# coco_chapter, coco_packs.

var coco_pending: Array[String] = []


func _coco_queue(slot: String) -> void:
	if slot not in coco_pending:
		coco_pending.append(slot)


## The login streak: reset to 1 after being above 1 is a lost streak; back to 2 after a loss
## is a streak won back.
func _watch_streak(s: Dictionary) -> void:
	var d = s.get("daily")
	if typeof(d) != TYPE_DICTIONARY or not (d as Dictionary).has("streak"):
		return
	var now := int(d["streak"])
	var seen := int(Save.get_v("coco_streak_seen", 0))
	if now == seen:
		return
	if now == 1 and seen > 1:
		_coco_queue("streak_lost")
		Save.set_v("coco_streak_lost", true)
	elif now == 2 and bool(Save.get_v("coco_streak_lost", false)):
		_coco_queue("streak_back")
		Save.set_v("coco_streak_lost", false)
	Save.set_v("coco_streak_seen", now)


## A new chapter, and a newly released update pack (a new woman in the House). A save that
## has never seen the house records it silently: a first visit is not news.
func _watch_house() -> void:
	var cid := current_chapter_id()
	if cid != "":
		var was := str(Save.get_v("coco_chapter", ""))
		if was != "" and was != cid:
			_coco_queue("chapter")
		Save.set_v("coco_chapter", cid)
	var rel := []
	for u in house.get("updates", []):
		if bool(u.get("released", false)):
			rel.append(str(u["id"]))
	var seen = Save.get_v("coco_packs", null)
	if typeof(seen) == TYPE_ARRAY:
		for id in rel:
			if id not in seen:
				_coco_queue("guest")
	Save.set_v("coco_packs", rel)


## The first queued account line Coco can say, removed from the queue; "" when none.
func take_coco() -> String:
	while not coco_pending.is_empty():
		var slot: String = coco_pending.pop_front()
		if Coco.has_slot(slot):
			return slot
	return ""


# ---- the crane letters (house.py tiers[].letter, house.cranes; data/letters.json) -----------

## Tier t's fold: {who, fold, of} and, once the tier is cleared, {id, hook?}; or {}.
func tier_letter(t: int) -> Dictionary:
	for row in house.get("tiers", []):
		if int(row["tier"]) == t and typeof(row.get("letter")) == TYPE_DICTIONARY:
			return row["letter"]
	return {}


## Each woman's crane: [{who, opened, of, last}].
func cranes() -> Array:
	return house.get("cranes", [])


## The folds of `who`'s crane the server has opened, in fold order: [{fold, of, id, hook?}].
func opened_folds(who: String) -> Array:
	var out := []
	for row in house.get("tiers", []):
		var lt = row.get("letter")
		if typeof(lt) == TYPE_DICTIONARY and str(lt.get("who", "")) == who and lt.has("id"):
			out.append(lt)
	out.sort_custom(func(a, b): return int(a["fold"]) < int(b["fold"]))
	return out


## The most recently opened fold (the highest cleared tier that carries one), or {}.
func last_letter() -> Dictionary:
	var best := {}
	var bt := -1
	for row in house.get("tiers", []):
		var lt = row.get("letter")
		if typeof(lt) == TYPE_DICTIONARY and lt.has("id") and int(row["tier"]) > bt:
			bt = int(row["tier"])
			best = lt
	return best
