extends Control
## The tier map — where After Dark's loop begins and ends.
##
## A column of tier cards: which levels, how many cleared, a PLAY button, and at the end
## of every row the scene card. Locked cards show the parent game's own *_x_locked teaser,
## dimmed, with a LOCKED tag; unlocked ones open scripts/scene_view.gd — which shows the
## delivered plate or nothing (no rendered creative, no bytes, no unlock: the map never
## invents a picture). Past the pool the card says PLACEHOLDER in as many words.
##
## The right column carries the three systems Nutaku's top 100 keep in the frame — daily
## mission, streak, leaderboard — as LOCAL STUBS, labelled as such on screen, so that
## the frame exists before the network does.

var focus_tier := 0
var from_title := true

var _ui: CanvasLayer
var _scroll: ScrollContainer
var _viewer: Control


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_backdrop()
	if F2P.on():
		# Nutaku: the map is the server's. Log in (handshake -> session) before drawing.
		_loading()
		if not await F2P.ensure():
			_loading("Could not reach the game server. " + Nutaku.last_error)
			return
		await Nutaku.refresh()
	_build()
	I18n.changed.connect(func(_l): _build())


func _loading(msg: String = "Signing in…") -> void:
	if _ui:
		_ui.queue_free()
	_ui = CanvasLayer.new()
	_ui.layer = 1
	add_child(_ui)
	var c := CenterContainer.new()
	c.theme = StudioTheme.build()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var l := StudioTheme.display_label(msg, 22, Palette.GOLD)
	l.name = "Loading"
	c.add_child(l)


func _build_backdrop() -> void:
	var stage := CanvasLayer.new()
	stage.layer = -1
	add_child(stage)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(root)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ground)
	# the key visual, far back and washed to a fifth, so the map lives in the same room
	var key := Art.plate("key")
	if key != null:
		var tr := TextureRect.new()
		tr.texture = key
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.modulate = Color(1, 1, 1, 0.22)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tr)
	var lamp := PieceView.lamp(1600.0, Palette.LAMP, 0.7)
	lamp.position = Vector2(get_viewport_rect().size.x * 0.75, get_viewport_rect().size.y * 0.15)
	root.add_child(lamp)


func _build() -> void:
	if _ui:
		_ui.queue_free()
	_ui = CanvasLayer.new()
	_ui.layer = 1
	add_child(_ui)

	var pad := MarginContainer.new()
	pad.theme = StudioTheme.build()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(m, 40)
	pad.add_theme_constant_override("margin_top", 22)
	pad.add_theme_constant_override("margin_bottom", 22)
	_ui.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	pad.add_child(col)

	# header: the mark, the title, back
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var mark := VectorMark.new()
	mark.mark = VectorMark.NAME
	mark.custom_minimum_size = Vector2(116, 38)
	mark.weight = 1.15
	mark.ink = Palette.ACCENT
	mark.accent = Palette.GOLD
	mark.shadow = Color(Palette.GROUND_DEEP, 0.9)
	head.add_child(mark)
	var title := StudioTheme.display_label(I18n.t("map_btn"), 24, Palette.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var rating := Label.new()
	rating.theme_type_variation = "Tag"
	rating.text = I18n.t("rating")
	rating.add_theme_color_override("font_color", Palette.MUTED)
	head.add_child(rating)
	var back := Button.new()
	back.name = "Back"
	back.text = "‹ " + I18n.t("back")
	back.theme_type_variation = "Ghost"
	back.pressed.connect(_to_title)
	head.add_child(back)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	col.add_child(body)

	# left: the tiers
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	_scroll.add_child(list)
	var focus_card: Control = null
	for t in range(Tier.count()):
		var card := _tier_card(t)
		list.add_child(card)
		if t == focus_tier:
			focus_card = card

	# right: the daily systems — the server's on Nutaku, the labelled local stubs elsewhere
	var side := VBoxContainer.new()
	side.name = "Side"
	side.custom_minimum_size = Vector2(300, 0)
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)
	if F2P.on():
		for p in F2PUI.side(func(): _build(), _open_shop):
			side.add_child(p)
	else:
		side.add_child(_stub_daily())
		side.add_child(_stub_streak())
		side.add_child(_stub_board())

	if focus_card != null:
		await get_tree().process_frame
		_scroll.ensure_control_visible(focus_card)
	_publish()


