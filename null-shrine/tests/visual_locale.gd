extends SceneTree

var game: Control


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.05).timeout
	DirAccess.make_dir_recursive_absolute("/tmp/midnight-locale")
	var image := root.get_texture().get_image()
	var path := "/tmp/midnight-locale/%s.png" % name
	image.save_png(path)
	print("VISUAL ", name, " ", image.get_size())


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/main.tscn") as PackedScene
	game = packed.instantiate()
	root.add_child(game)
	Loc.set_code("zh")
	await _shot("title-zh")
	Loc.set_code("en")
	await _shot("title-en")
	Loc.set_code("ja")
	await _shot("title-ja")
	Loc.set_code("es")
	await _shot("title-es")
	Loc.set_code("ko")
	await _shot("title-ko")
	Loc.set_code("zh")
	game.start_run()
	await _shot("opening-zh")
	game.complete_tutorial()
	await _shot("shop-zh")
	Loc.set_code("en")
	await _shot("shop-en")
	print("VISUAL_LOCALE_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
