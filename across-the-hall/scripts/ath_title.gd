extends Control
## ACROSS THE HALL — the first second of the game.
##
## What this replaces, and why it had to go. hud.gd's _splash() was: splash.png behind a
## 38%-black ColorRect, and ONE plain Label reading
##
##     Across the Hall
##     Click to enter the fourth floor
##     WASD  mouse look  E interact  F light  Esc
##
## — the title, the call to action and the keyboard map set as three lines of the same
## 26 px system font in the middle of the screen. That is the "picture beside a form"
## objection in ops/adult_forks/TITLE_SCREENS.md arrived at from the third direction: not a
## black panel, not a document, but a README centred on a photograph.
##
## And it was invisible anyway. splash.png measures **0.08 brightness** against a shelf
## floor of 0.45; captured through ops/capture_title.sh the whole frame came back
## effectively black. Of the four all-ages titles this one scored worst, and it scored
## worst because nobody had ever looked at it — which is the entire argument of the memory
## "verification that lies".
##
## --- the one place this title argues with its brief -------------------------------------
##
## Across the Hall was named alongside three genuinely cute games in a pass whose brief is
## CUTE, SWEET, COLOURFUL, BLING, ENERGETIC, with play/rebound-tycoon-godot as the
## reference. It is not that kind of game. It is a first-person apartment horror: a
## fourth-floor landing, a calendar stuck on February 17, a clock stuck at 02:17, and a
## neighbour who exists only in peripheral vision. Its README, its fog, its SSAO and its
## WorldEnvironment saturation of 0.82 are the product, not a palette accident.
##
## So this screen takes the half of the direction that genuinely applies to it and refuses
## the half that does not, and says so out loud rather than quietly splitting the
## difference:
##
##   TAKEN — the shelf floor, 0.45 brightness / 0.30 saturation. That number is not about
##   mood, it is about surviving as a thumbnail beside ninety-nine others, and it applies
##   to a horror game exactly as much as to a puzzle game. Colour is what makes a horror
##   thumbnail read; dimness is what makes it invisible. The key visual is a saturated
##   teal corridor with amber doors and a glossy floor — vivid, high-contrast, and still
##   unmistakably a corridor you would not want to walk down.
##
##   REFUSED — candy. No pink, no confetti, no bouncy round display face, no sticker
##   logotype. Painting this game bubblegum would be answering the letter of the brief
##   against its own product, and ops/adult_forks/UI_DIRECTION.md already records the cost
##   of the mirror-image error: The Other Side's 02:17 interiors were lit up to clear 0.63
##   and stopped reading as 02:17.
##
## Blaze gets to overrule this; it is recorded here so that he can, rather than discovering
## it as a silent choice.
##
## --- the six items (TITLE_SCREENS.md) ----------------------------------------------------
##
##   1. key visual   assets/title/keyvisual.webp, full bleed, nothing cropping it.
##                   ops/allages_title_art/allages_gen.py ath_title.
##   2. logotype     _paint_mark() — ACROSS THE / HALL in Work Sans Bold, the studio's
##                   grotesque for building horror (Floor 13 uses the same face), tracked
##                   wide, cut by a hard dark keyline and lit from the corridor's own amber.
##                   Never a plain Label; the screen it replaces used one for everything.
##   3. motion       a slow dolly INTO the corridor — the one camera move the composition
##                   asks for, because it is a one-point perspective and the vanishing
##                   point is the thing the game is about walking towards. The lights
##                   breathe, dust drifts, and the mark cuts in a letter at a time.
##   4. styled menu  one button, placed below the vanishing point where the floor is clear.
##                   A horror title has one thing to press.
##   5. marks        ALL AGES and blazeCore Play. No 18+ and no Flat 404 — Flat 404 is the
##                   adult label, and this is the mainstream track.
##   6. sound        the game's own drone is already running under this; the title adds no
##                   sting, because the first sound of this game should be the building.
##
## --- engine rules, each bought with a burned day -----------------------------------------
##
##   Shaders draw NOTHING on the Godot web export. Every gradient here is generated into an
##   Image and shown through a TextureRect. See play/after-six-godot/scripts/as_title.gd.
##
##   A CanvasItem paints itself BEFORE its children, so the mark is painted on a node of
##   its own added after the picture, never in this Control's _draw().
##
##   Draw order is child order. A negative z_index on a child of a Control sinks it below
##   the whole 3D viewport, which on this game means the title vanishes into the hallway.
##
##   A FontFile's fallbacks vanish on the web export unless the resource is held; _kept
##   does that.

signal enter_pressed

const W := 1280.0
const H := 720.0
const KV := "res://assets/title/keyvisual.webp"
const FACE := "res://assets/fonts/WorkSans-Bold.ttf"

