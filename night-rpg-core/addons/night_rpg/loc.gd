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
	lang = str(RPG.persist.get("lang", "en"))


func set_lang(l: String) -> void:
	lang = l
	RPG.persist["lang"] = l
	RPG.save_persist()
	language_changed.emit()


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
