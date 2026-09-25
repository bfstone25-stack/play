class_name TitleScreen
extends Overlay
## OCCUPANCY — the title screen, as a composition rather than a dialog.
##
## ## What it replaces
##
## `SimpleScreens.Intro`: a centred PanelContainer holding a grey Tag label, a Title label,
## a 90-word paragraph of rules and one themed Button. That is the failure Blaze named on
## After Six — "a dark-mode office productivity app" — arrived at from the documentation
## direction instead of the atmosphere one. It broke four lines of
## `ops/adult_forks/TITLE_SCREENS.md` at once: no key visual, no designed logotype, no
## motion, and a menu whose buttons were code-drawn shapes, which is studio rule 2.
##
## ## Why it is still an Overlay
##
## It would have been tidier to make this its own scene and set `run/main_scene` to it.
## That would also have broken `tests/headless_web.py`, which boots the page, waits for the
## JS dev bridge to answer — and the bridge lives in `building.gd`, i.e. in the main scene
## — and then sends `start`, which reaches in through `intro.start.emit()`. A title screen
## in front of the main scene means the bridge does not answer until someone clicks a
## Godot button, and nothing in that test can click one.
##
## So this subclasses `Overlay` and keeps the whole of the contract `building.gd` and the
## bridge already use: `open()`, `close()`, `is_open()`, `closed`, and a `start` signal.
## The presentation is replaced; the wiring is untouched. `building.gd` changes by one
## word — `SimpleScreens.Intro.new()` becomes `TitleScreen.new()`.
##
## ## The brightness rule, which is the whole brief here
##
## Overtime Idle is the Nutaku bet: free browser idle/tycoon, staff gacha, Android. Idle is
## 30 of Nutaku's top 100, and that shelf averages 0.63 brightness / 0.38 saturation while
## our adult titles have been shipping 0.13-0.30. So every instinct this studio has built
## up on the noir forks is wrong here, and two of them are actively removed:
##
##   * `Overlay.dim` is a near-opaque ColorRect over the room (GROUND_DEEP at 0.84). On
##     every other panel that is correct — a dialog should sit on a darkened room. Here it
##     would darken the one thing the screen exists to show, so it is turned off entirely
##     and the key visual is the ground.
##   * There is NO vignette. After Six has one, at a deliberately reduced 0.56, and
##     `ops/adult_forks/UI_DIRECTION.md` still records it as darkness spent on wallpaper.
##     On a bright title it would be pure loss — the mark and the menu each carry their own
##     ground already (a baked contour and a foot scrim respectively), so there is nothing
##     for a vignette to buy.
##
## Check it with `python3 ops/check_brightness.py` against a captured frame, not against
## the key visual on its own: the composed screen is what ships.
##
## ## Layers, back to front, on the 1280x720 canvas
##
##   ground     a warm off-white, so a frame that fails to load is never a black hole
##   keyvisual  Mirei on her own floor in daylight, full bleed — it IS the screen, nothing
##              crops it. It breathes: a slow drift and a ~1.5% swell.
##   motes      warm dust drifting in the window light. Two sheets at different speeds,
##              and the layer that guarantees no two frames are identical.
##   scrim      a generated bottom gradient so light type reads at the foot. An Image and
##              a TextureRect, NOT a shader: shaders draw nothing at all on the Godot web
##              export, with no error (floor-13 and after-six both record it).
##   mark       OCCUPANCY / IDLE (ops/overtime_title.py). Settles in from above.
##   key        the lit key fob the primary action is set on — art, so rule 2 holds.
##   badge      the 18+ staff pass, hung in the corner.
##
## ## Type
##
## One family, Lilita One for the display and Nunito for running text — the same two files
## `ops/overtime_title.py` bakes the mark from, so rule 4 ("the buttons in the same type
## family and treatment") is true rather than claimed. The CJK fallback is held in `_kept`
## because a fallback set on a `load()`ed FontFile is freed on the web export and nowhere
## else, which renders boxes in zh and ja and looks fine on every desktop run (memory:
## `godot-web-font-fallback`).

signal start

