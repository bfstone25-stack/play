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

## Piece and relic labels, as I18n keys (scripts/i18n.gd). A piece on the floor is named
## in the player's language; the ids under them never move.
const NAMES := {"coffee": "n_coffee", "dan": "n_dan", "priya": "n_priya", "wes": "n_wes", "mute": "n_mute", "printer": "n_printer", "mara": "n_mara", "corner": "n_corner", "nia": "n_nia", "sol": "n_sol"}
const RELIC_NAME := {"severance": "rl_severance", "quiet": "rl_quiet", "pto": "rl_pto", "glass": "rl_glass", "badge": "rl_badge", "army": "rl_army"}

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
## The Gold readout's whole box, not just its number: the tappable target that opens the
## shop (see _wire_shortcuts). _stat() hands it back through _last_stat_box.
var gold_box: Control
var _last_stat_box: Control
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
	Ticker.shielded.connect(func() -> void: banner(I18n.t("shield_used")))
	Ticker.shift_paid.connect(func(rep: Dictionary) -> void:
		floor_view.burst(int(rep["rent"]))
		Sfx.settle(min(5, int(rep["shifts"]))))
	Ticker.prestige_ready.connect(func() -> void: prestige.open())
	Ticker.plate_earned.connect(func(_slot: String) -> void:
		Sfx.win()
		_mark_gallery())
	Ticker.banner.connect(banner)
	Ticker.bridge_handler = _bridge
	_wire_barks()
	_wire_shortcuts()
	refill_offers()
	_mark_gallery()
	hud()
	intro.open()
	_qa_shots()


## QA only — nothing in the game calls this, and it does nothing without the flag.
##
##     DISPLAY=:0 godot --path . -- --title-shots
##
## Writes shots/title.png and shots/after-title.png and quits. It exists because the
## title screen rebuild left two claims and only one way to check them. `capture_title.sh`
## proves the title DRAWS, because the title is open when the main scene loads. Nothing
## proved it still CLOSES into the game — and since the screen is an Overlay subclass that
## this file and the JS dev bridge both reach through `start` / `close()` / `is_open()`, a
## presentation rewrite that quietly broke one of those would look perfect in every
## screenshot ever taken of it.
##
## `tests/headless_web.py` does cover it, through the bridge's `start` op, but it drives a
## browser: it resolves the build from the repo layout and stands up its own server, so
## `ops/remote_playtest.sh` cannot run it (that script rsyncs only `web/` to the GPU box),
## and running it here means headless Chromium on Blaze's desktop. This is the
## thirty-second version, in the engine, with the real signal. It does not replace it.
##
## A real display is required. `--headless` renders nothing, and a headless "capture" is a
## blank picture that passes for a screenshot.
func _qa_shots() -> void:
	if not OS.get_cmdline_user_args().has("--title-shots"):
		return
	# past the entrance: the mark settles at 0.35 + 1.2 s, the action at 1.25 + 0.7
	await get_tree().create_timer(2.8).timeout
	if not intro.is_open():
		push_error("title-shots: the title is not open on load; it should be")
		get_tree().quit(2)
		return
	await _qa_shoot("title")
	# the thing no screenshot has ever checked: that it goes away, and that the game is
	# underneath it. `start` is the signal this file and the bridge both use.
	intro.start.emit()
	intro.close()
	await get_tree().create_timer(1.4).timeout
	if intro.is_open():
		push_error("title-shots: close() did not close the title")
		get_tree().quit(2)
		return
	await _qa_shoot("after-title")
	print("title-shots: ok — the title drew, and closed into the building")
	get_tree().quit(0)


