extends Node
## Headless test scene — the JS<->GDScript conformance test over tests/conformance.json
## (300 games recorded from the prototype's real game.js), plus the prototype's
## fairness.test.js invariants over the planner.
##
##   $GODOT --headless --path . res://tests/run_tests.tscn

var passed := 0
var failed := 0
var shown := 0


func ok(c: bool, m: String) -> void:
	if c:
		passed += 1
	else:
		failed += 1
		if shown < 40:
			shown += 1
			printerr("  FAIL " + m)


func lcg(seed: int) -> Callable:
	var st := [seed & 0xFFFFFFFF]
	return func() -> float:
		st[0] = (st[0] * 1664525 + 1013904223) & 0xFFFFFFFF
		return float(st[0]) / 4294967296.0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_fairness()
	_conformance()
	print("\n%d checks passed, %d failed" % [passed, failed])
	print("TESTS_OK" if failed == 0 else "TESTS_FAILED")
	get_tree().quit(0 if failed == 0 else 1)


func _fairness() -> void:
	print("fairness (the prototype's fairness.test.js)")
	for n in range(40):
		var rng := lcg(77 + n)
		var s := {"rng": rng, "lang": "en"}
		var mimic: Dictionary = GCRules.pick(s, GCRules.AGENTS)
		s.mimicId = mimic.id
		s.op = GCRules.OPS[n % 3]
		s.agents = GCRules.AGENTS.map(func(a): return {"id": a.id})
		var q := GCRules.plan_requests(s)
		ok(q.size() == int(s.op.requests), "length")
		ok(q[0].speaker != s.mimicId, "first request must be friendly")
		ok(q[1].speaker != s.mimicId, "second request must be friendly")
		ok(q.any(func(r): return r.speaker == s.mimicId), "at least one mimic request")


func _snap(s: Dictionary) -> Dictionary:
	var p: Dictionary = s.panel
	var log_rows := []
	for row in s.log:
		log_rows.append([row[0], str(row[1]).replace("<b>", "").replace("</b>", "")])
	var name_btns := []
	if p.naming:
		name_btns = p.name_btns
	return {
		"who": p.who, "type": p.type, "body": p.body, "extra": p.extra,
		"locked": p.locked, "naming": p.naming, "nameBtns": name_btns,
		"time": s.hud.time, "ff": s.hud.ff, "score": s.hud.score,
		"codebook": s.codebook, "note": s.note, "opName": s.opName,
		"log": log_rows, "roster": GCRules.roster_rows(s),
		"end": s.end, "tel": s.events.size(),
	}


func _same(a, b) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for k in a:
			if not b.has(k) or not _same(a[k], b[k]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not _same(a[i], b[i]):
				return false
		return true
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a == null or b == null:
		return a == null and b == null
	return str(a) == str(b)


func _conformance() -> void:
	print("conformance: replaying the prototype's 300 recorded games")
	var f := FileAccess.open("res://tests/conformance.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var games: Array = data.games
	var reasons := {}
	for g in games:
		var op: Dictionary = GCRules.OPS[int(g.op) - 1]
		var wins := 3 if int(g.op) > 1 else 0
		var best := {"op1": 100, "op2": 100, "op3": 0} if int(g.op) > 1 else {}
		var s := GCRules.start_op(op, lcg(int(g.seed)), "en", wins, best)
		var mismatch := ""
		for i in range(g.actions.size()):
			var act: Dictionary = g.actions[i]
			match str(act.a):
				"start":
					pass
				"tick":
					for _k in range(int(act.n)):
						GCRules.tick(s)
				"q":
					GCRules.interrogate(s)
				"auth", "deny":
					var r := GCRules.resolve(s, str(act.a))
					if r.next:
						GCRules.next_request(s)
				"name":
					GCRules.accuse(s, s.agents[int(act.idx)].id)
			var want: Dictionary = g.snaps[i]
			var got := _snap(s)
			if mismatch == "":
				for k in want:
					if not _same(want[k], got.get(k)):
						mismatch = "seed %d op %d step %d (%s): %s\n    want %s\n    got  %s" % [int(g.seed), int(g.op), i, act.a, k, JSON.stringify(want[k]), JSON.stringify(got.get(k))]
						break
		ok(mismatch == "", mismatch)
		# the telemetry payloads, verbatim
		var tel_ok: bool = g.tel.size() == s.events.size()
		if tel_ok:
			for i in range(g.tel.size()):
				if not _same(g.tel[i].name, s.events[i].name) or not _same(g.tel[i].value, s.events[i].value):
					tel_ok = false
					ok(false, "seed %d tel %d: want %s got %s" % [int(g.seed), i, JSON.stringify(g.tel[i]), JSON.stringify(s.events[i])])
					break
		else:
			ok(false, "seed %d: %d tel events, want %d" % [int(g.seed), s.events.size(), g.tel.size()])
		if tel_ok:
			passed += 1
		var last: Dictionary = s.events[-1]
		var key: String = str(last.name) + ":" + str(last.value.get("reason", ""))
		reasons[key] = int(reasons.get(key, 0)) + 1
		# the save the prototype wrote
		ok(_same(int(g.save.wins), s.wins), "seed %d wins %d want %s" % [int(g.seed), s.wins, str(g.save.wins)])
		ok(_same(g.save.best, s.best), "seed %d best %s want %s" % [int(g.seed), JSON.stringify(s.best), JSON.stringify(g.save.best)])
	print("  endings: " + JSON.stringify(reasons))
