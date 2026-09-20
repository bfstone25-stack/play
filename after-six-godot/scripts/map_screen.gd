## MapScreen — AFTER SIX: the building, cut open, after six.
##
## What this is, and what it stopped being (rebuild, 2026-09-19). The first version was a
## grid of thumbnails on a backdrop, which is the one form `ops/adult_forks/beat_monday_map.md`
## §1.1 forbids in those words: *"Not a stack of thumbnails on a backdrop: the building
## itself, cut open"* — the architect's-model / dollhouse view. So the screen is now a
## section through the building: one concrete mass, four floor slabs cut through it, a lift
## shaft up the right, and a **room cut into the mass for every node**, each opening showing
## that room's own rendered interior with the thickness of the cut concrete visible around
## it. The character stands on a floor slab, inside a cell, and walks the slabs and rides
## the shaft between them. Progress is how much of the section is lit.
##
## The night rule, which is the whole picture (§2, §1.1's last bullet): **a lit cell means
## someone is still in it**, and the tag under a lit cell says who (BMStrings `who_*`).
## Only a few windows are on. That is read straight off the map, and it is the crime line's
## picture.
##
## 2.5D, per §1.1. Not true 3D and not a flat grid:
##   * the section is drawn in oblique projection — every opening and slab carries its
##     depth face (EXTRUDE), so you see the *thickness* of what was cut through;
##   * four parallax rates — sky, the mass and its rooms, the walker, the near slab edge —
##     against a slow camera drift, so the section has air in front of and behind it;
##   * a PointLight2D per lit room, spilling onto the concrete around its opening.
##
## Light, per `ops/adult_forks/UI_DIRECTION.md`. The failure this replaces was one pink
## multiply over everything: neither dark nor hot, a midpoint. Here the section is nearly
## black — the concrete sits at ~0.13, the sky at ~0.20 — and a handful of rooms are
## genuinely warm at full modulate with a lamp behind them. The accent is *earned by
## contrast*: magenta appears only on the tag of a room someone is in, and on the plaque of
## the room the character is standing in. Nothing is tinted globally, and there is no
## CanvasModulate: it would drag main.gd's header and footer down with it, which is half of
## why the old frame read grey.
##
## Legibility, per `ops/adult_forks/TITLE_SCREENS.md` §"The playfield is not the title
## screen". A dark room is *an interior you cannot make out* — the plate at a low, cool
## exposure, furniture just discernible — never a filled black rectangle with grey type on
## it. Every room name sits on a plaque struck into its floor slab, so it has a readable
## ground whether the room is lit or dark, and every label carries `light_mask = 0` so a
## lamp never washes its own caption out.
##
## No code-drawn shapes (studio rules 2026-09-18, rule 2): every visible surface is a
## rendered plate, a cut of one, a textured polygon carrying the concrete plate, a sprite,
## a Theme panel or a Label.
##
## Reads BMMap for the graph and the profile for state; owns only presentation (the walk
## tween, the drift, the bob). Emits `arrived(node_id)` when a walk ends and `tapped(node_id)`
## when a room is tapped; main.gd decides what a tap means.
extends Node2D

signal tapped(node_id: String)
signal arrived(node_id: String)

const WALK_SPEED := 190.0
const LIFT_SPEED := 150.0

# --- the section's geometry ----------------------------------------------------------------
## The opening cut for one room, and the slab band under it that carries the name plaque.
## A cell fills its storey: 86 of the 132 between slabs, so the rooms ARE the section
## rather than thumbnails floating in it. 80 wide is the widest three cells fit across
## floor 3 with their plaques clear of each other.
const CELL_W := 80.0
const CELL_H := 70.0
const SLAB_H := 24.0
## Oblique projection: how far back-and-up a cut surface runs. This is the whole of the
## "cut open" read — a face with no depth is a rectangle, a face with depth is a section.
const EXTRUDE := Vector2(24.0, -13.0)
## The mass itself: left, right, and how far past the top floor / bottom floor it runs.
const MASS_L := 16.0
const MASS_R := 402.0
## The lift shaft up the right of the section; BMMap.LIFT_X (372) rides inside it.
const SHAFT_L := 356.0
const SHAFT_R := 400.0

