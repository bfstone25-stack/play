extends Node
## Trailer footage: plays Night 1 for real (the scripted player, real game code) under the
## movie writer and HOLDS on the moments a trailer needs, printing a CUE line with the frame
## number for each, so ops/promo/elena_trailer.py can cut by frame. Then two adult CGs from
## the gallery, cued as adult_* (only the 18+ cut uses them).
##   xvfb-run godot --rendering-driver vulkan --write-movie out/frames.avi --fixed-fps 30 \
##       --path . res://tests/trailer.tscn
var main
var held := {}
var frame0 := 0


func cue(tag: String, secs: float) -> void:
	print("CUE %s %d %.2f" % [tag, Engine.get_frames_drawn() - frame0, secs])
	await get_tree().create_timer(secs).timeout


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(900.0).timeout.connect(func(): print("TRAILER TIMEOUT"); get_tree().quit(2))
	frame0 = Engine.get_frames_drawn()
	Loc.set_lang("en")
	RPG.persist["gallery"] = []
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	main.auto = true
	add_child(main)
	main.event.auto_mode = true
	main.shot_hook = hook
	main.stop_after = "night1"
	main.show_title()
	await cue("title", 4.0)
	RPG.new_game()
	await main.start_night("night1")
	await cue("room_study", 3.0)
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	var seen := {"study": true}
	while not ("night1" in RPG.s["nights_cleared"]) and steps < 600:
		steps += 1
		var h = sim._next_hotspot()
		if h == null:
			break
		await main.on_hotspot(h)
		var rid := str(RPG.s["room"])
		if not seen.has(rid) and "night1" not in RPG.s["nights_cleared"]:
			seen[rid] = true
			await get_tree().create_timer(0.3).timeout
			await cue("room_" + rid, 2.5)
	main.show_map()
	await cue("map", 2.5)
	main._clear_overlay()
	main.show_title()
	await cue("title_end", 4.0)
	for id in ["cg_climax_pact", "cg_trust7_bath"]:
		main._view_cg(id)
		await cue("adult_" + id, 3.0)
		main._clear_overlay()
	sim.free()
	print("TRAILER DONE")
	get_tree().quit()


func hook(tag: String) -> void:
	var hold := {"night_card": 3.0, "battle": 3.5, "battle_pressured": 2.5, "battle_boss": 3.5,
		"levelup": 3.0, "dialogue": 3.0, "dialogue2": 3.0, "choice": 2.5, "night_end": 3.0}
	if tag.begins_with("cg_"):
		await get_tree().create_timer(0.6).timeout
		await cue(tag, 3.5)
	elif hold.has(tag) and not held.has(tag):
		held[tag] = true
		await get_tree().create_timer(0.3).timeout
		await cue(tag, hold[tag])
