## MomentumGauge — the engine's momentum (0..1) as a heat bar: coral fill on the plum
## casing, gold ticks engraved at the two phase thresholds (.30 engaged, .68 wavering),
## and the readout in the display face at the right, counting up whenever the number
## changes. The fill is tweened; the readout overshoots and settles. Reads only what the
## backend returned.
class_name MomentumGauge
extends Control

const READOUT_W := 64.0

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
var closed := false:
	set(v):
		closed = v
		queue_redraw()
		if _readout:
			_readout.add_theme_color_override("font_color", Palette.HEAT_DEEP if closed else Palette.GOLD)
var _shown := 0.0
var _tween: Tween
var _font: Font
var _readout: Counter


func _ready() -> void:
	custom_minimum_size = Vector2(300, 46)
	_font = StudioTheme.font("bold")
	_readout = Counter.new()
	_readout.decimals = 2
	_readout.lo = 0.0
	_readout.hi = 1.0
	_readout.add_theme_font_override("font", StudioTheme.font("display"))
	_readout.add_theme_font_size_override("font_size", 24)
	_readout.add_theme_color_override("font_color", Palette.GOLD)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.set_now(0.0)
	add_child(_readout)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	_readout.position = Vector2(size.x - READOUT_W, 8)
	_readout.size = Vector2(READOUT_W, 32)


func _track_w() -> float:
	return maxf(40.0, size.x - READOUT_W - 10.0)


func animate_to(v: float) -> void:
	value = v
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(x): _shown = x; queue_redraw(), _shown, value, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_readout.set_target(value, 0.7)


func snap(v: float) -> void:
	value = v
	_shown = v
	_readout.set_now(v)
	queue_redraw()


func _draw() -> void:
	var w := _track_w()
	var track := Rect2(0, 18, w, 14)
	# casing: a shade up from the panel, plum edge
	draw_rect(Rect2(-2, 14, w + 4, 22), Palette.PANEL_RAISED, true)
	draw_rect(Rect2(-2, 14, w + 4, 22), Palette.LINE_STRONG, false, 1.0)
	draw_rect(track, Palette.GROUND_DEEP, true)
	# fill: deep coral -> coral, hotter toward the needle; lost = the heat gone out of it
	var fw := w * _shown
	var steps := 24
	for i in steps:
		var x0 := fw * i / steps
		var x1 := fw * (i + 1) / steps
		var c := Palette.HEAT_DEEP.lerp(Palette.HEAT, float(i) / steps)
		if closed:
			c = Palette.RED_DIM.lerp(Palette.HEAT_DEEP, float(i) / steps)
		draw_rect(Rect2(x0, 18, x1 - x0 + 1, 14), c, true)
	# the glow at the fill's edge (allowed: it is heat, not text)
	if not closed and _shown > 0.02:
		draw_rect(Rect2(fw - 10, 15, 10, 20), Color(Palette.HEAT, 0.35), true)
		draw_rect(Rect2(fw - 4, 16, 4, 18), Color(Palette.GOLD_PALE, 0.5), true)
	# gold ticks at the phase thresholds
	for t in [[0.30, Loc.t("ENGAGED")], [0.68, Loc.t("WAVERING")]]:
		var x := w * float(t[0])
		draw_line(Vector2(x, 12), Vector2(x, 38), Palette.GOLD, 1.5)
		draw_string(_font, Vector2(x + 4, 10), str(t[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.GOLD)
		draw_string(_font, Vector2(x + 4, 46), ".%02d" % int(round(float(t[0]) * 100)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Palette.MUTED, 0.9))
	# needle
	var nx := w * _shown
	var col := Palette.HEAT_DEEP if closed else Palette.GOLD_PALE
	draw_line(Vector2(nx, 12), Vector2(nx, 40), col, 2.0)
	draw_circle(Vector2(nx, 40), 3.5, col)
