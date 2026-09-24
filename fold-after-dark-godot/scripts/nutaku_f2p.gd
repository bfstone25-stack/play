extends Node
## COPIED from shared/godot/nutaku_f2p.gd by ops/nutaku/fold_f2p/build_web.sh — edit it there.
## Nutaku F2P client for Godot 4 — reusable. Autoload it as "Nutaku".
##
## Copied into each title as res://scripts/nutaku_f2p.gd (like shared/godot/gate.gd);
## edit it HERE, in shared/godot/, and copy. Nothing in this file knows which game it is.
##
## Two halves:
##   * the platform: NutakuGI (login handshake, createPayment, getQuickUserInfo), reached
##     through JavaScriptBridge on the web. On Nutaku, NutakuGI lives in the parent page
##     and shared/nutaku_bridge.js installs a Promise-shaped shim in our frame.
##   * our server: ops/nutaku/f2p/economy.py (/f2p/*) and gateway/nutaku.py (/nutaku/*).
##     The client only ASKS. Energy, tokens, progress, unlocks and days are the server's.
##
## JavaScriptBridge rule (memory: godot-js-bridge-promise): never hand eval() an
## expression whose value is a Promise. Every platform call here is: a guard eval that
## returns an int, then ONE eval whose value is the number 0 and whose side effect parks
## the Promise's result, JSON-encoded, in window.__nkf[slot]; then we poll that slot.
##
## Desktop/headless test path: `-- --nutaku-mock=http://127.0.0.1:8995
## --nutaku-api=http://127.0.0.1:8994 --nutaku-user=<id>` makes the same three platform
## calls straight to ops/nutaku/mock_platform.py over HTTP, so the whole client can be
## driven without a browser. Nothing sets these in a shipped build.

signal state_changed(state: Dictionary)
signal busy_changed(busy: bool)

var active := false          # true on the platform (or the mock path); false = inert
var api_base := ""
var session := ""
var user_id := ""
var nickname := ""
var state: Dictionary = {}
var catalog: Array = []
var last_error := ""
## Where refresh() reads the whole state. A title whose economy lives under its own
## router (Overtime: /ot/state) sets this once after boot; the default is the shared one.
var state_path := "/f2p/state"

var _mock_base := ""
var _booted := false
var _booting := false
var _seq := 0


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	if args.has("nutaku-mock") and args.has("nutaku-api"):
		_mock_base = str(args["nutaku-mock"]).trim_suffix("/")
		api_base = str(args["nutaku-api"]).trim_suffix("/")
		user_id = str(args.get("nutaku-user", "desktop-test"))
		active = true
		return
	if OS.has_feature("web"):
		var has_gi = JavaScriptBridge.eval("(window.NutakuGI && typeof window.NutakuGI.startHandshake === 'function') ? 1 : 0", true)
		if int(has_gi) == 1:
			active = true
			var base = JavaScriptBridge.eval("String(window.NUTAKU_F2P_API || '')", true)
			api_base = str(base).trim_suffix("/")


# ---------------------------------------------------------------------------- boot

## Handshake with the platform, then log in to our server. Safe to call repeatedly.
func boot() -> bool:
	if not active:
		return false
	if _booted:
		return true
	while _booting:
		await get_tree().process_frame
		if _booted:
			return true
	_booting = true
	var ok := await _boot()
	_booting = false
	_booted = ok
	return ok


func _boot() -> bool:
	var info := await _gi("getQuickUserInfo", [])
	if info.has("id"):
		user_id = str(info["id"])
		nickname = str(info.get("nickname", ""))
	var hs := await _gi("startHandshake", [])
	if int(hs.get("game_rc", 0)) != 200:
		last_error = "handshake: " + str(hs.get("message", hs.get("error", "no answer")))
		return false
	var msg = JSON.parse_string(str(hs.get("message", "")))
	if typeof(msg) != TYPE_DICTIONARY or not msg.has("sessionId"):
		last_error = "handshake: no session in the game server's answer"
		return false
	session = str(msg["sessionId"])
	var r := await api("POST", "/f2p/login", {"nickname": nickname})
	if not r["ok"]:
		last_error = "login: " + str(r["body"].get("reason", r["status"]))
		return false
	var c := await api("GET", "/nutaku/catalog")
	if c["ok"]:
		catalog = c["body"].get("skus", [])
	return true


# ------------------------------------------------------------------------- our API

## {ok, status, body}. Adds the session to every call; adopts any `state` it returns.
func api(method: String, path: String, body: Dictionary = {}) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var url := api_base + path
	var err: int
	busy_changed.emit(true)
	if method == "GET":
		url += ("&" if "?" in url else "?") + "session=" + session.uri_encode()
		err = http.request(url)
	else:
		var b := body.duplicate()
		b["session"] = session
		err = http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(b))
	if err != OK:
		http.queue_free()
		busy_changed.emit(false)
		return {"ok": false, "status": 0, "body": {"reason": "request failed"}}
	var res: Array = await http.request_completed
	http.queue_free()
	busy_changed.emit(false)
	var code := int(res[1])
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	var out: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	if out.has("state") and typeof(out["state"]) == TYPE_DICTIONARY:
		state = out["state"]
		state_changed.emit(state)
	return {"ok": code == 200 and bool(out.get("ok", code == 200)), "status": code, "body": out}


