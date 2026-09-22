extends Control
class_name TitleScreen

## The mainstream title screen as a composition — ops/adult_forks/TITLE_SCREENS.md.
##
## What stood here was `assets/pixel/scene_title.png` inside the ordinary game panel with
## the ordinary Labels beside it, which is the "looks like a document" Blaze named. This
## is a full-frame card over the whole 640x360 canvas, built on the same pattern the
## adult fork of this world already uses, so the two builds read as one studio.
##
## The constraint that shapes every line below is that this game is pixel art on a fixed
## palette (ops/palettes/midnight-pawn.json) and the title has to stay pixel-true. No
## sub-pixel drift, no fractional scale, no gaussian anything: a 1.004 swell on a 640x360
## canvas resamples the grid and the whole screen stops being pixel art. So every layer
## here moves in WHOLE PIXELS and every texture is drawn NEAREST at 1:1.
##
## Layers, back to front:
##
##   keyvisual   the shop at the counter — Nara, the lantern, the brass, the pledged
##               jewel in her hand — rendered at 1920x1080 through the render queue's
##               keyvisual slot and converted down by ops/pixelize.py onto the game's own
##               palette. 640x360, drawn 1:1 at a +40 px vertical offset so her face
##               clears the mark instead of sitting under it; the 40 px that opens at the
##               head of the frame is the dark ceiling the shop sign hangs in.
##   (the light) the plate's own lantern breathing, as a warm modulate on the plate —
##               value only, never scale, or the grid resamples.
##   motes       dust in the lamplight: single opaque pixels on whole-pixel paths.
##   scrim       ink at the head so the mark reads over the shelves; banded, and absent
##               across the middle where the picture is.
##   edges       a violet-black frame down each side, banded in five steps so it reads as
##               drawn rather than as a smooth ramp over the grid.
##   plaques     the menu gets a surface of its own (TITLE_SCREENS.md, "the playfield is
##               not the title screen"): a near-solid plate that dithers out into the
##               picture, never type floating on a lit counter. This game's own age gate
##               was once "swallowed by the lamp glow" — same defect, same fix.
##   logotype    the brass mark (ops/title_logotypes_mainstream.py), already rasterised at
##               1x and quantised to this same palette, sliding up two pixels at a time
##               and settling.
##
## There is no shader anywhere on this screen and there must not be one: on the web export
## the fork proved a shader drew NOTHING where a plain ColorRect dropped in beside it at
## the same point in the child order drew fine. Everything here is ColorRect and Image.

const KV_PATH := "res://assets/title/keyvisual.png"
const LOGO_PATH := "res://assets/title/logotype.png"

const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
## Was #9f94ac in the game's palette: too dim to carry the copy on a phone.
const MUTED := Color("#c3b8d2")
## The ground behind the picture — the shop's dark ceiling, not a void. #08050b is
## effectively black and the 40 px band above the key visual is a tenth of the frame.
const INK := Color("#3c2749")

## The key visual sits this far down the frame; the band above it is the sign's ceiling.
const KV_OFFSET_Y := 40

## How much brighter the shop is lit than the plate was baked. See _process().
const LAMP := 1.34

## The scrim is BANDS OF PLAIN ColorRect, not a gradient and not a shader. This screen
## wanted a banded falloff anyway: a smooth ramp over a 640x360 pixel lattice is the one
## thing a pixel title must not have. It holds most of its ink the whole way down the mark
## and feathers out below it, before the picture opens up.
## Eased hard, 2026-09-21. The scrim existed to make a flat vector wordmark legible over a
## lit shop. The mark is now an OPAQUE BRASS TICKET that carries its own contrast, so the
## ink under it was doing nothing but hiding the shelves and costing the frame a third of
## its brightness: 0.42 against the fantasy/battle floor of 0.60, with a key visual that
## measures 0.63 on its own. What is left is enough to seat the ticket in the room and to
## keep the head of the frame from competing with Nara's face.
const SCRIM_TOP := [0.46, 0.40, 0.34, 0.27, 0.20, 0.13]
const SCRIM_TAIL := [0.09, 0.06, 0.03, 0.01]
const INK_SCRIM := Color(0.030, 0.020, 0.042)

var bg: TextureRect
## The mirrored strip of ceiling above the key visual — see _build().
var ceiling: TextureRect
var logo: TextureRect
var motes: Array[Dictionary] = []
var t := 0.0
var _logo_y := 0
## The mark HANGS. Its string is drawn in the top of the plate image and runs off the top
## of the frame into the shop's ceiling beam, so the plate itself lands inside the scrim
## band and the string crosses the dark ceiling above the key visual. -22 was the old
## flat-mark offset, which cropped the string away entirely.
var _logo_target := -6
## One pixel of sway, on a slow beat, in WHOLE pixels. A tag on a string is never quite
## still; a sub-pixel sway on a 640x360 lattice is the grid coming apart.
var _logo_x := 80.0

