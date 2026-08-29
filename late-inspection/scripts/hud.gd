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
var vn: VnChrome
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
var document_panel: Control
var document_text: Label
var document_page: Label
var document_button: Button
var document_pages: PackedStringArray
var document_index := 0
var _document_cb: Callable = Callable()
var splash_title: Label
var pause_lab: Label
var pause_resume: Button
var pause_restart: Button
var lang_en: Button
var lang_zh: Button
var lang_buttons: Dictionary = {}
var lang_caption: Label
var splash_enter: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	note.visible = false
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.text = ""
	prompt.offset_top = -248.0
	prompt.offset_bottom = -208.0
	UiFont.apply_label(prompt)
	UiFont.apply_label(note)
	UiFont.apply_label(objective)
	_clock()
	_chapter()
	_title()
	_grain()
	_vn_ui()
	_pause_ui()
	_ending_ui()
	_splash()
	Loc.on_change(apply_locale)
	apply_locale()

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

func _vn_ui() -> void:
	vn = VnChrome.new()
	vn.name = "VnChrome"
	add_child(vn)
	vn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_panel = vn.choice_root
	choice_prompt = vn.choice_prompt
	btn_a = vn.btn_a
	btn_b = vn.btn_b
	document_panel = vn.adv_root
	document_text = vn.body
	document_page = vn.hint
	document_button = Button.new()
	document_button.visible = false
	add_child(document_button)

func _mk_btn(n: String, off: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.name = n
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.offset_left = off.x
	b.offset_top = off.y
	b.offset_right = off.x + size.x
	b.offset_bottom = off.y + size.y
	b.add_theme_font_size_override("font_size", 16)
	UiFont.apply_button(b)
	return b

func _pause_ui() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.01, 0.88)
	pause_panel.add_child(dim)
	pause_lab = Label.new()
	pause_lab.set_anchors_preset(Control.PRESET_CENTER)
	pause_lab.offset_left = -320
	pause_lab.offset_right = 320
	pause_lab.offset_top = -150
	pause_lab.offset_bottom = -40
	pause_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_lab.add_theme_font_size_override("font_size", 23)
	UiFont.apply_label(pause_lab)
	pause_panel.add_child(pause_lab)
	pause_resume = _mk_btn("Resume", Vector2(-180, 10), Vector2(360, 48))
	pause_resume.pressed.connect(func() -> void: get_tree().call_group("game", "toggle_pause"))
	pause_panel.add_child(pause_resume)
	pause_restart = _mk_btn("Restart", Vector2(-180, 72), Vector2(360, 48))
	pause_restart.pressed.connect(func() -> void: get_tree().call_group("game", "restart"))
	pause_panel.add_child(pause_restart)
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
	ending_button.text = Loc.t("btn.continue")
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
	splash_title = Label.new()
	splash_title.set_anchors_preset(Control.PRESET_CENTER)
	splash_title.offset_left = -440.0
	splash_title.offset_right = 440.0
	splash_title.offset_top = -140.0
	splash_title.offset_bottom = 20.0
	splash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title.add_theme_font_size_override("font_size", 24)
	splash_title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.72, 1))
	UiFont.apply_label(splash_title)
	splash.add_child(splash_title)
	lang_caption = Label.new()
	lang_caption.set_anchors_preset(Control.PRESET_CENTER)
	lang_caption.offset_left = -200
	lang_caption.offset_right = 200
	lang_caption.offset_top = 16
	lang_caption.offset_bottom = 40
	lang_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lang_caption.add_theme_font_size_override("font_size", 16)
	lang_caption.add_theme_color_override("font_color", Color(0.7, 0.62, 0.5, 1))
	UiFont.apply_label(lang_caption)
	splash.add_child(lang_caption)
	var codes := Loc.ALLOWED
	for i in codes.size():
		var code := str(codes[i])
		var col := i % 3
		var row := int(i / 3)
		var b := _mk_btn("Lang_%s" % code, Vector2(-270 + col * 186, 48 + row * 50), Vector2(174, 44))
		b.text = str(Loc.NATIVE[code])
		b.pressed.connect(func() -> void: Loc.set_code(code))
		splash.add_child(b)
		lang_buttons[code] = b
		if code == "en":
			lang_en = b
		elif code == "zh":
			lang_zh = b
	splash_enter = _mk_btn("Enter", Vector2(-180, 156), Vector2(360, 52))
	splash_enter.name = "EnterBuilding"
	splash_enter.pressed.connect(func() -> void:
		hide_splash()
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("capture_mouse"):
			p.capture_mouse()
	)
	splash.add_child(splash_enter)
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
	if not is_blocking():
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
		evidence_label.text = Loc.t("evidence", [evidence.size()])

func show_title(t: String) -> void:
	title.text = t
	title.visible = true

func hide_title() -> void:
	if title:
		title.visible = false

func set_fear(v: float) -> void:
	fear = v

func is_blocking() -> bool:
	return (splash and splash.visible) or (pause_panel and pause_panel.visible) or is_choice_open() or is_nvl_open()

func is_vn_open() -> bool:
	return vn != null and vn.is_open()

