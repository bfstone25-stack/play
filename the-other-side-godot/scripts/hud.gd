extends Control

@onready var prompt: Label = $Prompt
@onready var note: Label = $Note
@onready var objective: Label = $Objective
@onready var vignette: ColorRect = $Vignette

var note_t := 0.0
var _note_pending := false
var fear := 0.0
var clock: Label
var title: Label
var title_card: Control
var title_sub: Label
var title_rule: ColorRect
var note_card: Control
var grain: ColorRect
var splash: Control
var dlg: Control
var dlg_text: Label
var dlg_choice: Label
var dlg_lines: Array = []
var dlg_i := 0
var dlg_choices: Array = []
var dlg_result := -1
var dlg_open := false

## The splash's moving parts. All four were used by _splash()/_splash_type() and none of
## them was ever declared: the file did not parse, so the HUD autoload never instantiated
## and the title screen drew nothing at all. A GDScript parse error inside a script the
## scene instances is a console line and not a crash (memory: read the console), which is
## how a title screen can be "finished" in the source and blank in the build.
var splash_art: TextureRect          ## the key visual, overscanned so its edge never shows
var splash_name_slot: Control        ## holds the wordmark; repainted when the language changes
var start_button: Button       ## Shape.DOOR — the thing you cross the hall through
var _mirror_used := false
var lang_button: Button        ## Shape.DOOR, narrow, bottom-right
var choice_row: Control              ## the two doors the last dialogue line offers
var choice_doors: Array = []
var _art_t := 0.0                    ## drives the title's drift; STANDARD.md rule 6
signal dialogue_done(choice: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	note.visible = false
	prompt.text = ""
	# Cjk.apply_label, not UiFont.apply_label: these three carry translated prose, and the
	# Latin face draws a Chinese glyph as a blank box with no error (scripts/cjk.gd).
	Cjk.apply_label(prompt)
	Cjk.apply_label(note)
	Cjk.apply_label(objective)
	_clock()
	_title()
	_grain()
	_dialogue()
	_splash()
	_palette()
	# The language control repaints the screen it is standing on, rather than asking the
	# player to restart. Only the splash needs it: everything else is drawn on demand.
	I18n.changed.connect(_on_lang_changed)

func _clock() -> void:
	clock = Label.new()
	clock.name = "Clock"
	clock.position = Vector2(28, 52)
	clock.add_theme_font_size_override("font_size", 14)
	clock.add_theme_color_override("font_color", Color(1.0, 0.7, 0.28, 0.9))
	clock.text = "02:17"
	Cjk.apply_label(clock)
	add_child(clock)

## The title / chapter card, as a door plate.
##
## The first capture had this as one centred two-line Label at the vertical middle of the
## screen, where it landed on top of the mirror's billboard prompt and its own second line
## — three pieces of text inside eighty pixels. Two things fix it and both are needed: the
## card moves to a band at the TOP that nothing else in the HUD occupies, and it becomes
## an object instead of floating letters. The object is the brass door plate off 401 and
## 402, which is the one piece of furniture this game is actually about.
func _title() -> void:
	title_card = Control.new()
	title_card.name = "TitleCard"
	title_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_card.offset_left = -330.0
	title_card.offset_right = 330.0
	title_card.offset_top = 92.0
	title_card.offset_bottom = 196.0
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.visible = false
	add_child(title_card)

	var plate := ColorRect.new()
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.color = Color(0.072, 0.036, 0.056, 0.86)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.add_child(plate)
	# Two edges, not a border: a hot rule along the top and a dull brass one along the
	# bottom, so the plate has a lit side and reads as metal rather than as a rectangle.
	var top_edge := ColorRect.new()
	top_edge.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_edge.offset_bottom = 3.0
	top_edge.color = Color(1.0, 0.24, 0.54, 1)
	top_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.add_child(top_edge)
	var bot_edge := ColorRect.new()
	bot_edge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_edge.offset_top = -1.0
	bot_edge.color = Color(1.0, 0.7, 0.28, 0.5)
	bot_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.add_child(bot_edge)

	title = Label.new()
	title.name = "Title"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16.0
	title.offset_bottom = 62.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1))
	Cjk.apply_label(title) if I18n.needs_cjk() else UiFont.apply_display(title)
	title_card.add_child(title)

	title_rule = ColorRect.new()
	title_rule.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_rule.offset_left = -46.0
	title_rule.offset_right = 46.0
	title_rule.offset_top = 66.0
	title_rule.offset_bottom = 67.0
	title_rule.color = Color(1.0, 0.7, 0.28, 0.65)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.add_child(title_rule)

	title_sub = Label.new()
	title_sub.name = "TitleSub"
	title_sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_sub.offset_top = 74.0
	title_sub.offset_bottom = 98.0
	title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_sub.add_theme_font_size_override("font_size", 16)
	title_sub.add_theme_color_override("font_color", Color(0.72, 0.54, 0.63, 1))
	Cjk.apply_label(title_sub)
	title_card.add_child(title_sub)

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

