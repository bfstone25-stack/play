class_name RosterScreen
extends Overlay
## Staff · the gacha. The roster cards, the pity counter, PULL x1 / x10, and the reveal:
## card backs fan out, each flips with its rarity glow, a dupe gets its +5% toast.

signal pulled(results: Array)
signal need_gold

var grid: GridContainer
var pity: Label
var reveal: Control
var reveal_row: HBoxContainer
var reveal_done: Button
var _cards: Array = []
var _results: Array = []
var _reveal_gen := 0   # a newer reveal retires the coroutine of the one before it


func build() -> void:
	card_width = 980
	card.custom_minimum_size = Vector2(980, 0)
	tag(I18n.t("roster_tag"))
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := Label.new()
	t.text = I18n.t("roster_title")
	t.theme_type_variation = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(button(I18n.t("pull_1_btn"), "Pull", func() -> void: _pull(1)))
	head.add_child(button(I18n.t("pull_10_btn"), "Pull", func() -> void: _pull(10)))
	head.add_child(button(I18n.t("close"), "Ghost", close))
	para(I18n.t("roster_para"), 14)
	pity = Label.new()
	pity.theme_type_variation = "Value"
	pity.add_theme_color_override("font_color", Palette.GOLD)
	body.add_child(pity)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	# the reveal layer sits over the card
	reveal = Control.new()
	reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reveal.visible = false
	reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(reveal)
	var rdim := ColorRect.new()
	rdim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rdim.color = Color(Palette.GROUND_DEEP, 0.92)
	reveal.add_child(rdim)
	var rv := VBoxContainer.new()
	rv.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	rv.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rv.grow_vertical = Control.GROW_DIRECTION_BOTH
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 18)
	reveal.add_child(rv)
	var rt := Label.new()
	rt.text = I18n.t("new_hires")
	rt.add_theme_font_override("font", Look.font_display)
	rt.add_theme_font_size_override("font_size", 30)
	rt.add_theme_color_override("font_color", Palette.GOLD)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rt)
	reveal_row = HBoxContainer.new()
	reveal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reveal_row.add_theme_constant_override("separation", 10)
	rv.add_child(reveal_row)
	reveal_done = button(I18n.t("take_them"), "Primary", func() -> void:
		reveal.visible = false
		render())
	reveal_done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rv.add_child(reveal_done)


func on_open() -> void:
	render()


func render() -> void:
	pity.text = I18n.f("pity", [Roster.PITY - Economy.since_epic(), Economy.gold(), Economy.tickets()])
	clear(grid)
	for p in Roster.ROSTER:
		grid.add_child(_staff_card(p))


func _staff_card(p: Dictionary) -> Control:
	var owned := Economy.owned(p["id"]) > 0
	var c := PanelContainer.new()
	c.theme_type_variation = "Card"
	c.custom_minimum_size = Vector2(300, 0)
	if not owned:
		c.modulate = Color(1, 1, 1, 0.5)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	c.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(_portrait(p["id"], p["rarity"]))
	var nm := VBoxContainer.new()
	top.add_child(nm)
	var b := Label.new()
	b.text = I18n.t(str(p["nameKey"])) if owned else I18n.t("unknown")
	b.add_theme_font_override("font", Look.font_display)
	b.add_theme_font_size_override("font_size", 18)
	nm.add_child(b)
	var rar := Label.new()
	rar.text = I18n.t(str(p["rarity"]))
	rar.theme_type_variation = "Tag"
	rar.add_theme_color_override("font_color", rarity_color(p["rarity"]))
	nm.add_child(rar)
	var rule := Label.new()
	rule.text = I18n.t(str(p["ruleKey"]))
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.add_theme_color_override("font_color", Palette.GOLD)
	rule.add_theme_font_size_override("font_size", 13)
	v.add_child(rule)
	var bio := Label.new()
	bio.text = I18n.t(str(p["bioKey"])) if owned else I18n.t("not_pulled")
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio.add_theme_color_override("font_color", Palette.MUTED)
	bio.add_theme_font_size_override("font_size", 12)
	v.add_child(bio)
	var meta := Label.new()
	meta.theme_type_variation = "Tag"
	var d := Economy.dupes(p["id"])
	meta.text = I18n.f("on_floor", [Ticker.placed_count(p["id"]), int(p["slots"]), d, int(round((Roster.dupe_bonus(d) - 1.0) * 100.0)), Economy.affection(p["id"])])
	v.add_child(meta)
	var aff := HBoxContainer.new()
	aff.add_theme_constant_override("separation", 4)
	v.add_child(aff)
	var tier := Economy.affection_tier(p["id"])
	for i in range(4):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(26, 5)
		pip.color = Palette.HEAT if tier > i else Palette.PANEL_EDGE
		aff.add_child(pip)
	var nxt := Label.new()
	nxt.theme_type_variation = "Tag"
	var next_t := -1
	for x in Economy.AFF_TIERS:
		if int(x) > Economy.affection(p["id"]):
			next_t = int(x)
			break
	nxt.text = ("%d/%d" % [Economy.affection(p["id"]), next_t]) if next_t > 0 else I18n.t("max")
	aff.add_child(nxt)
	return c


