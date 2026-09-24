## locale_cover.gd — every offered language covers every string, or the build fails.
##
##   godot --headless --path . -s res://tests/locale_cover.gd
##
## Added 2026-09-23 with zh and ja. ops/STANDARD.md item 7: never offer a language that is
## not genuinely translated. A key present with an English value is not a translation, so
## this checks CONTENT: every story source has a value, the value is not the source, and it
## contains the script it claims to be in (CJK for zh, kana or CJK for ja).
extends SceneTree

func _init() -> void:
	var src: Array = JSON.parse_string(FileAccess.get_file_as_string("res://locale/_source_story_en.json"))
	var ui_src: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://locale/_source_ui_en.json"))
	var bad := 0
	for code in Loc.ALLOWED:
		if code == "en":
			continue
		var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://locale/story_%s.json" % code))
		var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://locale/%s.json" % code))
		var miss := 0
		for s in src:
			var v := str(story.get(s, ""))
			if v == "" or v == s or not _in_script(v, code):
				miss += 1
		var uimiss := 0
		for k in ui_src.keys():
			if not ui.has(k) or str(ui[k]) == "":
				uimiss += 1
		print("%s: story %d/%d  ui %d/%d" % [code, src.size() - miss, src.size(), ui_src.size() - uimiss, ui_src.size()])
		bad += miss + uimiss
	if bad > 0:
		push_error("LOCALE_COVER_FAIL %d missing" % bad)
		quit(1)
		return
	print("LOCALE_COVER_OK")
	quit(0)


func _in_script(v: String, code: String) -> bool:
	for i in v.length():
		var c := v.unicode_at(i)
		if code == "ja" and ((c >= 0x3040 and c <= 0x30ff) or (c >= 0x4e00 and c <= 0x9fff)):
			return true
		if code == "zh" and c >= 0x4e00 and c <= 0x9fff:
			return true
	return false
