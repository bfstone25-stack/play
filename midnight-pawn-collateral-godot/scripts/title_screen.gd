extends Control
class_name TitleScreen

## The title screen as a composition — ops/adult_forks/TITLE_SCREENS.md.
##
## What was here before was the thing Blaze named: a flat ColorRect with a column of
## Labels on it. This is the same information, designed.
##
## The constraint that shapes every line below is that this game is pixel art on a fixed
## palette (ops/palettes/midnight-pawn.json) and the title has to stay pixel-true. That
## rules out the tricks the other three forks use. No sub-pixel drift, no fractional
## scale, no gaussian anything: a 1.004 swell on a 640x360 canvas resamples the grid and
## the whole screen stops being pixel art. So every layer here moves in WHOLE PIXELS, and
## every texture is drawn NEAREST at 1:1.
##
## Layers, back to front:
##
##   keyvisual   the shop at the counter — Nara, the lamps, the pledged object — rendered
##               at 1920x1080 through the generator's keyvisual slot and converted down by
##               ops/pixelize.py onto the game's own 64-colour palette. 640x360, 1:1.
##   (the light) the plate's own two pendant lamps breathing, as a warm modulate on the
##               plate — value only, never scale, or the grid resamples.
##   motes       dust in the lamplight: single opaque pixels on whole-pixel paths.
##   scrim       ink at the head and the foot so the mark and the copy are readable over a
##               lit counter; banded, and absent across the middle where the picture is.
##   vignette    a violet-black corner fall, banded in eight steps so it reads as drawn
##               rather than as a smooth ramp over the grid.
##   logotype    the brass mark (ops/title_logotypes.py), already quantised to this same
##               palette, sliding up two pixels at a time and settling.
##   marks       18+ and the studio line in the game's own bitmap font.

const KV_PATH := "res://assets/title/keyvisual.png"
const LOGO_PATH := "res://assets/title/logotype.png"

const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const MUTED := Color("#c3b8d2")   # was #9f94ac: too dim to carry the gate copy on a phone
const INK := Color("#08050b")

## The scrim and the vignette are BANDS OF PLAIN ColorRect, not shaders.
##
## They were shaders, and on the web build they drew nothing at all while a plain
## ColorRect dropped in beside them at the same point in the child order drew fine —
## proven by putting a red test rect there and exporting. Rather than keep guessing at
## the GL-compatibility path, they are now the thing that is known to paint on every
## renderer. It costs nothing here: this screen wanted a BANDED falloff anyway, because a
## smooth ramp over a 640x360 pixel lattice is the one thing a pixel title must not have.
## Six steps of ink at the head, six at the foot, four in the corners. A hand-drawn pixel
## vignette is exactly this — a few flat steps — so the honest implementation and the
## robust one are the same implementation.
## The head scrim used to fall to 0.09 by the sixth band, which is where COLLATERAL sits —
## straight over the pale crown of her hat, and the subtitle disappeared into it the same
## way the gate copy disappeared into the lamp. It now holds most of its ink the whole way
## down the mark and feathers out in a seventh band below it, before the picture opens up.
const SCRIM_TOP := [0.90, 0.84, 0.76, 0.66, 0.54, 0.40]
const SCRIM_TAIL := [0.28, 0.17, 0.08]
const SCRIM_FOOT := [0.10, 0.24, 0.42, 0.60, 0.78, 0.92]
const INK_SCRIM := Color(0.030, 0.020, 0.042)

var bg: TextureRect
var logo: TextureRect
var motes: Array[Dictionary] = []
var mote_layer: Control
var t := 0.0
var _logo_y := 0
var _logo_target := 10


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# The title screen runs while the tree is PAUSED. Gate.require() pauses the tree
	# (scripts/gate.gd) and the web build reaches the gate before the title is dismissed —
	# gate.gd's own comment already records that floor-13-x sits paused behind its title
	# card. A node on PROCESS_MODE_INHERIT gets no _process at all while paused, which is
	# exactly what shipped: the live web title was frozen at frame one — no drift, no
	# light, and the mark stuck at the alpha 0 it starts its fade from. Measured, not
	# guessed: two canvas grabs 1.8 s apart differed by 0 pixels of 921600.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var ink := ColorRect.new()
	ink.color = INK
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	if ResourceLoader.exists(KV_PATH):
		bg.texture = load(KV_PATH)
	# 1:1 and NEAREST. The picture is already 640x360 — anything else resamples the grid.
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.position = Vector2.ZERO
	bg.size = Vector2(640, 360)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# The moving light is the picture's OWN two pendant lamps, brightened and warmed on a
	# slow breath in _process. It was an additive shader blob over them; the shader drew
	# nothing on the web build (see the scrim note above), and modulating the plate is in
	# any case the more honest version — the light that moves is the light in the room,
	# not a second light drawn over it. No material anywhere on this screen.

	mote_layer = Control.new()
	mote_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mote_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mote_layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1113
	for i in 46:
		motes.append({
			"x": rng.randf_range(0.0, 640.0),
			"y": rng.randf_range(0.0, 300.0),
			"vx": rng.randf_range(-5.0, 5.0),
			"vy": rng.randf_range(-11.0, -3.0),
			"a": rng.randf_range(0.20, 0.62),
		})

	# 2026-09-23, adult title pass: the three banded ink scrims are gone (0 of 33 Nutaku
	# tiles darken the picture under the type). The consent copy keeps its opaque plaque,
	# because a legal gate must be readable; an opaque in-world surface is what 7 of 28
	# titled Nutaku tiles use and it is not a see-through box.
	_edges()

	# The gate plaque and the footer rail. See _plaque().
	add_child(_plaque(10, 210, 452, 150, 14, 14, 0))   # the gate copy and its two buttons
	add_child(_plaque(0, 326, 640, 34, 0, 10, 0))      # the footer rail: 18+ and the studio

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.stretch_mode = TextureRect.STRETCH_KEEP
	logo.size = Vector2(480, 150)
	# 2026-09-23: left, not centred -- centred, LIEN sat across Nara's face. She owns the
	# right half now; the mark sits over the gate copy's column.
	logo.position = Vector2(-60, 10)
	# Present from frame one. It used to start at alpha 0 and be faded in by _process —
	# so on any frame where _process does not run (the tree is paused behind this card),
	# the mark was simply not there. The settle is motion ON TOP of a finished screen,
	# never the thing that makes the screen finished.
	logo.modulate.a = 1.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


