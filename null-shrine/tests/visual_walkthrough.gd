extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var game: Control
var output_dir := "res://visual-output"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_dir = arg.trim_prefix("--output=")
	call_deferred("_run")


func _frame() -> void:
	await process_frame
	await process_frame
	await create_timer(0.08).timeout


func _shot(name: String) -> void:
	await _frame()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var path := ProjectSettings.globalize_path(output_dir.path_join(name + ".png"))
	var image := root.get_texture().get_image()
	var result := image.save_png(path)
	print("VISUAL ", name, " ", image.get_size(), " result=", result, " path=", path)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	game = packed.instantiate()
	root.add_child(game)
	await _shot("01-title-desktop")
	game.start_run()
	await _shot("02-opening")
	game.complete_tutorial()
	await _shot("03-day1-shop")

	var state = game.state
	for id in ["wedding_ring", "bone_key"]:
		state.appraise(id)
		state.toggle_shelf(id)
		state.call_customer(id)
		state.resolve_customer(true, true)
	game._show_shop()
	await _shot("04-day1-ready")
	state.enter_night("music_box")
	game._start_room()
	await _shot("05-room1-receipt-stair")
	state.room_index = 1
	state.start_room(1)
	game._start_room()
	game._on_objective_reached()
	await _shot("06-room2-widow-combat")

	state.day = 2
	state.phase = StateScript.Phase.DAY_2
	state.customer_index = 2
	game._show_shop()
	await _shot("07-day2-shop")
	state.night = 2
	state.phase = StateScript.Phase.NIGHT_2
	state.carried_id = "bone_key"
	state.start_room(2)
	game._start_room()
	await _shot("08-room3-ossuary")
	state.start_room(3)
	state.carried_id = "music_box"
	game._start_room()
	game._on_objective_reached()
	await _shot("09-room4-bell-warden")

	state.phase = StateScript.Phase.FINAL
	if not state.has_item("crypt_heart"):
		state.inventory.append(state.make_curio("crypt_heart"))
	game._show_final()
	await _shot("10-final-appraisal")
	state.rooms_cleared = [0, 1, 2, 3]
	state.choose_final("seal")
	game._show_result()
	await _shot("11-quiet-seal-result")
	print("VISUAL WALKTHROUGH COMPLETE")
	quit(0)
