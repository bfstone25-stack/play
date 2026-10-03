extends Node
## Screenshot run: plays the whole game with the scripted player and saves what a reviewer
## must see -- disclosure, title, settings, the shift card, rooms, the map, battles, a
## level-up, the party/equipment menu, the gallery, every CG -- in English and in Japanese,
## then the Japanese trial to its end screen. Needs a real renderer (not --headless):
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --path . res://tests/shots.tscn -- --out=shots/run
## Prints the render device so a CPU fallback is visible (memory: xvfb-godot-renders-on-cpu).

var main
var out := "res://shots/run"
var taken := {}
var lang := "en"
const ROOM_SHOTS := ["back_office", "bar", "service_stair", "corridor_2", "room_212", "street", "corridor4", "room_702", "linen", "roof", "manager_flat", "boiler", "laundry", "loading_bay"]


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_video_adapter_vendor(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(900.0).timeout.connect(func():
		print("SHOTS TIMEOUT")
		get_tree().quit(2))
	await get_tree().process_frame
	RPG.persist["gallery"] = []
	await run_lang("en", true)
	await run_lang("ja", true)
	RPG.trial_override = true
	lang = "ja"
	taken.erase("ja_trial_end")
	await run_lang("ja", true)
	print("SHOTS: ", JSON.stringify(taken.keys()))
	get_tree().quit()


func _path(tag: String) -> String:
	var base := ProjectSettings.globalize_path(out) if out.begins_with("res://") else out
	return "%s/%s_%s.png" % [base, lang, tag]


func snap(tag: String) -> void:
	var key := lang + "_" + tag
	if taken.has(key):
		return
	if main != null:
		main.toast_lbl.modulate.a = 0.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_path(tag))
	taken[key] = _path(tag)
	print("shot ", _path(tag))


func hook(tag: String) -> void:
	if tag.begins_with("cg_"):
		await get_tree().create_timer(0.8).timeout
		await snap(tag)
	elif tag in ["battle", "battle_boss", "levelup", "choice", "dialogue", "dialogue2", "trial_end", "loss", "the_end"] or (tag == "night_card" and str(RPG.s.get("night", "")) == "shift1"):
		await snap(tag)
	elif tag == "night_card" and str(RPG.s.get("night", "")) == "shift2":
		# the gallery as it stands after shift 1: only the safe CGs are open (the DLsite sample)
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery_early")
		main._clear_overlay()
	elif tag == "night_end":
		await snap("night_end_" + str(RPG.s["night"]))


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
	main.stop_after = "" if RPG.trial_override else "epilogue"
	main.prefer_menu = ["Ask her why", "checked in", "Sit next to her", "Stay awake with me"] if l == "en" else ["Ask her why", "checked in", "Watch the car", "Turn her away"]
	main.show_disclosure(false)
	await get_tree().create_timer(0.6).timeout
	await snap("disclosure")
	main.show_title()
	await get_tree().create_timer(1.5).timeout
	await snap("title")
	main.show_settings()
	await get_tree().create_timer(0.3).timeout
	await snap("settings")
	RPG.new_game()
	await main.start_night("shift1")
	await get_tree().create_timer(1.0).timeout
	await snap("room_lobby")
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	var last := "shift1" if RPG.trial_override else "epilogue"
	while not (last in RPG.s["nights_cleared"]) and steps < 900 and not taken.has(lang + "_trial_end"):
		steps += 1
		var h = sim._next_hotspot()
		if h == null:
			break
		await main.on_hotspot(h)
		if RPG.s["room"] == "corridor_2" and not taken.has(lang + "_map"):
			main.show_map()
			await get_tree().create_timer(0.4).timeout
			await snap("map")
			main.render_room()
		for rid in ROOM_SHOTS:
			if RPG.s["room"] == rid and not taken.has(lang + "_room_" + rid):
				await get_tree().create_timer(0.8).timeout
				await snap("room_" + rid)
		if RPG.s["night"] == "shift2" and RPG.has("shirt") and not taken.has(lang + "_equip_menu"):
			RPG.equip("mira", "shirt")
			main.show_menu()
			await get_tree().create_timer(0.3).timeout
			var tabs = main.overlay.find_children("*", "TabContainer", true, false)
			if tabs.size() > 0:
				tabs[0].current_tab = 2
			await get_tree().create_timer(0.3).timeout
			await snap("equip_menu")
			main.render_room()
			await get_tree().create_timer(0.6).timeout
			await snap("room_outfit_shirt")
		if RPG.s["night"] == "shift2" and RPG.flag("mira_joined") and RPG.s["room"] == "corridor4" and not taken.has(lang + "_room_corridor4_party"):
			await get_tree().create_timer(0.8).timeout
			await snap("room_corridor4_party")
			main.show_menu()
			await get_tree().create_timer(0.4).timeout
			await snap("party_menu")
			main.render_room()
	if full:
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery")
	sim.free()
