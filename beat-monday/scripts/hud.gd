extends CanvasLayer
class_name HorrorHud

signal choice_made(choice_id: String)
signal route_requested
signal restart_requested
signal title_requested

var root_ui: Control
var chapter_label: Label
var place_label: Label
var clock_label: Label
var objective_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var body_label: Label
var continue_button: Button
var choice_panel: PanelContainer
var choice_prompt: Label
var choice_a: Button
var choice_b: Button
var route_button: Button
var log_button: Button
var pause_button: Button
var overlay: PanelContainer
var overlay_title: Label
var overlay_body: Label
var title_panel: ColorRect
var title_start: Button
var ending_panel: PanelContainer
var ending_label: Label
var ending_restart: Button
var _queue: Array = []
var _choice_ids := PackedStringArray()
var _busy := false

func _ready() -> void:
	layer = 30
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)
	_build_top()
	_build_dialogue()
	_build_choices()
	_build_controls()
	_build_overlay()
	_build_title()
	_build_ending()

func _panel_style(bg: Color, border: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _format_label(node: Label, size: int, color: Color) -> void:
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	UiFont.apply_label(node)

func _format_button(node: Button, size := 11) -> void:
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", Color("#e7edf5"))
	node.add_theme_stylebox_override("normal", _panel_style(Color("#151c2bdd"), Color("#526785"), 1))
	node.add_theme_stylebox_override("hover", _panel_style(Color("#22324ae8"), Color("#6ad9f1"), 2))
	node.add_theme_stylebox_override("pressed", _panel_style(Color("#34202bea"), Color("#ef4757"), 2))
	UiFont.apply_button(node)

func _build_top() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 0)
	bar.size = Vector2(640, 48)
	bar.color = Color("#080d17ee")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(bar)
	chapter_label = Label.new()
	chapter_label.position = Vector2(14, 7)
	chapter_label.size = Vector2(72, 16)
	_format_label(chapter_label, 8, Color("#ef4455"))
	root_ui.add_child(chapter_label)
	place_label = Label.new()
	place_label.position = Vector2(88, 5)
	place_label.size = Vector2(360, 19)
	_format_label(place_label, 12, Color("#e7edf5"))
	root_ui.add_child(place_label)
	clock_label = Label.new()
	clock_label.position = Vector2(520, 7)
	clock_label.size = Vector2(104, 18)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_format_label(clock_label, 9, Color("#6fdcef"))
	root_ui.add_child(clock_label)
	objective_label = Label.new()
	objective_label.position = Vector2(88, 27)
	objective_label.size = Vector2(528, 16)
	objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_format_label(objective_label, 8, Color("#8e9bb0"))
	root_ui.add_child(objective_label)

func _build_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.position = Vector2(38, 218)
	dialogue_panel.size = Vector2(564, 129)
	dialogue_panel.visible = false
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color("#080d18f2"), Color("#6b7c98"), 2))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	dialogue_panel.add_child(stack)
	speaker_label = Label.new()
	_format_label(speaker_label, 9, Color("#ef5262"))
	stack.add_child(speaker_label)
	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(0, 63)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_format_label(body_label, 10, Color("#e1e6ee"))
	stack.add_child(body_label)
	continue_button = Button.new()
	continue_button.text = "CONTINUE  ▸"
	continue_button.custom_minimum_size = Vector2(0, 28)
	_format_button(continue_button, 9)
	continue_button.pressed.connect(_advance_dialogue)
	stack.add_child(continue_button)
	root_ui.add_child(dialogue_panel)

