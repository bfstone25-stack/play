extends Node
## Headless test scene — the prototype's tests/idle.test.cjs (75 checks) ported, plus the
## JS<->GDScript conformance test over tests/conformance.json.
##
##   $GODOT --headless --path . res://tests/run_tests.tscn
##
## A scene, not --script: the autoloads (Economy, Ticker, Gate, Look, Sfx) exist here, so
## the economy under test is the one the game runs.

const H: int = 3600 * 1000
const M: int = 60 * 1000
const T0: int = 1800000000000 - (1800000000000 % 86400000) + 6 * H

var passed := 0
var failed := 0


func ok(c: bool, m: String) -> void:
	if c:
		passed += 1
		print("  ok   " + m)
	else:
		failed += 1
		printerr("  FAIL " + m)


func eq(a, b, m: String) -> void:
	ok(a == b, m + " (got " + JSON.stringify(a) + ", want " + JSON.stringify(b) + ")")


func chain_floor(f: Dictionary) -> Dictionary:
	for pair in [[0, "coffee"], [1, "dan"], [2, "coffee"], [5, "mute"], [6, "dan"], [7, "mara"]]:
		f["cells"][pair[0]] = pair[1]
	return f


func fresh_economy() -> void:
	Economy.reset()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	Economy.persist_enabled = true
	Ticker.persist_enabled = false
	_ticker()
	_offline_cap()
	_cap_sku()
	_rent_check()
	_frozen_days()
	_shield()
	_prestige()
	_dupes()
	_gacha()
	_grants()
	_timeskip()
	_affection()
	_ladder()
	_conformance()
	print("\n%d checks passed, %d failed" % [passed, failed])
	print("TESTS_OK" if failed == 0 else "TESTS_FAILED")
	get_tree().quit(0 if failed == 0 else 1)


func _ticker() -> void:
	print("shift ticker")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var per: int = Idle.floor_shift(s, s["floors"][0])["pay"]
	ok(per > 0, "a built floor pays per shift: " + str(per))
	var rep := Idle.tick(s, T0 + 9 * M)
	eq(rep["shifts"], 0, "nothing fires before the first 10 minutes")
	rep = Idle.tick(s, T0 + 10 * M)
	eq(rep["shifts"], 1, "one shift at 10 minutes")
	eq(s["bank"], per, "the shift landed in the bank")
	rep = Idle.tick(s, T0 + 60 * M)
	eq(rep["shifts"], 5, "five more by the hour")
	eq(Idle.rate_per_hour(s), float(per * 6), "HUD rent/hour is six shifts of the board")


func _offline_cap() -> void:
	print("offline accrual is capped at 8 h")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var rep := Idle.tick(s, T0 + 20 * H, {"capMs": Idle.OFFLINE_CAP_MS})
	eq(rep["shifts"], 48, "20 h away pays 8 h = 48 shifts")
	ok(bool(rep["capped"]) and int(rep["frozenMs"]) == 12 * H, "report says the building froze for 12 h")
	var s2 := Idle.fresh(T0)
	chain_floor(s2["floors"][0])
	var rep2 := Idle.tick(s2, T0 + 20 * H, {"capMs": 24 * H})
	eq(rep2["shifts"], 120, "offline_cap_24h raises it: 20 h away pays 120 shifts")
	ok(not bool(rep2["capped"]), "and is not capped")
	var rep3 := Idle.tick(s, T0 + 20 * H + 9 * M)
	eq(rep3["shifts"], 0, "no catch-up burst after the cap")
	eq(Idle.tick(s, T0 + 20 * H + 10 * M)["shifts"], 1, "shift resumes on the 10-minute clock")


