extends Node
## Cost of one fold on the main thread, board and all (game.tscn's handlers included).
##   godot --headless --path . res://tests/move_bench.tscn   -> MOVE_BENCH <ms per move>
var game: Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	game.set("start_level", 130)
	get_tree().root.add_child(game)
	for _i in range(30):
		await get_tree().process_frame
	var n := 0
	var total := 0.0
	var worst := 0.0
	for k in range(40):
		var d: Vector2i = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)][k % 4]
		if Fold.done:
			break
		var t0 := Time.get_ticks_usec()
		var r: int = Fold.move(d.x, d.y)
		var dt := (Time.get_ticks_usec() - t0) / 1000.0
		if r >= 0:
			n += 1
			total += dt
			worst = maxf(worst, dt)
		for _f in range(8):
			await get_tree().process_frame
	print("MOVE_BENCH %.2f ms/move (worst %.2f, n=%d)" % [total / maxi(1, n), worst, n])
	get_tree().quit(0)
