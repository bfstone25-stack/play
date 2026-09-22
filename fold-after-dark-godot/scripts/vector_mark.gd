## VectorMark — the PLICATA logotype, drawn.
##
## TITLE_SCREENS.md item 2: "a designed mark, not a font default … exported as an image or
## drawn with the engine's text effects, never a plain Label." So the wordmark is a set of
## hand-built SVG paths — see PATHS below, which is PLICATA's own seven letters and not the
## parent FOLD's four — and this node draws them: a minimal SVG path
## parser (M/L/H/V/C/S/Z, absolute and relative) flattening cubics into polylines, then
## `draw_polyline` for the strokes and `draw_colored_polygon` for the two filled planes.
##
## `reveal` (0 → 1) draws the mark on progressively, stroke by stroke and along each
## stroke, which is the "logotype settles in" of item 3. It is a real draw-on, not an
## alpha fade: the crease arrives last, after the letters, because that is the beat the
## mark is built around.
##
## 2026-09-19 — the restyle. The skeleton is the same designed mark (the `d` strings are
## still the page's), but it is no longer *drawn* the same way. It used to be a hairline
## engraving: 9-unit strokes, a construction grid of 1.6-unit diagonals under it, flat
## colour. Against a bright casual shelf that reads as a technical drawing, and Blaze's
## note was specific — rounded, chunky, glossy, with a highlight, not an engraved serif.
##
## So each letter stroke is now drawn four times, back to front:
##
##   1. a drop shadow, offset down, which is what gives the mark a body;
##   2. the body itself, in the fill colour;
##   3. a gloss — a thin lighter stroke riding the top edge of the body;
##   4. `shine`, a white band that sweeps left-to-right across the letters.
##
## Godot's `draw_polyline` has no round caps or joins, so every pass also stamps a circle
## at each vertex; that is the whole trick behind the rounded ends, and it is why the
## stroke weights can go up to chunky without the corners turning into spikes.
##
## The construction grid is off by default now (`show_grid`). It was the most "designed"
## thing about the old mark and the most wrong for this one.
class_name VectorMark
extends Control

## Vestigial: every value draws PLICATA. See `_mark()`.
@export var mark: String = "plicata":
	set(v):
		mark = v
		queue_redraw()

## 0 .. 1 — how much of the mark is drawn.
@export var reveal: float = 1.0:
	set(v):
		reveal = clampf(v, 0.0, 1.0)
		queue_redraw()

@export var ink: Color = Palette.GOLD
@export var accent: Color = Palette.ACCENT
@export var hairline: Color = Color(Palette.PAPER, 0.35)

## The gloss riding the top of each stroke, and the shadow under the whole mark.
## The `foil` plate. It used to fill the mark's turned-paper plane, on the theory that the
## plane *is* a sheet catching the light and so is the one place a rendered texture belongs
## in a vector logotype. `_draw` no longer samples it: at the size the flap actually
## occupies the crinkle read as mottling, not as material. Kept resolved here so the plate
## stays claimed by the mark that owns it, and so the decision is visible rather than a
## silently deleted line — a logo made of photographs is not a logo, this one included.
var foil: Texture2D = Art.plate("foil")

@export var gloss: Color = Color("FFF6C9")
# Deep grape at 0.7, not a soft tangerine at 0.55: the mark has to hold against whatever
# the key visual puts behind it, and the plate that landed is pale candy everywhere. A
# logotype whose only dark is a darker version of its own fill has nothing to sit on.
@export var shadow: Color = Color(Palette.INK, 0.70)

## The hairline construction grid. Part of the old engraved mark; off by default now.
@export var show_grid: bool = false

## 0 .. 1 sweeps a white shine across the letters; anything outside that range is "no
## shine", which is the resting state between sweeps.
@export var shine: float = -1.0:
	set(v):
		shine = v
		queue_redraw()

## Scale of the stroke weights relative to the design's own units.
@export var weight: float = 1.0

