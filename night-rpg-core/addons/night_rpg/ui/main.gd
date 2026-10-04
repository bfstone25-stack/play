extends Control
## Root of a night_rpg game: title -> nights of room exploration, events and standoffs.
##
## Flow lives here as coroutines (`await`), so a night reads top to bottom: enter a room,
## pick a hotspot, run its event steps, fight, level up. `auto` runs the same code with a
## scripted player (NRPolicy + an explorer route) and no waits: the balance/pacing sim and
## the screenshot runs use it, so they exercise the real game rather than a copy.

const VIEW := Vector2(1280, 720)

var stage: NRStage
var ui: Control
var hud: Control
var hot_layer: Control
var room_lbl: Label
var clock_lbl: Label
var trust_lbl: Label
var toast_lbl: Label
var event: NREventView
var battle: NRBattleView
var overlay: Control
var busy := false
var in_game := false

# scripted play (sim / shots)
var auto := false
var pace := {"read": 0.0, "voice": 0.0, "choice": 0.0, "battle": 0.0, "explore": 0.0, "menus": 0.0}
var stats := {"battles": [], "losses": 0, "lines": 0, "levels": [], "trust": 0, "nights": []}
var shot_hook: Callable   # called with (tag) at key moments in shot runs
var read_cps := 16.0      # measured adult reading speed for this prose, chars/s
var voice_cache := {}
var policy_override: Callable
var prefer_menu: Array = []   # sim: substrings of menu options to prefer (route/ending coverage)
var stop_after := ""      # sim: do not roll into the next night after this one
var choice_override: Callable   # sim: picks the option index itself (ending coverage: cold / middle players)


func _ready() -> void:
	theme = NRSkin.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := CanvasLayer.new()
	bg.layer = 0
	add_child(bg)
	stage = NRStage.new()
	bg.add_child(stage)
	var top := CanvasLayer.new()
	top.layer = 1
	add_child(top)
	ui = Control.new()
	ui.theme = theme
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.size = VIEW
	top.add_child(ui)
	_build_hud()
	event = NREventView.new()
	ui.add_child(event)
	battle = NRBattleView.new()
	battle.visible = false
	ui.add_child(battle)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(overlay)
	toast_lbl = NRSkin.heading("", 26)
	toast_lbl.position = Vector2(0, 90)
	toast_lbl.size = Vector2(VIEW.x, 40)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(toast_lbl)
	RPG.toast.connect(_toast)
	RPG.changed.connect(_refresh_hud)
	Loc.language_changed.connect(func():
		hud.queue_free()
		_build_hud()
		ui.move_child(hud, 0))
	Sound.play_ambience("ambience")
	var args := OS.get_cmdline_user_args()
	if not ("--no-title" in args) and not get_tree().root.has_meta("nr_no_title"):
		if RPG.game.has("disclosure_key"):
			show_disclosure(true)
		else:
			show_title()


func _toast(t: String) -> void:
	toast_lbl.text = t
	toast_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(toast_lbl, "modulate:a", 0.0, 0.8)


func _shot(tag: String) -> void:
	if shot_hook.is_valid():
		await shot_hook.call(tag)


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	hot_layer = Control.new()
	hot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hot_layer)
	var tp := PanelContainer.new()
	tp.position = Vector2(18, 14)
	hud.add_child(tp)
	var tv := VBoxContainer.new()
	tp.add_child(tv)
	room_lbl = NRSkin.heading("", 28)
	tv.add_child(room_lbl)
	clock_lbl = NRSkin.label("", 19)
	clock_lbl.custom_minimum_size = Vector2(440, 0)
	tv.add_child(clock_lbl)
	trust_lbl = NRSkin.label("", 18, Color(0.87, 0.74, 0.52))
	tv.add_child(trust_lbl)
	var bh := HBoxContainer.new()
	bh.position = Vector2(VIEW.x - 420, 16)
	bh.add_theme_constant_override("separation", 8)
	hud.add_child(bh)
	bh.add_child(NRSkin.button(Loc.t("m_map"), show_map, 20))
	bh.add_child(NRSkin.button(Loc.t("m_party"), show_menu, 20))
	bh.add_child(NRSkin.button(Loc.t("m_system"), show_system, 20))
	hud.visible = false


func _refresh_hud() -> void:
	if RPG.s.is_empty() or RPG.s.get("night", "") == "":
		return
	room_lbl.text = Loc.t(RPG.room().get("name_key", ""))
	clock_lbl.text = Loc.t("h_clock") % [RPG.clock_text(), int(RPG.s["turns_left"]), int(RPG.s["level"])]
	var tracks: Array = RPG.game.get("trust_tracks", [])
	if tracks.is_empty():
		trust_lbl.text = Loc.t("h_trust") % [int(RPG.s["trust"]), _next_threshold()]
	else:
		var parts := []
		for tr in tracks:
			parts.append(Loc.t("h_trust_track") % [Loc.t("n_" + tr), RPG.trust(tr)])
		trust_lbl.text = "   ·   ".join(parts)
	# game.json "hud_counter": an item whose count the HUD shows (e.g. a till) -- opt-in
	var hc: String = RPG.game.get("hud_counter", "")
	if hc != "":
		clock_lbl.text += "   ·   " + Loc.t("h_counter") % int(RPG.s["items"].get(hc, 0))


func _next_threshold() -> int:
	for th in RPG.game.get("trust_thresholds", [3, 5, 7, 9]):
		if int(RPG.s["trust"]) < int(th):
			return int(th)
	return 10


func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()


# ------------------------------------------------------------------ title

