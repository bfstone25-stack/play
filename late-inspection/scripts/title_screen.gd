extends Control
class_name TitleScreen

## The title screen as a composition, not a text card —
## ops/adult_forks/TITLE_SCREENS.md.
##
## Blaze, 2026-09-19: the mainstream parent "looks like a document". It did: a dark
## ColorRect, a centred Label and five language buttons. This is the same class of screen
## the fork (Overnight Clause) and Floor 13 X got, built for the mainstream rules — SFW
## art, no 18+ badge, the studio mark is `blazeCore Play`.
##
## This game is first-person procedural geometry with almost no 2D art, so the title is a
## 2D Control composition over a rendered key visual; the 3D world is not behind it.
##
## Layers, back to front, on the 1280x720 canvas:
##
##   ink          the floor under everything, so nothing ever shows the clear colour
##   key visual   Mara in the 401 corridor with the torch (pipeline render,
##                ops/late_inspection_art keyvisual_03) — breathing: a slow drift and a
##                ~1.2% swell, the way a hand-held camera never quite holds still
##   torch        a soft warm pool over her torch, swaying and guttering; the moving
##                light item 3 of the spec asks for, drawn as a runtime-built radial
##                ImageTexture and NOT a shader (see below)
##   damp (x2)    two particle sheets at different speeds — the parallax: near drips
##                fast and long, far motes drift slow and faint
##   overlay      one baked plate (assets/title/overlay.png): the radial darkening and a
##                SOFT lean of shadow into the left of the frame — not a wall
##   form         the survey sheet itself: a ruled, cornered, stamped plaque lying OVER
##                the corridor, which is where the type lives
##   logotype     the designed mark (ops/title_logotypes_mainstream.py lateinspect),
##                struck like an inspection form, settling in from below
##   marks        the studio line, small, fixed. No rating badge: this is the mainstream
##                build.
##
## Blaze, 2026-09-19, on the first capture of this screen: it was a hard 50/50 split —
## a flat black panel with left-aligned type, the picture cropped off at the seam, half
## the canvas dead. "A picture beside a form." The fix is not less type, it is the type
## having a surface that belongs to this world: the picture now runs full bleed under
## everything, and FORM 404 is drawn as an actual sheet of paper resting on it —
## gradient body so it is never a flat rectangle, hairline rules between the fields,
## registration ticks at the corners, and a condition stamp struck across the bottom
## edge so the sheet and the corridor touch. Floor 13 solves the same problem with an
## inset ink column (play/floor-13/scripts/title_screen.gd); this title has a better
## object available to it, so it uses the object.
##
## The HUD owns the buttons and the localised lines (hud.gd `_splash`); it places them
## into the column of this composition and styles them through style_label/style_button
## here, so the whole screen is set in one family.
##
## THREE HARD-WON FACTS, ported with the code (scripts are not the place to relearn them):
##
## 1. The vignette and the type-scrim are ONE BAKED TEXTURE, not runtime shaders. They
##    were shaders once, and on the WEB export they drew NOTHING at all, while a plain
##    ColorRect dropped in beside them at the same point in the child order drew fine.
##    A TextureRect with an imported texture paints on every renderer this project ships
##    to, so the gradient is baked by Pillow and the game draws a picture. Edit it in
##    ops/title_logotypes_mainstream.py and re-run; never hand-edit the PNG.
## 2. PROCESS_MODE_ALWAYS. The title runs while the tree is PAUSED (scripts/gate.gd
##    pauses it, and the web build reaches the gate before the title is dismissed). A
##    node on PROCESS_MODE_INHERIT gets no _process while paused, which is exactly what
##    once shipped: a live web title frozen at frame one, no drift, no light.
## 3. The fonts are held in `_fonts`. The web export frees a FontFile nothing references,
##    and a fallback list set on a load()ed FontFile goes with it — the CJK fallback then
##    renders tofu on the web build only.

const KV_PATH := "res://assets/title/keyvisual.webp"
const LOGO_PATH := "res://assets/title/logotype.png"
const OVERLAY_PATH := "res://assets/title/overlay.png"

const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Bold.ttf")
const FONT_MONO_REG := preload("res://assets/fonts/IBMPlexMono-Regular.ttf")
const FONT_UI := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_UI_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")
const FONT_CJK := preload("res://assets/fonts/wqy-microhei.ttc")

