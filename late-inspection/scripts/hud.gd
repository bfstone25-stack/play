extends Control

@onready var prompt: Label = $Prompt
@onready var note: Label = $Note
@onready var objective: Label = $Objective
@onready var vignette: ColorRect = $Vignette

var note_t := 0.0
var fear := 0.0
var clock: Label
var title: Label
var grain: ColorRect
var splash: Control
var choice_panel: Control
var choice_prompt: Label
var btn_a: Button
var btn_b: Button
var _choice_cb: Callable = Callable()
var chapter: Label
var evidence_label: Label
var pause_panel: Control
var ending_panel: Control
var ending_title: Label
var ending_text: Label
var ending_button: Button
var ending_beats: Array = []
var ending_index := 0
var evidence: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	note.visible = false
	note.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	note.offset_left = -380.0
	note.offset_right = 380.0
	note.offset_top = -220.0
	note.offset_bottom = -72.0
	prompt.text = ""
	UiFont.apply_label(prompt)
	UiFont.apply_label(note)
	UiFont.apply_label(objective)
	_clock()
	_chapter()
	_title()
	_grain()
	_choice_ui()
	_pause_ui()
	_ending_ui()
	_splash()

func _clock() -> void:
	clock = Label.new()
	clock.name = "Clock"
	clock.position = Vector2(28, 52)
	clock.add_theme_font_size_override("font_size", 14)
	clock.add_theme_color_override("font_color", Color(0.55, 0.72, 0.48, 0.85))
	clock.text = "02:04"
	UiFont.apply_label(clock)
	add_child(clock)

func _chapter() -> void:
	chapter = Label.new()
	chapter.name = "Chapter"
	chapter.position = Vector2(28, 72)
	chapter.add_theme_font_size_override("font_size", 13)
	chapter.add_theme_color_override("font_color", Color(0.72, 0.62, 0.48, 0.88))
	UiFont.apply_label(chapter)
	add_child(chapter)
	evidence_label = Label.new()
	evidence_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	evidence_label.offset_left = -310.0
	evidence_label.offset_right = -24.0
	evidence_label.offset_top = 24.0
	evidence_label.offset_bottom = 54.0
	evidence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	evidence_label.add_theme_font_size_override("font_size", 13)
	evidence_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.58, 0.9))
	UiFont.apply_label(evidence_label)
	add_child(evidence_label)

func _title() -> void:
	title = Label.new()
	title.name = "Title"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -360.0
	title.offset_right = 360.0
	title.offset_top = 64.0
	title.offset_bottom = 130.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.86, 0.8, 0.7, 1))
	title.visible = false
	UiFont.apply_label(title)
	add_child(title)

func _grain() -> void:
	grain = ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.color = Color(1, 1, 1, 1)
	var sh := load("res://shaders/grain.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		grain.material = mat
	add_child(grain)
	move_child(grain, 1)

func _choice_ui() -> void:
	choice_panel = Control.new()
	choice_panel.name = "ChoicePanel"
	choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_panel.visible = false
	choice_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_panel.add_child(dim)

	choice_prompt = Label.new()
	choice_prompt.set_anchors_preset(Control.PRESET_CENTER)
	choice_prompt.offset_left = -420.0
	choice_prompt.offset_right = 420.0
	choice_prompt.offset_top = -160.0
	choice_prompt.offset_bottom = -40.0
	choice_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_prompt.add_theme_font_size_override("font_size", 20)
	choice_prompt.add_theme_color_override("font_color", Color(0.9, 0.84, 0.72, 1))
	UiFont.apply_label(choice_prompt)
	choice_panel.add_child(choice_prompt)

	btn_a = _mk_btn("ChoiceA", Vector2(-420, 20), Vector2(840, 48))
	btn_b = _mk_btn("ChoiceB", Vector2(-420, 84), Vector2(840, 48))
	btn_a.pressed.connect(func() -> void: _pick(0))
	btn_b.pressed.connect(func() -> void: _pick(1))
	choice_panel.add_child(btn_a)
	choice_panel.add_child(btn_b)
	add_child(choice_panel)

func _mk_btn(n: String, off: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.name = n
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.offset_left = off.x
	b.offset_top = off.y
	b.offset_right = off.x + size.x
	b.offset_bottom = off.y + size.y
	b.add_theme_font_size_override("font_size", 16)
	return b

func _pause_ui() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.01, 0.88)
	pause_panel.add_child(dim)
	var lab := Label.new()
	lab.set_anchors_preset(Control.PRESET_CENTER)
	lab.offset_left = -320
	lab.offset_right = 320
	lab.offset_top = -150
	lab.offset_bottom = -40
	lab.text = "INSPECTION PAUSED\nEsc resumes · Mouse recaptures on return"
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 23)
	UiFont.apply_label(lab)
	pause_panel.add_child(lab)
	var resume := _mk_btn("Resume", Vector2(-180, 10), Vector2(360, 48))
	resume.text = "RESUME INSPECTION"
	resume.pressed.connect(func() -> void: get_tree().call_group("game", "toggle_pause"))
	pause_panel.add_child(resume)
	var restart_btn := _mk_btn("Restart", Vector2(-180, 72), Vector2(360, 48))
	restart_btn.text = "RESTART FROM ARRIVAL"
	restart_btn.pressed.connect(func() -> void: get_tree().call_group("game", "restart"))
	pause_panel.add_child(restart_btn)
	add_child(pause_panel)