func show_title() -> void:
	in_game = false
	_clear_overlay()
	hud.visible = false
	event.close()
	stage.set_plate(load(RPG.game["title_bg"]), RPG.game.get("title_mood", {"ambient": "#c8c0d0", "torch": true}))
	stage.set_figure(null)
	Sound.play_music("title")
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(root)
	var sp := NRSkin.ui("panel")   # a dark column behind the logo and menu
	if sp != "" and ResourceLoader.exists(sp):
		var scrim := TextureRect.new()
		scrim.texture = load(sp)
		scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		scrim.stretch_mode = TextureRect.STRETCH_SCALE
		scrim.size = Vector2(560, VIEW.y)
		scrim.modulate = Color(1, 1, 1, 0.78)
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(scrim)
	var logo := TextureRect.new()
	logo.texture = load(RPG.game["logo"])
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.position = Vector2(50, 30)
	logo.size = Vector2(440, 196)
	root.add_child(logo)
	# the tagline fits the left panel in every language: shrink first, then wrap to two lines
	var sub_txt := Loc.t("t_subtitle")
	var sub_sz := 26
	var dfont := NRSkin.font("display")
	while sub_sz > 18 and dfont.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_sz).x > 470:
		sub_sz -= 1
	var sub := NRSkin.heading(sub_txt, sub_sz)
	sub.position = Vector2(70, 236 if dfont.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_sz).x <= 470 else 226)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.size = Vector2(470, 0)
	sub.custom_minimum_size = Vector2(470, 0)
	sub.add_theme_constant_override("line_spacing", -4)
	root.add_child(sub)
	var v := VBoxContainer.new()
	v.position = Vector2(80, 296)
	v.custom_minimum_size = Vector2(340, 0)
	v.add_theme_constant_override("separation", 7)
	root.add_child(v)
	v.add_child(NRSkin.button(Loc.t("t_new"), new_game, 24))
	var c := NRSkin.button(Loc.t("t_continue"), func(): show_saves(false), 24)
	v.add_child(c)
	v.add_child(NRSkin.button(Loc.t("t_gallery"), show_gallery, 24))
	v.add_child(NRSkin.button(Loc.t("t_settings"), show_settings, 24))
	if RPG.game.has("disclosure_key"):
		v.add_child(NRSkin.button(Loc.t("t_about"), func(): show_disclosure(false), 24))
	if RPG.game.get("more_screen", "") != "":
		v.add_child(NRSkin.button(Loc.t("t_more"), show_more, 24))
	if not OS.has_feature("web"):   # a browser tab has nothing to quit to
		v.add_child(NRSkin.button(Loc.t("t_quit"), func(): get_tree().quit(), 24))
	if RPG.is_trial():
		var tl := NRSkin.heading(Loc.t("t_trial"), 22)
		tl.position = Vector2(80, 620)
		root.add_child(tl)
	var note := NRSkin.label(Loc.t("t_note"), 15, Color(0.75, 0.7, 0.65))
	note.add_theme_constant_override("outline_size", 6)
	note.position = Vector2(60, 664)
	note.size = Vector2(640, 44)
	note.custom_minimum_size = Vector2(640, 0)
	root.add_child(note)


# ------------------------------------------------------------------ game start / rooms

func new_game() -> void:
	_clear_overlay()
	RPG.new_game()
	await start_night(RPG.game["nights"][0])


func start_night(nid: String) -> void:
	# {"night_hook": "res://scripts/x.gd"} in game.json: an object with
	# `func before_night(main, nid) -> void`, awaited before each night starts (Elena's web
	# edition puts its sponsor gate here; it returns at once off the web).
	if RPG.game.get("night_hook", "") != "" and not auto:
		var hk = load(RPG.game["night_hook"]).new()
		await hk.before_night(self, nid)
	RPG.start_night(nid)
	RPG.autosave()
	var n := RPG.night()
	await _night_card(n)
	if n.has("start_event"):
		var r := await run_event(n["start_event"])
		if r == "abort":
			return
	render_room()


func _night_card(n: Dictionary) -> void:
	_clear_overlay()
	hud.visible = false
	var p := PanelContainer.new()
	p.position = Vector2(340, 250)
	p.custom_minimum_size = Vector2(600, 200)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var h := NRSkin.heading(Loc.t(n["title_key"]), 40)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var s := NRSkin.label(Loc.t(n.get("sub_key", "")), 20)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var s2 := NRSkin.label(Loc.t("nc_budget") % int(n.get("turns", 30)), 18, Color(0.87, 0.74, 0.52))
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s2)
	await _shot("night_card")
	if not auto:
		await get_tree().create_timer(2.6).timeout
	pace["menus"] += 3.0
	if is_instance_valid(p):   # a shot hook may have cleared the overlay already
		p.queue_free()


func render_room() -> void:
	in_game = true
	_clear_overlay()
	event.close()
	battle.visible = false
	var r := RPG.room()
	stage.set_plate(NRArt.tex("rooms", r.get("plate", RPG.s["room"])), r.get("mood", {}))
	var fig := ""
	if RPG.flag(RPG.game.get("heroine_flag", "heroine_joined")):
		fig = r.get("heroine_pose", RPG.heroine_sprite())
	stage.set_figure(NRArt.tex("sprites", fig) if fig != "" else null, float(r.get("heroine_x", 0.78)))
	Sound.play_music(r.get("music", "explore"))
	hud.visible = true
	_refresh_hud()
	for c in hot_layer.get_children():
		c.queue_free()
	for h in visible_hotspots():
		var b := NRSkin.button(_hot_label(h), func(): on_hotspot(h), 19)
		b.position = Vector2(float(h["pos"][0]) * VIEW.x, float(h["pos"][1]) * VIEW.y) - Vector2(90, 22)
		b.custom_minimum_size = Vector2(180, 44)
		hot_layer.add_child(b)
		var l := PointLight2D.new()
		l.texture = NRSkin.light_texture()
		l.texture_scale = 0.5
		l.energy = 0.6
		l.color = Color(1, 0.86, 0.6)
		l.position = b.position + Vector2(90, 22)
		stage.lamps.append(l)
		stage.add_child(l)


## Show the current room and play its first-visit event if that has not completed yet
## (the save taken on entering a room is taken before the event runs).
func enter_room_event() -> String:
	render_room()
	var rid: String = RPG.s["room"]
	var ev: String = RPG.room().get("enter_event", "")
	if ev == "" or RPG.s["done"].has("visited/" + rid):
		RPG.s["done"]["visited/" + rid] = true
		return "ok"
	hud.visible = false
	var r := await run_event(ev)
	if r == "ok":
		RPG.s["done"]["visited/" + rid] = true
	return r


func resume_room() -> void:
	var r := await enter_room_event()
	if r == "ok" and RPG.s.get("night", "") != "":
		render_room()


func _hot_label(h: Dictionary) -> String:
	var t := Loc.t(h.get("label_key", "hs_" + h["id"]))
	match h["kind"]:
		"door":
			if not h.has("label_key"):
				t = Loc.t(RPG.night()["rooms"].get(h["to"], {}).get("name_key", h["to"]))
			t = "→ " + t
			if h.has("needs") and not RPG.has(h["needs"]):
				t += "  " + Loc.t("hs_locked")
		"search":
			t = Loc.t("hs_search") + " " + t
		"enemy":
			if not h.has("label_key"):
				t = Loc.t(RPG.game["enemies"][h["enemy"]]["name_key"])
			t = "! " + t
	return t


func visible_hotspots() -> Array:
	return visible_hotspots_in(RPG.s["room"])