const KV := "res://assets/title/keyvisual.webp"
## The old noir plate. It is a dark empty room with no subject — the thing this screen was
## built to stop opening on — and it is referenced ONLY so that a checkout without the
## rendered frame still runs. It must never be what ships; `_ready` says so in the log.
const KV_FALLBACK := "res://assets/art/title.webp"
const MARK := "res://assets/title/mark.png"
const KEY := "res://assets/title/play.png"
const BADGE := "res://assets/title/badge.png"
const DISPLAY := "res://assets/fonts/LilitaOne-Regular.ttf"
const TEXT := "res://assets/fonts/Nunito.ttf"

const W := 1280.0
const H := 720.0

## Where the type lives. Decided against the real frame, and moved three times getting
## there — the moves are the useful part, so they are written down rather than tidied away.
##
## 1. Mark top-CENTRE. The first bake had Mirei centred with her head at 29% of the frame,
##    so there was a band above her and the clearance came out at fifteen pixels.
## 2. Mark top-LEFT. The second bake — same prompt, corrected exposure — put her head at
##    5%, and a top-centre mark landed in her hair. So the generator was asked for
##    `subject on the right` to free the left column.
## 3. Mark BOTTOM-left, where it is now. Animagine ignored `subject on the right`: it
##    centres a solo subject, and on the evidence it will keep doing that at every seed.
##
## That third move is the one worth keeping. Steps 1 and 2 were both attempts to find a
## band the subject is not in, in a picture whose composition is decided by a sampler that
## does not take direction on where to put her. Every such band is one bad seed from being
## occupied. The foot of the frame is not: it is below the subject's waist in every cowboy
## shot, it is where the scrim already darkens the picture on purpose, and it is the one
## region whose contents this file controls.
##
## So the whole type block — mark, promise, action — sits in the lower-left quadrant on the
## scrim, and the upper two thirds are the picture and nothing else. The wordmark carries
## its own dark contour and bloom (ops/overtime_title.py), so it does not depend on the
## scrim being dark where it lands; the smaller type below it does, and is placed
## accordingly.
##
## MARK_RECT keeps the mark's own 2.4:1 aspect (the PNG is 1440x600). An earlier 560x150
## was 3.7:1 and silently stretched every letter 1.5x wide — a distortion that is
## invisible on a screenshot of a bold display face, which is why it survived a capture.
## If you change one number here, change the other to match.
## 2026-09-24: the store logotype (ops/nutaku/covers/logotypes.py) is 1090x274, 3.98:1,
## with its NOW LEASING genre line baked in; same width and bottom edge as before.
const MARK_RECT := Rect2(52, 472, 520, 131)

## The foot, set by where the scrim is actually dark rather than by taste. An earlier pass
## put the tagline at 11% into the ramp, where `f*f*0.62` is alpha 0.0075 — i.e. nothing,
## and light type with an outline sitting on bare desk detail. TAG_Y is now at 62% of a
## linear ramp (alpha ~0.55), and the action sits below it, darker again.
const SCRIM_TOP := 300.0
const TAG_Y := 560.0
const KEY_RECT := Rect2(92, 592, 260, 66)
const ROW_X := 100.0

var bg: TextureRect
var mark: TextureRect
var key: TextureRect
var scrim: TextureRect
var primary: Button
var t := 0.0
var _ready_to_start := false
var _kept: Array = []                    # held fonts: the web export frees unreferenced ones
var _built := false


func build() -> void:
	# Overlay.build() runs inside Overlay._ready(), after `dim`, `card` and `body` exist.
	#
	# The dim is the panel look and this screen is not a panel: at GROUND_DEEP/0.84 it
	# would put a near-black sheet over the key visual, which is the single thing the
	# brightness rule above is about. The card goes with it — everything here is a child
	# of the Overlay itself, composed at absolute positions, not stacked in a VBox.
	dim.color = Color(0, 0, 0, 0)
	dim.visible = false
	card.visible = false

	_compose()
	_built = true


## This screen loads its own faces rather than going through the Theme, because the mark
## and the promise are set in Lilita/Nunito at sizes the Theme does not define. That meant
## it also missed the CJK fallback StudioTheme hangs off those same files, so the Japanese
## tagline and the Japanese start button drew as empty boxes while every panel behind them
## was fine -- the one screen every player sees, and the one the shelf screenshot is of.
## The fallback is attached here too, and both resources go into `_kept`.
func _font(path: String) -> Font:
	var f: Font = load(path)
	if f == null:
		return ThemeDB.fallback_font
	var cjk := Cjk.face()
	if cjk and f is FontFile:
		f.fallbacks = [cjk]
		_kept.append(cjk)
	_kept.append(f)
	return f