func _tier_card(t: int) -> Control:
	var card := PanelContainer.new()
	card.name = "Tier%d" % t
	card.theme_type_variation = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var open := Tier.is_open(t)
	var cleared := Tier.is_cleared(t)
	var h := StudioTheme.display_label("%s %d" % [I18n.t("tier").to_upper(), t + 1], 22,
		Palette.GOLD if open else Palette.FAINT)
	info.add_child(h)
	var lv := StudioTheme.mono_label("%s %d–%d   ·   %d/%d" % [I18n.t("level"), Tier.first_level(t) + 1,
		Tier.last_level(t) + 1, Tier.cleared_in(t), Tier.length(t)], 14, Palette.MUTED)
	info.add_child(lv)
	var bar := ProgressBar.new()
	bar.max_value = Tier.length(t)
	bar.value = Tier.cleared_in(t)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	info.add_child(bar)
	var play := Button.new()
	play.name = "Play"
	play.text = (I18n.t("continue") if Tier.cleared_in(t) > 0 and not cleared else I18n.t("play")) + " →"
	play.theme_type_variation = "Primary" if open and not cleared else "Amber"
	play.disabled = not open
	play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	play.pressed.connect(func(): _play(t))
	info.add_child(play)

	# the scene card
	var scene := Tier.scene_for(t)
	var sc := PanelContainer.new()
	sc.name = "Scene"
	sc.theme_type_variation = "Glass"
	sc.custom_minimum_size = Vector2(250, 0)
	row.add_child(sc)
	var scol := VBoxContainer.new()
	scol.add_theme_constant_override("separation", 6)
	sc.add_child(scol)
	var id := str(scene["id"])
	var placeholder := bool(scene.get("placeholder", false))
	var unlocked := (not placeholder) and Tier.is_unlocked(id)
	if F2P.on():
		unlocked = (not placeholder) and F2P.server_unlocked(id)
	if placeholder:
		var ph := StudioTheme.mono_label(I18n.t("placeholder_scene"), 12, Palette.RED_TEXT)
		ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ph.custom_minimum_size = Vector2(230, 96)
		scol.add_child(ph)
	else:
		var pic := TextureRect.new()
		pic.texture = load(Tier.teaser_path(id))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(230, 118)
		# locked: dimmed and desaturated toward the ground; unlocked: lit
		pic.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.45, 0.32, 0.42, 1)
		scol.add_child(pic)
	var st := StudioTheme.mono_label(str(scene["title"]), 13, Palette.TEXT if unlocked else Palette.MUTED)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scol.add_child(st)
	var tag := Label.new()
	tag.theme_type_variation = "Tag"
	if unlocked:
		tag.text = I18n.t("unlocked")
		tag.add_theme_color_override("font_color", Palette.SUCCESS)
	elif cleared and not placeholder:
		tag.text = I18n.t("trophy")     # earned, not yet delivered: the card says so
		tag.add_theme_color_override("font_color", Palette.GOLD)
	else:
		tag.text = I18n.t("locked") + " · " + I18n.t("clear_to_unlock")
		tag.add_theme_color_override("font_color", Palette.ACCENT)
	scol.add_child(tag)
	if F2P.on() and not placeholder and not unlocked and not cleared:
		# the one early-unlock offer: the tier's scene now, for gold
		var buy := Button.new()
		buy.name = "BuyScene"
		buy.text = "Unlock now · %s" % F2PUI.gold(F2P.tier_sku(t))
		buy.theme_type_variation = "Ghost"
		buy.pressed.connect(func():
			buy.disabled = true
			var r := await Nutaku.buy(F2P.tier_sku(t))
			if str(r.get("status", "")) == "success":
				_build()
			else:
				buy.text = F2PUI._pay_text(r)
				buy.disabled = false)
		scol.add_child(buy)
	if not placeholder and (unlocked or cleared):
		var view := Button.new()
		view.name = "View"
		view.text = I18n.t("scene").to_upper() if unlocked else I18n.t("unlock_scene")
		view.theme_type_variation = "Amber" if unlocked else "Primary"
		view.pressed.connect(func(): _view(scene))
		scol.add_child(view)
	return card


# ---- the stubs ------------------------------------------------------------------------