func visible_hotspots_in(rid: String) -> Array:
	var out := []
	for h in RPG.night().get("rooms", {}).get(rid, {}).get("hotspots", []):
		var key: String = rid + "/" + h["id"]
		if h.get("once", h["kind"] != "door") and RPG.s["done"].has(key):
			continue
		if h.has("if_flag") and not RPG.flag(h["if_flag"]):
			continue
		if h.has("if_not_flag") and RPG.flag(h["if_not_flag"]):
			continue
		out.append(h)
	return out


func on_hotspot(h: Dictionary) -> void:
	if busy:
		return
	busy = true
	hud.visible = false
	var r := await _do_hotspot(h)
	busy = false
	if r == "abort":
		return
	if r == "night_over":
		return
	if int(RPG.s["turns_left"]) <= 0:
		await _dawn_loss()
		return
	render_room()


func _do_hotspot(h: Dictionary) -> String:
	var key: String = RPG.s["room"] + "/" + h["id"]
	match h["kind"]:
		"door":
			if h.has("needs") and not RPG.has(h["needs"]):
				var r0 := await run_steps([{"say": "narrator", "key": h.get("locked_key", "hs_locked_msg")}])
				return r0
			RPG.spend_turns(int(h.get("turns", 1)))
			pace["explore"] += 6.0
			RPG.s["room"] = h["to"]
			RPG.autosave()
			return await enter_room_event()
		"search":
			RPG.autosave()
			RPG.spend_turns(int(h.get("turns", 1)))
			pace["explore"] += 7.0
			RPG.s["done"][key] = true
			var steps: Array = []
			if h.has("event"):
				steps.append({"event": h["event"]})
			for it in h.get("gives", []):
				steps.append({"give": it})
			if h.has("xp"):
				steps.append({"xp": h["xp"]})
			if h.has("trust"):
				steps.append({"trust": h["trust"]})
			return await run_steps(steps)
		"event", "npc":
			# saved before, marked done after: a standoff lost inside the event reloads to
			# just before this hotspot, which is still there to try again
			RPG.autosave()
			pace["explore"] += 3.0
			if h.get("turns", 0) > 0:
				RPG.spend_turns(int(h["turns"]))
			var r1 := await run_event(h["event"])
			if r1 == "ok":
				RPG.s["done"][key] = true
			return r1
		"enemy":
			RPG.autosave()
			pace["explore"] += 3.0
			var steps2: Array = []
			if h.has("event"):
				steps2.append({"event": h["event"]})
			steps2.append({"battle": h["enemy"]})
			if h.has("after"):
				steps2.append({"event": h["after"]})
			var r2 := await run_steps(steps2)
			if r2 == "ok":
				RPG.s["done"][key] = true
				RPG.spend_turns(int(h.get("turns", 2)))
			return r2
	return "ok"


# ------------------------------------------------------------------ events

func run_event(id: String) -> String:
	var steps = RPG.night().get("events", {}).get(id, null)
	if steps == null:
		for nid in RPG.nights.keys():
			steps = RPG.nights[nid].get("events", {}).get(id, null)
			if steps != null:
				break
	if steps == null:
		push_error("night_rpg: no event " + id)
		return "ok"
	var r := await run_steps(steps)
	event.close()
	return r


## Runs a list of steps. Returns "ok", "abort" (a loss reloaded the save) or "night_over".
func run_steps(steps: Array) -> String:
	for st in steps:
		var r := await _step(st)
		if r != "ok":
			return r
	return "ok"


func _who(id: String) -> String:
	if id == "narrator" or id == "":
		return ""
	return Loc.t("n_" + id)


func _say_line(who: String, body: String, ln: Dictionary) -> void:
	var secs := 0.0
	if not auto:
		secs = Sound.play_voice(ln)
	else:
		secs = _voice_len(ln)
	body = interp(body)
	var read: float = body.length() / read_cps + 0.6
	pace["read"] += max(read, secs + 0.4)
	if secs > read:
		pace["voice"] += secs - read
	stats["lines"] += 1
	if stats["lines"] == 14 or stats["lines"] == 60:
		event.say(who, body, secs)
		await _shot("dialogue" if stats["lines"] == 14 else "dialogue2")
	await event.say(who, body, secs)


## "{#item}" in a line -> how many of that item the party holds (a till, a tally). Opt-in.
func interp(body: String) -> String:
	if not body.contains("{#"):
		return body
	var re := RegEx.create_from_string("\\{#([a-z0-9_]+)\\}")
	for m in re.search_all(body):
		body = body.replace(m.get_string(0), str(int(RPG.s["items"].get(m.get_string(1), 0))))
	return body


func _voice_len(ln: Dictionary) -> float:
	var p: String = ln.get("v_en", "")
	if p == "":
		return 0.0
	if not voice_cache.has(p):
		var st = load(p) if ResourceLoader.exists(p) else null
		voice_cache[p] = st.get_length() if st != null else 0.0
	return voice_cache[p]


