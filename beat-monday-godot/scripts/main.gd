## Main — the screens, the input, the frame loop. The reflex loop lives in BMCore; the
## other nodes in BMTriage / BMReview / BMDeploy / BMEvents; the building in BMMap. This
## file only wires them (the HTML spec's main.js, grown a map). Screens are built in code
## so they live in git as text and share one Theme (StudioTheme). One thumb: drag anywhere
## on the arena to move; everything else is a tap.
##
## Flow (ops/adult_forks/beat_monday_map.md): title -> map -> tap a room -> walk -> the
## room's brief -> its node -> result -> map. Friday's deploy rolls the week; the weekend
## screen leads back to a fresh map.
extends Control

const CJK := "res://assets/fonts/NotoSansCJK-subset.otf"
## node id -> which plate the brief and the node play on
const NODE_PLATE := {"lobby": "lobby", "breakroom": "breakroom", "standup": "mon", "corridor1": "corridor",
	"inbox": "tue", "allhands": "wed", "review": "thu", "corridor2": "corridor", "deploy": "fri"}
const NODE_ACTOR := {"standup": "standup", "inbox": "inbox", "allhands": "allhands", "review": "review", "deploy": "deploy"}

var arena: Node2D
var hud: Control
var overlay: Control
var map: Node2D
var run: Dictionary = {}
var target = null
var autopilot := false
var screen := "title"
var down := false
var day_started := 0.0
var lvl_cards: Array = []
var node_id := ""             # the room the current node belongs to
var xrun: Dictionary = {}     # a thinking node's pseudo-run (level-ups, the result)
var triage: Dictionary = {}
var review: Dictionary = {}
var placement: Dictionary = {}
var tri_selected := -1
var dp_tile := -1
var toast_label: Label


class IconBox extends Control:
	var fn: Callable
	func _init(f: Callable, sz: Vector2, sc := 1.0) -> void:
		fn = f
		custom_minimum_size = sz
		size = sz
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# the sprite library resets the canvas transform inside its own calls, so a
		# thumbnail scales the Control, never the draw transform
		scale = Vector2(sc, sc)
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		fn.call(self)


func _ready() -> void:
	theme = StudioTheme.build()
	_install_cjk()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	arena = Node2D.new()
	arena.set_script(load("res://scripts/arena.gd"))
	add_child(arena)
	map = Node2D.new()
	map.set_script(load("res://scripts/map_screen.gd"))
	map.visible = false
	add_child(map)
	map.tapped.connect(_on_map_tap)
	map.arrived.connect(_on_map_arrive)
	hud = Control.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	Game.bridge_handler = _bridge
	BMMap.ensure(Game.profile)
	show_title()


## The three Latin faces carry no CJK; the zh-Hans strings and the corpus fall through to
## a Noto subset (tools/subset_cjk.py). Same mechanism as silvertongue's symbols.gd, with
## one lesson from the web export: ResourceCache holds resources weakly, so a FontFile
## loaded here and dropped at the end of the function is freed and re-read fresh — with
## no fallbacks — the next time the Theme asks for it. The Theme is built first (its static
## cache keeps the instances) and the fonts are kept here too.
var _kept_fonts: Array = []

func _install_cjk() -> void:
	var fb: Font = load(CJK)
	if fb == null:
		return
	_kept_fonts.append(fb)
	for path in [StudioTheme.FONT_DISPLAY, StudioTheme.FONT_UI, StudioTheme.FONT_ITALIC]:
		var f: Font = load(path)
		_kept_fonts.append(f)
		if f is FontFile and (f as FontFile).fallbacks.is_empty():
			(f as FontFile).fallbacks = [fb]


# ---------- helpers ----------------------------------------------------------------------------
func t(k: String, v: Dictionary = {}) -> String:
	return BMStrings.t(k, v)


func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()
	lvl_cards.clear()
	toast_label = null


func _show(name: String) -> void:
	screen = name
	Game.tel("screen", {"screen": name})


func _dim(alpha: float) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(Palette.GROUND_DEEP, alpha)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(d)
	return d


func _plate(name: String) -> void:
	var path: String = map.plate_path(name)
	if path == "":
		return
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(tr)


func _label(text: String, variation: String = "", size: int = 0, color := Color(0, 0, 0, 0), wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0:
		l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 300
	return l


func _button(text: String, variation: String, fn: Callable, min_w := 220.0) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_w, 46)
	b.pressed.connect(Sfx.tap)
	b.pressed.connect(fn)
	return b


