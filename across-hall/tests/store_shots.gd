extends SceneTree

## Store screenshots with HUD + wall clock frozen at 02:17.

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud := scene.get_node_or_null("HUD")
	if hud and hud.has_method("hide_splash"):
		hud.hide_splash()
	# Let ambience settle, then force the frozen time onto the HUD.
	for _i in 30:
		await process_frame
	if hud and hud.has_method("set_clock"):
		hud.set_clock("02:17")
	var player: Node3D = scene.get_node("Player")
	player.locked = true
	var head: Node3D = player.get_node("Head")
	(head.get_node("Camera3D") as Camera3D).current = true
	# Open 401 so we can shoot the wall clock.
	if scene.has_method("give_item"):
		scene.call("give_item", "key")
	if scene.has_method("open_401"):
		scene.call("open_401")
	await process_frame
	var shots := [
		{"name": "store_hall_0217", "pos": Vector3(0.05, 0.05, 1.2), "look": Vector3(0.2, 1.3, 9.0), "hud": true},
		{"name": "store_doors_0217", "pos": Vector3(0.0, 0.05, 5.0), "look": Vector3(-1.55, 1.35, 2.4), "hud": true},
		{"name": "store_clock_0217", "pos": Vector3(-7.2, 0.05, 0.85), "look": Vector3(-8.7, 1.55, 0.85), "hud": true},
		{"name": "store_calendar_0217", "pos": Vector3(-2.6, 0.05, 2.4), "look": Vector3(-3.25, 0.75, 2.15), "hud": true},
		{"name": "store_apt401_0217", "pos": Vector3(-4.0, 0.05, 2.2), "look": Vector3(-8.2, 1.45, 1.0), "hud": true},
	]
	DirAccess.make_dir_recursive_absolute("/tmp/across-store")
	for s in shots:
		player.global_position = s.pos
		head.look_at(s.look, Vector3.UP)
		if hud and hud.has_method("set_clock"):
			hud.set_clock("02:17")
		for _i in 20:
			RenderingServer.force_draw()
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path := "/tmp/across-store/%s.png" % s.name
			img.save_png(path)
			print("STORE_SHOT ", path)
	print("STORE_SHOTS_OK")
	quit(0)
