extends SceneTree

## Play the run by CLICKING, and photograph every screen it reaches.
##
## Why this exists, 2026-09-21. The shelf-wide evidence for "playable to an ending" is
## ops/play_driver.py driven on the GPU box, and the GPU box was unreachable for this
## pass (ssh timed out for the whole session; local headless Chromium is deliberately
## blocked on Blaze's machine). `tests/visual_walkthrough.gd` photographs the same screens
## but reaches them by assigning `state.phase` and calling `game._show_shop()` directly —
## which proves the screens DRAW and proves nothing at all about whether the controls
## work. That is the exact hole SilverTongue and Ghost Channel shipped through: a title
## that animates and a game where every button does nothing, for ever.
##
## So this presses the real controls. Every step finds a live Button in the tree and sends
## a real InputEventMouseButton at its centre through the viewport, so the press goes
## through Godot's input path, the control's hit test and its `pressed` signal — the same
## way a player's does. If a button is missing, or dead, or drawn somewhere it cannot be
## hit, the step fails and the run stops with the screen it stopped on named.
##
##   $GODOT --path . --resolution 1280x720 -s res://tests/stage_shots.gd
##
## Writes user://stages/sNN_<label>.png, which ops/play_matrix.py reads.

var out_dir := "user://stages"
var game: Control
var n := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _settle(frames := 6) -> void:
	for _i in frames:
		await process_frame
	await create_timer(0.12).timeout


func _shot(label: String) -> void:
	await _settle()
	var img := root.get_texture().get_image()
	img.save_png("%s/s%02d_%s.png" % [out_dir, n, label])
	print("  s%02d %s" % [n, label])
	n += 1


## Find the Button a player would actually hit for `want`.
##
## Two things make this less obvious than it looks, and both cost a run before they were
## understood:
##
##   * ShapedButton moves `text` into `label` the first time it draws, so BOTH have to be
##     checked — looking only at `text` finds nothing on this game's buttons and looking
##     only at `label` finds nothing on a plain one.
##   * The title screen is a full-screen card laid OVER the ordinary game panel, and the
##     panel underneath still holds its own visible BEGIN. Taking the first match in tree
##     order returned the buried one, and the click — sent at the buried button's
##     coordinates — landed on whatever the card had drawn in that spot: the language
##     picker. The run silently switched itself to Spanish and never left the title. So
##     this takes the LAST match, which is the one added most recently and therefore the
##     one drawn on top.
func _find(node: Node, want: String) -> Button:
	var found: Button = null
	if node is Button and node.is_visible_in_tree():
		var b := node as Button
		var word := b.text
		if word == "" and "label" in b:
			word = str(b.get("label"))
		if want != "" and word.to_lower().findn(want.to_lower()) >= 0:
			found = b
	for child in node.get_children():
		var hit := _find(child, want)
		if hit:
			found = hit
	return found


func _click(want: String) -> bool:
	var b := _find(game, want)
	if b == null:
		failures.append("no button matching '%s'" % want)
		return false
	var at := b.get_global_rect().get_center()
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		# in_local_coords = TRUE. The default is false, which means "these are window
		# coordinates" — and this game renders 640x360 into a 1280x720 window, so every
		# click landed at half the intended position and the first draft of this file
		# pressed BEGIN ninety-one times without ever leaving the title. A harness that
		# misses by a factor of two looks exactly like a game whose buttons are dead.
		root.push_input(ev, true)
		await process_frame
	await _settle(4)
	return true


func _step(want: String, label: String) -> bool:
	var ok: bool = await _click(want)
	if not ok:
		print("  STOPPED at %s: %s" % [label, failures[-1]])
		return false
	await _shot(label)
	return true


## The verbs, in the order a player would reach for them. At every step the first one
## that is actually on screen is pressed — which is how ops/play_driver.py works, minus
## the blind coordinates, and it means the route is not a script that can silently drift
## out of step with the game.
##
## Order is the whole design. "APPRAISE" has to come before "CALL CUSTOMER" or the shop
## never gets priced; "APPROACH" before "STRIKE" or the encounter never opens; "REPLAY"
## is last because it is the one verb that would loop for ever.
const VERBS := [
	"BEGIN", "CONTINUE", "APPRAISE", "DISPLAY", "PRICE", "CALL CUSTOMER",
	"ACCEPT + WARN", "REJECT", "CARRY & DESCEND", "APPROACH", "RETURN RING",
	# Combat needs more than two presses of one verb and the cycle-cap above stops at two,
	# so the other three combat verbs are here: the loop alternates STRIKE / GUARD /
	# STRIKE, which finishes a fight AND exercises the verbs a fixed script would skip.
	"STRIKE", "GUARD", "REMEMBER", "USE CARRIED",
	"SEAL", "SELL", "KEEP",
]
const MAX_STEPS := 140


func _run() -> void:
	# English, so the verb list above is the verb list on screen. Every other locale is
	# proven by tests/title_shot.gd and tests/locale_scan.gd.
	# Force English before anything is built. Loc persists the player's pick to
	# user://settings.cfg, so a previous test run's locale leaks into this one otherwise —
	# the first draft of this file came up in Spanish because title_shot.gd had last left
	# it there, and then matched none of the verbs below.
	Loc.set_code("en")
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _settle(40)                      # let the title mark settle
	await _shot("title")
	# A second title frame with NO input. ops/play_matrix.py uses it as this game's own
	# motion floor: whatever moved between s00 and s00b is the attract loop — the lantern
	# breathing, the dust, the ticket swaying on its string — and anything a click has to
	# beat must beat that, or the matrix fills up with the title breathing. Overtime
	# Idle's "11 stages" were exactly that.
	await _settle(30)
	var idle := root.get_texture().get_image()
	idle.save_png("%s/s00b_idle.png" % out_dir)
	print("  s00b idle")

	var seen_result := false
	var last := ""
	var repeats := 0
	for step in MAX_STEPS:
		var chosen := ""
		for v in VERBS:
			# A verb that only CYCLES is a trap for a priority list. PRICE walks
			# LOW -> FAIR -> HIGH and back for ever, and it sits above CALL CUSTOMER, so
			# the first draft of this file pressed it eighty-seven times and never sold
			# anything. Two presses of the same verb in a row is enough to see what it
			# does; the third goes to whatever is next on the screen.
			if v == last and repeats >= 2:
				continue
			if _find(game, v) != null:
				chosen = v
				break
		if chosen == "":
			break
		repeats = repeats + 1 if chosen == last else 1
		last = chosen
		if not await _click(chosen):
			break
		await _shot(chosen.to_lower().replace(" ", "_").replace("+", "").replace("&", ""))
		if _find(game, "REPLAY") != null:
			seen_result = true
			break

	if not seen_result:
		failures.append("the run never reached a result screen (no REPLAY verb after %d steps)" % n)
	_finish()


func _finish() -> void:
	print("STAGE_SHOTS_DONE frames=%d failures=%d" % [n, failures.size()])
	for f in failures:
		print("  FAIL ", f)
	quit(1 if failures.size() > 0 else 0)
