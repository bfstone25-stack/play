class_name Backdrop
extends Control
## The room behind a screen, drawn: "night" is the fork's own (plum ground, one hot pool
## of light where the table is); "east" is ink with incense smoke rising; "west" is
## violet with a candle's pool of light and a few stars; "reader" is the West at night with
## the lamp lower; "home" is ink with a faint warm centre.

var mode := "east"
var _t := 0.0
var _stars: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _i in range(40):
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.55, rng.randf()))


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var s := size
	match mode:
		"east":
			draw_rect(Rect2(Vector2.ZERO, s), Palette.INK)
			# a warm floor and a faint lacquer band up the centre
			draw_rect(Rect2(0, s.y * 0.62, s.x, s.y * 0.38), Color("1A1210"))
			draw_rect(Rect2(s.x * 0.5 - 120, 0, 240, s.y), Color(Palette.LACQUER_DEEP, 0.08))
			_smoke(Vector2(s.x * 0.5 - 150, s.y * 0.6), 0.0)
			_smoke(Vector2(s.x * 0.5 + 170, s.y * 0.58), 1.7)
		"west", "reader":
			draw_rect(Rect2(Vector2.ZERO, s), Palette.VIOLET_DEEP)
			for st in _stars:
				var a := 0.25 + 0.25 * sin(_t * 1.5 + st.z * 10.0)
				draw_circle(Vector2(st.x * s.x, st.y * s.y), 1.2 + st.z, Color(Palette.SILVER, a))
			var cy := s.y * (0.78 if mode == "west" else 0.62)
			var flick := 1.0 + 0.04 * sin(_t * 9.0) + 0.02 * sin(_t * 23.0)
			for i in range(6, 0, -1):
				var rr := 90.0 * i * flick
				draw_circle(Vector2(s.x * 0.5, cy), rr, Color(Palette.CANDLE, 0.035))
		"night":
			# The night fork's ground: plum-black, one hot pool of light low in the frame
			# where the table is, and the candle's flicker on it.
			draw_rect(Rect2(Vector2.ZERO, s), Palette.PLUM)
			# The table takes the lower half and is lit; the wall above it falls off. The
			# light is generous on purpose — a night scene still has to READ
			# (ops/check_brightness.py --scene), and the contrast that makes it night is
			# the wall against the table, not the whole frame being dark.
			draw_rect(Rect2(0, s.y * 0.52, s.x, s.y * 0.48), Color("3A2036"))
			var fl := 1.0 + 0.05 * sin(_t * 7.0) + 0.02 * sin(_t * 19.0)
			for i in range(9, 0, -1):
				draw_circle(Vector2(s.x * 0.5, s.y * 0.62), 82.0 * i * fl, Color(Palette.HOT, 0.030))
			for i in range(5, 0, -1):
				draw_circle(Vector2(s.x * 0.5, s.y * 0.62), 52.0 * i * fl, Color(Palette.AMBER, 0.055))
			draw_circle(Vector2(s.x * 0.5, s.y * 0.62), 26.0 * fl, Color(Palette.AMBER, 0.25))
			for st in _stars:
				var a := 0.16 + 0.16 * sin(_t * 1.5 + st.z * 10.0)
				draw_circle(Vector2(st.x * s.x, st.y * s.y * 0.7), 1.0 + st.z, Color(Palette.HOT_PALE, a))
		_:
			draw_rect(Rect2(Vector2.ZERO, s), Palette.PLUM)
			for i in range(5, 0, -1):
				draw_circle(Vector2(s.x * 0.5, s.y * 0.42), 110.0 * i, Color(Palette.HOT, 0.018))


func _smoke(origin: Vector2, phase: float) -> void:
	var pts := PackedVector2Array()
	for i in range(40):
		var y := origin.y - i * 14.0
		var x := origin.x + sin(_t * 0.6 + phase + i * 0.22) * (6.0 + i * 1.6)
		pts.append(Vector2(x, y))
	for i in range(pts.size() - 1):
		var a := 0.18 * (1.0 - float(i) / pts.size())
		draw_line(pts[i], pts[i + 1], Color(Palette.SMOKE, a), 2.0 + i * 0.12)
