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
	_scripts_compile()
	_map()
	_triage()
	_review_conformance()
	_review_node()
	_deploy_and_events()
	_languages()
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


# ==== 2026-09-18: the map and the mixed nodes =====================================================
## The scene scripts are not loaded by this test scene; loading them here compiles them,
## so a parse error in main.gd / map_screen.gd / arena.gd fails the run instead of
## surfacing only in the web build.
func _scripts_compile() -> void:
	print("\n-- scene scripts compile")
	for s in ["main", "map_screen", "arena", "hud", "game", "gate", "sfx"]:
		var scr = load("res://scripts/%s.gd" % s)
		ok(scr != null and scr.can_instantiate(), "%s.gd compiles" % s)


func _map() -> void:
	print("\n-- the map: graph invariants and unlock logic")
	var inv := BMMap.invariants()
	for k in inv:
		ok(inv[k], "invariant %s" % k)
	var p := BMCore.new_profile()
	BMMap.ensure(p)
	eq(BMMap.at(p), "lobby", "the week starts in the lobby")
	eq(BMMap.path(p, "lobby", "standup"), ["lobby", "standup"], "lobby -> standup is one edge")
	eq(BMMap.path(p, "lobby", "inbox"), [], "the inbox is locked until the standup falls")
	eq(BMMap.path(p, "lobby", "breakroom"), ["lobby", "breakroom"], "the break room is always open")
	ok(BMMap.clear(p, "standup"), "clearing the standup the first time returns true")
	ok(not BMMap.clear(p, "standup"), "clearing it again returns false (but counts the run)")
	eq(int(BMMap.ensure(p)["runs"]["standup"]), 2, "two runs counted")
	eq(int(p["credits"]), 6, "three credits per cleared run")
	eq(BMMap.state(p, "inbox"), "open", "inbox opens after the standup")
	eq(BMMap.state(p, "allhands"), "open", "all-hands opens after the standup (the branch)")
	eq(BMMap.state(p, "review"), "locked", "review needs inbox OR all-hands")
	eq(BMMap.path(p, "lobby", "allhands"), ["lobby", "standup", "allhands"], "walk through the standup to the all-hands")
	BMMap.clear(p, "allhands")
	eq(BMMap.state(p, "review"), "open", "review opens from the all-hands alone (route around triage)")
	eq(BMMap.state(p, "deploy"), "locked", "deploy still locked")
	BMMap.clear(p, "review")
	eq(BMMap.state(p, "deploy"), "open", "deploy opens after the review")
	eq(BMMap.path(p, "allhands", "deploy"), ["allhands", "review", "deploy"], "back-and-forth: a path from a cleared node")
	var down := BMMap.path(p, "deploy", "standup")
	ok(down.size() == 4 and down[0] == "deploy" and down[3] == "standup" and down[2] in ["allhands", "inbox"], "and back down the building, through either branch: %s" % [down])
	# persistence: the map slice survives a JSON round trip and resets with the week
	var back = JSON.parse_string(JSON.stringify(p))
	eq(back["map"]["cleared"], ["standup", "allhands", "review"], "map cleared set round-trips through JSON")
	back["week"] = 1
	BMMap.ensure(back)
	eq(back["map"]["cleared"], [], "a new week is a fresh map")
	eq(back["map"]["at"], "lobby", "and starts in the lobby")
	# commit through the ported progression: the inbox node grants Tuesday's row
	var q := BMCore.new_profile()
	BMMap.clear(q, "standup")
	var r := BMMap.commit_thinking(q, "inbox", 30, true)
	ok(q["owned"].has("headphones"), "clearing the inbox drops Tuesday's headphones (through commit_run)")
	ok(q["party"].has("pm"), "and Morgan joins after Tuesday")
	ok(q["cleared"].has("tue"), "BMCore's cleared days gains tue")
	ok(int(q["level"]) >= 2 and (r["pending"] == null or r["pending"].size() >= 1), "30 xp levels up; a pick is pending or the pool was picked")
	var lost := BMMap.commit_thinking(q, "review", 5, false)
	ok(not q["owned"].has("chair") and not BMMap.is_cleared(q, "review"), "a lost review drops nothing and clears nothing")
	eq(lost["over"], "lost", "the pseudo-run says lost")
	# the week rolls on Friday regardless of the order the other days were cleared
	var w := BMCore.new_profile()
	for id in ["standup", "allhands", "review"]:
		BMMap.clear(w, id)
	var fri := BMCore.create_run(w, 4, 1)
	fri["over"] = "clear"
	fri["reward"] = "badge"
	BMMap.clear(w, "deploy")
	BMCore.commit_run(w, fri)
	ok(int(w["week"]) == 1 and w.get("weekend", false), "Friday rolls the week with two days skipped")
	BMMap.ensure(w)
	eq(w["map"]["cleared"], [], "and the map resets for week 2")
	# the XP-only grant (the corridor)
	var e := BMCore.new_profile()
	var er := BMMap.grant_xp(e, 25, 3)
	ok(int(e["level"]) == 2 and er["pending"] != null and er["pending"].size() == 3, "grant_xp levels the profile and offers three skills")
	ok(BMCore.apply_skill(er, er["pending"][0]), "the offered skill applies")
	eq(e["skills"].size(), 1, "and lands in the profile")