func _panel(pos_y: float, width := 340.0, variation := "Glass") -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.theme_type_variation = variation
	pc.position = Vector2((BMCore.W - width) / 2, pos_y)
	pc.custom_minimum_size.x = width
	pc.size.x = width
	overlay.add_child(pc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	return v


## A rendered actor (or its vector rig) as a thumbnail Control.
func _actor_box(id: String, height: float, box := Vector2(160, 150)) -> Control:
	var c := IconBox.new(func(ci): _draw_actor_thumb(ci, id, height, box), box)
	c.custom_minimum_size = box
	return c


func _draw_actor_thumb(ci: CanvasItem, id: String, height: float, box: Vector2) -> void:
	if Sprites.actor(ci, id, Vector2(box.x / 2, box.y - 4), height, 1.0, Color(1, 1, 1), absf(sin(arena.clock * 1.5)) * 2.0):
		return
	match id:
		"player":
			Sprites.player(ci, Vector2(box.x / 2, box.y / 2), arena.clock, 0.0, 1.0, 0.0, false, false)
		"intern", "pm", "hr":
			Sprites.colleague(ci, Vector2(box.x / 2, box.y / 2), arena.clock, id, 1.6)
		_:
			var day := ""
			for d in BMData.DAYS:
				if d["boss"] == id:
					day = d["id"]
			Sprites.boss(ci, {"x": box.x / 2, "y": box.y / 2, "hit": 0.0}, day, arena.clock)


func _toast(text: String) -> void:
	if toast_label == null or not is_instance_valid(toast_label):
		toast_label = _label("", "Tag", 12, Palette.GOLD)
		toast_label.position = Vector2(0, 600)
		toast_label.size.x = BMCore.W
		overlay.add_child(toast_label)
	toast_label.text = text


func _stop_run() -> void:
	run = {}
	arena.set_run({})
	arena.placement = {}
	hud.run = {}


func _stats_line() -> String:
	var s := BMCore.compute_stats(Game.profile)
	return t("stats", {"lv": Game.profile["level"], "hp": s["hp"], "atk": s["atk"], "rate": s["rate"]})


func _has_progress() -> bool:
	return Game.profile["cleared"].size() > 0 or int(Game.profile["week"]) > 0 or BMMap.ensure(Game.profile)["cleared"].size() > 0


# ---------- title ------------------------------------------------------------------------------
## 2026-09-20: this screen is now scripts/bm_title.gd, and what it replaces is worth
## keeping a description of, because it is the shape every screen in this file still has
## and only this one has been pulled out of it.
##
## It was: _plate("title") — which resolved through map_screen.FALLBACK to the *corridor*
## plate, an unlit office corridor — then _dim(0.35) over the top of it, then two rounded
## navy "Glass" PanelContainers, the wordmark a plain Label inside the upper one. Captured
## and measured it scored 0.31 brightness against the shelf floor of 0.45.
##
## Two rules broken, both named in bm_title.gd's own header: studio rule 2 (the two Glass
## panels *were* the design, and a StyleBoxFlat rectangle is not a design) and the
## all-ages direction (kids play this; the night-office mood belongs to the adult forks).
##
## The title node owns its own layout, motion and marks and emits three signals; this
## function only wires them to the screens that already existed. Everything else in the
## flow — show_map, show_desk, the language toggle, the tests/headless_web.py bridge's
## "open title" — is untouched and still calls this.
func show_title() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	var title := Control.new()
	title.set_script(load("res://scripts/bm_title.gd"))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(title)
	title.start_pressed.connect(show_map)
	title.desk_pressed.connect(show_desk)
	title.lang_pressed.connect(func():
		Game.set_lang("en" if Game.lang == "zh" else "zh")
		show_title())
	_show("title")


# ---------- the map ----------------------------------------------------------------------------
func show_map() -> void:
	_clear_overlay()
	_stop_run()
	BMMap.ensure(Game.profile)
	map.visible = true
	map.refresh(Game.profile)
	var strip := PanelContainer.new()
	strip.theme_type_variation = "Glass"
	strip.position = Vector2(10, 8)
	strip.custom_minimum_size = Vector2(BMCore.W - 20, 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_label(t("map_title", {"n": int(Game.profile["week"]) + 1}), "Title", 20, Palette.TEXT))
	v.add_child(_label(_stats_line() + " · " + t("credits", {"n": int(Game.profile.get("credits", 0))}), "Tag", 10, Palette.GOLD))
	strip.add_child(v)
	overlay.add_child(strip)
	var hint := _label(t("map_hint"), "Tag", 10, Palette.MUTED)
	hint.position = Vector2(0, 608)
	hint.size.x = BMCore.W
	overlay.add_child(hint)
	_show("map")


func _on_map_tap(id: String) -> void:
	if screen != "map" or map.walking:
		return
	var path := BMMap.path(Game.profile, BMMap.at(Game.profile), id)
	if path.is_empty():
		_toast(t("locked"))
		Sfx.hurt()
		return
	Sfx.tap()
	Game.tel("walk", {"to": id, "steps": path.size()})
	map.walk(path)


func _on_map_arrive(id: String) -> void:
	BMMap.set_at(Game.profile, id)
	Game.save()
	if screen == "map":
		show_node(id)


## The room's brief: name, what it demands, the actor who runs it, ENTER / BACK.
func show_node(id: String) -> void:
	_clear_overlay()
	map.visible = false
	node_id = id
	var n := BMMap.node(id)
	var st := BMMap.state(Game.profile, id)
	arena.set_run({})
	_plate(NODE_PLATE.get(id, "mon"))
	_dim(0.5)
	var v := _panel(110, 340, "Glass")
	v.add_child(_label(t("floor_%d" % int(n["floor"])) + " · " + t("kind_" + n["type"]).to_upper(), "Tag", 11, Palette.TUBE))
	v.add_child(_label(t("node_" + id), "Title", 30, Palette.TEXT))
	if NODE_ACTOR.has(id):
		v.add_child(_actor_box(NODE_ACTOR[id], 140.0))
	match n["type"]:
		"start":
			v.add_child(_label(t("lobby_body"), "", 15, Palette.TEXT, true))
			v.add_child(_button(t("back_map"), "Primary", show_map))
		"break":
			show_breakroom()
			return
		"event":
			show_event(id)
			return
		_:
			var day: Dictionary = BMData.DAYS[int(n["day"])]
			var body := t("brief_" + day["id"]) + ("\n\n" + t("rant_hint") if day["mode"] == "rant" else "")
			if n["type"] == "inbox":
				body = t("brief_tue") + "\n\n" + t("tri_hint")
			elif n["type"] == "review":
				body = t("brief_thu") + "\n\n" + t("rv_hint")
			elif n["type"] == "deploy":
				body = t("brief_fri") + "\n\n" + t("dp_hint")
			v.add_child(_label(body, "", 14, Palette.TEXT, true))
			if st == "cleared":
				v.add_child(_label(t("cleared_tag") + " · " + t("runs", {"n": int(BMMap.ensure(Game.profile)["runs"].get(id, 0))}), "Tag", 11, Palette.GOLD))
			v.add_child(_button(t("rerun") if st == "cleared" else t("go"), "Primary", func(): enter_node(id)))
			v.add_child(_button(t("back_map"), "Ghost", show_map, 160))
	_show("node")


func enter_node(id: String) -> void:
	node_id = id
	var n := BMMap.node(id)
	Game.tel("node", {"id": id, "type": n["type"], "week": Game.profile["week"]})
	match n["type"]:
		"standup", "allhands":
			start_day(int(n["day"]))
		"inbox":
			show_triage()
		"review":
			show_review()
		"deploy":
			show_placement()
		"event":
			show_event(id)
		"break":
			show_breakroom()
		_:
			show_map()


# ---------- the reflex day (standup, all-hands, and the deploy after placement) ---------------
func start_day(i: int) -> void:
	_clear_overlay()
	map.visible = false
	run = BMCore.create_run(Game.profile, i, Time.get_ticks_msec() & 0xffff)
	run["lang"] = Game.lang
	# the corridor's consequence: the next run's starting HP
	var mod := BMEvents.take_hp_mod(Game.profile)
	if mod != 1.0:
		run["hp"] = clampf(run["maxHp"] * mod, 10.0, run["maxHp"])
	if BMData.DAYS[i]["boss"] == "deploy" and not placement.is_empty():
		run["stats"]["partyDps"] = 0    # the turrets replace the orbit
		arena.placement = placement
	else:
		arena.placement = {}
	target = {"x": run["px"], "y": run["py"]}
	arena.set_run(run)
	hud.run = run
	day_started = Time.get_ticks_msec() / 1000.0
	Game.tel_play_start({"day": BMData.DAYS[i]["id"], "week": Game.profile["week"], "node": node_id})
	_show("")


func _process(dt: float) -> void:
	if run.is_empty() or screen != "":
		return
	dt = minf(0.05, dt)
	if autopilot:
		var n := BMCore.nearest_foe(run)
		if not n.is_empty():
			var dx: float = run["px"] - n["x"]
			var dy: float = run["py"] - n["y"]
			var m := BMCore.hypot(dx, dy)
			if m == 0.0:
				m = 1.0
			var pull := (Vector2(BMCore.W / 2, BMCore.H * 0.6) - Vector2(run["px"], run["py"])) * 0.5
			target = {"x": maxf(30, minf(BMCore.W - 30, run["px"] + dx / m * 120 + pull.x)),
				"y": maxf(90, minf(BMCore.H - 30, run["py"] + dy / m * 120 + pull.y))}
	BMCore.step(run, dt, target)
	if not arena.placement.is_empty():
		BMDeploy.apply(run, arena.placement, dt)
	if run["pending"] != null:
		show_levelup(run)
	elif run["over"] != null:
		finish()


func _gui_input(e: InputEvent) -> void:
	if screen != "" or run.is_empty():
		return
	if e is InputEventMouseButton:
		down = e.pressed
		if down:
			target = {"x": e.position.x, "y": e.position.y}
	elif e is InputEventMouseMotion and down:
		target = {"x": e.position.x, "y": e.position.y}


## The pick-one-of-three, for any run dictionary with `pending` (the reflex run or a
## thinking node's pseudo-run). `after` is called once the pick is made.
var _lvl_run: Dictionary = {}
var _lvl_after: Callable = Callable()

func show_levelup(r: Dictionary, after: Callable = Callable()) -> void:
	_clear_overlay()
	_lvl_run = r
	_lvl_after = after
	_dim(0.62)
	var head := _panel(90, 300, "Glass")
	head.add_child(_label(t("lvup", {"n": r["level"]}), "Title", 34, Palette.GOLD))
	head.add_child(_label(t("pick"), "Tag", 13, Palette.TUBE))
	Sfx.levelup()
	var ids: Array = r["pending"]
	for i in ids.size():
		var id: String = ids[i]
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		card.custom_minimum_size = Vector2(300, 78)
		card.position = Vector2(60, 250 + i * 96)
		card.pivot_offset = Vector2(150, 39)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		card.add_child(h)
		h.add_child(IconBox.new(func(ci): Sprites.skill_icon(ci, id, Vector2(26, 26), 44), Vector2(52, 52)))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var n := _label(t("sk_" + id), "Value", 18, Palette.TEXT)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var dsc := _label(t("skd_" + id), "Tag", 12, Palette.MUTED)
		dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(n)
		vb.add_child(dsc)
		h.add_child(vb)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: pick_skill(id))
		overlay.add_child(card)
		lvl_cards.append(card)
		# the fan: from below, tilted, one after another
		var final := card.position
		card.position = final + Vector2(0, 260)
		card.rotation = -0.18 + i * 0.18
		card.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(card, "position", final, 0.42).set_delay(i * 0.09)
		tw.tween_property(card, "rotation", 0.0, 0.42).set_delay(i * 0.09)
		tw.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(i * 0.09)
	_show("lvup")