func _qa_shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	var path := "res://shots/%s.png" % name
	img.save_png(path)
	print("  %s  %dx%d" % [ProjectSettings.globalize_path(path), img.get_width(), img.get_height()])


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
	_last_stat_box = v
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
	t.text = I18n.t("hud_name")
	t.add_theme_font_override("font", Look.font_display)
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", Palette.ACCENT_SOFT)
	tv.add_child(t)
	mode_l = Label.new()
	mode_l.text = I18n.t("hud_sub")
	mode_l.theme_type_variation = "Tag"
	tv.add_child(mode_l)
	rate_l = _stat(h, I18n.t("rent_hour"), true, Palette.HEAT)
	bank_l = _stat(h, I18n.t("bank"), true, Palette.TEXT)
	gold_l = _stat(h, I18n.t("gold"), true, Palette.GOLD, true)
	gold_box = _last_stat_box
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 3)
	h.add_child(cv)
	var cl := HBoxContainer.new()
	cv.add_child(cl)
	var ct := Label.new()
	ct.text = I18n.t("chain")
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
	nt.text = I18n.t("next_shift")
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
	for pair in [["roster", "roster_btn"], ["shop", "shop_btn"], ["daily", "daily_btn"], ["gallery", "plates_btn"]]:
		var b := StudioTheme.stub(I18n.t(pair[1]) if pair[0] != "gallery" else I18n.f("plates_btn", [0, Ticker.PLATES.size()]), "", true)
		b.custom_minimum_size = Vector2(104, 42)
		b.add_theme_font_size_override("font_size", 13)
		var key: String = pair[0]
		b.pressed.connect(func() -> void: _open_tab(key))
		h.add_child(b)
		tabs[key] = b
	gallery_btn = tabs["gallery"]
	sound_btn = StudioTheme.stub(I18n.t("sound_on"), "Ghost", true)
	sound_btn.custom_minimum_size = Vector2(104, 42)
	sound_btn.add_theme_font_size_override("font_size", 13)
	sound_btn.pressed.connect(func() -> void:
		var on: bool = not bool(Ticker.cabinet.get("sound", true))
		Ticker.cabinet["sound"] = on
		Ticker.save_cabinet()
		Sfx.set_muted(not on)
		sound_btn.text = I18n.t("sound_on") if on else I18n.t("sound_off"))
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
	t.text = I18n.t("floors")
	t.theme_type_variation = "Tag"
	v.add_child(t)
	floor_strip = VBoxContainer.new()
	floor_strip.add_theme_constant_override("separation", 4)
	v.add_child(floor_strip)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var rt := Label.new()
	rt.text = I18n.t("relics")
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
	a.text = I18n.t("rent_due")
	a.theme_type_variation = "Tag"
	g.add_child(a)
	due_l = Label.new()
	due_l.theme_type_variation = "Value"
	due_l.add_theme_color_override("font_color", Palette.HEAT)
	due_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	due_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g.add_child(due_l)
	var b := Label.new()
	b.text = I18n.t("board_day")
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
	t.text = I18n.t("offers")
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
	reroll_btn = StudioTheme.stub(I18n.f("reroll", 4), "Amber", true)
	reroll_btn.custom_minimum_size = Vector2(120, 92)
	reroll_btn.pressed.connect(do_reroll)
	row.add_child(reroll_btn)
	commit_btn = StudioTheme.stub(I18n.t("commit"), "Primary", true)
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
			banner(I18n.t("b_no_gold"))
			return
		return_screen.cap_btn.visible = false
		banner(I18n.t("b_cap_24"))
		hud())
	roster = RosterScene.instantiate()
	roster.pulled.connect(func(_res: Array) -> void:
		refill_offers()
		hud())
	roster.need_gold.connect(func() -> void: banner(I18n.t("b_no_gold")))
	shop = ShopScene.instantiate()
	shop.bought.connect(func(_sku: String) -> void:
		refill_offers()
		hud())
	shop.need.connect(func(what: String) -> void: banner(I18n.t("b_no_rent") if what == "rent" else (I18n.t("b_no_gold") if what == "gold" else what)))
	shop.timeskip_report.connect(func(rep: Dictionary) -> void: return_screen.show_report(rep))
	gallery = GalleryScene.instantiate()
	plate_view = PlateView.new()
	gallery.view_plate.connect(func(id: String, cap: String, gated: bool, slot: String) -> void: plate_view.show_plate(id, cap, gated, slot))
	gallery.need_gold.connect(func() -> void: banner(I18n.t("b_no_gold")))
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
	# A reward earned behind a panel arrives when the panel goes, not an hour later.
	for o in [return_screen, roster, shop, gallery, plate_view, daily_result, prestige, notice]:
		(o as Overlay).closed.connect(_drain_pending)


func _tab_overlay(key: String) -> Overlay:
	match key:
		"roster": return roster
		"shop": return shop
		"daily": return daily_screen
		_: return gallery


func _open_tab(key: String) -> void:
	_tab_overlay(key).open()
	_mark_tabs()


