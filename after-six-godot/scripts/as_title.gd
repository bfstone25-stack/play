## AsTitle — After Six's title screen as a composition, not a panel stack.
##
## What it replaces, and why. The first pass (shots/01-title.png) was a blurred office
## plate behind two flat rounded-rectangle buttons and font-default text: a dark-mode
## office productivity app. Blaze rejected it. It broke four lines of
## ops/adult_forks/TITLE_SCREENS.md at once — no key visual, no designed logotype, no
## motion, a menu made of code-drawn shapes — and the last of those is studio rule 2,
## which forbids code-drawn shapes outright.
##
## His direction, in his words: sexual tension, crime, office 勾心斗角, and the confidence
## of having won — you win, you get the girl, and the people who used to cheat and deceive
## you now answer to you. A power fantasy with a knife in it. Not "an office at night".
##
## Layers, back to front, on the 420x640 canvas (the window is 840x1280, so every asset is
## authored at 2x and drawn LINEAR):
##
##   ground     deep blue-black, so nothing anywhere is ever a hole
##   keyvisual  the corner office, late: the chair that was not yours, the file on the
##              desk, and a woman who by day would not turn her head, turned toward you
##              and unhurried. Full bleed — it IS the screen, nothing crops it
##              (TITLE_SCREENS.md, "the surface must not eat the picture"). It breathes:
##              a slow drift and a ~1.4% swell, the way a camera on a shoulder never
##              quite holds still.
##   lights     city lights drifting on the glass — two particle sheets at different
##              speeds across the upper band only, additive, magenta and amber. This is
##              also the layer that guarantees no two frames are identical.
##   sweep      one soft magenta bar crawling down the glass: a light passing outside.
##   vignette   a radial darkening generated once into an Image, not a shader. Shaders
##              drew NOTHING on the web export for the sibling title (floor-13's
##              title_screen.gd records the same finding); a texture paints everywhere.
##   plate      the brass door plate, AFTER SIX engraved (ops/aftersix_title.py). It
##              settles in from below over 1.3 s after a beat of the room alone.
##   file       the open case file on the desk, and the surface the menu is set on. Its
##              ruled rows ARE the buttons' form; the Button nodes are transparent until
##              hovered.
##
## The lamp breathes as a slow warm modulate over the whole picture rather than as a glow
## sprite at a fixed point: where the lamp lands is the renderer's decision, not this
## file's, and a glow pinned to the wrong corner is worse than no glow.
##
## Type. One family, Work Sans — the mark is engraved in Work Sans Bold and the menu is
## set in it, so rule 4 ("the buttons in the same type family and treatment") is true and
## not merely claimed. zh falls back to the bundled CJK face, which main.gd installs as a
## fallback on the theme's fonts; the fallbacks are held in _kept so the web export cannot
## free them (memory: "Godot web font fallback").
extends Control
class_name AsTitle

const KV := "res://assets/title/keyvisual.webp"
const KV_FALLBACK := "res://assets/art/plate_title.webp"
const PLATE := "res://assets/title/plate.png"
const FILE := "res://assets/title/file.png"
const FONT := "res://assets/fonts/WorkSans-Bold.ttf"
const CJK := "res://assets/fonts/NotoSansCJK-subset.otf"

const W := 420.0
const H := 640.0

## The brand block, over the glass.
## The brass plate rides high and small so it crosses the window and her hair, never her
## face. The picture is full bleed at 1:1 vertically, so when the key visual is replaced
## the type is what moves, not the crop — on paper the old 60,48,300,89 was a perfectly
## reasonable rectangle and it landed squarely on her face.
##
## Re-checked 2026-09-19 against the v3 key visual (as_title_kv_00), and this time by
## arithmetic rather than by eye, because the breathing camera means no single capture is
## the worst case. _process drifts bg.position.y over ±3.5 and swells bg.scale over
## 1.046–1.074 about the canvas centre. Measuring her hairline in a capture and inverting
## both puts it at y≈99.5 unmoved, and never above y≈95 at the extreme of the swell. The
## plate's bottom edge is at 88. Seven pixels, at the one moment of the cycle that is
## tightest — so the rect stands as it is. If the next key visual is framed any closer,
## redo this sum before trusting the screenshot.
const PLATE_RECT := Rect2(78, 10, 264, 78)

