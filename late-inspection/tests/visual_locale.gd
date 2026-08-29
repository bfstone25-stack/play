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
	Loc.set_code("ja")
	await _shot("title-ja")
	Loc.set_code("ko")
	await _shot("title-ko")
	Loc.set_code("es")
	await _shot("title-es")
	Loc.set_code("zh")
	hud.hide_splash()
	hud.show_story("order", Loc.t("beat.witness.1") + "\n---\n" + Loc.t("obj.0"), false, Callable())
	await _shot("adv-zh")
	Loc.set_code("ja")
	hud.show_story("order", Loc.t("beat.witness.1") + "\n---\n" + Loc.t("obj.0"), false, Callable())
	await _shot("adv-ja")
	Loc.set_code("zh")
	hud.show_story("letters", Loc.t("beat.witness.0") + "\n---\n" + Loc.t("beat.404.2"), true, Callable())
	await _shot("nvl-zh")
	print("VISUAL_LOCALE_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
