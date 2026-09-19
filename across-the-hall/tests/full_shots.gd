extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/full_campaign.tscn")
	if packed == null:
		push_error("full_campaign.tscn failed")
		quit(1)
		return
	var campaign: Node = packed.instantiate()
	root.add_child(campaign)
	await process_frame
	await process_frame
	var player: Node3D = campaign.get_node("Player")
	player.locked = true
	var camera := player.get_node("Head/Camera3D") as Camera3D
	camera.current = true
	DirAccess.make_dir_recursive_absolute("/tmp/across-full-shots")
	for episode in [2, 3, 4, 5]:
		campaign.call("start_episode", episode)
		player.locked = true
		player.global_position = Vector3(0, 0.05, 0.4)
		var head: Node3D = player.get_node("Head")
		head.rotation = Vector3.ZERO
		head.look_at(Vector3(0, 1.1, 9.0), Vector3.UP)
		for frame in 16:
			RenderingServer.force_draw()
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		if image == null:
			push_error("Episode %d frame capture failed" % episode)
			quit(episode)
			return
		var path := "/tmp/across-full-shots/episode-%d.png" % episode
		image.save_png(path)
		print("FULL_SHOT ", path, " ", image.get_width(), "x", image.get_height())
	print("FULL_SHOTS_OK")
	quit(0)
