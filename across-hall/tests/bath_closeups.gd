extends SceneTree

## Close-ups of bathrooms / interior doors for walkthrough evidence.

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
		{"name": "vanity_toilet", "pos": Vector3(7.1, 0.05, 10.7), "look": Vector3(8.5, 0.9, 11.5)},
		{"name": "full_bath", "pos": Vector3(6.55, 0.05, 10.55), "look": Vector3(7.8, 1.2, 11.5)},
		{"name": "shower_head", "pos": Vector3(7.2, 0.05, 11.1), "look": Vector3(6.7, 1.85, 11.7)},
		{"name": "bath_door_leaf", "pos": Vector3(6.3, 0.05, 9.55), "look": Vector3(6.7, 1.15, 10.55)},
		{"name": "bed_door_leaf", "pos": Vector3(5.4, 0.05, 6.8), "look": Vector3(5.55, 1.15, 5.65)},
		{"name": "lived_in_402", "pos": Vector3(4.0, 0.05, 7.6), "look": Vector3(6.8, 1.15, 6.5)},
	]
	DirAccess.make_dir_recursive_absolute("/tmp/across-bath")
	for s in shots:
		player.global_position = s.pos
		var head: Node3D = player.get_node("Head")
		head.look_at(s.look, Vector3.UP)
		for _i in 18:
			RenderingServer.force_draw()
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path := "/tmp/across-bath/%s.png" % s.name
			img.save_png(path)
			print("BATH_SHOT ", path)
	print("BATH_CLOSEUPS_OK")
	quit(0)
