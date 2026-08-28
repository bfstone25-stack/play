extends Node2D
class_name OfficeBuilder

## Procedural pixel cubicle: desk, CRT, sticky, drawer, coworker silhouette.
## Designed for a 320x180 logical room scaled up with nearest filtering.

const W := 320
const H := 180

func build() -> void:
	_clear()
	_bg()
	_window()
	_floor_tiles()
	_cubicle()
	_desk()
	_crt()
	_lamp()
	_sticky()
	_drawer()
	_coworker()
	_exit_sign()

func _clear() -> void:
	for c in get_children():
		c.queue_free()

func _rect(pos: Vector2, size: Vector2, color: Color, z: int = 0) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = z
	add_child(r)
	return r

func _bg() -> void:
	_rect(Vector2.ZERO, Vector2(W, H), Color(0.04, 0.05, 0.09), -10)
	# Back wall paneling stripes (pixel office).
	for i in 16:
		var shade := 0.07 + (i % 2) * 0.015
		_rect(Vector2(i * 20, 0), Vector2(20, 110), Color(shade, shade + 0.02, shade + 0.06), -9)

func _window() -> void:
	_rect(Vector2(214, 18), Vector2(88, 52), Color(0.02, 0.03, 0.08), -8)
	_rect(Vector2(218, 22), Vector2(80, 44), Color(0.05, 0.08, 0.18), -7)
	# City night dots.
	for i in 12:
		var x := 222 + (i * 17) % 72
		var y := 26 + (i * 11) % 36
		_rect(Vector2(x, y), Vector2(2, 2), Color(0.85, 0.55, 0.2, 0.7), -6)
	_rect(Vector2(218, 44), Vector2(80, 2), Color(0.1, 0.14, 0.28), -6)
	_rect(Vector2(256, 22), Vector2(2, 44), Color(0.1, 0.14, 0.28), -6)

func _floor_tiles() -> void:
	for y in range(110, H, 10):
		for x in range(0, W, 16):
			var c := Color(0.08, 0.09, 0.12) if ((x / 16) + (y / 10)) % 2 == 0 else Color(0.06, 0.07, 0.1)
			_rect(Vector2(x, y), Vector2(16, 10), c, -8)

func _cubicle() -> void:
	_rect(Vector2(12, 48), Vector2(6, 70), Color(0.18, 0.2, 0.28), -5)
	_rect(Vector2(12, 48), Vector2(140, 6), Color(0.2, 0.22, 0.32), -5)
	_rect(Vector2(146, 48), Vector2(6, 70), Color(0.18, 0.2, 0.28), -5)
	# Fabric partition noise strips.
	for i in 8:
		_rect(Vector2(20 + i * 15, 54), Vector2(12, 4), Color(0.25, 0.18, 0.22), -4)

func _desk() -> void:
	_rect(Vector2(28, 98), Vector2(120, 10), Color(0.22, 0.16, 0.12), 0)
	_rect(Vector2(32, 108), Vector2(8, 28), Color(0.16, 0.12, 0.1), 0)
	_rect(Vector2(136, 108), Vector2(8, 28), Color(0.16, 0.12, 0.1), 0)
	_rect(Vector2(40, 92), Vector2(70, 6), Color(0.12, 0.1, 0.09), 1) # keyboard shelf

func _crt() -> void:
	_rect(Vector2(52, 58), Vector2(52, 40), Color(0.12, 0.12, 0.14), 1)
	_rect(Vector2(56, 62), Vector2(44, 30), Color(0.02, 0.08, 0.06), 2)
	_rect(Vector2(60, 68), Vector2(28, 3), Color(0.2, 0.95, 0.55), 3)
	_rect(Vector2(60, 74), Vector2(20, 2), Color(0.15, 0.7, 0.4), 3)
	_rect(Vector2(60, 80), Vector2(24, 2), Color(0.15, 0.7, 0.4), 3)
	_rect(Vector2(72, 98), Vector2(12, 4), Color(0.1, 0.1, 0.12), 1)

func _lamp() -> void:
	_rect(Vector2(118, 70), Vector2(4, 28), Color(0.35, 0.35, 0.4), 1)
	_rect(Vector2(112, 64), Vector2(16, 8), Color(0.9, 0.75, 0.35), 2)
	_rect(Vector2(114, 72), Vector2(12, 10), Color(0.95, 0.85, 0.45, 0.25), 0)

func _sticky() -> void:
	_rect(Vector2(108, 86), Vector2(18, 14), Color(0.92, 0.86, 0.35), 2)
	_rect(Vector2(110, 90), Vector2(14, 2), Color(0.2, 0.18, 0.1), 3)
	_rect(Vector2(110, 94), Vector2(10, 2), Color(0.2, 0.18, 0.1), 3)

func _drawer() -> void:
	_rect(Vector2(88, 108), Vector2(36, 22), Color(0.18, 0.14, 0.11), 1)
	_rect(Vector2(102, 116), Vector2(8, 4), Color(0.45, 0.4, 0.3), 2)

func _coworker() -> void:
	# Silhouette at hall edge — face never fully loads.
	_rect(Vector2(248, 70), Vector2(28, 60), Color(0.05, 0.06, 0.1), 1)
	_rect(Vector2(254, 58), Vector2(16, 16), Color(0.08, 0.09, 0.14), 2)
	_rect(Vector2(257, 64), Vector2(3, 3), Color(0.9, 0.12, 0.1), 3) # left eye
	_rect(Vector2(266, 64), Vector2(3, 3), Color(0.9, 0.12, 0.1), 3) # right eye
	_rect(Vector2(252, 88), Vector2(20, 8), Color(0.1, 0.12, 0.2), 2) # badge glow blue
	_rect(Vector2(256, 90), Vector2(12, 3), Color(0.2, 0.4, 1.0, 0.7), 3)

func _exit_sign() -> void:
	_rect(Vector2(176, 20), Vector2(28, 12), Color(0.05, 0.25, 0.12), 1)
	_rect(Vector2(178, 22), Vector2(24, 8), Color(0.15, 0.85, 0.35), 2)
