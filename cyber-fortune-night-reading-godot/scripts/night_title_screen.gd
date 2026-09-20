extends Control
## NightTitleScreen — 夜读's title screen as a composition, not a label stack.
##
## What it replaces. This fork had no title screen at all: main.gd opened straight onto
## night_home_screen.gd, which is a 13pt series label, a 54pt Label of the word "Night
## Reading", the rule wrapped under it, and three cast cards down a MarginContainer over a
## code-drawn Backdrop. ops/adult_forks/TITLE_SCREENS.md opens by rejecting exactly that —
## "a title page that shows a room and a name is not attractive" — and the fork arrived at
## it not by choosing wrong but by never having built one. Every one of that file's six
## items was missing, and studio rule 2 (no code-drawn shapes) was broken by the Backdrop
## standing in for a key visual.
##
## Why it is worth the night. This title is the traffic anchor for the occult line
## (ops/adult_forks/cyber_fortune_night_reading.md §1): nobody searches a mainstream store
## for a fortune-telling game, so the adult version is what brings people in and the day
## game and the app catch them. The first second of this screen is the funnel.
##
## The idea the screen is built on is the fork's own rule — *what you read for her, she
## starts living* — so every object on it is an object that makes a reading BINDING:
##
##   ground     plum, Palette.PLUM. Never a hole: the palette file records that the first
##              pass of this game used near-black and measured 0.12 brightness.
##   keyvisual  Mirren at the night table, the deck under her hand, the candle. Full
##              bleed — it IS the screen, nothing crops it (TITLE_SCREENS.md, "the surface
##              must not eat the picture"). It breathes: a slow drift and a ~1.4% swell.
##   embers     two sheets of candle sparks rising through the lower half at different
##              speeds, additive, gold and lacquer. This is also the layer that guarantees
##              no two frames are identical.
##   draught    one soft warm bar crawling up the frame: the candle guttering in a draught.
##   vignette   a radial darkening generated once into an Image, NOT a shader. Shaders drew
##              nothing at all on the sibling titles' web exports (after-six's as_title.gd
##              and floor-13's title_screen.gd both record it); a texture paints fine.
##   slip       the fortune slip, NIGHT READING pressed into it, 夜读 in lacquer down the
##              right (ops/nightreading_title.py). It settles in from below after a beat of
##              the room alone.
##   seal       the vermilion seal — 18+ · FLAT 404 — struck across the slip's foot a beat
##              later, because a seal is struck AFTER the slip is drawn and because the
##              rating belongs to an object rather than to a grey Tag label.
##   scrim      a generated bottom gradient the menu is set on. Not another panel: After
##              Six shipped a manila card here and Blaze had it removed on 2026-09-20
##              because a 380x260 rectangle covered the one thing the screen is for.
##
## Type. One family, Gloock — the mark is pressed in Gloock and the menu is set in it, so
## TITLE_SCREENS.md item 4 ("the buttons in the same type family and treatment") is true
## rather than claimed. zh falls back to the bundled NotoSerifSC, held in _kept so the web
## export cannot free it (memory: "Godot web font fallback" — fallbacks set on a load()ed
## FontFile vanish on the web export unless the resource is held).
##
## Studio rule 2. No button here has a shape of its own. A menu row's form is the ruled
## line drawn under it and the type on it; hover lights the paper the way a hand passing
## over a candle does, and press sinks it. The language chip is the one exception and it is
## deliberately the size of a control rather than of a promise — a 中文 button sitting as a
## peer of the two things the game is for reads as a settings screen that got loose.
class_name NightTitleScreen

const KV := "res://assets/night/title_kv.png"
const SLIP := "res://assets/title/slip.png"
const SEAL := "res://assets/title/seal.png"
const FONT := "res://assets/fonts/Gloock-Regular.ttf"
const CJK := "res://assets/fonts/NotoSerifSC-subset.otf"

