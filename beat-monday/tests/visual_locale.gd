extends SceneTree

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute("/tmp/floor13-locale")
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("/tmp/floor13-locale/%s.png" % name)
	print("VISUAL ", name, " ", image.get_size())


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var hud: Node = game.get_node("HUD")
	Loc.set_code("zh")
	await _shot("title-zh")
	Loc.set_code("en")
	await _shot("title-en")
	Loc.set_code("ja")
	await _shot("title-ja")
	Loc.set_code("ko")
	await _shot("title-ko")
	Loc.set_code("es")
	await _shot("title-es")
	Loc.set_code("zh")
	hud.title_panel.visible = false
	game.start_game()
	await _shot("dialogue-zh")
	game.restart()
	Loc.set_code("ja")
	hud.title_panel.visible = false
	game.start_game()
	await _shot("dialogue-ja")
	print("VISUAL_LOCALE_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