func pick_skill(id: String) -> void:
	if _lvl_run.is_empty() or _lvl_run["pending"] == null:
		return
	if BMCore.apply_skill(_lvl_run, id):
		Game.tel("skill", {"id": id, "level": _lvl_run["level"]})
		_clear_overlay()
		if _lvl_after.is_valid():
			_lvl_after.call()
		else:
			_show("")


func finish() -> void:
	var won: bool = run["over"] == "clear"
	var idx: int = run["dayIndex"]
	if won:
		Sfx.clear()
	else:
		Sfx.dead()
	if won:
		BMMap.clear(Game.profile, node_id)   # before the commit: Friday's commit rolls the week
	BMCore.commit_run(Game.profile, run)
	Game.save()
	Game.tel_play_end({"day": BMData.DAYS[idx]["id"], "won": won, "kills": run["kills"], "node": node_id}, int(Time.get_ticks_msec() / 1000.0 - day_started))
	var retry := func(): start_day(idx)
	_result(won, t("cleared") if won else t("dead"), t("kills", {"n": run["kills"]}), run, retry)


## The result panel shared by every node: what was picked up, who joined, where next.
func _result(won: bool, head: String, sub: String, r: Dictionary, retry: Callable) -> void:
	_clear_overlay()
	map.visible = false
	_dim(0.55)
	var v := _panel(150, 340, "Glass")
	v.add_child(_label(head, "Title", 28, Palette.GOLD if won else Palette.HEAT))
	v.add_child(_label(sub, "Tag", 12, Palette.MUTED))
	var day_id: String = r["day"]["id"] if r.has("day") else ""
	if won and r.get("reward") != null:
		var rid: String = r["reward"]
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(IconBox.new(func(ci): Sprites.equip_icon(ci, rid, Vector2(24, 24), 40), Vector2(48, 48)))
		var l := _label(t("got", {"item": t("eq_" + rid)}), "Value", 15)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		v.add_child(h)
	if won and day_id != "":
		for p in BMData.PARTY:
			if p["after"] == day_id and r.get("_joined", true):
				var pid: String = p["id"]
				var h2 := HBoxContainer.new()
				h2.alignment = BoxContainer.ALIGNMENT_CENTER
				h2.add_child(IconBox.new(func(ci): if not Sprites.actor(ci, pid, Vector2(24, 46), 44.0): Sprites.colleague(ci, Vector2(24, 30), arena.clock, pid, 1.0), Vector2(48, 48)))
				var l2 := _label(t("joined", {"who": t("pt_" + pid)}), "Value", 15, Palette.SUCCESS)
				l2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h2.add_child(l2)
				v.add_child(h2)
	var go := func():
		if not won:
			retry.call()
		elif Game.profile.get("weekend", false):
			Game.profile["weekend"] = false
			Game.save()
			show_weekend()
		else:
			show_map()
	v.add_child(_button(t("back_map") if won else t("retry"), "Primary", go))
	if not won:
		v.add_child(_button(t("back_map"), "Ghost", show_map, 160))
	v.add_child(_button(t("locker"), "Amber", show_desk, 160))
	_show("result")
	# cross-promotion, once per session, after a node ends: offered behind a timer, never forced
	get_tree().create_timer(0.9).timeout.connect(Game.offer_board)