# ---- the OTHER ways into the four panels -------------------------------------------------
#
# Until this pass, ROSTER / SHOP / DAILY / PLATES could each be reached by exactly one
# 104x42 stub in the top-right corner of the bar, and nothing else in the game opened them.
# Two reasons that is wrong, and only the second one is about a tool:
#
#   * This is the Nutaku bet: free browser AND Android. A row of small targets along the
#     top edge is the worst place on a phone -- it is the far end of the thumb's reach in
#     portrait and behind the notch in landscape. Every F2P convention this game is built
#     on says the opposite: you tap the currency to open the store, and you tap the
#     character to open the roster. Those targets are large, they are already on screen,
#     and they say what they open by being what they open.
#   * ops/play_driver.py reached the floor, placed a piece and committed a shift, and its
#     matrix was three tiles, because nothing it presses is within 250px of y=47. A game
#     whose panels can only be opened from one corner is a game that photographs as a room
#     with a board in it -- which is also what a player who never finds them sees.
#
# So: the landlord opens her roster, the Gold counter opens the shop, the plate counter
# opens the gallery, 1-4 open the four in order, and Esc closes the top one. The stubs
# stay; they are now the label rather than the only door.
func _wire_shortcuts() -> void:
	mirei.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_open_tab("roster"))
	mirei.mouse_filter = Control.MOUSE_FILTER_STOP
	mirei.tooltip_text = I18n.t("roster_btn")
	if gold_box != null:
		gold_box.mouse_filter = Control.MOUSE_FILTER_STOP
		gold_box.tooltip_text = I18n.t("shop_btn")
		gold_box.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_open_tab("shop"))


const DIGIT_TABS := {KEY_1: "roster", KEY_2: "shop", KEY_3: "daily", KEY_4: "gallery",
		KEY_KP_1: "roster", KEY_KP_2: "shop", KEY_KP_3: "daily", KEY_KP_4: "gallery"}


func _unhandled_key_input(event: InputEvent) -> void:
	if intro.is_open() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).keycode
	if k == KEY_ESCAPE:
		# Top-most first: a plate opened over the gallery closes back to the gallery, not
		# to the room.
		for pair in [["plate", plate_view], ["roster", roster], ["shop", shop],
				["gallery", gallery], ["daily", daily_screen]]:
			if pair[1].is_open():
				pair[1].close()
				_mark_tabs()
				return
		return
	if DIGIT_TABS.has(k) and _open_names().is_empty():
		_open_tab(str(DIGIT_TABS[k]))


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
		l.text = I18n.t("out_of_pieces") if mode == "daily" else I18n.t("roster_empty")
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
			_poke()
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
		nm.text = I18n.t(str(NAMES.get(id, id)))
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


## One size for every stub in the FLOORS column: as wide as the column allows and no
## wider, 40 high. `compact` removed the 220x56 floor these were overflowing with, and a
## compact ShapedButton takes its size from its text -- which would make the strip ragged,
## since "F1 · 0/shift" and "+ FLOOR 2 · 66" are different lengths.
func _strip_size(b: ShapedButton) -> ShapedButton:
	b.custom_minimum_size = Vector2(0, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 13)
	return b


func _render_floor_strip() -> void:
	for c in floor_strip.get_children():
		c.queue_free()
	if mode == "daily":
		floor_strip.add_child(_strip_size(StudioTheme.stub(I18n.f("daily_strip", Ticker.daily_key()), "Active", true)))
		var x := _strip_size(StudioTheme.stub(I18n.t("back_building"), "Ghost", true))
		x.pressed.connect(leave_daily)
		floor_strip.add_child(x)
		return
	for f in Ticker.B["floors"]:
		var pay := Ticker.floor_pay(f)
		# The floor the player is standing on is the HEAT stub; the rest are plain paper.
		var b := _strip_size(StudioTheme.stub(I18n.f("floor_btn", [int(f["n"]), pay]),
				"Active" if f == view else "", true))
		if f != view and not Idle._any(f["cells"]):
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
		var b := _strip_size(StudioTheme.stub(I18n.f("add_floor", [n, Idle.floor_cost(n)]), "Amber", true))
		b.pressed.connect(func() -> void: build_floor(n))
		floor_strip.add_child(b)


