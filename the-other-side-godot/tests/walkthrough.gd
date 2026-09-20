extends Node

## Drive the whole game and photograph it — all four beats, HUD included.
##
## tests/shots.gd photographs four empty camera positions with the HUD switched OFF. That
## is a picture of the level, not of the game, and it is why beats 3 and 4 could be
## "built" for a day without anyone having seen them: nothing in the repo ever ran the
## tenant resolve, the exchange, the choice, or the ending board.
##
## This runs the real methods — game.look_in_mirror(), game.open_402(), the tenant's own
## _physics_process resolve, hud.show_dialogue() answered with real InputEvents — so a
## frame here is evidence the beat happened, not evidence the scene loads.
##
## Run it as a SCENE, not with --script. GDScript binds autoload identifiers at parse
## time from the list the engine builds at startup, and `-s` never builds that list: every
## script that mentions Gate — game.gd, mirror.gd, and everything that depends on them —
## fails to compile, and the capture quietly photographs an empty room instead. Standing a
## node named Gate up by hand does not help; the failure is in the parser, not the lookup.
##
##   ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
##     --path play/the-other-side-godot res://tests/walkthrough.tscn
##
## Frames land in OUT_DIR. Read every one at full size and again at 390 px
## (ops/adult_forks/TITLE_SCREENS.md) — this script cannot tell you whether they are good.

const OUT_DIR := "/tmp/other-side-walkthrough"
const W := 1280
const H := 720

var scene: Node
var game: Node
var player: Node3D
var hud: Node
var shot_n := 0


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(W, H))
	# One frame of daylight first: root is still setting up its own children during our
	# _ready(), and add_child() into a busy parent fails outright — the capture then
	# photographs an empty viewport and reports every beat as "no mirror in the scene".
	await get_tree().process_frame
	var packed := load("res://scenes/main.tscn")
	scene = packed.instantiate()
	get_tree().root.add_child(scene)
	game = scene
	player = scene.get_node("Player")
	hud = scene.get_node("HUD")
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await _settle(8)
	# The splash is a click-to-start overlay; the walkthrough starts past it.
	hud.hide_splash()
	await _run()
	get_tree().quit(0)


## Hold the player still for `n` frames and force a draw each one. Twenty is not excessive:
## the bathroom spot casts a real shadow now, the grain shader animates, and the tenant's
## alpha lerps toward its target — a frame grabbed too early catches all three mid-way.
func _settle(n: int) -> void:
	for i in n:
		RenderingServer.force_draw()
		await get_tree().process_frame


func _shot(name: String) -> void:
	shot_n += 1
	await _settle(14)
	var img := get_tree().root.get_viewport().get_texture().get_image()
	var path := "%s/%02d_%s.png" % [OUT_DIR, shot_n, name]
	img.save_png(path)
	print("SHOT %s  phase=%s chapter=%s choice=%s ending=%s"
		% [path, str(game.get("phase")), str(game.get("chapter")),
		   str(game.get("choice")), str(game.get("ending"))])


## Put the player somewhere and point them at something. Teleport rather than walk: the
## walk is the player's job, the capture's job is to be at the spot deterministically.
func _place(pos: Vector3, look: Vector3) -> void:
	player.set("locked", true)
	player.global_position = pos
	player.velocity = Vector3.ZERO
	var flat := Vector3(look.x, pos.y, look.z)
	if flat.distance_to(pos) > 0.05:
		player.look_at(flat, Vector3.UP)
		player.rotation.x = 0.0
		player.rotation.z = 0.0
	var head: Node3D = player.get_node("Head")
	head.rotation.x = clampf(atan2(look.y - (pos.y + 1.55), Vector2(look.x - pos.x, look.z - pos.z).length()), -1.2, 1.2)
	await _settle(4)


## Wait out the title card and the note, up to twelve seconds of game time.
func _wait_clear() -> void:
	for i in 900:
		await _settle(1)
		var card: Control = hud.get("title_card")
		var note: Control = hud.get("note_card")
		if (card == null or not card.visible) and (note == null or not note.visible):
			return


## Press a key at the HUD's dialogue handler, the way _unhandled_input would.
func _key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	hud.dialogue_input(ev)
	await _settle(3)


