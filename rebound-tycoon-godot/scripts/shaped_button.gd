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
	DOSSIER,   ## a manila case file with an index tab, opening on hover — After Six
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
	#
	# ADOPT, then clear — 2026-09-21, Midnight Pawn's pass. This was a bare `text = ""`,
	# which silently THREW AWAY the word on any button labelled before it entered the
	# tree:
	#
	#     var b := ShapedButton.new()
	#     b.text = "APPRAISE"        # assigned here...
	#     row.add_child(b)           # ...and destroyed here, by _ready()
	#
	# `_draw()` adopts `text` too, but only sees writes that happen AFTER _ready has run,
	# so it could not save this ordering. The result is a shaped button with no word on
	# it, drawn correctly, clickable, and completely silent about what it does — and
	# Midnight Pawn's whole action row (APPRAISE, PRICE, DISPLAY, CALL CUSTOMER, STRIKE,
	# GUARD) came out blank the first time it was wired up. Construct-then-add is the more
	# natural of the two orderings, so this is likely not the only game affected.
	if text != "":
		label = text
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
		Shape.DOSSIER: _draw_dossier(r, lift)
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
			# FOLD's turned corner lives in the top-right and its flap lies back over the
			# sheet, so the label is centred on the field that is LEFT once the corner is
			# accounted for. Centring on the full rect put long words (TIER MAP, 日本語)
			# under the flap, where they are drawn in the paper's own darkened back and
			# stop being readable — which is the fault that made the v1 shape look like a
			# rectangle in the first place, arriving from the other side.
			if shape == Shape.FOLD:
				var corner: float = minf(size.y * 0.72, size.x * 0.34)
				pos = Vector2(maxf((size.x - corner - w) * 0.5, size.y * 0.16),
						size.y * 0.5 + fs * 0.35)
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
			# DOSSIER types its label onto the folder's face, below the index tab that runs
			# along the top and clear of the page that slides out on the right. A case file
			# is typed onto, not centred, so it is left-aligned on the ruled field.
			if shape == Shape.DOSSIER:
				pos = Vector2(size.x * 0.09, size.y * 0.60 + fs * 0.35)
			# TAG writes in the ticket's printed field: past the cut point and the
			# eyelet on the left, and short of the perforation and the broker's stub on
			# the right. Centred on that field and lifted off the ruled line the sum is
			# written along. Centring on the FULL rect put the words over the eyelet at
			# the action row's 92x28.
			if shape == Shape.TAG:
				var pt := size.y * 0.46
				var st: float = size.x - maxf(size.y * 0.52, 9.0)
				pos = Vector2(pt + maxf((st - pt - w) * 0.5, 0.0), size.y * 0.5 + fs * 0.30)
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
## v2, 2026-09-21, PLICATA's pass. v1 was `var c := 18.0` — a FIXED eighteen pixels of
## corner on a button the title screen lays out at 300x58, which is six percent of its
## width. The captured title frame is the argument: PLAY read as a magenta rectangle and
## TIER MAP as a gold one, each with a small nick out of the top-right, and that is the
## "rectangle wearing a costume" this file's own header warns about — the same fault the
## TAG shape was rewritten for two rows above.
##
## Two things changed and they are the same thing twice. First, every measurement is a
## fraction of HEIGHT, never a constant, so the corner is the same corner on the title's
## 300x58 and on a compact 92x28 row. Second, the corner is now a corner that has actually
## been TURNED, not clipped off: the flap is drawn where the paper went, lying back across
## the body with its own shading, the hinge it swung on catches the light, and it casts a
## soft shadow onto the sheet under it. A clipped corner is a shape; a turned corner is a
## fold, and this is a folding game.
##
## The hover is the verb: the flap OPENS. It grows along the diagonal and its shadow grows
## with it, which is what a sheet does when a thumb lifts the corner. The idle state keeps
## a real fold rather than a hint of one, because a button that is only a fold while the
## pointer is on it is a rectangle for everyone reading a screenshot — and a screenshot is
## how this shelf is judged.
func _draw_fold(r: Rect2, lift: float) -> void:
	# The turned corner, as a fraction of the button's height, and never more than a third
	# of its width — on a very wide button a corner scaled off the height is still a
	# corner, but on a narrow one it must not eat the label.
	var c: float = minf(r.size.y * (0.46 + lift * 0.26), r.size.x * 0.34)
	var hinge_a := Vector2(r.size.x - c, 0.0)      # where the crease meets the top edge
	var hinge_b := Vector2(r.size.x, c)            # where it meets the right edge

	# The sheet, with the corner gone from it.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), hinge_a, hinge_b,
		Vector2(r.size.x, r.size.y), Vector2(0, r.size.y)]), tint)

	# The shadow the lifted corner throws onto the sheet, just inside the crease. Drawn
	# before the flap, offset along the fold's own axis, and it deepens as the flap opens.
	var drop: float = c * (0.10 + lift * 0.10)
	draw_colored_polygon(PackedVector2Array([
		hinge_a + Vector2(-drop, drop), hinge_b + Vector2(-drop, drop),
		hinge_a + Vector2(-c * 0.62 - drop, c * 0.62 + drop)]),
		Color(0, 0, 0, 0.20 + 0.10 * lift))

	# The flap: the corner lying back across the sheet, hinged on the crease. Its far
	# point is the reflection of the old corner through the crease, which is what a fold
	# IS — ops/fold/REDESIGN.md's one sentence, drawn on a button.
	var tip := (hinge_a + hinge_b) * 0.5 + Vector2(-c * 0.5, c * 0.5) * (0.86 + lift * 0.22)
	draw_colored_polygon(PackedVector2Array([hinge_a, hinge_b, tip]), tint.darkened(0.34))
	# The back of the paper is lit unevenly: brighter where it is still near the crease.
	draw_colored_polygon(PackedVector2Array([
		hinge_a, hinge_b, (hinge_a + hinge_b) * 0.5 + (tip - (hinge_a + hinge_b) * 0.5) * 0.45]),
		tint.darkened(0.18))
	# The crease itself, catching the lamp.
	draw_line(hinge_a, hinge_b, tint.lightened(0.45), maxf(1.4, r.size.y * 0.035), true)
	# The flap's own cut edges, a shade darker so it reads as a separate piece of paper
	# rather than as a stain on the button.
	draw_polyline(PackedVector2Array([hinge_a, tip, hinge_b]),
		tint.darkened(0.52), maxf(1.0, r.size.y * 0.022), true)


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


