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

	await _shot(campaign, player, Vector3(0, 0.05, 0.8), Vector3(0, 1.1, 8.0), "episode-2")
	campaign.call("perform_action", "ep2_tag")
	campaign.call("perform_action", "ep2_reset")
	await _shot(campaign, player, Vector3(1.8, 0.05, 6.2), Vector3(3.5, 1.25, 7.5), "episode-2-present")
	campaign.call("perform_action", "ep2_present")
	campaign.call("perform_action", "ep2_plate")
	campaign.call("perform_action", "ep2_elevator")
	await _shot(campaign, player, Vector3(-1.4, 0.05, 1.0), Vector3(-2.4, 1.1, 3.0), "episode-3")
	campaign.call("perform_action", "ep3_lift")
	campaign.call("perform_action", "ep3_fuse")
	campaign.call("perform_action", "ep3_archive")
	campaign.call("perform_action", "ep3_recording")
	campaign.call("perform_action", "ep3_hall")
	await _shot(campaign, player, Vector3(0, 0.05, 10.2), Vector3(0.8, 1.2, 12.4), "episode-3-tenant")
	campaign.call("start_episode", 4)
	await _shot(campaign, player, Vector3(0, 0.05, 0.6), Vector3(0, 1.0, 4.5), "episode-4")
	campaign.call("perform_action", "ep4_vacancy")
	campaign.call("perform_action", "ep4_noise")
	campaign.call("perform_action", "ep4_duplicate")
	await _shot(campaign, player, Vector3(0, 0.05, 3.8), Vector3(0, 1.1, 6.2), "episode-4-stamps")
	campaign.call("start_episode", 5)
	await _shot(campaign, player, Vector3(0, 0.05, 2.0), Vector3(0, 1.1, 9.0), "episode-5")
	print("FULL_SHOTS_OK")
	quit(0)

func _shot(campaign: Node, player: Node3D, pos: Vector3, look_at: Vector3, name: String) -> void:
	player.locked = true
	player.global_position = pos
	player.rotation = Vector3.ZERO
	var head: Node3D = player.get_node("Head")
	head.rotation = Vector3.ZERO
	head.look_at(look_at, Vector3.UP)
	for _frame in 14:
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