func _step(st: Dictionary) -> String:
	if st.has("lines"):
		for ln in RPG.story_range(st["lines"]):
			if ln.get("skip", false):
				continue
			await _say_line(_who(ln["who"]), Loc.line(ln), ln)
		return "ok"
	if st.has("say"):
		# RPG-only lines are voiced per string key (game.json "voice"); missing = silent
		await _say_line(_who(st["say"]), Loc.t(st["key"]), RPG.game.get("voice", {}).get(st["key"], {}))
		return "ok"
	if st.has("event"):
		return await run_event(st["event"])
	if st.has("bg"):
		event.show_cg(null)
		stage.set_plate(NRArt.tex("rooms", st["bg"]), RPG.night().get("rooms", {}).get(st["bg"], {}).get("mood", {}))
		return "ok"
	if st.has("cg"):
		if NRArt.path("cg", st["cg"]) == "":
			return "ok"   # a CG still being rendered: the scene plays without it
		event.visible = true
		var cg_id: String = st["cg"]
		if RPG.is_trial() and cg_id in RPG.game.get("trial_locked_cgs", []) and NRArt.path("cg", cg_id + "_locked") != "":
			cg_id += "_locked"
		event.show_cg(NRArt.tex("cg", cg_id))
		if st.get("unlock", true):
			RPG.unlock_cg(st["cg"])
		await _shot("cg_" + st["cg"])
		return "ok"
	if st.has("hide_cg"):
		event.show_cg(null)
		return "ok"
	if st.has("show"):
		stage.set_figure(NRArt.tex("sprites", st["show"]) if st["show"] != "" else null, float(st.get("x", 0.72)))
		return "ok"
	if st.has("music"):
		Sound.play_music(st["music"])
		return "ok"
	if st.has("sfx"):
		Sound.play_sfx(st["sfx"])
		return "ok"
	if st.has("flag"):
		RPG.set_flag(st["flag"], st.get("value", true))
		return "ok"
	if st.has("give"):
		RPG.give(st["give"], int(st.get("n", 1)))
		if st.get("quiet", false):
			return "ok"
		var got := Loc.t("i_" + st["give"])
		if int(st.get("n", 1)) > 1:
			got += " ×%d" % int(st["n"])
		await _say_line("", Loc.t("ev_got") % got, {})
		Sound.play_sfx("page_flip")
		return "ok"
	if st.has("take"):
		RPG.take(st["take"], int(st.get("n", 1)))
		return "ok"
	if st.has("trust"):
		var track: String = st.get("track", "")
		RPG.add_trust(int(st["trust"]), track)
		if int(st["trust"]) > 0:
			if track != "":
				await _say_line("", Loc.t("ev_trust_track") % [Loc.t("n_" + track), int(st["trust"])], {})
			else:
				await _say_line("", Loc.t("ev_trust") % int(st["trust"]), {})
		return "ok"
	if st.has("xp"):
		var lv := RPG.add_xp(int(st["xp"]))
		if not auto:
			_toast(Loc.t("ev_xp") % int(st["xp"]))
		if lv > 0:
			await level_up_flow()
		return "ok"
	if st.has("if_trust"):
		var ok := RPG.trust(st.get("track", "")) >= int(st["if_trust"])
		return await run_steps(st["then"] if ok else st.get("else", []))
	if st.has("if_flag"):
		return await run_steps(st["then"] if RPG.flag(st["if_flag"]) else st.get("else", []))
	if st.has("if_equipped"):
		var worn := false
		for mid in RPG.s["members"].keys():
			if st["if_equipped"] in RPG.s["members"][mid]["equip"].values():
				worn = true
		return await run_steps(st["then"] if worn else st.get("else", []))
	if st.has("if_has"):
		# {"if_has": item, "n": 35}: the party holds at least n of the item
		var okh := int(RPG.s["items"].get(st["if_has"], 0)) >= int(st.get("n", 1))
		return await run_steps(st["then"] if okh else st.get("else", []))
	if st.has("if_count"):
		# {"if_count": [flags], "n": 2}: at least n of the flags are set
		var cnt := 0
		for f in st["if_count"]:
			if RPG.flag(f):
				cnt += 1
		return await run_steps(st["then"] if cnt >= int(st.get("n", 1)) else st.get("else", []))
	if st.has("choice"):
		var opts := []
		var shown := []   # options whose if_flag / if_not_flag allow them now
		for o in st["choice"]:
			if o.has("if_flag") and not RPG.flag(o["if_flag"]):
				continue
			if o.has("if_not_flag") and RPG.flag(o["if_not_flag"]):
				continue
			if o.has("if_has") and int(RPG.s["items"].get(o["if_has"], 0)) < int(o.get("n", 1)):
				continue
			if o.has("if_lacks") and int(RPG.s["items"].get(o["if_lacks"], 0)) >= int(o.get("n", 1)):
				continue
			# an option that leads to a night this build does not ship (the trial pck) is not offered
			if o.has("if_night") and not RPG.nights.has(o["if_night"]):
				continue
			shown.append(o)
			var t := Loc.menu(o["menu"]) if o.has("menu") else Loc.t(o["key"])
			var locked := false
			if o.has("req_trust") and RPG.trust(o.get("req_track", "")) < int(o["req_trust"]):
				locked = true
				t += "   " + Loc.t("ch_need_trust") % int(o["req_trust"])
			opts.append({"text": t, "locked": locked})
		if shown.is_empty():
			return "ok"
		pace["choice"] += 8.0
		var idx := 0
		if auto:
			event.auto_choice = _auto_choice(shown)
			idx = await event.choose(opts)
			await _shot("choice")
		else:
			idx = await event.choose(opts)
		return await run_steps(shown[idx].get("do", []))
	if st.has("screen"):
		# {"screen": "res://scripts/x.gd", "args": {...}}: a game's own screen (a shop
		# counter, a planner). It is a Control with `func run(main, args) -> String`
		# that returns "ok" (or "abort"); `main.auto` tells it to play itself for the sim.
		event.close()
		hud.visible = false
		var scr: Control = load(st["screen"]).new()
		overlay.add_child(scr)
		var rs: String = await scr.run(self, st.get("args", {}))
		scr.queue_free()
		return rs
	if st.has("battle"):
		return await do_battle(st["battle"])
	if st.has("end_night"):
		return await end_night(st.get("next", ""))
	if st.has("join"):
		RPG.set_flag(RPG.game.get("heroine_flag", "heroine_joined"))
		return "ok"
	if st.has("turns"):
		RPG.spend_turns(int(st["turns"]))
		return "ok"
	push_warning("night_rpg: unknown step %s" % st)
	return "ok"


## Scripted player's menu choice: the highest-trust option it may take.
func _auto_choice(opts: Array) -> int:
	if choice_override.is_valid():
		return int(choice_override.call(opts))
	var best := 0
	var best_v := -99
	for i in opts.size():
		for pm in prefer_menu:
			# a VN menu's English text, or an RPG option's string key
			if str(opts[i].get("menu", "")).contains(pm) or str(opts[i].get("key", "")).begins_with(pm):
				return i
	for i in opts.size():
		var o: Dictionary = opts[i]
		if o.has("req_trust") and RPG.trust(o.get("req_track", "")) < int(o["req_trust"]):
			continue
		var v := int(o.get("auto_rank", 0))
		if not o.has("auto_rank"):
			for d in o.get("do", []):
				if d is Dictionary and int(d.get("trust", 0)) > 0:
					v += 1
		if v > best_v:
			best_v = v
			best = i
	return best


# ------------------------------------------------------------------ battle