func _ending_ui() -> void:
	ending_panel = Control.new()
	ending_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_panel.visible = false
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.014, 0.9)
	ending_panel.add_child(bg)
	ending_title = Label.new()
	ending_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ending_title.offset_left = -440
	ending_title.offset_right = 440
	ending_title.offset_top = 90
	ending_title.offset_bottom = 150
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_title.add_theme_font_size_override("font_size", 30)
	ending_title.add_theme_color_override("font_color", Color(0.9, 0.76, 0.55))
	UiFont.apply_label(ending_title)
	ending_panel.add_child(ending_title)
	ending_text = Label.new()
	ending_text.set_anchors_preset(Control.PRESET_CENTER)
	ending_text.offset_left = -450
	ending_text.offset_right = 450
	ending_text.offset_top = -130
	ending_text.offset_bottom = 150
	ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_text.add_theme_font_size_override("font_size", 21)
	ending_text.add_theme_color_override("font_color", Color(0.91, 0.86, 0.77))
	UiFont.apply_label(ending_text)
	ending_panel.add_child(ending_text)
	ending_button = _mk_btn("EndingNext", Vector2(-180, 185), Vector2(360, 50))
	ending_button.text = "CONTINUE"
	ending_button.pressed.connect(_next_ending_beat)
	ending_panel.add_child(ending_button)
	add_child(ending_panel)

func _splash() -> void:
	splash = Control.new()
	splash.name = "Splash"
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.035, 0.025, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(bg)
	var lab := Label.new()
	lab.set_anchors_preset(Control.PRESET_CENTER)
	lab.offset_left = -440.0
	lab.offset_right = 440.0
	lab.offset_top = -90.0
	lab.offset_bottom = 110.0
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 24)
	lab.add_theme_color_override("font_color", Color(0.93, 0.86, 0.72, 1))
	lab.text = "Late Inspection: Flat 404\n深夜验房：404室\nClick to enter  ·  WASD  mouse  E interact  Esc"
	UiFont.apply_label(lab)
	splash.add_child(lab)
	splash.gui_input.connect(_on_splash_input)
	add_child(splash)

func _on_splash_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_splash()
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("capture_mouse"):
			p.capture_mouse()

func hide_splash() -> void:
	if splash:
		splash.visible = false
		splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not choice_panel or not choice_panel.visible:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_prompt(t: String) -> void:
	prompt.text = t

func set_objective(t: String) -> void:
	objective.text = t

func set_clock(t: String) -> void:
	if clock:
		clock.text = t

func set_chapter(t: String, clock_text: String) -> void:
	if chapter:
		chapter.text = t
	set_clock(clock_text)

func add_evidence(id: String) -> void:
	if not evidence.has(id):
		evidence.append(id)
	if evidence_label:
		evidence_label.text = "EVIDENCE %02d / 15" % evidence.size()

func show_title(t: String) -> void:
	title.text = t
	title.visible = true

func hide_title() -> void:
	if title:
		title.visible = false

func set_fear(v: float) -> void:
	fear = v

func show_note(t: String) -> void:
	note.text = t
	note.visible = true
	note_t = 7.0
	hide_title()

func open_choice(text: String, a: String, b: String, cb: Callable) -> void:
	choice_prompt.text = text
	btn_a.text = "A  " + a
	btn_b.text = "B  " + b
	_choice_cb = cb
	choice_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_pause(value: bool) -> void:
	pause_panel.visible = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

func show_ending(t: String, beats: Array) -> void:
	ending_title.text = t
	ending_beats = beats
	ending_index = 0
	ending_panel.visible = true
	ending_text.text = str(ending_beats[0])
	ending_button.text = "CONTINUE"
	mouse_filter = Control.MOUSE_FILTER_STOP

func _next_ending_beat() -> void:
	ending_index += 1
	if ending_index >= ending_beats.size():
		ending_text.text = "FLAT 404\n\nThank you for witnessing.\n\nPress R to restart the inspection."
		ending_button.text = "RESTART"
		ending_button.pressed.disconnect(_next_ending_beat)
		ending_button.pressed.connect(func() -> void: get_tree().call_group("game", "restart"))
		return
	ending_text.text = str(ending_beats[ending_index])
	if ending_index == ending_beats.size() - 1:
		ending_button.text = "CREDITS"

func _pick(i: int) -> void:
	choice_panel.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cb := _choice_cb
	_choice_cb = Callable()
	if cb.is_valid():
		cb.call(i)

func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0:
			note.visible = false
	vignette.color.a = 0.05 + fear * 0.3
	if grain and grain.material is ShaderMaterial:
		(grain.material as ShaderMaterial).set_shader_parameter("grain", 0.06 + fear * 0.1)
