extends Node
## Ticker autoload — the building that keeps running, and everything game.js kept in the
## page: the building state (Idle), the skill ladder (the parent's ten predicates), the
## affection ladder, the daily floor, the object/relic shop, persistence, and the dev
## hooks the headless run drives. Scenes read from here and connect to the signals; they
## never touch the Idle dictionary directly.

const BUILDING_PATH := "user://building.json"
const CABINET_PATH := "user://cabinet.json"
const FREE_FLOORS := 3
const OBJECT_PRICE := {"coffee": 12, "mute": 20, "printer": 16, "corner": 16}
const RELIC_PRICE := 150

## The skill ladder — the parent's ten predicates, verbatim in meaning (game.js PLATES).
## "who" and "cond" are I18n keys; "en" is kept as the English of record, so a reader of
## this file can still see what a plate asks for without opening the translation table.
const PLATES: Array = [
	{"slot": "cg_mirei_lease", "who": "who_mirei", "cond": "p_lease", "en": "Make rent on any floor with a surplus.", "free": true},
	{"slot": "cg_dan_x", "who": "who_dan", "cond": "p_dan", "en": "Three coffee->Dan multipliers in one settle."},
	{"slot": "cg_priya_x", "who": "who_priya", "cond": "p_priya", "en": "Settle with 3+ staff placed, someone shielded, and no tax from Wes."},
	{"slot": "cg_mara_corners", "who": "who_mara", "cond": "p_mara", "en": "Hold all four corners with corner desks."},
	{"slot": "cg_wes_x", "who": "who_wes", "cond": "p_wes", "en": "With the Intern Army relic, four copies in one settle."},
	{"slot": "cg_quiet_floor", "who": "who_mirei_priya", "cond": "p_quiet", "en": "With Quiet Floor, clear a settle with a six-link chain."},
	{"slot": "cg_glass_office", "who": "who_mirei", "cond": "p_glass", "en": "With Glass Office, make rent on floor 6 or later."},
	{"slot": "cg_vault_x", "who": "who_mirei", "cond": "p_vault", "en": "Bank 40 or more."},
	{"slot": "cg_floor9", "who": "who_ninth", "cond": "p_floor9", "en": "Reach floor nine."},
	{"slot": "cg_evicted", "who": "who_badge", "cond": "p_evicted", "en": "Get evicted. It happens."},
]
## Affection tier plates reuse the parent's installed art by path (game.js AFF_PLATE).
const AFF_PLATE := {"dan": "cg_dan_x", "priya": "cg_priya_x", "mara": "cg_mara_corners", "wes": "cg_wes_x", "nia": "cg_glass_office", "sol": "cg_quiet_floor"}

signal changed
signal shift_paid(rep: Dictionary)
signal returned(rep: Dictionary)
signal evicted(rep: Dictionary)
signal shielded
signal prestige_ready
signal plate_earned(slot: String)
signal tier_up(id: String, tier: int)
signal banner(msg: String)

var B: Dictionary = {}
var cabinet: Dictionary = {"cg": [], "affSeen": {}, "visits": 0, "sound": true}
var persist_enabled := true
var started := false
var prestige_offered := false
var best_payout := 0
var best_chain := 0
var _acc := 0.0
var _last_cmd := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_all()


# ---- clock ----------------------------------------------------------------------

func wall_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func now() -> int:
	return wall_ms() + int(B.get("clockOffset", 0))


# ---- persistence ------------------------------------------------------------------

func load_all() -> void:
	B = Idle.fresh(wall_ms())
	if persist_enabled and FileAccess.file_exists(BUILDING_PATH):
		var f := FileAccess.open(BUILDING_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("v", 0)) == 1:
				B = _ints(parsed)
	if persist_enabled and FileAccess.file_exists(CABINET_PATH):
		var f2 := FileAccess.open(CABINET_PATH, FileAccess.READ)
		if f2:
			var parsed2 = JSON.parse_string(f2.get_as_text())
			f2.close()
			if typeof(parsed2) == TYPE_DICTIONARY:
				for k in parsed2.keys():
					cabinet[k] = parsed2[k]


## JSON gives floats back for every number; the ticker does integer millisecond math.
func _ints(v):
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if v == floor(v) and abs(v) < 9.0e15 else v
		TYPE_DICTIONARY:
			var d := {}
			for k in v.keys():
				d[k] = _ints(v[k])
			if d.has("mult"):
				d["mult"] = float(v["mult"])
			return d
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(_ints(x))
			return a
	return v


func save_building() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(BUILDING_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(B))
		f.close()


func save_cabinet() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(CABINET_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cabinet))
		f.close()