## The DESIGN canvas. Everything below is expressed as a fraction of it and multiplied by
## the node's real rect at build time — it is not a set of pixel coordinates.
##
## It was, for one capture. project.godot sets window/stretch/aspect="expand", which means
## the visible canvas is NOT 720x1280: it is whatever shape the window is, and the engine
## hands this Control that rect. Absolute coordinates written against 720x1280 drew the
## whole screen 110 px to the left of where it belonged, with the slip's left end and the
## first letter of every menu row off the edge of the picture. Nothing errored, the frame
## was plausible, and it was wrong — which is the failure mode this studio keeps writing
## down (memory: verification-that-lies).
##
## So: ratios, resolved in _layout(), re-resolved on `resized`. That also makes the screen
## correct on a phone, which is the only aspect this game will mostly be played at.
const W := 720.0
const H := 1280.0

var w := W
var h := H

## WHERE THE TYPE LIVES, decided by arithmetic against the real key visual rather than by
## eye — and moved once, for a reason worth keeping.
##
## The first version put the slip high, across the wall above her, on the assumption that
## a portrait key visual leaves headroom. The frame that landed does not. title_kv_00 is
## a chest-up shot: measured in the source plate her hairline sits at y 60 of 1152 and her
## eyes at y 280, and the picture is drawn STRETCH_KEEP_ASPECT_COVERED into 720x1280, so
## it is scaled by 1280/1152 = 1.111 and her eyes land at y 311 on the canvas. A mark at
## 118..349 would have been struck across her forehead and both eyes. On paper it was a
## perfectly reasonable rectangle; the same mistake, in the same words, is recorded
## against After Six's brass plate.
##
## The fix is not to crop her — the key visual is full bleed and nothing crops it
## (TITLE_SCREENS.md, "the surface must not eat the picture"). It is to put the whole type
## block BELOW her: she owns the top half, the slip and the menu own the bottom, and the
## scrim between them is a gradient so the picture runs out rather than stopping at a
## seam. Her chin measures at y ~560 and the table edge at y ~790; the scrim starts at 660
## and the slip's top edge at 700, which is over the table rather than over her.
##
## If the key visual is ever replaced, redo this sum. _process drifts the picture +/-6 px
## and swells it between 1.046 and 1.074 about the canvas centre, so NO SINGLE CAPTURE IS
## THE WORST CASE and a screenshot that looks fine is not evidence.
const SLIP_RECT := Rect2(52.0 / W, 700.0 / H, 616.0 / W, 200.0 / H)
## The seal, and the arithmetic that placed it, because it took three goes and each wrong
## answer was wrong in a way that looked fine in the editor.
##
## The slip is a 880x330 plate drawn into 616x200, so it is scaled by 0.70 across and
## 0.606 down, and everything below is measured in the plate and converted. NIGHT READING
## occupies plate x 44..745, i.e. canvas x 83..573, with its baseline at canvas y 813.
## 夜读 runs down plate x 728..880 = canvas x 561..668. The slip's printed foot is at
## canvas y 900.
##
##   1st try, y 826..976: struck through the TAGLINE, so "FLAT 404" was unreadable. On an
##      adult title screen the rating is the one thing that must read at a glance, and it
##      was the least legible element on the frame.
##   2nd try, y 758..908 at x 452: cleared the tagline and struck through the G of
##      READING instead. A seal may clip a Chinese character's corner — that is what seals
##      do — but it may not damage the wordmark.
##   3rd, y 836 at x 470: geometrically right — below the wordmark's baseline, above the
##      tagline, crossing the slip's foot — and it landed squarely on the candle flame,
##      which is the brightest thing in the key visual. Vermilion on a lit flame is not a
##      contrast, and "FLAT 404" was a pink smudge.
##   4th, moved right to the table edge: dark red ink on a dark red table. Worse, and it
##      clipped 夜读 as well.
##
## The fourth attempt is where the actual mistake became visible. All three placements
## were chasing a position on the SCREEN, and a vermilion seal has exactly one ground it
## reads on: the paper it was designed to be struck into. ops/nightreading_title.py leaves
## a band of empty paper between the magenta bar and the printed foot for precisely this,
## and none of the three placements used it.
##
## So the seal is positioned by the SLIP PLATE'S OWN coordinates rather than by the
## screen's. The plate is 880x330 drawn into 616x200 at (52, 700), so plate->canvas is
## x*0.70 + 52 and y*0.606 + 700; the empty band runs from plate y 220 to the sheet's
## bottom at ~310, and the wordmark's baseline is at plate y 194. Striking at plate
## (561, 193) at a UNIFORM 0.70 (a square seal must not be squashed by the plate's
## non-uniform fit) gives canvas (445, 817) at 106 px: its top two thirds are on lit
## paper, where the ink reads, and its foot crosses the printed edge onto the table, which
## is what a struck seal is supposed to do. It starts 4 px under the wordmark's baseline,
## so the word is untouched.
const SEAL_RECT := Rect2(445.0 / W, 817.0 / H, 106.0 / W, 106.0 / H)