## 0 .. 1 — how far the sheet the letters are folded out of has OPENED.
##
## ops/STANDARD.md, 2026-09-21: the letters should be made of the game's own material, and
## the recorded starting idea for PLICATA is "letters folded from a single sheet, creases
## catching the light, unfolding as the title settles". This is that, and it is not a
## decoration on top of the mark — it is the same accordion the game's merge ramp is
## (2, 4, 8 … layers, ops/fold/BRIDGE.md), applied to the mark's own geometry.
##
## At 0 the design box is pleated into PANELS vertical panels, each squeezed to a sliver,
## so the word is a closed concertina of paper standing on the baseline. At 1 every panel
## is at full width and the mark is exactly the geometry it was before this existed — so
## `unfold = 1.0` is the resting state and nothing downstream (the probe, the HUD lockup,
## the ad-track fallback) has to know this parameter is here.
##
## Panels open LEFT TO RIGHT with a stagger, because a concertina opened by hand does not
## open all at once, and the crease between two panels is drawn as a lit edge whose
## brightness falls off as the panel it hinges flattens — the "creases catching the light"
## half of the idea. A crease on flat paper is invisible, which is why it fades to nothing
## rather than staying on as a graphic line.
@export var unfold: float = 1.0:
	set(v):
		unfold = clampf(v, 0.0, 1.0)
		queue_redraw()

## How many panels the sheet is pleated into. Seven — one per letter of PLICATA — so a
## crease never lands inside a letterform's counter, where it would read as a scratch
## rather than as a fold. (That is the same fault the long crease diagonals had; see the
## ORDER note below.)
const PANELS := 7
## Each panel starts this much later than the one to its left, as a fraction of the whole
## unfold. Small enough that the word is never seen as two disconnected halves.
const PANEL_STAGGER := 0.055
## A panel never closes completely: at 0 it keeps this fraction of its width, so the
## closed state is a thick concertina you can read as paper, not a vertical line.
const PANEL_MIN := 0.10

# --- the mark, as drawn on the page -------------------------------------------------------
# Each entry: [d, layer], where layer is one of
#   "letter"  the letter body        (ink, heavy)
#   "fine"    the construction grid  (hairline)
#   "crease"  the fold line          (accent, medium)
#   "plane"   the turned paper       (accent, FILLED)
## The wordmark is the NAME, and the name is PLICATA.
##
## 2026-09-21. The fork was renamed everywhere -- project.godot, the kicker, the exports,
## I18n.WORDMARK -- and the title screen went on drawing FOLD, because this node does not
## set a string: it draws designed glyph strokes, and the strokes said F, O, L, D. Changing
## the constant next door could never have moved a single pixel of it. A mark is geometry.
##
## So these are PLICATA's own letters, built the way the parent's were -- centreline
## strokes on a 680x170 design box, cap height 22..146, drawn chunky with a shadow, a gloss
## and a shine sweep by `_draw`. Two things are deliberate:
##
##   * The name is NOT translated -- not into zh, not into ja. PLICATA is a proper noun,
##     and `I18n.WORDMARK` already says so for both languages it had. `_mark()` therefore
##     ignores the language entirely and the parent's 归一 mark is gone from this file: it
##     belongs to FOLD, and a fork that can accidentally draw its parent's logo is exactly
##     the defect this replaces.
##   * The planes -- the two filled flaps of turned paper, on the L's foot and the T's arm
##     -- are the only thing the mark keeps from FOLD's vocabulary, and they are the whole
##     reason the mark belongs to a folding game. Each is wound HINGE FIRST
##     (placed[0]..placed[1] is the crease) because `_draw` lights that edge and shades the
##     opposite one; wind one backwards and the flap reads as a coloured wedge.
const NAME := "plicata"

const PATHS := {
	"plicata": {
		"box": Vector2(680, 170),
		"strokes": [
			# P -- stem plus a bowl that closes on the stem at the half-height
			["M30 22V146M30 23H67C113 23 113 84 67 84H30", "letter"],
			["M136 22V146H192", "letter"],
			["M226 22V146", "letter"],
			# C -- open to the right, both terminals cut on the same angle
			["M330 48C306 20 256 28 256 84C256 140 306 148 330 120", "letter"],
			["M364 146L400 22L436 146M377 106H423", "letter"],
			["M470 24H542M506 24V146", "letter"],
			["M576 146L612 22L648 146M589 106H635", "letter"],
			# Two corners of the sheet turned over -- and NOTHING crosses a letterform.
			# The first pass hinged these on the L's foot and the T's arm and let them fold
			# back INTO the word, which drew a magenta diagonal across the I and across the
			# final A: the identical fault the parent's long crease strokes had, arriving by
			# a different route (see the ORDER note -- the letters are hollow polylines, so
			# there is no occlusion to hide anything behind them). These two fold into empty
			# air instead: one hangs below the L's foot in the band under the baseline, one
			# turns out past the last A into the right margin.
			["M192 146L218 146L232 168L206 168Z", "plane"],
			["M648 146L648 124L676 106L676 128Z", "plane"],
		],
	},
}

