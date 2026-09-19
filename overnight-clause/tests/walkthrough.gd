extends SceneTree

## Playing the game rather than calling its functions.
##
## tests/playthrough.gd drives the story by calling game.on_note("cassette") and friends
## directly, which proves the flag graph and the plate hooks but cannot prove a player can
## reach any of it. Everything a person actually does — the prop being spawned, being in a
## room with a floor under it, being inside the interact radius, being the thing the
## interact ray/focus picks, and its interact() opening what it should — is skipped there.
## This file does that half: for every stage, it finds the props the game spawned, walks
## the player to each one, asserts the game's own interact_target() picks it up, and
## triggers it through the prop, never through the game.
##
## What it is looking for is a dead end: a stage that spawns nothing, a prop standing in
## the void with no floor, a prop nothing can focus, or a run that stops advancing before
## an ending. Run for all three endings.
##
##   godot --headless --script tests/walkthrough.gd

const ROUTES := {
	"WITNESS":   {"stain": 0, "pipe": 0, "clause": 1, "final": 0},
	"COMPLICIT": {"stain": 1, "pipe": 1, "clause": 0, "final": 1},
	"404":       {"stain": 0, "pipe": 1, "clause": 1, "final": 0},
}

var failures: Array[String] = []
var game: Node
var hud: Node
var player: Node3D
var notes := 0
var choices := 0
var plates_shown: Array[String] = []
var endings: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(m: String) -> void:
	failures.append(m)


func _fresh() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	hud = game.get_node("HUD")
	player = game.get_node("Player")
	hud.hide_splash()
	player.locked = false


func _drain() -> void:
	var guard := 0
	while hud.is_vn_open() and not game.ending and guard < 900:
		if hud.plates and hud.plates.visible and not plates_shown.has(str(hud.plates.current)):
			if hud.plates.art.texture == null:
				_fail("plate %s came up with no picture" % hud.plates.current)
			plates_shown.append(str(hud.plates.current))
		hud.advance_vn()
		guard += 1
		await process_frame
	if guard >= 900:
		_fail("a scene never closed")
	player.locked = false


## Find somewhere a player could actually stand and use this prop, stand there, and look
## at it.
##
## Props are not all free-standing: a thermostat, a wall stain, a taped invoice and a
## kitchen kettle sit against the walls at z=0.3, and a fixed "half a metre behind it"
## offset puts the player inside the wall, where there is no floor and nothing in reach.
## That was this driver being wrong rather than the game, and it is the reason the check
## is written as a search: try the ring of approaches a player has, and require that at
## least one of them is a place to stand with the prop in range. Returns the distance at
## the spot it settled on, or -1.0 when there is no such spot — which is what "a prop you
## cannot get to" looks like from the floor.
##
## Standing is only half of it. player.gd's fallback focus has a facing cone (FACE_DOT,
## a 36.9 degree half-angle) so that props cannot be taken from behind, and this driver
## used to teleport the player around the ring without ever turning the body — whatever
## yaw the last prop left behind was the yaw every candidate spot was judged at. Of eight
## ring points spaced 45 degrees apart at most one can fall inside a 36.9 degree cone, so
## whether a prop passed came down to whether that one point happened to be the lucky one.
## 'clock' and 'letters' sit 3 cm apart on the same bedside table and only one of them was
## failing, which is the tell: nothing about the floor differs between two props at the
## same spot. Aim at the prop from each spot, the way the player would, and the check
## measures the game instead of the leftover yaw.
const APPROACH := 0.85

## Turn to face a point, body for yaw and head for pitch, exactly as the mouse would.
func _look_at_point(target: Vector3) -> void:
	var flat := Vector3(target.x - player.global_position.x, 0.0, target.z - player.global_position.z)
	if flat.length() > 0.001:
		# -basis.z is forward, so yaw theta gives forward (-sin theta, 0, -cos theta).
		player.rotation.y = atan2(-flat.x, -flat.z)
	var head: Node3D = player.get_node("Head")
	var cam: Node3D = head.get_node("Camera3D")
	var to_cam := target - cam.global_position
	if to_cam.length() > 0.001:
		player.pitch = clampf(asin(clampf(to_cam.normalized().y, -1.0, 1.0)), -1.25, 1.25)
		head.rotation.x = player.pitch