func do_battle(enemy_id: String) -> String:
	event.close()
	hud.visible = false
	var heroine: String = RPG.heroine_sprite() if RPG.heroine_id() == "" or RPG.in_party(RPG.heroine_id()) else ""
	stage.set_figure(NRArt.tex("sprites", heroine) if heroine != "" else null, 0.16)
	if auto:
		battle.delay = 0.0
		battle.policy = policy_override if policy_override.is_valid() else NRPolicy.choose
	if shot_hook.is_valid():
		battle.delay = 0.25
		battle.shot_hook = shot_hook
		var tag := "battle_boss" if RPG.game["enemies"][enemy_id].get("boss", false) else "battle"
		get_tree().create_timer(1.6).timeout.connect(func(): _shot(tag))
	var rounds_before := 0
	var res: String = await battle.start(enemy_id)
	var e: Dictionary = RPG.game["enemies"][enemy_id]
	var acts := 0
	for ev in battle.b["log"]:
		acts += 1
		pace["battle"] += 4.0 if ev["who"] == "enemy" else 12.0
	pace["battle"] += 15.0
	stats["battles"].append({"enemy": enemy_id, "result": res, "rounds": int(battle.b["round"]), "susp": int(battle.b["suspicion"]), "level": int(RPG.s["level"]), "actions": acts})
	if res == "lose":
		stats["losses"] += 1
		await _loss("lose_standoff")
		return "abort"
	var steps := [{"xp": int(e.get("xp", 30))}]
	if e.has("drop"):
		steps.push_front({"give": e["drop"]})
	# a game may pay the standoff's Trust only for a close win: Suspicion still under the bar
	var close := not e.has("trust_win_max_susp") or int(battle.b["suspicion"]) < int(e["trust_win_max_susp"])
	if e.has("trust_win") and int(e["trust_win"]) != 0 and not close and Loc.has("ev_trust_missed"):
		steps.append({"say": "narrator", "key": "ev_trust_missed"})
	if e.has("trust_win") and int(e["trust_win"]) != 0 and close:
		if e.get("trust_track", "") != "":
			steps.append({"trust": int(e["trust_win"]), "track": e["trust_track"]})
		elif RPG.flag(RPG.game.get("heroine_flag", "heroine_joined")):
			steps.append({"trust": int(e["trust_win"])})
	Sound.play_music(RPG.room().get("music", "explore"))
	return await run_steps(steps)


func _loss(key: String) -> void:
	event.close()
	hud.visible = false
	var p := PanelContainer.new()
	p.position = Vector2(290, 230)
	p.custom_minimum_size = Vector2(700, 220)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(NRSkin.heading(Loc.t(key + "_t"), 34))
	v.add_child(NRSkin.label(Loc.t(key), 20))
	var done := [false]
	v.add_child(NRSkin.button(Loc.t("lose_reload"), func(): done[0] = true, 22))
	await _shot("loss")
	while not auto and not done[0]:
		await get_tree().process_frame
	p.queue_free()
	if auto and stats["losses"] > 20:
		return
	RPG.load_slot(0)
	await resume_room()


func _dawn_loss() -> void:
	stats["losses"] += 1
	await _loss("lose_dawn")


# ------------------------------------------------------------------ level up

func level_up_flow() -> void:
	while int(RPG.s["pending_levels"]) > 0:
		RPG.s["pending_levels"] = int(RPG.s["pending_levels"]) - 1
		stats["levels"].append(int(RPG.s["level"]))
		pace["menus"] += 20.0
		for m in RPG.game["party"]:
			await _level_member(m["id"])


func _level_member(mid: String) -> void:
	var offers := RPG.skill_offers(mid)
	var md := RPG.member_def(mid)
	if (auto and not shot_hook.is_valid()) or not RPG.in_party(mid):
		RPG.apply_level_choice(mid, md.get("grow", ["wit"])[int(RPG.s["level"]) % md.get("grow", ["wit"]).size()], offers[0] if offers.size() > 0 else "")
		return
	_clear_overlay()
	event.box.visible = false
	event.name_panel.visible = false
	_dim()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", NRSkin.box("modal", 22))
	p.position = Vector2(240, 90)
	p.custom_minimum_size = Vector2(800, 520)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(NRSkin.heading(Loc.t("lv_title") % [Loc.t("n_" + mid), int(RPG.s["level"])], 34))
	v.add_child(NRSkin.label(Loc.t("lv_stat"), 20))
	var picked := {"st": "", "sk": ""}
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 8)
	v.add_child(sh)
	var stat_btns := []
	for st in RPG.game["stats"]:
		var b := NRSkin.button("%s %d" % [Loc.t("s_" + st), RPG.stat(mid, st)], func():
			picked["st"] = st
			for x in stat_btns:
				x.modulate = Color(1, 1, 1, 0.55)
			stat_btns[RPG.game["stats"].find(st)].modulate = Color(1, 1, 1, 1), 20)
		b.tooltip_text = Loc.t("sd_" + st)
		b.custom_minimum_size = Vector2(180, 48)
		stat_btns.append(b)
		sh.add_child(b)
	if offers.size() > 0:
		v.add_child(NRSkin.label(Loc.t("lv_skill"), 20))
		var sk_btns := []
		for sk in offers:
			var sd: Dictionary = RPG.game["skills"][sk]
			var b2 := NRSkin.button("%s  [%s]\n%s" % [Loc.t("sk_" + sk), Loc.t("br_" + sd["branch"]), Loc.t("skd_" + sk)], func():
				picked["sk"] = sk
				for x in sk_btns:
					x.modulate = Color(1, 1, 1, 0.55)
				sk_btns[offers.find(sk)].modulate = Color(1, 1, 1, 1), 18)
			b2.custom_minimum_size = Vector2(760, 70)
			b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sk_btns.append(b2)
			v.add_child(b2)
	var done := [false]
	var ok := NRSkin.button(Loc.t("lv_confirm"), func():
		if picked["st"] != "" and (picked["sk"] != "" or offers.is_empty()):
			done[0] = true, 22)
	v.add_child(ok)
	if auto:
		picked["st"] = md.get("grow", ["wit"])[0]
		picked["sk"] = offers[0] if offers.size() > 0 else ""
		if offers.size() > 0:
			v.get_child(v.get_child_count() - 1 - offers.size()).modulate = Color(1, 1, 1, 1)
		await _shot("levelup")
		done[0] = true
	while not done[0]:
		await get_tree().process_frame
	RPG.apply_level_choice(mid, picked["st"], picked["sk"])
	_clear_overlay()   # the panel and the dim behind it (the dim swallows clicks)


# ------------------------------------------------------------------ night end

