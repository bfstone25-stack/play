extends SceneTree

## Count the DISTINCT stages a real playthrough reaches, headlessly.
##
## Ported from Late Inspection 2026-09-21 (a21a4c7 / stage_walk.gd) after tests/progression.gd
## turned out to prove nothing about the playthrough: it drives ending state through
## debug_complete_route(), which sets the four ending flags and calls _finish() directly --
## it never touches _advance() or _spawn_stage(), so a route it calls COMPLETE can still
## have entered zero rooms. This test drives the authored sequence itself instead, the way
## the props actually drive it: on_note() for every document, _resolve_choice() for every
## decision, in the order game.gd's own match statements advance the stage -- and it checks
## visited_stages, which world_builder/game.gd now record at _spawn_stage() time, for both
## a stage count and a "did this stage actually spawn props" check.
##
## Unlike the parent, four of this fork's stage advances (stain, pipe, cassette, clause) go
## through plate_scene(), which shows a VN page and only calls its continuation when the
## page is closed -- normally by player input. So each such step is followed by draining
## the VN panel with hud.advance_vn() rather than a single process_frame. Two of the
## plates on the witness route (cg_hatch via pipe=0, cg_403 via clause on that branch) are
## gated (scripts/overnight.gd GATED), but _offer_unlock short-circuits to the censored
## text when Gate.is_web() is false -- true for this headless, non-web test run -- so
## nothing here waits on an ad.
##
##     godot --headless --path . -s res://tests/stage_walk.gd

## The authored order, matching game.gd's on_note()/_resolve_choice() match statements. A
## row of one element is a document; a row of three is a choice carrying the branch index
## for the witness route and for the complicit route.
const _SEQUENCE := [
	["order"], ["dane"], ["notice"], ["checklist"], ["answering"],
	["stain", 0, 1], ["service"], ["pipe", 0, 1], ["wardrobe"], ["cassette"],
	["followup"], ["clause", 1, 0], ["final", 0, 1],
]

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	await _walk("witness")
	await _walk("complicit")
	if failures.is_empty():
		quit(0)
	for f in failures:
		push_error(f)
	quit(1)


func _walk(route: String) -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var hud = game.get_node("HUD")
	hud.call("hide_splash")
	var ending := ""
	for step in _SEQUENCE:
		var id: String = step[0]
		if step.size() > 1:
			var pick: int = (step[1] if route == "witness" else step[2])
			game.call("_resolve_choice", id, pick, null)
		else:
			game.call("on_note", id)
		await process_frame
		# Drain any VN page plate_scene() opened -- stain/pipe/cassette/clause don't call
		# _advance() until the story panel closes, and that only happens on advance_vn().
		var guard := 0
		while hud.vn != null and hud.vn.is_open() and guard < 40:
			hud.call("advance_vn")
			await process_frame
			guard += 1
		if bool(game.get("ending")):
			ending = str(game.get("ending_id"))
			break

	var seen: Array[int] = []
	var empty: Array[int] = []
	for row in game.get("visited_stages"):
		var s := int(row["stage"])
		if s not in seen:
			seen.append(s)
		if int(row["props"]) <= 0:
			empty.append(s)

	print("route %-10s ending=%-9s distinct stages=%2d  %s"
			% [route, ending, seen.size(), seen])
	for row in game.get("visited_stages"):
		print("    stage %-2d  %-16s props=%d"
				% [int(row["stage"]), str(row["objective"]), int(row["props"])])
	if seen.size() < 6:
		failures.append("route %s reached only %d distinct stages (need 6)"
				% [route, seen.size()])
	if not empty.is_empty():
		failures.append("route %s advanced into stage(s) %s with NO props spawned -- the "
				% [route, empty] + "counter moved over an empty room")
	if ending == "":
		failures.append("route %s reached no ending" % route)
	game.free()
	await process_frame
