## Rain on the window — the moving light TITLE_SCREENS.md asks for, on the glass plane.
##
## Drawn rather than rendered, deliberately, and this is the one place in the build where
## that is the right call: rain is motion, not an image, and a rendered plate of rain is a
## still photograph of rain. The rule this does not break is the other one — no code-drawn
## *shapes where an asset should be*. The station, the room, the five faces are all plates.
## This is weather.
extends Node2D

const DESIGN := Vector2(1280, 720)
const DROPS := 90
const RUNNELS := 14

var _drops := []            # [pos, speed, length, alpha]
var _runnels := []          # [x, y, speed, width] — the slow ones on the glass
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 90210
	for i in DROPS:
		_drops.append([
			Vector2(_rng.randf() * DESIGN.x, _rng.randf() * DESIGN.y),
			_rng.randf_range(520.0, 1150.0),
			_rng.randf_range(9.0, 26.0),
			_rng.randf_range(0.05, 0.18),
		])
	for i in RUNNELS:
		_runnels.append([
			_rng.randf() * DESIGN.x,
			_rng.randf() * DESIGN.y,
			_rng.randf_range(14.0, 46.0),
			_rng.randf_range(1.0, 2.6),
		])
	set_process(true)


func _process(delta: float) -> void:
	for d in _drops:
		d[0].y += d[1] * delta
		d[0].x -= d[1] * 0.16 * delta      # the squall comes in from the right
		if d[0].y > DESIGN.y:
			d[0] = Vector2(_rng.randf() * DESIGN.x * 1.2, -30.0)
	for r in _runnels:
		r[1] += r[2] * delta
		if r[1] > DESIGN.y:
			r[1] = -40.0
			r[0] = _rng.randf() * DESIGN.x
	queue_redraw()


func _draw() -> void:
	for d in _drops:
		var p: Vector2 = d[0]
		draw_line(p, p + Vector2(-d[2] * 0.16, d[2]), Color(Palette.ACCENT_SOFT, d[3]), 1.0)
	for r in _runnels:
		# a runnel is a wet streak with a brighter head: the light is behind the glass
		draw_line(Vector2(r[0], r[1] - 34.0), Vector2(r[0], r[1]), Color(Palette.TEXT, 0.05), r[3])
		draw_circle(Vector2(r[0], r[1]), r[3] * 1.3, Color(Palette.TEXT, 0.12))