## node id -> which room interior is cut in behind it. Two nodes share the corridor.
const ROOM := {
	"lobby": "lobby", "breakroom": "breakroom", "standup": "standup", "corridor1": "corridor",
	"inbox": "inbox", "allhands": "allhands", "review": "review", "corridor2": "corridor",
	"deploy": "deploy",
}
## Until After Six's own night interiors land, a room falls back to the day plate the night
## tint pass produced for it (play/after-six-godot/README.md, the honest placeholder list).
const FALLBACK := {
	"as_room_lobby": "lobby", "as_room_breakroom": "breakroom", "as_room_standup": "mon",
	"as_room_corridor": "corridor", "as_room_inbox": "tue", "as_room_allhands": "wed",
	"as_room_review": "thu", "as_room_deploy": "fri",
	"as_sky": "map_sky", "as_shell": "map_building",
	"lobby": "sat", "breakroom": "sat", "corridor": "mon", "map_sky": "title",
}

# --- the light the states are read in ---------------------------------------------------------
## A dark room is an unlit interior, not a black rectangle: low, cool, and still legible as
## furniture. A lit room is at full exposure and warm. A cleared room keeps its lamp on and
## nobody in it.
const TONE_DARK := Color(0.34, 0.32, 0.44)
## The night interiors are rendered under blue-ish ambient with one warm lamp. A lit cell
## has to read WARM against the concrete, so the lit tone pushes the lamp and pulls the
## ambient: this plus the gold PointLight2D is the whole of the "hot accent".
const TONE_LIT := Color(1.22, 0.96, 0.74)
const TONE_DONE := Color(0.62, 0.50, 0.40)
## The concrete of the section, and the brighter cut faces of a slab.
## The section has to be *visible* concrete, or the cells read as floating cards again:
## the first pass put the mass at 0.13 and it disappeared into the sky. The band is
## 0.10-0.34 — still nearly black beside a lit room at 1.0, but a building.
const CONCRETE := Color(0.15, 0.135, 0.175)
const CONCRETE_SLAB := Color(0.225, 0.20, 0.25)
const CONCRETE_CUT := Color(0.27, 0.24, 0.30)
const CONCRETE_SIDE := Color(0.075, 0.065, 0.095)

var art: Node2D          # the parallax group: everything that is not a label
var sky: Sprite2D
var mass: Node2D         # the concrete section and its slabs
var rooms: Node2D        # the openings cut into it
var fg: Node2D           # the near slab edge, in front of the character
var walk_layer: Node2D   # holds the walker, so the drift never fights the walk tween
var labels: Node2D       # plaques and type; never lit, never dimmed
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
var _shell: Texture2D


static func plate_path(name: String) -> String:
	var p := "res://assets/art/plate_%s.webp" % name
	if ResourceLoader.exists(p):
		return p
	var fb: String = FALLBACK.get(name, "")
	if fb != "":
		return plate_path(fb) if fb != name else ""
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


## The top of a floor slab: the line the character's feet stand on.
static func floor_y(f: int) -> float:
	return BMMap.FLOOR_Y[f]


## The opening cut for a node: its rect in the front face of the mass.
static func cell_rect(id: String) -> Rect2:
	var p := BMMap.pos(id)
	# min x keeps a plaque off the floor tag struck into the left end of the slab
	var x: float = clampf(p.x - CELL_W / 2.0, MASS_L + 44.0, SHAFT_L - CELL_W - 4.0)
	return Rect2(x, p.y - CELL_H, CELL_W, CELL_H)


## One textured face of the section. Every surface on this screen goes through here, so
## nothing on it is a code-drawn shape: the polygon only says where, the concrete plate
## says what it looks like. uv == the screen polygon, so the concrete keeps one scale
## across the whole section however a face is angled.
func _face(parent: Node2D, pts: PackedVector2Array, tint: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = pts
	if _shell != null:
		poly.texture = _shell
		poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		poly.uv = pts
	poly.color = tint
	parent.add_child(poly)
	return poly


## A rectangle's face, given its corners.
func _rect_face(parent: Node2D, r: Rect2, tint: Color) -> Polygon2D:
	return _face(parent, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y),
		r.end, Vector2(r.position.x, r.end.y)]), tint)