func is_nvl_open() -> bool:
	return vn != null and vn.is_nvl_open()

func is_choice_open() -> bool:
	return vn != null and vn.is_choice_open()

func show_note(t: String) -> void:
	note.visible = false
	note_t = 0.0
	hide_title()
	_document_cb = Callable()
	vn.show_text(t, false, Callable())
	document_pages = vn.document_pages
	document_panel = vn.adv_root
	_sync_mouse()

func show_document(t: String, cb: Callable) -> void:
	show_story("", t, false, cb)

func show_story(id: String, t: String, use_nvl: bool, cb: Callable) -> void:
	hide_title()
	_document_cb = cb
	vn.show_text(t, use_nvl or VnChrome.is_nvl_id(id), func() -> void:
		document_panel = vn.adv_root
		_sync_mouse()
		var done := _document_cb
		_document_cb = Callable()
		if done.is_valid():
			done.call()
	)
	document_pages = vn.document_pages
	document_panel = vn.nvl_root if vn.is_nvl_open() else vn.adv_root
	_sync_mouse()

func _next_document_page() -> void:
	if vn == null or not vn.is_open():
		return
	vn.advance(true)
	document_panel = vn.nvl_root if vn.is_nvl_open() else vn.adv_root
	if not vn.is_open():
		_sync_mouse()

func advance_vn() -> void:
	if vn == null:
		return
	vn.advance(false)
	document_panel = vn.nvl_root if vn.is_nvl_open() else vn.adv_root
	_sync_mouse()

func open_choice(text: String, a: String, b: String, cb: Callable) -> void:
	_choice_cb = cb
	vn.open_choice(text, a, b, func(i: int) -> void:
		var done := _choice_cb
		_choice_cb = Callable()
		_sync_mouse()
		if done.is_valid():
			done.call(i)
	)
	choice_panel = vn.choice_root
	_sync_mouse()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _sync_mouse() -> void:
	if is_blocking():
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_pause(value: bool) -> void:
	pause_panel.visible = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

func show_ending(t: String, beats: Array, thanks_key := "ending.thanks") -> void:
	ending_title.text = t
	ending_beats = beats
	ending_index = 0
	ending_panel.visible = true
	ending_panel.modulate = Color(1, 1, 1, 0)
	ending_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_text.text = str(ending_beats[0])
	ending_button.text = Loc.t("btn.continue")
	var pages: Array = [{"speaker": "SYSTEM", "body": t}]
	for beat in beats:
		pages.append_array(VnChrome.parse_text(str(beat)))
	pages.append({"speaker": "SYSTEM", "body": Loc.t(thanks_key)})
	vn.show_lines(pages, true, Callable(), true)
	document_panel = vn.nvl_root
	_sync_mouse()

func _next_ending_beat() -> void:
	if vn and vn.is_open():
		vn.advance(true)
		ending_index = vn.line_index
		if ending_index >= vn.lines.size() - 1:
			ending_button.text = Loc.t("btn.restart")
		return
	ending_index += 1
	if ending_index >= ending_beats.size():
		ending_text.text = Loc.t("ending.thanks")
		ending_button.text = Loc.t("btn.restart")
		ending_button.pressed.disconnect(_next_ending_beat)
		ending_button.pressed.connect(func() -> void: get_tree().call_group("game", "restart"))
		return
	ending_text.text = str(ending_beats[ending_index])
	if ending_index == ending_beats.size() - 1:
		ending_button.text = Loc.t("btn.credits")

func _pick(i: int) -> void:
	if vn:
		vn.pick(i)
	else:
		var cb := _choice_cb
		_choice_cb = Callable()
		if cb.is_valid():
			cb.call(i)

func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0:
			note.visible = false
	var nvl_boost := 0.55 if is_nvl_open() else 0.0
	vignette.color.a = 0.05 + fear * 0.3 + nvl_boost
	if grain and grain.material is ShaderMaterial:
		(grain.material as ShaderMaterial).set_shader_parameter("grain", 0.06 + fear * 0.1 + nvl_boost * 0.12)


func apply_locale() -> void:
	UiFont.refresh()
	if splash_title:
		UiFont.apply_label(splash_title)
		splash_title.text = "%s\n%s" % [Loc.t("splash.title"), Loc.t("splash.hint")]
	if splash_enter:
		splash_enter.text = Loc.t("splash.start")
	if pause_lab:
		pause_lab.text = Loc.t("pause.title")
	if pause_resume:
		pause_resume.text = Loc.t("pause.resume")
	if pause_restart:
		pause_restart.text = Loc.t("pause.restart")
	if lang_caption:
		lang_caption.text = Loc.t("lang.caption")
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		b.text = str(Loc.NATIVE[code])
		UiFont.apply_button(b)
		if str(code) == Loc.current():
			b.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
		else:
			b.remove_theme_color_override("font_color")
	if evidence_label and evidence.size() > 0:
		evidence_label.text = Loc.t("evidence", [evidence.size()])
	if vn:
		vn.apply_locale()
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("on_locale_changed"):
		game.on_locale_changed()
