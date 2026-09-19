class_name Idle
## Port of play/overtime-idle/frontend/js/idle.js — the building keeps running when you
## leave. Pure state (a Dictionary) + a clock you hand in, in milliseconds. Nothing here
## touches the scene tree; tests drive it with a mocked clock and Ticker with the real one.

const SHIFT_MS: int = 10 * 60 * 1000
const DAY_MS: int = 86400 * 1000
const OFFLINE_CAP_MS: int = 8 * 3600 * 1000
const RENT_SHIFTS := 24
const MAX_FLOORS := 9
const PRESTIGE_DAYS := 7
const PRESTIGE_MULT := 1.5


static func day_index(ms: int) -> int:
	return ms / DAY_MS


static func empty_cells() -> Array:
	return Landlord.empty_cells()


static func new_floor(n: int, now: int) -> Dictionary:
	return {"n": n, "cells": empty_cells(), "builtAt": now, "earnedToday": 0, "shifts": 0, "evictions": 0, "best": 0}


static func fresh(now: int) -> Dictionary:
	return {"v": 1, "building": 1, "mult": 1.0, "floors": [new_floor(1, now)], "relics": [], "bank": 0, "inventory": {},
		"lastSeen": now, "nextShift": now + SHIFT_MS, "lastDay": day_index(now), "solventDays": 0, "totalShifts": 0, "totalRent": 0,
		"clockOffset": 0, "daily": {}}


static func floor_cost(n: int) -> int:
	return Landlord.rent_for_floor(n, []) * 6


static func daily_rent(floor_d: Dictionary, relics: Array) -> int:
	return Landlord.rent_for_floor(int(floor_d["n"]), relics) * RENT_SHIFTS


static func rent_due(floor_d: Dictionary, relics: Array, at: int) -> int:
	var frac: float = min(1.0, max(0.0, float(at - int(floor_d["builtAt"])) / float(DAY_MS)))
	return int(ceil(float(daily_rent(floor_d, relics)) * frac))


static func floor_shift(state: Dictionary, floor_d: Dictionary, dupes: Dictionary = {}) -> Dictionary:
	var r := Roster.settle_idle(floor_d["cells"], state["relics"], dupes)
	var pay := int(round(float(r["shift"]) * float(state["mult"])))
	return {"r": r, "pay": pay}


static func rate_per_hour(state: Dictionary, dupes: Dictionary = {}) -> float:
	var sum := 0
	for f in state["floors"]:
		sum += int(floor_shift(state, f, dupes)["pay"])
	return float(sum) * (3600000.0 / float(SHIFT_MS))


static func _any(cells: Array) -> bool:
	for c in cells:
		if c != null and str(c) != "":
			return true
	return false