func _compose() -> void:
	var ground := ColorRect.new()
	# Warm off-white rather than the game's GROUND_DEEP. If the key visual ever fails to
	# load, the screen is a bright empty room and not a black hole — and on a title whose
	# whole job is "bright and inviting", the failure mode should fail in the right
	# direction.
	ground.color = Color("#f3ece0")
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	var kv := KV if ResourceLoader.exists(KV) else KV_FALLBACK
	if kv == KV_FALLBACK:
		push_warning("TitleScreen: no %s — falling back to the OLD NOIR PLATE. "
			% KV + "That frame is an empty dark room and must not ship; "
			+ "render ops/overtime_art/overtime_gen.py plates --only oi_title_kv")
	if ResourceLoader.exists(kv):
		bg.texture = load(kv)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.size = Vector2(W, H)
	bg.pivot_offset = Vector2(W / 2.0, H / 2.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Dust in the window light. Warm and slow: on the noir forks this layer is city lights
	# on glass, which is the same mechanism doing the opposite job.
	add_child(_motes(6, 11.0, 0.15, 30, Color("#fff0cf")))
	add_child(_motes(3, 19.0, 0.11, 38, Color("#ffffff")))

	# 2026-09-23, adult title pass: the foot scrim is still built (the intro tween
	# references it) but never shown -- a generated darkening laid under the type is the
	# one thing 0 of 33 Nutaku tiles do (ops/market/ADULT_SHELF_TITLES.md). The mark's
	# own outline and bevel hold it on the plate. The key-fob picture is gone with it: the
	# start control is an ObjectButton now (below).
	scrim = _scrim()
	scrim.visible = false
	mark = _picture(MARK, MARK_RECT)
	key = TextureRect.new()

	_menu()
	_badge()
	_studio()
	_lang()


func _picture(path: String, rect: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	else:
		push_warning("TitleScreen: missing %s — run python3 ops/overtime_title.py" % path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## The bottom gradient the menu is set on. Transparent at SCRIM_TOP and strongest at the
## foot, so the picture runs out rather than stopping at an edge — TITLE_SCREENS.md, "the
## surface must not eat the picture". Generated into an Image and drawn as a TextureRect:
## a shader draws NOTHING on the Godot web export, with no error and nothing in the log.
##
## It is warm brown at a low peak (0.62), not the near-black the noir titles use. Over a
## daylit picture a cold dark scrim reads as a bruise; this reads as the floor falling into
## shadow, which is a thing rooms do.
func _scrim() -> TextureRect:
	var h := int(H - SCRIM_TOP)
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var f := float(y) / float(h - 1)
		# LINEAR, and the exponent is the whole story. It was f*f, then pow(f, 1.5), and
		# both were set by eye; the frame was then measured, by sampling a column of the
		# real capture down the band, and pow(f, 1.5) * 0.80 turned out to put alpha 0.31
		# under the tagline — which took a mean luminance of 229 down to 196. Light type
		# on 196 is light type on a bright picture, outline or no outline.
		#
		# A straight ramp over a band that starts higher gets alpha ~0.55 there (mean ~120,
		# which light type reads on cleanly) while still beginning at zero, so the picture
		# still runs out rather than stopping at a visible edge. Re-measure if you touch
		# either number: sample the capture, do not look at it and decide.
		img.set_pixel(0, y, Color(0.15, 0.09, 0.05, f * 0.88))
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


## Soft round motes drifting across the frame. CPUParticles2D rather than a shader, for
## the same reason the scrim is a texture.
func _motes(size: int, speed: float, alpha: float, count: int, tint: Color) -> CPUParticles2D:
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
	p.lifetime = 30.0
	# Without preprocess the screen opens on an empty frame and fills up over half a
	# minute, so the first thing a player sees is the one frame with no motion in it.
	p.preprocess = 30.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40, 210)
	p.position = Vector2(-40, 300)
	p.direction = Vector2(1.0, -0.05)
	p.spread = 8.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.modulate = Color(tint.r, tint.g, tint.b, alpha)
	return p


# ---------------------------------------------------------------------------------------
## The menu. Two actions and no third.
##
## The Intro this replaces said everything at once: a 90-word paragraph covering the tick,
## the rent, eviction, the gacha, two plate ladders and the adults statement, in front of a
## player who has not seen the game yet. None of it survives here as body copy — the game
## teaches its own loop and the store page carries the pitch. One line of promise, two
## actions, and the compliance line at the foot where it belongs.
func _menu() -> void:
	var tag := Label.new()
	tag.text = I18n.t("tagline")
	tag.position = Vector2(ROW_X, TAG_Y)
	tag.size.x = W - ROW_X * 2
	tag.add_theme_font_override("font", _font(TEXT))
	tag.add_theme_font_size_override("font_size", 17)
	tag.add_theme_color_override("font_color", Color("#ffe9c4"))
	tag.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03, 0.85))
	tag.add_theme_constant_override("outline_size", 6)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	# The primary action. Its form is the lit key fob behind it (KEY_RECT) — the Button
	# itself has no fill, no border and no corner radius in any state, which is studio
	# rule 2: a button on a title screen takes its shape from art or it has no shape.
	# 2026-09-23: the start control is her red lipstick in its gold case, not a gold key
	# fob (keys are Office Landlord's, the all-ages twin, and the two worlds must not share
	# props). ObjectButton: the object with the label beside it, no box. GPU render, cut
	# out with rembg; the first O of the mark is her powder compact, same route.
	primary = ObjectButton.new()
	primary.text = I18n.t("start")
	primary.object_texture = load("res://assets/title/btn_lipstick.png")
	primary.object_size = 66.0
	primary.motion = ObjectButton.Motion.TURN
	primary.label_color = Color("#fff1d6")
	primary.accent_color = Color("#ff8a8a")
	primary.ink = Color(0.12, 0.03, 0.03, 1.0)
	primary.outline_px = 5
	primary.shadow_px = 0
	primary.add_theme_font_override("font", _font(DISPLAY))
	primary.add_theme_font_size_override("font_size", 26)
	primary.position = KEY_RECT.position + Vector2(0, -4)
	primary.custom_minimum_size = Vector2(380, 70)
	primary.focus_mode = Control.FOCUS_NONE
	primary.pressed.connect(_begin)
	add_child(primary)

	# There is no second row, and that is a decision rather than an omission.
	#
	# The Intro this replaces had exactly one button too — OPEN THE BUILDING — under a
	# 90-word paragraph explaining the tick, the rent, eviction, the gacha and two plate
	# ladders to a player who had not yet seen a floor. A draft of this screen kept that
	# copy behind a "HOW THE FLOOR PAYS" toggle; it is gone as well. An idle game teaches
	# its loop by running, the store page carries the pitch, and a title screen that
	# explains itself is the "looks like a document" read arrived at from the third
	# direction. One promise, one action, and the compliance line at the foot.



