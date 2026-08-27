extends Node3D

const NOTES := {
	"note1": "物业回执写着：402 于三个月前退租。\n空置证明上的签名，是我的名字。\n笔迹比我现在的手稳。",
	"note2": "401 的拖鞋在 402 的垫子上。尺码对得上。\n我把钥匙从里面反锁。\n所以现在敲门的，只能是还留在外面的那一个。",
	"tape": "没有日期。带仓是温的。\n像刚从耳朵里抽出来。",
	"end": "磁带里的呼吸对得上你的胸腔。\n对门从来没有别人。\n你只是把不想承认的那一半，留在了开着的那扇门里。",
}

var items := {}
var phase := 0
var ending := false
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
	hud.show_title("四楼。你没锁门。")
	if OS.has_feature("web"):
		hud.set_objective("点击画面。走廊灯坏了一半。对门开着。")
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.004
		env.ambient_light_energy = 0.62
		env.tonemap_exposure = 1.28
	else:
		hud.set_objective("走廊灯坏了一半。对门开着。")
		player.capture_mouse()

func _setup_audio() -> void:
	drone.stream = _tone_stream(44.0, 0.32)
	drone.volume_db = -20.0
	drone.play()
	tape_player.stream = _tape_stream()

func _unhandled_input(event: InputEvent) -> void:
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if ending:
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
	var t = player.interact_target()
	if t and t.get("prompt"):
		hud.set_prompt("E / 点击  " + str(t.prompt))
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
	_pickup(Vector3(0.55, 0.06, 2.6), "flashlight", "拿手电", "", Color(0.75, 0.72, 0.35), Vector3(0.28, 0.07, 0.08))
	_pickup(Vector3(3.05, 0.48, 8.05), "note", "读退租确认书", NOTES["note1"], Color(0.92, 0.88, 0.72), Vector3(0.32, 0.03, 0.42))
	_pickup(Vector3(7.85, 0.58, 11.35), "tape", "拿磁带", NOTES["tape"], Color(0.55, 0.12, 0.1), Vector3(0.2, 0.06, 0.12))
	var radio := StaticBody3D.new()
	radio.set_script(preload("res://scripts/radio.gd"))
	radio.position = Vector3(3.55, 0.56, 8.05)
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
	tag.text = "录音机"
	tag.font_size = 64
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
	tag.text = prompt
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
	match id:
		"flashlight":
			player.give_flashlight()
			hud.set_objective("F 手电。对门一直开着。不要正视角落。")
			phase = maxi(phase, 1)
		"note":
			hud.set_objective("浴室水龙头没关。还有别的声音。")
			phase = maxi(phase, 2)
			_dim_hall(0.45)
		"tape":
			hud.set_objective("客厅桌上那台录音机还在转。")
			phase = maxi(phase, 3)
			_dim_hall(0.18)

func show_note(text: String) -> void:
	hud.show_note(text)

func knock_behind_401() -> void:
	sfx.global_position = Vector3(-1.6, 1.2, 2.4)
	sfx.stream = _click_stream(70.0, 0.16)
	sfx.volume_db = -4.0
	sfx.play()

func play_tape() -> void:
	if not items.get("tape", false):
		show_note("仓是空的。你却已经听见磁带在转。")
		return
	if ending:
		return
	ending = true
	tape_player.play()
	hud.set_objective("呼吸对得上。")
	_dim_hall(0.06)
	await get_tree().create_timer(6.8).timeout
	show_note(NOTES["end"])
	hud.note_t = 40.0
	player.locked = true
	drone.volume_db = -6.0
	hud.set_prompt("终局。按 R 重新开始（E 不会把你送回走廊）")
	hud.show_title("你就是对门")
	await_restart = true

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
	hud.show_note("有人从后面捂住你的眼睛。\n洗发水是你早上那瓶。\n手的温度也是。")
	drone.volume_db = -3.0

func _reset_catch() -> void:
	player.locked = false
	player.global_position = Vector3(0, 0.05, 0.8)
	player.rotation.y = PI
	drone.volume_db = -20.0
	hud.set_objective("你还在四楼。门还开着。那一半已经认得你了。")
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
