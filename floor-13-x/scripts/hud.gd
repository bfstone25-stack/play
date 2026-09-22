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
var portrait: TextureRect
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
var title_panel: TextureRect
var title_screen: TitleScreen
var title_start: Button
var title_eyebrow: Label
var title_name: Label
var title_info: Label
var title_lang_caption: Label
var lang_buttons: Dictionary = {}
var choice_banner: Label
var overlay_close: Button
var overlay_restart: Button
var ending_panel: PanelContainer
var ending_label: Label
var ending_restart: Button
var _queue: Array = []
var _choice_ids := PackedStringArray()
var _busy := false
var nvl_root: Control
var nvl_veil: ColorRect
var nvl_name: Label
var nvl_body: Label
var nvl_hint: Label
var pressure: Label
var _nvl := false
var _pulse := 0.0
## [fork] CG presenter and gallery.
var cg_root: Control
var cg_plate: TextureRect
var cg_caption: Label
var cg_notice: Label
var cg_dismiss: Button
var cg_unlock: Button
var gallery_button: Button
var gallery_root: Control
var gallery_grid: GridContainer
var gallery_close: Button
var _cg_open := false
var _cg_slot := ""
var _cg_unavailable := false

func _ready() -> void:
	layer = 30
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiFont.apply_theme(root_ui)
	add_child(root_ui)
	_build_top()
	_build_dialogue()
	_build_choices()
	_build_nvl()
	_build_controls()
	_build_overlay()
	_build_cg()
	_build_gallery()
	_build_title()
	_build_ending()
	set_process_unhandled_input(true)
	Loc.on_change(apply_locale)
	apply_locale()

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

func _atlas(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/pixel/ui_atlas.png")
	texture.region = region
	return texture

func _pixel_style(region: Rect2, margin := 3.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _atlas(region)
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return style

func _format_label(node: Label, size: int, color: Color) -> void:
	UiFont.apply_label(node, size >= 14)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color("#160903"))
	node.add_theme_constant_override("outline_size", 2)

## [fork] Every control the player presses is a PAYROLL TIME CARD (STANDARD.md rule 4).
##
## The game is about a company that keeps people by keeping their hours, so the object the
## player presses is the object the story is about: a manila card with a punch column down
## the left, and on hover the clock bites one more hole and a red RETAINED stamp bleeds in
## from the right. ShapedButton.Shape.TIMECARD draws it; nothing here is a stylebox.
##
## Manila, not the UI's blue. The shelf data says the top twenty covers on Nutaku are the
## warm ones (ops/SHELF_STYLE.md), and on this screen the cards are the only warm thing —
## which also makes them the thing the eye finds first, which is what a button is for.
const CARD_TINT := Color("#cc9772")
const CARD_INK := Color("#2d1f16")

func _card_button(text: String, sz: Vector2, font_size := 8) -> ShapedButton:
	var b := ShapedButton.new()
	b.shape = ShapedButton.Shape.TIMECARD
	b.compact = true          # 640x360 canvas: these are 80x28, not 220x56
	b.tint = CARD_TINT
	b.ink = CARD_INK
	b.label = text
	b.custom_minimum_size = sz
	b.add_theme_color_override("font_outline_color", Color("#160903"))
	b.add_theme_constant_override("outline_size", 2)
	UiFont.apply_button(b)
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _format_button(node: Button, _size := 11) -> void:
	node.add_theme_color_override("font_color", Color("#f7eae3"))
	node.add_theme_stylebox_override("normal", _pixel_style(Rect2(64, 64, 64, 32)))
	node.add_theme_stylebox_override("hover", _pixel_style(Rect2(192, 64, 64, 32)))
	node.add_theme_stylebox_override("pressed", _pixel_style(Rect2(128, 64, 64, 32)))
	node.add_theme_color_override("font_outline_color", Color("#160903"))
	node.add_theme_constant_override("outline_size", 2)
	UiFont.apply_button(node)

func _build_top() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 0)
	bar.size = Vector2(640, 40)
	bar.color = Color("#230f04cc")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(bar)
	chapter_label = Label.new()
	chapter_label.position = Vector2(14, 7)
	chapter_label.size = Vector2(72, 16)
	_format_label(chapter_label, 8, Color("#f21d6f"))
	root_ui.add_child(chapter_label)
	place_label = Label.new()
	place_label.position = Vector2(88, 5)
	place_label.size = Vector2(360, 19)
	_format_label(place_label, 12, Color("#f7eae3"))
	root_ui.add_child(place_label)
	clock_label = Label.new()
	clock_label.position = Vector2(368, 7)
	clock_label.size = Vector2(56, 18)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_format_label(clock_label, 9, Color("#f2a83a"))
	root_ui.add_child(clock_label)
	objective_label = Label.new()
	objective_label.position = Vector2(88, 22)
	objective_label.size = Vector2(528, 22)
	objective_label.clip_text = false
	objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_format_label(objective_label, 8, Color("#bc9b89"))
	root_ui.add_child(objective_label)

