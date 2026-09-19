extends Node
## Headless tests — the HTML spec's rpg-smoke.cjs ported (a whole week played by a kiting
## thumb: level-ups, drops, party, week rollover, the Wednesday phrase projectiles) plus
## the JS<->GDScript conformance over tests/conformance.json.
##
##   bash tests/run.sh      (fails on any engine error, not only a failed check)

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


func near(a, b, m: String, tol: float = 1e-6) -> void:
	var da := float(a) if a != null else INF
	var db := float(b) if b != null else INF
	ok((a == null and b == null) or absf(da - db) <= tol * maxf(1.0, absf(db)), m + " (got " + str(a) + ", want " + str(b) + ")")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	Game.persist_enabled = false
	_unit()
	_week()
	_conformance()
	print("\n%d checks passed, %d failed" % [passed, failed])
	print("TESTS_OK" if failed == 0 else "TESTS_FAILED")
	get_tree().quit(0 if failed == 0 else 1)


static func kite(run: Dictionary) -> Dictionary:
	var n := BMCore.nearest_foe(run)
	var tx := BMCore.W / 2
	var ty := BMCore.H * 0.8
	if not n.is_empty():
		var dx: float = run["px"] - n["x"]
		var dy: float = run["py"] - n["y"]
		var m := BMCore.hypot(dx, dy)
		if m == 0.0:
			m = 1.0
		tx = maxf(20, minf(BMCore.W - 20, run["px"] + dx / m * 120))
		ty = maxf(70, minf(BMCore.H - 20, run["py"] + dy / m * 120))
	return {"x": tx, "y": ty}


func _unit() -> void:
	print("units")
	eq(BMCore.xp_needed(1), 19, "xp for level 1")
	eq(BMCore.xp_needed(7), 73, "xp for level 7")
	var p := BMCore.new_profile()
	var s := BMCore.compute_stats(p)
	eq(s["hp"], 100, "base hp")
	eq(s["atk"], 10.0, "base atk")
	p["level"] = 4
	p["skills"] = ["overtime", "delegate", "boundary"]
	p["owned"] = ["stapler", "headphones"]
	p["equipped"]["hand"] = "stapler"
	p["equipped"]["wear"] = "headphones"
	p["party"] = ["intern", "pm"]
	s = BMCore.compute_stats(p)
	eq(s["hp"], 100 + 24 + 20 + 18, "hp with growth, headphones, boundary")
	eq(s["atk"], 10 + 3.6 + 4 + 2, "atk with growth, stapler, spite")
	eq(s["rate"], 2.35, "rate with headphones")
	eq(s["flags"], {"pierce": 1}, "delegate sets the pierce flag")
	eq(s["partyDps"], 15, "party dps sums")

	# level-up: three distinct choices, applying one raises max hp for boundary
	var run := BMCore.create_run(BMCore.new_profile(), 0, 5)
	BMCore.gain_xp(run, 19)
	eq(run["level"], 2, "19 xp is level 2")
	ok(run["pending"] != null and run["pending"].size() == 3, "three skill cards pending")
	var uniq := {}
	for id in run["pending"]:
		uniq[id] = true
	eq(uniq.size(), 3, "the three cards are distinct")
	ok(not BMCore.apply_skill(run, "not-offered"), "a card not offered is refused")
	var before: float = run["maxHp"]
	ok(BMCore.apply_skill(run, run["pending"][0]), "picking an offered card works")
	ok(run["pending"] == null, "pending cleared after the pick")
	ok(run["maxHp"] >= before, "max hp never drops on a pick")
	ok(BMCore.step(run, 1.0 / 60, null)["t"] > 0, "step runs once pending is cleared")

	# rant: pattern thresholds and projectile counts
	var cat := BMCore.rant_catalog()
	eq(BMCore.rant_pattern(["ok"], cat), "stream", "ok alone streams")
	eq(BMCore.rant_pattern(["ok", "lie", "teach"], cat), "spread", "three phrases spread")
	eq(BMCore.rant_pattern(["legend"], cat), "burst", "legend bursts")
	var wed := BMCore.create_run(BMCore.new_profile(), 2, 9)
	wed["foes"].append({"kind": "cc", "x": 210.0, "y": 100.0, "r": 8.0, "color": "", "hp": 1e6, "spd": 0.0, "xp": 0, "dmg": 0.0, "hit": 0.0})
	BMCore.fire(wed)
	eq(wed["shots"].size(), 1, "stream: one phrase projectile")
	eq(wed["shots"][0]["text"], "OK", "the projectile carries the phrase")
	wed["rantCombo"] = ["ok", "lie", "teach"]
	wed["shots"].clear()
	BMCore.fire(wed)
	eq(wed["shots"].size(), 3, "spread: three phrase projectiles")
	wed["rantCombo"] = ["legend"]
	wed["shots"].clear()
	BMCore.fire(wed)
	eq(wed["shots"].size(), 5, "burst: five phrase projectiles")
	wed["stats"]["flags"]["multishot"] = 1
	wed["shots"].clear()
	BMCore.fire(wed)
	eq(wed["shots"].size(), 6, "burst + CC Everyone: six")
	wed["lang"] = "zh"
	eq(BMCore.phrase_for(wed, 0), "别劝", "zh phrase text")

	# drops, party, rollover through commit_run
	var prof := BMCore.new_profile()
	var r0 := BMCore.create_run(prof, 0, 1)
	r0["over"] = "clear"
	r0["reward"] = "stapler"
	r0["level"] = 3
	BMCore.commit_run(prof, r0)
	eq(prof["owned"], ["stapler"], "monday drops the stapler")
	eq(prof["equipped"]["hand"], "stapler", "an empty slot auto-equips the drop")
	eq(prof["party"], ["intern"], "Riley joins after Monday")
	eq(prof["day"], 1, "day advances")
	eq(prof["level"], 3, "level persists")
	var r1 := BMCore.create_run(prof, 1, 1)
	r1["over"] = "dead"
	BMCore.commit_run(prof, r1)
	eq(prof["day"], 1, "a death does not advance the day")
	for d in range(1, 5):
		var rr := BMCore.create_run(prof, d, 1)
		rr["over"] = "clear"
		rr["reward"] = BMData.DAYS[d]["drop"]
		BMCore.commit_run(prof, rr)
	eq(prof["owned"].size(), 5, "five drops across the week")
	eq(prof["party"], ["intern", "pm", "hr"], "Morgan and Pat joined")
	eq(prof["week"], 1, "friday rolls into week 2")
	eq(prof["day"], 0, "back to monday")
	ok(prof.get("weekend", false), "the weekend flag is set for the Saturday screen")
	ok(BMCore.equip(prof, "stapler"), "equip toggles an owned item")
	eq(prof["equipped"]["hand"], null, "toggled off")
	ok(not BMCore.equip(prof, "coldbrew"), "cannot equip what you do not own")
	var w2 := BMCore.create_run(prof, 0, 1)
	eq(w2["week"]["id"], "w2", "week 2 is the crunch week")
	BMCore.spawn_foe(w2)
	near(w2["foes"][0]["hp"], BMData.FOES[w2["foes"][0]["kind"]]["hp"] * 1.6, "week 2 foes carry 1.6x hp")


