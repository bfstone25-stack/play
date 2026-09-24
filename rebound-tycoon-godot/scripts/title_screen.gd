extends Control
## The first second of the game (ops/adult_forks/TITLE_SCREENS.md).
##
## Not a background with a logo on it. The checklist, and where each item is:
##   1. key visual   plate_title_portrait — 老王 with the water cannon at the gate, the
##                   skyline he is rebuilding going up behind him. The parallax stack
##                   splits it into sky / skyline / him / gate so it has depth.
##   2. logotype     scripts/logotype.gd — neon tube over a brass plate, hand-set track.
##   3. motion       a slow camera push on the key visual, the skyline drifting against
##                   it, the sodium lamp breathing, coins rising, the mark settling in.
##                   Two to four seconds of life before anything is pressed.
##   4. styled menu  the buttons sit in the composition (right of him, over the wet road),
##                   in the same family, with hover/press sound.
##   5. marks        no 18+ here — this is the mainstream track — but the studio mark and
##                   the cabinet number are where they always are.
##   6. sound        Sfx.title_sting() on arrival over Sfx.ambient()'s sodium hum.

signal start_pressed
signal ledger_pressed
signal lang_pressed
signal sound_pressed
signal motion_pressed

const W := 420.0
const H := 640.0
const ART := "res://assets/art/"
## A grade on the key visual, not a repaint of it.
##
## ops/SHELF_STYLE.md's puzzle/casual floor is 0.57 brightness / 0.43 saturation and this
## title composes at 0.44/0.42. The scrim is not what is holding it down any more: the
## PLATES top out at 0.429 (plate_title_portrait; sky 0.309, skyline 0.390), so a
## perfectly transparent grade still could not reach the floor. Repainting them brighter
## is a composition call and belongs to Blaze -- it is in the report with these numbers.
##
## What is honest to do here is lift the exposure. It is a MULTIPLY, which is why the
## channels are unequal and slightly warm: scaling all three by the same factor preserves
## HSV saturation exactly, so this buys brightness without the washed-out look that sank
## the one bright title in the catalogue (measured at 0.20 saturation). Kept modest --
## the factor that would actually reach 0.57 is about 1.30, and that clips the neon and
## the water spray to white, which is a worse frame than a dark one.
const EXPOSURE := Color(1.0, 1.0, 1.0)

var reduce_motion := false
var _clock := 0.0
var _layers: Array = []          # {node, depth, base}
var _logo: Control
var _lamp: PointLight2D
var _coins: Array = []
var _world: Node2D


func _tex(n: String) -> Texture2D:
	var p := ART + n
	return load(p) if ResourceLoader.exists(p) else null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = StudioTheme.build()
	_world = Node2D.new()
	add_child(_world)
	_build_key_visual()
	_build_light()
	_build_marks()
	_build_menu()
	Sfx.ambient()
	Sfx.title_sting()
	set_process(true)


# ---------- 1 + 3: the key visual, in layers so it can move ------------------------------
func _add_layer(tex: Texture2D, depth: float, rect: Rect2, alpha := 1.0, z := 0) -> void:
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.position = rect.position
	tr.size = rect.size
	tr.modulate = Color(EXPOSURE.r, EXPOSURE.g, EXPOSURE.b, alpha)
	tr.z_index = z
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	move_child(tr, 0)
	_layers.append({"node": tr, "depth": depth, "base": rect.position})