## `heights` worth of ink in equal bands from `y` down, each at its own alpha.
func _bands(y: int, total: int, alphas: Array) -> void:
	var h := int(float(total) / float(alphas.size()))
	for i in alphas.size():
		var r := ColorRect.new()
		r.color = Color(INK_SCRIM.r, INK_SCRIM.g, INK_SCRIM.b, float(alphas[i]))
		r.position = Vector2(0, y + i * h)
		r.size = Vector2(640, h)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)


## The left and right edges, stepped inward. The first cut of this did the CORNERS —
## four stacked squares — and they read on screen as four squares, which is a bug, not a
## vignette. Full-height bands down each side do the same job (hold the eye in the
## middle) and look like a frame.
func _edges() -> void:
	for step in 5:
		var w := 26 - step * 4
		var a := 0.26 - step * 0.05
		for x in [step * 26, 640 - step * 26 - w]:
			var r := ColorRect.new()
			r.color = Color(0.030, 0.018, 0.048, a)
			r.position = Vector2(x, 0)
			r.size = Vector2(w, 360)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(r)


## A PLAQUE: the one thing on this screen that is allowed to be opaque.
##
## The four lines of the age gate and the two buttons were set straight onto the key
## visual, and the key visual is LIT — the lamp glow, her face, the shelf highlights. The
## foot scrim above is a six-step ramp that bottoms out at 0.92 only in the last band, so
## across the copy column it was carrying ~0.2-0.6 of ink over cream type on highlights,
## and whole words vanished ("a shop that prices both", and the first button label). A
## live capture is in ops/adult_forks/shots/titles/.
##
## The fix Elena's title used is a soft gradient scrim that holds full strength across the
## type column and falls off before the subject. A smooth gradient is the one thing this
## screen cannot have: it is a 640x360 pixel title on a fixed 64-colour palette, and a
## ramp over that lattice is banding-by-accident. So the falloff is DITHERED instead —
## one ink value, one alpha, an ordered 4x4 Bayer threshold deciding which pixels take
## it. That is what a pixel artist actually draws, it quantises onto the palette by
## construction (there is only ever one colour in it), and it lets the plaque die out
## into the art over ten to fourteen pixels instead of ending on a hard rectangle edge.
##
## The plaque is built as ONE Image and shown at 1:1 NEAREST, not as a mesh of ColorRects:
## a 4-pixel checker across 452 columns would be hundreds of nodes.
##
## `fade_r` is the falloff into the picture on the right (0 = the plaque runs to the frame
## edge, as the footer rail does), `fade_t` / `fade_b` the falloff at the top and bottom.
## Both of these plaques run to the bottom of the frame, so their `fade_b` is 0: a plaque
## that dithers out one pixel above the screen edge leaves a bright hairline of art under
## the type, which is the defect again in miniature.
func _plaque(x: int, y: int, w: int, h: int, fade_r: int, fade_t: int, fade_b: int) -> TextureRect:
	const BAYER := [
		[0, 8, 2, 10],
		[12, 4, 14, 6],
		[3, 11, 1, 9],
		[15, 7, 13, 5],
	]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var face := Color(0.043, 0.031, 0.063, 0.955)   # palette ink, near-solid
	for py in h:
		for px in w:
			# Coverage: 1.0 in the body, ramping to 0 across each fading edge.
			var c := 1.0
			if fade_r > 0:
				c = minf(c, clampf(float(w - 1 - px) / float(fade_r), 0.0, 1.0))
			if fade_t > 0:
				c = minf(c, clampf(float(py) / float(fade_t), 0.0, 1.0))
			if fade_b > 0:
				c = minf(c, clampf(float(h - 1 - py) / float(fade_b), 0.0, 1.0))
			if c >= 1.0 or (BAYER[py % 4][px % 4] + 0.5) / 16.0 < c:
				img.set_pixel(px, py, face)
	# A brass hairline top and bottom, inside the solid body: the plaque reads as a plate
	# screwed to the wall rather than as a hole cut in the picture.
	var rule := Color(0.545, 0.353, 0.125, 0.85)
	var solid_r := w - fade_r
	for px in range(0, maxi(solid_r, 1)):
		img.set_pixel(px, mini(fade_t, h - 1), rule)
	var tr := TextureRect.new()
	tr.name = "Plaque"
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.position = Vector2(x, y)
	tr.size = Vector2(w, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _draw() -> void:
	for m in motes:
		draw_rect(Rect2(Vector2(floorf(m["x"]), floorf(m["y"])), Vector2.ONE),
				  Color(0.95, 0.83, 0.58, m["a"]))


## Called when the title becomes visible: the room alone for half a second, then the mark
## settles up two pixels at a time. Whole pixels, so it never softens mid-tween.
func play_in() -> void:
	t = 0.0
	_logo_y = _logo_target + 14
	logo.position.y = _logo_y
	# The mark starts READABLE and the settle only finishes it. It used to start at
	# alpha 0 and be brought up by a Tween — and a Tween does not advance while the tree
	# is paused, which is exactly the state this card is shown in (Gate.require() pauses
	# the tree). Live, that meant the title screen had no title on it. Motion is allowed
	# to add to a finished screen; it is never allowed to be the thing that finishes it.
	logo.modulate.a = 0.85
	_snd("sting")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta

	# The lamps breathe, as a warm lift on the plate itself. Value only — no scale, or the
	# grid resamples.
	if bg:
		var k := 0.06 * sin(t * 0.85) + 0.016 * sin(t * 4.3)
		bg.modulate = Color(1.0 + k * 1.3, 1.0 + k, 1.0 + k * 0.4)

	# The key visual drifts, but only ever by an integer — the parallax a pixel game is
	# allowed to have.
	if bg:
		bg.position = Vector2(roundf(sin(t * 0.17) * 3.0), roundf(cos(t * 0.11) * 2.0))

	# Dust.
	for m in motes:
		m["x"] += m["vx"] * delta
		m["y"] += m["vy"] * delta
		if m["y"] < -2.0:
			m["y"] = 320.0
			m["x"] = randf_range(0.0, 640.0)
		if m["x"] < -2.0:
			m["x"] = 642.0
		elif m["x"] > 642.0:
			m["x"] = -2.0
	queue_redraw()

	# The mark settles in after a beat of the room alone.
	if t > 0.5:
		logo.modulate.a = minf(1.0, logo.modulate.a + delta * 0.9)
	else:
		logo.modulate.a = maxf(logo.modulate.a, 0.85)
		if _logo_y > _logo_target and fmod(t, 0.09) < delta:
			_logo_y -= 2
			logo.position.y = _logo_y


func _snd(kind: String) -> void:
	var game := get_parent()
	while game and not game.has_method("title_sound"):
		game = game.get_parent()
	if game:
		game.title_sound(kind)


# ---- the type family, lent to whatever places buttons over this composition -------------

func style_label(l: Label, size: int, color: Color, display := false) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	# A one-pixel ink shadow under every glyph. The plaque does the real work; this is
	# what keeps the type crisp where it sits on the plaque's dithered edge, and it is a
	# whole-pixel offset so it cannot soften the grid. (An outline is not an option: these
	# are bitmap fonts, and Godot grows outlines only on dynamic ones.)
	l.add_theme_color_override("font_shadow_color", Color(0.027, 0.018, 0.039, 0.95))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	if display:
		l.add_theme_font_override("font", load("res://assets/fonts/midnight_pixel_16.fnt"))
	else:
		l.add_theme_font_override("font", load("res://assets/fonts/midnight_pixel_12.fnt"))


## Brass plate buttons: a dark ink face, a gold rule under it that thickens on hover, the
## same bevel the logotype carries. Not a default Button anywhere on this screen.
func style_button(b: Button) -> void:
	b.add_theme_font_override("font", load("res://assets/fonts/midnight_pixel_12.fnt"))
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color("#fff3d2"))
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_focus_color", Color("#fff3d2"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.03, 0.06, 0.80)
	normal.border_color = Color("#8a5a20")
	normal.border_width_bottom = 2
	normal.set_content_margin_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var hover := normal.duplicate()
	hover.bg_color = Color(0.10, 0.07, 0.04, 0.88)
	hover.border_color = GOLD
	hover.border_width_bottom = 3
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.18, 0.12, 0.04, 0.92)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	if not b.mouse_entered.is_connected(_on_hover):
		b.mouse_entered.connect(_on_hover)
		b.button_down.connect(_on_press)


func _on_hover() -> void:
	_snd("hover")


func _on_press() -> void:
	_snd("press")
