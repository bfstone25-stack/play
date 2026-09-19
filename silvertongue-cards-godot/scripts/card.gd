## Card — one playing card, drawn by hand. Face = rarity frame, the character's face in
## the picture panel (assets/faces/<who>.webp, cut from the installed tier-1 plate by
## tools/sync_art.py), the printed line in serif below it, the signal chips at the foot,
## the nerve cost gem. A coercion card has no face: it shows a big "MOMENTUM +0.40" with
## the trap in small print, exactly as the design asks — it is meant to look tempting.
## The back carries the studio mark.
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
var _pic: TextureRect
var _pic_frame: Control
var _selected := false

const PIC := Rect2(8, 28, W - 16, 98)      # the picture panel
static var _faces := {}                    # character -> Texture2D (or null once looked up)


## The face texture for a character, or null when the package has none (house, wild).
static func face_texture(who: String) -> Texture2D:
	if who == "":
		return null
	if not _faces.has(who):
		var path := "res://assets/faces/%s.webp" % who
		_faces[who] = load(path) if ResourceLoader.exists(path) else null
	return _faces[who]


static func face_path(who: String) -> String:
	return "res://assets/faces/%s.webp" % who


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
	_pic_frame = Control.new()
	_pic_frame.position = PIC.position
	_pic_frame.size = PIC.size
	_pic_frame.clip_contents = true
	_pic_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic_frame)
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pic_frame.add_child(_pic)
	_line = StudioTheme.serif_label("", 13, Palette.PARCHMENT, true)
	_line.position = Vector2(12, 130)
	_line.size = Vector2(W - 24, 62)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_line)
	_chips = HBoxContainer.new()
	_chips.position = Vector2(10, H - 30)
	_chips.size = Vector2(W - 20, 22)
	_chips.add_theme_constant_override("separation", 4)
	_chips.clip_contents = true
	add_child(_chips)
	_small = StudioTheme.mono_label("", 8, Palette.INK_SOFT)
	_small.position = Vector2(12, H - 50)
	_small.size = Vector2(W - 24, 44)
	_small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_small.visible = false
	add_child(_small)
	_back_mark = StudioTheme.mono_label("SILVERTONGUE", 8, Color(Palette.LAMP, 0.6))
	_back_mark.position = Vector2(0, H - 36)
	_back_mark.size = Vector2(W, 16)
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
	var face := face_texture(str(data.get("character", ""))) if not (coercion or wild) else null
	_pic.texture = face
	_pic_frame.visible = face != null and not face_down
	if coercion:
		_big.text = str(data.get("face", "MOMENTUM +0.40"))
		_line.text = str(data.get("line", ""))
		_line.position.y = 92
		_line.size.y = 80
		_line.add_theme_font_size_override("font_size", 13)
		_small.text = str(data.get("small_print", ""))
		_chips.visible = false
	elif wild:
		_line.text = "Say it in your own words."
		_line.add_theme_color_override("font_color", Palette.AMBER)
		_line.position.y = 44
		_line.size.y = 120
		_line.add_theme_font_size_override("font_size", 15)
		_chips.visible = true
		_add_chip("the engine reads it", false)
	else:
		_line.text = "“%s”" % str(data.get("line", ""))
		_line.position.y = 130 if face != null else 44
		_line.size.y = 62 if face != null else 120
		_line.add_theme_font_size_override("font_size", 13 if str(data.get("line", "")).length() < 40 else 11)
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
		_draw_back(r)
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
	# rarity frame styles: common one hairline, rare a double line with corner ticks,
	# epic a gilt double frame with lit corners (and the glow the reveal drives)
	if rarity == "rare":
		draw_rect(r.grow(-4), Color(frame, 0.55), false, 1.0)
		_draw_corners(r.grow(-4), frame, 10.0, 1.5)
	elif rarity == "epic":
		draw_rect(r.grow(-4), Color(frame, 0.8), false, 1.5)
		draw_rect(r.grow(-7), Color(Palette.LAMP, 0.35), false, 1.0)
		_draw_corners(r.grow(-4), Palette.LAMP, 14.0, 2.0)
	elif kind == "coercion":
		draw_rect(r.grow(-4), Color(frame, 0.35), false, 1.0)
	else:
		draw_rect(r.grow(-7), Color(frame, 0.16), false, 1.0)
	if _pic_frame.visible:
		# picture panel frame + a lamp fall-off along its foot so the line reads
		draw_rect(PIC.grow(1), Color(frame, 0.7), false, 1.0)
		draw_rect(Rect2(PIC.position.x, PIC.end.y - 14, PIC.size.x, 14), Color(0, 0, 0, 0.0), true)
		var steps2 := 6
		for i in steps2:
			var y := PIC.end.y - 14 + i * 14.0 / steps2
			draw_rect(Rect2(PIC.position.x, y, PIC.size.x, 14.0 / steps2 + 1), Color(0.06, 0.04, 0.05, 0.12 * (i + 1)), true)
	else:
		# a faint watermark of the card's first signal, so a face-less card has a centre
		var sigs: Array = data.get("signals", [])
		var mark := "×" if kind == "coercion" else ("?" if rarity == "wild" else (Palette.glyph(str(sigs[0])) if not sigs.is_empty() else ""))
		if mark != "":
			draw_string(StudioTheme.font("display"), Vector2(r.size.x / 2 - 22, r.size.y * 0.62), mark, HORIZONTAL_ALIGNMENT_CENTER, 44, 64, Color(frame, 0.10))


