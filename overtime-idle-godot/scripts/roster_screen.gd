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


func build() -> void:
	card_width = 980
	card.custom_minimum_size = Vector2(980, 0)
	tag("STAFF · THE GACHA")
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := Label.new()
	t.text = "Roster"
	t.theme_type_variation = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(button("PULL ×1 · 30", "Amber", func() -> void: _pull(1)))
	head.add_child(button("PULL ×10 · 270", "Primary", func() -> void: _pull(10)))
	head.add_child(button("CLOSE", "Ghost", close))
	para("Everyone is a rule. Pull new people; a duplicate gives that person +5% per shift, capped at +50%. Pity: an epic within 30 pulls.", 14)
	pity = Label.new()
	pity.theme_type_variation = "Mono"
	pity.add_theme_color_override("font_color", Look.AMBER)
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
	rdim.color = Color(0.01, 0.01, 0.02, 0.9)
	reveal.add_child(rdim)
	var rv := VBoxContainer.new()
	rv.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	rv.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rv.grow_vertical = Control.GROW_DIRECTION_BOTH
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 18)
	reveal.add_child(rv)
	var rt := Label.new()
	rt.text = "NEW HIRES"
	rt.theme_type_variation = "Tag"
	rt.add_theme_color_override("font_color", Look.AMBER)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rt)
	reveal_row = HBoxContainer.new()
	reveal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reveal_row.add_theme_constant_override("separation", 10)
	rv.add_child(reveal_row)
	reveal_done = button("TAKE THEM TO THE FLOOR", "Primary", func() -> void:
		reveal.visible = false
		render())
	reveal_done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rv.add_child(reveal_done)


func on_open() -> void:
	render()


func render() -> void:
	pity.text = "Epic guaranteed within %d pulls  ·  Gold %d  ·  tickets %d" % [Roster.PITY - Economy.since_epic(), Economy.gold(), Economy.tickets()]
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
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(52, 52)
	var pc := Piece.new()
	pc.setup(p["id"], 60, 31)
	pc.position = Vector2(26, 36)
	pc.show_score = false
	icon.add_child(pc)
	top.add_child(icon)
	var nm := VBoxContainer.new()
	top.add_child(nm)
	var b := Label.new()
	b.text = p["name"] if owned else "???"
	b.add_theme_font_override("font", Look.font_ui_bold)
	nm.add_child(b)
	var rar := Label.new()
	rar.text = str(p["rarity"]).to_upper()
	rar.theme_type_variation = "Tag"
	rar.add_theme_color_override("font_color", rarity_color(p["rarity"]))
	nm.add_child(rar)
	var rule := Label.new()
	rule.text = p["rule"]
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.add_theme_color_override("font_color", Look.AMBER)
	rule.add_theme_font_size_override("font_size", 13)
	v.add_child(rule)
	var bio := Label.new()
	bio.text = p["bio"] if owned else "Not pulled yet."
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio.add_theme_color_override("font_color", Look.MUTED)
	bio.add_theme_font_size_override("font_size", 12)
	v.add_child(bio)
	var meta := Label.new()
	meta.theme_type_variation = "Tag"
	var d := Economy.dupes(p["id"])
	meta.text = "on floor %d/%d · dupes %d (+%d%%) · shifts %d" % [Ticker.placed_count(p["id"]), int(p["slots"]), d, int(round((Roster.dupe_bonus(d) - 1.0) * 100.0)), Economy.affection(p["id"])]
	v.add_child(meta)
	var aff := HBoxContainer.new()
	aff.add_theme_constant_override("separation", 4)
	v.add_child(aff)
	var tier := Economy.affection_tier(p["id"])
	for i in range(4):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(26, 5)
		pip.color = Look.ROSE if tier > i else Look.LINE
		aff.add_child(pip)
	var nxt := Label.new()
	nxt.theme_type_variation = "Tag"
	var next_t := -1
	for x in Economy.AFF_TIERS:
		if int(x) > Economy.affection(p["id"]):
			next_t = int(x)
			break
	nxt.text = ("%d/%d" % [Economy.affection(p["id"]), next_t]) if next_t > 0 else "MAX"
	aff.add_child(nxt)
	return c


static func rarity_color(r: String) -> Color:
	match r:
		"epic": return Look.ROSE
		"rare": return Look.AMBER
	return Look.STEEL.lightened(0.3)


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
	reveal.visible = true
	reveal_done.visible = false
	clear(reveal_row)
	_cards.clear()
	for i in range(results.size()):
		var gc := GachaCard.new()
		gc.setup(results[i])
		gc.modulate.a = 0.0
		gc.position.y = 40
		reveal_row.add_child(gc)
		_cards.append(gc)
	await get_tree().process_frame
	for i in range(_cards.size()):
		var gc: GachaCard = _cards[i]
		var tw := gc.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_property(gc, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(0.35 + 0.06 * _cards.size()).timeout
	for i in range(_cards.size()):
		var gc: GachaCard = _cards[i]
		gc.flip()
		Sfx.flip(str(results[i]["rarity"]))
		await get_tree().create_timer(0.22 if _cards.size() > 1 else 0.4).timeout
	reveal_done.visible = true
	reveal_done.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(reveal_done, "modulate:a", 1.0, 0.25)