## The menu, on the generated gradient under the slip.
const SCRIM_TOP := 660.0 / H
const TAGLINE_Y := 975.0 / H
const ROW_TOP := 1040.0 / H
const ROW_H := 78.0 / H
const ROW_X := 72.0 / W
const ROW_W := 576.0 / W

var main: Node
var bg: TextureRect
var _ground: ColorRect
var _vig: TextureRect
var _lang: Button
var _hint: Label
var slip: TextureRect
var seal: TextureRect
var scrim: TextureRect
var draught: ColorRect
var tagline: Label
var rows: Array[Button] = []
var t := 0.0
var _kept: Array = []              # held fonts: the web export frees unreferenced ones


## The design rect resolved against the node's real one.
func _r(rt: Rect2) -> Rect2:
	return Rect2(rt.position.x * w, rt.position.y * h, rt.size.x * w, rt.size.y * h)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _ready() -> void:
	# Gate.require() pauses the tree on a screen like this one. A node on
	# PROCESS_MODE_INHERIT gets no _process while paused, which is how a sibling title once
	# shipped frozen at frame one: no drift, no embers, the mark stuck at the alpha it
	# fades in from.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_measure()
	_build()
	_compose()
	Tx.changed.connect(_on_lang)
	resized.connect(_layout)
	call_deferred("play_in")


## The real rect, with a floor. `size` is zero for one frame on a node added this frame,
## and dividing a layout by zero silently piles every element at the origin.
func _measure() -> void:
	var r := size
	if r.x < 2.0 or r.y < 2.0:
		r = get_viewport_rect().size
	if r.x < 2.0 or r.y < 2.0:
		r = Vector2(W, H)
	w = r.x
	h = r.y


## Re-resolve every position against the current rect. Called on build and on every
## resize, so a rotated phone or a dragged window re-lays rather than clipping.
func _layout() -> void:
	_measure()
	if bg != null:
		bg.size = Vector2(w, h)
		bg.pivot_offset = Vector2(w / 2.0, h / 2.0)
	for n in [_ground, _vig]:
		if n != null:
			n.size = Vector2(w, h)
	if draught != null:
		draught.size = Vector2(w, h * 0.072)
	if scrim != null:
		scrim.position = Vector2(0, SCRIM_TOP * h)
		scrim.size = Vector2(w, h - SCRIM_TOP * h)
	if slip != null:
		var sr := _r(SLIP_RECT)
		slip.position = sr.position
		slip.size = sr.size
	if seal != null:
		var er := _r(SEAL_RECT)
		seal.position = er.position
		seal.size = er.size
		seal.pivot_offset = er.size / 2.0
	if tagline != null:
		tagline.position = Vector2(ROW_X * w - 30.0, TAGLINE_Y * h)
		tagline.size.x = w - (ROW_X * w - 30.0) * 2.0
	for i in rows.size():
		rows[i].position = Vector2(ROW_X * w, ROW_TOP * h + i * ROW_H * h)
		rows[i].size = Vector2(ROW_W * w, ROW_H * h - 8.0)
		rows[i].custom_minimum_size = rows[i].size
	if _lang != null:
		_lang.position = Vector2(w - 96.0, 26.0)
	if _hint != null:
		_hint.position = Vector2(0, h - 42.0)
		_hint.size.x = w


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
	_ground = ColorRect.new()
	_ground.color = Palette.PLUM
	_ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	if ResourceLoader.exists(KV):
		bg.texture = load(KV)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.size = Vector2(w, h)
	bg.pivot_offset = Vector2(w / 2.0, h / 2.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Candle sparks, in the lower half only: above the table is wall, and embers drifting
	# through it would read as dust rather than as a flame.
	add_child(_embers(6, 11.0, 0.17, 26, Palette.GOLD_PALE))
	add_child(_embers(4, 18.0, 0.13, 32, Palette.LACQUER_SOFT))

	draught = ColorRect.new()
	draught.color = Color(1.0, 0.72, 0.38, 0.040)
	draught.size = Vector2(w, h * 0.072)
	draught.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draught)

	_vig = TextureRect.new()
	_vig.texture = _vignette()
	_vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vig.stretch_mode = TextureRect.STRETCH_SCALE
	_vig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_vig.size = Vector2(w, h)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vig)

	scrim = _scrim()
	slip = _picture(SLIP, _r(SLIP_RECT))
	seal = _picture(SEAL, _r(SEAL_RECT))
	seal.pivot_offset = seal.size / 2.0


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


