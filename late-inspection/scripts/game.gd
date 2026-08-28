extends Node3D

## Flat 404 production episode. The same flag resolver is used by play,
## deterministic route verification, and automated progression tests.

const CHAPTERS := [
	"CHAPTER I — AFTER HOURS",
	"CHAPTER II — PREMISES SURRENDERED",
	"CHAPTER III — STILL HERE",
	"CHAPTER IV — THE PIPE SPEAKS",
	"CHAPTER V — ONE MINUTE",
	"CHAPTER VI — TEMPORARY CUSTODIAN",
	"CHAPTER VII — THE FINAL KNOCK",
]

var ending := false
var ending_id := ""
var stage := 0
var paused := false
var await_restart := false
var title_t := 6.0
var elapsed := 0.0
var flags := {
	"order_read": false,
	"dane_note": false,
	"photo_kept": false,
	"photo_deleted": false,
	"pipe_answered": false,
	"pipe_silenced": false,
	"iris_record": false,
	"clause_signed": false,
	"clause_refused": false,
	"final_open": false,
	"final_ignore": false,
}
var interaction_count := 0
var choice_count := 0
var collected: Array[String] = []
var active_ids: Dictionary = {}

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var drone: AudioStreamPlayer = $Drone

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	_setup_audio()
	_spawn_stage(0)
	var amb := Node.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	add_child(amb)
	hud.show_title("FLAT 404\nA late inspection")
	hud.set_chapter(CHAPTERS[0], "01:47")
	hud.set_objective("Read the after-hours inspection order in the lift lobby.")
	if OS.has_feature("web"):
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.006
		env.ambient_light_energy = 0.45
	else:
		player.capture_mouse()
	_check_automated_route()

func _setup_audio() -> void:
	drone.stream = _tone_stream(42.0, 0.28)
	drone.volume_db = -22.0
	drone.play()

func _spawn_stage(s: int) -> void:
	match s:
		0:
			_note(Vector3(-5.0, 0.52, 4.0), "order", "Read inspection order",
				"VESPER COURT / AFTER-HOURS INSPECTION 71-B\nUnit: 404. Tenant: [name removed].\nConfirm vacant. Record water damage. Do not contact adjoining tenants.\nIf work exceeds midnight, complete the overnight occupancy clause.\n— M. Pell, Building Manager\n\nMARA: It exceeded midnight before he called me.")
		1:
			_note(Vector3(-2.72, 0.14, 5.5), "dane", "Read note from 403",
				"INSPECTOR—\nPell will tell you 404 is empty. Ask why an empty room knocks back.\nIf the pipe calls three times, answer three times. Not two.\n— D, 403")
			_note(Vector3(0.72, 0.82, 4.0), "notice", "Read 404 access notice",
				"FINAL ACCESS NOTICE\nPremises surrendered. Contents abandoned.\nEntry constitutes confirmation that no resident remains.\n\nMARA: That isn't what entry means.\nThe key turns before it enters fully. Warm air pushes through the gap.\nMARA: Hello? Building inspection.")
		2:
			_note(Vector3(4.1, 0.48, 3.2), "checklist", "Read room checklist",
				"1. Confirm all personal property removed.\n2. Kitchen wall dry.\n3. Bathroom service pipe closed.\n4. Bedroom wardrobe empty.\n5. Overnight clause completed if keys remain after 00:00.\n\nMARA: Shoes. Tea. Half the books. Nothing about this says vacant.")
			_note(Vector3(5.8, 1.28, 0.36), "answering", "Play answering machine",
				"PELL: Iris, this is the last courtesy. Sign the surrender. We can correct the damp after access is returned. Please don't involve 403 again.\n\nIRIS: Dane, if this records: the wall gets wet when Pell brings an inspector. It isn't rain. Don't let them erase my name.\n\nMARA: Iris.")
			_note(Vector3(6.45, 0.7, 4.9), "frame", "Inspect empty photograph frame",
				"Dust protects the rectangle where a photograph stood.\nOn the backing, in blue pen:\nIRIS + DANE / FIRST NIGHT WITH HEAT.")
		3:
			_choice(Vector3(10.82, 1.08, 4.18), "stain", "Inspect letter-shaped stain",
				"The checklist camera opens. In its preview, letters surface inside the damp:\nIRIS VALE — STILL HERE",
				"Keep the photograph and attach it to the report",
				"Wipe the wall and delete the corrupted image")
		4:
			_note(Vector3(8.25, 1.52, 5.72), "mirror", "Look into the delayed mirror",
				"MARA: My reflection blinks late.\n\nIn the mirror, the bathroom door is closed.\nBehind you, it is open.")
			_note(Vector3(10.84, 1.38, 7.34), "service", "Read service tag",
				"STACK 4 / DO NOT ISOLATE WHILE OCCUPIED\nLast service: 14 NOV / PELL\nReported voice transmission: 'tenant misuse.'\n\nThree metallic knocks travel up the copper: short, short, long.")
		5:
			_choice(Vector3(10.78, 0.9, 7.0), "pipe", "Respond to the service pipe",
				"The copper knocks three times. Something waits for a reply.",
				"Answer with three knocks",
				"Close the valve and silence it")
		6:
			_note(Vector3(2.0, 0.78, 9.12), "clock", "Inspect frozen clock",
				"The second hand reaches 17 and falls back to 16.\nScratched beneath it:\nSHE GETS ONE MINUTE EACH INSPECTION.")
			_note(Vector3(6.08, 1.0, 8.5), "wardrobe", "Open the wardrobe",
				"Coats conceal a false plywood back. Behind it: a cassette recorder,\none woman-sized cavity, and copper crossing torn insulation.\n\nMARA: This wall was opened and closed from the room side.")
		7:
			_note(Vector3(7.02, 0.7, 8.5), "cassette", "Play Iris's cassette",
				"IRIS: My name is Iris Vale. It is November fourteenth. Pell says the leak makes the flat uninhabitable, but he won't let me leave with proof.\n\nIRIS: When the first inspector signed 'vacant,' the corridor forgot my door. I stayed in the wall so somebody would hear me before it closed.\n\nIRIS: Keep my name. Answer the pipe. At the final knock, open the flat from inside. A witness has to cross the threshold willingly.\n\nDANE, through the wall: Inspector! Pell is in the corridor. He doesn't have a face in the peephole.")
		8:
			_choice(Vector3(4.1, 0.49, 3.2), "clause", "Read overnight clause",
				"OVERNIGHT OCCUPANCY CLAUSE\nThe undersigned accepts temporary custodianship of Unit 404 and all unresolved contents until morning. Custodianship supersedes prior occupancy claims.",
				"Sign as temporary custodian",
				"Refuse and tear the clause in half")
		9:
			_choice(Vector3(0.82, 1.0, 4.0), "final", "Answer the final knock",
				"Four knocks sound from the corridor: 4 — 0 — 4 — silence.\nWho leaves Flat 404?",
				"Open the door and state what you witnessed",
				"Turn off the light and certify the flat vacant")