func _triage() -> void:
	print("\n-- the inbox: triage rules")
	var p := BMCore.new_profile()
	p["party"] = ["intern"]
	var t := BMTriage.new_triage(p, 42)
	eq(t["hand"].size(), 5, "a hand of five")
	eq(t["deck"].size(), 7, "12 in the desk, 7 still in the pile")
	eq(t["actions"], 3, "three actions a turn")
	var t2 := BMTriage.new_triage(p, 42)
	eq(JSON.stringify(t2["hand"]), JSON.stringify(t["hand"]), "the same seed deals the same hand")
	var t3 := BMTriage.new_triage(p, 43)
	ok(JSON.stringify(t3["hand"]) != JSON.stringify(t["hand"]) or JSON.stringify(t3["deck"]) != JSON.stringify(t["deck"]), "a different seed deals differently")
	# reply costs what it costs
	var m: Dictionary = t["hand"][0]
	var cost: int = int(m["cost"])
	eq(BMTriage.act(t, "reply", int(m["uid"])), "", "reply to the first message")
	eq(t["actions"], 3 - cost, "reply cost %d action(s)" % cost)
	eq(t["hand"].size(), 4, "the hand is not refilled mid-turn")
	eq(BMTriage.act(t, "reply", 9999), "no_such_message", "replying to a message not in the hand is refused")
	# spend the rest, then a refusal
	while t["actions"] > 0 and t["hand"].size():
		var cheapest: Dictionary = t["hand"][0]
		for h in t["hand"]:
			if int(h["cost"]) < int(cheapest["cost"]):
				cheapest = h
		if int(cheapest["cost"]) > int(t["actions"]):
			eq(BMTriage.act(t, "reply", int(cheapest["uid"])), "not_enough_actions", "a reply dearer than the actions left is refused")
			break
		BMTriage.act(t, "reply", int(cheapest["uid"]))
	# snooze: free, once a turn
	if t["hand"].size() >= 2:
		var a0: int = t["actions"]
		var s1: Dictionary = t["hand"][0]
		eq(BMTriage.act(t, "snooze", int(s1["uid"])), "", "snooze is allowed")
		eq(t["actions"], a0, "and costs nothing")
		ok(t["deck"].size() > 0 and int(t["deck"][t["deck"].size() - 1]["uid"]) == int(s1["uid"]), "the snoozed message went to the bottom of the pile")
		eq(BMTriage.act(t, "snooze", int(t["hand"][0]["uid"])), "already_snoozed", "a second snooze in the turn is refused")
	# end of turn: refill, actions back, urgency down
	var stress0: int = t["stress"]
	BMTriage.end_turn(t)
	eq(t["actions"], 3, "actions reset at the end of the turn")
	eq(t["turn"], 2, "turn 2")
	eq(t["hand"].size(), mini(5, t["hand"].size() + t["deck"].size()) if t["deck"].size() == 0 else 5, "hand refilled to five")
	ok(t["stress"] >= stress0, "stress never falls")
	# escalation: a pager (urgency 1) left in the hand hits stress on the next end of turn
	var u := BMTriage.new_triage(p, 7)
	u["hand"] = [BMTriage._msg(u, "pager")]
	u["deck"] = [BMTriage._msg(u, "ping")]
	BMTriage.end_turn(u)
	eq(u["stress"], 16, "an ignored pager escalates for 16 stress")
	eq(int(u["hand"][0]["cost"]), 3, "its cost is capped at 3")
	eq(int(u["hand"][0]["esc"]), 1, "and it is marked escalated")
	# archive: cheap, but a sticky message comes back angrier
	var v := BMTriage.new_triage(p, 7)
	v["hand"] = [BMTriage._msg(v, "metric")]
	v["deck"] = []
	var uid: int = int(v["hand"][0]["uid"])
	eq(BMTriage.act(v, "archive", uid), "", "archive a metric")
	eq(v["actions"], 2, "archive costs one action")
	eq(v["deck"].size(), 1, "the metric came back to the pile")
	eq(int(v["deck"][0]["cost"]), 3, "with cost +1")
	ok(v["over"] == null, "not over: it is still in the pile")
	# delegate: two actions, one colleague each
	var d := BMTriage.new_triage(p, 7)
	d["hand"] = [BMTriage._msg(d, "pager"), BMTriage._msg(d, "pager")]
	d["deck"] = []
	eq(BMTriage.act(d, "delegate", int(d["hand"][0]["uid"])), "", "Riley takes a pager")
	eq(d["actions"], 1, "delegate costs two actions")
	eq(BMTriage.act(d, "delegate", int(d["hand"][0]["uid"])), "nobody_to_delegate_to", "and there is nobody left to hand the second one to")
	# win: clear everything
	var w := BMTriage.new_triage(p, 7)
	w["hand"] = [BMTriage._msg(w, "ping")]
	w["deck"] = []
	BMTriage.act(w, "reply", int(w["hand"][0]["uid"]))
	eq(w["over"], "clear", "an empty desk is a clear")
	eq(w["xp"], 2, "the ping paid 2 xp")
	# lose: the clock
	var l := BMTriage.new_triage(p, 7)
	l["turn"] = l["turns"]
	BMTriage.end_turn(l)
	eq(l["over"], "lost", "the clock running out with messages left is a loss")
	# lose: stress
	var s := BMTriage.new_triage(p, 7)
	s["hand"] = [BMTriage._msg(s, "pager"), BMTriage._msg(s, "pager")]
	s["deck"] = []
	s["stress"] = 90
	BMTriage.end_turn(s)
	eq(s["over"], "lost", "stress at 100 is a loss")
	# the greedy autoplayer clears a week-1 desk more often than not (a smoke, not a balance claim)
	var wins := 0
	for seed in 20:
		var g := BMTriage.new_triage(p, 100 + seed)
		var guard := 0
		while g["over"] == null and guard < 40:
			BMTriage.autoplay_turn(g)
			guard += 1
		if g["over"] == "clear":
			wins += 1
	ok(wins >= 10, "the greedy autoplayer clears %d/20 week-1 desks" % wins)


