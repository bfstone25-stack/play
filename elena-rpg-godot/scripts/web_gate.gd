## The web edition's sponsor gate at each night boundary (game.json "night_hook").
## Off the web (the DLsite download) it returns at once: no page, no ad, no call out.
##
## On the web it hands over to window.ElenaGate (web/elena_rpg_gate.js) and waits. The page
## decides; this side only waits for "ok". There is deliberately no other answer: if the
## sponsor cannot load, the page shows the ad-blocker wall with Retry and the game does
## not continue until a sponsor has actually been seen for the full slot.
extends RefCounted


func before_night(main, nid: String) -> void:
	if not OS.has_feature("web"):
		return
	if int(JavaScriptBridge.eval("(window.ElenaGate && window.ElenaGate.start) ? 1 : 0")) != 1:
		return   # a local page without the gate script (dev run); the ad build always has it
	var key := "night_" + nid
	JavaScriptBridge.eval("window.ElenaGate.start(%s); 0" % JSON.stringify(key))
	var tree: SceneTree = main.get_tree()
	tree.paused = true
	while true:
		await tree.create_timer(0.4, true, false, true).timeout
		var r = JavaScriptBridge.eval("window.ElenaGate.result(%s)" % JSON.stringify(key))
		if str(r) == "ok":
			break
	tree.paused = false
