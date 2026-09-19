## unlock_live.gd — the gateway reveal, against the real gateway.
##
##     godot --headless res://tests/unlock_live.tscn
##
## This fork shipped with a gate and no reveal: request_unlock() ran the page gate, got
## "unlocked" back, and drew the same censored plate, because nothing ever fetched the
## uncensored bytes. The obvious test — "is unlock.gd wired into cg_gate.gd" — is exactly
## the kind of check this project keeps getting burned by, so this one makes the two real
## HTTP calls, writes the bytes, decodes them, and asserts the plate the presenter would
## draw actually changes.
##
## Needs the network. It is not part of ops/floor13x_build.sh's build gate for that reason;
## run it when the unlock path or the staged assets change.
extends Node

const SLOT := "cg_breakroom_x"

var failures := PackedStringArray()


func _ready() -> void:
	await get_tree().process_frame
	await _run()
	for f in failures:
		printerr("FAIL  ", f)
	print("\n%s — %d failure(s)" % ["FAIL" if failures.size() else "PASS", failures.size()])
	get_tree().quit(1 if failures.size() else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func _run() -> void:
	# Start from nothing delivered, or the test proves only that a previous run worked.
	var path := Unlock.saved_path(SLOT)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	check(not Unlock.delivered(SLOT), "could not clear a previously delivered plate")

	# A desktop checkout is a paid build; pretend it is the free web package so the fetch
	# path is the one under test.
	Unlock.simulate_free = true
	var unlock: Unlock = CgGate.unlock
	check(unlock != null, "CgGate has no Unlock child — the fetch half is not wired at all")
	if unlock == null:
		return

	var ticketed := await unlock.start(SLOT)
	check(ticketed, "POST %s/unlock/start returned no ticket for app=%s key=%s"
		% [Unlock.API, Unlock.APP, SLOT])
	var got := await unlock.redeem(SLOT)
	check(got, "GET %s/unlock/fetch delivered nothing usable for %s" % [Unlock.API, SLOT])
	check(Unlock.delivered(SLOT), "bytes did not land at %s" % path)

	var tex := Unlock.delivered_texture(SLOT)
	check(tex != null, "the delivered bytes did not decode to a texture")
	if tex != null:
		check(tex.get_width() > 256 and tex.get_height() > 256,
			"delivered plate is %dx%d — that is not a plate" % [tex.get_width(), tex.get_height()])
		print("delivered %s: %dx%d, %d bytes" % [SLOT, tex.get_width(), tex.get_height(),
			FileAccess.open(path, FileAccess.READ).get_length()])

	# And the thing the player actually sees.
	check(CgGate.is_unlocked(SLOT), "is_unlocked() is still false after a successful delivery")
	check(CgGate.plate_path(SLOT) == path,
		"the presenter would still draw %s, not the delivered plate" % CgGate.plate_path(SLOT))
	check(CgGate.plate_texture(SLOT) != null, "plate_texture() drew nothing for a delivered plate")

	# A ticket is single use: spending it twice must not report a second unlock.
	DirAccess.remove_absolute(path)
	var twice := await unlock.redeem(SLOT)
	check(not twice, "a spent ticket delivered a second time — the reveal is not ticketed")

	# The slot with no render installed must refuse the trade rather than take a clip for
	# a plate nothing can serve (ops/adult_forks/STATUS.md: cg_desk_x).
	for slot in CgGate.SLOTS:
		if not CgGate.installed(slot):
			check(not CgGate.can_unlock(slot),
				"%s has no render installed but is still offered for unlock" % slot)
			var p := CgGate.plate_path(slot)
			check(p.ends_with("_locked.png") or p.ends_with("cg_withheld.png"),
				"uninstalled slot %s resolves to %s instead of its censored partner" % [slot, p])
			print("uninstalled slot %s falls back to %s" % [slot, p])
	Unlock.simulate_free = false
