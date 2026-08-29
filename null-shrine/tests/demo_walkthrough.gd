extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var game: Control


func _hold(seconds := 1.8) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	game = packed.instantiate()
	root.add_child(game)
	await _hold(2.0)
	game.start_run()
	await _hold()
	game.complete_tutorial()
	await _hold()

	var state = game.state
	state.appraise("wedding_ring")
	state.toggle_shelf("wedding_ring")
	state.call_customer("wedding_ring")
	game._show_customer_offer()
	await _hold(2.2)
	state.resolve_customer(true, true)
	state.appraise("bone_key")
	state.toggle_shelf("bone_key")
	state.call_customer("bone_key")
	state.resolve_customer(false, true)
	state.enter_night("music_box")

	for room_index in 4:
		state.night = 1 if room_index < 2 else 2
		state.phase = StateScript.Phase.NIGHT_1 if room_index < 2 else StateScript.Phase.NIGHT_2
		state.start_room(room_index)
		state.carried_id = "music_box"
		game._start_room()
		await _hold(1.5)
		game._on_objective_reached()
		await _hold(1.8)

	state.phase = StateScript.Phase.FINAL
	if not state.has_item("crypt_heart"):
		state.inventory.append(state.make_curio("crypt_heart"))
	state.rooms_cleared.assign([0, 1, 2, 3])
	state.marks_bank = 25
	state.mercy = 3
	state.trust = 2
	state.clues = 7
	game._show_final()
	await _hold(2.4)
	state.choose_final("seal")
	game._show_result()
	await _hold(3.0)
	print("DEMO WALKTHROUGH COMPLETE")
	quit(0)


func _init() -> void:
	call_deferred("_run")
