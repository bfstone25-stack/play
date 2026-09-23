## title_shot.gd — photograph the title screen.
##
##   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/title_shot.gd
##
## Written 2026-09-22 during the title pass. tests/shots.gd hides the HUD and walks the
## corridor, so this game had no way to photograph its own first second — which is how a
## title can be wrong for weeks without anything failing.
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
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await _wait(2200)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + "/title_en_00.png")
	print("shot title_en_00 %dx%d" % [img.get_width(), img.get_height()])
	await _wait(900)
	var b := root.get_viewport().get_texture().get_image()
	b.save_png(OUT + "/title_en_01.png")
	if img.get_data() == b.get_data():
		push_error("the title screen is a still: two frames 0.9 s apart are identical")
		quit(1)
		return
	print("TITLE_SHOT_OK moving=true")
	quit(0)