func reset_all() -> void:
	B = Idle.fresh(wall_ms())
	cabinet = {"cg": [], "affSeen": {}, "visits": 0, "sound": true}
	best_payout = 0
	best_chain = 0
	prestige_offered = false
	Economy.reset()
	save_building()
	save_cabinet()
	changed.emit()


# ---- the skill ladder ---------------------------------------------------------------

func plate_by(slot: String) -> Dictionary:
	for p in PLATES:
		if p["slot"] == slot:
			return p
	return {}


func earned(slot: String) -> bool:
	return cabinet["cg"].has(slot)


func award(slot: String) -> void:
	if earned(slot):
		return
	cabinet["cg"].append(slot)
	save_cabinet()
	plate_earned.emit(slot)
	var p := plate_by(slot)
	banner.emit("NEW PLATE — " + str(p.get("who", slot)))


func award_board(f: Dictionary, r: Dictionary, chain: int) -> void:
	var cells: Array = f["cells"]
	var ev: Array = r["events"]
	var n := func(name: String) -> int: return ev.count(name)
	var relics: Array = B["relics"]
	if n.call("coffee-dan") >= 3:
		award("cg_dan_x")
	var staff_on := 0
	for c in cells:
		if c == "dan" or c == "priya" or c == "mara":
			staff_on += 1
	if staff_on >= 3 and ev.has("mute-shield") and n.call("wes-tax") == 0:
		award("cg_priya_x")
	var corners := true
	for i in [0, 4, 15, 19]:
		if cells[i] != "corner":
			corners = false
	if corners:
		award("cg_mara_corners")
	if relics.has("army") and n.call("priya-army") >= 4:
		award("cg_wes_x")
	if relics.has("quiet") and chain >= 6:
		award("cg_quiet_floor")


func award_cleared(f: Dictionary, surplus: int) -> void:
	if surplus > 0:
		award("cg_mirei_lease")
	if B["relics"].has("glass") and int(f["n"]) >= 6:
		award("cg_glass_office")
	if int(B["bank"]) >= 40:
		award("cg_vault_x")


## A shift is a settle. Break-even per shift is the day's rent over the day's 144 shifts.
func break_even(f: Dictionary) -> int:
	return int(ceil(float(Idle.daily_rent(f, B["relics"])) / float(Idle.DAY_MS / Idle.SHIFT_MS)))


func _on_shift_settle(f: Dictionary, r: Dictionary, chain: int) -> void:
	best_payout = max(best_payout, int(r["payout"]))
	best_chain = max(best_chain, chain)
	award_board(f, r, chain)
	award_cleared(f, int(round(float(r["shift"]) * float(B["mult"]))) - break_even(f))


# ---- affection ladder ---------------------------------------------------------------

func check_affection() -> void:
	for id in Roster.staff_ids():
		var tier := Economy.affection_tier(id)
		var seen := int(cabinet["affSeen"].get(id, 0))
		if tier > seen:
			cabinet["affSeen"][id] = tier
			save_cabinet()
			tier_up.emit(id, tier)
			banner.emit(I18n.f("aff_caption", [I18n.t(str(Roster.by(id).get("nameKey", id))), tier]))


func aff_plate(id: String, tier: int) -> String:
	var base: String = AFF_PLATE.get(id, "cg_mirei_lease")
	if tier == 1:
		return base + "_locked"
	if tier == 2:
		return base
	if tier == 3:
		return "cg_mirei_lease"
	return "plate_unearned"


# ---- ticker ---------------------------------------------------------------------------

func tick_opts() -> Dictionary:
	return {
		"capMs": Economy.offline_cap_ms(),
		"dupes": Economy.dupe_map(),
		"shields": func() -> bool: return Economy.use_shield(),
		"onSettle": _on_shift_settle,
		"onShift": func(id: String, _f: Dictionary) -> void: Economy.add_shifts(id, 1),
		"onEvict": func(_f: Dictionary) -> void: award("cg_evicted"),
	}


func run_tick(from_visit: bool) -> Dictionary:
	var rep := Idle.tick(B, now(), tick_opts())
	if int(rep["shifts"]) > 0 or int(rep["days"]) > 0:
		Economy.save()
		save_building()
		check_affection()
	if from_visit and (int(rep["shifts"]) > 0 or rep["evictions"].size() > 0 or bool(rep["capped"])):
		returned.emit(rep)
	elif rep["evictions"].size() > 0:
		evicted.emit(rep)
	elif int(rep["shielded"]) > 0:
		shielded.emit()
	if int(rep["shifts"]) > 0 and not from_visit:
		shift_paid.emit(rep)
	if Idle.can_prestige(B) and not prestige_offered:
		prestige_offered = true
		prestige_ready.emit()
	changed.emit()
	return rep


