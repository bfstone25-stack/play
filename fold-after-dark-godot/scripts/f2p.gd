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
		return "Candles ∞"
	var s := "Candles %d/%d" % [int(e.get("now", 0)), int(e.get("max", 5))]
	var nxt := float(e.get("next_in_s", 0))
	if nxt > 0:
		var left := maxf(0.0, nxt - (Time.get_unix_time_from_system() - _state_at))
		s += "  ·  +1 in %s" % _clock(left)
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
	return 1


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


## The solved board goes to the server as its action log. {ok, stars, unlocked, reason}
func finish(moves: int) -> Dictionary:
	if attempt.is_empty():
		return {"ok": false, "reason": "no attempt"}
	var r := await Nutaku.finish_level(str(attempt["id"]), str(attempt["actions"]), moves)
	attempt = {}
	if not r["ok"]:
		return {"ok": false, "reason": str(r["body"].get("reason", r["status"]))}
	return {"ok": true, "stars": int(r["body"].get("stars", 0)), "unlocked": r["body"].get("unlocked", [])}


func give_up() -> void:
	if attempt.is_empty():
		return
	var id := str(attempt["id"])
	attempt = {}
	await Nutaku.fail_level(id)


## Deliver an unlocked scene's plate into user://unlocked/ through Unlock's own
## write-and-decode check, so the viewer and the map read it exactly as before.
func deliver(id: String) -> bool:
	if Unlock.ready_for(id):
		return true
	var data := await Nutaku.bytes("/f2p/scene/" + id.uri_encode())
	if data.size() <= 1024:
		return false
	return Unlock.write_delivered(id, data)
