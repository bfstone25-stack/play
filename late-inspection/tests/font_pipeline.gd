extends SceneTree

const BitmapFont = preload("res://assets/fonts/late_inspection_pixel_16.fnt")

func _assert_chars(text: String, label: String) -> int:
	var missing := 0
	for ch in text:
		if ch >= " " and ch != "\u007f" and not BitmapFont.has_char(ch.unicode_at(0)):
			push_error("FONT_MISSING %s U+%04X %s" % [label, ch.unicode_at(0), ch])
			missing += 1
	return missing

func _init() -> void:
	var missing := 0
	for locale in Loc.ALLOWED:
		Loc.set_code(locale)
		for key in Loc.table():
			missing += _assert_chars(str(Loc.t(str(key))), "%s:%s" % [locale, key])
	var font_source := FileAccess.get_file_as_string("res://scripts/ui_font.gd")
	if "SystemFont.new" in font_source or "load_dynamic_font" in font_source:
		push_error("FONT_PIPELINE uses a Web-unsafe runtime font source")
		missing += 1
	if missing > 0:
		quit(1)
		return
	print("FONT_PIPELINE_OK locales=%d" % Loc.ALLOWED.size())
	quit(0)