func _week() -> void:
	print("a whole week, headless (rpg-smoke.cjs)")
	var profile := BMCore.new_profile()
	var level_ups := 0
	var phrase_shots := 0
	for d in BMData.DAYS.size():
		var run := {}
		var cleared := false
		var attempts := 0
		while not cleared and attempts < 40:
			attempts += 1
			run = BMCore.create_run(profile, d, 1234 + d * 31 + attempts)
			var t := 0.0
			while run["over"] == null and t < 400:
				if run["pending"] != null:
					var pick: String = run["pending"][0]
					if not BMCore.apply_skill(run, pick):
						ok(false, "applySkill rejected " + pick)
					level_ups += 1
					continue
				BMCore.step(run, 1.0 / 60, kite(run))
				t += 1.0 / 60
			cleared = run["over"] == "clear"
		ok(cleared, "day %s cleared in %d attempt(s), %d kills" % [BMData.DAYS[d]["id"], attempts, run["kills"]])
		if d == 2:
			eq(run["day"]["mode"], "rant", "wednesday is the rant level")
			ok(run["phrasesFired"] >= 50, "rant level fired %d phrase projectiles" % run["phrasesFired"])
			phrase_shots = run["phrasesFired"]
			ok(run["lastPattern"] in ["stream", "spread", "burst"], "pattern " + run["lastPattern"])
		var before: int = profile["level"]
		BMCore.commit_run(profile, run)
		ok(profile["level"] >= before, "level never goes backwards")
	var bare := profile.duplicate(true)
	bare["equipped"] = {"hand": null, "desk": null, "wear": null}
	var b := BMCore.compute_stats(bare)
	var k := BMCore.compute_stats(profile)
	ok(k["hp"] > b["hp"] or k["atk"] > b["atk"] or k["rate"] > b["rate"] or k["spd"] > b["spd"], "equipment changes the numbers")
	ok(profile["level"] >= 5, "reached level %d across a week" % profile["level"])
	ok(level_ups >= 5, "%d level-up choices offered" % level_ups)
	eq(profile["owned"].size(), 5, "five equipment drops")
	eq(profile["party"].size(), 3, "party filled")
	ok(profile["week"] == 1 and profile["day"] == 0, "week rolled over")
	ok(phrase_shots >= 50, "phrase projectiles recorded")


