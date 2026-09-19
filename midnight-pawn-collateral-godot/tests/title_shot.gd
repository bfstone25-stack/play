extends SceneTree

## Render the title screen and prove it is on the screen.
##
## The splash only builds itself under OS.has_feature("web"), so this calls it directly —
## the point is the composition, not the platform gate. Two frames are captured a second
## apart, because half of what this pass added is motion: if 00 and 01 are byte-identical
## the lamps are not breathing, the dust is not moving and the mark is not settling, and
## that is a failure even though something drew.
##
##   $GODOT --path . --resolution 1280x720 -s res://tests/title_shot.gd
##
## Run it under xvfb-run; it writes PNGs to user://shots.

var out_dir := "user://shots"
var game: Node


func _init() -> void:
	call_deferred("_run")


func _shot(name: String) -> Image:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("  shot %s %dx%d" % [name, img.get_width(), img.get_height()])
	return img


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._show_splash()
	await process_frame

	# A beat, so the mark has settled before the first frame is taken.
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1800:
		await process_frame
	var a := await _shot("title_00")

	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1200:
		await process_frame
	var b := await _shot("title_01")

	if game.title_screen == null:
		push_error("no title screen built")
		quit(1)
		return
	if game.title_screen.get_node_or_null("KeyVisual") == null:
		push_error("no key visual on the title screen")
		quit(1)
		return
	if a.get_data() == b.get_data():
		push_error("the title screen is a still: two frames 1.2 s apart are identical")
		quit(1)
		return
	print("TITLE_SHOT_OK moving=true")
	quit(0)
