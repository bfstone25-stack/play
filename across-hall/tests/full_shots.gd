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
	await _shot(campaign, player, 2, Vector3(0, 1.1, 9.0), "episode-2")
	campaign.call("perform_action", "ep2_tag")
	campaign.call("perform_action", "ep2_reset")
	player.global_position = Vector3(2.2, 0.05, 6.6)
	await _shot(campaign, player, 2, Vector3(3.35, 1.2, 7.5), "episode-2-present")
	campaign.call("start_episode", 3)
	await _shot(campaign, player, 3, Vector3(0, 1.1, 9.0), "episode-3")
	campaign.call("perform_action", "ep3_lift")
	campaign.call("perform_action", "ep3_fuse")
	campaign.call("perform_action", "ep3_archive")
	campaign.call("perform_action", "ep3_recording")
	campaign.call("perform_action", "ep3_hall")
	player.global_position = Vector3(0, 0.05, 9.4)
	await _shot(campaign, player, 3, Vector3(0.8, 1.2, 11.1), "episode-3-tenant")
	await _shot(campaign, player, 4, Vector3(0, 1.1, 9.0), "episode-4")
	await _shot(campaign, player, 5, Vector3(0, 1.1, 9.0), "episode-5")
	print("FULL_SHOTS_OK")
	quit(0)

func _shot(campaign: Node, player: Node3D, episode: int, look_at: Vector3, name: String) -> void:
	if int(campaign.get("episode")) != episode:
		campaign.call("start_episode", episode)
	player.locked = true
	if look_at.z > 8.5 and player.global_position.z < 1.0:
		player.global_position = Vector3(0, 0.05, 0.4)
	var head: Node3D = player.get_node("Head")
	head.rotation = Vector3.ZERO
	head.look_at(look_at, Vector3.UP)
	for _frame in 16:
		RenderingServer.force_draw()
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("%s frame capture failed" % name)
		quit(2)
		return
	var path := "/tmp/across-full-shots/%s.png" % name
	image.save_png(path)
	print("FULL_SHOT ", path, " ", image.get_width(), "x", image.get_height())