const CANVAS := Vector2(1280, 720)

## The picture is FULL BLEED: it is the screen, and the form sheet lies on top of it.
## The sheet covers roughly the left 44% at 42-54% opacity, so what is under it has to be
## corridor, not face. keyvisual_03 frames Mara on the right with the wet corridor and the
## far figure walking away down the left — the figure lands just clear of the sheet's
## right edge, which is the best place for her — so the install needs no flip and no
## crop: cover scale is only what the breathing camera eats.
## 1.18, not 1.06 (ops/STANDARD.md item 6: "never shows the plate's edge — scale past
## 1.16, the 16:9 diagonal ratio"). At 1.06 the overscan is 38 px across and 21 down; the
## breathing drift is ±9 and ±5 and the swell subtracts 0.012, which leaves single-digit
## margins. It survived, but it survived by arithmetic, and the drift numbers are the kind
## of thing a later pass raises without re-deriving the headroom. 1.18 has the margin.
const BG_SCALE := 1.18
const BG_OFFSET := Vector2(-8.0, 0.0)

## The survey sheet. These four numbers and hud.gd's COL_X/COL_W are one layout; the HUD
## places its labels and buttons inside this rectangle, so they move together or not at
## all. Rules are drawn between the fields at FORM_RULES (canvas y).
##
## There was a third rule, at y=520. On the capture it ran straight through the 한국어
## button's row — the language grid's last row is 490..532 — so it read as a strike
## through the interface rather than a division of the form. The primary button already
## has a surface of its own; the rule is gone rather than nudged.
##
## Narrowed and shortened on 2026-09-21, and the reason is a measurement rather than a
## taste: the composite of this screen measured **0.41 brightness / 0.17 saturation**
## against the horror/occult floor of 0.60/0.38 (ops/SHELF_STYLE.md, ops/check_shelf_floor
## .py) — the lowest saturation of the 26. The key visual under it measures 0.80. So the
## picture was not the problem; the three things stacked on it were, and the sheet was the
## largest: 548x606 is 36% of a 1280x720 canvas held at about half opacity in ink.
## 418x474 keeps the paper the type needs and gives the rest of the frame back to the
## corridor. The primary control moved out of this column entirely (hud.gd ENTER_RECT).
const FORM_POS := Vector2(14.0, 22.0)
const FORM_SIZE := Vector2(418.0, 474.0)
const FORM_RULES := [228.0, 330.0]

## Palette: the damp green of the building, the amber of the torch, ink for everything
## the type has to survive.
const INK := Color("#0b0d0c")
const PAPER := Color("#dfe6df")
const DAMP := Color("#8fae94")
const AMBER := Color("#ffb85c")

var bg: TextureRect
var logo: TextureRect
var torch: TextureRect
var drip_near: CPUParticles2D
var drip_far: CPUParticles2D
var audio: TitleAudio
var t := 0.0
var flick := 1.0
var next_flick := 1.1
var _fonts := [FONT_MONO, FONT_MONO_REG, FONT_UI, FONT_UI_BOLD, FONT_CJK]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_fallbacks()
	_build()
	audio = TitleAudio.new()
	audio.name = "TitleAudio"
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio)
	if is_visible_in_tree():
		call_deferred("play_in")


## Every Latin face on this screen gets the CJK face behind it, so zh/ja/ko draw glyphs
## and not tofu. Set once, on the preloaded resources this node holds a reference to.
func _bind_fallbacks() -> void:
	for f in [FONT_MONO, FONT_MONO_REG, FONT_UI, FONT_UI_BOLD]:
		var face: FontFile = f
		if face.fallbacks.is_empty():
			face.fallbacks = [FONT_CJK]