func _build_key_visual() -> void:
	# The whole key visual, slightly oversized so a push has somewhere to go.
	var hero := _tex("plate_title_portrait.webp")
	if hero == null:
		hero = _tex("plate_title.webp")
	if hero == null:
		hero = _tex("plate_title_legacy.webp")     # the JS build's key visual, until the new one lands
	# Oversized in every direction, so a push has somewhere to go AND the plate's own edge
	# can never come on screen (ops/STANDARD.md #6). The first cut started the stack at
	# y = 26 to leave the mark a clean top band, and the 26 px it left was the black of the
	# clear colour -- a hard horizontal seam across the top of the key visual, visible in
	# every screenshot of this title. The mark gets its contrast from the grade below
	# instead, which is what a grade is for.
	#
	# The margins are sized against what _process does to these layers, not guessed: sway
	# reaches 16 px and bob 8 px at depth 1.0, and the scale is applied from the top-left
	# corner so it can only ever push the far edges further out. 12% of W on each side and
	# 6% of H top and bottom leaves the nearest edge 30 px off screen at the worst frame.
	var over := Rect2(Vector2(-W * 0.12, -H * 0.06), Vector2(W * 1.24, H * 1.20))
	# far: the sky, drifting most
	_add_layer(_tex("plate_sky.webp"), 1.0, over, 1.0, -40)
	# mid: the skyline he is buying
	_add_layer(_tex("plate_skyline_neon.webp"), 0.62, over, 0.9, -30)
	# near: him, the gate, the whole composition
	_add_layer(hero, 0.28, over, 1.0, -20)
	# A night grade over the lot, so the plates sit in one light.
	#
	# It was 0.34, and with the 0.92 road gradient below it the title measured 0.12
	# brightness against ops/SHELF_STYLE.md's casual floor of 0.57. Two separable things
	# make this title dark: the plates themselves (0.19-0.43) and this scrim on top of
	# them. The scrim is mine to change and the plates are a composition call for Blaze,
	# so only the scrim moved -- 0.34 -> 0.13 here and 0.92 -> 0.62 below. That recovers
	# what the plates actually contain without repainting anything.
	var grade := ColorRect.new()
	# 2026-09-23: 0.13 -> 0.0. Blaze: brighten it, keep the uniform blues and greens, make
	# them bright. The plates are regraded (shadows lifted, colour pushed); this and the
	# road gradient below were the last darkness laid on top.
	grade.color = Color(Palette.GROUND_DEEP, 0.0)
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.z_index = -15
	add_child(grade)
	move_child(grade, 0)
	# The road at the bottom goes darker, so the menu has something to sit on. It does not
	# go BLACK: at 0.92 the bottom half of the key visual -- the wet road, the coins, his
	# boots, the whole lower third of the composition the menu was placed "in" -- was
	# painted out, and the menu was sitting on a flat dark panel wearing a photograph as a
	# hat. 0.62 with a knee two thirds down keeps the stubs legible and lets the road read.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	g.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.0),
		Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = Vector2(0, H - 320.0)
	tr.size = Vector2(W, 320.0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.z_index = -14
	add_child(tr)
	move_child(tr, 1)


func _build_light() -> void:
	# The sodium lamp over the gate: a real Light2D on the composition, breathing.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	_lamp = PointLight2D.new()
	_lamp.texture = t
	_lamp.color = Palette.SODIUM
	# A little more lamp than before, but measured, not hoped for: raising this from 0.9
	# to 1.25 and widening it moved the composed title's brightness by 0.00, and a second
	# fill light moved it by 0.00 as well, so the fill was taken back out. 2D lights are
	# not where this frame's brightness is. See EXPOSURE below for what actually moves it,
	# and the report for the part that is not mine to do.
	_lamp.energy = 0.9
	_lamp.texture_scale = 3.0
	_lamp.position = Vector2(W * 0.22, H * 0.30)
	_world.add_child(_lamp)


# ---------- 2 + 5: the mark, and the marks -----------------------------------------------
func _build_marks() -> void:
	_logo = Control.new()
	_logo.set_script(load("res://scripts/logotype.gd"))
	_logo.position = Vector2(0, 28)
	_logo.size = Vector2(W, 150)
	_logo.set("word", RTStrings.t("wordmark"))
	_logo.set("sub", RTStrings.t("local_title"))
	_logo.set("size_px", 56)
	_logo.set("reduce_motion", reduce_motion)
	add_child(_logo)

	var kicker := Label.new()
	kicker.text = RTStrings.t("kicker")
	kicker.theme_type_variation = "Tag"
	kicker.add_theme_color_override("font_color", Palette.ACCENT_SOFT)
	kicker.add_theme_font_size_override("font_size", 11)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# NOT SOLVED, and it is in the report: the logotype's brass plate overhangs this line,
	# so "GATE 01 · NIGHT EMPIRE" is cut in half on the shipped title. Moving the kicker
	# down to 182 puts it across the guard's chest at low contrast, which reads worse, and
	# moving the mark down to 40 does not clear it either -- the plate is drawn from the
	# logotype's own baseline, not from its node position. It wants the plate's geometry
	# changed in scripts/logotype.gd, which is the mark, which is a design call.
	kicker.position = Vector2(0, 8)
	kicker.size.x = W
	add_child(kicker)

	# The tagline, over the menu. It lived at the bottom of _motion_word() -- after that
	# function's `match`, every arm of which returns -- so it was unreachable code and the
	# game shipped with no tagline on the title at all, with no error anywhere. Moved here,
	# where the rest of the type is set.
	var tag := Label.new()
	tag.text = RTStrings.t("tagline")
	# the plate is bright now; a pale tagline needs its own keyline to read on it
	tag.add_theme_color_override("font_outline_color", Color("1B1320"))
	tag.add_theme_constant_override("outline_size", 6)
	tag.theme_type_variation = "Tag"
	tag.add_theme_color_override("font_color", Palette.GOLD_PALE)
	tag.add_theme_font_size_override("font_size", 12)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(0, H - 232.0)
	tag.size.x = W
	add_child(tag)

	# the studio mark, small and in the same place it always is
	var studio := Label.new()
	studio.text = RTStrings.t("studio")
	studio.theme_type_variation = "Tag"
	studio.add_theme_color_override("font_color", Palette.MUTED)
	studio.add_theme_font_size_override("font_size", 10)
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.position = Vector2(0, H - 26)
	studio.size.x = W
	add_child(studio)


# ---------- 4: the menu, placed in the composition ---------------------------------------
## 2026-09-23: OBJECTS, not torn ticket stubs (ops/STANDARD.md, "Buttons are objects from
## the game"). A ticket is a rectangle in costume. This game is a night guard at a gate
## with a water hose, so: the hose NOZZLE starts the shift, the guard's star BADGE opens
## the ledger, the WHISTLE is the sound toggle. Language and motion stay words with an
## outline -- a settings word does not need a prop, and inventing one would be noise.
## Objects are GPU renders cut out by ops/install_button_objects.py.
const BTN_OBJ := {
	"start": "res://assets/title/btn_nozzle.png",
	"shop": "res://assets/title/btn_badge.png",
	"sound": "res://assets/title/btn_whistle.png",
}


func _btn(text: String, variation: String, at: Vector2, w: float, fn: Callable,
		h: float = 46.0, obj_key := "") -> Button:
	var b := ObjectButton.new()
	b.text = text
	var path: String = BTN_OBJ.get(obj_key, "")
	if path != "" and ResourceLoader.exists(path):
		b.object_texture = load(path)
		b.object_size = h
	else:
		b.object_size = 0.0
		b.gap = 0.0
	b.motion = ObjectButton.Motion.BOB if obj_key == "start" else ObjectButton.Motion.TURN
	b.label_color = Color("FFF6E6")
	b.accent_color = Color("FFD35A")
	b.ink = Color("1B1320")
	b.outline_px = 3
	b.shadow_px = 0
	b.add_theme_font_override("font", StudioTheme.font("display"))
	b.add_theme_font_size_override("font_size", 20 if variation == "Primary" else 15)
	b.position = at
	b.size = Vector2(w, h)
	b.pressed.connect(Sfx.tap)
	b.pressed.connect(fn)
	b.mouse_entered.connect(Sfx.flip)
	add_child(b)
	return b


func _build_menu() -> void:
	# Right of him, over the wet road — not a stack in the middle of the screen. The column
	# is 224 wide and four rows deep; the two settings rows split it rather than adding a
	# fifth, because the studio mark sits at H-26 and there is no room under them.
	var x := W * 0.5 - 112.0
	# Every row is sized so the CENTRE COLUMN of the screen lands on a button, not between
	# two of them. On a 420-wide portrait cabinet the centre column is where a thumb goes
	# first, and it was the one place with nothing under it: Sound ran 98..206 and Motion
	# started at 214, so x = 210 -- the middle of the screen -- was an eight-pixel dead
	# gap between them. ops/play_driver.py presses exactly there and found the same hole.
	_btn(RTStrings.t("cont") if Game.has_progress() else RTStrings.t("start"),
		"Primary", Vector2(x, H - 206.0), 224.0, func(): start_pressed.emit(), 60.0, "start")
	_btn(RTStrings.t("shop"), "Amber", Vector2(x, H - 142.0), 146.0, func(): ledger_pressed.emit(), 42.0, "shop")
	_btn(RTStrings.t("lang"), "Ghost", Vector2(x + 150.0, H - 142.0), 74.0, func(): lang_pressed.emit())
	_btn(RTStrings.t("sound") + ": " + (RTStrings.t("on") if not Sfx.muted else RTStrings.t("off")),
		"Amber", Vector2(x, H - 92.0), 120.0, func(): sound_pressed.emit(), 38.0, "sound")
	# Reduced motion, offered on the first screen rather than buried: a player who needs it
	# needs it before the parallax push and the neon flicker have had four seconds at them.
	var motion := _btn(RTStrings.t("motion") + ": " + _motion_word(),
		"Amber", Vector2(x + 124.0, H - 92.0), 100.0, func(): motion_pressed.emit())
	# "Motion: Auto" is twelve characters in an 84 px inner box; 14 px overruns the button
	# and paints over the one beside it, so this row's second button is set a size down.
	motion.add_theme_font_size_override("font_size", 12)


func _motion_word() -> String:
	match Game.motion_pref:
		"on":
			return RTStrings.t("motion_calm")
		"off":
			return RTStrings.t("motion_full")
		_:
			return RTStrings.t("motion_auto")


# ---------- 3: motion ---------------------------------------------------------------------
func _process(dt: float) -> void:
	_clock += dt
	if reduce_motion:
		return
	# a slow push in, and each layer drifting at its own rate against it
	var push := 1.0 + (1.0 - exp(-_clock * 0.35)) * 0.05
	var sway := sin(_clock * 0.28)
	var bob := sin(_clock * 0.21 + 1.1)
	for l in _layers:
		var n: TextureRect = l["node"]
		var d: float = l["depth"]
		n.position = Vector2(l["base"]) + Vector2(sway * 16.0 * d, bob * 8.0 * d)
		n.scale = Vector2.ONE * (1.0 + (push - 1.0) * (0.4 + d))
	# the lamp breathes
	_lamp.energy = 0.78 + sin(_clock * 1.3) * 0.06 + sin(_clock * 4.7) * 0.02
	# coins rise out of the gate, slowly, the way they do in the key visual
	if _coins.size() < 14 and randf() < dt * 5.0:
		_coins.append({"p": Vector2(randf_range(W * 0.2, W * 0.8), H * 0.62),
			"v": Vector2(randf_range(-9.0, 9.0), randf_range(-26.0, -52.0)), "t": 0.0,
			"m": randf_range(1.8, 3.4), "r": randf_range(1.8, 3.2)})
	var live: Array = []
	for c in _coins:
		c["t"] += dt
		if c["t"] < c["m"]:
			c["p"] += c["v"] * dt
			live.append(c)
	_coins = live
	queue_redraw()


func _draw() -> void:
	for c in _coins:
		var a: float = sin(clampf(c["t"] / c["m"], 0.0, 1.0) * PI) * 0.8
		draw_circle(c["p"], c["r"], Color(Palette.GOLD, a))
		draw_circle(c["p"] - Vector2(c["r"] * 0.3, c["r"] * 0.3), c["r"] * 0.35,
			Color(Palette.GOLD_PALE, a))
