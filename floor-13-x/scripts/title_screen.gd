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
##   vignette     a radial darkening so the eye lands on her and the logotype
##   logotype     the designed mark (ops/title_logotypes.py) settling in from below
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

const VIGNETTE := """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.62;
void fragment() {
	vec2 d = (UV - vec2(0.36, 0.5)) * vec2(1.25, 1.0);
	float v = smoothstep(0.30, 0.95, length(d));
	// a cold band at the top where the tube is, a hard dark at the foot
	float foot = smoothstep(0.62, 1.0, UV.y) * 0.55;
	COLOR = vec4(0.01, 0.02, 0.03, clamp(v * strength + foot, 0.0, 0.92));
}
"""

## The file panel. The logotype, the eyebrow and the start button all live in the right
## third, and the key visual under them is a lit corridor wall — the first shot of this
## screen had FLOOR 13 sitting across June's face and was unreadable. This is the ink
## HR keeps its forms on: a soft-edged column down the right, no border, nothing that
## reads as a dialog box. It is the scrim that makes the type a designed block rather
## than words dropped on a picture.
const FILE_PANEL := """
shader_type canvas_item;
void fragment() {
	float a = smoothstep(0.40, 0.62, UV.x) * 0.80;
	a *= 1.0 - smoothstep(0.80, 1.0, UV.y) * 0.45;
	COLOR = vec4(0.012, 0.028, 0.030, a);
}
"""

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
	_build()
	if is_visible_in_tree():
		call_deferred("play_in")


func _build() -> void:
	var ink := ColorRect.new()
	ink.color = Color("#04070a")
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
	bg.modulate = Color(0.86, 0.96, 0.98)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	rain_far = _rain(1, 6, 150.0, 0.10, 70)
	add_child(rain_far)
	rain_near = _rain(1, 14, 320.0, 0.20, 40)
	add_child(rain_near)

	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psh := Shader.new()
	psh.code = FILE_PANEL
	var pmat := ShaderMaterial.new()
	pmat.shader = psh
	panel.material = pmat
	add_child(panel)

	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.position = Vector2(318, 30)
	logo.size = Vector2(300, 103)
	logo.modulate.a = 0.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	_mark("18+", Vector2(14, 326), true)
	_mark("FLAT 404  ·  blazeCore Play", Vector2(444, 330), false)


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


func _mark(text: String, pos: Vector2, boxed: bool) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT_BOLD if boxed else FONT_REG)
	l.add_theme_font_size_override("font_size", 9 if boxed else 8)
	l.add_theme_color_override("font_color", Color("#c9d8d2"))
	l.add_theme_color_override("font_outline_color", Color("#04070a"))
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boxed:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#04070a99")
		box.border_color = Color("#c9d8d2")
		box.set_border_width_all(1)
		box.set_content_margin_all(3)
		box.content_margin_left = 5
		box.content_margin_right = 5
		l.add_theme_stylebox_override("normal", box)
	add_child(l)


## Called each time the title becomes visible. The logotype settles in from a little
## below over 1.3 s after a beat of the room alone, and the sting plays once per showing.
func play_in() -> void:
	logo.modulate.a = 0.0
	logo.position.y = 40
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 1.3).set_delay(0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "position:y", 30.0, 1.4).set_delay(0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
	bg.modulate = Color(0.86 * flick, 0.96 * flick, 0.98 * flick)


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