## Soft round sparks rising off the candle. CPUParticles2D rather than a shader, for the
## same reason the vignette is a texture.
func _embers(size: int, speed: float, alpha: float, count: int, tint: Color) -> CPUParticles2D:
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
	p.lifetime = 24.0
	p.preprocess = 24.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(w * 0.26, h * 0.055)
	p.position = Vector2(w * 0.5, h * 0.66)
	p.direction = Vector2(0.06, -1.0)
	p.spread = 11.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.modulate = Color(tint.r, tint.g, tint.b, alpha)
	return p


## The bottom gradient the menu is set on. Transparent at SCRIM_TOP, near-opaque at the
## foot, so the picture runs OUT rather than stopping at an edge — which is the whole
## difference between this and the black half-screen TITLE_SCREENS.md rejected. Generated
## into an Image for the same reason the vignette is: shaders draw nothing on the web
## export.
func _scrim() -> TextureRect:
	var n := maxi(2, int(h - SCRIM_TOP * h))
	var img := Image.create(1, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var u := float(y) / float(n - 1)
		img.set_pixel(0, y, Color(Palette.PLUM.r * 0.5, Palette.PLUM.g * 0.5,
			Palette.PLUM.b * 0.5, u * u * 0.88))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = Vector2(0, SCRIM_TOP)
	tr.size = Vector2(W, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## A radial darkening baked once into a small Image and scaled up. Kept deliberately light
## — 0.50 at the corners rather than the 0.74 a sibling started from. There is no type set
## directly on the picture here (the mark is pressed paper and the menu has its own
## gradient), so a heavy vignette would be spending the whole budget of darkness on
## wallpaper, which ops/adult_forks/UI_DIRECTION.md names as this studio's recurring
## failure and which this game's own palette.gd already records losing a night to.
func _vignette() -> ImageTexture:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := Vector2(x / float(n - 1) - 0.5, y / float(n - 1) - 0.5) * 2.0
			var r: float = clampf(u.length() / 1.42, 0.0, 1.0)
			var edge: float = maxf(0.0, absf(u.y) - 0.62) * 0.8
			img.set_pixel(x, y, Color(Palette.PLUM.r * 0.6, Palette.PLUM.g * 0.6,
				Palette.PLUM.b * 0.6, clampf(r * r * 0.50 + edge, 0.0, 0.70)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------------------
## The localised type, built over the composition above.
func _compose() -> void:
	tagline = Label.new()
	tagline.text = Tx.t("title.tagline")
	tagline.position = Vector2(ROW_X * w - 30.0, TAGLINE_Y * h)
	tagline.size.x = w - (ROW_X * w - 30.0) * 2.0
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_override("font", _font())
	tagline.add_theme_font_size_override("font_size", 20)
	tagline.add_theme_color_override("font_color", Palette.SMOKE)
	tagline.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	tagline.add_theme_constant_override("outline_size", 6)
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tagline)

	rows.append(_row(Tx.t("title.read"), func(): _start(), 0, true))
	rows.append(_row(Tx.t("title.again"), func(): _start(), 1, false))
	for b in rows:
		add_child(b)

	var lang := Button.new()
	_lang = lang
	lang.text = Tx.t("lang")
	lang.position = Vector2(w - 96.0, 26.0)
	lang.custom_minimum_size = Vector2(70, 44)
	lang.size = Vector2(70, 44)
	lang.focus_mode = Control.FOCUS_NONE
	lang.add_theme_font_override("font", _font())
	lang.add_theme_font_size_override("font_size", 18)
	for role in ["font_color", "font_pressed_color", "font_focus_color"]:
		lang.add_theme_color_override(role, Palette.GOLD_PALE)
	lang.add_theme_color_override("font_hover_color", Palette.HOT_PALE)
	lang.add_theme_color_override("font_outline_color", Palette.PLUM)
	lang.add_theme_constant_override("outline_size", 6)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(Palette.PLUM.r, Palette.PLUM.g, Palette.PLUM.b, 0.46)
	chip.border_color = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.32)
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(2)
	var chip_hi := chip.duplicate()
	chip_hi.border_color = Palette.HOT
	lang.add_theme_stylebox_override("normal", chip)
	lang.add_theme_stylebox_override("hover", chip_hi)
	lang.add_theme_stylebox_override("pressed", chip_hi)
	lang.add_theme_stylebox_override("focus", chip)
	lang.pressed.connect(func():
		Sfx.flip()
		Tx.set_lang("en" if Tx.lang == "zh" else "zh")
		Fortune.save_state())
	add_child(lang)

	var hint := Label.new()
	_hint = hint
	hint.text = Tx.t("title.hint")
	hint.position = Vector2(0, h - 42.0)
	hint.size.x = w
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", _font())
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(Palette.MAUVE.r, Palette.MAUVE.g,
		Palette.MAUVE.b, 0.88))
	hint.add_theme_color_override("font_outline_color", Palette.PLUM)
	hint.add_theme_constant_override("outline_size", 6)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)


