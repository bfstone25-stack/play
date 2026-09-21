## Game — the autoload that owns what persists: the profile (level, skills, equipment,
## party, rant combo, week/day), the language, telemetry, and the web dev bridge the
## headless screenshot run drives. No loop logic here: that is BMCore.
extends Node

const SAVE := "user://aftersix.json"
## en -> zh -> ja -> en. ja is here because this title sells on DLsite, where 507 of the
## 581 works we scraped are Japanese (STANDARD.md item 7). Every key is translated in
## BMStrings.JA and the font pack carries a Noto Sans CJK JP subset for it.
const LANGS := ["en", "zh", "ja"]

var profile: Dictionary = BMCore.new_profile()
var lang := "en"
var persist_enabled := true
var bridge_handler: Callable = Callable()
var board_offered := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()
	lang = _detect_lang()


func _process(_dt: float) -> void:
	_poll_bridge()


# ---------- persistence -------------------------------------------------------------------
func load_profile() -> void:
	profile = BMCore.new_profile()
	if not FileAccess.file_exists(SAVE):
		return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var p = data.get("beatMonday")
	if typeof(p) == TYPE_DICTIONARY and p.has("role"):
		for k in p.keys():
			profile[k] = p[k]
		# JSON turns ints into floats; the core wants ints where the JS had ints
		for k in ["week", "day", "level", "xp"]:
			profile[k] = int(profile[k])
	if data.has("lang") and str(data["lang"]) in LANGS:
		lang = str(data["lang"])


func save() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"beatMonday": profile, "lang": lang}))


func reset() -> void:
	profile = BMCore.new_profile()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)


func set_lang(code: String) -> void:
	lang = code if code in LANGS else "en"
	save()


func _detect_lang() -> String:
	if lang != "en":
		return lang
	var loc := OS.get_locale_language()
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("(navigator.language||'en').toLowerCase()")
		if r != null:
			loc = str(r)
	return "zh" if loc.begins_with("zh") else "en"


# ---------- telemetry: the page's TEL SDK (stamped in by ops/godot_build.sh) ------------
func tel(name: String, value: Dictionary = {}) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.TEL&&TEL.ev&&TEL.ev(%s,%s)" % [JSON.stringify(name), JSON.stringify(value)])


func tel_play_start(meta: Dictionary) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.TEL&&TEL.play_start&&TEL.play_start(%s)" % JSON.stringify(meta))


func tel_play_end(meta: Dictionary, dur: int) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.TEL&&TEL.play_end&&TEL.play_end(%s,%d)" % [JSON.stringify(meta), dur])


## The cross-promotion board, once per session, after a day ends. Offered, never forced.
func offer_board() -> void:
	if board_offered:
		return
	board_offered = true
	# an adult title: the adult catalogue; board.js refuses to draw it off the adult hosts
	Gate.board_offer_more("adult")


# ---------- web dev bridge (tests/headless_web.py) ---------------------------------------
## The run pushes JSON commands onto window.__bm_cmd; the main scene answers through
## bridge_handler and the result lands in window.__bm_result / window.__bm_state. Every
## command is something a thumb can also do, plus "simulate", which steps the same core
## faster than real time so five days fit in a screenshot run.
func _poll_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("(function(){var q=window.__bm_cmd||[];if(!q.length)return '';var c=q.shift();return JSON.stringify(c);})()")
	if raw == null or str(raw) == "":
		return
	var cmd = JSON.parse_string(str(raw))
	if typeof(cmd) != TYPE_DICTIONARY:
		return
	var out := {"ok": false, "why": "no_handler"}
	if bridge_handler.is_valid():
		out = bridge_handler.call(cmd)
	out["seq"] = cmd.get("seq", 0)
	var state: Dictionary = bridge_handler.call({"op": "state"}) if bridge_handler.is_valid() else {}
	JavaScriptBridge.eval("window.__bm_result=%s;window.__bm_state=%s" % [JSON.stringify(out), JSON.stringify(state)])
