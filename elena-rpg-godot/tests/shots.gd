extends Node
## Screenshot run: plays Night 1 with the scripted player and saves what a reviewer must
## see -- title, night card, a room, the map, a battle, a level-up, a CG -- then the same
## key screens in Japanese. Needs a real renderer (not --headless):
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --path . res://tests/shots.tscn -- --out=shots/run
## Prints the render device so a CPU fallback is visible (memory: xvfb-godot-renders-on-cpu).

var main
var out := "res://shots/run"
var taken := {}
var lang := "en"


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_video_adapter_vendor(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(600.0).timeout.connect(func():
		print("SHOTS TIMEOUT")
		get_tree().quit(2))
	await get_tree().process_frame
	RPG.persist["gallery"] = []
	await run_lang("en", true)
	await run_lang("ja", false)
	print("SHOTS: ", JSON.stringify(taken.keys()))
	get_tree().quit()


func _path(tag: String) -> String:
	var base := ProjectSettings.globalize_path(out) if out.begins_with("res://") else out
	return "%s/%s_%s.png" % [base, lang, tag]


func snap(tag: String) -> void:
	var key := lang + "_" + tag
	if taken.has(key):
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_path(tag))
	taken[key] = _path(tag)
	print("shot ", _path(tag))


func hook(tag: String) -> void:
	if tag.begins_with("cg_"):
		await get_tree().create_timer(0.8).timeout
		var e = main.event
		print("CGDBG ", tag, " ev.vis=", e.visible, " ev.size=", e.size, " ev.pos=", e.global_position, " cg.vis=", e.cg.visible, " cg.size=", e.cg.size, " cg.tex=", e.cg.texture, " cg.mod=", e.cg.modulate, " in_tree=", e.is_visible_in_tree())
		await snap(tag)
	elif tag in ["battle", "levelup", "night_card", "choice"]:
		await snap(tag)


func run_lang(l: String, full: bool) -> void:
	lang = l
	Loc.set_lang(l)
	if main != null:
		main.queue_free()
		await get_tree().process_frame
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	main.auto = true
	add_child(main)
	main.event.auto_mode = true
	main.shot_hook = hook
	main.stop_after = "night1"
	main.show_title()
	await get_tree().create_timer(1.5).timeout
	await snap("title")
	main.show_settings()
	await get_tree().create_timer(0.3).timeout
	await snap("settings")
	RPG.new_game()
	await main.start_night("night1")
	await get_tree().create_timer(1.0).timeout
	await snap("room_study")
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	while not ("night1" in RPG.s["nights_cleared"]) and steps < 200:
		steps += 1
		var h = sim._next_hotspot()
		if h == null:
			break
		await main.on_hotspot(h)
		if RPG.s["room"] == "stair" and not taken.has(lang + "_room_stair"):
			await get_tree().create_timer(0.8).timeout
			await snap("room_stair")
		if RPG.s["room"] == "stacks" and not taken.has(lang + "_map"):
			main.show_map()
			await get_tree().create_timer(0.4).timeout
			await snap("map")
			main.render_room()
		if not full and taken.has(lang + "_battle") and taken.has(lang + "_map"):
			break
	if full:
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery")
	sim.free()
