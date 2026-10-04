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
	if "--only=equip" in OS.get_cmdline_user_args():
		for l in ["en", "ja"]:
			lang = l
			Loc.set_lang(l)
			main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
			main.auto = true
			add_child(main)
			main.event.auto_mode = true
			RPG.new_game()
			RPG.start_night("night3")
			RPG.set_flag("elena_joined")
			RPG.s["level"] = 10
			for mid in ["vance", "elena"]:
				for k in RPG.s["members"][mid]["base"].keys():
					RPG.s["members"][mid]["base"][k] = int(RPG.s["members"][mid]["base"][k]) + 4
			RPG.give("evening"); RPG.give("spectacles"); RPG.give("signet"); RPG.give("torch"); RPG.give("cardigan")
			RPG.equip("elena", "evening"); RPG.equip("elena", "spectacles"); RPG.equip("vance", "signet"); RPG.equip("vance", "torch")
			main.render_room()
			main.show_menu()
			await get_tree().create_timer(0.4).timeout
			var tabs = main.overlay.find_children("*", "TabContainer", true, false)
			if tabs.size() > 0:
				tabs[0].current_tab = 2
			await get_tree().create_timer(0.4).timeout
			await snap("equip_menu")
			main.queue_free()
			await get_tree().process_frame
		print("SHOTS: ", JSON.stringify(taken.keys()))
		get_tree().quit()
		return
	if "--only=more" in OS.get_cmdline_user_args():
		# the "More from Flat 404" matrix (title menu + final screen), EN and JA
		for l in ["en", "ja"]:
			lang = l
			Loc.set_lang(l)
			main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
			add_child(main)
			main.show_title()
			await get_tree().create_timer(0.8).timeout
			await snap("title_more")
			var scr = load(RPG.game["more_screen"]).new()
			main.ui.add_child(scr)
			scr.run(null, {})
			await get_tree().create_timer(0.8).timeout
			await snap("more_matrix")
			scr.get_child(4).scroll_vertical = 2000
			await get_tree().create_timer(0.5).timeout
			await snap("more_matrix_bottom")
			main.queue_free()
			await get_tree().process_frame
		print("SHOTS: ", JSON.stringify(taken.keys()))
		get_tree().quit()
		return
	if "--only=disclosure" in OS.get_cmdline_user_args():
		for l in ["ja", "en"]:
			lang = l
			Loc.set_lang(l)
			main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
			add_child(main)
			main.show_disclosure(false)
			await get_tree().create_timer(0.6).timeout
			await snap("disclosure")
			main.queue_free()
			await get_tree().process_frame
		print("SHOTS: ", JSON.stringify(taken.keys()))
		get_tree().quit()
		return
	await run_lang("en", true)
	await run_lang("ja", true)
	RPG.trial_override = true   # a third, short pass: the Japanese trial to its end screen
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
		main.toast_lbl.modulate.a = 0.0   # a trust toast over a sample reads as clutter
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
	elif tag in ["battle", "battle_boss", "battle_pressured", "levelup", "choice", "dialogue", "dialogue2", "trial_end", "loss"] or (tag == "night_card" and str(RPG.s.get("night", "")) == "night1"):
		await snap(tag)
	elif tag == "night_card" and str(RPG.s.get("night", "")) == "night2":
		# the gallery as it stands after night 1: three CGs open, nothing explicit (the DLsite sample)
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
	main.stop_after = "" if RPG.trial_override else "night4"   # EN: through night 4 (gala, carrel); JA: the trial
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
	await main.start_night("night1")
	await get_tree().create_timer(1.0).timeout
	await snap("room_study")
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	var last := "night1" if RPG.trial_override else "night4"
	if RPG.trial_override:
		for k in taken.keys():
			if k.begins_with(lang + "_") and k != lang + "_trial_end":
				pass   # already taken in the full pass; only the trial end is new here
	while not (last in RPG.s["nights_cleared"]) and steps < 900 and not taken.has(lang + "_trial_end"):
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
		for rid in ["entrance_hall", "map_room", "bell_chamber", "bindery", "conservation_lab", "common_room", "deans_corridor"]:
			if RPG.s["room"] == rid and not taken.has(lang + "_room_" + rid):
				await get_tree().create_timer(0.8).timeout
				await snap("room_" + rid)
		if RPG.s["night"] == "night3" and RPG.has("evening") and not taken.has(lang + "_equip_menu"):
			RPG.equip("elena", "evening")
			main.show_menu()
			await get_tree().create_timer(0.3).timeout
			var tabs = main.overlay.find_children("*", "TabContainer", true, false)
			if tabs.size() > 0:
				tabs[0].current_tab = 2
			await get_tree().create_timer(0.3).timeout
			await snap("equip_menu")
			main.render_room()
			await get_tree().create_timer(0.6).timeout
			await snap("room_outfit_evening")
		if RPG.s["room"] == "vault" and RPG.flag("elena_joined") and not taken.has(lang + "_room_vault_party"):
			await get_tree().create_timer(0.8).timeout
			await snap("room_vault_party")
			main.show_menu()
			await get_tree().create_timer(0.4).timeout
			await snap("party_menu")
			main.render_room()
	if full:
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery")
	sim.free()
