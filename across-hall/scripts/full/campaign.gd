extends Node3D

const ACTION_SCRIPT := preload("res://scripts/full/campaign_interact.gd")
const SAVE_PATH := "user://campaign.cfg"

var episode := 2
var items := {}
var flags := {}
var campaign_complete := false
var final_choice := ""
var _stamp_index := 0
var _title_t := 0.0
var _blackout_t := 0.0
var _forms := {"vacancy": false, "noise": false, "duplicate": false}
var _memories := {"elevator": false, "mailbox": false, "exterior": false}
var _fade: ColorRect

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
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 0)
	hud.add_child(_fade)
	hud.move_child(_fade, 0)
	start_episode(_load_progress() if OS.has_feature("full_game") else 2)
	if hud.has_method("hide_splash"):
		hud.hide_splash()
	if not DisplayServer.get_name().contains("headless"):
		player.capture_mouse()

func start_episode(number: int) -> void:
	episode = clampi(number, 2, 5)
	player.locked = false
	if player.has_flashlight:
		player.battery = 1.0
		player.light_on = true
		player.flashlight.visible = true
	_clear_actions()
	world.build_episode(episode)
	player.global_position = Vector3(0, 0.05, 0.8)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	if "pitch" in player:
		player.pitch = 0.0
		player.head.rotation.x = 0.0
	_spawn_episode_actions()
	hud.set_clock("02:17")
	hud.set_fear(0.0)
	if hud.note:
		hud.note.visible = false
		hud.note_t = 0.0
	hud.show_title(_episode_title())
	_title_t = 2.8
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
			var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
			if FileAccess.file_exists(SAVE_PATH):
				DirAccess.remove_absolute(absolute_path)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
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
	if _blackout_t > 0.0:
		_blackout_t -= delta
		if _fade:
			_fade.color.a = clampf(_blackout_t / 0.85, 0.0, 0.92)
	elif _fade and _fade.color.a > 0.0:
		_fade.color.a = maxf(0.0, _fade.color.a - delta * 1.4)
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
			_blackout_t = 0.45
			if world.has_method("mark_present_room"):
				world.mark_present_room()
			_mark_action("ep2_reset", "RESET already pulled")
			show_note(
				"The lights blink out. Every door returns to 401.\n"
				+ "The tag is still in your hand. The present room clicks open."
			)
			hud.set_objective("Open the glowing PRESENT 401. Recover the missing floor plate.")
			return false
		"ep2_present":
			if not flags.get("reset_done", false):
				show_note("This 401 belongs to a later version of the night.")
				return false
			flags["present_open"] = true
			hud.set_objective("Take the missing floor plate from the present room.")
			show_note("Inside: your coat, still warm. The elevator plate lies beneath it.")
			return true
		"ep2_plate":
			if not flags.get("present_open", false):
				show_note("The floor plate is behind the present 401.")
				return false
			items["floor_plate"] = true
			hud.set_objective("Walk to the elevator. Install the missing B plate.")
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
			hud.set_objective("LIFT is live. Take the fuse from the elevator cabinet.")
			show_note("LIFT circuit live. A cabinet unlatches beside the elevator.")
			return false
		"ep3_archive":
			if not items.get("fuse", false):
				show_note("ARCHIVE draws more power than the dead fuse can carry.")
				return false
			flags["circuit"] = "archive"
			world.set_circuit("archive")
			hud.set_objective("ARCHIVE is live. Play the 02:17 complaint reel.")
			show_note("ARCHIVE circuit live. A reel marked 02:17 begins to turn.")
			return false
		"ep3_hall":
			if not flags.get("recording_played", false):
				show_note("HALL power refuses the route. The archive has priority.")
				return false
			flags["circuit"] = "hall"
			world.set_circuit("hall")
			if world.has_method("show_waiting_tenant"):
				world.show_waiting_tenant()
			hud.set_fear(0.28)
			hud.set_objective("The tenant is waiting, not hunting. Take the management key.")
			show_note("The exit lights. The tenant waits beneath it instead of hunting.")
			return false
		"ep3_fuse":
			if flags.get("circuit", "") != "lift":
				show_note("The elevator cabinet is dark. Route power to LIFT.")
				return false
			items["fuse"] = true
			hud.set_objective("Route power to ARCHIVE. Then play the 02:17 reel.")
			show_note("The fuse is warm enough to have been used moments ago.")
			return true
		"ep3_recording":
			if flags.get("circuit", "") != "archive" or not items.get("fuse", false):
				show_note("The complaint reel has no power.")
				return false
			flags["recording_played"] = true
			_mark_action("ep3_recording", "Complaint already heard")
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
			hud.set_fear(0.08)
			hud.set_objective("Unlock the records stairwell with the management key.")
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
				_highlight_next_stamp()
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
			_mark_action(action_id, memory.to_upper() + " installed")
			show_note(_memory_text(memory))
			if _all_memories():
				hud.set_objective("Choose OCCUPANT or DOOR for the blank directory slot.")
			else:
				hud.set_objective("Install the remaining memories. Three sockets. One plate.")
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
	_save_progress(next_episode)
	_blackout_t = 0.55
	start_episode(next_episode)