## Strip a Button of every shape it has, in every state — studio rule 2, enforced rather
## than trusted. The primary action's form comes from the key fob art behind it; the Button
## is a hit box with type in it and nothing else.
func _shapeless(b: Button) -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.content_margin_left = 6
	flat.content_margin_right = 6
	flat.content_margin_top = 2
	flat.content_margin_bottom = 2
	# EVERY state, not just `normal`. Godot's default theme gives a Button a filled,
	# rounded, bordered StyleBox in normal/hover/pressed/focus/disabled, and leaving any
	# one of them is how a code-drawn pill reappears on hover only — which a still
	# screenshot cannot catch, because a capture has no pointer in it.
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, flat)
	b.mouse_entered.connect(func() -> void: Sfx.tick())


func _lift(node: TextureRect, to: float) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	create_tween().tween_property(node, "scale", Vector2(to, to), 0.14) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The rating, hung in the corner as an object.
## TITLE_SCREENS.md: "the 18+ badge belongs to an object". A grey Tag label above a
## paragraph — which is exactly what the Intro had — is what a settings page looks like.
## On a game whose economy is hiring staff, the thing that carries a rating is a staff
## pass, and it costs nothing to say so.
func _badge() -> void:
	var b := _picture(BADGE, Rect2(W - 124, 22, 96, 124))
	b.pivot_offset = Vector2(48, 6)
	# it hangs, very slightly, and settles
	create_tween().tween_property(b, "rotation", 0.0, 1.6).from(-0.09) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.7)


