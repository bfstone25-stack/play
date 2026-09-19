## Tel — telemetry bootstrap. Autoloaded as "Tel".
##
## ops/godot_build.sh injects the shared SDK (shared/telemetry.py's TELEMETRY_JS) into the
## exported page and sets window.TEL_APP / window.TEL_API, so on the web there is already
## a window.TEL by the time the engine boots. This forwards to it, the way
## play/beat-monday-godot/scripts/game.gd does, and does nothing at all off the web.
##
## The event names are the web build's names, unchanged — intro_shown, intro_closed,
## game_started, level_opened, move_made, level_completed, result_shared,
## language_selected — because itch-analytics already has months of them under those keys
## and renaming them on the port would make the two builds uncomparable at exactly the
## moment there is something to compare.
##
## Memory note `itch-telemetry-blind-spots`: the failure mode here is silence that looks
## like success. `booted()` reports whether a window.TEL was actually found, tests assert
## it, and tests/headless_web.py checks the events land in window.__tel_sent rather than
## trusting that calling the function meant anything.
extends Node

var _web := false
var _booted := false
var _started_at := 0


func _ready() -> void:
	_web = OS.has_feature("web")
	_started_at = Time.get_ticks_msec()
	if not _web:
		return
	# A page without the SDK (a local harness, an itch build mid-upload) must never brick
	# the game; it just means no events. Record which it was.
	_booted = int(JavaScriptBridge.eval("(window.TEL && window.TEL.ev) ? 1 : 0", true)) == 1
	# a test hook the headless driver reads: every event, in order, as it is sent
	JavaScriptBridge.eval("window.__tel_sent = window.__tel_sent || [];", true)


func booted() -> bool:
	return _booted


func ev(name: String, value = null) -> void:
	if not _web:
		return
	var payload := JSON.stringify(value if value != null else {})
	JavaScriptBridge.eval("window.__tel_sent && window.__tel_sent.push([%s,%s]);"
		% [JSON.stringify(name), payload], true)
	if not _booted:
		return
	JavaScriptBridge.eval("window.TEL && TEL.ev && TEL.ev(%s,%s)" % [JSON.stringify(name), payload], true)


func play_start(meta: Dictionary = {}) -> void:
	_started_at = Time.get_ticks_msec()
	if _web and _booted:
		JavaScriptBridge.eval("window.TEL && TEL.play_start && TEL.play_start(%s)" % JSON.stringify(meta), true)


func play_end(meta: Dictionary = {}) -> void:
	if _web and _booted:
		var dur := int((Time.get_ticks_msec() - _started_at) / 1000)
		JavaScriptBridge.eval("window.TEL && TEL.play_end && TEL.play_end(%s,%d)"
			% [JSON.stringify(meta), dur], true)


## The common envelope every FOLD event carries in the web build.
func level_ev(name: String, extra: Dictionary = {}) -> void:
	var d := {"language": I18n.lang, "level": Fold.level_index + 1,
		"group": "curated" if Fold.level_index < Fold.CURATED else "endless"}
	for k in extra.keys():
		d[k] = extra[k]
	ev(name, d)