## The depth face hanging off an edge: the thickness of what was cut through. This is the
## line that turns a rectangle into a section.
func _depth_face(parent: Node2D, a: Vector2, b: Vector2, tint: Color) -> Polygon2D:
	return _face(parent, PackedVector2Array([a, b, b + EXTRUDE, a + EXTRUDE]), tint)


func _ready() -> void:
	_fonts_font = StudioTheme.font("display")
	var shell_p := plate_path("as_shell")
	if shell_p != "":
		_shell = load(shell_p)

	art = Node2D.new()
	add_child(art)
	labels = Node2D.new()
	add_child(labels)

	# --- far: the night city, behind the section -------------------------------------------
	sky = Sprite2D.new()
	var sp := plate_path("as_sky")
	if sp != "":
		sky.texture = load(sp)
		sky.centered = false
		var ss := sky.texture.get_size()
		sky.scale = Vector2((BMCore.W + 96.0) / ss.x, (BMCore.H + 96.0) / ss.y)
		sky.position = Vector2(-48, -48)
		# deep, and not pink: the sky is the dark the lit rooms are read against
		sky.modulate = Color(0.24, 0.21, 0.34)
	art.add_child(sky)

	# --- the mass: one block of concrete, cut through ---------------------------------------
	mass = Node2D.new()
	art.add_child(mass)
	var top_y := floor_y(3) - CELL_H - 6.0
	var bot_y := floor_y(0) + SLAB_H
	var front := Rect2(MASS_L, top_y, MASS_R - MASS_L, bot_y - top_y)
	# the roof and the right flank, in projection: the two faces that say this is a solid
	_depth_face(mass, Vector2(MASS_L, top_y), Vector2(MASS_R, top_y), CONCRETE_CUT)
	_depth_face(mass, Vector2(MASS_R, top_y), Vector2(MASS_R, bot_y), CONCRETE_SIDE)
	_rect_face(mass, front, CONCRETE)
	# the four floor slabs, each cut through: a front band, and the slab's top going back
	for f in 4:
		var fy := floor_y(f)
		_rect_face(mass, Rect2(MASS_L, fy, MASS_R - MASS_L, SLAB_H), CONCRETE_SLAB)
		_depth_face(mass, Vector2(MASS_L, fy + SLAB_H), Vector2(MASS_R, fy + SLAB_H), CONCRETE_SIDE)
	# the lift shaft up the right, and its own depth: the edges the walker rides between
	_rect_face(mass, Rect2(SHAFT_L, top_y, SHAFT_R - SHAFT_L, bot_y - top_y), CONCRETE_SIDE)
	_depth_face(mass, Vector2(SHAFT_L, top_y), Vector2(SHAFT_L, bot_y), CONCRETE_CUT)

	# --- the rooms cut into it ----------------------------------------------------------------
	rooms = Node2D.new()
	art.add_child(rooms)
	for n in BMMap.NODES:
		_marker(n)

	# --- the character, standing on a slab, inside a cell --------------------------------------
	walk_layer = Node2D.new()
	art.add_child(walk_layer)
	walker = Node2D.new()
	walk_layer.add_child(walker)
	walker_sprite = Sprite2D.new()
	var wt := Sprites.tex("player")
	if wt != null:
		walker_sprite.texture = wt
		var ws := wt.get_size()
		walker_sprite.scale = Vector2(54.0 / ws.y, 54.0 / ws.y)
		walker_sprite.offset = Vector2(0, -ws.y / 2)
		walker.add_child(walker_sprite)
	else:
		walker_vec = IconBoxVec.new(func(ci): Sprites.player(ci, Vector2(0, -14), clock, 1.0 if walking else 0.0, face, 0.0, false, false), Vector2(1, 1), 1.4)
		walker.add_child(walker_vec)
	walker_light = PointLight2D.new()
	walker_light.texture = radial(128)
	walker_light.texture_scale = 1.6
	walker_light.energy = 0.7
	walker_light.color = Palette.GOLD
	walker_light.position = Vector2(0, -20)
	walker.add_child(walker_light)
	walker.position = BMMap.pos(at)

	# --- near: the slab edge the section is standing on, in front of everything ----------------
	fg = Node2D.new()
	art.add_child(fg)
	var fy0 := floor_y(0) + SLAB_H
	_depth_face(fg, Vector2(MASS_L - 14, fy0 + 12), Vector2(MASS_R + 14, fy0 + 12), Color(0.10, 0.085, 0.12))
	_rect_face(fg, Rect2(MASS_L - 14, fy0 + 12, MASS_R - MASS_L + 28, 26), Color(0.07, 0.06, 0.09))

	# --- the floor tags, struck into the left edge of each slab --------------------------------
	for f in 4:
		var l := Label.new()
		l.text = BMStrings.t("floor_%d" % f)
		l.theme_type_variation = "Tag"
		l.add_theme_font_size_override("font_size", 7)
		l.add_theme_font_override("font", _fonts_font)
		l.add_theme_color_override("font_color", Palette.DIM)
		l.position = Vector2(MASS_L + 3, floor_y(f) + 7)
		l.light_mask = 0
		labels.add_child(l)


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


