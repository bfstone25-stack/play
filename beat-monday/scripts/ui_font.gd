extends RefCounted
class_name UiFont

## Pixel atlas for Latin + a CJK bitmap subset. Missing glyphs (Hangul, ñ)
## load from OS/res FontFile paths — never a packed-Web TTF theme, and never
## a Latin SystemFont with allow_system_fallback (Across the Hall tofu).

static var _face: Font

static func refresh() -> void:
	_face = null

static func face() -> Font:
	if _face:
		return _face
	var latin: Font = load("res://assets/pixel/floor13_font.fnt")
	var composed: Font = latin.duplicate()
	var extras: Array[Font] = []
	if ResourceLoader.exists("res://assets/pixel/floor13_cjk.fnt"):
		extras.append(load("res://assets/pixel/floor13_cjk.fnt"))
	for path in _font_files():
		var ttf := FontFile.new()
		if ttf.load_dynamic_font(path) == OK:
			extras.append(ttf)
	if OS.has_feature("web"):
		extras.append(_web_cjk())
	composed.fallbacks = extras
	_face = composed
	return _face

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())

static func _web_cjk() -> Font:
	var f := SystemFont.new()
	f.allow_system_fallback = true
	f.font_names = PackedStringArray([
		"Noto Sans CJK KR", "Malgun Gothic", "Apple SD Gothic Neo",
		"Noto Sans CJK SC", "Noto Sans CJK JP", "Microsoft YaHei",
		"PingFang SC", "Hiragino Sans", "Yu Gothic", "sans-serif",
	])
	return f

static func _font_files() -> Array[String]:
	var out: Array[String] = []
	for path in [
		OS.get_environment("HOME").path_join(".local/share/fonts/NanumGothic.ttf"),
		"/usr/share/fonts/truetype/nanum/NanumGothic.ttf",
		"/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf",
		"/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
		"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
		"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
		"C:/Windows/Fonts/malgun.ttf",
		"C:/Windows/Fonts/msyh.ttc",
		"/System/Library/Fonts/AppleSDGothicNeo.ttc",
		"/System/Library/Fonts/PingFang.ttc",
	]:
		if path.begins_with("res://"):
			if FileAccess.file_exists(path):
				out.append(path)
		elif FileAccess.file_exists(path):
			out.append(path)
	return out