func _build_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.position = Vector2(8, 186)
	dialogue_panel.size = Vector2(624, 168)
	dialogue_panel.visible = false
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.gui_input.connect(_on_vn_gui)
	dialogue_panel.add_theme_stylebox_override("panel", _pixel_style(Rect2(0, 64, 64, 32), 4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	dialogue_panel.add_child(row)
	portrait = TextureRect.new()
	portrait.name = "SpeakerPortrait"
	portrait.custom_minimum_size = Vector2(48, 48)
	portrait.texture = _atlas(Rect2(0, 0, 48, 48))
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 4)
	row.add_child(stack)
	speaker_label = Label.new()
	_format_label(speaker_label, 9, Color("#f21d70"))
	stack.add_child(speaker_label)
	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(0, 52)
	body_label.clip_text = false
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_format_label(body_label, 10, Color("#f1e5de"))
	stack.add_child(body_label)
	continue_button = _card_button(Loc.t("btn.continue"), Vector2(0, 36), 10)
	continue_button.pressed.connect(_advance_dialogue)
	stack.add_child(continue_button)
	root_ui.add_child(dialogue_panel)

func _build_choices() -> void:
	choice_panel = PanelContainer.new()
	choice_panel.position = Vector2(18, 108)
	choice_panel.size = Vector2(604, 140)
	choice_panel.visible = false
	choice_panel.add_theme_stylebox_override("panel", _pixel_style(Rect2(128, 64, 64, 32), 4))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	choice_panel.add_child(stack)
	var label := Label.new()
	choice_banner = Label.new()
	_format_label(choice_banner, 8, Color("#f21d6f"))
	stack.add_child(choice_banner)
	choice_prompt = Label.new()
	choice_prompt.custom_minimum_size = Vector2(0, 20)
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_format_label(choice_prompt, 11, Color("#f3e1d0"))
	stack.add_child(choice_prompt)
	choice_a = _card_button("", Vector2(0, 44), 11)
	choice_a.pressed.connect(func() -> void: _pick(0))
	stack.add_child(choice_a)
	choice_b = _card_button("", Vector2(0, 44), 11)
	choice_b.pressed.connect(func() -> void: _pick(1))
	stack.add_child(choice_b)
	root_ui.add_child(choice_panel)

func _build_controls() -> void:
	log_button = _card_button(Loc.t("btn.case_log"), Vector2(80, 28))
	log_button.position = Vector2(430, 6)
	log_button.size = Vector2(80, 28)
	log_button.pressed.connect(show_log)
	root_ui.add_child(log_button)
	# [fork] The gallery drawer. Kept out of the top bar's crowded right end by moving the
	# case-log row left; the base game's log and pause keep their own positions relative to
	# each other so nothing else in apply_locale() has to move.
	gallery_button = _card_button("GALLERY", Vector2(78, 28))
	gallery_button.position = Vector2(348, 6)
	gallery_button.size = Vector2(78, 28)
	gallery_button.pressed.connect(show_gallery)
	root_ui.add_child(gallery_button)
	pause_button = _card_button(Loc.t("btn.pause"), Vector2(104, 28))
	pause_button.position = Vector2(524, 6)
	pause_button.size = Vector2(104, 28)
	pause_button.pressed.connect(show_pause)
	root_ui.add_child(pause_button)
	route_button = _card_button(Loc.t("btn.proceed"), Vector2(220, 32), 10)
	route_button.position = Vector2(210, 214)
	route_button.size = Vector2(220, 32)
	route_button.visible = false
	route_button.pressed.connect(func() -> void: route_requested.emit())
	root_ui.add_child(route_button)

func _build_overlay() -> void:
	overlay = PanelContainer.new()
	overlay.position = Vector2(73, 48)
	overlay.size = Vector2(494, 265)
	overlay.visible = false
	overlay.add_theme_stylebox_override("panel", _pixel_style(Rect2(0, 64, 64, 32), 4))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	overlay.add_child(stack)
	overlay_title = Label.new()
	_format_label(overlay_title, 14, Color("#f2a83a"))
	stack.add_child(overlay_title)
	overlay_body = Label.new()
	overlay_body.custom_minimum_size = Vector2(0, 175)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_format_label(overlay_body, 9, Color("#ecded6"))
	stack.add_child(overlay_body)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)
	overlay_close = Button.new()
	overlay_close.custom_minimum_size = Vector2(226, 32)
	_format_button(overlay_close, 9)
	overlay_close.pressed.connect(func() -> void: overlay.visible = false; _busy = false)
	actions.add_child(overlay_close)
	overlay_restart = Button.new()
	overlay_restart.custom_minimum_size = Vector2(226, 32)
	_format_button(overlay_restart, 9)
	overlay_restart.pressed.connect(func() -> void: restart_requested.emit())
	actions.add_child(overlay_restart)
	root_ui.add_child(overlay)