func _build() -> void:
	var ink := ColorRect.new()
	ink.color = INK
	ink.set_anchors_preset(Control.PRESET_FULL_RECT)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	if ResourceLoader.exists(KV_PATH):
		bg.texture = load(KV_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.size = CANVAS
	bg.pivot_offset = CANVAS * 0.5
	bg.scale = Vector2(BG_SCALE, BG_SCALE)
	# Was Color(0.82, 0.90, 0.86): a multiply that cost 10-18% of every channel before the
	# vignette and the sheet had taken their share, on a frame already measured 0.19 below
	# its bucket's brightness floor. The corridor's colour belongs to the render, not to a
	# tint applied on top of it. What remains is the torch's live exposure in _process,
	# which is the flicker and has to stay.
	bg.modulate = Color(1.0, 1.0, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	torch = TextureRect.new()
	torch.name = "Torch"
	torch.texture = _glow(256)
	torch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	torch.stretch_mode = TextureRect.STRETCH_SCALE
	torch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	torch.size = Vector2(620, 620)
	torch.position = Vector2(700, 330)
	torch.modulate = Color(AMBER.r, AMBER.g, AMBER.b, 0.36)
	torch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(torch)

	drip_far = _damp(2, 10, 90.0, 0.10, 60, 2.6)
	add_child(drip_far)
	drip_near = _damp(2, 26, 260.0, 0.17, 34, 1.5)
	add_child(drip_near)

	var overlay := TextureRect.new()
	overlay.name = "Overlay"
	if ResourceLoader.exists(OVERLAY_PATH):
		overlay.texture = load(OVERLAY_PATH)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.position = Vector2.ZERO
	overlay.size = CANVAS
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_form_sheet()

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Fitted to the narrowed sheet: 468 was wider than the 418-wide paper it is struck on,
	# so the mark hung over the right edge onto the corridor.
	logo.position = Vector2(26, 40)
	logo.size = Vector2(398, 150)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	_mark("blazeCore Play", Vector2(26, 676))


## FORM 404 — BUILDING CONDITION SURVEY, as a sheet of paper lying on the corridor floor
## of the picture rather than a panel bolted beside it.
##
## Everything here exists to stop it reading as a black rectangle:
##   * the body is a GRADIENT, built as an ImageTexture (same reason as _glow: a shader
##     would draw nothing on the web export). It runs from damp ink at the top to a
##     thinner, greener ink at the bottom, and it is translucent enough at the foot that
##     the wet floor shows through the paper. A flat fill is the thing Blaze objected to.
##   * a hairline border and registration ticks at the four corners: a printed form has
##     crop marks, and they are what tells the eye this is an object with edges and not
##     an absence of picture.
##   * rules between the fields, at the y where the HUD's own sections start.
##   * a condition stamp struck across the bottom edge at an angle, half on the paper and
##     half on the corridor — the one element that makes the sheet lie ON the picture.
func _form_sheet() -> void:
	var sheet := TextureRect.new()
	sheet.name = "FormSheet"
	sheet.texture = _paper(64, 256)
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sheet.position = FORM_POS
	sheet.size = FORM_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sheet)

	# border
	var b := Color(DAMP.r, DAMP.g, DAMP.b, 0.40)
	_rect(FORM_POS, Vector2(FORM_SIZE.x, 1), b)
	_rect(FORM_POS + Vector2(0, FORM_SIZE.y - 1), Vector2(FORM_SIZE.x, 1), b)
	_rect(FORM_POS, Vector2(1, FORM_SIZE.y), b)
	_rect(FORM_POS + Vector2(FORM_SIZE.x - 1, 0), Vector2(1, FORM_SIZE.y), b)

	# registration ticks: an L in each corner, off the paper's own edge
	var tick := Color(AMBER.r, AMBER.g, AMBER.b, 0.55)
	for sx in [0.0, 1.0]:
		for sy in [0.0, 1.0]:
			var c := FORM_POS + Vector2(FORM_SIZE.x * sx, FORM_SIZE.y * sy)
			var dx := -1.0 if sx > 0.5 else 0.0
			var dy := -1.0 if sy > 0.5 else 0.0
			_rect(c + Vector2(-18.0 * sx, dy), Vector2(18, 2), tick)
			_rect(c + Vector2(dx, -18.0 * sy), Vector2(2, 18), tick)

	# field rules, inset from the paper edge the way a printed rule is
	for y in FORM_RULES:
		_rect(Vector2(FORM_POS.x + 16.0, float(y)), Vector2(FORM_SIZE.x - 32.0, 1),
			Color(DAMP.r, DAMP.g, DAMP.b, 0.26))

	_field_row()
	_stamp()


## The one printed field on the sheet, in the space between the strapline and the
## language grid. Without it that band is 80 px of empty paper, which is how a form card
## turns back into a panel. Numerals and a unit code: this line is locale-neutral by
## construction, so it is set here and not in the localised HUD.
##
## y=302, not 282: the strapline above it is one line in en and TWO in zh (深夜验房 /
## 点击进入…), and at 282 the zh capture had the field row almost touching the second
## line. It is placed for the taller locale and reads as air in the shorter one.
func _field_row() -> void:
	var l := Label.new()
	l.name = "FormField"
	l.text = "UNIT 401     FLOOR 4     02:04     SURVEY INCOMPLETE"
	l.position = Vector2(FORM_POS.x + 16.0, 302.0)
	l.size = Vector2(FORM_SIZE.x - 32.0, 24)
	l.add_theme_font_override("font", FONT_MONO_REG)
	l.add_theme_font_size_override("font_size", 15)
	# Paper value, not damp green: this line sits over the lit end of the corridor, which
	# is the brightest thing on the screen, and a mid-green at 0.82 disappeared into it.
	l.add_theme_color_override("font_color", Color(0.80, 0.86, 0.80, 0.92))
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


## The condition stamp: struck at an angle across the foot of the sheet so that part of
## it is on the paper and part on the wet floor behind it. Rust ink, worn back to 0.62 —
## a rubber stamp on damp paper does not print solid.
func _stamp() -> void:
	var s := Control.new()
	s.name = "Stamp"
	s.size = Vector2(268, 62)
	# Straddling the sheet's new bottom edge (y=496) and its right edge (x=432), which is
	# the whole point of the stamp: half on the paper, half on the wet floor behind it. At
	# the old (352, 586) it was clear of the shortened sheet entirely — a stamp floating on
	# the corridor — and it landed on the language row's new position as well.
	s.position = Vector2(232, 462)
	s.pivot_offset = s.size * 0.5
	s.rotation = deg_to_rad(-8.0)
	s.modulate = Color(1, 1, 1, 0.62)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)

	var rust := Color("#c8613c")
	for r in [
		[Vector2.ZERO, Vector2(268, 3)],
		[Vector2(0, 59), Vector2(268, 3)],
		[Vector2.ZERO, Vector2(3, 62)],
		[Vector2(265, 0), Vector2(3, 62)],
	]:
		var e := ColorRect.new()
		e.color = rust
		e.position = r[0]
		e.size = r[1]
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.add_child(e)

	var l := Label.new()
	l.text = "CONDITION: UNFIT"
	l.position = Vector2(0, 14)
	l.size = Vector2(268, 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT_MONO)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", rust)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(l)


