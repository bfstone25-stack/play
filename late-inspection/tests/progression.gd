extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	await process_frame
	await _test_route("witness", "WITNESS")
	await _test_route("complicit", "COMPLICIT")
	await _test_route("404", "404")
	await _test_mixed_routes()
	await _test_stage_flags()
	if failures.is_empty():
		print("PROGRESSION_OK routes=6 endings=3 critical_flags=10")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _fresh_game() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game

func _test_route(route: String, expected: String) -> void:
	var game := await _fresh_game()
	var result: String = game.debug_complete_route(route)
	if result != expected or game.ending_id != expected:
		failures.append("%s route expected %s got %s" % [route, expected, game.ending_id])
	if not game.ending or not game.await_restart:
		failures.append("%s route did not reach complete ending state" % route)
	game.free()
	await process_frame

func _test_mixed_routes() -> void:
	for mix in [
		{"photo_kept": true, "pipe_silenced": true, "clause_signed": true, "final_open": true},
		{"photo_deleted": true, "pipe_answered": true, "clause_refused": true, "final_ignore": true},
		{"photo_kept": true, "pipe_answered": true, "clause_signed": true, "final_ignore": true},
	]:
		var game := await _fresh_game()
		game.flags["iris_record"] = true
		for key in mix:
			game.flags[key] = mix[key]
		var result: String = game._resolve_ending()
		if result != "404":
			failures.append("mixed route resolved %s instead of 404" % result)
		game.free()
		await process_frame

func _test_stage_flags() -> void:
	var game := await _fresh_game()
	game.on_note("order")
	if game.stage != 1 or not game.flags["order_read"]:
		failures.append("inspection order did not advance chapter gate")
	game.on_note("dane")
	if not game.flags["dane_note"]:
		failures.append("Dane note flag missing")
	game.flags["photo_kept"] = true
	game.flags["pipe_answered"] = true
	game.flags["iris_record"] = true
	game.flags["final_open"] = true
	if game._resolve_ending() != "WITNESS":
		failures.append("Witness eligibility does not consume early flags")
	game.free()
