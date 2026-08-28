extends Node3D

const ACTION_SCRIPT := preload("res://scripts/full/campaign_interact.gd")

var episode := 2
var items := {}
var flags := {}
var campaign_complete := false
var final_choice := ""
var _stamp_index := 0
var _title_t := 0.0
var _forms := {"vacancy": false, "noise": false, "duplicate": false}
var _memories := {"elevator": false, "mailbox": false, "exterior": false}

@onready var world: Node3D = $World
@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var drone: AudioStreamPlayer = $Drone
@onready var sfx: AudioStreamPlayer3D = $Sfx

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	player.give_flashlight()
	drone.stream = _tone_stream(38.0, 0.2)
	drone.volume_db = -24.0
	drone.play()
	start_episode(2)
	if hud.has_method("hide_splash"):
		hud.hide_splash()
	if not DisplayServer.get_name().contains("headless"):
		player.capture_mouse()

func start_episode(number: int) -> void:
	episode = clampi(number, 2, 5)
	player.locked = false
	_clear_actions()
	world.build_episode(episode)
	player.global_position = Vector3(0, 0.05, 0.0)
	player.rotation = Vector3(0, PI, 0)
	player.velocity = Vector3.ZERO
	_spawn_episode_actions()
	hud.set_clock("02:17")
	hud.set_fear(0.0)
	hud.show_title(_episode_title())
	_title_t = 4.5
	hud.set_objective(_objective())
	hud.set_prompt("")

func _episode_title() -> String:
	match episode:
		2:
			return "Episode II — The Unlisted Fifth Floor"
		3:
			return "Episode III — The Service Basement"
		4:
			return "Episode IV — Management"
		_:
			return "Episode V — The Exit Directory"

func _objective() -> String:
	match episode:
		2:
			return "Anchor one object. Reset the floor. Restore the missing button."
		3:
			return "Route one circuit at a time: LIFT → ARCHIVE → HALL."
		4:
			return "Collect the complaints. RETURN / RETAIN / REMOVE."
		_:
			return "Install the master plate at three memory sockets."

func _unhandled_input(event: InputEvent) -> void:
	if campaign_complete:
		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
			and event.physical_keycode == KEY_R
		):
			get_tree().reload_current_scene()
		return
	if event is InputEventMouseButton and event.pressed and not player.captured:
		player.capture_mouse()
		return
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		_interact()
	elif (
		event.is_action_pressed("interact")
		or (
			event is InputEventKey
			and event.pressed
			and not event.echo
			and event.keycode == KEY_E
		)
	):
		_interact()

func _process(delta: float) -> void:
	if _title_t > 0.0:
		_title_t -= delta
		if _title_t <= 0.0:
			hud.hide_title()
	if campaign_complete:
		return
	var target: Node = player.interact_target()
	if target and target.get("prompt"):
		hud.set_prompt("E / click  " + str(target.prompt))
	else:
		hud.set_prompt("")

func _interact() -> void:
	var target: Node = player.interact_target()
	if target:
		target.interact(self)

