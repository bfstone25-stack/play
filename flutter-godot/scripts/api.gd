extends Node

## Api — the HTTP client to play/flutter/backend (autoload "Api").
##
## Same shape as play/silvertongue-cards-godot/scripts/api.gd: base_url resolves
## web-vs-desktop the same way frontend/config.js does, pid persists across sessions the
## same way. The one thing that file does not need and this one does is a hand-rolled SSE
## reader — /say_stream is a chunked `text/event-stream` body, and HTTPRequest buffers the
## whole response before returning it, which defeats the entire point of streaming (the
## first token in ~2s that PORT_PLAN.md calls out as the fix for "feels frozen"). So the
## reply is read with HTTPClient, driven a chunk at a time from this coroutine.
##
## Per PORT_PLAN.md: "the backend does not move." Every call here hits the same FastAPI
## routes the HTML build hits (backend/app.py) — nothing about /routes, /say_stream or
## /story/{route} changes on this side.

const GATEWAY := "https://apps.blazecore.dev/flutter"
const LOCAL := "http://127.0.0.1:8919"
const TIMEOUT := 20.0
const STALL_TIMEOUT_MS := 60000  ## no bytes at all for 60s on an open stream = give up

var base_url := ""
var pid := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_url = _resolve_base()
	pid = _resolve_pid()


func _resolve_base() -> String:
	if OS.has_feature("web"):
		var js := """(function(){var h=location.hostname||"";var off=location.protocol==="file:"||/itch\\.zone$/i.test(h)||/\\.itch\\.io$/i.test(h);return off?%s:location.origin+"/flutter";})()""" % JSON.stringify(GATEWAY)
		var r = JavaScriptBridge.eval(js)
		return str(r) if r != null and str(r) != "" else GATEWAY
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--api="):
			return a.substr(6)
	var env := OS.get_environment("FLUTTER_API")
	return env if env != "" else GATEWAY


func _resolve_pid() -> String:
	if OS.has_feature("web"):
		# Same key the HTML build reads (index.html: pid()), so a player who later moves
		# to this build on the same browser keeps talking to the same server-side memory.
		var js := """(function(){try{var p=localStorage.getItem("flutter_pid");if(!p){p=Math.random().toString(36).slice(2)+Date.now().toString(36);localStorage.setItem("flutter_pid",p);}return p;}catch(e){return "";}})()"""
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


# --- plain JSON GET (routes, story info) ----------------------------------------------------
func get_json(path: String) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var err := http.request(base_url + path)
	if err != OK:
		http.queue_free()
		return {"error": "request error %d" % err}
	var res: Array = await http.request_completed
	http.queue_free()
	if int(res[0]) != HTTPRequest.RESULT_SUCCESS:
		return {"error": "network: no answer from the backend"}
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "bad json (%d)" % int(res[1])}
	return parsed


func routes(lang: String = "en") -> Dictionary:
	return await get_json("/routes?lang=%s" % lang.uri_encode())


func story_info(route_id: String) -> Dictionary:
	return await get_json("/story/%s" % route_id.uri_encode())


# --- streaming /say_stream --------------------------------------------------------------------
## Calls on_token.call(text) as each fragment of the reply arrives, and returns the final
## `done` record once the stream closes (reply/affection/mood/milestone/story/... — see
## backend/app.py's say_stream). `{"error": "..."}` on any failure: a connect/TLS error, a
## stall, or a stream that closes without ever sending a `done` record.
func say_stream(payload: Dictionary, on_token: Callable) -> Dictionary:
	var parts := _split_url(base_url + "/say_stream")
	if parts.is_empty():
		return {"error": "bad base url: %s" % base_url}

	var client := HTTPClient.new()
	var tls: TLSOptions = TLSOptions.client() if parts.scheme == "https" else null
	var err := client.connect_to_host(parts.host, parts.port, tls)
	if err != OK:
		return {"error": "connect failed (%d)" % err}

	while client.get_status() in [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING]:
		client.poll()
		await get_tree().process_frame
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"error": "could not connect (status %d)" % client.get_status()}

	var body := JSON.stringify(payload)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: text/event-stream",
		"Host: " + parts.host,
	])
	err = client.request(HTTPClient.METHOD_POST, parts.path, headers, body)
	if err != OK:
		return {"error": "request failed (%d)" % err}

	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
	if client.get_status() not in [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]:
		return {"error": "bad status after request: %d" % client.get_status()}

	var code := client.get_response_code()
	var buf := PackedByteArray()
	var done_payload := {}
	var got_done := false
	var last_byte_ms := Time.get_ticks_msec()

	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() == 0:
			if Time.get_ticks_msec() - last_byte_ms > STALL_TIMEOUT_MS:
				return {"error": "stream stalled (no data for %ds)" % (STALL_TIMEOUT_MS / 1000)}
			await get_tree().process_frame
			continue
		last_byte_ms = Time.get_ticks_msec()
		buf.append_array(chunk)
		while true:
			var idx := _find_bytes(buf, "\n\n".to_utf8_buffer())
			if idx == -1:
				break
			var record := buf.slice(0, idx)
			buf = buf.slice(idx + 2)
			var line := record.get_string_from_utf8().strip_edges()
			if not line.begins_with("data:"):
				continue  # ": ping" keepalive comment line
			var parsed = JSON.parse_string(line.substr(5).strip_edges())
			if typeof(parsed) != TYPE_DICTIONARY:
				continue
			if parsed.get("done", false):
				done_payload = parsed
				got_done = true
			elif parsed.has("token"):
				on_token.call(str(parsed["token"]))

	if not got_done:
		if code != 200 and code != 0:
			return {"error": "backend %d" % code}
		return {"error": "stream closed with no reply"}
	return done_payload


static func _find_bytes(hay: PackedByteArray, needle: PackedByteArray) -> int:
	var n := needle.size()
	if n == 0 or hay.size() < n:
		return -1
	for i in range(hay.size() - n + 1):
		var match_here := true
		for j in range(n):
			if hay[i + j] != needle[j]:
				match_here = false
				break
		if match_here:
			return i
	return -1


## Splits "https://host[:port]/path" into {scheme, host, port, path}. Empty dict on a URL
## this cannot parse — callers treat that as a hard failure rather than guessing a host.
static func _split_url(url: String) -> Dictionary:
	var scheme_end := url.find("://")
	if scheme_end == -1:
		return {}
	var scheme := url.substr(0, scheme_end)
	var rest := url.substr(scheme_end + 3)
	var slash := rest.find("/")
	var host_port := rest if slash == -1 else rest.substr(0, slash)
	var path := "/" if slash == -1 else rest.substr(slash)
	var host := host_port
	var port := 443 if scheme == "https" else 80
	var colon := host_port.rfind(":")
	if colon != -1:
		host = host_port.substr(0, colon)
		port = int(host_port.substr(colon + 1))
	if host == "":
		return {}
	return {"scheme": scheme, "host": host, "port": port, "path": path}
