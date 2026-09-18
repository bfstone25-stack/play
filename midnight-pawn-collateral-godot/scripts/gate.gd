## Gate.gd — dual-track unlock gate for the Godot web exports (ops/DUAL_TRACK.md).
##
## Autoload as "Gate". At a cut point:
##     if await Gate.require("ch2", "Chapter 2"):
##         _advance_to_chapter_2()
##
## On the web it hands the decision to gate.js on the page (a price on itch, a sponsor
## clip on free.blazecore.dev) and waits for the answer; on desktop (the paid download)
## everything is open and it returns true at once.
extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # the gate keeps ticking while the tree is paused

func is_web() -> bool:
	return OS.has_feature("web")

func has(key: String) -> bool:
	if not is_web():
		return true
	var r = JavaScriptBridge.eval("(window.Gate && window.Gate.has(%s)) ? 1 : 0" % JSON.stringify(key))
	return int(r) == 1

func require(key: String, title: String, kind: String = "chapter") -> bool:
	if not is_web():
		return true
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return true  # page without gate.js (local test): never brick the game
	if has(key):
		return true
	var js = """
		window.__gate = window.__gate || {};
		window.__gate[%s] = "";
		window.Gate.require(%s, {title: %s, kind: %s}).then(function (r) { window.__gate[%s] = r; });
	""" % [JSON.stringify(key), JSON.stringify(key), JSON.stringify(title), JSON.stringify(kind), JSON.stringify(key)]
	JavaScriptBridge.eval(js)
	var result := ""
	while result == "":
		await get_tree().create_timer(0.4).timeout
		var r = JavaScriptBridge.eval("(window.__gate && window.__gate[%s]) || ''" % JSON.stringify(key))
		result = str(r) if r != null else ""
	return result == "unlocked"

## Fire-and-forget form for places that cannot await: pauses the whole tree while the
## page shows the gate, resumes on unlock. A refusal reloads the page — the free part
## starts over, which is what "the demo ends here" means on the itch track.
func block(key: String, title: String, kind: String = "chapter") -> void:
	if not is_web() or has(key):
		return
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return
	get_tree().paused = true
	var ok := await _require_paused(key, title, kind)
	if ok:
		get_tree().paused = false
	else:
		JavaScriptBridge.eval("location.reload()")

func _require_paused(key: String, title: String, kind: String) -> bool:
	var js = """
		window.__gate = window.__gate || {};
		window.__gate[%s] = "";
		window.Gate.require(%s, {title: %s, kind: %s}).then(function (r) { window.__gate[%s] = r; });
	""" % [JSON.stringify(key), JSON.stringify(key), JSON.stringify(title), JSON.stringify(kind), JSON.stringify(key)]
	JavaScriptBridge.eval(js)
	var result := ""
	while result == "":
		await get_tree().create_timer(0.4, true, false, true).timeout   # runs while paused
		var r = JavaScriptBridge.eval("(window.__gate && window.__gate[%s]) || ''" % JSON.stringify(key))
		result = str(r) if r != null else ""
	return result == "unlocked"
