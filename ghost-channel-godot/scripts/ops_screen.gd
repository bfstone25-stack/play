## SELECT OPERATION — the three ops as console cards.
##
## Carries both gates the prototype had and they are different things:
##   progress   op 2 and 3 are locked until the one before it has been finished at all
##              (GCRules.op_locked — the prototype's `locked`)
##   dual track op 2 and 3 are behind Gate on the web (ops/DUAL_TRACK.md): a price on the
##              itch build, a sponsor clip on the ad-supported one, open on the desktop
##              download. A locked-by-progress card says LOCKED; a gated one says what it
##              costs, and pressing it runs the gate and starts the op if it opens.
extends Control

var main: Control

var _cards := []
var _title: Label
var _hint: Label
var _back: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(84, 108)
	col.custom_minimum_size = Vector2(760, 0)
	col.add_theme_constant_override("separation", 14)
	add_child(col)

	_title = StudioTheme.display_label("", 38, Palette.TEXT)
	col.add_child(_title)
	_hint = StudioTheme.mono_label("", 13, Palette.MUTED)
	col.add_child(_hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	for i in range(GCRules.OPS.size()):
		var card := preload("res://scripts/op_card.gd").new()
		card.index = i
		card.custom_minimum_size = Vector2(244, 244)
		card.chosen.connect(_choose)
		row.add_child(card)
		_cards.append(card)

	_back = Button.new()
	_back.theme_type_variation = "Ghost"
	_back.custom_minimum_size = Vector2(150, 0)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.pressed.connect(func():
		Sfx.click()
		main.show_screen("title"))
	col.add_child(_back)
	relocalise()


func relocalise() -> void:
	_title.text = Game.t("selectOp")
	_hint.text = Game.t("opsHint")
	_back.text = Game.t("back")
	for c in _cards:
		c.refresh()


func on_show() -> void:
	for c in _cards:
		c.refresh()


func _choose(index: int) -> void:
	var op: Dictionary = GCRules.OPS[index]
	if GCRules.op_locked(index, Game.wins, Game.best):
		Sfx.warn()
		return
	var key := "op" + str(int(op.id))
	if index > 0 and OS.has_feature("web") and not Gate.has(key):
		var meta := GCStrings.op_meta(Game.lang, index)
		var ok: bool = await Gate.require(key, str(meta.name), "level")
		if not ok:
			for c in _cards:
				c.refresh()
			return
	main.screens["play"].start_op(index)


func on_key(k: InputEventKey) -> bool:
	var n := k.keycode - KEY_1
	if n >= 0 and n < _cards.size():
		Sfx.click()
		_choose(n)
		return true
	return false
