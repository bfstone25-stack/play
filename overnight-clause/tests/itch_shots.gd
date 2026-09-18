extends SceneTree

## Capture English 1280x720 screenshots for the itch page.
## Run: xvfb-run -a godot --path late-inspection -s res://tests/itch_shots.gd

const OUT := "/tmp/itch-shots/late"


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute(OUT)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s-%s.png" % [OUT, name])
	print("VISUAL ", name, " ", image.get_size())


func _close_story(hud: Node) -> void:
	var vn: Node = hud.vn
	var guard := 0
	while vn.is_open() and guard < 40:
		vn.advance(true)
		guard += 1
		await process_frame


func _view(game: Node, pos: Vector3, target: Vector3, pitch := -0.08) -> void:
	var player: Node3D = game.get_node("Player")
	player.velocity = Vector3.ZERO
	player.global_position = pos
	player.look_at(Vector3(target.x, pos.y, target.z))
	player.head.rotation.x = pitch
	await create_timer(0.35).timeout


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hud: Node = scene.get_node("HUD")
	Loc.set_code("en")
	await create_timer(1.0).timeout
	await _shot("title")

	hud.hide_splash()
	hud.hide_title()

	# World tour: lift lobby, corridor to 404, living room, kitchen, bathroom pipe.
	await _view(scene, Vector3(-5.2, 0.0, 6.4), Vector3(-5.8, 1.3, 1.4))
	await _shot("zone-lobby")
	await _view(scene, Vector3(-1.3, 0.0, 8.9), Vector3(1.08, 1.0, 4.0))
	await _shot("zone-corridor")
	await _view(scene, Vector3(1.9, 0.0, 5.4), Vector3(4.4, 0.7, 1.6), -0.12)
	await _shot("zone-living")
	await _view(scene, Vector3(6.0, 0.0, 2.6), Vector3(8.4, 0.8, 0.9), -0.10)
	await _shot("zone-kitchen")
	await _view(scene, Vector3(7.4, 0.0, 6.6), Vector3(9.4, 1.0, 6.0), -0.05)
	await _shot("zone-bathroom")
	await _view(scene, Vector3(3.4, 0.0, 9.4), Vector3(7.0, 0.8, 8.4), -0.10)
	await _shot("zone-bedroom")

	# UI chrome: ADV document, NVL page, two-button choice.
	await _view(scene, Vector3(-5.2, 0.0, 6.4), Vector3(-5.8, 1.3, 1.4))
	hud.show_story("order", Loc.t("beat.witness.1") + "\n---\n" + Loc.t("obj.0"), false, Callable())
	await create_timer(2.5).timeout
	hud.vn._snap_type()
	await _shot("adv")
	await _close_story(hud)

	hud.show_story("letters", Loc.t("beat.witness.0") + "\n---\n" + Loc.t("beat.404.2"), true, Callable())
	await create_timer(2.5).timeout
	hud.vn._snap_type()
	await _shot("nvl")
	await _close_story(hud)

	hud.open_choice(
		"The checklist camera reveals IRIS VALE — STILL HERE inside the hand-shaped stain. Keeping the image uploads Iris's name outside 404. Deleting it marks the kitchen dry and releases Pell's payment.",
		"Keep and upload the photograph",
		"Wipe the wall and delete it",
		Callable())
	await create_timer(0.6).timeout
	await _shot("choice")

	print("ITCH_SHOTS_OK")
	quit(0)


func _init() -> void:
	call_deferred("_run")
