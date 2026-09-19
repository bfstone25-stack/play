## VectorMark — the FOLD logotype, drawn.
##
## TITLE_SCREENS.md item 2: "a designed mark, not a font default … exported as an image or
## drawn with the engine's text effects, never a plain Label." FOLD already has a designed
## mark — the page draws it as hand-built SVG paths, one for the Latin FOLD and one for the
## Chinese 归一, each with a hairline construction grid under it, a crease across two
## letters and a small filled plane where the paper turns. That mark is the brand; setting
## the title in Marcellus instead would be a different logo.
##
## So the SVG path data is carried over verbatim (see PATHS below — the `d` strings are
## copied out of play/fold/frontend/index.html), and this node draws it: a minimal SVG path
## parser (M/L/H/V/C/S/Z, absolute and relative) flattening cubics into polylines, then
## `draw_polyline` for the strokes and `draw_colored_polygon` for the two filled planes.
##
## `reveal` (0 → 1) draws the mark on progressively, stroke by stroke and along each
## stroke, which is the "logotype settles in" of item 3. It is a real draw-on, not an
## alpha fade: the crease arrives last, after the letters, because that is the beat the
## mark is built around.
class_name VectorMark
extends Control

## Which mark: "en" draws FOLD, "zh" draws 归一.
@export var mark: String = "en":
	set(v):
		mark = v
		queue_redraw()

## 0 .. 1 — how much of the mark is drawn.
@export var reveal: float = 1.0:
	set(v):
		reveal = clampf(v, 0.0, 1.0)
		queue_redraw()

@export var ink: Color = Palette.TEXT
@export var accent: Color = Palette.GOLD
@export var hairline: Color = Color(Palette.MUTED, 0.30)

## Scale of the stroke weights relative to the design's own units.
@export var weight: float = 1.0

# --- the mark, as drawn on the page -------------------------------------------------------
# Each entry: [d, layer], where layer is one of
#   "letter"  the letter body        (ink, heavy)
#   "fine"    the construction grid  (hairline)
#   "crease"  the fold line          (accent, medium)
#   "plane"   the turned paper       (accent, FILLED)
const PATHS := {
	"en": {
		"box": Vector2(560, 170),
		"strokes": [
			["M38 22V146M38 24H126M38 82H112", "letter"],
			["M218 20C176 20 154 45 154 84S176 148 218 148 282 123 282 84 260 20 218 20Z", "letter"],
			["M320 22V146H397", "letter"],
			["M429 22V146M429 23H466C512 23 532 47 532 84S512 145 466 145H429", "letter"],
			["M20 84H540M218 9V159M411 10V158", "fine"],
			["M38 22L112 82L38 146M154 84L218 20L282 84L218 148Z", "fine"],
			["M183 139L253 29M457 23L501 84L457 145", "crease"],
			["M218 20L253 29L238 53ZM466 23L501 84L476 73Z", "plane"],
		],
	},
	# The Chinese mark: 归 built from its strokes, the 一 as a long axis to the right, the
	# little fold plane sitting on that axis, and a seal in the corner.
	"zh": {
		"box": Vector2(440, 170),
		"strokes": [
			["M58 24V116M34 72L58 54", "letter"],
			["M88 28H190V118H84M94 72H184", "letter"],
			["M71 18V128M79 136H206", "fine"],
			["M215 75H399", "letter"],
			["M308 75L322 59L337 75Z", "plane"],
			["M350 91H396V137H350Z", "crease"],
			["M359 109L373 99L387 109M363 111H383M361 118H385V130H361ZM373 111V118", "crease"],
		],
	},
}

const WIDTHS := {"letter": 9.0, "fine": 1.6, "crease": 4.0, "plane": 0.0}
# The order the mark is drawn on in: grid first (it is the scaffolding), then the letters,
# then the crease and the plane it turns.
const ORDER := ["fine", "letter", "crease", "plane"]

var _cache := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# --- SVG path parsing ---------------------------------------------------------------------

## Split a `d` string into tokens: single-letter commands and numbers.
static func _tokens(d: String) -> Array:
	var out := []
	var i := 0
	var n := d.length()
	while i < n:
		var ch := d[i]
		if ch in "MmLlHhVvCcSsZz":
			out.append(ch)
			i += 1
		elif ch in " ,\t\n\r":
			i += 1
		else:
			var j := i
			if d[j] in "+-":
				j += 1
			while j < n and (d[j].is_valid_int() or d[j] == "." or d[j] == "e"
					or (d[j] in "+-" and j > i and d[j - 1] == "e")):
				j += 1
			if j == i:
				i += 1            # unparseable byte: skip rather than loop forever
				continue
			out.append(float(d.substr(i, j - i)))
			i = j
	return out


## Flatten a cubic Bézier into `pts` (excluding p0, which is already there).
static func _cubic(pts: PackedVector2Array, p0: Vector2, c1: Vector2, c2: Vector2, p1: Vector2) -> void:
	var steps := 16
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var u := 1.0 - t
		pts.append(u * u * u * p0 + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * p1)


