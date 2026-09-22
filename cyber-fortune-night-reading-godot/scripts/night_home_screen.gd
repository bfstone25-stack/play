extends Control
## The night table — who are you reading tonight. Three women, each with her three
## tracks drawn as three bars; a woman whose three are all true is waiting.

var root: VBoxContainer


func _ready() -> void:
	Sfx.bark("greet")
	relayout()


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	# The shelf frame: when the key visual is rendered it IS the title screen's ground
	# (ops/check_brightness.py with no flag, 0.45/0.30 floor). While it is a labelled
	# placeholder the drawn room stands in, and this screen measures as a scene.
	var kv := Night.art("title_kv")
	if kv != null and not Night.is_placeholder("title_kv"):
		var tr := TextureRect.new()
		tr.texture = kv
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
	else:
		var bg := Backdrop.new()
		bg.mode = "night"
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 92)
	m.add_theme_constant_override("margin_bottom", 36)
	add_child(m)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)

	var series := StudioTheme.label(Tx.t("series"), 13, Palette.MUTED, "bold")
	series.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(series)
	var title := StudioTheme.label(Tx.t("title"), 54, Palette.HOT_PALE, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	# The rule, on the first screen, in one line: this is the whole of the second world.
	var rule := StudioTheme.wrapped(Tx.t("night.rule"), 17, Palette.SMOKE, "italic" if Tx.lang == "en" else "serif")
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(rule)
	var daily := StudioTheme.label(Tx.t("daily.free" if Fortune.free_available() else "daily.used"),
		15, Palette.SUCCESS if Fortune.free_available() else Palette.MUTED, "bold")
	daily.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(daily)

	if Night.cleared():
		root.add_child(_clear_panel())
		return

	var who := StudioTheme.label(Tx.t("night.who"), 20, Palette.TEXT, "serif")
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(who)
	for c in Night.cast:
		root.add_child(_card(c))


func _clear_panel() -> Control:
	var p := PanelContainer.new()
	p.theme_type_variation = "Glass"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22)
	m.add_child(v)
	p.remove_child(v)
	p.add_child(m)
	var t := StudioTheme.label(Tx.t("night.clear"), 30, Palette.HOT_PALE, "serif")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := StudioTheme.wrapped(Tx.t("night.clear.sub"), 18, Palette.SMOKE, "italic" if Tx.lang == "en" else "serif")
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var b := StudioTheme.button(Tx.t("night.more"), "Gold")
	b.pressed.connect(func(): Gate.board_offer_more("adult"))
	v.add_child(b)
	return p


func _card(c: Dictionary) -> Control:
	var d := ClientCard.new()
	d.cid = str(c["id"])
	d.cname = Tx.field(c, "name")
	d.who = Tx.field(c, "who")
	d.custom_minimum_size = Vector2(0, 176)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.pressed.connect(func():
		Night.current = d.cid
		Night.save_state()
		get_parent().open("scene" if (Night.scene_ready(d.cid) and not Night.scene_seen(d.cid)) else "read"))
	return d


func dev_state() -> Dictionary:
	return {}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	if str(cmd.get("op", "")) == "pick":
		Night.current = str(cmd.get("client", Night.current))
		Night.save_state()
		get_parent().open("read")
		return {"ok": true}
	return {"ok": false, "why": "home_has_no_" + str(cmd.get("op", ""))}


## One woman: her name, her line, and her three tracks as three segmented bars — the
## whole of her state, visible without opening her.
class ClientCard extends Button:
	var cid := ""
	var cname := ""
	var who := ""

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		for s in ["normal", "hover", "pressed"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var ready: bool = Night.scene_ready(cid)
		var seen: bool = Night.scene_seen(cid)
		var edge: Color = Palette.HOT if ready and not seen else Palette.PLUM_EDGE
		if is_hovered():
			edge = edge.lightened(0.3)
		var sb := StudioTheme.flat(Palette.PLUM_SOFT, edge, 16, 2 if ready else 1, Vector2.ZERO)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 14
		draw_style_box(sb, r)
		var portrait := Night.portrait(cid)
		var box := Rect2(14, 14, 108, size.y - 28)
		if portrait:
			draw_texture_rect(portrait, box, false)
			draw_rect(box, Color(Palette.HOT_DEEP, 0.5), false, 1.0)
		else:
			draw_rect(box, Palette.PLUM)
			draw_rect(box, Color(Palette.HOT_DEEP, 0.4), false, 1.0)
		var f := StudioTheme.font("serif")
		var fi := StudioTheme.font("italic" if Tx.lang == "en" else "serif")
		draw_string(f, Vector2(142, 46), cname, HORIZONTAL_ALIGNMENT_LEFT, -1, 32,
			Palette.HOT_PALE if ready and not seen else Palette.TEXT)
		draw_multiline_string(fi, Vector2(144, 74), who, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 164, 15, 2, Palette.MUTED)
		# the three tracks
		var t: Array = Night.tracks(cid)
		var x0 := 144.0
		var w := (size.x - 164.0) / 3.0 - 8.0
		for i in range(t.size()):
			var x := x0 + i * (w + 8.0)
			var y := size.y - 44.0
			for k in range(Night.TRACK_MAX):
				var seg := Rect2(x + k * (w / 3.0), y, w / 3.0 - 3.0, 7.0)
				draw_rect(seg, Palette.HOT if int(t[i]) > k else Color(Palette.SMOKE, 0.16))
			var nm := Tx.field(Night.client(cid)["tracks"][i], "name")
			draw_string(StudioTheme.font("ui"), Vector2(x, y + 26), nm,
				HORIZONTAL_ALIGNMENT_LEFT, w, 13,
				Palette.HOT_PALE if int(t[i]) >= Night.TRACK_MAX else Palette.MUTED)
		var tag := ""
		if seen:
			tag = Tx.t("night.done")
		elif ready:
			tag = Tx.t("night.ready")
		else:
			tag = Tx.t("night.tracks", {"n": Night.total(cid)})
		draw_string(StudioTheme.font("bold"), Vector2(size.x - 130, 40), tag,
			HORIZONTAL_ALIGNMENT_RIGHT, 116, 15,
			Palette.SUCCESS if seen else (Palette.HOT_PALE if ready else Palette.MUTED))