## A thinking node ended: commit through the ported progression, then level-ups, then the
## result.
func _finish_thinking(won: bool, xp: int, head: String, sub: String, retry: Callable) -> void:
	if won:
		Sfx.clear()
	else:
		Sfx.dead()
	var joined_before: int = Game.profile["party"].size()
	xrun = BMMap.commit_thinking(Game.profile, node_id, xp, won)
	xrun["_joined"] = Game.profile["party"].size() > joined_before
	Game.save()
	Game.tel_play_end({"day": xrun["day"]["id"], "won": won, "node": node_id, "xp": xp}, int(Time.get_ticks_msec() / 1000.0 - day_started))
	var show := func(): _result(won, head, sub, xrun, retry)
	if xrun["pending"] != null:
		show_levelup(xrun, show)
	else:
		show.call()


# ---------- the inbox: triage --------------------------------------------------------------------
func show_triage() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	triage = BMTriage.new_triage(Game.profile, Time.get_ticks_msec() & 0xffff)
	tri_selected = -1
	day_started = Time.get_ticks_msec() / 1000.0
	Game.tel_play_start({"day": "tue", "week": Game.profile["week"], "node": node_id})
	_draw_triage()


func _draw_triage() -> void:
	_clear_overlay()
	_plate("tue")
	_dim(0.55)
	var tr := triage
	# the strip: turn, actions, stress
	var top := _panel(8, 400, "Glass")
	top.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.add_child(_label(t("tri_turn", {"t": tr["turn"], "max": tr["turns"]}), "Tag", 12, Palette.TUBE))
	row.add_child(_label(t("tri_actions", {"n": tr["actions"]}), "Value", 16, Palette.GOLD))
	row.add_child(_label(t("tri_pile", {"n": tr["deck"].size()}), "Tag", 12, Palette.MUTED))
	top.add_child(row)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = BMTriage.STRESS_MAX
	bar.value = tr["stress"]
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(360, 10)
	top.add_child(bar)
	top.add_child(_label(t("tri_stress") + " %d" % int(tr["stress"]), "Tag", 9, Palette.HEAT))
	# the hand
	for i in tr["hand"].size():
		var m: Dictionary = tr["hand"][i]
		var kind: String = m["kind"]
		var card := PanelContainer.new()
		card.theme_type_variation = "Active" if i == tri_selected else "Card"
		card.position = Vector2(20, 112 + i * 66)
		card.custom_minimum_size = Vector2(380, 58)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var uid: int = int(m["uid"])
		card.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: tri_selected = i; Sfx.tap(); _draw_triage())
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var icon := IconBox.new(func(ci): Sprites.foe(ci, {"x": 22.0, "y": 24.0, "r": float(BMData.FOES[kind]["r"]), "kind": kind, "hit": 0.0, "vx": 1.0, "vy": 0.0}, arena.clock), Vector2(44, 48))
		h.add_child(icon)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var subj := _label(t("msgs_" + kind), "Value", 15, Palette.TEXT)
		subj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var meta := _label(t("msg_" + kind).to_upper() + " · " + t("tri_cost", {"n": m["cost"]}) + " · " + t("tri_urg", {"n": m["urg"]})
			+ ("  " + t("tri_esc") if int(m["esc"]) > 0 else "") + ("  ↺" if BMTriage.KINDS[kind]["sticky"] else ""), "Tag", 10,
			Palette.HEAT if int(m["urg"]) <= 1 else Palette.MUTED)
		meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(subj)
		vb.add_child(meta)
		h.add_child(vb)
		card.add_child(h)
		overlay.add_child(card)
	# the actions
	var acts := HBoxContainer.new()
	acts.position = Vector2(14, 452)
	acts.add_theme_constant_override("separation", 6)
	for a in ["reply", "archive", "delegate", "snooze"]:
		var aid: String = a
		var b := _button(t("act_" + a), "Button", func(): _tri_act(aid), 94.0)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tri_selected < 0 or tri_selected >= tr["hand"].size()
		acts.add_child(b)
	overlay.add_child(acts)
	var endb := _button(t("act_end"), "Primary", _tri_end, 200.0)
	endb.position = Vector2(110, 508)
	overlay.add_child(endb)
	var hint := _label(t("tri_hint"), "Tag", 9, Palette.MUTED, true)
	hint.custom_minimum_size.x = 380
	hint.position = Vector2(20, 560)
	overlay.add_child(hint)
	_show("triage")