func perform_action(action_id: String) -> bool:
	click_sfx()
	match action_id:
		"ep2_tag":
			flags["anchored_tag"] = true
			show_note(
				"The inspection tag is stamped 02:17.\n"
				+ "The maintenance slot can anchor one object through a reset."
			)
			hud.set_objective("Use the RESET lever. The tag should remember you.")
			return true
		"ep2_reset":
			if not flags.get("anchored_tag", false):
				show_note("The hall resets. Your hands come back empty.\nAnchor the tag first.")
				return false
			flags["reset_done"] = true
			show_note(
				"The lights blink out. Every door returns to 401.\n"
				+ "The tag is still in your hand. The present room clicks open."
			)
			hud.set_objective("Open the present 401 and recover the missing floor plate.")
			return false
		"ep2_present":
			if not flags.get("reset_done", false):
				show_note("This 401 belongs to a later version of the night.")
				return false
			flags["present_open"] = true
			show_note("Inside: your coat, still warm. The elevator plate lies beneath it.")
			return true
		"ep2_plate":
			if not flags.get("present_open", false):
				show_note("The floor plate is behind the present 401.")
				return false
			items["floor_plate"] = true
			hud.set_objective("Install the missing B plate in the elevator panel.")
			show_note("A brass B. The scratch beneath it reads: BASEMENT / BEFORE.")
			return true
		"ep2_elevator":
			if not items.get("floor_plate", false):
				show_note("The panel has a rectangular absence below 5.")
				return false
			flags["episode_2_complete"] = true
			show_note("The B plate fits. The elevator descends past the lobby.")
			_advance_to(3)
			return false
		"ep3_lift":
			flags["circuit"] = "lift"
			world.set_circuit("lift")
			show_note("LIFT circuit live. A cabinet unlatches beside the elevator.")
			return false
		"ep3_archive":
			if not items.get("fuse", false):
				show_note("ARCHIVE draws more power than the dead fuse can carry.")
				return false
			flags["circuit"] = "archive"
			world.set_circuit("archive")
			show_note("ARCHIVE circuit live. A reel marked 02:17 begins to turn.")
			return false
		"ep3_hall":
			if not flags.get("recording_played", false):
				show_note("HALL power refuses the route. The archive has priority.")
				return false
			flags["circuit"] = "hall"
			world.set_circuit("hall")
			show_note("The exit lights. The tenant waits beneath it instead of hunting.")
			return false
		"ep3_fuse":
			if flags.get("circuit", "") != "lift":
				show_note("The elevator cabinet is dark. Route power to LIFT.")
				return false
			items["fuse"] = true
			hud.set_objective("Route power to ARCHIVE, install the fuse, play 02:17.")
			show_note("The fuse is warm enough to have been used moments ago.")
			return true
		"ep3_recording":
			if flags.get("circuit", "") != "archive" or not items.get("fuse", false):
				show_note("The complaint reel has no power.")
				return false
			flags["recording_played"] = true
			hud.set_objective("Route power to HALL. Meet what has been following you.")
			show_note(
				"COMPLAINT 401, 02:17:\n"
				+ "\"Remove the part of me that keeps coming home.\" Signed: you."
			)
			return true
		"ep3_key":
			if flags.get("circuit", "") != "hall" or not flags.get("recording_played", false):
				show_note("In the dark, the tenant closes its hand around the key.")
				return false
			items["management_key"] = true
			hud.set_objective("Use the management key on the records stairwell.")
			show_note("It opens its palm. The key is tagged MANAGEMENT / NO PERSON.")
			return true
		"ep3_stairs":
			if not items.get("management_key", false):
				show_note("The records stairwell has no public lock.")
				return false
			flags["episode_3_complete"] = true
			show_note("The basement door opens into carpet and fluorescent light.")
			_advance_to(4)
			return false
		"ep4_vacancy", "ep4_noise", "ep4_duplicate":
			var form_name := action_id.trim_prefix("ep4_")
			_forms[form_name] = true
			show_note(_form_text(form_name))
			if _all_forms():
				hud.set_objective("File in order: vacancy RETURN, noise RETAIN, duplicate REMOVE.")
			return true
		"ep4_return":
			return _stamp("RETURN")
		"ep4_retain":
			return _stamp("RETAIN")
		"ep4_remove":
			return _stamp("REMOVE")
		"ep4_plate":
			if _stamp_index < 3:
				show_note("The manager's desk has no drawer. Finish the filing.")
				return false
			items["master_plate"] = true
			hud.set_objective("Insert TENANT / DOOR into the records-window lock.")
			show_note(
				"The master plate has two faces: TENANT and DOOR.\n"
				+ "Management is a sorting rule, not a person."
			)
			return true
		"ep4_stairs":
			if not items.get("master_plate", false):
				show_note("The records window accepts a plate, not a key.")
				return false
			flags["episode_4_complete"] = true
			show_note("The records window rises. The lobby was behind it all along.")
			_advance_to(5)
			return false
		"ep5_elevator", "ep5_mailbox", "ep5_exterior":
			var memory := action_id.trim_prefix("ep5_")
			_memories[memory] = true
			show_note(_memory_text(memory))
			if _all_memories():
				hud.set_objective("The blank directory slot is ready. Choose who occupies it.")
			return false
		"ep5_occupant":
			if not _all_memories():
				show_note("The directory will not accept a name without its memories.")
				return false
			_finish_campaign("OCCUPANT")
			return false
		"ep5_door":
			if not _all_memories():
				show_note("The directory will not accept a name without its memories.")
				return false
			_finish_campaign("DOOR")
			return false
	return false

func _advance_to(next_episode: int) -> void:
	start_episode(next_episode)

