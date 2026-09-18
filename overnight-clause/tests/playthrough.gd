extends SceneTree

## A scripted full playthrough on the Witness route, through the production scene and the
## production resolver — every interaction in order, every VN page advanced, both adult
## scenes reached. Run twice: once as a free package (gated plates censored), once after
## an unlock has been delivered, so the same route proves both sides of the gate.

var failures: Array[String] = []
var game: Node
var hud: Node

func _init() -> void:
	call_deferred("_run")

func _fail(m: String) -> void:
	failures.append(m)

func _fresh() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	hud = game.get_node("HUD")
	hud.hide_splash()

func _drain() -> void:
	var guard := 0
	# The ending sequence is held open on purpose (stay_open), so it is not something
	# to advance past — stop there.
	while hud.is_vn_open() and not game.ending and guard < 800:
		hud.advance_vn()
		guard += 1
		await process_frame
	if guard >= 800:
		_fail("a scene never closed")

func _choose(id: String, i: int) -> void:
	game.open_choice(id, "prompt", "A", "B", null)
	await process_frame
	hud._pick(i)
	await process_frame
	await _drain()

func _route(expect_unlocked: bool) -> String:
	await _fresh()
	game.on_note("order")
	game.on_note("dane")          # 403 opens: Dane in person
	await _drain()
	if not game.flags["dane_note"]:
		_fail("dane_note not set")
	game.on_note("notice")
	game.on_note("checklist")
	game.on_note("answering")
	await _choose("stain", 0)     # keep the photograph -> cg_mirror
	if hud.plates.seen.get("cg_mirror", false) != true:
		_fail("cg_mirror did not play")
	game.on_note("service")
	await _choose("pipe", 0)      # answer the pipe -> cg_hatch (gated)
	if not game.flags["pipe_answered"]:
		_fail("pipe_answered not set")
	if game.last_plate_unlocked != expect_unlocked:
		_fail("cg_hatch unlocked=%s, expected %s" % [game.last_plate_unlocked, expect_unlocked])
	game.on_note("wardrobe")
	game.on_note("cassette")      # -> cg_cavity, never gated
	await _drain()
	if hud.plates.seen.get("cg_cavity", false) != true:
		_fail("cg_cavity did not play")
	game.on_note("followup")
	await _choose("clause", 1)    # tear it -> cg_403 (gated, three flags)
	if not game.flags["clause_refused"]:
		_fail("clause_refused not set")
	if game.last_plate_unlocked != expect_unlocked:
		_fail("cg_403 unlocked=%s, expected %s" % [game.last_plate_unlocked, expect_unlocked])
	game.on_note("final_evidence")
	await _choose("final", 0)
	var id: String = game.ending_id
	if not hud.plates.seen.get("cg_witness", false):
		_fail("no ending plate for %s" % id)
	game.free()
	await process_frame
	return id

func _run() -> void:
	# 1. the free package: the two gated plates are censored, everything else plays
	Unlock.simulate_free = true
	DirAccess.remove_absolute(Unlock.saved_path("cg_hatch"))
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	var first := await _route(false)
	if first != "WITNESS":
		_fail("free run resolved %s, expected WITNESS" % first)

	# 2. deliver both unlocks the way a redeemed ticket does, and replay the same route
	for id in Overnight.GATED:
		var bytes := FileAccess.get_file_as_bytes("res://assets/plates_x/%s.png" % id)
		if not Unlock.write_delivered(id, bytes):
			_fail("could not deliver %s" % id)
	var second := await _route(true)
	if second != "WITNESS":
		_fail("unlocked run resolved %s, expected WITNESS" % second)

	Unlock.simulate_free = false
	DirAccess.remove_absolute(Unlock.saved_path("cg_hatch"))
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	if failures.is_empty():
		print("PLAYTHROUGH_OK route=WITNESS runs=2 plates_seen=6 unlocks_redeemed=2")
		quit(0)
	for f in failures:
		push_error(f)
	quit(1)
