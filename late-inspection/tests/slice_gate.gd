extends SceneTree

## Slice builds stop after the player enters Flat 404 and reads the checklist.
## Full builds must never trigger the slice gate.

func _init() -> void:
	call_deferred("_run")


func _fresh_game() -> Node:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	return game


func _run() -> void:
	var game: Node = await _fresh_game()
	await process_frame

	game.SLICE = true
	game.on_note("order")
	if game.stage != 1 or game.ending:
		push_error("slice: order should advance to stage 1 without ending")
		quit(1)
		return
	game.on_note("notice")
	if game.stage != 2 or game.ending:
		push_error("slice: notice should advance to stage 2 without ending")
		quit(1)
		return
	game.on_note("checklist")
	if not game.ending or game.ending_id != "SLICE":
		push_error("slice: checklist should end the slice, got ending=%s id=%s" % [game.ending, game.ending_id])
		quit(1)
		return
	game.queue_free()

	var full: Node = await _fresh_game()
	await process_frame
	full.SLICE = false
	full.on_note("order")
	full.on_note("notice")
	full.on_note("checklist")
	if full.ending or full.stage != 3:
		push_error("full: checklist must advance to stage 3, got stage=%s ending=%s" % [full.stage, full.ending])
		quit(1)
		return
	print("SLICE_GATE_OK")
	quit(0)
