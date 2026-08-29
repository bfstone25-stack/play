extends SceneTree

## Slice builds end after File 2 (elevator lobby). Full builds continue
## into the break room and beyond.

func _drain(hud: Node) -> void:
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
		await process_frame


func _play_area(game: Node, hud: Node, index: int) -> void:
	var area: Dictionary = StoryData.live()[index]
	for hotspot in area.hotspots:
		game._on_hotspot(hotspot[0])
		await _drain(hud)


func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	game.SLICE = true
	game.start_game()
	await _drain(hud)
	await _play_area(game, hud, 0)
	game._on_route()
	await _drain(hud)
	if game.area_index != 1:
		push_error("slice: expected to reach area 1, got %d" % game.area_index)
		quit(1)
		return
	await _play_area(game, hud, 1)
	game._on_route()
	await _drain(hud)
	await process_frame
	if game.ending_id != "SLICE":
		push_error("slice: expected SLICE ending, got %s (area %d)" % [game.ending_id, game.area_index])
		quit(1)
		return
	if not hud.ending_panel.visible:
		push_error("slice: ending card panel not visible")
		quit(1)
		return
	print("SLICE_GATE_OK card=", hud.ending_label.text.left(40))
	quit(0)


func _init() -> void:
	call_deferred("_run")