func _cap_sku() -> void:
	print("the cap SKU is wired through the economy")
	fresh_economy()
	eq(Economy.offline_cap_ms(), 8 * H, "default cap 8 h")
	Economy.dev_add_gold(500)
	ok(Economy.buy("offline_cap_24h")["ok"], "buy offline_cap_24h")
	eq(Economy.offline_cap_ms(), 24 * H, "cap now 24 h")
	eq(Economy.buy("offline_cap_24h")["why"], "already_owned", "one-time SKU cannot be bought twice")


func _rent_check() -> void:
	print("daily rent check evicts and refunds staff")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var ok1 := Idle.build_floor(s, T0)
	eq(ok1["why"], "bank", "floor 2 costs rent the bank does not have yet")
	s["bank"] = 10000
	ok(Idle.build_floor(s, T0)["ok"], "floor 2 built")
	s["floors"][1]["cells"][7] = "priya"
	var day_end: int = (Idle.day_index(T0) + 1) * Idle.DAY_MS
	var evicted: Array = []
	var rep := Idle.tick(s, day_end + 5 * M, {"capMs": 48 * H, "onEvict": func(f): evicted.append(f["n"])})
	eq(rep["days"], 1, "one daily check ran")
	eq(",".join(rep["evictions"].map(func(x): return str(x))), "2", "floor 2 evicted, floor 1 (chain board) solvent")
	eq(",".join(evicted.map(func(x): return str(x))), "2", "onEvict hook fired for floor 2")
	ok(not Idle._any(s["floors"][1]["cells"]), "evicted floor is cleared")
	ok(s["floors"][0]["cells"][1] == "dan", "solvent floor keeps its board")
	eq(s["floors"][1]["evictions"], 1, "eviction counted")
	eq(s["solventDays"], 0, "solvent-day streak reset by the eviction")
	var placed := 0
	for f in s["floors"]:
		placed += f["cells"].count("priya")
	eq(placed, 0, "Priya is back in the roster")
	var s3 := Idle.fresh(day_end - 6 * H)
	eq(Idle.rent_due(s3["floors"][0], [], day_end), int(ceil(Idle.daily_rent(s3["floors"][0], []) * 0.25)), "first-day rent prorated to the quarter day")


func _frozen_days() -> void:
	print("frozen days: one check for the day the window closed in, the rest skipped")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var rep := Idle.tick(s, T0 + 3 * 24 * H, {"capMs": 8 * H})
	eq(rep["shifts"], 48, "8 h of shifts")
	eq(rep["days"], 1, "exactly one rent check for a three-day absence")
	eq(s["lastDay"], Idle.day_index(T0 + 3 * 24 * H), "later frozen days skipped, not queued for the next tick")
	eq(Idle.tick(s, T0 + 3 * 24 * H + 1000)["days"], 0, "and the next tick runs no check")
	var s2 := Idle.fresh(T0)
	s2["floors"][0]["cells"][7] = "priya"
	var rep2 := Idle.tick(s2, T0 + 3 * 24 * H, {"capMs": 8 * H})
	eq(rep2["evictions"].size(), 1, "an insolvent floor is evicted once")
	eq(s2["floors"][0]["evictions"], 1, "eviction count 1")


func _shield() -> void:
	print("rent shield skips one eviction")
	fresh_economy()
	var s := Idle.fresh(T0)
	s["floors"][0]["cells"][7] = "priya"
	var day_end: int = (Idle.day_index(T0) + 1) * Idle.DAY_MS
	Economy.dev_add_gold(100)
	ok(Economy.buy("rent_shield")["ok"], "buy rent_shield")
	var rep := Idle.tick(s, day_end + M, {"capMs": 48 * H, "shields": func() -> bool: return Economy.use_shield()})
	eq(rep["evictions"].size(), 0, "no eviction")
	eq(rep["shielded"], 1, "shield consumed")
	eq(Economy.shields(), 0, "no shields left")


