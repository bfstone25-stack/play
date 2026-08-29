extends RefCounted
class_name UiFont

## Latin pixel atlas for EN/ES. CJK/Kana/Hangul come from the packed bitmap
## subset (Web-safe PNG). Browser/system FontFile is a fallback only — never
## a packed TTF theme, and never a Latin SystemFont with allow_system_fallback
## as the first face (that is the Across the Hall tofu path).

static var _face: Font

static func refresh() -> void:
	_face = null


static func face() -> Font:
	if _face:
		return _face
	var latin: Font = load("res://assets/pixel/floor13_font.fnt")
	var cjk: Font = null
	if ResourceLoader.exists("res://assets/pixel/floor13_cjk.fnt"):
		cjk = load("res://assets/pixel/floor13_cjk.fnt")
	var extras: Array[Font] = []
	# Latin-only BMFont draws .notdef for ñ/á instead of falling through.
	# Put the complete atlas first for ES and CJK locales.
	var primary: Font = latin
	if cjk and Loc.current() in ["es", "zh", "ja", "ko"]:
		primary = cjk
		extras.append(latin)
	elif cjk:
		extras.append(cjk)
	for path in _font_files():
		var ttf := FontFile.new()
		if ttf.load_dynamic_font(path) == OK:
			extras.append(ttf)
	if OS.has_feature("web"):
		var web := _web_cjk()
		if _cjk_locale():
			# WebGL will not bind a packed TTF. Put the browser face first so
			# JA/KO never sit behind a Latin-only bitmap that draws hex tofu.
			var web_extras: Array[Font] = [primary]
			web_extras.append_array(extras)
			web.fallbacks = web_extras
			_face = web
			return _face
		extras.append(web)
	var composed: Font = primary.duplicate()
	composed.fallbacks = extras
	_face = composed
	return _face


static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())
	l.clip_text = false


static func apply_button(b: Button) -> void:
	b.add_theme_font_override("font", face())
	b.clip_text = false


static func _cjk_locale() -> bool:
	return Loc.current() in ["zh", "ja", "ko"]


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
