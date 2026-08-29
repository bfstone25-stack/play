extends SceneTree

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute("/tmp/late-locale")
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("/tmp/late-locale/%s.png" % name)
	print("VISUAL ", name, " ", image.get_size())


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hud: Node = scene.get_node("HUD")
	Loc.set_code("zh")
	await _shot("title-zh")
	Loc.set_code("en")
	await _shot("title-en")
	Loc.set_code("zh")
	hud.hide_splash()
	await _shot("lobby-zh")
	print("VISUAL_LOCALE_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
