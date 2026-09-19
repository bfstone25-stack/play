## Game — the autoload that owns what persists: the run state (Kernel's dictionary), the
## language, the settings, telemetry, and the web dev bridge the headless screenshot run
## drives. No rules here: those are Kernel and Idle.
##
## Save shape matches the JS build's `rebound.tycoon.v2` key so the two are talking about
## the same thing, plus `lastSeen` for the offline gate the JS never had.
extends Node

const SAVE := "user://rebound-tycoon.json"
const LANGS := ["en", "zh"]
const FREE_NIGHTS := 3   # dual-track (ops/DUAL_TRACK.md): nights 1-3 free, later behind the gate

var st: Dictionary = Kernel.new_state()
var lang := "en"
var sound := true
## Reduced motion. Three states, not two: "auto" asks the platform every time it is read
## (the OS switch in GNOME/macOS/Windows, `prefers-reduced-motion` in the browser), and
## "on"/"off" are the player overriding that from the booth menu. Auto is the default so
## that a player who has already told their system stops having to tell us as well.
const MOTION_PREFS := ["auto", "on", "off"]
var motion_pref := "auto"
var best_coins := 0
var last_seen := 0           # ms; 0 = never played
var persist_enabled := true
var bridge_handler: Callable = Callable()
var board_offered := false
var pending_return: Dictionary = {}   # the offline settlement waiting to be shown
var started := false

## The RNG the kernel draws from. Seedable so tests and the headless run are repeatable.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	load_save()
	lang = _detect_lang()


func _process(_dt: float) -> void:
	_poll_bridge()


func rng() -> Callable:
	return func() -> float: return _rng.randf()


func seed_rng(s: int) -> void:
	_rng.seed = s
	_rng.state = s


func now_ms() -> int:
	return Time.get_unix_time_from_system() * 1000 as int


# ---------- persistence -------------------------------------------------------------------
func load_save() -> void:
	st = Kernel.new_state()
	if not FileAccess.file_exists(SAVE):
		return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	st = Kernel.hydrate(data.get("run"))
	if data.has("lang") and str(data["lang"]) in LANGS:
		lang = str(data["lang"])
	sound = bool(data.get("sound", true))
	if str(data.get("motion", "auto")) in MOTION_PREFS:
		motion_pref = str(data["motion"])
	best_coins = int(data.get("bestCoins", 0))
	last_seen = int(data.get("lastSeen", 0))
	started = bool(data.get("started", false))
	# The gate kept collecting. Worked out here, shown by the return screen, claimed by
	# the player — never silently added, because a number you did not watch arrive is a
	# number you do not believe.
	var settled := Idle.settle(st, last_seen, now_ms())
	if int(settled["coins"]) > 0:
		pending_return = settled


func save() -> void:
	if not persist_enabled:
		return
	last_seen = now_ms()
	best_coins = maxi(best_coins, int(st["lifetime"]))
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"run": Kernel.snapshot(st, last_seen), "lang": lang, "sound": sound,
		"bestCoins": best_coins, "lastSeen": last_seen, "started": started,
		"motion": motion_pref,
	}))


func reset() -> void:
	st = Kernel.new_state()
	started = false
	pending_return = {}
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)


# ---------- reduced motion ----------------------------------------------------------------
## What the platform itself says. Godot 4.5+ exposes the desktop switch through
## DisplayServer; the web export's DisplayServer does not answer for the browser, so the
## page's own media query is asked there. Wrapped in has_method because the call is newer
## than some of the export templates this project has been built with.
func platform_reduce_motion() -> bool:
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("(window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) ? 1 : 0")
		return int(r) == 1 if r != null else false
	if DisplayServer.has_method("accessibility_should_reduce_animation"):
		return bool(DisplayServer.call("accessibility_should_reduce_animation"))
	return false


## The answer every screen asks for. Read it, do not cache it: on "auto" the player can
## flip the OS switch while the game is open and the next frame should already be calm.
func reduce_motion() -> bool:
	match motion_pref:
		"on":
			return true
		"off":
			return false
		_:
			return platform_reduce_motion()


## Cycles auto -> on -> off -> auto, which is the only honest shape for a tri-state: a
## two-way toggle cannot say "whatever my system says".
func cycle_motion() -> void:
	var i := MOTION_PREFS.find(motion_pref)
	motion_pref = MOTION_PREFS[(i + 1) % MOTION_PREFS.size()]
	tel("motion", {"pref": motion_pref, "reduced": reduce_motion()})
	save()


func set_lang(code: String) -> void:
	lang = code if code in LANGS else "en"
	tel("language", {"lang": lang})
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


func has_progress() -> bool:
	return started or int(st["lifetime"]) > 0 or int(st["night"]) > 1


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


## The cross-promotion board, once per session, when the night ends. Offered, never forced.
## "casual" explicitly: this is a mainstream title and the adult catalogue must never be
## asked for from an AdSense host (ops/check_adsense_isolation.py).
func offer_board() -> void:
	if board_offered:
		return
	board_offered = true
	Gate.board_offer_more("casual")


# ---------- web dev bridge (tests/headless_web.py) ---------------------------------------
## The run pushes JSON commands onto window.__rt_cmd; the main scene answers through
## bridge_handler and the result lands in window.__rt_result / window.__rt_state. Every
## command is something a thumb can also do, plus "clock", which moves the offline gate's
## idea of "when you left" so eight hours of away time fit inside a screenshot run.
func _poll_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("(function(){var q=window.__rt_cmd||[];if(!q.length)return '';var c=q.shift();return JSON.stringify(c);})()")
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
	JavaScriptBridge.eval("window.__rt_result=%s;window.__rt_state=%s" % [JSON.stringify(out), JSON.stringify(state)])
