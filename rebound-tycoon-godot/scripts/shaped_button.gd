## A button that is a SHAPE from the game's own world, not a rounded rectangle.
##
## Blaze, 2026-09-20 and again 2026-09-21: every title screen in the studio uses the same
## rounded rectangle with a word in it, and seen side by side on one board they read as
## one template rendered eighteen times rather than eighteen games. "看起来就像懒惰机器人
## 做的游戏." The fix is not a nicer rectangle -- it is that the control the player presses
## should be an object from the fiction: a radio dial for a radio game, a playing card for
## a card game, a folded paper corner for a folding game.
##
## Why drawn and not a plate: these have to respond. A pressed PNG needs a second PNG, a
## hover needs a third, and every localisation needs the text baked in. Drawn in _draw()
## the shape is one file, it tints, it animates on hover, and the label stays a real Label
## so zh/ja keep working.
##
## Usage — the game supplies its own shape and colours, nothing here is game-specific:
##
##     var b := ShapedButton.new()
##     b.shape = ShapedButton.Shape.DIAL
##     b.tint = Palette.SIGNAL
##     b.label = "ANSWER THE RADIO"
##     b.pressed.connect(...)
##
## Shapes are deliberately few. A studio with one shape per game reads as a studio; a
## studio with nine shapes per game reads as a sticker book.
class_name ShapedButton
extends Button

enum Shape {
	FOLD,      ## a sheet with one corner folded back — FOLD / PLICATA
	DIAL,      ## a tuning dial with a notch — Ghost Channel
	CARD,      ## a playing card, corner clipped — SilverTongue
	TICKET,    ## a torn ticket stub — Rebound Tycoon, Overtime Idle
	TAG,       ## a hanging luggage tag — Midnight Pawn, Late Inspection
	SLAB,      ## a heavy bevelled slab — the noir titles
	DOOR,      ## a door with light under it, which opens a crack on hover — The Other Side
	TIMECARD,  ## a payroll time card the clock punches on hover — Floor 13 / Floor 13 X
	## a bamboo fortune slip with a lacquered head and a torn tail — Cyber Fortune.
	## Added here 2026-09-21 by the Floor 13 pass: _draw_slip(), its arm in _draw()'s match
	## and its label case were all already written and only this member was missing, which
	## does not compile -- and an uncompilable shared script takes every game with it, not
	## just the one being worked on. The shape itself is not this pass's design.
	SLIP,
}

@export var shape: Shape = Shape.SLAB
@export var tint: Color = Color("d0a349")
@export var ink: Color = Color("12100e")
## The word on the shape, drawn by _draw() rather than by Button. Prefer assigning `text`
## from game code: _draw() adopts it (see below), and setting `text` queues a redraw of its
## own, whereas writing here does not. Set this directly only before the node enters the
## tree, where no redraw is needed yet.
@export var label: String = ""
## TICKET only: the colour of the punched notches down the stub's left edge. They are the
## ground BEHIND the button, so only the caller knows it -- and the original lookup
## (get_theme_color("bg","Panel")) resolved to a fully transparent colour on every theme in
## the studio, which draws nothing at all: the "torn ticket" shipped as a plain rectangle
## with a dotted line on it. Left at alpha 0 it still falls back to that lookup, so nothing
## that already uses TICKET changes.
@export var notch: Color = Color(0, 0, 0, 0):
	set(v):
		if notch == v:
			return
		notch = v
		queue_redraw()
## Skip the 220x56 minimum. Additive, 2026-09-21: that floor is sized for a 1280x720
## title screen, and Midnight Pawn's canvas is the base game's 640x360 -- a 56px button is
## a sixth of the screen height there, and three of them do not fit in the action row at
## all. A pixel game sets its own size and means it. Default false, so nothing that
## already ships moves.
@export var compact: bool = false