func end_night(next: String) -> String:
	var nid: String = RPG.s["night"]
	if not (nid in RPG.s["nights_cleared"]):
		RPG.s["nights_cleared"].append(nid)
	stats["nights"].append(nid)
	stats["trust"] = RPG.trust_shown()
	event.close()
	if stop_after == nid:
		return "night_over"
	if RPG.is_trial() and nid == RPG.game.get("trial_last_night", ""):
		RPG.save(1)
		await show_trial_end()
		return "night_over"
	if next == "" or not RPG.nights.has(next):
		_clear_overlay()
		var p := PanelContainer.new()
		p.position = Vector2(290, 200)
		p.custom_minimum_size = Vector2(700, 260)
		overlay.add_child(p)
		var v := VBoxContainer.new()
		p.add_child(v)
		var fin := next == ""
		v.add_child(NRSkin.heading(Loc.t("fin_t" if fin else "end_t"), 34))
		v.add_child(NRSkin.label(Loc.t("fin_body" if fin else "end_body") % [int(RPG.s["level"]), RPG.trust_shown()], 20))
		await _shot("the_end" if fin else "night_end")
		RPG.save(1)
		var done := [false]
		if fin and RPG.game.get("more_screen", "") != "":
			v.add_child(NRSkin.button(Loc.t("t_more"), func(): show_more(), 22))
		v.add_child(NRSkin.button(Loc.t("end_title"), func(): done[0] = true, 22))
		while not auto and not done[0]:
			await get_tree().process_frame
		if not auto:
			show_title()
		return "night_over"
	RPG.save(1)
	await start_night(next)
	return "night_over"


# ------------------------------------------------------------------ menus

func _dim() -> void:
	var d := TextureRect.new()
	var sp := NRSkin.ui("dim")
	if sp != "" and ResourceLoader.exists(sp):
		d.texture = load(sp)
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_SCALE
	d.size = VIEW
	d.modulate = Color(0, 0, 0, 0.72)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(d)


func _modal(title: String, w: float = 1000, h: float = 600) -> VBoxContainer:
	_clear_overlay()
	hud.visible = false
	_dim()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", NRSkin.box("modal", 22))
	p.position = (VIEW - Vector2(w, h)) / 2
	p.custom_minimum_size = Vector2(w, h)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var hb := HBoxContainer.new()
	v.add_child(hb)
	var t := NRSkin.heading(title, 32)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	hb.add_child(NRSkin.button(Loc.t("m_close"), _close_modal, 20))
	return v


func _close_modal() -> void:
	_clear_overlay()
	if in_game:
		render_room()
	else:
		show_title()


func show_menu() -> void:
	var v := _modal(Loc.t("m_party"), 1120, 680)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tabs)
	# status
	tabs.add_theme_font_size_override("font_size", 22)
	var st := VBoxContainer.new()
	st.name = Loc.t("m_status")
	tabs.add_child(st)
	st.add_child(NRSkin.label(Loc.t("ms_level") % [int(RPG.s["level"]), int(RPG.s["xp"]), NRRules.xp_to_next(int(RPG.s["level"])), RPG.trust_shown()], 20))
	for m in RPG.game["party"]:
		var mid: String = m["id"]
		var parts := []
		for s2 in RPG.game["stats"]:
			parts.append("%s %d" % [Loc.t("s_" + s2), RPG.stat(mid, s2)])
		st.add_child(NRSkin.heading(Loc.t("n_" + mid), 24))
		st.add_child(NRSkin.label("   ".join(parts) + "   " + Loc.t("b_comp_nerve") % [int(RPG.s["members"][mid]["comp"]), RPG.comp_max(mid), int(RPG.s["members"][mid]["nerve"]), RPG.nerve_max(mid)], 18))
		var sk := []
		for x in RPG.s["members"][mid]["skills"]:
			sk.append(Loc.t("sk_" + x))
		st.add_child(NRSkin.label(Loc.t("ms_skills") + " " + (", ".join(sk) if sk.size() > 0 else "—"), 18))
	# items
	var it := VBoxContainer.new()
	it.name = Loc.t("m_items")
	tabs.add_child(it)
	for id in RPG.s["items"].keys():
		var d := RPG.item_def(id)
		if d.get("hidden", false):
			continue   # a tally the story counts, not something carried
		var row := HBoxContainer.new()
		var l := NRSkin.label("%s ×%d — %s" % [Loc.t("i_" + id), int(RPG.s["items"][id]), Loc.t("id_" + id)], 18)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if d.get("slot", "") != "":
			for m in RPG.game["party"]:
				if d.get("for", m["id"]) == m["id"]:
					var mid2: String = m["id"]
					row.add_child(NRSkin.button(Loc.t("m_equip_to") % Loc.t("n_" + mid2), func():
						RPG.equip(mid2, id)
						show_menu(), 16))
		if d.get("gift", false) and (d.get("gift_track", "") != "" or RPG.flag(RPG.game.get("heroine_flag", "heroine_joined"))):
			var gl: String = Loc.t("m_gift_to") % Loc.t("n_" + d["gift_track"]) if d.get("gift_track", "") != "" else Loc.t("m_gift")
			row.add_child(NRSkin.button(gl, func():
				RPG.take(id)
				RPG.add_trust(int(d.get("gift_trust", 1)), d.get("gift_track", ""))
				show_menu(), 16))
		it.add_child(row)
	# equipment: one column per member, filling the panel at sample size
	var eq := HBoxContainer.new()
	eq.name = Loc.t("m_equip")
	eq.add_theme_constant_override("separation", 24)
	tabs.add_child(eq)
	var stat_max := 20.0
	for m in RPG.game["party"]:
		var mid3: String = m["id"]
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)
		eq.add_child(col)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 14)
		col.add_child(head)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 4)
		head.add_child(info)
		info.add_child(NRSkin.heading(Loc.t("n_" + mid3), 30))
		info.add_child(NRSkin.label(Loc.t("b_comp_nerve") % [int(RPG.s["members"][mid3]["comp"]), RPG.comp_max(mid3), int(RPG.s["members"][mid3]["nerve"]), RPG.nerve_max(mid3)], 17, Color(0.75, 0.7, 0.65)))
		for s3 in RPG.game["stats"]:
			var srow := HBoxContainer.new()
			srow.add_theme_constant_override("separation", 10)
			var sl := NRSkin.label(Loc.t("s_" + s3), 22)
			sl.custom_minimum_size = Vector2(104, 0)
			srow.add_child(sl)
			var bar := NRSkin.meter("bar_fill_gold")
			bar.custom_minimum_size = Vector2(170, 22)
			bar.max_value = stat_max
			bar.value = RPG.stat(mid3, s3)
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			srow.add_child(bar)
			var vl := NRSkin.label(str(RPG.stat(mid3, s3)), 22, Color(0.87, 0.74, 0.52))
			vl.autowrap_mode = TextServer.AUTOWRAP_OFF
			vl.custom_minimum_size = Vector2(44, 0)
			srow.add_child(vl)
			info.add_child(srow)
		# outfit preview: whoever the equipped outfit (or default) has a sprite for
		var cur_outfit: String = RPG.s["members"][mid3]["equip"].get("outfit", "")
		var spr: String = RPG.item_def(cur_outfit).get("sprite", "") if cur_outfit != "" else ""
		if spr == "" and m.get("join_flag", "") != "":
			spr = RPG.game.get("heroine_sprite", "")
		var ptex: Texture2D = NRArt.tex("sprites", spr) if spr != "" and NRArt.path("sprites", spr) != "" else null
		if ptex != null:
			var pf := PanelContainer.new()
			pf.custom_minimum_size = Vector2(176, 250)
			var pv := TextureRect.new()
			pv.texture = ptex
			pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pv.custom_minimum_size = Vector2(176, 250)
			pf.add_child(pv)
			head.add_child(pf)
		for slot in ["outfit", "accessory", "tool"]:
			var cur: String = RPG.s["members"][mid3]["equip"][slot]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var l := NRSkin.label(Loc.t("slot_" + slot), 19, Color(0.87, 0.74, 0.52))
			l.custom_minimum_size = Vector2(120, 0)
			row.add_child(l)
			var nm := NRSkin.label(Loc.t("i_" + cur) if cur != "" else "—", 24)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nm)
			col.add_child(row)
			if cur != "":
				var dl := NRSkin.label(Loc.t("id_" + cur), 18, Color(0.75, 0.7, 0.65))
				dl.custom_minimum_size = Vector2(400, 0)
				col.add_child(dl)
		var spare := []
		for id in RPG.s["items"].keys():
			var d := RPG.item_def(id)
			if d.get("slot", "") != "" and d.get("for", mid3) == mid3:
				spare.append(Loc.t("i_" + id))
		if spare.size() > 0:
			var sp := NRSkin.label(Loc.t("m_items") + ": " + ", ".join(spare), 18, Color(0.75, 0.7, 0.65))
			sp.custom_minimum_size = Vector2(400, 0)
			col.add_child(sp)

