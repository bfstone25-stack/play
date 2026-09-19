extends Node2D
## TableView — the cabinet. Runs Kernel.step every frame and draws the result as a lit
## 2.5D scene rather than a flat canvas of shapes.
##
## The 2.5D, per ops/adult_forks/TITLE_SCREENS.md and the studio conventions:
##   - the backglass behind the table is a parallax stack (sky / the era's skyline / the
##     gate), each layer drifting at its own rate against a slow camera breath, so the
##     thing 老王 is rebuilding is visibly *behind* the glass rather than printed on it;
##   - the table pieces are rendered sprites with contact shadows and a small offset away
##     from the light, which is what makes them read as standing above the bed;
##   - every light is a real Light2D: the sodium lamp over the booth, the era key light
##     that changes colour as the skyline grows, and a light that rides the ball, so a
##     fast shot actually lights the playfield it crosses. A CanvasModulate puts the whole
##     cabinet under night.
##
## The table pieces are the rendered assets the JS build already shipped, converted once
## into neutral masters (ops/rebound_art/rebound_gen.py, step "pieces") so the engine can
## colour them per era — Godot's modulate multiplies, and a pastel candy bumper times a
## steel-grey era colour is still a pastel candy bumper.
##
## Nothing here decides a number. Kernel owns the rules; this shows them.

signal events(list)

const W := 420.0
const H := 640.0
const ART := "res://assets/art/"

## The table lives in the lower part of the screen; the backglass fills the band above it,
## between the HUD rail and the table's top edge. That band is the whole point of the 2.5D
## — the first build put the table at y=96 with a 88 px HUD over it, so the parallax stack
## existed and was never once visible. x and y are both normalised to the table rect, and a
## radius scales by its width — the same mapping the JS stage used (px(v, w) = v * w), so
## the geometry is identical.
const RAIL_H := 74.0
const TABLE_TOP := 150.0

var state: Dictionary = {}
var input := {"left": false, "right": false, "plunge": false, "fire": false}
var clock := 0.0
var reduce_motion := false
var paused := true

var _sky: TextureRect
var _skyline: TextureRect
var _gate: TextureRect
var _bed: Sprite2D
var _pieces: Node2D
var _ball: Sprite2D
var _ball_light: PointLight2D
var _lamp: PointLight2D
var _key: PointLight2D
var _grade: CanvasModulate
var _bumpers: Array[Sprite2D] = []
var _targets: Array[Sprite2D] = []
var _saucer: Sprite2D
var _flip_l: Sprite2D
var _flip_r: Sprite2D
var _guard: Sprite2D
var _fx: Node2D
var _sparks: Array = []           # {pos, vel, life, max, color, size}
var _floaters: Array = []         # {pos, text, life}
var _era := "booth"
var _shake := 0.0
var _guard_reset := 0.0


func table_rect() -> Rect2:
	return Rect2(0.0, TABLE_TOP, W, H - TABLE_TOP)


func to_px(u: float, v: float) -> Vector2:
	var r := table_rect()
	return Vector2(r.position.x + u * r.size.x, r.position.y + v * r.size.y)


func to_r(u: float) -> float:
	return u * table_rect().size.x


func _tex(name: String) -> Texture2D:
	var p := ART + name
	if ResourceLoader.exists(p):
		return load(p)
	return null


## A soft round light cone. A gradient is a falloff curve, not art: the pieces, the plates
## and the character are all rendered assets, and this is the only thing drawn in code.
func _light_tex(inner: float = 0.0) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, maxf(0.02, inner), 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


func _ready() -> void:
	state = Game.st
	_grade = CanvasModulate.new()
	_grade.color = Color(0.82, 0.88, 1.0)          # night: cool, never grey
	add_child(_grade)
	_build_backglass()
	_build_table()
	_build_lights()
	_fx = Node2D.new()
	_fx.z_index = 60
	add_child(_fx)
	set_process(true)


