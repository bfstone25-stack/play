extends SceneTree

## Prove the animation is actually moving, and give something to look at while judging it.
##
## The rest of the tests assert rules. This one exists because the 2026-09-18 art pass
## added motion that no assertion can see: a breath is one pixel, a lamp flicker is a few
## percent of brightness, and both are exactly the kind of thing that can be switched off
## by a typo while every test still passes. So it captures a run of frames spaced in real
## time, writes them as a filmstrip, and reports how many pixels changed between them.
##
##   $GODOT -s res://tests/motion.gd        # needs a display; writes to user://motion/
##
## A frame-to-frame difference of zero on the shop means the room is a still picture and
## something is broken, and the script fails on it rather than printing a filmstrip nobody
## looks at.

const FRAMES := 8
const GAP := 14          # process frames between captures, ~0.23s at 60fps

var out_dir := "user://motion"
var game: Node


func _init() -> void:
	call_deferred("_run")


func _settle(n: int) -> void:
	for i in range(n):
		await process_frame


func _capture(tag: String) -> int:
	## Returns the number of pixels that changed across the run.
	var shots: Array[Image] = []
	for i in range(FRAMES):
		await _settle(GAP)
		shots.append(root.get_texture().get_image())
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var strip := Image.create(w * FRAMES / 2, h / 2 * 1, false, Image.FORMAT_RGBA8)
	var changed := 0
	for i in range(FRAMES):
		var half := shots[i].duplicate()
		half.resize(w / 2, h / 2, Image.INTERPOLATE_NEAREST)
		strip.blit_rect(half, Rect2i(0, 0, w / 2, h / 2), Vector2i(i * w / 2, 0))
		if i > 0:
			for y in range(0, h, 4):          # every fourth row: this is a smoke test
				for x in range(0, w, 4):
					if shots[i].get_pixel(x, y) != shots[i - 1].get_pixel(x, y):
						changed += 1
	strip.save_png("%s/%s.png" % [out_dir, tag])
	print("  %-16s %d frames, %d sampled pixels changed" % [tag, FRAMES, changed])
	return changed


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	# The shop, with a client at the counter and an object on it — everything the stage
	# animates at once: breath, hair, hem, lamp, rain, dust.
	game.plates.hide_plate()
	game.stage.set_scene("shop")
	game.stage.set_customer("tamsin")
	game.stage.set_counter_item("finial")
	var shop := await _capture("shop")

	# A plate, which moves through the treatment shader instead: the whole-pixel waver,
	# the lamp flicker and the read band travelling up the frame.
	game.plates.show_plate("cg_finial")
	var plate := await _capture("plate_finial")

	var bad := 0
	if shop < 200:
		push_error("the shop is not moving (%d changed pixels)" % shop)
		bad += 1
	if plate < 200:
		push_error("the plate treatment is not moving (%d changed pixels)" % plate)
		bad += 1
	print("MOTION_OK" if bad == 0 else "MOTION_FAIL")
	quit(bad)