var _hover := 0.0          ## 0..1, tweened; every shape uses it for its own accent
var _tw: Tween


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	if not compact:
		custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 220.0),
				maxf(custom_minimum_size.y, 56.0))
	# The text is drawn by this script, not by Button, so the shape can put it where the
	# shape wants it. Button's own text would centre inside the full rect and land on the
	# folded corner or outside the card.
	text = ""
	mouse_entered.connect(func() -> void: _to(1.0))
	mouse_exited.connect(func() -> void: _to(0.0))
	focus_entered.connect(func() -> void: _to(1.0))
	focus_exited.connect(func() -> void: _to(0.0))


func _to(v: float) -> void:
	if _tw and _tw.is_running():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(func(x: float) -> void:
			_hover = x
			queue_redraw(), _hover, v, 0.16).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	# `label` is what this script draws, but half the studio's code writes to `text` --
	# both at construction and later, when a button re-labels itself ("REROLL · 4" ->
	# "REROLL · 6", "SOUND ON" -> "SOUND OFF"). _ready() clears `text` once, which caught
	# the first kind and missed the second entirely: Overtime Idle's tray buttons went
	# blank the first time the reroll price changed. Setting `text` queues a redraw (it
	# changes the control's minimum size), so adopting it here catches every later write
	# as well, and the two ways of naming a button stop being a trap.
	if text != "":
		label = text
		text = ""
	var r := Rect2(Vector2.ZERO, size)
	var lift := _hover * 3.0
	# A disabled ShapedButton drew exactly like an enabled one: `flat = true` throws away
	# Button's own "disabled" stylebox, and every shape below paints `tint` unconditionally.
	# Rebound Tycoon's ledger greys out REBOUND THE EMPIRE until a token is earned, and it
	# was not greyed out at all -- the press just did nothing. Done by swapping the two
	# colours round the draw rather than with modulate, because assigning modulate inside
	# _draw re-queues the redraw it is already inside.
	var _t0 := tint
	var _i0 := ink
	if disabled:
		tint = tint.darkened(0.55)
		ink = ink.lerp(tint, 0.6)
	match shape:
		Shape.FOLD:   _draw_fold(r, lift)
		Shape.DIAL:   _draw_dial(r, lift)
		Shape.CARD:   _draw_card(r, lift)
		Shape.TICKET: _draw_ticket(r, lift)
		Shape.TAG:    _draw_tag(r, lift)
		Shape.DOOR:   _draw_door(r, lift)
		Shape.SLIP:   _draw_slip(r, lift)
		Shape.TIMECARD: _draw_timecard(r, lift)
		_:            _draw_slab(r, lift)
	tint = _t0
	var _ink_now := ink
	ink = _i0
	if label != "":
		# get_theme_font("font") returns null on a Button that carries a theme_type_variation
		# the theme does not define -- and a null font draws NOTHING, silently. Ghost
		# Channel's first build shipped three dials with no words on them and no error in
		# the log. Fall back to the default font rather than trusting the lookup.
		var f := get_theme_font("font")
		if f == null:
			f = ThemeDB.fallback_font
		var fs := get_theme_font_size("font_size")
		if fs <= 0:
			fs = ThemeDB.fallback_font_size
		if f:
			var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			# DIAL puts its label above the scale and to the left, like a band name
			# printed on a receiver; every other shape centres it on the body.
			var pos := Vector2((size.x - w) * 0.5, size.y * 0.5 + fs * 0.35)
			if shape == Shape.DIAL:
				pos = Vector2(2.0, size.y * 0.46)
			# DOOR keeps its label off the knob and off the opening edge: the knob lives
			# in the right-hand sixth and the crack of light grows down the left, so the
			# words are centred on what is left between them.
			# TIMECARD keeps its label clear of the punch column on the left and of the
			# stamp that bleeds in from the right on hover, so it sits in the card's
			# printed field, left-aligned the way a name is typed onto a real card.
			if shape == Shape.TIMECARD:
				pos = Vector2(size.x * 0.17, size.y * 0.5 + fs * 0.35)
			# SLIP writes down the strip past the lacquered head, the way a 签 is
			# printed: the head is the painted end and carries no words.
			if shape == Shape.SLIP:
				var hd := size.y * 0.92
				pos = Vector2(hd + (size.x - hd - size.y * 0.5 - w) * 0.5,
						size.y * 0.5 + fs * 0.35)
			if shape == Shape.DOOR:
				var pad := size.x * 0.17
				pos = Vector2(pad + (size.x - pad * 2.0 - w) * 0.5, size.y * 0.5 + fs * 0.35)
			# The ink colour belongs to the FILLED shapes. DIAL fills nothing -- it is a
			# scale drawn on the picture behind it -- so dark ink on a dark title screen
			# drew three dials with no words on them and no error anywhere. An unfilled
			# shape writes in its own tint.
			var col := _ink_now
			if shape == Shape.DIAL:
				col = tint.lightened(0.25)
			draw_string(f, pos + Vector2(0, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
					Color(0, 0, 0, 0.55))
			draw_string(f, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## A sheet with the top-right corner folded back, and the fold OPENS on hover — the whole
## game is folding, so the button folds.
func _draw_fold(r: Rect2, lift: float) -> void:
	var c := 18.0 + lift * 8.0
	var body := PackedVector2Array([
		Vector2(0, 0), Vector2(r.size.x - c, 0), Vector2(r.size.x, c),
		Vector2(r.size.x, r.size.y), Vector2(0, r.size.y)])
	draw_colored_polygon(body, tint)
	# the folded flap, darker, because it is the paper's back
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.size.x - c, 0), Vector2(r.size.x, c), Vector2(r.size.x - c, c)]),
		tint.darkened(0.32))
	draw_polyline(PackedVector2Array([Vector2(r.size.x - c, 0), Vector2(r.size.x - c, c),
			Vector2(r.size.x, c)]), tint.lightened(0.35), 1.5)