## Parse a `d` string into a list of subpaths: {"pts": PackedVector2Array, "closed": bool}.
static func parse_path(d: String) -> Array:
	var toks := _tokens(d)
	var subs := []
	var pts := PackedVector2Array()
	var closed := false
	var cur := Vector2.ZERO
	var start := Vector2.ZERO
	var last_c2 := Vector2.ZERO
	var had_curve := false
	var cmd := ""
	var i := 0

	var flush := func():
		if pts.size() > 1:
			subs.append({"pts": pts, "closed": closed})
		pts = PackedVector2Array()
		closed = false

	while i < toks.size():
		if toks[i] is String:
			cmd = toks[i]
			i += 1
			if cmd in "Zz":
				closed = true
				flush.call()
				cur = start
				had_curve = false
			continue
		if cmd == "":
			i += 1
			continue
		var rel := cmd == cmd.to_lower()
		match cmd.to_upper():
			"M":
				flush.call()
				var p := Vector2(toks[i], toks[i + 1])
				cur = cur + p if rel else p
				start = cur
				pts.append(cur)
				i += 2
				cmd = "l" if rel else "L"      # SVG: implicit lineto after a moveto
				had_curve = false
			"L":
				var p := Vector2(toks[i], toks[i + 1])
				cur = cur + p if rel else p
				pts.append(cur)
				i += 2
				had_curve = false
			"H":
				var x: float = toks[i]
				cur = Vector2(cur.x + x if rel else x, cur.y)
				pts.append(cur)
				i += 1
				had_curve = false
			"V":
				var y: float = toks[i]
				cur = Vector2(cur.x, cur.y + y if rel else y)
				pts.append(cur)
				i += 1
				had_curve = false
			"C":
				var c1 := Vector2(toks[i], toks[i + 1])
				var c2 := Vector2(toks[i + 2], toks[i + 3])
				var p := Vector2(toks[i + 4], toks[i + 5])
				if rel:
					c1 += cur
					c2 += cur
					p += cur
				if pts.is_empty():
					pts.append(cur)
				_cubic(pts, cur, c1, c2, p)
				cur = p
				last_c2 = c2
				had_curve = true
				i += 6
			"S":
				var c2 := Vector2(toks[i], toks[i + 1])
				var p := Vector2(toks[i + 2], toks[i + 3])
				if rel:
					c2 += cur
					p += cur
				# the reflection of the previous second control point, per the SVG spec
				var c1 := (cur * 2.0 - last_c2) if had_curve else cur
				if pts.is_empty():
					pts.append(cur)
				_cubic(pts, cur, c1, c2, p)
				cur = p
				last_c2 = c2
				had_curve = true
				i += 4
			_:
				i += 1
	flush.call()
	return subs


func _mark() -> Dictionary:
	return PATHS.get(mark, PATHS["en"])


func _subpaths() -> Array:
	var key := mark
	if _cache.has(key):
		return _cache[key]
	var out := []
	for entry in _mark()["strokes"]:
		for sub in parse_path(entry[0]):
			out.append({"pts": sub["pts"], "closed": sub["closed"], "layer": entry[1]})
	_cache[key] = out
	return out


## The design box, so a caller can size the Control to the mark's own aspect.
func aspect() -> float:
	var b: Vector2 = _mark()["box"]
	return b.x / b.y


# --- drawing -------------------------------------------------------------------------------

func _layer_color(layer: String) -> Color:
	match layer:
		"fine": return hairline
		"crease", "plane": return accent
	return ink


func _draw() -> void:
	var box: Vector2 = _mark()["box"]
	var s: float = minf(size.x / box.x, size.y / box.y)
	if s <= 0.0:
		return
	var off := (size - box * s) * 0.5
	var subs := _subpaths()
	# The hairline construction grid is part of the mark at title size and illegible mush
	# at HUD size — at 104 px wide the diagonals cross the letterforms and the whole thing
	# reads as a scribble. Below this width the mark is the letters, the crease and the
	# plane, which is what a small lockup of a logo is.
	var small := size.x < 190.0

	# The reveal runs through the layers in ORDER, each layer getting an equal share.
	var per := 1.0 / float(ORDER.size())
	for li in range(ORDER.size()):
		var layer: String = ORDER[li]
		var t := clampf((reveal - li * per) / per, 0.0, 1.0)
		if t <= 0.0:
			continue
		var col := _layer_color(layer)
		var w: float = WIDTHS[layer] * s * weight
		if small and layer == "fine":
			continue
		for sub in subs:
			if sub["layer"] != layer:
				continue
			var pts: PackedVector2Array = sub["pts"]
			var placed := PackedVector2Array()
			for p in pts:
				placed.append(off + p * s)
			if sub["closed"] and layer == "plane":
				# the turned paper: filled, and it fades in rather than drawing on
				draw_colored_polygon(placed, Color(col, 0.85 * t))
				continue
			var drawn := _partial(placed, t)
			if drawn.size() > 1:
				draw_polyline(drawn, col, maxf(1.0, w), true)


## The first `t` of a polyline by arc length, so a stroke draws on rather than appearing.
static func _partial(pts: PackedVector2Array, t: float) -> PackedVector2Array:
	if t >= 1.0 or pts.size() < 2:
		return pts
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	var want := total * t
	var out := PackedVector2Array([pts[0]])
	var run := 0.0
	for i in range(pts.size() - 1):
		var seg := pts[i].distance_to(pts[i + 1])
		if run + seg >= want:
			var k: float = 0.0 if seg <= 0.0 else (want - run) / seg
			out.append(pts[i].lerp(pts[i + 1], k))
			return out
		run += seg
		out.append(pts[i + 1])
	return out
