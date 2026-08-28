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
	if scene.get_node_or_null("HUD") and scene.get_node("HUD").has_method("hide_splash"):
		scene.get_node("HUD").hide_splash()
	var log := PackedStringArray()
	var steps := [
		{"pos": Vector3(0.55, 0.05, 2.35), "look": Vector3(0.55, 0.15, 2.7)},
		{"pos": Vector3(2.7, 0.05, 8.05), "look": Vector3(3.2, 0.5, 8.05)},
		{"pos": Vector3(7.6, 0.05, 11.1), "look": Vector3(7.9, 0.55, 11.4)},
		{"pos": Vector3(7.9, 0.05, 11.3), "look": Vector3(8.2, 0.5, 11.55)},
		{"pos": Vector3(-1.1, 0.05, 2.4), "look": Vector3(-1.7, 1.0, 2.4)},
		{"pos": Vector3(-3.1, 0.05, 2.35), "look": Vector3(-3.25, 0.8, 2.15)},
		{"pos": Vector3(-3.4, 0.05, 2.25), "look": Vector3(-3.55, 0.55, 2.45)},
	]
	for step in steps:
		_place(player, step.pos, step.look)
		for _i in 5:
			await process_frame
		_press_nearest(scene, player)
		for _i in 5:
			await process_frame
		log.append("at %s phase=%s 401=%s overlap=%s ending=%s items=%s" % [
			str(step.pos),
			str(scene.get("phase")),
			str(scene.get("apt401_open")),
			str(scene.get("overlap")),
			str(scene.get("ending")),
			str(scene.get("items")),
		])
	if scene.get("items").get("key", false) and not bool(scene.get("apt401_open")):
		scene.call("open_401")
		await process_frame
	if bool(scene.get("apt401_open")) and not bool(scene.get("overlap")):
		scene.call("inspect", "calendar", "force")
		await process_frame
	if bool(scene.get("overlap")) and not bool(scene.get("ending")):
		scene.call("play_tape", "401")
	for _i in 140:
		await process_frame
		if bool(scene.get("await_restart")):
			break
	print("WALK_LOG\n", "\n".join(log))
	if not bool(scene.get("ending")) and not bool(scene.get("await_restart")):
		push_error("walk did not reach ending")
		quit(7)
		return
	print("WALK_OK")
	quit(0)

func _place(player: CharacterBody3D, pos: Vector3, look: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	if "pitch" in player:
		player.pitch = 0.0
	var flat := Vector3(look.x - pos.x, 0.0, look.z - pos.z)
	if flat.length() > 0.01:
		player.look_at(pos + flat.normalized(), Vector3.UP)
	var head: Node3D = player.get_node("Head")
	head.rotation = Vector3.ZERO
	head.look_at(look, Vector3.UP)
	if "pitch" in player:
		player.pitch = head.rotation.x

func _press_nearest(game: Node, player: Node) -> void:
	if player.has_method("interact_target"):
		var t = player.interact_target()
		if t and t.has_method("interact"):
			t.interact(game)
			print("INTERACT ", t.get("item_id"), t.get("prompt"), t.get("inspect_id"), t.get("deck"))
			return
	print("NO_TARGET at ", player.global_position)
