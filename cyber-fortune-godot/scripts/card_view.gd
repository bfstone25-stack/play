class_name CardView
extends Control
## One tarot card, drawn: a procedural back (violet, silver double border, a lattice of
## diamonds, a central mark) and a typographic face (numeral, symbol glyph, name). The
## face slots in later by filename — assets/tarot/<slug>.webp — and is drawn in the
## frame when it exists; the layout does not change. flip() turns it over through the
## edge; reversed cards show the face upside down.

var slug := ""
var reversed := false
var face_up := false
var tex: Texture2D
var _flip := 0.0     # 0 = full back, 1 = full face (the scale.x through zero)
var _card: Dictionary = {}
var _highlight := false


func setup(s: String, rev: bool = false, up: bool = false) -> void:
	slug = s
	reversed = rev
	face_up = up
	_flip = 1.0 if up else 0.0
	_card = Fortune.card(slug)
	var path := "res://assets/tarot/%s.webp" % slug
	if ResourceLoader.exists(path):
		tex = load(path)
	queue_redraw()


func set_highlight(on: bool) -> void:
	_highlight = on
	queue_redraw()


func flip() -> void:
	face_up = not face_up
	Sfx.flip()
	var tw := create_tween()
	tw.tween_method(func(v): _flip = v; queue_redraw(), _flip, 1.0 if face_up else 0.0, 0.42).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _draw() -> void:
	var w := size.x
	var h := size.y
	var sx := absf(cos(_flip * PI))
	var showing_face := _flip >= 0.5
	draw_set_transform(Vector2(w * 0.5, h * 0.5), 0.0, Vector2(maxf(sx, 0.02), 1.0))
	var r := Rect2(Vector2(-w * 0.5, -h * 0.5), Vector2(w, h))
	if _highlight:
		var g := StudioTheme.glow(StudioTheme.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 10, 0, Vector2.ZERO), Palette.CANDLE, 18, 0.8)
		draw_style_box(g, r)
	if showing_face:
		_draw_face(r)
	else:
		_draw_back(r)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_back(r: Rect2) -> void:
	var sb := StudioTheme.flat(Palette.VIOLET, Palette.SILVER, 10, 2, Vector2.ZERO)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	draw_style_box(sb, r)
	var inner := r.grow(-9)
	draw_rect(inner, Color(Palette.SILVER, 0.55), false, 1.0)
	# lattice of diamonds
	var step := 22.0
	var y := inner.position.y + step
	var row := 0
	while y < inner.end.y - step * 0.5:
		var x := inner.position.x + step * (0.5 if row % 2 == 0 else 1.0)
		while x < inner.end.x - step * 0.4:
			var d := PackedVector2Array([Vector2(x, y - 7), Vector2(x + 7, y), Vector2(x, y + 7), Vector2(x - 7, y)])
			draw_polyline(d + PackedVector2Array([d[0]]), Color(Palette.SILVER, 0.22), 1.0)
			x += step
		y += step
		row += 1
	# the central mark: a silver ring with a moon
	var c := r.get_center()
	draw_circle(c, 34.0, Palette.VIOLET_DEEP)
	draw_arc(c, 34.0, 0, TAU, 48, Palette.SILVER, 2.0, true)
	draw_arc(c, 26.0, 0, TAU, 48, Color(Palette.SILVER, 0.5), 1.0, true)
	draw_circle(c + Vector2(-4, 0), 13.0, Palette.SILVER)
	draw_circle(c + Vector2(2, -3), 12.0, Palette.VIOLET_DEEP)


func _draw_face(r: Rect2) -> void:
	var sb := StudioTheme.flat(Palette.PARCHMENT, Palette.SILVER_DIM, 10, 2, Vector2.ZERO)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	draw_style_box(sb, r)
	var rot := PI if reversed else 0.0
	var c := r.get_center()
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.5), rot, Vector2(maxf(absf(cos(_flip * PI)), 0.02), 1.0))
	var rr := Rect2(-r.size * 0.5, r.size)
	var inner := rr.grow(-8)
	draw_rect(inner, Color(Palette.VIOLET_EDGE, 0.7), false, 1.0)
	var frame := Rect2(inner.position + Vector2(8, 34), Vector2(inner.size.x - 16, inner.size.y * 0.58))
	if tex:
		draw_texture_rect(tex, frame, false)
		draw_rect(frame, Color(Palette.VIOLET_EDGE, 0.7), false, 1.0)
	else:
		draw_rect(frame, Color(Palette.VIOLET, 0.06))
		draw_rect(frame, Color(Palette.VIOLET_EDGE, 0.5), false, 1.0)
		var glyph := str(_card.get("glyph", "◎"))
		var gf := StudioTheme.font("serif")
		var gs := int(frame.size.y * 0.42)
		var gw := gf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
		draw_string(gf, Vector2(frame.get_center().x - gw * 0.5, frame.get_center().y + gs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Palette.VIOLET_SOFT)
	var f := StudioTheme.font("black")
	var num := str(_card.get("numeral", ""))
	draw_string(f, inner.position + Vector2(8, 24), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.VIOLET_SOFT)
	var nw := f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(f, Vector2(inner.end.x - 8 - nw, inner.position.y + 24), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.VIOLET_SOFT)
	var name := Tx.field(_card, "name") if not _card.is_empty() else slug
	var nf := StudioTheme.font("serif")
	var ns := 15 if rr.size.x > 150 else 11
	var lines := [name]
	if nf.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x > inner.size.x - 12 and " of " in name:
		lines = name.split(" of ")
		lines[1] = "of " + lines[1]
	var y := frame.end.y + 20
	for ln in lines:
		var lw := nf.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		draw_string(nf, Vector2(-lw * 0.5, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, Palette.PARCHMENT_INK)
		y += ns + 4
