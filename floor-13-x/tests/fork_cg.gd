## fork_cg.gd — plays the fork for real and checks the CG hooks fire on state, not on time.
##
##   godot --headless res://tests/fork_cg.tscn
##
## Run as a SCENE, not with --script. `--script` starts a bare SceneTree with no autoloads,
## so `Gate` and `CgGate` do not resolve and game.gd will not even compile — which is also
## why every test in tests/ has been failing in the mainstream game since the Gate autoload
## was added by ops/godot_build.sh. Reported, not fixed here: the SFW game is not this
## fork's to touch.
##
## This is a play, not a simulation: it instantiates main.tscn, starts the game, clicks
## hotspots and choice buttons through the real HUD, and asserts on what actually appeared.
## The one thing it stubs is the hotspot *click* — it calls game._on_hotspot(id), which is
## exactly what the Button's pressed signal calls — because driving pixel coordinates in a
## headless viewport tests the layout, not the hooks.
##
## What it proves:
##   1. The TRUST route with the coat inspected earns cg_breakroom_x, and a plate is drawn.
##   2. The SUSPECT route earns nothing in the break room, and the three slots the design
##      doc says close for that run stay closed all the way to the ending.
##   3. No slot is earned by playing longer: a run that clears every required hotspot on
##      the SUSPECT/OBEY/ELEVATOR line reaches an ending with strictly fewer plates.
##   4. Every earned slot resolves to a file that exists, and a locked slot resolves to its
##      censored counterpart rather than to the open plate.
extends Node

const ROUTE_WARM := {"eli_stance": "TRUST", "compliance": "REFUSE", "escape_route": "STAIRS", "contract": "RESIGN"}
const ROUTE_COLD := {"eli_stance": "SUSPECT", "compliance": "OBEY", "escape_route": "ELEVATOR", "contract": "SIGN"}

var failures := PackedStringArray()


func _ready() -> void:
	# The test node is still being set up; wait a frame before parenting the game under root.
	await get_tree().process_frame
	await _run()
	for f in failures:
		printerr("FAIL  ", f)
	print("\n%s — %d failure(s)" % ["FAIL" if failures.size() else "PASS", failures.size()])
	get_tree().quit(1 if failures.size() else 0)


func fail(msg: String) -> void:
	failures.append(msg)


func check(cond: bool, msg: String) -> void:
	if not cond:
		fail(msg)


func _run() -> void:
	# ---- the plate files the rest of this depends on ------------------------
	for slot in CgGate.SLOTS:
		var open_path: String = CgGate.ART_DIR + slot + ".png"
		check(ResourceLoader.exists(open_path), "missing plate %s" % open_path)
		if int(CgGate.SLOTS[slot].tier) >= 3:
			var locked: String = CgGate.ART_DIR + slot + "_locked.png"
			check(ResourceLoader.exists(locked), "missing censored plate %s" % locked)

	# ---- the fork's writing is actually spliced in --------------------------
	var areas: Array = StoryX.patch(StoryData.AREAS)
	var coat_found := false
	for area in areas:
		if str(area.id) == "breakroom":
			for h in area.hotspots:
				if str(h[0]) == "coat":
					coat_found = true
	check(coat_found, "the breakroom `coat` hotspot was not spliced in")
	check(StoryX.word_count() > 1500, "fork word count unexpectedly low: %d" % StoryX.word_count())
	print("fork adds ~%d words of English" % StoryX.word_count())

	# ---- the shipped locale list is the corrected one ------------------------
	# The source used to sell ja/ko/es tables that are ~95% Chinese text; the mainstream
	# game was corrected to ["en","zh"] and the fork carries the correction.
	check(Loc.ALLOWED == ["en", "zh"], "locale list is %s, not the corrected [en, zh]" % [Loc.ALLOWED])
	for dead in ["ja", "ko", "es"]:
		check(not ResourceLoader.exists("res://scripts/story_%s.gd" % dead),
			"story_%s.gd is still in the package" % dead)

	# ---- Eli reads as an adult in every locale ------------------------------
	for script_name in ["story_data.gd", "story_zh.gd"]:
		var text := FileAccess.get_file_as_string("res://scripts/" + script_name)
		check(not ("twenty-two" in text), "%s still says 'twenty-two'" % script_name)
		check(not ("二十二岁" in text), "%s still says '二十二岁'" % script_name)

	# ---- play the warm route ------------------------------------------------
	var warm := await _play(ROUTE_WARM, true)
	check("cg_breakroom_x" in warm.earned, "TRUST + coat did not earn cg_breakroom_x")
	check("cg_terminal_x" in warm.earned, "REFUSE + terminal second read did not earn cg_terminal_x")
	check("cg_landing_x" in warm.earned, "STAIRS + replacement_list + coats did not earn cg_landing_x")
	check("cg_present_x" in warm.earned, "the CLOCK_OUT completionist plate did not earn")
	check(warm.ending == "CLOCK_OUT", "warm route ended in %s" % warm.ending)
	check(warm.plates_drawn > 0, "no plate was ever drawn on the warm route")
	print("warm route: ending %s, %d earned %s, %d plate(s) drawn"
		% [warm.ending, warm.earned.size(), warm.earned, warm.plates_drawn])

	# ---- play the cold route, clearing every required hotspot ---------------
	var cold := await _play(ROUTE_COLD, true)
	for closed in ["cg_breakroom_x", "cg_landing_x", "cg_present_x"]:
		check(not (closed in cold.earned), "%s should be closed on the SUSPECT route" % closed)
	check("cg_retention_x" in cold.earned, "ELEVATOR + rusk_keycard did not earn cg_retention_x")
	check("cg_desk_x" in cold.earned, "contract == SIGN did not earn cg_desk_x")
	check(cold.ending == "NEW_MANAGER", "cold route ended in %s" % cold.ending)
	check(cold.earned.size() < warm.earned.size(),
		"treating Eli as a discrepancy did not cost content (%d vs %d)" % [cold.earned.size(), warm.earned.size()])
	print("cold route: ending %s, %d earned %s, %d plate(s) drawn"
		% [cold.ending, cold.earned.size(), cold.earned, cold.plates_drawn])

	# ---- the bad end has its own plate --------------------------------------
	# A mixed route (route and declaration disagree) is the MONDAY_FOREVER ending, which is
	# 14 of the 16 flag combinations — the one plate that is not about a stance toward a
	# person but about what the building keeps.
	var loop := await _play({"eli_stance": "TRUST", "compliance": "REFUSE",
		"escape_route": "STAIRS", "contract": "SIGN"}, true)
	check(loop.ending == "MONDAY_FOREVER", "mixed route ended in %s" % loop.ending)
	check("cg_monday_x" in loop.earned, "MONDAY_FOREVER did not earn cg_monday_x")
	check(not ("cg_present_x" in loop.earned), "cg_present_x leaked into the loop ending")
	print("loop route: ending %s, %d earned %s" % [loop.ending, loop.earned.size(), loop.earned])

	# ---- no plate is earned by playing longer -------------------------------
	# The warm route with the optional coat SKIPPED: same length, same rooms, same time,
	# one fewer plate. If anything unlocked from progress this would not change.
	var warm_no_coat := await _play(ROUTE_WARM, false)
	check(not ("cg_breakroom_x" in warm_no_coat.earned),
		"cg_breakroom_x was earned without inspecting the coat — that is a progress unlock")
	print("warm route without the coat: %d earned %s" % [warm_no_coat.earned.size(), warm_no_coat.earned])


