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
var title_screen: TitleScreen
var title_panel: Control
var title_mark: TextureRect
## The title column: the form sheet down the left of the composition
## (scripts/title_screen.gd FORM_POS/FORM_SIZE) and the type inside it. These two numbers
## and the sheet's are ONE layout — move one without the other and the type walks off the
## paper.
##
## Narrowed from 520 on 2026-09-21. The sheet used to be 548 wide and 606 tall: a slab
## over 44% of a 1280x720 canvas at about half opacity, plus a vignette, plus a 0.82/0.90/
## 0.86 multiply on the picture itself. Measured, the composite took a 0.80-brightness key
## visual down to **0.41 brightness / 0.17 saturation** — the lowest saturation on the
## studio shelf, against a horror floor of 0.60/0.38. The picture is now mostly picture.
const COL_X := 26.0
const COL_W := 418.0

## The primary control lives in the MIDDLE of the canvas, not at the foot of the left
## column, and the languages are one row across the bottom.
##
## This is a composition fix that happens to also be a reachability fix. ops/play_driver.py
## walks every game in the studio by pressing the obvious places — (640, 500), (640, 400),
## (640, 360) — and ENTER THE BUILDING was a 520-wide button at x=26, its centre at
## (286, 569). The driver never touched it, so the matrix for this game was three tiles of
## the title screen and read as "broken". Nothing was broken; the only door in was in the
## corner. A primary action a generic prober cannot find is one a player has to hunt for.
const ENTER_RECT := Rect2(Vector2(420.0, 470.0), Vector2(440.0, 86.0))
const LANG_ROW_Y := 596.0
const LANG_SIZE := Vector2(232.0, 46.0)
const LANG_GAP := 8.0

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
	title_mark = TextureRect.new()
	title_mark.name = "TitleMark"
	if ResourceLoader.exists("res://assets/title/logotype.png"):
		title_mark.texture = load("res://assets/title/logotype.png")
	title_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_mark.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# Full width and tall: the mark carries its own outline, bevel and shadow now, and
	# the shelf's marks are at least a quarter of the frame wide (62 of 64). At
	# -300..300 / 96..320 this one was a caption.
	title_mark.offset_left = -620.0
	title_mark.offset_right = 620.0
	title_mark.offset_top = 28.0
	title_mark.offset_bottom = 508.0
	title_mark.visible = false
	title_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_mark)
	title.offset_top = 296.0
	title.offset_bottom = 356.0
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

## The pause menu's and the ending screen's buttons, and they are the SAME condemnation
## tag the title menu is made of (see _col_btn, and ops/STANDARD.md item 4).
##
## They were plain `Button.new()` rectangles until 2026-09-21 -- the title screen had been
## given the game's shape and the two screens behind it had not, which is worse than
## neither having it: the player meets the fiction on the first screen and then presses a
## stock grey box for the rest of the game.
##
## `compact` matters and is not cosmetic: ShapedButton forces a 220x56 minimum on anything
## that does not set it, and these are 360x48 and 360x50. Without it the pause menu's two
## rows grow past their 62 px pitch and overlap.
func _mk_btn(n: String, off: Vector2, size: Vector2) -> ShapedButton:
	var b := ShapedButton.new()
	b.name = n
	b.compact = true
	b.shape = ShapedButton.Shape.TAG
	# Buff card stock, the same tag the title menu hands out. The pause and ending screens
	# both sit on near-black scrims, so this is the un-lit tag rather than the amber one:
	# the amber is reserved for the single control the player must find on the title.
	b.tint = Color("#9fb6a1")
	b.ink = Color("#11150f")
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
	_btn_text(ending_button, Loc.t("btn.continue"))
	ending_button.pressed.connect(_next_ending_beat)
	ending_panel.add_child(ending_button)
	add_child(ending_panel)

func _splash() -> void:
	# The first screen of the game — ops/adult_forks/TITLE_SCREENS.md. It used to be a
	# brown ColorRect with a centred Label on it, which is what Blaze meant by "looks like
	# a document". The composition (key visual, logotype, moving torch, damp, baked
	# overlay) is scripts/title_screen.gd; the HUD keeps owning these buttons, so every
	# test that presses `splash_enter` still does, and places them in the form column down
	# the LEFT of that composition.
	splash = Control.new()
	splash.name = "Splash"
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	title_screen = TitleScreen.new()
	title_screen.name = "TitleScreen"
	splash.add_child(title_screen)

	splash_title = Label.new()
	splash_title.name = "SplashTitle"
	# Below the mark, not through it: the logotype is a full-width arc since
	# 2026-09-22 and its left end lands at y~230.
	splash_title.position = Vector2(COL_X, 306)
	splash_title.size = Vector2(COL_W, 100)
	splash_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	splash_title.add_theme_constant_override("line_spacing", 6)
	splash.add_child(splash_title)

	lang_caption = Label.new()
	lang_caption.name = "LangCaption"
	# The caption follows its field. The languages are a row across the foot of the picture
	# now, so their label goes with them rather than staying at y=342 captioning air.
	lang_caption.position = Vector2(0.0, LANG_ROW_Y - 30.0)
	lang_caption.size = Vector2(1280.0, 26)
	lang_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash.add_child(lang_caption)

	# One row across the foot of the picture, centred. A 2x3 grid in the left column meant
	# the last row sat at y=490 and a form rule ran through it; a row also makes the five
	# tags read as one row of tags on a hook, which is what they now look like.
	var codes := Loc.ALLOWED
	var row_w := codes.size() * LANG_SIZE.x + (codes.size() - 1) * LANG_GAP
	var row_x := (1280.0 - row_w) * 0.5
	for i in codes.size():
		var code := str(codes[i])
		var b := _col_btn("Lang_%s" % code,
			Vector2(row_x + i * (LANG_SIZE.x + LANG_GAP), LANG_ROW_Y), LANG_SIZE)
		_btn_text(b, str(Loc.NATIVE[code]))
		b.pressed.connect(func() -> void: Loc.set_code(code))
		splash.add_child(b)
		lang_buttons[code] = b
		if code == "en":
			lang_en = b
		elif code == "zh":
			lang_zh = b

	splash_enter = _col_btn("Enter", ENTER_RECT.position, ENTER_RECT.size, true)
	splash_enter.name = "EnterBuilding"
	splash_enter.pressed.connect(func() -> void:
		hide_splash()
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("capture_mouse"):
			p.capture_mouse()
	)
	splash.add_child(splash_enter)
	add_child(splash)
	title_panel = splash