func _note(pos: Vector3, id: String, prompt: String, text: String) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/note_prop.gd"))
	body.position = pos
	body.prompt = prompt
	body.note_id = id
	body.note_text = text
	body.set_meta("story_id", id)
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
	active_ids[id] = body

func _choice(pos: Vector3, id: String, prompt: String, text: String, a: String, b: String) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/choice_prop.gd"))
	body.position = pos
	body.prompt = prompt
	body.choice_id = id
	body.prompt_text = text
	body.option_a = a
	body.option_b = b
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
	lab.text = "DECIDE"
	lab.font_size = 26
	lab.position = Vector3(0, 0.1, 0)
	lab.pixel_size = 0.004
	lab.modulate = Color(0.85, 0.55, 0.4)
	UiFont.apply_3d(lab)
	body.add_child(lab)
	add_child(body)
	active_ids[id] = body

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not ending:
		toggle_pause()
		return
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if ending or paused:
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
	if not paused:
		elapsed += delta
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
	var fear := 0.12 + float(stage) * 0.055
	if flags["pipe_answered"]:
		fear += 0.12
	hud.set_fear(fear)

func show_note(text: String) -> void:
	hud.show_note(text)

func on_note(id: String) -> void:
	if not collected.has(id):
		collected.append(id)
		interaction_count += 1
	hud.add_evidence(id)
	match id:
		"order":
			flags["order_read"] = true
			_advance(1, "Find Flat 404. Read the notice taped over its number.", 1, "01:53")
		"dane":
			flags["dane_note"] = true
			hud.set_objective("Read the access notice on Flat 404.")
		"notice":
			_advance(2, "Enter 404 and inspect the checklist in the living room.", 2, "01:58")
		"checklist":
			_advance(3, "Investigate the letter-shaped damp in the kitchen.", 2, "02:01")
		"service":
			_advance(5, "The pipe is waiting. Answer it or close the valve.", 3, "02:09")
		"wardrobe":
			_advance(7, "Play the cassette hidden inside the wall cavity.", 4, "02:17")
		"cassette":
			flags["iris_record"] = true
			var conditional := "\nPELL: You uploaded a tenant name. Delete it. Your authorization does not include testimony." if flags["photo_kept"] else "\nPELL: The kitchen correction came through clean. You understand how buildings survive."
			hud.show_note(str((active_ids[id] as Node).get("note_text")) + conditional)
			_advance(8, "Return to the living room and read the overnight clause.", 5, "02:23")

func open_choice(choice_id: String, text: String, a: String, b: String, source: Node) -> void:
	player.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	drone.volume_db = -28.0
	hud.open_choice(text, a, b, func(i: int) -> void:
		_resolve_choice(choice_id, i, source)
	)

