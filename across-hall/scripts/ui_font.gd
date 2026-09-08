extends RefCounted
class_name UiFont

## Browser-safe Latin. Do not bind a TTF as the project font on Web.

static func face() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial", "Helvetica", "Noto Sans", "DejaVu Sans", "sans-serif"])
	return f

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_3d(l: Label3D) -> void:
	l.font = face()