# 22, not the parent's 17: PLICATA is seven letters on a 680-wide box where FOLD was four
# on a 560, so the same nominal weight comes out a third thinner on screen. Measured on
# tools/mark_probe.gd at the title's real 470x150 -- the first pass read as a wire frame.
const WIDTHS := {"letter": 22.0, "fine": 1.6, "crease": 7.0, "plane": 0.0}
# The order the mark is drawn on in: grid first (it is the scaffolding), then the letters,
# then the plane the corner turns.
#
# 2026-09-19, second pass. The first fix for the scratches was to move "crease" in front
# of "letter" so the crease drew *under* the letters. It did nothing, and the captured
# frame said so: the letters are not solid. `_stroke` draws each letter as a polyline of
# width 17 — an outline with a hollow middle and open counters — so a line drawn beneath
# it shows straight through, and the crease's own drop shadow (INK at 0.70) came through
# with it as the thin dark diagonals across the F, the O, the L and the D. Draw order was
# never the mechanism. Occlusion was, and there is none.
#
# So the long crease diagonals are gone from the EN mark entirely. What a fold mark needs
# is a corner genuinely turned over, not a line laid across a letter, and the mark already
# had the better idea in "plane": a filled triangle of turned paper. The two planes now
# sit on the O's and the D's own right shoulders, hinged on the letter's vertical edge and
# folding inward and down, and `_draw` gives each one a lit hinge and a shaded underside
# so it reads as paper rather than as a coloured wedge. Nothing crosses a letterform.
#
# The ZH mark keeps its "crease" strokes: there they are the seal in the corner, they sit
# clear of the characters, and the captured zh frame shows them reading correctly.
const ORDER := ["fine", "crease", "letter", "plane"]

var _cache := {}


# --- the pleat ------------------------------------------------------------------------------

## Per-panel open fraction at this `unfold`, plus where each panel's left edge lands and
## how wide it is, all in DESIGN space. Computed once per `_draw` rather than per point:
## seven panels against a few thousand flattened path points.
##
## Returns {"x": PackedFloat32Array (PANELS+1 boundaries), "f": PackedFloat32Array (open
## fraction per panel)}. When the mark is flat this is the identity pleat and `_pleat` is
## skipped entirely.
func _pleat(box: Vector2) -> Dictionary:
	var pw := box.x / float(PANELS)
	var f := PackedFloat32Array()
	# The stagger compresses each panel's own ramp into the time left after the last panel
	# has started, so panel 6 still reaches 1.0 exactly at unfold = 1.0.
	var span: float = maxf(1.0 - PANEL_STAGGER * float(PANELS - 1), 0.2)
	for i in range(PANELS):
		var u := clampf((unfold - PANEL_STAGGER * float(i)) / span, 0.0, 1.0)
		# ease-out: paper swings open fast and settles slow
		u = 1.0 - pow(1.0 - u, 2.2)
		f.append(PANEL_MIN + (1.0 - PANEL_MIN) * u)
	# Lay the open panels out end to end and centre the result on the design box, so the
	# word opens from its middle instead of growing off the right-hand edge.
	var total := 0.0
	for v in f:
		total += v * pw
	var x := PackedFloat32Array()
	var run := (box.x - total) * 0.5
	for i in range(PANELS):
		x.append(run)
		run += f[i] * pw
	x.append(run)
	return {"x": x, "f": f, "pw": pw}


