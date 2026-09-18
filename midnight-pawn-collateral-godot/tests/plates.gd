extends SceneTree

## Plate layer, gate and ledger. The thing actually being asserted is the 09_dist.rpy
## property, the one the whole dual-track model rests on: in a package without
## assets/plates_x/, a gated plate resolves to the censored file no matter what any flag
## says, and resolves to the real one only after bytes have been delivered to
## user://unlocked/.
##
## tests/pack_audit.gd is the other half — it greps the exported .pck to prove those bytes
## are not in the free download in the first place.

const C := preload("res://scripts/collateral_core.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	failures.append(msg)


func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var layer = game.plates
	if layer == null:
		_fail("no plate layer")
		return _done()

	# Every plate in the table has a file, or a censored file if it is gated.
	for id in Collateral.PLATES.keys():
		if Collateral.is_gated(id):
			if not FileAccess.file_exists("res://assets/plates/%s_locked.png" % id):
				_fail("gated plate %s has no censored counterpart" % id)
			if not FileAccess.file_exists("res://assets/plates_x/%s.png" % id):
				_fail("gated plate %s has no uncensored source in this checkout" % id)
		elif not FileAccess.file_exists("res://assets/plates/%s.png" % id):
			_fail("open plate %s has no file" % id)

	# ---- the gate, in a package that does not carry the uncensored bytes ----
	Unlock.simulate_free = true
	DirAccess.remove_absolute(Unlock.saved_path("cg_ring"))
	if Unlock.ready_for("cg_ring"):
		_fail("cg_ring reported ready with no bytes anywhere")
	var locked: Array = layer.pick("cg_ring")
	if locked[0] == null or not bool(locked[1]):
		_fail("free package did not fall back to the censored cg_ring")
	if Unlock.source_for("cg_ring") != "":
		_fail("free package claimed a source for cg_ring")

	# The ungated plate is never affected by the gate.
	var open_pick: Array = layer.pick("cg_tamsin")
	if open_pick[0] == null or bool(open_pick[1]):
		_fail("cg_tamsin must be open in every build")

	# ---- the refund rule turns on exactly this answer ----
	if Collateral.delivered("ring"):
		_fail("delivered() said yes for a gated plate with no bytes")
	if not Collateral.delivered("tamsin"):
		_fail("delivered() said no for the ungated plate")

	# A run that pays the fee and gets a censored plate must end up square. This is the
	# free-track path through Story.reading_take().
	var run := C.Run.new()
	var before := run.till
	var beats: Array = Story.reading_take(run, "ring")
	if run.till != before:
		_fail("the shop charged %d for a censored plate" % (before - run.till))
	if run.fees_refunded != 35:
		_fail("the censored plate did not trigger the refund")
	var said_so := false
	for beat in beats:
		if str(beat.get("text", "")).contains("puts the 35 back in the drawer"):
			said_so = true
	if not said_so:
		_fail("the refund happened silently — the player must be told")

	# The first plate on any track must be the uncensored one. A free build whose opening
	# reading is a silhouette is the bait screen 09_dist.rpy:17 blames for Room 704's 75
	# browser plays and zero purchase clicks — and this port shipped that bug for about an
	# hour, because the finial reading showed cg_finial instead of cg_tamsin.
	var opening := ""
	for beat in Story.l_finial_read(C.Run.new()):
		if str(beat.get("t", "")) == "plate":
			opening = Collateral.plate_for(str(beat["item"]))
			break
	if opening != "cg_tamsin":
		_fail("the opening reading shows %s; it must be the ungated cg_tamsin" % opening)
	if Collateral.is_gated(opening):
		_fail("the opening reading is gated")

	# ---- deliver the bytes, as a redeemed ticket would ----
	var data := FileAccess.get_file_as_bytes("res://assets/plates_x/cg_ring.png")
	if data.size() <= 1024:
		_fail("no uncensored source to deliver in this checkout")
	elif not Unlock.write_delivered("cg_ring", data):
		_fail("delivered bytes did not land in user://unlocked/")
	if not Unlock.ready_for("cg_ring"):
		_fail("cg_ring still not ready after delivery")
	var unlocked: Array = layer.pick("cg_ring")
	if unlocked[0] == null or bool(unlocked[1]):
		_fail("cg_ring still censored after a successful unlock")
	if not Unlock.source_for("cg_ring").begins_with("user://unlocked/"):
		_fail("unlocked source did not come from the save dir")
	if not Collateral.delivered("ring"):
		_fail("delivered() still says no after the bytes landed")

	# A short delivery must not count as an unlock: a gate that "succeeds" without bytes
	# would charge the fee and show a silhouette, which is the failure being designed out.
	DirAccess.remove_absolute(Unlock.saved_path("cg_veil"))
	Unlock.write_delivered("cg_veil", PackedByteArray([1, 2, 3]))
	if Unlock.ready_for("cg_veil"):
		_fail("a 3-byte delivery counted as an unlock")

	# ---- the Reading Ledger ----
	layer.show_plate("cg_tamsin")
	var ledger_run := C.Run.new()
	ledger_run.record_reading("finial")
	ledger_run.pay_client("finial", "fair")
	var rows: Array = layer.ledger_rows(ledger_run)
	if rows.size() != Collateral.PLATES.size():
		_fail("ledger rows %d != plates %d" % [rows.size(), Collateral.PLATES.size()])
	var tamsin_row := {}
	var veil_row := {}
	for row in rows:
		if str(row["item"]) == "tamsin":
			tamsin_row = row
		if str(row["item"]) == "veil":
			veil_row = row
	if not bool(tamsin_row.get("earned", false)):
		_fail("the ledger did not credit a FAIR finial")
	if not bool(tamsin_row.get("seen", false)):
		_fail("the ledger did not remember a shown plate")
	if bool(veil_row.get("earned", true)):
		_fail("the ledger credited a veil that was never read")
	if str(veil_row.get("why", "")) == "":
		_fail("an unearned slot has no condition text to show")

	Unlock.simulate_free = false
	DirAccess.remove_absolute(Unlock.saved_path("cg_ring"))
	DirAccess.remove_absolute(Unlock.saved_path("cg_veil"))
	game.free()
	_done()


func _done() -> void:
	if failures.is_empty():
		print("PLATES_OK plates=%d gated=%d" % [Collateral.PLATES.size(), Collateral.GATED.size()])
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)
