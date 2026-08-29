extends RefCounted
class_name UiFont

## System Latin first (no allow_system_fallback). CJK/Hangul from FontFile
## paths that actually have those glyphs. Packed TTF is never the theme font.

static var _face: Font

static func refresh() -> void:
	_face = null

static func face() -> Font:
	if _face:
		return _face
	var latin := SystemFont.new()
	latin.allow_system_fallback = false
	latin.font_names = PackedStringArray(["Arial", "Helvetica", "DejaVu Sans", "Liberation Sans", "Noto Sans"])
	var extras: Array[Font] = []
	for path in _font_files():
		var ttf := FontFile.new()
		if ttf.load_dynamic_font(path) == OK:
			extras.append(ttf)
	if OS.has_feature("web"):
		extras.append(_web_cjk())
	latin.fallbacks = extras
	_face = latin
	return _face

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())

static func apply_3d(l: Label3D) -> void:
	l.font = face()

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
