## Counter — a number that lands. Instead of changing, it counts to the new value,
## overshoots a little and settles (UI_DIRECTION: "numbers animate: count up, overshoot,
## settle"). Gold in the wallet, the momentum readout, the affection and Gold lines on
## the end banner all use one. Display face is the caller's choice; this only moves.
class_name Counter
extends Label

var value := 0.0
var target := 0.0
var prefix := ""
var suffix := ""
var decimals := 0
var lo := -INF                 # the shown value is clamped here, so an overshoot on a
var hi := INF                  # 0..1 gauge never prints 1.02
var _tw: Tween


func set_now(v: float) -> void:
	value = v
	target = v
	text = _fmt(v)


func set_target(v: float, dur: float = 0.7, pop: bool = true) -> void:
	if is_equal_approx(v, target):
		return
	target = v
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(_apply, value, target, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if pop:
		pivot_offset = size / 2.0
		scale = Vector2(1.18, 1.18)
		_tw.parallel().tween_property(self, "scale", Vector2.ONE, dur * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply(v: float) -> void:
	value = v
	text = _fmt(clampf(v, lo, hi))


func _fmt(v: float) -> String:
	if decimals > 0:
		return prefix + ("%.*f" % [decimals, v]) + suffix
	var n := int(round(v))
	var s := str(absi(n))
	var out := ""
	var k := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		k += 1
		if k % 3 == 0 and i > 0:
			out = "," + out
	return prefix + ("-" if n < 0 else "") + out + suffix
