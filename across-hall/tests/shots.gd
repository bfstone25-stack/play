extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud := scene.get_node_or_null("HUD") as CanvasItem
	if hud:
		hud.visible = false
	var player: Node3D = scene.get_node("Player")
	player.locked = true
	var cam := player.get_node("Head/Camera3D") as Camera3D
	cam.current = true
	var shots := [
		{"name": "hall", "pos": Vector3(0.05, 0.05, 1.1), "look": Vector3(1.55, 1.25, 8.0)},
		{"name": "doors", "pos": Vector3(0.0, 0.05, 5.2), "look": Vector3(-1.55, 1.35, 2.4)},
		{"name": "apt402", "pos": Vector3(3.4, 0.05, 8.05), "look": Vector3(7.6, 1.2, 8.05)},
		{"name": "apt401", "pos": Vector3(-3.4, 0.05, 2.4), "look": Vector3(-7.4, 1.2, 2.4)},
	]
	DirAccess.make_dir_recursive_absolute("/tmp/across-shots")
	for s in shots:
		player.global_position = s.pos
		var head: Node3D = player.get_node("Head")
		head.look_at(s.look, Vector3.UP)
		for i in 20:
			RenderingServer.force_draw()
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path := "/tmp/across-shots/%s.png" % s.name
			img.save_png(path)
			print("SHOT ", path, " ", img.get_width(), "x", img.get_height())
	print("SHOTS_OK")
	quit(0)