func _build_title() -> void:
	# The composition lives in TitleScreen (scripts/title_screen.gd); this function keeps
	# the HUD's own nodes — the localised lines, the start button, the language buttons —
	# and places them in it. title_panel stays the switch the rest of the HUD and the
	# tests flip; it no longer carries a picture of its own.
	title_panel = TextureRect.new()
	title_panel.name = "TitlePanel"
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	title_panel.z_index = 30
	root_ui.add_child(title_panel)
	title_screen = TitleScreen.new()
	title_screen.name = "TitleScreen"
	title_panel.add_child(title_screen)
	title_eyebrow = Label.new()
	title_eyebrow.position = Vector2(322, 136)
	title_eyebrow.size = Vector2(300, 14)
	title_eyebrow.clip_text = false
	title_panel.add_child(title_eyebrow)
	title_name = Label.new()
	title_name.visible = false   # the logotype image is the name now
	title_panel.add_child(title_name)
	title_info = Label.new()
	title_info.position = Vector2(322, 154)
	title_info.size = Vector2(300, 40)
	title_info.clip_text = false
	title_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_info.max_lines_visible = 3
	title_panel.add_child(title_info)
	title_lang_caption = Label.new()
	title_lang_caption.position = Vector2(0, 204)
	title_lang_caption.size = Vector2(640, 18)
	title_lang_caption.clip_text = false
	title_lang_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_format_label(title_lang_caption, 8, Color("#bc9b89"))
	title_panel.add_child(title_lang_caption)
	# [fork] English only. The base game ships five locales; translating ~3,000 new words
	# four ways is a bigger job than writing them, and the fork's store copy does not claim
	# five languages. locale.gd is left completely intact — the bar is hidden, not removed,
	# so nothing downstream of Loc.current() changes behaviour.
	var codes := Loc.ALLOWED
	for i in codes.size():
		var code := str(codes[i])
		var b := Button.new()
		b.name = "Lang_%s" % code
		b.position = Vector2(12 + (i % 5) * 124, 220)
		b.size = Vector2(120, 40)
		b.clip_text = false
		b.text = str(Loc.NATIVE[code])
		_format_button(b, 8)
		b.pressed.connect(_on_lang_pressed.bind(code))
		b.visible = false   # [fork] see above
		title_panel.add_child(b)
		lang_buttons[code] = b
	title_lang_caption.visible = false   # [fork] see above
	Loc.set_code("en")
	title_start = _card_button(Loc.t("title.start"), Vector2(190, 34), 12)
	title_start.name = "TitleStart"
	title_start.position = Vector2(322, 214)
	title_start.size = Vector2(250, 46)
	title_start.pressed.connect(_emit_start)
	title_panel.add_child(title_start)
	title_panel.gui_input.connect(_on_title_gui)
	title_panel.visibility_changed.connect(func() -> void:
		if title_panel.visible and title_screen:
			title_screen.play_in())
	_style_title_text()

