## MapScreen — the building, drawn as a place: a sky plate far back, the building plate
## (or, until it is rendered, the floors' own room plates stacked as a cutaway), a room
## "window" per node cut from that room's plate, lights on the floors that are open, and
## the character walking the corridors and riding the lift between floors. 2.5D: the sky
## and the building move at different rates as the character climbs, the rooms are lit by
## PointLight2D, the walker carries a light. No code-drawn shapes: every visible thing is a
## rendered plate, a cut of one, a sprite, a Theme panel or a Label.
##
## Reads BMMap for the graph and the profile for state; owns only presentation (the
## walk tween, the bob). Emits `arrived(node_id)` when a walk ends and `tapped(node_id)`
## when a room is tapped; main.gd decides what a tap means.
extends Node2D

signal tapped(node_id: String)
signal arrived(node_id: String)

const WALK_SPEED := 190.0
const LIFT_SPEED := 150.0
const FLOOR_H := 132.0
## Which plate a node's window is cut from, and where in it (a fraction of the plate).
const WINDOW := {
	"lobby": ["lobby", 0.5, 0.55], "breakroom": ["breakroom", 0.5, 0.55], "standup": ["mon", 0.5, 0.5],
	"corridor1": ["corridor", 0.5, 0.5], "inbox": ["tue", 0.5, 0.5], "allhands": ["wed", 0.5, 0.45],
	"review": ["thu", 0.5, 0.5], "corridor2": ["corridor", 0.5, 0.5], "deploy": ["fri", 0.5, 0.5],
}
const FALLBACK := {"lobby": "sat", "breakroom": "sat", "corridor": "mon", "map_sky": "title"}

var sky: Sprite2D
var building: Node2D
var walker: Node2D
var walker_sprite: Sprite2D
var walker_vec: Control
var walker_light: PointLight2D
var markers: Dictionary = {}
var lights: Dictionary = {}
var walking := false
var at := BMMap.START
var clock := 0.0
var face := 1.0
var _tween: Tween
var _fonts_font: Font
var _catcher: Control
## How far a missed tap may be from a room's centre and still count as that room. 120 is
## a little over one marker's width, so the map reads as "press a room", not "press this
## 84-pixel box"; past that the tap is empty space and stays empty space.
const TAP_SLACK := 120.0


## A tap that hit no marker: walk to the nearest room the player is allowed into. The
## profile is not reachable from here, so main.gd's `tapped` handler does the unlocking
## check as it always did -- this only decides WHICH room the tap meant.
func _on_catcher_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed) or walking:
		return
	var p: Vector2 = (e as InputEventMouseButton).position
	var best := ""
	var best_d := TAP_SLACK
	for n in BMMap.NODES:
		var id: String = n["id"]
		if id == at:
			continue
		# the marker sits above the floor line, so measure to the card, not the feet
		var d := p.distance_to(BMMap.pos(id) + Vector2(0, -44))
		if d < best_d:
			best_d = d
			best = id
	if best != "":
		tapped.emit(best)


static func plate_path(name: String) -> String:
	var p := "res://assets/art/plate_%s.webp" % name
	if ResourceLoader.exists(p):
		return p
	var fb: String = FALLBACK.get(name, "")
	if fb != "" and ResourceLoader.exists("res://assets/art/plate_%s.webp" % fb):
		return "res://assets/art/plate_%s.webp" % fb
	return ""


static func radial(size: int, inner := Color(1, 1, 1, 1)) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


