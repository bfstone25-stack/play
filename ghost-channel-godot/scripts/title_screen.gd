## The title screen — TITLE_SCREENS.md, all six items, in one composition.
##
## The key visual is the whole screen (the operator's back at the console, the five
## call-lights, the night outside), the logotype sits in the quiet left third the plate was
## composed to leave, and the menu sits *under the logotype inside that column* rather than
## being centred over the picture — the eye lands on the lit console on the right, travels
## left along the desk, and arrives at the name and then at the first thing to press.
##
## The five call-lights along the bottom of the logotype column are the game in miniature
## and the reason this screen is not just a picture with a name on it: five lamps, one of
## which is lying. They idle in the call-sign colours; every few seconds one of them
## transmits — its lamp brightens, the station's console spill turns that colour, the CRT
## noise lifts, and if there is a voice bake in the build you hear that person's line. One
## time in five it is the mimic, and then the lamp lights in the *wrong* colour for a beat.
## Nothing is at stake on the title screen; it is a demonstration of the verb.
extends Control

var main: Control

var _logo: Control
var _lamps := []                  # [Control] in GCRules.AGENTS order
var _menu: VBoxContainer
var _tag: Label
var _mark: Label
var _note: Label
var _t := 0.0
var _next := 2.6
var _live := -1
var _live_left := 0.0
var _lie := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_process(true)


func _build() -> void:
	# the column: the plate's empty left third, 84 px in from the edge
	var col := VBoxContainer.new()
	col.position = Vector2(84, 118)
	col.custom_minimum_size = Vector2(470, 0)
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	_logo = preload("res://scripts/logotype.gd").new()
	_logo.base_size = 84
	_logo.rule_text = "BLAZECORE PLAY"
	_logo.custom_minimum_size = Vector2(470, 250)
	col.add_child(_logo)

	_tag = StudioTheme.serif_label("", 19, Palette.TEXT)
	_tag.custom_minimum_size = Vector2(440, 0)
	_tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_tag)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	col.add_child(gap)

	# the five call-lights, in a row, as a strip of the console
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 10)
	col.add_child(strip)
	for a in GCRules.AGENTS:
		var lamp := preload("res://scripts/call_light.gd").new()
		lamp.agent_id = a.id
		lamp.custom_minimum_size = Vector2(84, 30)
		strip.add_child(lamp)
		_lamps.append(lamp)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 22)
	col.add_child(gap2)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 9)
	col.add_child(_menu)
	_menu_button("start", "Primary", func(): _start())
	_menu_button("how", "Amber", func(): _go("how"))
	_menu_button("credits", "Ghost", func(): _go("credits"))

	_note = StudioTheme.mono_label("", 12, Palette.MUTED)
	_note.custom_minimum_size = Vector2(440, 0)
	col.add_child(_note)

	# the studio mark and the rating, bottom-left, small and consistent
	_mark = StudioTheme.mono_label("", 12, Palette.DIM)
	_mark.position = Vector2(84, 668)
	add_child(_mark)

	relocalise()


func _menu_button(key: String, variation: String, cb: Callable) -> void:
	var b := Button.new()
	b.name = key
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(320, 0)
	# a designed block, not a stretched column: the three buttons are one width and the
	# container does not get to decide it
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		Sfx.click()
		cb.call())
	b.mouse_entered.connect(func(): Sfx.squelch_open())
	_menu.add_child(b)


func relocalise() -> void:
	_tag.text = Game.t("tag")
	_mark.text = "BLAZECORE PLAY   ·   " + Game.t("mark")
	for key in ["start", "how", "credits"]:
		var b: Button = _menu.get_node(key)
		b.text = "  " + Game.t(key)
	var have: Array = Voice.have()
	# Say plainly what is in this build. A player who hears no voices should be told the
	# bake is missing, not left assuming their sound is broken.
	if have.is_empty():
		_note.text = Game.t("noVoiceNote")
	else:
		_note.text = ""


func on_show() -> void:
	_logo.settle()
	Sfx.title_sting()
	_t = 0.0
	_next = 2.8


func _go(name: String) -> void:
	main.show_screen(name)


func _start() -> void:
	if Game.returning_player():
		main.show_screen("ops")
	else:
		main.screens["play"].start_op(0)


func on_key(k: InputEventKey) -> bool:
	if k.keycode == KEY_ENTER or k.keycode == KEY_SPACE or k.keycode == KEY_KP_ENTER:
		Sfx.click()
		_start()
		return true
	return false


# ---- the demonstration ------------------------------------------------------------------
func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _live >= 0:
		_live_left -= delta
		if _live_left <= 0.0:
			_lamps[_live].live = false
			_lamps[_live].lying = false
			_live = -1
			Sfx.squelch_close()
			main.crt.set_floor(0.11)
	elif _t >= _next:
		_transmit()
		_next = _t + _rng.randf_range(4.0, 7.0)


func _transmit() -> void:
	_live = _rng.randi_range(0, _lamps.size() - 1)
	_lie = _rng.randf() < 0.2
	var a: Dictionary = GCRules.AGENTS[_live]
	_lamps[_live].live = true
	_lamps[_live].lying = _lie
	_live_left = 3.2
	Sfx.squelch_open()
	Sfx.callsign(float(a.freq))
	main.station.channel_live(Palette.callsign(a.id))
	main.crt.set_floor(0.17)
	if _lie:
		main.crt.tear(false)
	# the person's own line, if the bake is in the build
	Voice.say(Game.lang, a.id, "quote")
