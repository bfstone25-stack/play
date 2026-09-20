extends Control
## The building — the main scene. A 16:9 room: the parent's office plate as the room,
## the 5x4 floor drawn on it as furniture positions, Mirei on the right, the offers tray
## at the bottom, the floor strip on the left, the rolling HUD across the top. Every
## other screen is an Overlay opened from a click here.

const FloorViewScene := preload("res://scenes/floor.tscn")
const ReturnScene := preload("res://scenes/return_screen.tscn")
const RosterScene := preload("res://scenes/roster.tscn")
const ShopScene := preload("res://scenes/shop.tscn")
const GalleryScene := preload("res://scenes/gallery.tscn")
const DailyScene := preload("res://scenes/daily_floor.tscn")
const PrestigeScene := preload("res://scenes/prestige.tscn")

const NAMES := {"coffee": "Coffee", "dan": "Dan, 41", "priya": "Priya, 29", "wes": "Wes, 36", "mute": "Headphones", "printer": "Printer", "mara": "Mara, 34", "corner": "Corner desk", "nia": "Nia, 33", "sol": "Sol, 38"}
const RELIC_NAME := {"severance": "Severance", "quiet": "Quiet Floor", "pto": "Unlimited PTO", "glass": "Glass Office", "badge": "Badge Reel", "army": "Intern Army"}

var view: Dictionary = {}
var mode := "building"
var daily: Dictionary = {}
var offers: Array = []
var selected := -1
var last_chain := 0

var floor_view: FloorView
var mirei: MireiPanel
var rate_l: RollingLabel
var bank_l: RollingLabel
var gold_l: RollingLabel
var chain_l: Label
var pips: Array = []
var next_l: Label
var preview_l: Label
var due_l: Label
var cover_l: Label
var floor_strip: VBoxContainer
var relic_l: Label
var offer_row: HBoxContainer
var commit_btn: Button
var reroll_btn: Button
var banner_l: Label
var gallery_btn: Button
var tabs: Dictionary = {}
var sound_btn: Button
var mode_l: Label
var _banner_tw: Tween

var return_screen: ReturnScreen
var roster: RosterScreen
var shop: ShopScreen
var gallery: GalleryScreen
var plate_view: PlateView
var daily_screen: Overlay
var daily_result: SimpleScreens.DailyResult
var prestige: Overlay
var notice: SimpleScreens.Notice
var intro: TitleScreen


func _ready() -> void:
	view = Ticker.B["floors"][0]
	_build_room()
	_build_hud()
	_build_left()
	_build_right()
	_build_tray()
	_build_overlays()
	Ticker.changed.connect(hud)
	Ticker.returned.connect(func(rep: Dictionary) -> void: return_screen.show_report(rep))
	Ticker.evicted.connect(func(rep: Dictionary) -> void:
		Sfx.evict()
		notice.show_evictions(rep["evictions"]))
	Ticker.shielded.connect(func() -> void: banner("A rent shield covered one eviction."))
	Ticker.shift_paid.connect(func(rep: Dictionary) -> void:
		floor_view.burst(int(rep["rent"]))
		Sfx.settle(min(5, int(rep["shifts"]))))
	Ticker.prestige_ready.connect(func() -> void: prestige.open())
	Ticker.plate_earned.connect(func(_slot: String) -> void:
		Sfx.win()
		_mark_gallery())
	Ticker.banner.connect(banner)
	Ticker.bridge_handler = _bridge
	refill_offers()
	_mark_gallery()
	hud()
	intro.open()


# ---- the room -------------------------------------------------------------------------