func _style_title_text() -> void:
	# Re-applied after apply_locale(), which sets the pixel BMFont on every HUD node; the
	# title screen is the one place set in the logotype's own face.
	if title_screen == null:
		return
	title_screen.style_label(title_eyebrow, 7, Color("#c3a785"))
	title_screen.style_label(title_info, 7, Color("#d2c7ba"))
	title_screen.style_button(title_start)

func _build_ending() -> void:
	ending_panel = PanelContainer.new()
	ending_panel.position = Vector2(104, 66)
	ending_panel.size = Vector2(432, 242)
	ending_panel.visible = false
	ending_panel.add_theme_stylebox_override("panel", _pixel_style(Rect2(128, 64, 64, 32), 4))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	ending_panel.add_child(stack)
	ending_label = Label.new()
	ending_label.custom_minimum_size = Vector2(0, 146)
	ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_format_label(ending_label, 18, Color("#f3e2d5"))
	stack.add_child(ending_label)
	ending_restart = Button.new()
	ending_restart.text = Loc.t("btn.restart_shift")
	ending_restart.custom_minimum_size = Vector2(0, 38)
	_format_button(ending_restart, 10)
	ending_restart.pressed.connect(func() -> void: restart_requested.emit())
	stack.add_child(ending_restart)
	root_ui.add_child(ending_panel)

