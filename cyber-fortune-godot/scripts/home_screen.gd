extends Control
## Home — "what do you want to ask with today?": the two instruments and the reader's
## curtain, each in its own light; the rack and the offerings below.

var root: VBoxContainer


func _ready() -> void:
	relayout()


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var bg := Backdrop.new()
	bg.mode = "home"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 36)
	m.add_theme_constant_override("margin_right", 36)
	m.add_theme_constant_override("margin_top", 96)
	m.add_theme_constant_override("margin_bottom", 40)
	add_child(m)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	m.add_child(root)
	var series := StudioTheme.label(Tx.t("series"), 13, Palette.MUTED, "bold")
	series.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(series)
	var title := StudioTheme.label(Tx.t("title"), 54, Palette.GOLD_PALE, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var ask := StudioTheme.label(Tx.t("home.ask"), 20, Palette.SMOKE, "italic" if Tx.lang == "en" else "serif")
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(ask)
	var daily := StudioTheme.label(Tx.t("daily.free" if Fortune.free_available() else "daily.used"), 15, Palette.SUCCESS if Fortune.free_available() else Palette.MUTED, "bold")
	daily.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(daily)
	root.add_child(_spacer(6))
	root.add_child(_door("east", Tx.t("home.east"), Tx.t("home.east.sub"), "tube"))
	root.add_child(_door("west", Tx.t("home.west"), Tx.t("home.west.sub"), "deck"))
	root.add_child(_door("reader", Tx.t("home.reader"), Tx.t("home.reader.sub"), "reader"))
	root.add_child(_spacer(4))
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	root.add_child(nav)
	var counts := Fortune.collection_counts()
	var rack := StudioTheme.button("%s  %d/%d" % [Tx.t("home.collection"), counts["slips"] + counts["cards"], counts["slips_all"] + counts["cards_all"]], "Gold")
	rack.pressed.connect(func(): get_parent().open("rack"))
	nav.add_child(rack)
	var shop := StudioTheme.button(Tx.t("home.shop"))
	shop.pressed.connect(func(): get_parent().open("shop"))
	nav.add_child(shop)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _door(kind: String, title: String, sub: String, screen: String) -> Control:
	var d := Door.new()
	d.kind = kind
	d.title = title
	d.sub = sub
	d.custom_minimum_size = Vector2(0, 200)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.pressed.connect(func(): get_parent().open(screen))
	return d


## One door: a panel in its own palette, a mark, the title and a line under it.
class Door extends Button:
	var kind := "east"
	var title := ""
	var sub := ""
	var _t := 0.0

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		theme_type_variation = "Ghost"
		add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var hover := is_hovered()
		var bg: Color
		var edge: Color
		var accent: Color
		match kind:
			"east":
				bg = Palette.INK_SOFT
				edge = Palette.GOLD_DEEP
				accent = Palette.LACQUER
			"west":
				bg = Palette.VIOLET
				edge = Palette.VIOLET_EDGE
				accent = Palette.SILVER
			_:
				bg = Color("1A1224")
				edge = Palette.CANDLE_DEEP
				accent = Palette.CANDLE
		if hover:
			edge = edge.lightened(0.25)
		var sb := StudioTheme.flat(bg, edge, 16, 1, Vector2.ZERO)
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 14
		draw_style_box(sb, r)
		# the mark on the left
		var c := Vector2(92, size.y * 0.5)
		match kind:
			"east":
				# the tube: a wooden cylinder with sticks
				draw_rect(Rect2(c + Vector2(-30, -22), Vector2(60, 74)), Palette.WOOD)
				draw_rect(Rect2(c + Vector2(-30, -22), Vector2(60, 74)), Palette.WOOD_LIGHT, false, 2.0)
				for i in range(7):
					var x := c.x - 22 + i * 7.5
					var h := 38.0 + 10.0 * sin(_t * 1.3 + i)
					draw_line(Vector2(x, c.y - 22), Vector2(x + 2, c.y - 22 - h), Palette.PAPER, 3.0)
					draw_line(Vector2(x + 2, c.y - 22 - h), Vector2(x + 2, c.y - 22 - h + 10), accent, 3.0)
			"west":
				# a fanned deck
				for i in range(3):
					draw_set_transform(c + Vector2(0, 10), -0.25 + i * 0.25, Vector2.ONE)
					draw_rect(Rect2(Vector2(-26, -40), Vector2(52, 80)), Palette.VIOLET_DEEP)
					draw_rect(Rect2(Vector2(-26, -40), Vector2(52, 80)), accent, false, 1.5)
					draw_rect(Rect2(Vector2(-18, -32), Vector2(36, 64)), Color(accent, 0.25), false, 1.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:
				# the curtain with a lamp behind it
				var glow := Color(Palette.CANDLE, 0.10 + 0.04 * sin(_t * 3.0))
				draw_circle(c, 46.0, glow)
				draw_circle(c, 30.0, Color(Palette.CANDLE, 0.16))
				draw_rect(Rect2(c + Vector2(-44, -60), Vector2(40, 120)), Color("3A2544"))
				draw_rect(Rect2(c + Vector2(4, -60), Vector2(40, 120)), Color("3A2544"))
				draw_line(c + Vector2(-44, -60), c + Vector2(44, -60), Palette.CANDLE_DEEP, 3.0)
				draw_circle(c + Vector2(0, 8), 6.0, Palette.CANDLE)
		var f := StudioTheme.font("serif")
		var fi := StudioTheme.font("italic" if Tx.lang == "en" else "serif")
		draw_string(f, Vector2(170, size.y * 0.5 - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Palette.TEXT if kind != "reader" else Palette.CANDLE)
		draw_string(fi, Vector2(172, size.y * 0.5 + 30), sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 190, 19, Palette.MUTED if kind != "west" else Palette.SILVER_DIM)
