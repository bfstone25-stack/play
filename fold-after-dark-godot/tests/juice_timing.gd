extends Node
## How much wall time the juice adds to a level, measured in the real board (game.tscn).
##
##   godot --headless --path . res://tests/juice_timing.tscn
##
## Plays the shortest solution of 10 sample levels (tests/timing_solutions.json, made by
## ops/nutaku/fold_f2p/fold_rules.py solve()) with real Fold.move calls through the
## board's own signal handlers, and times three things per level:
##   * move_block: how long after a move the next move is refused (0 = never blocks);
##   * results: solve -> next board open, left alone (the results card auto-continues);
##   * results_tap: the same with one tap 0.25 s in and a second tap as soon as it
##     reaches its end state (a player who wants speed);
## and the same "left alone" figure under reduced motion. The pre-juice board waited a
## fixed 0.45 s here (scenes/game.gd before 2026-09-23), which the report subtracts.
## Prints one JSON line starting TIMING_JSON and exits.

const OLD_WAIT := 0.45
var game: Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# The board writes stars to the real save; keep a copy and put it back at the end, and
	# clear each sample level first so every run measures a FIRST clear (stars fly).
	var save_path := "user://fold_after_dark_save.json"
	var saved := FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	var sols: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/timing_solutions.json"))
	var rows := []
	for mode in ["alone", "tap", "reduced"]:
		Juice.reduced_motion = mode == "reduced"
		for k in sols.keys():
			var lv := int(k)
			var r := await _play(lv, str(sols[k]), mode)
			r["mode"] = mode
			rows.append(r)
			print("level %d  %-7s  results %.2fs  move_block %.3fs" % [lv + 1, mode, r["results"], r["move_block"]])
	print("TIMING_JSON " + JSON.stringify({"old_wait": OLD_WAIT, "rows": rows}))
	if saved.size() > 0:
		var f := FileAccess.open(save_path, FileAccess.WRITE)
		f.store_buffer(saved)
		f.close()
	get_tree().quit(0)


func _play(lv: int, sol: String, mode: String) -> Dictionary:
	if game != null:
		game.queue_free()
		await get_tree().process_frame
	var done: Dictionary = Save.get_v("fold_done", {})
	done.erase(str(lv))
	Save.set_v("fold_done", done)
	var scene: PackedScene = load("res://scenes/game.tscn")
	game = scene.instantiate()
	game.set("start_level", lv)
	get_tree().root.add_child(game)
	await _until(func(): return Fold.level_index == lv and not Fold.done and Fold.moves == 0)
	var block := 0.0
	var dirs := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
	for ch in sol:
		var d: Vector2i = dirs[ch]
		var t0 := Time.get_ticks_usec()
		# the board never gates Fold.move on an animation; measure that it did not start
		while Fold.move(d.x, d.y) < 0 and not Fold.done:
			await get_tree().process_frame
		block = maxf(block, (Time.get_ticks_usec() - t0) / 1e6)
		await get_tree().create_timer(0.12).timeout
	var t_solved := Time.get_ticks_usec()
	if mode == "tap":
		await get_tree().create_timer(0.25).timeout
		_tap()
		for _i in range(3):
			await get_tree().process_frame
		await _until(func(): return game.get("_results_skip") == false and game.get("_results_open") == true, 5.0)
		_tap()
	await _until(func(): return Fold.level_index == lv + 1 and not Fold.done, 15.0)
	var results := (Time.get_ticks_usec() - t_solved) / 1e6
	return {"level": lv + 1, "moves": sol.length(), "results": results, "move_block": block}


func _tap() -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = Vector2(640, 360)
	Input.parse_input_event(e)
	var u := e.duplicate()
	u.pressed = false
	Input.parse_input_event(u)


func _until(cond: Callable, timeout := 10.0) -> bool:
	var t := 0.0
	while t < timeout:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false
