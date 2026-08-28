extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("main.tscn failed to load")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if scene.get_node_or_null("Player") == null:
		push_error("missing Player")
		quit(2)
		return
	if scene.get_node_or_null("World") == null:
		push_error("missing World")
		quit(3)
		return
	var world := scene.get_node("World")
	if world.get_child_count() < 8:
		push_error("world did not build geometry")
		quit(4)
		return
	var interactables := get_nodes_in_group("interactable")
	if interactables.size() < 1:
		push_error("expected initial inspection interaction")
		quit(5)
		return
	var hud := scene.get_node_or_null("HUD") as CanvasItem
	if hud:
		hud.visible = false
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.current = true
	scene.add_child(cam)
	cam.global_position = Vector3(-6.0, 1.5, 5.6)
	cam.look_at(Vector3(-1.0, 1.15, 5.0), Vector3.UP)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for i in 50:
		RenderingServer.force_draw()
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("user://smoke.png")
		var dest := "/tmp/late-inspection-smoke.png"
		img.save_png(dest)
		print("SMOKE_PNG ", dest, " ", img.get_width(), "x", img.get_height())
	cam.global_position = Vector3(7.9, 1.45, 2.0)
	cam.look_at(Vector3(10.6, 0.9, 4.0), Vector3.UP)
	for i in 35:
		RenderingServer.force_draw()
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img:
		var dest2 := "/tmp/late-inspection-pipe.png"
		img.save_png(dest2)
		print("SMOKE_PNG ", dest2, " ", img.get_width(), "x", img.get_height())
	if hud:
		hud.visible = true
		if hud.has_method("hide_splash"):
			hud.hide_splash()
	(scene as Node).call(
		"open_choice",
		"stain",
		"IRIS VALE — STILL HERE",
		"Keep the photograph and attach it",
		"Wipe the wall and delete the image",
		null
	)
	for i in 20:
		RenderingServer.force_draw()
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img:
		var dest3 := "/tmp/late-inspection-choice.png"
		img.save_png(dest3)
		print("SMOKE_PNG ", dest3, " ", img.get_width(), "x", img.get_height())
	print("SMOKE_OK children=", world.get_child_count(), " interactables=", interactables.size())
	quit(0)
