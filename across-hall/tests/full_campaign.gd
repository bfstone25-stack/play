extends SceneTree

#region agent log
func _agent_log(message: String, data: Dictionary, hypothesis_id: String) -> void:
	var path := "/opt/cursor/logs/debug.log"
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify({
			"hypothesisId": hypothesis_id,
			"location": "tests/full_campaign.gd",
			"message": message,
			"data": data,
			"timestamp": Time.get_unix_time_from_system() * 1000.0,
		}))
#endregion

func _init() -> void:
	#region agent log
	_agent_log("test init entered", {}, "A")
	#endregion
	var packed := load("res://scenes/full_campaign.tscn")
	#region agent log
	_agent_log("scene load returned", {"loaded": packed != null}, "A")
	#endregion
	if packed == null:
		_fail("full_campaign.tscn failed to load", 1)
		return
	var campaign: Node = packed.instantiate()
	#region agent log
	_agent_log("scene instantiate returned; entering tree next", {"campaign_valid": is_instance_valid(campaign)}, "B")
	#endregion
	root.add_child(campaign)
	#region agent log
	_agent_log("root add_child returned", {"inside_tree": campaign.is_inside_tree(), "episode": campaign.get("episode")}, "B")
	#endregion
	await process_frame
	await process_frame
	if int(campaign.get("episode")) != 2:
		_fail("campaign did not start at Episode II", 2)
		return

	# Episode II: one anchored item survives the reset.
	campaign.call("perform_action", "ep2_elevator")
	if int(campaign.get("episode")) != 2:
		_fail("Episode II gate skipped", 3)
		return
	campaign.call("perform_action", "ep2_tag")
	campaign.call("perform_action", "ep2_reset")
	campaign.call("perform_action", "ep2_present")
	campaign.call("perform_action", "ep2_plate")
	campaign.call("perform_action", "ep2_elevator")
	if int(campaign.get("episode")) != 3:
		_fail("Episode II did not advance", 4)
		return

	# Episode III: only the powered circuit exposes its resource.
	campaign.call("perform_action", "ep3_archive")
	if campaign.get("flags").get("circuit", "") == "archive":
		_fail("Archive powered without fuse", 5)
		return
	campaign.call("perform_action", "ep3_lift")
	campaign.call("perform_action", "ep3_fuse")
	campaign.call("perform_action", "ep3_archive")
	campaign.call("perform_action", "ep3_recording")
	campaign.call("perform_action", "ep3_hall")
	campaign.call("perform_action", "ep3_key")
	campaign.call("perform_action", "ep3_stairs")
	if int(campaign.get("episode")) != 4:
		_fail("Episode III did not advance", 6)
		return

	# Episode IV: a wrong stamp does not consume the current complaint.
	campaign.call("perform_action", "ep4_vacancy")
	campaign.call("perform_action", "ep4_noise")
	campaign.call("perform_action", "ep4_duplicate")
	campaign.call("perform_action", "ep4_remove")
	if int(campaign.get("_stamp_index")) != 0:
		_fail("Wrong stamp advanced filing", 7)
		return
	campaign.call("perform_action", "ep4_return")
	campaign.call("perform_action", "ep4_retain")
	campaign.call("perform_action", "ep4_remove")
	campaign.call("perform_action", "ep4_plate")
	campaign.call("perform_action", "ep4_stairs")
	if int(campaign.get("episode")) != 5:
		_fail("Episode IV did not advance", 8)
		return

	# Episode V: all three memories are required before the final designation.
	campaign.call("perform_action", "ep5_occupant")
	if bool(campaign.get("campaign_complete")):
		_fail("Episode V ended before memories", 9)
		return
	campaign.call("perform_action", "ep5_elevator")
	campaign.call("perform_action", "ep5_mailbox")
	campaign.call("perform_action", "ep5_exterior")
	campaign.call("perform_action", "ep5_occupant")
	if not bool(campaign.get("campaign_complete")):
		_fail("OCCUPANT ending did not complete", 10)
		return
	if str(campaign.get("final_choice")) != "OCCUPANT":
		_fail("OCCUPANT ending choice missing", 11)
		return
	var clock: Label = campaign.get_node("HUD").get("clock")
	if clock.text != "02:18":
		_fail("Final clock did not advance", 12)
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
		_fail("DOOR ending did not converge", 13)
		return

	print("FULL_CAMPAIGN_OK episodes=2-5 final_clock=02:18 choices=2")
	quit(0)

func _fail(message: String, code: int) -> void:
	push_error(message)
	quit(code)