## A tuning dial: a bar with a notch that slides toward the right as it is hovered, the
## way a station comes in.
func _draw_dial(r: Rect2, lift: float) -> void:
	# v2. The first version filled the whole rect with a tinted block and drew ticks on
	# it -- which is a rectangle wearing a costume, and Blaze would have said so. An
	# instrument is not a filled box: it is a THIN scale with a pointer, and the frame
	# around it is air. So nothing is filled; the label sits above the scale, the way it
	# does on a real receiver, and the only solid thing is the pointer.
	var mid := r.size.y * 0.74
	var n := 17
	for i in n:
		var x: float = r.size.x * (float(i) / float(n - 1))
		var major := i % 4 == 0
		var h: float = 9.0 if major else 5.0
		draw_line(Vector2(x, mid - h), Vector2(x, mid), tint.darkened(0.25), 1.0)
	draw_line(Vector2(0, mid), Vector2(r.size.x, mid), tint.darkened(0.45), 1.0)
	# The pointer slides toward the right as the pointer arrives: the station coming in.
	var nx: float = lerpf(r.size.x * 0.18, r.size.x * 0.82, _hover)
	draw_line(Vector2(nx, mid - 16.0), Vector2(nx, mid + 5.0), tint, 2.0)
	draw_circle(Vector2(nx, mid + 5.0), 3.0 + _hover * 1.5, tint)
	# a faint glow on the tuned side, so hover reads as signal rather than as a highlight
	if _hover > 0.01:
		draw_line(Vector2(0, mid), Vector2(nx, mid), tint, 1.0 + _hover * 1.5)


## A playing card with one clipped corner; it tilts a degree on hover, like a card lifted
## off the felt.
func _draw_card(r: Rect2, lift: float) -> void:
	var c := 14.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(c, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y - c),
		Vector2(r.size.x - c, r.size.y), Vector2(0, r.size.y), Vector2(0, c)]), tint)
	draw_polyline(PackedVector2Array([
		Vector2(c, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y - c),
		Vector2(r.size.x - c, r.size.y), Vector2(0, r.size.y), Vector2(0, c), Vector2(c, 0)]),
		tint.lightened(0.25 + _hover * 0.2), 1.5)
	var pip := 5.0 + _hover * 1.5
	draw_circle(Vector2(12, 12), pip, ink)
	draw_circle(Vector2(r.size.x - 12, r.size.y - 12), pip, ink)


