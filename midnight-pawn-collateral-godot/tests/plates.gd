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

	# Every plate in the table resolves to a picture, whatever art is or is not installed.
	#
	# This used to require every file to exist, which is a rule the project cannot keep:
	# ops/adult_forks/STATUS.md has carried empty slots all day and cg_veil/cg_veil_locked
	# are blocked on a reference only Blaze can pick. So the assertion is the one that has
	# to hold forever — a plate slot is never a broken texture and never an empty frame —
	# and it is checked for every slot, including the ones whose art is missing right now.
	Unlock.simulate_free = true
	for id in Collateral.PLATES.keys():
		Unlock.clear(id)
		var resolved: Array = layer.pick(id)
		if resolved[0] == null:
			_fail("plate %s resolved to nothing" % id)
		elif (resolved[0] as Texture2D).get_width() < 16:
			_fail("plate %s resolved to a degenerate texture" % id)
	Unlock.simulate_free = false

	# The slots with no art at all today must be taking the pixel floor, not a placeholder
	# card that a survey would count as a render (ops/adult_forks/STATUS.md: a file-size
	# survey mistook 300 KB placeholder cards for finished plates across all six forks).
	Unlock.simulate_free = true
	for id in ["cg_tamsin", "cg_veil"]:
		Unlock.clear(id)
		var floored: Array = layer.pick(id)
		if int(floored[2]) != layer.SRC_PIXEL:
			_fail("%s did not take the pixel floor — is a placeholder card back?" % id)
	# ...and the ones that do have a censored stand-in must use it rather than the floor.
	var ring_pick: Array = layer.pick("cg_ring")
	if int(ring_pick[2]) != layer.SRC_LOCKED:
		_fail("cg_ring has a _locked file and did not use it")
	Unlock.simulate_free = false

	# Showing a floored plate must not write it into the Ledger as seen.
	Unlock.simulate_free = true
	layer.seen.erase("cg_veil")
	layer.show_plate("cg_veil")
	if bool(layer.seen.get("cg_veil", false)):
		_fail("the Ledger recorded a plate the player never actually saw")
	Unlock.simulate_free = false

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
	if run.till != before - 35:
		_fail("the fee was not charged up front")
	# reading_take() no longer answers the delivery question itself — it cannot, because on
	# the web track the bytes are fetched at the plate beat, after this list is built. It
	# emits a settle beat and game.gd resolves it once the fetch has happened or failed.
	var settle := {}
	for beat in beats:
		if str(beat.get("t", "")) == "settle":
			settle = beat
	if settle.is_empty():
		_fail("a paid reading emitted no settle beat — the refund can never fire")
	var refund: Array = Story.settle_reading(run, str(settle.get("item", "")), str(settle.get("plate", "")))
	if run.till != before:
		_fail("the shop charged %d for a censored plate" % (before - run.till))
	if run.fees_refunded != 35:
		_fail("the censored plate did not trigger the refund")
	var said_so := false
	for beat in refund:
		if str(beat.get("text", "")).contains("puts the 35 back in the drawer"):
			said_so = true
	if not said_so:
		_fail("the refund happened silently — the player must be told")
	# And the other way: when the art did arrive, nothing is refunded and nothing is said.
	var paid_run := C.Run.new()
	Story.reading_take(paid_run, "finial")
	if not Story.settle_reading(paid_run, "finial", "cg_tamsin").is_empty():
		_fail("a delivered reading still produced refund lines")

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
	var data := FileAccess.get_file_as_bytes("res://assets/plates_x/cg_finial.png")
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
	Unlock.clear("cg_veil")
	Unlock.write_delivered("cg_veil", PackedByteArray([1, 2, 3]))
	if Unlock.ready_for("cg_veil"):
		_fail("a 3-byte delivery counted as an unlock")

	# ---- and the bug a live fetch found: the gateway serves webp, not png ----
	#
	# gateway/app.py:309 returns image/webp. Godot picks its decoder from the extension, so
	# writing those bytes to "<id>.png" produced a file that passed the >1024-byte "it
	# arrived" test, suppressed the refund, and could not be decoded by anything. These
	# bytes are a real webp, encoded the same way ops/export_gated.py encodes the ones on
	# the gateway.
	Unlock.clear("cg_market")
	var webp := Image.load_from_file("res://assets/plates_x/cg_market.png").save_webp_to_buffer(true)
	if Unlock.ext_of(webp) != "webp":
		_fail("the webp sniffer does not recognise a webp")
	if not Unlock.write_delivered("cg_market", webp):
		_fail("a webp delivery was rejected — the web track can never reveal")
	if not Unlock.saved_path("cg_market").ends_with(".webp"):
		_fail("webp bytes were not stored under a webp extension: %s" % Unlock.saved_path("cg_market"))
	var revealed: Array = layer.pick("cg_market")
	if revealed[0] == null or bool(revealed[1]) or int(revealed[2]) != layer.SRC_REAL:
		_fail("a delivered webp did not decode into the uncensored plate")
	elif (revealed[0] as Texture2D).get_width() < 100:
		_fail("the delivered webp decoded to a degenerate texture")
	# An error page from the gateway is not an image and must not count as a delivery.
	Unlock.clear("cg_collateral")
	if Unlock.write_delivered("cg_collateral", ('{"ok":false,"error":"invalid ticket"}'.repeat(60)).to_utf8_buffer()):
		_fail("a JSON error body was accepted as a plate")
	Unlock.clear("cg_market")
	Unlock.clear("cg_collateral")

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
	Unlock.clear("cg_ring")
	Unlock.clear("cg_veil")
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