func _build_room() -> void:
	var bg := TextureRect.new()
	bg.name = "Room"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture = Look.art("title")
	bg.modulate = Color(0.62, 0.46, 0.56)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	if bg.texture == null:
		bg.self_modulate = Color(0, 0, 0, 0)
		var fallback := ColorRect.new()
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.color = Palette.GROUND
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fallback)
	# a warm lamp pool in the middle of the room, dark at the edges
	var lamp := TextureRect.new()
	lamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.46, 0.55)
	gt.fill_to = Vector2(0.46, 1.15)
	var g := Gradient.new()
	g.set_color(0, Color(Palette.GOLD, 0.14))
	g.set_color(1, Color(Palette.GROUND_DEEP, 0.82))
	gt.gradient = g
	gt.width = 256
	gt.height = 144
	lamp.texture = gt
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lamp)
	floor_view = FloorViewScene.instantiate()
	floor_view.anchor_left = 0.0
	floor_view.anchor_right = 1.0
	floor_view.anchor_top = 0.0
	floor_view.anchor_bottom = 1.0
	floor_view.offset_left = 214
	floor_view.offset_right = -318
	floor_view.offset_top = 84
	floor_view.offset_bottom = -168
	floor_view.cell_clicked.connect(_on_cell)
	add_child(floor_view)


# ---- HUD ------------------------------------------------------------------------------

func _stat(parent: Control, label: String, big: bool = true, color: Color = Palette.TEXT, coin: bool = false) -> RollingLabel:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)
	var l := Label.new()
	l.text = label
	l.theme_type_variation = "Tag"
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	v.add_child(row)
	if coin:
		row.add_child(Coin.new(9))
	var n := RollingLabel.new()
	n.theme_type_variation = "Big" if big else "Value"
	n.add_theme_color_override("font_color", color)
	n.set_now(0)
	row.add_child(n)
	return n


func _build_hud() -> void:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "Glass"
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12
	bar.offset_right = -12
	bar.offset_top = 10
	bar.offset_bottom = 74
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	bar.add_child(h)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	h.add_child(tv)
	var t := Label.new()
	t.text = "OVERTIME LANDLORD"
	t.add_theme_font_override("font", Look.font_display)
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", Palette.ACCENT_SOFT)
	tv.add_child(t)
	mode_l = Label.new()
	mode_l.text = "AFTER HOURS · IDLE · 18+"
	mode_l.theme_type_variation = "Tag"
	tv.add_child(mode_l)
	rate_l = _stat(h, "RENT / HOUR", true, Palette.HEAT)
	bank_l = _stat(h, "BANK", true, Palette.TEXT)
	gold_l = _stat(h, "GOLD", true, Palette.GOLD, true)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 3)
	h.add_child(cv)
	var cl := HBoxContainer.new()
	cv.add_child(cl)
	var ct := Label.new()
	ct.text = "CHAIN "
	ct.theme_type_variation = "Tag"
	cl.add_child(ct)
	chain_l = Label.new()
	chain_l.theme_type_variation = "Value"
	chain_l.text = "0"
	chain_l.add_theme_color_override("font_color", Palette.HEAT)
	cl.add_child(chain_l)
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 4)
	cv.add_child(pr)
	for i in range(6):
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(22, 6)
		p.color = Palette.PANEL_EDGE
		p.pivot_offset = Vector2(11, 3)
		pr.add_child(p)
		pips.append(p)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 0)
	h.add_child(nv)
	var nt := Label.new()
	nt.text = "NEXT SHIFT"
	nt.theme_type_variation = "Tag"
	nv.add_child(nt)
	next_l = Label.new()
	next_l.theme_type_variation = "Big"
	next_l.add_theme_color_override("font_color", Palette.TEXT)
	next_l.text = "10:00"
	nv.add_child(next_l)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	tabs = {}
	for pair in [["roster", "ROSTER"], ["shop", "SHOP"], ["daily", "DAILY"], ["gallery", "PLATES 0/10"]]:
		var b := Button.new()
		b.text = pair[1]
		var key: String = pair[0]
		b.pressed.connect(func() -> void: _open_tab(key))
		h.add_child(b)
		tabs[key] = b
	gallery_btn = tabs["gallery"]
	sound_btn = Button.new()
	sound_btn.theme_type_variation = "Ghost"
	sound_btn.text = "SOUND ON"
	sound_btn.pressed.connect(func() -> void:
		var on: bool = not bool(Ticker.cabinet.get("sound", true))
		Ticker.cabinet["sound"] = on
		Ticker.save_cabinet()
		Sfx.set_muted(not on)
		sound_btn.text = "SOUND ON" if on else "SOUND OFF")
	h.add_child(sound_btn)
	banner_l = Label.new()
	banner_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner_l.offset_top = 86
	banner_l.offset_left = -300
	banner_l.offset_right = 300
	banner_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_l.add_theme_font_override("font", Look.font_display)
	banner_l.add_theme_color_override("font_color", Palette.GOLD_PALE)
	banner_l.add_theme_font_size_override("font_size", 18)
	banner_l.modulate.a = 0.0
	banner_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blayer := CanvasLayer.new()
	blayer.layer = 20
	add_child(blayer)
	banner_l.theme = Look.theme
	blayer.add_child(banner_l)