## tick(state, now, opts) — advance the building to `now`. Mutates state, returns a report.
##   opts.capMs     offline cap (Economy.offline_cap_ms())
##   opts.dupes     {id: n}
##   opts.shields   Callable() -> bool — consume a rent shield, if any
##   opts.onSettle  Callable(floor, r, chain)
##   opts.onShift   Callable(id, floor)
##   opts.onEvict   Callable(floor)
static func tick(state: Dictionary, now: int, opts: Dictionary = {}) -> Dictionary:
	var cap_ms: int = int(opts.get("capMs", 0))
	if cap_ms <= 0:
		cap_ms = OFFLINE_CAP_MS
	var last_seen: int = int(state["lastSeen"])
	var report := {"from": last_seen, "to": now, "elapsed": now - last_seen, "shifts": 0, "rent": 0, "evictions": [], "rentPaid": 0,
		"capped": false, "frozenMs": 0, "perFloor": {}, "days": 0, "shielded": 0}
	if now <= last_seen:
		return report
	var end: int = min(now, last_seen + cap_ms)
	var frozen: bool = now > last_seen + cap_ms
	if frozen:
		report["frozenMs"] = now - end
		report["capped"] = int(report["frozenMs"]) >= SHIFT_MS
	var dupes: Dictionary = opts.get("dupes", {})

	var daily_check := func(at: int) -> void:
		report["days"] = int(report["days"]) + 1
		var all_solvent: bool = state["floors"].size() > 0
		for f in state["floors"]:
			var due := rent_due(f, state["relics"], at)
			state["bank"] = max(0, int(state["bank"]) - due)
			report["rentPaid"] = int(report["rentPaid"]) + due
			if int(f["earnedToday"]) >= due:
				f["earnedToday"] = 0
				continue
			if opts.has("shields") and bool((opts["shields"] as Callable).call()):
				report["shielded"] = int(report["shielded"]) + 1
				f["earnedToday"] = 0
				continue
			all_solvent = false
			f["cells"] = empty_cells()
			f["evictions"] = int(f["evictions"]) + 1
			f["earnedToday"] = 0
			f["builtAt"] = at
			report["evictions"].append(int(f["n"]))
			if opts.has("onEvict"):
				(opts["onEvict"] as Callable).call(f)
		state["solventDays"] = (int(state["solventDays"]) + 1) if all_solvent else 0

	while int(state["nextShift"]) <= end:
		var at: int = int(state["nextShift"])
		while day_index(at) > int(state["lastDay"]):
			state["lastDay"] = int(state["lastDay"]) + 1
			daily_check.call(int(state["lastDay"]) * DAY_MS)
		for f in state["floors"]:
			var fs := floor_shift(state, f, dupes)
			var pay: int = fs["pay"]
			if pay <= 0 and not _any(f["cells"]):
				continue
			state["bank"] = int(state["bank"]) + pay
			f["earnedToday"] = int(f["earnedToday"]) + pay
			f["shifts"] = int(f["shifts"]) + 1
			f["best"] = max(int(f["best"]), pay)
			state["totalShifts"] = int(state["totalShifts"]) + 1
			state["totalRent"] = int(state["totalRent"]) + pay
			report["shifts"] = int(report["shifts"]) + 1
			report["rent"] = int(report["rent"]) + pay
			var key := str(int(f["n"]))
			report["perFloor"][key] = int(report["perFloor"].get(key, 0)) + pay
			if opts.has("onShift"):
				for id in f["cells"]:
					if id != null and Roster.is_staff(str(id)):
						(opts["onShift"] as Callable).call(str(id), f)
			if opts.has("onSettle"):
				(opts["onSettle"] as Callable).call(f, fs["r"], int(fs["r"]["chain"]))
		state["nextShift"] = int(state["nextShift"]) + SHIFT_MS
	while day_index(end) > int(state["lastDay"]):
		state["lastDay"] = int(state["lastDay"]) + 1
		daily_check.call(int(state["lastDay"]) * DAY_MS)
	if day_index(now) > int(state["lastDay"]):
		state["lastDay"] = int(state["lastDay"]) + 1
		daily_check.call(int(state["lastDay"]) * DAY_MS)
		state["lastDay"] = day_index(now)
	if frozen:
		state["nextShift"] = now + (int(state["nextShift"]) - end)
	state["lastSeen"] = now
	return report


static func timeskip(state: Dictionary, now: int, ms: int, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate()
	o["capMs"] = ms + OFFLINE_CAP_MS
	var rep := tick(state, now + ms, o)
	state["lastSeen"] = now
	state["nextShift"] = int(state["nextShift"]) - ms
	return rep


static func can_prestige(state: Dictionary) -> bool:
	return int(state["solventDays"]) >= PRESTIGE_DAYS and state["floors"].size() >= 1


static func prestige(state: Dictionary, now: int) -> Dictionary:
	state["building"] = int(state["building"]) + 1
	state["mult"] = to_fixed3(float(state["mult"]) * PRESTIGE_MULT)
	state["floors"] = [new_floor(1, now)]
	state["relics"] = []
	state["solventDays"] = 0
	state["bank"] = 0
	state["inventory"] = {}
	return state


## JS `+(x).toFixed(3)`: ties round away from zero (5.0625 -> 5.063), where C's %.3f
## rounds them to even (5.062). The conformance test pins the chain for twelve buildings.
static func to_fixed3(x: float) -> float:
	var scaled := x * 1000.0
	var n: float = floor(scaled)
	if scaled - n >= 0.5:
		n += 1.0
	return n / 1000.0


static func build_floor(state: Dictionary, now: int) -> Dictionary:
	var n: int = state["floors"].size() + 1
	if n > MAX_FLOORS:
		return {"ok": false, "why": "max"}
	var cost := floor_cost(n)
	if int(state["bank"]) < cost:
		return {"ok": false, "why": "bank", "need": cost - int(state["bank"])}
	state["bank"] = int(state["bank"]) - cost
	state["floors"].append(new_floor(n, now))
	return {"ok": true, "n": n}
