extends Control
## Title — SUASION's first second, as a composition.
##
## What it replaces. Nothing: this game had no title screen. `scenes/main.tscn` is a bare
## Control and `main.gd` ended `_ready()` with `go("duel" if state.duel else "home")`, so
## the player's first frame was a HUD and a roster of five faces.
## ops/adult_forks/TITLE_SCREENS.md lists this title in the row whose key-visual, logotype
## and palette cells are empty with the note "(their own passes carry it)"; this is that
## pass, and it is the sixth item of that file's checklist as much as the first — the
## screen a store page screenshots.
##
## The fantasy it has to sell in one second is the fork's own rule, and the rule is not
## "cards with girls in them": **coercion loses the duel outright.** Not loses points —
## loses. The person across the table has a reason to say no and it is a good one, and the
## whole game is being worth a yes. So the key visual is Mara mid-deal, looking straight at
## you, amused and entirely unhurried, with the shutter already down behind her. She is not
## available; she is interested. That is a different picture from a pin-up and it is the
## one that matches what the player is about to do.
##
## Layers, back to front:
##
##   ground     Palette.GROUND, so nothing anywhere is a hole.
##   keyvisual  Mara at the counter. Full bleed — it IS the screen, nothing crops it
##              (TITLE_SCREENS.md, "the surface must not eat the picture"). It breathes.
##   motes      two sheets of warm dust drifting across the lamp, additive, gold and
##              magenta. Also what guarantees no two frames are identical.
##   vignette   a radial darkening baked once into an Image. NOT a shader: shaders drew
##              nothing at all on the sibling titles' web exports.
##   scrim      a generated left-hand gradient. The type column is on the LEFT here rather
##              than at the foot, because the canvas is 1280x720 landscape and a bottom
##              scrim on a 16:9 frame either eats the subject or leaves no room. It is a
##              gradient and not a panel: TITLE_SCREENS.md rejected Late Inspection's hard
##              50/50 split as "a picture beside a form", and the fix there was that the
##              picture stays full bleed and the type sits OVER it.
##   mark       SUASION in gold foil + SILVERTONGUE · CARDS (ops/silvertongue_title.py).
##   card       the card back, tilted, carrying the 18+ in its rank corner and the studio
##              mark. It slides in from the right edge like a card being dealt.
##
## Studio rule 2: no button here has a shape of its own. A menu row's form is the foil
## rule drawn beside it and the type on it; hover lights it and thickens the magenta bar.
class_name TitleScreen

const KV := "res://assets/title/keyvisual.webp"
const MARK := "res://assets/title/mark.png"
const CARD := "res://assets/title/card.png"

## The design canvas. Every number below is a FRACTION of it, resolved in _layout()
## against the node's real rect — the sibling fork shipped two captures laid out against
## hard-coded pixels before anyone noticed the canvas was not the size it assumed.
const W := 1280.0
const H := 720.0

const MARK_RECT := Rect2(56.0 / W, 132.0 / H, 620.0 / W, 207.0 / H)
const CARD_RECT := Rect2(1022.0 / W, 366.0 / H, 232.0 / W, 303.0 / H)
const SCRIM_W := 0.62
const TAG_Y := 372.0 / H
const ROW_TOP := 440.0 / H
const ROW_H := 74.0 / H
const ROW_X := 62.0 / W
const ROW_W := 520.0 / W
const HINT_Y := 600.0 / H

var main: Node
var w := W
var h := H
var bg: TextureRect
var mark: TextureRect
var card: TextureRect
var scrim: TextureRect
var _ground: ColorRect
var _vig: TextureRect
var tagline: Label
var rows: Array[Button] = []
var hint: Label
var t := 0.0
var _sel := 0


func _r(rt: Rect2) -> Rect2:
	return Rect2(rt.position.x * w, rt.position.y * h, rt.size.x * w, rt.size.y * h)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# STOP, not IGNORE. The screen itself has to be able to catch a click, and for two
	# separate reasons — see _gui_input and _unhandled_key_input below. The rows are
	# children and still get the clicks that land on them; this only picks up the ones
	# that land on the picture.
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_process_unhandled_key_input(true)
	_measure()
	_build()
	_compose()
	resized.connect(_layout)
	call_deferred("play_in")