func _resolve_choice(choice_id: String, i: int, source: Node) -> void:
	choice_count += 1
	interaction_count += 1
	if source:
		source.consumed = true
		source.taken = true
		source.collision_layer = 0
		for c in source.get_children():
			if c is Label3D:
				c.visible = false
	match choice_id:
		"stain":
			if i == 0:
				flags["photo_kept"] = true
				hud.show_note("MARA: Evidence first. Pell can explain the impossible part.\nThe letters IRIS VALE remain visible inside the damp.")
			else:
				flags["photo_deleted"] = true
				hud.show_note("MARA: A reflection. Bad compression. Finish the job.\nThe letters smear into a five-fingered handprint.")
			_advance(4, "Follow the wet line into the bathroom. Read the service tag.", 3, "02:06")
		"pipe":
			if i == 0:
				flags["pipe_answered"] = true
				hud.show_note("MARA knocks three times.\nIRIS, through copper: Bedroom. Behind the coats. Record me.\nDANE: You heard her. Don't let Pell make it maintenance.")
			else:
				flags["pipe_silenced"] = true
				hud.show_note("The valve resists like a held wrist, then turns.\nPELL: Good. A quiet building is a safe building.")
			_advance(6, "Wet footprints lead to the bedroom wardrobe.", 4, "02:13")
		"clause":
			if i == 0:
				flags["clause_signed"] = true
				hud.show_note("MARA VENN. Temporary. Until morning.\nInk crawls from your signature toward the printed word 'contents.'")
			else:
				flags["clause_refused"] = true
				hud.show_note("MARA: No. This inspection is suspended.\nBoth torn halves now read UNIT 404: NOT FOUND.")
			_advance(9, "Four knocks at the front door. Decide who leaves.", 6, "02:29")
		"final":
			flags["final_open"] = i == 0
			flags["final_ignore"] = i == 1
			_finish(_resolve_ending())
			return
	player.locked = false
	player.capture_mouse()
	drone.volume_db = -22.0

func _advance(next_stage: int, objective: String, chapter_index: int, clock: String) -> void:
	stage = next_stage
	hud.set_objective(objective)
	hud.set_chapter(CHAPTERS[chapter_index], clock)
	_spawn_stage(stage)

func _resolve_ending() -> String:
	if flags["final_open"] and flags["photo_kept"] and flags["pipe_answered"] and flags["iris_record"]:
		return "WITNESS"
	if flags["final_ignore"] and flags["photo_deleted"] and flags["pipe_silenced"] and flags["clause_signed"]:
		return "COMPLICIT"
	return "404"

func _finish(id: String) -> void:
	ending = true
	ending_id = id
	await_restart = true
	player.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("")
	drone.stop()
	var world := $World
	if world.has_method("apply_ending"):
		world.apply_ending(id)
	match id:
		"WITNESS":
			hud.show_ending("ENDING — WITNESS", [
				"The door opens onto the service cavity. Iris stands behind translucent pipework, one hand against the wall.",
				"MARA: Iris Vale occupied this flat. I heard her. I recorded her. I am not certifying it vacant.\nIRIS: Then look at me.",
				"Door 404 bears IRIS VALE. Dawn reaches the corridor.\nDANE: Did she come out?\nMARA: Her name did.",
				"Vesper Court received seventeen inspection requests that morning.\nFlat 404 was never listed as vacant again."
			])
		"COMPLICIT":
			hud.show_ending("ENDING — COMPLICIT", [
				"You turn off the standing lamp. The knocking stops halfway through a strike.",
				"Daylight. The flat is immaculate. Family photographs now show you with your face turned away.\nPELL: Inspection accepted. Your renewal begins today.",
				"OCCUPANT: MARA VENN\nMOVE-OUT INSPECTOR: [awaiting arrival]\nPlease keep the pipe quiet for the next guest.",
				"A new inspector's key enters from the corridor.\nYou made the building quiet. The building made you easy to replace."
			])
		_:
			hud.show_ending("ERROR 404 — INSPECTOR NOT FOUND", [
				"Every fourth-floor door now reads 403. Your key passes through the wall where 404 stood.",
				"MARA: I was inside. Kitchen, bath, bedroom—\nOPERATOR: Vesper Court has no fourth unit on any floor.",
				"Your inventory erases itself: cassette, photograph, clause, then MARA VENN.\nIRIS: A witness who will not choose is only another missing room.",
				"The lift opens on a brick wall.\nThe next appointment is at 01:47. Please bring identification."
			])

func toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	hud.set_pause(paused)
	player.locked = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func debug_complete_route(route: String) -> String:
	hud.hide_splash()
	flags["iris_record"] = true
	match route.to_lower():
		"witness":
			flags["photo_kept"] = true
			flags["pipe_answered"] = true
			flags["final_open"] = true
		"complicit":
			flags["photo_deleted"] = true
			flags["pipe_silenced"] = true
			flags["clause_signed"] = true
			flags["final_ignore"] = true
		_:
			flags["photo_kept"] = true
			flags["pipe_silenced"] = true
			flags["clause_refused"] = true
			flags["final_open"] = true
	var result := _resolve_ending()
	_finish(result)
	return result

func _check_automated_route() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--route="):
			call_deferred("debug_complete_route", arg.trim_prefix("--route="))

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