func _splash() -> void:
	splash = Control.new()
	splash.name = "Splash"
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	# The key visual. assets/title/keyvisual.webp is the rendered plate installed by
	# ops/install_title_keyvisual.py; splash.png is the old in-engine grab and stays only
	# as the fallback, because a title that draws NOTHING when a file is missing is how
	# Flutter shipped with no key visual at all and nobody noticed.
	splash_art = TextureRect.new()
	splash_art.name = "Art"
	splash_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = null
	for path in ["res://assets/title/keyvisual.webp", "res://splash.png"]:
		if ResourceLoader.exists(path):
			tex = load(path)
			break
	if tex:
		splash_art.texture = tex
	else:
		splash_art.modulate = Color(0.12, 0.09, 0.07, 1)
	splash.add_child(splash_art)
	_art_layout()
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(dim)
	# The splash HAS a key visual (splash.png) and always did; what failed was the type.
	# Four lines — the game's name, an instruction, the rating, and the keyboard map — were
	# set in one Label, one size, one weight, centred. Blaze's word for that look is 学术:
	# it reads as a slide. ops/check_title_has_art.py passes this screen and is right to,
	# because the picture is real; no pixel statistic can see that the TYPE is a default.
	#
	# So the fix here is entirely typographic, and the hierarchy is the whole of it: the
	# name is the only thing set large, the line under it is the hook, the action is the
	# only thing that looks clickable, and the rating and controls are reference at the
	# foot. Nothing gains a fill, a border or a corner radius — studio rule 2.
	_splash_type(splash)
	splash.gui_input.connect(_on_splash_input)
	add_child(splash)

## UI_DIRECTION.md: dark ground, hot accents. Text warm off-white, never grey.
##
## The note also gets moved out of the centre of the screen and onto a surface. It used to
## be centred white prose floating over the room at exactly the height of the mirror, so it
## sat on the plate AND under the title card; and unbacked body text over a lit bathroom
## fails the TITLE_SCREENS.md legibility check at 390 px whatever colour it is.
func _palette() -> void:
	prompt.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1))
	objective.add_theme_color_override("font_color", Color(1.0, 0.7, 0.28, 0.95))
	vignette.color = Color(0.07, 0.03, 0.06, 0.04)

	note_card = Control.new()
	note_card.name = "NoteCard"
	note_card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	note_card.offset_left = -400.0
	note_card.offset_right = 400.0
	note_card.offset_top = -258.0
	note_card.offset_bottom = -104.0
	note_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_card.visible = false
	add_child(note_card)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.072, 0.036, 0.056, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_card.add_child(bg)
	# One hot bar down the left, the way a margin rule marks a passage. The panel is the
	# only lit-looking thing in the lower half, so the eye goes to the words.
	var bar := ColorRect.new()
	bar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar.offset_right = 3.0
	bar.color = Color(1.0, 0.24, 0.54, 1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_card.add_child(bar)

	# Reparent the scene's Note label into the panel, left-aligned: centred prose of three
	# uneven lines reads as a credits roll, not as something the character is noticing.
	note.reparent(note_card)
	note.set_anchors_preset(Control.PRESET_FULL_RECT)
	note.offset_left = 26.0
	note.offset_right = -26.0
	note.offset_top = 18.0
	note.offset_bottom = -18.0
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 19)
	note.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1))
	# The label itself is always shown from here on; note_card carries the visibility, so
	# the _ready() hide above must be undone or show_note() would raise an empty panel.
	note.visible = true