var draws := 0

func _conformance() -> void:
	print("JS <-> GDScript conformance (tests/conformance.json)")
	var f := FileAccess.open("res://tests/conformance.json", FileAccess.READ)
	if f == null:
		ok(false, "tests/conformance.json missing — run: node tests/conformance_gen.cjs")
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var fails0 := failed
	# stats
	var n_stats := 0
	for c in data["stats"]:
		var p: Dictionary = _fix_profile(c["profile"])
		var s := BMCore.compute_stats(p)
		var want: Dictionary = c["stats"]
		var same: bool = int(s["hp"]) == int(want["hp"]) and int(s["spd"]) == int(want["spd"]) \
			and absf(s["atk"] - want["atk"]) < 1e-9 and absf(s["rate"] - want["rate"]) < 1e-9 \
			and int(s["partyDps"]) == int(want["partyDps"]) and _flags_eq(s["flags"], want["flags"])
		if not same:
			ok(false, "stats differ: " + JSON.stringify(s) + " vs " + JSON.stringify(want))
		else:
			n_stats += 1
	ok(n_stats == data["stats"].size(), "computeStats identical on %d/%d profiles" % [n_stats, data["stats"].size()])
	# rant
	var cat := BMCore.rant_catalog()
	var n_rant := 0
	for c in data["rant"]:
		var pat := BMCore.rant_pattern(c["combo"], cat)
		var pw := BMCore.rant_shot_power(c["combo"], cat)
		if pat == c["pattern"] and absf(pw - c["power"]) < 1e-9:
			n_rant += 1
		else:
			ok(false, "rant differs for " + JSON.stringify(c["combo"]) + ": " + pat + " " + str(pw))
	ok(n_rant == data["rant"].size(), "rantPattern/rantShotPower identical on %d loadouts" % n_rant)
	var n_ph := 0
	for c in data["phrases"]:
		if BMPhrases.shot(c["lang"], c["kind"]) == c["text"]:
			n_ph += 1
		else:
			ok(false, "phrase differs %s/%s" % [c["lang"], c["kind"]])
	ok(n_ph == data["phrases"].size(), "phrase text identical on %d cases" % n_ph)
	# runs
	var n_runs := 0
	var n_snaps := 0
	var max_dev := 0.0
	for c in data["runs"]:
		var profile := _fix_profile(c["profile"])
		var run := BMCore.create_run(profile, int(c["day"]), int(c["seed"]))
		run["lang"] = c["lang"]
		draws = 0
		var snaps: Array = c["snaps"]
		var picks: Array = []
		var texts: Array = []
		var step := 0
		var si := 0
		var bad := ""
		var max_steps := 75 * 60
		while run["over"] == null and step < max_steps:
			if run["pending"] != null:
				picks.append(run["pending"].duplicate())
				BMCore.apply_skill(run, run["pending"][0])
				continue
			_step_counted(run)
			step += 1
			if step % 30 == 0:
				if si < snaps.size():
					var d := _snap_diff(run, snaps[si])
					max_dev = maxf(max_dev, d["dev"])
					if d["bad"] != "":
						bad = "step %d: %s" % [step, d["bad"]]
						break
					n_snaps += 1
				si += 1
			if run["day"]["mode"] == "rant" and texts.size() < 40:
				for s in run["shots"]:
					if s["text"] != "" and texts.size() < 40 and (texts.is_empty() or texts[-1] != s["text"]):
						texts.append(s["text"])
		if bad == "":
			if step != int(c["steps"]):
				bad = "ran %d steps, js ran %d" % [step, int(c["steps"])]
			elif JSON.stringify(picks) != JSON.stringify(c["picks"]):
				bad = "skill offers differ"
			elif JSON.stringify(texts) != JSON.stringify(c["texts"]):
				bad = "phrase texts differ"
			elif run["reward"] != c["reward"]:
				bad = "reward differs"
			else:
				var d := _snap_diff(run, c["final"])
				max_dev = maxf(max_dev, d["dev"])
				if d["bad"] != "":
					bad = "final: " + d["bad"]
				else:
					var committed := BMCore.commit_run(run["profile"].duplicate(true), run)
					var want: Dictionary = c["committed"]
					for k in ["level", "xp", "day", "week"]:
						if int(committed[k]) != int(want[k]):
							bad = "committed %s: %s vs %s" % [k, str(committed[k]), str(want[k])]
					for k in ["rant", "owned", "party", "cleared", "skills"]:
						if JSON.stringify(committed[k]) != JSON.stringify(want[k]):
							bad = "committed %s differs" % k
		if bad == "":
			n_runs += 1
		else:
			ok(false, "run seed %d day %d: %s" % [int(c["seed"]), int(c["day"]), bad])
	ok(n_runs == data["runs"].size(), "%d/%d seeded runs identical (%d snapshots; max float deviation %.10f)" % [n_runs, data["runs"].size(), n_snaps, max_dev])
	if failed == fails0:
		print("  CONFORMANCE_OK")