## One room: an opening cut into the mass, the room's own interior set into it, the
## thickness of the cut concrete around it, the room's floor running back from the front
## edge, and — on the slab below — a plaque with the room's name on a ground you can read
## whether the room is lit or dark.
func _marker(n: Dictionary) -> void:
	var id: String = n["id"]
	var r := cell_rect(id)

	# the interior, clipped to the opening
	var clip := Control.new()
	clip.position = r.position
	clip.size = r.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rooms.add_child(clip)
	var win := TextureRect.new()
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pp := plate_path("as_room_" + str(ROOM.get(id, "corridor")))
	if pp != "":
		win.texture = load(pp)
	win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	win.size = r.size
	clip.add_child(win)

	# the cut: the concrete's thickness along the head and the two jambs of the opening
	var reveal := Node2D.new()
	rooms.add_child(reveal)
	_depth_face(reveal, r.position, Vector2(r.end.x, r.position.y), CONCRETE_CUT)
	_depth_face(reveal, r.position, Vector2(r.position.x, r.end.y), CONCRETE_SIDE)
	# the room's own floor, running back from the front edge the character stands on
	var floor_face := _depth_face(rooms, Vector2(r.position.x, r.end.y), r.end, CONCRETE_CUT)

	# the lamp behind the opening, spilling onto the concrete around it
	var light := PointLight2D.new()
	light.texture = radial(160)
	light.texture_scale = 1.7
	light.enabled = false
	light.position = r.position + Vector2(r.size.x / 2.0, r.size.y * 0.45)
	light.color = Palette.GOLD
	light.energy = 0.0
	art.add_child(light)

	# --- the type, on grounds of its own, never lit and never dimmed --------------------------
	# who is in the room: over the foot of the picture, on a plaque so it reads against a
	# bright lamp as well as a dark one. Only a lit room has one.
	var who_panel := PanelContainer.new()
	who_panel.theme_type_variation = "Card"
	who_panel.position = Vector2(r.position.x - 6, r.end.y - 20)
	who_panel.custom_minimum_size = Vector2(r.size.x + 12, 16)
	who_panel.size = Vector2(r.size.x + 12, 16)
	who_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who_panel.light_mask = 0
	who_panel.add_theme_stylebox_override("panel",
		StudioTheme.flat(Color(Palette.INK, 0.88), Color(Palette.ACCENT_DEEP, 0.7), 4, 1, Vector2(3, 1)))
	labels.add_child(who_panel)
	var tag := Label.new()
	tag.theme_type_variation = "Tag"
	tag.add_theme_font_size_override("font_size", 8)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.light_mask = 0
	tag.custom_minimum_size = Vector2(r.size.x + 4, 12)
	who_panel.add_child(tag)

	# the room's name, struck into the slab below it: the architect's-model label, and the
	# readable ground a dark room's name needs
	var plaque := PanelContainer.new()
	plaque.position = Vector2(r.position.x - 6, r.end.y + 3)
	plaque.custom_minimum_size = Vector2(r.size.x + 12, 20)
	plaque.size = Vector2(r.size.x + 12, 20)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.light_mask = 0
	labels.add_child(plaque)
	var name_l := Label.new()
	name_l.text = BMStrings.t("node_" + id)
	name_l.add_theme_font_size_override("font_size", 9)
	name_l.add_theme_font_override("font", _fonts_font)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_l.light_mask = 0
	name_l.custom_minimum_size = Vector2(r.size.x + 4, 16)
	plaque.add_child(name_l)

	# the tap target: the opening and its plaque
	var hit := Control.new()
	hit.position = Vector2(r.position.x - 6, r.position.y)
	hit.size = Vector2(r.size.x + 12, r.size.y + 26)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: tapped.emit(id))
	labels.add_child(hit)

	markers[id] = {"win": win, "reveal": reveal, "floor": floor_face, "name": name_l,
		"plaque": plaque, "tag": tag, "who": who_panel}
	lights[id] = light


