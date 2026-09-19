class_name FloorView
extends Control
## The floor: the parent's 5x4 isometric desk, drawn as furniture positions in the room.
## Cells are diamonds on the floor plane; pieces are Piece nodes that drop in; the link
## lines of a settle are drawn between pieces and sparks run along them on a commit.

signal cell_clicked(i: int)

var cells: Array = Landlord.empty_cells()
var result: Dictionary = {}
var selected_id := ""
var hover := -1
var caption := "FLOOR 1 · 5 × 4"
var punch := 0.0
var t := 0.0
var pieces: Dictionary = {}   # index -> Piece
var ox := 0.0
var oy := 0.0
var tw := 96.0
var th := 50.0
var coins: CPUParticles2D
var _sparks: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	coins = CPUParticles2D.new()
	coins.emitting = false
	coins.one_shot = true
	coins.explosiveness = 0.9
	coins.amount = 28
	coins.lifetime = 1.1
	coins.direction = Vector2(0, -1)
	coins.spread = 60.0
	coins.gravity = Vector2(0, 220)
	coins.initial_velocity_min = 140.0
	coins.initial_velocity_max = 260.0
	coins.scale_amount_min = 2.0
	coins.scale_amount_max = 3.4
	coins.color = Look.AMBER
	var g := Gradient.new()
	g.set_color(0, Color(Look.LAMP, 1.0))
	g.set_color(1, Color(Look.AMBER, 0.0))
	coins.color_ramp = g
	add_child(coins)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var span := float(Landlord.COLS + Landlord.ROWS)
	var w := size.x
	var h := size.y
	var tw_w := (w * 0.92) * 2.0 / span
	var tw_h := (h * 0.86) * 2.0 / (span * 0.52)
	tw = clamp(min(tw_w, tw_h), 40.0, 118.0)
	th = tw * 0.52
	ox = w * 0.5
	var grid_h := span * th / 2.0
	oy = (h - grid_h) * 0.5 + th * 0.5
	for i in pieces.keys():
		var p: Piece = pieces[i]
		var xy := Landlord.xy_of(i)
		p.position = iso(xy.x, xy.y)
		p.setup(p.id, tw, th)
	queue_redraw()


func iso(x: float, y: float) -> Vector2:
	return Vector2(ox + (x - y) * (tw / 2.0), oy + (x + y) * (th / 2.0))


func cell_at(p: Vector2) -> int:
	var best := -1
	var best_d := 1e9
	for i in range(Landlord.SIZE):
		var xy := Landlord.xy_of(i)
		var c := iso(xy.x, xy.y)
		var dx := p.x - c.x
		var dy := p.y - (c.y + th * 0.15)
		var d := (dx * dx) / (tw * tw) + (dy * dy) / (th * th)
		if d < 0.55 and d < best_d:
			best_d = d
			best = i
	return best


## Rebuild the pieces from a cells array. `dropped` is the index that was just placed
## (it drops in); everything else appears in place.
func set_cells(next: Array, dropped: int = -1) -> void:
	cells = next.duplicate()
	for i in range(Landlord.SIZE):
		var id: String = "" if cells[i] == null else str(cells[i])
		if id == "":
			if pieces.has(i):
				var gone: Piece = pieces[i]
				pieces.erase(i)
				var tw2 := gone.create_tween()
				tw2.tween_property(gone, "lift", -60.0, 0.18).set_trans(Tween.TRANS_QUAD)
				tw2.parallel().tween_property(gone, "modulate:a", 0.0, 0.18)
				tw2.tween_callback(gone.queue_free)
			continue
		if pieces.has(i) and (pieces[i] as Piece).id == id:
			continue
		if pieces.has(i):
			(pieces[i] as Piece).queue_free()
		var p := Piece.new()
		var xy := Landlord.xy_of(i)
		p.position = iso(xy.x, xy.y)
		p.setup(id, tw, th)
		p.z_index = xy.x + xy.y
		add_child(p)
		pieces[i] = p
		if i == dropped:
			p.drop_in()
	queue_redraw()


func set_result(r: Dictionary) -> void:
	result = r
	for i in pieces.keys():
		var p: Piece = pieces[i]
		p.score = int(r["cellScore"][i]) if r.has("cellScore") else 0
	queue_redraw()


## A commit: the room punches, coins rise, sparks run along every link.
func burst(payout: int) -> void:
	punch = 1.0
	coins.position = iso(2.0, 1.5)
	coins.amount = min(40, 10 + payout)
	coins.restart()
	coins.emitting = true
	if result.has("links"):
		var k := 0
		for link in result["links"]:
			_spark(int(link["a"]), int(link["b"]), str(link["kind"]), k * 0.04)
			k += 1
	for i in pieces.keys():
		(pieces[i] as Piece).pop()


