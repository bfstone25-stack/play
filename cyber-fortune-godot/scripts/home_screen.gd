extends Control
const KV := "res://assets/title/keyvisual.webp"
## Home — "what do you want to ask with today?": the two instruments and the reader's
## curtain, each in its own light; the rack and the offerings below.

var root: VBoxContainer
var sky: TextureRect
var _t := 0.0

## Standard #6: the title moves, and NEVER shows the plate's edge. 1.22 is past the 1.16
## the 16:9 diagonal needs, and DRIFT is the remaining 3% of headroom, so the picture can
## wander for the whole cycle without an edge ever entering the frame.
const SKY_SCALE := 1.22
const DRIFT := 0.03


func _ready() -> void:
	relayout()


## A slow drift across the key visual: 47 seconds one way and 31 the other, two periods
## that do not divide into each other, so the picture never visibly returns to a pose. A
## rotation was the alternative and is wrong here -- the sky has a horizon in it, and a
## horizon that tilts reads as a bug.
func _process(dt: float) -> void:
	_t += dt
	if sky == null or not is_instance_valid(sky):
		return
	var w: float = size.x
	var h: float = size.y
	sky.size = Vector2(w, h) * SKY_SCALE
	sky.position = Vector2(
			-w * (SKY_SCALE - 1.0) * 0.5 + sin(_t * TAU / 47.0) * w * DRIFT,
			-h * (SKY_SCALE - 1.0) * 0.5 + sin(_t * TAU / 31.0) * h * DRIFT)


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	_build_sky()
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 36)
	m.add_theme_constant_override("margin_right", 36)
	# 118, not 96: the mark's ascenders were running into main.gd's merit counter.
	m.add_theme_constant_override("margin_top", 118)
	m.add_theme_constant_override("margin_bottom", 40)
	add_child(m)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)
	# 2026-09-23: the mark is now a 匾額 — the carved lacquer board with gold-leaf letters
	# that hangs over a temple door, made in ops/title_logotypes.py::cyber_fortune, with a
	# cash coin standing in for the O. CfMark drew the words in a display face with a gold
	# fill and an under-shadow, which is a font in a costume (ops/STANDARD.md), and the
	# neon-tube version that replaced it first could not survive on a lantern-lit plate:
	# neon only reads against a dark wall and this key visual is brightest exactly here.
	# A hanging board is an opaque in-world object, which is what 19 of the 64 shelf
	# covers that carry a plate actually use.
	var mark := TextureRect.new()
	mark.name = "Mark"
	if ResourceLoader.exists("res://assets/title/logotype.png"):
		mark.texture = load("res://assets/title/logotype.png")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mark.custom_minimum_size = Vector2(0, 186)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mark)
	# The question, now ink on a lit sky rather than SMOKE on ink. SMOKE (#C9BBA8) is a
	# pale warm grey chosen to sit on the black ground this screen no longer has; on the
	# key visual it is a light line on a light picture.
	# The question and the daily line get a paper ground of their own. They are dark ink and
	# the band they sit in is the busiest part of the key visual — gold lanterns against
	# blue — so on the picture alone neither could be read. A ground, not a scrim: this
	# brightens rather than darkens, which is the whole argument of UI_DIRECTION.md against
	# the way this studio has been laying black over its own art.
	root.add_child(_paper_band())
	var ask := StudioTheme.label(Tx.t("home.ask"), 20, Palette.PAPER_INK, "italic" if Tx.lang == "en" else "serif")
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(ask)
	var daily := StudioTheme.label(Tx.t("daily.free" if Fortune.free_available() else "daily.used"), 15, Palette.LACQUER if Fortune.free_available() else Palette.PAPER_INK, "bold")
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
	# The two nav buttons are the same 签 the three rows are, at a smaller size: one shape
	# for the whole title, which is the point of shared/godot/shaped_button.gd. They were
	# the studio's default rounded rectangle.
	var counts := Fortune.collection_counts()
	nav.add_child(_slip_button(
			"%s  %d/%d" % [Tx.t("home.collection"), counts["slips"] + counts["cards"],
					counts["slips_all"] + counts["cards_all"]],
			Palette.GOLD_DEEP, func(): get_parent().open("rack")))
	nav.add_child(_slip_button(Tx.t("home.shop"), Palette.LACQUER,
			func(): get_parent().open("shop")))


