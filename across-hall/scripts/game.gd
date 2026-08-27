extends Node3D

const NOTES := {
	"note1": "对门一直开着。\n物业说那户三个月前就退租了。\n可昨晚两点十七，我听见有人在用我的牙刷。",
	"note2": "401 的拖鞋在 402 的垫子上。\n尺码对得上。\n我没有出门。",
}

var items := {}
var phase := 0
var ending := false
var caught_t := 0.0

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var tape_player: AudioStreamPlayer = $Tape
@onready var drone: AudioStreamPlayer = $Drone
@onready var sfx: AudioStreamPlayer3D = $Sfx

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	hud.set_objective("走廊灯坏了。对门开着。")
	_setup_audio()
	_spawn_pickups()
	player.capture_mouse()

func _setup_audio() -> void:
	drone.stream = _tone_stream(46.0, 0.35)
	drone.volume_db = -18.0
	drone.play()
	tape_player.stream = _tape_stream()

func _unhandled_input(event: InputEvent) -> void:
	if ending:
		return
	if event.is_action_pressed("interact"):
		var t = player.interact_target()
		if t:
			t.interact(self)

func _process(delta: float) -> void:
	if ending:
		return
	var t = player.interact_target()
	if t and t.get("prompt"):
		hud.set_prompt("E  " + str(t.prompt))
	else:
		hud.set_prompt("")
	if caught_t > 0.0:
		caught_t -= delta
		if caught_t <= 0.0:
			_reset_catch()

func _spawn_pickups() -> void:
	_pickup(Vector3(0.55, 0.04, 3.4), "flashlight", "拿手电", "", Color(0.18, 0.18, 0.2), Vector3(0.22, 0.05, 0.06))
	_pickup(Vector3(4.35, 0.55, 8.6), "note", "读字条", NOTES["note1"], Color(0.78, 0.72, 0.58), Vector3(0.16, 0.01, 0.22))
	_pickup(Vector3(7.9, 0.55, 11.35), "tape", "拿磁带", "", Color(0.35, 0.12, 0.1), Vector3(0.14, 0.04, 0.08))
	var radio := StaticBody3D.new()
	radio.set_script(preload("res://scripts/radio.gd"))
	radio.position = Vector3(4.55, 0.42, 8.35)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.16, 0.18)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.12)
	mesh.material_override = mat
	radio.add_child(mesh)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.4, 0.3, 0.3)
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
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.1, 0.1, 0.1)
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
			hud.set_objective("F 开关手电。进 402。")
			phase = maxi(phase, 1)
		"note":
			show_note(NOTES["note1"])
			hud.set_objective("浴室里有什么在响。")
			phase = maxi(phase, 2)
		"tape":
			show_note("一盒没标日期的磁带。带仓还是温的。")
			hud.set_objective("客厅桌上有录音机。")
			phase = maxi(phase, 3)

func show_note(text: String) -> void:
	hud.show_note(text)

func play_tape() -> void:
	if not items.get("tape", false):
		show_note("仓是空的。")
		return
	if ending:
		return
	tape_player.play()
	hud.set_objective("那是你自己的呼吸。")
	ending = true
	await get_tree().create_timer(6.5).timeout
	show_note(NOTES["note2"] + "\n\n你没有关门。\n你就是对门。")
	player.locked = true
	drone.volume_db = -8.0
	await get_tree().create_timer(7.0).timeout
	get_tree().reload_current_scene()

func on_tenant_seen() -> void:
	click_sfx()

func caught() -> void:
	if ending or caught_t > 0.0:
		return
	caught_t = 1.6
	player.locked = true
	hud.show_note("有人从后面捂住了你的眼睛。\n味道是你自己的洗发水。")
	drone.volume_db = -4.0

func _reset_catch() -> void:
	player.locked = false
	player.global_position = Vector3(0, 1.0, 0.4)
	player.rotation.y = 0.0
	drone.volume_db = -18.0
	hud.set_objective("你还在四楼。门还开着。")
	var tenant := get_tree().get_first_node_in_group("tenant") as Node3D
	if tenant:
		tenant.global_position = Vector3(6.8, 0.95, 11.4)

func footstep(pos: Vector3) -> void:
	sfx.global_position = pos
	sfx.stream = _click_stream(randf_range(90.0, 140.0), 0.05)
	sfx.volume_db = -16.0
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
	var n := sr * 6
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var hiss := (randf() - 0.5) * 0.08
		var breath := 0.0
		if t > 1.2:
			breath = sin(TAU * 2.1 * t) * 0.12 * sin(TAU * 0.35 * t)
		var voice := 0.0
		if t > 2.4 and t < 5.2:
			voice = sin(TAU * 110.0 * t) * 0.04 * sin(TAU * 3.0 * t)
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
