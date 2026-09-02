extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_title("Across the Hall — bathroom / doors tour")
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud := scene.get_node_or_null("HUD")
	if hud and hud.has_method("hide_splash"):
		hud.hide_splash()
	elif hud is CanvasItem:
		(hud as CanvasItem).visible = false
	var player: Node3D = scene.get_node("Player")
	player.locked = true
	var head: Node3D = player.get_node("Head")
	var cam := head.get_node("Camera3D") as Camera3D
	cam.current = true
	var tour := [
		{"pos": Vector3(2.4, 0.05, 8.05), "look": Vector3(6.5, 1.2, 8.0), "hold": 70},
		{"pos": Vector3(4.2, 0.05, 8.0), "look": Vector3(6.5, 1.15, 10.2), "hold": 65},
		{"pos": Vector3(6.2, 0.05, 9.5), "look": Vector3(6.55, 1.2, 10.5), "hold": 80},
		{"pos": Vector3(6.55, 0.05, 10.55), "look": Vector3(7.9, 1.15, 11.5), "hold": 90},
		{"pos": Vector3(7.15, 0.05, 10.85), "look": Vector3(8.45, 0.95, 11.4), "hold": 90},
		{"pos": Vector3(7.3, 0.05, 11.15), "look": Vector3(6.7, 1.85, 11.7), "hold": 75},
		{"pos": Vector3(5.5, 0.05, 7.2), "look": Vector3(5.55, 1.2, 5.65), "hold": 70},
		{"pos": Vector3(6.0, 0.05, 5.4), "look": Vector3(7.4, 1.0, 4.5), "hold": 80},
	]
	for s in tour:
		player.global_position = s.pos
		head.look_at(s.look, Vector3.UP)
		for _i in int(s.hold):
			RenderingServer.force_draw()
			await process_frame
	print("BATH_TOUR_OK")
	# Hold final frame a bit for the recording
	for _i in 40:
		RenderingServer.force_draw()
		await process_frame
	quit(0)