## The file card, and its menu rows. These four numbers are the contract with
## ops/aftersix_title.py, which bakes the ruled lines the buttons sit on: the card is
## drawn at half its authored size, so ROW_TOP/ROW_H here are that file's values halved.
## Change one side and change the other — a button floating off its own rule is exactly
## the "code-drawn shape" look this screen exists to remove.
const CARD_RECT := Rect2(20, 352, 380, 260)
const TAGLINE_Y := 352.0 + 120.0 / 2.0    # 412 — the card's tagline band
const ROW_TOP := 352.0 + 190.0 / 2.0      # 447
const ROW_H := 78.0 / 2.0                 # 39
const ROW_X := 42.0
const ROW_W := 336.0

var bg: TextureRect
var plate: TextureRect
var card: TextureRect
var sweep: ColorRect
var tagline: Label
var rows: Array[Button] = []
var t := 0.0
var _kept: Array = []                     # held fonts: the web export frees unreferenced ones


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _ready() -> void:
	# Gate.require() pauses the tree on this screen. A node on PROCESS_MODE_INHERIT gets no
	# _process while paused, which is how the sibling title once shipped frozen at frame
	# one: no drift, no light, the mark stuck at the alpha it fades in from.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	call_deferred("play_in")


func _font() -> Font:
	var f: Font = load(FONT)
	if f == null:
		return ThemeDB.fallback_font
	if f is FontFile and (f as FontFile).fallbacks.is_empty():
		var cjk: Font = load(CJK)
		if cjk != null:
			(f as FontFile).fallbacks = [cjk]
			_kept.append(cjk)
	_kept.append(f)
	return f


func _build() -> void:
	var ground := ColorRect.new()
	ground.color = Color("#09070f")
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	# The fallback is the relit day plate the fork shipped on. It is a room, not a key
	# visual, and it is here only so a checkout without the rendered frame still runs —
	# never as the thing that ships.
	var kv := KV if ResourceLoader.exists(KV) else KV_FALLBACK
	if ResourceLoader.exists(kv):
		bg.texture = load(kv)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.size = Vector2(W, H)
	bg.pivot_offset = Vector2(W / 2.0, H / 2.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# City lights on the glass: two sheets at different speeds, so the window has depth.
	# Confined to the upper band — below it is the room, and lights drifting through the
	# desk would read as dust, not as a city.
	add_child(_lights(7, 9.0, 0.16, 26, Color("#ff3d8a")))
	add_child(_lights(4, 15.0, 0.13, 34, Color("#ffb347")))

	sweep = ColorRect.new()
	sweep.color = Color(1.0, 0.48, 0.72, 0.045)
	sweep.size = Vector2(W, 58)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sweep)

	var vig := TextureRect.new()
	vig.texture = _vignette()
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vig.size = Vector2(W, H)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	plate = _picture(PLATE, PLATE_RECT)
	card = _picture(FILE, CARD_RECT)


