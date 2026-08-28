extends Node3D

## Prototype slice: walk Flat 404, read notes, one hard choice, knock/drip pressure.

var ending := false
var flags := {
	"read_landlord": false,
	"read_neighbor": false,
	"saw_pipe": false,
	"choice_stay": false,
	"choice_done": false,
}
var title_t := 5.0
var await_restart := false

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var drone: AudioStreamPlayer = $Drone

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	_setup_audio()
	_spawn_props()
	var amb := Node.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	add_child(amb)
	hud.show_title("Flat 404 — late inspection")
	hud.set_objective("Enter 404. Read what management left. Check the wet wall.")
	if OS.has_feature("web"):
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.006
		env.ambient_light_energy = 0.45
	else:
		player.capture_mouse()

func _setup_audio() -> void:
	drone.stream = _tone_stream(42.0, 0.28)
	drone.volume_db = -22.0
	drone.play()

func _spawn_props() -> void:
	_note(
		Vector3(3.45, 0.42, 1.45),
		"landlord",
		"Read landlord note",
		"Management:\nUnit 404 re-listed after 'tenant dispute.'\nDo not photograph the kitchen wall.\nLeave the key on the table if you refuse the overnight clause."
	)
	_note(
		Vector3(1.55, 0.08, 2.55),
		"neighbor",
		"Read neighbor note",
		"Slipped under the door:\n'If they ask you to stay past 2,\nsay the pipe is already speaking.\n— 403'"
	)
	_pipe_inspect(Vector3(7.2, 0.55, 4.9))
	_choice_spot(Vector3(3.5, 0.9, 0.9))

func _note(pos: Vector3, id: String, prompt: String, text: String) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/note_prop.gd"))
	body.position = pos
	body.prompt = prompt
	body.note_id = id
	body.note_text = text
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.02, 0.16)
	mesh.mesh = box
	mesh.material_override = GameMaterials.paper(Color(0.82, 0.76, 0.6))
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.28, 0.12, 0.22)
	col.shape = sh
	body.add_child(col)
	var lab := Label3D.new()
	lab.text = "NOTE"
	lab.font_size = 28
	lab.position = Vector3(0, 0.08, 0)
	lab.pixel_size = 0.004
	lab.modulate = Color(0.9, 0.82, 0.65)
	UiFont.apply_3d(lab)
	body.add_child(lab)
	add_child(body)

func _pipe_inspect(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/note_prop.gd"))
	body.position = pos
	body.prompt = "Inspect pipe"
	body.note_id = "pipe"
	body.note_text = "The copper is warm.\nSomething darker than rust beads at the joint\nand falls on a rhythm that is not the building's."
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.5, 1.0, 0.5)
	col.shape = sh
	body.add_child(col)
	add_child(body)

func _choice_spot(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/choice_prop.gd"))
	body.position = pos
	body.prompt = "Overnight clause"
	body.choice_id = "stay_or_leave"
	body.prompt_text = "The lease says the inspection ends at midnight.\nIt is already later than that.\nManagement left an overnight clause unsigned."
	body.option_a = "Stay overnight and finish the checklist"
	body.option_b = "Leave the key on the table and walk out"
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.02, 0.2)
	mesh.mesh = box
	mesh.material_override = GameMaterials.paper(Color(0.7, 0.62, 0.48))
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.4, 0.5, 0.35)
	col.shape = sh
	body.add_child(col)
	var lab := Label3D.new()
	lab.text = "CLAUSE"
	lab.font_size = 26
	lab.position = Vector3(0, 0.1, 0)
	lab.pixel_size = 0.004
	lab.modulate = Color(0.85, 0.55, 0.4)
	UiFont.apply_3d(lab)
	body.add_child(lab)
	add_child(body)

func _unhandled_input(event: InputEvent) -> void:
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if ending:
		return
	if hud and hud.splash and hud.splash.visible:
		if event is InputEventMouseButton and event.pressed:
			hud.hide_splash()
			player.capture_mouse()
		return
	if hud and hud.choice_panel and hud.choice_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t = player.interact_target()
		if t:
			t.interact(self)
			return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		var t2 = player.interact_target()
		if t2:
			t2.interact(self)

func _process(delta: float) -> void:
	if title_t > 0.0:
		title_t -= delta
		if title_t <= 0.0:
			hud.hide_title()
	if ending:
		return
	if hud.choice_panel and hud.choice_panel.visible:
		hud.set_prompt("")
		return
	var t = player.interact_target()
	if t and t.get("prompt"):
		hud.set_prompt("E / click  " + str(t.prompt))
	else:
		hud.set_prompt("")
	var fear := 0.15
	if flags["saw_pipe"]:
		fear += 0.2
	if flags["choice_stay"]:
		fear += 0.25
	hud.set_fear(fear)

func show_note(text: String) -> void:
	hud.show_note(text)

func on_note(id: String) -> void:
	match id:
		"landlord":
			flags["read_landlord"] = true
			hud.set_objective("Neighbor slip under the door. Kitchen wall is wet.")
		"neighbor":
			flags["read_neighbor"] = true
			hud.set_objective("Check the pipe. Then the overnight clause on the table.")
		"pipe":
			flags["saw_pipe"] = true
			hud.set_objective("The overnight clause is waiting on the living-room table.")

func open_choice(choice_id: String, text: String, a: String, b: String, source: Node) -> void:
	player.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	drone.volume_db = -28.0
	hud.open_choice(text, a, b, func(i: int) -> void:
		_resolve_choice(choice_id, i, source)
	)

func _resolve_choice(choice_id: String, i: int, source: Node) -> void:
	flags["choice_done"] = true
	if source:
		source.consumed = true
		source.taken = true
		for c in source.get_children():
			if c is Label3D:
				c.visible = false
	if choice_id == "stay_or_leave":
		if i == 0:
			flags["choice_stay"] = true
			hud.show_note("You initial the overnight clause.\nSomewhere in the building, a knock answers once.")
			hud.set_objective("Prototype choice locked: STAY. Full endings in script pass.")
			hud.set_fear(0.55)
		else:
			flags["choice_stay"] = false
			hud.show_note("You leave the key.\nIn the corridor the 404 plaque looks freshly blank.")
			hud.set_objective("Prototype choice locked: LEAVE → Ending C stub (404).")
			_ending_stub("Ending C — 404\nUnit not found. Press R to restart.")
			return
	player.locked = false
	player.capture_mouse()
	drone.volume_db = -22.0

func _ending_stub(msg: String) -> void:
	ending = true
	await_restart = true
	player.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_title(msg)
	hud.set_prompt("")
	hud.set_objective(msg)

func _tone_stream(hz: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := sr * 2
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := sin(TAU * hz * i / sr) * amp
		s += sin(TAU * (hz * 0.5) * i / sr) * amp * 0.4
		var v := int(clampf(s, -1.0, 1.0) * 12000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = n
	st.data = data
	return st
