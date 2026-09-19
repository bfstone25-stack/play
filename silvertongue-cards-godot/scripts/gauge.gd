## MomentumGauge — a physical brass gauge for the engine's momentum (0..1), with the two
## phase ticks at .30 (engaged) and .68 (wavering) engraved on it. The needle is tweened;
## the fill is lamp-lit. Reads only what the backend returned.
class_name MomentumGauge
extends Control

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
var closed := false:
	set(v):
		closed = v
		queue_redraw()
var _shown := 0.0
var _tween: Tween
var _font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(300, 46)
	_font = StudioTheme.font("mono")


func animate_to(v: float) -> void:
	value = v
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(x): _shown = x; queue_redraw(), _shown, value, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func snap(v: float) -> void:
	value = v
	_shown = v
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var track := Rect2(0, 18, w, 14)
	# casing
	draw_rect(Rect2(-2, 14, w + 4, 22), Color("2a2220"), true)
	draw_rect(Rect2(-2, 14, w + 4, 22), Color("4a3c30"), false, 1.0)
	draw_rect(track, Color("120e12"), true)
	# fill: brass -> lamp
	var fw := w * _shown
	var steps := 24
	for i in steps:
		var x0 := fw * i / steps
		var x1 := fw * (i + 1) / steps
		var c := Palette.BRASS.lerp(Palette.LAMP, float(i) / steps)
		if closed:
			c = Color("5a4a44").lerp(Color("8a7060"), float(i) / steps)
		draw_rect(Rect2(x0, 18, x1 - x0 + 1, 14), c, true)
	# glow on the fill's edge
	if not closed and _shown > 0.02:
		draw_rect(Rect2(fw - 6, 16, 6, 18), Color(Palette.LAMP, 0.35), true)
	# ticks at the phase thresholds
	for t in [[0.30, "ENGAGED"], [0.68, "WAVERING"]]:
		var x := w * float(t[0])
		draw_line(Vector2(x, 12), Vector2(x, 38), Color(Palette.CREAM, 0.7), 1.0)
		draw_string(_font, Vector2(x + 4, 10), str(t[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Palette.MUTED, 0.9))
		draw_string(_font, Vector2(x + 4, 46), ".%02d" % int(round(float(t[0]) * 100)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Palette.DIM, 0.9))
	# needle
	var nx := w * _shown
	var col := Palette.RED_TEXT if closed else Palette.LAMP
	draw_line(Vector2(nx, 12), Vector2(nx, 40), col, 2.0)
	draw_circle(Vector2(nx, 40), 3.5, col)
	draw_string(_font, Vector2(w - 34, 10), "%.2f" % _shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.LAMP)