## One menu entry. The button has NO shape of its own in the normal state — no fill, no
## border, no corner radius (studio rule 2). Its form is the hairline rule drawn under it
## and the type on it. Hover lights the paper the way a hand passing over a candle does
## and thickens the lacquer rule at the left; press sinks it.
func _row(text: String, fn: Callable, index: int, lead: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(ROW_X * w, ROW_TOP * h + index * ROW_H * h)
	b.custom_minimum_size = Vector2(ROW_W * w, ROW_H * h - 8.0)
	b.size = b.custom_minimum_size
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = false
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font())
	b.add_theme_font_size_override("font_size", 30 if lead else 23)
	# The lead action takes the seal's red, the second stays in paper-white, so the eye
	# lands on the one that starts the night.
	b.add_theme_color_override("font_color", Palette.HOT_PALE if lead else Palette.PAPER)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1) if lead else Palette.GOLD_PALE)
	b.add_theme_color_override("font_pressed_color", Palette.HOT_DEEP)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.84))
	b.add_theme_constant_override("outline_size", 7)

	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.content_margin_left = 18
	flat.content_margin_right = 12
	flat.content_margin_top = 6
	flat.content_margin_bottom = 6
	# the ruled line the row is written on: one hairline at the foot, drawn by the stylebox
	# rather than by a ColorRect so it hovers and presses with the row it belongs to
	flat.border_color = Color(Palette.PAPER_LINE.r, Palette.PAPER_LINE.g,
		Palette.PAPER_LINE.b, 0.30)
	flat.border_width_bottom = 1
	var hover := flat.duplicate()
	hover.bg_color = Color(1.0, 0.86, 0.60, 0.13)        # the candle falling on the page
	hover.border_color = Palette.HOT
	hover.border_width_left = 5
	hover.border_width_bottom = 1
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.28, 0.08, 0.10, 0.22)
	b.add_theme_stylebox_override("normal", flat)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", flat)
	b.mouse_entered.connect(Sfx.flip)
	b.pressed.connect(Sfx.knock)
	b.pressed.connect(fn)
	return b


