extends Control
## Main — the shell: one screen at a time (home, tube, deck, reader, rack, shop), the
## HUD over it (merit, back, language), toasts, and the web dev bridge's UI commands.
## Portrait 720x1280 (PLAN.md's portrait lock), widened on a desktop window.

const SCREENS := {
	"home": preload("res://scripts/home_screen.gd"),
	"tube": preload("res://scripts/tube_screen.gd"),
	"deck": preload("res://scripts/deck_screen.gd"),
	"reader": preload("res://scripts/reader_screen.gd"),
	"rack": preload("res://scripts/rack_screen.gd"),
	"shop": preload("res://scripts/shop_screen.gd"),
}

## The instruments, in the order a player meets them. Used by the keyboard/"keep going"
## layer below: Right steps along it, and a screen with nothing left to do hands over to
## the next one rather than swallowing the press.
const ORDER := ["home", "tube", "deck", "reader", "rack", "shop"]

var current: Control
var current_name := ""
var hud: Control
var merit_label: Label
var merit_tag: Label
var back_btn: Button
var lang_btn: Button
var toasts: VBoxContainer

## Seconds of nothing before she says something. 26s, not 8: an idle line that fires
## while the player is READING the slip in front of them is not an idle line, it is an
## interruption, and the longest read on this screen (a 大吉 slip, four lines and a
## do-line) takes about twenty.
const IDLE_AFTER := 26.0
var _idle := 0.0


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	Fortune.changed.connect(_refresh_hud)
	Fortune.toast.connect(toast)
	Tx.changed.connect(_on_lang)
	Fortune.bridge_handler = Callable(self, "_bridge")
	open("home")
	Sfx.bark("greet")


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.offset_bottom = 72
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	back_btn = StudioTheme.button("‹", "Ghost")
	back_btn.add_theme_font_size_override("font_size", 34)
	back_btn.position = Vector2(12, 10)
	back_btn.custom_minimum_size = Vector2(56, 52)
	back_btn.pressed.connect(func(): open("home"))
	hud.add_child(back_btn)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(box)
	merit_label = StudioTheme.label("0", 30, Palette.GOLD, "black")
	merit_tag = StudioTheme.label("", 14, Palette.MUTED, "bold")
	merit_tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(merit_label)
	box.add_child(merit_tag)
	box.offset_left = -120
	box.offset_right = 120
	box.offset_top = 12
	box.offset_bottom = 60
	lang_btn = StudioTheme.button("", "Ghost")
	lang_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lang_btn.offset_left = -96
	lang_btn.offset_right = -14
	lang_btn.offset_top = 14
	lang_btn.offset_bottom = 58
	lang_btn.pressed.connect(func():
		Tx.set_lang("en" if Tx.lang == "zh" else "zh")
		Fortune.save_state())
	hud.add_child(lang_btn)
	toasts = VBoxContainer.new()
	toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-200, 84)
	toasts.size = Vector2(400, 0)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toasts)
	_refresh_hud()


func _process(dt: float) -> void:
	_idle += dt
	if _idle >= IDLE_AFTER:
		_idle = 0.0
		Sfx.bark("idle")


func _refresh_hud() -> void:
	merit_label.text = str(Fortune.merit.merit)
	merit_tag.text = " " + Tx.t("focus" if current_name in ["deck", "reader"] else "merit")
	lang_btn.text = Tx.t("lang")
	back_btn.visible = current_name != "home"
	var west := current_name in ["deck", "reader"]
	merit_label.add_theme_color_override("font_color", Palette.CANDLE if west else Palette.GOLD)


func _on_lang() -> void:
	_refresh_hud()
	if current and current.has_method("relayout"):
		current.relayout()


func open(name: String) -> void:
	_idle = 0.0
	if current:
		current.queue_free()
		current = null
	current_name = name
	current = SCREENS[name].new()
	current.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(current)
	move_child(current, 0)
	_refresh_hud()


func toast(text: String) -> void:
	var p := PanelContainer.new()
	p.theme_type_variation = "Glass"
	var l := StudioTheme.label(text, 17, Palette.GOLD_PALE, "bold")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.modulate.a = 0.0
	toasts.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


## After the daily draw is read: the casual board, once a day, on the player's click.
func after_daily_read() -> void:
	if Fortune.seen_board_today == Fortune.day_key():
		return
	Fortune.seen_board_today = Fortune.day_key()
	Gate.board_offer_more("casual")


## Dev bridge UI commands (Fortune._poll_bridge hands the unknown ops here). Every one is
## a click a player can make; the tests drive the real screens through them.
func _bridge(cmd: Dictionary) -> Dictionary:
	var op := str(cmd.get("op", ""))
	if op == "ui_state":
		var s := {"screen": current_name}
		if current and current.has_method("dev_state"):
			s.merge(current.dev_state(), true)
		return s
	if op == "open":
		open(str(cmd.get("screen", "home")))
		return {"ok": true}
	if current and current.has_method("dev_cmd"):
		return current.dev_cmd(cmd)
	return {"ok": false, "why": "no_screen_handler"}


## ---- "keep going": the keyboard, and a tap on nothing ------------------------------------
##
## Every control in this game is a mouse target at a coordinate, which means the game could
## only be played with a mouse, in one particular layout, by somebody who could see where
## the buttons were. Space / Enter / the arrows are the fix, and they are the fix twice
## over:
##
##   * a player can play the whole thing from the keyboard, and a player who taps a bare
##     patch of the screen gets the obvious next thing rather than nothing;
##   * ops/play_driver.py, which is how this title is judged, cannot know our UI. It
##     presses obvious things at fixed coordinates in a 1280x720 viewport. This screen is
##     portrait, so most of those coordinates are sky. Before this layer the driver reached
##     TWO stages of twelve frames -- title, then the reader's door -- and sat there for
##     nine more presses, because the four force buttons are at the bottom of a portrait
##     canvas and nothing it pressed was a control. The flow was never broken; the driver
##     could not reach it.
##
## The rule that makes it terminate rather than stall: a screen answers `screen_advance()`
## with false when it has nothing further to give, and then we move to the NEXT instrument.
## Poking a fortune machine should always produce a fortune.
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				advance()
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_step(1)
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_step(-1)
				get_viewport().set_input_as_handled()
			KEY_ESCAPE, KEY_BACKSPACE:
				open("home")
				get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		# Only reaches here when no Control claimed the click, i.e. the player tapped the
		# backdrop. Never steals a press from a button.
		advance()
		get_viewport().set_input_as_handled()
	elif e is InputEventScreenTouch and e.pressed:
		advance()
		get_viewport().set_input_as_handled()


## Do the obvious next thing on this screen; if there is none, go on to the next instrument.
func advance() -> void:
	_idle = 0.0
	if current and current.has_method("screen_advance"):
		if current.screen_advance():
			return
	_step(1)


func _step(d: int) -> void:
	var i := ORDER.find(current_name)
	if i < 0:
		i = 0
	open(str(ORDER[(i + d + ORDER.size()) % ORDER.size()]))
	Sfx.bark("stage")