## The web export frees a FontFile nobody is holding, and the title loses its type — a
## defect that once destroyed a title screen silently. These are the references that keep
## them alive for as long as this card is on screen.
var _font_body: FontFile
var _font_display: FontFile


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# The title card can be shown while the tree is paused (the pause layer, and the
	# splash the web build puts up). A node on PROCESS_MODE_INHERIT gets no _process at
	# all while paused, which in the fork shipped as a title screen frozen at frame one —
	# no drift, no light, and the mark stuck at the alpha it fades from.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font_body = load("res://assets/fonts/midnight_pixel_12.fnt")
	_font_display = load("res://assets/fonts/midnight_pixel_16.fnt")
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
	bg.position = Vector2(0, KV_OFFSET_Y)
	bg.size = Vector2(640, 360)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# The 40 px above the picture used to be a flat rectangle of ink — a ninth of the frame
	# carrying no image at all, and the single darkest thing in every measurement of this
	# screen. It is now the CEILING: the picture's own top rows, mirrored upward, so the
	# beams and the lantern chains carry on above the key visual instead of stopping at a
	# hard line. A vertical flip of a NEAREST texture drawn at 1:1 is exact — no
	# resampling, no drift, which a scale or a blur would both have cost.
	if bg.texture:
		ceiling = TextureRect.new()
		ceiling.name = "Ceiling"
		ceiling.texture = bg.texture
		ceiling.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ceiling.stretch_mode = TextureRect.STRETCH_KEEP
		ceiling.flip_v = true
		ceiling.position = Vector2(0, KV_OFFSET_Y - 360)
		ceiling.size = Vector2(640, 360)
		ceiling.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Behind the picture in z, so the seam is the picture's own edge either way.
		add_child(ceiling)
		move_child(ceiling, bg.get_index())

	# The moving light is the picture's OWN lantern, brightened and warmed on a slow
	# breath in _process. Not an additive blob drawn over it: the light that moves is the
	# light in the room. No material anywhere on this screen.

	var rng := RandomNumberGenerator.new()
	rng.seed = 1113
	for i in 46:
		motes.append({
			"x": rng.randf_range(0.0, 640.0),
			"y": rng.randf_range(0.0, 320.0),
			"vx": rng.randf_range(-5.0, 5.0),
			"vy": rng.randf_range(-11.0, -3.0),
			"a": rng.randf_range(0.20, 0.62),
		})

	_bands(0, 108, SCRIM_TOP)      # under the mark
	_bands(108, 40, SCRIM_TAIL)    # and out, before the picture opens up
	_edges()

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.stretch_mode = TextureRect.STRETCH_KEEP
	logo.size = Vector2(480, 150)
	# The mark is 480x150 with its ink between rows 15 and 96 of the frame once placed
	# here; drawn at 1:1, never scaled by a non-integer factor.
	logo.position = Vector2(80, _logo_target)
	# Present from frame one. It must never start at alpha 0 and be brought up by a Tween:
	# a Tween does not advance while the tree is paused, and that shipped once as a title
	# screen with no title on it. Motion is allowed to add to a finished screen; it is
	# never allowed to be the thing that finishes it.
	logo.modulate.a = 1.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


## `total` pixels of ink in equal bands from `y` down, each at its own alpha.
func _bands(y: int, total: int, alphas: Array) -> void:
	var h := int(float(total) / float(alphas.size()))
	for i in alphas.size():
		var r := ColorRect.new()
		r.color = Color(INK_SCRIM.r, INK_SCRIM.g, INK_SCRIM.b, float(alphas[i]))
		r.position = Vector2(0, y + i * h)
		r.size = Vector2(640, h)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)


## The left and right edges, stepped inward. Corners-as-squares read on screen as four
## squares, which is a bug, not a vignette; full-height bands do the same job and look
## like a frame.
func _edges() -> void:
	for step in 5:
		var w := 26 - step * 4
		var a := 0.085 - step * 0.017
		for x in [step * 26, 640 - step * 26 - w]:
			var r := ColorRect.new()
			r.color = Color(0.055, 0.032, 0.080, a)
			r.position = Vector2(x, 0)
			r.size = Vector2(w, 360)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(r)


