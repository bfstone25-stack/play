extends CanvasLayer
class_name HorrorHud

signal choice_made(choice_id: String)

var root_ui: Control
var prompt: Label
var clock: Label
var objective: Label
var dialogue_panel: PanelContainer
var dialogue_name: Label
var dialogue_body: Label
var dialogue_continue: Button
var choice_panel: PanelContainer
var choice_prompt: Label
var btn_a: Button
var btn_b: Button
var title_label: Label
var wash: ColorRect
var grain: ColorRect
var _choice_ids: PackedStringArray = PackedStringArray()
var _dialogue_queue: Array = []
var _busy := false

func _ready() -> void:
	layer = 20
	root_ui = Control.new()
	root_ui.name = "Root"
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)
	_build()

func _build() -> void:
	_wash()
	_grain()
	_labels()
	_dialogue()
	_choice()
	_title()

func _wash() -> void:
	wash = ColorRect.new()
	wash.name = "Wash"
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(1, 1, 1, 1)
	var sh: Shader = load("res://shaders/horror_palette.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("red_wash", 0.0)
		mat.set_shader_parameter("blue_wash", 0.35)
		mat.set_shader_parameter("scanlines", 0.1)
		mat.set_shader_parameter("vignette", 0.4)
		mat.set_shader_parameter("pulse", 0.0)
		wash.material = mat
	root_ui.add_child(wash)

func set_palette(red: float, blue: float, pulse: float = 0.0) -> void:
	if wash and wash.material is ShaderMaterial:
		var m: ShaderMaterial = wash.material
		m.set_shader_parameter("red_wash", red)
		m.set_shader_parameter("blue_wash", blue)
		m.set_shader_parameter("pulse", pulse)

func _grain() -> void:
	grain = ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.color = Color(1, 1, 1, 1)
	var sh: Shader = load("res://shaders/grain.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		grain.material = mat
	root_ui.add_child(grain)

func _labels() -> void:
	clock = Label.new()
	clock.position = Vector2(28, 20)
	clock.add_theme_font_size_override("font_size", 18)
	clock.add_theme_color_override("font_color", Color(0.25, 0.55, 1.0))
	clock.text = "23:47  ·  FLOOR 13"
	UiFont.apply_label(clock)
	root_ui.add_child(clock)

	objective = Label.new()
	objective.position = Vector2(28, 48)
	objective.add_theme_font_size_override("font_size", 14)
	objective.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.9))
	objective.text = "Investigate your desk. Something is wrong with the overtime ticket."
	UiFont.apply_label(objective)
	root_ui.add_child(objective)

	prompt = Label.new()
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -280.0
	prompt.offset_right = 280.0
	prompt.offset_top = -56.0
	prompt.offset_bottom = -24.0
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	prompt.text = ""
	UiFont.apply_label(prompt)
	root_ui.add_child(prompt)

func set_prompt(t: String) -> void:
	prompt.text = t

func clear_prompt() -> void:
	prompt.text = ""

func set_objective(t: String) -> void:
	objective.text = t

func set_clock(t: String) -> void:
	clock.text = t

func _title() -> void:
	title_label = Label.new()
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -420.0
	title_label.offset_right = 420.0
	title_label.offset_top = -80.0
	title_label.offset_bottom = 40.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.16))
	title_label.text = "FLOOR 13: NIGHT SHIFT\n13楼夜班"
	UiFont.apply_label(title_label)
	root_ui.add_child(title_label)

func show_title(show: bool) -> void:
	title_label.visible = show

func _dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.visible = false
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.offset_left = -420.0
	dialogue_panel.offset_right = 420.0
	dialogue_panel.offset_top = -210.0
	dialogue_panel.offset_bottom = -70.0
	var vb := VBoxContainer.new()
	dialogue_panel.add_child(vb)
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 14)
	dialogue_name.add_theme_color_override("font_color", Color(0.95, 0.35, 0.28))
	UiFont.apply_label(dialogue_name)
	vb.add_child(dialogue_name)
	dialogue_body = Label.new()
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_body.add_theme_font_size_override("font_size", 16)
	dialogue_body.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	UiFont.apply_label(dialogue_body)
	vb.add_child(dialogue_body)
	dialogue_continue = Button.new()
	dialogue_continue.text = "…"
	dialogue_continue.custom_minimum_size = Vector2(0, 36)
	UiFont.apply_button(dialogue_continue)
	dialogue_continue.pressed.connect(_advance_dialogue)
	vb.add_child(dialogue_continue)
	root_ui.add_child(dialogue_panel)

func show_dialogue(lines: Array) -> void:
	_dialogue_queue = lines.duplicate()
	_busy = true
	dialogue_panel.visible = true
	choice_panel.visible = false
	_advance_dialogue()

func _advance_dialogue() -> void:
	if _dialogue_queue.is_empty():
		dialogue_panel.visible = false
		_busy = false
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("on_dialogue_done"):
			game.on_dialogue_done()
		return
	var line = _dialogue_queue.pop_front()
	dialogue_name.text = str(line.get("name", ""))
	dialogue_body.text = str(line.get("text", ""))

func _choice() -> void:
	choice_panel = PanelContainer.new()
	choice_panel.visible = false
	choice_panel.set_anchors_preset(Control.PRESET_CENTER)
	choice_panel.offset_left = -320.0
	choice_panel.offset_right = 320.0
	choice_panel.offset_top = -90.0
	choice_panel.offset_bottom = 110.0
	var vb := VBoxContainer.new()
	choice_panel.add_child(vb)
	choice_prompt = Label.new()
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_prompt.add_theme_font_size_override("font_size", 16)
	choice_prompt.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	UiFont.apply_label(choice_prompt)
	vb.add_child(choice_prompt)
	btn_a = Button.new()
	btn_a.custom_minimum_size = Vector2(0, 44)
	UiFont.apply_button(btn_a)
	btn_a.pressed.connect(func() -> void: _pick(0))
	vb.add_child(btn_a)
	btn_b = Button.new()
	btn_b.custom_minimum_size = Vector2(0, 44)
	UiFont.apply_button(btn_b)
	btn_b.pressed.connect(func() -> void: _pick(1))
	vb.add_child(btn_b)
	root_ui.add_child(choice_panel)

func show_choice(prompt_text: String, a_label: String, a_id: String, b_label: String, b_id: String) -> void:
	_busy = true
	dialogue_panel.visible = false
	choice_panel.visible = true
	choice_prompt.text = prompt_text
	btn_a.text = a_label
	btn_b.text = b_label
	_choice_ids = PackedStringArray([a_id, b_id])

func _pick(i: int) -> void:
	choice_panel.visible = false
	_busy = false
	var id := _choice_ids[i] if i < _choice_ids.size() else ""
	choice_made.emit(id)

func is_busy() -> bool:
	return _busy or dialogue_panel.visible or choice_panel.visible