var _clock := 0.0
var _settle := 0.0
var _kv: TextureRect
var _kv_base := Rect2()
var _paint: Control
var _mark_tex: Texture2D
var _dust: Array = []
var _flick := 1.0
var _next_flick := 2.0
var _kept: Array = []
var _door: Button
var _keys: Label
var _marks: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_key_visual()
	if ResourceLoader.exists("res://assets/title/logotype.png"):
		_mark_tex = load("res://assets/title/logotype.png")
	_paint = Control.new()
	_paint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint.draw.connect(_paint_mark)
	add_child(_paint)
	_build_menu()
	_build_marks()
	set_process(true)


## The display face, held so the web export cannot free it.
##
## SystemFont — which is what every other label in this game uses, deliberately, per
## ui_font.gd's "do not bind a TTF as the project font on Web" — is the right call for body
## copy and the wrong one for a logotype: a mark whose letterforms are whatever the
## player's machine happens to have is not a designed mark. So the face is bundled (OFL,
## licence beside it in assets/fonts/) for this screen only, and the rest of the game keeps
## its system stack.
func _mark_font() -> Font:
	if _kept.is_empty():
		var f: Font = load(FACE) if ResourceLoader.exists(FACE) else UiFont.face()
		_kept.append(f)
	return _kept[0]


# ---------- 1: the key visual, full bleed -------------------------------------------------
func _build_key_visual() -> void:
	_kv = TextureRect.new()
	if ResourceLoader.exists(KV):
		_kv.texture = load(KV)
	_kv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_kv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Oversized, and the dolly scales it from the vanishing point rather than the centre of
	# the rectangle — see _process. The extra margin is what the push moves into.
	_kv_base = Rect2(Vector2(-W * 0.07, -H * 0.07), Vector2(W * 1.14, H * 1.14))
	_kv.position = _kv_base.position
	_kv.size = _kv_base.size
	_kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kv)

	# A ground for the mark and a ground for the menu, top and bottom, in the corridor's
	# own ink rather than in neutral black — a neutral scrim on a saturated teal picture
	# reads as grey fog laid over it, which is how the old splash got to 0.08. These are
	# short and they are tinted, so they cost the frame very little brightness.
	_grad(Color(0.03, 0.09, 0.12, 0.72), Color(0.03, 0.09, 0.12, 0.0), Rect2(0, 0, W, 250.0))
	_grad(Color(0.03, 0.09, 0.12, 0.0), Color(0.03, 0.09, 0.12, 0.78), Rect2(0, H - 210.0, W, 210.0))


## A vertical gradient as an IMAGE behind a TextureRect. NOT a shader: shaders draw nothing
## at all on the Godot web export — no error, no warning, the element is simply absent.
func _grad(top: Color, bottom: Color, rect: Rect2) -> void:
	var n := 128
	var img := Image.create(2, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var c := top.lerp(bottom, float(y) / float(n - 1))
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)


# ---------- 4: the menu -------------------------------------------------------------------
func _build_menu() -> void:
	# One button. A horror title has one thing to press, and the composition has exactly one
	# clear place to put it: the floor below the vanishing point.
	#
	# It was a rounded rectangle with a 1 px amber border — STANDARD.md item 4, and the
	# objection Blaze actually made: eighteen titles that all read as one template rendered
	# eighteen times. The shape has to come from the game's own world, and no game in the
	# studio has a more obvious object than this one. The game is called Across the Hall.
	# The thing across the hall is a door standing open. So the control is a door, it is
	# shut when you are not touching it, and on hover it comes off the jamb and the warm
	# room behind it shows in the crack — which is the game's one sentence, performed by
	# the button before the player has pressed anything.
	#
	# shared/godot/shaped_button.gd's DOOR shape was written for The Other Side (this
	# game's night twin) and had never been copied into a project. scripts/shaped_button.gd
	# is that file verbatim; the two games share the shape the way they share the hallway.
	var b := ShapedButton.new()
	b.shape = ShapedButton.Shape.DOOR
	# The leaf is the corridor's own painted door, not a new colour on the screen: a teal
	# so dark it is nearly ink, so the only warm thing on the button is the crack of light.
	b.tint = Color(0.10, 0.20, 0.23)
	b.ink = Color(0.97, 0.94, 0.86)
	b.label = I18n.t("title_enter")
	# Taller than a text button and narrower: a door is a portrait rectangle, and one
	# shaped like a letterbox reads as a plank.
	b.custom_minimum_size = Vector2(300, 92)
	b.size = Vector2(300, 92)
	b.position = Vector2(W * 0.5 - 150.0, H - 214.0)
	b.add_theme_font_size_override("font_size", 16)
	# Work Sans has no CJK glyphs; "走进四楼" set in it draws four blank boxes and reports
	# nothing. Cjk.apply_control falls through to the display face for English.
	b.add_theme_font_override("font", _mark_font())
	Cjk.apply_control(b)
	b.pressed.connect(func(): enter_pressed.emit())
	add_child(b)
	_door = b


