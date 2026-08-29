extends SceneTree

func _init() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_position(Vector2i(0, 0))
	var hud: Node = game.get_node("HUD")
	await create_timer(2.0).timeout
	hud.title_panel.visible = false
	game.start_game()
	await create_timer(1.4).timeout
	await _drain(hud)
	for area_index in 7:
		var area: Dictionary = StoryData.AREAS[area_index]
		await create_timer(1.2).timeout
		game._on_hotspot(area.hotspots[0][0])
		await create_timer(1.8).timeout
		await _drain(hud)
		for i in range(1, area.hotspots.size()):
			game._on_hotspot(area.hotspots[i][0])
			await _drain(hud)
		if area.has("choice"):
			await create_timer(1.5).timeout
			var choice := {"breakroom": "TRUST", "server": "REFUSE", "lobby": "STAIRS", "manager": "RESIGN"}[area.id]
			game._on_choice(choice)
			await create_timer(1.2).timeout
			await _drain(hud)
		game._on_route()
		await _drain(hud)
	await create_timer(3.0).timeout
	print("DEMO_OK ending=", game.ending_id)
	quit(0)

func _drain(hud: Node) -> void:
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
		await process_frame