func refresh() -> Dictionary:
	var r := await api("GET", state_path)
	return state


func bytes(path: String) -> PackedByteArray:
	var http := HTTPRequest.new()
	add_child(http)
	var url := api_base + path + ("&" if "?" in path else "?") + "session=" + session.uri_encode()
	if http.request(url) != OK:
		http.queue_free()
		return PackedByteArray()
	var res: Array = await http.request_completed
	http.queue_free()
	return res[3] if int(res[1]) == 200 else PackedByteArray()


func start_level(level: int) -> Dictionary:
	return await api("POST", "/f2p/level/start", {"level": level})


func finish_level(attempt_id: String, actions: String, moves: int) -> Dictionary:
	return await api("POST", "/f2p/level/finish", {"attempt_id": attempt_id, "actions": actions, "moves": moves})


func fail_level(attempt_id: String) -> Dictionary:
	return await api("POST", "/f2p/level/fail", {"attempt_id": attempt_id})


func use_item(attempt_id: String, item: String, actions: String = "") -> Dictionary:
	return await api("POST", "/f2p/use", {"attempt_id": attempt_id, "item": item, "actions": actions})


func claim_daily() -> Dictionary:
	return await api("POST", "/f2p/daily/claim")


func claim_mission(slot: int) -> Dictionary:
	return await api("POST", "/f2p/mission/claim", {"slot": slot})


func claim_bonus() -> Dictionary:
	return await api("POST", "/f2p/mission/claim", {"bonus": true})


func leaderboard() -> Dictionary:
	return await api("GET", "/f2p/leaderboard")


func sku(id: String) -> Dictionary:
	for s in catalog:
		if str(s.get("skuId", "")) == id:
			return s
	return {}


## Buy a SKU with Nutaku gold. The platform shows its own confirm, charges the gold, and
## calls our payment handler, which delivers inside its own transaction; we then re-read
## the state. Returns {status: "success"|"cancel"|"errorFromGPHS"|"error", ...}.
func buy(sku_id: String) -> Dictionary:
	var s := sku(sku_id)
	if s.is_empty():
		return {"status": "error", "error": "unknown sku"}
	var obj := {"skuId": sku_id, "name": str(s.get("name", "")), "price": int(s.get("price", 0)),
		"imgUrl": str(s.get("imgUrl", "")), "description": str(s.get("description", "")),
		"message": str(s.get("message", ""))}
	var r := await _gi("createPayment", [obj])
	await refresh()
	if r.has("error"):
		return {"status": "error", "error": str(r["error"])}
	return r


# ----------------------------------------------------------------- the platform

## Call a NutakuGI method; returns its resolved value as a Dictionary.
func _gi(method: String, args: Array) -> Dictionary:
	if _mock_base != "":
		return await _gi_mock(method, args)
	if not OS.has_feature("web"):
		return {"error": "not on the web"}
	var guard = JavaScriptBridge.eval("(window.NutakuGI && typeof window.NutakuGI[%s] === 'function') ? 1 : 0" % JSON.stringify(method), true)
	if int(guard) != 1:
		return {"error": "NutakuGI.%s missing" % method}
	_seq += 1
	var slot := "s%d" % _seq
	# Value of this eval is 0, never the Promise.
	JavaScriptBridge.eval("""
		window.__nkf = window.__nkf || {};
		window.__nkf[%s] = '';
		Promise.resolve(window.NutakuGI[%s].apply(window.NutakuGI, %s)).then(
			function (r) { window.__nkf[%s] = JSON.stringify(r === undefined ? {} : r); },
			function (e) { window.__nkf[%s] = JSON.stringify({error: String(e)}); });
		0;
	""" % [JSON.stringify(slot), JSON.stringify(method), JSON.stringify(args), JSON.stringify(slot), JSON.stringify(slot)], true)
	var waited := 0.0
	while waited < 120.0:      # a payment dialog can sit open while the player thinks
		var v = JavaScriptBridge.eval("String((window.__nkf && window.__nkf[%s]) || '')" % JSON.stringify(slot), true)
		if str(v) != "":
			JavaScriptBridge.eval("delete window.__nkf[%s]; 0;" % JSON.stringify(slot), true)
			var parsed = JSON.parse_string(str(v))
			return parsed if typeof(parsed) == TYPE_DICTIONARY else {"value": parsed}
		await get_tree().create_timer(0.05).timeout
		waited += 0.05
	return {"error": "timeout"}


## The desktop test path: the same three calls, answered by mock_platform.py directly.
func _gi_mock(method: String, args: Array) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var err: int
	match method:
		"getQuickUserInfo":
			err = http.request(_mock_base + "/mock/quickUserInfo?userId=" + user_id.uri_encode())
		"startHandshake":
			err = http.request(_mock_base + "/mock/handshake", ["Content-Type: application/json"],
				HTTPClient.METHOD_POST, JSON.stringify({"userId": user_id}))
		"createPayment":
			err = http.request(_mock_base + "/mock/createPayment", ["Content-Type: application/json"],
				HTTPClient.METHOD_POST, JSON.stringify({"userId": user_id, "paymentObject": args[0], "confirm": true}))
		_:
			http.queue_free()
			return {"error": "unknown method"}
	if err != OK:
		http.queue_free()
		return {"error": "request failed"}
	var res: Array = await http.request_completed
	http.queue_free()
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {"error": "bad answer"}
