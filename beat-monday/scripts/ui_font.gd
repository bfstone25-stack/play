extends RefCounted
class_name UiFont

## Pixel atlas for Latin. CJK/Kana/Hangul use the bitmap subset when present,
## then a system face that actually exists (never a packed Web TTF).

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
	var sys_cjk := _system_cjk()
	if sys_cjk:
		extras.append(sys_cjk)
	if not OS.has_feature("web"):
		var path := _os_cjk_file()
		if path != "":
			var ttf := FontFile.new()
			if ttf.load_dynamic_font(path) == OK:
				extras.append(ttf)
	composed.fallbacks = extras
	_face = composed
	return _face

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())

static func _system_cjk() -> Font:
	var f := SystemFont.new()
	f.allow_system_fallback = true
	f.font_names = PackedStringArray([
		"WenQuanYi Micro Hei", "文泉驛微米黑", "文泉驿微米黑",
		"Droid Sans Fallback",
		"Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
		"Noto Sans SC", "Noto Sans JP", "Noto Sans KR",
		"Source Han Sans SC", "Source Han Sans",
		"Microsoft YaHei", "PingFang SC", "Hiragino Sans GB",
		"Hiragino Sans", "Yu Gothic", "Malgun Gothic",
		"Apple SD Gothic Neo", "SimSun", "sans-serif",
	])
	return f

static func _os_cjk_file() -> String:
	for path in [
		"/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
		"/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf",
		"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
		"/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
		"C:/Windows/Fonts/msyh.ttc",
		"/System/Library/Fonts/PingFang.ttc",
	]:
		if FileAccess.file_exists(path):
			return path
	return ""