func _dialogue() -> void:
	dlg = Control.new()
	dlg.name = "Dialogue"
	dlg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.visible = false
	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -210.0
	panel.offset_bottom = 0.0
	panel.color = Color(0.2, 0.115, 0.16, 0.95)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(panel)
	var edge := ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	edge.offset_top = -212.0
	edge.offset_bottom = -209.0
	edge.color = Color(1.0, 0.24, 0.54, 1)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(edge)
	dlg_text = Label.new()
	dlg_text.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg_text.offset_left = 80.0
	dlg_text.offset_right = -80.0
	dlg_text.offset_top = -190.0
	dlg_text.offset_bottom = -90.0
	dlg_text.add_theme_font_size_override("font_size", 22)
	dlg_text.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1))
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Cjk.apply_label(dlg_text)
	dlg.add_child(dlg_text)
	dlg_choice = Label.new()
	dlg_choice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg_choice.offset_left = 80.0
	dlg_choice.offset_right = -80.0
	dlg_choice.offset_top = -84.0
	dlg_choice.offset_bottom = -16.0
	dlg_choice.add_theme_font_size_override("font_size", 19)
	dlg_choice.add_theme_color_override("font_color", Color(1.0, 0.7, 0.28, 1))
	dlg_choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_choice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Cjk.apply_label(dlg_choice)
	dlg.add_child(dlg_choice)
	add_child(dlg)

## Lines are shown one at a time on click / E / Space; the last line carries the choice,
## answered with 1 or 2. Returns the index chosen. The 9-second show_note() label cannot
## carry an exchange; this can.
func show_dialogue(lines: Array, choices: Array) -> int:
	dlg_lines = lines
	dlg_choices = choices
	dlg_i = 0
	dlg_result = -1
	dlg_open = true
	dlg.visible = true
	if note_card:
		note_card.visible = false
	_dlg_draw()
	var r: int = await dialogue_done
	dlg.visible = false
	dlg_open = false
	return r

func _dlg_draw() -> void:
	dlg_text.text = str(dlg_lines[dlg_i])
	var last := dlg_i >= dlg_lines.size() - 1
	if last and dlg_choices.size() > 0:
		# The choice is the one moment this game asks the player for a decision, and it
		# used to be two bracketed numbers in a Label. Same rule as the splash: the thing
		# you press is a door. The keys 1 and 2 still work (dialogue_input) because the
		# pointer is captured for the rest of the game and a player may not think to
		# release it.
		dlg_choice.text = ""
		_choice_doors()
	else:
		_clear_choice_doors()
		dlg_choice.text = I18n.t("dlg_more")

func dialogue_input(event: InputEvent) -> bool:
	if not dlg_open:
		return false
	var last := dlg_i >= dlg_lines.size() - 1
	if last and dlg_choices.size() > 0:
		if event is InputEventKey and event.pressed and not event.echo:
			var k: int = event.keycode
			var idx := -1
			if k == KEY_1 or k == KEY_KP_1:
				idx = 0
			elif k == KEY_2 or k == KEY_KP_2:
				idx = 1
			if idx >= 0 and idx < dlg_choices.size():
				dialogue_done.emit(idx)
		return true
	var advance: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_E or event.keycode == KEY_SPACE))
	if advance:
		if last:
			dialogue_done.emit(0)
		else:
			dlg_i += 1
			_dlg_draw()
	return true

func _on_splash_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_splash()
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("capture_mouse"):
			p.capture_mouse()

func hide_splash() -> void:
	if _note_pending and note_card:
		note_card.visible = true
		note_t = 9.0
		_note_pending = false
	if splash:
		splash.visible = false
		splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_prompt(t: String) -> void:
	prompt.text = t

func set_objective(t: String) -> void:
	objective.text = t

func set_clock(t: String) -> void:
	if clock:
		clock.text = t