func _tri_act(action: String) -> void:
	if tri_selected < 0 or tri_selected >= triage["hand"].size():
		return
	var uid: int = int(triage["hand"][tri_selected]["uid"])
	var why := BMTriage.act(triage, action, uid)
	if why != "":
		_draw_triage()
		_toast(t("why_" + why))
		return
	Sfx.hit()
	tri_selected = -1
	Game.tel("triage", {"act": action})
	if triage["over"] != null:
		_tri_over()
	else:
		_draw_triage()


func _tri_end() -> void:
	BMTriage.end_turn(triage)
	if int(triage.get("lastHit", 0)) > 0:
		Sfx.hurt()
	tri_selected = -1
	if triage["over"] != null:
		_tri_over()
	else:
		_draw_triage()


func _tri_over() -> void:
	var won: bool = triage["over"] == "clear"
	_finish_thinking(won, int(triage["xp"]), t("tri_clear") if won else t("tri_lost"),
		t("kills", {"n": triage["cleared"]}), show_triage)


# ---------- the review: dialogue tactics ---------------------------------------------------------
func show_review() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	review = BMReview.new_review(int(Game.profile["week"]), Time.get_ticks_msec() & 0xffff)
	day_started = Time.get_ticks_msec() / 1000.0
	Game.tel_play_start({"day": "thu", "week": Game.profile["week"], "node": node_id, "scenario": review["scenario"]})
	_draw_review()


func _sig_names(list: Array, prefix := "sig_") -> String:
	var out: Array = []
	for s in list:
		out.append(t(prefix + str(s)))
	return " + ".join(out)


func _draw_review() -> void:
	_clear_overlay()
	_plate("thu")
	_dim(0.55)
	var rv := review
	var pr := BMReview.progress(rv)
	# the manager and her reply
	var head := _panel(6, 400, "Glass")
	head.add_theme_constant_override("separation", 3)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(_actor_box("review", 96.0, Vector2(90, 100)))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.add_child(_label(t("rv_turn", {"t": rv["turn"], "max": rv["maxTurns"]}) + " · " + t("rv_momentum") + " %.2f" % float(pr["momentum"]), "Tag", 10, Palette.TUBE))
	var say := _label(t("rv_reply_" + rv["reply"]), "", 14, Palette.TEXT, true)
	say.custom_minimum_size.x = 270
	say.add_theme_font_override("font", StudioTheme.font("italic"))
	vb.add_child(say)
	hb.add_child(vb)
	head.add_child(hb)
	# the rule: the row, with what is already held lit
	var want: Array = []
	for s in pr["path"]:
		want.append(("✓ " if pr["have"][s] else "") + t("sig_" + str(s)))
	head.add_child(_label(t("rv_rule", {"path": " + ".join(want)}), "Tag", 11, Palette.GOLD))
	var help: Array = []
	for s in pr["help"]:
		help.append(("✓ " if pr["help"][s] else "") + t("sig_" + str(s)))
	if help.size():
		head.add_child(_label(t("rv_help", {"help": " + ".join(help)}), "Tag", 10, Palette.TUBE))
	if pr["harms"].size():
		head.add_child(_label(_sig_names(pr["harms"], "harm_"), "Tag", 10, Palette.HEAT))
	# the hand
	for i in rv["hand"].size():
		var cid: String = rv["hand"][i]
		var c := BMReview.card(cid)
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		card.position = Vector2(20, 214 + i * 84)
		card.custom_minimum_size = Vector2(380, 76)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _rv_play(cid))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var line := _label(t("rv_" + cid) if Game.lang == "zh" else c["line"], "", 14, Palette.TEXT, true)
		line.custom_minimum_size.x = 350
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(line)
		var face: String
		var col: Color
		if c["rarity"] == "coercion":
			face = t("rv_face_coerce")
			col = Palette.ACCENT
		else:
			face = _sig_names(c["signals"])
			col = Palette.GOLD if c["rarity"] == "epic" else (Palette.RARE if c["rarity"] == "rare" else Palette.TUBE)
		var fl := _label(face, "Tag", 10, col)
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(fl)
		card.add_child(v)
		overlay.add_child(card)
	var small := _label(t("rv_small"), "Tag", 9, Palette.MUTED, true)
	small.custom_minimum_size.x = 380
	small.position = Vector2(20, 556)
	overlay.add_child(small)
	_show("review")


func _rv_play(cid: String) -> void:
	if not BMReview.play(review, cid):
		return
	Sfx.rant()
	Game.tel("review", {"card": cid, "phase": review["state"]["phase"]})
	if review["over"] != null:
		var won: bool = review["over"] == "clear"
		_draw_review()
		var xp := BMReview.xp_for(review)
		get_tree().create_timer(1.1).timeout.connect(func():
			_finish_thinking(won, xp, t("rv_clear") if won else t("rv_lost"),
				t("rv_turn", {"t": review["turn"], "max": review["maxTurns"]}), show_review))
	else:
		_draw_review()


# ---------- the deploy: placement, then the boss day ------------------------------------------
func show_placement() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	placement = BMDeploy.new_placement()
	dp_tile = -1
	_draw_placement()