func _ready() -> void:
	_fonts_font = StudioTheme.font("display")
	# --- far: the sky --------------------------------------------------------------------
	sky = Sprite2D.new()
	var sp := plate_path("map_sky")
	if sp != "":
		sky.texture = load(sp)
		sky.centered = false
		var ss := sky.texture.get_size()
		sky.scale = Vector2((BMCore.W + 80.0) / ss.x, (BMCore.H + 80.0) / ss.y)
		sky.position = Vector2(-40, -40)
		sky.modulate = Color(0.75, 0.8, 0.9)
	add_child(sky)
	# --- mid: the building -----------------------------------------------------------------
	building = Node2D.new()
	add_child(building)
	var bp := plate_path("map_building")
	if bp != "":
		var b := Sprite2D.new()
		b.texture = load(bp)
		b.centered = false
		var bs := b.texture.get_size()
		b.scale = Vector2(BMCore.W / bs.x, BMCore.H / bs.y)
		building.add_child(b)
	else:
		# the cutaway assembled from the floors' own plates: each floor is a band of the
		# room the floor is about, so the building reads as those rooms stacked
		var bands := [["lobby", 0.62], ["mon", 0.55], ["wed", 0.5], ["thu", 0.5]]
		for f in bands.size():
			var pp := plate_path(bands[f][0])
			if pp == "":
				continue
			var tex: Texture2D = load(pp)
			var ts := tex.get_size()
			var at_t := AtlasTexture.new()
			at_t.atlas = tex
			var band_h := ts.y * (FLOOR_H / BMCore.H) * 1.15
			at_t.region = Rect2(0, ts.y * float(bands[f][1]) - band_h / 2, ts.x, band_h)
			var s := Sprite2D.new()
			s.texture = at_t
			s.centered = false
			s.scale = Vector2(BMCore.W / ts.x, (FLOOR_H + 2) / band_h)
			s.position = Vector2(0, BMMap.FLOOR_Y[f] + 26 - FLOOR_H)
			s.modulate = Color(0.82, 0.86, 0.95)
			building.add_child(s)
		# the roof band: the sky again, so the top floor does not end in nothing
		var top := Sprite2D.new()
		if sp != "":
			top.texture = load(sp)
			top.centered = false
			var tss := top.texture.get_size()
			top.scale = Vector2(BMCore.W / tss.x, (BMMap.FLOOR_Y[3] + 26 - FLOOR_H) / tss.y)
			top.modulate = Color(0.6, 0.66, 0.8)
			building.add_child(top)
			building.move_child(top, 0)
	# the whole scene is dim; the lights bring the open floors up
	var cm := CanvasModulate.new()
	cm.color = Color(0.42, 0.45, 0.55)
	add_child(cm)
	# --- the rooms ---------------------------------------------------------------------------
	for n in BMMap.NODES:
		_marker(n)
	# --- the walker ----------------------------------------------------------------------------
	walker = Node2D.new()
	add_child(walker)
	walker_sprite = Sprite2D.new()
	var wt := Sprites.tex("player")
	if wt != null:
		walker_sprite.texture = wt
		var ws := wt.get_size()
		walker_sprite.scale = Vector2(58.0 / ws.y, 58.0 / ws.y)
		walker_sprite.offset = Vector2(0, -ws.y / 2)
		walker.add_child(walker_sprite)
	else:
		walker_vec = IconBoxVec.new(func(ci): Sprites.player(ci, Vector2(0, -14), clock, 1.0 if walking else 0.0, face, 0.0, false, false), Vector2(1, 1), 1.4)
		walker.add_child(walker_vec)
	walker_light = PointLight2D.new()
	walker_light.texture = radial(128)
	walker_light.texture_scale = 2.0
	walker_light.energy = 0.9
	walker_light.color = Palette.GOLD_PALE
	walker_light.position = Vector2(0, -20)
	walker.add_child(walker_light)
	walker.position = BMMap.pos(at)
	# --- the forgiving tap ---------------------------------------------------------------
	# The markers are 84x96 boxes on a 420x640 canvas. A thumb is wider than that, and a
	# tap that lands two pixels outside one used to do NOTHING -- no walk, no toast, no
	# clue that the rooms were the thing to press. That is how the whole second half of
	# this game (the reflex days, triage, review, deploy) stayed invisible: they are all
	# behind a tap that was too small to hit. So the map catches every tap that missed a
	# marker and routes it to the nearest room, if one is anywhere near.
	_catcher = Control.new()
	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catcher.size = Vector2(BMCore.W, BMCore.H)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)
	move_child(_catcher, 0)      # every marker is a later sibling, so markers still win
	# the floor tags
	for f in 4:
		var l := Label.new()
		l.text = BMStrings.t("floor_%d" % f)
		l.theme_type_variation = "Tag"
		l.add_theme_font_size_override("font_size", 9)
		l.add_theme_color_override("font_color", Palette.TUBE)
		l.position = Vector2(8, BMMap.FLOOR_Y[f] - FLOOR_H + 34)
		add_child(l)


class IconBoxVec extends Control:
	var fn: Callable
	func _init(f: Callable, sz: Vector2, sc := 1.0) -> void:
		fn = f
		custom_minimum_size = sz
		size = sz
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		scale = Vector2(sc, sc)
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		fn.call(self)


func _marker(n: Dictionary) -> void:
	var id: String = n["id"]
	var p := BMMap.pos(id)
	var root := Control.new()
	root.position = p + Vector2(-42, -92)
	root.size = Vector2(84, 96)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: tapped.emit(id))
	add_child(root)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Card"
	frame.position = Vector2(4, 0)
	frame.size = Vector2(76, 60)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	var win := TextureRect.new()
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spec: Array = WINDOW.get(id, ["mon", 0.5, 0.5])
	var pp := plate_path(spec[0])
	if pp != "":
		var tex: Texture2D = load(pp)
		var ts := tex.get_size()
		var a := AtlasTexture.new()
		a.atlas = tex
		var rw := ts.x * 0.62
		var rh := rw * 0.7
		a.region = Rect2(ts.x * float(spec[1]) - rw / 2, ts.y * float(spec[2]) - rh / 2, rw, rh)
		win.texture = a
	win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	win.custom_minimum_size = Vector2(66, 48)
	frame.add_child(win)
	var name := Label.new()
	name.text = BMStrings.t("node_" + id)
	name.theme_type_variation = "Tag"
	name.add_theme_font_size_override("font_size", 9)
	name.add_theme_font_override("font", _fonts_font)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.position = Vector2(-20, 62)
	name.size = Vector2(124, 14)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name)
	var tag := Label.new()
	tag.theme_type_variation = "Tag"
	tag.add_theme_font_size_override("font_size", 8)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(-20, 76)
	tag.size = Vector2(124, 12)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tag)
	var light := PointLight2D.new()
	light.texture = radial(160)
	light.texture_scale = 2.0
	light.enabled = false
	light.position = p + Vector2(0, -50)
	light.color = Palette.TUBE
	light.energy = 0.0
	add_child(light)
	markers[id] = {"root": root, "frame": frame, "win": win, "name": name, "tag": tag}
	lights[id] = light


