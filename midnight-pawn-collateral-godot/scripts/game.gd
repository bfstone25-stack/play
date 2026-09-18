extends Control

## Midnight Pawn: Collateral — the runner and the UI.
##
## The layout is the base game's, rebuilt rather than reinvented: a 300x240 pixel scene
## window on the left, an info column on the right, a row of action buttons along the
## bottom, the same palette constants and the same two bitmap fonts. What changed is what
## the buttons do — the base game's appraise/price/call-customer verbs become the fork's
## read/price verbs, and the crypt's movement and combat are gone.
##
## The story runner is small on purpose. Story.run_label() hands back the beats a Ren'Py
## label emitted; this walks them, and the only beats that pause are the ones a player
## would have had to click through in Ren'Py: a line of text, a menu, the ledger.

const C := preload("res://scripts/collateral_core.gd")
const PixelStageScript = preload("res://scripts/pixel_stage.gd")
const PlateLayerScript = preload("res://scripts/plates.gd")
const PixelBodyFont = preload("res://assets/fonts/midnight_pixel_12.fnt")
const PixelDisplayFont = preload("res://assets/fonts/midnight_pixel_16.fnt")

const BG := Color("#100d18")
const PANEL := Color("#201928")
const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const MUTED := Color("#9f94ac")
const RED := Color("#d45b68")
const GREEN := Color("#7f9a7a")

## Speaker colours. Five clients, each seen once, each named — if these ever collapse into
## one woman at a counter the fork is Room 704 and is cancelled.
const VOICES := {
	"nara": {"name": "Nara", "color": Color("#e8b84a")},
	"tam": {"name": "Tamsin", "color": Color("#d98a6a")},
	"ivo": {"name": "Ivo", "color": Color("#8fa8c0")},
	"mara": {"name": "Mara", "color": Color("#b9a7c8")},
	"cal": {"name": "Calder", "color": Color("#7f9a7a")},
	"shop": {"name": "the shop", "color": Color("#6b6478")},
}

## The browser sample is the cold open plus the first two appraisals — Tamsin and Ivo —
## which is exactly enough to have used the reading fee twice and to have been asked, once,
## by a person, not to look. It cuts at the chapter-2 gate, one beat before the veil.
var DEMO := false

var run: C.Run
var stage: PixelStage
var plates: PlateLayer
var label := ""
var finished := false
var ending_id := ""
var beats: Array = []
var beat_index := 0
var visited: Dictionary = {}
var awaiting_choice := false
var current_options: Array = []

var header: Label
var title_label: Label
var detail: RichTextLabel
var actions: HBoxContainer
var footer: Label
var ledger_layer: ColorRect
var ledger_box: VBoxContainer
var ledger_open := false
var ledger_from_beat := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	start_night()


func start_night() -> void:
	run = C.Run.new()
	finished = false
	ending_id = ""
	visited = {}
	plates.hide_plate()
	_enter("start")


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 24
	column.add_child(top)
	var brand := Label.new()
	brand.text = "COLLATERAL"
	brand.add_theme_color_override("font_color", GOLD)
	brand.add_theme_font_override("font", PixelDisplayFont)
	brand.add_theme_font_size_override("font_size", 16)
	top.add_child(brand)
	header = Label.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_theme_color_override("font_color", CREAM)
	header.add_theme_font_size_override("font_size", 12)
	top.add_child(header)
	var ledger_button := Button.new()
	ledger_button.text = "Ledger"
	ledger_button.custom_minimum_size = Vector2(60, 22)
	ledger_button.pressed.connect(open_ledger)
	top.add_child(ledger_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	column.add_child(body)

	var stage_panel := PanelContainer.new()
	stage_panel.custom_minimum_size = Vector2(300, 240)
	stage_panel.clip_contents = true
	body.add_child(stage_panel)
	stage = PixelStageScript.new()
	stage.custom_minimum_size = Vector2(300, 240)
	stage_panel.add_child(stage)
	plates = PlateLayerScript.new()
	stage_panel.add_child(plates)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	body.add_child(info)
	title_label = Label.new()
	title_label.add_theme_color_override("font_color", GOLD)
	title_label.add_theme_font_override("font", PixelDisplayFont)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(title_label)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.scroll_active = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("normal_font_size", 12)
	info.add_child(detail)

	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	actions.custom_minimum_size.y = 30
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	footer = Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", MUTED)
	footer.add_theme_font_size_override("font_size", 12)
	column.add_child(footer)

	ledger_layer = ColorRect.new()
	ledger_layer.color = Color(0.04, 0.03, 0.07, 1.0)
	ledger_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ledger_layer.visible = false
	ledger_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ledger_layer)
	var ledger_margin := MarginContainer.new()
	ledger_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ledger_margin.add_theme_constant_override("margin_left", 16)
	ledger_margin.add_theme_constant_override("margin_right", 16)
	ledger_margin.add_theme_constant_override("margin_top", 10)
	ledger_margin.add_theme_constant_override("margin_bottom", 10)
	ledger_layer.add_child(ledger_margin)
	ledger_box = VBoxContainer.new()
	ledger_box.add_theme_constant_override("separation", 3)
	ledger_margin.add_child(ledger_box)

	var theme := Theme.new()
	theme.default_font = PixelBodyFont
	theme.default_font_size = 12
	self.theme = theme