func _draw_placement() -> void:
	_clear_overlay()
	_plate("fri")
	_dim(0.45)
	var top := _panel(6, 400, "Glass")
	top.add_theme_constant_override("separation", 2)
	top.add_child(_label(t("boss_deploy") + " · " + t("dp_title"), "Title", 20, Palette.TEXT))
	top.add_child(_label(t("dp_hint"), "Tag", 10, Palette.MUTED, true))
	for i in BMDeploy.TILES.size():
		var tp: Vector2 = BMDeploy.TILES[i]
		var tile := PanelContainer.new()
		tile.theme_type_variation = "Active" if i == dp_tile else "Card"
		tile.position = tp - Vector2(48, 44)
		tile.custom_minimum_size = Vector2(96, 88)
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		var ti := i
		tile.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: dp_tile = ti; Sfx.tap(); _draw_placement())
		var it = placement["tiles"].get(i)
		if it != null:
			var iid: String = it["id"]
			var kind: String = it["kind"]
			var vb := VBoxContainer.new()
			vb.alignment = BoxContainer.ALIGNMENT_CENTER
			if kind == "party":
				vb.add_child(_actor_box(iid, 48.0, Vector2(88, 52)))
				vb.add_child(_label(t("pt_" + iid).split(",")[0], "Tag", 9, Palette.TEXT))
			else:
				vb.add_child(IconBox.new(func(ci): Sprites.equip_icon(ci, iid, Vector2(44, 26), 36), Vector2(88, 52)))
				vb.add_child(_label(t("eq_" + iid), "Tag", 9, Palette.TEXT))
			tile.add_child(vb)
		overlay.add_child(tile)
	# the tray
	var tray := _panel(450, 400, "Glass")
	tray.add_theme_constant_override("separation", 4)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var placed := BMDeploy.placed_ids(placement)
	for c in BMDeploy.what_can_go(Game.profile):
		var cid: String = c["id"]
		var ck: String = c["kind"]
		var b := Button.new()
		b.custom_minimum_size = Vector2(122, 40)
		b.theme_type_variation = "Active" if placed.has(cid) else "Button"
		b.add_theme_font_size_override("font_size", 10)
		b.text = (t("pt_" + cid).split(",")[0] if ck == "party" else t("eq_" + cid))
		b.tooltip_text = t("aura_turret") if ck == "party" else t("aura_" + BMDeploy.AURA[cid]["kind"])
		b.pressed.connect(func():
			if dp_tile < 0:
				_toast(t("dp_hint"))
				return
			var why := BMDeploy.place(placement, Game.profile, dp_tile, ck, cid)
			if why == "too_much_gear":
				_toast(t("dp_gear_full"))
			else:
				Sfx.pickup()
			_draw_placement())
		grid.add_child(b)
	tray.add_child(grid)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(_button(t("dp_clear"), "Ghost", func(): if dp_tile >= 0: BMDeploy.remove(placement, dp_tile); _draw_placement(), 120.0))
	row.add_child(_button(t("dp_go"), "Primary", func(): start_day(4), 160.0))
	tray.add_child(row)
	_show("placement")


# ---------- the corridor: one screen, one choice ------------------------------------------------
func show_event(id: String) -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	node_id = id
	var e := BMEvents.pick(Game.profile, id)
	_plate("corridor")
	_dim(0.5)
	var v := _panel(150, 340, "Glass")
	v.add_child(_label(t("ev_title"), "Tag", 12, Palette.TUBE))
	v.add_child(_label(t("ev_%s_text" % e["id"]), "", 16, Palette.TEXT, true))
	var done: bool = BMMap.is_cleared(Game.profile, id)
	if done:
		v.add_child(_label(t("cleared_tag"), "Tag", 11, Palette.GOLD))
		v.add_child(_button(t("back_map"), "Primary", show_map))
	else:
		for c in ["a", "b"]:
			var choice: String = c
			v.add_child(_button(t("ev_%s_%s" % [e["id"], c]), "Primary" if c == "a" else "Amber", func(): _ev_choose(choice), 260.0))
		v.add_child(_button(t("back_map"), "Ghost", show_map, 160))
	_show("event")


func _ev_choose(choice: String) -> void:
	var out := BMEvents.choose(Game.profile, node_id, choice)
	Game.save()
	Game.tel("event", {"id": out["event"], "choice": choice})
	var fx: Dictionary = out["fx"]
	var lines: Array = []
	if fx.has("xp"):
		lines.append(t("fx_xp", {"n": fx["xp"]}))
	if fx.has("credits"):
		lines.append(t("fx_credits", {"n": ("+%d" % int(fx["credits"])) if int(fx["credits"]) > 0 else str(fx["credits"])}))
	if fx.has("hpNext"):
		lines.append(t("fx_hp", {"n": ("+%d" % int(round(fx["hpNext"] * 100))) if fx["hpNext"] > 0 else str(int(round(fx["hpNext"] * 100)))}))
	if lines.is_empty():
		lines.append(t("fx_none"))
	var show := func():
		_clear_overlay()
		_plate("corridor")
		_dim(0.5)
		var v := _panel(200, 340, "Glass")
		v.add_child(_label(t("ev_title"), "Tag", 12, Palette.TUBE))
		v.add_child(_label(" · ".join(lines), "Title", 22, Palette.GOLD))
		v.add_child(_button(t("back_map"), "Primary", show_map))
		_show("event_done")
	var r: Dictionary = out["run"]
	if r.get("pending") != null:
		show_levelup(r, show)
	else:
		show.call()


# ---------- the break room / the weekend -------------------------------------------------------
func show_breakroom() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	_plate("breakroom")
	_dim(0.45)
	var p: Dictionary = Game.profile
	var m := BMMap.ensure(p)
	var v := _panel(60, 360, "Glass")
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label(t("node_breakroom"), "Title", 28, Palette.TEXT))
	v.add_child(_label(t("credits", {"n": int(p["credits"])}) + " · " + _stats_line(), "Tag", 11, Palette.GOLD))
	v.add_child(_label(t("br_hint"), "Tag", 10, Palette.MUTED, true))
	var offers: Array = [
		{"key": "coffee", "cost": 3, "label": t("br_coffee"), "desc": t("br_coffee_d") + (" (%+d%%)" % int(round(float(m.get("hpNext", 0.0)) * 100)) if float(m.get("hpNext", 0.0)) != 0.0 else "")},
	]
	if not p["owned"].has("coldbrew"):
		offers.append({"key": "coldbrew", "cost": 8, "label": t("br_coldbrew"), "desc": t("br_coldbrew_d")})
	for pt in BMData.PARTY:
		if not p["party"].has(pt["id"]):
			offers.append({"key": "recruit:" + pt["id"], "cost": 10, "label": t("br_recruit", {"who": t("pt_" + pt["id"]).split(",")[0]}), "desc": t("br_recruit_d")})
			break
	for o in offers:
		var key: String = o["key"]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var b := _button(o["label"], "Amber", func(): _buy(key), 170.0)
		b.add_theme_font_size_override("font_size", 11)
		h.add_child(b)
		var d := _label(o["desc"], "Tag", 10, Palette.MUTED, true)
		d.custom_minimum_size.x = 150
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(d)
		v.add_child(h)
	v.add_child(_button(t("locker"), "Button", show_desk, 200.0))
	v.add_child(_button(t("br_save"), "Primary", func(): Game.save(); _toast(t("br_saved")); Sfx.pickup(), 200.0))
	v.add_child(_button(t("back_map"), "Ghost", show_map, 160.0))
	_show("breakroom")


