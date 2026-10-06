extends Node
## Trailer footage for any night_rpg title (ops/trailers/record.sh drives it on the GPU box).
## Plays the first night for real (the game's own tests/sim.gd player, real game code) under the
## movie writer and HOLDS on each new moment, printing
##   CUE <tag> <frame> <secs> cg=<visible cg id or ->
## so ops/trailers/cut.py can cut by frame and drop any hold that shows a CG outside the
## shop-safe list. Then: map, party menu, the heroine voice lines from tests/trailer_voice.json
## (ops/trailers/pick_voice.py) spoken over her sprite, the shop-safe CGs, and the title.
## User args:  --lang=ja|en  --safe=cg_a,cg_b
##   xvfb-run godot --rendering-driver vulkan --resolution 1920x1080 --write-movie out/x.avi \
##       --fixed-fps 30 --path . res://addons/night_rpg/tests/trailer.tscn -- --lang=ja --safe=...
var main
var held := {}
var frame0 := 0
var safe: Array = []
var lang := "ja"


func _args() -> Dictionary:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	return a


func _cg_now() -> String:
	if main == null or main.event == null or not main.event.cg.visible or main.event.cg.texture == null:
		return "-"
	return main.event.cg.texture.resource_path.get_file().get_basename()


func cue(tag: String, secs: float) -> void:
	print("CUE %s %d %.2f cg=%s" % [tag, Engine.get_frames_drawn() - frame0, secs, _cg_now()])
	await get_tree().create_timer(secs).timeout


func _ready() -> void:
	var a := _args()
	lang = str(a.get("lang", "ja"))
	safe = str(a.get("safe", "")).split(",", false)
	get_tree().root.set_meta("nr_no_title", true)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_current_rendering_driver_name())
	get_tree().create_timer(1500.0).timeout.connect(func(): print("TRAILER TIMEOUT"); get_tree().quit(2))
	frame0 = Engine.get_frames_drawn()
	Loc.set_lang(lang)
	RPG.persist["voice_lang"] = lang
	RPG.persist["gallery"] = []
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	main.auto = true
	add_child(main)
	main.event.auto_mode = true
	main.shot_hook = hook
	var first: String = RPG.game["nights"][0]
	main.stop_after = first
	main.show_title()
	await cue("title", 4.0)
	RPG.new_game()
	await main.start_night(first)
	await cue("room_start", 3.0)
	var sim = load("res://tests/sim.gd").new()
	sim.main = main
	var steps := 0
	var seen := {}
	while not (first in RPG.s["nights_cleared"]) and steps < 600:
		steps += 1
		var h = sim._next_hotspot()
		if h == null:
			break
		await main.on_hotspot(h)
		var rid := str(RPG.s["room"])
		if not seen.has(rid) and first not in RPG.s["nights_cleared"]:
			seen[rid] = true
			await get_tree().create_timer(0.3).timeout
			await cue("room_" + rid, 2.5)
	print("NIGHT DONE steps=%d cleared=%s" % [steps, str(first in RPG.s["nights_cleared"])])
	await _choice_screen(first)
	main._clear_overlay()
	main.show_map()
	await cue("map", 3.0)
	main._clear_overlay()
	main.show_menu()
	await cue("menu", 3.0)
	main._close_modal()
	main._clear_overlay()
	await _voices()
	await _takes()
	for id in safe:
		if NRArt.path("cg", id) != "":
			main.event.box.visible = false
			main.event.name_panel.visible = false
			main.event.show_cg(NRArt.tex("cg", id))
			await get_tree().create_timer(0.7).timeout
			await cue("safe_" + id, 4.5)
	main.event.show_cg(null)
	main._clear_overlay()
	main.show_title()
	await cue("title_end", 5.0)
	sim.free()
	print("TRAILER DONE")
	get_tree().quit()


func _sprite_for(who: String) -> Texture2D:
	var sprites: Dictionary = NRArt.manifest().get("sprites", {})
	for pref in [who, who + "_neutral", who + "_work"]:
		if sprites.has(pref) and NRArt.path("sprites", pref) != "":
			return NRArt.tex("sprites", pref)
	for k in sprites:
		if str(k).begins_with(who + "_") and NRArt.path("sprites", k) != "":
			return NRArt.tex("sprites", k)
	var hs: String = RPG.game.get("heroine_sprite", "")
	return NRArt.tex("sprites", hs) if hs != "" else null


