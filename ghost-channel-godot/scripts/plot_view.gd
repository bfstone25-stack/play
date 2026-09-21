## PlotView — the 8×8 live plot, drawn.
##
## This one is vector on purpose and it is not a violation of "no code-drawn shapes where an
## asset should be": a plot is an *instrument readout*. It is drawn by the console out of
## live positions, and a painted picture of a grid would be a picture of the wrong grid the
## moment anybody moved. What sits underneath it — the console's steel, the scratches, the
## worn paint — is the plate (assets/art/console_bed.png), and the phosphor is drawn on top
## of it. That is the division the real object has.
##
## Ported from the prototype's loopMap(): the same 8×8, the same five marker shapes, the
## same per-agent colour, the same magenta box on the request's target, and the same
## op-3 spoof where the mimic's blip jumps two columns and one row for part of each cycle.
extends Control

var state: Dictionary = {}            # the GCRules state, or {} before an op starts
var _t := 0.0
var _sweep := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_sweep = fmod(_sweep + delta * 0.22, 1.0)
	queue_redraw()


func _cell() -> Vector2:
	return Vector2(size.x - 46.0, size.y - 40.0) / 8.0


func _at(gx: int, gy: int) -> Vector2:
	var c := _cell()
	return Vector2(36.0 + gx * c.x + c.x * 0.5, 26.0 + gy * c.y + c.y * 0.5)


func _draw() -> void:
	var c := _cell()
	var grid := Rect2(36, 26, c.x * 8, c.y * 8)

	# the bed: the console's own surface, under everything
	var bed := "res://assets/art/console_bed.png"
	if ResourceLoader.exists(bed):
		# The bed is the console's steel, not a picture to look at: pushed well down so the
		# phosphor drawn on top of it is the brightest thing in the panel, which is the
		# whole point of a plot.
		draw_texture_rect(load(bed), Rect2(Vector2.ZERO, size), false, Color(0.30, 0.35, 0.40, 1.0))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.GROUND_DEEP, true)
	draw_rect(grid, Color(Palette.GROUND_DEEP, 0.55), true)

	# the sweep: a soft bar crossing the plot, the way a scope refreshes
	var sx: float = grid.position.x + grid.size.x * _sweep
	draw_rect(Rect2(sx - 26, grid.position.y, 26, grid.size.y), Color(Palette.SUCCESS, 0.05), true)
	draw_line(Vector2(sx, grid.position.y), Vector2(sx, grid.end.y), Color(Palette.SUCCESS, 0.16), 1.0)

	# the rules
	for i in range(9):
		var x: float = grid.position.x + i * c.x
		var y: float = grid.position.y + i * c.y
		draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), Color(Palette.SUCCESS, 0.12), 1.0)
		draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), Color(Palette.SUCCESS, 0.12), 1.0)
	draw_rect(grid, Color(Palette.SUCCESS, 0.3), false, 1.0)

	# the labels: A..H across, 1..8 down, monospace, the way the readout is
	var mono := StudioTheme.font("mono")
	for i in range(8):
		mono.draw_string(get_canvas_item(), Vector2(grid.position.x + i * c.x + c.x * 0.5 - 4, grid.position.y - 8),
			String.chr(65 + i), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Palette.MUTED, 0.9))
		mono.draw_string(get_canvas_item(), Vector2(10, grid.position.y + i * c.y + c.y * 0.5 + 4),
			str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Palette.MUTED, 0.9))

	if state.is_empty():
		return

	for a in state.agents:
		if not a.alive:
			continue
		var gx: int = int(a.grid[0])
		var gy: int = int(a.grid[1])
		# op 3: the map itself lies about where the mimic is, for part of every cycle
		if state.op.mapSpoof and a.id == state.mimicId and sin(_t * 2.5) > 0.2:
			gx = (gx + 2) % 8
			gy = (gy + 1) % 8
		var p := _at(gx, gy)
		var col: Color = Palette.callsign(a.id)
		draw_circle(p, c.x * 0.32, Color(col, 0.20))
		_marker(p, a.id, col, minf(c.x, c.y) * 0.22)
		var nf := StudioTheme.font("bold")
		var nm: String = GCRules.who(state, a)
		var nw := nf.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		nf.draw_string(get_canvas_item(), p + Vector2(-nw * 0.5, c.y * 0.46), nm,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.TEXT, 0.9))

	if state.request != null and state.request.target != null:
		var g: Array = state.request.target
		var p := _at(int(g[0]), int(g[1]))
		var pulse: float = 0.6 + 0.4 * sin(_t * 5.0)
		var box := Rect2(p - Vector2(c.x, c.y) * 0.44, Vector2(c.x, c.y) * 0.88)
		draw_rect(box, Color(Palette.HEAT, pulse), false, 2.0)
		# the corner ticks: a target box, not a selection rectangle
		var k := minf(c.x, c.y) * 0.22
		for corner in [[box.position, Vector2(1, 1)], [Vector2(box.end.x, box.position.y), Vector2(-1, 1)],
				[Vector2(box.position.x, box.end.y), Vector2(1, -1)], [box.end, Vector2(-1, -1)]]:
			var o: Vector2 = corner[0]
			var d: Vector2 = corner[1]
			draw_line(o, o + Vector2(d.x * k, 0), Color(Palette.HEAT, pulse), 2.0)
			draw_line(o, o + Vector2(0, d.y * k), Color(Palette.HEAT, pulse), 2.0)


## The five marker shapes, exactly the prototype's drawMarker().
func _marker(p: Vector2, id: String, col: Color, s: float) -> void:
	var pts := PackedVector2Array()
	match id:
		"viper":
			pts = PackedVector2Array([Vector2(0, -s), Vector2(s * 0.7, s), Vector2(0, s * 0.45), Vector2(-s * 0.7, s)])
		"moth":
			# two wings: drawn as two triangles meeting at the body
			for sign in [-1.0, 1.0]:
				var w := PackedVector2Array([Vector2(0, 0), Vector2(sign * s * 1.2, -s * 0.5), Vector2(sign * s * 1.0, s * 0.45)])
				for i in w.size():
					w[i] = w[i] + p
				draw_colored_polygon(w, col)
			return
		"hex":
			for i in range(6):
				var ang: float = PI / 3.0 * i - PI / 6.0
				pts.append(Vector2(cos(ang) * s, sin(ang) * s))
		"raven":
			pts = PackedVector2Array([Vector2(0, -s), Vector2(s, s * 0.3), Vector2(0, s * 0.1), Vector2(-s, s * 0.3)])
		_:
			pts = PackedVector2Array([Vector2(0, -s), Vector2(s * 0.75, 0), Vector2(0, s), Vector2(-s * 0.75, 0)])
	for i in pts.size():
		pts[i] = pts[i] + p
	draw_colored_polygon(pts, col)
