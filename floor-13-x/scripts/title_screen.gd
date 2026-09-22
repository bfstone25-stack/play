extends Control
class_name TitleScreen

## The title screen as a composition, not a backdrop with a name on it —
## ops/adult_forks/TITLE_SCREENS.md.
##
## Layers, back to front, on the 640x360 canvas (drawn at 2x, so the 1920x1080 key visual
## keeps its pixels — this node is the one place in the game that is not pixel art, and
## it is filtered LINEAR on purpose; the pixel UI sits over it):
##
##   key visual   June under the tube with the retention letter, breathing: a slow drift
##                and a 1.2% swell, the way a camera on a shoulder never quite holds still
##   tube         the fluorescent flicker, done as a modulate on the picture itself so the
##                whole room dips when the tube does
##   rain (x2)    two particle sheets at different speeds and sizes — the parallax; the
##                near sheet is faster and longer, the far one slower and faint
##   overlay      one baked plate: the radial darkening plus the ink column down the right
##                third, where the logotype and the start button sit
##   logotype     HOLDOVER's mark: the lift's floor indicator, a dot-matrix panel with
##                the word burning in it and the car stopped at 13, its direction arrow
##                dead. Drawn by ops/title_logotypes.py :: holdover(). It settles in from
##                below. This is NOT the parent's FLOOR 13 wordmark recoloured — the two
##                games must not share a mark (ops/STANDARD.md, "Adult fork vs all-ages
##                parent").
##   marks        18+ and the studio line, small, fixed
##
## The HUD owns the buttons and the localised lines; it places them over this. The sound
## is the game's own Soundscape: a sting when the screen is first seen, a tick on hover
## and press.

const KV_PATH := "res://assets/title/keyvisual.webp"
const LOGO_PATH := "res://assets/title/logotype.png"
const FONT_REG := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")

## Framing. The right third of this screen is type — logotype, eyebrow, start button —
## so the picture under it has to be wall, not face. The render has June on the right
## with the retention letter, which is the wrong way round, and cropping her over to the
## left at 1.34 threw away the letter and the corridor with her. So the installed key
## visual is MIRRORED (assets/title/keyvisual.webp is keyvisual_01 flipped): June and the
## letter both move to the left half, the lit corridor wall lands under the type, and
## nothing is cropped away to get there. Nothing in the picture carries legible text, so
## the flip costs nothing. The cover scale is then only what the breathing camera needs.
const BG_SCALE := 1.10
const BG_OFFSET := Vector2(-6.0, 4.0)

## The vignette and the type-scrim are ONE BAKED TEXTURE (assets/title/overlay.png,
## made by ops/title_logotypes.py), not runtime shaders.
##
## They were shaders. On the WEB export they drew nothing at all, while a plain ColorRect
## dropped in beside them at the same point in the child order drew fine — proven by
## exporting a build with a red test rect in it. A TextureRect with an imported texture
## paints on every renderer this project ships to, so the gradient is baked once by
## Pillow and the game draws a picture. It is also faster and it is editable somewhere a
## designer can see it.
const OVERLAY_PATH := "res://assets/title/overlay.png"

var bg: TextureRect
var logo: TextureRect
var rain_far: CPUParticles2D
var rain_near: CPUParticles2D
var t := 0.0
var flick := 1.0
var next_glitch := 1.4
var _played_in := false
var _fonts := [FONT_REG, FONT_BOLD]   # held: web frees an unreferenced FontFile


func _ready() -> void:
	# _and_offsets_, and no explicit size: setting size on a Control whose anchors span the
	# parent is fought by the layout and Godot warns on every instance. The offsets preset
	# gives the same 640x360 without the argument.
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
	if is_visible_in_tree():
		call_deferred("play_in")


func _build() -> void:
	var ink := ColorRect.new()
	ink.color = Color("#0a0603")
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
	bg.size = Vector2(640, 360)
	bg.pivot_offset = Vector2(320, 180)
	bg.scale = Vector2(BG_SCALE, BG_SCALE)
	bg.modulate = Color(1.04, 0.93, 0.80)   # sodium, not fluorescent — HOLDOVER's ramp
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	rain_far = _rain(1, 6, 150.0, 0.10, 70)
	add_child(rain_far)
	rain_near = _rain(1, 14, 320.0, 0.20, 40)
	add_child(rain_near)

	var overlay := TextureRect.new()
	overlay.name = "Overlay"
	if ResourceLoader.exists(OVERLAY_PATH):
		overlay.texture = load(OVERLAY_PATH)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(640, 360)
	# 2026-09-22. This baked plate is 0.05 brightness -- effectively a black veil -- and
	# drawing it opaque took the composed title from a key visual that measures 0.66/0.36
	# on its own down to 0.33, against a Nutaku shelf that averages 0.63. Half the
	# brightness of a plate that was already on shelf, spent on an overlay.
	#
	# Third title tonight with exactly this shape: PLICATA's veil, Night Reading's scrim,
	# this. The plates are fine; the darkness is being added on top of them. See
	# ops/market/CRAZYGAMES_SHELF.md -- five of six adult titles sit below a shelf whose
	# own covers are lit and warm rather than noir.
	#
	# Eased rather than removed, because this texture also carries the ink column the
	# logotype and menu sit against.
	# 0.55 lit the figure but also thinned the ink column this plate bakes in alongside
	# the vignette, and the body copy that sits on that column lost its ground. One
	# texture, two jobs, so the alpha is a single tradeoff rather than two dials. 0.75
	# keeps the column readable and still recovers most of the brightness.
	overlay.modulate.a = 0.75
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The mark is the lift's floor indicator (ops/title_logotypes.py :: holdover), 1500x430.
	# Sized to that ratio: KEEP_ASPECT letterboxes inside the rect, so a rect cut for the
	# old 1400x480 mark would have shrunk the panel and left a dead band under it.
	# Pushed right off June's hair. The mirrored key visual puts her left-of-centre and at
	# x=318 the panel's first column of LEDs landed on her fringe, which ate the H.
	logo.position = Vector2(352, 26)
	logo.size = Vector2(272, 78)
	logo.modulate.a = 1.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	_mark("18+", Vector2(14, 326), true)
	_mark("FLAT 404  ·  blazeCore Play", Vector2(444, 330), false)


