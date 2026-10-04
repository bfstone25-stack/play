extends Node
## Autoload "Loc": every on-screen string comes from a table keyed by id with one column per
## language (EN JA DE FR ES ZH KO). A missing cell falls back to English, so adding a
## language is filling a column, never touching code.
## Tables: res://addons/night_rpg/strings_core.json (menus, battle) + res://data/strings.json.

signal language_changed

const LANGS := ["en", "ja", "de", "fr", "es", "zh", "ko"]
const LANG_NAMES := {"en": "English", "ja": "日本語", "de": "Deutsch", "fr": "Français", "es": "Español", "zh": "中文", "ko": "한국어"}

var lang := "en"
var table: Dictionary = {}


func _ready() -> void:
	for p in ["res://addons/night_rpg/strings_core.json", "res://data/strings.json"]:
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for k in d.keys():
				table[k] = d[k]
	# first launch: follow the OS language when we have it (a Japanese buyer starts in Japanese)
	if not RPG.persist.has("lang_chosen"):
		var os_lang := OS.get_locale_language()
		RPG.persist["lang"] = os_lang if os_lang in LANGS and coverage(os_lang) > 0.9 else "en"
	lang = str(RPG.persist.get("lang", "en"))
	_apply_locale()


func set_lang(l: String) -> void:
	lang = l
	RPG.persist["lang"] = l
	RPG.persist["lang_chosen"] = true
	RPG.save_persist()
	_apply_locale()
	language_changed.emit()


## The text server shapes and line-breaks by the locale (CJK breaks between ideographs, Hangul
## and Latin at spaces) and picks the right CJK glyph forms; the skin re-orders font fallbacks.
func _apply_locale() -> void:
	TranslationServer.set_locale({"zh": "zh_CN", "ko": "ko_KR", "ja": "ja_JP"}.get(lang, lang))
	NRSkin.apply_lang(lang)


func t(key: String) -> String:
	var row = table.get(key)
	if row == null:
		return key
	if row is String:
		return row
	var v = row.get(lang, "")
	if v == "" or v == null:
		v = row.get("en", key)
	return str(v)


func has(key: String) -> bool:
	return table.has(key)


## Fraction of the table filled for a language (settings shows it; the check script asserts it).
func coverage(l: String) -> float:
	var n := 0
	var have := 0
	for k in table.keys():
		if table[k] is Dictionary:
			n += 1
			if str(table[k].get(l, "")) != "":
				have += 1
	return float(have) / max(1, n)


## A ported VN line: {"en": ..., "ja": ...}.
func line(ln: Dictionary) -> String:
	var v = ln.get(lang, "")
	if v == "" or v == null:
		v = ln.get("en", "")
	return str(v)


func menu(en: String) -> String:
	if lang == "en":
		return en
	var v = RPG.menus.get(en, {}).get(lang, "")
	return en if v == "" else str(v)
