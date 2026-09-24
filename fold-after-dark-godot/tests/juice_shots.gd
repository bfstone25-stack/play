## juice_shots.gd — photograph the feel pass in a real window (2026-09-23).
##
##   JUICE_SHOTS_OUT=/abs/dir SHOW_GAME=1 ops/on_game_monitor.sh \
##       ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path play/fold-after-dark-godot -s res://tests/juice_shots.gd
##
## Drives itself (no pointer, no focus needed): a combo run on level 80, its results card
## counting up, Coco's bubble, then level 5 -> trophy -> Unlock -> the scene. Frames are the
## engine's own viewport, so no compositor screenshot is involved. The save file is copied
## first and put back at the end.
extends SceneTree

var out := ""
var game: Node

func _init() -> void:
	call_deferred("_run")

func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame

func snap(name: String) -> void:
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("SHOT ", name)

func open(lv: int) -> void:
	if game != null:
		game.queue_free()
		await process_frame
	var done: Dictionary = root.get_node("Save").get_v("fold_done", {})
	done.erase(str(lv))
	root.get_node("Save").set_v("fold_done", done)
	game = load("res://scenes/game.tscn").instantiate()
	game.set("start_level", lv)
	root.add_child(game)
	current_scene = game

func play(moves: String, gap_ms: int, tag: String) -> void:
	var dirs := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
	var k := 0
	for ch in moves:
		var d: Vector2i = dirs[ch]
		root.get_node("Fold").move(d.x, d.y)
		k += 1
		await _wait(90)
		await snap("%s_move%d_a" % [tag, k])
		await _wait(150)
		await snap("%s_move%d_b" % [tag, k])
		await _wait(gap_ms)

func _run() -> void:
	out = OS.get_environment("JUICE_SHOTS_OUT")
	if out == "":
		out = "user://juice_shots"
	DirAccess.make_dir_recursive_absolute(out)
	var sp := "user://fold_after_dark_save.json"
	var saved := FileAccess.get_file_as_bytes(sp) if FileAccess.file_exists(sp) else PackedByteArray()
	root.get_node("Save").set_v("coco_day", "")
	root.get_node("Juice").reduced_motion = false

	# A. level 80, the combo goal's witness: five merging folds in a row (x2 .. x5)
	await open(79)
	await _wait(350)
	await snap("01_level_start_card")
	await _wait(1300)
	await play("DRULU", 600, "02_combo")
	# B. the results card as it pays out
	for ms in [250, 350, 400, 450, 500, 600]:
		await _wait(ms)
		await snap("03_results_%04d" % ms)
	await _wait(1500)
	# C. level 5: the end of tier 1 -> trophy -> Unlock -> the scene, and Coco on it
	await open(4)
	await _wait(1600)
	var sol := "DRUL"
	var fr = load("res://tests/solutions.json")
	var sols: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/solutions.json"))
	var dirs: Array = sols["4"]["dirs"]
	for d in dirs:
		root.get_node("Fold").move(int(d[0]), int(d[1]))
		await _wait(450)
	await _wait(1200)
	await snap("04_results_tier_end")
	await _wait(3200)
	await snap("05_trophy")
	var win: Control = game.get("_win")
	var b := win.find_child("Unlock", true, false) as Button
	if b != null:
		b.pressed.emit()
	await _wait(900)
	await snap("06_scene_unlocked")
	await _wait(1500)
	await snap("07_scene_unlocked_later")
	if saved.size() > 0:
		var f := FileAccess.open(sp, FileAccess.WRITE)
		f.store_buffer(saved)
		f.close()
	print("JUICE_SHOTS_OK ", out)
	quit(0)