# ---------- the parallax backglass ------------------------------------------------------
func _layer(tex: Texture2D, z: int, alpha: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.size = Vector2(W * 1.24, TABLE_TOP - RAIL_H + 90.0)
	tr.position = Vector2(-W * 0.12, RAIL_H - 34.0)
	tr.modulate = Color(1, 1, 1, alpha)
	tr.z_index = z
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


func _build_backglass() -> void:
	_sky = _layer(_tex("plate_sky.webp"), -30, 1.0)
	_skyline = _layer(_tex("plate_skyline_booth.webp"), -20, 0.95)
	_gate = _layer(_tex("plate_gate.webp"), -10, 0.55)
	if _gate:
		_gate.size = Vector2(W * 1.3, 120.0)
		_gate.position = Vector2(-W * 0.15, TABLE_TOP - 86.0)


func _piece(tex_name: String, z: int, tint: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(tex_name)
	s.z_index = z
	s.modulate = tint
	_pieces.add_child(s)
	return s


func _build_table() -> void:
	var r := table_rect()
	_bed = Sprite2D.new()
	_bed.texture = _tex("plate_playfield.webp")
	_bed.centered = false
	_bed.z_index = -5
	add_child(_bed)
	_fit_bed()

	_pieces = Node2D.new()
	add_child(_pieces)

	# The three bumpers take the era's rim colour so "the era went up" is visible on the
	# table itself, not only in a label.
	const BUMPER_ART := ["piece_bumper_sky.webp", "piece_bumper_coral.webp", "piece_bumper_mint.webp"]
	for i in range(Kernel.BUMPERS.size()):
		var b: Sprite2D = _piece(BUMPER_ART[i], 12)
		_bumpers.append(b)
	for i in range(Kernel.TARGETS.size()):
		_targets.append(_piece("piece_target.webp", 10))
	_saucer = _piece("piece_saucer.webp", 8)
	_flip_l = _piece("piece_flipper.webp", 14, Palette.GOLD_PALE)
	_flip_r = _piece("piece_flipper.webp", 14, Palette.GOLD_PALE)
	if _flip_r:
		_flip_r.flip_h = true
	_ball = _piece("piece_ball.webp", 20, Color(0.86, 0.94, 1.0))

	# 老王 stands beside the lane, in the cabinet's light — and reacts. Three rendered
	# sprites (idle / cheer / oops), never a code-drawn rig. He is the reason the game has
	# a face; a pinball table without him is a pinball table.
	_guard = Sprite2D.new()
	_guard.texture = _guard_tex("idle")
	_guard.z_index = 4
	add_child(_guard)
	_fit_guard()


func _guard_tex(mood: String) -> Texture2D:
	var t := _tex("sprite_guard_%s.webp" % mood)
	if t == null:
		t = _tex("guard_%s.png" % mood)
	return t


func _fit_guard() -> void:
	if _guard == null or _guard.texture == null:
		return
	var want := 96.0
	_guard.scale = Vector2.ONE * (want / float(_guard.texture.get_height()))
	_guard.position = Vector2(W - 44.0, TABLE_TOP - 26.0)
	# He stands in the backglass band, under the cabinet's light, graded into it — a
	# full-brightness cutout on a night plate reads as a sticker, not a character.
	_guard.modulate = Color(0.74, 0.86, 0.92)


## Called from main when something good or bad happens. He holds the face for a beat.
func guard_mood(mood: String, hold := 1.1) -> void:
	if _guard == null:
		return
	var t := _guard_tex(mood)
	if t == null:
		return
	_guard.texture = t
	_fit_guard()
	_guard_reset = hold


func _fit_bed() -> void:
	if _bed == null or _bed.texture == null:
		return
	var r := table_rect()
	_bed.position = r.position
	_bed.scale = Vector2(r.size.x / float(_bed.texture.get_width()), r.size.y / float(_bed.texture.get_height()))


func _build_lights() -> void:
	_lamp = PointLight2D.new()
	_lamp.texture = _light_tex(0.08)
	_lamp.color = Palette.SODIUM
	_lamp.energy = 1.15
	_lamp.texture_scale = 3.4
	_lamp.position = Vector2(W * 0.18, TABLE_TOP - 24.0)
	_lamp.z_index = 40
	add_child(_lamp)

	_key = PointLight2D.new()
	_key.texture = _light_tex(0.02)
	_key.color = Palette.era("booth")["key"]
	_key.energy = 0.8
	_key.texture_scale = 5.0
	_key.position = Vector2(W * 0.55, TABLE_TOP + 180.0)
	_key.z_index = 40
	add_child(_key)

	_ball_light = PointLight2D.new()
	_ball_light.texture = _light_tex(0.0)
	_ball_light.color = Palette.WATER
	_ball_light.energy = 0.9
	_ball_light.texture_scale = 1.1
	_ball_light.z_index = 41
	add_child(_ball_light)


# ---------- the era ---------------------------------------------------------------------
func set_era(id: String) -> void:
	if id == _era:
		return
	_era = id
	var e := Palette.era(id)
	if _skyline:
		var t := _tex("plate_skyline_%s.webp" % id)
		if t:
			_skyline.texture = t
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_key, "color", e["key"], 0.8)
	tw.tween_property(_key, "energy", 0.6 + float(e["glow"]) * 0.9, 0.8)


# ---------- the frame --------------------------------------------------------------------
func _process(dt: float) -> void:
	clock += dt
	if not paused:
		var out := Kernel.step(state, input, dt, Game.rng())
		state = out["state"]
		Game.st = state
		input["fire"] = false
		if not out["events"].is_empty():
			events.emit(out["events"])
	set_era(Kernel.era_id(state))
	_breathe(dt)
	_place_pieces()
	_step_fx(dt)
	queue_redraw()


## The camera breath and the parallax drift. Two to four seconds of life even when nothing
## is pressed (TITLE_SCREENS.md item 3) — and off entirely under reduced motion.
func _breathe(dt: float) -> void:
	if reduce_motion:
		return
	var b := sin(clock * 0.32)
	var ballx := 0.5
	if state.get("ball") != null:
		ballx = float(state["ball"]["x"])
	var lean := (ballx - 0.5) * 2.0
	if _sky:
		_sky.position.x = -W * 0.12 + b * 5.0 + lean * 4.0
	if _skyline:
		_skyline.position.x = -W * 0.12 + b * 11.0 + lean * 10.0
		_skyline.position.y = RAIL_H - 34.0 + b * 3.0
	if _gate:
		_gate.position.x = -W * 0.15 + b * 20.0 + lean * 18.0
	if _guard_reset > 0.0:
		_guard_reset = maxf(0.0, _guard_reset - dt)
		if _guard_reset == 0.0:
			guard_mood("idle", 0.0)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - dt * 3.2)
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 6.0
	else:
		position = Vector2.ZERO


