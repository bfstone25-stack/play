extends SceneTree

const OUT := "res://build/playtest"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var packed := load("res://scenes/full_campaign.tscn")
	var campaign: Node = packed.instantiate()
	root.add_child(campaign)
	await process_frame
	await process_frame
	var player: Node3D = campaign.get_node("Player")
	campaign.call("start_episode", 2)
	await _look(campaign, player, Vector3(0.7, 0.9, 2.2), "ep2_start")
	campaign.call("perform_action", "ep2_tag")
	campaign.call("perform_action", "ep2_reset")
	await _look(campaign, player, Vector3(2.6, 1.1, 7.2), "ep2_present")
	campaign.call("perform_action", "ep2_present")
	campaign.call("perform_action", "ep2_plate")
	campaign.call("perform_action", "ep2_elevator")
	await _look(campaign, player, Vector3(0, 1.1, 3.4), "ep3_circuits")
	campaign.call("perform_action", "ep3_lift")
	campaign.call("perform_action", "ep3_fuse")
	campaign.call("perform_action", "ep3_archive")
	campaign.call("perform_action", "ep3_recording")
	campaign.call("perform_action", "ep3_hall")
	await _look(campaign, player, Vector3(0.4, 1.2, 10.4), "ep3_tenant")
	campaign.call("perform_action", "ep3_key")
	campaign.call("perform_action", "ep3_stairs")
	await _look(campaign, player, Vector3(0, 1.1, 3.8), "ep4_stamps")
	campaign.call("perform_action", "ep4_vacancy")
	campaign.call("perform_action", "ep4_noise")
	campaign.call("perform_action", "ep4_duplicate")
	campaign.call("perform_action", "ep4_return")
	campaign.call("perform_action", "ep4_retain")
	campaign.call("perform_action", "ep4_remove")
	campaign.call("perform_action", "ep4_plate")
	campaign.call("perform_action", "ep4_stairs")
	await _look(campaign, player, Vector3(0, 1.15, 9.2), "ep5_directory")
	campaign.call("perform_action", "ep5_elevator")
	campaign.call("perform_action", "ep5_mailbox")
	campaign.call("perform_action", "ep5_exterior")
	campaign.call("perform_action", "ep5_occupant")
	await _look(campaign, player, Vector3(0, 1.2, 12.2), "ep5_ending")
	print("PLAY_WALK_OK shots=6")
	quit(0)

func _look(campaign: Node, player: Node3D, look_at: Vector3, name: String) -> void:
	player.locked = true
	var head: Node3D = player.get_node("Head")
	head.look_at(look_at, Vector3.UP)
	for _i in 10:
		RenderingServer.force_draw()
		await process_frame
	var texture := player.get_node("Head/Camera3D").get_viewport().get_texture()
	if texture:
		var image := texture.get_image()
		if image:
			image.save_png(ProjectSettings.globalize_path(OUT + "/" + name + ".png"))
	player.locked = false
