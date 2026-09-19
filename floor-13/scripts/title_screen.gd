extends Control
class_name TitleScreen

## The mainstream title screen as a composition, not a Label over a backdrop —
## ops/adult_forks/TITLE_SCREENS.md. This is the SFW parent of the same pass the fork
## got on 2026-09-18, and it is a straight port of that file's lessons with the fork's
## adult marks removed.
##
## Layers, back to front, on the 640x360 canvas (drawn at 2x, so the 1920x1080 key
## visual keeps its pixels — this node is the one place in this pixel game that is not
## pixel art, and it is filtered LINEAR on purpose; the pixel UI sits over it):
##
##   key visual   the night-shift corridor, breathing: a slow drift and a ~1.2% swell,
##                the way a camera on a shoulder never quite holds still
##   tube         the fluorescent flicker, done as a modulate on the picture itself so
##                the whole corridor dips when the tube does
##   sweep        one soft bar of light crawling down the corridor — the "light moves"
##                item of the spec, and the layer that guarantees the frame is never
##                byte-identical to the one before it
##   rain (x2)    two particle sheets at different speeds and sizes — the parallax; the
##                near sheet is faster and longer, the far one slower and faint
##   overlay      one baked plate: the radial darkening plus the ink column down the
##                RIGHT third, where the logotype and the menu sit
##   logotype     the designed mark (ops/title_logotypes_mainstream.py) settling in
##   marks        the studio line only. No rating badge, no adult label: this is the
##                mainstream build and nothing on it may name or imply the adult one.
##
## The HUD owns the buttons and the localised lines; it places them in the ink column.
## Sound is the game's own Soundscape (scripts/soundscape.gd): a cue when the screen is
## first seen, a lighter cue on hover and press.

const KV_PATH := "res://assets/title/keyvisual.webp"
const LOGO_PATH := "res://assets/title/logotype.png"
const FONT_REG := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")

## Framing. The right ~38% of this screen is type — logotype, eyebrow, menu — so the
## picture under it has to be wall, not face.
##
## The installed key visual is keyvisual_03, and unlike the fork's it is NOT mirrored.
## The fork flipped its render because the character and the letter both sat on the
## right, under the type. This frame already reads the other way: the fluorescent tube
## and the lit end of the corridor are upper-LEFT, she stands just left of centre with
## her face at about 51% of the width — clear of the ink column, which starts at 62% —
## and the right third is the dark corridor wall her ponytail falls against. Flipping it
## would drag the bright corridor under the type and put her face against the ink.
## So: no flip. The cover scale is only what the breathing camera needs.
const BG_SCALE := 1.10
const BG_OFFSET := Vector2(-6.0, 3.0)

## The vignette and the type-scrim are ONE BAKED TEXTURE (assets/title/overlay.png, made
## by ops/title_logotypes_mainstream.py), not runtime shaders.
##
## They were shaders in the fork. On the WEB export they drew nothing at all, while a
## plain ColorRect dropped in beside them at the same point in the child order drew
## fine. A TextureRect with an imported texture paints on every renderer this project
## ships to, so the gradient is baked once by Pillow and the game draws a picture. It is
## also faster, and it is editable somewhere a designer can see it.
const OVERLAY_PATH := "res://assets/title/overlay.png"

## Where the type column lives, in canvas units. The HUD reads these so the two files
## cannot drift apart.
const COL_X := 402.0
const COL_W := 226.0

var bg: TextureRect
var logo: TextureRect
var sweep: ColorRect
var rain_far: CPUParticles2D
var rain_near: CPUParticles2D
var t := 0.0
var flick := 1.0
var next_glitch := 1.4
var _fonts := [FONT_REG, FONT_BOLD]   # held: the web export frees an unreferenced FontFile


func _ready() -> void:
	# _and_offsets_, and no explicit size: setting size on a Control whose anchors span
	# the parent is fought by the layout and Godot warns on every instance. The offsets
	# preset gives the same 640x360 without the argument.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# The title screen can run while the tree is PAUSED (Gate.require() pauses the tree,
	# scripts/gate.gd). A node on PROCESS_MODE_INHERIT gets no _process at all while
	# paused, and that is exactly how the fork's live web title shipped once: frozen at
	# frame one — no drift, no light, the mark stuck at the alpha it fades from. Measured
	# there, not guessed: two canvas grabs 1.8 s apart differed by 0 pixels of 921600.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	if is_visible_in_tree():
		call_deferred("play_in")