func _build_left() -> void:
	var col := PanelContainer.new()
	col.theme_type_variation = "Glass"
	col.anchor_top = 0.0
	col.anchor_bottom = 1.0
	col.offset_left = 12
	col.offset_right = 206
	col.offset_top = 84
	col.offset_bottom = -12
	add_child(col)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	col.add_child(v)
	var t := Label.new()
	t.text = "FLOORS"
	t.theme_type_variation = "Tag"
	v.add_child(t)
	floor_strip = VBoxContainer.new()
	floor_strip.add_theme_constant_override("separation", 4)
	v.add_child(floor_strip)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var rt := Label.new()
	rt.text = "RELICS"
	rt.theme_type_variation = "Tag"
	v.add_child(rt)
	relic_l = Label.new()
	relic_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_l.add_theme_font_size_override("font_size", 12)
	relic_l.add_theme_color_override("font_color", Palette.MUTED)
	v.add_child(relic_l)
	var dv := Label.new()
	dv.text = "DEV"
	dv.theme_type_variation = "Tag"
	v.add_child(dv)
	var dr := GridContainer.new()
	dr.columns = 3
	dr.add_theme_constant_override("h_separation", 3)
	dr.add_theme_constant_override("v_separation", 3)
	v.add_child(dr)
	for pair in [["+500g", func() -> void: Economy.dev_add_gold(500); hud()], ["+1h", func() -> void: Ticker.dev_advance(3600000)], ["+8h", func() -> void: Ticker.dev_advance(8 * 3600000)],
			["+1d", func() -> void: Ticker.dev_advance(24 * 3600000)], ["prestige", func() -> void: Ticker.dev_force_prestige()], ["reset", func() -> void: Ticker.reset_all(); view = Ticker.B["floors"][0]; refill_offers(); hud()]]:
		var b := Button.new()
		b.theme_type_variation = "Ghost"
		b.text = pair[0]
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(pair[1])
		dr.add_child(b)


func _build_right() -> void:
	var col := VBoxContainer.new()
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.anchor_top = 0.0
	col.anchor_bottom = 1.0
	col.offset_left = -310
	col.offset_right = -12
	col.offset_top = 84
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	mirei = MireiPanel.new()
	mirei.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mirei)
	var stats := PanelContainer.new()
	stats.theme_type_variation = "Glass"
	col.add_child(stats)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	stats.add_child(g)
	var a := Label.new()
	a.text = "RENT DUE / DAY"
	a.theme_type_variation = "Tag"
	g.add_child(a)
	due_l = Label.new()
	due_l.theme_type_variation = "Value"
	due_l.add_theme_color_override("font_color", Palette.HEAT)
	due_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	due_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g.add_child(due_l)
	var b := Label.new()
	b.text = "THIS BOARD / DAY"
	b.theme_type_variation = "Tag"
	g.add_child(b)
	cover_l = Label.new()
	cover_l.theme_type_variation = "Value"
	cover_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g.add_child(cover_l)


