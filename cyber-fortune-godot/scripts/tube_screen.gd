extends Control
## 求签 — the slip tube. Tap the wooden fish to fill the tube with merit (the merit.js
## curve, exactly); a full tube shakes; sticks rattle, one rises and falls out; the slip
## is read on paper. Space also taps.

var fish: Fish
var tube: Tube
var subject := "work"
var chips: Array = []
var shake_btn: Button
var upgrade_btn: Button
var level_lbl: Label
var fill_lbl: Label
var fill_bar: ProgressBar
var panel_host: Control
var busy := false
var shake_done := true
var last_result: Dictionary = {}

## How full the tube has to be before she says you are nearly there. 0.85 and not 0.95:
## at 0.95 the line lands after the shake button has already lit, which makes it a
## commentary on the past rather than an encouragement.
const NEAR := 0.85


func _ready() -> void:
	relayout()
	Fortune.changed.connect(_refresh)


func _process(dt: float) -> void:
	Fortune.tick(dt)


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var bg := Backdrop.new()
	bg.mode = "east"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 84
	v.offset_left = 28
	v.offset_right = -28
	v.offset_bottom = -24
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var title := StudioTheme.label(Tx.t("home.east"), 30, Palette.GOLD_PALE, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	# the tube
	tube = Tube.new()
	tube.custom_minimum_size = Vector2(0, 390)
	v.add_child(tube)
	# fill gauge
	var g := HBoxContainer.new()
	g.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(g)
	fill_lbl = StudioTheme.label("", 15, Palette.SMOKE, "bold")
	g.add_child(fill_lbl)
	fill_bar = ProgressBar.new()
	fill_bar.custom_minimum_size = Vector2(300, 12)
	fill_bar.show_percentage = false
	fill_bar.max_value = 1.0
	fill_bar.step = 0.001
	g.add_child(fill_bar)
	# subjects
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	v.add_child(flow)
	chips = []
	for s in Fortune.SUBJECTS:
		var b := StudioTheme.button(Tx.t("subj." + s), "ChipOn" if s == subject else "Chip")
		b.pressed.connect(func():
			subject = s
			for i in range(chips.size()):
				chips[i].theme_type_variation = "ChipOn" if Fortune.SUBJECTS[i] == s else "Chip")
		flow.add_child(b)
		chips.append(b)
	# the shake button
	shake_btn = StudioTheme.button("", "Lacquer")
	shake_btn.custom_minimum_size = Vector2(280, 0)
	shake_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shake_btn.pressed.connect(shake)
	v.add_child(shake_btn)
	# the fish
	fish = Fish.new()
	fish.custom_minimum_size = Vector2(0, 250)
	fish.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fish.tapped.connect(_tap)
	v.add_child(fish)
	var hint := StudioTheme.label(Tx.t("tube.tap.hint"), 13, Palette.MUTED, "bold")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	# incense (the upgrade) and level
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	level_lbl = StudioTheme.label("", 14, Palette.SMOKE, "bold")
	row.add_child(level_lbl)
	upgrade_btn = StudioTheme.button("", "Gold")
	upgrade_btn.pressed.connect(func():
		if Fortune.upgrade():
			Sfx.chime(1.5)
			Sfx.bark("unlock"))
	row.add_child(upgrade_btn)
	panel_host = Control.new()
	panel_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_host)
	_refresh()
	if not Fortune.pending.is_empty() and Fortune.pending["kind"] == "slip":
		_show_result(Fortune.pending)


func _refresh() -> void:
	if not is_instance_valid(fill_bar):
		return
	fill_bar.value = Fortune.fill()
	fill_lbl.text = "%s %d/%d  " % [Tx.t("tube.fill"), mini(Fortune.merit.merit, Fortune.TUBE), Fortune.TUBE]
	var m := Fortune.merit
	level_lbl.text = Tx.t("tube.level", {"level": m.level}) + ("  " + Tx.t("tube.auto", {"auto": m.auto}) if m.auto > 0 else "")
	upgrade_btn.text = Tx.t("tube.upgrade", {"cost": m.upgrade_cost()})
	upgrade_btn.disabled = m.merit < m.upgrade_cost()
	var free := Fortune.free_available()
	shake_btn.text = Tx.t("tube.shake.free" if free else "tube.shake")
	if not free and m.merit < Fortune.TUBE:
		shake_btn.text = Tx.t("tube.need", {"n": Fortune.TUBE - m.merit})
	shake_btn.disabled = busy or not Fortune.can_draw()
	tube.fill = Fortune.fill()


func _tap() -> void:
	if busy:
		return
	var was := Fortune.fill()
	var g := Fortune.tap()
	fish.knock(g)
	Sfx.knock()
	# "One card left." -- said once as the tube comes up to full, not every tap after it.
	if was < NEAR and Fortune.fill() >= NEAR:
		Sfx.bark("near")


