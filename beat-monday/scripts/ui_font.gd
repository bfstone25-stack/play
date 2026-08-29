extends RefCounted
class_name UiFont

## Hard-edged, Web-safe bitmap face generated with the authored pixel assets.

static func face() -> Font:
	return load("res://assets/pixel/floor13_font.fnt")

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())