func _run() -> void:
	# ---- Beat 1: wake in 401, and the mirror ----------------------------------------
	await _place(Vector3(-4.6, 0.05, 1.6), Vector3(-7.9, 1.3, 4.6))
	await _shot("wake")

	# Let the title card and the opening note time out before the next two frames. They
	# belong in 01, where they are the beat; on top of the mirror they are just covering
	# the thing the screenshot exists to show.
	await _wait_clear()

	# Stand in the front room looking THROUGH the bathroom doorway. This is the frame the
	# whole pass is about: it has to show a floor, a doorway, a lit room beyond it.
	await _place(Vector3(-6.8, 0.05, 3.4), Vector3(-8.1, 1.35, 5.2))
	await _shot("bathroom_door")

	# At the mirror, and no closer. interact_target() measures from the player's FEET, so
	# the 1.85 m radius is spent on the mirror's 1.43 m of height before any of it is spent
	# on standing back: 1.09 m of floor is all the prompt allows. Closer than this and the
	# bezel fills the frame, which is the composition the first capture shipped.
	# From the doorway, looking in at an angle. Two things make this the frame rather than
	# a nose-to-bezel close-up: interact_target() also casts a 2.8 m ray from the camera,
	# so the prompt survives a standoff the 1.85 m proximity radius would not; and the
	# bathroom is only 1.95 m wide, so backing straight off along +x puts the camera THROUGH
	# the side wall at x=-6.96 and photographs a black frame with a lit patch in it. Stay
	# inside the room and use the doorway for the angle.
	await _place(Vector3(-7.55, 0.05, 4.8), Vector3(-8.84, 1.42, 5.66))
	await _shot("mirror")

	var mirror := get_tree().get_first_node_in_group("mirror")
	if mirror == null:
		push_error("no mirror in the scene")
		return
	mirror.interact(game)
	await _settle(40)
	await _shot("mirror_looked")

	# ---- Beat 2: the hall, and 402 ---------------------------------------------------
	game.open_401()
	# From the HALL, not from inside 401. The door plate faces the hall, so photographing
	# the open door from your own side of it catches the back of the plate and "401" comes
	# out mirrored.
	await _place(Vector3(-0.3, 0.05, 3.6), Vector3(-1.75, 1.35, 2.4))
	await _shot("401_open")

	await _place(Vector3(0.0, 0.05, 6.4), Vector3(1.6, 1.35, 8.05))
	await _shot("402_closed")

	game.open_402()
	await _settle(30)
	await _shot("402_opens")

	await _place(Vector3(2.6, 0.05, 8.05), Vector3(6.6, 1.25, 8.05))
	await _shot("402_inside")

	await _place(Vector3(4.5, 0.05, 5.6), Vector3(4.4, 1.35, 4.1))
	await _shot("402_print")

	# ---- Beat 3: the tenant resolves, then the exchange ------------------------------
	# The tenant activates on entering 402 and resolves by distance in its own
	# _physics_process. Walk the camera in on a curve and let it do that, rather than
	# poking its alpha — the resolve IS the beat.
	var tenant := get_tree().get_first_node_in_group("tenant") as Node3D
	if tenant == null:
		push_error("no tenant in the scene")
		return
	# Let him take up his post in 402's doorway before reading his position off him.
	await _settle(30)
	for step in [3.6, 2.6]:
		var from: Vector3 = tenant.global_position - Vector3(0, 0, 1) * step
		await _place(Vector3(from.x, 0.05, from.z), tenant.global_position)
		await _settle(60)
	await _shot("tenant_resolving")
	print("  tenant resolved=%.2f" % float(tenant.get("resolved")))

	# Inside 1.7 m the tenant calls game.confront() itself.
	var near: Vector3 = tenant.global_position - Vector3(0, 0, 1) * 1.35
	await _place(Vector3(near.x, 0.05, near.z), tenant.global_position)
	player.set("locked", false)
	for i in 240:
		await _settle(1)
		if bool(game.get("confronting")):
			break
	if not bool(game.get("confronting")):
		push_error("tenant never triggered confront(); resolved=%.2f dist=%.2f"
			% [float(tenant.get("resolved")),
			   player.global_position.distance_to(tenant.global_position)])
		return
	# confront() aims the player at the tenant itself. Whether it actually worked is not
	# something to assume — a dot product below zero means the exchange is playing out
	# behind the camera, which is what the first run of this script captured.
	await _settle(20)
	var to_him: Vector3 = tenant.global_position - player.global_position
	to_him.y = 0.0
	var dot: float = player.facing().dot(to_him.normalized())
	print("  confront facing dot=%.2f dist=%.2f tenant=(%.1f, %.1f) player=(%.1f, %.1f)"
		% [dot, to_him.length(), tenant.global_position.x, tenant.global_position.z,
		   player.global_position.x, player.global_position.z])
	if dot < 0.6:
		push_error("the tenant is not in frame at the confrontation (dot=%.2f)" % dot)
	if tenant.global_position.x < 1.85:
		push_error("the confrontation is happening in 401, not across the hall in 402")
	await _shot("confront")

	# Four lines, click-advanced, then the choice on the last one.
	for i in 3:
		await _key(KEY_SPACE)
		await _settle(6)
	await _shot("choice")

	# 1 = keep him in the mirror. The branch that has to leave the plate in the glass.
	await _key(KEY_1)
	await _settle(40)
	await _shot("after_choice")

	# ---- Beat 4: back to 401, and the mirror keeps its image -------------------------
	# Same framing as the beat-1 mirror shot, deliberately: this frame's whole job is to be
	# compared with that one, and it also keeps the room's colour in the picture rather
	# than filling the screen with the plate (which photographs as a washed-out frame).
	await _place(Vector3(-7.55, 0.05, 4.8), Vector3(-8.84, 1.42, 5.66))
	await _settle(40)
	await _shot("mirror_after_kept")
	var kept: bool = bool(mirror.get("kept"))
	var plate_up: bool = bool(mirror.get("quad").visible)
	print("  mirror kept=%s plate_visible=%s" % [str(kept), str(plate_up)])

	# The ending fires on its own six seconds after the choice; wait it out rather than
	# calling _begin_ending(), so the clear state is the one the player actually gets.
	for i in 900:
		await _settle(1)
		if bool(game.get("ending")):
			break
	if not bool(game.get("ending")):
		push_error("the ending never began")
		return
	await _settle(60)
	await _shot("end")
	print("WALKTHROUGH_OK")