func shake() -> void:
	if busy or not Fortune.can_draw():
		return
	busy = true
	shake_done = false
	_refresh()
	var r := Fortune.draw("slip", subject)
	last_result = r
	await tube.shake_out()
	_show_result(r)
	busy = false
	shake_done = true
	_refresh()


func _show_result(r: Dictionary) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_host.add_child(dim)
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.offset_top = 90
	sc.offset_left = 30
	sc.offset_right = -30
	sc.offset_bottom = -30
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_host.add_child(sc)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(center)
	var p := ResultPanel.new()
	p.custom_minimum_size = Vector2(600, 0)
	p.setup(r)
	p.done.connect(func():
		dim.queue_free()
		sc.queue_free()
		_refresh())
	center.add_child(p)
	p.modulate.a = 0.0
	p.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.35)
	tw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	Sfx.chime(1.0 if not Fortune.is_ill(r["rank"]) else 0.75)
	# She reads the rank out. 大吉 is the once-in-thirty-draws line, so it gets its own
	# slot; 凶 / 大凶 get the fail line, which in an all-ages fortune game is a shrug and
	# not a defeat. Fired here rather than on the keep/burn press: the bark belongs to the
	# moment the slip is turned over.
	Sfx.bark(Fortune.bark_slot(r))


## Space / Enter / a tap on the shrine floor. In order: read the slip that is waiting,
## then spend the free daily draw, then knock the fish. Only the FREE draw is spent this
## way -- a paid shake stays on its own button, because a stray tap must never cost merit.
## Returns false only when there is genuinely nothing left here, which hands the player on
## to the deck.
func screen_advance() -> bool:
	if busy:
		return true                      # the tube is mid-shake; the press is not lost
	for panel in panel_host.find_children("*", "ResultPanel", true, false):
		return panel.choose("keep")
	if Fortune.free_available():
		shake()
		return true
	if Fortune.merit.merit < Fortune.TUBE:
		_tap()
		return true
	return false


# ---- dev bridge --------------------------------------------------------------------------
func dev_state() -> Dictionary:
	return {"shake_done": shake_done, "subject": subject, "result_open": panel_host.get_child_count() > 0}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	match str(cmd["op"]):
		"subject":
			subject = str(cmd.get("subject", "work"))
			return {"ok": true}
		"shake":
			if busy or not Fortune.can_draw():
				return {"ok": false}
			shake()
			return {"ok": true}
		"result":
			return {"ok": true, "result": last_result}
		"read":
			for panel in panel_host.find_children("*", "ResultPanel", true, false):
				return {"handled": true, "ok": panel.choose(str(cmd.get("choice", "keep")))}
			return {"handled": false}
		"tap_fish":
			_tap()
			return {"ok": true}
	return {"ok": false, "why": "unknown"}


