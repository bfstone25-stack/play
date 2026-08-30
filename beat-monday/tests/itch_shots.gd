extends SceneTree

## Capture English 1280x720 screenshots for the itch page.
## Run: xvfb-run -a godot --path beat-monday -s res://tests/itch_shots.gd

const OUT := "/tmp/itch-shots/floor13"


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute(OUT)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s-%s.png" % [OUT, name])
	print("VISUAL ", name, " ", image.get_size())


func _drain(hud: Node) -> void:
	var guard := 0
	while hud.dialogue_panel.visible and guard < 120:
		hud._advance_dialogue()
		guard += 1
		await process_frame


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	Loc.set_code("en")
	await create_timer(1.0).timeout
	await _shot("title")

	hud.title_panel.visible = false
	game.start_game()
	await create_timer(2.0).timeout
	await _shot("opening")

	# Area tour with real chapter headers and hotspot markers.
	var names := ["cubicle", "office", "breakroom", "server", "lobby", "stairs", "manager"]
	for i in names.size():
		game.area_index = i
		game._load_area()
		await _drain(hud)
		await create_timer(0.4).timeout
		await _shot("area-" + names[i])

	# Choice presentation from the break room.
	game.area_index = 2
	game._load_area()
	await _drain(hud)
	var area: Dictionary = StoryData.live()[2]
	if area.has("choice"):
		hud.show_choice(area.choice)
		await create_timer(0.6).timeout
		await _shot("choice")

	# NVL evidence page.
	hud.show_dialogue([
		["PA", "Night Operations staff: report to Floor 13 for close. Day Operations staff: disregard any voices, alarms, or personnel observed after scheduled departure."],
		["JUNE", "Meridian occupies eight through twelve. The directory skips thirteen. It has always skipped thirteen."],
	], true)
	await create_timer(2.0).timeout
	await _shot("nvl")
	await _drain(hud)

	# Ending card.
	hud.show_ending_card(StoryData.live_endings()["CLOCK_OUT"][-1][1])
	await create_timer(0.6).timeout
	await _shot("ending")

	print("ITCH_SHOTS_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