func _review_conformance() -> void:
	print("\n-- the review engine: GDScript port vs the Python advance() (tests/persuasion_conformance.json)")
	var f := FileAccess.open("res://tests/persuasion_conformance.json", FileAccess.READ)
	ok(f != null, "fixture present (python3 tests/persuasion_conformance_gen.py)")
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	var n_cases := 0
	var n_calls := 0
	var bad := 0
	for c in data["cases"]:
		var state := {}
		var this_bad := ""
		for i in c["turns"].size():
			var got := BMPersuasion.advance(state, c["turns"][i], c["scenario"], c["difficulty"])
			var want: Dictionary = c["expected"][i]
			n_calls += 1
			if int(got["turns"]) != int(want["turns"]):
				this_bad = "turns %d vs %d" % [int(got["turns"]), int(want["turns"])]
				break
			for k in ["phase", "evidence", "harms", "expert", "eligible", "cg"]:
				if JSON.stringify(got[k]) != JSON.stringify(want[k]):
					this_bad = "%s: %s vs %s (turn %d, %s)" % [k, JSON.stringify(got[k]), JSON.stringify(want[k]), i, JSON.stringify(c["turns"][i])]
					break
			if this_bad == "" and absf(float(got["momentum"]) - float(want["momentum"])) > 1e-9:
				this_bad = "momentum %s vs %s" % [got["momentum"], want["momentum"]]
			if this_bad == "":
				if int(got["last_move"]["clauses"]) != int(want["last_move"]["clauses"]):
					this_bad = "clauses %d vs %d (%s)" % [int(got["last_move"]["clauses"]), int(want["last_move"]["clauses"]), JSON.stringify(c["turns"][i])]
				for k in ["signals", "harms"]:
					if JSON.stringify(got["last_move"][k]) != JSON.stringify(want["last_move"][k]):
						this_bad = "last_move.%s: %s vs %s (%s)" % [k, JSON.stringify(got["last_move"][k]), JSON.stringify(want["last_move"][k]), JSON.stringify(c["turns"][i])]
			if this_bad != "":
				break
			state = got
		if this_bad != "":
			bad += 1
			if bad <= 8:
				ok(false, "%s/%s: %s" % [c["scenario"], c["difficulty"], this_bad])
		else:
			n_cases += 1
	ok(bad == 0, "%d/%d conversations, %d advance() calls identical to the Python engine" % [n_cases, data["cases"].size(), n_calls])
	if bad == 0:
		print("  REVIEW_CONFORMANCE_OK")
	# the review's faces are honest: declared signals == decompose(line) (cards.py's rule)
	var dishonest := 0
	for c in BMReview.CARDS:
		var d := BMPersuasion.decompose(c["line"], "raise")
		if JSON.stringify(d["signals"]) != JSON.stringify(c["signals"]) or JSON.stringify(d["harms"]) != JSON.stringify(c["harms"]):
			dishonest += 1
			ok(false, "card %s claims %s/%s, the engine reads %s/%s" % [c["id"], c["signals"], c["harms"], d["signals"], d["harms"]])
	ok(dishonest == 0, "every review card face matches what the engine reads from its line")
	ok(data["review_lines"].size() == BMReview.CARDS.size(), "the fixture was generated from this card set (%d lines)" % BMReview.CARDS.size())


