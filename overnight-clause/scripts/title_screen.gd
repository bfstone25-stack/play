extends Control
class_name TitleScreen

## The title screen — ops/adult_forks/TITLE_SCREENS.md.
##
## This one uses the game's real corridor. A second Camera3D stands at the lobby end of
## the corridor and dollies toward the 401 door over half a minute, breathing as it goes,
## with Mara's torch on it — the same SpotLight the player carries, swaying a little. The
## corridor's own fixture at z=2 flickers as it always does, so the light that moves on the
## title is the light that moves in the game. Over the 3D: the key visual (Mara, the
## torch, the door — the pipeline render) blended in on the right through a soft edge,
## breathing at a different rate from the camera so the two read as layers; a wet
## vignette; the typewriter logotype striking in; the 18+ and studio marks.
##
## The HUD keeps its own buttons (EnterBuilding, the language buttons) and places them in
## this composition, so every test that presses `splash_enter` still does.

const KV_PATH := "res://assets/title/keyvisual.webp"
const LOGO_PATH := "res://assets/title/logotype.png"
const FONT_REG := preload("res://assets/fonts/IBMPlexMono-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexMono-Bold.ttf")

## The key visual's soft left edge and its green-damp tint are BAKED INTO THE IMAGE
## (assets/title/keyvisual.webp carries alpha). They were a canvas_item shader, and on the
## web export that shader did not run — which would have left an opaque plate covering
## the 3D corridor this title dollies through, i.e. covering the idea.
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

var cam: Camera3D
var torch: SpotLight3D
var kv: TextureRect
var logo: TextureRect
var audio: TitleAudio
var t := 0.0
var _cam_origin := Vector3(-0.85, 1.48, 0.35)
var _fonts := [FONT_REG, FONT_BOLD]   # held: web frees an unreferenced FontFile


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The title screen runs while the tree is PAUSED. Gate.require() pauses the tree
	# (scripts/gate.gd) and the web build reaches the gate before the title is dismissed —
	# gate.gd's own comment already records that floor-13-x sits paused behind its title
	# card. A node on PROCESS_MODE_INHERIT gets no _process at all while paused, which is
	# exactly what shipped: the live web title was frozen at frame one — no drift, no
	# light, and the mark stuck at the alpha 0 it starts its fade from. Measured, not
	# guessed: two canvas grabs 1.8 s apart differed by 0 pixels of 921600.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_2d()
	audio = TitleAudio.new()
	audio.name = "TitleAudio"
	add_child(audio)
	call_deferred("_build_3d")
	call_deferred("play_in")


func _build_3d() -> void:
	# The HUD is a child of the Game (Node3D); the camera has to live in 3D space.
	var game := get_parent().get_parent() if get_parent() else null
	if game == null or not (game is Node3D):
		return
	cam = Camera3D.new()
	cam.name = "TitleCamera"
	cam.fov = 62.0
	cam.near = 0.08
	cam.far = 60.0
	cam.position = _cam_origin
	game.add_child(cam)
	cam.look_at(Vector3(-3.05, 1.05, 3.05), Vector3.UP)
	torch = SpotLight3D.new()
	torch.light_color = Color(1.0, 0.86, 0.62)
	torch.light_energy = 2.6
	torch.spot_range = 13.0
	# Left at 24. Widening this to 34 was tried on 2026-09-22 to lift the title's
	# brightness (0.43 against a shelf averaging 0.63) and changed the composed frame by
	# exactly nothing -- so the corridor you see behind the key visual is the plate's own
	# opaque 48%, not this 3D scene. Recorded because the next person will have the same
	# idea: the darkness here is in the art, not in the lighting or in an overlay, and it
	# needs a re-render rather than a dial.
	torch.spot_angle = 24.0
	torch.spot_angle_attenuation = 0.7
	torch.shadow_enabled = true
	torch.position = Vector3(0.14, -0.1, -0.1)
	cam.add_child(torch)
	cam.current = true


func _build_2d() -> void:
	kv = TextureRect.new()
	kv.name = "KeyVisual"
	if ResourceLoader.exists(KV_PATH):
		kv.texture = load(KV_PATH)
	kv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	kv.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# _and_offsets_: anchors alone leave the offsets, so a 0x0 Control anchored full
	# rect stays 0x0 and paints nothing. This layer was invisible until now.
	kv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kv.pivot_offset = Vector2(640, 360)
	kv.scale = Vector2(1.05, 1.05)
	kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kv)

	var overlay := TextureRect.new()
	overlay.name = "Overlay"
	if ResourceLoader.exists(OVERLAY_PATH):
		overlay.texture = load(OVERLAY_PATH)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 2026-09-22. Fourth title with the same shape: a key visual that is already on shelf
	# (0.73/0.38 here, against a Nutaku average of 0.63/0.38) composited down to 0.40 by a
	# baked 0.05-brightness overlay drawn opaque on top. PLICATA's veil, Night Reading's
	# scrim and HOLDOVER's overlay were all this. The plates are fine; the darkness is
	# added afterwards, and the shelf does not sell noir. See ops/market/CRAZYGAMES_SHELF.md.
	# 2026-09-23, adult title pass: 0.75 -> 0.4 -- the baked overlay's column is a darkening
	# under the type, which 0 of 33 Nutaku tiles use; the new plate is lit and the type
	# carries its own outline.
	overlay.modulate.a = 0.4
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.position = Vector2(64, 56)
	logo.size = Vector2(660, 246)
	logo.modulate.a = 1.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	_mark("18+", Vector2(28, 664), true)
	_mark("FLAT 404  ·  blazeCore Play", Vector2(1020, 672), false)