## A PLAQUE: the one thing on this screen that is allowed to be opaque.
##
## Type set straight onto a lit key visual is the defect this game already shipped once.
## The fix Elena's title used is a soft gradient scrim — and a smooth gradient is the one
## thing a 640x360 title on a fixed palette cannot have. So the falloff is DITHERED
## instead: one ink value, one alpha, an ordered 4x4 Bayer threshold deciding which pixels
## take it. That is what a pixel artist actually draws, it quantises onto the palette by
## construction (there is only ever one colour in it), and it lets the plate die out into
## the art over ten to fourteen pixels instead of ending on a hard rectangle edge.
##
## Built as ONE Image shown at 1:1 NEAREST, not a mesh of ColorRects: a 4-pixel checker
## across 336 columns would be hundreds of nodes.
##
## `fade_r` is the falloff into the picture on the right, `fade_t` / `fade_b` the falloff
## at the top and bottom. A plaque that runs to the bottom of the frame keeps `fade_b` 0:
## dithering out one pixel above the screen edge leaves a bright hairline of art under the
## type, which is the defect again in miniature.
func make_plaque(x: int, y: int, w: int, h: int, fade_r: int, fade_t: int, fade_b: int) -> TextureRect:
	const BAYER := [
		[0, 8, 2, 10],
		[12, 4, 14, 6],
		[3, 11, 1, 9],
		[15, 7, 13, 5],
	]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# A warm brown plate rather than a near-black hole. Cream type at #f1dfb0 on this is
	# still a 9:1 contrast, and 27% of the frame stops reading as zero.
	var face := Color(0.205, 0.130, 0.076, 0.78)
	for py in h:
		for px in w:
			var c := 1.0
			if fade_r > 0:
				c = minf(c, clampf(float(w - 1 - px) / float(fade_r), 0.0, 1.0))
			if fade_t > 0:
				c = minf(c, clampf(float(py) / float(fade_t), 0.0, 1.0))
			if fade_b > 0:
				c = minf(c, clampf(float(h - 1 - py) / float(fade_b), 0.0, 1.0))
			if c >= 1.0 or (BAYER[py % 4][px % 4] + 0.5) / 16.0 < c:
				img.set_pixel(px, py, face)
	# A brass hairline along the top of the solid body: the plaque reads as a plate
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


## Called when the card becomes visible: the room alone for half a second, then the mark
## settles up two pixels at a time. Whole pixels, so it never softens mid-tween.
func play_in() -> void:
	t = 0.0
	_logo_y = _logo_target + 14
	logo.position.y = _logo_y
	logo.modulate.a = 0.85
	_snd("sting")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta

	# The lantern breathes, as a warm lift on the plate itself. Value only — no scale, or
	# the grid resamples.
	if bg:
		# LAMP is a value-only lift on the plate, not a scale and not a shader: the shop is
		# lit brighter than the plate was baked. The composed screen measured 0.42 against
		# the fantasy/battle floor of 0.60 with the raw plate at 0.63, and after the scrim
		# and the plaque were eased the rest of the gap is simply how much light is in the
		# room. Value only, so the 640x360 grid is untouched.
		var k := 0.06 * sin(t * 0.85) + 0.016 * sin(t * 4.3)
		bg.modulate = Color(LAMP + k * 1.3, LAMP + k, LAMP * 0.985 + k * 0.4)
		# The key visual drifts, but only ever by an integer — the parallax a pixel game
		# is allowed to have.
		# Vertical drift ONLY, and this is the pixel-game form of STANDARD item 6's
		# "never shows the plate's edge". A 16:9 title normally buys its parallax by
		# scaling the plate past 1.16 so the edge is always outside the frame — which this
		# screen cannot do, because a non-integer scale resamples a 640x360 lattice and the
		# picture stops being pixel art. The plate is therefore exactly frame-sized, and
		# any HORIZONTAL drift opens a sliver of ground at one side. Vertically there is
		# cover on both axes: the mirrored ceiling above and the frame edge below, so the
		# picture can breathe up and down for ever without an edge ever appearing.
		bg.position = Vector2(0, KV_OFFSET_Y + roundf(cos(t * 0.11) * 2.0))
		if ceiling:
			ceiling.modulate = bg.modulate
			ceiling.position = Vector2(bg.position.x, bg.position.y - 360)

	# The ticket sways on its string, a pixel either way, out of phase with the lantern so
	# the two motions never lock into one beat.
	if logo:
		logo.position.x = _logo_x + roundf(sin(t * 0.43 + 1.2))

	for m in motes:
		m["x"] += m["vx"] * delta
		m["y"] += m["vy"] * delta
		if m["y"] < -2.0:
			m["y"] = 362.0
			m["x"] = randf_range(0.0, 640.0)
		if m["x"] < -2.0:
			m["x"] = 642.0
		elif m["x"] > 642.0:
			m["x"] = -2.0
	queue_redraw()

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


# ---- the type family, lent to whatever places copy over this composition ---------------

func style_label(l: Label, size: int, color: Color, display := false) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	# A one-pixel ink shadow under every glyph: what keeps the type crisp where it sits on
	# the plaque's dithered edge, at a whole-pixel offset so it cannot soften the grid.
	# (An outline is not an option: these are bitmap fonts, and Godot grows outlines only
	# on dynamic ones.)
	l.add_theme_color_override("font_shadow_color", Color(0.027, 0.018, 0.039, 0.95))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_font_override("font", _font_display if display else _font_body)


## Brass plate buttons: a dark ink face and a gold rule under it that thickens on hover.
## Not a default Button anywhere on this screen, and no book serif anywhere in the menu —
## the display face belongs to the mark; the UI face is the game's own pixel font.
func style_button(b: Button, size := 12) -> void:
	b.add_theme_font_override("font", _font_display if size >= 16 else _font_body)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color("#fff3d2"))
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_focus_color", Color("#fff3d2"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.037, 0.075, 0.92)
	normal.border_color = Color("#8a5a20")
	normal.border_width_bottom = 2
	normal.set_content_margin_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.08, 0.04, 0.95)
	hover.border_color = GOLD
	hover.border_width_bottom = 3
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.20, 0.13, 0.04, 0.96)
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
