extends SceneTree

## Slice builds end once Night 1 is banked (or lost). Full builds continue
## into Day 2. Drives the deterministic state machine through the real
## tutorial -> Day 1 -> Night 1 loop, then asserts the gate.


func _init() -> void:
	call_deferred("_run")


func _fresh_game() -> Control:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	return game


func _drive_night_one(game: Control) -> void:
	game._start_run()
	var s = game.state
	s.tutorial_sale()
	for id in ["wedding_ring", "bone_key"]:
		s.appraise(id)
		s.toggle_shelf(id)
		s.call_customer(id)
		s.resolve_customer(true, true)
	s.enter_night("music_box")
	while s.room_active:
		s.combat_action("strike")
	game._advance_room()
	while s.room_active:
		s.combat_action("strike")


func _run() -> void:
	var game: Control = await _fresh_game()
	await process_frame

	game.SLICE = true
	_drive_night_one(game)
	game._advance_room()
	if game.phase_label.text != Loc.t("slice.phase"):
		push_error("slice: banking Night 1 should show the slice gate, got phase=%s" % game.phase_label.text)
		quit(1)
		return
	if game.title.text != Loc.t("slice.title"):
		push_error("slice: gate title mismatch, got %s" % game.title.text)
		quit(1)
		return
	game.queue_free()

	var full: Control = await _fresh_game()
	await process_frame
	full.SLICE = false
	_drive_night_one(full)
	full._advance_room()
	if full.phase_label.text == Loc.t("slice.phase"):
		push_error("full: slice gate must never trigger without the slice feature")
		quit(1)
		return
	if full.state.phase != MidnightState.Phase.DAY_2:
		push_error("full: banking Night 1 should continue to Day 2, got phase=%s" % full.state.phase)
		quit(1)
		return
	full.queue_free()

	print("SLICE_GATE_OK")
	quit(0)