func _spark(a: int, b: int, kind: String, delay: float) -> void:
	var s := Node2D.new()
	var col := _link_color(kind)
	s.set_script(preload("res://scripts/spark.gd"))
	s.set("color", col)
	var pa := Landlord.xy_of(a)
	var pb := Landlord.xy_of(b)
	var from := iso(pa.x, pa.y) + Vector2(0, -th * 0.5)
	var to := iso(pb.x, pb.y) + Vector2(0, -th * 0.5)
	s.position = from
	s.z_index = 50
	add_child(s)
	var tw2 := s.create_tween()
	tw2.tween_interval(delay)
	tw2.tween_property(s, "position", to, 0.28).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(s, "modulate:a", 0.0, 0.18)
	tw2.tween_callback(s.queue_free)


static func _link_color(kind: String) -> Color:
	if kind == "wes-tax":
		return Look.EMBER
	if kind.find("shield") >= 0:
		return Look.STEEL.lightened(0.2)
	if kind == "nia-audit" or kind == "sol-late":
		return Look.ROSE
	return Look.AMBER


func _process(delta: float) -> void:
	t += delta
	if punch > 0.0:
		punch *= 0.86
		if punch < 0.01:
			punch = 0.0
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := cell_at(ev.position)
		if h != hover:
			hover = h
			queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var i := cell_at(ev.position)
		if i >= 0:
			cell_clicked.emit(i)
			accept_event()
	elif ev is InputEventScreenTouch and ev.pressed:
		var i := cell_at(ev.position)
		if i >= 0:
			cell_clicked.emit(i)
			accept_event()


func _draw() -> void:
	var s := 1.0 + punch * 0.018
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.5) * (1.0 - s), 0.0, Vector2(s, s))
	# the floor plate: a dark rug under the desks
	var a := iso(-0.85, -0.85)
	var b := iso(Landlord.COLS - 0.15, -0.85)
	var c := iso(Landlord.COLS - 0.15, Landlord.ROWS - 0.15)
	var d := iso(-0.85, Landlord.ROWS - 0.15)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, 10), b + Vector2(0, 10), c + Vector2(0, 10), d + Vector2(0, 10)]), Color(0, 0, 0, 0.45))
	draw_colored_polygon(PackedVector2Array([a, b, c, d]), Color(0.06, 0.11, 0.125, 0.92))
	draw_polyline(PackedVector2Array([a, b, c, d, a]), Look.LINE2, 1.2, true)
	# the desks: diamonds, back to front
	var order: Array = range(Landlord.SIZE)
	order.sort_custom(func(i: int, j: int) -> bool:
		var A := Landlord.xy_of(i)
		var B := Landlord.xy_of(j)
		return (A.x + A.y) < (B.x + B.y))
	for i in order:
		var p := Landlord.xy_of(i)
		var hv: bool = (hover == i)
		var lift := 5.0 if hv else 0.0
		var cc := iso(p.x, p.y)
		var hw := tw * 0.48
		var hh := th * 0.48
		var top := cc.y - lift
		var filled: bool = cells[i] != null
		var checker := (p.x + p.y) % 2
		var fill := Color("#1a3d34") if filled else (Color("#142c34") if checker else Color("#1a3840"))
		if hv and selected_id != "" and not filled:
			fill = Color("#2a5a44")
		var poly := PackedVector2Array([Vector2(cc.x, top - hh), Vector2(cc.x + hw, top), Vector2(cc.x, top + hh), Vector2(cc.x - hw, top)])
		# the slab side
		draw_colored_polygon(PackedVector2Array([Vector2(cc.x - hw, top), Vector2(cc.x, top + hh), Vector2(cc.x, top + hh + 8), Vector2(cc.x - hw, top + 8)]), Color(0.04, 0.06, 0.08, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(cc.x + hw, top), Vector2(cc.x, top + hh), Vector2(cc.x, top + hh + 8), Vector2(cc.x + hw, top + 8)]), Color(0.03, 0.05, 0.07, 0.7))
		draw_colored_polygon(poly, fill)
		draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Look.AMBER if filled else Look.STEEL, 1.4 if filled else 1.0, true)
		if not filled and selected_id != "":
			# an open desk when something is in hand: a soft lamp pool
			draw_colored_polygon(poly, Color(Look.LAMP, 0.06 + 0.04 * sin(t * 4.0 + i)))
	# link lines of the current settle
	if result.has("links"):
		var alpha := 0.55 + sin(t * 5.0) * 0.15
		for link in result["links"]:
			var A := Landlord.xy_of(int(link["a"]))
			var B := Landlord.xy_of(int(link["b"]))
			var pa := iso(A.x, A.y) + Vector2(0, -th * 0.5)
			var pb := iso(B.x, B.y) + Vector2(0, -th * 0.5)
			var col := _link_color(str(link["kind"]))
			draw_line(pa, pb, Color(col, alpha), 2.0, true)
			draw_circle(pb, 3.0, Color(col, alpha))
	# caption
	var cap := iso((Landlord.COLS - 1) / 2.0, Landlord.ROWS - 0.15)
	draw_string(Look.font_mono, Vector2(cap.x - 150, cap.y + th + 22), caption, HORIZONTAL_ALIGNMENT_CENTER, 300, 12, Look.MUTED)