func start() -> void:
	started = true
	cabinet["visits"] = int(cabinet.get("visits", 0)) + 1
	save_cabinet()


func _process(delta: float) -> void:
	_poll_bridge()
	if not started:
		return
	_acc += delta
	if _acc >= 1.0:
		_acc = 0.0
		run_tick(false)


# ---- what can be placed --------------------------------------------------------------

func placed_count(id: String) -> int:
	var n := 0
	for f in B["floors"]:
		for c in f["cells"]:
			if c != null and str(c) == id:
				n += 1
	return n


func available() -> Array:
	var pool: Array = []
	for p in Roster.ROSTER:
		if Economy.owned(p["id"]) <= 0:
			continue
		var free: int = int(p["slots"]) - placed_count(p["id"])
		for _i in range(free):
			pool.append(p["id"])
	for id in Roster.OBJECTS:
		for _i in range(int(B["inventory"].get(id, 0))):
			pool.append(id)
	return pool


func reroll_cost(f: Dictionary) -> int:
	return 4 + (int(f["n"]) - 1)


func settle_floor(f: Dictionary) -> Dictionary:
	return Roster.settle_idle(f["cells"], B["relics"], Economy.dupe_map())


func floor_pay(f: Dictionary) -> int:
	return int(Idle.floor_shift(B, f, Economy.dupe_map())["pay"])


func rate_per_hour() -> float:
	return Idle.rate_per_hour(B, Economy.dupe_map())


## The manual settle commits the board: the skill ladder is evaluated on it (no pay —
## the shifts pay).
func commit(f: Dictionary) -> Dictionary:
	var r := settle_floor(f)
	best_payout = max(best_payout, int(r["payout"]))
	best_chain = max(best_chain, int(r["chain"]))
	award_board(f, r, int(r["chain"]))
	award_cleared(f, int(round(float(r["shift"]) * float(B["mult"]))) - break_even(f))
	save_building()
	changed.emit()
	return r


func place(f: Dictionary, index: int, id: String) -> bool:
	var next := Landlord.place_at(f["cells"], id, index)
	if next.is_empty():
		return false
	f["cells"] = next
	if Roster.OBJECTS.has(id):
		B["inventory"][id] = int(B["inventory"].get(id, 0)) - 1
	save_building()
	changed.emit()
	return true


func take_back(f: Dictionary, index: int) -> String:
	var id = f["cells"][index]
	if id == null:
		return ""
	f["cells"][index] = null
	if Roster.OBJECTS.has(str(id)):
		B["inventory"][str(id)] = int(B["inventory"].get(str(id), 0)) + 1
	save_building()
	changed.emit()
	return str(id)


func reroll(f: Dictionary) -> bool:
	var cost := reroll_cost(f)
	if int(B["bank"]) < cost:
		return false
	B["bank"] = int(B["bank"]) - cost
	save_building()
	changed.emit()
	return true


func build_floor() -> Dictionary:
	var res := Idle.build_floor(B, now())
	if res["ok"]:
		if int(res["n"]) >= Idle.MAX_FLOORS:
			award("cg_floor9")
		save_building()
		changed.emit()
	return res


func buy_object(id: String) -> bool:
	var price: int = OBJECT_PRICE[id]
	if int(B["bank"]) < price:
		return false
	B["bank"] = int(B["bank"]) - price
	B["inventory"][id] = int(B["inventory"].get(id, 0)) + 1
	save_building()
	changed.emit()
	return true


func buy_relic(id: String) -> bool:
	if B["relics"].has(id) or int(B["bank"]) < RELIC_PRICE:
		return false
	B["bank"] = int(B["bank"]) - RELIC_PRICE
	B["relics"].append(id)
	save_building()
	changed.emit()
	return true


func do_timeskip() -> Dictionary:
	var ms := Economy.take_timeskip()
	var rep := Idle.timeskip(B, now(), ms, tick_opts())
	Economy.save()
	save_building()
	check_affection()
	changed.emit()
	return rep


func do_prestige() -> void:
	Idle.prestige(B, now())
	prestige_offered = false
	save_building()
	changed.emit()


# ---- daily floor ------------------------------------------------------------------------

static func seeded(seed: int) -> Callable:
	var s := [seed & 0xFFFFFFFF]
	return func() -> float:
		s[0] = (s[0] * 1664525 + 1013904223) & 0xFFFFFFFF
		return float(s[0]) / 4294967296.0


func daily_key() -> String:
	return str(Idle.day_index(now()))


