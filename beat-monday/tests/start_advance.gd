extends SceneTree

## Title Start must be clickable, first ADV must advance, first choice must work.

func _fail(code: int, msg: String) -> void:
	push_error(msg)
	quit(code)


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Loc.set_code("en")
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	if hud.title_panel == null or not hud.title_panel.visible:
		_fail(1, "title missing")
		return
	if hud.title_start == null or not hud.title_start.visible or hud.title_start.size.y < 44:
		_fail(2, "start button missing or too small")
		return
	if str(hud.title_start.text).strip_edges() == "":
		_fail(3, "start button has no label")
		return
	if hud.lang_buttons.size() != 5:
		_fail(4, "expected 5 language buttons, got %d" % hud.lang_buttons.size())
		return
	hud._emit_start()
	for _i in 8:
		await process_frame
	if not game.started:
		_fail(5, "start did not begin the game")
		return
	if not hud.dialogue_panel.visible:
		_fail(6, "first ADV did not open")
		return
	if hud.nvl_root.visible:
		_fail(7, "opening must be ADV not NVL")
		return
	var first: String = hud.current_line_text()
	if first == "":
		_fail(8, "first ADV line empty")
		return
	hud._advance_dialogue()
	await process_frame
	if hud.current_line_text() == first:
		_fail(9, "click/advance did not change the first ADV line")
		return
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
		await process_frame
	if hud.is_busy() and not game.get_tree().get_nodes_in_group("hotspot").size():
		_fail(10, "stuck after opening ADV")
		return
	game._on_hotspot("ticket")
	await process_frame
	if not hud.is_line_open():
		_fail(11, "hotspot inspect did not open ADV")
		return
	while hud.dialogue_panel.visible or hud.nvl_root.visible:
		hud._advance_dialogue()
		await process_frame
	game.area_index = 2
	game.pending = ""
	game.completed_hotspots.clear()
	var area: Dictionary = StoryData.live()[2]
	for hotspot in area.hotspots:
		game.completed_hotspots[game._area_key(str(hotspot[0]))] = true
	hud.show_choice(area.choice)
	await process_frame
	if not hud.choice_panel.visible:
		_fail(12, "choice panel hidden")
		return
	if hud.choice_a.size.y < 36 and hud.choice_a.custom_minimum_size.y < 36:
		_fail(13, "choice A too small for touch")
		return
	hud._pick(0)
	await process_frame
	if hud.choice_panel.visible:
		_fail(14, "choice A did not resolve")
		return
	print("START_ADVANCE_OK start=", hud.title_start.text, " langs=", hud.lang_buttons.size())
	quit(0)


func _init() -> void:
	call_deferred("_run")
