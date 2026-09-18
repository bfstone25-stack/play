extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("main.tscn failed")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var game := scene
	var hud := scene.get_node("HUD")
	if hud.has_method("hide_splash"):
		hud.hide_splash()
	game.open_choice("stain", "IRIS VALE — STILL HERE", "Keep photograph", "Delete image", null)
	await process_frame
	await process_frame
	if not hud.choice_panel or not hud.choice_panel.visible:
		push_error("choice panel not visible")
		quit(2)
		return
	hud._pick(0)
	await process_frame
	await process_frame
	if not game.flags["photo_kept"]:
		push_error("expected stain choice to set evidence flag")
		quit(3)
		return
	# In this fork the stain choice plays cg_mirror + the bathroom scene, and the stage
	# advances when the scene ends. Walk the scene to its last page.
	if not hud.is_nvl_open():
		push_error("stain choice did not open the mirror scene")
		quit(3)
		return
	if hud.plates == null or hud.plates.current != "cg_mirror":
		push_error("mirror plate did not come up with the scene")
		quit(3)
		return
	var guard := 0
	while hud.is_vn_open() and guard < 400:
		hud.advance_vn()
		guard += 1
		await process_frame
	if game.stage != 5:
		push_error("expected stage 5 after the mirror scene, got %d" % game.stage)
		quit(3)
		return
	var ending_id: String = game.debug_complete_route("witness")
	if ending_id != "WITNESS":
		push_error("expected Witness route")
		quit(4)
		return
	print("CHOICE_SMOKE_OK choice_flag=", game.flags["photo_kept"], " plate=cg_mirror ending=", ending_id)
	quit(0)
