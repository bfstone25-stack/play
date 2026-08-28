extends Node3D

const NOTES := {
	"note1": "Management says 402 vacated three months ago.\nThe vacancy form is signed with my name.\nThe handwriting is steadier than mine is now.",
	"note2": "401's calendar is still on February 17.\nThe clock is frozen at 02:17.\nYou already came home. You just used the other door.",
	"tape": "No date. The cassette is still warm.\nThe spine is labeled 401 in your handwriting.",
	"key": "A key on a ring with a photo of this hallway.\nThe tag says HOME. The teeth match 401.",
	"clock": "The second hand is not stuck.\nIt is waiting for you to catch up.",
	"end": "The breathing on the tape matches your chest.\nThere was never anyone across the hall.\nYou only left the half of yourself you would not claim behind an open door.",
}

var items := {}
var phase := 0
var chapter := 1
var ending := false
var apt401_open := false
var visited_401 := false
var overlap := false
var await_restart := false
var caught_t := 0.0
var title_t := 5.5

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var tape_player: AudioStreamPlayer = $Tape
@onready var drone: AudioStreamPlayer = $Drone
@onready var sfx: AudioStreamPlayer3D = $Sfx

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	_setup_audio()
	_spawn_pickups()
	var amb := Node.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	add_child(amb)
	hud.show_title("Chapter 1 — The hall. 02:17, again.")
	if OS.has_feature("web"):
		hud.set_objective("Ch.1 Hall. Click to capture the mouse. Take the flashlight.")
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.004
		env.ambient_light_energy = 0.62
		env.tonemap_exposure = 1.28
	else:
		hud.set_objective("Ch.1 Hall. Take the flashlight. 401 is locked. 402 is open.")
		player.capture_mouse()
	if OS.has_feature("full_game"):
		var unlocked := _saved_full_episode()
		if unlocked >= 2:
			hud.set_objective(
				"Episode I. Press C to continue at Episode %d, or take the flashlight."
				% unlocked
			)

func _setup_audio() -> void:
	drone.stream = _tone_stream(44.0, 0.32)
	drone.volume_db = -20.0
	drone.play()
	tape_player.stream = _tape_stream()

func _unhandled_input(event: InputEvent) -> void:
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		elif (
			OS.has_feature("full_game")
			and event is InputEventKey
			and event.pressed
			and not event.echo
			and event.physical_keycode == KEY_N
		):
			get_tree().change_scene_to_file("res://scenes/full_campaign.tscn")
		return
	if ending:
		return
	if (
		OS.has_feature("full_game")
		and _saved_full_episode() >= 2
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.physical_keycode == KEY_C
	):
		get_tree().change_scene_to_file("res://scenes/full_campaign.tscn")
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

func _process(delta: float) -> void:
	if title_t > 0.0:
		title_t -= delta
		if title_t <= 0.0:
			hud.hide_title()
	if ending:
		return
	_track_401()
	var t = player.interact_target()
	if t and t.get("prompt"):
		hud.set_prompt("E / click  " + str(t.prompt))
	else:
		hud.set_prompt("")
	if caught_t > 0.0:
		caught_t -= delta
		hud.set_fear(0.55)
		if caught_t <= 0.0:
			_reset_catch()
	else:
		hud.set_fear(0.0)

func _spawn_pickups() -> void:
	_pickup(Vector3(0.55, 0.06, 2.6), "flashlight", "Take flashlight", "", Color(0.75, 0.72, 0.35), Vector3(0.28, 0.07, 0.08))
	_pickup(Vector3(3.05, 0.48, 8.05), "note", "Read vacancy notice", NOTES["note1"], Color(0.92, 0.88, 0.72), Vector3(0.32, 0.03, 0.42))
	_pickup(Vector3(7.85, 0.58, 11.35), "tape", "Take cassette", NOTES["tape"], Color(0.55, 0.12, 0.1), Vector3(0.2, 0.06, 0.12))
	_pickup(Vector3(8.2, 0.52, 11.55), "key", "Take 401 key", NOTES["key"], Color(0.72, 0.62, 0.22), Vector3(0.12, 0.04, 0.22))
	_inspect(Vector3(-3.25, 0.72, 2.15), "calendar", "Read calendar", NOTES["note2"], Color(0.85, 0.78, 0.62), Vector3(0.28, 0.36, 0.04))
	_inspect(Vector3(-5.9, 0.85, 0.7), "clock", "Check the clock", NOTES["clock"], Color(0.2, 0.18, 0.16), Vector3(0.16, 0.16, 0.08))
	_deck(Vector3(3.55, 0.56, 8.05), "402", "Play cassette (402)")
	_deck(Vector3(-3.55, 0.56, 2.4), "401", "Play cassette (401)")

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

