extends SceneTree

const WORDS_PER_MINUTE := 180.0
const HOTSPOT_SCAN_SECONDS := 4.0
const DECISION_SECONDS := 15.0

func _init() -> void:
	var started_at := Time.get_ticks_msec()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Node = game.get_node("HUD")
	hud.title_panel.visible = false
	game.start_game()
	await _read_dialogue(hud)
	var decisions := {"breakroom": "TRUST", "server": "REFUSE", "lobby": "STAIRS", "manager": "RESIGN"}
	for area_index in 7:
		var area: Dictionary = StoryData.AREAS[area_index]
		await create_timer(3.0).timeout
		for hotspot in area.hotspots:
			await create_timer(HOTSPOT_SCAN_SECONDS).timeout
			game._on_hotspot(hotspot[0])
			await _read_dialogue(hud)
		if area.has("choice"):
			await create_timer(DECISION_SECONDS).timeout
			game._on_choice(decisions[area.id])
			await _read_dialogue(hud)
		await create_timer(2.0).timeout
		game._on_route()
		await _read_dialogue(hud)
	var elapsed_minutes := float(Time.get_ticks_msec() - started_at) / 60000.0
	print("FIRST_READ_OK ending=", game.ending_id, " elapsed_minutes=", snapped(elapsed_minutes, 0.01), " pace_wpm=", WORDS_PER_MINUTE, " hotspots=", game.completed_hotspots.size())
	if game.ending_id != "CLOCK_OUT" or elapsed_minutes < 25.0 or elapsed_minutes > 35.0:
		push_error("first-read production gate failed")
		quit(1)
	else:
		quit(0)

func _read_dialogue(hud: Node) -> void:
	while hud.dialogue_panel.visible:
		var words: int = hud.body_label.text.replace("\n", " ").split(" ", false).size()
		await create_timer(max(1.5, float(words) / WORDS_PER_MINUTE * 60.0)).timeout
		hud._advance_dialogue()
		await process_frame