## Play one full route through the real HUD.
func _play(route: Dictionary, take_optional: bool) -> Dictionary:
	CgGate.reset()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	var plates_drawn := 0
	var guard := 0

	game.start_game()
	while guard < 4000:
		guard += 1
		await get_tree().process_frame
		# a plate is up: record what was drawn and dismiss it
		if hud.cg_root.visible:
			if hud.cg_plate.texture != null:
				plates_drawn += 1
			else:
				fail("plate %s drew no texture" % hud._cg_slot)
			# a locked slot must resolve to its censored counterpart, never to the open art
			var path: String = CgGate.plate_path(hud._cg_slot)
			if CgGate.is_showing_censored(hud._cg_slot) and path != "":
				if not path.ends_with("_locked.png"):
					fail("censored slot %s resolved to the open plate %s" % [hud._cg_slot, path])
			hud._close_cg()
			continue
		if hud.ending_panel.visible:
			break
		if hud.choice_panel.visible:
			var area: Dictionary = game._areas()[game.area_index]
			var want := str(route.get(str(area.choice.id), ""))
			hud._pick(0 if str(area.choice.a[1]) == want else 1)
			continue
		if hud.is_line_open():
			hud._advance_dialogue()
			continue
		# hotspots are up: click them all (optionally skipping the fork's optional ones)
		var clicked := false
		# Drive from the area data rather than from node names: what is on screen is a
		# button per hotspot, and the ids are the authoritative list.
		if get_tree().get_nodes_in_group("hotspot").is_empty():
			if hud.route_button.visible:
				hud.route_requested.emit()
				continue
			break
		for hotspot in game._areas()[game.area_index].hotspots:
			var id := str(hotspot[0])
			var key := "%s/%s" % [game._areas()[game.area_index].id, id]
			if game.completed_hotspots.has(key):
				continue   # the base game keeps drawing buttons for finished hotspots
			if not take_optional and game.OPTIONAL_HOTSPOTS.has(key):
				continue
			game._on_hotspot(id)
			clicked = true
			break
		if clicked:
			continue
		# nothing left to click: proceed if the game is offering that, otherwise the run
		# is stuck and the guard below will say so.
		if hud.route_button.visible:
			hud.route_requested.emit()
			continue
		break

	if guard >= 4000:
		fail("route did not terminate: %s" % route)
	var out := {
		"ending": str(game.ending_id),
		"earned": CgGate.earned_slots(),
		"plates_drawn": plates_drawn,
		"flags": game.flags.duplicate(),
	}
	game.queue_free()
	await get_tree().process_frame
	return out
