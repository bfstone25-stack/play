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
	var hud := scene.get_node_or_null("HUD") as CanvasItem
	if hud:
		hud.visible = false
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.current = true
	scene.add_child(cam)
	cam.global_position = Vector3(0.15, 1.52, 0.55)
	cam.look_at(Vector3(1.4, 1.15, 8.2), Vector3.UP)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for i in 45:
		RenderingServer.force_draw()
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("user://smoke.png")
		var dest := "/tmp/across-hall-smoke.png"
		img.save_png(dest)
		print("SMOKE_PNG ", dest, " ", img.get_width(), "x", img.get_height())
	print("SMOKE_OK children=", world.get_child_count())
	quit(0)