## The sky behind the home screen.
##
## This was Backdrop.new() with mode "home", which is draw_rect(Palette.INK) plus five
## concentric gold circles at 1.8% alpha — a code-drawn black rectangle standing in for a
## key visual (studio rule 2), and the reason the captured frame measured 0.14 brightness
## against a shelf floor of 0.45.
##
## It is now the rendered key visual, full bleed, with a warm foot under it so the three
## instrument rows and the nav have a ground. The dark lacquer rows on a bright sky is the
## approved pattern rather than a compromise: play/rebound-tycoon-godot and play/fold-godot
## are both bright screens with a dark board, and FOLD's palette.gd records why — a tray
## dark enough to make saturated pieces read as lit objects, set into a lit page.
##
## Backdrop is untouched and still draws the east / west / reader rooms; only "home"
## stopped being a rectangle.
func _build_sky() -> void:
	var kv := TextureRect.new()
	# Positioned by _process, not anchored: it is bigger than the screen on purpose (see
	# SKY_SCALE) and an anchored FULL_RECT would pin it back to the viewport every frame.
	kv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(KV):
		kv.texture = load(KV)
	else:
		# Never a silent black screen if the plate is missing. A flat warm paper ground is
		# wrong, and it is VISIBLY wrong, which is the point — the failure this whole pass
		# exists to fix shipped for a day because a dark screen looks like a decision.
		kv.modulate = Palette.PAPER
	add_child(kv)
	sky = kv
	_t = 0.0
	# A warm foot for the rows and the nav, generated into an Image and shown through a
	# TextureRect. NOT a shader: shaders draw nothing at all on the Godot web export — no
	# error, no warning, the element is simply absent.
	var n := 128
	var img := Image.create(2, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var t := float(y) / float(n - 1)
		var c := Color(Palette.PAPER, 0.0).lerp(Color(Palette.PAPER, 0.72), t * t)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	var foot := TextureRect.new()
	foot.texture = ImageTexture.create_from_image(img)
	foot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot.stretch_mode = TextureRect.STRETCH_SCALE
	foot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -560.0
	foot.offset_bottom = 0.0
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foot)