func _build_marks() -> void:
	# The keyboard map, which used to be the third line of the logotype. It is reference,
	# not a mark, so it is set small and quiet at the foot where reference goes.
	_keys = _band(I18n.t("title_keys"), 13, Color(0.72, 0.80, 0.82, 0.92), H - 104.0)
	_marks = _band(I18n.t("title_marks"), 12, Color(0.62, 0.72, 0.74, 0.85), H - 54.0)
	_build_lang()


## The language control: four languages, each written in its own script, cycled by one
## press. Not a dropdown — a horror title with a settings widget on it is a settings screen
## with a picture behind it, and the whole argument of this file is that it is not that.
##
## It sits top-right, away from the mark and away from the door, and it is the only thing on
## this screen besides the door that can be pressed.
##
## STANDARD.md item 7: ja is the priority and all four are actually translated
## (scripts/i18n.gd). The control exists so a player can reach them — a game whose language
## is decided once by OS.get_locale() and never again is a game most of whose players never
## learn it has their language.
func _build_lang() -> void:
	var l := Button.new()
	l.flat = true
	l.focus_mode = Control.FOCUS_NONE
	l.text = I18n.ENDONYM[I18n.lang]
	l.size = Vector2(150, 30)
	l.position = Vector2(W - 168.0, 20.0)
	l.add_theme_font_size_override("font_size", 14)
	Cjk.apply_control(l)
	l.add_theme_color_override("font_color", Color(0.72, 0.80, 0.82, 0.80))
	l.add_theme_color_override("font_hover_color", Color(0.99, 0.74, 0.30))
	l.pressed.connect(func() -> void:
		I18n.cycle()
		l.text = I18n.ENDONYM[I18n.lang]
		Cjk.apply_control(l)
		_relang())
	add_child(l)


## Repaint every string on this screen in the new language, in place.
##
## Rebuilding the screen would restart the dolly and re-cut the logotype, so switching
## language would look like a crash and a reload. The four things that carry words are held
## and re-set instead; the picture and the motion never learn it happened.
func _relang() -> void:
	if _door:
		_door.label = I18n.t("title_enter")
		Cjk.apply_control(_door)
		_door.queue_redraw()
	for pair in [[_keys, "title_keys"], [_marks, "title_marks"]]:
		var lab: Label = pair[0]
		if lab:
			lab.text = I18n.t(str(pair[1]))
			Cjk.apply_label(lab)
	if _paint:
		_paint.queue_redraw()


func _band(text: String, size_px: int, color: Color, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _mark_font())
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	# Anchored, never `size.x = W`: that is a value the layout system owns and overwrites,
	# and a label set that way comes back clipped to its first word.
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_left = 0.0
	l.offset_right = 0.0
	l.offset_top = y
	l.offset_bottom = y + size_px * 2.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Cjk.apply_label(l)
	add_child(l)
	return l


# ---------- 2: the logotype ---------------------------------------------------------------
func _letters(f: Font, text: String, sz: int, track: float) -> Array:
	var out: Array = []
	var total := 0.0
	for i in range(text.length()):
		out.append({"ch": text[i],
			"w": f.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x})
		total += out[i]["w"] + (track if i < text.length() - 1 else 0.0)
	return [out, total]


