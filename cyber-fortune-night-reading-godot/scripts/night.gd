extends Node
## Night autoload — the second world's one rule, in code.
##
##   By day you read people. After dark, what you read becomes true: the card you turn
##   for her is the one she starts living.
##
## Everything under it is the parent's machine (Fortune: the six-rank ladder, pity, the
## free daily draw, merit). This file is only what a draw *does to the person it was
## drawn for* — and the consent gate, which is the part that must never be decorative:
## a reading she refuses is not written and is not remembered.
##
## State: user://night.json. Fortune keeps its own file; the two are saved together.

signal changed
signal spoken(event: Dictionary)

const SAVE_PATH := "user://night.json"

## Rank -> how far the reading moves the track it names. 末吉 moves nothing: a reading
## that says "carry on as you are" leaves her as she is, which is the honest reading of it.
const STRENGTH := {"daji": 3, "zhongji": 2, "xiaoji": 1, "moji": 0, "xiong": -1, "daxiong": -2}
const TRACK_MAX := 3
const TRACKS_PER := 3
const FULL := TRACK_MAX * TRACKS_PER          # 9 — every track true

var cast: Array = []
var by_id: Dictionary = {}
var state: Dictionary = {}                    # client id -> {"tracks": [int,int,int], "seen": bool}
var current := ""
var instrument := "slip"                      # slip | card | force
var offer: Dictionary = {}                    # the drawn reading, before she answers
var persist_enabled := true


func _ready() -> void:
	cast = Tx._load_json("res://pool/night.json")
	for c in cast:
		by_id[c["id"]] = c
	load_state()
	if current == "" and cast.size() > 0:
		current = str(cast[0]["id"])


func client(id: String = "") -> Dictionary:
	return by_id.get(id if id != "" else current, {})


func tracks(id: String = "") -> Array:
	var k := id if id != "" else current
	if not state.has(k):
		state[k] = {"tracks": [0, 0, 0], "seen": false}
	return state[k]["tracks"]


func total(id: String = "") -> int:
	var n := 0
	for v in tracks(id):
		n += int(v)
	return n


func scene_ready(id: String = "") -> bool:
	return total(id) >= FULL


func scene_seen(id: String = "") -> bool:
	var k := id if id != "" else current
	tracks(k)
	return bool(state[k].get("seen", false))


func mark_seen(id: String = "") -> void:
	var k := id if id != "" else current
	tracks(k)
	state[k]["seen"] = true
	save_state()
	changed.emit()


func cleared() -> bool:
	for c in cast:
		if not scene_seen(str(c["id"])):
			return false
	return true


# ---- the draw names one of her tracks -------------------------------------------------
## Which of her three the reading is about. Deterministic and legible, so a player can
## learn it: the tube's subject, the card's position, the force she sat through.
static func track_index(result: Dictionary) -> int:
	match str(result.get("kind", "slip")):
		"slip":
			var i: int = Fortune.SUBJECTS.find(str(result.get("subject", "")))
			return maxi(i, 0) % TRACKS_PER
		"card":
			var p: int = Fortune.POSITIONS.find(str(result.get("position", "")))
			return maxi(p, 0) % TRACKS_PER
		_:
			return int(result.get("force_index", 0)) % TRACKS_PER


static func strength_of(result: Dictionary) -> int:
	return int(STRENGTH.get(str(result.get("rank", "moji")), 0))


## Draw with the instrument, for the woman at the table. Returns the offer, or {}.
func read_her(kind: String = "") -> Dictionary:
	if kind == "":
		kind = instrument
	if not offer.is_empty():
		return {}
	var subject := ""
	var r := Fortune.draw("slip" if kind == "slip" else "card", subject)
	if r.is_empty():
		return {}
	if kind == "force":
		# Mentalism does not roll its own rank — it rides the same ladder — but the force
		# she sat through decides which of her it is about.
		r["kind"] = "force"
		r["force_index"] = Fortune.rng.randi() % 3
	var idx := track_index(r)
	var s := strength_of(r)
	var t: Array = tracks()
	offer = {
		"result": r,
		"track": idx,
		"strength": s,
		"accepted": would_accept(idx, s),
		"at": Fortune.now_ms(),
	}
	changed.emit()
	return offer