func _build_tray() -> void:
	var tray := PanelContainer.new()
	tray.theme_type_variation = "Glass"
	tray.anchor_top = 1.0
	tray.anchor_bottom = 1.0
	tray.anchor_left = 0.0
	tray.anchor_right = 1.0
	tray.offset_left = 214
	tray.offset_right = -318
	tray.offset_top = -158
	tray.offset_bottom = -12
	add_child(tray)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	tray.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var t := Label.new()
	t.text = "OFFERS — pick one, then tap an open desk. Tap a placed piece to send it back."
	t.theme_type_variation = "Tag"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	preview_l = Label.new()
	preview_l.theme_type_variation = "Value"
	preview_l.add_theme_color_override("font_color", Palette.GOLD)
	preview_l.add_theme_font_override("font", Look.font_display)
	preview_l.add_theme_font_size_override("font_size", 17)
	top.add_child(preview_l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	offer_row = HBoxContainer.new()
	offer_row.add_theme_constant_override("separation", 8)
	offer_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(offer_row)
	reroll_btn = Button.new()
	reroll_btn.text = "REROLL · 4"
	reroll_btn.custom_minimum_size = Vector2(0, 92)
	reroll_btn.pressed.connect(do_reroll)
	row.add_child(reroll_btn)
	commit_btn = Button.new()
	commit_btn.text = "COMMIT"
	commit_btn.theme_type_variation = "Primary"
	commit_btn.custom_minimum_size = Vector2(130, 92)
	commit_btn.pressed.connect(do_commit)
	row.add_child(commit_btn)


func _build_overlays() -> void:
	return_screen = ReturnScene.instantiate()
	return_screen.collect.connect(func() -> void:
		Sfx.win()
		hud())
	return_screen.extend_cap.connect(func() -> void:
		var r := Economy.buy("offline_cap_24h")
		if not r["ok"]:
			banner("Not enough Gold.")
			return
		return_screen.cap_btn.visible = false
		banner("Offline cap is now 24 hours.")
		hud())
	roster = RosterScene.instantiate()
	roster.pulled.connect(func(_res: Array) -> void:
		refill_offers()
		hud())
	roster.need_gold.connect(func() -> void: banner("Not enough Gold."))
	shop = ShopScene.instantiate()
	shop.bought.connect(func(_sku: String) -> void:
		refill_offers()
		hud())
	shop.need.connect(func(what: String) -> void: banner("Not enough rent." if what == "rent" else ("Not enough Gold." if what == "gold" else what)))
	shop.timeskip_report.connect(func(rep: Dictionary) -> void: return_screen.show_report(rep))
	gallery = GalleryScene.instantiate()
	plate_view = PlateView.new()
	gallery.view_plate.connect(func(id: String, cap: String, gated: bool, slot: String) -> void: plate_view.show_plate(id, cap, gated, slot))
	gallery.need_gold.connect(func() -> void: banner("Not enough Gold."))
	daily_screen = DailyScene.instantiate()
	daily_screen.start.connect(start_daily)
	daily_result = SimpleScreens.DailyResult.new()
	daily_result.back.connect(func() -> void:
		leave_daily()
		# The daily floor is this game's run, and its end is where the board is offered:
		# the casual catalogue, in the page, after a click. Nothing opens by itself.
		await get_tree().create_timer(0.9).timeout
		Gate.board_offer_more("casual"))
	prestige = PrestigeScene.instantiate()
	prestige.sign.connect(func() -> void:
		Ticker.do_prestige()
		view = Ticker.B["floors"][0]
		refill_offers()
		Sfx.win()
		banner("×%s" % str(Ticker.B["mult"]))
		hud())
	notice = SimpleScreens.Notice.new()
	notice.understood.connect(func() -> void:
		await get_tree().create_timer(0.9).timeout
		Gate.board_offer_break())
	intro = TitleScreen.new()
	intro.start.connect(func() -> void:
		Sfx.set_muted(not bool(Ticker.cabinet.get("sound", true)))
		Sfx.unlock()
		Ticker.start()
		Ticker.run_tick(true)
		refill_offers()
		hud())
	# Overlays live on their own canvas layer: the floor's pieces carry a z_index (back to
	# front on the desk) and would otherwise paint through every panel above them.
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	for o in [return_screen, roster, shop, gallery, plate_view, daily_screen, daily_result, prestige, notice, intro]:
		layer.add_child(o)
	for key in tabs.keys():
		(_tab_overlay(key) as Overlay).closed.connect(_mark_tabs)


func _tab_overlay(key: String) -> Overlay:
	match key:
		"roster": return roster
		"shop": return shop
		"daily": return daily_screen
		_: return gallery


func _open_tab(key: String) -> void:
	_tab_overlay(key).open()
	_mark_tabs()


## The active tab is magenta; the others fall back (PLATES keeps its gold once a plate is earned).
func _mark_tabs() -> void:
	for key in tabs.keys():
		var b: Button = tabs[key]
		if _tab_overlay(key).is_open():
			b.theme_type_variation = "Active"
		elif key == "gallery" and Ticker.cabinet["cg"].size() > 0:
			b.theme_type_variation = "Amber"
		else:
			b.theme_type_variation = ""


# ---- state helpers ------------------------------------------------------------------------

func cells() -> Array:
	return view["cells"]


func occupied() -> int:
	var n := 0
	for c in cells():
		if c != null:
			n += 1
	return n


func settle_now() -> Dictionary:
	if mode == "daily":
		return Roster.settle_idle(cells(), [], {})
	return Ticker.settle_floor(view)


func draw_offers(n: int) -> Array:
	if mode == "daily":
		return daily["seq"].slice(int(daily["at"]), int(daily["at"]) + n)
	var pool := Ticker.available()
	var out: Array = []
	for _i in range(n):
		if pool.is_empty():
			break
		out.append(pool.pop_at(randi() % pool.size()))
	return out


func refill_offers() -> void:
	offers = draw_offers(3)
	selected = -1
	_render_offers()


func _render_offers() -> void:
	for c in offer_row.get_children():
		c.queue_free()
	if offers.is_empty():
		var l := Label.new()
		l.text = "Out of pieces. Settle." if mode == "daily" else "The roster is empty — pull, or buy objects."
		l.theme_type_variation = "Value"
		l.add_theme_color_override("font_color", Palette.MUTED)
		offer_row.add_child(l)
		return
	for i in range(offers.size()):
		var id: String = offers[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if selected == i:
			b.theme_type_variation = "Active"
		var idx := i
		b.pressed.connect(func() -> void:
			selected = idx
			Sfx.place()
			mirei.set_line("place", true)
			_render_offers()
			floor_view.selected_id = offers[selected])
		var icon := Control.new()
		icon.position = Vector2(8, 10)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pc := Piece.new()
		pc.setup(id, 66, 34)
		pc.position = Vector2(30, 46)
		pc.show_score = false
		icon.add_child(pc)
		b.add_child(icon)
		var nm := Label.new()
		nm.text = NAMES.get(id, id)
		nm.position = Vector2(66, 22)
		nm.add_theme_font_override("font", Look.font_ui_bold)
		nm.add_theme_font_size_override("font_size", 14)
		nm.add_theme_color_override("font_color", Palette.TEXT)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		var pay := Label.new()
		var cat := Landlord.catalog_by_id(Roster.catalog())
		pay.text = "+%d" % int(cat.get(id, {}).get("payout", 1))
		pay.position = Vector2(66, 46)
		pay.add_theme_font_override("font", Look.font_display)
		pay.add_theme_font_size_override("font_size", 16)
		pay.add_theme_color_override("font_color", Palette.GOLD)
		pay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pay)
		offer_row.add_child(b)
	floor_view.selected_id = offers[selected] if selected >= 0 else ""


func _render_floor_strip() -> void:
	for c in floor_strip.get_children():
		c.queue_free()
	if mode == "daily":
		var b := Button.new()
		b.text = "DAILY · %s" % Ticker.daily_key()
		b.theme_type_variation = "Active"
		floor_strip.add_child(b)
		var x := Button.new()
		x.text = "« BUILDING"
		x.pressed.connect(leave_daily)
		floor_strip.add_child(x)
		return
	for f in Ticker.B["floors"]:
		var b := Button.new()
		var pay := Ticker.floor_pay(f)
		b.text = "F%d  ·  %d/shift" % [int(f["n"]), pay]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if f == view:
			b.theme_type_variation = "Active"
		elif not Idle._any(f["cells"]):
			b.modulate.a = 0.6
		var fd: Dictionary = f
		b.pressed.connect(func() -> void:
			view = fd
			refill_offers()
			mirei.unlock_line()
			hud())
		floor_strip.add_child(b)
	if Ticker.B["floors"].size() < Idle.MAX_FLOORS:
		var n: int = Ticker.B["floors"].size() + 1
		var b := Button.new()
		b.text = "+ FLOOR %d  ·  %d" % [n, Idle.floor_cost(n)]
		b.theme_type_variation = "Ghost"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: build_floor(n))
		floor_strip.add_child(b)