func _review_node() -> void:
	print("\n-- the review node: hand, sequence, coercion")
	var r := BMReview.new_review(0, 11)
	eq(r["scenario"], "raise", "week 1 is the raise conversation")
	eq(r["difficulty"], "silver", "at silver")
	eq(r["hand"].size(), 4, "a hand of four")
	eq(r["deck"].size(), BMReview.CARDS.size() - 4, "the rest in the deck")
	eq(r["maxTurns"], 15, "fifteen turns")
	# the winning sequence: evidence + a direct ask + precision (silver needs one support)
	var s := BMReview.new_review(0, 11)
	s["hand"] = ["ev_01", "dr_01", "pr_01", "rs_01"]
	s["deck"] = ["ac_01"]
	ok(BMReview.play(s, "ev_01"), "say the evidence")
	eq(s["state"]["phase"], "engaged", "half the path: engaged")
	eq(s["hand"].size(), 4, "drew back to four")
	ok(BMReview.play(s, "dr_01"), "then the ask")
	eq(s["state"]["phase"], "wavering", "path complete, no support at silver: wavering, not a win")
	ok(s["over"] == null, "not over yet")
	ok(BMReview.play(s, "pr_01"), "then precision")
	eq(s["state"]["phase"], "breakthrough", "support arrives: breakthrough")
	eq(s["over"], "clear", "she signed")
	eq(s["reply"], "breakthrough", "the breakthrough reply")
	ok(BMReview.xp_for(s) > 0, "xp for the clear")
	# order matters less than the set for this engine, but coercion is permanent
	var x := BMReview.new_review(0, 11)
	x["hand"] = ["x_threat", "ev_01", "dr_01", "pr_01"]
	x["deck"] = []
	BMReview.play(x, "x_threat")
	eq(x["reply"], "coerced", "the threat gets the coerced reply")
	BMReview.play(x, "ev_01")
	BMReview.play(x, "dr_01")
	BMReview.play(x, "pr_01")
	eq(x["state"]["eligible"], false, "the full path after a threat never becomes eligible")
	eq(x["over"], "lost", "and the hand running dry is a loss")
	# the clock
	var c := BMReview.new_review(1, 5)
	eq(c["scenario"], "investor", "week 2 points the engine at the investor row")
	eq(c["maxTurns"], 10, "gold: ten turns")
	var guard := 0
	while c["over"] == null and guard < 40:
		var first: String = c["hand"][0]
		for h in c["hand"]:
			if BMReview.card(h)["rarity"] != "coercion" and BMReview.card(h)["signals"] == ["respect"]:
				first = h
		if BMReview.card(first)["rarity"] == "coercion":
			first = c["hand"][1]
		BMReview.play(c, first)
		guard += 1
	ok(c["over"] != null and c["turn"] <= 10, "the review always ends inside its turn budget (ended %s at turn %d)" % [c["over"], c["turn"]])
	# the cg field is carried but never used by the day game (the twin reads it)
	var g := BMReview.new_review(0, 3)
	g["hand"] = ["ev_01"]
	BMReview.play(g, "ev_01")
	eq(g["lastCg"], ["cg1_raise"], "the engine's cg keys come through untouched")


