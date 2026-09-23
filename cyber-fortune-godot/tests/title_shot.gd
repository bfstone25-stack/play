## title_shot.gd — photograph the home screen, which is this game's title.
##
##   xvfb-run -a godot --path . --resolution 720x1280 -s res://tests/title_shot.gd
##
## Added 2026-09-23 in the title pass. tests/headless_web.py drives the whole loop through
## Chromium, which is the right test for the loop and the wrong one for "what does the
## first frame look like": it needs a build, a server and a browser. This needs none.
extends SceneTree

const OUT := "user://shots"


func _init() -> void:
	call_deferred("_run")


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await _wait(2400)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + "/title_en_00.png")
	print("shot title_en_00 %dx%d" % [img.get_width(), img.get_height()])
	print("TITLE_SHOT_OK")
	quit(0)
