extends SceneTree

func _init() -> void:
	if not OS.has_feature("full_game"):
		print("FULL_ENTRY_SKIPPED no full_game export feature")
		quit(0)
		return
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		_fail("main.tscn missing from full build", 1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.call("give_item", "flashlight")
	game.call("give_item", "note")
	game.call("give_item", "tape")
	game.call("give_item", "key")
	game.call("open_401")
	game.call("inspect", "calendar", "test")
	game.call("play_tape", "401")
	await create_timer(7.0).timeout
	var prompt: Label = game.get_node("HUD/Prompt")
	if "N next floor" not in prompt.text:
		_fail("full build ending does not expose next-floor action", 2)
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_N
	game.call("_unhandled_input", event)
	await process_frame
	await process_frame
	if root.get_node_or_null("Campaign") == null:
		_fail("N did not load the paid campaign", 3)
		return
	print("FULL_ENTRY_OK Episode I -> Episode II")
	quit(0)

func _fail(message: String, code: int) -> void:
	push_error(message)
	quit(code)
