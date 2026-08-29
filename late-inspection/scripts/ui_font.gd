extends RefCounted
class_name UiFont

## System fonts with CJK fallbacks. Web uses the browser face list.

static func face() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Noto Sans CJK SC", "Noto Sans SC", "Source Han Sans SC",
		"WenQuanYi Micro Hei", "Microsoft YaHei", "PingFang SC",
		"Noto Sans", "Arial", "Helvetica", "DejaVu Sans", "sans-serif",
	])
	return f

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_3d(l: Label3D) -> void:
	l.font = face()