## Re-read the profile: which rooms are lit, cleared, dark; where the character stands.
func refresh(profile: Dictionary) -> void:
	at = BMMap.at(profile)
	if not walking:
		walker.position = BMMap.pos(at)
	for id in markers:
		var st := BMMap.state(profile, id)
		var m: Dictionary = markers[id]
		var runs: int = int(BMMap.ensure(profile)["runs"].get(id, 0))
		var here: bool = id == at
		match st:
			"locked":
				# dark: an interior you cannot make out. Not a filled rectangle — the plate
				# is there, at a low cool exposure, and the furniture is just discernible.
				m["win"].modulate = TONE_DARK
				m["reveal"].modulate = Color(0.8, 0.8, 0.9)
				m["floor"].modulate = Color(0.7, 0.7, 0.85)
				m["who"].visible = false
				m["name"].add_theme_color_override("font_color", Palette.DIM)
				lights[id].enabled = false
			"open":
				# a window on: someone is still in it, and the tag says who
				m["win"].modulate = TONE_LIT
				m["reveal"].modulate = Color(1.5, 1.32, 1.1)
				m["floor"].modulate = Color(1.7, 1.45, 1.15)
				m["who"].visible = true
				m["tag"].text = BMStrings.t("who_" + id)
				m["tag"].add_theme_color_override("font_color", Palette.ACCENT_SOFT)
				m["name"].add_theme_color_override("font_color", Palette.TEXT)
				lights[id].enabled = true
				lights[id].color = Palette.GOLD
				lights[id].energy = 1.25
			_:
				# done: the lamp left on, and nobody in it any more
				m["win"].modulate = TONE_DONE
				m["reveal"].modulate = Color(1.15, 1.05, 0.9)
				m["floor"].modulate = Color(1.25, 1.1, 0.92)
				m["who"].visible = true
				m["tag"].text = BMStrings.t("cleared_tag") + (" · " + BMStrings.t("runs", {"n": runs}) if runs > 1 else "")
				m["tag"].add_theme_color_override("font_color", Palette.GOLD_PALE)
				m["name"].add_theme_color_override("font_color", Palette.GOLD)
				lights[id].enabled = true
				lights[id].color = Palette.GOLD_PALE
				lights[id].energy = 0.55
		# the plaque: concrete, except the room the character is standing in, which takes
		# the one magenta edge on the screen. The accent is earned, never applied.
		var edge: Color = Palette.ACCENT if here else Color(Palette.LINE_SOFT, 0.9)
		var ground: Color = Color(Palette.PANEL, 0.95) if here else Color(Palette.INK, 0.92)
		m["plaque"].add_theme_stylebox_override("panel",
			StudioTheme.flat(ground, edge, 3, 1, Vector2(3, 1)))


## Walk a BMMap.path: along the slab to the shaft, up or down it, along the slab.
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
	# 2.5D: a slow camera drift with four rates against it — the city far behind, the
	# section and its rooms, and the near slab edge in front. The labels ride the section,
	# because they are struck into its slabs.
	var drift := Vector2(sin(clock * 0.11) * 5.0, sin(clock * 0.077) * 3.0)
	var climb: float = (floor_y(0) - walker.position.y) / (floor_y(0) - floor_y(3))
	if sky:
		sky.position = Vector2(-48, -48) - drift * 0.35 + Vector2(climb * 20.0, climb * 26.0)
	mass.position = drift
	rooms.position = drift
	walk_layer.position = drift
	labels.position = drift
	fg.position = drift * 1.7 + Vector2(0, climb * -4.0)
	if walker_sprite:
		walker_sprite.position.y = -absf(sin(clock * 12.0)) * 3.0 if walking else -absf(sin(clock * 1.6)) * 1.0
	walker_light.energy = 0.65 + sin(clock * 3.0) * 0.07
