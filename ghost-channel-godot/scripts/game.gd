## Game — the autoload that owns everything the rules do not: the save, the language, the
## telemetry beacon, and which screen is up.
##
## GCRules is pure and static; this is the only place that persists anything or talks to the
## page. Keeping the split exact is what lets tests/run_tests.gd replay 300 recorded games
## against the rules with no engine state at all.
extends Node

signal lang_changed(lang: String)
signal screen_changed(name: String)

const SAVE_PATH := "user://ghost-channel.cfg"

var lang := "en"
var wins := 0
var best := {}                      # "op1" -> score
var current := ""                   # the screen on top


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	lang = _detect_lang()


# ---- the save ---------------------------------------------------------------------------
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	wins = int(cfg.get_value("save", "wins", 0))
	var b = cfg.get_value("save", "best", {})
	best = b if b is Dictionary else {}
	var l = cfg.get_value("save", "lang", "")
	if str(l) in GCStrings.LANGS:
		lang = str(l)
		_lang_forced = true


var _lang_forced := false


func persist() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "wins", wins)
	cfg.set_value("save", "best", best)
	cfg.set_value("save", "lang", lang)
	cfg.save(SAVE_PATH)


func best_for(op_id: int) -> int:
	return int(best.get("op" + str(op_id), 0))


func returning_player() -> bool:
	return wins > 0 or not best.is_empty()


# ---- language ----------------------------------------------------------------------------
## The prototype's detect(): a saved choice wins, then the browser/OS locale, then en.
## en, zh and ja ship in this build; es and pt exist in the prototype's i18n.js but are not
## pulled into the port, so they fall back to en rather than silently drawing English under
## a Spanish flag. Never offer a language whose pack you have not checked -- STANDARD item 7.
func _detect_lang() -> String:
	if _lang_forced:
		return lang
	var l := OS.get_locale().to_lower()
	if l.begins_with("zh"):
		return "zh"
	if l.begins_with("ja"):
		return "ja"
	return "en"


func set_lang(next: String) -> void:
	if next == lang or not (next in GCStrings.LANGS):
		return
	lang = next
	_lang_forced = true
	persist()
	tel("lang", {"lang": lang})
	lang_changed.emit(lang)


func t(key: String, vars: Dictionary = {}) -> String:
	return GCStrings.t(lang, key, vars)


# ---- telemetry ---------------------------------------------------------------------------
## The page's TEL beacon (shared/telemetry.py, injected by ops/godot_build.sh). Reachable
## from a wasm export only through JavaScriptBridge, and absent on desktop and in the
## editor, so every call is a no-op there rather than an error.
func tel(name: String, value: Dictionary = {}) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.TEL && TEL.ev(%s, %s)" % [JSON.stringify(name), JSON.stringify(value)])


func note_screen(name: String) -> void:
	current = name
	tel("screen", {"screen": name})
	screen_changed.emit(name)