## Callers pass "Name\nsubtitle"; the two lines are set in two different faces and sizes
## on the plate rather than stacked in one Label, which is what let them collide.
func show_title(t: String, sub := "") -> void:
	var head := t
	if sub == "" and t.contains("\n"):
		var parts := t.split("\n", true, 1)
		head = parts[0]
		sub = parts[1]
	title.text = head
	title_sub.text = sub
	title_sub.visible = sub != ""
	title_rule.visible = sub != ""
	title_card.visible = true

## The splash's typography. Godot's Label has no letter-spacing, so the tracking on the
## name IS the separation between one-glyph Labels in an HBox — that is the difference
## between a title and a caption and it cannot be had from font_size.
func _splash_type(root: Control) -> void:
	var ink := Color(0.95, 0.93, 0.92)
	var dim := Color(0.66, 0.60, 0.62)
	var bruise := Color(0.72, 0.17, 0.30)

	# THE LAYOUT, 2026-09-21. This column used to be one centred block, and the capture
	# shows exactly what that costs: THE OTHER SIDE is printed across the neighbour's face
	# and the tagline is white 16 px type lying on her white shirt, unreadable at any size.
	# Centring the type over a plate whose subject is also centred puts the two things the
	# screen is for on top of each other.
	#
	# So the screen is banded the way the Nutaku shelf bands a cover: the NAME at the top,
	# the ACTION at the foot, and the middle third left alone for the person the player is
	# crossing the hall to meet. Nothing gains a fill or a border to achieve it (studio
	# rule 2) -- the legibility comes from the outline already on every line, and from the
	# type no longer sitting on the brightest part of the picture.
	# 2026-09-23, adult title pass: the name and the door live in the LEFT half now and
	# Iris owns the right, not a band across the middle -- a centred name still crossed
	# her head once she was framed big (ops/market/ADULT_SHELF_TITLES.md: the figure takes
	# ~85% of the frame; nothing of the UI touches her face).
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	col.offset_left = 0.0
	col.offset_right = -600.0
	col.offset_top = 46.0
	col.offset_bottom = 210.0
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)

	# The foot: the door, then the reference lines under it.
	var foot := VBoxContainer.new()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_left = 0.0
	foot.offset_right = -600.0
	foot.offset_top = -196.0
	foot.offset_bottom = -34.0
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 12)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(foot)

	# The name is set in the player's language. Letter-spacing on a CJK line is a
	# different typographic gesture from tracking Latin caps, so the tracked-glyph row is
	# only built for the Latin wordmark; the CJK name is one Label, larger, with its own
	# spacing constant.
	splash_name_slot = Control.new()
	splash_name_slot.custom_minimum_size = Vector2(0, 64)
	splash_name_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(splash_name_slot)
	_draw_splash_name(ink)

	var rule := ColorRect.new()
	rule.color = bruise
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.custom_minimum_size.x = 200.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)

	# 18, not 16, and warm off-white rather than the grey: this line is the hook and it was
	# set smaller and dimmer than the keyboard map underneath it.
	col.add_child(_splash_line(I18n.t("tagline"), 18, Color(0.90, 0.84, 0.84)))
	# STANDARD.md rule 4: the control the player presses is an object from the fiction.
	# This game is one sentence -- across the hall is the life you did not claim, and the
	# only thing in the way is a door you never opened -- so the button IS that door, and
	# hovering it opens the crack (shared/godot/shaped_button.gd, Shape.DOOR). The warm
	# light in the gap is the only warm colour on the screen, which is what makes the eye
	# land on the one thing the player is meant to do.
	# 2026-09-23, adult title pass: the door is now the door's own brass lever handle -- the
	# object you would put your hand on -- as an ObjectButton, not a drawn door panel
	# (ops/STANDARD.md, "Buttons are objects from the game"). GPU render, rembg.
	var start := ObjectButton.new()
	start.text = I18n.t("start")
	start.object_texture = load("res://assets/title/btn_doorhandle.png")
	start.object_size = 76.0
	start.gap = 12.0
	start.motion = ObjectButton.Motion.TURN
	start.label_color = Color(1.0, 0.94, 0.90)
	start.accent_color = Color(1.0, 0.70, 0.28)
	start.ink = Color(0.06, 0.02, 0.05, 1.0)
	start.outline_px = 5
	start.shadow_px = 0
	start.custom_minimum_size = Vector2(360, 84)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 24)
	Cjk.apply_control(start)
	start.pressed.connect(func() -> void:
		hide_splash()
		var pl := get_tree().get_first_node_in_group("player")
		if pl and pl.has_method("capture_mouse"):
			pl.capture_mouse())
	foot.add_child(start)
	start_button = start

	foot.add_child(_splash_line(I18n.t("footer"), 13, dim))
	foot.add_child(_splash_line(I18n.t("controls"), 12, Color(0.60, 0.55, 0.57)))

	# The language control. It is a door too -- a narrow one, off in the corner, because
	# the player who needs it is looking for it and the player who does not should not
	# have a second big object competing with the start door.
	var lang := ObjectButton.new()
	lang.object_texture = load("res://assets/title/btn_handmirror.png")
	lang.object_size = 44.0
	lang.motion = ObjectButton.Motion.TURN
	lang.label_color = Color(0.92, 0.86, 0.84)
	lang.accent_color = Color(1.0, 0.70, 0.28)
	lang.ink = Color(0.06, 0.02, 0.05, 1.0)
	lang.outline_px = 4
	lang.shadow_px = 0
	lang.text = I18n.ENDONYM[I18n.lang]
	lang.custom_minimum_size = Vector2(190, 52)
	lang.add_theme_font_size_override("font_size", 15)
	lang.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lang.offset_left = -214.0
	lang.offset_top = -76.0
	lang.offset_right = -24.0
	lang.offset_bottom = -24.0
	Cjk.apply_control(lang)
	lang.pressed.connect(func() -> void: I18n.cycle())
	root.add_child(lang)
	lang_button = lang


