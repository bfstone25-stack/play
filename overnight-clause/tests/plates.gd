extends SceneTree

## Plate layer, gate and gallery. The thing actually being asserted is the 09_dist.rpy
## property: in a package without assets/plates_x/, a gated plate resolves to the
## censored file no matter what any flag says, and resolves to the real one only after
## bytes have been delivered to user://unlocked/.

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _fresh() -> Node:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	return game

func _fail(msg: String) -> void:
	failures.append(msg)

func _run() -> void:
	var game: Node = _fresh()
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	var layer = hud.plates
	if layer == null:
		_fail("no plate layer on the HUD")
		return _done()

	# every plate in the table has a file, or a censored file if it is gated
	for id in Overnight.PLATES.keys():
		if Overnight.is_gated(id):
			if not FileAccess.file_exists("res://assets/plates/%s_locked.png" % id):
				_fail("gated plate %s has no censored counterpart" % id)
		elif not FileAccess.file_exists("res://assets/plates/%s.png" % id):
			_fail("open plate %s has no file" % id)

	# ---- the gate, in a package that does not carry the uncensored bytes ----
	Unlock.simulate_free = true
	var saved := Unlock.saved_path("cg_hatch")
	DirAccess.remove_absolute(saved)
	if Unlock.ready_for("cg_hatch"):
		_fail("cg_hatch reported ready with no bytes anywhere")
	var locked: Array = layer.pick("cg_hatch")
	if locked[0] == null or not bool(locked[1]):
		_fail("free package did not fall back to the censored cg_hatch")
	if Unlock.source_for("cg_hatch") != "":
		_fail("free package claimed a source for cg_hatch")

	# open plates are never affected by the gate
	var open_pick: Array = layer.pick("cg_cavity")
	if open_pick[0] == null or bool(open_pick[1]):
		_fail("cg_cavity must be open in every build")

	# ---- deliver the bytes, as a redeemed ticket would ----
	var bytes := FileAccess.get_file_as_bytes("res://assets/plates_x/cg_hatch.png")
	if bytes.size() <= 1024:
		_fail("no uncensored source to deliver in this checkout")
	elif not Unlock.write_delivered("cg_hatch", bytes):
		_fail("delivered bytes did not land in user://unlocked/")
	if not Unlock.ready_for("cg_hatch"):
		_fail("cg_hatch still not ready after delivery")
	var unlocked: Array = layer.pick("cg_hatch")
	if unlocked[0] == null or bool(unlocked[1]):
		_fail("cg_hatch still censored after a successful unlock")
	if not Unlock.source_for("cg_hatch").begins_with("user://unlocked/"):
		_fail("unlocked source did not come from the save dir")

	# a short delivery must not count as an unlock
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	Unlock.write_delivered("cg_403", PackedByteArray([1, 2, 3]))
	if Unlock.ready_for("cg_403"):
		_fail("a 3-byte delivery counted as an unlock")

	# ---- gallery ----
	layer.show_plate("cg_mirror")
	var rows: Array = layer.gallery_rows()
	if rows.size() != Overnight.PLATES.size():
		_fail("gallery rows %d != plates %d" % [rows.size(), Overnight.PLATES.size()])
	var mirror_row := {}
	var hatch_row := {}
	for row in rows:
		if str(row["id"]) == "cg_mirror":
			mirror_row = row
		if str(row["id"]) == "cg_hatch":
			hatch_row = row
	if not bool(mirror_row.get("seen", false)):
		_fail("gallery did not remember a shown plate")
	if not bool(hatch_row.get("unlocked", false)):
		_fail("gallery did not see the unlock")

	Unlock.simulate_free = false
	DirAccess.remove_absolute(Unlock.saved_path("cg_hatch"))
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	game.free()
	_done()

func _done() -> void:
	if failures.is_empty():
		print("PLATES_OK plates=%d gated=%d unlocks_reached=1" % [Overnight.PLATES.size(), Overnight.GATED.size()])
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)
