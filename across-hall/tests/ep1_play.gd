extends SceneTree

## Episode I visual checkpoints after the materials upgrade.

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var player: CharacterBody3D = scene.get_node("Player")
	player.locked = true
	player.get_node("Head/Camera3D").current = true
	if scene.has_method("hide_splash") == false and scene.get_node_or_null("HUD"):
		var hud = scene.get_node("HUD")
		if hud.has_method("hide_splash"):
			hud.hide_splash()
	DirAccess.make_dir_recursive_absolute("/tmp/across-ep1-play")
	var shots := [
		{"name": "hall_start", "pos": Vector3(0.05, 0.05, 1.0), "look": Vector3(0.2, 1.2, 9.0)},
		{"name": "doors", "pos": Vector3(0.0, 0.05, 5.0), "look": Vector3(-1.5, 1.3, 2.4)},
		{"name": "apt402", "pos": Vector3(3.5, 0.05, 8.05), "look": Vector3(7.8, 1.2, 9.5)},
		{"name": "bath402", "pos": Vector3(7.15, 0.05, 10.85), "look": Vector3(8.4, 1.1, 11.2)},
		{"name": "bath_door", "pos": Vector3(6.2, 0.05, 9.4), "look": Vector3(6.55, 1.2, 10.4)},
		{"name": "bedroom", "pos": Vector3(5.3, 0.05, 6.5), "look": Vector3(7.2, 1.0, 4.7)},
	]
	for s in shots:
		player.global_position = s.pos
		player.rotation = Vector3.ZERO
		var head: Node3D = player.get_node("Head")
		head.rotation = Vector3.ZERO
		head.look_at(s.look, Vector3.UP)
		for _i in 14:
			RenderingServer.force_draw()
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("/tmp/across-ep1-play/%s.png" % s.name)
			print("EP1_SHOT ", s.name)

	# Play through critical beats and capture ending state cues.
	player.locked = false
	scene.call("give_item", "flashlight")
	scene.call("give_item", "note")
	scene.call("give_item", "tape")
	scene.call("give_item", "key")
	scene.call("open_401")
	await process_frame
	player.global_position = Vector3(-3.2, 0.05, 2.4)
	var head2: Node3D = player.get_node("Head")
	head2.look_at(Vector3(-7.2, 1.2, 2.4), Vector3.UP)
	for _i in 12:
		RenderingServer.force_draw()
		await process_frame
	var img401 := root.get_viewport().get_texture().get_image()
	if img401:
		img401.save_png("/tmp/across-ep1-play/apt401_open.png")
	scene.call("inspect", "calendar", "calendar check")
	await process_frame
	if not bool(scene.get("overlap")):
		push_error("calendar did not start overlap")
		quit(2)
		return
	scene.call("play_tape", "401")
	# Ending waits ~6.8s on the tape before await_restart.
	for _i in 240:
		await process_frame
		if bool(scene.get("await_restart")):
			break
	if not bool(scene.get("await_restart")):
		push_error("ending did not settle")
		quit(3)
		return
	print("EP1_PLAY_OK phase=", scene.get("phase"), " chapter=", scene.get("chapter"))
	quit(0)