func show_system() -> void:
	var v := _modal(Loc.t("m_system"), 520, 420)
	v.add_child(NRSkin.button(Loc.t("m_save"), func(): show_saves(true), 22))
	v.add_child(NRSkin.button(Loc.t("m_load"), func(): show_saves(false), 22))
	v.add_child(NRSkin.button(Loc.t("t_settings"), show_settings, 22))
	v.add_child(NRSkin.button(Loc.t("t_gallery"), show_gallery, 22))
	v.add_child(NRSkin.button(Loc.t("m_to_title"), show_title, 22))


func show_saves(saving: bool) -> void:
	var v := _modal(Loc.t("m_save") if saving else Loc.t("m_load"), 820, 600)
	for i in range(0 if not saving else 1, RPG.SLOTS):
		var info := RPG.slot_info(i)
		var t := Loc.t("sv_slot") % i if i > 0 else Loc.t("sv_auto")
		if info.is_empty():
			t += " — " + Loc.t("sv_empty")
		else:
			var nn: Dictionary = RPG.nights.get(info.get("night", ""), {})
			t += " — %s · %s · Lv %d · %s" % [Loc.t(nn.get("title_key", "")), Loc.t(nn.get("rooms", {}).get(info.get("room", ""), {}).get("name_key", "")), int(info.get("level", 1)), str(info.get("saved_at", ""))]
		var slot := i
		var b := NRSkin.button(t, func():
			if saving:
				RPG.save(slot)
				show_saves(true)
			elif RPG.load_slot(slot):
				_clear_overlay()
				resume_room(), 18)
		b.disabled = not saving and info.is_empty()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)


func show_gallery() -> void:
	var v := _modal(Loc.t("t_gallery"), 1180, 660)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(g)
	v.add_child(sc)
	for cg in RPG.game.get("gallery", []):
		if NRArt.path("cg", cg["id"]) == "":
			continue
		var have: bool = cg["id"] in RPG.persist["gallery"]
		var tb := TextureButton.new()
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		tb.custom_minimum_size = Vector2(270, 152)
		tb.texture_normal = NRArt.tex("cg", cg["thumb"] if have else cg["locked"])
		var cid: String = cg["id"]
		if have:
			tb.pressed.connect(func(): _view_cg(cid))
		var box := VBoxContainer.new()
		box.add_child(tb)
		var lock_txt: String = Loc.t("g_locked") % int(cg["trust"]) if int(cg.get("trust", 0)) > 0 else Loc.t("g_unseen")
		box.add_child(NRSkin.label(Loc.t(cg["key"]) if have else lock_txt, 15))
		g.add_child(box)


func _view_cg(id: String) -> void:
	var tr := TextureRect.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.size = VIEW
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = NRArt.tex("cg", id)
	tr.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			tr.queue_free())
	overlay.add_child(tr)


func show_settings() -> void:
	var v := _modal(Loc.t("t_settings"), 900, 680)
	v.add_child(NRSkin.label(Loc.t("st_lang"), 20))
	var g := GridContainer.new()
	g.columns = 4
	v.add_child(g)
	for l in Loc.LANGS:
		var cov := Loc.coverage(l)
		var name: String = Loc.LANG_NAMES[l]
		if cov < 0.95:
			name += " (%d%%)" % int(cov * 100)
		var b := NRSkin.button(name, func():
			Loc.set_lang(l)
			show_settings(), 18)
		if l == Loc.lang:
			b.modulate = Color(1, 0.9, 0.6)
		g.add_child(b)
	# voice pack: "same as text" or any language with recorded takes (English always)
	v.add_child(NRSkin.label(Loc.t("st_voice_lang"), 20))
	var gv := GridContainer.new()
	gv.columns = 4
	v.add_child(gv)
	var cur := str(RPG.persist.get("voice_lang", "auto"))
	for vl in ["auto"] + Loc.LANGS:
		if vl != "auto" and vl != "en" and Sound.voice_coverage(vl) <= 0.0:
			continue
		var vb := NRSkin.button(Loc.t("st_voice_auto") if vl == "auto" else Loc.LANG_NAMES[vl], func():
			RPG.persist["voice_lang"] = vl
			RPG.save_persist()
			show_settings(), 18)
		if vl == cur:
			vb.modulate = Color(1, 0.9, 0.6)
		gv.add_child(vb)
	# motion: breathing / sway on figures and CGs; off for players who prefer still images
	var mrow := HBoxContainer.new()
	v.add_child(mrow)
	var mlab := NRSkin.label(Loc.t("st_motion"), 18)
	mlab.custom_minimum_size = Vector2(260, 0)
	mrow.add_child(mlab)
	for on in [true, false]:
		var mb := NRSkin.button(Loc.t("st_on") if on else Loc.t("st_off"), func():
			RPG.persist["motion"] = on
			RPG.save_persist()
			for m in [stage.figure.material if stage != null else null, event.cg.material if event != null else null]:
				if m is ShaderMaterial:
					m.set_shader_parameter("motion", 1.0 if on else 0.0)
			show_settings(), 18)
		if NRAlive.enabled() == on:
			mb.modulate = Color(1, 0.9, 0.6)
		mrow.add_child(mb)
	for key in ["vol_music", "vol_sfx", "vol_voice"]:
		var row := HBoxContainer.new()
		v.add_child(row)
		var lab := NRSkin.label(Loc.t("st_" + key), 18)
		lab.custom_minimum_size = Vector2(260, 0)
		row.add_child(lab)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(RPG.persist.get(key, 0.8))
		s.custom_minimum_size = Vector2(500, 24)
		var k: String = key
		s.value_changed.connect(func(x):
			RPG.persist[k] = x
			RPG.save_persist()
			Sound.apply_volumes())
		row.add_child(s)