func _stub(title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "Card"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(StudioTheme.display_label(title, 16, Palette.ACCENT))
	v.set_meta("panel", p)
	return v


func _stub_daily() -> Control:
	var v := _stub(I18n.t("daily"))
	v.add_child(StudioTheme.serif_label(I18n.f("daily_line", Tier.DAILY_GOAL), 14, Palette.TEXT))
	var bar := ProgressBar.new()
	bar.max_value = Tier.DAILY_GOAL
	bar.value = mini(Tier.daily_progress(), Tier.DAILY_GOAL)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	v.add_child(bar)
	v.add_child(StudioTheme.mono_label("%d/%d   ·   %s" % [Tier.daily_progress(), Tier.DAILY_GOAL,
		I18n.f("daily_days", Tier.daily_days())], 14, Palette.GOLD))
	v.add_child(StudioTheme.mono_label(I18n.t("stub"), 12, Palette.RED_TEXT))
	return v.get_meta("panel")


func _stub_streak() -> Control:
	var v := _stub(I18n.t("streak"))
	var big := StudioTheme.display_label("%d" % Tier.streak, 34, Palette.HEAT)
	v.add_child(big)
	v.add_child(StudioTheme.mono_label("best %d" % Tier.streak_best(), 14, Palette.MUTED))
	return v.get_meta("panel")


func _stub_board() -> Control:
	var v := _stub(I18n.t("board"))
	var i := 1
	for r in Tier.leaderboard():
		var line := StudioTheme.mono_label("%d.  %-10s %6d" % [i, r[0], r[1]], 14,
			Palette.GOLD if r[2] else Palette.FAINT)
		v.add_child(line)
		i += 1
	v.add_child(StudioTheme.mono_label(I18n.t("stub"), 12, Palette.RED_TEXT))
	return v.get_meta("panel")


# ---- going places ----------------------------------------------------------------------

func _play(t: int) -> void:
	Sfx.slide()
	var scene: PackedScene = load("res://scenes/game.tscn")
	var node := scene.instantiate()
	node.set("start_level", Tier.next_level_in(t))
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


## View an unlocked scene, or try the delivery again for a tier that is cleared but whose
## plate never arrived. Either way the picture comes from Unlock or does not come.
func _view(scene: Dictionary) -> void:
	var id := str(scene["id"])
	if F2P.on():
		if not F2P.server_unlocked(id) or not await F2P.deliver(id):
			return
		_viewer = SceneView.open(_ui, scene, func():
			_viewer = null
			_build())
		_publish()
		return
	if not Unlock.ready_for(id):
		var ok := await _deliver(id)
		if not ok:
			return
	Tier.mark_unlocked(id)
	_viewer = SceneView.open(_ui, scene, func():
		_viewer = null
		get_node("/root/Gate").board_offer_more("adult")
		_build())
	_publish()


func _deliver(id: String) -> bool:
	var gate := get_node("/root/Gate")
	var okay: bool = await gate.require("scene_" + id, str(Tier.scene_by_id(id).get("title", "")), "cg")
	if not okay:
		return false
	if not await Unlock.start(id):
		return false
	# the gateway refuses a redeem inside its minimum wait; wait it out honestly
	for _i in range(5):
		if await Unlock.redeem(id):
			return true
		if Unlock.last_status != 425:
			break
		await get_tree().create_timer(4.0).timeout
	return false


func _to_title() -> void:
	Sfx.slide()
	var scene: PackedScene = load("res://scenes/title.tscn")
	var node := scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed):
		return
	# Enter/Space: the viewer's Close when it is open, else play the current tier — the
	# keyboard path a phone never uses and the headless driver always does.
	if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER or e.keycode == KEY_SPACE:
		if _viewer != null:
			var c := _viewer.find_child("Close", true, false)
			if c is Button:
				(c as Button).pressed.emit()
			return
		_play(Tier.current())
	elif e.keycode == KEY_ESCAPE:
		if _viewer != null:
			return
		_to_title()


func _process(_d: float) -> void:
	_publish()
	if F2P.on() and _ui:
		var ct := _ui.find_child("CandleText", true, false)
		if ct is Label:
			(ct as Label).text = F2P.candle_text()


func _open_shop() -> void:
	var ov := Control.new()
	ov.name = "ShopOverlay"
	ov.theme = StudioTheme.build()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(Palette.GROUND_DEEP, 0.82)
	ov.add_child(bg)
	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(centre)
	_ui.add_child(ov)
	F2PUI.shop(ov, func():
		ov.queue_free()
		_build())


func _publish() -> void:
	if not OS.has_feature("web"):
		return
	var unlocked := []
	for t in range(Tier.count()):
		var sc := Tier.scene_for(t)
		if Tier.is_unlocked(str(sc["id"])):
			unlocked.append(sc["id"])
	JavaScriptBridge.eval("window.__fold_state=%s;" % JSON.stringify({
		"f2p": F2P.on(),
		"energy": F2P.energy(),
		"frontier": int((Nutaku.state.get("progress", {}) as Dictionary).get("frontier", -1)),
		"screen": "map",
		"tier": Tier.current() + 1,
		"tiers": Tier.count(),
		"unlocked": unlocked,
		"scene_visible": _viewer != null,
		"streak": Tier.streak,
		"daily": Tier.daily_progress(),
		"lang": I18n.lang,
	}), true)