## The wooden fish: a rounded body with a mouth slit and a mallet; it squashes on a tap
## and a "+n" floats up. Click or touch anywhere on it.
class Fish extends Control:
	signal tapped
	var squash := 0.0
	var floats: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			tapped.emit()

	func knock(gain: int) -> void:
		squash = 1.0
		floats.append({"t": 0.0, "x": randf_range(-40, 40), "n": gain})

	func _process(dt: float) -> void:
		squash = maxf(0.0, squash - dt * 6.0)
		for f in floats:
			f["t"] += dt
		floats = floats.filter(func(f): return f["t"] < 1.0)
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.55)
		var sq := 1.0 - 0.10 * squash
		var sx := 1.0 + 0.06 * squash
		draw_set_transform(c, 0.0, Vector2(sx, sq))
		# the body: a wide rounded shape, lacquered wood
		var body := PackedVector2Array()
		for i in range(48):
			var a := TAU * i / 48.0
			var rx := 120.0 + 14.0 * cos(a * 2.0)
			var ry := 78.0
			body.append(Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(body, Palette.WOOD)
		draw_polyline(body + PackedVector2Array([body[0]]), Palette.WOOD_LIGHT, 3.0, true)
		# the sound slit
		draw_arc(Vector2(0, 14), 84.0, PI * 0.15, PI * 0.85, 24, Palette.WOOD_DARK, 7.0, true)
		draw_arc(Vector2(0, 20), 62.0, PI * 0.2, PI * 0.8, 24, Palette.WOOD_DARK, 4.0, true)
		# the eye and a gold ring
		draw_circle(Vector2(-70, -18), 9.0, Palette.WOOD_DARK)
		draw_circle(Vector2(-70, -18), 4.0, Palette.GOLD)
		draw_arc(Vector2(0, 0), 40.0, 0, TAU, 40, Color(Palette.GOLD, 0.35), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the mallet, swinging in on a knock
		var ang := -0.9 + 0.7 * squash
		var pivot := c + Vector2(150, -120)
		var tip := pivot + Vector2(cos(ang + PI * 0.5), sin(ang + PI * 0.5)) * 120.0
		draw_line(pivot, tip, Palette.WOOD_LIGHT, 8.0)
		draw_circle(tip, 18.0, Palette.WOOD_DARK)
		draw_circle(tip, 18.0, Palette.GOLD_DEEP)
		draw_circle(tip, 12.0, Palette.WOOD_DARK)
		# floats
		var f := StudioTheme.font("black")
		for fl in floats:
			var a: float = 1.0 - fl["t"]
			draw_string(f, c + Vector2(fl["x"] - 12, -90 - fl["t"] * 80.0), "+%d" % fl["n"], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(Palette.GOLD_PALE, a))


## The tube: a wooden cylinder with sticks; the fill shows as a lacquer band. shake_out()
## tilts it, rattles the sticks, and lets one rise and fall out.
class Tube extends Control:
	var fill := 0.0
	var tilt := 0.0
	var jitter := 0.0
	var rise := 0.0       # 0..1 the chosen stick rising
	var fall := 0.0       # 0..1 the stick falling out
	var chosen := 5
	var _t := 0.0

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func shake_out() -> void:
		var tw := create_tween()
		for i in range(6):
			tw.tween_property(self, "tilt", (0.16 if i % 2 == 0 else -0.16), 0.09)
			tw.parallel().tween_callback(Sfx.rattle)
		tw.tween_property(self, "tilt", 0.0, 0.1)
		jitter = 1.0
		await tw.finished
		jitter = 0.0
		var t2 := create_tween()
		t2.tween_property(self, "rise", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(self, "fall", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t2.parallel().tween_callback(Sfx.drop).set_delay(0.45)
		await t2.finished
		await get_tree().create_timer(0.25).timeout
		rise = 0.0
		fall = 0.0

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.94)
		draw_set_transform(c, tilt, Vector2.ONE)
		var w := 150.0
		var h := 170.0
		# the sticks
		for i in range(12):
			var x := -w * 0.5 + 14 + i * 11.0
			var jx := (randf() - 0.5) * 6.0 * jitter
			var sh := 56.0 + 12.0 * sin(i * 1.7)
			var top := Vector2(x + jx, -h - sh)
			var col := Palette.PAPER
			var band := Palette.LACQUER
			if i == chosen:
				top.y -= rise * 120.0
				if fall > 0.0:
					var fx := x + 120.0 * fall
					var fy := -h - sh - 120.0 + fall * fall * 420.0
					draw_set_transform(c, tilt + fall * 1.4, Vector2.ONE)
					draw_line(Vector2(fx, fy), Vector2(fx, fy + 150.0), Palette.GOLD_PALE, 6.0)
					draw_line(Vector2(fx, fy), Vector2(fx, fy + 24.0), Palette.LACQUER, 6.0)
					draw_set_transform(c, tilt, Vector2.ONE)
					continue
				col = Palette.GOLD_PALE
			draw_line(top, Vector2(x + jx, -h * 0.4), col, 6.0)
			draw_line(top, top + Vector2(0, 22), band, 6.0)
		# the body, over the sticks
		var body := Rect2(Vector2(-w * 0.5, -h), Vector2(w, h))
		draw_rect(body, Palette.WOOD)
		draw_rect(Rect2(body.position + Vector2(10, 0), Vector2(22, h)), Palette.WOOD_LIGHT)
		draw_rect(Rect2(body.position + Vector2(w - 26, 0), Vector2(14, h)), Palette.WOOD_DARK)
		# the lacquer fill band, rising with merit
		var fh := (h - 24.0) * fill
		draw_rect(Rect2(Vector2(-w * 0.5 + 40, -12 - fh), Vector2(w - 80, fh)), Color(Palette.LACQUER, 0.85))
		draw_rect(Rect2(Vector2(-w * 0.5 + 40, -12 - (h - 24.0)), Vector2(w - 80, h - 24.0)), Palette.GOLD_DEEP, false, 2.0)
		# rim and base
		draw_rect(Rect2(Vector2(-w * 0.5 - 6, -h - 8), Vector2(w + 12, 16)), Palette.WOOD_DARK)
		draw_rect(Rect2(Vector2(-w * 0.5 - 6, -h - 8), Vector2(w + 12, 16)), Palette.GOLD, false, 2.0)
		draw_rect(Rect2(Vector2(-w * 0.5 - 10, -6), Vector2(w + 20, 12)), Palette.WOOD_DARK)
		# the character on the tube
		var f := StudioTheme.font("serif")
		draw_string(f, Vector2(-16, -h * 0.5 + 12), "签", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Palette.GOLD)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