func _step_counted(run: Dictionary) -> void:
	var before: int = run["rng"]
	BMCore.step(run, 1.0 / 60, kite(run))
	# rng draws are counted by replaying the state: each draw advances by 0x6D2B79F5 mod 2^32
	var after: int = run["rng"]
	var diff: int = (after - before) & 0xFFFFFFFF
	# diff = k * 0x6D2B79F5 mod 2^32; k is small, solve by scanning
	var k := 0
	var acc := 0
	while acc != diff and k < 4096:
		acc = (acc + 0x6D2B79F5) & 0xFFFFFFFF
		k += 1
	draws += k


func _snap_diff(run: Dictionary, want: Dictionary) -> Dictionary:
	var dev := 0.0
	var bad := ""
	for k in ["level", "xp", "kills", "shotsFired", "phrasesFired", "foes", "shots", "foeShots", "picks", "draws", "pierce"]:
		var have
		match k:
			"foes": have = run["foes"].size()
			"shots": have = run["shots"].size()
			"foeShots": have = run["foeShots"].size()
			"picks": have = run["picks"].size()
			"draws": have = draws
			"pierce":
				have = 0
				for s in run["shots"]:
					have += int(s["pierce"])
			_: have = run[k]
		if int(have) != int(want[k]):
			return {"dev": dev, "bad": "%s %s vs %s" % [k, str(have), str(want[k])]}
	for k in ["lastPattern", "phase"]:
		if run[k] != want[k]:
			return {"dev": dev, "bad": "%s %s vs %s" % [k, str(run[k]), str(want[k])]}
	if str(run["over"]) != str(want["over"]) and not (run["over"] == null and want["over"] == null):
		return {"dev": dev, "bad": "over %s vs %s" % [str(run["over"]), str(want["over"])]}
	if JSON.stringify(run["rantCombo"]) != JSON.stringify(want["rantCombo"]):
		return {"dev": dev, "bad": "rantCombo differs"}
	if JSON.stringify(run["profile"]["skills"]) != JSON.stringify(want["skills"]):
		return {"dev": dev, "bad": "skills differ"}
	var hp_sum := 0.0
	for f in run["foes"]:
		hp_sum += f["hp"]
	var boss_hp = run["boss"]["hp"] if run["boss"] != null else null
	for pair in [["t", run["t"]], ["px", run["px"]], ["py", run["py"]], ["hp", run["hp"]], ["maxHp", run["maxHp"]], ["foeHpSum", hp_sum], ["bossHp", boss_hp]]:
		var w = want[pair[0]]
		var h = pair[1]
		if (w == null) != (h == null):
			return {"dev": dev, "bad": "%s null mismatch" % pair[0]}
		if w == null:
			continue
		var d: float = absf(float(h) - float(w)) / maxf(1.0, absf(float(w)))
		dev = maxf(dev, d)
		# Continuous state is held to 1e-4 relative, not bit-exact: V8 and glibc round
		# sin/cos/atan2 differently in the last ulp, and one such ulp on a shot's angle
		# flips a razor-edge hit by a frame. Every count above (kills, level, xp, shots,
		# rng draws, pierce, skills, pattern, phase) stays exact.
		if d > 1e-4:
			return {"dev": dev, "bad": "%s %.9f vs %.9f" % [pair[0], float(h), float(w)]}
	return {"dev": dev, "bad": ""}


func _flags_eq(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k) or int(a[k]) != int(b[k]):
			return false
	return true


## JSON gives floats for every number and null where JS had null; the core wants ints.
static func _fix_profile(p: Dictionary) -> Dictionary:
	var out: Dictionary = p.duplicate(true)
	for k in ["week", "day", "level", "xp"]:
		out[k] = int(out[k])
	return out