## STANDARD.md rule 6: the title MOVES, and it never shows the plate's edge.
##
## The plate is laid out larger than the viewport by ART_OVERSCAN and drifts inside that
## margin, so there is always picture beyond every edge of the screen. 1.16 is the bare 16:9
## diagonal ratio quoted in the rule -- the ratio at which a rotating plate just covers the
## frame and nothing more. This uses 1.22 because the motion here is a TRANSLATION as well
## as a rotation, and a drift of 60 px each way needs its own margin on top of the rotation's.
## The budget, at 1280x720: 140 px of margin per side, of which the drift spends 60 and the
## rotation about 4. Widen the drift and you must widen this constant with it.
## 1.26, and the reason it is not 1.22 is ART_BIAS_Y below: the bias spends vertical
## margin that the drift also needs, so the budget had to grow to hold both.
const ART_OVERSCAN := 1.26
const ART_DRIFT := 60.0      ## px, peak, horizontal
const ART_DRIFT_Y := 25.0    ## px, peak, vertical -- smaller, because the bias spends the rest
const ART_SPIN := 0.006      ## rad, peak

## Push the plate DOWN behind the type.
##
## The key visual is a cowboy shot: her head is near the top of the 1920x1080 plate, and an
## overscan crop takes its 13% off every edge -- so the centred crop lifts her face into the
## top band, and the capture showed THE OTHER SIDE printed across her eye. Banding the type
## (see _splash_type) fixed the tagline and the button but could not fix this, because the
## collision is the picture moving up, not the type sitting low.
##
## So the visible window is biased toward the top of the plate, which moves her face down
## the screen and out from under the wordmark. The budget, at 1280x720 and 1.26: 93 px of
## vertical margin, of which the bias spends 50 and the drift 25, leaving 18 spare. Raise
## either and raise ART_OVERSCAN with it or the plate's edge comes on screen.
const ART_BIAS_Y := 50.0

func _art_layout() -> void:
	if splash_art == null:
		return
	var vp := get_viewport_rect().size
	var m := vp * (ART_OVERSCAN - 1.0) * 0.5
	splash_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash_art.offset_left = -m.x
	splash_art.offset_top = -m.y + ART_BIAS_Y
	splash_art.offset_right = m.x
	splash_art.offset_bottom = m.y + ART_BIAS_Y
	splash_art.pivot_offset = vp * ART_OVERSCAN * 0.5


