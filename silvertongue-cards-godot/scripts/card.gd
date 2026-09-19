## Card — one playing card, drawn by hand. Face = rarity frame, character, the printed
## line in serif, the signal chips, the nerve cost gem. A coercion card shows a big
## "MOMENTUM +0.40" with the trap in small print, exactly as the design asks: it is meant
## to look tempting on its face.
##
## States: idle / hover (lifted) / disabled (unaffordable, dimmed) / face-down (gacha).
## Emits `pressed` on click or tap; the owner decides what a press means.
class_name Card
extends Control

signal pressed(card: Card)
signal hovered(card: Card, on: bool)

const W := 190.0
const H := 224.0

var data: Dictionary = {}
var affordable := true
var face_down := false
var interactive := true
var glow := 0.0                   # 0..1, rarity glow for the gacha reveal
var _hover := false
var _pressed := false
var _line: Label
var _small: Label
var _big: Label
var _who: Label
var _chips: HBoxContainer
var _cost: Label
var _back_mark: Label
var _selected := false


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	pivot_offset = Vector2(W / 2, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _set_hover(true))
	mouse_exited.connect(func(): _set_hover(false))
	_build()
	refresh()


func setup(d: Dictionary, can_afford: bool = true) -> void:
	data = d
	affordable = can_afford
	if is_inside_tree():
		refresh()


func _build() -> void:
	_who = StudioTheme.mono_label("", 10, Palette.MUTED)
	_who.position = Vector2(12, 10)
	add_child(_who)
	_cost = StudioTheme.mono_label("", 12, Palette.GREEN)
	_cost.position = Vector2(W - 44, 8)
	_cost.size = Vector2(32, 18)
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_cost)
	_big = StudioTheme.display_label("", 19, Palette.RED_TEXT)
	_big.position = Vector2(12, 36)
	_big.size = Vector2(W - 24, 52)
	_big.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_big.visible = false
	add_child(_big)
	_line = StudioTheme.serif_label("", 15, Palette.PARCHMENT, true)
	_line.position = Vector2(14, 44)
	_line.size = Vector2(W - 28, 120)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_line)
	_chips = HBoxContainer.new()
	_chips.position = Vector2(12, H - 44)
	_chips.size = Vector2(W - 24, 22)
	_chips.add_theme_constant_override("separation", 4)
	add_child(_chips)
	_small = StudioTheme.mono_label("", 8, Palette.INK_SOFT)
	_small.position = Vector2(12, H - 50)
	_small.size = Vector2(W - 24, 44)
	_small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_small.visible = false
	add_child(_small)
	_back_mark = StudioTheme.display_label("S", 64, Color(Palette.LAMP, 0.55))
	_back_mark.size = Vector2(W, H)
	_back_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_back_mark.visible = false
	add_child(_back_mark)


func refresh() -> void:
	for c in _chips.get_children():
		c.queue_free()
	var kind := str(data.get("kind", ""))
	var rarity := str(data.get("rarity", "common"))
	var coercion := kind == "coercion"
	var wild := rarity == "wild"
	_who.text = ("%s · %s" % [rarity.to_upper(), str(data.get("character", ""))]) if not wild else "WILD · once"
	_who.add_theme_color_override("font_color", Palette.rarity_text(rarity, kind))
	_cost.text = "%d◈" % int(data.get("cost", 1))
	_cost.add_theme_color_override("font_color", Palette.GREEN if affordable else Palette.FAINT)
	_big.visible = coercion
	_small.visible = coercion
	if coercion:
		_big.text = str(data.get("face", "MOMENTUM +0.40"))
		_line.text = str(data.get("line", ""))
		_line.position.y = 92
		_line.add_theme_font_size_override("font_size", 13)
		_small.text = str(data.get("small_print", ""))
		_chips.visible = false
	elif wild:
		_line.text = "Say it in your own words."
		_line.add_theme_color_override("font_color", Palette.AMBER)
		_line.position.y = 44
		_chips.visible = true
		_add_chip("the engine reads it", false)
	else:
		_line.text = "“%s”" % str(data.get("line", ""))
		_line.position.y = 44
		_line.add_theme_font_size_override("font_size", 15 if str(data.get("line", "")).length() < 44 else 13)
		_chips.visible = true
		for s in data.get("signals", []):
			_add_chip("%s %s" % [Palette.glyph(str(s)), Palette.label(str(s))], false)
	for c in [_who, _cost, _line]:
		c.visible = true
	for c in [_who, _cost, _big, _line, _chips, _small]:
		c.visible = c.visible and not face_down
	_back_mark.visible = face_down
	_apply_dim()
	queue_redraw()


