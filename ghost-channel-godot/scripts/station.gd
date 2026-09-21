## Station — the key visual, in three planes, with the lights that make it a room.
##
## ops/adult_forks/TITLE_SCREENS.md item 3: the key visual is layered
## (foreground / character / background) with slow parallax or a breathing camera; light
## moves; there are two to four seconds of life before anything is pressed.
##
## The three planes are three renders of the same room from the same eye height
## (ops/ghost_art/ghost_gen.py: title_far, title_mid, title_fore), so they stack instead of
## reading as a diorama. `keyvisual` — the operator at the desk, the five call-lights — is
## the single frame the title screen actually shows; the three planes sit behind it and
## carry the motion, and when a plate is missing the plane simply is not added, so the
## screen degrades to whatever did render rather than to a hole.
##
## The light is real Light2D, not a painted glow: a PointLight2D for the desk lamp (a slow
## amber breath with an occasional filament stutter), one for the live channel's cyan
## spill, and a small hard one out at the antenna for the beacon, which is the only thing in
## the composition on a fixed rhythm. A CanvasModulate puts the whole layer down to a night
## key so the lamps have somewhere to lift from — a Light2D over an already-bright plate
## does nothing visible, which is the usual reason engine lighting looks like a filter.
extends Node2D

const DESIGN := Vector2(1280, 720)

## plane -> how far it moves against the camera drift. Far is nearly still.
const DEPTH := {"far": 0.012, "mid": 0.035, "key": 0.05, "fore": 0.1}

@export var show_key := true          # the title shows the operator; the menus show the room
@export var motion := 1.0             # 0 stills the whole thing (the play screen wants calm)

var _t := 0.0
var _planes := {}                     # name -> Sprite2D
var _lamp: PointLight2D
var _channel: PointLight2D
var _beacon: PointLight2D
var _rain: Node2D
var _modulate: CanvasModulate
var _flicker := 0.0
var _next_flicker := 3.0
var _rng := RandomNumberGenerator.new()
var _channel_color := Palette.ACCENT
var _channel_heat := 0.0              # 0..1, pushed up when a voice is on the air


func _ready() -> void:
	_rng.randomize()
	_modulate = CanvasModulate.new()
	# Night key. Not black — the sea outside is a light source too, just a cold one. Set so
	# the plate reads as a lit room seen at night rather than as a dark photograph: the
	# lamps below have to have somewhere to lift *from*, and a key this low leaves nothing
	# for them to do.
	# 2026-09-21: was Color(0.66, 0.74, 0.84) -- a flat x0.75 on every pixel of the art.
	# That was the right call when the plates were a night room rendered at 0.17 and the
	# lamps needed somewhere to lift from; it is the wrong call now that the plates are a
	# lit station at dusk, because it simply throws away the brightness that was the whole
	# point of re-rendering them, and the lamps are BLEND_MODE_ADD -- they add over a bright
	# base perfectly well, they are just less theatrical about it. The cool cast stays (the
	# sea outside is a cold light source); the level does not.
	_modulate.color = Color(1.06, 1.08, 1.12)
	add_child(_modulate)
	for plane in ["far", "mid", "key", "fore"]:
		if plane == "key" and not show_key:
			continue
		var tex := _load_plate(plane)
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.position = DESIGN * 0.5
		# cover the design rect with a little overscan, so parallax never shows an edge
		# 1.06 was under the STANDARD's own figure (item 6: scale past 1.16, the 16:9
		# diagonal ratio) -- with the camera drifting, a 6% overscan is not enough margin
		# and the far plane can reach its own edge. 1.18 fixes that and does something
		# else worth having: the key plane is the operator, so a larger scale is a tighter
		# crop on her, and how much of the frame is a person is the number that separates
		# the top of the Nutaku shelf from the bottom.
		var k: float = maxf(DESIGN.x / tex.get_width(), DESIGN.y / tex.get_height()) * 1.18
		s.scale = Vector2(k, k)
		s.z_index = ["far", "mid", "key", "fore"].find(plane)
		if plane == "fore":
			# The foreground plate is a black console edge under out-of-focus warm bokeh.
			# Drawn normally it is an opaque black sheet over the whole composition; drawn
			# additively it is what a foreground plane at this distance actually contributes
			# — bloom and dropped light in front of the lens — and the black costs nothing.
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			s.material = mat
			s.modulate = Color(1, 1, 1, 0.7)
		add_child(s)
		_planes[plane] = s
	_add_lights()
	_rain = preload("res://scripts/rain.gd").new()
	_rain.z_index = 6
	add_child(_rain)
	set_process(true)


