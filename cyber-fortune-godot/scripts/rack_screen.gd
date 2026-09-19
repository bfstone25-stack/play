extends Control
## The rack — one collection screen for both instruments (the kill condition in the
## spec: "they must meet in the same rack"). Three tabs: what is tied and converting,
## the slips by rank and subject, the 78 cards with their reversals.

var tab := "rack"
var body: VBoxContainer


func _ready() -> void:
	relayout()
	Fortune.changed.connect(_fill)


func _process(_dt: float) -> void:
	if tab == "rack" and Engine.get_process_frames() % 30 == 0:
		_fill()


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
	v.offset_left = 26
	v.offset_right = -26
	v.offset_bottom = -20
	add_child(v)
	var title := StudioTheme.label(Tx.t("collection.title"), 30, Palette.GOLD_PALE, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(tabs)
	var counts := Fortune.collection_counts()
	for pair in [["rack", Tx.t("rack.title") + " %d/%d" % [Fortune.rack.size(), Fortune.rack_slots]],
			["slips", Tx.t("collection.slips") + " " + Tx.t("collection.count", {"have": counts["slips"], "all": counts["slips_all"]})],
			["cards", Tx.t("collection.cards") + " " + Tx.t("collection.count", {"have": counts["cards"], "all": counts["cards_all"]})]]:
		var b := StudioTheme.button(pair[1], "ChipOn" if tab == pair[0] else "Chip")
		b.pressed.connect(func():
			tab = pair[0]
			relayout())
		tabs.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	sc.add_child(body)
	_fill()


func _fill() -> void:
	if not is_instance_valid(body):
		return
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	match tab:
		"rack": _rack()
		"slips": _slips()
		"cards": _cards()


func _rack() -> void:
	if Fortune.resolved_bonus > 0:
		var b := StudioTheme.label(Tx.t("rack.ready") + " %d · " % Fortune.resolved_bonus + Tx.t("rack.bonus", {"n": Fortune.resolved_bonus}), 15, Palette.GOLD, "bold")
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(b)
	if Fortune.rack.is_empty():
		var e := StudioTheme.wrapped(Tx.t("collection.empty"), 17, Palette.MUTED, "ui")
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(e)
	for i in range(Fortune.rack.size()):
		var e: Dictionary = Fortune.rack[i]
		var p := PanelContainer.new()
		p.theme_type_variation = "Glass"
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		p.add_child(h)
		var stamp := StudioTheme.label(Tx.t("rank." + e["rank"]), 26, Palette.rank_text(e["rank"]), "serif")
		stamp.custom_minimum_size = Vector2(110, 0)
		h.add_child(stamp)
		var name := ""
		if e["kind"] == "slip":
			var s := Fortune.slip(e["id"])
			name = Tx.field(s, "verse") + " · " + Tx.t("subj." + s["subject"])
		else:
			var c := Fortune.card(e["id"])
			name = Tx.field(c, "name") + " · " + Tx.t("deck.reversed")
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(StudioTheme.wrapped(name, 16, Palette.TEXT, "ui"))
		var ready := Fortune.rack_ready(i)
		col.add_child(StudioTheme.label(Tx.t("rack.ready") if ready else Tx.t("rack.remaining", {"t": Tx.minutes(Fortune.rack_remaining_ms(i))}), 13, Palette.SUCCESS if ready else Palette.MUTED, "bold"))
		h.add_child(col)
		var b := StudioTheme.button(Tx.t("rack.claim") if ready else Tx.t("rack.tied"), "Lacquer" if ready else "Chip")
		b.disabled = not ready
		b.pressed.connect(func():
			Fortune.claim(i)
			Sfx.chime(1.6))
		h.add_child(b)
		body.add_child(p)


func _slips() -> void:
	var by := {}
	for s in Fortune.slips:
		var k: String = s["rank"] + "/" + s["subject"]
		if not by.has(k):
			by[k] = {"all": 0, "have": 0}
		by[k]["all"] += 1
		if Fortune.have_slips.has(s["id"]):
			by[k]["have"] += 1
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(grid)
	grid.add_child(Control.new())
	for subj in Fortune.SUBJECTS:
		var l := StudioTheme.label(Tx.t("subj." + subj).split(" ")[0] if Tx.lang == "en" else Tx.t("subj." + subj), 13, Palette.MUTED, "bold")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(84, 0)
		grid.add_child(l)
	for rank in Fortune.RANKS:
		var rl := StudioTheme.label(Tx.t("rank." + rank) if Tx.lang == "zh" else Tx.t("rank." + rank).split(" ")[0], 15, Palette.rank_text(rank), "serif")
		rl.custom_minimum_size = Vector2(70, 0)
		grid.add_child(rl)
		for subj in Fortune.SUBJECTS:
			var d: Dictionary = by.get(rank + "/" + subj, {"all": 0, "have": 0})
			var cell := PanelContainer.new()
			var full: bool = d["have"] >= d["all"] and d["all"] > 0
			cell.add_theme_stylebox_override("panel", StudioTheme.flat(Color(Palette.rank_color(rank), 0.15 + 0.5 * (float(d["have"]) / maxf(d["all"], 1))), Palette.rank_color(rank) if full else Color(Palette.INK_EDGE, 0.8), 6, 1, Vector2(4, 8)))
			cell.custom_minimum_size = Vector2(84, 44)
			var l := StudioTheme.label("%d/%d" % [d["have"], d["all"]], 15, Palette.TEXT if d["have"] > 0 else Palette.MUTED, "bold")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(l)
			grid.add_child(cell)
	# the kept slips, readable
	var kept := []
	for s in Fortune.slips:
		if Fortune.have_slips.has(s["id"]):
			kept.append(s)
	for s in kept:
		var p := PanelContainer.new()
		p.theme_type_variation = "Paper"
		var h := HBoxContainer.new()
		var st := StudioTheme.label(Tx.t("rank." + s["rank"]), 20, Palette.rank_color(s["rank"]) if s["rank"] != "moji" else Palette.GOLD_DEEP, "serif")
		st.custom_minimum_size = Vector2(100, 0)
		h.add_child(st)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(StudioTheme.label(Tx.field(s, "verse") + "  · " + Tx.t("subj." + s["subject"]), 18, Palette.PAPER_INK, "serif"))
		col.add_child(StudioTheme.wrapped(Tx.field(s, "do"), 14, Palette.PAPER_INK, "ui"))
		h.add_child(col)
		h.add_child(StudioTheme.label("×%d" % int(Fortune.have_slips[s["id"]]), 14, Palette.GOLD_DEEP, "bold"))
		p.add_child(h)
		body.add_child(p)


func _cards() -> void:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(grid)
	for c in Fortune.cards:
		var up := Fortune.have_cards.has(c["slug"] + ":up")
		var rev := Fortune.have_cards.has(c["slug"] + ":rev")
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		var cv := CardView.new()
		cv.setup(c["slug"], rev and not up, up or rev)
		cv.custom_minimum_size = Vector2(100, 160)
		cv.modulate = Color(1, 1, 1, 1.0 if (up or rev) else 0.35)
		v.add_child(cv)
		var dots := HBoxContainer.new()
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		dots.add_theme_constant_override("separation", 4)
		for pair in [[up, Tx.t("deck.upright")], [rev, Tx.t("deck.reversed")]]:
			var d := StudioTheme.label("●", 10, Palette.CANDLE if pair[0] else Color(Palette.SILVER_DIM, 0.4), "ui")
			d.tooltip_text = pair[1]
			dots.add_child(d)
		v.add_child(dots)
		grid.add_child(v)