func _mark_gallery() -> void:
	var n: int = Ticker.cabinet["cg"].size()
	gallery_btn.text = I18n.f("plates_btn", [n, Ticker.PLATES.size()])
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
	preview_l.text = I18n.f("shift_mult", [pay, float(r["mult"])])
	if mode == "daily":
		floor_view.caption = I18n.t("daily_caption")
		due_l.text = "—"
		cover_l.text = I18n.f("daily_pieces", int(daily["at"]))
		mode_l.text = I18n.t("daily_same")
		reroll_btn.text = I18n.t("reroll_none")
		reroll_btn.disabled = true
	else:
		floor_view.caption = I18n.f("floor_hdr", int(view["n"])) + (I18n.f("floor_caption_b", [int(Ticker.B["building"]), str(Ticker.B["mult"])]) if int(Ticker.B["building"]) > 1 else "")
		var need := Idle.daily_rent(view, Ticker.B["relics"])
		due_l.text = str(need)
		var per_day := pay * (Idle.DAY_MS / Idle.SHIFT_MS)
		if per_day >= need:
			cover_l.text = I18n.f("covers", float(per_day) / float(need))
			cover_l.add_theme_color_override("font_color", Palette.SUCCESS)
		else:
			cover_l.text = I18n.f("short_day", need - per_day)
			cover_l.add_theme_color_override("font_color", Palette.HEAT)
		mode_l.text = I18n.f("hud_sub_n", int(Ticker.B["building"]))
		reroll_btn.text = I18n.f("reroll", Ticker.reroll_cost(view))
		reroll_btn.disabled = false
	var left: int = max(0, int(Ticker.B["nextShift"]) - Ticker.now())
	next_l.text = "%d:%02d" % [left / 60000, (left % 60000) / 1000]
	var relics: Array = Ticker.B["relics"] if mode != "daily" else []
	var names: Array = []
	for rid in relics:
		names.append(I18n.t(str(RELIC_NAME.get(rid, rid))))
	relic_l.text = ", ".join(names) if not names.is_empty() else I18n.t("no_relics")
	_render_floor_strip()
	floor_view.set_cells(cells())
	floor_view.set_result(r)
	var mood := "calm" if (mode == "daily" and occupied() > 0) else ("empty" if mode == "daily" else Ticker.mood_for(view, pay))
	mirei.set_mood(mood)
	mirei.set_line(mood)


func _process(_d: float) -> void:
	_bark_idle(_d)
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
			banner(I18n.f("b_back_roster", I18n.t(str(NAMES.get(id, id)))))
			refill_offers()
			hud()
		return
	if selected < 0:
		banner(I18n.t("b_pick_first"))
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
			banner(I18n.t("b_desk_taken"))
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
	_poke()
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
		banner(I18n.t("b_no_rent"))
		return
	Sfx.reroll()
	refill_offers()
	hud()


func do_commit() -> void:
	if occupied() == 0:
		banner(I18n.t("b_nothing"))
		return
	var r := settle_now()
	floor_view.set_result(r)
	floor_view.burst(int(r["shift"]))
	Sfx.settle(int(r["chain"]))
	if int(r["chain"]) > 0:
		Sfx.combo()
	_poke()
	_bark_commit(int(r["chain"]))
	if mode == "daily":
		var res := Ticker.finish_daily(r)
		daily_result.show_result(res)
		return
	Ticker.commit(view)
	banner(I18n.t("b_committed"))
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
	_poke()
	Sfx.bark("stage")
	hud()


# ---- daily floor -------------------------------------------------------------------------

func start_daily() -> void:
	mode = "daily"
	daily = {"seq": Ticker.daily_seq(), "at": 0, "cells": Idle.empty_cells(), "n": 0}
	view = daily
	offers = draw_offers(3)
	selected = -1
	mirei.unlock_line()
	_poke()
	Sfx.bark("stage")
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


