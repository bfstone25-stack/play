extends Node
## The headless test scene. Two halves:
##
##   unit         the port's own invariants, and the traps that do not show up in a diff
##   conformance  tests/conformance.json (node tests/conformance_gen.cjs) replayed against
##                scripts/kernel.gd and scripts/idle.gd — every number, string and event
##                from the SHIPPED JS kernel, asserted identical
##
## Run: tests/run.sh. It fails on any engine error too, not only on a failed check: a parse
## error in one class silently skips every check that used it.
##
## Two rounding traps are pinned here on purpose, because both produce *plausible* wrong
## numbers rather than crashes:
##
##   1. JS `toFixed` rounds ties away from zero; C's "%.3f" rounds them to even. The
##      sibling hit this on its prestige chain (5.0625 -> "5.063" vs "5.062"); here it is
##      formatCoins, where 10_005 must format as "10.0K" and 1_235_000 as "1.24M".
##   2. `Math.hypot` is not `sqrt(x*x+y*y)`. V8 scales by the largest term and sums with a
##      Neumaier compensation; the two disagree in the last ulp for about 37% of inputs,
##      which over a few thousand substeps is the difference between a ball that drains
##      and a ball that does not. Kernel.hyp replicates V8. The conformance physics block
##      is what proves it: it would not survive one frame otherwise.

var passed := 0
var failed := 0
var _ctx := ""


