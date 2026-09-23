## title_shot.gd — photograph the title cheaply. Added 2026-09-23 in the title pass.
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
	await _wait(3000)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + "/title_en_00.png")
	print("TITLE_SHOT_OK %dx%d" % [img.get_width(), img.get_height()])
	quit(0)