func _prestige() -> void:
	print("solvent streak and prestige")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var t := T0
	for _d in range(7):
		t += 12 * H
		Idle.tick(s, t, {"capMs": 8 * H})
		t += 12 * H
		Idle.tick(s, t, {"capMs": 8 * H})
	eq(s["solventDays"], 7, "seven solvent days, visiting twice a day")
	ok(Idle.can_prestige(s), "prestige unlocked")
	Idle.prestige(s, t)
	eq(s["building"], 2, "second building")
	eq(s["mult"], 1.5, "rent multiplier 1.5")
	chain_floor(s["floors"][0])
	var s2 := Idle.fresh(T0)
	chain_floor(s2["floors"][0])
	eq(Idle.floor_shift(s, s["floors"][0])["pay"], int(round(float(Idle.floor_shift(s2, s2["floors"][0])["pay"]) * 1.5)), "same board pays 1.5x in building 2")


func _dupes() -> void:
	print("dupes raise the shift bonus, capped")
	var cells := Idle.empty_cells()
	cells[1] = "dan"
	cells[0] = "coffee"
	var base: int = Roster.settle_idle(cells, [], {})["shift"]
	var d3: int = Roster.settle_idle(cells, [], {"dan": 3})["shift"]
	var d10: int = Roster.settle_idle(cells, [], {"dan": 10})["shift"]
	var d40: int = Roster.settle_idle(cells, [], {"dan": 40})["shift"]
	ok(d3 > base, "3 dupes pay more than none (%d -> %d)" % [base, d3])
	eq(Roster.dupe_bonus(3), 1.15, "+5% per dupe")
	eq(d10, d40, "bonus caps at 10 dupes")
	eq(Roster.dupe_bonus(99), 1.5, "cap is +50%")


func lcg(seed: int) -> Callable:
	return Ticker.seeded(seed)


func _gacha() -> void:
	print("gacha: weights and pity")
	fresh_economy()
	Economy.dev_add_gold(100000)
	var rng := lcg(7)
	var counts := {"common": 0, "rare": 0, "epic": 0}
	for _i in range(300):
		Economy.buy("pull_10")
		for r in Economy.pull(10, rng)["results"]:
			counts[r["rarity"]] += 1
	var pct := func(k: String) -> float: return float(counts[k]) / 30.0
	ok(pct.call("common") > 62 and pct.call("common") < 78, "common ~70%%: %.1f" % pct.call("common"))
	ok(pct.call("rare") > 18 and pct.call("rare") < 32, "rare ~25%%: %.1f" % pct.call("rare"))
	ok(pct.call("epic") > 3 and pct.call("epic") < 9, "epic ~5%% (+pity): %.1f" % pct.call("epic"))
	fresh_economy()
	Economy.dev_add_gold(10000)
	Economy.buy("pull_10")
	Economy.buy("pull_10")
	Economy.buy("pull_10")
	var never := func() -> float: return 0.99
	var res: Array = Economy.pull(30, never)["results"]
	var epics := 0
	for r in res.slice(0, 29):
		if r["rarity"] == "epic":
			epics += 1
	eq(epics, 0, "no epic in 29 unlucky pulls")
	eq(res[29]["rarity"], "epic", "pull 30 is the pity epic")
	eq(Economy.since_epic(), 0, "pity counter reset")
	ok(res[29]["id"] == "sol", "the epic is Sol (the only epic in the pool)")
	eq(Economy.owned("sol"), 1, "Sol is now owned")
	eq(Economy.pull(1, never)["why"], "tickets", "no tickets left: pull refused")