func _draw_corners(r: Rect2, c: Color, len: float, w: float) -> void:
	var pts := [[r.position, Vector2(1, 0), Vector2(0, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 0), Vector2(0, 1)],
		[r.end, Vector2(-1, 0), Vector2(0, -1)], [Vector2(r.position.x, r.end.y), Vector2(1, 0), Vector2(0, -1)]]
	for p in pts:
		draw_line(p[0], p[0] + p[1] * len, c, w)
		draw_line(p[0], p[0] + p[2] * len, c, w)


## The back: dark felt, a brass double frame, the studio mark (the icon's card with three
## lines and the green gem) in the centre.
func _draw_back(r: Rect2) -> void:
	draw_rect(r, Color("1c1420"), true)
	draw_rect(r.grow(-6), Color("2a1f2e"), true)
	draw_rect(r.grow(-6), Palette.AMBER_DEEP, false, 2.0)
	draw_rect(r.grow(-14), Color(Palette.BRASS, 0.7), false, 1.0)
	draw_rect(r, Palette.BRASS, false, 2.0)
	# lattice
	for i in range(0, int(r.size.x / 12)):
		var x := 16.0 + i * 12.0
		if x > r.size.x - 16:
			break
		draw_line(Vector2(x, 16), Vector2(x, r.size.y - 16), Color(Palette.BRASS, 0.10), 1.0)
	for i in range(0, int(r.size.y / 12)):
		var y := 16.0 + i * 12.0
		if y > r.size.y - 16:
			break
		draw_line(Vector2(16, y), Vector2(r.size.x - 16, y), Color(Palette.BRASS, 0.10), 1.0)
	var c := r.size / 2.0 - Vector2(0, 8)
	var mark := Rect2(c - Vector2(30, 40), Vector2(60, 80))
	draw_rect(mark.grow(6), Color("1c1420"), true)
	draw_rect(mark, Color("211822"), true)
	draw_rect(mark, Palette.AMBER, false, 3.0)
	for i in 3:
		var y := mark.position.y + 20 + i * 14
		var len := 32.0 if i < 2 else 20.0
		draw_line(Vector2(mark.position.x + 14, y), Vector2(mark.position.x + 14 + len, y), Palette.LAMP, 4.0)
	draw_circle(Vector2(mark.end.x - 14, mark.end.y - 16), 5.0, Palette.GREEN)


func _draw_dashed(r: Rect2, c: Color, w: float) -> void:
	var pts := [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 10.0)
		for k in range(0, n, 2):
			draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), c, w)
