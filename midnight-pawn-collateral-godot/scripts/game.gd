extends Control

## LIEN — the runner and the UI (adult fork of Midnight Pawn & Crypt).
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
const TitleScreenScript = preload("res://scripts/title_screen.gd")
const TitleAudioScript = preload("res://scripts/title_audio.gd")
## ops/STANDARD.md rule 4: the control the player presses is an object from the
## fiction. Every button in this game is a pawn TAG -- the ticket tied to a pledge,
## which is literally what the shop hands you. shared/godot/shaped_button.gd reserved
## Shape.TAG for Midnight Pawn and nothing here had ever used it.
const ShapedButtonScript = preload("res://scripts/shaped_button.gd")


## One constructor so all four button sites agree. `compact` because the canvas is the
## base game's 640x360 and the library's 220x56 floor is sized for a 1280x720 title.
static func _tag(txt: String, w: float, h: float, col: Color = GOLD) -> ShapedButton:
	var b: ShapedButton = ShapedButtonScript.new()
	b.compact = true
	b.shape = ShapedButton.Shape.TAG
	b.tint = col
	b.ink = Color("#17121c")
	b.label = txt
	b.custom_minimum_size = Vector2(w, h)
	return b

const BG := Color("#100d18")
const PANEL := Color("#201928")
const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const MUTED := Color("#9f94ac")
## The gate copy sits over a lit key visual, not over the in-game slab: the secondary
## lines get their own, lighter grey so they read on a phone. See title_screen.gd::_plaque.
const TITLE_MUTED := Color("#c3b8d2")
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
## The gate's affirmative, so a keypress can press the button rather than bypass it.
var splash_enter: Button
var title_screen: TitleScreen
var title_audio: TitleAudio


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	start_night()
	# The web build is the one that gets opened from a link by someone who has not read a
	# store page, and it had no age wall of any kind. A download has already been bought
	# from an 18+ listing -- but the title screen is not only an age wall, it is the game's
	# face, and on 2026-09-20 that reasoning had cost this fork its face everywhere except
	# the web: a desktop window opened straight onto the intro paragraph over flat black,
	# which is the "office software" screen Blaze rejected by name. Every build now shows
	# it. The headless tests still do not -- they have no display and dismiss_splash is
	# still the only way through.
	#
	# 2026-09-21: this guard was `OS.has_feature("headless")`, which is FALSE under
	# --headless on Godot 4.7 -- the display driver is named "headless" but no feature tag
	# of that name is ever set. So from the 2026-09-20 change that gave every build the
	# title screen, the splash opened in the test harness too; `advance()` returns early
	# while `splash_open`, so all five routes in tests/playthrough.gd spun 4000 no-op
	# iterations and reported "route did not terminate". The tests had been red ever
	# since and the README still quoted the old green output.
	#
	# It is the same fault the matrix was showing from the outside: four tiles, all of
	# them this screen. One unverified feature string closed the front door on the
	# players AND on the tests that would have said so. Ask the display server its name,
	# which is a thing it actually knows. tests/headless.gd holds this down.
	if DisplayServer.get_name() != "headless":
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
	brand.text = Loc.s("COLLATERAL")
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
	var ledger_button := _tag("Ledger", 74, 24)
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
	var b := _tag(text, 0, 30, color)
	b.add_theme_font_override("font", PixelBodyFont)
	b.add_theme_font_size_override("font_size", 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on_press)
	actions.add_child(b)
	# The first action is focused, so Enter/Space works the choice menu without a mouse.
	# It is also what lets ops/play_driver.py past a choice at all: the driver presses
	# keys and clicks a fixed grid, and a choice row that only answers to a precise click
	# is a wall. See the gate note in _show_splash.
	if actions.get_child_count() == 1:
		# Deferred, because a Control cannot take focus in the same frame it is added --
		# and guarded, because _clear_actions() removes these from the tree the moment the
		# next beat lands. Ungurded this printed one "!is_inside_tree()" per line of prose
		# in the playthrough test: harmless, and exactly the kind of noise that hides a
		# real error in a log nobody can read.
		_focus_soon.call_deferred(b)
	return b


