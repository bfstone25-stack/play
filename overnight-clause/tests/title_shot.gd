## title_shot.gd — photograph the title screen and prove it is alive.
##
##   DISPLAY=:0 godot --path . --resolution 1280x720 -s res://tests/title_shot.gd
##
## This title is the game's own 3D corridor with a slow dolly on it, so the moving-frames
## check below is also the check that the dolly is running.
##
## The other shot tests photograph plates. This one photographs the first second of the
## game, which is the thing ops/adult_forks/TITLE_SCREENS.md is about. Two frames are
## taken 1.2 s apart: if they are byte-identical then the rain is not falling, the tube is
## not flickering and the camera is not breathing, and a still that draws is still a
## failure of this pass.
extends SceneTree

const OUT := "user://shots"


func _init() -> void:
	call_deferred("_run")


func _shot(name: String) -> Image:
	for _f in 3:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("  shot %s %dx%d" % [name, img.get_width(), img.get_height()])
	return img


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var hud: Node = game.get_node("HUD")
	if not hud.splash.visible:
		hud.splash.visible = true
	# The 3D camera is built deferred; give it a frame to stand up before the beat.
	await process_frame
	await process_frame
	if hud.title_screen:
		hud.title_screen.play_in()

	await _wait(1900)
	var a := await _shot("title_00")
	await _wait(1200)
	var b := await _shot("title_01")

	if hud.title_screen == null:
		push_error("no title screen built")
		quit(1)
		return
	if hud.title_screen.get_node_or_null("KeyVisual") == null \
			or hud.title_screen.get_node("KeyVisual").texture == null:
		push_error("no key visual on the title screen")
		quit(1)
		return
	if hud.title_screen.get_node("Logotype").texture == null:
		push_error("no logotype on the title screen")
		quit(1)
		return
	if a.get_data() == b.get_data():
		push_error("the title screen is a still: two frames 1.2 s apart are identical")
		quit(1)
		return
	print("TITLE_SHOT_OK moving=true")
	quit(0)
