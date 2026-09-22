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
var title_screen: TitleScreen
var _title_up := false   # the title screen owns the screen; the game HUD keeps quiet
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
var plates: PlateLayer
var gallery_panel: Control
var gallery_list: VBoxContainer
var gallery_view: TextureRect
var gallery_caption: Label

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
	# The plate layer lives inside the NVL root, above the veil and under the text.
	plates = PlateLayer.new()
	vn.nvl_root.add_child(plates)
	vn.nvl_root.move_child(plates, 1)
	_gallery_ui()

## ops/STANDARD.md item 4: buttons are not rectangles. The shape comes from the game's own
## world -- a torn summons stub, since this fork's core object is the inspection order/
## consent clause slid under a door, not the survey clipboard the (all-ages) parent hands
## out. TICKET rather than the parent's TAG keeps this fork reading as its own object.
func _mk_btn(n: String, off: Vector2, size: Vector2) -> ShapedButton:
	var b := ShapedButton.new()
	b.name = n
	b.shape = ShapedButton.Shape.TICKET
	b.tint = Color("#8a2f2f")
	b.ink = Color("#120705")
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.offset_left = off.x
	b.offset_top = off.y
	b.offset_right = off.x + size.x
	b.offset_bottom = off.y + size.y
	b.add_theme_font_size_override("font_size", 16)
	UiFont.apply_button(b)
	return b

## Set the visible words on a title/menu button whether or not it is a ShapedButton.
## ShapedButton draws its own text from `label` and clears Button.text in _ready -- writing
## .text directly on one of these draws nothing (shaped_button.gd's own header warns about
## this exact silent failure), so every caller routes through here instead.
func _btn_text(b: Button, s: String) -> void:
	if b is ShapedButton:
		(b as ShapedButton).label = s
		b.queue_redraw()
	else:
		b.text = s

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
	_btn_text(ending_button, Loc.t("btn.continue"))
	ending_button.pressed.connect(_next_ending_beat)
	ending_panel.add_child(ending_button)
	add_child(ending_panel)

func _splash() -> void:
	# The composition is TitleScreen (scripts/title_screen.gd): the corridor dolly, the key
	# visual, the typewriter mark, the marks and the sound. This keeps the HUD's own nodes
	# — splash_title (hidden; the logotype is the name), the language buttons, EnterBuilding
	# — and sets them in the title's face, so hide_splash()/splash_enter keep working for
	# every test and for game.gd.
	splash = Control.new()
	splash.name = "Splash"
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	title_screen = TitleScreen.new()
	title_screen.name = "TitleScreen"
	splash.add_child(title_screen)
	splash_title = Label.new()
	splash_title.visible = false
	UiFont.apply_label(splash_title)
	splash.add_child(splash_title)
	lang_caption = Label.new()
	lang_caption.visible = false   # the `info` label below says this; two 18+ paragraphs
	                               # stacked on one title screen is the AI look, not design
	lang_caption.position = Vector2(64, 318)
	lang_caption.size = Vector2(640, 24)
	lang_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_screen.style_label(lang_caption, 13, Color(0.7, 0.72, 0.6, 1))
	splash.add_child(lang_caption)
	var codes := Loc.ALLOWED if Loc.ALLOWED.size() > 1 else []
	for i in codes.size():
		var code := str(codes[i])
		var col := i % 3
		var row := int(i / 3)
		var b := _mk_btn("Lang_%s" % code, Vector2(-576 + col * 186, 0 + row * 50), Vector2(174, 44))
		_btn_text(b, str(Loc.NATIVE[code]))
		b.pressed.connect(func() -> void: Loc.set_code(code))
		title_screen.style_button(b)
		splash.add_child(b)
		lang_buttons[code] = b
		if code == "en":
			lang_en = b
		elif code == "zh":
			lang_zh = b
	# The one line the form needs said: what this is, and that it is for adults.
	var info := Label.new()
	info.position = Vector2(64, 470)
	info.size = Vector2(620, 60)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "18+  ·  A night inspection in first person, 40 minutes, three endings.\nEveryone in the building is an adult. Headphones recommended."
	title_screen.style_label(info, 13, Color(0.78, 0.8, 0.7, 1))
	splash.add_child(info)
	splash_enter = _mk_btn("Enter", Vector2(-576, 190), Vector2(400, 54))
	splash_enter.name = "EnterBuilding"
	title_screen.style_button(splash_enter)
	splash_enter.pressed.connect(enter_building)
	splash.add_child(splash_enter)
	# The title accepts a click ANYWHERE, not only on EnterBuilding.
	#
	# This connection is the whole of a bug that made the game look unfinished for three
	# weeks. `splash` is a full-rect Control on MOUSE_FILTER_STOP, so it swallowed every
	# mouse button that landed on it — and game.gd:247 has a "while the splash is up, any
	# click dismisses it" branch in _unhandled_input that therefore never once ran: a
	# consumed event is not an unhandled one. `_on_splash_input` was written for this and
	# was never connected to anything, so the ONLY way into the building was to hit a
	# 400x54 button sitting left of centre.
	#
	# What that cost: ops/play_matrix.py reported `overnight-clause — 2 stage(s) of 12
	# frames`, i.e. the automated play-through never got past the title, and the two
	# distinct frames it did find were the title breathing. The build was fine — every
	# test including tests/walkthrough.gd plays all three routes to an ending — so the
	# source read as working and the game read as broken. It was neither: it was
	# unreachable.
	splash.gui_input.connect(_on_splash_input)
	add_child(splash)
	_hide_gameplay_hud(true)