# ---- barks, and the moment the loop pays out ---------------------------------------------
#
# Two things at once, because they are the same gap.
#
# 1. `ops/bark_wire.py` put the bark LAYER into `scripts/sfx.gd` (Sfx.bark) and stopped
#    there, deliberately: which moment fires which slot is per-game. Nothing in this file
#    called it, so 43 rendered voice files shipped in the build and never made a sound.
#    Everything below `_wire_barks()` is that choice, made.
#
# 2. `Ticker.tier_up` was emitted and nobody was listening. Affection tier-up IS this
#    game's payoff -- it is the moment a staff plate becomes available -- and all it did
#    was push a one-line banner and file the picture in a gallery the player has to go
#    find. 81 of Nutaku's top 100 use the scene as the REWARD OF THE LOOP rather than as
#    the content, and a reward the player has to go looking for is not a reward, it is an
#    archive. So the tier-up now opens the plate, in front of them, at the moment it is
#    earned.
#
## Which overlays a pushed reward must not land on top of. The title screen is the sharp
## case: `intro.start` runs `Ticker.run_tick(true)` immediately, an offline tick can cross
## an affection threshold, and without this guard the first thing a returning player sees
## is a CG over the title they have not finished pressing. A reward that interrupts is a
## popup, which the no-popup rule bans; deferred, it is a reward.
const NO_PUSH := ["intro", "prestige", "notice", "daily_result", "plate"]

var _pending_tier: Array = []          ## [id, tier] earned while something else was open
var _idle_since := 0.0                 ## seconds since the player last did anything
var _streak := 0                       ## consecutive commits that chained


func _wire_barks() -> void:
	# greet: the building opens. Not on _ready -- on the press, so it lands with the room
	# rather than under the title's own entrance animation.
	intro.start.connect(func() -> void:
		await get_tree().create_timer(0.5).timeout
		Sfx.bark("greet")
		_poke())
	# stage: a new floor bought, and the daily floor opened. Both are "the game moved on".
	Ticker.tier_up.connect(_on_tier_up)
	Ticker.plate_earned.connect(func(_slot: String) -> void: Sfx.bark("unlock"))
	Ticker.evicted.connect(func(_rep: Dictionary) -> void: Sfx.bark("fail"))


## The commit result decides win / win_big / near, and it is the one place the three are
## distinguishable. `chain` is the board's chain count: 4+ is the good board, 3 is the
## board that nearly was, which is exactly what a near-miss line is for.
func _bark_commit(chain: int) -> void:
	if chain >= 6:
		Sfx.bark("win_big")
		_streak += 1
	elif chain >= 4:
		_streak += 1
		# A streak line beats a win line when there is a streak to name; below three in a
		# row there is nothing to name and it would just be a third win line.
		if _streak >= 3:
			Sfx.bark("streak")
		else:
			Sfx.bark("win")
	elif chain == 3:
		_streak = 0
		Sfx.bark("near")
	else:
		_streak = 0


## Any interaction at all. Resets the idle timer, so the idle line is a line for a player
## who has stopped, not a line on a timer that fires over the top of them playing.
func _poke() -> void:
	_idle_since = 0.0


func _bark_idle(delta: float) -> void:
	if intro.is_open() or not _open_names().is_empty():
		return
	_idle_since += delta
	if _idle_since >= 42.0:
		_idle_since = 0.0
		Sfx.bark("idle")


## The payoff. Opens the plate the tier just bought, or holds it until whatever is in front
## of the player closes.
func _on_tier_up(id: String, tier: int) -> void:
	var blocked := false
	for n in _open_names():
		if n in NO_PUSH:
			blocked = true
			break
	if blocked:
		_pending_tier = [id, tier]
		return
	_pending_tier = []
	var slot := Ticker.aff_plate(id, tier)
	if slot == "plate_unearned":
		return
	# nameKey, not name: `name` is the English of record in the roster table, and using it
	# here put an English name on the one screen this game exists to show, in every language.
	var who: String = I18n.t(str(Roster.by(id).get("nameKey", id)))
	Sfx.bark("unlock")
	Sfx.win()
	mirei.set_line("chain", true)
	# `gated` follows the gallery's own rule: the uncensored cut is a web gate, tier 1 is
	# the censored cut and is never gated. aff_plate() already returns the "_locked" name
	# for tier 1, so the gate slot is only meaningful from tier 2 up.
	var gated := tier >= 2
	await get_tree().create_timer(0.35).timeout
	plate_view.show_plate(slot, I18n.f("aff_caption", [who, tier]), gated, "cg_%s_%d" % [id, tier])
	_mark_gallery()


## Drain a reward that was earned while a panel was in the way. Called when any overlay
## closes, so the plate arrives the moment the screen is free rather than on the next
## tier-up (which for a late-game staffer can be an hour away, i.e. never).
func _drain_pending() -> void:
	if _pending_tier.is_empty():
		return
	var p := _pending_tier
	_pending_tier = []
	await get_tree().create_timer(0.25).timeout
	_on_tier_up(str(p[0]), int(p[1]))
