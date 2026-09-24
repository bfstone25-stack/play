class_name RollingLabel
extends Label
## A number that rolls to its target instead of changing. Rent paying out is a counter
## that counts: it runs up, overshoots a little, settles back — and the label lands with
## a small pop when the number went up.

var value := 0.0
var target := 0.0
var prefix := ""
var suffix := ""
## Show 1,000,000 and up as 1.00M / 12.3M / 350M, so a late-game bank cannot push the HUD
## row past 1280 (the Nutaku HUD sets it; everything else keeps the full number).
var compact := false
var _tw: Tween
var _last_int := 0


func set_now(v: float) -> void:
	value = v
	target = v
	_last_int = int(round(v))
	text = prefix + _show(v) + suffix


func set_target(v: float, dur: float = 0.6) -> void:
	if is_equal_approx(v, target):
		return
	var up := v > target
	target = v
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	# TRANS_BACK / EASE_OUT runs past the target and comes back: the overshoot.
	_tw.tween_method(_apply, value, target, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if up:
		pivot_offset = size * 0.5
		_tw.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tw.tween_property(self, "scale", Vector2(1, 1), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply(v: float) -> void:
	value = v
	var iv := int(round(v))
	if iv != _last_int:
		_last_int = iv
		text = prefix + _show(v) + suffix


func _show(v: float) -> String:
	return _short(v) if compact else _fmt(v)


static func _short(v: float) -> String:
	var a := absf(v)
	if a < 1000000.0:
		return _fmt(v)
	var units := [[1e12, "T"], [1e9, "B"], [1e6, "M"]]
	for u in units:
		if a >= float(u[0]):
			var x: float = v / float(u[0])
			var dp := 2 if absf(x) < 10.0 else (1 if absf(x) < 100.0 else 0)
			return String.num(x, dp) + str(u[1])
	return _fmt(v)


static func _fmt(v: float) -> String:
	var n := int(round(v))
	var s := str(abs(n))
	var out := ""
	var k := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		k += 1
		if k % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
