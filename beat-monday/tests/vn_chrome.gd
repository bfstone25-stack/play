extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	game.start_game()
	await process_frame
	if not hud.dialogue_panel.visible or hud.nvl_root.visible:
		push_error("opening should use ADV")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("/tmp/floor13-vn")
	var tex := root.get_viewport().get_texture()
	if tex:
		var img := tex.get_image()
		if img:
			img.save_png("/tmp/floor13-vn/adv.png")
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
		await process_frame
	game._on_hotspot("coffee")
	await process_frame
	if not hud.nvl_root.visible:
		push_error("coffee diary should use NVL")
		quit(2)
		return
	tex = root.get_viewport().get_texture()
	if tex:
		var nvl_img := tex.get_image()
		if nvl_img:
			nvl_img.save_png("/tmp/floor13-vn/nvl.png")
	print("VN_CHROME_OK adv=1 nvl=1")
	quit(0)