func _build_choices() -> void:
	choice_panel = PanelContainer.new()
	choice_panel.position = Vector2(106, 86)
	choice_panel.size = Vector2(428, 194)
	choice_panel.visible = false
	choice_panel.add_theme_stylebox_override("panel", _panel_style(Color("#080d18f7"), Color("#ef4455"), 2))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	choice_panel.add_child(stack)
	var label := Label.new()
	label.text = "DECISION RECORDED PERMANENTLY"
	_format_label(label, 8, Color("#ef4455"))
	stack.add_child(label)
	choice_prompt = Label.new()
	choice_prompt.custom_minimum_size = Vector2(0, 45)
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_format_label(choice_prompt, 11, Color("#f0eee6"))
	stack.add_child(choice_prompt)
	choice_a = Button.new()
	choice_a.custom_minimum_size = Vector2(0, 43)
	_format_button(choice_a, 10)
	choice_a.pressed.connect(func() -> void: _pick(0))
	stack.add_child(choice_a)
	choice_b = Button.new()
	choice_b.custom_minimum_size = Vector2(0, 43)
	_format_button(choice_b, 10)
	choice_b.pressed.connect(func() -> void: _pick(1))
	stack.add_child(choice_b)
	root_ui.add_child(choice_panel)

func _build_controls() -> void:
	log_button = Button.new()
	log_button.position = Vector2(14, 321)
	log_button.size = Vector2(77, 27)
	log_button.text = "CASE LOG"
	_format_button(log_button, 8)
	log_button.pressed.connect(show_log)
	root_ui.add_child(log_button)
	pause_button = Button.new()
	pause_button.position = Vector2(549, 321)
	pause_button.size = Vector2(77, 27)
	pause_button.text = "PAUSE"
	_format_button(pause_button, 8)
	pause_button.pressed.connect(show_pause)
	root_ui.add_child(pause_button)
	route_button = Button.new()
	route_button.position = Vector2(225, 301)
	route_button.size = Vector2(190, 43)
	route_button.text = "PROCEED  ▸"
	route_button.visible = false
	_format_button(route_button, 10)
	route_button.add_theme_stylebox_override("normal", _panel_style(Color("#192e36ed"), Color("#62d6e9"), 2))
	route_button.pressed.connect(func() -> void: route_requested.emit())
	root_ui.add_child(route_button)

func _build_overlay() -> void:
	overlay = PanelContainer.new()
	overlay.position = Vector2(73, 48)
	overlay.size = Vector2(494, 265)
	overlay.visible = false
	overlay.add_theme_stylebox_override("panel", _panel_style(Color("#070b14fa"), Color("#5f789d"), 2))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	overlay.add_child(stack)
	overlay_title = Label.new()
	_format_label(overlay_title, 14, Color("#6fdcef"))
	stack.add_child(overlay_title)
	overlay_body = Label.new()
	overlay_body.custom_minimum_size = Vector2(0, 175)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_format_label(overlay_body, 9, Color("#d9dfe8"))
	stack.add_child(overlay_body)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)
	var close := Button.new()
	close.text = "RETURN"
	close.custom_minimum_size = Vector2(226, 32)
	_format_button(close, 9)
	close.pressed.connect(func() -> void: overlay.visible = false; _busy = false)
	actions.add_child(close)
	var restart := Button.new()
	restart.text = "RESTART FROM TITLE"
	restart.custom_minimum_size = Vector2(226, 32)
	_format_button(restart, 9)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	actions.add_child(restart)
	root_ui.add_child(overlay)

func _build_title() -> void:
	title_panel = ColorRect.new()
	title_panel.color = Color("#050914f5")
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_panel.z_index = 30
	root_ui.add_child(title_panel)
	var eyebrow := Label.new()
	eyebrow.position = Vector2(0, 72)
	eyebrow.size = Vector2(640, 22)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.text = "A MERIDIAN LEDGER NIGHT OPERATIONS FILE"
	_format_label(eyebrow, 9, Color("#667b9a"))
	title_panel.add_child(eyebrow)
	var title := Label.new()
	title.position = Vector2(0, 99)
	title.size = Vector2(640, 106)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "FLOOR 13\nNIGHT SHIFT"
	_format_label(title, 29, Color("#ee4052"))
	title_panel.add_child(title)
	var chinese := Label.new()
	chinese.position = Vector2(0, 202)
	chinese.size = Vector2(640, 28)
	chinese.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chinese.text = "13 楼 夜 班"
	_format_label(chinese, 14, Color("#67d8ec"))
	title_panel.add_child(chinese)
	var info := Label.new()
	info.position = Vector2(90, 245)
	info.size = Vector2(460, 35)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.text = "A 25–35 MINUTE POINT-CLICK HORROR NARRATIVE\nHeadphones recommended · choices persist"
	_format_label(info, 8, Color("#929db1"))
	title_panel.add_child(info)
	title_start = Button.new()
	title_start.position = Vector2(215, 294)
	title_start.size = Vector2(210, 42)
	title_start.text = "BEGIN NIGHT SHIFT"
	_format_button(title_start, 11)
	title_start.pressed.connect(func() -> void: title_panel.visible = false; title_requested.emit())
	title_panel.add_child(title_start)