func _build_nvl() -> void:
	nvl_root = Control.new()
	nvl_root.name = "NvlRoot"
	nvl_root.position = Vector2(0, 0)
	nvl_root.size = Vector2(640, 360)
	nvl_root.visible = false
	nvl_root.mouse_filter = Control.MOUSE_FILTER_STOP
	nvl_root.gui_input.connect(_on_vn_gui)
	nvl_veil = ColorRect.new()
	nvl_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	nvl_veil.size = Vector2(640, 360)
	nvl_veil.color = Color(0.18, 0.01, 0.03, 0.88)
	nvl_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	nvl_veil.gui_input.connect(_on_vn_gui)
	nvl_root.add_child(nvl_veil)
	nvl_name = Label.new()
	nvl_name.position = Vector2(40, 48)
	nvl_name.size = Vector2(560, 22)
	nvl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_format_label(nvl_name, 10, Color("#f72a75"))
	nvl_root.add_child(nvl_name)
	nvl_body = Label.new()
	nvl_body.position = Vector2(36, 78)
	nvl_body.size = Vector2(568, 230)
	nvl_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nvl_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nvl_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_format_label(nvl_body, 14, Color("#f5acbf"))
	var sh := load("res://shaders/nvl_shake.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		nvl_body.material = mat
	nvl_root.add_child(nvl_body)
	nvl_hint = Label.new()
	nvl_hint.position = Vector2(200, 322)
	nvl_hint.size = Vector2(240, 18)
	nvl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_format_label(nvl_hint, 8, Color("#ce4170"))
	nvl_root.add_child(nvl_hint)
	pressure = Label.new()
	pressure.position = Vector2(14, 42)
	pressure.size = Vector2(120, 14)
	pressure.visible = false
	_format_label(pressure, 8, Color("#f21d6f"))
	root_ui.add_child(nvl_root)
	root_ui.add_child(pressure)

func set_header(chapter: String, place: String, clock: String, objective: String) -> void:
	chapter_label.text = chapter
	place_label.text = place
	clock_label.text = clock
	objective_label.text = objective

func show_dialogue(lines: Array, use_nvl := false) -> void:
	_queue = lines.duplicate(true)
	_busy = true
	_nvl = use_nvl
	route_button.visible = false
	choice_panel.visible = false
	dialogue_panel.visible = true
	if use_nvl:
		dialogue_panel.modulate.a = 0.0
		nvl_root.visible = true
		nvl_veil.color = Color(0, 0, 0, 1)
		pressure.visible = true
		pressure.text = Loc.t("vn.pressure")
		_pulse = 0.0
	else:
		dialogue_panel.modulate.a = 1.0
		nvl_root.visible = false
		pressure.visible = false
	_advance_dialogue()

func is_line_open() -> bool:
	return dialogue_panel.visible or (nvl_root != null and nvl_root.visible)

func current_line_text() -> String:
	return body_label.text if body_label else ""

func _advance_dialogue() -> void:
	if _queue.is_empty():
		dialogue_panel.visible = false
		dialogue_panel.modulate.a = 1.0
		if nvl_root:
			nvl_root.visible = false
		pressure.visible = false
		_nvl = false
		_busy = false
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("on_dialogue_done"):
			game.on_dialogue_done()
		return
	var line: Array = _queue.pop_front()
	speaker_label.text = str(line[0])
	body_label.text = str(line[1])
	_set_portrait(str(line[0]))
	continue_button.text = Loc.t("btn.continue_n", [_queue.size() + 1])
	if _nvl and nvl_root:
		nvl_name.text = str(line[0])
		nvl_body.text = str(line[1])
		nvl_hint.text = Loc.t("vn.advance")

func _set_portrait(speaker: String) -> void:
	var index := 0
	var s := speaker.to_upper()
	if "ELI" in s or "伊莱" in speaker or "イーライ" in speaker or "엘리" in speaker:
		index = 1
	elif "MARA" in s or "玛拉" in speaker or "マラ" in speaker or "마라" in speaker:
		index = 2
	elif s in ["AUDITOR", "COMPLIANCE", "SYSTEM", "PA"] or "审计" in speaker or "監査" in speaker or "시스템" in speaker or "시스템" in speaker or "广播" in speaker or "广播" in speaker:
		index = 3
	portrait.texture = _atlas(Rect2(index * 48, 0, 48, 48))

func _on_lang_pressed(next: String) -> void:
	Loc.set_code(next)

func _emit_start() -> void:
	if title_panel == null or not title_panel.visible:
		return
	title_panel.visible = false
	title_requested.emit()

func _on_title_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		for b in lang_buttons.values():
			if b is Control and Rect2((b as Control).position, (b as Control).size).has_point(pos):
				return
		_emit_start()

func _on_vn_gui(event: InputEvent) -> void:
	if choice_panel.visible or overlay.visible or ending_panel.visible or _cg_open:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_dialogue()
		get_viewport().set_input_as_handled()

func _is_advance(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER] or event.physical_keycode in [KEY_E, KEY_SPACE, KEY_ENTER]
	return false

func _unhandled_input(event: InputEvent) -> void:
	if title_panel and title_panel.visible:
		if _is_advance(event) and not (event is InputEventMouseButton):
			_emit_start()
			get_viewport().set_input_as_handled()
		return
	if overlay.visible or ending_panel.visible or choice_panel.visible or _cg_open:
		return
	if gallery_root != null and gallery_root.visible:
		return
	if is_line_open():
		if _is_advance(event):
			_advance_dialogue()
			get_viewport().set_input_as_handled()

func show_choice(data: Dictionary) -> void:
	_busy = true
	_nvl = false
	if nvl_root:
		nvl_root.visible = false
	pressure.visible = false
	dialogue_panel.visible = true
	dialogue_panel.modulate.a = 1.0
	speaker_label.text = Loc.t("choice.banner")
	body_label.text = data.prompt
	choice_panel.visible = true
	choice_prompt.text = data.prompt
	choice_a.text = data.a[0]
	choice_b.text = data.b[0]
	_choice_ids = PackedStringArray([data.a[1], data.b[1]])

func _pick(index: int) -> void:
	choice_panel.visible = false
	_busy = false
	choice_made.emit(_choice_ids[index])

func enable_route(label := "") -> void:
	if label == "":
		label = Loc.t("btn.proceed")
	route_button.text = label
	route_button.visible = true

func hide_route() -> void:
	route_button.visible = false

func show_log() -> void:
	if _busy:
		return
	var game := get_tree().get_first_node_in_group("game")
	overlay_title.text = Loc.t("log.title")
	overlay_body.text = game.get_case_log_text() if game else Loc.t("log.empty")
	overlay.visible = true
	_busy = true

func show_pause() -> void:
	if _busy:
		return
	overlay_title.text = Loc.t("pause.title")
	overlay_body.text = Loc.t("pause.body")
	overlay.visible = true
	_busy = true

func show_ending_card(text: String) -> void:
	_busy = true
	dialogue_panel.visible = false
	if nvl_root:
		nvl_root.visible = true
		nvl_name.text = ""
		nvl_body.text = text
		nvl_hint.text = ""
		pressure.visible = true
	ending_label.text = text
	ending_label.visible = false
	ending_panel.visible = true
	ending_panel.position = Vector2(176, 300)
	ending_panel.size = Vector2(288, 48)

func reset_ui() -> void:
	_busy = false
	_nvl = false
	dialogue_panel.visible = false
	dialogue_panel.modulate.a = 1.0
	choice_panel.visible = false
	overlay.visible = false
	ending_panel.visible = false
	ending_panel.modulate = Color(1, 1, 1, 1)
	ending_panel.position = Vector2(104, 66)
	ending_panel.size = Vector2(432, 242)
	if ending_label:
		ending_label.visible = true
	if nvl_root:
		nvl_root.visible = false
	if pressure:
		pressure.visible = false
	if cg_root:
		cg_root.visible = false
	if gallery_root:
		gallery_root.visible = false
	_cg_open = false
	_cg_slot = ""
	_cg_unavailable = false
	route_button.visible = false
	title_panel.visible = true

func apply_locale() -> void:
	UiFont.refresh()
	for node in [title_eyebrow, title_name, title_info, title_lang_caption, title_start,
			chapter_label, place_label, clock_label, objective_label,
			speaker_label, body_label, continue_button, choice_banner, choice_prompt,
			choice_a, choice_b, log_button, pause_button, route_button,
			nvl_name, nvl_body, nvl_hint, pressure, overlay_title, overlay_body,
			overlay_close, overlay_restart, ending_label, ending_restart]:
		if node is Label:
			var display: bool = node == title_name or node == overlay_title or node == ending_label or node == nvl_body
			UiFont.apply_label(node, display)
		elif node is Button:
			UiFont.apply_button(node)
	for code in lang_buttons.keys():
		UiFont.apply_button(lang_buttons[code])
	_style_title_text()
	if title_eyebrow:
		title_eyebrow.text = Loc.t("title.eyebrow")
	if title_name:
		title_name.text = Loc.t("title.name")
	if title_info:
		title_info.text = Loc.t("title.info")
	if title_start:
		title_start.text = Loc.t("title.start")
	if title_lang_caption:
		title_lang_caption.text = Loc.t("lang.caption")
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		b.text = str(Loc.NATIVE[code])
		if str(code) == Loc.current():
			b.add_theme_color_override("font_color", Color("#f2a83a"))
		else:
			b.remove_theme_color_override("font_color")
	if continue_button and not dialogue_panel.visible:
		continue_button.text = Loc.t("btn.continue")
	if log_button:
		log_button.text = Loc.t("btn.case_log")
	if pause_button:
		pause_button.text = Loc.t("btn.pause")
	if route_button and not route_button.visible:
		route_button.text = Loc.t("btn.proceed")
	if choice_banner:
		choice_banner.text = Loc.t("choice.banner")
	if overlay_close:
		overlay_close.text = Loc.t("btn.return")
	if overlay_restart:
		overlay_restart.text = Loc.t("btn.restart")
	if ending_restart:
		ending_restart.text = Loc.t("btn.restart_shift")
	if pressure:
		pressure.text = Loc.t("vn.pressure")
	if nvl_hint and nvl_root and nvl_root.visible:
		nvl_hint.text = Loc.t("vn.advance")
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("on_locale_changed"):
		game.on_locale_changed()

func _process(delta: float) -> void:
	if nvl_root == null or not nvl_root.visible:
		return
	_pulse += delta
	nvl_veil.color = Color(0, 0, 0, 1).lerp(Color(0.2, 0.015, 0.04, 0.9), clampf(_pulse * 3.0, 0.0, 1.0))
	var pulse := 1.0 + 0.1 * sin(_pulse * 3.6)
	nvl_body.scale = Vector2(pulse, pulse)
	nvl_body.pivot_offset = nvl_body.size * 0.5
	if nvl_body.material is ShaderMaterial:
		(nvl_body.material as ShaderMaterial).set_shader_parameter("time", _pulse)
		(nvl_body.material as ShaderMaterial).set_shader_parameter("shake", 2.1 + sin(_pulse * 8.0))
	if pressure:
		pressure.modulate.a = 0.4 + 0.45 * absf(sin(_pulse * 2.5))

## [fork] ------------------------------------------------------------------ CG presenter
##
## The base game can only draw a full-screen image through OfficeBuilder.show_ending(),
## which tears down the scene to do it. A mid-scene plate cannot do that — the room has to
## still be there underneath when the passage resumes — so the presenter is a HUD layer
## over the existing backdrop, which is also the cheapest possible staging and the reason
## this fork needs no new scene.
signal cg_closed

func _build_cg() -> void:
	cg_root = Control.new()
	cg_root.name = "CgRoot"
	cg_root.position = Vector2(0, 0)
	cg_root.size = Vector2(640, 360)
	cg_root.visible = false
	cg_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.size = Vector2(640, 360)
	veil.color = Color(0.01, 0.015, 0.03, 0.97)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cg_root.add_child(veil)
	cg_plate = TextureRect.new()
	cg_plate.name = "CgPlate"
	cg_plate.position = Vector2(32, 18)
	cg_plate.size = Vector2(576, 288)
	cg_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cg_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cg_root.add_child(cg_plate)
	cg_caption = Label.new()
	cg_caption.position = Vector2(32, 306)
	cg_caption.size = Vector2(400, 18)
	_format_label(cg_caption, 9, Color("#f2a83a"))
	cg_root.add_child(cg_caption)
	cg_notice = Label.new()
	cg_notice.position = Vector2(32, 322)
	cg_notice.size = Vector2(420, 18)
	cg_notice.visible = false
	_format_label(cg_notice, 8, Color("#f21d6f"))
	cg_root.add_child(cg_notice)
	cg_unlock = Button.new()
	cg_unlock.position = Vector2(400, 316)
	cg_unlock.size = Vector2(110, 32)
	cg_unlock.text = "UNLOCK"
	cg_unlock.visible = false
	_format_button(cg_unlock, 8)
	cg_unlock.pressed.connect(_on_cg_unlock)
	cg_root.add_child(cg_unlock)
	cg_dismiss = Button.new()
	cg_dismiss.position = Vector2(518, 316)
	cg_dismiss.size = Vector2(90, 32)
	cg_dismiss.text = "CONTINUE"
	_format_button(cg_dismiss, 8)
	cg_dismiss.pressed.connect(_close_cg)
	cg_root.add_child(cg_dismiss)
	root_ui.add_child(cg_root)

func set_cg_notice(unavailable: bool) -> void:
	_cg_unavailable = unavailable

## Show one plate and wait for the player to dismiss it. Censored or open is decided by
## CgGate.plate_path(), which checks the *file*, because the free packages genuinely do not
## contain the uncensored plates.
func show_cg(slot: String) -> void:
	_cg_slot = slot
	_cg_open = true
	_busy = true
	dialogue_panel.visible = false
	if nvl_root:
		nvl_root.visible = false
	pressure.visible = false
	_refresh_cg()
	cg_root.visible = true
	await cg_closed

func _refresh_cg() -> void:
	var path := CgGate.plate_path(_cg_slot)
	# plate_texture(), not load(): a plate delivered by the gateway lives in user:// as raw
	# WebP bytes, and load() only resolves res:// resources — it would have drawn nothing.
	cg_plate.texture = CgGate.plate_texture(_cg_slot)
	var censored := CgGate.is_showing_censored(_cg_slot)
	cg_caption.text = CgGate.slot_title(_cg_slot) + ("  ·  RECORD WITHHELD" if censored else "")
	# Only offer the trade when there is art on the other side of it. cg_desk_x has no
	# render installed yet (ops/adult_forks/STATUS.md), so nothing is staged on the
	# gateway for it either and a clip spent on it would buy the same censored plate.
	cg_unlock.visible = censored and CgGate.can_unlock(_cg_slot)
	cg_notice.visible = censored and _cg_unavailable
	if cg_notice.visible:
		# Named for what happened, not blamed on the player: no creative was served, so
		# there was nothing to trade the plate for.
		cg_notice.text = "No sponsor available — the plate stays withheld."
	if path == "" and censored:
		cg_caption.text = CgGate.slot_title(_cg_slot) + "  ·  RECORD WITHHELD (no plate shipped)"

func _on_cg_unlock() -> void:
	var result := await CgGate.request_unlock(_cg_slot)
	_cg_unavailable = result == "unavailable"
	_refresh_cg()

func _close_cg() -> void:
	cg_root.visible = false
	_cg_open = false
	_cg_unavailable = false
	_busy = false
	cg_closed.emit()

## [fork] -------------------------------------------------------------------- gallery
##
## Earned plates only. A slot that was never earned is not listed as a locked teaser,
## because the design's whole claim is that treating Eli as a discrepancy costs content —
## and a grid of grey rectangles telling the player exactly what they missed converts that
## into a checklist, which is the opposite of the point.
func _build_gallery() -> void:
	gallery_root = Control.new()
	gallery_root.name = "GalleryRoot"
	gallery_root.position = Vector2(0, 0)
	gallery_root.size = Vector2(640, 360)
	gallery_root.visible = false
	gallery_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.size = Vector2(640, 360)
	veil.color = Color(0.01, 0.015, 0.03, 0.97)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery_root.add_child(veil)
	var title := Label.new()
	title.name = "GalleryTitle"
	title.position = Vector2(26, 18)
	title.size = Vector2(400, 22)
	_format_label(title, 14, Color("#f2a83a"))
	title.text = "RECOVERED RECORDS"
	gallery_root.add_child(title)
	gallery_grid = GridContainer.new()
	gallery_grid.name = "GalleryGrid"
	gallery_grid.position = Vector2(26, 52)
	gallery_grid.size = Vector2(588, 248)
	gallery_grid.columns = 4
	gallery_grid.add_theme_constant_override("h_separation", 8)
	gallery_grid.add_theme_constant_override("v_separation", 8)
	gallery_root.add_child(gallery_grid)
	gallery_close = Button.new()
	gallery_close.position = Vector2(258, 314)
	gallery_close.size = Vector2(124, 32)
	gallery_close.text = Loc.t("btn.return")
	_format_button(gallery_close, 9)
	gallery_close.pressed.connect(func() -> void:
		gallery_root.visible = false
		_busy = false)
	gallery_root.add_child(gallery_close)
	root_ui.add_child(gallery_root)

func show_gallery() -> void:
	if _busy:
		return
	for child in gallery_grid.get_children():
		child.queue_free()
	var any := false
	for slot in CgGate.gallery_order():
		if not CgGate.is_earned(slot):
			continue
		any = true
		var thumb := Button.new()
		thumb.name = "Gallery_%s" % slot
		thumb.custom_minimum_size = Vector2(138, 104)
		thumb.tooltip_text = CgGate.slot_title(slot) + ("  (withheld)" if CgGate.is_showing_censored(slot) else "")
		var path := CgGate.plate_path(slot)
		if path != "":
			thumb.icon = CgGate.plate_texture(slot)
			thumb.expand_icon = true
		thumb.text = "" if path != "" else CgGate.slot_title(slot)
		_format_button(thumb, 8)
		thumb.pressed.connect(func() -> void:
			gallery_root.visible = false
			_busy = false
			show_cg(slot))
		gallery_grid.add_child(thumb)
	if not any:
		var empty := Label.new()
		empty.custom_minimum_size = Vector2(560, 60)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_format_label(empty, 9, Color("#bc9b89"))
		# The rule, said in the game rather than only in the store copy.
		empty.text = "Nothing recovered yet. Records are not recovered by staying on the floor longer. They are recovered by what you decided about the other two people who are still in this building."
		gallery_grid.add_child(empty)
	gallery_root.visible = true
	_busy = true

func is_busy() -> bool:
	return _busy or _cg_open or (gallery_root != null and gallery_root.visible) or dialogue_panel.visible or choice_panel.visible or overlay.visible or ending_panel.visible or (nvl_root != null and nvl_root.visible)
