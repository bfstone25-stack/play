extends Control

@onready var prompt: Label = $Prompt
@onready var note: Label = $Note
@onready var objective: Label = $Objective
@onready var vignette: ColorRect = $Vignette

var note_t := 0.0
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
signal dialogue_done(choice: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	note.visible = false
	prompt.text = ""
	UiFont.apply_label(prompt)
	UiFont.apply_label(note)
	UiFont.apply_label(objective)
	_clock()
	_title()
	_grain()
	_dialogue()
	_splash()
	_palette()

func _clock() -> void:
	clock = Label.new()
	clock.name = "Clock"
	clock.position = Vector2(28, 52)
	clock.add_theme_font_size_override("font_size", 14)
	clock.add_theme_color_override("font_color", Color(1.0, 0.7, 0.28, 0.9))
	clock.text = "02:17"
	UiFont.apply_label(clock)
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
	UiFont.apply_display(title)
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
	UiFont.apply_label(title_sub)
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
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load("res://splash.png")
	if tex:
		bg.texture = tex
	else:
		bg.modulate = Color(0.12, 0.09, 0.07, 1)
	splash.add_child(bg)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(dim)
	var lab := Label.new()
	lab.set_anchors_preset(Control.PRESET_CENTER)
	lab.offset_left = -420.0
	lab.offset_right = 420.0
	lab.offset_top = -70.0
	lab.offset_bottom = 110.0
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 26)
	lab.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1))
	lab.text = "The Other Side\nClick to wake up. It is 02:17.\n18+  ·  Flat 404\nWASD  mouse look  E interact  F light  Esc"
	UiFont.apply_label(lab)
	splash.add_child(lab)
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
	UiFont.apply_label(dlg_text)
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
	UiFont.apply_label(dlg_choice)
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
		var s := ""
		for i in dlg_choices.size():
			s += "[%d]  %s     " % [i + 1, dlg_choices[i]]
		dlg_choice.text = s
	else:
		dlg_choice.text = "click · E · Space  to continue"

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

func hide_title() -> void:
	if title_card:
		title_card.visible = false

func set_fear(v: float) -> void:
	fear = v

func show_note(t: String) -> void:
	note.text = t
	if note_card:
		note_card.visible = true
	note_t = 9.0

func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0 and note_card:
			note_card.visible = false
	vignette.color.a = 0.04 + fear * 0.28
	if grain and grain.material is ShaderMaterial:
		(grain.material as ShaderMaterial).set_shader_parameter("grain", 0.05 + fear * 0.1)