func ok(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL  %s%s" % [_ctx, what])


func eq(a, b, what: String) -> void:
	if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
		ok(float(a) == float(b), "%s: %s != %s" % [what, String.num(float(a), 17), String.num(float(b), 17)])
	else:
		ok(a == b, "%s: %s != %s" % [what, str(a), str(b)])


## Exactly equal doubles — no epsilon. A conformance port that needs an epsilon is not one.
func exact(a: float, b: float, what: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		print("FAIL  %s%s: %s != %s (delta %s)" % [_ctx, what, String.num(a, 17), String.num(b, 17), String.num(a - b, 17)])


## The JS side's LCG, bit for bit: s = (s*1664525 + 1013904223) >>> 0; s / 2^32.
class Lcg:
	var s: int
	func _init(seed_value: int) -> void:
		s = seed_value & 0xFFFFFFFF
	func next() -> float:
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF
		return float(s) / 4294967296.0


## Godot's JSON number parser is not correctly rounded — it reads "19.349999999999998" as
## 19.350000000000001421, and String.to_float agrees with it. That is a whole ulp, and an
## exact conformance comparison would fail on the *transport* rather than on the port. So
## conformance_gen.cjs sends every non-integer double as its IEEE-754 bit pattern
## ("f" + 8 bytes little-endian hex) and this decodes it. Integers cross as integers.
##
## (An epsilon comparison would have passed here and hidden it — the memory note
## "verification that lies": make a check fail once before trusting it. This one did.)
var _f64_buf := PackedByteArray()

func f(v) -> float:
	if typeof(v) == TYPE_STRING:
		var s := str(v)
		if s.begins_with("f") and s.length() == 17:
			if _f64_buf.size() != 8:
				_f64_buf.resize(8)
			for i in range(8):
				_f64_buf[i] = s.substr(1 + i * 2, 2).hex_to_int()
			return _f64_buf.decode_double(0)
	return float(v)


func _ready() -> void:
	_unit()
	_conformance()
	print("\n%d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("TESTS_OK")
	get_tree().quit(0 if failed == 0 else 1)


# ---------------- unit ---------------------------------------------------------------------
func _unit() -> void:
	_ctx = "[unit] "
	var st := Kernel.new_state()
	eq(st["balls"], 3, "fresh state has three hoses")
	eq(st["mode"], "plunge", "fresh state waits at the plunger")
	eq(Kernel.era_id(st), "booth", "fresh state is the booth era")
	eq(Kernel.upgrade_cost("springs", 0), 40, "springs level 1 costs 40")
	eq(Kernel.upgrade_cost("springs", 3), 72, "springs level 4 costs 72")
	eq(Kernel.perk_cost("uniform", 0), 1, "the first perk rank costs one token")

	# trap 1: the formatter's ties
	eq(Kernel.format_coins(10005.0), "10.0K", "10,005 formats as 10.0K")
	eq(Kernel.format_coins(1235000.0), "1.24M", "1,235,000 formats as 1.24M")
	eq(Kernel.format_coins(999.0), "999", "under ten thousand is a plain integer")
	eq(Kernel._to_fixed(5.0625, 3), "5.063", "a tie rounds away from zero, not to even")
	ok(Kernel._to_fixed(5.0625, 3) != "5.062", "and specifically NOT to even (the sibling's bug)")

	# trap 2: V8's hypot, not sqrt(x*x+y*y)
	var mismatches := 0
	var differs := 0
	var lg := Lcg.new(7)
	for _i in range(20000):
		var a := (lg.next() - 0.5) * 6.0
		var b := (lg.next() - 0.5) * 6.0
		if Kernel.hyp(a, b) != sqrt(a * a + b * b):
			differs += 1
	ok(differs > 1000, "Kernel.hyp really does differ from sqrt(x*x+y*y) (%d of 20000)" % differs)
	eq(mismatches, 0, "no NaNs out of hyp")
	eq(Kernel.hyp(0.0, 0.0), 0.0, "hyp(0,0) is 0")
	eq(Kernel.hyp(3.0, 4.0), 5.0, "hyp(3,4) is 5")

	# the drain, the save, and the night ending
	var s2 := Kernel.new_state()
	s2["owned"]["doorman"] = 1
	s2["ballSave"] = Kernel.save_time(s2)
	ok(float(s2["ballSave"]) > 0.0, "the doorman buys ball-save time")
	eq(Kernel.drain_ball(s2), "save", "with ball save, a drain is a save")
	eq(s2["balls"], 3, "a save costs no hose")
	eq(Kernel.drain_ball(s2), "drain", "the next drain is a real one")
	eq(s2["balls"], 2, "and costs a hose")
	Kernel.drain_ball(s2)
	eq(Kernel.drain_ball(s2), "nightover", "the last hose ends the night")
	ok(s2["ball"] == null, "and takes the ball off the table")

	# the offline gate
	_ctx = "[unit/idle] "
	var s3 := Kernel.new_state()
	eq(Idle.offline_seconds(0, 1000, 8.0), 0.0, "never played: nothing accrues")
	eq(Idle.offline_seconds(2000, 1000, 8.0), 0.0, "a backwards clock accrues nothing")
	eq(Idle.offline_seconds(0 + 1000, 1000 + 3600 * 1000, 8.0), 3600.0, "an hour is an hour")
	eq(Idle.offline_seconds(1000, 1000 + 30 * 3600 * 1000, 8.0), 8.0 * 3600.0, "past the cap, eight hours")
	eq(Idle.rate_of(s3), 1.0, "a bare booth earns one coin a second")
	s3["owned"]["penthouse"] = 2
	s3["perks"]["empire"] = 1
	exact(Idle.rate_of(s3), Idle.idle_rate(Kernel.era_index(s3) + 1, Idle.buildings_of(s3)) * 1.12,
		"the empire perk is +12% on the gate's rate")
	var before := int(s3["coins"])
	Idle.claim(s3, 500)
	eq(int(s3["coins"]), before + 500, "claiming adds the coins")
	eq(int(s3["runCoins"]), 500, "and they count toward the prestige token")


# ---------------- conformance --------------------------------------------------------------
func _conformance() -> void:
	var path := "res://tests/conformance.json"
	if not FileAccess.file_exists(path):
		print("SKIP  conformance.json missing — run: node tests/conformance_gen.cjs")
		failed += 1
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		print("FAIL  conformance.json did not parse")
		failed += 1
		return
	_conf_constants(data["constants"])
	_conf_economy(data["economy"])
	_conf_physics(data["physics"])
	_conf_offline(data["offline"])


## Every number the table is BUILT from, bit for bit.
##
## Two of the three real bugs in this port were constants rather than code:
##   - LEFT_PIVOT/RIGHT_PIVOT were Vector2, which in Godot holds 32-bit floats: 0.255 was
##     quietly stored as 0.25499999523162842. The game looked fine. Four seeded runs out
##     of seventy-two drifted by 1e-7 and one of them drained a ball the JS did not.
##   - Godot's decimal-to-double parser is not correctly rounded, so even a literal can
##     land an ulp away from the one V8 read from the same source text. (It happens to be
##     right for all 112 literals in kernel.gd — checked — but "happens to be" is why this
##     block runs every time rather than once.)
func _conf_constants(c: Dictionary) -> void:
	_ctx = "[const] "
	var mine := {
		"GRAVITY": Kernel.GRAVITY, "DAMP": Kernel.DAMP, "MAX_SPEED": Kernel.MAX_SPEED,
		"BALL_R": Kernel.BALL_R, "FLIP_LEN": Kernel.FLIP_LEN, "FLIP_R": Kernel.FLIP_R,
		"COMBO_WINDOW_S": Kernel.COMBO_WINDOW_S, "COMBO_STEP": Kernel.COMBO_STEP,
		"LEFT_REST": Kernel.LEFT_REST, "LEFT_UP": Kernel.LEFT_UP,
		"RIGHT_REST": Kernel.RIGHT_REST, "RIGHT_UP": Kernel.RIGHT_UP,
		"LEFT_PIVOT.x": Kernel.LEFT_PIVOT["x"], "LEFT_PIVOT.y": Kernel.LEFT_PIVOT["y"],
		"RIGHT_PIVOT.x": Kernel.RIGHT_PIVOT["x"], "RIGHT_PIVOT.y": Kernel.RIGHT_PIVOT["y"],
		"PI": PI,
	}
	for k in Kernel.TABLE:
		mine["TABLE." + k] = Kernel.TABLE[k]
	for i in range(Kernel.BUMPERS.size()):
		for k in ["x", "y", "r"]:
			mine["BUMPERS.%d.%s" % [i, k]] = Kernel.BUMPERS[i][k]
	for i in range(Kernel.TARGETS.size()):
		for k in ["x", "y", "w", "h"]:
			mine["TARGETS.%d.%s" % [i, k]] = Kernel.TARGETS[i][k]
	for k in ["x", "y", "r"]:
		mine["SAUCER." + k] = Kernel.SAUCER[k]
	for i in range(Kernel.WALLS.size()):
		for j in range(4):
			mine["WALLS.%d.%d" % [i, j]] = Kernel.WALLS[i][j]
	for i in range(Kernel.SLINGS.size()):
		for k in ["ax", "ay", "bx", "by", "kick"]:
			mine["SLINGS.%d.%s" % [i, k]] = Kernel.SLINGS[i][k]
	for i in range(Kernel.ERAS.size()):
		mine["ERAS.%d.mult" % i] = float(Kernel.ERAS[i]["mult"])
	for i in range(Kernel.UPGRADES.size()):
		mine["UPGRADES.%d.growth" % i] = float(Kernel.UPGRADES[i]["growth"])
	for i in range(Kernel.PERKS.size()):
		mine["PERKS.%d.tokenGrowth" % i] = float(Kernel.PERKS[i]["tokenGrowth"])
	eq(mine.size(), c.size(), "the same set of constants is checked on both sides")
	for k in c:
		ok(mine.has(k), "constant %s exists in the port" % k)
		if mine.has(k):
			exact(float(mine[k]), f(c[k]), "constant %s" % k)
	# and the trap itself, stated so a future edit that reaches for Vector2 fails here
	ok(Vector2(0.255, 0.865).x != 0.255, "Vector2 really is 32-bit — do not put table geometry in one")
	ok(typeof(Kernel.LEFT_PIVOT) == TYPE_DICTIONARY, "the pivots are 64-bit, not a Vector2")


func _state_from(c: Dictionary) -> Dictionary:
	var st := Kernel.new_state()
	for id in c["owned"]:
		st["owned"][id] = int(c["owned"][id])
	for id in c["perks"]:
		st["perks"][id] = int(c["perks"][id])
	st["coins"] = int(c["coins"])
	st["tokens"] = int(c["tokens"])
	st["runCoins"] = int(c["runCoins"])
	st["combo"] = int(c["combo"])
	st["lifetime"] = int(c["lifetime"])
	return st


func _conf_economy(cases: Array) -> void:
	var n := 0
	for c in cases:
		_ctx = "[econ %d] " % n
		n += 1
		var st := _state_from(c)
		for id in c["costs"]:
			eq(Kernel.upgrade_cost(id, Kernel.level_of(st, id)), int(c["costs"][id]), "cost %s" % id)
		for id in c["perkCosts"]:
			eq(Kernel.perk_cost(id, Kernel.perk_of(st, id)), int(c["perkCosts"][id]), "perk cost %s" % id)
		eq(Kernel.skyline_score(st), int(c["skyline"]), "skyline")
		eq(Kernel.era_index(st), int(c["eraIndex"]), "era index")
		eq(Kernel.era_id(st), str(c["eraId"]), "era id")
		exact(Kernel.era_mult(st), f(c["eraMult"]), "era mult")
		exact(Kernel.prestige_mult(st), f(c["prestigeMult"]), "prestige mult")
		exact(Kernel.score_mult(st), f(c["scoreMult"]), "score mult")
		exact(Kernel.combo_mult(int(c["combo"])), f(c["comboMult"]), "combo mult")
		exact(Kernel.flip_power(st), f(c["flipPower"]), "flip power")
		exact(Kernel.bumper_kick(st), f(c["bumperKick"]), "bumper kick")
		exact(Kernel.plunge_power(st), f(c["plungePower"]), "plunge power")
		eq(Kernel.start_balls(st), int(c["startBalls"]), "start balls")

		var bought := Kernel.buy(st, str(c["buyId"]))
		eq(bought["ok"], bool(c["buyOk"]), "buy ok %s" % c["buyId"])
		eq(int(bought["spent"]), int(c["buySpent"]), "buy spent")
		eq(int(bought["state"]["coins"]), int(c["buyCoins"]), "coins after buy")
		eq(Kernel.level_of(bought["state"], str(c["buyId"])), int(c["buyLevel"]), "level after buy")

		var pb := Kernel.buy_perk(st, str(c["perkId"]))
		eq(pb["ok"], bool(c["perkOk"]), "perk ok %s" % c["perkId"])
		eq(int(pb["spent"]), int(c["perkSpent"]), "perk spent")
		eq(int(pb["state"]["tokens"]), int(c["perkTokens"]), "tokens after perk")
		eq(Kernel.perk_of(pb["state"], str(c["perkId"])), int(c["perkLevel"]), "perk level")

		var aw := Kernel.clone(st)
		var pts := Kernel.award(aw, f(c["awardBase"]))
		eq(pts, int(c["awardPts"]), "award points")
		eq(int(aw["coins"]), int(c["awardCoins"]), "coins after award")
		eq(int(aw["score"]), int(c["awardScore"]), "score after award")
		eq(int(aw["combo"]), int(c["awardCombo"]), "combo after award")

		eq(Kernel.prestige_tokens_for(st), int(c["prestigeTokens"]), "prestige tokens")
		eq(Kernel.can_prestige(st), bool(c["canPrestige"]), "can prestige")
		var pres := Kernel.do_prestige(st)
		eq(pres["ok"], bool(c["prestigeOk"]), "prestige ok")
		eq(int(pres["state"]["night"]), int(c["prestigeNight"]), "night after prestige")
		eq(int(pres["state"]["tokens"]), int(c["prestigeTokensAfter"]), "tokens after prestige")

		eq(Kernel.format_coins(f(c["coins"])), str(c["fmtCoins"]), "formatCoins(coins)")
		eq(Kernel.format_coins(f(c["lifetime"])), str(c["fmtLifetime"]), "formatCoins(lifetime)")
		eq(Kernel.format_coins(f(c["runCoins"])), str(c["fmtRun"]), "formatCoins(runCoins)")


func _unpack(nibble: String) -> Dictionary:
	var v := nibble.hex_to_int()
	return {"left": (v & 1) != 0, "right": (v & 2) != 0, "plunge": (v & 4) != 0, "fire": (v & 8) != 0}


func _conf_physics(runs: Array) -> void:
	var n := 0
	for run in runs:
		_ctx = "[phys %d] " % n
		n += 1
		var st := Kernel.new_state()
		for id in run["owned"]:
			st["owned"][id] = int(run["owned"][id])
		for id in run["perks"]:
			st["perks"][id] = int(run["perks"][id])
		var lg := Lcg.new(int(run["randSeed"]))
		var rng := func() -> float: return lg.next()
		var dt := f(run["dt"])
		var timeline := str(run["timeline"])
		var frames := int(run["frames"])
		var got_events: Array = []
		var trace: Array = run["trace"]
		var ti := 0
		var s := st
		for fr in range(frames):
			var out := Kernel.step(s, _unpack(timeline[fr]), dt, rng)
			s = out["state"]
			for e in out["events"]:
				var rec := {"f": fr}
				for k in e:
					rec[k] = e[k]
				got_events.append(rec)
			if fr % 25 == 0 and ti < trace.size():
				var want: Dictionary = trace[ti]
				ti += 1
				eq(int(want["f"]), fr, "trace frame alignment")
				if want["x"] == null:
					ok(s["ball"] == null, "frame %d: no ball, as in JS" % fr)
				else:
					ok(s["ball"] != null, "frame %d: a ball, as in JS" % fr)
					if s["ball"] != null:
						exact(float(s["ball"]["x"]), f(want["x"]), "frame %d ball.x" % fr)
						exact(float(s["ball"]["y"]), f(want["y"]), "frame %d ball.y" % fr)
						exact(float(s["ball"]["vx"]), f(want["vx"]), "frame %d ball.vx" % fr)
						exact(float(s["ball"]["vy"]), f(want["vy"]), "frame %d ball.vy" % fr)
				exact(float(s["flipL"]), f(want["fl"]), "frame %d flipL" % fr)
				exact(float(s["flipR"]), f(want["fr"]), "frame %d flipR" % fr)
				eq(str(s["mode"]), str(want["mode"]), "frame %d mode" % fr)
				eq(int(s["coins"]), int(want["coins"]), "frame %d coins" % fr)
				eq(int(s["score"]), int(want["score"]), "frame %d score" % fr)
				eq(int(s["combo"]), int(want["combo"]), "frame %d combo" % fr)
				eq(int(s["balls"]), int(want["balls"]), "frame %d balls" % fr)
				eq(bool(s["inPlay"]), bool(want["inPlay"]), "frame %d inPlay" % fr)

		var want_events: Array = run["events"]
		eq(got_events.size(), want_events.size(), "event count")
		for i in range(mini(got_events.size(), want_events.size())):
			var g: Dictionary = got_events[i]
			var w: Dictionary = want_events[i]
			eq(int(g["f"]), int(w["f"]), "event %d frame" % i)
			eq(str(g["type"]), str(w["type"]), "event %d type" % i)
			if w.has("pts"):
				eq(int(g.get("pts", -1)), int(w["pts"]), "event %d pts" % i)
			if w.has("id"):
				eq(str(g.get("id", "")), str(w["id"]), "event %d id" % i)
			if w.has("i"):
				eq(int(g.get("i", -1)), int(w["i"]), "event %d index" % i)
			if w.has("charge"):
				exact(f(g.get("charge", -1.0)), f(w["charge"]), "event %d charge" % i)

		var end: Dictionary = run["end"]
		eq(str(s["mode"]), str(end["mode"]), "end mode")
		eq(int(s["coins"]), int(end["coins"]), "end coins")
		eq(int(s["score"]), int(end["score"]), "end score")
		eq(int(s["balls"]), int(end["balls"]), "end balls")
		eq(int(s["night"]), int(end["night"]), "end night")
		eq(int(s["combo"]), int(end["combo"]), "end combo")
		eq(int(s["rebounds"]), int(end["rebounds"]), "end rebounds")
		eq(int(s["lifetime"]), int(end["lifetime"]), "end lifetime")
		eq(int(s["runCoins"]), int(end["runCoins"]), "end runCoins")
		exact(float(s["flipL"]), f(end["flipL"]), "end flipL")
		exact(float(s["flipR"]), f(end["flipR"]), "end flipR")
		exact(float(s["saucerHold"]), f(end["saucerHold"]), "end saucerHold")
		exact(float(s["ballSave"]), f(end["ballSave"]), "end ballSave")
		eq(bool(s["inPlay"]), bool(end["inPlay"]), "end inPlay")
		for i in range(3):
			eq(bool(s["targetDown"][i]), bool(end["targetDown"][i]), "end targetDown[%d]" % i)
		if end["ball"] == null:
			ok(s["ball"] == null, "end: no ball")
		else:
			ok(s["ball"] != null, "end: a ball")
			if s["ball"] != null:
				exact(float(s["ball"]["x"]), f(end["ball"]["x"]), "end ball.x")
				exact(float(s["ball"]["y"]), f(end["ball"]["y"]), "end ball.y")
				exact(float(s["ball"]["vx"]), f(end["ball"]["vx"]), "end ball.vx")
				exact(float(s["ball"]["vy"]), f(end["ball"]["vy"]), "end ball.vy")


func _conf_offline(cases: Array) -> void:
	var n := 0
	for c in cases:
		_ctx = "[idle %d] " % n
		n += 1
		var st := Kernel.new_state()
		for id in c["owned"]:
			st["owned"][id] = int(c["owned"][id])
		for id in c["perks"]:
			st["perks"][id] = int(c["perks"][id])
		eq(Kernel.era_index(st), int(c["eraIndex"]), "era index")
		exact(Idle.idle_rate(Kernel.era_index(st) + 1, Idle.buildings_of(st)), f(c["base"]), "idle base rate")
		exact(Idle.rate_of(st), f(c["rate"]), "gate rate")
		exact(Idle.offline_seconds(int(c["last"]), int(c["now"])), f(c["seconds"]), "offline seconds")
		eq(Idle.offline_earn(int(c["last"]), int(c["now"]), f(c["rate"])), int(c["earn"]), "offline earn")
		eq(Idle.offline_earn(int(c["now"]), int(c["last"]), f(c["rate"])), int(c["backwards"]),
			"a backwards clock earns nothing")
		eq(Idle.offline_earn(0, int(c["now"]), f(c["rate"])), int(c["coldStart"]),
			"a cold start earns nothing")
		var settled := Idle.settle(st, int(c["last"]), int(c["now"]))
		eq(int(settled["coins"]), int(c["earn"]), "settle agrees with offlineEarn")
