extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/full_campaign.tscn")
	if packed == null:
		_fail("full_campaign.tscn failed to load", 1)
		return
	var campaign: Node = packed.instantiate()
	if campaign.get_script() == null or not campaign.has_method("perform_action"):
		_fail("full_campaign.tscn instantiated without its campaign script", 2)
		return
	root.add_child(campaign)
	await process_frame
	await process_frame
	campaign.call("start_episode", 2)
	if int(campaign.get("episode")) != 2:
		_fail("campaign did not start at Episode II", 3)
		return

	# Episode II: one anchored item survives the reset.
	campaign.call("perform_action", "ep2_elevator")
	if int(campaign.get("episode")) != 2:
		_fail("Episode II gate skipped", 4)
		return
	campaign.call("perform_action", "ep2_tag")
	campaign.call("perform_action", "ep2_reset")
	campaign.call("perform_action", "ep2_present")
	campaign.call("perform_action", "ep2_plate")
	campaign.call("perform_action", "ep2_elevator")
	if int(campaign.get("episode")) != 3:
		_fail("Episode II did not advance", 5)
		return

	# Episode III: only the powered circuit exposes its resource.
	campaign.call("perform_action", "ep3_archive")
	if campaign.get("flags").get("circuit", "") == "archive":
		_fail("Archive powered without fuse", 6)
		return
	campaign.call("perform_action", "ep3_lift")
	campaign.call("perform_action", "ep3_fuse")
	campaign.call("perform_action", "ep3_archive")
	campaign.call("perform_action", "ep3_recording")
	campaign.call("perform_action", "ep3_hall")
	campaign.call("perform_action", "ep3_key")
	campaign.call("perform_action", "ep3_stairs")
	if int(campaign.get("episode")) != 4:
		_fail("Episode III did not advance", 7)
		return

	# Episode IV: a wrong stamp does not consume the current complaint.
	campaign.call("perform_action", "ep4_vacancy")
	campaign.call("perform_action", "ep4_noise")
	campaign.call("perform_action", "ep4_duplicate")
	campaign.call("perform_action", "ep4_remove")
	if int(campaign.get("_stamp_index")) != 0:
		_fail("Wrong stamp advanced filing", 8)
		return
	campaign.call("perform_action", "ep4_return")
	campaign.call("perform_action", "ep4_retain")
	campaign.call("perform_action", "ep4_remove")
	campaign.call("perform_action", "ep4_plate")
	campaign.call("perform_action", "ep4_stairs")
	if int(campaign.get("episode")) != 5:
		_fail("Episode IV did not advance", 9)
		return

	# Episode V: all three memories are required before the final designation.
	campaign.call("perform_action", "ep5_occupant")
	if bool(campaign.get("campaign_complete")):
		_fail("Episode V ended before memories", 10)
		return
	campaign.call("perform_action", "ep5_elevator")
	campaign.call("perform_action", "ep5_mailbox")
	campaign.call("perform_action", "ep5_exterior")
	campaign.call("perform_action", "ep5_occupant")
	if not bool(campaign.get("campaign_complete")):
		_fail("OCCUPANT ending did not complete", 11)
		return
	if str(campaign.get("final_choice")) != "OCCUPANT":
		_fail("OCCUPANT ending choice missing", 12)
		return
	var clock: Label = campaign.get_node("HUD").get("clock")
	if clock.text != "02:18":
		_fail("Final clock did not advance", 13)
		return

	# The alternate final designation converges on the same campaign ending.
	root.remove_child(campaign)
	campaign.queue_free()
	var alternate: Node = packed.instantiate()
	root.add_child(alternate)
	await process_frame
	await process_frame
	alternate.call("start_episode", 5)
	alternate.call("perform_action", "ep5_elevator")
	alternate.call("perform_action", "ep5_mailbox")
	alternate.call("perform_action", "ep5_exterior")
	alternate.call("perform_action", "ep5_door")
	if (
		not bool(alternate.get("campaign_complete"))
		or str(alternate.get("final_choice")) != "DOOR"
	):
		_fail("DOOR ending did not converge", 14)
		return

	print("FULL_CAMPAIGN_OK episodes=2-5 final_clock=02:18 choices=2")
	quit(0)

func _fail(message: String, code: int) -> void:
	push_error(message)
	quit(code)