## A torn ticket stub: notched sides, and the perforation brightens on hover.
func _draw_ticket(r: Rect2, lift: float) -> void:
	draw_rect(r, tint)
	var n := 7
	for i in n:
		var y := r.size.y * (float(i) + 0.5) / float(n)
		var nc := notch if notch.a > 0.0 else (get_theme_color("bg", "Panel") if has_theme_color("bg", "Panel") else Color(0, 0, 0, 0))
		draw_circle(Vector2(0, y), 5.0, nc)
		draw_circle(Vector2(r.size.x, y), 5.0, nc)
	var px := r.size.x * 0.76
	for i in int(r.size.y / 6.0):
		draw_line(Vector2(px, i * 6.0 + 1), Vector2(px, i * 6.0 + 4),
				tint.darkened(0.45 - _hover * 0.2), 1.5)
	draw_rect(r, tint.darkened(0.2), false, 1.5)


## A luggage tag on a string, which swings a little on hover.
func _draw_tag(r: Rect2, lift: float) -> void:
	var c := 16.0
	var sway := _hover * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(c + sway, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y),
		Vector2(c - sway, r.size.y), Vector2(0, r.size.y * 0.5)]), tint)
	draw_circle(Vector2(c * 0.9, r.size.y * 0.5), 4.0, ink)
	draw_arc(Vector2(c * 0.9, r.size.y * 0.5), 9.0 + sway, PI * 0.6, PI * 1.6, 12,
			tint.lightened(0.3), 1.5)


## A heavy bevelled slab: still rectangular, but lit like an object rather than a div.
func _draw_slab(r: Rect2, lift: float) -> void:
	draw_rect(r, tint)
	draw_line(Vector2(0, 0), Vector2(r.size.x, 0), tint.lightened(0.35 + _hover * 0.2), 2.0)
	draw_line(Vector2(0, r.size.y - 1), Vector2(r.size.x, r.size.y - 1), tint.darkened(0.4), 2.0)
	draw_rect(Rect2(Vector2(0, 0), Vector2(3.0 + _hover * 4.0, r.size.y)),
			tint.lightened(0.5))