func _start() -> void:
	if main != null and main.has_method("open"):
		main.open("home")


## Switching language rebuilds the type without re-running the intro. Rebuilding the whole
## screen would be the sibling's bug: main.gd re-enters from the chip's own signal handler,
## which queue_frees the node the handler belongs to, and the intro tween is then lost
## mid-flight. Here only the strings are replaced, so there is nothing to lose.
func _on_lang() -> void:
	if tagline != null:
		tagline.text = Tx.t("title.tagline")
	if rows.size() > 0:
		rows[0].text = Tx.t("title.read")
	if rows.size() > 1:
		rows[1].text = Tx.t("title.again")
	for c in get_children():
		if c is Button and not rows.has(c):
			(c as Button).text = Tx.t("lang")
		elif c is Label and c != tagline:
			(c as Label).text = Tx.t("title.hint")


# ---------------------------------------------------------------------------------------
## Two to four seconds of life before anything is pressed (TITLE_SCREENS.md item 3): the
## room alone for half a beat, then the slip settles onto the wall, then the seal is
## struck over it, then the menu comes up.
##
## Every property here animates with .from(), and NOTHING is set to alpha 0 outside the
## tween. That is not a style preference: the sibling title shipped a Chinese title screen
## with no menu at all because the intro tween was interrupted after the code had already
## written modulate.a = 0 to the rows. With .from(), the resting state of every element is
## VISIBLE and only the animation can be lost. A screen that fails to animate is a screen;
## a screen that fails to appear is a bug report.
func play_in() -> void:
	if slip == null:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(slip, "modulate:a", 1.0, 1.1).from(0.0).set_delay(0.5) \
		.set_trans(Tween.TRANS_SINE)
	var slip_y := SLIP_RECT.position.y * h
	tw.tween_property(slip, "position:y", slip_y, 1.3) \
		.from(slip_y + 22.0).set_delay(0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# the seal is STRUCK, so it arrives fast and slightly oversized and settles — a seal
	# that fades in is a watermark
	tw.tween_property(seal, "modulate:a", 1.0, 0.18).from(0.0).set_delay(1.55)
	tw.tween_property(seal, "scale", Vector2.ONE, 0.26).from(Vector2(1.22, 1.22)) \
		.set_delay(1.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(scrim, "modulate:a", 1.0, 1.0).from(0.0).set_delay(1.1) \
		.set_trans(Tween.TRANS_SINE)
	if tagline != null:
		tw.tween_property(tagline, "modulate:a", 1.0, 0.9).from(0.0).set_delay(1.45)
	for i in rows.size():
		tw.tween_property(rows[i], "modulate:a", 1.0, 0.8).from(0.0).set_delay(1.7 + i * 0.12)
	Sfx.chime(0.8)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	# the breathing camera — a drift you would not notice if you were told to look for it
	bg.position = Vector2(sin(t * 0.10) * 6.0, cos(t * 0.075) * 4.0)
	var swell := 1.06 + 0.014 * sin(t * 0.18)
	bg.scale = Vector2(swell, swell)
	# The candle breathing: one slow warm rise and fall over the whole room, plus a faster
	# small term. A single flame warms and cools; it does not flicker on a timer, and a
	# periodic dip reads as a fault rather than as a flame.
	var flame := 0.94 + 0.070 * sin(t * 0.68) + 0.022 * sin(t * 1.9)
	bg.modulate = Color(flame, flame * 0.962, flame * 0.985)
	draught.position.y = h - fmod(t * 34.0, h + 140.0)


func dev_state() -> Dictionary:
	return {"title_rows": rows.size(), "slip": slip != null and slip.texture != null,
			"kv": bg != null and bg.texture != null}
