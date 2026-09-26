class_name Tel
## PORT_PLAN.md step 5 -- telemetry parity with the web build. The shared SDK
## (shared/telemetry.py TELEMETRY_JS, stamped into the page by ops/godot_build.sh) already
## records pageview/arrive/engaged/session_end and everything gate.js and board.js send.
## What the canvas cannot give it is the page's own named calls, so they go through here
## with the SAME names and payload shapes as frontend/index.html:
##   TEL.chat(msg, reply, {route, aff})     index.html:1725
##   TEL.ev("select_shown", ...)             index.html:1939
##   TEL.ev("gate_passed", {via, phase})     index.html:1947
## intro_done / opening_done arrive with step 6 (the intro and opening are not ported).
## A desktop build, or a page without the SDK, is a no-op -- never an error.


static func _ok() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("!!(window.TEL && window.TEL.ev)"))


static func ev(name: String, value: Variant = "") -> void:
	if _ok():
		JavaScriptBridge.eval("window.TEL.ev(%s, %s); void 0" % [JSON.stringify(name), JSON.stringify(value)])


static func chat(msg: String, reply: String, meta: Dictionary) -> void:
	if _ok():
		JavaScriptBridge.eval("window.TEL.chat(%s, %s, %s); void 0" % [JSON.stringify(msg), JSON.stringify(reply), JSON.stringify(meta)])