## A door, seen flat on, with light under it — and on hover it opens a crack.
##
## The Other Side is one sentence: across the hall is the life you did not claim, and the
## only thing between you and it is a door you never opened. So the control the player
## presses is that door, and pressing it is the game. Hover does not "highlight" it; the
## door comes off the jamb and the warm room behind it shows in the gap, which is the only
## warm colour on the screen and therefore the only thing the eye goes to.
##
## The geometry is a stile-and-rail door rather than a filled box: two recessed panels, a
## knob plate in the right-hand sixth, and the strip of light on the floor. The crack
## widens from the LEFT (the hinges are on the right, with the knob) so the light and the
## knob are never on the same edge.
func _draw_door(r: Rect2, lift: float) -> void:
	var w := r.size.x
	var h := r.size.y
	# The gap the door swings open. At rest it is a hairline — a shut door in this game is
	# still not quite shut, which is the whole of beat one.
	var gap: float = 2.0 + _hover * (w * 0.14)
	# Behind the door: the warm room. Drawn first so the leaf covers all but the crack.
	var warm := Color(1.0, 0.72, 0.36)
	draw_rect(Rect2(Vector2(0, 0), Vector2(gap, h)), warm.lerp(Color(1, 1, 1), _hover * 0.25))
	if _hover > 0.01:
		# The light falls out of the gap and across the floor, which is how you know a
		# door is open from the hall.
		draw_rect(Rect2(Vector2(gap, h - 3.0), Vector2(w * 0.5 * _hover, 3.0)),
				Color(warm.r, warm.g, warm.b, 0.5 * _hover))
	# The leaf itself, pushed off the jamb by the gap.
	var x0 := gap
	var leaf := Rect2(Vector2(x0, 0), Vector2(w - x0, h))
	draw_rect(leaf, tint)
	# Stiles and rails: the lit edge is the one the crack lights, so the door reads as a
	# solid in a room rather than as a flat swatch.
	draw_line(Vector2(x0 + 1, 0), Vector2(x0 + 1, h), tint.lightened(0.4 + _hover * 0.3), 2.0)
	draw_line(Vector2(w - 1, 0), Vector2(w - 1, h), tint.darkened(0.45), 2.0)
	draw_line(Vector2(x0, h - 1), Vector2(w, h - 1), tint.darkened(0.5), 2.0)
	# Two recessed panels.
	var mx := 9.0
	var my := 8.0
	var mid := h * 0.52
	for panel in [Rect2(Vector2(x0 + mx, my), Vector2(w - x0 - mx * 2.0 - h * 0.18, mid - my * 1.5)),
			Rect2(Vector2(x0 + mx, mid + my * 0.5), Vector2(w - x0 - mx * 2.0 - h * 0.18, h - mid - my * 2.0))]:
		if panel.size.x <= 2.0 or panel.size.y <= 2.0:
			continue
		draw_rect(panel, tint.darkened(0.14))
		draw_line(panel.position, panel.position + Vector2(panel.size.x, 0), tint.darkened(0.42), 1.0)
		draw_line(panel.position + Vector2(0, panel.size.y),
				panel.position + panel.size, tint.lightened(0.28), 1.0)
	# The knob, on the opening edge, catching the light from the crack as it turns.
	var kx := w - h * 0.11
	var ky := h * 0.52
	draw_circle(Vector2(kx, ky), h * 0.075, tint.darkened(0.35))
	draw_circle(Vector2(kx - _hover * 1.5, ky), h * 0.055,
			Color(1.0, 0.78, 0.42).lerp(Color(1, 1, 1), _hover * 0.4))


## A fortune slip — the 签: a strip with a turned, lacquered head at one end and a torn
## tail at the other, and on hover it RISES, because rising out of the tube is the single
## gesture the whole game is built on. Cyber Fortune's shape.
##
## Drawn as one polygon rather than a rect with decoration, so the silhouette itself is
## wrong for a rectangle: the left end is a half-round cap, the right end is torn in five
## teeth. A player who never thinks about it still sees a stick, not a div.
##
## `slip_points` is static because Cyber Fortune's three instrument rows are not
## ShapedButtons — they carry a drawn instrument mark, a title and a subtitle, which is
## more than one label — and they must have the SAME silhouette as the buttons beneath
## them. Two hand-drawn slips that drift apart is exactly the "one template rendered
## eighteen times" failure wearing the opposite coat.
static func slip_points(sz: Vector2, rise: float) -> PackedVector2Array:
	var h: float = sz.y
	var w: float = sz.x
	var rr: float = h * 0.5
	var pts := PackedVector2Array()
	# the turned head: a half-round cap on the left, walked top -> bottom
	var steps := 14
	for i in range(steps + 1):
		var a: float = -PI * 0.5 - PI * (float(i) / float(steps))
		pts.append(Vector2(rr + cos(a) * rr, rr + sin(a) * rr - rise))
	# down the torn tail, five teeth, then back along the top
	var teeth := 5
	var bite: float = h * 0.11
	pts.append(Vector2(w - bite, h - rise))
	for i in range(teeth + 1):
		var t: float = float(i) / float(teeth)
		var x: float = w - (bite if i % 2 == 1 else 0.0)
		pts.append(Vector2(x, h - rise - h * t))
	pts.append(Vector2(rr, 0.0 - rise))
	return pts