static func rarity_color(r: String) -> Color:
	return Palette.rarity_color(r)


## The card is the portrait: a frame sized for the piece sprite (piece_<id>.webp) with
## the rarity edge; the vector block stands in until the sprite is installed.
func _portrait(id: String, rarity: String) -> Control:
	var rc := Palette.rarity_color(rarity)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(72, 96)
	frame.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, rc, 8, 2 if rarity != "common" else 1, Vector2(0, 0)))
	if rarity == "epic":
		frame.add_theme_stylebox_override("panel", StudioTheme.glow(StudioTheme.flat(Palette.PANEL, rc, 8, 2, Vector2(0, 0)), rc, 8, 0.45))
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(72, 96)
	inner.clip_contents = true
	frame.add_child(inner)
	var tex := Look.piece_portrait(id)
	if tex != null:
		var im := TextureRect.new()
		im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		im.texture = tex
		inner.add_child(im)
	else:
		var pc := Piece.new()
		pc.setup(id, 62, 32)
		pc.position = Vector2(36, 62)
		pc.show_score = false
		inner.add_child(pc)
	return frame


func _pull(n: int) -> void:
	var sku := "pull_10" if n == 10 else "pull_1"
	if Economy.tickets() < n:
		var r := Economy.buy(sku)
		if not r["ok"]:
			need_gold.emit()
			render()
			return
	var res := Economy.pull(n)
	if not res["ok"]:
		need_gold.emit()
		return
	_results = res["results"]
	pulled.emit(_results)
	Sfx.shop()
	_reveal(_results)


## The moment: backs fan in, then flip one by one; rarity sets the glow; dupes toast.
func _reveal(results: Array) -> void:
	_reveal_gen += 1
	var gen := _reveal_gen
	reveal.visible = true
	reveal_done.visible = false
	clear(reveal_row)
	_cards.clear()
	# this reveal's own cards: a pull that lands while the last reveal is still flipping
	# must not have the old coroutine flip the new cards at its leftover indices
	var cards: Array = []
	for i in range(results.size()):
		var gc := GachaCard.new()
		gc.setup(results[i])
		gc.modulate.a = 0.0
		gc.position.y = 40
		reveal_row.add_child(gc)
		cards.append(gc)
	_cards = cards
	await get_tree().process_frame
	if gen != _reveal_gen:
		return
	for i in range(cards.size()):
		var gc: GachaCard = cards[i]
		var tw := gc.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_property(gc, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(0.35 + 0.06 * cards.size()).timeout
	for i in range(cards.size()):
		if gen != _reveal_gen:
			return
		var gc: GachaCard = cards[i]
		gc.flip()
		Sfx.flip(str(results[i]["rarity"]))
		await get_tree().create_timer(0.22 if cards.size() > 1 else 0.4).timeout
	if gen != _reveal_gen:
		return
	reveal_done.visible = true
	reveal_done.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(reveal_done, "modulate:a", 1.0, 0.25)