## A PAWN TICKET tied to the thing it is written against — Midnight Pawn, Late Inspection.
##
## v2, 2026-09-21, Midnight Pawn's pass. v1 was a pentagon with a dot in it and an arc
## beside the dot: at the 92x28 a 640x360 canvas can afford, the dot and the arc are three
## pixels each and the whole control reads as "a rectangle with the left corner cut off".
## That is the costume-on-a-rectangle failure the file's own header warns about.
##
## What a pawnbroker actually hands you is one object, and every part of it means
## something: the punched eyelet with the string that ties the ticket to the pledge, the
## brass ring that stops the string tearing out, the printed rule the sum is written along,
## and the perforation with the stub the broker keeps. So all four are drawn, and the ones
## that carry the fiction are the ones that MOVE: on hover the ticket swings on its string
## the way a tag does when something is lifted off the shelf, the eyelet catches the lamp,
## and the stub starts to come away at the perforation — a pledge being redeemed.
##
## Everything is a fraction of HEIGHT, never a constant: the same shape has to read at the
## title's 220x56 and at the action row's 92x28, and a 16px point on a 28px control is the
## whole left third of it.
func _draw_tag(r: Rect2, lift: float) -> void:
	var w := r.size.x
	var h := r.size.y
	# The swing. A tag hangs from ONE hole, so it does not slide sideways — it rotates
	# about the eyelet, which means the far end travels and the near end barely moves.
	var sway: float = _hover * h * 0.09
	var point: float = h * 0.46           # the cut left end, where the string goes
	var perf: float = w - maxf(h * 0.52, 9.0)   # the broker's stub starts here
	# The body: point at the left, square at the right, the far end lifted by the swing.
	draw_colored_polygon(PackedVector2Array([
		Vector2(point, -sway * 0.35), Vector2(w, -sway), Vector2(w, h - sway),
		Vector2(point, h + sway * 0.35), Vector2(0, h * 0.5)]), tint)
	# The stub past the perforation is the same card seen from its back: a shade darker,
	# and it separates a little as the ticket is hovered.
	draw_colored_polygon(PackedVector2Array([
		Vector2(perf + lift * 0.5, -sway * 0.9), Vector2(w, -sway),
		Vector2(w, h - sway), Vector2(perf + lift * 0.5, h - sway * 0.9)]),
		tint.darkened(0.17))
	# The perforation itself — punched dots, not a dashed line.
	var dots := maxi(int(h / 4.0), 3)
	for i in dots:
		var y: float = h * (float(i) + 0.5) / float(dots) - sway * 0.9
		draw_circle(Vector2(perf, y), maxf(h * 0.035, 0.8), tint.darkened(0.45))
	# The rule the sum is written along, under the label, the length of the printed field.
	draw_line(Vector2(point + h * 0.18, h * 0.76 + sway * 0.1),
			Vector2(perf - h * 0.14, h * 0.76 - sway * 0.45),
			tint.darkened(0.38), maxf(h * 0.03, 1.0))
	# The eyelet: a brass ring with the hole punched through it, and the string above.
	var ex: float = point * 0.62
	var ey: float = h * 0.5
	var rr: float = maxf(h * 0.15, 2.5)
	draw_circle(Vector2(ex, ey), rr + maxf(h * 0.055, 1.0),
			tint.lightened(0.30 + _hover * 0.28))
	draw_circle(Vector2(ex, ey), rr, ink)
	# The string, going up and off the control: what the tag hangs from, and the reason
	# the far end swings rather than sliding.
	# It leaves the control, because that is what sells "hung from something" — but only
	# just. At -0.3h it reached up into the line of copy above the button and read as a
	# scratch through the text, in every locale.
	draw_line(Vector2(ex, ey - rr), Vector2(ex - h * 0.10 - sway, -h * 0.10),
			tint.lightened(0.18), maxf(h * 0.035, 1.0))
	# The light on the top edge, so the card reads as a card and not as a swatch.
	draw_line(Vector2(point, -sway * 0.35), Vector2(w, -sway),
			tint.lightened(0.34), maxf(h * 0.03, 1.0))


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
	# Torn tail: three DEEP jagged teeth (a real omikuji strip is hand-torn off the roll,
	# not a rectangle with a nibbled edge). Previous bite (h*0.11, five teeth) was so
	# shallow at normal button heights that it read as a straight edge from three feet
	# away -- Blaze's flagged complaint. Also taper the whole strip narrower toward the
	# tail (top edge ramps down, bottom edge ramps up) so the silhouette reads as a torn
	# paper ribbon even with the teeth ignored, not just a rect with a notched corner.
	var taper: float = h * 0.22
	var teeth := 3
	var bite: float = h * 0.42
	pts.append(Vector2(w, h - taper - rise))
	for i in range(teeth):
		var t0: float = float(i) / float(teeth)
		var t1: float = float(i + 1) / float(teeth)
		var y_top: float = (h - taper) - (h - 2.0 * taper) * t0
		var y_bot: float = (h - taper) - (h - 2.0 * taper) * t1
		pts.append(Vector2(w - bite, lerp(y_top, y_bot, 0.5) - rise))
		pts.append(Vector2(w, y_bot - rise))
	pts.append(Vector2(w, taper - rise))
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