func _build() -> void:
	var ink := ColorRect.new()
	ink.color = Color("#05070d")
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
	bg.modulate = Color(0.88, 0.96, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# The moving light: a soft horizontal bar that crawls down the corridor and wraps.
	# Cheap, always in motion, and it reads as the tube's reflection travelling the wall.
	sweep = ColorRect.new()
	sweep.name = "Sweep"
	sweep.color = Color(0.62, 0.86, 0.92, 0.055)
	sweep.size = Vector2(640, 46)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sweep)

	rain_far = _rain(1, 6, 150.0, 0.09, 70)
	add_child(rain_far)
	rain_near = _rain(1, 14, 320.0, 0.17, 40)
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
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# A second, harder scrim under the type only. The baked column is a gradient built
	# for a 1920-wide plate; at 640 the menu still floated on it, so the column gets a
	# flat surface of its own — TITLE_SCREENS.md, "the interface gets a surface".
	var plate := ColorRect.new()
	plate.name = "TypePlate"
	plate.color = Color(0.016, 0.027, 0.047, 0.62)
	plate.position = Vector2(COL_X - 12.0, 24.0)
	plate.size = Vector2(COL_W + 24.0, 312.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	var edge := ColorRect.new()
	edge.color = Color("#ff3b4a")
	edge.position = Vector2(COL_X - 12.0, 24.0)
	edge.size = Vector2(1, 312)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.position = Vector2(COL_X, 38)
	logo.size = Vector2(COL_W, 78)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	# Mainstream marks: the studio line, and nothing else. blazeCore Play is the SFW
	# label; Flat 404 and any rating badge belong to the other build and must never
	# appear here.
	_mark("blazeCore Play", Vector2(14, 338))


func _rain(w: int, h: int, speed: float, alpha: float, count: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var a: float = 1.0 - absf(float(y) / float(h - 1) - 0.5) * 2.0
		img.set_pixel(0, y, Color(0.8, 0.95, 1.0, a))
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


func _mark(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT_BOLD)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#d5e4de"))
	l.add_theme_color_override("font_outline_color", Color("#05070d"))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


## Called each time the title becomes visible. The logotype settles in from a little
## below over 1.3 s after a beat of the room alone, and the cue plays once per showing.
func play_in() -> void:
	if logo == null:
		return
	logo.modulate.a = 0.55
	logo.position.y = 48
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 1.3).set_delay(0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "position:y", 38.0, 1.4).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snd("elevator")


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
		flick = 0.58 if randf() < 0.5 else 1.07
		next_glitch = randf_range(0.04, 0.16) if flick < 0.8 else randf_range(0.9, 3.4)
	var target := 1.0 + 0.025 * sin(t * 37.0)
	flick = lerpf(flick, target, delta * 9.0)
	bg.modulate = Color(0.88 * flick, 0.96 * flick, 1.0 * flick)
	sweep.position.y = fmod(t * 34.0, 420.0) - 50.0


func _snd(kind: String) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	var s = game.get("soundscape")
	if s == null or not s.has_method("cue"):
		return
	s.cue(kind)


## The title's type family, applied to the HUD's own labels and button so the whole
## screen is set in one face.
##
## Latin is Work Sans (OFL, assets/fonts/). zh is NOT Work Sans and is NOT a runtime
## fallback: this project's Chinese path is the complete BMFont in assets/fonts (see
## scripts/ui_font.gd — a Latin face first draws .notdef, which is the 乱码 this game
## already fixed once), and the 5 MB wqy-microhei.ttc is deliberately excluded from the
## web pack. So in zh the column's localised lines are set in the game's own display
## BMFont, one size up. Verified by looking at a zh capture: no tofu.
func style_label(l: Label, size: int, color: Color, bold := false) -> void:
	if Loc.is_zh():
		UiFont.apply_label(l, size >= 10)
	else:
		l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
		l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#05070d"))
	l.add_theme_constant_override("outline_size", 3)


func style_button(b: Button, size := 13) -> void:
	if Loc.is_zh():
		# the display BMFont for the primary action, the body one for the small pair
		b.add_theme_font_override("font", UiFont.display() if size >= 13 else UiFont.body())
		b.add_theme_font_size_override("font_size", 16 if size >= 13 else 12)
	else:
		b.add_theme_font_override("font", FONT_BOLD)
		b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("#e8f3ee"))
	b.add_theme_color_override("font_hover_color", Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("#ff3b4a"))
	b.add_theme_color_override("font_focus_color", Color("#ffffff"))
	b.add_theme_color_override("font_outline_color", Color("#05070d"))
	b.add_theme_constant_override("outline_size", 3)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = false
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.03, 0.05, 0.07, 0.72)
	normal.border_color = Color("#8fb8a8")
	normal.border_width_left = 2
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var hover := normal.duplicate()
	hover.bg_color = Color(0.05, 0.09, 0.11, 0.86)
	hover.border_color = Color("#ff3b4a")
	hover.border_width_left = 5
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.18, 0.04, 0.07, 0.9)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	if not b.mouse_entered.is_connected(_on_hover):
		b.mouse_entered.connect(_on_hover)
		b.button_down.connect(_on_press)


func _on_hover() -> void:
	_snd("scanner")


func _on_press() -> void:
	_snd("choice")
