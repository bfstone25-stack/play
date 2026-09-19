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
	tr.modulate = Color(1, 1, 1, alpha)
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
	# Pushed down and oversized: the mark takes the top band (the moon and the sky are
	# there in the plate, which is why it was composed that way), 老王 keeps the middle,
	# and the coins on the wet ground are what the menu sits on.
	var over := Rect2(Vector2(-W * 0.09, 26.0), Vector2(W * 1.18, H * 1.08))
	# far: the sky, drifting most
	_add_layer(_tex("plate_sky.webp"), 1.0, over, 1.0, -40)
	# mid: the skyline he is buying
	_add_layer(_tex("plate_skyline_neon.webp"), 0.62, over, 0.9, -30)
	# near: him, the gate, the whole composition
	_add_layer(hero, 0.28, over, 1.0, -20)
	# a night grade over the lot, so the plates sit in one light
	var grade := ColorRect.new()
	grade.color = Color(Palette.GROUND_DEEP, 0.34)
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.z_index = -15
	add_child(grade)
	move_child(grade, 0)
	# the road at the bottom goes darkest, so the menu has something to sit on
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.92)])
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
	kicker.position = Vector2(0, 8)
	kicker.size.x = W
	add_child(kicker)

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
func _btn(text: String, variation: String, at: Vector2, w: float, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.position = at
	b.custom_minimum_size = Vector2(w, 46)
	b.size = Vector2(w, 46)
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
	_btn(RTStrings.t("cont") if Game.has_progress() else RTStrings.t("start"),
		"Primary", Vector2(x, H - 196.0), 224.0, func(): start_pressed.emit())
	_btn(RTStrings.t("shop"), "Amber", Vector2(x, H - 142.0), 146.0, func(): ledger_pressed.emit())
	_btn(RTStrings.t("lang"), "Ghost", Vector2(x + 150.0, H - 142.0), 74.0, func(): lang_pressed.emit())
	_btn(RTStrings.t("sound") + ": " + (RTStrings.t("on") if not Sfx.muted else RTStrings.t("off")),
		"Amber", Vector2(x, H - 92.0), 108.0, func(): sound_pressed.emit())
	# Reduced motion, offered on the first screen rather than buried: a player who needs it
	# needs it before the parallax push and the neon flicker have had four seconds at them.
	var motion := _btn(RTStrings.t("motion") + ": " + _motion_word(),
		"Amber", Vector2(x + 116.0, H - 92.0), 108.0, func(): motion_pressed.emit())
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

	var tag := Label.new()
	tag.text = RTStrings.t("tagline")
	tag.theme_type_variation = "Tag"
	tag.add_theme_color_override("font_color", Palette.GOLD_PALE)
	tag.add_theme_font_size_override("font_size", 12)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(0, H - 228.0)
	tag.size.x = W
	add_child(tag)


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