## The creases themselves, drawn UNDER everything else — the hinges the panels turn on.
##
## Each interior boundary gets two lines: a lit edge on the side of the crease facing the
## light and a shaded one behind it, which is the only cheap way a flat renderer says
## "this is a folded edge" rather than "this is a line". Both fade out with the panel they
## hinge, because a crease in flat paper catches nothing.
func _draw_creases(pl: Dictionary, box: Vector2, off: Vector2, s: float) -> void:
	var top := off.y + 8.0 * s
	var bot := off.y + (box.y + 14.0) * s
	for i in range(1, PANELS):
		# how open the tighter of the two panels this crease joins is
		var f: float = minf(pl["f"][i - 1], pl["f"][i])
		var a := 1.0 - (f - PANEL_MIN) / (1.0 - PANEL_MIN)
		a = clampf(a, 0.0, 1.0)
		if a <= 0.02:
			continue
		var x: float = off.x + float(pl["x"][i]) * s
		var w: float = maxf(1.5, WIDTHS["letter"] * s * weight * 0.22)
		draw_line(Vector2(x - w * 0.5, top), Vector2(x - w * 0.5, bot),
			Color(gloss, 0.55 * a), w, true)
		draw_line(Vector2(x + w * 0.5, top), Vector2(x + w * 0.5, bot),
			Color(shadow, shadow.a * 0.65 * a), w, true)


## Map one design-space point through the pleat.
##
## The horizontal part is the fold: a point at fraction k across panel i lands at fraction
## k across the panel's projected width. The vertical part is what stops the closed state
## looking like a squashed word rather than a folded sheet — a panel seen nearly edge-on
## is also seen slightly from below, so it keeps a little more of its height near the
## crease. It is small (8%) on purpose; more than that and the letters bow.
func _pleated(p: Vector2, pl: Dictionary, box: Vector2) -> Vector2:
	var pw: float = pl["pw"]
	var i := int(p.x / pw)
	i = clampi(i, 0, PANELS - 1)
	var f: float = pl["f"][i]
	var k := (p.x - float(i) * pw) / pw
	var nx: float = pl["x"][i] + k * f * pw
	var base := box.y                      # the baseline the concertina stands on
	var ny := base - (base - p.y) * (0.92 + 0.08 * f)
	return Vector2(nx, ny)



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

	# `flush` takes the subpath as arguments and the caller does the clearing.
	#
	# 2026-09-19: it used to be `func():` closing over `pts` and `closed`, and that was
	# the single bug under every complaint about this mark. A GDScript lambda captures a
	# local by value, so `pts = PackedVector2Array()` inside the lambda rebound only the
	# lambda's own copy and the outer `pts` never cleared: every subpath of a multi-`M`
	# path was appended as an alias of one array that kept growing. The F's three strokes
	# came out as one polyline that ran the stem, jumped diagonally to the top bar, then
	# jumped diagonally again to the middle bar — the diagonal across the F. For the same
	# reason the lambda's `closed` was always false, so `sub["closed"]` never became true
	# and `_draw`'s filled-plane branch had never once executed: every "plane" fell
	# through to the stroke path at WIDTHS 0.0, clamped to a 1 px hairline.
	var flush := func(p: PackedVector2Array, c: bool) -> void:
		if p.size() > 1:
			subs.append({"pts": p.duplicate(), "closed": c})

	while i < toks.size():
		if toks[i] is String:
			cmd = toks[i]
			i += 1
			if cmd in "Zz":
				closed = true
				flush.call(pts, closed)
				pts = PackedVector2Array()
				closed = false
				cur = start
				had_curve = false
			continue
		if cmd == "":
			i += 1
			continue
		var rel := cmd == cmd.to_lower()
		match cmd.to_upper():
			"M":
				flush.call(pts, closed)
				pts = PackedVector2Array()
				closed = false
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
	flush.call(pts, closed)
	return subs


func _mark() -> Dictionary:
	# There is one mark. `mark` survives as a property because three scenes set it from the
	# language and a removed setter is a crash, but PLICATA is a name: it is the same seven
	# letters in en, zh and ja, and any value lands on the same design.
	return PATHS.get(mark, PATHS[NAME])


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


## One stroke pass: a polyline plus a disc at every vertex, which is how a renderer with
## no round joins still draws a rounded stroke.
func _stroke(pts: PackedVector2Array, col: Color, w: float, offset: Vector2 = Vector2.ZERO) -> void:
	if pts.size() < 2 or w <= 0.0:
		return
	var moved := pts
	if offset != Vector2.ZERO:
		moved = PackedVector2Array()
		for p in pts:
			moved.append(p + offset)
	draw_polyline(moved, col, w, true)
	var r := w * 0.5
	for p in moved:
		draw_circle(p, r, col)


