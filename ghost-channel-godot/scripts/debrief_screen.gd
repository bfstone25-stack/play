## DEBRIEF — how the op ended, and who the ghost actually was.
##
## The reveal is the whole screen: the five faces again, the one that was lying lit in the
## alarm colour and every other one dropped back, so the player sees the answer as a face
## rather than as a sentence. The stats sit under it as instrument readouts.
##
## The end of a run is where this catalogue offers the rest of itself
## (shared/godot/gate.gd, ops/board_inject.py). This is a mainstream title, so it asks for
## the **casual** board explicitly — board.js refuses to draw the adult one on an AdSense
## host anyway, but a mainstream title that asks for "adult" gets silence, which is the
## failure mode play/confession-room actually shipped. Offered once, a beat after the
## debrief lands, and the debrief is still behind it.
extends Control

var main: Control

var _state: Dictionary = {}
var _op_index := 0
var _offered := false        # the board is offered once per run, not once per redraw
var _title: Label
var _lead: Label
var _stats: HBoxContainer
var _faces: HBoxContainer
var _again: Button
var _menu: Button
var _reveal: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glass := PanelContainer.new()
	glass.theme_type_variation = "Glass"
	glass.position = Vector2(140, 74)
	glass.custom_minimum_size = Vector2(1000, 572)
	add_child(glass)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	glass.add_child(col)

	_title = StudioTheme.display_label("", 46, Palette.ACCENT)
	col.add_child(_title)

	_lead = StudioTheme.serif_label("", 18, Palette.TEXT)
	_lead.custom_minimum_size = Vector2(960, 54)
	_lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lead)

	_reveal = StudioTheme.serif_label("", 12, Palette.MUTED, true)
	col.add_child(_reveal)

	_faces = HBoxContainer.new()
	_faces.add_theme_constant_override("separation", 12)
	col.add_child(_faces)
	for i in range(GCRules.AGENTS.size()):
		var f := preload("res://scripts/portrait.gd").new()
		f.custom_minimum_size = Vector2(178, 226)
		_faces.add_child(f)

	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 30)
	col.add_child(_stats)

	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 12)
	col.add_child(acts)
	_again = Button.new()
	_again.theme_type_variation = "Primary"
	_again.custom_minimum_size = Vector2(280, 46)
	_again.pressed.connect(func():
		Sfx.click()
		main.screens["play"].start_op(_op_index))
	acts.add_child(_again)
	_menu = Button.new()
	_menu.theme_type_variation = "Ghost"
	_menu.custom_minimum_size = Vector2(220, 46)
	_menu.pressed.connect(func():
		Sfx.click()
		main.show_screen("ops"))
	acts.add_child(_menu)


func show_result(state: Dictionary, op_index: int) -> void:
	if state != _state:
		_offered = false
	_state = state
	_op_index = op_index
	var e: Dictionary = state.end
	_title.text = str(e.title)
	_title.add_theme_color_override("font_color", Palette.ACCENT if state.win else Palette.HEAT)
	_lead.text = str(e.lead)
	var ghost := GCRules.agent_by_id(state, str(state.mimicId))
	_reveal.text = "%s · %s" % [str(ghost.name), GCRules.who(state, ghost)]

	for i in range(_faces.get_child_count()):
		var f: Control = _faces.get_child(i)
		var a: Dictionary = state.agents[i]
		f.setup(str(a.id), GCRules.who(state, a))
		var is_ghost: bool = str(a.id) == str(state.mimicId)
		f.alive = bool(a.alive)
		f.suspect = is_ghost
		f.live = false
		f.modulate = Color(1, 1, 1, 1.0) if is_ghost else Color(0.55, 0.6, 0.66, 1.0)

	for c in _stats.get_children():
		c.queue_free()
	for pair in e.stats:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.add_child(StudioTheme.serif_label(str(pair[0]), 11, Palette.MUTED, true))
		box.add_child(StudioTheme.mono_label(str(pair[1]), 26,
			Palette.GOLD if str(pair[0]) == Game.t("statScore") else Palette.SUCCESS))
		_stats.add_child(box)

	_again.text = Game.t("again")
	_menu.text = Game.t("menu")
	# relocalise() redraws through here too, and a language switch made from the title
	# screen must not drag the player back to a debrief they have left.
	if Game.current != "debrief":
		main.show_screen("debrief")
	if not _offered:
		_offered = true
		_offer_board()


## A beat after the debrief lands, once, and never in a way that hides it.
func _offer_board() -> void:
	await get_tree().create_timer(0.9).timeout
	if Game.current == "debrief":
		Gate.board_offer_more("casual")


## Switching language on the debrief has to redraw the *result*, not just the two buttons:
## the verdict, the sentence about who the ghost was, and the six stat captions are all
## strings. GCRules.relocalise() rebuilds them (rebuild_end), and this draws them again.
func relocalise() -> void:
	if _state.is_empty():
		return
	GCRules.relocalise(_state, Game.lang)
	show_result(_state, _op_index)


func on_key(k: InputEventKey) -> bool:
	if k.keycode == KEY_ENTER or k.keycode == KEY_SPACE:
		Sfx.click()
		main.screens["play"].start_op(_op_index)
		return true
	if k.keycode == KEY_ESCAPE:
		main.show_screen("ops")
		return true
	return false
