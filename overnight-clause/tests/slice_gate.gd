extends SceneTree

## Slice builds stop with the stain choice made, the mirror plate seen and the pipe
## knocking — SLICE_LAST_STAGE is 5 in this fork (2 in the base game), which lands the
## cut exactly one beat before the first gated plate, cg_hatch. Full builds must never
## trigger the slice gate.

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
	game.on_note("answering")
	if game.stage != 4 or game.ending:
		push_error("slice: the free slice must reach the kitchen, got stage=%s" % game.stage)
		quit(1)
		return
	game._advance(5, "obj.stain", 3, "02:06")
	if game.ending:
		push_error("slice: the mirror plate beat (stage 5) must be inside the free slice")
		quit(1)
		return
	# The service tag is the next beat; it advances to 6 and must hit the gate, so the
	# pipe choice — and therefore cg_hatch — is never reachable in the slice.
	game.on_note("service")
	if not game.ending or game.ending_id != "SLICE":
		push_error("slice: service tag should end the slice, got ending=%s id=%s" % [game.ending, game.ending_id])
		quit(1)
		return
	if game.flags["pipe_answered"]:
		push_error("slice: pipe choice must be unreachable in the slice")
		quit(1)
		return
	game.queue_free()

	var full: Node = await _fresh_game()
	await process_frame
	full.SLICE = false
	full.on_note("order")
	full.on_note("notice")
	full.on_note("checklist")
	full.on_note("answering")
	full.on_note("service")
	if full.ending or full.stage != 6:
		push_error("full: service tag must advance to stage 6, got stage=%s ending=%s" % [full.stage, full.ending])
		quit(1)
		return
	print("SLICE_GATE_OK")
	quit(0)
