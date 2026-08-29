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
	"fire_plan": false,
	"frame_found": false,
	"shoes_seen": false,
	"invoice_found": false,
	"medicine_found": false,
	"drain_seen": false,
	"locket_found": false,
	"letters_found": false,
	"pell_threat": false,
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
	for item in StoryContent.stage(s, flags):
		var pos: Vector3 = item["pos"]
		if item["kind"] == "choice":
			_choice(pos, item["id"], item["prompt"], item["text"], item["a"], item["b"])
		else:
			_note(pos, item["id"], item["prompt"], item["text"] + StoryContent.commentary(item["id"]))
	if $World.has_method("stage_event"):
		$World.stage_event(s, flags)

func _note(pos: Vector3, id: String, prompt: String, text: String) -> void:
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/note_prop.gd"))
	body.position = pos
	body.prompt = prompt
	body.note_id = id
	body.note_text = text
	body.set_meta("story_id", id)
	_decorate_prop(body, id, false)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.28, 0.12, 0.22)
	col.shape = sh
	body.add_child(col)
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
	_decorate_prop(body, id, true)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.4, 0.5, 0.35)
	col.shape = sh
	body.add_child(col)
	add_child(body)
	active_ids[id] = body

func _prop_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)

func _prop_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)

func _decorate_prop(body: Node3D, id: String, choice: bool) -> void:
	var paper := GameMaterials.paper(Color(0.76, 0.68, 0.5))
	var dark := GameMaterials.flat(Color(0.055, 0.045, 0.035), 0.8)
	var metal := GameMaterials.metal(Color(0.22, 0.2, 0.16))
	if id in ["answering", "followup"]:
		_prop_box(body, Vector3.ZERO, Vector3(.42,.16,.3), dark)
		_prop_box(body, Vector3(0,.12,-.04), Vector3(.3,.08,.12), metal)
		for x in [-.12, 0.0, .12]:
			_prop_cylinder(body, Vector3(x,.11,.09), .025, .02, paper)
	elif id in ["frame", "mirror"]:
		for x in [-.18,.18]:
			_prop_box(body, Vector3(x,0,0), Vector3(.035,.42,.03), metal)
		for y in [-.2,.2]:
			_prop_box(body, Vector3(0,y,0), Vector3(.4,.035,.03), metal)
	elif id in ["medicine", "kettle"]:
		_prop_cylinder(body, Vector3.ZERO, .12, .28, metal if id == "kettle" else paper)
		_prop_cylinder(body, Vector3(0,.17,0), .06, .05, dark)
	elif id in ["clock", "thermostat"]:
		_prop_box(body, Vector3.ZERO, Vector3(.32,.22,.1), dark)
		_prop_box(body, Vector3(0,0,-.055), Vector3(.22,.1,.01), GameMaterials.emissive(Color(.32,.5,.28), .25))
	elif id in ["cassette", "wardrobe"]:
		_prop_box(body, Vector3.ZERO, Vector3(.38,.16,.26), dark)
		_prop_cylinder(body, Vector3(-.1,.09,-.03), .065, .025, metal)
		_prop_cylinder(body, Vector3(.1,.09,-.03), .065, .025, metal)
	elif id in ["stain", "pipe", "final"]:
		_prop_cylinder(body, Vector3.ZERO, .16, .08, GameMaterials.emissive(Color(.42,.09,.055), .18))
	else:
		_prop_box(body, Vector3.ZERO, Vector3(.3,.018,.22), paper)
		if id in ["order", "checklist", "invoice", "clause", "final_evidence"]:
			_prop_box(body, Vector3(0,-.025,.015), Vector3(.34,.045,.26), dark)
			_prop_box(body, Vector3(0,.025,-.08), Vector3(.1,.035,.04), metal)
	if choice:
		_prop_box(body, Vector3(0,.035,0), Vector3(.36,.012,.28), paper)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not ending:
		toggle_pause()
		return
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER]:
			hud._next_ending_beat()
		return
	if ending or paused:
		return
	if hud and hud.splash and hud.splash.visible:
		if event is InputEventMouseButton and event.pressed:
			hud.hide_splash()
			player.capture_mouse()
		return
	if hud and hud.choice_panel and hud.choice_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_A:
				hud._pick(0)
			elif event.physical_keycode == KEY_B:
				hud._pick(1)
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

func on_document(id: String, text: String) -> void:
	player.locked = true
	hud.show_document(text, func() -> void:
		on_note(id)
		player.locked = false
		player.capture_mouse()
	)

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
		"fire_plan":
			flags["fire_plan"] = true
		"frame":
			flags["frame_found"] = true
		"shoes":
			flags["shoes_seen"] = true
		"invoice":
			flags["invoice_found"] = true
		"medicine":
			flags["medicine_found"] = true
		"drain":
			flags["drain_seen"] = true
		"locket":
			flags["locket_found"] = true
		"letters":
			flags["letters_found"] = true
		"notice":
			_advance(2, "Enter 404 and inspect the checklist in the living room.", 2, "01:58")
		"checklist":
			_advance(3, "Search the living room. Play the answering machine when ready.", 2, "02:01")
		"answering":
			_advance(4, "Investigate the kitchen and document the damp wall.", 2, "02:04")
		"service":
			_advance(6, "The pipe is waiting. Answer it or close the valve.", 3, "02:09")
		"wardrobe":
			_advance(8, "Play the cassette hidden inside the wall cavity.", 4, "02:17")
		"cassette":
			flags["iris_record"] = true
			_advance(9, "Return to the living room. Pell is calling.", 5, "02:21")
		"followup":
			flags["pell_threat"] = flags["photo_kept"] or flags["pipe_answered"]
			_advance(10, "Read the overnight clause on the coffee table.", 5, "02:23")
		"final_evidence":
			_advance(12, "The final knock is waiting at the front door.", 6, "02:29")

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
			_advance(5, "Follow the wet line into the bathroom. Read the service tag.", 3, "02:06")
		"pipe":
			if i == 0:
				flags["pipe_answered"] = true
				hud.show_note("MARA knocks three times.\nIRIS, through copper: Bedroom. Behind the coats. Record me.\nDANE: You heard her. Don't let Pell make it maintenance.")
			else:
				flags["pipe_silenced"] = true
				hud.show_note("The valve resists like a held wrist, then turns.\nPELL: Good. A quiet building is a safe building.")
			_advance(7, "Wet footprints lead to the bedroom. Search before opening the wardrobe.", 4, "02:13")
		"clause":
			if i == 0:
				flags["clause_signed"] = true
				hud.show_note("MARA VENN. Temporary. Until morning.\nInk crawls from your signature toward the printed word 'contents.'")
			else:
				flags["clause_refused"] = true
				hud.show_note("MARA: No. This inspection is suspended.\nBoth torn halves now read UNIT 404: NOT FOUND.")
			_advance(11, "Inspect the changed key and look through the peephole.", 6, "02:27")
		"final":
			flags["final_open"] = i == 0
			flags["final_ignore"] = i == 1
			_finish(_resolve_ending())
			return
	player.locked = false
	player.capture_mouse()
	drone.volume_db = -22.0

func _advance(next_stage: int, objective: String, chapter_index: int, clock: String) -> void:
	for prop in active_ids.values():
		if is_instance_valid(prop) and prop.get("taken") != true:
			prop.set("taken", true)
			prop.set("collision_layer", 0)
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
