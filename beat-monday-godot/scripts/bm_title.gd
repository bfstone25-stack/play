extends Control
## BEAT THE MONDAY — the first second of the game.
##
## ops/adult_forks/TITLE_SCREENS.md asks for six things, and the screen this replaces had
## two of them. What it was: plate_corridor (an UNLIT office corridor) behind two rounded
## navy PanelContainers in the "Glass" variation, with the wordmark set as a plain Label
## inside the upper one. Captured and measured, it came in at 0.31 brightness against a
## shelf floor of 0.45 — and that is the *flattering* reading, because the number does not
## say that the screen of an all-ages comedy about surviving a work week was a dark
## corridor with a form on it.
##
## Two rules it broke outright:
##
##   studio rule 2, no code-drawn shapes: the two Glass panels WERE the design. A
##   StyleBoxFlat rectangle is not a surface that belongs to a world, it is the absence of
##   one — TITLE_SCREENS.md, "the absence of an idea looks exactly like a black panel,
##   because that is what it is." The panels are gone. Nothing on this screen is a drawn
##   rectangle except the type's own sticker outline, which is a letterform, not a box.
##
##   the all-ages direction (ops/adult_forks/UI_DIRECTION.md, and the memory "casual titles
##   want candy"): kids play this. The shelf it sells on is bright, saturated and sweet,
##   and our whole catalogue sat two to five times darker than it. The "study room at
##   night" mood belongs to the adult forks and to nothing here.
##
## The six items, and where each one is:
##
##   1. key visual   assets/art/plate_title_kv.webp — the joke the game is about, in one
##                   frame: she has thrown the week's paperwork in the air and is laughing
##                   at it. Full bleed. Nothing crops it (TITLE_SCREENS.md: "the key
##                   visual IS the screen"). ops/allages_title_art/allages_gen.py bm_title.
##   2. logotype     _draw_mark() — BEAT THE / MONDAY set in Lilita One as a candy sticker:
##                   a magenta under-shadow, a thick white keyline, a sunny-yellow body and
##                   a hot core, letter-spaced by hand and landing letter by letter. Never
##                   a Label (the old screen's was one).
##   3. motion       a slow push on the key visual with a sway against it, confetti falling
##                   the way it falls in the picture, the mark landing and then breathing,
##                   and a shine sweeping it every few seconds. Two to four seconds of life
##                   before anything is pressed.
##   4. styled menu  the buttons sit low in the composition, on the clear pink band under
##                   her, rather than stacked in a panel in the middle of the screen.
##   5. marks        ALL AGES and blazeCore Play, small, bottom. No 18+ and no Flat 404 —
##                   this is the mainstream track and Flat 404 is the adult label.
##   6. sound        Sfx.levelup() as the sting over the tap/hover cues the menu already has.
##
## Two engine rules this screen is built around, each bought with a burned day:
##
##   Shaders draw NOTHING on the Godot web export. Every gradient here — the sky lift
##   behind the mark, the warm foot the menu sits on — is generated into an Image and shown
##   through a TextureRect. Same pattern as play/after-six-godot/scripts/as_title.gd.
##
##   `expand` scales by the smaller of window/base, so the 390 px phone read is the one
##   that governs. Nothing here is sized in raw pixels without being checked against it.

signal start_pressed
signal desk_pressed
signal lang_pressed

const W := 420.0
const H := 640.0
const KV := "res://assets/art/plate_title_kv.webp"

var reduce_motion := false

var _clock := 0.0
var _kv: TextureRect
var _kv_base := Rect2()
var _settle := 0.0
var _shine := -1.0
var _shine_clock := 0.0
var _confetti: Array = []
## The node the mark and the confetti are painted on.
##
## NOT this Control's own _draw(). A CanvasItem paints itself and THEN its children, so
## anything drawn in the title node's own _draw() lands underneath the key visual that is
## its first child — the first build had the logotype invisible behind the picture for
## exactly that reason. A sibling added after the picture paints over it.
var _paint: Control
## Held fonts. main.gd's _install_cjk() sets CJK fallbacks on the three Latin FontFiles,
## and ResourceCache holds resources WEAKLY: a face this node draws with and does not keep
## a reference to is freed and re-read with no fallbacks the next time it is asked for. On
## the web export that is a screen of tofu boxes with no error anywhere. See as_title.gd's
## own _kept, and the memory "Godot web font fallback".
var _kept: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = StudioTheme.build()
	_kept.append(StudioTheme.font("display"))
	_kept.append(StudioTheme.font("bold"))
	_build_key_visual()
	_paint = Control.new()
	_paint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint.draw.connect(_paint_mark)
	add_child(_paint)
	_build_menu()
	_build_marks()
	Sfx.levelup()
	set_process(true)


