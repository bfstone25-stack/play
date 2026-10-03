extends Node
## Screenshot run: plays the game with the scripted (warm) player and saves what a reviewer must
## see -- disclosure, title, settings, the route select, night cards, every room and venue, the
## map, standoffs (stranger, date, rival boss, last wall), a level-up, the equipment menu, the
## gallery and EVERY CG -- in English across all six routes, in Japanese on route 1 (Gu Yan)
## plus the route select, then the Japanese trial to its end screen.
## Needs a real renderer (not --headless):
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --path . res://tests/shots.tscn -- --out=shots/run
## Prints the render device so a CPU fallback is visible (memory: xvfb-godot-renders-on-cpu).

var main
var out := "res://shots/run"
var taken := {}
var lang := "en"
var route := ""
const ROUTES := ["guyan", "ethan", "luxingye", "liam", "adrian", "fushen"]


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		if a.begins_with("--routes="):
			only = a.trim_prefix("--routes=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_video_adapter_vendor(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(2400.0).timeout.connect(func():
		print("SHOTS TIMEOUT")
		get_tree().quit(2))
	await get_tree().process_frame
	RPG.persist["gallery"] = []
	var en_routes: Array = ROUTES if only == "" else Array(only.split(","))
	await run_lang("en", en_routes, true)
	await run_lang("ja", ["guyan"], true)
	RPG.trial_override = true
	RPG.nights.clear()
	RPG.load_content()   # nights are all present in the editor; the trial run stops at guyan_c2 by trial_last_night
	await run_lang("ja", ["guyan"], false, "trial_")
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
	var nid := str(RPG.s.get("night", ""))
	if tag.begins_with("cg_"):
		await get_tree().create_timer(0.8).timeout
		await snap(tag)
	elif tag in ["battle", "battle_boss"]:
		await snap("battle_" + nid)
	elif tag in ["levelup", "choice", "dialogue", "dialogue2", "trial_end", "loss", "the_end"]:
		await snap(tag + ("_" + route if tag in ["choice", "the_end"] else ""))
	elif tag == "night_card":
		await snap("card_" + nid)


func run_lang(l: String, routes: Array, full: bool, prefix: String = "") -> void:
	lang = l
	Loc.set_lang(l)
	for r in routes:
		route = r
		if main != null:
			main.queue_free()
			await get_tree().process_frame
		main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
		main.auto = true
		add_child(main)
		main.event.auto_mode = true
		main.shot_hook = hook
		main.stop_after = ""
		main.prefer_menu = [str(Loc.table.get("pick_" + r, {}).get("en", r)).substr(0, 12)]
		if r == routes[0]:
			main.show_disclosure(false)
			await get_tree().create_timer(0.6).timeout
			await snap(prefix + "disclosure")
			main.show_title()
			await get_tree().create_timer(1.5).timeout
			await snap(prefix + "title")
			main.show_settings()
			await get_tree().create_timer(0.3).timeout
			await snap(prefix + "settings")
			main._clear_overlay()
		RPG.new_game()
		# the route select, shown before the scripted player answers it
		var opts := []
		for o in RPG.nights["prologue"]["events"]["start"][3]["choice"]:
			if RPG.nights.has(o["if_night"]):
				opts.append({"text": Loc.menu(o["menu"])})
		main.event.say("", Loc.t("ev_pro_3"))
		main.event.auto_choice = 0
		main.event.choose(opts)
		await get_tree().create_timer(0.5).timeout
		await snap(prefix + "route_select")
		main.event.close()
		await main.start_night("prologue")
		var sim = load("res://tests/sim.gd").new()
		sim.main = main
		var steps := 0
		var last := "%s_c5" % r if full else "%s_c2" % r
		while not (last in RPG.s["nights_cleared"]) and steps < 1200 and not taken.has(lang + "_trial_end"):
			steps += 1
			var h = sim._next_hotspot()
			if h == null:
				break
			await main.on_hotspot(h)
			sim._auto_equip()
			var nid := str(RPG.s.get("night", ""))
			var rk := "room_" + (RPG.room().get("plate", "") if RPG.s["room"] == "venue" else RPG.s["room"])
			if main.hud.visible and not taken.has(lang + "_" + prefix + rk):
				await get_tree().create_timer(0.8).timeout
				await snap(prefix + rk)
			if nid == r + "_c1" and RPG.s["room"] == "street" and not taken.has(lang + "_" + prefix + "map"):
				main.show_map()
				await get_tree().create_timer(0.4).timeout
				await snap(prefix + "map")
				main.render_room()
			if nid == r + "_c2" and RPG.s["room"] == "home" and not taken.has(lang + "_" + prefix + "equip_menu"):
				main.show_menu()
				await get_tree().create_timer(0.3).timeout
				var tabs = main.overlay.find_children("*", "TabContainer", true, false)
				if tabs.size() > 0:
					tabs[0].current_tab = 2
				await get_tree().create_timer(0.3).timeout
				await snap(prefix + "equip_menu")
				if tabs.size() > 0:
					tabs[0].current_tab = 0
				await get_tree().create_timer(0.3).timeout
				await snap(prefix + "status_menu")
				main.render_room()
		print("route %s %s: %d steps, cleared %s, trust %d, flags %s" % [l, r, steps, str(RPG.s["nights_cleared"]), RPG.trust_shown(), str(RPG.s["flags"].keys())])
		sim.free()
	if full:
		main.show_gallery()
		await get_tree().create_timer(0.5).timeout
		await snap(prefix + "gallery")