func _deploy_and_events() -> void:
	print("\n-- the deploy: placement and auras; the corridor")
	var p := BMCore.new_profile()
	p["party"] = ["intern", "pm"]
	p["owned"] = ["stapler", "headphones", "chair"]
	var pl := BMDeploy.new_placement()
	eq(BMDeploy.what_can_go(p).size(), 5, "two colleagues and three gear can be placed")
	eq(BMDeploy.place(pl, p, 0, "party", "intern"), "", "Riley on tile 0")
	eq(BMDeploy.place(pl, p, 0, "party", "pm"), "", "Morgan takes tile 0 (swap)")
	eq(BMDeploy.place(pl, p, 1, "party", "intern"), "", "Riley moves to tile 1")
	eq(pl["tiles"].size(), 2, "two tiles used")
	eq(BMDeploy.place(pl, p, 2, "gear", "stapler"), "", "stapler on 2")
	eq(BMDeploy.place(pl, p, 3, "gear", "headphones"), "", "headphones on 3")
	eq(BMDeploy.place(pl, p, 4, "gear", "chair"), "too_much_gear", "a third gear is refused")
	eq(pl["tiles"].size(), 4, "and the refusal left the four placements alone")
	eq(BMDeploy.place(pl, p, 4, "gear", "badge"), "not_yours", "gear you do not own is refused")
	eq(BMDeploy.place(pl, p, 9, "party", "pm"), "no_such_tile", "no tile 9")
	eq(BMDeploy.place(pl, p, 5, "party", "hr"), "not_yours", "Pat is not in the party yet")
	# auras act on the run after a core step, and never on a run that is over
	var run := BMCore.create_run(p, 4, 1)
	run["stats"]["partyDps"] = 0
	run["foes"].append({"x": BMDeploy.TILES[1].x + 10, "y": BMDeploy.TILES[1].y, "r": 9.0, "hp": 5.0, "spd": 50.0, "dmg": 1.0, "xp": 2, "kind": "ping", "hit": 0.0})
	var kills0: int = run["kills"]
	BMDeploy.apply(run, pl, 1.0)
	ok(run["kills"] == kills0 + 1, "Riley's turret killed the ping on her tile (dps %.0f/s)" % (6 * BMDeploy.TURRET_MUL))
	run["px"] = BMDeploy.TILES[2].x
	run["py"] = BMDeploy.TILES[2].y
	run["hp"] = 10.0
	BMDeploy.place(pl, p, 2, "gear", "chair")
	BMDeploy.apply(run, pl, 2.0)
	near(run["hp"], 16.0, "the chair heals 3/s when you stand on it")
	run["hp"] = run["maxHp"]
	BMDeploy.apply(run, pl, 2.0)
	near(run["hp"], run["maxHp"], "and never past max")
	run["foes"].append({"x": BMDeploy.TILES[3].x, "y": BMDeploy.TILES[3].y, "r": 9.0, "hp": 100.0, "spd": 100.0, "dmg": 1.0, "xp": 2, "kind": "ping", "hit": 0.0})
	var fx0: float = run["foes"][0]["x"]
	BMDeploy.apply(run, pl, 0.1)
	ok(run["foes"][0]["x"] != fx0, "the headphones push the foe back (a slow)")
	run["over"] = "clear"
	run["hp"] = 5.0
	run["px"] = BMDeploy.TILES[2].x
	BMDeploy.apply(run, pl, 1.0)
	near(run["hp"], 5.0, "nothing applies once the run is over")
	# events
	var e := BMCore.new_profile()
	BMMap.clear(e, "standup")
	var ev := BMEvents.pick(e, "corridor1")
	ok(ev.has("id") and ev.has("a") and ev.has("b"), "the corridor picks an event with two choices: %s" % ev["id"])
	eq(BMEvents.pick(e, "corridor1")["id"], ev["id"], "the same corridor shows the same event within the week")
	var c0: int = e["credits"]
	var out := BMEvents.choose(e, "corridor1", "a")
	ok(BMMap.is_cleared(e, "corridor1"), "choosing clears the corridor")
	var fx: Dictionary = out["fx"]
	if fx.has("credits"):
		eq(int(e["credits"]), maxi(0, c0 + int(fx["credits"])) + 3, "credits applied (+3 for the clear)")
	if fx.has("hpNext"):
		near(float(e["map"]["hpNext"]), float(fx["hpNext"]), "the HP modifier waits for the next run")
		near(BMEvents.take_hp_mod(e), 1.0 + float(fx["hpNext"]), "and is consumed once")
		near(BMEvents.take_hp_mod(e), 1.0, "gone after that")
	if fx.has("xp"):
		ok(int(e["xp"]) == int(fx["xp"]) or int(e["level"]) > 1, "xp applied")
	var e2 := BMCore.new_profile()
	e2["week"] = 1
	BMMap.clear(e2, "standup")
	ok(BMEvents.pick(e2, "corridor1")["id"] != ev["id"] or BMEvents.pick(e2, "corridor2")["id"] != BMEvents.pick(e, "corridor2")["id"], "another week or corridor can show another event")