func _mark(text: String, pos: Vector2, boxed: bool) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT_BOLD if boxed else FONT_REG)
	l.add_theme_font_size_override("font_size", 16 if boxed else 13)
	l.add_theme_color_override("font_color", Color("#cfd6c6"))
	l.add_theme_color_override("font_outline_color", Color("#060907"))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boxed:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#06090799")
		box.border_color = Color("#cfd6c6")
		box.set_border_width_all(1)
		box.set_content_margin_all(4)
		box.content_margin_left = 8
		box.content_margin_right = 8
		l.add_theme_stylebox_override("normal", box)
	add_child(l)


## The logotype strikes in: a typewriter does not fade, so it lands in three hits —
## faint, hard, settle — over about a second, after the corridor has been seen alone.
func play_in() -> void:
	if logo == null:
		return
	# The mark starts READABLE and the settle only finishes it. It used to start at
	# alpha 0 and be brought up by a Tween — and a Tween does not advance while the tree
	# is paused, which is exactly the state this card is shown in (Gate.require() pauses
	# the tree). Live, that meant the title screen had no title on it. Motion is allowed
	# to add to a finished screen; it is never allowed to be the thing that finishes it.
	logo.modulate.a = 0.85
	logo.position = Vector2(64, 56)
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(logo, "modulate:a", 0.88, 0.05)
	tw.tween_property(logo, "position:x", 66.0, 0.05)
	tw.tween_interval(0.12)
	tw.tween_property(logo, "modulate:a", 1.0, 0.06)
	tw.tween_property(logo, "position:x", 63.0, 0.04)
	tw.tween_property(logo, "position:x", 64.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if audio:
		audio.sting()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	if cam:
		# the dolly: 0.7 m toward the door over ~28 s, with a breath in height and a little
		# yaw drift, and the torch sways as a torch in a hand does
		# minf, not min: the variadic min() returns Variant and ":=" cannot infer a type from
		# it, which is a PARSE error — this whole title screen failed to compile until now.
		var z := _cam_origin.z + minf(t * 0.026, 0.75)
		cam.position = Vector3(_cam_origin.x + sin(t * 0.37) * 0.035, _cam_origin.y + sin(t * 1.05) * 0.014, z)
		cam.look_at(Vector3(-3.05 + sin(t * 0.21) * 0.08, 1.05 + sin(t * 0.33) * 0.05, 3.05), Vector3.UP)
		if torch:
			torch.rotation = Vector3(sin(t * 1.3) * 0.02, sin(t * 0.9) * 0.03, 0.0)
			torch.light_energy = 2.6 + 0.15 * sin(t * 7.0)
	if kv:
		kv.position = Vector2(sin(t * 0.11) * 8.0, cos(t * 0.08) * 5.0)
		var swell := 1.05 + 0.012 * sin(t * 0.17)
		kv.scale = Vector2(swell, swell)


## The HUD calls this when the splash goes: hand the view back to the player and stop
## the bed. The node stays (hidden) so a test that looks for it still finds it.
func leave() -> void:
	if cam:
		var p := get_tree().get_first_node_in_group("player")
		if p and p.get("camera"):
			p.camera.current = true
		cam.queue_free()
		cam = null
	if audio:
		audio.bed(false)


func style_label(l: Label, size: int, color: Color, bold := false) -> void:
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#060907"))
	l.add_theme_constant_override("outline_size", 3)


## Buttons set like lines on the inspection form: mono, a bracket at the left, the
## bracket goes amber (the torch) on hover and the line goes bone on press.
func style_button(b: Button) -> void:
	# ObjectButtons draw their own label; font colours here would make Button draw it twice.
	if b is ObjectButton:
		b.add_theme_font_override("font", FONT_BOLD)
		return
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("#cfd6c6"))
	b.add_theme_color_override("font_hover_color", Color("#f4efdc"))
	b.add_theme_color_override("font_pressed_color", Color("#ffc46a"))
	b.add_theme_color_override("font_focus_color", Color("#f4efdc"))
	b.add_theme_color_override("font_outline_color", Color("#060907"))
	b.add_theme_constant_override("outline_size", 3)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# A ShapedButton IS the shape -- ops/STANDARD.md item 4, "buttons are not rectangles".
	# It draws its own torn stub in _draw() and hovers by tearing further, so handing it
	# the StyleBoxFlat set below would frame that stub in the exact bracket-rectangle the
	# shape exists to replace. The fonts/colours above still apply; the boxes do not.
	if b is ShapedButton:
		if not b.mouse_entered.is_connected(_on_hover):
			b.mouse_entered.connect(_on_hover)
			b.button_down.connect(_on_press)
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#06090788")
	normal.border_color = Color("#7f9a7a")
	normal.border_width_left = 3
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate()
	hover.bg_color = Color("#0c1410bb")
	hover.border_color = Color("#ffc46a")
	hover.border_width_left = 6
	var pressed := hover.duplicate()
	pressed.bg_color = Color("#2a2010bb")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	if not b.mouse_entered.is_connected(_on_hover):
		b.mouse_entered.connect(_on_hover)
		b.button_down.connect(_on_press)


func _on_hover() -> void:
	if audio:
		audio.ui("hover")


func _on_press() -> void:
	if audio:
		audio.ui("press")