func _voices() -> void:
	var f := FileAccess.open("res://tests/trailer_voice.json", FileAccess.READ)
	if f == null:
		print("NO VOICE LIST")
		return
	var rows = JSON.parse_string(f.get_as_text())
	var i := 0
	for r in rows:
		var body := ""
		if r["kind"] == "story":
			body = Loc.line(RPG.story[r["ch"]][int(r["idx"])])
		else:
			body = Loc.t(r["key"])
		main.event.show_cg(null)
		main.stage.set_figure(_sprite_for(r["who"]), 0.62)
		main.event.say(main._who(r["who"]), body, 0.0)
		var secs: float = Sound.play_voice({"v_en": r["v_en"], "v_ja": r["v_ja"]}, {"pan": 0.0})
		print("VOICE %s %s %.2f" % [r["who"], Sound.voice_path({"v_en": r["v_en"], "v_ja": r["v_ja"]}), secs])
		await cue("voice_%d_%s" % [i, r["who"]], max(secs, 2.0) + 0.5)
		i += 1
	main.event.box.visible = false
	main.stage.set_figure(null)


func hook(tag: String) -> void:
	var hold := {"night_card": 3.0, "battle": 3.5, "battle_pressured": 2.5, "battle_boss": 3.5,
		"levelup": 3.0, "dialogue": 3.0, "dialogue2": 3.0, "choice": 2.5, "night_end": 3.0}
	if tag.begins_with("cg_"):
		var id := tag.substr(3) if tag.begins_with("cg_cg_") else tag
		if id in safe and not held.has(id):
			held[id] = true
			await get_tree().create_timer(0.7).timeout
			await cue(id, 3.5)
		return
	if held.has(tag):
		return
	held[tag] = true
	await get_tree().create_timer(0.3).timeout
	await cue(tag, hold.get(tag, 2.5))


func _find_choice(o):
	if o is Dictionary:
		if o.has("choice") and o["choice"] is Array and o["choice"].size() >= 2:
			return o["choice"]
		for v in o.values():
			var r = _find_choice(v)
			if r != null:
				return r
	elif o is Array:
		for v in o:
			var r = _find_choice(v)
			if r != null:
				return r
	return null


## The real choice panel with its options on screen (the "choice" shot hook only fires after the
## pick, when the buttons are gone): shown with auto_mode off and released after the hold.
func _choice_screen(nid: String) -> void:
	var ch = _find_choice(RPG.nights.get(nid, {}))
	if ch == null:
		return
	var opts := []
	for o in ch.slice(0, 4):
		opts.append({"text": Loc.menu(o["menu"]) if o.has("menu") else Loc.t(o.get("key", ""))})
	main.event.show_cg(null)
	main.event.auto_mode = false
	main.event.choose(opts)
	await get_tree().create_timer(0.5).timeout
	await cue("choice_screen", 3.0)
	main.event.chosen.emit(0)
	main.event.auto_mode = true
	await get_tree().create_timer(0.2).timeout


## Motion takes for the trailer edit: every room plate (ambient dust/light) and every heroine
## figure over a plate, alive.gdshader breathing/sway running, no dialogue box, 3-4 s each.
func _takes() -> void:
	var excl := ["after", "undone", "lace", "nightwear"]
	main.event.show_cg(null)
	main.event.box.visible = false
	main.event.name_panel.visible = false
	main.hud.visible = false
	var rooms: Dictionary = NRArt.manifest().get("rooms", {})
	var rids := []
	for r in rooms:
		if NRArt.path("rooms", r) != "":
			rids.append(r)
	var n := 0
	for r in rids.slice(0, 14):
		main.stage.set_figure(null)
		main.stage.set_plate(NRArt.tex("rooms", r), {})
		await get_tree().create_timer(0.4).timeout
		await cue("plate_" + r, 3.0)
	var heroes := {}
	var f := FileAccess.open("res://tests/trailer_voice.json", FileAccess.READ)
	if f != null:
		for row in JSON.parse_string(f.get_as_text()):
			heroes[row["who"]] = true
	var hs: String = RPG.game.get("heroine_sprite", "")
	for k in NRArt.manifest().get("sprites", {}):
		var ok := str(k) == hs
		for h in heroes:
			if str(k) == h or str(k).begins_with(h + "_"):
				ok = true
		for e in excl:
			if e in str(k):
				ok = false
		if not ok or NRArt.path("sprites", k) == "":
			continue
		main.stage.set_plate(NRArt.tex("rooms", rids[n % rids.size()]), {})
		n += 1
		main.stage.set_figure(NRArt.tex("sprites", k), 0.62)
		await get_tree().create_timer(0.4).timeout
		await cue("fig_%s_%d" % [k, (n - 1) % rids.size()], 3.5)
	main.stage.set_figure(null)
	main.hud.visible = true