## While the title is up, the game's own HUD is not. The first shot of the new title
## screen had the prompt, the clock, the chapter line and the "401" door label printed
## across the key visual — the game talking over its own cover. These are hidden for the
## splash and put back by hide_splash(); nothing is freed, so every test that reaches for
## hud.prompt or hud.clock still finds the node.
func _hide_gameplay_hud(hidden: bool) -> void:
	_title_up = hidden
	for n in [prompt, note, objective, clock, title, chapter, evidence_label]:
		if n:
			n.visible = not hidden

## Any click on the title that is not on one of its buttons: enter the building. The
## language buttons are children with their own mouse_filter, so they are picked first and
## a player choosing 中文 does not start the game by doing so.
func _on_splash_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		enter_building()


## The keyboard way in, and the one a controller lands on. Space / Enter / E are the three
## keys this game already uses to advance and to interact, so the title answers all three
## rather than teaching a fourth.
func enter_building() -> void:
	if splash == null or not splash.visible:
		return
	hide_splash()
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("capture_mouse"):
		p.capture_mouse()

func hide_splash() -> void:
	_hide_gameplay_hud(false)
	if splash:
		splash.visible = false
		splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if title_screen:
			title_screen.leave()
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
	# game.gd shows the place card as the level starts, which is while the title screen is
	# still up — the card was printing over the key visual. It waits its turn.
	title.visible = not _title_up

func hide_title() -> void:
	if title:
		title.visible = false

func set_fear(v: float) -> void:
	fear = v

func is_blocking() -> bool:
	return (splash and splash.visible) or (pause_panel and pause_panel.visible) or is_choice_open() or is_nvl_open() or is_gallery_open()

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
	_btn_text(ending_button, Loc.t("btn.continue"))
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
			_btn_text(ending_button, Loc.t("btn.restart"))
		return
	ending_index += 1
	if ending_index >= ending_beats.size():
		ending_text.text = Loc.t("ending.thanks")
		_btn_text(ending_button, Loc.t("btn.restart"))
		ending_button.pressed.disconnect(_next_ending_beat)
		ending_button.pressed.connect(func() -> void: get_tree().call_group("game", "restart"))
		return
	ending_text.text = str(ending_beats[ending_index])
	if ending_index == ending_beats.size() - 1:
		_btn_text(ending_button, Loc.t("btn.credits"))

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
		_btn_text(splash_enter, Loc.t("splash.start"))
	if pause_lab:
		pause_lab.text = Loc.t("pause.title")
	if pause_resume:
		_btn_text(pause_resume, Loc.t("pause.resume"))
	if pause_restart:
		_btn_text(pause_restart, Loc.t("pause.restart"))
	if lang_caption:
		lang_caption.text = Loc.t("splash.adult")
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		_btn_text(b, str(Loc.NATIVE[code]))
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


