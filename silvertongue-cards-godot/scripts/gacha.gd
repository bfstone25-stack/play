## Gacha — a moment, not a list. Cards land face-down on the felt, flip one by one, a
## rarity glow on rares and epics, a DUPE toast when the collection already held one.
## Pity and prices are the backend's; the client only reads them.
extends Control

var main: Node
var _grid: GridContainer
var _pity: Label
var _pull1: Button
var _pull10: Button
var _owned := {}                 # card id -> n, before the pull, for the dupe toast
var _busy := false
var last_pull := {}


func setup(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 14
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 0)
	tbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbox.add_child(StudioTheme.display_label("GACHA", 30, Palette.LAMP))
	var sub := StudioTheme.serif_label("Common 70 · Rare 25 · Epic 5. A ten-pull always holds a rare; every thirtieth pull is an epic. Cards add sentences you can say. They do not change what she needs.", 13, Palette.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tbox.add_child(sub)
	head.add_child(tbox)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pull1 = Button.new()
	_pull1.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(_pull1, "primary")
	_pull1.pressed.connect(func(): drive_pull(1))
	_pull10 = Button.new()
	_pull10.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(_pull10, "primary")
	_pull10.pressed.connect(func(): drive_pull(10))
	btns.add_child(_pull1)
	btns.add_child(_pull10)
	var dev := Button.new()
	dev.text = "+1000 GOLD (dev)"
	dev.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(dev, "quiet")
	dev.pressed.connect(func():
		Sfx.play("ui_click")
		var r := await Api.dev_gold(1000)
		if r.has("error"):
			main.toast(str(r["error"]))
		else:
			Sfx.play("gold")
			main.toast("+1000 gold (dev)")
			await main.refresh()
			_render_prices())
	btns.add_child(dev)
	head.add_child(btns)
	_pity = StudioTheme.mono_label("", 11, Palette.DIM)
	col.add_child(_pity)
	# the felt
	var felt := PanelContainer.new()
	felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	felt.add_theme_stylebox_override("panel", StudioTheme.flat(Color("17121a"), Palette.LINE, 14, 1, Vector2(16, 14)))
	col.add_child(felt)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	felt.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	_render_prices()
	_load_owned()
	resized.connect(_fit_columns)
	call_deferred("_fit_columns")


func _fit_columns() -> void:
	_grid.columns = maxi(2, int((size.x - 90) / (Card.W + 14)))


func _render_prices() -> void:
	var eco: Dictionary = Api.last_economy
	var pp: Dictionary = eco.get("pull_price", {"1": 100, "10": 900})
	_pull1.text = "1 PULL · %d" % int(pp.get("1", 100))
	_pull10.text = "10 PULL · %d" % int(pp.get("10", 900))
	var p: Dictionary = eco.get("pity", {})
	_pity.text = "PULLS %d · EPIC PITY IN %d · CREDITS %d" % [int(p.get("pulls", 0)), int(p.get("epic_pity_in", 30)), int(p.get("pull_credits", 0))]


func _load_owned() -> void:
	var d := await Api.deck("closing_time")
	_owned.clear()
	for c in d.get("collection", []):
		_owned[str(c.get("id", ""))] = int(c.get("n", 0))


func drive_pull(n: int) -> Dictionary:
	if _busy:
		return {"error": "busy"}
	_busy = true
	Sfx.play("ui_click")
	var r := await Api.pull(n)
	if r.has("error"):
		_busy = false
		main.toast(str(r["error"]))
		_render_prices()
		return r
	last_pull = r
	_render_prices()
	for c in _grid.get_children():
		c.queue_free()
	var cards: Array = r.get("cards", [])
	var dupes := 0
	var seen := {}
	var nodes: Array[Card] = []
	for i in cards.size():
		var d: Dictionary = cards[i]
		var wrap := Control.new()
		wrap.custom_minimum_size = Vector2(Card.W, Card.H)
		_grid.add_child(wrap)
		var c := Card.new()
		c.interactive = false
		wrap.add_child(c)
		c.setup(d, true)
		c.set_face_down(true)
		c.modulate.a = 0.0
		nodes.append(c)
	await get_tree().process_frame
	# deal
	for i in nodes.size():
		var c := nodes[i]
		var tw := create_tween()
		tw.tween_property(c, "modulate:a", 1.0, 0.16).set_delay(0.06 * i)
		Sfx.play("flip", -20.0)
	await get_tree().create_timer(0.06 * nodes.size() + 0.25).timeout
	# flip, one by one
	for i in nodes.size():
		var c := nodes[i]
		var d: Dictionary = cards[i]
		var id := str(d.get("id", ""))
		var had := int(_owned.get(id, 0)) + int(seen.get(id, 0))
		seen[id] = int(seen.get(id, 0)) + 1
		var pity = d.get("pity")
		var is_pity: bool = typeof(pity) == TYPE_STRING and pity != "" or typeof(pity) == TYPE_BOOL and pity
		await _flip(c, had > 0, is_pity)
		if had > 0:
			dupes += 1
		await get_tree().create_timer(0.12).timeout
	for id in seen:
		_owned[id] = int(_owned.get(id, 0)) + int(seen[id])
	if dupes > 0:
		main.toast("%d DUPE%s — already in your collection" % [dupes, "" if dupes == 1 else "S"])
	_busy = false
	return r


func _flip(c: Card, dupe: bool, pity: bool) -> void:
	c.pivot_offset = Vector2(Card.W / 2, Card.H / 2)
	var base := c.scale
	var tw := create_tween()
	tw.tween_property(c, "scale:x", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		c.set_face_down(false)
		var rar := str(c.data.get("rarity", "common"))
		if rar == "epic":
			Sfx.play("epic")
		elif rar == "rare":
			Sfx.play("rare")
		else:
			Sfx.play("flip", -14.0)
		if dupe:
			Sfx.play("dupe", -14.0)
			_stamp(c, "DUPE", Palette.MUTED)
		if pity:
			_stamp(c, "PITY", Palette.EPIC_TEXT, 22))
	tw.tween_property(c, "scale:x", base.x, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var rar := str(c.data.get("rarity", "common"))
	if rar != "common":
		tw.parallel().tween_property(c, "glow", 1.0, 0.2)
		tw.tween_property(c, "glow", 0.25 if rar == "epic" else 0.0, 1.0)
	await tw.finished


func _stamp(c: Card, text: String, color: Color, y: float = 0.0) -> void:
	var l := StudioTheme.mono_label(text, 11, color)
	l.position = Vector2(Card.W - 60, Card.H - 30 - y)
	l.rotation_degrees = -12
	c.add_child(l)
