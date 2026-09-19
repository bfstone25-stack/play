## facing_probe.gd — pick the interaction cone by looking through it, not by arguing
## about dot products.
##
##   "$GODOT" --path . --resolution 1280x720 -s res://tests/facing_probe.gd
##   "$GODOT" --path . --resolution 1280x720 -s res://tests/facing_probe.gd -- --shots
##
## player.gd's interact_target() has two halves: an InteractRay that reaches 2.8 m down the
## exact centre of the screen, and a 6.5 m radius fallback so small paper props stay usable
## on a controller and on a low-resolution Web build. The radius half carried a facing gate
## that had been stubbed to `var face_ok := true` — so the fallback would hand back the
## nearest prop in the room whether or not it was in front of the player, or on screen, or
## behind them.
##
## Restoring the gate needs a number, and the only question that number really answers is:
## when a prop becomes takeable, where is it on the player's screen? So this harness runs
## the real scene, stands the player at authored viewpoints, and for each candidate cone
## reports exactly that — the prop's horizontal position in the frame at the moment it
## enters the cone, as a fraction of half the frame (0 = dead centre, 1 = the left or right
## edge of the picture, >1 = off screen and unreachable by eye).
##
## With --shots it also photographs the boundary, so the number can be judged by looking.
## Shots land in user://shots/facing/ (~/.local/share/godot/app_userdata/<project>/shots).
extends SceneTree

const CANDIDATES := [0.40, 0.50, 0.62, 0.70, 0.75, 0.80, 0.87]
## Where a player actually stands while working a room, and which stage fills it. Stage 3
## is the flat itself — nine props between the living room and the bathroom, the densest
## the game gets and the case the 6.5 m fallback was written for. The last viewpoint is the
## near field: standing half a metre off a prop, where the angle to it is widest and a tight
## cone would be felt as fighting the controls.
const VIEWPOINTS := [
	{"stage": 0, "at": Vector3(-5.2, 0.05, 5.2), "name": "hall-spawn"},
	{"stage": 3, "at": Vector3(4.6, 0.05, 4.2), "name": "living-room"},
	{"stage": 3, "at": Vector3(8.9, 0.05, 7.1), "name": "bathroom"},
	{"stage": 3, "at": Vector3(2.35, 0.05, 5.25), "name": "close-range"},
]
const OUT := "user://shots/facing"

var _shots := false
var _prompt_shots := false


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--shots":
			_shots = true
		if a == "--prompt-shots":
			_prompt_shots = true
	call_deferred("_run")


func _settle(frames := 8) -> void:
	for _f in frames:
		await process_frame


func _shot(name: String) -> void:
	await _settle(3)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("      shot %s.png" % name)


## The same flat-plane geometry interact_target() uses, kept here rather than calling into
## the player so a candidate can be tried without rebuilding.
func _dot_to(player: Node3D, prop: Node3D) -> float:
	var to: Vector3 = prop.global_position - player.global_position
	var flat := Vector3(to.x, 0.0, to.z)
	var look: Vector3 = player.facing()
	var look_flat := Vector3(look.x, 0.0, look.z)
	if flat.length() < 0.001 or look_flat.length() < 0.001:
		return 1.0
	return look_flat.normalized().dot(flat.normalized())