# ---- plate layer ----------------------------------------------------------

func show_plate(id: String) -> bool:
	if plates == null:
		return false
	var unlocked := plates.show_plate(id)
	if plates.visible and vn and vn.nvl_veil:
		# Let the picture through; the NVL veil is opaque by default.
		vn.nvl_veil.color = Color(0.04, 0.0, 0.01, 0.25)
	return unlocked


func hide_plate() -> void:
	if plates:
		plates.hide_plate()
	if vn and vn.nvl_veil:
		vn.nvl_veil.color = Color(0.04, 0.0, 0.01, 1.0)


# ---- gallery --------------------------------------------------------------

func _gallery_ui() -> void:
	gallery_panel = Control.new()
	gallery_panel.name = "Gallery"
	gallery_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	gallery_panel.visible = false
	gallery_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.025, 0.02, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery_panel.add_child(bg)
	gallery_view = TextureRect.new()
	gallery_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	gallery_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gallery_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	gallery_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery_view.visible = false
	gallery_panel.add_child(gallery_view)
	var head := Label.new()
	head.position = Vector2(48, 36)
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55))
	head.text = Loc.t("gallery.title")
	UiFont.apply_label(head)
	gallery_panel.add_child(head)
	gallery_list = VBoxContainer.new()
	gallery_list.position = Vector2(48, 84)
	gallery_list.custom_minimum_size = Vector2(760, 0)
	gallery_list.add_theme_constant_override("separation", 6)
	gallery_panel.add_child(gallery_list)
	gallery_caption = Label.new()
	gallery_caption.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	gallery_caption.offset_left = 48.0
	gallery_caption.offset_top = -64.0
	gallery_caption.offset_right = 980.0
	gallery_caption.offset_bottom = -28.0
	gallery_caption.add_theme_font_size_override("font_size", 13)
	gallery_caption.add_theme_color_override("font_color", Color(0.72, 0.64, 0.5, 0.9))
	gallery_caption.text = Loc.t("gallery.hint")
	UiFont.apply_label(gallery_caption)
	gallery_panel.add_child(gallery_caption)
	add_child(gallery_panel)


func is_gallery_open() -> bool:
	return gallery_panel != null and gallery_panel.visible


func toggle_gallery() -> void:
	if gallery_panel == null:
		return
	gallery_panel.visible = not gallery_panel.visible
	gallery_view.visible = false
	if gallery_panel.visible:
		_fill_gallery()
	_sync_mouse()


func _fill_gallery() -> void:
	for child in gallery_list.get_children():
		child.queue_free()
	for row in plates.gallery_rows():
		var b := Button.new()
		b.custom_minimum_size = Vector2(700, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var state := Loc.t("gallery.unseen")
		if bool(row["seen"]):
			state = Loc.t("gallery.locked") if (bool(row["gated"]) and not bool(row["unlocked"])) else Loc.t("gallery.seen")
		b.text = "%s   —   %s" % [str(row["title"]), state]
		b.disabled = not bool(row["seen"])
		UiFont.apply_button(b)
		var id := str(row["id"])
		b.pressed.connect(func() -> void: _view_plate(id))
		gallery_list.add_child(b)


func _view_plate(id: String) -> void:
	var picked: Array = plates.pick(id)
	if picked[0] == null:
		gallery_caption.text = Loc.t("gallery.missing")
		return
	gallery_view.texture = picked[0]
	gallery_view.visible = true
	gallery_caption.text = Loc.t("gallery.locked_hint") if bool(picked[1]) else Loc.t("gallery.hint")


func append_story_page(text: String) -> void:
	## Add pages to the sequence that is already on screen — used to say, inside the
	## scene, that this build carries the censored plate.
	if vn == null or text.strip_edges() == "":
		return
	vn.lines.append_array(VnChrome.parse_text(text))