func _build_ending() -> void:
	ending_panel = PanelContainer.new()
	ending_panel.position = Vector2(104, 66)
	ending_panel.size = Vector2(432, 242)
	ending_panel.visible = false
	ending_panel.add_theme_stylebox_override("panel", _panel_style(Color("#060a13fa"), Color("#ef4455"), 3))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	ending_panel.add_child(stack)
	ending_label = Label.new()
	ending_label.custom_minimum_size = Vector2(0, 146)
	ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_format_label(ending_label, 18, Color("#f1e9dc"))
	stack.add_child(ending_label)
	ending_restart = Button.new()
	ending_restart.text = "RESTART NIGHT SHIFT"
	ending_restart.custom_minimum_size = Vector2(0, 38)
	_format_button(ending_restart, 10)
	ending_restart.pressed.connect(func() -> void: restart_requested.emit())
	stack.add_child(ending_restart)
	root_ui.add_child(ending_panel)

func set_header(chapter: String, place: String, clock: String, objective: String) -> void:
	chapter_label.text = chapter
	place_label.text = place
	clock_label.text = clock
	objective_label.text = objective

func show_dialogue(lines: Array) -> void:
	_queue = lines.duplicate(true)
	_busy = true
	route_button.visible = false
	dialogue_panel.visible = true
	choice_panel.visible = false
	_advance_dialogue()

func _advance_dialogue() -> void:
	if _queue.is_empty():
		dialogue_panel.visible = false
		_busy = false
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("on_dialogue_done"):
			game.on_dialogue_done()
		return
	var line: Array = _queue.pop_front()
	speaker_label.text = str(line[0])
	body_label.text = str(line[1])
	continue_button.text = "CONTINUE  ▸  %d" % (_queue.size() + 1)

func show_choice(data: Dictionary) -> void:
	_busy = true
	dialogue_panel.visible = false
	choice_panel.visible = true
	choice_prompt.text = data.prompt
	choice_a.text = data.a[0]
	choice_b.text = data.b[0]
	_choice_ids = PackedStringArray([data.a[1], data.b[1]])

func _pick(index: int) -> void:
	choice_panel.visible = false
	_busy = false
	choice_made.emit(_choice_ids[index])

func enable_route(label := "PROCEED  ▸") -> void:
	route_button.text = label
	route_button.visible = true

func hide_route() -> void:
	route_button.visible = false

func show_log() -> void:
	if _busy:
		return
	var game := get_tree().get_first_node_in_group("game")
	overlay_title.text = "CASE LOG // PERSISTENT RECORD"
	overlay_body.text = game.get_case_log_text() if game else "No record."
	overlay.visible = true
	_busy = true

func show_pause() -> void:
	if _busy:
		return
	overlay_title.text = "NIGHT SHIFT PAUSED"
	overlay_body.text = "The clock has stopped for you. The record has not.\n\nAll progress is held in this session. Resume to continue, or restart from the title using the button below."
	overlay.visible = true
	_busy = true

func show_ending_card(text: String) -> void:
	_busy = true
	dialogue_panel.visible = false
	ending_label.text = text
	ending_panel.visible = true

func reset_ui() -> void:
	_busy = false
	dialogue_panel.visible = false
	choice_panel.visible = false
	overlay.visible = false
	ending_panel.visible = false
	route_button.visible = false
	title_panel.visible = true

func is_busy() -> bool:
	return _busy or dialogue_panel.visible or choice_panel.visible or overlay.visible or ending_panel.visible