## The drift itself. Two sine terms at incommensurate periods (23 s and 31 s) so the frame
## never visibly returns to where it started -- a loop the eye can find reads as a GIF.
func _art_drift(delta: float) -> void:
	if splash_art == null or splash == null or not splash.visible:
		return
	_art_t += delta
	var vp := get_viewport_rect().size
	var m := vp * (ART_OVERSCAN - 1.0) * 0.5
	var dx := sin(_art_t * TAU / 23.0) * ART_DRIFT
	var dy := sin(_art_t * TAU / 31.0) * ART_DRIFT_Y + ART_BIAS_Y
	splash_art.offset_left = -m.x + dx
	splash_art.offset_right = m.x + dx
	splash_art.offset_top = -m.y + dy
	splash_art.offset_bottom = m.y + dy
	splash_art.rotation = sin(_art_t * TAU / 37.0) * ART_SPIN


## The wordmark, set in the player's language.
##
## Letter-spacing a line of Latin caps and letter-spacing a CJK line are not the same
## gesture: tracking is what makes THE OTHER SIDE read as a mark rather than as a word, and
## the same treatment applied to 向こう側 just looks broken. So the Latin name is built as a
## tracked row of single glyphs (_tracked) and the CJK name is one Label, larger, in the
## CJK face -- and in that case the Latin mark is kept underneath, small, because DLsite's
## shelf carries the Latin title alongside the local one and the player should be able to
## match the two.
func _draw_splash_name(ink: Color) -> void:
	if splash_name_slot == null:
		return
	for c in splash_name_slot.get_children():
		splash_name_slot.remove_child(c)
		c.queue_free()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_name_slot.add_child(box)
	if I18n.lang == "en":
		splash_name_slot.custom_minimum_size = Vector2(0, 66)
		box.add_child(_tracked(I18n.t("title"), 44, 7, ink))
		return
	splash_name_slot.custom_minimum_size = Vector2(0, 92)
	var n := _splash_line(I18n.t("title"), 52, ink, true)
	# UiFont draws a CJK glyph as a blank box and reports nothing (memory:
	# verification-that-lies), so the CJK name is re-faced after _splash_line.
	Cjk.apply_label(n)
	box.add_child(n)
	box.add_child(_splash_line(str(I18n.T["en"]["title"]), 14, Color(0.60, 0.54, 0.56), true))


## Repaint every piece of the splash that carries a string.
func _on_lang_changed(_l: String) -> void:
	_draw_splash_name(Color(0.95, 0.93, 0.92))
	if start_button:
		start_button.text = I18n.t("start")
		Cjk.apply_control(start_button)
		start_button.queue_redraw()
	if lang_button:
		lang_button.text = I18n.ENDONYM[I18n.lang]
		Cjk.apply_control(lang_button)
		lang_button.queue_redraw()
	if splash:
		for c in splash.get_children():
			if c is VBoxContainer:
				_relabel_static(c)


## The tagline / footer / controls lines, which are plain Labels built inline by
## _splash_type. They are found by the key they were built from rather than re-running the
## whole builder, which would drop the start door and its connection with it.
func _relabel_static(col: VBoxContainer) -> void:
	# The splash is two columns now (head and foot), and this is called for each: the head
	# holds the tagline, the foot holds the footer and the keyboard map, in that order.
	var keys := ["tagline", "footer", "controls"]
	for c in col.get_children():
		if not (c is Label):
			continue
		var l := c as Label
		for k in keys:
			# Match on the string it is currently showing, in any language, rather than on
			# position: a column that gains a line later must not silently re-label the
			# wrong one.
			if l.text == I18n.t(k) or _was(l, k):
				l.text = I18n.t(k)
				Cjk.apply_label(l)
				break


## Did this label come from key `k` in some language? Checked against every finished
## language, because the repaint runs AFTER I18n.lang has already moved on.
func _was(l: Label, k: String) -> bool:
	for lang in I18n.LANGS:
		if l.text == str(I18n.T[lang].get(k, "")):
			return true
	return false