func _buy(key: String) -> void:
	var p: Dictionary = Game.profile
	var cost := 3 if key == "coffee" else (8 if key == "coldbrew" else 10)
	if int(p["credits"]) < cost:
		_toast(t("br_broke"))
		Sfx.hurt()
		return
	match key:
		"coffee":
			var m := BMMap.ensure(p)
			m["hpNext"] = clampf(float(m.get("hpNext", 0.0)) + 0.2, -0.4, 0.4)
		"coldbrew":
			p["owned"].append("coldbrew")
			if p["equipped"].get("hand") == null:
				p["equipped"]["hand"] = "coldbrew"
		_:
			var who := key.split(":")[1]
			if not p["party"].has(who):
				p["party"].append(who)
	p["credits"] = int(p["credits"]) - cost
	Game.tel("buy", {"what": key})
	Game.save()
	Sfx.pickup()
	show_breakroom()


func show_weekend() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	_plate("sat")
	_dim(0.4)
	var v := _panel(160, 340, "Glass")
	v.add_child(_label(t("weekend"), "Title", 32, Palette.GOLD))
	v.add_child(_label(t("weekend_body"), "", 15, Palette.TEXT, true))
	v.add_child(_label(t("credits", {"n": int(Game.profile.get("credits", 0))}), "Tag", 11, Palette.GOLD))
	v.add_child(_button(t("nextweek", {"n": int(Game.profile["week"]) + 1}), "Primary", show_map))
	v.add_child(_button(t("locker"), "Amber", show_desk, 160))
	_show("weekend")


# ---------- the desk ----------------------------------------------------------------------------
const SLOT_POS := {"wear": Vector2(346, 6), "hand": Vector2(338, 214), "desk": Vector2(30, 214)}

func show_desk() -> void:
	_clear_overlay()
	_stop_run()
	map.visible = false
	var bg := IconBox.new(func(ci): Sprites.desk(ci, Vector2(BMCore.W, BMCore.H), arena.clock), Vector2(BMCore.W, BMCore.H))
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)
	var p: Dictionary = Game.profile
	for slot in SLOT_POS:
		var eq = p["equipped"].get(slot)
		var box := PanelContainer.new()
		box.theme_type_variation = "Card"
		box.position = SLOT_POS[slot]
		box.custom_minimum_size = Vector2(64, 78)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		var eid: String = str(eq) if eq != null else ""
		vb.add_child(IconBox.new(func(ci): if eid != "": Sprites.equip_icon(ci, eid, Vector2(20, 20), 34) else: ci.draw_arc(Vector2(20, 20), 12, 0, TAU, 24, Palette.FAINT, 1.5), Vector2(40, 40)))
		vb.add_child(_label(t("slot_" + slot), "Tag", 9, Palette.MUTED))
		box.add_child(vb)
		overlay.add_child(box)
	var v := _panel(304, 380, "Glass")
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label(_stats_line(), "Tag", 12, Palette.GOLD))
	if p["owned"].is_empty():
		v.add_child(_label(t("empty_desk"), "Tag", 12, Palette.MUTED, true))
	else:
		v.add_child(_label(t("tap_equip"), "Tag", 11, Palette.MUTED))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for id in p["owned"]:
			var item := BMData.find(BMData.EQUIP, id)
			var on: bool = p["equipped"].get(item["slot"]) == id
			var b := Button.new()
			b.custom_minimum_size = Vector2(170, 40)
			b.theme_type_variation = "Active" if on else "Button"
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = "        " + t("eq_" + id)
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			var iid: String = id
			var ic := IconBox.new(func(ci): Sprites.equip_icon(ci, iid, Vector2(16, 16), 28), Vector2(32, 32))
			ic.position = Vector2(6, 4)
			b.add_child(ic)
			b.pressed.connect(func(): BMCore.equip(Game.profile, iid); Game.save(); show_desk())
			grid.add_child(b)
		v.add_child(grid)
	v.add_child(_label(t("party"), "Tag", 11, Palette.TUBE))
	if p["party"].is_empty():
		v.add_child(_label(t("nobody"), "Tag", 12, Palette.MUTED))
	else:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 18)
		for pid in p["party"]:
			var col := VBoxContainer.new()
			var cid: String = pid
			col.add_child(IconBox.new(func(ci): if not Sprites.actor(ci, cid, Vector2(22, 42), 40.0): Sprites.colleague(ci, Vector2(22, 28), arena.clock, cid, 1.0), Vector2(44, 42)))
			col.add_child(_label(t("pt_" + cid), "Tag", 10, Palette.TEXT))
			h.add_child(col)
		v.add_child(h)
	v.add_child(_button(t("back"), "Ghost", func(): show_map() if _has_progress() else show_title(), 120))
	_show("desk")


