class_name Coin
extends Control
## The currency glyph: a gold coin drawn in code, so it sits beside a number in any font
## without asking the fonts for a symbol they do not have.

var radius := 9.0


func _init(r: float = 9.0) -> void:
	radius = r
	custom_minimum_size = Vector2(r * 2 + 2, r * 2 + 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := Vector2(radius + 1, size.y * 0.5)
	draw_circle(c + Vector2(0, 1.5), radius, Color(0, 0, 0, 0.35))
	draw_circle(c, radius, Palette.GOLD_DEEP)
	draw_circle(c, radius * 0.82, Palette.GOLD)
	draw_arc(c, radius * 0.62, PI * 0.9, PI * 1.9, 12, Palette.GOLD_PALE, 1.6, true)
	draw_circle(c + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.2, Color(Palette.GOLD_PALE, 0.9))