## The floor map: the night's painted map if it has one, room plates as thumbnails placed
## at their map positions; rooms not yet visited stay dark; the current room is lit.
func show_map() -> void:
	var v := _modal(Loc.t("m_map") + " — " + Loc.t(RPG.night().get("title_key", "")), 1180, 660)
	var area := Control.new()
	area.custom_minimum_size = Vector2(1140, 560)
	v.add_child(area)
	var mp: String = RPG.night().get("map", {}).get("image", "")
	if mp != "" and NRArt.path("maps", mp) != "":
		var bgm := TextureRect.new()
		bgm.texture = NRArt.tex("maps", mp)
		bgm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bgm.stretch_mode = TextureRect.STRETCH_SCALE
		bgm.size = Vector2(1140, 560)
		area.add_child(bgm)
	var pos: Dictionary = RPG.night().get("map", {}).get("rooms", {})
	for rid in pos.keys():
		var rd: Dictionary = RPG.night()["rooms"].get(rid, {})
		var seen: bool = RPG.s["done"].has("visited/" + rid) or rid == RPG.s["room"] or rid == RPG.night()["start_room"]
		var tr := TextureRect.new()
		var locked_tex := NRArt.tex("rooms_locked", rd.get("plate", rid)) if not seen and NRArt.path("rooms_locked", rd.get("plate", rid)) != "" else null
		tr.texture = locked_tex if locked_tex != null else NRArt.tex("rooms", rd.get("plate", rid))
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.size = Vector2(208, 117)
		tr.position = Vector2(float(pos[rid][0]) * 1140 - 104, float(pos[rid][1]) * 560 - 70)
		tr.modulate = Color(1, 1, 1) if rid == RPG.s["room"] else (Color(0.7, 0.68, 0.72) if seen else Color(0.85, 0.82, 0.88))
		area.add_child(tr)
		var l := NRSkin.label(Loc.t(rd.get("name_key", "")) if seen else "?", 17, Color(0.87, 0.74, 0.52) if rid == RPG.s["room"] else Color(0.85, 0.8, 0.75))
		l.position = tr.position + Vector2(0, 118)
		l.size = Vector2(208, 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		area.add_child(l)



## A game's own "more from the studio" screen (game.json "more_screen"): a Control with
## `func run(main, args) -> String`, shown over whatever is on screen and closed by itself.
func show_more() -> void:
	var scr: Control = load(RPG.game["more_screen"]).new()
	ui.add_child(scr)
	await scr.run(self, {})
	scr.queue_free()


## AI-use disclosure + adult notice: shown at every launch before the title, and from the
## title's About button. Language buttons on it, so a Japanese player can read it first.
func show_disclosure(then_title: bool) -> void:
	_clear_overlay()
	hud.visible = false
	stage.set_plate(load(RPG.game["title_bg"]), {"ambient": "#403840", "torch": false})
	stage.set_figure(null)
	_dim()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", NRSkin.box("modal", 22))
	p.position = Vector2(170, 70)
	p.custom_minimum_size = Vector2(940, 560)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(NRSkin.heading(Loc.t("ds_title"), 32))
	v.add_child(NRSkin.label(Loc.t("ds_adult"), 20, Color(0.87, 0.74, 0.52)))
	var body := NRSkin.label(Loc.t(RPG.game["disclosure_key"]), 19)
	body.custom_minimum_size = Vector2(880, 0)
	v.add_child(body)
	var hb := GridContainer.new()
	hb.columns = 7
	hb.add_theme_constant_override("h_separation", 6)
	v.add_child(hb)
	for l in Loc.LANGS:
		if Loc.coverage(l) < 0.9:
			continue
		hb.add_child(NRSkin.button(Loc.LANG_NAMES[l], func():
			Loc.set_lang(l)
			show_disclosure(then_title), 18))
	var ok := NRSkin.button(Loc.t("ds_continue"), func():
		if then_title:
			show_title()
		else:
			_close_modal(), 22)
	v.add_child(ok)


func show_trial_end() -> void:
	_clear_overlay()
	hud.visible = false
	event.close()
	_dim()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", NRSkin.box("modal", 22))
	p.position = Vector2(190, 110)
	p.custom_minimum_size = Vector2(900, 480)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	# bilingual on purpose, like the VN trial's last screen: the player's language, then Japanese
	# (the store's own language) -- or English when the player reads Japanese
	var second := "en" if Loc.lang == "ja" else "ja"
	var langs := [Loc.lang, second]
	for k in ["tr_end_title", "tr_end_body"]:
		var row: Dictionary = Loc.table.get(k, {})
		for i in 2:
			var txt := str(row.get(langs[i], "")) if str(row.get(langs[i], "")) != "" else str(row.get("en", ""))
			v.add_child(NRSkin.heading(txt, 30 - 4 * i) if k == "tr_end_title" else NRSkin.label(txt, 20 - i))
	var both := func(key: String) -> String:
		var row: Dictionary = Loc.table.get(key, {})
		return Loc.t(key) + " / " + str(row.get(second, row.get("en", "")))
	var done := [false]
	if RPG.game.get("store_url", "") != "":
		v.add_child(NRSkin.button(both.call("tr_open_store"), func(): OS.shell_open(RPG.game["store_url"]), 20))
	v.add_child(NRSkin.button(both.call("tr_back"), func(): done[0] = true, 20))
	await _shot("trial_end")
	while not auto and not done[0]:
		await get_tree().process_frame
	if not auto:
		show_title()