func _grants() -> void:
	print("SKU grants are idempotent")
	fresh_economy()
	var g1 := Economy.purchase("gold_m", "nutaku-tx-1")
	ok(g1["ok"] and Economy.gold() == 600, "gold_m grants 600")
	var g2 := Economy.purchase("gold_m", "nutaku-tx-1")
	ok(not g2["ok"] and g2["why"] == "duplicate", "same transaction id again is refused")
	eq(Economy.gold(), 600, "and grants nothing")
	ok(Economy.purchase("gold_m", "nutaku-tx-2")["ok"] and Economy.gold() == 1200, "a new transaction id grants again")
	eq(Economy.grant("nope", "x")["why"], "unknown_sku", "unknown SKU refused")
	ok(Economy.buy("pull_1")["ok"] and Economy.tickets() == 1 and Economy.gold() == 1170, "pull_1 costs 30 gold, grants a ticket")
	ok(Economy.buy("scene_skip_dan")["ok"], "scene_skip_<name> matched by prefix")
	eq(Economy.buy("scene_skip_dan")["why"], "already_owned", "scene skip once per character")
	eq(Economy.buy("gold_s")["why"], "iap_only", "IAP SKUs are not buyable with Gold")
	# the ledger survives a reload (same user://, new state)
	Economy.state = Economy._fresh()
	Economy.load_state()
	eq(Economy.gold(), 1090, "gold persisted across reload")
	ok(not Economy.purchase("gold_m", "nutaku-tx-1")["ok"], "duplicate detection persisted too")


func _timeskip() -> void:
	print("timeskip collects four hours now without moving the real clock")
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	Idle.tick(s, T0 + 5 * M)
	var rep := Idle.timeskip(s, T0 + 5 * M, 4 * H)
	eq(rep["shifts"], 24, "24 shifts collected")
	eq(Idle.tick(s, T0 + 10 * M)["shifts"], 1, "the real 10-minute shift still lands on time")


func _affection() -> void:
	print("affection counts shifts on a solvent floor")
	fresh_economy()
	var s := Idle.fresh(T0)
	chain_floor(s["floors"][0])
	var aff := {}
	Idle.tick(s, T0 + 200 * M, {"onShift": func(id: String, _f): aff[id] = int(aff.get(id, 0)) + 1})
	eq(aff.get("dan", 0), 40, "two Dans x 20 shifts = 40 shift-credits")
	eq(aff.get("mara", 0), 20, "Mara: 20")
	ok(not aff.has("coffee"), "objects have no affection")
	Economy.add_shifts("dan", 60)
	eq(Economy.affection_tier("dan"), 2, "60 shifts = tier 2 (cg2)")
	Economy.add_shifts("dan", 90)
	eq(Economy.affection_tier("dan"), 3, "150 = tier 3")
	ok(not Economy.can_see_scene("dan"), "tier-4 scene not yet")
	Economy.dev_add_gold(80)
	Economy.buy("scene_skip_dan")
	ok(Economy.can_see_scene("dan"), "scene_skip_dan opens it at 150")


## The Godot shell's own additions: the ladder through Ticker, and the daily seed.
func _ladder() -> void:
	print("skill ladder through the ticker")
	fresh_economy()
	Ticker.B = Idle.fresh(T0)
	Ticker.cabinet = {"cg": [], "affSeen": {}, "visits": 0, "sound": true}
	var f: Dictionary = Ticker.B["floors"][0]
	chain_floor(f)
	var r := Ticker.commit(f)
	ok(Ticker.earned("cg_mirei_lease"), "a surplus board on commit earns the free plate")
	ok(not Ticker.earned("cg_dan_x"), "two coffee-dan links are not three")
	f["cells"][10] = "coffee"
	f["cells"][11] = "dan"
	f["cells"][12] = "coffee"
	r = Ticker.commit(f)
	ok(r["events"].count("coffee-dan") >= 3 and Ticker.earned("cg_dan_x"), "three coffee->Dan multipliers earn cg_dan_x")
	Ticker.B["relics"].append("quiet")
	r = Ticker.commit(f)
	ok(int(r["chain"]) >= 6 and Ticker.earned("cg_quiet_floor"), "six-link chain with Quiet Floor earns cg_quiet_floor")
	Ticker.B["bank"] = 10000
	Ticker.commit(f)
	ok(Ticker.earned("cg_vault_x"), "bank >= 40 on a commit earns cg_vault_x")
	for _i in range(8):
		Ticker.build_floor()
	ok(Ticker.earned("cg_floor9"), "reaching floor nine earns cg_floor9")
	eq(Ticker.mood_for(f, 0), "fail", "moodFrom: an occupied floor paying nothing is fail")
	eq(Ticker.mood_for(f, 999), "calm", "moodFrom: covering break-even is calm")
	eq(Ticker.mood_for(Idle.new_floor(3, T0), 0), "empty", "moodFrom: an empty floor is empty")
	var seq := Ticker.daily_seq()
	eq(seq.size(), 12, "daily floor deals twelve pieces")
	eq(seq, Ticker.daily_seq(), "and the same twelve for everyone that day")


