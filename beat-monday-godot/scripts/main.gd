## Main — the screens, the input, the frame loop. The loop lives in BMCore; this file only
## wires it (the HTML spec's main.js). Screens are built in code so they live in git as
## text and share one Theme (StudioTheme) — title, week board, brief, level-up, result,
## desk, weekend. One thumb: drag anywhere on the arena to move; everything else is a tap.
extends Control

const CJK := "res://assets/fonts/NotoSansCJK-subset.otf"

var arena: Node2D
var hud: Control
var overlay: Control
var run: Dictionary = {}
var target = null
var autopilot := false
var screen := "title"
var down := false
var day_started := 0.0
var lvl_cards: Array = []


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
	var path := "res://assets/art/plate_%s.webp" % name
	if not ResourceLoader.exists(path):
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


func _stop_run() -> void:
	run = {}
	arena.set_run({})
	hud.run = {}


func _stats_line() -> String:
	var s := BMCore.compute_stats(Game.profile)
	return t("stats", {"lv": Game.profile["level"], "hp": s["hp"], "atk": s["atk"], "rate": s["rate"]})


# ---------- title / week / brief ------------------------------------------------------------
func show_title() -> void:
	_clear_overlay()
	arena.set_run({})
	hud.run = {}
	run = {}
	_plate("title")
	_dim(0.35)
	var top := _panel(150, 340, "Glass")
	top.add_child(_label(t("brand"), "Title", 40, Palette.TEXT))
	top.add_child(_label(t("sub"), "Tag", 13, Palette.TUBE))
	var v := _panel(330, 260, "Glass")
	var cont: bool = Game.profile["cleared"].size() > 0 or Game.profile["week"] > 0
	v.add_child(_button(t("cont") if cont else t("start"), "Primary", func(): show_week() if cont else show_brief(0)))
	v.add_child(_button(t("locker"), "Amber", show_desk))
	v.add_child(_button(t("lang"), "Ghost", func(): Game.set_lang("en" if Game.lang == "zh" else "zh"); show_title(), 120))
	var hint := _label(t("drag"), "Tag", 12, Palette.MUTED)
	hint.position = Vector2(0, 590)
	hint.size.x = BMCore.W
	overlay.add_child(hint)
	_show("title")