## A manila case file with an index tab, and it OPENS on hover — After Six.
##
## The fiction picks the shape. After Six is a crime thriller whose only currency is
## leverage, and leverage in this game is one physical object: the open case file on the
## desk. It is what the title's menu is typed on, it is where the night's evidence goes,
## and it is what the player is really pressing when he takes the chair. So the control is
## that folder, and the studio's shared rectangle is not involved.
##
## Three parts, each of which moves:
##
##   the tab     an index tab along the top-left, its outer corner cut. This is the
##               silhouette — the top edge of this control is not a straight line, which is
##               the entire difference between a folder and a rounded rectangle.
##   the folder  manila, creased down the left where the card is folded.
##   the page    a sheet inside, edged in the stamp's red. At rest it sits behind the
##               folder and is not drawn at all; on hover it slides out and rides up — the
##               file opening a crack, the leverage showing.
##
## Deliberately not a bevel and not a glow: hover is a MOVEMENT of an object in the world,
## the same grammar as DOOR's crack of light and FOLD's opening corner.
func _draw_dossier(r: Rect2, lift: float) -> void:
	var w := r.size.x
	var h := r.size.y
	var tab_h: float = maxf(6.0, h * 0.20)
	var tab_w: float = w * 0.40
	var slant: float = tab_h * 0.55
	var body_top := tab_h

	# The page inside, drawn FIRST so the folder covers it. At rest it is flush behind the
	# folder's edge and invisible; hover slides it out to the right and up, because a sheet
	# pulled from a folder rides over the lip rather than sliding sideways out of it.
	var out: float = lift * 2.6 + _hover * 7.0
	if out > 0.4:
		var pg := Rect2(Vector2(w * 0.30, body_top + 3.0 - out * 0.45),
				Vector2(w * 0.70 + out, h - body_top - 6.0))
		draw_rect(pg, Color(0.94, 0.91, 0.85, 0.95))
		# the stamp's red down the page's outer edge — what the file is worth
		draw_rect(Rect2(Vector2(pg.position.x + pg.size.x - 3.0, pg.position.y),
				Vector2(3.0, pg.size.y)), Color(0.85, 0.20, 0.33, 0.95))
		# two typed rules, so the page reads as paper and not as a coloured block
		for i in 2:
			var ly: float = pg.position.y + pg.size.y * (0.38 + 0.22 * i)
			draw_line(Vector2(pg.position.x + 6.0, ly),
					Vector2(pg.position.x + pg.size.x * 0.55, ly),
					Color(0.35, 0.31, 0.27, 0.55), 1.0)

	# the index tab, outer top corner cut
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, tab_h), Vector2(0, slant), Vector2(slant, 0),
		Vector2(tab_w - slant, 0), Vector2(tab_w, slant), Vector2(tab_w, tab_h)]),
		tint.lightened(0.10))

	# the folder
	draw_rect(Rect2(Vector2(0, body_top), Vector2(w, h - body_top)), tint)

	# The crease down the left: a folder is one piece of card bent, and a bend catches the
	# light on one side of itself and loses it on the other.
	draw_line(Vector2(w * 0.055, body_top), Vector2(w * 0.055, h), tint.darkened(0.26), 1.5)
	draw_line(Vector2(w * 0.055 + 1.5, body_top), Vector2(w * 0.055 + 1.5, h),
			tint.lightened(0.22), 1.0)
	# the seam where the tab meets the folder, so the two parts read as two parts
	draw_line(Vector2(0, body_top), Vector2(w, body_top), tint.darkened(0.30), 1.0)
	# the lip along the foot, catching the lamp
	draw_line(Vector2(0, h - 1.0), Vector2(w, h - 1.0), tint.lightened(0.30), 1.0)