## The picked plate for a plane, or null when that render has not landed yet.
func _load_plate(plane: String) -> Texture2D:
	var path := "res://assets/art/%s.png" % ("keyvisual" if plane == "key" else "title_" + plane)
	if not ResourceLoader.exists(path):
		return null
	return load(path)


## True when the real renders are in the build. The title screen asks, so that a build
## without art can say so on the screen instead of quietly looking broken.
func has_plates() -> bool:
	return not _planes.is_empty()


func _add_lights() -> void:
	_lamp = _light(Palette.GOLD, 2.6, 4.2, Vector2(DESIGN.x * 0.62, DESIGN.y * 0.58))
	_channel = _light(Palette.ACCENT, 1.2, 3.0, Vector2(DESIGN.x * 0.50, DESIGN.y * 0.50))
	_beacon = _light(Palette.HEAT, 0.0, 1.4, Vector2(DESIGN.x * 0.20, DESIGN.y * 0.30))


func _light(color: Color, energy: float, scale: float, at: Vector2) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = _falloff()
	l.color = color
	l.energy = energy
	l.texture_scale = scale
	l.position = at
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.z_index = 7
	add_child(l)
	return l


## A soft round falloff, generated once. This is a light's *shape*, not art: an asset here
## would be a 512px white blob in git for no reason.
static var _falloff_tex: Texture2D


func _falloff() -> Texture2D:
	if _falloff_tex:
		return _falloff_tex
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) * 0.5
	for y in n:
		for x in n:
			var d: float = (Vector2(x, y) - c).length() / (n * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)          # smoothstep: no ring at the edge
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_falloff_tex = ImageTexture.create_from_image(img)
	return _falloff_tex


## The hero plate is the operator at the desk, and it is opaque, so while it is up the far
## and mid planes are behind it doing nothing. That is the right composition for a title
## screen and the wrong one for everything else: off the title, the hero fades and what is
## left is the same room with nobody in it — the far window, the wall of racks, the empty
## chair — which is what should be behind a rules page or an op-select list. All four
## plates earn their place, and the transition is the operator getting up.
func set_hero(on: bool) -> void:
	if not _planes.has("key"):
		return
	var s: Sprite2D = _planes["key"]
	if _hero_tween and _hero_tween.is_running():
		_hero_tween.kill()
	_hero_tween = create_tween()
	_hero_tween.tween_property(s, "modulate:a", 1.0 if on else 0.0, 0.55)\
		.set_trans(Tween.TRANS_SINE)


var _hero_tween: Tween


## A voice is on the air: push the console spill towards that call-sign's colour.
func channel_live(color: Color) -> void:
	_channel_color = color
	_channel_heat = 1.0


func _process(delta: float) -> void:
	_t += delta
	# --- the camera breathes: a slow ellipse, never a pan. Two periods that do not
	# divide into each other, so the drift never visibly repeats.
	var drift := Vector2(sin(_t * 0.11) * 26.0, cos(_t * 0.083) * 14.0) * motion
	for plane in _planes:
		var s: Sprite2D = _planes[plane]
		s.position = DESIGN * 0.5 + drift * DEPTH[plane]

	# --- the lamp: a slow breath, and every few seconds the filament stutters once
	if _t >= _next_flicker:
		_flicker = 1.0
		_next_flicker = _t + _rng.randf_range(4.0, 9.0)
	_flicker = maxf(0.0, _flicker - delta * 6.0)
	var breath: float = 1.0 + sin(_t * 0.9) * 0.06
	_lamp.energy = (2.6 * breath - _flicker * 1.6) * motion + 0.35

	# --- the live channel fades back to a resting glow after each transmission
	_channel_heat = maxf(0.0, _channel_heat - delta * 0.55)
	_channel.color = Palette.ACCENT.lerp(_channel_color, _channel_heat)
	_channel.energy = 0.7 + _channel_heat * 1.6 + sin(_t * 3.1) * 0.05

	# --- the beacon: the one thing on a fixed rhythm. 3 s period, a short hard flash.
	var phase: float = fmod(_t, 3.0)
	_beacon.energy = 2.4 * maxf(0.0, 1.0 - phase * 7.0) * motion