func _mark_gallery() -> void:
	var n: int = Ticker.cabinet["cg"].size()
	gallery_btn.text = "PLATES %d/%d" % [n, Ticker.PLATES.size()]
	_mark_tabs()


# ---- HUD refresh -------------------------------------------------------------------------

func hud() -> void:
	if not is_inside_tree():
		return
	var r := settle_now()
	rate_l.set_target(round(Ticker.rate_per_hour()))
	bank_l.set_target(float(int(Ticker.B["bank"])))
	gold_l.set_target(float(Economy.gold()))
	var chain: int = int(r["chain"])
	chain_l.text = str(chain)
	for i in range(pips.size()):
		var p: ColorRect = pips[i]
		var on := chain > i
		var want := Palette.HEAT if on else Palette.PANEL_EDGE
		if p.color != want:
			var tw := p.create_tween()
			tw.tween_property(p, "color", want, 0.18)
			if on:
				tw.parallel().tween_property(p, "scale", Vector2(1.3, 1.6), 0.1)
				tw.tween_property(p, "scale", Vector2(1, 1), 0.2)
	if chain > last_chain:
		Sfx.set_chain(min(5, chain))
		Sfx.combo()
	last_chain = chain
	var pay: int = int(r["shift"]) if mode == "daily" else int(round(float(r["shift"]) * float(Ticker.B["mult"])))
	preview_l.text = "SHIFT %d   ×%.2f" % [pay, float(r["mult"])]
	if mode == "daily":
		floor_view.caption = "DAILY FLOOR · 5 × 4"
		due_l.text = "—"
		cover_l.text = "%d / 12 pieces" % int(daily["at"])
		mode_l.text = "DAILY FLOOR · SAME PIECES FOR EVERYONE"
		reroll_btn.text = "REROLL · —"
		reroll_btn.disabled = true
	else:
		floor_view.caption = "FLOOR %d · 5 × 4" % int(view["n"]) + ("  ·  B%d ×%s" % [int(Ticker.B["building"]), str(Ticker.B["mult"])] if int(Ticker.B["building"]) > 1 else "")
		var need := Idle.daily_rent(view, Ticker.B["relics"])
		due_l.text = str(need)
		var per_day := pay * (Idle.DAY_MS / Idle.SHIFT_MS)
		if per_day >= need:
			cover_l.text = "COVERS ×%.1f" % (float(per_day) / float(need))
			cover_l.add_theme_color_override("font_color", Palette.SUCCESS)
		else:
			cover_l.text = "SHORT %d/d" % (need - per_day)
			cover_l.add_theme_color_override("font_color", Palette.HEAT)
		mode_l.text = "AFTER HOURS · IDLE · 18+   ·   BUILDING %d" % int(Ticker.B["building"])
		reroll_btn.text = "REROLL · %d" % Ticker.reroll_cost(view)
		reroll_btn.disabled = false
	var left: int = max(0, int(Ticker.B["nextShift"]) - Ticker.now())
	next_l.text = "%d:%02d" % [left / 60000, (left % 60000) / 1000]
	var relics: Array = Ticker.B["relics"] if mode != "daily" else []
	var names: Array = []
	for rid in relics:
		names.append(RELIC_NAME.get(rid, rid))
	relic_l.text = ", ".join(names) if not names.is_empty() else "No relics yet."
	_render_floor_strip()
	floor_view.set_cells(cells())
	floor_view.set_result(r)
	var mood := "calm" if (mode == "daily" and occupied() > 0) else ("empty" if mode == "daily" else Ticker.mood_for(view, pay))
	mirei.set_mood(mood)
	mirei.set_line(mood)


