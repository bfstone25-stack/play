extends Node3D

## The Other Side — the adult night twin of Across the Hall (ops/adult_forks/across-the-hall.md §2).
##
## The one rule that makes it a different world (ops/adult_forks/TWO_WORLDS.md): in Across
## the Hall there was never anyone across the hall. Here the mirror shows the neighbour,
## and the neighbour is you as you would be if you claimed what you want — a rendered
## adult, and the game is walking toward them. Cut the figure and the rule has no payoff.
##
## Four beats, playable end to end:
##   1. wake in 401, reach the bathroom mirror — it shows a figure that moves when you do not
##   2. cross the hall — 402 opens this time; it is 401 mirrored, one real thing per room
##   3. the tenant resolves into a rendered person as you approach; an exchange, a choice
##   4. the choice decides whether the mirror keeps its image; the clear state; the board

const NOTES := {
	"wake": "02:17. You are on your own couch in your own coat.\nThe bathroom light is on. You did not leave it on.",
	"mirror1": "It is not you. It is what you would look like if you had said yes.\nIt is not moving. It only moves when you stop.",
	"mirror2": "It turned its head toward the door.\nIt wants you to go across the hall.",
	"door402": "The door opens this time.\nThe air inside already knows your shampoo.",
	"flat402": "It is your flat, laid out backwards.\nEverything you own is here. One thing in each room is not yours.\nHe is in the bathroom doorway. Walk to him.",
	"kept": "You go back to 401. The mirror still shows him.\nHe raises a hand when you do, half a second late.\nYou are two people now, and you both live here.",
	"refused": "You go back to 401. The mirror is glass again.\nIt shows the wall behind you and nothing in front of it.\nThe half of you that wanted things is across the hall, with the door shut.",
}

## Three lines and a choice, through the click-to-advance panel (hud.show_dialogue).
const CONFRONT_LINES := [
	"He has your face, rested. He has your hands, not shaking. He is not wearing your coat.",
	"\"You came across. Six years, and you finally came across.\"",
	"\"I am not a stranger. I am the half you left on this side of the door. Everything you wanted and did not take — it is all still here, and it is warm.\"",
	"\"So. Do you want to stay on this side tonight, or do you want your mirror back?\"",
]
const CONFRONT_CHOICES := ["Stay. Keep him in the mirror.", "Go home. Make the glass empty."]

var items := {}
var phase := 0
var chapter := 1
var ending := false
var apt401_open := false
var apt402_open := false
var visited_402 := false
var mirror_seen := false
var confronting := false
var choice := -1
var await_restart := false
var caught_t := 0.0
var title_t := 5.5

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var tape_player: AudioStreamPlayer = $Tape
@onready var drone: AudioStreamPlayer = $Drone
@onready var sfx: AudioStreamPlayer3D = $Sfx
var unlock: Node

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	unlock = Node.new()
	unlock.set_script(preload("res://scripts/unlock.gd"))
	add_child(unlock)
	_setup_audio()
	_spawn_pickups()
	var amb := Node.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	add_child(amb)
	hud.show_title("The Other Side\nI — You wake in 401. 02:17.")
	hud.set_objective("I  Home. The bathroom light is on. Go and look in the mirror.")
	if OS.has_feature("web"):
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.004
		env.ambient_light_energy = 0.62
		env.tonemap_exposure = 1.28
	else:
		player.capture_mouse()
	# The mirror is the first thing lit: the plum room, one hot bulb through the bathroom door.
	_dim_hall(0.9)
	show_note(NOTES["wake"])

func _setup_audio() -> void:
	drone.stream = _tone_stream(44.0, 0.32)
	drone.volume_db = -20.0
	drone.play()
	tape_player.stream = _tape_stream()

func _unhandled_input(event: InputEvent) -> void:
	if hud.dialogue_input(event):
		return
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if ending or confronting:
		return
	if hud and hud.has_method("hide_splash") and hud.splash and hud.splash.visible:
		if event is InputEventMouseButton and event.pressed:
			hud.hide_splash()
			player.capture_mouse()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t = player.interact_target()
		if t:
			t.interact(self)
			return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		var t = player.interact_target()
		if t:
			t.interact(self)