## 2026-09-21. The play board scored this game BROKEN for the second time, and the second
## time the build was genuinely fine: offline play worked, the title drew, the art was
## there. Twenty interactions later it was still on the title, because of two holes that
## are only visible when something that is not a mouse-owning human tries to play.
##
##   * **Nothing on this screen answers the keyboard.** Both rows are FOCUS_NONE — which
##     is right, focus rectangles would wreck the composition — but nothing was put in
##     their place, so Space, Enter and the arrows fell through to no one. A title screen
##     that cannot be started from the keyboard is not a stylistic choice, it is a screen
##     a player with no mouse cannot get past.
##   * **The menu column is nowhere near the middle.** The type column is on the LEFT
##     (x 62..582, y 440..588 of 1280x720) for the composition reasons in the header, and
##     every coordinate a generic driver tries is in the centre or the bottom strip. Not
##     one of them lands in that box. The same is true of a player who clicks the picture
##     because the picture is the thing that looks pressable.
##
## So: any key starts, the arrows walk the rows, and a click anywhere that is not a row
## starts as well. None of it changes what the rows do or how they look.
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_activate(0)


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	match ev.keycode:
		KEY_UP, KEY_LEFT:
			_select(_sel - 1)
		KEY_DOWN, KEY_RIGHT:
			_select(_sel + 1)
		KEY_ESCAPE:
			return
		_:
			# Any other key — Space, Enter, a letter — takes the selected row. "Press any
			# key" has to mean any key, or it is one more thing to guess at.
			_activate(_sel)
	get_viewport().set_input_as_handled()


## Highlight without focus: the row's own hover stylebox, so the keyboard and the mouse
## show the player the same thing.
func _select(i: int) -> void:
	if rows.is_empty():
		return
	_sel = wrapi(i, 0, rows.size())
	for n in rows.size():
		# Only the colour, never the alpha: play_in() is tweening modulate:a from 0 on
		# these same nodes, and writing a whole Color here would snap the intro to
		# full opacity — the class of bug the header warns about two paragraphs up.
		var k: float = 1.0 if n == _sel else 0.82
		rows[n].modulate = Color(k, k, k, rows[n].modulate.a)
	if Sfx.has_method("hover"):
		Sfx.hover()


func _activate(i: int) -> void:
	if rows.is_empty() or i < 0 or i >= rows.size():
		return
	Sfx.play("ui_click")
	rows[i].emit_signal("pressed")


func _measure() -> void:
	var r := size
	if r.x < 2.0 or r.y < 2.0:
		r = get_viewport_rect().size
	if r.x < 2.0 or r.y < 2.0:
		r = Vector2(W, H)
	w = r.x
	h = r.y


func _layout() -> void:
	_measure()
	for n in [_ground, _vig, bg]:
		if n != null:
			n.size = Vector2(w, h)
	if bg != null:
		bg.pivot_offset = Vector2(w / 2.0, h / 2.0)
	if scrim != null:
		scrim.size = Vector2(w * SCRIM_W, h)
	for pair in [[mark, MARK_RECT], [card, CARD_RECT]]:
		var n: TextureRect = pair[0]
		if n != null:
			var rr := _r(pair[1])
			n.position = rr.position
			n.size = rr.size
	if tagline != null:
		tagline.position = Vector2(ROW_X * w, TAG_Y * h)
		tagline.size.x = ROW_W * w
	if hint != null:
		hint.position = Vector2(ROW_X * w, HINT_Y * h)
	for i in rows.size():
		rows[i].position = Vector2(ROW_X * w, ROW_TOP * h + i * ROW_H * h)
		rows[i].size = Vector2(ROW_W * w, ROW_H * h - 8.0)
		rows[i].custom_minimum_size = rows[i].size


func _build() -> void:
	_ground = ColorRect.new()
	_ground.color = Palette.GROUND
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

	add_child(_motes(6, 9.0, 0.15, 26, Palette.GOLD_PALE))
	add_child(_motes(4, 15.0, 0.11, 30, Palette.ACCENT_SOFT))

	_vig = TextureRect.new()
	_vig.texture = _vignette()
	_vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vig.stretch_mode = TextureRect.STRETCH_SCALE
	_vig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_vig.size = Vector2(w, h)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vig)

	scrim = _scrim()
	# 2026-09-23: built for the layout code, not shown -- 0 of 33 Nutaku tiles darken the
	# picture under the type; the rows are objects with outlined words.
	scrim.visible = false
	mark = _picture(MARK, _r(MARK_RECT))
	card = _picture(CARD, _r(CARD_RECT))