func _form_text(form_name: String) -> String:
	match form_name:
		"vacancy":
			return "VACANCY: occupant returned after removal.\nRequested route: RETURN."
		"noise":
			return "NOISE: breathing continues in an empty room.\nRequested route: RETAIN."
		_:
			return "UNAUTHORIZED DUPLICATE: answers to your name.\nRequested route: REMOVE."

func _all_forms() -> bool:
	return (
		_forms.get("vacancy", false)
		and _forms.get("noise", false)
		and _forms.get("duplicate", false)
	)

func _stamp(stamp: String) -> bool:
	if not _all_forms():
		show_note("There are three empty spaces on the filing rail. Collect every complaint.")
		return false
	var expected := ["RETURN", "RETAIN", "REMOVE"]
	var names := ["VACANCY", "NOISE", "UNAUTHORIZED DUPLICATE"]
	if _stamp_index >= expected.size():
		show_note("The filing rail is complete. The manager's desk unlocks.")
		return false
	if stamp != expected[_stamp_index]:
		show_note(
			"REJECTED. "
			+ names[_stamp_index]
			+ " does not belong under "
			+ stamp
			+ "."
		)
		return false
	show_note(names[_stamp_index] + " → " + stamp + ". ACCEPTED.")
	_stamp_index += 1
	if _stamp_index == 3:
		hud.set_objective("The manager's desk is open. Take the master plate.")
	return false

func _memory_text(memory: String) -> String:
	match memory:
		"elevator":
			return "ELEVATOR MEMORY: you rode up alone. Two shadows stepped out."
		"mailbox":
			return "MAILBOX MEMORY: every letter was addressed to OCCUPANT / CURRENT."
		_:
			return "EXIT MEMORY: the tenant reached the street. You pulled it back."

func _all_memories() -> bool:
	return (
		_memories.get("elevator", false)
		and _memories.get("mailbox", false)
		and _memories.get("exterior", false)
	)

func _finish_campaign(choice: String) -> void:
	final_choice = choice
	campaign_complete = true
	flags["episode_5_complete"] = true
	player.locked = true
	hud.set_clock("02:18")
	hud.set_objective("The clock moved. The building did not follow.")
	if choice == "OCCUPANT":
		show_note(
			"You give the tenant a name and keep none for yourself.\n"
			+ "It walks outside. For the first time, you do not pull it back."
		)
	else:
		show_note(
			"You return DOOR to your own slot and leave it open.\n"
			+ "The part of you that kept coming home finally stops."
		)
	hud.note_t = 60.0
	hud.show_title("02:18\nAcross the Hall — complete")
	hud.set_prompt("R replay the full campaign · Follow bfstone25-stack on itch.io")
	drone.stop()