func _word(f: Font, text: String, sz: int, at: Vector2, track: float, color: Color,
		drop := Vector2.ZERO, delay := 0.0) -> void:
	var r := _letters(f, text, sz, track)
	var glyphs: Array = r[0]
	var x: float = at.x - float(r[1]) * 0.5
	for i in range(glyphs.size()):
		var g: Dictionary = glyphs[i]
		# Letters CUT IN rather than dropping: no bounce, no overshoot. The reference
		# title's mark lands like a toy because that game is a toy; this one arrives the
		# way a light comes on in a corridor.
		var d := clampf((_settle - delay - i * 0.05) * 3.0, 0.0, 1.0)
		if d <= 0.001:
			continue
		_paint.draw_string(f, Vector2(x, at.y) + drop, str(g["ch"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(color, color.a * d))
		x += float(g["w"]) + track


func _paint_mark() -> void:
	var f := _mark_font()
	var cx := W * 0.5
	var amber := Color(0.99, 0.74, 0.30)
	# 2026-09-22: the two lines used to be drawn here with _word() -- the display font
	# stamped eight times around itself for a cut, plus an amber bloom. That is a font
	# wearing effects, which ops/STANDARD.md rules out, and the O was just an O.
	#
	# The mark is now made in ops/title_logotypes.py::across_the_hall: forty-year-old
	# corridor paint, scraped thin along the grain, chipped at the edges -- and the O of
	# ACROSS is the peephole, brass barrel, knurled ring, dark glass with one sliver of
	# landing light on it. The peephole is what this game is about.
	#
	# The flicker stays HERE rather than being baked into the PNG: the corridor's light
	# is alive and the mark lives with it, which was the one genuinely good thing about
	# the old drawn version.
	if _mark_tex:
		var mw := 940.0
		var mh := mw * float(_mark_tex.get_height()) / float(_mark_tex.get_width())
		var a := 0.96 * (0.62 + 0.38 * _flick) * clampf(_settle * 1.4, 0.0, 1.0)
		_paint.draw_texture_rect(_mark_tex,
			Rect2(Vector2(cx - mw * 0.5, 74.0), Vector2(mw, mh)), false, Color(1, 1, 1, a))
		# the corridor's amber laid over the letterforms, flickering with the tube
		_paint.draw_texture_rect(_mark_tex,
			Rect2(Vector2(cx - mw * 0.5, 74.0), Vector2(mw, mh)), false,
			Color(amber.r, amber.g, amber.b, 0.16 * _flick))

	# a hairline under the mark, struck from the centre out as it settles
	var half := 210.0 * clampf((_settle - 0.5) * 1.4, 0.0, 1.0)
	if half > 1.0:
		_paint.draw_line(Vector2(cx - half, 248.0), Vector2(cx + half, 248.0),
			Color(amber, 0.55 * _flick), 1.0)

	# The title in the player's own language, under the rule. The MARK stays ACROSS THE /
	# HALL in all four — it is what the storefront and the itch page say, and a player who
	# found the game under that name has to recognise the screen (the same split as
	# fold-godot's WORDMARK / WORDMARK_SUB). This line is how they read it.
	var sub_text: String = I18n.SUBTITLE.get(I18n.lang, "")
	if sub_text != "" and _settle > 0.7:
		var sf := Cjk.face()
		if sf == null:
			sf = f
		var ss := 26
		var sw := sf.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		var sa := clampf((_settle - 0.7) * 2.0, 0.0, 1.0)
		_paint.draw_string(sf, Vector2(cx - sw * 0.5 + 1, 285.0), sub_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(0.02, 0.06, 0.08, 0.8 * sa))
		_paint.draw_string(sf, Vector2(cx - sw * 0.5, 284.0), sub_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(amber, 0.85 * sa))

	# dust in the corridor light
	for d in _dust:
		var a: float = sin(clampf(d["t"] / d["life"], 0.0, 1.0) * PI) * d["a"]
		_paint.draw_circle(d["p"], d["r"], Color(0.92, 0.88, 0.78, a))


# ---------- 3: motion ---------------------------------------------------------------------
func _process(dt: float) -> void:
	_clock += dt
	_settle = minf(2.2, _settle + dt)

	# The dolly. A one-point perspective has exactly one honest camera move and this is it:
	# scale about the VANISHING POINT, not about the middle of the rectangle, so the walls
	# slide outward past the camera and the far end of the hall stays put. Scaling about
	# the centre would make the whole picture swell, which reads as a zoom on a photograph
	# rather than as walking.
	if _kv:
		var push := 1.0 + (1.0 - exp(-_clock * 0.16)) * 0.085
		_kv.pivot_offset = Vector2(_kv.size.x * 0.5, _kv.size.y * 0.46)
		_kv.scale = Vector2.ONE * push
		_kv.position = _kv_base.position + Vector2(sin(_clock * 0.19) * 5.0,
			sin(_clock * 0.13 + 0.7) * 3.0)

	# The fluorescents. Mostly steady with an occasional stutter — in FOLD a flicker is a
	# fault (it is a children's game and it reads as a bug); here it is the fixture, and it
	# is the one thing on this screen that says what kind of game this is.
	_next_flick -= dt
	if _next_flick <= 0.0:
		_next_flick = randf_range(2.2, 6.5)
		_flick = 0.42
	_flick = minf(1.0, _flick + dt * 5.0)

	# dust drifting through the light
	if _dust.size() < 34 and randf() < dt * 14.0:
		_dust.append({"p": Vector2(randf_range(0.0, W), randf_range(0.0, H)),
			"v": Vector2(randf_range(-7.0, 7.0), randf_range(-14.0, -3.0)),
			"r": randf_range(0.8, 2.1), "a": randf_range(0.10, 0.34),
			"life": randf_range(5.0, 11.0), "t": 0.0})
	var live: Array = []
	for d in _dust:
		d["t"] += dt
		if d["t"] < d["life"]:
			d["p"] += d["v"] * dt
			live.append(d)
	_dust = live
	if _paint:
		_paint.queue_redraw()


func _gui_input(e: InputEvent) -> void:
	# Click anywhere, the way the screen this replaces worked — the button is where the eye
	# is told to go, but a player who clicks the picture should not be ignored.
	if e is InputEventMouseButton and e.pressed:
		enter_pressed.emit()
