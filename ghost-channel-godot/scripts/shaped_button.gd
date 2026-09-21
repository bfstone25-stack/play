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
}

@export var shape: Shape = Shape.SLAB
@export var tint: Color = Color("d0a349")
@export var ink: Color = Color("12100e")
@export var label: String = ""

var _hover := 0.0          ## 0..1, tweened; every shape uses it for its own accent
var _tw: Tween


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
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
	var r := Rect2(Vector2.ZERO, size)
	var lift := _hover * 3.0
	match shape:
		Shape.FOLD:   _draw_fold(r, lift)
		Shape.DIAL:   _draw_dial(r, lift)
		Shape.CARD:   _draw_card(r, lift)
		Shape.TICKET: _draw_ticket(r, lift)
		Shape.TAG:    _draw_tag(r, lift)
		_:            _draw_slab(r, lift)
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
			# The ink colour belongs to the FILLED shapes. DIAL fills nothing -- it is a
			# scale drawn on the picture behind it -- so dark ink on a dark title screen
			# drew three dials with no words on them and no error anywhere. An unfilled
			# shape writes in its own tint.
			var col := ink
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
		draw_circle(Vector2(0, y), 5.0, get_theme_color("bg", "Panel") if has_theme_color("bg", "Panel") else Color(0, 0, 0, 0))
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