func _picture(path: String, rect: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## Soft round dots drifting sideways across the window band. CPUParticles2D rather than a
## shader, for the same reason the vignette is a texture.
func _lights(size: int, speed: float, alpha: float, count: int, tint: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var d := size * 2
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(d / 2.0, d / 2.0)
	for y in d:
		for x in d:
			var f: float = clampf(1.0 - Vector2(x + 0.5, y + 0.5).distance_to(c) / (d / 2.0), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, f * f))
	p.texture = ImageTexture.create_from_image(img)
	p.amount = count
	p.lifetime = 26.0
	p.preprocess = 26.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	# the upper band only: the glass, not the room
	p.emission_rect_extents = Vector2(40, 96)
	p.position = Vector2(-30, 128)
	p.direction = Vector2(1.0, -0.04)
	p.spread = 6.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.55
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	p.modulate = Color(tint.r, tint.g, tint.b, alpha)
	return p


## A radial darkening, baked once into a small Image and scaled up. Deliberately not a
## shader: on the sibling's web export a shader drew nothing at all while a plain texture
## dropped in beside it painted fine.
func _vignette() -> ImageTexture:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := Vector2(x / float(n - 1) - 0.5, y / float(n - 1) - 0.5) * 2.0
			var r: float = clampf(u.length() / 1.42, 0.0, 1.0)
			# Darker at the corners, and a little darker again along the very top and
			# bottom. Both terms are lighter than they were: the old 0.74/1.5 pair was
			# written to buy contrast for type set directly on the picture, and there is
			# no longer any such type — the mark is engraved brass and the menu is ink on
			# a manila card, each carrying its own ground. Measured, the old vignette cost
			# the composed frame ~0.06 brightness for nothing, and
			# ops/adult_forks/UI_DIRECTION.md is explicit that darkness spent on wallpaper
			# is the failure this studio keeps shipping.
			var edge: float = maxf(0.0, absf(u.y) - 0.58) * 0.9
			img.set_pixel(x, y, Color(0.035, 0.027, 0.06, clampf(r * r * 0.56 + edge, 0.0, 0.74)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------------------
## The localised type. main.gd owns the strings and the actions; this builds the controls
## into the composition it has already laid out.
##
## `items` is an ordered array of {text, fn} — at most ROWS of them, one per ruled line on
## the card.
func compose(tag: String, items: Array, lang_text: String, lang_fn: Callable, hint: String) -> void:
	tagline = Label.new()
	tagline.text = tag
	tagline.position = Vector2(CARD_RECT.position.x, TAGLINE_Y)
	tagline.size.x = CARD_RECT.size.x
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_override("font", _font())
	tagline.add_theme_font_size_override("font_size", 12)
	# Ink on the file, not lit type over the window. The first pass outlined it against the
	# picture; with the real key visual in, that band is a bright city and an outlined line
	# floating on it is the "text on a photo" look the whole pass is removing.
	tagline.add_theme_color_override("font_color", Color("#3c2a22"))
	tagline.add_theme_constant_override("outline_size", 0)
	tagline.add_theme_constant_override("line_spacing", 0)
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tagline)

	for i in mini(items.size(), 2):
		var b := _row(items[i]["text"], items[i]["fn"], i, i == 0)
		rows.append(b)
		add_child(b)

	# Language is NOT a peer of the two actions. A 中文 button beside "take the chair" on a
	# global adult release reads as a settings screen that got loose; this is a small chip
	# in the corner, the size of a control and not of a promise.
	var lang := Button.new()
	lang.text = lang_text
	lang.position = Vector2(W - 54, 14)
	lang.custom_minimum_size = Vector2(40, 26)
	lang.size = Vector2(40, 26)
	lang.tooltip_text = lang_text
	lang.focus_mode = Control.FOCUS_NONE
	lang.add_theme_font_override("font", _font())
	lang.add_theme_font_size_override("font_size", 11)
	for role in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		lang.add_theme_color_override(role, Color("#ffdca3") if role == "font_hover_color" else Color("#c9a98f"))
	lang.add_theme_color_override("font_outline_color", Color("#09070f"))
	lang.add_theme_constant_override("outline_size", 5)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.04, 0.03, 0.06, 0.42)
	chip.border_color = Color(1.0, 0.86, 0.64, 0.30)
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(2)
	var chip_hi := chip.duplicate()
	chip_hi.border_color = Color("#ff3d8a")
	lang.add_theme_stylebox_override("normal", chip)
	lang.add_theme_stylebox_override("hover", chip_hi)
	lang.add_theme_stylebox_override("pressed", chip_hi)
	lang.add_theme_stylebox_override("focus", chip)
	lang.pressed.connect(func(): Sfx.tap(); lang_fn.call())
	lang.mouse_entered.connect(_hover)
	add_child(lang)

	var h := Label.new()
	h.text = hint
	h.position = Vector2(0, 618)
	h.size.x = W
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_override("font", _font())
	h.add_theme_font_size_override("font_size", 10)
	h.add_theme_color_override("font_color", Color(0.72, 0.60, 0.68, 0.85))
	h.add_theme_color_override("font_outline_color", Color("#09070f"))
	h.add_theme_constant_override("outline_size", 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)


## One menu entry: a line typed on the file, landing exactly on its printed rule.
##
## The button has NO shape of its own in the normal state — no fill, no border, no corner
## radius. Its form is the ruled row already drawn on the card. Hover lights the paper the
## way a hand moving over a desk lamp does and thickens the magenta rule at the left; press
## sinks it. That is the whole treatment, and it is the difference between a menu placed in
## a composition and two pills floating on a photo.
func _row(text: String, fn: Callable, index: int, lead: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(ROW_X, ROW_TOP + index * ROW_H + 2.0)
	b.custom_minimum_size = Vector2(ROW_W, ROW_H - 5.0)
	b.size = Vector2(ROW_W, ROW_H - 5.0)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = false
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font())
	b.add_theme_font_size_override("font_size", 17 if lead else 14)
	# Ink on manila. The lead action takes the stamp's red, the second stays in ink, so the
	# eye lands on the one that starts the night.
	b.add_theme_color_override("font_color", Color("#8c1c2c") if lead else Color("#241a16"))
	b.add_theme_color_override("font_hover_color", Color("#b02030") if lead else Color("#3a1420"))
	b.add_theme_color_override("font_pressed_color", Color("#5e1220"))
	b.add_theme_constant_override("outline_size", 0)

	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.content_margin_left = 14
	flat.content_margin_right = 10
	flat.content_margin_top = 4
	flat.content_margin_bottom = 4
	var hover := flat.duplicate()
	hover.bg_color = Color(1.0, 0.92, 0.76, 0.16)      # the lamp falling on the page
	hover.border_color = Color("#ff3d8a")
	hover.border_width_left = 4
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.25, 0.10, 0.06, 0.20)
	b.add_theme_stylebox_override("normal", flat)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", flat)
	b.mouse_entered.connect(_hover)
	b.pressed.connect(Sfx.tap)
	b.pressed.connect(fn)
	return b