func _studio() -> void:
	var s := Label.new()
	# The adult label, not blazeCore Play: this is an 18+ title. TITLE_SCREENS.md reserves
	# the bare studio mark for the mainstream builds.
	#
	# The adults statement rides with it rather than in a paragraph nobody reads. It is a
	# compliance line for Nutaku and DLsite, it was in the Intro's body copy, and dropping
	# it while deleting that paragraph would have been a quiet regression — so it is here,
	# small, permanent, and on the screen every player sees.
	s.text = I18n.t("footer")
	s.position = Vector2(0, H - 30)
	s.size.x = W - 28
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	s.add_theme_font_override("font", _font(TEXT))
	s.add_theme_font_size_override("font_size", 13)
	s.add_theme_color_override("font_color", Color(0.97, 0.93, 0.86, 1.0))
	s.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03, 0.85))
	s.add_theme_constant_override("outline_size", 5)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)


# ---------------------------------------------------------------------------------------
## TITLE_SCREENS.md item 3: two to four seconds of life before anything is pressed. The
## room alone for a beat, then the mark comes down, then the key and the menu arrive under
## it.
##
## Overlay.open() calls on_open() once its own tween is running; that tween animates `card`,
## which is invisible here, so it is harmless and this is the real entrance.
func on_open() -> void:
	if not _built:
		return
	# EVERY property here animates with .from(), and NOTHING is set to alpha 0 outside a
	# tween. That is a bug fix, not a style: After Six's zh title screen came up as a
	# picture with a mark and NO MENU AT ALL, because the screen was rebuilt mid-entrance
	# and the code had already written modulate.a = 0 to elements the interrupted tween
	# never brought back. With .from(), the resting state of every element is VISIBLE and
	# the animation is the only thing that can be lost. A screen that fails to animate is
	# a screen; a screen that fails to appear is a bug report.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mark, "modulate:a", 1.0, 1.0).from(0.0).set_delay(0.35) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(mark, "position:y", MARK_RECT.position.y, 1.2) \
		.from(MARK_RECT.position.y - 18.0).set_delay(0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(scrim, "modulate:a", 1.0, 0.9).from(0.0).set_delay(0.8)
	tw.tween_property(key, "modulate:a", 1.0, 0.8).from(0.0).set_delay(1.05)
	tw.tween_property(key, "position:y", KEY_RECT.position.y, 1.0) \
		.from(KEY_RECT.position.y + 14.0).set_delay(1.05) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if primary != null:
		tw.tween_property(primary, "modulate:a", 1.0, 0.7).from(0.0).set_delay(1.25)
	# Armed when the key fob has finished arriving -- see _begin() for why the whole screen
	# is a hit box from that moment on.
	tw.chain().tween_callback(func() -> void: _ready_to_start = true)


func _process(delta: float) -> void:
	if not is_open() or bg == null:
		return
	t += delta
	# the breathing camera — a drift you would not notice if you were told to look for it
	bg.position = Vector2(sin(t * 0.10) * 6.0, cos(t * 0.075) * 4.0)
	var swell := 1.06 + 0.016 * sin(t * 0.17)
	bg.scale = Vector2(swell, swell)
	# Daylight moving, not a lamp breathing: a much smaller amplitude and centred on 1.0
	# rather than under it. The noir titles dip to 0.93 and the dip is the effect; here any
	# dip is brightness spent for nothing.
	var sun := 1.0 + 0.030 * sin(t * 0.43) + 0.012 * sin(t * 1.3)
	bg.modulate = Color(sun, sun * 0.995, sun * 0.975)


# ---------------------------------------------------------------------------------------
## The language control.
##
## It is a rent stub like every other button in this game (studio rule 4), and it is small
## and in the corner opposite the key: the player who needs it is looking for it, and the
## player who does not should not have a second lit object competing with OPEN THE
## BUILDING. It shows the language it will switch TO, in that language's own name -- a
## picker labelled in a script you cannot read is not a picker.
##
## Changing language RELOADS THE SCENE, and that is deliberate rather than lazy. Half this
## game's text is baked into Labels at build time: the HUD bar, the floor strip, the tray,
## the six overlays' tags and titles. A `changed` signal that only repainted what it could
## reach would leave a Japanese title screen in front of an English HUD, which is worse
## than not offering the language. The building's whole state lives in user:// (Ticker and
## Economy both save on every change), so a reload costs nothing but this animation, and it
## lands the player back on the title screen in the language they just picked -- which is
## where they were standing when they pressed it.
func _lang() -> void:
	# an outlined word, not a dark stub: a settings word does not need a prop, and it
	# does not need a box either
	var b := ObjectButton.new()
	b.text = I18n.ENDONYM[_next_lang()]
	b.object_size = 0.0
	b.gap = 0.0
	b.label_color = Color("#fff1d6")
	b.accent_color = Color("#ff8a8a")
	b.ink = Color(0.12, 0.03, 0.03, 1.0)
	b.outline_px = 4
	b.shadow_px = 0
	b.custom_minimum_size = Vector2(150, 40)
	b.add_theme_font_size_override("font_size", 18)
	b.position = Vector2(W - 178, H - 82)
	b.size = b.custom_minimum_size
	b.pressed.connect(func() -> void:
		Sfx.tick()
		I18n.set_lang(_next_lang())
		StudioTheme.reset_fonts()
		# The Theme is the tree root's, so it has to be replaced as well as rebuilt: the
		# old one holds the old language's FontFiles and nothing else would drop them.
		Look.rebuild()
		get_tree().reload_current_scene())
	add_child(b)


func _next_lang() -> String:
	var l: Array = I18n.LANGS
	return str(l[(l.find(I18n.lang) + 1) % l.size()])


# ---------------------------------------------------------------------------------------
## Starting the game, from the key fob OR from anywhere on the picture.
##
## This is the most expensive thing learned on this title, so it is written down in full.
##
## The per-game matrix (ops/play_driver.py + ops/play_matrix.py) came back with EIGHTEEN
## distinct stages, and all eighteen were this title screen: the parallax swell moves
## enough pixels between captures to clear the 6% "this is a new stage" threshold, so a
## game that never started photographed as a game with eighteen stages. Item 1 of
## STANDARD.md says one tile means broken; it does not say that eighteen tiles of the same
## tile means broken, and it does. The number was not evidence of anything.
##
## The cause was geometry. KEY_RECT sits at (92, 592) — the lower-LEFT corner, because the
## wordmark and the promise live in the one band of this picture that the sampler does not
## put the subject in. The driver presses the centre column and the bottom action row,
## which is where every other game in the studio keeps its verbs, and there is nothing
## under any of those points here. It pressed the picture eleven times and photographed a
## woman standing in an office.
##
## The fix is not to move the key fob into the middle of her face. A browser player who
## sees a still picture with a start button on it clicks the PICTURE — that is what a
## title screen is for — and an idle game that answers a click on the picture with nothing
## at all has spent its first five seconds teaching the player that the game is not
## responding. So: the whole screen takes the press, Enter and Space take it too, and the
## key fob stays exactly where the composition wants it as the thing that SAYS so.
##
## The guard is the entrance animation, not a timer someone picked: `_ready_to_start` is
## armed when on_open()'s tween finishes, which is the moment the key fob has finished
## arriving. Before that a press would cut off the two seconds of life that TITLE_SCREENS
## item 3 asks for; after it, every input opens the building.
func _begin() -> void:
	if not _open or not _ready_to_start:
		return
	_ready_to_start = false
	Sfx.unlock()
	start.emit()
	close()


## The mouse and the keyboard arrive by two different doors, and the mouse's is the one
## that is easy to get wrong. `Overlay._ready()` sets `mouse_filter = STOP` on this
## Control, so a click on the picture is consumed as GUI input and NEVER reaches
## `_unhandled_input` -- an any-click handler written only there compiles, runs, and does
## nothing, which is the same silent-success shape as everything else in this file's
## history. Clicks are taken in `_gui_input`; keys, which are not routed by mouse_filter,
## in `_unhandled_input`. The Buttons on this screen (the key fob, the language stub) are
## children and consume their own presses first, so neither path double-fires.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_begin()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_begin()
