extends RefCounted
class_name UiFont

## Midnight Pawn path: one complete BMFont per size, assigned as FontFile.
## No packed TTF, no SystemFont, no Latin-only face first. WebGL cannot
## bind a browser fallback, and a Latin BMFont draws .notdef instead of
## falling through — that is the Floor 13 乱码 path.

const BodyFont = preload("res://assets/fonts/floor13_pixel_12.fnt")
const DisplayFont = preload("res://assets/fonts/floor13_pixel_16.fnt")


static func body() -> Font:
	return BodyFont


static func display() -> Font:
	return DisplayFont


static func face() -> Font:
	return BodyFont


static func refresh() -> void:
	pass


static func apply_label(l: Label, use_display := false) -> void:
	l.add_theme_font_override("font", DisplayFont if use_display else BodyFont)
	l.add_theme_font_size_override("font_size", 16 if use_display else 12)
	l.clip_text = false


static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", BodyFont)
	b.add_theme_font_size_override("font_size", 12)
	b.clip_text = false


static func apply_theme(node: Control) -> void:
	var theme := Theme.new()
	theme.default_font = BodyFont
	theme.default_font_size = 12
	node.theme = theme