## Re-read the profile: which rooms are lit, cleared, locked; where the walker stands.
func refresh(profile: Dictionary) -> void:
	at = BMMap.at(profile)
	if not walking:
		walker.position = BMMap.pos(at)
	for id in markers:
		var st := BMMap.state(profile, id)
		var m: Dictionary = markers[id]
		var n := BMMap.node(id)
		var runs: int = int(BMMap.ensure(profile)["runs"].get(id, 0))
		match st:
			"locked":
				m["win"].modulate = Color(0.28, 0.3, 0.36)
				m["name"].add_theme_color_override("font_color", Palette.DIM)
				m["tag"].text = BMStrings.t("locked")
				m["tag"].add_theme_color_override("font_color", Palette.MUTED)
				lights[id].enabled = false
			"open":
				m["win"].modulate = Color(1, 1, 1)
				m["name"].add_theme_color_override("font_color", Palette.TEXT)
				m["tag"].text = "" if BMMap.ALWAYS_OPEN.has(n["type"]) else BMStrings.t("kind_" + n["type"]).split(" · ")[0].to_upper()
				m["tag"].add_theme_color_override("font_color", Palette.TUBE)
				lights[id].enabled = true
				lights[id].energy = 1.1
			_:
				m["win"].modulate = Color(0.95, 0.92, 0.85)
				m["name"].add_theme_color_override("font_color", Palette.GOLD)
				m["tag"].text = BMStrings.t("cleared_tag") + (" · " + BMStrings.t("runs", {"n": runs}) if runs > 1 else "")
				m["tag"].add_theme_color_override("font_color", Palette.GOLD)
				lights[id].enabled = true
				lights[id].energy = 0.7
				lights[id].color = Palette.GOLD_PALE


## Walk a BMMap.path: along the floor to the lift, up or down the shaft, along the floor.
func walk(path: Array) -> void:
	if path.size() < 2 or walking:
		if path.size() == 1:
			arrived.emit(path[0])
		return
	walking = true
	var pts: Array = [walker.position]
	for i in range(1, path.size()):
		var a := BMMap.pos(path[i - 1])
		var b := BMMap.pos(path[i])
		if a.y != b.y:
			pts.append(Vector2(BMMap.LIFT_X, a.y))
			pts.append(Vector2(BMMap.LIFT_X, b.y))
		pts.append(b)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var cur: Vector2 = pts[0]
	for i in range(1, pts.size()):
		var nxt: Vector2 = pts[i]
		var d := cur.distance_to(nxt)
		if d < 0.5:
			continue
		var vertical := absf(nxt.x - cur.x) < 0.5
		var dur := d / (LIFT_SPEED if vertical else WALK_SPEED)
		if not vertical:
			var f := 1.0 if nxt.x > cur.x else -1.0
			_tween.tween_callback(func(): face = f; if walker_sprite: walker_sprite.flip_h = f < 0)
		_tween.tween_property(walker, "position", nxt, dur).set_trans(Tween.TRANS_SINE if vertical else Tween.TRANS_LINEAR)
		cur = nxt
	var dest: String = path[path.size() - 1]
	_tween.tween_callback(func():
		walking = false
		at = dest
		arrived.emit(dest))


func _process(dt: float) -> void:
	clock += dt
	# 2.5D: the sky slides against the building as the character climbs; the walker bobs
	var climb: float = (BMMap.FLOOR_Y[0] - walker.position.y) / (BMMap.FLOOR_Y[0] - BMMap.FLOOR_Y[3])
	if sky:
		sky.position = Vector2(-40 + climb * 24.0, -40 + climb * 30.0)
	building.position = Vector2(0, climb * 6.0)
	if walker_sprite:
		walker_sprite.position.y = -absf(sin(clock * 12.0)) * 3.0 if walking else -absf(sin(clock * 1.6)) * 1.0
	walker_light.energy = 0.85 + sin(clock * 3.0) * 0.08
