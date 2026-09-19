## Api — the HTTP client to play/silvertongue-cards/backend (autoload "Api").
##
## Identity is the parent's scheme (silvertongue-x app.py): a `pid` the client mints once
## and keeps, sent as ?pid= on GETs and as "pid" in every POST body; the backend resolves
## an account cookie (`stc_session`) over it when one is present. On the web the pid is
## the same localStorage key the HTML prototype used (`stc_pid`), so a player who moves
## from the prototype page to this build keeps their collection. On desktop it lives in
## user://identity.cfg.
##
## Base URL: the prototype's config.js rule. On the web, a foreign host (itch, Nutaku)
## talks to the gateway path; anything else talks to its own origin, which is what the
## dev server in tools/serve_web.py provides. On desktop, `--api=<url>` on the command
## line or $ST_CARDS_API, else the backend's default port.
##
## There is no model behind this game: the parent's typed-duel endpoint is not reachable
## from here, and no path in this file calls one.
extends Node

signal economy_changed(economy: Dictionary)
signal request_failed(path: String, error: String)

const GATEWAY := "https://apps.blazecore.dev/silvertongue-cards"
const LOCAL := "http://127.0.0.1:8929"
const TIMEOUT := 12.0

var base_url := ""
var pid := ""
var last_economy := {}
var inflight := 0
var _textures := {}                     # path -> Texture2D, plates fetched once


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_url = _resolve_base()
	pid = _resolve_pid()


func _resolve_base() -> String:
	if OS.has_feature("web"):
		var js := """(function(){var h=location.hostname||"";var off=location.protocol==="file:"||/itch\\.zone$/i.test(h)||/\\.itch\\.io$/i.test(h)||/nutaku/i.test(h);return off?%s:location.origin;})()""" % JSON.stringify(GATEWAY)
		var r = JavaScriptBridge.eval(js)
		return str(r) if r != null and str(r) != "" else GATEWAY
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--api="):
			return a.substr(6)
	var env := OS.get_environment("ST_CARDS_API")
	return env if env != "" else LOCAL


func _resolve_pid() -> String:
	if OS.has_feature("web"):
		var js := """(function(){try{var p=localStorage.getItem("stc_pid");if(!p){p=Math.random().toString(36).slice(2)+Date.now().toString(36);localStorage.setItem("stc_pid",p);}return p;}catch(e){return "";}})()"""
		var r = JavaScriptBridge.eval(js)
		if r != null and str(r) != "":
			return str(r)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pid="):
			return a.substr(6)
	var cfg := ConfigFile.new()
	if cfg.load("user://identity.cfg") == OK:
		var p := str(cfg.get_value("identity", "pid", ""))
		if p != "":
			return p
	var fresh := "%s%x" % [_rand_token(10), int(Time.get_unix_time_from_system())]
	cfg.set_value("identity", "pid", fresh)
	cfg.save("user://identity.cfg")
	return fresh


static func _rand_token(n: int) -> String:
	const A := "abcdefghijklmnopqrstuvwxyz0123456789"
	var s := ""
	for _i in n:
		s += A[randi() % A.length()]
	return s


## Swap identity at runtime — the tests use a fresh pid per run so a player's real
## collection is never touched.
func set_pid(p: String) -> void:
	pid = p


# --- transport -----------------------------------------------------------------------------
func _request(method: int, path: String, body: Variant = null) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	http.accept_gzip = true
	add_child(http)
	var url := base_url + path
	var headers := PackedStringArray(["Accept: application/json"])
	var data := ""
	if method == HTTPClient.METHOD_POST:
		var b: Dictionary = body if body != null else {}
		b["pid"] = pid
		data = JSON.stringify(b)
		headers.append("Content-Type: application/json")
	else:
		url += ("&" if "?" in path else "?") + "pid=" + pid.uri_encode()
	inflight += 1
	var err := http.request(url, headers, method, data)
	if err != OK:
		inflight -= 1
		http.queue_free()
		request_failed.emit(path, "request error %d" % err)
		return {"error": "network: could not start request"}
	var res: Array = await http.request_completed
	inflight -= 1
	http.queue_free()
	var result := int(res[0])
	var code := int(res[1])
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit(path, "result %d" % result)
		return {"error": "network: no answer from the backend"}
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit(path, "bad json (%d)" % code)
		return {"error": "network: bad answer (%d)" % code}
	if code >= 400 and not parsed.has("error"):
		parsed["error"] = "backend %d: %s" % [code, str(parsed.get("detail", ""))]
	if parsed.has("economy") and typeof(parsed["economy"]) == TYPE_DICTIONARY:
		last_economy = parsed["economy"]
		economy_changed.emit(last_economy)
	return parsed


func get_json(path: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, path)


func post_json(path: String, body: Dictionary = {}) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, path, body)


# --- the endpoints, by name ---------------------------------------------------------------
func health() -> Dictionary:
	return await get_json("/cards/health")

func state() -> Dictionary:
	return await get_json("/cards/state")

func deck(scenario: String, auto: bool = false) -> Dictionary:
	return await get_json("/cards/deck?scenario=%s%s" % [scenario.uri_encode(), "&auto=1" if auto else ""])

func save_deck(scenario: String, ids: Array) -> Dictionary:
	return await post_json("/cards/deck", {"scenario": scenario, "deck": ids})

func start(scenario: String, difficulty: String, daily: bool = false) -> Dictionary:
	return await post_json("/cards/start", {"scenario": scenario, "difficulty": difficulty, "daily": daily})

func play(card: String, text: String = "") -> Dictionary:
	return await post_json("/cards/play", {"card": card, "text": text})

func forfeit() -> Dictionary:
	return await post_json("/cards/forfeit", {})

func daily() -> Dictionary:
	return await get_json("/cards/daily")

func pull(n: int) -> Dictionary:
	return await post_json("/cards/pull", {"n": n})

func affection() -> Dictionary:
	return await get_json("/cards/affection")

func dev_gold(amount: int = 1000) -> Dictionary:
	return await post_json("/cards/dev/gold", {"amount": amount})

func dev_energy() -> Dictionary:
	return await post_json("/cards/dev/energy", {})

func register(handle: String, password: String) -> Dictionary:
	return await post_json("/cards/auth/register", {"handle": handle, "password": password})

func login(handle: String, password: String) -> Dictionary:
	return await post_json("/cards/auth/login", {"handle": handle, "password": password})

func me() -> Dictionary:
	return await get_json("/cards/auth/me")


# --- plates ---------------------------------------------------------------------------------
## The parent's rendered plates are served by the backend at /assets/cg/<key>.png and are
## never in this package (art ceiling: the client only ever shows what the ladder earned).
func plate_texture(key: String) -> Texture2D:
	var path := "/assets/cg/%s.png" % key
	if _textures.has(path):
		return _textures[path]
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT * 2
	add_child(http)
	var err := http.request(base_url + path)
	if err != OK:
		http.queue_free()
		return null
	var res: Array = await http.request_completed
	http.queue_free()
	if int(res[0]) != HTTPRequest.RESULT_SUCCESS or int(res[1]) != 200:
		return null
	var img := Image.new()
	if img.load_png_from_buffer(res[3]) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_textures[path] = tex
	return tex