## Web drive hook for playing the build from a script: window.__cmd = "goto x z yaw" |
## "use" | "look dx". Read once a frame, cleared after. Costs nothing without it and does
## nothing off the web — the same shape as Gate's ?warp=board.
func _drive() -> void:
	if not OS.has_feature("web"):
		return
	var c = JavaScriptBridge.eval("(function(){var c=window.__cmd||'';window.__cmd='';return c;})()")
	var cmd := str(c) if c != null else ""
	if cmd == "":
		return
	var parts := cmd.split(" ")
	match parts[0]:
		"goto":
			player.global_position = Vector3(float(parts[1]), 0.05, float(parts[2]))
			player.rotation.y = float(parts[3])
			player.pitch = 0.0
			player.head.rotation.x = 0.0
			player.velocity = Vector3.ZERO
		"look":
			player.rotate_y(float(parts[1]))
		"use":
			var t = player.interact_target()
			if t:
				t.interact(self)
		"state":
			JavaScriptBridge.eval("window.__state=%s" % JSON.stringify({
				"phase": phase, "chapter": chapter, "choice": choice, "ending": ending,
				"x": player.global_position.x, "z": player.global_position.z,
				"confronting": confronting, "prompt": hud.prompt.text, "objective": hud.objective.text}))

func _process(delta: float) -> void:
	_drive()
	if title_t > 0.0:
		title_t -= delta
		if title_t <= 0.0:
			hud.hide_title()
	if ending:
		return
	_track_402()
	var t = player.interact_target()
	if t and t.get("prompt") and not confronting:
		hud.set_prompt("E / click  " + str(t.prompt))
	else:
		hud.set_prompt("")
	if caught_t > 0.0:
		caught_t -= delta
		hud.set_fear(0.55)
		if caught_t <= 0.0:
			_reset_catch()
	else:
		hud.set_fear(0.35 if confronting else 0.0)

func _spawn_pickups() -> void:
	# The flashlight is on your own table this time; you live here.
	_pickup(Vector3(-3.25, 0.46, 2.4), "flashlight", "Take flashlight", "", Color(0.75, 0.72, 0.35), Vector3(0.28, 0.07, 0.08))
	_inspect(Vector3(-5.9, 0.85, 0.7), "clock", "Check the clock", "02:17. The second hand is not stuck.\nIt is waiting for you to catch up.", Color(0.2, 0.18, 0.16), Vector3(0.16, 0.16, 0.08))
	_inspect(Vector3(3.55, 0.56, 8.05), "lease", "Read the lease on the table", "A lease for 402 in your handwriting, dated six years ago.\nThe signature is steadier than yours is now.", Color(0.92, 0.88, 0.72), Vector3(0.32, 0.03, 0.42))
func _inspect(pos: Vector3, id: String, prompt: String, note: String, color: Color, size: Vector3) -> void:
	var p := StaticBody3D.new()
	p.set_script(preload("res://scripts/inspect.gd"))
	p.position = pos
	p.inspect_id = id
	p.prompt = prompt
	p.note_text = note
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	p.add_child(mesh)
	var tag := Label3D.new()
	tag.text = prompt
	tag.font_size = 36
	tag.pixel_size = 0.0035
	tag.width = 400
	tag.position = Vector3(0, size.y * 0.5 + 0.14, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.9, 0.8, 0.58)
	UiFont.apply_3d(tag)
	p.add_child(tag)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.22, 0.22, 0.22)
	col.shape = sh
	p.add_child(col)
	p.collision_layer = 1
	p.collision_mask = 0
	add_child(p)

