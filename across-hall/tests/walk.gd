extends SceneTree

## Walks the player through the five-chapter loop using interactables.

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var player: CharacterBody3D = scene.get_node("Player")
	player.locked = false
	var log := PackedStringArray()
	var steps := [
		{"pos": Vector3(0.55, 0.05, 2.6), "want": "flashlight"},
		{"pos": Vector3(3.05, 0.05, 8.05), "want": "note"},
		{"pos": Vector3(7.85, 0.05, 11.35), "want": "tape"},
		{"pos": Vector3(8.2, 0.05, 11.55), "want": "key"},
		{"pos": Vector3(-1.62, 0.05, 2.4), "want": "open"},
		{"pos": Vector3(-3.25, 0.05, 2.15), "want": "calendar"},
		{"pos": Vector3(-3.55, 0.05, 2.4), "want": "ending"},
	]
	for step in steps:
		player.global_position = step.pos
		player.velocity = Vector3.ZERO
		for _i in 4:
			await process_frame
		_press_nearest(scene, player)
		for _i in 3:
			await process_frame
		log.append("at %s phase=%s 401=%s overlap=%s ending=%s items=%s" % [
			str(step.pos),
			str(scene.get("phase")),
			str(scene.get("apt401_open")),
			str(scene.get("overlap")),
			str(scene.get("ending")),
			str(scene.get("items")),
		])
	print("WALK_LOG\n", "\n".join(log))
	if not bool(scene.get("ending")):
		push_error("walk did not reach ending")
		quit(7)
		return
	print("WALK_OK")
	quit(0)

func _press_nearest(game: Node, player: Node) -> void:
	if player.has_method("interact_target"):
		var t = player.interact_target()
		if t and t.has_method("interact"):
			t.interact(game)
			print("INTERACT ", t)
			return
	print("NO_TARGET at ", player.global_position)