# ---------- 1: the key visual, full bleed -------------------------------------------------
func _build_key_visual() -> void:
	_kv = TextureRect.new()
	_kv.texture = load(KV) if ResourceLoader.exists(KV) else null
	_kv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# COVERED, never SCALE: the plate is 832x1216 against a 420x640 canvas and the aspect
	# ratios are within 5% of each other, so this crops almost nothing — but it guarantees
	# the picture fills the frame on a window that is not exactly 420x640, which is every
	# window a browser ever gives us.
	_kv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Oversized so the push has somewhere to go without ever showing an edge.
	_kv_base = Rect2(Vector2(-W * 0.08, -H * 0.05), Vector2(W * 1.16, H * 1.12))
	_kv.position = _kv_base.position
	_kv.size = _kv_base.size
	_kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Draw order here is CHILD ORDER, never a negative z_index. The first build set
	# z_index = -40 on this node to put it behind the mark and the menu, and it went behind
	# the arena and the map as well — those live in the same canvas, so a negative z on a
	# child of the overlay sinks it below the whole game board. The captured frame was the
	# empty office floor with a logotype on it. The key visual is added first and every
	# other element after it, which is all the ordering this screen needs.
	add_child(_kv)

	# A lift under the mark, not a scrim over the picture. The top band of the key visual
	# is the cyan window between her raised arms; the mark sits on it, and this is a
	# *brightening* veil (white, low alpha, fading down) rather than the darkening one a
	# night title would use. It buys the white keyline its separation without spending any
	# of the frame's brightness, which is the whole quarrel UI_DIRECTION.md has with the
	# way this studio has been scrimming pictures.
	_grad_rect(Color(1, 1, 1, 0.34), Color(1, 1, 1, 0.0), Rect2(0, 0, W, 210.0))
	# and a warm foot for the menu: the pink band under her, pushed a little warmer and a
	# little denser so tangerine buttons and small type have a ground of their own.
	_grad_rect(Color(Palette.GOLD_PALE, 0.0), Color(Palette.GOLD_PALE, 0.30),
		Rect2(0, H - 250.0, W, 250.0))
	# and a short denser one right at the foot, so the studio mark has a ground of its own.
	# The picture has a sheet of white paper falling through exactly this band.
	_grad_rect(Color(Palette.GOLD_PALE, 0.0), Color(Palette.GOLD_PALE, 0.55),
		Rect2(0, H - 72.0, W, 72.0))