func _pickup(pos: Vector3, id: String, prompt: String, note: String, color: Color, size: Vector3) -> void:
	var p := StaticBody3D.new()
	p.set_script(preload("res://scripts/pickup.gd"))
	p.position = pos
	p.item_id = id
	p.prompt = prompt
	p.note_text = note
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	p.add_child(mesh)
	var tag := Label3D.new()
	tag.text = prompt
	tag.font_size = 52
	tag.pixel_size = 0.004
	tag.position = Vector3(0, size.y * 0.5 + 0.14, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.95, 0.86, 0.62)
	UiFont.apply_3d(tag)
	p.add_child(tag)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.25, 0.25, 0.25)
	col.shape = sh
	p.add_child(col)
	p.collision_layer = 1
	p.collision_mask = 0
	add_child(p)

func give_item(id: String) -> void:
	items[id] = true
	click_sfx()
	if id == "flashlight":
		player.give_flashlight()

func show_note(text: String) -> void:
	hud.show_note(text)

func inspect(id: String, text: String) -> void:
	show_note(text)
	click_sfx()

## Beat 1. Looking is the first act. On the web the figure is the censored plate until the
## page's gate reports a rendered sponsor creative AND the gateway ticket lands the bytes
## (scripts/mirror.gd, scripts/unlock.gd); a gate that passes with no creative unlocks nothing.
func look_in_mirror(mirror: Node) -> void:
	click_sfx()
	if not mirror_seen:
		mirror_seen = true
		phase = maxi(phase, 1)
		show_note(NOTES["mirror1"])
		hud.note_t = 7.0
		await get_tree().create_timer(4.5).timeout
		show_note(NOTES["mirror2"])
		_set_chapter(2, "II  The hall. Open your door. Cross. 402 opens this time.")
		knock_behind_401()
		return
	if Gate.is_web() and not mirror.unlocked:
		player.locked = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.captured = false
		var ok: bool = await mirror.try_unlock(unlock)
		player.locked = false
		player.capture_mouse()
		show_note("The glass clears." if ok else "The glass stays fogged. Nothing was shown, so nothing is shown.")
		return
	show_note(NOTES["mirror1"] if choice < 0 else (NOTES["kept"] if choice == 0 else NOTES["refused"]))

func open_401() -> void:
	if apt401_open:
		return
	apt401_open = true
	click_sfx()
	var world := get_node_or_null("World")
	if world and world.has_method("open_door"):
		world.open_door("401")
	show_note("Your door. The hall is the colour of a bruise.\n402 is opposite. Knock.")

## Beat 2. In Across the Hall this door was always open and 401 was locked; here it is
## the other way round, and it opens because you looked.
func open_402() -> void:
	if apt402_open:
		return
	apt402_open = true
	phase = maxi(phase, 2)
	click_sfx()
	var world := get_node_or_null("World")
	if world and world.has_method("open_door"):
		world.open_door("402")
	show_note(NOTES["door402"])
	_set_chapter(3, "III  402. Your flat, mirrored. Find him.")

func _track_402() -> void:
	if player.global_position.x > 1.9 and not visited_402:
		visited_402 = true
		show_note(NOTES["flat402"])
		hud.note_t = 9.0

## Beat 3. The tenant has resolved and is within arm's reach.
func confront() -> void:
	if confronting or choice >= 0 or ending:
		return
	confronting = true
	player.locked = true
	hud.set_prompt("")
	drone.volume_db = -8.0
	hud.show_title("III — The other side of your door")
	title_t = 3.0
	var tenant := get_tree().get_first_node_in_group("tenant") as Node3D
	if tenant:
		player.look_at(Vector3(tenant.global_position.x, player.global_position.y, tenant.global_position.z), Vector3.UP)
		player.rotation.x = 0.0
		player.rotation.z = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.captured = false
	var picked: int = await hud.show_dialogue(CONFRONT_LINES, CONFRONT_CHOICES)
	choice = picked
	click_sfx()
	player.locked = false
	player.capture_mouse()
	confronting = false
	_resolve(picked)

