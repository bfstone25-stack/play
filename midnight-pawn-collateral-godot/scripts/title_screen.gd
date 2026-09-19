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
##   lamp        the two pendant lamps breathing. Done as a modulate on an additive amber
##               blob, not as a scale, for the reason above — the light changes value, the
##               grid does not move.
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
const MUTED := Color("#9f94ac")
const INK := Color("#08050b")

## Banded so the falloff reads as drawn steps rather than a smooth ramp — but only
## eight of them, and starting well out at 0.52. The first cut used four steps from 0.26
## and the result was concentric rings across the whole picture: a dartboard, not a
## vignette. A pixel vignette is a dark corner, not a pattern.
const VIGNETTE := """
shader_type canvas_item;
void fragment() {
	vec2 d = (UV - vec2(0.5, 0.46)) * vec2(1.16, 1.0);
	float v = smoothstep(0.52, 0.95, length(d));
	v = floor(clamp(v, 0.0, 1.0) * 8.0) / 8.0;
	COLOR = vec4(0.030, 0.018, 0.048, v * 0.85);
}
"""

## The two scrims that make the type readable over a lit counter. Ink, banded the same
## way, opaque behind the mark at the top and behind the copy at the foot, gone in the
## middle band where the picture is the point. Without these the body copy sat on top of
## a brass kettle and could not be read at all.
const SCRIM := """
shader_type canvas_item;
void fragment() {
	// Down to 0.42, not 0.34: the sub-line COLLATERAL sits at y~0.32 and at 0.34 it was
	// landing on her hair with nothing behind it.
	float top = smoothstep(0.42, 0.0, UV.y) * 0.92;
	float foot = smoothstep(0.50, 1.0, UV.y) * 0.90;
	float a = floor(clamp(max(top, foot), 0.0, 1.0) * 8.0) / 8.0;
	COLOR = vec4(0.030, 0.020, 0.042, a);
}
"""

var bg: TextureRect
var lamp: ColorRect
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

	# The lamps. An additive amber wash over the upper half, breathing in value only.
	lamp = ColorRect.new()
	lamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lsh := Shader.new()
	lsh.code = """
shader_type canvas_item;
render_mode blend_add;
uniform float amount : hint_range(0.0, 1.0) = 0.5;
void fragment() {
	float a = 0.0;
	a += smoothstep(0.30, 0.0, distance(UV * vec2(1.78, 1.0), vec2(0.40, 0.10)));
	a += smoothstep(0.30, 0.0, distance(UV * vec2(1.78, 1.0), vec2(1.38, 0.10)));
	a = floor(clamp(a, 0.0, 1.0) * 5.0) / 5.0;
	COLOR = vec4(0.90, 0.63, 0.22, a * amount * 0.26);
}
"""
	var lmat := ShaderMaterial.new()
	lmat.shader = lsh
	lamp.material = lmat
	add_child(lamp)

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

	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ssh := Shader.new()
	ssh.code = SCRIM
	var smat := ShaderMaterial.new()
	smat.shader = ssh
	scrim.material = smat
	add_child(scrim)

	var vig := ColorRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	vig.material = mat
	add_child(vig)

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.stretch_mode = TextureRect.STRETCH_KEEP
	logo.size = Vector2(480, 150)
	logo.position = Vector2(80, 10)
	logo.modulate.a = 0.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


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
	logo.modulate.a = 0.0
	_snd("sting")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta

	# The lamps breathe. Value only.
	if lamp and lamp.material:
		var amt := 0.62 + 0.30 * sin(t * 0.85) + 0.08 * sin(t * 4.3)
		lamp.material.set_shader_parameter("amount", clampf(amt, 0.0, 1.0))

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