## STANDARD.md rule 4, applied to the one decision the game asks for.
##
## The choice used to be two bracketed numbers in a Label -- "[1] ...  [2] ..." -- which is
## the same failure as a rectangular button, only smaller. In this game a choice is a door
## you either go through or do not, so the choice IS two doors, and the warm crack of light
## under the one you hover is the whole of the hover state.
##
## The number stays on the face because game.gd releases the pointer for this beat
## (dialogue_input still answers to 1 and 2) and a player who has been holding WASD for ten
## minutes reaches for the keyboard first.
func _choice_doors() -> void:
	_clear_choice_doors()
	var row := HBoxContainer.new()
	row.name = "ChoiceDoors"
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 80.0
	row.offset_right = -80.0
	row.offset_top = -96.0
	row.offset_bottom = -18.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	dlg.add_child(row)
	choice_row = row
	for i in dlg_choices.size():
		var b := ShapedButton.new()
		b.shape = ShapedButton.Shape.DOOR
		# Kept and refused are not the same door: the first is the warm one.
		b.tint = Color(0.34, 0.17, 0.26) if i == 0 else Color(0.19, 0.15, 0.24)
		b.ink = Color(1.0, 0.94, 0.90)
		b.label = "%d   %s" % [i + 1, str(dlg_choices[i])]
		b.custom_minimum_size = Vector2(340, 66)
		b.add_theme_font_size_override("font_size", 16)
		Cjk.apply_control(b)
		# .bind(), not a lambda that closes over the loop variable: a rebound capture
		# compiles clean and runs wrong (ops/godot_lambda_capture.md).
		b.pressed.connect(_on_choice_door.bind(i))
		row.add_child(b)
		choice_doors.append(b)


func _on_choice_door(idx: int) -> void:
	if idx >= 0 and idx < dlg_choices.size():
		dialogue_done.emit(idx)


func _clear_choice_doors() -> void:
	choice_doors.clear()
	if choice_row and is_instance_valid(choice_row):
		choice_row.queue_free()
	choice_row = null


func _tracked(text: String, size: int, track: int, col: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", track)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in text.length():
		if text[i] == " ":
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(size * 0.40, 0)
			row.add_child(gap)
			continue
		# 2026-09-23: the O of OTHER is her hand mirror -- in this fork the mirror is what
		# shows her at 02:17 (the fork's rule, README). An object standing in for a letter,
		# picked by what the letter is shaped like and what the game is about.
		if text[i] == "O" and not _mirror_used and ResourceLoader.exists("res://assets/title/btn_handmirror.png"):
			_mirror_used = true
			var m := TextureRect.new()
			m.texture = load("res://assets/title/btn_handmirror.png")
			m.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			m.custom_minimum_size = Vector2(size * 1.25, size * 1.35)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(m)
			continue
		row.add_child(_splash_line(text[i], size, col, true))
	_mirror_used = false
	return row


func _splash_line(text: String, size: int, col: Color, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	# An outline, not a panel: the type has to survive a lit bathroom behind it without
	# putting a box between the player and the picture.
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		UiFont.apply_display(l)
	else:
		UiFont.apply_label(l)
	return l


func hide_title() -> void:
	if title_card:
		title_card.visible = false

func set_fear(v: float) -> void:
	fear = v

func show_note(t: String) -> void:
	note.text = t
	note_t = 9.0
	# Not while the title is up. The game's first line of prose was drawing across the
	# splash's footer, which is how the keyboard map ended up half behind a black box in
	# the capture. It is held and shown the moment the player wakes up, so nothing is lost
	# -- and its nine-second timer starts then too, rather than expiring behind the title.
	if splash and splash.visible:
		_note_pending = true
		return
	if note_card:
		note_card.visible = true

func _process(delta: float) -> void:
	_art_drift(delta)
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0 and note_card:
			note_card.visible = false
	vignette.color.a = 0.04 + fear * 0.28
	if grain and grain.material is ShaderMaterial:
		(grain.material as ShaderMaterial).set_shader_parameter("grain", 0.05 + fear * 0.1)