func _clear_actions() -> void:
	for child in actions.get_children():
		child.queue_free()
		actions.remove_child(child)


func _add_action(text: String, on_press: Callable, color: Color = CREAM) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", color)
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size.y = 26
	b.pressed.connect(on_press)
	actions.add_child(b)
	return b


func _refresh_header() -> void:
	if run == null:
		return
	header.text = "Till %d   Shelf %d   Estate %d   Readings %d/5" % [
		run.till, run.stock_value(), C.DEBT, run.readings_taken.size()]


# ---------------------------------------------------------------------------
# The runner
# ---------------------------------------------------------------------------

func _enter(next_label: String) -> void:
	if visited.has(next_label):
		# Labels mutate run state as they generate, so entering one twice would charge a
		# fee twice. Ren'Py could not do this; neither can we.
		push_error("label entered twice: " + next_label)
		return
	visited[next_label] = true
	label = next_label
	beats = Story.run_label(next_label, run)
	beat_index = 0
	_step()


## Walk beats until one of them needs the player. Returns when it is their turn.
func _step() -> void:
	while beat_index < beats.size():
		var beat: Dictionary = beats[beat_index]
		beat_index += 1
		match str(beat["t"]):
			"scene":
				plates.hide_plate()
				stage.set_scene(str(beat["bg"]))
			"customer":
				stage.set_customer(str(beat["id"]))
			"plate":
				_show_plate(str(beat["item"]))
			"goto":
				_enter(str(beat["label"]))
				return
			"gate":
				if not await _gate(int(beat["chapter"])):
					return
			"ledger":
				ledger_from_beat = true
				open_ledger()
				return
			"menu":
				_show_menu(beat)
				return
			"end":
				_finish(str(beat["ending"]))
				return
			"nar":
				_say_line("", str(beat["text"]))
				return
			"say":
				_say_line(str(beat["who"]), str(beat["text"]))
				return
	push_error("label %s ran off the end" % label)


func _say_line(who: String, text: String) -> void:
	if who == "":
		title_label.text = ""
		detail.clear()
		detail.append_text("[color=#c8bfd0]%s[/color]" % text)
	else:
		var voice: Dictionary = VOICES.get(who, {"name": who, "color": CREAM})
		title_label.text = str(voice["name"])
		title_label.add_theme_color_override("font_color", voice["color"])
		detail.clear()
		detail.append_text("[color=#f1dfb0]%s[/color]" % text)
	_refresh_header()
	_clear_actions()
	_add_action("Continue", advance, GOLD)
	footer.text = "Space or click to go on."


func _show_menu(beat: Dictionary) -> void:
	title_label.text = ""
	title_label.add_theme_color_override("font_color", GOLD)
	detail.clear()
	detail.append_text("[color=#e8b84a]%s[/color]" % str(beat["prompt"]))
	_refresh_header()
	_clear_actions()
	current_options = beat["options"]
	awaiting_choice = true
	for i in current_options.size():
		var option: Dictionary = current_options[i]
		var idx := i
		_add_action(str(option["text"]), func() -> void: choose(idx))
	footer.text = "The ticket is yours to write."


func _show_plate(item: String) -> void:
	var id := Collateral.plate_for(item)
	var delivered := plates.show_plate(id)
	footer.text = "" if delivered else "This reading is censored in this build."


## The chapter cut. On a desktop download Gate.require() returns true without touching the
## network; on the web it hands the decision to gate.js on the page. The demo build stops
## here instead, which is the only place in the game that a price is mentioned.
func _gate(chapter: int) -> bool:
	if DEMO and chapter == 2:
		_finish("DEMO")
		return false
	return await Gate.require("act%d" % chapter, "Appraisal %d" % chapter)