## A soft paper card the header type sits on. Generated into an Image, never a shader:
## shaders draw nothing at all on the Godot web export.
func _paper_band() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := 64
	var img := Image.create(2, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var t := float(y) / float(n - 1)
		# brightest in the middle, fading at both ends so it has no hard edge
		var a: float = sin(t * PI) * 0.80
		img.set_pixel(0, y, Color(Palette.PAPER, a))
		img.set_pixel(1, y, Color(Palette.PAPER, a))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = -40.0
	tr.offset_right = 40.0
	tr.offset_top = -14.0
	tr.offset_bottom = 78.0
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(tr)
	return c


func _slip_button(text: String, tint: Color, on_press: Callable) -> ShapedButton:
	var b := ShapedButton.new()
	b.shape = ShapedButton.Shape.SLIP
	b.tint = tint
	b.ink = Palette.PAPER
	b.label = text
	b.custom_minimum_size = Vector2(300, 64)
	b.add_theme_font_override("font", StudioTheme.font("bold"))
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(on_press)
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _door(kind: String, title: String, sub: String, screen: String) -> Control:
	var d := Door.new()
	d.kind = kind
	d.title = title
	d.sub = sub
	# 150, and NOT EXPAND_FILL. At 200-and-expand the three rows took ~600 px of a 1280 px
	# screen and, once there was a picture behind them instead of a black ground, they read
	# as three full-bleed bars slicing the key visual into stripes — the "picture beside a
	# form" objection in TITLE_SCREENS.md, turned on its side. The rows are the menu; the
	# picture is the screen.
	d.custom_minimum_size = Vector2(0, 150)
	d.pressed.connect(func(): get_parent().open(screen))
	return d


## One door: a panel in its own palette, a mark, the title and a line under it.
class Door extends Button:
	var kind := "east"
	var title := ""
	var sub := ""
	var _t := 0.0
	var _rise := 0.0
	var _rise_to := 0.0
	var _was_hover := false

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		theme_type_variation = "Ghost"
		add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	## How far the row's panel is inset from the node's own rect.
	##
	## The page's MarginContainer (36 px) does not reach these rows — measured off a
	## capture, the panel's left edge lands at x=32 but its right edge runs to the full
	## 720, and the row's own marks and type draw from the node's local origin at screen
	## x=0. Rather than keep guessing at the container, the row insets its own drawing,
	## which is true whatever the cause: everything below is positioned from INSET instead
	## of from zero.
	##
	## This matters because there is a rendered sky behind these rows now. On the old flat
	## ink ground a row that ran to the screen edge was invisible as an error; over a
	## picture it reads as a bar laid across it, which is the "picture beside a form"
	## objection in TITLE_SCREENS.md turned on its side.
	## 66, arrived at by measuring a capture rather than by reasoning about the container.
	## At INSET 30 the panel's left edge still landed at screen x=0, which puts the row
	## node's own origin about 36 px left of the viewport — so the page margin is being
	## applied somewhere and then given back, and the row is wider than the screen. 66
	## lands the panel edge at x=36, which is the page margin the rest of the screen uses.
	##
	## Recorded as a measured number and not as a fix: the underlying container is still
	## wrong and the next person to touch this layout should find it rather than tune this
	## constant again.
	const INSET := 66.0

	func _draw() -> void:
		var w: float = maxf(40.0, size.x - INSET * 2.0)
		var hover := is_hovered()
		if hover != _was_hover:
			_was_hover = hover
			_rise_to = 5.0 if hover else 0.0
		_rise = lerpf(_rise, _rise_to, 0.22)
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
		# THE ROW IS A 签 -- a fortune slip: a turned, lacquered head at the left end and a
		# torn tail at the right. It was a rounded rectangle with a picture in it, which is
		# studio rule 4 ("buttons are not rectangles") and, worse, is the same rounded
		# rectangle eighteen other titles use. The silhouette is
		# scripts/shaped_button.gd's SLIP, shared with the two buttons in the nav below, so
		# the row and the button are demonstrably the same object at two sizes rather than
		# two drawings that happen to look alike.
		#
		# Hover makes the slip RISE. That is not a highlight: rising out of the tube is the
		# one gesture this whole game is built on, and the row does in miniature what the
		# tube does when you shake it.
		var pts := ShapedButton.slip_points(Vector2(w, size.y), _rise)
		var body := PackedVector2Array()
		for pt in pts:
			body.append(pt + Vector2(INSET, 0))
		# Translucent, as before: there is a rendered sky behind this row, and at 0.88 the
		# lantern light shows through the lacquer the way it does on a lacquered surface in
		# daylight. The type is drawn on top of the panel, not through it, so it keeps full
		# contrast.
		# 2026-09-23: 0.88 -> 0.97. A lacquered slip is a lacquered object; at 0.88 the
		# lantern behind it showed through and the three rows read as translucent bars
		# laid over the character's face, which is the scrim pattern under another name.
		draw_colored_polygon(body, Color(bg, 0.97))
		var outline := body.duplicate()
		outline.append(body[0])
		draw_polyline(outline, edge, 2.0)
		# the turned head, and the instrument's own mark inside it
		var c := Vector2(INSET + size.y * 0.5, size.y * 0.5 - _rise)
		draw_circle(c, size.y * 0.42, Color(edge, 0.16))
		draw_arc(c, size.y * 0.42, 0.0, TAU, 48, Color(edge, 0.55), 1.5)
		var mark_scale: float = 0.62
		draw_set_transform(c, 0.0, Vector2(mark_scale, mark_scale))
		_draw_mark(Vector2.ZERO, accent)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var f := StudioTheme.font("serif")
		var fi := StudioTheme.font("italic" if Tx.lang == "en" else "serif")
		var tx: float = INSET + size.y * 1.02
		var avail: float = w - size.y * 1.02 - size.y * 0.45
		draw_string(f, Vector2(tx, size.y * 0.5 - 8 - _rise), title, HORIZONTAL_ALIGNMENT_LEFT, avail, 40, Palette.TEXT if kind != "reader" else Palette.CANDLE)
		draw_string(fi, Vector2(tx + 2, size.y * 0.5 + 30 - _rise), sub, HORIZONTAL_ALIGNMENT_LEFT, avail, 19, Palette.MUTED if kind != "west" else Palette.SILVER_DIM)

	## The instrument, drawn around a local origin so the head can scale it.
	func _draw_mark(c: Vector2, accent: Color) -> void:
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
