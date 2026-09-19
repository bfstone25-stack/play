extends Control
## The deck — the West's instrument. Cut, then turn one card from the 78, upright or
## reversed; the same ladder underneath (Fortune.RANK_TIERS). The reading sits on
## parchment; a reversed card is integrated on the rack like a 凶.

var stack: Control
var top_card: CardView
var cut_btn: Button
var turn_btn: Button
var panel_host: Control
var busy := false
var turn_done := true
var cut := false
var last_result: Dictionary = {}
var pos_lbl: Label


func _ready() -> void:
	relayout()
	Fortune.changed.connect(_refresh)


func _process(dt: float) -> void:
	Fortune.tick(dt)


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var bg := Backdrop.new()
	bg.mode = "west"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 84
	v.offset_left = 28
	v.offset_right = -28
	v.offset_bottom = -30
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var title := StudioTheme.label(Tx.t("home.west"), 30, Palette.SILVER, "italic" if Tx.lang == "en" else "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := StudioTheme.label(Tx.t("home.west.sub"), 16, Palette.SILVER_DIM, "ui")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	stack = Control.new()
	stack.custom_minimum_size = Vector2(0, 560)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(stack)
	_build_stack()
	pos_lbl = StudioTheme.label("", 16, Palette.CANDLE, "bold")
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pos_lbl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	cut_btn = StudioTheme.button(Tx.t("deck.cut"), "Silver")
	cut_btn.custom_minimum_size = Vector2(180, 0)
	cut_btn.pressed.connect(do_cut)
	row.add_child(cut_btn)
	turn_btn = StudioTheme.button("", "Candle")
	turn_btn.custom_minimum_size = Vector2(260, 0)
	turn_btn.pressed.connect(turn)
	row.add_child(turn_btn)
	var honest := StudioTheme.label(Tx.t("shop.honest"), 13, Palette.SILVER_DIM, "ui")
	honest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	honest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(honest)
	panel_host = Control.new()
	panel_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_host)
	_refresh()
	if not Fortune.pending.is_empty() and Fortune.pending["kind"] == "card":
		_show_result(Fortune.pending)


func _build_stack() -> void:
	for c in stack.get_children():
		c.queue_free()
	var cw := 230.0
	var ch := 380.0
	for i in range(7):
		var cv := CardView.new()
		cv.setup("")
		cv.size = Vector2(cw, ch)
		cv.position = Vector2((720 - 56) * 0.5 - cw * 0.5 + i * 1.5, 560 * 0.5 - ch * 0.5 + 40 - i * 3.0)
		stack.add_child(cv)
	top_card = CardView.new()
	top_card.setup("")
	top_card.size = Vector2(cw, ch)
	top_card.pivot_offset = top_card.size * 0.5
	top_card.position = Vector2((720 - 56) * 0.5 - cw * 0.5 + 10, 560 * 0.5 - ch * 0.5 + 20)
	stack.add_child(top_card)


func _refresh() -> void:
	if not is_instance_valid(turn_btn):
		return
	var free := Fortune.free_available()
	turn_btn.text = Tx.t("deck.turn.free" if free else "deck.turn")
	if not free and Fortune.merit.merit < Fortune.TUBE:
		turn_btn.text = Tx.t("tube.need", {"n": Fortune.TUBE - Fortune.merit.merit})
	turn_btn.disabled = busy or not Fortune.can_draw()
	cut_btn.disabled = busy


func do_cut() -> void:
	if busy:
		return
	busy = true
	_refresh()
	Sfx.flip()
	# the top half slides off and comes back under
	var half := []
	var kids := stack.get_children()
	for i in range(kids.size() / 2, kids.size()):
		half.append(kids[i])
	var tw := create_tween().set_parallel(true)
	for c in half:
		tw.tween_property(c, "position:x", c.position.x + 200.0, 0.22).set_trans(Tween.TRANS_SINE)
	await tw.finished
	var t2 := create_tween().set_parallel(true)
	for c in half:
		stack.move_child(c, 0)
		t2.tween_property(c, "position:x", c.position.x - 200.0, 0.22).set_trans(Tween.TRANS_SINE)
	await t2.finished
	# keep top_card on top for the turn
	stack.move_child(top_card, stack.get_child_count() - 1)
	cut = true
	busy = false
	_refresh()


func turn() -> void:
	if busy or not Fortune.can_draw():
		return
	busy = true
	turn_done = false
	_refresh()
	var r := Fortune.draw("card")
	last_result = r
	top_card.setup(r["id"], r["reversed"], false)
	var tw := create_tween()
	tw.tween_property(top_card, "position:y", top_card.position.y - 40.0, 0.25).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await top_card.flip()
	pos_lbl.text = Tx.t("deck.position", {"p": Tx.t("pos." + r["position"])})
	await get_tree().create_timer(0.7).timeout
	_show_result(r)
	busy = false
	turn_done = true
	_refresh()


func _show_result(r: Dictionary) -> void:
	if top_card and not top_card.face_up:
		top_card.setup(r["id"], r["reversed"], true)
	stack.visible = false
	var dim := ColorRect.new()
	dim.color = Color(Palette.VIOLET_DEEP, 0.6)
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
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)
	var cv := CardView.new()
	cv.setup(r["id"], r["reversed"], true)
	cv.custom_minimum_size = Vector2(170, 280)
	cv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(cv)
	var p := ResultPanel.new()
	p.custom_minimum_size = Vector2(600, 0)
	p.setup(r)
	p.done.connect(func():
		dim.queue_free()
		sc.queue_free()
		top_card.setup("", false, false)
		stack.visible = true
		pos_lbl.text = ""
		_refresh())
	col.add_child(p)
	col.modulate.a = 0.0
	create_tween().tween_property(col, "modulate:a", 1.0, 0.35)
	Sfx.chime(1.0 if not r["reversed"] else 0.75)


func dev_state() -> Dictionary:
	return {"turn_done": turn_done, "cut": cut, "result_open": panel_host.get_child_count() > 0}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	match str(cmd["op"]):
		"cut":
			do_cut()
			return {"ok": true}
		"turn":
			if busy or not Fortune.can_draw():
				return {"ok": false}
			turn()
			return {"ok": true}
		"result":
			return {"ok": true, "result": last_result}
		"read":
			for panel in panel_host.find_children("*", "ResultPanel", true, false):
				return {"handled": true, "ok": panel.choose(str(cmd.get("choice", "keep")))}
			return {"handled": false}
	return {"ok": false, "why": "unknown"}