# ---------- web dev bridge (tests/headless_web.py) ----------------------------------------
func _bridge(cmd: Dictionary) -> Dictionary:
	var out := {"ok": true}
	match str(cmd.get("op", "")):
		"state":
			pass
		"diag":
			var fb: Font = load(CJK)
			out["cjk_loaded"] = fb != null
			out["cjk_has"] = fb.has_char(0x522B) if fb else false
			out["display_has"] = StudioTheme.font("display").has_char(0x522B)
			out["ui_has"] = StudioTheme.font("ui").has_char(0x522B)
			out["sprites"] = {}
			for id in ["player", "intern", "pm", "hr", "standup", "inbox", "allhands", "review", "deploy"]:
				out["sprites"][id] = Sprites.has_actor(id)
			out["plates"] = {}
			for pl in ["map_sky", "map_building", "lobby", "corridor", "breakroom"]:
				out["plates"][pl] = ResourceLoader.exists("res://assets/art/plate_%s.webp" % pl)
		"reset":
			Game.reset()
			show_title()
		"lang":
			Game.set_lang(str(cmd.get("code", "en")))
			if screen == "title":
				show_title()
			elif screen == "map":
				show_map()
		"open":
			match str(cmd.get("screen", "")):
				"map": show_map()
				"desk": show_desk()
				"title": show_title()
				"node": show_node(str(cmd.get("id", "lobby")))
				"breakroom": show_breakroom()
				"weekend": show_weekend()
		"walk":
			# the same tap a thumb makes on a room; the walk runs in real time
			var to := str(cmd.get("id", "lobby"))
			var path := BMMap.path(Game.profile, BMMap.at(Game.profile), to)
			out["path"] = path
			if path.is_empty():
				out["ok"] = false
				out["why"] = "locked"
			elif screen == "map":
				map.walk(path)
		"enter":
			enter_node(str(cmd.get("id", node_id)))
		"start":
			start_day(int(cmd.get("day", 0)))
		"go":
			_press_primary()
		"pick":
			pick_skill(str(cmd.get("id", "")))
		"equip":
			BMCore.equip(Game.profile, str(cmd.get("id", "")))
			Game.save()
			show_desk()
		"tri":
			tri_selected = int(cmd.get("i", 0))
			_tri_act(str(cmd.get("action", "reply")))
		"tri_end":
			_tri_end()
		"tri_auto":
			# one greedy turn of BMTriage.autoplay_turn, through the same act()/end_turn()
			if screen == "triage" and not triage.is_empty() and triage["over"] == null:
				BMTriage.autoplay_turn(triage)
				tri_selected = -1
				if triage["over"] != null:
					_tri_over()
				else:
					_draw_triage()
		"say":
			var cid := str(cmd.get("id", ""))
			if cid == "" and not review.is_empty():
				# the honest player: the first non-coercion card whose signals the rule still needs
				var pr := BMReview.progress(review)
				for h in review["hand"]:
					var c := BMReview.card(h)
					if c["rarity"] == "coercion":
						continue
					for s in c["signals"]:
						if (pr["have"].has(s) and not pr["have"][s]) or (pr["help"].has(s) and not pr["help"][s]):
							cid = h
							break
					if cid != "":
						break
				if cid == "":
					for h in review["hand"]:
						if BMReview.card(h)["rarity"] != "coercion":
							cid = h
							break
			_rv_play(cid)
		"place":
			out["why"] = BMDeploy.place(placement, Game.profile, int(cmd.get("tile", 0)), str(cmd.get("kind", "party")), str(cmd.get("id", "")))
			_draw_placement()
		"ship":
			start_day(4)
		"choose":
			_ev_choose(str(cmd.get("c", "a")))
		"buy":
			_buy(str(cmd.get("what", "coffee")))
		"auto":
			autopilot = bool(cmd.get("on", true))
		"target":
			target = {"x": float(cmd.get("x", 210)), "y": float(cmd.get("y", 460))}
		"simulate":
			# the same core, stepped without waiting for frames; stops at a level-up or the end
			var secs := float(cmd.get("seconds", 5))
			var steps := 0
			var was := autopilot
			autopilot = true
			while not run.is_empty() and screen == "" and steps < int(secs * 60):
				_process(1.0 / 60)
				steps += 1
			autopilot = was
			out["steps"] = steps
		_:
			out = {"ok": false, "why": "unknown op"}
	out["screen"] = screen
	if not run.is_empty():
		out["run"] = {"t": run["t"], "hp": run["hp"], "level": run["level"], "kills": run["kills"], "phase": run["phase"],
			"over": run["over"], "pending": run["pending"], "foes": run["foes"].size(), "shots": run["shots"].size(),
			"phrasesFired": run["phrasesFired"], "pattern": run["lastPattern"], "day": run["day"]["id"]}
	if not triage.is_empty():
		out["triage"] = {"turn": triage["turn"], "actions": triage["actions"], "stress": triage["stress"], "hand": triage["hand"].size(),
			"deck": triage["deck"].size(), "over": triage["over"], "xp": triage["xp"], "cleared": triage["cleared"]}
	if not review.is_empty():
		out["review"] = {"turn": review["turn"], "over": review["over"], "phase": review["state"].get("phase", ""),
			"momentum": review["state"].get("momentum", 0), "hand": review["hand"], "scenario": review["scenario"], "reply": review["reply"]}
	if not placement.is_empty():
		out["placement"] = placement["tiles"]
	var m := BMMap.ensure(Game.profile)
	out["map"] = {"at": m["at"], "cleared": m["cleared"], "walking": map.walking, "week": m["week"],
		"states": {}}
	for n in BMMap.NODES:
		out["map"]["states"][n["id"]] = BMMap.state(Game.profile, n["id"])
	out["node"] = node_id
	if screen == "lvup" and not _lvl_run.is_empty():
		out["lvl"] = _lvl_run.get("pending")
	out["profile"] = Game.profile
	out["lang"] = Game.lang
	return out


func _press_primary() -> void:
	for c in _all_controls(overlay):
		if c is Button and c.theme_type_variation == "Primary" and not c.disabled:
			c.pressed.emit()
			return


func _all_controls(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		out.append(c)
		out += _all_controls(c)
	return out
