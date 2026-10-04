extends Node
## Screenshot run: plays the whole game with the scripted player and saves what a reviewer
## must see -- disclosure, title, settings, the case card, rooms, the board (map), standoffs,
## a boss, a level-up, the party/equipment menu, the gallery, every CG -- in English and in
## Japanese, then the Japanese trial to its end screen. Needs a real renderer (not --headless):
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --path . res://tests/shots.tscn -- --out=shots/run
## Prints the render device so a CPU fallback is visible (memory: xvfb-godot-renders-on-cpu).

var main
var out := "res://shots/run"
var taken := {}
var lang := "en"
const ROOM_SHOTS := ["lobby", "open_plan", "copy_room", "break_room", "sublet", "meeting_room", "stairwell", "accounts", "records",
	"server_room", "newsroom", "print_room", "rooftop", "penthouse", "boardroom", "vault"]


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_video_adapter_vendor(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(1500.0).timeout.connect(func():
		print("SHOTS TIMEOUT")
		get_tree().quit(2))
	await get_tree().process_frame
	RPG.persist["gallery"] = []
	# --langs=de,fr,... : night one in each listed language only (the i18n check run)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--langs="):
			for l in a.trim_prefix("--langs=").split(","):
				await run_lang(l, false)
			print("SHOTS: ", JSON.stringify(taken.keys()))
			get_tree().quit()
			return
	await run_lang("en", true)
	await run_lang("ja", false)
	RPG.trial_override = true
	lang = "ja"
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
	elif tag in ["battle", "battle_boss", "battle_pressured", "levelup", "choice", "dialogue", "dialogue2", "trial_end", "loss"] or (tag == "night_card" and str(RPG.s.get("night", "")) == "n1"):
		await snap(tag)
	elif tag == "night_card" and str(RPG.s.get("night", "")) == "n2":
		# the gallery as it stands after case 1 (the DLsite sample: nothing explicit yet open is fine, the tiles show)
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery_early")
		main._clear_overlay()
	elif tag in ["office", "office_built", "recruit", "recruit10", "supplies"]:
		# the second genre on screen, every night
		var k := tag + "_" + str(RPG.s.get("night", ""))
		if not taken.has(lang + "_" + k):
			await snap(k)
	elif tag == "night_end":
		await snap("night_end_" + str(RPG.s["night"]))
	elif tag == "the_end":
		await snap("the_end")


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
	main.stop_after = "" if (RPG.trial_override or full) else "n1"   # the trial reaches its own end screen
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
	await main.start_night("n1")
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	var last := "n1" if (RPG.trial_override or not full) else "n5"
	while not (last in RPG.s["nights_cleared"]) and steps < 1500 and not taken.has(lang + "_trial_end"):
		steps += 1
		var h = sim._next_hotspot()
		if h == null:
			break
		await main.on_hotspot(h)
		for rid in ROOM_SHOTS:
			if RPG.s["room"] == rid and not taken.has(lang + "_room_" + rid):
				await get_tree().create_timer(0.8).timeout
				await snap("room_" + rid)
		if RPG.s["room"] == "sublet" and not taken.has(lang + "_map"):
			main.show_map()
			await get_tree().create_timer(0.4).timeout
			await snap("map")
			main.render_room()
		if RPG.s["night"] == "n3" and not taken.has(lang + "_equip_menu"):
			if not RPG.has("mara_after") and RPG.s["members"]["mara"]["equip"]["outfit"] != "mara_after":
				RPG.give("mara_after")   # the dress is a Supplies purchase; the shot shows it worn
			RPG.equip("mara", "mara_after")
			if RPG.has("priya_after"):
				RPG.equip("priya", "priya_after")
			main.show_menu()
			await get_tree().create_timer(0.3).timeout
			var tabs = main.overlay.find_children("*", "TabContainer", true, false)
			if tabs.size() > 0:
				tabs[0].current_tab = 2
			await get_tree().create_timer(0.3).timeout
			await snap("equip_menu")
			main.render_room()
		if RPG.s["room"] == "meeting_room" and not taken.has(lang + "_party_menu"):
			main.show_menu()
			await get_tree().create_timer(0.4).timeout
			await snap("party_menu")
			main.render_room()
	if full:
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap("gallery")
		main._clear_overlay()
		# every CG on screen through the game's own CG view, whichever route reached it
		if lang == "en":
			for c in RPG.game["gallery"]:
				if NRArt.path("cg", c["id"]) == "":
					continue
				main.event.visible = true
				main.event.box.visible = false
				main.event.name_panel.visible = false
				main.event.show_cg(NRArt.tex("cg", c["id"]))
				await get_tree().create_timer(0.5).timeout
				await snap("cgview_" + c["id"])
			main.event.show_cg(null)
			main.event.box.visible = true
	sim.free()