func advance() -> void:
	if finished or ledger_open:
		return
	_step()


func choose(index: int) -> void:
	if not awaiting_choice or index < 0 or index >= current_options.size():
		return
	awaiting_choice = false
	var option: Dictionary = current_options[index]
	current_options = []
	_enter(str(option["to"]))


func _finish(id: String) -> void:
	finished = true
	ending_id = id
	awaiting_choice = false
	plates.hide_plate()
	_clear_actions()
	if id == "DEMO":
		title_label.text = "The free part ends here"
		detail.clear()
		var lead := "Two appraisals down."
		if run.readings_taken.has("ring"):
			lead = "You put your palm on a ring a man had just asked you not to touch."
		elif not run.readings_refused.is_empty():
			lead = "You priced them on brass and gold and let them go home."
		detail.append_text("[color=#c8b8b0]%s There are three more objects in the book tonight and one of them has your name on the ticket.[/color]\n\n" % lead)
		detail.append_text("[color=#7f7a8c]Till: %d · readings taken: %d · against the estate: %d[/color]" % [
			run.till, run.readings_taken.size(), C.DEBT])
		footer.text = "Midnight Pawn: Collateral — the whole night, nothing censored."
		_add_action("Open the Reading Ledger", open_ledger, GOLD)
		_add_action("Price them differently", restart, MUTED)
	else:
		title_label.text = str(C.ENDING_NAMES.get(id, id))
		detail.clear()
		detail.append_text("[color=#c8bfd0]Two prices on everything. You have just found out which one you were.[/color]")
		footer.text = "Readings taken: %d · refused: %d · net %d against %d" % [
			run.readings_taken.size(), run.readings_refused.size(), run.net_worth(), C.DEBT]
		_add_action("Open the Reading Ledger", open_ledger, GOLD)
		_add_action("Run the night again", restart, MUTED)
	_refresh_header()


func restart() -> void:
	close_ledger()
	start_night()


# ---------------------------------------------------------------------------
# The Reading Ledger — doubles as the CG gallery.
# ---------------------------------------------------------------------------

func open_ledger() -> void:
	ledger_open = true
	for child in ledger_box.get_children():
		child.queue_free()
		ledger_box.remove_child(child)

	var head := Label.new()
	head.text = "THE READING LEDGER"
	head.add_theme_font_override("font", PixelDisplayFont)
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", GOLD)
	ledger_box.add_child(head)
	var sub := Label.new()
	sub.text = "Every object that crossed the counter, and whether you looked."
	sub.add_theme_color_override("font_color", MUTED)
	sub.add_theme_font_size_override("font_size", 12)
	ledger_box.add_child(sub)

	for row in plates.ledger_rows(run):
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 12)
		if bool(row["earned"]):
			line.text = "[x]  %s — %s" % [row["title"], row["why"]]
			line.add_theme_color_override("font_color", GREEN if bool(row["unlocked"]) else RED)
			if not bool(row["unlocked"]):
				line.text += "  (censored in this build)"
		else:
			line.text = "[ ]  %s — not taken. This one stays dark." % row["title"]
			line.add_theme_color_override("font_color", Color("#5c5468"))
		ledger_box.add_child(line)

	var tally := Label.new()
	tally.text = "Taken: %s · refused: %s · till: %d" % [
		", ".join(run.readings_taken) if not run.readings_taken.is_empty() else "none",
		", ".join(run.readings_refused) if not run.readings_refused.is_empty() else "none",
		run.till]
	tally.add_theme_color_override("font_color", MUTED)
	tally.add_theme_font_size_override("font_size", 12)
	ledger_box.add_child(tally)

	var close := Button.new()
	close.text = "Close the book"
	close.custom_minimum_size = Vector2(160, 26)
	close.pressed.connect(close_ledger)
	ledger_box.add_child(close)
	ledger_layer.visible = true


func close_ledger() -> void:
	if not ledger_open:
		return
	ledger_open = false
	ledger_layer.visible = false
	# The ledger beat inside act_collateral pauses the label; closing it resumes. Opening
	# the book from the header button must not advance anything.
	if ledger_from_beat:
		ledger_from_beat = false
		if not finished:
			_step()


func _unhandled_input(event: InputEvent) -> void:
	if ledger_open or finished or awaiting_choice:
		return
	if event.is_action_pressed("interact"):
		advance()