## Beat 4. The choice decides whether the mirror keeps its image. Then the clear state.
func _resolve(picked: int) -> void:
	phase = 4
	for m in get_tree().get_nodes_in_group("mirror"):
		m.set_kept(picked == 0)
	if picked == 0:
		_set_chapter(4, "IV  Kept. He stays in the glass. Go home and look.")
		show_note("\"Good.\" He does not touch you. He does not have to.\nThe bathroom light in 401 goes on by itself.")
	else:
		_set_chapter(4, "IV  Refused. The glass empties. Go home and look.")
		show_note("\"All right.\" He steps back into the doorway.\nBehind you, across the hall, something in 401 goes quiet.")
	hud.note_t = 8.0
	await get_tree().create_timer(6.0).timeout
	_begin_ending()

func _set_chapter(n: int, objective: String) -> void:
	if n > chapter:
		if n >= 3:
			Gate.block("ch%d" % n, "Chapter %d" % n)   # dual-track (ops/DUAL_TRACK.md)
		chapter = n
		hud.show_title("Chapter %d" % n)
		title_t = 3.2
	hud.set_objective(objective)

func _begin_ending() -> void:
	ending = true
	tape_player.play()
	_dim_hall(0.35)
	show_note(NOTES["kept"] if choice == 0 else NOTES["refused"])
	hud.note_t = 40.0
	player.locked = true
	drone.volume_db = -6.0
	hud.set_objective("Episode I-X complete. " + ("Two of you live here now." if choice == 0 else "One of you lives here now."))
	hud.set_prompt("R restart")
	hud.show_title("The Other Side\n" + ("He is in the mirror." if choice == 0 else "The mirror is empty."))
	await_restart = true
	# End of the run: the cross-promotion board (play/_shared/board.js). Adult fork, adult
	# host only — board.js refuses to draw the adult board anywhere else, and this build is
	# never served from blazecore.dev (ops/check_adsense_isolation.py).
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.captured = false
	Gate.board_offer_more("adult")

func knock_behind_401() -> void:
	sfx.global_position = Vector3(-1.6, 1.2, 2.4)
	sfx.stream = _click_stream(70.0, 0.16)
	sfx.volume_db = -4.0
	sfx.play()

func on_tenant_seen() -> void:
	sfx.stream = _click_stream(220.0, 0.08)
	sfx.volume_db = -8.0
	sfx.play()
	hud.set_fear(0.35)

func caught() -> void:
	if ending or caught_t > 0.0 or confronting:
		return
	caught_t = 2.2
	player.locked = true
	hud.show_note("Someone covers your eyes from behind.\nThe hands are the same temperature as yours.")
	drone.volume_db = -3.0

func _reset_catch() -> void:
	player.locked = false
	drone.volume_db = -20.0
	hud.set_objective("He let go. He is waiting where you were going anyway.")

func _dim_hall(energy: float) -> void:
	for n in get_tree().get_nodes_in_group("hall_light"):
		if n is OmniLight3D:
			(n as OmniLight3D).light_energy = energy

func footstep(pos: Vector3) -> void:
	sfx.global_position = pos
	sfx.stream = _click_stream(randf_range(85.0, 130.0), 0.055)
	sfx.volume_db = -15.0
	sfx.play()

func click_sfx() -> void:
	sfx.stream = _click_stream(420.0, 0.04)
	sfx.volume_db = -10.0
	sfx.play()

func _tone_stream(hz: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := sr * 4
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := sin(TAU * hz * i / sr) * amp + sin(TAU * (hz * 0.5) * i / sr) * amp * 0.4
		s += sin(TAU * 0.2 * i / sr) * 0.05
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = n
	return st

func _click_stream(hz: float, dur: float) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / float(n)
		var s := sin(TAU * hz * i / sr) * env * env
		var v := int(clampf(s, -1.0, 1.0) * 20000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st

func _tape_stream() -> AudioStreamWAV:
	var sr := 22050
	var n := sr * 7
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var hiss := (randf() - 0.5) * 0.1
		var breath := 0.0
		if t > 0.8:
			breath = sin(TAU * 1.7 * t) * 0.16 * maxf(0.0, sin(TAU * 0.22 * t))
		var voice := 0.0
		if t > 2.8 and t < 6.0:
			voice = sin(TAU * 98.0 * t) * 0.05 * sin(TAU * 2.4 * t)
		var s := hiss + breath + voice
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st