## The shine: the same stroke drawn again in white, segment by segment, each segment's
## alpha falling off with its distance from a vertical band travelling across the mark.
## Drawing it per-segment is what clips the shine to the letterforms without a mask.
func _shine_pass(pts: PackedVector2Array, w: float, band_x: float, band: float) -> void:
	if pts.size() < 2:
		return
	for i in range(pts.size() - 1):
		var mid := (pts[i] + pts[i + 1]) * 0.5
		var d := absf(mid.x - band_x)
		if d > band:
			continue
		var a := (1.0 - d / band)
		a = a * a * 0.85
		if a <= 0.01:
			continue
		draw_line(pts[i], pts[i + 1], Color(1, 1, 1, a), w * 0.55, true)


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
	# plane, which is what a small lockup of a logo is. It is also off entirely unless a
	# caller asks for it.
	var small := size.x < 190.0 or not show_grid
	# where the shine band is, in local x, and how wide it is
	var band := size.x * 0.22
	var band_x := lerpf(-band, size.x + band, clampf(shine, 0.0, 1.0))
	var shining := shine >= 0.0 and shine <= 1.0

	# how far the body shadow is offset down, in pixels at this scale
	var w_shadow: float = WIDTHS["letter"] * s * weight * 0.26
	# The pleat. Identity at unfold = 1.0, and skipped outright there so the flat mark
	# costs exactly what it did before the fold existed.
	var pleating := unfold < 1.0
	var pl := _pleat(box) if pleating else {}
	if pleating:
		_draw_creases(pl, box, off, s)
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
			if pleating:
				for p in pts:
					placed.append(off + _pleated(p, pl, box) * s)
			else:
				for p in pts:
					placed.append(off + p * s)
			if sub["closed"] and layer == "plane":
				# the turned paper: filled, and it fades in rather than drawing on
				var lift := PackedVector2Array()
				for p in placed:
					lift.append(p + Vector2(0, w_shadow))
				draw_colored_polygon(lift, Color(shadow, shadow.a * 0.7 * t))
				# The underside of the sheet: the mark's own gold, taken down a step in
				# value and saturation, because the back of a piece of paper is the same
				# paper with less light on it. It is deliberately NOT the `foil` plate.
				# The plate was here on the theory that a turned sheet is the one place a
				# photograph belongs in a logotype; the captured frame disagreed. At the
				# 24 px this flap occupies, the foil's crinkle is not a material, it is
				# mottling, and a mottled wedge hanging off the L reads as dirt on the
				# logo — the same complaint the crease diagonals earned, arriving by a
				# different route. Flat fill, lit crease, shaded lifted edge.
				var back := Color(col.r * 0.80, col.g * 0.74, col.b * 0.66, 0.97 * t)
				draw_colored_polygon(placed, back)
				# What makes a turned corner read as a fold rather than as a coloured
				# wedge: the crease it hinges on catches the light, and the edge farthest
				# from the hinge — the one that has lifted away from the page — carries
				# the shade. Each plane is wound hinge-first, so placed[0]..placed[1] is
				# always the crease and the opposite edge is the lifted one.
				var hw: float = maxf(1.5, WIDTHS["letter"] * s * weight * 0.16)
				if placed.size() >= 3:
					var far_a: int = 2 if placed.size() == 3 else 2
					var far_b: int = 0 if placed.size() == 3 else 3
					draw_line(placed[far_a], placed[far_b],
						Color(shadow, shadow.a * 0.55 * t), hw, true)
					draw_line(placed[0], placed[1],
						Color(gloss, 0.9 * t), hw, true)
				continue
			var drawn := _partial(placed, t)
			if drawn.size() < 2:
				continue
			var lw := maxf(1.0, w)
			if layer == "fine":
				draw_polyline(drawn, col, lw, true)
				continue
			# 1. body shadow, 2. body, 3. gloss along the top edge
			_stroke(drawn, Color(shadow, shadow.a * t), lw * 1.02, Vector2(0, w_shadow))
			_stroke(drawn, col, lw)
			if layer == "letter":
				_stroke(drawn, Color(gloss, 0.75 * t), lw * 0.30, Vector2(0, -lw * 0.30))
				if shining:
					_shine_pass(drawn, lw, band_x, band)


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
