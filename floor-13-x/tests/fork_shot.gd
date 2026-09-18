## fork_shot.gd — plays to the first unlocks and photographs what the player actually sees.
##
##   godot --headless res://tests/fork_shot.tscn
##
## The assertions in fork_cg.gd prove a texture was bound. This proves a plate was
## rendered, which is the thing actually in question while the art is a placeholder: a
## plate that draws as a black rectangle passes the former and fails the player. Also
## photographs the gallery, the other surface waiting on art. Writes /tmp/floor13x-shots/.
extends Node

const OUT := "/tmp/floor13x-shots"

func _ready() -> void:
	await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(OUT)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	var route := {"eli_stance": "TRUST", "compliance": "REFUSE", "escape_route": "STAIRS", "contract": "RESIGN"}
	var shots := 0
	var guard := 0
	game.start_game()
	while guard < 4000 and shots < 2:
		guard += 1
		await get_tree().process_frame
		if hud.cg_root.visible:
			for _f in 6:
				RenderingServer.force_draw()
				await get_tree().process_frame
			var image := get_tree().root.get_viewport().get_texture().get_image()
			if image == null or image.is_empty():
				printerr("no capture for ", hud._cg_slot)
				get_tree().quit(3)
				return
			var path := "%s/%s.png" % [OUT, hud._cg_slot]
			image.save_png(path)
			print("SHOT ", hud._cg_slot, " ", image.get_width(), "x", image.get_height(), " -> ", path)
			shots += 1
			hud._close_cg()
			continue
		if hud.ending_panel.visible:
			break
		if hud.choice_panel.visible:
			var area: Dictionary = game._areas()[game.area_index]
			hud._pick(0 if str(area.choice.a[1]) == str(route.get(str(area.choice.id), "")) else 1)
			continue
		if hud.is_line_open():
			hud._advance_dialogue()
			continue
		if get_tree().get_nodes_in_group("hotspot").is_empty():
			if hud.route_button.visible:
				hud.route_requested.emit()
				continue
			break
		var clicked := false
		for hotspot in game._areas()[game.area_index].hotspots:
			var id := str(hotspot[0])
			if game.completed_hotspots.has("%s/%s" % [game._areas()[game.area_index].id, id]):
				continue
			game._on_hotspot(id)
			clicked = true
			break
		if not clicked and hud.route_button.visible:
			hud.route_requested.emit()
	# show_gallery() refuses while the HUD is busy, which it will be mid-passage. Drain the
	# open line first — that is what a player pressing through would do.
	var drain := 0
	while hud.is_line_open() and drain < 400:
		drain += 1
		hud._advance_dialogue()
		await get_tree().process_frame
	hud.show_gallery()
	for _f in 6:
		RenderingServer.force_draw()
		await get_tree().process_frame
	var gal := get_tree().root.get_viewport().get_texture().get_image()
	gal.save_png(OUT + "/gallery.png")
	print("SHOT gallery -> ", OUT, "/gallery.png")
	print("captured ", shots, " plate(s)")
	get_tree().quit(0 if shots > 0 else 4)