func _draw_slip(r: Rect2, lift: float) -> void:
	var rise: float = lift * 1.6
	var pts := slip_points(r.size, rise)
	draw_colored_polygon(pts, tint)
	var edge := pts.duplicate()
	edge.append(pts[0])
	draw_polyline(edge, tint.lightened(0.28 + _hover * 0.25), 1.5)
	# the lacquer band across the turned head, and the pinhole it hangs by
	var c := Vector2(r.size.y * 0.5, r.size.y * 0.5 - rise)
	draw_circle(c, r.size.y * 0.34, tint.darkened(0.42 - _hover * 0.18))
	draw_circle(c, r.size.y * 0.10, ink)
	# the ink rule the 签文 is written along, which fills in as the slip comes up
	var y0: float = r.size.y * 0.5 - rise
	var x0: float = r.size.y * 0.92
	draw_line(Vector2(x0, y0 + r.size.y * 0.32), 
			Vector2(x0 + (r.size.x - x0 - r.size.y * 0.5) * (0.35 + 0.65 * _hover), y0 + r.size.y * 0.32),
			tint.darkened(0.35), 1.5)


## A payroll time card — the object Floor 13 is about.
##
## The whole game is one sentence: a company that keeps people by keeping their hours, and
## the retention letter is a card with your number on it. So the control the player presses
## IS that card, and pressing it is what the floor does to you.
##
## Geometry: a card with the top-right corner clipped (every real time card is, so it only
## goes into the rack one way up), a column of punch holes down the left where the clock
## bites, and two printed rules across the field where IN and OUT are typed.
##
## Hover is not a highlight. The clock punches one more hole — the next hole down the
## column fills with the ink colour and a red stamp bleeds in from the right edge — because
## in this game being noticed costs you an hour. The red is the same wound the logotype
## carries (#ff3b4a), so the title screen reads as one design.
func _draw_timecard(r: Rect2, lift: float) -> void:
	var w := r.size.x
	var h := r.size.y
	var c := 13.0
	var body := PackedVector2Array([
		Vector2(0, 0), Vector2(w - c, 0), Vector2(w, c),
		Vector2(w, h), Vector2(0, h)])
	draw_colored_polygon(body, tint)
	# The clipped corner reads as the card's back, the way FOLD's flap does.
	draw_colored_polygon(PackedVector2Array([
		Vector2(w - c, 0), Vector2(w, c), Vector2(w - c, c)]), tint.darkened(0.3))
	# The punch column. Holes are drawn in ink, i.e. punched THROUGH the card.
	var n := 5
	var px := w * 0.075
	for i in n:
		var y := h * (float(i) + 0.5) / float(n)
		# The hole the clock is about to bite is the one under the hover: it fills in as
		# _hover goes to 1, so the card visibly loses an hour while the pointer rests on it.
		var punched: float = clampf(_hover * float(n) - float(i), 0.0, 1.0)
		var rad: float = 2.0 + punched * 2.2
		draw_circle(Vector2(px, y), rad, ink.lerp(Color(1.0, 0.23, 0.29), punched * 0.7))
	# The printed field: two rules where IN and OUT are typed.
	for f in [0.36, 0.68]:
		draw_line(Vector2(w * 0.17, h * f), Vector2(w * 0.88, h * f),
				tint.darkened(0.3), 1.0)
	# The stamp bleeds in from the right as the card is pressed — RETAINED, in the red the
	# logotype uses. Drawn as a bar rather than as type so it survives every localisation.
	if _hover > 0.01:
		var sw: float = w * 0.30 * _hover
		draw_rect(Rect2(Vector2(w - sw - 4.0, h * 0.18), Vector2(sw, h * 0.64)),
				Color(1.0, 0.23, 0.29, 0.20 + 0.28 * _hover))
		draw_rect(Rect2(Vector2(w - sw - 4.0, h * 0.18), Vector2(sw, h * 0.64)),
				Color(1.0, 0.23, 0.29, 0.55 * _hover), false, 1.5)
	draw_polyline(body + PackedVector2Array([Vector2(0, 0)]),
			tint.lightened(0.28 + _hover * 0.22), 1.5)