func _fit(s: Sprite2D, px_r: float) -> void:
	if s == null or s.texture == null:
		return
	s.scale = Vector2.ONE * (px_r * 2.0 / float(s.texture.get_width()))


## The 2.5D pop: a piece sits a little away from the key light, which is what tells the eye
## it is standing on the bed rather than painted into it.
func _lift(at: Vector2, height: float) -> Vector2:
	var d := (at - _key.position).normalized()
	return at + d * height


func _place_pieces() -> void:
	for i in range(Kernel.BUMPERS.size()):
		var b: Dictionary = Kernel.BUMPERS[i]
		var at := to_px(float(b["x"]), float(b["y"]))
		var sp := _bumpers[i]
		_fit(sp, to_r(float(b["r"])) * 1.18)
		sp.position = _lift(at, 5.0)
		var flash := float(state.get("bumperFlash", [0, 0, 0])[i])
		sp.scale *= 1.0 + flash * 0.16
		# The pieces are the rendered assets the JS build shipped, in a pastel key that
		# fought this game's night. They are re-lit here rather than redrawn: each bumper
		# carries the era's rim colour and goes gold on a hit. One tint path — setting
		# modulate and self_modulate from different places made the era tween invisible.
		var e := Palette.era(_era)
		sp.modulate = Color(e["rim"]).lerp(Palette.GOLD_PALE, 0.35 + flash * 0.65)
	for i in range(Kernel.TARGETS.size()):
		var t: Dictionary = Kernel.TARGETS[i]
		var at := to_px(float(t["x"]) + float(t["w"]) * 0.5, float(t["y"]) + float(t["h"]) * 0.5)
		var sp := _targets[i]
		_fit(sp, to_r(float(t["w"])) * 0.62)
		sp.position = _lift(at, 3.0)
		var down: bool = bool(state.get("targetDown", [false, false, false])[i])
		sp.modulate = Color(Palette.INK_SOFT, 0.7) if down else Palette.GOLD_PALE
		sp.scale.y *= 0.5 if down else 1.0
	if _saucer:
		_fit(_saucer, to_r(float(Kernel.SAUCER["r"])) * 1.5)
		_saucer.position = to_px(float(Kernel.SAUCER["x"]), float(Kernel.SAUCER["y"]))
		var hold := float(state.get("saucerHold", 0.0))
		_saucer.modulate = Color(Palette.NEON, 0.95).lerp(Palette.WATER, minf(1.0, hold * 3.0))
	_place_flipper(_flip_l, Kernel.LEFT_PIVOT, float(state.get("flipL", Kernel.LEFT_REST)))
	_place_flipper(_flip_r, Kernel.RIGHT_PIVOT, float(state.get("flipR", Kernel.RIGHT_REST)))
	var ball = state.get("ball")
	if ball == null:
		if _ball:
			_ball.visible = false
		_ball_light.energy = 0.0
		return
	if _ball:
		_ball.visible = true
		_fit(_ball, to_r(Kernel.BALL_R) * 1.35)
		_ball.position = to_px(float(ball["x"]), float(ball["y"]))
	_ball_light.position = _ball.position
	var spd := Kernel.hyp(float(ball["vx"]), float(ball["vy"]))
	_ball_light.energy = 0.55 + minf(1.0, spd / Kernel.MAX_SPEED) * 0.9
	_ball_light.texture_scale = 0.9 + minf(1.0, spd / Kernel.MAX_SPEED) * 0.8