func _deck(pos: Vector3, which: String, prompt: String) -> void:
	var radio := StaticBody3D.new()
	radio.set_script(preload("res://scripts/radio.gd"))
	radio.position = pos
	radio.deck = which
	radio.prompt = prompt
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.22, 0.28)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.12, 0.08)
	mesh.material_override = mat
	radio.add_child(mesh)
	var speaker := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.04
	speaker.mesh = cyl
	speaker.rotation.x = PI * 0.5
	speaker.position = Vector3(0.08, 0.02, -0.12)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.08, 0.08, 0.08)
	speaker.material_override = sm
	radio.add_child(speaker)
	var tag := Label3D.new()
	tag.text = "TAPE DECK " + which
	tag.font_size = 56
	tag.pixel_size = 0.0045
	tag.position = Vector3(0, 0.28, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.95, 0.82, 0.55)
	UiFont.apply_3d(tag)
	radio.add_child(tag)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.7, 0.5, 0.55)
	col.shape = sh
	radio.add_child(col)
	radio.collision_layer = 1
	radio.collision_mask = 0
	add_child(radio)

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
	match id:
		"flashlight":
			player.give_flashlight()
			_set_chapter(1, "Ch.1 Hall. F flashlight. 402 is open. 401 is still locked.")
			phase = maxi(phase, 1)
		"note":
			_set_chapter(2, "Ch.2 Apt 402. Bathroom tap is still running. Find the cassette.")
			phase = maxi(phase, 2)
			_dim_hall(0.45)
		"tape":
			_set_chapter(3, "Ch.3 Bath. Take the 401 key. The 402 deck is only a copy.")
			phase = maxi(phase, 3)
			_dim_hall(0.28)
		"key":
			_set_chapter(4, "Ch.4 Home. Unlock 401 across the hall.")
			phase = maxi(phase, 4)

func show_note(text: String) -> void:
	hud.show_note(text)

func knock_behind_401() -> void:
	sfx.global_position = Vector3(-1.6, 1.2, 2.4)
	sfx.stream = _click_stream(70.0, 0.16)
	sfx.volume_db = -4.0
	sfx.play()

func play_tape(deck: String = "402") -> void:
	if not items.get("tape", false):
		show_note("The deck is empty. You can still hear a cassette turning.")
		return
	if ending:
		return
	if deck == "402":
		if not visited_401:
			show_note("The voice on the tape is coming from 401.\nThis deck is a copy. Play it in the room that is yours.")
			if items.get("key", false) and not apt401_open:
				open_401()
			return
		show_note("Wrong room. The breathing is louder through the other door.")
		return
	_begin_ending()

func inspect(id: String, text: String) -> void:
	show_note(text)
	click_sfx()
	if id == "calendar" or id == "clock":
		visited_401 = true
		_start_overlap()

func open_401() -> void:
	if apt401_open:
		return
	apt401_open = true
	phase = maxi(phase, 4)
	click_sfx()
	var world := get_node_or_null("World")
	if world and world.has_method("open_401"):
		world.open_401()
	show_note("The deadbolt yields. The air inside already knows your shampoo.")
	_set_chapter(4, "Ch.4 Apt 401. Read the calendar. The clock is waiting.")
	knock_behind_401()

func _track_401() -> void:
	if player.global_position.x < -1.9:
		visited_401 = true
		if chapter < 4:
			_set_chapter(4, "Ch.4 Apt 401. This is the room you locked from the inside.")

func _start_overlap() -> void:
	if overlap:
		return
	overlap = true
	phase = maxi(phase, 5)
	_set_chapter(5, "Ch.5 Overlap. The plates have swapped. Play the tape in 401.")
	hud.show_title("Chapter 5 — The plates have swapped")
	title_t = 4.0
	_dim_hall(0.1)
	var world := get_node_or_null("World")
	if world and world.has_method("swap_plates"):
		world.swap_plates()
	hud.set_clock("02:17 / 02:17")

func _set_chapter(n: int, objective: String) -> void:
	if n > chapter:
		chapter = n
		hud.show_title("Chapter %d" % n)
		title_t = 3.2
	hud.set_objective(objective)

func _begin_ending() -> void:
	ending = true
	phase = 6
	tape_player.play()
	hud.set_objective("Ch.5 Overlap. The breathing matches.")
	_dim_hall(0.06)
	await get_tree().create_timer(6.8).timeout
	show_note(NOTES["end"])
	hud.note_t = 40.0
	player.locked = true
	drone.volume_db = -6.0
	hud.set_objective("Episode I complete. The Fourth Floor stays free.")
	if OS.has_feature("full_game"):
		hud.set_prompt("N next floor · R replay Episode I")
	else:
		hud.set_prompt("R restart · Follow bfstone25-stack on itch.io · More: /ghost-channel")
	hud.show_title("Episode I complete\nYou are the door across the hall")
	await_restart = true

func _saved_full_episode() -> int:
	var config := ConfigFile.new()
	if config.load("user://campaign.cfg") != OK:
		return 1
	return clampi(int(config.get_value("campaign", "unlocked_episode", 1)), 1, 5)

func on_tenant_seen() -> void:
	sfx.stream = _click_stream(220.0, 0.08)
	sfx.volume_db = -8.0
	sfx.play()
	hud.set_fear(0.35)

func caught() -> void:
	if ending or caught_t > 0.0:
		return
	caught_t = 2.2
	player.locked = true
	hud.show_note("Someone covers your eyes from behind.\nThe shampoo is the bottle you used this morning.\nThe hands are the same temperature.")
	drone.volume_db = -3.0

func _reset_catch() -> void:
	player.locked = false
	player.global_position = Vector3(0, 0.05, 0.8)
	player.rotation.y = PI
	drone.volume_db = -20.0
	hud.set_objective("You're still on the fourth floor. The door is still open. That half already knows you.")
	var tenant := get_tree().get_first_node_in_group("tenant") as Node3D
	if tenant:
		tenant.global_position = Vector3(2.2, 0.95, 8.05)
		tenant.visible = true

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