func _hover() -> void:
	Sfx.hover()


# ---------------------------------------------------------------------------------------
## Two to four seconds of life before anything is pressed (TITLE_SCREENS.md item 3): the
## room alone for half a beat, then the plate settles onto the door, then the file comes up
## off the desk under it.
func play_in() -> void:
	if plate == null:
		return
	# Every property here animates with .from(), and NOTHING is set to alpha 0 outside the
	# tween. That is not a style preference — it is a bug fix found by looking at a zh
	# capture. Switching language rebuilds this screen (main.gd re-enters show_title from
	# the chip's own signal handler, which queue_frees the node the handler belongs to);
	# on that rebuild the intro tween did not finish, and because the old code had already
	# written modulate.a = 0 to the card, the rows and the tagline, the Chinese title
	# screen came up as a picture with a brass plate and no menu at all. Nothing errored.
	#
	# With .from(), the resting state of every element is VISIBLE, and the animation is the
	# only thing that can be lost. A screen that fails to animate is a screen; a screen that
	# fails to appear is a bug report.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(plate, "modulate:a", 1.0, 1.1).from(0.0).set_delay(0.45) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(plate, "position:y", PLATE_RECT.position.y, 1.3) \
		.from(PLATE_RECT.position.y + 14.0).set_delay(0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 1.0).from(0.0).set_delay(1.0) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(card, "position:y", CARD_RECT.position.y, 1.2) \
		.from(CARD_RECT.position.y + 16.0).set_delay(1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# The rows and the tagline are siblings of the card, not children, so they have to be
	# brought up with it by hand — otherwise the menu hangs in the air for a second before
	# the paper it is typed on arrives, which is the floating-pill read being removed.
	for b in rows:
		tw.tween_property(b, "modulate:a", 1.0, 0.8).from(0.0).set_delay(1.35)
	if tagline != null:
		tw.tween_property(tagline, "modulate:a", 1.0, 0.9).from(0.0).set_delay(1.3)
	_snd()


## The title sting: one low room tone under the plate landing. Sfx builds its cues from
## oscillators, so this costs no asset.
func _snd() -> void:
	if Sfx.has_method("pickup"):
		Sfx.pickup()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	# the breathing camera — a drift you would not notice if you were told to look for it
	bg.position = Vector2(sin(t * 0.11) * 5.0, cos(t * 0.08) * 3.5)
	var swell := 1.06 + 0.014 * sin(t * 0.19)
	bg.scale = Vector2(swell, swell)
	# the lamp breathing: one slow warm rise and fall over the whole room, because a single
	# filament lamp warms and cools rather than flickering
	var lamp := 0.93 + 0.075 * sin(t * 0.62) + 0.02 * sin(t * 1.7)
	bg.modulate = Color(lamp, lamp * 0.965, lamp * 0.99)
	sweep.position.y = fmod(t * 26.0, 470.0) - 70.0