func _place_flipper(sp: Sprite2D, pivot: Dictionary, angle: float) -> void:
	if sp == null or sp.texture == null:
		return
	var at := to_px(float(pivot["x"]), float(pivot["y"]))
	var length := to_r(Kernel.FLIP_LEN)
	sp.scale = Vector2.ONE * (length * 1.12 / float(sp.texture.get_width()))
	if sp == _flip_r:
		sp.scale.x *= -1.0
	sp.position = at
	sp.rotation = angle if sp == _flip_l else angle - PI
	sp.offset = Vector2(float(sp.texture.get_width()) * 0.42, 0.0)


# ---------- effects ----------------------------------------------------------------------
func spark(at: Vector2, color: Color, n: int = 8) -> void:
	if reduce_motion:
		return
	for _i in range(n):
		var a := randf() * TAU
		_sparks.append({"pos": at, "vel": Vector2(cos(a), sin(a)) * randf_range(40.0, 190.0),
			"life": 0.0, "max": randf_range(0.25, 0.6), "color": color, "size": randf_range(1.6, 3.4)})


func float_text(at: Vector2, text: String) -> void:
	_floaters.append({"pos": at, "text": text, "life": 0.0})


func kick(amount: float = 1.0) -> void:
	_shake = maxf(_shake, amount)


func _step_fx(dt: float) -> void:
	var live: Array = []
	for s in _sparks:
		s["life"] += dt
		if s["life"] < s["max"]:
			s["pos"] += s["vel"] * dt
			s["vel"].y += 320.0 * dt
			s["vel"] *= 0.965
			live.append(s)
	_sparks = live
	var lf: Array = []
	for f in _floaters:
		f["life"] += dt
		if f["life"] < 1.0:
			f["pos"].y -= dt * 40.0
			lf.append(f)
	_floaters = lf


func _draw() -> void:
	var r := table_rect()
	# The bed when the plate has not been rendered yet: the table's own wash, so the game
	# is playable and honest about the missing art rather than showing a grey rectangle.
	if _bed == null or _bed.texture == null:
		var e := Palette.era(_era)
		draw_rect(r, Color(e["fill"]))
		draw_rect(Rect2(r.position, r.size), Color(e["rim"], 0.5), false, 2.0)
	# the shelf the backglass band sits on, and 老王's contact shadow on it
	if _guard and _guard.texture:
		# at his feet, not at his centre: a Sprite2D's position is its middle
		var half: float = _guard.texture.get_height() * _guard.scale.y * 0.5
		var foot := _guard.position + Vector2(0, half - 3.0)
		draw_circle(foot, 20.0, Color(Palette.GROUND_DEEP, 0.5))
	draw_line(Vector2(0, TABLE_TOP), Vector2(W, TABLE_TOP), Color(Palette.BRASS, 0.7), 2.0)
	# the drain mouth, the one piece of table geometry with no asset: it is a gap
	var dl := to_px(float(Kernel.TABLE["drainL"]), 1.0)
	var dr := to_px(float(Kernel.TABLE["drainR"]), 1.0)
	draw_line(dl, dr, Color(Palette.HEAT, 0.55), 3.0)
	# the plunge lane charge
	if state.get("mode", "") == "plunge":
		var p := float(state.get("plunge", 0.0))
		var top := to_px(0.915, 0.86)
		var bot := to_px(0.915, 0.94)
		draw_line(top, bot, Color(Palette.PANEL_EDGE, 0.8), 6.0)
		if p > 0.0:
			draw_line(bot, bot.lerp(top, p), Palette.WATER, 6.0)
	for s in _sparks:
		var a: float = 1.0 - s["life"] / s["max"]
		draw_circle(s["pos"], s["size"] * a, Color(s["color"], a))
	var f_ := StudioTheme.font("display")
	for f in _floaters:
		var a: float = 1.0 - f["life"]
		draw_string(f_, f["pos"], str(f["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 17,
			Color(Palette.GOLD_PALE, a))