func _add_chip(text: String, lit: bool) -> void:
	_chips.add_child(Chip.make(text, lit, false))


func _apply_dim() -> void:
	modulate = Color(1, 1, 1, 1) if (affordable or face_down) else Color(0.7, 0.7, 0.7, 0.55)


func set_selected(on: bool) -> void:
	_selected = on
	queue_redraw()


func set_face_down(on: bool) -> void:
	face_down = on
	refresh()


func _set_hover(on: bool) -> void:
	if _hover == on:
		return
	_hover = on
	hovered.emit(self, on)
	if not interactive or not affordable or face_down:
		return
	if on:
		Sfx.play("card_hover", -18.0)
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if not interactive:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_pressed = true
		elif _pressed:
			_pressed = false
			accept_event()
			if affordable or face_down:
				pressed.emit(self)
	elif ev is InputEventScreenTouch and not ev.pressed:
		if affordable or face_down:
			pressed.emit(self)


func _draw() -> void:
	var kind := str(data.get("kind", ""))
	var rarity := str(data.get("rarity", "common"))
	var r := Rect2(Vector2.ZERO, size)
	var frame := Palette.rarity_color(rarity, kind)
	# shadow
	draw_rect(Rect2(Vector2(4, 6), size), Color(0, 0, 0, 0.45), true)
	if glow > 0.0:
		for i in 4:
			var g := Rect2(Vector2(-4 - i * 4, -4 - i * 4), size + Vector2(8 + i * 8, 8 + i * 8))
			draw_rect(g, Color(frame, glow * 0.18 * (1.0 - i * 0.2)), true)
	if face_down:
		draw_rect(r, Color("1c1420"), true)
		draw_rect(r.grow(-6), Color("2a1f2e"), true)
		draw_rect(r.grow(-6), Palette.AMBER_DEEP, false, 2.0)
		draw_rect(r.grow(-14), Color(Palette.BRASS, 0.7), false, 1.0)
		draw_rect(r, Palette.BRASS, false, 2.0)
		return
	# face
	var top := Color("2a2124") if kind != "coercion" else Color("2c1916")
	var bottom := Color("191317")
	var steps := 12
	for i in steps:
		var y0 := r.size.y * i / steps
		var y1 := r.size.y * (i + 1) / steps
		draw_rect(Rect2(0, y0, r.size.x, y1 - y0 + 1), top.lerp(bottom, float(i) / steps), true)
	# rarity band on top
	draw_rect(Rect2(0, 0, r.size.x, 30), Color(frame, 0.18), true)
	draw_line(Vector2(0, 30), Vector2(r.size.x, 30), Color(frame, 0.55), 1.0)
	var border := frame
	var width := 1.5
	if _selected:
		border = Palette.LAMP
		width = 3.0
	elif _hover and interactive and affordable:
		border = Palette.LAMP
		width = 2.0
	if rarity == "wild":
		_draw_dashed(r, border, 2.0)
	else:
		draw_rect(r, border, false, width)
	if rarity == "epic" or kind == "coercion":
		draw_rect(r.grow(-4), Color(frame, 0.35), false, 1.0)
	# a faint watermark of the card's first signal, so the face has a centre
	var sigs: Array = data.get("signals", [])
	var mark := "×" if kind == "coercion" else ("?" if rarity == "wild" else (Palette.glyph(str(sigs[0])) if not sigs.is_empty() else ""))
	if mark != "" and not face_down:
		draw_string(StudioTheme.font("display"), Vector2(r.size.x / 2 - 22, r.size.y * 0.62), mark, HORIZONTAL_ALIGNMENT_CENTER, 44, 64, Color(frame, 0.10))
	draw_rect(r.grow(-7), Color(frame, 0.16), false, 1.0)


func _draw_dashed(r: Rect2, c: Color, w: float) -> void:
	var pts := [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 10.0)
		for k in range(0, n, 2):
			draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), c, w)