## The consent gate. She takes a reading that opens something (a positive rank), or one
## she is already far enough into to absorb (that track already moved). She does not take
## a reading that pushes her somewhere she has not agreed to go — 末吉 says nothing, and a
## 凶 on a track she has not opened is a stranger telling her who she is.
##
## This is the whole of it, and it is meant to be readable in one screen: nothing anywhere
## in this game writes a track she refused, and nothing remembers the refusal.
func would_accept(idx: int, s: int) -> bool:
	if s > 0:
		return true
	var t: Array = tracks()
	return s < 0 and int(t[idx]) >= 1


## "Say it to her." Applies the reading if she takes it; spends the draw either way.
func speak() -> Dictionary:
	if offer.is_empty():
		return {}
	var idx: int = int(offer["track"])
	var s: int = int(offer["strength"])
	var accepted: bool = bool(offer["accepted"])
	var t: Array = tracks()
	var before: int = int(t[idx])
	var after := before
	if accepted:
		after = clampi(before + s, 0, TRACK_MAX)
		t[idx] = after
	Fortune.keep()                       # the slip/card goes into the collection either way
	var ev := {
		"client": current, "track": idx, "strength": s, "accepted": accepted,
		"before": before, "after": after,
		"locked": accepted and after >= TRACK_MAX and before < TRACK_MAX,
		"ready": scene_ready(),
	}
	offer = {}
	save_state()
	changed.emit()
	spoken.emit(ev)
	return ev


## "Keep it." The draw is not spoken; the slip burns back to merit, she is unchanged.
func hold() -> int:
	if offer.is_empty():
		return 0
	offer = {}
	var back := Fortune.burn()
	changed.emit()
	return back


# ---- art ------------------------------------------------------------------------------
## Plates live in assets/night/ and are loaded by name, so replacing a placeholder with a
## rendered plate is a file copy plus `godot --headless --path . --import` (without the
## reimport the old image renders from cache, with no error — memory: verification-that-lies).
##   <id>_calm.png    tier 1, at the table                      — the home card and the room
##   <id>_turn.png    tier 2, the moment a reading lands
##   <id>_night.png   tier 3, the payoff, behind the gate
##   <id>_night_locked.png  the censored plate shown when the gate is not passed
const ART_DIR := "res://assets/night/"
var _art_cache := {}


func art(name: String) -> Texture2D:
	if _art_cache.has(name):
		return _art_cache[name]
	var path := ART_DIR + name + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_art_cache[name] = tex
	return tex


func portrait(id: String) -> Texture2D:
	return art(id + "_calm")


## True when this slot is still the labelled placeholder rather than rendered art.
## The list is written by tools/make_placeholders.py, not guessed from file size —
## ops/check_two_worlds.py had to infer it from bytes on Flutter and that is exactly how
## nine placeholder cards shipped unnoticed.
var _placeholders: Array = []
var _placeholders_loaded := false


func is_placeholder(name: String) -> bool:
	if not _placeholders_loaded:
		_placeholders_loaded = true
		var v = Tx._load_json(ART_DIR + "placeholders.json")
		_placeholders = v if typeof(v) == TYPE_ARRAY else []
	return name in _placeholders


# ---- persistence -----------------------------------------------------------------------
func snapshot() -> Dictionary:
	return {"schema": 1, "state": state, "current": current, "instrument": instrument,
		"offer": offer}


func load_from(d: Dictionary) -> void:
	state = d.get("state", {})
	current = str(d.get("current", ""))
	instrument = str(d.get("instrument", "slip"))
	offer = d.get("offer", {})
	# JSON has no ints: the track arrays come back as floats and every comparison against
	# TRACK_MAX would then be a float comparison that happens to work until it does not.
	for k in state.keys():
		var arr: Array = state[k].get("tracks", [0, 0, 0])
		for i in range(arr.size()):
			arr[i] = int(arr[i])
		state[k]["tracks"] = arr


func load_state() -> void:
	if not persist_enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) == TYPE_DICTIONARY:
		load_from(v)


func save_state() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(snapshot()))


func reset() -> void:
	state = {}
	offer = {}
	current = str(cast[0]["id"]) if cast.size() > 0 else ""
	instrument = "slip"
	save_state()
	changed.emit()


func dev_state() -> Dictionary:
	var per := {}
	for c in cast:
		var id := str(c["id"])
		per[id] = {"tracks": tracks(id), "total": total(id), "ready": scene_ready(id),
			"seen": scene_seen(id)}
	return {"night": {"current": current, "instrument": instrument, "clients": per,
		"offer": offer, "cleared": cleared()}}