## Turn the player until the prop sits exactly on the cone edge, and report where that puts
## it in the frame. Returns [frame_fraction, yaw] — frame_fraction is |x - centre| over
## half the viewport width, so 1.0 is the edge of the picture.
func _edge_of(player: Node3D, camera: Camera3D, prop: Node3D, dot: float, sign_: float) -> Array:
	var to: Vector3 = prop.global_position - player.global_position
	var base := atan2(-to.x, -to.z)              # the yaw that points straight at it
	player.rotation.y = base + sign_ * acos(clampf(dot, -1.0, 1.0))
	await _settle(2)
	var p := camera.unproject_position(prop.global_position)
	var half := float(root.size.x) * 0.5
	return [absf(p.x - half) / half, player.rotation.y]


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		print("!! could not load the scene: %d" % err)
		quit(1)
		return
	await _settle(40)
	var game := current_scene
	if game == null:
		print("!! no scene")
		quit(1)
		return
	var player: Node3D = game.get_node("Player")
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var hud: CanvasItem = game.get_node("HUD")
	hud.visible = false
	player.set("locked", true)                   # nothing the desktop does can move it
	player.set("has_flashlight", true)
	player.set("light_on", true)
	player.get_node("Head/Camera3D/Flashlight").visible = true
	await _settle(10)

	# ---- the player-visible symptom: the HUD prompt with the player's back turned -------
	# game.gd drives hud.set_prompt() straight off interact_target(), so the prompt is the
	# bug as a player meets it. Photographed with the HUD left on, facing away from a prop
	# and then at it. Run it once with FACE_DOT loosened to see the stub's version.
	if _prompt_shots:
		game._spawn_stage(3)
		player.global_position = Vector3(4.6, 0.05, 4.2)
		hud.visible = true
		await _settle(6)
		var subj: Node3D = null
		for n in get_nodes_in_group("interactable"):
			if n is Node3D and player.global_position.distance_to(n.global_position) < 6.5:
				if subj == null or player.global_position.distance_to(n.global_position) < \
						player.global_position.distance_to(subj.global_position):
					subj = n
		var tos: Vector3 = subj.global_position - player.global_position
		player.rotation.y = atan2(-tos.x, -tos.z) + PI
		await _settle(20)
		print("   prompt with the back turned on %s: %s"
			% [subj.get_meta("story_id", subj.name), hud.prompt.text])
		await _shot("prompt-back-turned")
		player.rotation.y = atan2(-tos.x, -tos.z)
		await _settle(20)
		print("   prompt looking at it: %s" % hud.prompt.text)
		await _shot("prompt-looking-at-it")
		hud.visible = false
		quit(0)
		return

	var overall_ok := true

	# ---- the mapping from cone to frame, measured once ----------------------------------
	# A point's horizontal screen position depends only on the yaw between it and the
	# camera — not on its distance or its height — so this table is the same for every prop
	# in the game, and measuring it on one is measuring it on all of them.
	print("== the cone edge, as a fraction of half the frame (1.0 = the edge of the picture)")
	# The fraction depends on the aspect ratio, so the window it was measured in is part of
	# the measurement: at 1280x720 the horizontal half-frame is 51.7 deg, and a wider window
	# only ever moves a given cone further inside the picture.
	print("   window %dx%d, camera fov %.0f (vertical), horizontal half-frame %.1f deg"
		% [root.size.x, root.size.y, camera.fov,
			rad_to_deg(atan(tan(deg_to_rad(camera.fov) * 0.5) * float(root.size.x) / float(root.size.y)))])
	var ref_prop: Node3D = null
	for n in get_nodes_in_group("interactable"):
		if n is Node3D:
			ref_prop = n
			break
	if ref_prop != null:
		for dot in CANDIDATES:
			var r := await _edge_of(player, camera, ref_prop, dot, 1.0)
			print("   dot %.2f   half-angle %5.1f deg   frame %.2f"
				% [dot, rad_to_deg(acos(dot)), float(r[0])])

	var spawned := {0: true}                     # stage 0 is already in the scene
	for vp in VIEWPOINTS:
		var stage := int(vp["stage"])
		if not spawned.has(stage):
			spawned[stage] = true
			game._spawn_stage(stage)
		player.global_position = vp["at"]
		await _settle(6)
		var props: Array = []
		for n in get_nodes_in_group("interactable"):
			if n is Node3D and player.global_position.distance_to(n.global_position) < 6.5:
				props.append(n)
		print("")
		print("== %s: %d props within the 6.5 m fallback, eye %.2f m, standing at %v"
			% [vp["name"], props.size(), camera.global_position.y, player.global_position])
		if props.is_empty():
			print("   (nothing in range — viewpoint skipped)")
			continue

		# ---- 1. what the gate does when the player's back is turned ---------------------
		var nearest: Node3D = props[0]
		for n in props:
			if player.global_position.distance_to(n.global_position) < \
					player.global_position.distance_to(nearest.global_position):
				nearest = n
		var to0: Vector3 = nearest.global_position - player.global_position
		player.rotation.y = atan2(-to0.x, -to0.z) + PI       # 180 degrees off it
		await _settle(4)
		var behind = player.interact_target()
		# Turning your back on the nearest prop must take it off the table. Something else
		# in the room may legitimately be in front of you now — what must never happen is
		# a prop being offered from outside the cone.
		var behind_name := "null" if behind == null else str(behind.get_meta("story_id", behind.name))
		var behind_dot := 1.0 if behind == null else _dot_to(player, behind)
		print("   back turned on %s (dot %.2f): interact_target() -> %s (dot %.2f)"
			% [nearest.get_meta("story_id", nearest.name), _dot_to(player, nearest),
				behind_name, behind_dot])
		if behind == nearest:
			print("   !! the prop behind the player is still offered")
			overall_ok = false
		if behind != null and behind_dot < 0.79:
			print("   !! %s was offered from outside the cone" % behind_name)
			overall_ok = false
		if _shots:
			await _shot("%s-back-turned" % vp["name"])

		# ---- 3. photograph the boundary -------------------------------------------------
		if _shots:
			var subject: Node3D = props[0]
			for p in props:
				var dd := player.global_position.distance_to(p.global_position)
				if dd > 2.9 and dd < 6.5:
					subject = p            # past the ray's reach: the fallback's own case
					break
			print("   photographing the boundary on %s (%.1f m away)"
				% [str(subject.get_meta("story_id", subject.name)),
					player.global_position.distance_to(subject.global_position)])
			for dot in CANDIDATES:
				await _edge_of(player, camera, subject, dot, 1.0)
				await _shot("%s-edge-%03d" % [vp["name"], int(dot * 100.0)])
			var toc: Vector3 = subject.global_position - player.global_position
			player.rotation.y = atan2(-toc.x, -toc.z)
			await _shot("%s-centred" % vp["name"])

		# ---- 4. what the shipped constant actually does ----------------------------------
		var consts: Dictionary = player.get_script().get_script_constant_map()
		var shipped = consts.get("FACE_DOT")
		if shipped == null:
			print("   player.gd has no FACE_DOT — the gate is still stubbed to true")
			overall_ok = false
			continue
		var ok := 0
		var wrong := 0
		for p in props:
			var to2: Vector3 = p.global_position - player.global_position
			player.rotation.y = atan2(-to2.x, -to2.z)        # squarely at it
			await _settle(2)
			var got = player.interact_target()
			if got == p:
				ok += 1
			elif got != null and got is Node3D and _dot_to(player, got) >= 0.79 and \
					player.global_position.distance_to((got as Node3D).global_position) < \
					player.global_position.distance_to(p.global_position):
				# The documented rule: inside the cone, the nearest active prop wins. Worth
				# printing rather than hiding, but it is not the facing gate failing.
				ok += 1
				print("   .. %s is in the cone but %s is nearer and takes it"
					% [p.get_meta("story_id", p.name), got.get_meta("story_id", got.name)])
			else:
				print("   !! looking straight at %s and it is not offered (got %s)"
					% [p.get_meta("story_id", p.name), got])
			player.rotation.y += PI                          # and with the back turned
			await _settle(2)
			if player.interact_target() == p:
				wrong += 1
				print("   !! %s is still offered from behind" % p.get_meta("story_id", p.name))
		# The near field: standing on a prop, where the pitch clamp means it cannot be
		# centred and the horizontal direction to it is meaningless.
		var under: Node3D = props[0]
		player.global_position = Vector3(under.global_position.x + 0.12,
			player.global_position.y, under.global_position.z + 0.12)
		await _settle(4)
		player.rotation.y = 0.0
		player.get_node("Head").rotation.x = -1.25       # looking down as far as it goes
		await _settle(2)
		var near_ok: bool = player.interact_target() == under
		player.get_node("Head").rotation.x = 0.0
		player.global_position = vp["at"]
		await _settle(2)
		print("   FACE_DOT %.2f (%.1f deg): %d/%d offered when looked at, %d from behind, underfoot %s"
			% [float(shipped), rad_to_deg(acos(float(shipped))), ok, props.size(), wrong,
				"offered" if near_ok else "NOT OFFERED"])
		if ok != props.size() or wrong != 0 or not near_ok:
			overall_ok = false

	print("")
	print("FACING_OK" if overall_ok else "!! FACING NOT OK")
	quit(0 if overall_ok else 1)
