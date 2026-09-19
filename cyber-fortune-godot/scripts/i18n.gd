extends Node
## Tx autoload — the locale loader. Copy lives in pool/ui.json (zh-Hans, en); the
## scenes call Tx.t("key", {vars}). Default follows the player's locale, as
## play/cyber-merit's i18n.js does: zh for a zh-* system, en otherwise.

signal changed

var lang := "en"
var _ui: Dictionary = {}


func _ready() -> void:
	_ui = _load_json("res://pool/ui.json")
	var loc := OS.get_locale()
	if OS.has_feature("web"):
		var nav = JavaScriptBridge.eval("navigator.language || ''")
		if nav != null:
			loc = str(nav)
	lang = "zh" if loc.begins_with("zh") else "en"


static func _load_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("missing " + path)
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if v != null else {}


func set_lang(code: String) -> void:
	lang = "zh" if code.begins_with("zh") else "en"
	changed.emit()


func t(key: String, vars: Dictionary = {}) -> String:
	var entry = _ui.get(key)
	var s: String
	if typeof(entry) == TYPE_DICTIONARY:
		s = str(entry.get(lang, entry.get("en", key)))
	else:
		s = key
	for k in vars:
		s = s.replace("{" + str(k) + "}", str(vars[k]))
	return s


## A {"zh": .., "en": ..} pair from the pools.
func pick(pair) -> String:
	if typeof(pair) != TYPE_DICTIONARY:
		return str(pair)
	return str(pair.get(lang, pair.get("en", "")))


## A record with <field>_zh / <field>_en.
func field(rec: Dictionary, field_name: String) -> String:
	return str(rec.get(field_name + "_" + lang, rec.get(field_name + "_en", "")))


func minutes(ms: int) -> String:
	var m := int(ceil(ms / 60000.0))
	if m >= 60:
		return t("time.hr", {"n": int(ceil(m / 60.0))})
	return t("time.min", {"n": maxi(m, 1)})