## A vertical gradient as an IMAGE, shown through a TextureRect.
##
## NOT a shader, and not negotiable: shaders draw nothing at all on the Godot web export —
## no error, no warning, just a missing element that looks fine in the editor. Two pixels
## wide and 128 tall is plenty; the TextureRect stretches it and the linear filter does the
## rest.
func _grad_rect(top: Color, bottom: Color, rect: Rect2) -> TextureRect:
	var n := 128
	var img := Image.create(2, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var t := float(y) / float(n - 1)
		var c := top.lerp(bottom, t)
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
	return tr


# ---------- 4: the menu, placed in the composition ----------------------------------------
func _btn(text: String, variation: String, at: Vector2, w: float, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.position = at
	b.custom_minimum_size = Vector2(w, 46)
	b.size = Vector2(w, 46)
	b.pressed.connect(Sfx.tap)
	b.pressed.connect(fn)
	b.mouse_entered.connect(Sfx.pickup)
	add_child(b)
	return b


func _build_menu() -> void:
	# Low, on the clear band under her, and NOT inside a panel. The old screen put these in
	# a Glass PanelContainer floating at y=330 — dead centre, over her, in a box.
	var x := W * 0.5 - 110.0
	_btn(BMStrings.t("cont") if _has_progress() else BMStrings.t("start"),
		"Primary", Vector2(x, H - 156.0), 220.0, func(): start_pressed.emit())
	_btn(BMStrings.t("locker"), "Amber", Vector2(x, H - 102.0), 142.0,
		func(): desk_pressed.emit())
	# Amber, not Ghost. The Ghost variation is a transparent box with MUTED slate type —
	# it was designed to sit on this game's dark PANEL and it is invisible the moment it
	# sits on a picture instead. The 390 px read had the language button as a faint grey
	# smudge on a pink wall. The approved reference (rebound-tycoon title_screen.gd) puts
	# its own language button in Amber for the same reason.
	_btn(BMStrings.t("lang"), "Amber", Vector2(x + 148.0, H - 102.0), 72.0,
		func(): lang_pressed.emit())


func _has_progress() -> bool:
	return Game.profile["cleared"].size() > 0 or int(Game.profile["week"]) > 0


# ---------- 5: the marks ------------------------------------------------------------------
func _build_marks() -> void:
	_band(BMStrings.t("sub"), 13, Palette.INK, 150.0)
	# ALL AGES, and the mainstream studio mark. No 18+ badge and no Flat 404 here — that is
	# the adult label, and ops/check_adsense_isolation.py is the proof that the two tracks
	# do not leak into one another.
	#
	# The gameplay hint ("Drag to move. You attack on your own.") that used to sit just
	# above this is gone from the title. It is an instruction about the arena, it was set
	# in small slate type directly on the picture where it could not be read at 390 px, and
	# the arena tells the player the same thing at the moment it is true. A title screen's
	# job is the first second, not the manual.
	# INK, not INK_SOFT, and lifted clear of the bottom edge. At 390 px the slate version
	# of this line was a grey smudge competing with a sheet of white paper in the picture
	# behind it — small type on a busy ground needs the darkest ink available, not a
	# politely muted one.
	_band("ALL AGES  ·  blazeCore Play", 11, Palette.INK, H - 40.0)


## A full-width centred line of type.
##
## Anchored rather than positioned. `label.size.x = W` is a write to a value the layout
## system owns and overwrites on the next resort: the first build set it that way and the
## studio mark came back clipped to the word "ALL", centred inside a box a few pixels wide.
## Anchoring left and right to the parent is the thing that actually holds.
func _band(text: String, size_px: int, color: Color, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Tag"
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size_px)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_left = 0.0
	l.offset_right = 0.0
	l.offset_top = y
	l.offset_bottom = y + size_px * 2.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


# ---------- 2: the logotype ---------------------------------------------------------------
## Letter widths plus a hand-set track, so the mark can be drawn letter by letter and each
## letter can land on its own beat. Same method as rebound-tycoon's logotype.gd.
func _letters(f: Font, text: String, sz: int, track: float) -> Array:
	var out: Array = []
	var total := 0.0
	for i in range(text.length()):
		var ch := text[i]
		out.append({"ch": ch, "w": f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x})
		total += out[i]["w"] + (track if i < text.length() - 1 else 0.0)
	return [out, total]


func _word(f: Font, text: String, sz: int, at: Vector2, track: float, color: Color,
		drop := Vector2.ZERO, delay := 0.0) -> void:
	var r := _letters(f, text, sz, track)
	var glyphs: Array = r[0]
	var x: float = at.x - float(r[1]) * 0.5
	for i in range(glyphs.size()):
		var g: Dictionary = glyphs[i]
		# each letter arrives on its own beat, dropping in rather than fading up: the mark
		# LANDS, which is the whole difference between a logotype and a caption
		var d := clampf((_settle - delay - i * 0.045) * 2.0, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - d, 3.0)
		var rise := (1.0 - e) * -26.0
		var a := color.a * e
		if a > 0.001:
			_paint.draw_string(f, Vector2(x, at.y + rise) + drop, str(g["ch"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(color, a))
		x += float(g["w"]) + track


## The sticker. Drawn back to front: a magenta under-shadow that gives the mark weight on a
## busy picture, a thick white keyline built by stamping the word eight times around a ring
## (Godot's draw_string has no stroke), the sunny-yellow body, and a hot highlight offset
## up. That stack — not a font choice — is what makes type read as a toy rather than as a
## caption, and it is the same treatment the approved reference uses in its own key.
func _draw_sticker(f: Font, text: String, sz: int, at: Vector2, track: float, delay: float) -> void:
	# TWO keylines, dark outside and white inside, and the order matters.
	#
	# The first build had the white ring only, and the 390 px phone read is what caught it:
	# a sunny-yellow body inside a white keyline, sitting on the pale paper and pale window
	# of its own key visual, is light type on a light ground with a lighter edge between
	# them. It survived on a monitor and dissolved on a phone.
	#
	# A grape ring OUTSIDE the white one fixes it without darkening the frame, because it
	# costs only the handful of pixels the letterform's edge occupies: whatever is behind
	# the mark, there is now a hard dark/light step at its boundary. This is the ordinary
	# sticker construction and it is the reason real casual-game logotypes read on any
	# background at any size.
	var ring := 3.0
	_word(f, text, sz, at, track, Color(Palette.ACCENT_DEEP, 0.5), Vector2(0, 8), delay)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		_word(f, text, sz, at, track, Color(Palette.INK, 0.95),
			Vector2(cos(a), sin(a)) * (ring + 2.6), delay)
	for i in range(12):
		var a2 := TAU * float(i) / 12.0
		_word(f, text, sz, at, track, Color(1, 1, 1, 1.0),
			Vector2(cos(a2), sin(a2)) * ring, delay)
	_word(f, text, sz, at, track, Palette.GOLD, Vector2.ZERO, delay)
	_word(f, text, sz, at, track, Color(Palette.GOLD_PALE, 0.9), Vector2(0, -2.5), delay)


func _paint_mark() -> void:
	var f := StudioTheme.font("display")
	var cx := W * 0.5
	# Two lines: the small one leads, the big one is the mark. "BEAT THE MONDAY" set on one
	# line at a size worth reading is 470 px wide on a 420 px canvas — it does not fit, and
	# shrinking it until it does is how a logotype becomes a caption.
	_draw_sticker(f, "BEAT THE", 30, Vector2(cx, 62.0), 4.0, 0.0)
	_draw_sticker(f, "MONDAY", 56, Vector2(cx, 122.0), 3.0, 0.18)

	# the shine: a soft diagonal band travelling across the mark once it has landed
	if _shine >= 0.0:
		var band := 54.0
		var span := W + band * 2.0
		var sx := -band + span * _shine
		for i in range(7):
			var t := float(i) / 6.0
			var a := sin(t * PI) * 0.30 * (1.0 - absf(_shine * 2.0 - 1.0) * 0.4)
			_paint.draw_line(Vector2(sx + t * band - 18.0, 24.0),
				Vector2(sx + t * band + 18.0, 156.0), Color(1, 1, 1, a), 7.0)

	# the confetti, falling the way it falls in the picture. Drawn as little rotating
	# quads rather than circles so it reads as paper.
	for c in _confetti:
		var p: Vector2 = c["p"]
		var w: float = c["w"]
		var h: float = w * (0.35 + absf(sin(c["t"] * c["spin"])) * 0.75)
		var col: Color = c["c"]
		var a: float = clampf(sin(clampf(c["t"] / c["life"], 0.0, 1.0) * PI) * 2.2, 0.0, 1.0)
		_paint.draw_rect(Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h)), Color(col, col.a * a))


# ---------- 3: motion ---------------------------------------------------------------------
func _process(dt: float) -> void:
	_clock += dt
	_settle = minf(1.6, _settle + dt)
	if reduce_motion:
		if _paint:
			_paint.queue_redraw()
		return

	# a slow push in with a sway against it — the camera breathing, not panning
	var push := 1.0 + (1.0 - exp(-_clock * 0.30)) * 0.045
	var sway := sin(_clock * 0.24)
	var bob := sin(_clock * 0.19 + 1.1)
	if _kv:
		_kv.position = _kv_base.position + Vector2(sway * 9.0, bob * 5.0)
		_kv.pivot_offset = _kv.size * 0.5
		_kv.scale = Vector2.ONE * push

	# the mark breathes once it has landed, and takes a shine every few seconds
	if _settle >= 1.6:
		if _shine >= 0.0:
			_shine += dt * 1.15
			if _shine > 1.0:
				_shine = -1.0
				_shine_clock = 0.0
		else:
			_shine_clock += dt
			if _shine_clock >= 4.4:
				_shine = 0.0

	# confetti. Capped, and spawned at a rate rather than on a timer, so the screen is
	# never still and never turns into a snowstorm.
	if _confetti.size() < 26 and randf() < dt * 9.0:
		var candy := [Palette.GOLD, Palette.ACCENT_SOFT, Palette.RARE, Palette.TUBE,
			Palette.SUCCESS, Palette.GOLD_PALE]
		_confetti.append({
			"p": Vector2(randf_range(-10.0, W + 10.0), randf_range(-40.0, -6.0)),
			"v": Vector2(randf_range(-14.0, 14.0), randf_range(26.0, 62.0)),
			"w": randf_range(5.0, 11.0), "spin": randf_range(1.6, 4.2),
			"life": randf_range(7.0, 12.0), "t": 0.0,
			"c": Color(candy[randi() % candy.size()], randf_range(0.65, 0.95))})
	var live: Array = []
	for c in _confetti:
		c["t"] += dt
		if c["t"] < c["life"] and c["p"].y < H + 30.0:
			# a little lateral drift, the way paper actually falls
			c["p"] += (c["v"] + Vector2(sin(c["t"] * c["spin"] * 0.5) * 16.0, 0.0)) * dt
			live.append(c)
	_confetti = live
	if _paint:
		_paint.queue_redraw()
