extends RefCounted
class_name UiFont

## Latin stays on the authored pixel atlas. Chinese uses a matching BMFont
## subset rasterized from WenQuanYi, falling back to the same source TTF.

static var _face: Font

static func refresh() -> void:
	_face = null

static func face() -> Font:
	if _face:
		return _face
	var latin: Font = load("res://assets/pixel/floor13_font.fnt")
	var composed: Font = latin.duplicate()
	if ResourceLoader.exists("res://assets/pixel/floor13_cjk.fnt"):
		composed.fallbacks = [load("res://assets/pixel/floor13_cjk.fnt")]
	elif ResourceLoader.exists("res://assets/fonts/wqy-microhei.ttc"):
		var ttf := FontFile.new()
		ttf.load_dynamic_font("res://assets/fonts/wqy-microhei.ttc")
		composed.fallbacks = [ttf]
	_face = composed
	return _face

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())