func _mark_action(action_id: String, next_prompt: String) -> void:
	for action in get_tree().get_nodes_in_group("campaign_action"):
		if action.get("action_id") == action_id and action.has_method("mark_used"):
			action.mark_used(next_prompt)

func _load_progress() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 2
	return clampi(int(config.get_value("campaign", "unlocked_episode", 2)), 2, 5)

func _save_progress(unlocked_episode: int) -> void:
	if not OS.has_feature("full_game"):
		return
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var previous := int(config.get_value("campaign", "unlocked_episode", 2))
	config.set_value("campaign", "unlocked_episode", maxi(previous, unlocked_episode))
	config.save(SAVE_PATH)

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
	_highlight_next_stamp()
	if _stamp_index == 3:
		hud.set_objective("The manager's desk is open. Take the master plate.")
	else:
		hud.set_objective(
			"Next: file "
			+ names[_stamp_index]
			+ " as "
			+ expected[_stamp_index]
			+ "."
		)
	return false

func _highlight_next_stamp() -> void:
	var order := ["ep4_return", "ep4_retain", "ep4_remove"]
	for action in get_tree().get_nodes_in_group("campaign_action"):
		var id := str(action.get("action_id"))
		if id not in order:
			continue
		var idx := order.find(id)
		var live := idx == _stamp_index
		for child in action.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var mat := (child.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.emission_enabled = true
				mat.emission = Color(0.75, 0.55, 0.18) if live else Color(0.08, 0.06, 0.03)
				child.material_override = mat
			elif child is Label3D:
				(child as Label3D).modulate = (
					Color(0.98, 0.88, 0.45) if live else Color(0.55, 0.5, 0.42)
				)

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
			_action(Vector3(0.7, 0.12, 2.0), "ep2_tag", "Take inspection tag", true, Color(0.78, 0.58, 0.2), Vector3(0.28, 0.03, 0.38), "TAG", "plate")
			_action(Vector3(-1.2, 0.85, 4.5), "ep2_reset", "Pull floor RESET", false, Color(0.58, 0.1, 0.08), Vector3(0.12, 0.55, 0.12), "RESET", "lever")
			_action(Vector3(3.55, 1.05, 7.5), "ep2_present", "Open present 401", true, Color(0.28, 0.22, 0.16), Vector3(0.14, 2.0, 1.0), "401", "door")
			_action(Vector3(2.55, 0.14, 8.35), "ep2_plate", "Take missing floor plate", true, Color(0.78, 0.58, 0.18), Vector3(0.36, 0.04, 0.28), "B", "plate")
			_action(Vector3(0, 1.15, 12.55), "ep2_elevator", "Install B plate", false, Color(0.42, 0.44, 0.4), Vector3(0.5, 0.6, 0.1), "PANEL", "panel")
		3:
			_action(Vector3(-2.6, 0.95, 2.28), "ep3_lift", "Route circuit: LIFT", false, Color(0.7, 0.18, 0.1), Vector3(0.42, 0.28, 0.2), "LIFT", "pad")
			_action(Vector3(0.0, 0.95, 5.28), "ep3_archive", "Route circuit: ARCHIVE", false, Color(0.7, 0.18, 0.1), Vector3(0.42, 0.28, 0.2), "ARCHIVE", "pad")
			_action(Vector3(2.6, 0.95, 8.28), "ep3_hall", "Route circuit: HALL", false, Color(0.7, 0.18, 0.1), Vector3(0.42, 0.28, 0.2), "HALL", "pad")
			_action(Vector3(-2.6, 0.4, 3.7), "ep3_fuse", "Take elevator fuse", true, Color(0.72, 0.58, 0.18), Vector3(0.18, 0.18, 0.5), "FUSE", "fuse")
			_action(Vector3(2.2, 0.7, 10.4), "ep3_recording", "Play complaint 02:17", true, Color(0.28, 0.22, 0.16), Vector3(0.55, 0.18, 0.4), "02:17", "deck")
			_action(Vector3(0.8, 0.25, 12.2), "ep3_key", "Take management key", true, Color(0.78, 0.58, 0.2), Vector3(0.12, 0.04, 0.28), "KEY", "key")
			_action(Vector3(0, 1.05, 14.4), "ep3_stairs", "Unlock records stairwell", false, Color(0.28, 0.24, 0.18), Vector3(0.9, 2.0, 0.12), "RECORDS", "door")
		4:
			_action(Vector3(-1.8, 0.9, 1.65), "ep4_vacancy", "Take VACANCY complaint", true, Color(0.86, 0.8, 0.64), Vector3(0.32, 0.03, 0.42), "VACANCY", "paper")
			_action(Vector3(0.0, 0.9, 1.65), "ep4_noise", "Take NOISE complaint", true, Color(0.86, 0.8, 0.64), Vector3(0.32, 0.03, 0.42), "NOISE", "paper")
			_action(Vector3(1.8, 0.9, 1.65), "ep4_duplicate", "Take DUPLICATE complaint", true, Color(0.86, 0.8, 0.64), Vector3(0.32, 0.03, 0.42), "DUPLICATE", "paper")
			_action(Vector3(-2.7, 0.95, 5.95), "ep4_return", "Stamp current form RETURN", false, Color(0.62, 0.48, 0.18), Vector3(0.42, 0.12, 0.42), "RETURN", "pad")
			_action(Vector3(0.0, 0.95, 5.95), "ep4_retain", "Stamp current form RETAIN", false, Color(0.62, 0.48, 0.18), Vector3(0.42, 0.12, 0.42), "RETAIN", "pad")
			_action(Vector3(2.7, 0.95, 5.95), "ep4_remove", "Stamp current form REMOVE", false, Color(0.62, 0.48, 0.18), Vector3(0.42, 0.12, 0.42), "REMOVE", "pad")
			_action(Vector3(0, 0.7, 12.7), "ep4_plate", "Take TENANT / DOOR plate", true, Color(0.78, 0.6, 0.22), Vector3(0.4, 0.05, 0.28), "MASTER", "plate")
			_action(Vector3(0, 1.1, 13.55), "ep4_stairs", "Insert plate in records window", false, Color(0.24, 0.22, 0.18), Vector3(1.2, 1.4, 0.12), "WINDOW", "panel")
		5:
			_action(Vector3(-2.4, 0.7, 6.5), "ep5_elevator", "Install plate: ELEVATOR memory", false, Color(0.42, 0.58, 0.58), Vector3(0.45, 0.08, 0.35), "ELEVATOR", "socket")
			_action(Vector3(2.4, 0.7, 8.5), "ep5_mailbox", "Install plate: MAILBOX memory", false, Color(0.42, 0.58, 0.58), Vector3(0.45, 0.08, 0.35), "MAILBOX", "socket")
			_action(Vector3(0, 0.7, 10.7), "ep5_exterior", "Install plate: EXIT memory", false, Color(0.42, 0.58, 0.58), Vector3(0.45, 0.08, 0.35), "EXIT", "socket")
			_action(Vector3(-1.2, 1.05, 14.4), "ep5_occupant", "Choose OCCUPANT", false, Color(0.62, 0.74, 0.66), Vector3(0.9, 2.0, 0.12), "OCCUPANT", "door")
			_action(Vector3(1.2, 1.05, 14.4), "ep5_door", "Choose DOOR", false, Color(0.48, 0.34, 0.22), Vector3(0.9, 2.0, 0.12), "DOOR", "door")

func _action(
	pos: Vector3,
	action_id: String,
	prompt: String,
	one_shot: bool,
	color: Color,
	size := Vector3(0.48, 0.3, 0.38),
	short_label := "",
	kind := "box"
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
	var mesh_instance := _prop_mesh(kind, size, color, action_id)
	action.add_child(mesh_instance)
	var label := Label3D.new()
	label.name = "WorldLabel"
	label.text = short_label if short_label != "" else prompt
	label.font_size = 26
	label.pixel_size = 0.002
	label.width = 420
	label.position = Vector3(0, maxf(size.y * 0.5, 0.2) + 0.22, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_begin = 0.85
	label.visibility_range_begin_margin = 0.25
	label.visibility_range_end = 5.2
	label.visibility_range_end_margin = 0.8
	label.modulate = Color(0.94, 0.84, 0.64)
	UiFont.apply_3d(label)
	action.add_child(label)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(size.x, 0.35), maxf(size.y, 0.35), maxf(size.z, 0.35)) + Vector3(0.2, 0.2, 0.2)
	collision.shape = shape
	action.add_child(collision)
	add_child(action)

func _prop_mesh(kind: String, size: Vector3, color: Color, action_id: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Prop"
	match kind:
		"lever":
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.04
			shaft.bottom_radius = 0.05
			shaft.height = size.y
			mesh_instance.mesh = shaft
			mesh_instance.rotation.z = PI * 0.18
		"fuse":
			var cyl := CylinderMesh.new()
			cyl.top_radius = size.x * 0.45
			cyl.bottom_radius = size.x * 0.45
			cyl.height = size.z
			mesh_instance.mesh = cyl
			mesh_instance.rotation.x = PI * 0.5
		"key":
			var key := BoxMesh.new()
			key.size = size
			mesh_instance.mesh = key
		"paper":
			var paper := BoxMesh.new()
			paper.size = size
			mesh_instance.mesh = paper
		"pad":
			var pad := BoxMesh.new()
			pad.size = size
			mesh_instance.mesh = pad
		"socket":
			var sock := BoxMesh.new()
			sock.size = size
			mesh_instance.mesh = sock
		"deck":
			var deck := BoxMesh.new()
			deck.size = size
			mesh_instance.mesh = deck
		"door", "panel":
			var panel := BoxMesh.new()
			panel.size = size
			mesh_instance.mesh = panel
		_:
			var box := BoxMesh.new()
			box.size = size
			mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	if (
		action_id.ends_with("_plate")
		or action_id == "ep2_tag"
		or kind in ["plate", "socket", "key", "fuse"]
	):
		material.emission_enabled = true
		material.emission = color * 0.4
	mesh_instance.material_override = material
	if kind == "lever":
		var knob := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		knob.mesh = sphere
		knob.position = Vector3(0, size.y * 0.45, 0)
		var km := StandardMaterial3D.new()
		km.albedo_color = Color(0.75, 0.15, 0.1)
		km.emission_enabled = true
		km.emission = Color(0.45, 0.08, 0.05)
		knob.material_override = km
		mesh_instance.add_child(knob)
	return mesh_instance

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