func show_week() -> void:
	_clear_overlay()
	_stop_run()
	_plate("title")
	_dim(0.55)
	var v := _panel(40, 360, "Glass")
	v.add_child(_label(t("week", {"n": int(Game.profile["week"]) + 1}), "Title", 30))
	v.add_child(_label(_stats_line(), "Tag", 12, Palette.GOLD))
	for i in BMData.DAYS.size():
		var d: Dictionary = BMData.DAYS[i]
		var done: bool = Game.profile["cleared"].has(d["id"])
		var locked: bool = i > int(Game.profile["day"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(320, 62)
		b.theme_type_variation = "Primary" if (not locked and not done and i == int(Game.profile["day"])) else ("Active" if done else "Button")
		b.disabled = locked
		var day_l := _label(t("day_" + d["id"]), "Tag", 11, Palette.TUBE if not locked else Palette.DIM)
		day_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		day_l.position = Vector2(66, 12)
		b.add_child(day_l)
		var boss_l := _label(t("boss_" + d["boss"]), "Value", 17, Palette.TEXT if not locked else Palette.DIM)
		boss_l.add_theme_font_override("font", StudioTheme.font("display"))
		boss_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		boss_l.position = Vector2(66, 28)
		b.add_child(boss_l)
		var boss_id: String = d["id"]
		var icon := IconBox.new(func(ci): _boss_thumb(ci, boss_id, locked), Vector2(120, 120), 0.36)
		icon.position = Vector2(10, 9)
		b.add_child(icon)
		if done:
			var tag := _label("DONE", "Tag", 10, Palette.SUCCESS)
			tag.position = Vector2(260, 24)
			b.add_child(tag)
		b.pressed.connect(func(): show_brief(i))
		v.add_child(b)
	v.add_child(_button(t("locker"), "Amber", show_desk, 160))
	_show("week")


func _boss_thumb(ci: CanvasItem, day_id: String, locked: bool) -> void:
	Sprites.boss(ci, {"x": 60.0, "y": 60.0, "hit": 0.0}, day_id, arena.clock)
	if locked:
		ci.draw_rect(Rect2(-10, -10, 140, 140), Color(Palette.GROUND, 0.7))


func show_brief(i: int) -> void:
	_clear_overlay()
	var d: Dictionary = BMData.DAYS[i]
	arena.set_run({})
	arena._load_plate(d["id"])
	_dim(0.5)
	var v := _panel(120, 340, "Glass")
	v.add_child(_label(t("day_" + d["id"]), "Tag", 13, Palette.TUBE))
	v.add_child(_label(t("boss_" + d["boss"]), "Title", 30, Palette.TEXT))
	var day_id: String = d["id"]
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(300, 130)
	var ib := IconBox.new(func(ci): Sprites.boss(ci, {"x": 100.0, "y": 80.0, "hit": 0.0}, day_id, arena.clock), Vector2(200, 160), 0.8)
	ib.position = Vector2(70, 0)
	holder.add_child(ib)
	v.add_child(holder)
	var body := t("brief_" + d["id"]) + ("\n\n" + t("rant_hint") if d["mode"] == "rant" else "")
	v.add_child(_label(body, "", 15, Palette.TEXT, true))
	v.add_child(_button(t("go"), "Primary", func(): start_day(i)))
	v.add_child(_button(t("back"), "Ghost", show_week, 120))
	_show("brief")


# ---------- the day ---------------------------------------------------------------------------
func start_day(i: int) -> void:
	_clear_overlay()
	run = BMCore.create_run(Game.profile, i, Time.get_ticks_msec() & 0xffff)
	run["lang"] = Game.lang
	target = {"x": run["px"], "y": run["py"]}
	arena.set_run(run)
	hud.run = run
	day_started = Time.get_ticks_msec() / 1000.0
	Game.tel_play_start({"day": BMData.DAYS[i]["id"], "week": Game.profile["week"]})
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
	if run["pending"] != null:
		show_levelup()
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


func show_levelup() -> void:
	_clear_overlay()
	_dim(0.62)
	var head := _panel(90, 300, "Glass")
	head.add_child(_label(t("lvup", {"n": run["level"]}), "Title", 34, Palette.GOLD))
	head.add_child(_label(t("pick"), "Tag", 13, Palette.TUBE))
	Sfx.levelup()
	var ids: Array = run["pending"]
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
	if run.is_empty() or run["pending"] == null:
		return
	if BMCore.apply_skill(run, id):
		Game.tel("skill", {"id": id, "level": run["level"]})
		_clear_overlay()
		_show("")


func finish() -> void:
	var won: bool = run["over"] == "clear"
	var idx: int = run["dayIndex"]
	if won:
		Sfx.clear()
	else:
		Sfx.dead()
	BMCore.commit_run(Game.profile, run)
	Game.save()
	Game.tel_play_end({"day": BMData.DAYS[idx]["id"], "won": won, "kills": run["kills"]}, int(Time.get_ticks_msec() / 1000.0 - day_started))
	_clear_overlay()
	_dim(0.55)
	var v := _panel(150, 340, "Glass")
	v.add_child(_label(t("cleared") if won else t("dead"), "Title", 28, Palette.GOLD if won else Palette.HEAT))
	v.add_child(_label(t("kills", {"n": run["kills"]}), "Tag", 12, Palette.MUTED))
	if won and run["reward"] != null:
		var rid: String = run["reward"]
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(IconBox.new(func(ci): Sprites.equip_icon(ci, rid, Vector2(24, 24), 40), Vector2(48, 48)))
		var l := _label(t("got", {"item": t("eq_" + rid)}), "Value", 15)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		v.add_child(h)
		for p in BMData.PARTY:
			if p["after"] == BMData.DAYS[idx]["id"]:
				var pid: String = p["id"]
				var h2 := HBoxContainer.new()
				h2.alignment = BoxContainer.ALIGNMENT_CENTER
				h2.add_child(IconBox.new(func(ci): Sprites.colleague(ci, Vector2(24, 30), arena.clock, pid, 1.0), Vector2(48, 48)))
				var l2 := _label(t("joined", {"who": t("pt_" + pid)}), "Value", 15, Palette.SUCCESS)
				l2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h2.add_child(l2)
				v.add_child(h2)
	var go := func():
		if not won:
			start_day(idx)
		elif Game.profile.get("weekend", false):
			Game.profile["weekend"] = false
			Game.save()
			show_weekend()
		else:
			show_week()
	v.add_child(_button(t("back") if won else t("retry"), "Primary", go))
	v.add_child(_button(t("locker"), "Amber", show_desk, 160))
	_show("result")
	# cross-promotion, once per session, after a day ends: offered behind a timer, never forced
	get_tree().create_timer(0.9).timeout.connect(Game.offer_board)


func show_weekend() -> void:
	_clear_overlay()
	_stop_run()
	arena.set_run({})
	_plate("sat")
	_dim(0.4)
	var v := _panel(160, 340, "Glass")
	v.add_child(_label(t("weekend"), "Title", 32, Palette.GOLD))
	v.add_child(_label(t("weekend_body"), "", 15, Palette.TEXT, true))
	v.add_child(_button(t("nextweek", {"n": int(Game.profile["week"]) + 1}), "Primary", show_week))
	v.add_child(_button(t("locker"), "Amber", show_desk, 160))
	_show("weekend")


# ---------- the desk ----------------------------------------------------------------------------
const SLOT_POS := {"wear": Vector2(346, 6), "hand": Vector2(338, 214), "desk": Vector2(30, 214)}

func show_desk() -> void:
	_clear_overlay()
	_stop_run()
	arena.set_run({})
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
			col.add_child(IconBox.new(func(ci): Sprites.colleague(ci, Vector2(22, 28), arena.clock, cid, 1.0), Vector2(44, 42)))
			col.add_child(_label(t("pt_" + cid), "Tag", 10, Palette.TEXT))
			h.add_child(col)
		v.add_child(h)
	v.add_child(_button(t("back"), "Ghost", func(): show_week() if (Game.profile["cleared"].size() > 0 or Game.profile["week"] > 0) else show_title(), 120))
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
			var ff: Font = load(StudioTheme.FONT_DISPLAY)
			out["display_fallbacks"] = (ff as FontFile).fallbacks.size() if ff is FontFile else -1
			out["display_class"] = ff.get_class() if ff else "null"
		"reset":
			Game.reset()
			show_title()
		"lang":
			Game.set_lang(str(cmd.get("code", "en")))
			if screen == "title":
				show_title()
		"open":
			match str(cmd.get("screen", "")):
				"week": show_week()
				"desk": show_desk()
				"title": show_title()
				"brief": show_brief(int(cmd.get("day", 0)))
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
