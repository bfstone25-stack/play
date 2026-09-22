extends Node
## Tx autoload — the locale loader. Copy lives in pool/ui.json and the three content pools
## (night/slips/tarot, as <field>_<lang>); the scenes call Tx.t("key", {vars}). Default
## follows the player's locale, as play/cyber-merit's i18n.js does.
##
## 2026-09-21: ja joins en and zh. 507 of 581 DLsite works in ops/market/dlsite_data/ are
## Japanese and that is the shelf this fork is going on. An earlier comment here claimed
## this was already true while pool/night.json, pool/tarot.json and pool/slips.json still
## carried zero _ja fields -- caught and reverted mid-pass, then genuinely fixed:
## tools/pool_ja.py holds the Japanese layer by hand (not machine-pasted zh), and
## tools/build_pool.py's ja() helper refuses to build on a missing field or on prose with
## no kana in it (the omikuji verses are the one deliberate exception -- a four-character
## 漢語 idiom has no kana in Japanese either, same as in Chinese). Re-run
## `python3 tools/build_pool.py` after editing any *_ja source. That is the real guard
## against the Floor 13 failure (ja/ko/es whose story files held Chinese prose): a build
## step that cannot produce the fake, not a promise that nobody pasted it.

signal changed

## The order the language chip walks. The chip's label is the language you get NEXT.
const LANGS := ["en", "zh", "ja"]

var lang := "en"
var _ui: Dictionary = {}


func _ready() -> void:
	_ui = _load_json("res://pool/ui.json")
	var loc := OS.get_locale()
	if OS.has_feature("web"):
		var nav = JavaScriptBridge.eval("navigator.language || ''")
		if nav != null:
			loc = str(nav)
	lang = _normalise(loc)


## A system/browser locale, or a saved code, mapped onto the three we actually have.
static func _normalise(code: String) -> String:
	if code.begins_with("ja"):
		return "ja"
	if code.begins_with("zh"):
		return "zh"
	return "en"


static func _load_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("missing " + path)
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if v != null else {}


func set_lang(code: String) -> void:
	lang = _normalise(code)
	changed.emit()


## The chip: en -> zh -> ja -> en.
func next_lang() -> void:
	set_lang(LANGS[(LANGS.find(lang) + 1) % LANGS.size()])


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
