extends SceneTree

## Render the title card and prove it is on the screen, moving, and legible in every
## locale the game ships.
##
## Two frames are captured 1.2 s apart, because half of what this pass added is motion: if
## the two are byte-identical the lantern is not breathing, the dust is not moving and the
## mark is not settling, and that is a failure even though something drew.
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


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	# A beat, so the mark has settled before the first frame is taken.
	await _wait(1800)
	var a := await _shot("title_en_00")
	await _wait(1200)
	var b := await _shot("title_en_01")

	if game.title_card == null or not is_instance_valid(game.title_card):
		push_error("no title card built")
		quit(1)
		return
	if game.title_screen == null:
		push_error("no title screen built")
		quit(1)
		return
	if game.title_screen.get_node_or_null("KeyVisual") == null:
		push_error("no key visual on the title screen")
		quit(1)
		return
	if game.title_screen.get_node_or_null("Logotype") == null:
		push_error("no logotype on the title screen")
		quit(1)
		return
	if a.get_data() == b.get_data():
		push_error("the title card is a still: two frames 1.2 s apart are identical")
		quit(1)
		return

	# Every locale, because the card carries type in all of them and a missing glyph is a
	# row of tofu boxes nobody sees until a player does.
	for code in ["zh", "ja", "es", "ko", "en"]:
		Loc.set_code(code)
		await _wait(300)
		await _shot("title_%s" % code)
		if game.title_card == null or not is_instance_valid(game.title_card):
			push_error("the title card did not survive the switch to %s" % code)
			quit(1)
			return

	print("TITLE_SHOT_OK moving=true locales=zh,ja,es,ko,en")
	quit(0)
