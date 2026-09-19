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
## The two painted rooms (assets/plates/bg_*.png). They were dropped into the project as
## new files with no .import sidecar and nothing loading them, which meant a headless
## export would not even have carried them. They are used as a darkened ground behind the
## whole 640x360 frame — the room the pixel stage is a window into — and never at a weight
## where they compete with the pixel art in front of them.
const GROUNDS := {
	"shop": preload("res://assets/plates/bg_shop.png"),
	"title": preload("res://assets/plates/bg_shop.png"),
	"dawn": preload("res://assets/plates/bg_shop.png"),
	"market": preload("res://assets/plates/bg_market.png"),
}
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
var ground: TextureRect
var splash: ColorRect
var splash_open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	start_night()
	# The web build is the one that gets opened from a link by someone who has not read a
	# store page, and it had no age wall of any kind. A download has already been bought
	# from an 18+ listing, and the headless tests are not the web, so neither sees this.
	if OS.has_feature("web"):
		_show_splash()


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

	ground = TextureRect.new()
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Was 22% of a painted room behind a 300x240 pixel stamp — the dark of the room, with a
	# lamp in it. The pixel room now fills the whole canvas and is the room, so this sits
	# under it at a quarter of that and only shows through where the stage does not reach.
	ground.modulate = Color(0.10, 0.09, 0.12, 1.0)
	ground.texture = GROUNDS["shop"]
	add_child(ground)

	# The stage is the canvas. Full bleed at 640x360, 1:1 with the logical pixel grid, and
	# the UI below is drawn on top of it in translucent ink panels rather than beside it in
	# a column. This is the single change that stops the game looking like a form with a
	# picture stapled to it; everything else in the re-do is art feeding into it.
	stage = PixelStageScript.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	plates = PlateLayerScript.new()
	add_child(plates)

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

	var top_panel := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.055, 0.045, 0.082, 0.62)
	top_style.set_content_margin_all(2)
	top_panel.add_theme_stylebox_override("panel", top_style)
	column.add_child(top_panel)
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 22
	top_panel.add_child(top)
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

	# The room gets the top of the frame to itself; the words take the bottom. The sky is
	# the expanding child, so the text box sits on the floor of the frame at its own height
	# whatever else the column is holding.
	var sky := Control.new()
	sky.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(sky)

	# The text box. A translucent ink slab pinned to the lower half of the frame, which is
	# where an adventure game puts its words — over the room, not next to it. 0.86 alpha is
	# the lowest that kept 12px bitmap type legible over the lamp; it was checked against
	# the brightest frame in the game (dawn) rather than against the shop.
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.y = 126
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.055, 0.045, 0.082, 0.96)
	box_style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.28)
	box_style.set_border_width_all(1)
	box_style.set_content_margin_all(7)
	box.add_theme_stylebox_override("panel", box_style)
	column.add_child(box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	box.add_child(info)
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
	# Three lines of 12px type. Without a floor the label collapsed to nothing and the
	# question sat under the buttons, which is the sort of thing a screenshot catches and
	# a test never does.
	detail.custom_minimum_size.y = 40
	info.add_child(detail)

	# Inside the slab, not under it. Loose buttons on the bare room left three separate
	# strips of chrome eating the bottom third of the frame; one slab with the verbs in it
	# gives the room back about sixty rows, which is the difference between seeing the
	# counter the game is played across and not.
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	actions.custom_minimum_size.y = 28
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_child(actions)
	footer = Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", MUTED)
	footer.add_theme_font_size_override("font_size", 12)
	info.add_child(footer)

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
				if GROUNDS.has(str(beat["bg"])):
					ground.texture = GROUNDS[str(beat["bg"])]
			"customer":
				stage.set_customer(str(beat["id"]))
			"plate":
				await _show_plate(str(beat["item"]))
			"settle":
				# The refund rule, decided after the fetch rather than before it.
				var extra: Array = Story.settle_reading(run, str(beat["item"]), str(beat["plate"]))
				for i in extra.size():
					beats.insert(beat_index + i, extra[i])
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
	if Collateral.is_gated(id) and not Unlock.ready_for(id):
		await _reveal(id)
	var delivered := plates.show_plate(id)
	footer.text = "" if delivered else "This reading is censored in this build."


## The web track's reveal, and the half of the dual-track model that was never wired.
##
## unlock.gd has been in this project since the port with a start() and a redeem() that
## nothing called, so a browser player who cleared a gate got the censored plate every
## time and the fork's whole paid proposition was unreachable. Verified against the live
## gateway: /unlock/start issues a ticket and names a wait, a fetch inside that wait is
## refused with 425, a fetch after it returns the webp, and the same ticket a second time
## is 403.
##
## Ordered so the server's clock starts with the gate and not with the redeem — the wait
## is the length of the sponsor clip, so the player spends it watching something rather
## than looking at a spinner. Off the web, start() returns false before it makes any
## request: a desktop download asks the network for nothing.
func _reveal(id: String) -> bool:
	if not await plates.unlock.start(id):
		return false
	var spec: Dictionary = Collateral.PLATES.get(id, {})
	if not await Gate.require(id, str(spec.get("title", "A reading")), "cg"):
		return false
	return await plates.unlock.redeem(id)


## The chapter cut. On a desktop download Gate.require() returns true without touching the
## network; on the web it hands the decision to gate.js on the page. The demo build stops
## here instead, which is the only place in the game that a price is mentioned.
func _gate(chapter: int) -> bool:
	if DEMO and chapter == 2:
		_finish("DEMO")
		return false
	var opened := await Gate.require("act%d" % chapter, "Appraisal %d" % chapter)
	if opened:
		# Offered after the unlock, never instead of it: the player has just earned the
		# next appraisal, so this asks whether they would rather spend ten minutes on
		# something lighter first. Gate.board_offer_break() says nothing on the 1st and
		# 3rd crossing — see shared/godot/gate.gd.
		Gate.board_offer_break()
	return opened


func advance() -> void:
	if finished or ledger_open or splash_open:
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
	if id != "DEMO":
		# End of a run, and only a real ending: the demo stop is a price prompt and
		# stacking a catalogue on top of it would bury the one thing it has to say.
		Gate.board_offer_more()
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


## The 18+ card. Not a legal document — a door, with the one sentence on it that the
## content rules require the game to say in its own voice: everyone depicted is an adult.
func _show_splash() -> void:
	splash_open = true
	splash = ColorRect.new()
	splash.color = Color(0.04, 0.03, 0.07, 1.0)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(splash)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	splash.add_child(box)
	var lines := [
		["MIDNIGHT PAWN: COLLATERAL", GOLD, 16],
		["An adult fork of Midnight Pawn & Crypt.", CREAM, 12],
		["18+ only. Everyone depicted is an adult and is written as one.", CREAM, 12],
		["Sexual content, grief, and a shop that prices both.", MUTED, 12],
		["The artwork is AI-assisted, directed and culled by hand. The writing is human.", MUTED, 12],
	]
	for spec in lines:
		var l := Label.new()
		l.text = str(spec[0])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", spec[1])
		l.add_theme_font_size_override("font_size", int(spec[2]))
		if int(spec[2]) == 16:
			l.add_theme_font_override("font", PixelDisplayFont)
		box.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var enter := Button.new()
	enter.text = "I am 18 or older — open the shop"
	enter.custom_minimum_size = Vector2(220, 26)
	enter.pressed.connect(dismiss_splash)
	row.add_child(enter)
	var leave := Button.new()
	leave.text = "Leave"
	leave.custom_minimum_size = Vector2(60, 26)
	leave.pressed.connect(func() -> void: JavaScriptBridge.eval("location.href='https://free.blazecore.dev/'"))
	row.add_child(leave)


func dismiss_splash() -> void:
	if not splash_open:
		return
	splash_open = false
	splash.queue_free()
	splash = null


func _unhandled_input(event: InputEvent) -> void:
	if ledger_open or finished or awaiting_choice or splash_open:
		return
	if event.is_action_pressed("interact"):
		advance()
