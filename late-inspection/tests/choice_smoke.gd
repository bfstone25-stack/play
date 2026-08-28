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
	game.open_choice(
		"stay_or_leave",
		"The lease says the inspection ends at midnight.",
		"Stay overnight and finish the checklist",
		"Leave the key on the table and walk out",
		null
	)
	await process_frame
	await process_frame
	if not hud.choice_panel or not hud.choice_panel.visible:
		push_error("choice panel not visible")
		quit(2)
		return
	hud._pick(1)
	await process_frame
	await process_frame
	if not game.ending:
		push_error("expected ending after leave choice")
		quit(3)
		return
	print("CHOICE_SMOKE_OK ending=", game.ending, " stay=", game.flags["choice_stay"])
	quit(0)
