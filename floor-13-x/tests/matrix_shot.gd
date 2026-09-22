## matrix_shot.gd — HOLDOVER's stage matrix, shot from inside the engine.
##
##   godot --rendering-driver opengl3 res://tests/matrix_shot.tscn
##
## ops/play_driver.py is the house harness and it drives the WEB build through Chromium
## on the GPU box. That is still the reference measurement. This exists because on
## 2026-09-21 the GPU box stopped answering ssh and local browser launches are blocked on
## purpose (chrome-headless-shell refuses: "local browser tests are disabled on this
## machine"), which left no way at all to re-shoot and therefore no way to prove anything
## — and ops/STANDARD.md is explicit that "I changed the code" is not evidence.
##
## It photographs the same thing the web driver photographs: the frames the player is
## actually shown, in order, nothing discarded. ops/play_matrix.py then decides which are
## distinct, exactly as it does for a browser run — it only ever reads s*.png from a
## directory, so the frames are written with the same names.
##
## What it does NOT prove, and the report has to say so: that the WEB export boots and
## reaches these stages in a browser. Only the Chromium run proves that.
extends Node

const OUT := "user://matrix"

var game: Node
var hud: Node
var n := 0
var dir := ""


func _shot(label: String) -> void:
	for _f in 4:
		RenderingServer.force_draw()
		await get_tree().process_frame
	var img := get_tree().root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		printerr("EMPTY CAPTURE at ", label, " — no GL context; run with --rendering-driver opengl3")
		get_tree().quit(3)
		return
	var path := "%s/s%02d_%s.png" % [dir, n, label]
	img.save_png(path)
	print("SHOT s%02d_%s  %dx%d" % [n, label, img.get_width(), img.get_height()])
	n += 1


func _ready() -> void:
	dir = ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	for f in (DirAccess.get_files_at(dir) if DirAccess.dir_exists_absolute(dir) else []):
		DirAccess.remove_absolute(dir + "/" + f)
	await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	hud = game.get_node("HUD")

	# The title, twice. s00b_idle is the matrix's own noise floor: whatever moves between
	# the two with no input is this game's attract loop (the breathing camera and the
	# tube), and a click has to beat that to count as a stage. Without it the title's
	# flicker alone would register as progress. See ops/play_matrix.py.
	await _shot("title")
	for _f in 40:
		await get_tree().process_frame
	var img := get_tree().root.get_viewport().get_texture().get_image()
	img.save_png("%s/s00b_idle.png" % dir)

	hud.title_panel.visible = false
	game.start_game()
	await get_tree().process_frame

	# One decided route through the night, so the run is reproducible: trust Eli, refuse
	# Compliance, take the stairs, resign. That route opens CG slots rather than closing
	# them (reporting Eli shuts three), so the gallery has something in it at the end.
	var route := {"eli_stance": "TRUST", "compliance": "REFUSE", "escape_route": "STAIRS", "contract": "RESIGN"}
	var area := -1
	var guard := 0
	var cgs := 0
	while guard < 20000 and n < 40:
		guard += 1
		await get_tree().process_frame
		if game.area_index != area:
			area = game.area_index
			await _shot("area_%d" % area)
			continue
		if hud.cg_root.visible:
			await _shot("cg_%d" % cgs)
			cgs += 1
			hud._close_cg()
			continue
		if hud.ending_panel.visible:
			await _shot("ending")
			break
		if hud.choice_panel.visible:
			await _shot("choice_%d" % area)
			var a: Dictionary = game._areas()[game.area_index]
			hud._pick(0 if str(a.choice.a[1]) == str(route.get(str(a.choice.id), "")) else 1)
			continue
		if hud.is_line_open():
			hud._advance_dialogue()
			continue
		var clicked := false
		for hotspot in game._areas()[game.area_index].hotspots:
			var id := str(hotspot[0])
			if game.completed_hotspots.has("%s/%s" % [game._areas()[game.area_index].id, id]):
				continue
			game._on_hotspot(id)
			clicked = true
			break
		if clicked:
			continue
		if hud.route_button.visible:
			hud.route_requested.emit()
			continue
		break

	# The gallery is a stage too — it is the surface the whole fork is built around.
	if hud.has_method("show_gallery"):
		while hud.is_line_open():
			hud._advance_dialogue()
			await get_tree().process_frame
		hud.show_gallery()
		await _shot("gallery")

	print("MATRIX frames=%d dir=%s" % [n, dir])
	get_tree().quit(0)