func _process(_d: float) -> void:
	if Ticker.started and not intro.is_open():
		var left: int = max(0, int(Ticker.B["nextShift"]) - Ticker.now())
		next_l.text = "%d:%02d" % [left / 60000, (left % 60000) / 1000]


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and Ticker.started:
		if Ticker.now() - int(Ticker.B["lastSeen"]) >= Idle.SHIFT_MS:
			Ticker.run_tick(true)


func banner(msg: String) -> void:
	banner_l.text = msg
	if _banner_tw and _banner_tw.is_valid():
		_banner_tw.kill()
	banner_l.modulate.a = 1.0
	banner_l.position.y = 86
	_banner_tw = create_tween()
	_banner_tw.tween_property(banner_l, "position:y", 80.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(1.3)
	_banner_tw.tween_property(banner_l, "modulate:a", 0.0, 0.35)


# ---- placement ----------------------------------------------------------------------------

func _on_cell(i: int) -> void:
	if cells()[i] != null:
		if mode == "daily":
			return
		var id := Ticker.take_back(view, i)
		if id != "":
			banner("%s is back in the roster." % NAMES.get(id, id))
			refill_offers()
			hud()
		return
	if selected < 0:
		banner("Pick a piece from the tray first.")
		return
	var id: String = offers[selected]
	if mode == "daily":
		var next := Landlord.place_at(cells(), id, i)
		if next.is_empty():
			return
		daily["cells"] = next
		daily["at"] = int(daily["at"]) + 1
		offers = draw_offers(3)
		selected = -1
	else:
		if not Ticker.place(view, i, id):
			banner("That desk is taken.")
			return
		var at := selected
		offers.remove_at(at)
		var pool := Ticker.available()
		for o in offers:
			var k := pool.find(o)
			if k >= 0:
				pool.remove_at(k)
		if not pool.is_empty():
			offers.insert(min(at, offers.size()), pool[randi() % pool.size()])
		selected = -1
	Sfx.place()
	floor_view.set_cells(cells(), i)
	var r := settle_now()
	mirei.unlock_line()
	for e in ["coffee-dan", "priya-copy", "nia-audit", "sol-late"]:
		if r["events"].has(e):
			mirei.set_line("chain", true)
			break
	_render_offers()
	hud()


func do_reroll() -> void:
	if mode == "daily":
		return
	if not Ticker.reroll(view):
		banner("Not enough rent.")
		return
	Sfx.reroll()
	refill_offers()
	hud()


func do_commit() -> void:
	if occupied() == 0:
		banner("Nothing to settle.")
		return
	var r := settle_now()
	floor_view.set_result(r)
	floor_view.burst(int(r["shift"]))
	Sfx.settle(int(r["chain"]))
	if int(r["chain"]) > 0:
		Sfx.combo()
	if mode == "daily":
		var res := Ticker.finish_daily(r)
		daily_result.show_result(res)
		return
	Ticker.commit(view)
	banner("Committed. The shifts take it from here.")
	mirei.set_line("chain" if int(r["chain"]) >= 4 else "calm", true)
	hud()


func build_floor(n: int) -> void:
	if n > Ticker.FREE_FLOORS and Gate.is_web() and not Gate.has("floor%d" % n):
		var ok := await Gate.require("floor%d" % n, "Floor %d" % n, "level")
		if not ok:
			return
	var res := Ticker.build_floor()
	if not res["ok"]:
		banner(("Not enough rent (%d short)." % int(res.get("need", 0))) if res["why"] == "bank" else "—")
		return
	view = Ticker.B["floors"][Ticker.B["floors"].size() - 1]
	refill_offers()
	Sfx.shop()
	hud()


# ---- daily floor -------------------------------------------------------------------------

func start_daily() -> void:
	mode = "daily"
	daily = {"seq": Ticker.daily_seq(), "at": 0, "cells": Idle.empty_cells(), "n": 0}
	view = daily
	offers = draw_offers(3)
	selected = -1
	mirei.unlock_line()
	hud()


func leave_daily() -> void:
	mode = "building"
	view = Ticker.B["floors"][0]
	daily = {}
	refill_offers()
	hud()


# ---- the web dev bridge ------------------------------------------------------------------

func _bridge(cmd: Dictionary) -> Dictionary:
	match str(cmd.get("op", "")):
		"state":
			pass
		"start":
			if intro.is_open():
				intro.start.emit()
				intro.close()
		"select":
			var k := offers.find(str(cmd.get("id", "")))
			if k < 0:
				return {"ok": false, "why": "not_offered", "offers": offers}
			selected = k
			_render_offers()
		"cell":
			_on_cell(int(cmd.get("i", 0)))
		"place":
			# a direct placement, for building a known board: the same Ticker.place the tray uses
			if mode == "daily":
				var next := Landlord.place_at(cells(), str(cmd["id"]), int(cmd["i"]))
				if next.is_empty():
					return {"ok": false, "why": "taken"}
				daily["cells"] = next
			elif not Ticker.place(view, int(cmd["i"]), str(cmd["id"])):
				return {"ok": false, "why": "taken"}
			floor_view.set_cells(cells(), int(cmd["i"]))
			refill_offers()
			hud()
		"commit":
			do_commit()
		"reroll":
			do_reroll()
		"open":
			match str(cmd.get("screen", "")):
				"roster": roster.open()
				"shop": shop.open()
				"gallery": gallery.open()
				"daily": daily_screen.open()
				"prestige": prestige.open()
		"close":
			for o in [return_screen, roster, shop, gallery, plate_view, daily_screen, daily_result, prestige, notice]:
				if o.is_open():
					o.close()
		"collect":
			if return_screen.is_open():
				return_screen.collect_btn.pressed.emit()
		"pull":
			roster._pull(int(cmd.get("n", 1)))
			var rarities: Array = []
			for r in roster._results:
				rarities.append(str(r["rarity"]))
			return {"ok": true, "offers": offers, "mode": mode, "open": _open_names(), "pulled": rarities}
		"daily_start":
			if daily_screen.is_open():
				daily_screen.close()
			start_daily()
		"daily_back":
			if daily_result.is_open():
				daily_result.back.emit()
				daily_result.close()
		"notice_ok":
			if notice.is_open():
				notice.understood.emit()
				notice.close()
		"floor":
			build_floor(int(cmd.get("n", 2)))
		"view":
			var n := int(cmd.get("n", 1))
			for f in Ticker.B["floors"]:
				if int(f["n"]) == n:
					view = f
			refill_offers()
			hud()
		_:
			return {"ok": false, "why": "unknown_op"}
	return {"ok": true, "offers": offers, "mode": mode, "open": _open_names(), "reveal_done": roster.reveal.visible and roster.reveal_done.visible}


func _open_names() -> Array:
	var out: Array = []
	for pair in [["return", return_screen], ["roster", roster], ["shop", shop], ["gallery", gallery], ["plate", plate_view], ["daily", daily_screen], ["daily_result", daily_result], ["prestige", prestige], ["notice", notice], ["intro", intro]]:
		if (pair[1] as Overlay).is_open():
			out.append(pair[0])
	return out