func _rain(w: int, h: int, speed: float, alpha: float, count: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var a: float = 1.0 - absf(float(y) / float(h - 1) - 0.5) * 2.0
		img.set_pixel(0, y, Color(1.0, 0.86, 0.62, a))   # rain lit by the sodium lamp
	p.texture = ImageTexture.create_from_image(img)
	p.amount = count
	p.lifetime = 1.6
	p.preprocess = 1.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(360, 4)
	p.position = Vector2(320, -10)
	p.direction = Vector2(0.08, 1.0)
	p.spread = 2.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.85
	p.initial_velocity_max = speed
	p.modulate = Color(1, 1, 1, alpha)
	return p


func _mark(text: String, pos: Vector2, boxed: bool) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT_BOLD if boxed else FONT_REG)
	l.add_theme_font_size_override("font_size", 9 if boxed else 8)
	l.add_theme_color_override("font_color", Color("#e8d3b4"))
	l.add_theme_color_override("font_outline_color", Color("#0a0603"))
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boxed:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#0a060399")
		box.border_color = Color("#e8d3b4")
		box.set_border_width_all(1)
		box.set_content_margin_all(3)
		box.content_margin_left = 5
		box.content_margin_right = 5
		l.add_theme_stylebox_override("normal", box)
	add_child(l)


## Called each time the title becomes visible. The logotype settles in from a little
## below over 1.3 s after a beat of the room alone, and the sting plays once per showing.
func play_in() -> void:
	logo.modulate.a = 0.6
	logo.position.y = 36
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 1.3).set_delay(0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "position:y", 26.0, 1.4).set_delay(0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snd("sting")
	_played_in = true


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	# breathing camera: a drift you would not see if you were told to look for it
	bg.position = BG_OFFSET + Vector2(sin(t * 0.13) * 5.0, cos(t * 0.09) * 3.0)
	var swell := BG_SCALE + 0.012 * sin(t * 0.21)
	bg.scale = Vector2(swell, swell)
	# the tube: mostly steady, dips at random, and a fast shimmer under it
	next_glitch -= delta
	if next_glitch <= 0.0:
		flick = 0.55 if randf() < 0.5 else 1.08
		next_glitch = randf_range(0.04, 0.16) if flick < 0.8 else randf_range(0.9, 3.4)
	var target := 1.0 + 0.025 * sin(t * 37.0)
	flick = lerpf(flick, target, delta * 9.0)
	bg.modulate = Color(1.04 * flick, 0.93 * flick, 0.80 * flick)


func _snd(kind: String) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	var s = game.get("soundscape")
	if s == null:
		return
	if kind == "sting" and s.has_method("sting"):
		s.sting()
	elif s.has_method("ui"):
		s.ui(kind)


## The title's type family, applied to the HUD's own labels and button so the whole
## screen is set in one face. Work Sans, cold, a red bar on the left when the button is
## live — the same wound the logotype carries.
func style_label(l: Label, size: int, color: Color, bold := false) -> void:
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#04070a"))
	l.add_theme_constant_override("outline_size", 2)


func style_button(b: Button) -> void:
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color("#dfeee8"))
	b.add_theme_color_override("font_hover_color", Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("#ff3b4a"))
	b.add_theme_color_override("font_focus_color", Color("#ffffff"))
	b.add_theme_color_override("font_outline_color", Color("#04070a"))
	b.add_theme_constant_override("outline_size", 2)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# [fork] The START button is a ShapedButton — a payroll time card it draws itself
	# (STANDARD.md rule 4). It still wants this function's TYPE (Work Sans, cold, the red
	# pressed state) so the title screen is set in one face, but it must not be given
	# styleboxes: a StyleBoxFlat paints a filled rectangle behind the card, which is
	# exactly the rounded-rectangle-with-a-word-in-it the shape exists to replace. Return
	# before the boxes and let the card draw.
	if b is ShapedButton:
		if not b.mouse_entered.is_connected(_on_hover):
			b.mouse_entered.connect(_on_hover)
			b.button_down.connect(_on_press)
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#04070a66")
	normal.border_color = Color("#8fb8a8")
	normal.border_width_left = 2
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color("#0a1418aa")
	hover.border_color = Color("#ff3b4a")
	hover.border_width_left = 4
	var pressed := hover.duplicate()
	pressed.bg_color = Color("#2a0a10aa")
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