func daily_seq() -> Array:
	var rng := seeded(Idle.day_index(now()) * 7919 + 17)
	var bag := ["coffee", "coffee", "coffee", "dan", "dan", "priya", "priya", "priya", "mara", "wes", "mute", "mute", "printer", "corner", "nia", "sol"]
	var seq: Array = []
	for _i in range(12):
		seq.append(bag[int(floor(float(rng.call()) * bag.size()))])
	return seq


## Mocked distribution: an exponential fit to the random-vs-chain spread in the
## prototype's tests/kill_condition.cjs. The real one comes from the server.
static func percentile(score: int) -> int:
	return max(1, min(99, int(round(100.0 * (1.0 - exp(-float(score) / 90.0))))))


func finish_daily(r: Dictionary) -> Dictionary:
	var k := daily_key()
	B["daily"][k] = max(int(B["daily"].get(k, 0)), int(r["shift"]))
	save_building()
	return {"day": k, "shift": int(r["shift"]), "best": int(B["daily"][k]), "chain": int(r["chain"]), "pct": percentile(int(B["daily"][k]))}


# ---- Mirei ----------------------------------------------------------------------------------

## moodFrom(): the parent's, over the per-shift pay against the floor's break-even.
func mood_for(f: Dictionary, pay: int) -> String:
	var occupied := 0
	for c in f["cells"]:
		if c != null:
			occupied += 1
	if occupied == 0:
		return "empty"
	var need := break_even(f)
	if pay >= need:
		return "calm"
	return "tense" if pay >= need * 0.75 else "fail"


func bark(rep: Dictionary) -> String:
	if rep["evictions"].size() > 0:
		return I18n.t("r_evicted")
	if int(rep["shielded"]) > 0:
		return I18n.t("r_shielded")
	if bool(rep["capped"]) and int(rep["shifts"]) > 0:
		return I18n.t("r_capped")
	if int(rep["shifts"]) == 0:
		return I18n.t("r_nothing")
	if int(cabinet.get("visits", 0)) <= 1:
		return I18n.t("r_first")
	var per_shift := float(rep["rent"]) / float(rep["shifts"])
	if per_shift >= 60:
		return I18n.t("r_rich")
	if per_shift >= 12:
		return I18n.t("r_ok")
	return I18n.t("r_thin")


# ---- dev hooks --------------------------------------------------------------------------------

func dev_advance(ms: int) -> Dictionary:
	B["clockOffset"] = int(B.get("clockOffset", 0)) + ms
	save_building()
	return run_tick(true)


func dev_force_prestige() -> void:
	B["solventDays"] = Idle.PRESTIGE_DAYS
	prestige_offered = false
	save_building()
	run_tick(false)


## Web dev bridge: the headless run pushes JSON commands onto window.__oi_cmd and reads
## window.__oi_state. Polled once a frame; a page without the array costs one eval.
## Every command is something the player could also do by clicking — this is a driver,
## not a cheat surface with anything the UI does not have.
var bridge_handler: Callable = Callable()

func _poll_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("(function(){var q=window.__oi_cmd||[];if(!q.length)return '';var c=q.shift();return JSON.stringify(c);})()")
	if raw == null or str(raw) == "":
		return
	var cmd = JSON.parse_string(str(raw))
	if typeof(cmd) != TYPE_DICTIONARY:
		return
	var out := {"ok": true}
	match str(cmd.get("op", "")):
		"advance":
			var rep := dev_advance(int(cmd.get("ms", 0)))
			out["shifts"] = rep["shifts"]
			out["rent"] = rep["rent"]
		"gold":
			Economy.dev_add_gold(int(cmd.get("n", 0)))
		"prestige":
			dev_force_prestige()
		"reset":
			reset_all()
		_:
			if bridge_handler.is_valid():
				out = bridge_handler.call(cmd)
			else:
				out = {"ok": false, "why": "no_handler"}
	out["seq"] = cmd.get("seq", 0)
	JavaScriptBridge.eval("window.__oi_result=%s;window.__oi_state=%s" % [JSON.stringify(out), JSON.stringify(dev_state())])


func dev_state() -> Dictionary:
	var floors: Array = []
	for f in B["floors"]:
		floors.append({"n": f["n"], "cells": f["cells"], "pay": floor_pay(f)})
	return {"bank": B["bank"], "gold": Economy.gold(), "tickets": Economy.tickets(), "building": B["building"], "mult": B["mult"],
		"floors": floors, "cg": cabinet["cg"], "visits": cabinet["visits"], "solventDays": B["solventDays"], "rate": rate_per_hour()}