func _picture(path: String, rect: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## Warm dust across the lamp. CPUParticles2D rather than a shader, for the same reason the
## vignette is a texture: on the sibling forks' web exports a shader drew nothing at all
## while a plain texture dropped in beside it painted fine.
func _motes(sz: int, speed: float, alpha: float, count: int, tint: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var d := sz * 2
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
	p.emission_rect_extents = Vector2(w * 0.06, h * 0.34)
	p.position = Vector2(-w * 0.04, h * 0.48)
	p.direction = Vector2(1.0, -0.05)
	p.spread = 7.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.modulate = Color(tint.r, tint.g, tint.b, alpha)
	return p


## The left-hand gradient the type column is set on. Opaque-ish at the very edge, gone by
## SCRIM_W — so the picture runs THROUGH it rather than stopping at a seam. That is the
## whole difference between this and the hard 50/50 split TITLE_SCREENS.md rejected as
## "a picture beside a form": the bar behind her stays visible all the way across.
func _scrim() -> TextureRect:
	var n := 160
	var img := Image.create(n, 1, false, Image.FORMAT_RGBA8)
	for x in n:
		var u := float(x) / float(n - 1)
		var a: float = clampf(1.0 - u, 0.0, 1.0)
		# 0.62 and a steeper falloff, not 0.90 and a square. The composed title measured
		# 0.51 brightness / 0.30 saturation against the fantasy/battle floor of 0.60 /
		# 0.38, and a 90%-opaque near-black wash over the left 62% of the frame was the
		# single largest reason: it is most of the picture, and what it covers is the
		# lit end of the bar. The type keeps its 6-7px outline, which the note above says
		# is what carried it on this ground in the first place, so legibility does not
		# depend on the scrim being heavy — only on it being there.
		img.set_pixel(x, 0, Color(Palette.GROUND.r, Palette.GROUND.g, Palette.GROUND.b,
			pow(a, 2.4) * 0.62))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = Vector2.ZERO
	tr.size = Vector2(w * SCRIM_W, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## Deliberately light — 0.46 at the corners. There is no type set directly on the picture
## (the mark is a baked foil plate and the menu has the scrim), so a heavy vignette would
## be spending the whole budget of darkness on wallpaper, which
## ops/adult_forks/UI_DIRECTION.md names as this studio's recurring failure: "a product
## whose every screen sits at 0.2 has spent its whole budget of darkness on wallpaper."
func _vignette() -> ImageTexture:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := Vector2(x / float(n - 1) - 0.5, y / float(n - 1) - 0.5) * 2.0
			var r: float = clampf(u.length() / 1.42, 0.0, 1.0)
			# Lighter again (0.30 from 0.46) for the same measurement, and for the reason
			# already written three lines up: the budget of darkness is not to be spent
			# on wallpaper. A vignette this light still seats the frame.
			img.set_pixel(x, y, Color(Palette.GROUND_DEEP.r, Palette.GROUND_DEEP.g,
				Palette.GROUND_DEEP.b, clampf(r * r * 0.30, 0.0, 0.44)))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------------------
func _compose() -> void:
	# Blaze's own sentence for this fork, not a description of the UI. TITLE_SCREENS.md on
	# After Six: the menu "stopped describing its own UI" and the tagline became the line
	# the game is actually about.
	# Palette.MUTED on a lit picture is not a colour, it is camouflage: the first capture
	# put this line in mauve across a backlit whisky bottle and it vanished completely.
	# The menu rows survived the same ground only because they carry a 7 px outline, and
	# this line needs the same — ops/adult_forks/TITLE_SCREENS.md is explicit that the
	# check is to READ the captured frame, and this was the one element that failed it.
	tagline = StudioTheme.serif_label("She has every reason to say no.", 21, Palette.CREAM)
	tagline.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	tagline.add_theme_constant_override("outline_size", 6)
	tagline.position = Vector2(ROW_X * w, TAG_Y * h)
	tagline.size.x = ROW_W * w
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tagline)

	# Two actions, and neither is called "Start". The first is what the game is; the
	# second is the collection, which on an F2P card title is the other half of the loop.
	rows.append(_row("SIT DOWN ACROSS FROM HER", func(): _start(), 0, true))
	rows.append(_row("WHO YOU HAVE PERSUADED", func(): _go("affection"), 1, false))
	for b in rows:
		add_child(b)

	# Loc has carried "PRESS ANY KEY" in all three languages since the day the screen was
	# written and nothing ever drew it. It is drawn now, because it is true now: it is the
	# instruction for the keyboard path added above, and it is the one line on this screen
	# that tells a player who has not found the left column that there is a way in.
	hint = StudioTheme.mono_label(Loc.t("PRESS ANY KEY"), 11, Palette.MUTED)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint.add_theme_constant_override("outline_size", 5)
	hint.position = Vector2(ROW_X * w, HINT_Y * h)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	_select(0)


func _row(text: String, fn: Callable, index: int, lead: bool) -> Button:
	# 2026-09-23, adult title pass: OBJECTS with the words beside them, not a foil rule
	# with a hover plate (ops/STANDARD.md, "Buttons are objects from the game"). Sitting
	# down across from her is her whisky glass; who-you-have-persuaded is the deck. GPU
	# renders cut out with rembg. The O of the mark is a chip, same route.
	var b := ObjectButton.new()
	b.text = text
	var tex := "res://assets/title/btn_whisky.png" if lead else "res://assets/title/btn_deck.png"
	if ResourceLoader.exists(tex):
		b.object_texture = load(tex)
	b.object_size = 70.0 if lead else 52.0
	b.gap = 14.0
	b.motion = ObjectButton.Motion.TURN
	b.label_color = Palette.GOLD_PALE if lead else Palette.TEXT
	b.accent_color = Color(1, 1, 1)
	b.ink = Color(0, 0, 0, 0.9)
	b.outline_px = 5
	b.shadow_px = 0
	b.add_theme_font_override("font", StudioTheme.font("display"))
	b.add_theme_font_size_override("font_size", 30 if lead else 22)
	b.position = Vector2(ROW_X * w, ROW_TOP * h + index * ROW_H * h)
	b.custom_minimum_size = Vector2(ROW_W * w, ROW_H * h - 8.0)
	b.size = b.custom_minimum_size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_entered.connect(func(): _select(index))
	b.pressed.connect(fn)
	return b


## Resume-aware, and deliberately the exact expression main.gd used before this screen was
## put in front of it: a player with a duel in flight is returned to that duel rather than
## to the roster. Moving the title in front of the game must not change what the game
## does when it starts.
func _start() -> void:
	_go("duel" if main != null and main.state.get("duel") else "home")


func _go(name: String) -> void:
	if main != null and main.has_method("go"):
		main.go(name)


func setup(_args: Dictionary) -> void:
	pass


# ---------------------------------------------------------------------------------------
## Two to four seconds of life before anything is pressed (TITLE_SCREENS.md item 3): the
## bar alone for a beat, the mark settles in, the card is DEALT in from the right edge,
## then the menu.
##
## Every property animates with .from() and nothing is set to alpha 0 outside the tween,
## so the resting state of every element is VISIBLE and only the animation can be lost.
## The sibling title shipped a language variant with a mark and no menu because its intro
## tween was interrupted after the code had already written modulate.a = 0 to the rows;
## a screen that fails to animate is a screen, a screen that fails to appear is a bug.
func play_in() -> void:
	if mark == null:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	var my := MARK_RECT.position.y * h
	tw.tween_property(mark, "modulate:a", 1.0, 1.0).from(0.0).set_delay(0.4) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(mark, "position:y", my, 1.2).from(my + 18.0).set_delay(0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var cx := CARD_RECT.position.x * w
	tw.tween_property(card, "modulate:a", 1.0, 0.5).from(0.0).set_delay(1.15)
	tw.tween_property(card, "position:x", cx, 0.85).from(cx + w * 0.22).set_delay(1.15) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(tagline, "modulate:a", 1.0, 0.8).from(0.0).set_delay(1.3)
	for i in rows.size():
		tw.tween_property(rows[i], "modulate:a", 1.0, 0.7).from(0.0).set_delay(1.55 + i * 0.12)
	if hint != null:
		tw.tween_property(hint, "modulate:a", 1.0, 0.7).from(0.0).set_delay(1.9)
	if Sfx.has_method("deal"):
		Sfx.deal()
	elif Sfx.has_method("flip"):
		Sfx.flip()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	bg.position = Vector2(sin(t * 0.10) * 7.0, cos(t * 0.077) * 4.5)
	var swell := 1.05 + 0.012 * sin(t * 0.19)
	bg.scale = Vector2(swell, swell)
	# the pendant lamp breathing — one slow warm rise and fall, not a flicker
	# Centred on 1.06 rather than 0.95: the breathing lamp was darkening the plate more
	# than half the time, which is a permanent ~5% off the measured brightness for an
	# effect that only needs to MOVE, not to dim.
	var lamp := 1.06 + 0.055 * sin(t * 0.61) + 0.018 * sin(t * 1.8)
	bg.modulate = Color(lamp, lamp * 0.972, lamp * 0.99)
	# the foil catches the light as the lamp swings: the mark is metal, so it answers
	if mark != null:
		var g := 0.97 + 0.045 * sin(t * 0.61 + 0.7)
		mark.modulate = Color(g, g, g)