func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


## The paper: a vertical gradient with a little horizontal fibre in it, as an
## ImageTexture. Narrow (64 px) because it is stretched — only the vertical axis carries
## information, and the fibre is there so the stretch is not a perfectly clean ramp.
func _paper(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for y in h:
		var k := float(y) / float(h - 1)
		# 0.58 at the head where the mark is struck, 0.48 at the foot where the floor
		# should come through. Three passes to land on it: 0.66/0.44 still read as a black
		# panel at the head, and 0.54/0.42 was fine until a capture caught the torch at
		# flick 1.10 — the corridor's bright phase — and the thin foot of the sheet lost
		# the body type. The number that matters is the BRIGHT frame, not the average one;
		# the title is a live screen and the reader sees every phase of it.
		var a := lerpf(0.58, 0.48, k * k)
		var g := lerpf(0.0, 0.5, k)         # the damp coming up through the paper
		for x in w:
			var n := rng.randf_range(-0.012, 0.012)
			img.set_pixel(x, y, Color(INK.r, INK.g + g * 0.05, INK.b + g * 0.03,
				clampf(a + n, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## The studio mark. Mainstream: no rating badge.
func _mark(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.name = "StudioMark"
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT_MONO_REG)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.72, 0.78, 0.72))
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


## A soft round falloff, built at runtime as an ImageTexture. Same reason as the baked
## overlay: no shader survives the web export here, and an ImageTexture always draws.
func _glow(n: int) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := float(n - 1) * 0.5
	for y in n:
		for x in n:
			var d: float = Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _damp(w: int, h: int, speed: float, alpha: float, count: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var a: float = 1.0 - absf(float(y) / float(maxi(h - 1, 1)) - 0.5) * 2.0
		for x in w:
			img.set_pixel(x, y, Color(0.78, 0.92, 0.86, a))
	p.texture = ImageTexture.create_from_image(img)
	p.amount = count
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 8)
	p.position = Vector2(640, -20)
	p.direction = Vector2(0.06, 1.0)
	p.spread = 3.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.8
	p.initial_velocity_max = speed
	p.modulate = Color(1, 1, 1, alpha)
	return p


## Called each time the title becomes visible: the mark strikes in from a little below
## after a beat of the corridor alone, and the sting plays once per showing.
func play_in() -> void:
	if logo == null:
		return
	logo.modulate.a = 0.0
	logo.position.y = 64
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 1.1).set_delay(0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "position:y", 46.0, 1.3).set_delay(0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snd("sting")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	# breathing camera: a drift you would not see if you were told to look for it
	bg.position = BG_OFFSET + Vector2(sin(t * 0.13) * 9.0, cos(t * 0.09) * 5.0)
	var swell := BG_SCALE + 0.012 * sin(t * 0.21)
	bg.scale = Vector2(swell, swell)
	# the torch: a wandering pool that gutters, and takes the picture's exposure with it
	next_flick -= delta
	if next_flick <= 0.0:
		flick = 0.62 if randf() < 0.5 else 1.10
		next_flick = randf_range(0.05, 0.18) if flick < 0.8 else randf_range(0.8, 2.6)
	var target := 1.0 + 0.03 * sin(t * 31.0)
	flick = lerpf(flick, target, delta * 8.0)
	torch.position = Vector2(700.0 + sin(t * 0.37) * 26.0, 330.0 + cos(t * 0.29) * 18.0)
	torch.modulate.a = clampf(0.36 * flick, 0.0, 1.0)
	# Centred on 1.0 rather than on the old 0.82/0.90/0.86 tint, and floored: `flick`
	# drops to 0.62 on a gutter, and a title frame is judged on every phase it shows
	# (see _paper), so the dark phase may not take the picture back under its floor.
	var expo := maxf(flick, 0.86)
	bg.modulate = Color(expo, expo, expo)


func _snd(kind: String) -> void:
	if audio == null:
		return
	if kind == "sting":
		audio.sting()
	else:
		audio.ui(kind)


## The bed stops when the player goes through the door; the game's own drone takes over.
func stop_audio() -> void:
	if audio:
		audio.bed(false)
		audio.stop()


## The title's type family, applied to the HUD's own labels and buttons so the whole
## screen is set in one family: IBM Plex Mono for anything stamped like the form, Work
## Sans for the interface. No book serif — the Times-ish serifs make the games academic.
func style_label(l: Label, size: int, color: Color, mono := false) -> void:
	l.add_theme_font_override("font", FONT_MONO_REG if mono else FONT_UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 4)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.clip_text = false


func style_button(b: Button, primary := false) -> void:
	b.add_theme_font_override("font", FONT_UI_BOLD if primary else FONT_UI)
	b.add_theme_font_size_override("font_size", 22 if primary else 18)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color", AMBER)
	b.add_theme_color_override("font_focus_color", Color("#ffffff"))
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 4)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.clip_text = false
	# A ShapedButton IS the shape — it draws a condemnation tag in _draw() and hovers by
	# swaying it. Handing it the StyleBoxFlat set below would frame that tag in the exact
	# rounded rectangle the shape exists to replace, so the fonts and colours above apply
	# and the boxes do not. ShapedButton also draws its own words (`label`), which is why
	# the colour that matters to it is `ink`/`tint` and not font_color.
	if b is ShapedButton:
		if not b.mouse_entered.is_connected(_on_hover):
			b.mouse_entered.connect(_on_hover)
			b.button_down.connect(_on_press)
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.06, 0.88)
	normal.border_color = Color(DAMP.r, DAMP.g, DAMP.b, 0.8)
	normal.set_border_width_all(1)
	normal.border_width_left = 4 if primary else 2
	normal.set_content_margin_all(6)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.10, 0.14, 0.11, 0.94)
	hover.border_color = AMBER
	hover.border_width_left = 6 if primary else 4
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.18, 0.12, 0.05, 0.96)
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
