extends RefCounted
class_name UiFont

## One project-owned Unicode BMFont atlas for every runtime label. This avoids
## the WebGL SystemFont binding path and its .notdef fallback behaviour.
const Face = preload("res://assets/fonts/late_inspection_pixel_16.fnt")

static func refresh() -> void:
	pass

static func face() -> Font:
	return Face

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", Face)
	l.add_theme_font_size_override("font_size", 16)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.clip_text = false

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", Face)
	b.add_theme_font_size_override("font_size", 16)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.clip_text = false

static func apply_3d(l: Label3D) -> void:
	l.font = Face
	l.font_size = 16
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
