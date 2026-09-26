extends SceneTree
## zone_shots.gd — one frame from inside each of the six zones, from the player's camera.
##
##   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/zone_shots.gd
##
## Added 2026-09-26. The browser driver cannot steer this build (pointer lock turns clicks
## into look-deltas) and the only in-game frames on disk predated the 2026-09-21 lamp fix,
## so the "one colour" PUNCHLIST row could not be judged. This puts the camera in each
## room facing its zone label and photographs it; the flashlight is switched off so the
## frame shows the room's own lamps, which is what the row is about.

const OUT := "user://shots"
const ZONES := [Vector3(-5.2, 2.42, 2.0), Vector3(-1.0, 2.42, 6.5), Vector3(4.4, 2.42, 0.4),
	Vector3(9.4, 2.42, 0.32), Vector3(9.4, 2.42, 9.05), Vector3(4.5, 2.42, 9.78)]
const CENTRE := Vector3(2.0, 0.0, 5.0)


func _init() -> void:
	call_deferred("_run")


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _wait(1500)
	var hud = game.get("hud")
	if hud:
		hud.call("hide_splash")
		if hud.has_method("hide_title"):
			hud.hide_title()
	var player: Node3D = game.get("player")
	player.set_physics_process(false)
	player.set_process(false)
	var cam: Camera3D = player.get_node("Head/Camera3D")
	var torch = cam.get_node_or_null("Flashlight")
	if torch:
		torch.visible = false
	for i in ZONES.size():
		var label: Vector3 = ZONES[i]
		var flat := Vector3(label.x, 0, label.z)
		var dir := (CENTRE - flat).normalized()
		player.global_position = flat + dir * 2.6
		cam.look_at(Vector3(label.x, 1.3, label.z), Vector3.UP)
		await _wait(700)
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/zone_%d.png" % [OUT, i])
		print("shot zone_%d" % i)
	print("ZONE_SHOTS_OK")
	quit(0)
