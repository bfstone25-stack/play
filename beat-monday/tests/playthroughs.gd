extends SceneTree

var failures := PackedStringArray()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/floor13-endings")
	var routes := [
		{"name": "clock_out", "choices": ["TRUST", "REFUSE", "STAIRS", "RESIGN"], "ending": "CLOCK_OUT"},
		{"name": "new_manager", "choices": ["SUSPECT", "OBEY", "ELEVATOR", "SIGN"], "ending": "NEW_MANAGER"},
		{"name": "monday_forever", "choices": ["TRUST", "OBEY", "STAIRS", "SIGN"], "ending": "MONDAY_FOREVER"}
	]
	for route in routes:
		await _play(route)
	if failures.is_empty():
		print("PLAYTHROUGHS_OK routes=3 complete_areas=21 complete_hotspots=84 endings=3")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _play(route: Dictionary) -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	game.start_game()
	await _drain(hud)
	var choice_index := 0
	for expected_area in 7:
		if game.area_index != expected_area:
			failures.append("%s entered area %d as %d" % [route.name, expected_area, game.area_index])
			break
		var area: Dictionary = StoryData.AREAS[game.area_index]
		for hotspot in area.hotspots:
			game._on_hotspot(hotspot[0])
			await _drain(hud)
		if area.has("choice"):
			if not hud.choice_panel.visible:
				failures.append("%s did not show choice in %s" % [route.name, area.id])
				break
			game._on_choice(route.choices[choice_index])
			choice_index += 1
			await _drain(hud)
		if not hud.route_button.visible:
			failures.append("%s route button missing in %s" % [route.name, area.id])
			break
		game._on_route()
		await _drain(hud)
	if game.ending_id != route.ending:
		failures.append("%s resolved %s instead of %s" % [route.name, game.ending_id, route.ending])
	if game.completed_hotspots.size() != 28:
		failures.append("%s completed %d hotspots" % [route.name, game.completed_hotspots.size()])
	if not hud.ending_panel.visible:
		failures.append("%s did not stage ending card" % route.name)
	for _frame in 8:
		RenderingServer.force_draw()
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image and not image.is_empty():
		image.save_png("/tmp/floor13-endings/%s.png" % route.name)
	print("PLAYTHROUGH ", route.name, " ending=", game.ending_id, " hotspots=", game.completed_hotspots.size(), " evidence=", game.discoveries.size())
	game.queue_free()
	await process_frame

func _drain(hud: Node) -> void:
	var guard := 0
	while hud.dialogue_panel.visible and guard < 500:
		hud._advance_dialogue()
		await process_frame
		guard += 1
	if guard >= 500:
		failures.append("dialogue drain exceeded guard")