## A button placed by its top-left corner in the title composition, styled by the title
## screen so the menu is set in the same family as the mark.
##
## It is a CONDEMNATION TAG, not a rectangle (ops/STANDARD.md item 4, and
## scripts/shaped_button.gd Shape.TAG). A building condition survey ends with a tag wired
## to the meter or the door of a unit that failed: punched eyelet, one pointed end, a
## number written on it. That is the object this game's fiction hands the player, so it is
## the object they press — and it sways off its eyelet on hover, which is what a tag on a
## wire does when you touch it.
##
## ShapedButton draws its own text from `label` and clears Button.text in _ready, so the
## localiser has to go through _btn_text below rather than assigning .text. Assigning
## .text on one of these is not an error, it just draws nothing — which is precisely the
## silent-failure class this repo keeps meeting, so there is one helper and nothing
## assigns .text directly.
func _col_btn(n: String, pos: Vector2, size: Vector2, primary := false) -> ShapedButton:
	var b := ShapedButton.new()
	b.name = n
	b.shape = ShapedButton.Shape.TAG
	# The tag is buff card stock; the primary one is the amber of the torch, because it is
	# the only thing on the screen the player must find.
	b.tint = Color("#d8a24e") if primary else Color("#9fb6a1")
	b.ink = Color("#11150f")
	b.position = pos
	b.size = size
	b.custom_minimum_size = size
	if title_screen:
		title_screen.style_button(b, primary)
	else:
		UiFont.apply_button(b)
	return b


## Set the visible words on a title button whether or not it is a ShapedButton.
func _btn_text(b: Button, s: String) -> void:
	if b is ShapedButton:
		(b as ShapedButton).label = s
		b.queue_redraw()
	else:
		b.text = s


func _on_splash_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_splash()
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("capture_mouse"):
			p.capture_mouse()

func hide_splash() -> void:
	if title_screen:
		title_screen.stop_audio()
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

## The in-game card, after the door closes behind the player. It was the raw two-line
## Label that made the opening look like a document; now it is the same designed mark the
## title screen carries, with the localised line under it.
func show_title(t: String) -> void:
	var lines := t.split("\n")
	title.text = lines[lines.size() - 1] if lines.size() > 1 else ""
	title.visible = title.text != ""
	if title_mark:
		title_mark.visible = true
		title_mark.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(title_mark, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func hide_title() -> void:
	if title:
		title.visible = false
	if title_mark:
		title_mark.visible = false

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

func show_ending(t: String, beats: Array) -> void:
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
	pages.append({"speaker": "SYSTEM", "body": Loc.t("ending.thanks")})
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
		# The logotype already sets the English name. In every other locale the mark is
		# still English, so the localised title has to be said once, under it.
		var lines := PackedStringArray()
		if Loc.current() != "en":
			lines.append(Loc.t("splash.title"))
		lines.append(Loc.t("splash.hint"))
		splash_title.text = "\n".join(lines)
		if title_screen:
			# Ink, not bone: the form sheet under this label became real paper on
			# 2026-09-22 and light type on paper is invisible.
			title_screen.style_label(splash_title, 18, Color(0.90, 0.92, 0.86))
		else:
			UiFont.apply_label(splash_title)
	if splash_enter:
		_btn_text(splash_enter, Loc.t("splash.start"))
		if title_screen:
			title_screen.style_button(splash_enter, true)
	if pause_lab:
		pause_lab.text = Loc.t("pause.title")
	if pause_resume:
		_btn_text(pause_resume, Loc.t("pause.resume"))
	if pause_restart:
		_btn_text(pause_restart, Loc.t("pause.restart"))
	if lang_caption:
		lang_caption.text = Loc.t("lang.caption")
		if title_screen:
			# 18 at paper value, not 16 at 0.66 green. At 390 px — the phone check in
			# TITLE_SCREENS.md — the dimmer, smaller version of this field label was the
			# one piece of live interface on the screen you could not read, because it
			# lands on the lit end of the corridor rather than on the deep part of the
			# sheet. It is a form field caption; a form prints its captions.
			title_screen.style_label(lang_caption, 18, Color(0.82, 0.88, 0.82), true)
		else:
			UiFont.apply_label(lang_caption)
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		_btn_text(b, str(Loc.NATIVE[code]))
		if title_screen:
			title_screen.style_button(b)
		else:
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