func _conformance() -> void:
	print("JS <-> GDScript conformance (tests/conformance.json)")
	var f := FileAccess.open("res://tests/conformance.json", FileAccess.READ)
	if f == null:
		ok(false, "tests/conformance.json missing — run: node tests/conformance_gen.cjs")
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	var boards: Array = data["boards"]
	var bad_settle := 0
	var bad_tick := 0
	var bad_rate := 0
	var first := ""
	for b in range(boards.size()):
		var board: Dictionary = boards[b]
		var cells: Array = board["cells"]
		var relics: Array = board["relics"]
		var dupes := {}
		for k in board["dupes"].keys():
			dupes[k] = int(board["dupes"][k])
		var r := Roster.settle_idle(cells, relics, dupes)
		var want: Dictionary = board["settle"]
		var same := int(r["payout"]) == int(want["payout"]) and int(r["shift"]) == int(want["shift"]) and int(r["chain"]) == int(want["chain"])
		same = same and abs(float(r["mult"]) - float(want["mult"])) < 1e-9 and abs(float(r["dupeExtra"]) - float(want["dupeExtra"])) < 1e-9
		same = same and _arr_eq(r["events"], want["events"]) and _arr_eq(r["cellScore"], want["cellScore"]) and _links_eq(r["links"], want["links"])
		var plain := Roster.settle_idle(cells, relics, {})
		same = same and int(plain["shift"]) == int(board["plain"]["shift"])
		if not same:
			bad_settle += 1
			if first == "":
				first = "board %d settle: got %s want %s" % [b, JSON.stringify({"p": r["payout"], "s": r["shift"], "c": r["chain"], "ev": r["events"]}), JSON.stringify(want)]
		# ticker
		var s := Idle.fresh(T0)
		s["floors"][0]["cells"] = cells.duplicate()
		s["relics"] = relics.duplicate()
		if board["floors"].size() > 1:
			s["bank"] = 10000
			Idle.build_floor(s, T0)
			s["floors"][1]["cells"][7] = "priya"
		var by_staff := {}
		var tick_ok := true
		for tk in board["ticks"]:
			var rep := Idle.tick(s, int(tk["at"]), {"capMs": 8 * H, "dupes": dupes, "onShift": func(id: String, _f): by_staff[id] = int(by_staff.get(id, 0)) + 1})
			var same_t := int(rep["shifts"]) == int(tk["shifts"]) and int(rep["rent"]) == int(tk["rent"]) and int(rep["rentPaid"]) == int(tk["rentPaid"])
			same_t = same_t and bool(rep["capped"]) == bool(tk["capped"]) and int(rep["frozenMs"]) == int(tk["frozenMs"]) and int(rep["days"]) == int(tk["days"])
			same_t = same_t and int(s["bank"]) == int(tk["bank"]) and int(s["nextShift"]) == int(tk["nextShift"]) and int(s["lastDay"]) == int(tk["lastDay"])
			same_t = same_t and int(s["solventDays"]) == int(tk["solventDays"]) and int(s["totalShifts"]) == int(tk["totalShifts"]) and _arr_eq(rep["evictions"], tk["evictions"])
			same_t = same_t and _dict_eq(rep["perFloor"], tk["perFloor"])
			if not same_t:
				tick_ok = false
				if first == "":
					first = "board %d tick@%d: got %s/%s/%s want %s" % [b, int(tk["at"]), JSON.stringify(rep), JSON.stringify(s["bank"]), JSON.stringify(s["nextShift"]), JSON.stringify(tk)]
		for i in range(board["floors"].size()):
			var wf: Dictionary = board["floors"][i]
			var gf: Dictionary = s["floors"][i]
			if not (_arr_eq(gf["cells"], wf["cells"]) and int(gf["evictions"]) == int(wf["evictions"]) and int(gf["shifts"]) == int(wf["shifts"]) and int(gf["best"]) == int(wf["best"]) and int(gf["earnedToday"]) == int(wf["earnedToday"]) and int(gf["builtAt"]) == int(wf["builtAt"])):
				tick_ok = false
		if not _dict_eq(by_staff, board["shiftsByStaff"]):
			tick_ok = false
		if not tick_ok:
			bad_tick += 1
		if abs(Idle.rate_per_hour(s, dupes) - float(board["rate"])) > 1e-6:
			bad_rate += 1
	eq(bad_settle, 0, "settleIdle identical on all %d boards" % boards.size())
	eq(bad_tick, 0, "ticker identical on all %d boards (shifts, bank, rent, evictions, per-floor, per-staff)" % boards.size())
	eq(bad_rate, 0, "ratePerHour identical on all boards")
	if first != "":
		printerr("  first mismatch: " + first)
	# gacha
	var bad_gacha := 0
	for g in data["gacha"]:
		fresh_economy()
		Economy.dev_add_gold(100000)
		for _i in range(4):
			Economy.buy("pull_10")
		var res: Array = Economy.pull(40, lcg(int(g["seed"])))["results"]
		var ids: Array = []
		var rar: Array = []
		var dps: Array = []
		for x in res:
			ids.append(x["id"])
			rar.append(x["rarity"])
			dps.append(x["dupes"])
		if not (_arr_eq(ids, g["ids"]) and _arr_eq(rar, g["rarities"]) and _arr_eq(dps, g["dupes"]) and Economy.since_epic() == int(g["sinceEpic"])):
			bad_gacha += 1
	eq(bad_gacha, 0, "gacha identical on all %d seeded 40-pull runs" % data["gacha"].size())
	var bad_rent := 0
	for i in range(9):
		var want: Array = data["rent"][i]
		if Landlord.rent_for_floor(i + 1, []) != int(want[0]) or Landlord.rent_for_floor(i + 1, ["glass"]) != int(want[1]) or Idle.floor_cost(i + 1) != int(want[2]):
			bad_rent += 1
	eq(bad_rent, 0, "rentForFloor / floorCost identical for floors 1-9")
	var m := 1.0
	var bad_p := 0
	for i in range(data["prestige"].size()):
		m = Idle.to_fixed3(m * 1.5)
		if abs(m - float(data["prestige"][i])) > 1e-9:
			bad_p += 1
	eq(bad_p, 0, "prestige multiplier chain identical for twelve buildings")


func _arr_eq(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		var x = a[i]
		var y = b[i]
		if x == null or y == null:
			if not (x == null and y == null):
				return false
			continue
		if typeof(x) == TYPE_STRING or typeof(y) == TYPE_STRING:
			if str(x) != str(y):
				return false
		elif float(x) != float(y):
			return false
	return true


func _links_eq(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if int(a[i]["a"]) != int(b[i]["a"]) or int(a[i]["b"]) != int(b[i]["b"]) or str(a[i]["kind"]) != str(b[i]["kind"]):
			return false
	return true


func _dict_eq(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a.keys():
		if not b.has(str(k)) or int(a[k]) != int(b[str(k)]):
			return false
	return true
