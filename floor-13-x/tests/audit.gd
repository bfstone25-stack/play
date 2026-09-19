## audit.gd — play every route of the fork and report every place a run stops.
##
##     godot --headless res://tests/audit.tscn
##
## fork_cg.gd proves four hand-picked routes reach their plates. This one is the opposite
## question: is there ANY combination of the four decisions, with or without the optional
## coat, that stalls, loops, draws nothing, or lands on an ending with no text? It plays
## all 2^4 flag combinations twice (coat taken / coat skipped) through the real HUD and
## prints a table.
##
## Run as a SCENE, never with --script (no autoloads → Gate/CgGate unresolved).
extends Node

const STANCES := ["TRUST", "SUSPECT"]
const COMPLIANCES := ["REFUSE", "OBEY"]
const ROUTES := ["STAIRS", "ELEVATOR"]
const CONTRACTS := ["RESIGN", "SIGN"]

var failures := PackedStringArray()
var rows: Array = []
var endings_seen := {}
var slots_seen := {}


func _ready() -> void:
	await get_tree().process_frame
	await _run()
	print("\n%-7s %-8s %-9s %-7s %-15s %5s %5s  %s"
		% ["ELI", "COMPLY", "ROUTE", "CONTR", "ENDING", "LINES", "STEPS", "PLATES"])
	for r in rows:
		print("%-7s %-8s %-9s %-7s %-15s %5d %5d  %s"
			% [r.eli, r.comply, r.route, r.contract, r.ending, r.lines, r.steps, r.plates])
	print("\nendings reached: %s" % [endings_seen.keys()])
	print("slots drawn across the matrix: %d of %d %s"
		% [slots_seen.size(), CgGate.SLOTS.size(), slots_seen.keys()])
	for slot in CgGate.SLOTS:
		if not slots_seen.has(slot):
			fail("slot %s is unreachable from every route combination" % slot)
	for f in failures:
		printerr("FAIL  ", f)
	print("\n%s — %d failure(s)" % ["FAIL" if failures.size() else "PASS", failures.size()])
	get_tree().quit(1 if failures.size() else 0)


func fail(msg: String) -> void:
	failures.append(msg)


func _run() -> void:
	for eli in STANCES:
		for comply in COMPLIANCES:
			for route in ROUTES:
				for contract in CONTRACTS:
					for coat in [true, false]:
						var r := await _play({"eli_stance": eli, "compliance": comply,
							"escape_route": route, "contract": contract}, coat)
						if coat:
							rows.append(r)
						endings_seen[r.ending] = true
						for s in r.drawn:
							slots_seen[s] = true


func _play(route: Dictionary, take_optional: bool) -> Dictionary:
	CgGate.reset()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	var drawn: Array = []
	var lines_read := 0
	var steps := 0
	var guard := 0
	var stalled := ""
	var label := "%s/%s/%s/%s coat=%s" % [route.eli_stance, route.compliance,
		route.escape_route, route.contract, take_optional]

	game.start_game()
	while guard < 6000:
		guard += 1
		await get_tree().process_frame
		if hud.cg_root.visible:
			steps += 1
			var slot: String = hud._cg_slot
			var path: String = CgGate.plate_path(slot)
			if path == "":
				fail("%s: plate %s resolved to no file at all" % [label, slot])
			elif hud.cg_plate.texture == null:
				fail("%s: plate %s (%s) drew no texture" % [label, slot, path])
			else:
				drawn.append(slot)
			if CgGate.is_showing_censored(slot) and path != "" and path.ends_with("%s.png" % slot):
				fail("%s: censored slot %s resolved to the OPEN plate" % [label, slot])
			hud._close_cg()
			continue
		if hud.ending_panel.visible:
			break
		if hud.choice_panel.visible:
			steps += 1
			var area: Dictionary = game._areas()[game.area_index]
			var want := str(route.get(str(area.choice.id), ""))
			if str(area.choice.a[1]) != want and str(area.choice.b[1]) != want:
				fail("%s: area %s has no branch for %s" % [label, area.id, want])
			hud._pick(0 if str(area.choice.a[1]) == want else 1)
			continue
		if hud.is_line_open():
			lines_read += 1
			if str(hud.current_line_text()).strip_edges() == "":
				fail("%s: empty dialogue line in area %s" % [label, game._areas()[game.area_index].id])
			hud._advance_dialogue()
			continue
		var clicked := false
		if not get_tree().get_nodes_in_group("hotspot").is_empty():
			for hotspot in game._areas()[game.area_index].hotspots:
				var id := str(hotspot[0])
				var key := "%s/%s" % [game._areas()[game.area_index].id, id]
				if game.completed_hotspots.has(key):
					continue
				if not take_optional and game.OPTIONAL_HOTSPOTS.has(key):
					continue
				steps += 1
				game._on_hotspot(id)
				clicked = true
				break
		if clicked:
			continue
		if hud.route_button.visible:
			steps += 1
			hud.route_requested.emit()
			continue
		stalled = "no line, no choice, no hotspot, no route button (area %d/%s, pending=%s)" % [
			game.area_index, game._areas()[game.area_index].id, game.pending]
		break

	if guard >= 6000:
		stalled = "ran %d frames without reaching an ending" % guard
	if stalled != "":
		fail("%s STALLED: %s" % [label, stalled])
	var ending := str(game.ending_id)
	if ending == "" and stalled == "":
		fail("%s: run finished with no ending id" % label)
	elif ending != "":
		var ending_text: Array = StoryData.live_endings().get(ending, [])
		if ending_text.is_empty():
			fail("%s: ending %s has no text" % [label, ending])
	var out := {
		"eli": route.eli_stance, "comply": route.compliance, "route": route.escape_route,
		"contract": route.contract, "ending": ending if ending != "" else "(none)",
		"lines": lines_read, "steps": steps, "drawn": drawn,
		"plates": "%d %s" % [drawn.size(), drawn],
	}
	game.queue_free()
	await get_tree().process_frame
	return out