## Focus a control if it is still in the tree by the time the deferred call lands.
func _focus_soon(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree():
		c.grab_focus()


func _refresh_header() -> void:
	if run == null:
		return
	header.text = Loc.s("Till %d   Shelf %d   Estate %d   Readings %d/5") % [
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
		title_label.text = Loc.s("")
		detail.clear()
		detail.append_text(Loc.s("[color=#c8bfd0]%s[/color]") % text)
	else:
		var voice: Dictionary = VOICES.get(who, {"name": who, "color": CREAM})
		title_label.text = str(voice["name"])
		title_label.add_theme_color_override("font_color", voice["color"])
		detail.clear()
		detail.append_text(Loc.s("[color=#f1dfb0]%s[/color]") % text)
	_refresh_header()
	_clear_actions()
	_add_action("Continue", advance, GOLD)
	footer.text = Loc.s("Space or click to go on.")


func _show_menu(beat: Dictionary) -> void:
	title_label.text = Loc.s("")
	title_label.add_theme_color_override("font_color", GOLD)
	detail.clear()
	detail.append_text(Loc.s("[color=#e8b84a]%s[/color]") % str(beat["prompt"]))
	_refresh_header()
	_clear_actions()
	current_options = beat["options"]
	awaiting_choice = true
	for i in current_options.size():
		var option: Dictionary = current_options[i]
		var idx := i
		_add_action(str(option["text"]), func() -> void: choose(idx))
	footer.text = Loc.s("The ticket is yours to write.")


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
	var opened := await Gate.require("act%d" % chapter, Loc.s("Appraisal %d") % chapter)
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
		title_label.text = Loc.s("The free part ends here")
		detail.clear()
		var lead := "Two appraisals down."
		if run.readings_taken.has("ring"):
			lead = "You put your palm on a ring a man had just asked you not to touch."
		elif not run.readings_refused.is_empty():
			lead = "You priced them on brass and gold and let them go home."
		detail.append_text(Loc.s("[color=#c8b8b0]%s There are three more objects in the book tonight and one of them has your name on the ticket.[/color]\n\n") % lead)
		detail.append_text(Loc.s("[color=#7f7a8c]Till: %d · readings taken: %d · against the estate: %d[/color]") % [
			run.till, run.readings_taken.size(), C.DEBT])
		footer.text = Loc.s("LIEN — the whole night, nothing censored.")
		_add_action("Open the Reading Ledger", open_ledger, GOLD)
		_add_action("Price them differently", restart, MUTED)
	else:
		title_label.text = Loc.s(str(C.ENDING_NAMES.get(id, id)))
		detail.clear()
		detail.append_text("[color=#c8bfd0]Two prices on everything. You have just found out which one you were.[/color]")
		footer.text = Loc.s("Readings taken: %d · refused: %d · net %d against %d") % [
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
	head.text = Loc.s("THE READING LEDGER")
	head.add_theme_font_override("font", PixelDisplayFont)
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", GOLD)
	ledger_box.add_child(head)
	var sub := Label.new()
	sub.text = Loc.s("Every object that crossed the counter, and whether you looked.")
	sub.add_theme_color_override("font_color", MUTED)
	sub.add_theme_font_size_override("font_size", 12)
	ledger_box.add_child(sub)

	for row in plates.ledger_rows(run):
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 12)
		if bool(row["earned"]):
			line.text = Loc.s("[x]  %s — %s") % [Loc.s(str(row["title"])), Loc.s(str(row["why"]))]
			line.add_theme_color_override("font_color", GREEN if bool(row["unlocked"]) else RED)
			if not bool(row["unlocked"]):
				line.text += Loc.s("  (censored in this build)")
		else:
			line.text = Loc.s("[ ]  %s — not taken. This one stays dark.") % Loc.s(str(row["title"]))
			line.add_theme_color_override("font_color", Color("#5c5468"))
		ledger_box.add_child(line)

	var tally := Label.new()
	tally.text = Loc.s("Taken: %s · refused: %s · till: %d") % [
		", ".join(run.readings_taken) if not run.readings_taken.is_empty() else "none",
		", ".join(run.readings_refused) if not run.readings_refused.is_empty() else "none",
		run.till]
	tally.add_theme_color_override("font_color", MUTED)
	tally.add_theme_font_size_override("font_size", 12)
	ledger_box.add_child(tally)

	var close := _tag("Close the book", 170, 30)
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


## The title screen. It is also the 18+ card — a door, with the one sentence on it the
## content rules require the game to say in its own voice: everyone depicted is an adult.
##
## What stood here was a flat ColorRect with a centred column of Labels on it, which is
## exactly the "a room and a name" look this pass exists to kill. The composition now
## lives in scripts/title_screen.gd (the key visual, the lamps, the dust, the brass mark);
## this function only places the copy and the two buttons INTO that composition and lends
## them its type family. The gate is unchanged: `dismiss_splash` is still the only way
## through and the web build is still the only thing that shows it.
func _show_splash() -> void:
	splash_open = true
	splash = ColorRect.new()
	splash.color = Color(0, 0, 0, 0)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(splash)

	title_screen = TitleScreenScript.new()
	title_screen.name = "TitleScreen"
	splash.add_child(title_screen)

	title_audio = TitleAudioScript.new()
	title_audio.name = "TitleAudio"
	# Same reason as the title screen: the tree is paused behind this card, and a
	# generator that is not processed pushes no frames.
	title_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	splash.add_child(title_audio)

	# The copy sits low-left under the mark, ranged left in the composition rather than
	# stacked down the middle of the screen.
	var box := VBoxContainer.new()
	box.position = Vector2(24, 226)
	box.custom_minimum_size = Vector2(500, 0)
	box.add_theme_constant_override("separation", 3)
	splash.add_child(box)
	var lines := [
		["An adult fork of Midnight Pawn & Crypt.", CREAM, 12],
		["18+ only. Everyone depicted is an adult and is written as one.", CREAM, 12],
		["Sexual content, grief, and a shop that prices both.", TITLE_MUTED, 12],
		["Made with AI in the loop and a person steering it.", TITLE_MUTED, 12],
	]
	for spec in lines:
		var l := Label.new()
		l.text = Loc.s(str(spec[0]))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_screen.style_label(l, int(spec[2]), spec[1])
		box.add_child(l)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	# 2026-09-21, found by shooting the game rather than by reading it. The matrix
	# (ops/play_matrix.py) reported four stages and all four were THIS screen: the title
	# with the consent card on it, differing only by the lamp flicker. Nothing in the
	# build was broken -- the gate simply could not be got through.
	#
	# Two faults, and the second is the real one:
	#
	#  1. The affirmative was a 220x26 control at the left edge of a 640x360 canvas, i.e.
	#     a 440x52 target in the bottom-left twelfth of a 1280x720 window. A player finds
	#     it; a grid of clicks does not, and neither does a thumb.
	#  2. `_unhandled_input` returns early while `splash_open`, so NO key did anything.
	#     There was exactly one way through the front door of this game and it was a
	#     mouse click on a small rectangle. Off a trackpad that is a bad gate; on a
	#     keyboard it is a locked one.
	#
	# So: the affirmative is a full-width TAG, it takes focus on open, and Enter/Space
	# presses it. The keypress is still an affirmative act on a control that says what it
	# is -- the consent is not weakened, it is reachable. `Leave` stays small and stays
	# beside it, because the two must not be symmetrical.
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	# 2026-09-23: the affirmative is the pledge itself -- the violet ring she holds to her
	# monocle in the plate -- as an ObjectButton, not a tag (ops/STANDARD.md, "Buttons are
	# objects from the game"). Focus-on-open and Enter/Space still press it: it extends
	# Button. GPU render, rembg, quantised to the palette, 30 px.
	var enter := ObjectButton.new()
	enter.text = Loc.s("I am 18 or older — open the shop")
	enter.object_texture = load("res://assets/title/btn_ring.png")
	enter.object_size = 30.0
	enter.gap = 6.0
	enter.motion = ObjectButton.Motion.TURN
	enter.label_color = GOLD
	enter.accent_color = CREAM
	enter.ink = Color("#0b0810")
	enter.outline_px = 0
	enter.shadow_px = 1
	enter.custom_minimum_size = Vector2(300, 34)
	enter.focus_mode = Control.FOCUS_ALL
	enter.add_theme_font_override("font", PixelBodyFont)
	enter.add_theme_font_size_override("font_size", 12)
	enter.pressed.connect(dismiss_splash)
	row.add_child(enter)
	var leave := _tag(Loc.s("Leave"), 86, 34, TITLE_MUTED)
	leave.add_theme_font_override("font", PixelBodyFont)
	leave.add_theme_font_size_override("font_size", 12)
	leave.pressed.connect(func() -> void: JavaScriptBridge.eval("location.href='https://free.blazecore.dev/'"))
	row.add_child(leave)
	splash_enter = enter
	_focus_soon.call_deferred(enter)

	# The rating and the studio line, small and fixed, bottom corners.
	var rating := Label.new()
	rating.text = Loc.s("18+")
	rating.position = Vector2(12, 332)
	title_screen.style_label(rating, 12, GOLD)
	splash.add_child(rating)
	var studio := Label.new()
	studio.text = Loc.s("FLAT 404  ·  blazeCore Play")
	studio.position = Vector2(404, 334)
	title_screen.style_label(studio, 12, TITLE_MUTED)
	splash.add_child(studio)

	# 2026-09-23: the language row. Outlined words on the art, no box (ops/STANDARD.md). A
	# language is offered only because tests/locale_cover.gd proves it is fully translated.
	# Choosing one rebuilds the splash in place so every line re-reads through Loc.
	var lx := 470.0
	for code in Loc.ALLOWED:
		var lb := ObjectButton.new()
		lb.text = str(Loc.NATIVE[code])
		lb.object_size = 0.0
		lb.gap = 0.0
		lb.label_color = CREAM
		lb.accent_color = GOLD
		lb.selected = code == Loc.current()
		lb.outline_px = 0
		lb.shadow_px = 1
		lb.add_theme_font_override("font", PixelBodyFont)
		lb.add_theme_font_size_override("font_size", 12)
		lb.position = Vector2(lx, 8)
		lb.size = Vector2(52, 16)
		var c := str(code)
		lb.pressed.connect(func() -> void:
			Loc.set_code(c)
			if is_instance_valid(splash):
				splash.queue_free()
			_show_splash.call_deferred())
		splash.add_child(lb)
		lx += 56.0

	title_screen.play_in()


## The title screen's sound hook. Synthesised, not an asset — see scripts/title_audio.gd.
func title_sound(kind: String) -> void:
	if title_audio == null:
		return
	if kind == "sting":
		title_audio.sting()
	else:
		title_audio.ui(kind)


func dismiss_splash() -> void:
	if not splash_open:
		return
	splash_open = false
	splash.queue_free()   # takes the title screen and its generator with it
	splash = null
	splash_enter = null
	title_screen = null
	title_audio = null


func _unhandled_input(event: InputEvent) -> void:
	# The gate is the one overlay that answers keys, and it answers them by pressing its
	# own affirmative button rather than by calling dismiss_splash() behind the button's
	# back -- so the press is visible, it makes the UI sound, and there is still exactly
	# one code path through the gate. See _show_splash.
	if splash_open:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			if splash_enter != null:
				splash_enter.grab_focus()
			dismiss_splash()
			get_viewport().set_input_as_handled()
		return
	if ledger_open or finished or awaiting_choice:
		return
	if event.is_action_pressed("interact"):
		advance()
