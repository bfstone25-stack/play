extends SceneTree

## Count the DISTINCT stages a real playthrough reaches, headlessly.
##
## This is the substance of ops/play_matrix.py's "six or more distinct stages" for a build
## that cannot currently be photographed: the GPU box (ops/remote_playtest.sh) is
## unreachable, and this machine has no xvfb, so the only local capture path opens a real
## window on Blaze's desktop -- which is forbidden for this title, because the build
## captures the pointer.
##
## It is NOT a replacement for the matrix and does not claim to be. The matrix proves the
## screen CHANGED; this proves the game STATE advanced. A build with a dead renderer would
## pass this and fail that. What it does cover is the failure the stage count exists to
## catch -- a game that never leaves its first room -- and it covers it better than a
## photograph does, because finding 4 of the studio's list is that stage counts were
## unreliable in both directions: an attract loop counted as progress and a consent card
## counted as the title.
##
## Each stage must do three things to be counted, and the third is the one that makes this
## more than a variable increment:
##
##   * the game's `stage` must change;
##   * the chapter/objective the HUD is showing must change with it;
##   * the world must actually RESPAWN -- the props of the new stage exist, and are not
##     the props of the previous one. A stage counter that advances over an empty room is
##     exactly the "one tile" the matrix rule is written against.
##
##     godot --headless --path . -s res://tests/stage_walk.gd

## The authored order, exactly as scripts/game.gd's on_note()/_resolve_choice() match
## statements advance through it. A row of one element is a document; a row of three is a
## choice and carries the branch index for the witness route and for the complicit route.
const _SEQUENCE := [
	["order"], ["dane"], ["fire_plan"], ["notice"], ["checklist"], ["frame"],
	["answering"], ["stain", 0, 1], ["shoes"], ["service"], ["pipe", 0, 1],
	["invoice"], ["medicine"], ["wardrobe"], ["drain"], ["locket"], ["cassette"],
	["followup"], ["clause", 1, 0], ["letters"], ["final_evidence"], ["final", 0, 1],
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

	# NOT debug_complete_route. That helper sets the four ending flags and calls _finish()
	# directly -- it never touches _advance() or _spawn_stage(), so it reaches an ending
	# without entering a single room. tests/progression.gd is built on it, which means the
	# evidence this game had for "playable to an ending" covered the ending RESOLVER and
	# not the playthrough. Found 2026-09-21 by this test reporting 1 distinct stage on a
	# route that progression.gd calls complete.
	#
	# So the walk below is the authored sequence itself, driven the way the props drive it:
	# on_note() for every document the player reads and _resolve_choice() for every
	# decision, in the order game.gd's own match statements advance the stage.
	game.get_node("HUD").call("hide_splash")
	var ending := ""
	for step in _SEQUENCE:
		var id: String = step[0]
		if step.size() > 1:
			# a choice: index 0 is the evidence-preserving branch, 1 the compliant one
			var pick: int = (step[1] if route == "witness" else step[2])
			game.call("_resolve_choice", id, pick, null)
		else:
			game.call("on_note", id)
		await process_frame
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
