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
	var game := scene
	if not game.has_method("give_item"):
		push_error("game missing give_item")
		quit(2)
		return
	game.call("give_item", "flashlight")
	game.call("give_item", "note")
	game.call("give_item", "tape")
	game.call("give_item", "key")
	if int(game.get("phase")) < 4:
		push_error("phase did not advance")
		quit(3)
		return
	game.call("open_401")
	if not bool(game.get("apt401_open")):
		push_error("401 did not open")
		quit(4)
		return
	game.call("inspect", "calendar", "test")
	if not bool(game.get("overlap")):
		push_error("overlap did not start")
		quit(5)
		return
	game.call("play_tape", "401")
	await process_frame
	if not bool(game.get("ending")):
		push_error("ending did not start")
		quit(6)
		return
	print("CHAPTERS_OK phase=", game.get("phase"), " chapter=", game.get("chapter"))
	quit(0)
