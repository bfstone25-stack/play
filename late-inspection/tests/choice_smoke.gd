## KNOWN: THIS TEST HANGS. Do not spend an afternoon rediscovering it — that has now
## happened twice, most recently 2026-09-19 during the title-screen pass.
##
## It never reaches its own quit(0): run it with
##
##   $GODOT --path . -s res://tests/choice_smoke.gd
##
## and it sits forever rather than printing CHOICE_SMOKE_OK. The failure is PRE-EXISTING
## and has nothing to do with the title screen, the HUD splash or the fonts — it predates
## all of that work. The suspect is an `await process_frame` that never resolves once the
## tree is paused (scripts/gate.gd pauses it; a SceneTree script's process_frame is not
## exempt the way a PROCESS_MODE_ALWAYS node is), but that has not been confirmed.
##
## tests/vn_chrome.gd hangs the same way and is almost certainly the same bug: it is the
## other test that drives the VN chrome after hide_splash().
##
## The green set, as measured on 2026-09-19:
##   PASS  progression.gd  font_pipeline.gd  locale_scan.gd  content_audit.gd
##         title_shot.gd (five locales)
##   FAIL  smoke.gd            "expected initial inspection interaction" — the
##                             interactable group is empty at frame 3
##         document_smoke.gd   scene.active_ids on a Node3D: it reaches for the Game
##                             node and gets the scene root
##   HANG  choice_smoke.gd  vn_chrome.gd
## All five of those are PRE-EXISTING and none is about the title screen.
extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("main.tscn failed")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var game := scene
	var hud := scene.get_node("HUD")
	if hud.has_method("hide_splash"):
		hud.hide_splash()
	game.open_choice("stain", "IRIS VALE — STILL HERE", "Keep photograph", "Delete image", null)
	await process_frame
	await process_frame
	if not hud.choice_panel or not hud.choice_panel.visible:
		push_error("choice panel not visible")
		quit(2)
		return
	hud._pick(0)
	await process_frame
	await process_frame
	if not game.flags["photo_kept"] or game.stage != 5:
		push_error("expected stain choice to set evidence flag and advance")
		quit(3)
		return
	var ending_id: String = game.debug_complete_route("witness")
	if ending_id != "WITNESS":
		push_error("expected Witness route")
		quit(4)
		return
	print("CHOICE_SMOKE_OK choice_flag=", game.flags["photo_kept"], " ending=", ending_id)
	quit(0)
