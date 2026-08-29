extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("main scene failed to load")
		quit(1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if game.get_node_or_null("PixelWorld") == null or game.get_node_or_null("HUD") == null:
		push_error("runtime systems missing")
		quit(2)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	var world: Node = game.get_node("PixelWorld")
	DirAccess.make_dir_recursive_absolute("/tmp/floor13-screens")
	var area_ids := ["cubicle", "office", "breakroom", "server", "lobby", "stairs", "manager"]
	for id in area_ids:
		world.build(id)
		hud.set_header("VISUAL AUDIT", id.to_upper(), "12:00 AM", "Seven-area production visual check.")
		for _frame in 8:
			RenderingServer.force_draw()
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		if image == null or image.is_empty():
			push_error("could not capture %s" % id)
			quit(3)
			return
		image.save_png("/tmp/floor13-screens/%s.png" % id)
		print("SCREEN ", id, " ", image.get_width(), "x", image.get_height())
	game.start_game()
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
	await process_frame
	var hotspots := get_nodes_in_group("hotspot")
	if hotspots.size() != 4:
		push_error("expected four current-area hotspots, got %d" % hotspots.size())
		quit(4)
		return
	var min_target := Vector2(10000, 10000)
	for hotspot in hotspots:
		min_target.x = min(min_target.x, hotspot.size.x)
		min_target.y = min(min_target.y, hotspot.size.y)
	if min_target.x < 88 or min_target.y < 44:
		push_error("touch target below minimum: %s" % min_target)
		quit(5)
		return
	game._on_hotspot("ticket")
	await process_frame
	var dialogue_image := root.get_viewport().get_texture().get_image()
	dialogue_image.save_png("/tmp/floor13-screens/dialogue.png")
	print("SMOKE_OK screens=7 current_hotspots=", hotspots.size(), " min_touch_target=", min_target)
	quit(0)