## The languages, and the two ways a translation lies on disk.
##
## Both of these were real on 2026-09-21 and neither produced an error of any kind:
##
##   * a language offered in LANGS with no table behind it falls through to EN, so the
##     game "supports" it and shows English -- STANDARD.md item 7, the Floor 13 failure;
##   * a language whose table is complete but whose FONT has none of its glyphs draws the
##     whole language as blank boxes. The shipped CJK face was a 342-character subset cut
##     for the Chinese strings and contained no kana at all, while every string check
##     passed. That is the studio memory `verification-that-lies`, so the font is checked
##     here against the actual strings rather than assumed.
##
## Both checks were confirmed to FAIL before they were trusted: dropping one key from JA
## reports the key, and pointing BMStrings.CJK_FONT at the retired subset reports the kana.
func _languages() -> void:
	# Every code the chip can cycle to must have a table behind it, or the game "supports"
	# a language by falling through to English.
	var tables := {"en": BMStrings.EN, "zh": BMStrings.ZH, "ja": BMStrings.JA}
	for code in Game.LANGS:
		ok(tables.has(code) and (tables[code] as Dictionary).size() > 0,
			"a table exists for every language in LANGS: " + str(code))
	var missing: Array = []
	for k in BMStrings.EN:
		if not BMStrings.JA.has(k):
			missing.append(k)
	ok(missing.is_empty(), "every EN key is translated in JA (missing: %s)" % [missing.slice(0, 8)])
	eq(BMStrings.JA.size(), BMStrings.EN.size(), "JA has exactly the EN key set, no strays")

	# Placeholders are substituted by literal match, so a translated brace prints raw.
	var bad_ph: Array = []
	for k in BMStrings.EN:
		var want := 0
		for part in str(BMStrings.EN[k]).split("{"):
			want += 1
		var got := 0
		for part in str(BMStrings.JA.get(k, "")).split("{"):
			got += 1
		if want != got:
			bad_ph.append(k)
	ok(bad_ph.is_empty(), "JA keeps every {placeholder} verbatim (bad: %s)" % [bad_ph.slice(0, 8)])

	# The font actually has the glyphs. A FontFile reports per-character coverage, which is
	# the only way to tell a real subset from one that silently dropped a script.
	for code in ["zh", "ja"]:
		var f: Font = load(BMStrings.font_for(code))
		ok(f != null, "the %s CJK subset loads" % code)
		if f == null:
			continue
		var bank: Dictionary = BMStrings.ZH if code == "zh" else BMStrings.JA
		var absent := ""
		for k in bank:
			for ch in str(bank[k]):
				if ch == "\n" or ch == " ":
					continue
				if not f.has_char(ch.unicode_at(0)) and not absent.contains(ch):
					absent += ch
			if absent.length() > 12:
				break
		ok(absent == "", "the %s font draws every character the %s table uses (missing: %s)"
			% [code, code, absent])