func _walk_to(prop: Node3D) -> float:
	var here := prop.global_position
	var stand_y: float = player.global_position.y
	var best := -1.0
	for i in 8:
		var a := TAU * float(i) / 8.0
		player.global_position = Vector3(here.x + sin(a) * APPROACH, stand_y, here.z + cos(a) * APPROACH)
		player.velocity = Vector3.ZERO
		for _f in 16:
			await physics_frame
		if not player.is_on_floor():
			continue
		_look_at_point(here)
		await process_frame
		var d: float = player.global_position.distance_to(here)
		if d < 6.5 and player.interact_target() != null:
			return d
	return best


func _live_props() -> Array:
	var out: Array = []
	for n in game.get_tree().get_nodes_in_group("interactable"):
		if is_instance_valid(n) and n.get("taken") != true and n.get("consumed") != true:
			out.append(n)
	return out


func _play(route: String) -> String:
	await _fresh()
	var picks: Dictionary = ROUTES[route]
	var guard := 0
	while not game.ending and guard < 60:
		guard += 1
		var props := _live_props()
		if props.is_empty():
			_fail("%s: stage %d spawned nothing to interact with — dead end" % [route, game.stage])
			break
		var stage_before: int = game.stage
		for prop in props:
			if game.ending:
				break
			var label: String = str(prop.get("note_id") if prop.get("note_id") else prop.get("choice_id"))
			var reach: float = await _walk_to(prop)
			if reach < 0.0:
				# Both halves of _walk_to fail the same way, so name both: nowhere on the
				# ring is floor, or nowhere on it does the game offer the prop to a player
				# standing there looking straight at it.
				_fail("%s: nowhere to stand and use '%s' at %s — no floor on the approach ring, or the game offers nothing from any of it" % [
					route, label, prop.global_position])
			var choice_id: String = str(prop.get("choice_id")) if prop.get("choice_id") != null else ""
			prop.interact(game)
			await process_frame
			await process_frame
			if choice_id != "":
				if not hud.is_choice_open():
					_fail("%s: choice %s did not open its panel" % [route, choice_id])
					continue
				if not picks.has(choice_id):
					_fail("%s: no answer written for choice %s" % [route, choice_id])
					continue
				choices += 1
				hud._pick(int(picks[choice_id]))
				await process_frame
				await process_frame
			else:
				notes += 1
			await _drain()
		if game.stage == stage_before and not game.ending:
			_fail("%s: stage %d did not advance after every prop in it was used" % [route, stage_before])
			break
	if not game.ending:
		_fail("%s: the run never reached an ending" % route)
	# The ending is a picture too, and the COMPLICIT one is the substituted slot: its own
	# render does not exist, so what has to be true is that a texture is on screen anyway.
	if hud.plates == null or hud.plates.art.texture == null:
		_fail("%s ending: no ending plate on screen (slot %s)" % [route, hud.plates.current if hud.plates else "-"])
	else:
		endings.append("%s->%s" % [route, hud.plates.current])
	var id: String = game.ending_id
	game.free()
	await process_frame
	return id


func _run() -> void:
	Unlock.simulate_free = false
	for route in ROUTES.keys():
		var got := await _play(route)
		if got != route:
			_fail("route %s resolved as %s" % [route, got])
	if failures.is_empty():
		print("WALKTHROUGH_OK routes=%d notes=%d choices=%d plates=%s endings=%s" % [
			ROUTES.size(), notes, choices, ", ".join(plates_shown), ", ".join(endings)])
		quit(0)
	for f in failures:
		push_error(f)
	quit(1)