func _spawn_episode_actions() -> void:
	match episode:
		2:
			_action(Vector3(0.7, 0.35, 2.0), "ep2_tag", "Take inspection tag", true, Color(0.72, 0.55, 0.2))
			_action(Vector3(-1.2, 0.6, 4.5), "ep2_reset", "Pull floor RESET", false, Color(0.55, 0.1, 0.08))
			_action(Vector3(1.8, 0.65, 7.0), "ep2_present", "Open present 401", true, Color(0.3, 0.26, 0.2))
			_action(Vector3(-1.4, 0.32, 9.3), "ep2_plate", "Take missing floor plate", true, Color(0.72, 0.55, 0.16))
			_action(Vector3(0, 0.7, 12.2), "ep2_elevator", "Install B plate", false, Color(0.4, 0.42, 0.38))
		3:
			_action(Vector3(-2.4, 0.55, 3.0), "ep3_lift", "Route circuit: LIFT", false, Color(0.65, 0.18, 0.1))
			_action(Vector3(0, 0.55, 3.0), "ep3_archive", "Route circuit: ARCHIVE", false, Color(0.65, 0.18, 0.1))
			_action(Vector3(2.4, 0.55, 3.0), "ep3_hall", "Route circuit: HALL", false, Color(0.65, 0.18, 0.1))
			_action(Vector3(-2.4, 0.35, 6.2), "ep3_fuse", "Take elevator fuse", true, Color(0.68, 0.58, 0.2))
			_action(Vector3(2.2, 0.65, 8.0), "ep3_recording", "Play complaint 02:17", true, Color(0.25, 0.2, 0.16))
			_action(Vector3(0.8, 0.3, 11.0), "ep3_key", "Take management key", true, Color(0.72, 0.55, 0.2))
			_action(Vector3(0, 0.7, 14.2), "ep3_stairs", "Unlock records stairwell", false, Color(0.26, 0.24, 0.2))
		4:
			_action(Vector3(-2.2, 0.32, 2.0), "ep4_vacancy", "Take VACANCY complaint", true, Color(0.82, 0.76, 0.62))
			_action(Vector3(0, 0.32, 2.0), "ep4_noise", "Take NOISE complaint", true, Color(0.82, 0.76, 0.62))
			_action(Vector3(2.2, 0.32, 2.0), "ep4_duplicate", "Take DUPLICATE complaint", true, Color(0.82, 0.76, 0.62))
			_action(Vector3(-2.7, 0.7, 4.3), "ep4_return", "Stamp current form RETURN", false, Color(0.58, 0.46, 0.18))
			_action(Vector3(0, 0.7, 4.3), "ep4_retain", "Stamp current form RETAIN", false, Color(0.58, 0.46, 0.18))
			_action(Vector3(2.7, 0.7, 4.3), "ep4_remove", "Stamp current form REMOVE", false, Color(0.58, 0.46, 0.18))
			_action(Vector3(0, 0.6, 10.5), "ep4_plate", "Take TENANT / DOOR plate", true, Color(0.72, 0.58, 0.22))
			_action(Vector3(0, 0.75, 13.3), "ep4_stairs", "Insert plate in records window", false, Color(0.24, 0.22, 0.18))
		5:
			_action(Vector3(-2.4, 0.6, 3.0), "ep5_elevator", "Install plate: ELEVATOR memory", false, Color(0.42, 0.55, 0.55))
			_action(Vector3(2.4, 0.6, 6.4), "ep5_mailbox", "Install plate: MAILBOX memory", false, Color(0.42, 0.55, 0.55))
			_action(Vector3(0, 0.6, 10.0), "ep5_exterior", "Install plate: EXIT memory", false, Color(0.42, 0.55, 0.55))
			_action(Vector3(-1.1, 0.7, 13.3), "ep5_occupant", "Choose OCCUPANT", false, Color(0.62, 0.72, 0.65))
			_action(Vector3(1.1, 0.7, 13.3), "ep5_door", "Choose DOOR", false, Color(0.48, 0.34, 0.22))

func _action(
	pos: Vector3,
	action_id: String,
	prompt: String,
	one_shot: bool,
	color: Color
) -> void:
	var action := StaticBody3D.new()
	action.set_script(ACTION_SCRIPT)
	action.position = pos
	action.action_id = action_id
	action.prompt = prompt
	action.one_shot = one_shot
	action.collision_layer = 1
	action.collision_mask = 0
	action.add_to_group("campaign_action")
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.48, 0.3, 0.38)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	mesh_instance.material_override = material
	action.add_child(mesh_instance)
	var label := Label3D.new()
	label.text = prompt
	label.font_size = 30
	label.pixel_size = 0.0022
	label.width = 600
	label.position = Vector3(0, 0.32, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 4.5
	label.visibility_range_end_margin = 0.8
	label.modulate = Color(0.94, 0.84, 0.64)
	UiFont.apply_3d(label)
	action.add_child(label)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 0.65, 0.7)
	collision.shape = shape
	action.add_child(collision)
	add_child(action)

func _clear_actions() -> void:
	for action in get_tree().get_nodes_in_group("campaign_action"):
		if is_instance_valid(action):
			action.get_parent().remove_child(action)
			action.queue_free()

func show_note(text: String) -> void:
	hud.show_note(text)

func click_sfx() -> void:
	sfx.stream = _click_stream(360.0, 0.045)
	sfx.volume_db = -11.0
	sfx.play()

func footstep(pos: Vector3) -> void:
	sfx.global_position = pos
	sfx.stream = _click_stream(90.0, 0.05)
	sfx.volume_db = -17.0
	sfx.play()

func _tone_stream(hz: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := sample_rate * 2
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var sample := sin(TAU * hz * i / sample_rate) * amp
		sample += sin(TAU * hz * 0.5 * i / sample_rate) * amp * 0.35
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 255
		data[i * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _click_stream(hz: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var envelope := 1.0 - float(i) / float(sample_count)
		var sample := sin(TAU * hz * i / sample_rate) * envelope * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 19000.0)
		data[i * 2] = value & 255
		data[i * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
