extends Node3D

## The seven notes moved to scripts/i18n.gd, which holds them in four languages. NOTES
## stays as the id->key map so every call site still reads I18n.t(NOTES["tape"]) and the notes keep
## their names; what it holds now is a key, and I18n.t() turns it into prose.
const NOTES := {
	"note1": "note1",
	"note2": "note2",
	"tape": "note_tape",
	"key": "note_key",
	"clock": "note_clock",
	"end": "note_end",
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

# --- the spoken barks (assets/voice/, Sfx autoload) ---------------------------------------
#
# 21 lines were rendered for this game and sat unplayed because it had no scripts/sfx.gd
# for ops/bark_wire.py to wire. It has one now, and these are the moments.
#
# The mapping is not the arcade one, because this is not an arcade game. There is no score,
# so "near miss" and "streak" have to mean something in a walk-sim or they never fire:
#
#   greet     the first frame of play, once the title is dismissed
#   stage     a chapter turns (_set_chapter) — the four stage lines are the four chapters
#   near      the tenant is seen in peripheral vision: "one more door"
#   unlock    401 opens — the one door the whole game is about
#   win       the overlap begins; the walk is effectively done
#   win_big   the ending, with every note read
#   win       the ending otherwise
#   fail      caught
#   idle      IDLE_BARK seconds without the player moving or interacting
#   streak    three items picked up with no catch in between
#
# Every call goes through Sfx.bark_once, not Sfx.bark: the beats here arrive in clusters
# (open_401 sets a chapter, clicks, shows a note and knocks inside one frame) and the raw
# call would let two lines race for the single voice.
const IDLE_BARK := 34.0

var idle_t := 0.0
var clean_items := 0
var greeted := false
var _objective_key := ""

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
	hud.show_title(I18n.t("card_ch1"))
	if OS.has_feature("web"):
		hud.set_objective(I18n.t("obj_web"))
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.004
		env.ambient_light_energy = 0.62
		env.tonemap_exposure = 1.28
	else:
		hud.set_objective(I18n.t("obj_desk"))
		player.capture_mouse()
	if OS.has_feature("full_game"):
		var unlocked := _saved_full_episode()
		if unlocked >= 2:
			hud.set_objective(I18n.f("obj_continue", unlocked))

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
	# The greeting waits for the title to be gone: a line spoken under a splash the player
	# has not clicked yet is a line nobody hears as the game talking to them.
	if not greeted and not (hud.splash and hud.splash.visible):
		greeted = true
		Sfx.bark_once("greet")
	# Idle is measured on the PLAYER, not on the clock. A walk-sim's player stands still to
	# look at things, which is the game working; what this catches is somebody who put the
	# controller down, and velocity is the only honest signal for that.
	if player.velocity.length() > 0.3 or Input.is_action_just_pressed("interact"):
		idle_t = 0.0
	else:
		idle_t += delta
		if idle_t >= IDLE_BARK:
			idle_t = 0.0
			Sfx.bark_once("idle", 45.0)
	_track_401()
	var t = player.interact_target()
	if t and t.get("prompt"):
		hud.set_prompt(I18n.t("p_interact") + I18n.t(str(t.prompt)))
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
	_pickup(Vector3(0.55, 0.06, 2.6), "flashlight", "p_flashlight", "", Color(0.75, 0.72, 0.35), Vector3(0.28, 0.07, 0.08))
	_pickup(Vector3(3.05, 0.48, 8.05), "note", "p_note", I18n.t(NOTES["note1"]), Color(0.92, 0.88, 0.72), Vector3(0.32, 0.03, 0.42))
	_pickup(Vector3(7.85, 0.58, 11.35), "tape", "p_tape", I18n.t(NOTES["tape"]), Color(0.55, 0.12, 0.1), Vector3(0.2, 0.06, 0.12))
	_pickup(Vector3(8.2, 0.52, 11.55), "key", "p_key", I18n.t(NOTES["key"]), Color(0.72, 0.62, 0.22), Vector3(0.12, 0.04, 0.22))
	_inspect(Vector3(-3.25, 0.72, 2.15), "calendar", "p_calendar", I18n.t(NOTES["note2"]), Color(0.85, 0.78, 0.62), Vector3(0.28, 0.36, 0.04))
	_inspect(Vector3(-5.9, 0.85, 0.7), "clock", "p_clock", I18n.t(NOTES["clock"]), Color(0.2, 0.18, 0.16), Vector3(0.16, 0.16, 0.08))
	_deck(Vector3(3.55, 0.56, 8.05), "402", "p_deck402")
	_deck(Vector3(-3.55, 0.56, 2.4), "401", "p_deck401")

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
	tag.text = I18n.t(prompt)
	tag.font_size = 36
	tag.pixel_size = 0.0035
	tag.width = 400
	tag.position = Vector3(0, size.y * 0.5 + 0.14, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.9, 0.8, 0.58)
	Cjk.apply_3d(tag)
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
	Cjk.apply_3d(tag)
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
	tag.text = I18n.t(prompt)
	tag.font_size = 52
	tag.pixel_size = 0.004
	tag.position = Vector3(0, size.y * 0.5 + 0.14, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.95, 0.86, 0.62)
	Cjk.apply_3d(tag)
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
	# "Three clean runs" is the recorded line; in a game with one run it is three finds with
	# no catch in between, which is the same claim — you have not put a foot wrong yet.
	clean_items += 1
	if clean_items == 3:
		Sfx.bark_once("streak")
	match id:
		"flashlight":
			player.give_flashlight()
			_set_chapter(1, "obj_ch1")
			phase = maxi(phase, 1)
		"note":
			_set_chapter(2, "obj_ch2")
			phase = maxi(phase, 2)
			_dim_hall(0.45)
		"tape":
			_set_chapter(3, "obj_ch3")
			phase = maxi(phase, 3)
			_dim_hall(0.28)
		"key":
			_set_chapter(4, "obj_ch4")
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
		show_note(I18n.t("say_empty_deck"))
		return
	if ending:
		return
	if deck == "402":
		if not visited_401:
			show_note(I18n.t("say_from_401"))
			if items.get("key", false) and not apt401_open:
				open_401()
			return
		show_note(I18n.t("say_wrong_room"))
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
	Sfx.bark_once("unlock")
	show_note(I18n.t("say_deadbolt"))
	_set_chapter(4, "obj_ch4_in")
	knock_behind_401()

func _track_401() -> void:
	if player.global_position.x < -1.9:
		visited_401 = true
		if chapter < 4:
			_set_chapter(4, "obj_ch4_walked")

func _start_overlap() -> void:
	if overlap:
		return
	overlap = true
	phase = maxi(phase, 5)
	Sfx.bark_once("win", 8.0)
	_set_chapter(5, "obj_ch5")
	hud.show_title(I18n.t("card_ch5"))
	title_t = 4.0
	_dim_hall(0.1)
	var world := get_node_or_null("World")
	if world and world.has_method("swap_plates"):
		world.swap_plates()
	hud.set_clock("02:17 / 02:17")

## `objective` is an I18n KEY, not a sentence. Passing the sentence would have meant the
## objective line freezing in whatever language it was set in — the HUD only repaints when
## something sets it again, and a player who switches language mid-chapter would sit under
## an English line until the next chapter turned.
func _set_chapter(n: int, objective: String) -> void:
	if n > chapter:
		if n >= 2:
			Gate.block("ch%d" % n, "Chapter %d" % n)   # dual-track (ops/DUAL_TRACK.md)
		chapter = n
		hud.show_title(I18n.f("card_ch", n))
		title_t = 3.2
		Sfx.bark_once("stage", 6.0)
	_objective_key = objective
	hud.set_objective(I18n.t(objective))

func _begin_ending() -> void:
	ending = true
	phase = 6
	# win_big is "every room, you missed nothing" — so it is earned, not automatic. All four
	# findables read means the player actually walked the whole building.
	var complete := items.has("flashlight") and items.has("note") and items.has("tape") \
		and items.has("key")
	Sfx.bark_once("win_big" if complete else "win", 0.0)
	tape_player.play()
	hud.set_objective(I18n.t("obj_breath"))
	_dim_hall(0.06)
	await get_tree().create_timer(6.8).timeout
	show_note(I18n.t(NOTES["end"]))
	hud.note_t = 40.0
	player.locked = true
	drone.volume_db = -6.0
	hud.set_objective(I18n.t("obj_done"))
	if OS.has_feature("full_game"):
		hud.set_prompt(I18n.t("end_full"))
	else:
		hud.set_prompt(I18n.t("end_web"))
	hud.show_title(I18n.t("card_end"))
	await_restart = true
	# End of the run: the cross-promotion board (play/_shared/board.js) — the other small
	# games, as links the player may click. The mouse is captured in this game, so it has
	# to be released first or the tiles cannot be clicked. Mainstream title: the casual
	# board, never the adult one (ops/check_adsense_isolation.py).
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.captured = false
	Gate.board_offer_more("casual")

func _saved_full_episode() -> int:
	var config := ConfigFile.new()
	if config.load("user://campaign.cfg") != OK:
		return 1
	return clampi(int(config.get_value("campaign", "unlocked_episode", 1)), 1, 5)

func on_tenant_seen() -> void:
	sfx.stream = _click_stream(220.0, 0.08)
	sfx.volume_db = -8.0
	sfx.play()
	# Long gap: the tenant is a peripheral-vision effect that can retrigger every few
	# seconds, and a narrator who says "one more door" every time is a fault light.
	Sfx.bark_once("near", 40.0)
	hud.set_fear(0.35)

func caught() -> void:
	if ending or caught_t > 0.0:
		return
	caught_t = 2.2
	clean_items = 0
	Sfx.bark_once("fail", 8.0)
	player.locked = true
	hud.show_note(I18n.t("say_caught"))
	drone.volume_db = -3.0

func _reset_catch() -> void:
	player.locked = false
	player.global_position = Vector3(0, 0.05, 0.8)
	player.rotation.y = PI
	drone.volume_db = -20.0
	hud.set_objective(I18n.t("obj_caught"))
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
