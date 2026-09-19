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

	# Every plate in the table resolves to a picture. Not "has a file": a slot whose
	# render has not landed falls through plates.gd's chain to its censored partner or
	# to Overnight.SUBSTITUTE, and what matters to a player is that something is there.
	# Asserting files existed is what let cg_complicit ship a placeholder card — the file
	# was present, so the check passed, and the COMPLICIT ending showed the player a card
	# reading "PLACEHOLDER PLATE".
	for id in Overnight.PLATES.keys():
		if Overnight.is_gated(id):
			if not FileAccess.file_exists("res://assets/plates/%s_locked.png" % id):
				_fail("gated plate %s has no censored counterpart" % id)
			continue
		var resolved: Array = layer.pick(id)
		if resolved[0] == null:
			_fail("open plate %s resolves to nothing — no file, no _locked, no substitute" % id)
		if bool(resolved[1]):
			_fail("open plate %s reported itself locked" % id)
	# and the substitutes point somewhere real
	for id in Overnight.SUBSTITUTE.keys():
		var sub: String = Overnight.substitute(id)
		if not FileAccess.file_exists("res://assets/plates/%s.png" % sub):
			_fail("substitute %s -> %s does not exist" % [id, sub])

	# ---- the gate, in a package that does not carry the uncensored bytes ----
	# cg_403 is the gated slot whose render has landed. cg_hatch is gated too but its
	# plate has not been rendered yet, so it is exercised below as the degrade case.
	Unlock.simulate_free = true
	var saved := Unlock.saved_path("cg_403")
	DirAccess.remove_absolute(saved)
	if Unlock.ready_for("cg_403"):
		_fail("cg_403 reported ready with no bytes anywhere")
	var locked: Array = layer.pick("cg_403")
	if locked[0] == null or not bool(locked[1]):
		_fail("free package did not fall back to the censored cg_403")
	if Unlock.source_for("cg_403") != "":
		_fail("free package claimed a source for cg_403")

	# open plates are never affected by the gate
	var open_pick: Array = layer.pick("cg_cavity")
	if open_pick[0] == null or bool(open_pick[1]):
		_fail("cg_cavity must be open in every build")

	# ---- deliver the bytes, as a redeemed ticket would ----
	var bytes := FileAccess.get_file_as_bytes("res://assets/plates_x/cg_403.png")
	if bytes.size() <= 1024:
		_fail("no uncensored source to deliver in this checkout")
	elif not Unlock.write_delivered("cg_403", bytes):
		_fail("delivered bytes did not land in user://unlocked/")
	if not Unlock.ready_for("cg_403"):
		_fail("cg_403 still not ready after delivery")
	var unlocked: Array = layer.pick("cg_403")
	if unlocked[0] == null or bool(unlocked[1]):
		_fail("cg_403 still censored after a successful unlock")
	if not Unlock.source_for("cg_403").begins_with("user://unlocked/"):
		_fail("unlocked source did not come from the save dir")

	# a short delivery must not count as an unlock
	DirAccess.remove_absolute(Unlock.saved_path("cg_hatch"))
	Unlock.write_delivered("cg_hatch", PackedByteArray([1, 2, 3]))
	if Unlock.ready_for("cg_hatch"):
		_fail("a 3-byte delivery counted as an unlock")
	DirAccess.remove_absolute(Unlock.saved_path("cg_hatch"))

	# A gated slot with no render yet must degrade to its censored partner, not to a hole.
	var not_yet: Array = layer.pick("cg_hatch")
	if not_yet[0] == null or not bool(not_yet[1]):
		_fail("cg_hatch (no render yet) did not fall back to cg_hatch_locked")

	# The gateway serves WEBP (gateway/app.py:304), and this used to write those bytes to
	# a file called "<id>.png" and then decode by extension — so a redeemed ticket landed
	# the right bytes and still showed the censored plate. Deliver genuine WEBP here.
	var webp := Image.load_from_file("res://assets/plates_x/cg_403.png").save_webp_to_buffer()
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	if not Unlock.write_delivered("cg_403", webp):
		_fail("webp delivery did not land")
	if Unlock.decode_delivered(Unlock.saved_path("cg_403")) == null:
		_fail("delivered WEBP did not decode — the gateway's own format")
	var webp_pick: Array = layer.pick("cg_403")
	if webp_pick[0] == null or bool(webp_pick[1]):
		_fail("a WEBP unlock still resolved to the censored plate")
	# and a gateway error page must never become a "plate"
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	Unlock.write_delivered("cg_403", ("x".repeat(4096)).to_utf8_buffer())
	if Unlock.decode_delivered(Unlock.saved_path("cg_403")) != null:
		_fail("4KB of text decoded as an image")
	DirAccess.remove_absolute(Unlock.saved_path("cg_403"))
	Unlock.write_delivered("cg_403", FileAccess.get_file_as_bytes("res://assets/plates_x/cg_403.png"))

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
		if str(row["id"]) == "cg_403":
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
