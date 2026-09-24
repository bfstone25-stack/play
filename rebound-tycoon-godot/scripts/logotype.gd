extends Control
## Logotype — REBOUND set as a designed mark, not a Label in the default face.
##
## ops/adult_forks/TITLE_SCREENS.md item 2: "one display face chosen for the theme,
## letter-spacing and weight decided, a treatment that belongs to the world. Exported as
## an image or drawn with the engine's text effects, never a plain Label."
##
## The world is a night gate, so the treatment is a **neon sign over a brass plate**: the
## wordmark is drawn four times — a brass emboss under it, a wide teal bloom, a tight
## bloom, and the hot core — with the letters spaced by hand so REBOUND reads as signage
## rather than as a word. The subtitle (老王逆袭记 / Rebound Tycoon) sits on an engraved
## rule beneath it, in the small-caps weight, because that is where a plate's second line
## goes.
##
## The tube flickers the way a real one does — mostly on, occasionally stuttering — and
## settles when the screen settles. Reduced motion holds it lit.

@export var word := "REBOUND"
@export var sub := ""
@export var size_px := 54
@export var track := 9.0              # letter-spacing, in pixels, decided by eye
@export var reduce_motion := false

var settle := 0.0                     # 0 -> 1, the mark arriving
var _clock := 0.0
var _flicker := 1.0
var _next_flicker := 1.4
var flickers := 0                     # how many times the tube has stuttered; 0 under reduced motion


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(320, size_px * 2.1)
	set_process(true)


func _process(dt: float) -> void:
	_clock += dt
	settle = minf(1.0, settle + dt * 1.1)
	if reduce_motion:
		_flicker = 1.0
	else:
		_next_flicker -= dt
		if _next_flicker <= 0.0:
			_next_flicker = randf_range(1.6, 5.5)
			_flicker = 0.35
			flickers += 1
		_flicker = minf(1.0, _flicker + dt * 6.0)
	queue_redraw()


func _letters(f: Font, text: String, sz: int) -> Array:
	## Widths per glyph plus the hand-set track, so the mark can be drawn letter by letter.
	var out: Array = []
	var total := 0.0
	for i in range(text.length()):
		var ch := text[i]
		var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		out.append({"ch": ch, "w": w})
		total += w + (track if i < text.length() - 1 else 0.0)
	return [out, total]


func _draw_word(f: Font, text: String, sz: int, at: Vector2, color: Color, drop: Vector2 = Vector2.ZERO) -> void:
	var r := _letters(f, text, sz)
	var glyphs: Array = r[0]
	var total: float = r[1]
	var x := at.x - total * 0.5
	for i in range(glyphs.size()):
		var g: Dictionary = glyphs[i]
		# each letter settles with its own tiny delay: the mark lands, it does not appear
		var d := clampf((settle - i * 0.035) * 1.6, 0.0, 1.0)
		var rise := (1.0 - d) * 14.0
		if i == _obj_index and _obj_tex != null:
			# the letter's slot is an object: drawn once, on the face pass only (the emboss and
			# bloom passes would stamp it three times), at 1.35x cap height on the baseline
			if drop == Vector2.ZERO and color.a > 0.9 * lit_face_alpha:
				var s := sz * 1.35
				var cxl: float = x + float(g["w"]) * 0.5
				draw_texture_rect(_obj_tex, Rect2(Vector2(cxl - s * 0.5, at.y + rise - s * 0.86),
					Vector2(s, s)), false, Color(1, 1, 1, d))
		else:
			draw_string(f, Vector2(x, at.y + rise) + drop, str(g["ch"]), HORIZONTAL_ALIGNMENT_LEFT,
				-1, sz, Color(color, color.a * d))
		x += float(g["w"]) + track


var lit_face_alpha := 1.0
## The O of REBOUND is the guard's fire hose, coiled flat -- the game launches with a hose,
## and a coil is already an O with a counter. GPU render, cut out with rembg
## (ops/install_button_objects.py). Only the Latin wordmark has an O to give up; other
## locales draw every letter.
var _obj_tex: Texture2D = load("res://assets/title/obj_hosecoil.png") if ResourceLoader.exists("res://assets/title/obj_hosecoil.png") else null
var _obj_index := -1


func _draw() -> void:
	_obj_index = word.find("O")
	var f := StudioTheme.font("display")
	var cx := size.x * 0.5
	var base := Vector2(cx, size_px * 1.05)
	var lit := _flicker * (0.35 + settle * 0.65)

	# 1. the brass plate the sign is bolted to — sized to the word it carries, not to a
	#    fraction of the control, so a longer wordmark or a wider face never overhangs it
	var word_w: float = _letters(f, word, size_px)[1]
	var plate_w: float = minf(size.x - 16.0, word_w + size_px * 0.9)
	var plate := Rect2(cx - plate_w * 0.5, base.y - size_px * 0.94, plate_w, size_px * 1.26)
	# 2026-09-23: the plate is gone. It was a 0.55-alpha ink rectangle under the word with a
	# brass hairline round it -- a translucent box, which 0 of 64 shelf covers use. The
	# neon word already carries an emboss and a bloom; that is what holds it on the sky.
	lit_face_alpha = lit

	# 2. the emboss: the word cut into the brass, offset down-right
	_draw_word(f, word, size_px, base, Color(Palette.GROUND_DEEP, 0.85), Vector2(2, 3))

	# 3. the tube: a wide bloom, then a tight one, then the hot core
	_draw_word(f, word, size_px, base, Color(Palette.ACCENT, 0.13 * lit), Vector2(0, -1))
	_draw_word(f, word, size_px, base, Color(Palette.ACCENT_SOFT, 0.30 * lit))
	_draw_word(f, word, size_px, base, Color(Palette.TEXT, lit))

	if sub == "":
		return
	# 4. the engraved rule and the second line
	var ry := base.y + size_px * 0.42
	var half := size.x * 0.30 * settle
	draw_line(Vector2(cx - half, ry), Vector2(cx + half, ry), Color(Palette.BRASS, 0.8 * settle), 1.0)
	var fu := StudioTheme.font("bold")
	var sz := int(size_px * 0.30)
	var w := fu.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	# a keyline under the second line: pale gold on a now-bright sky disappeared
	for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2), Vector2(2, 2)]:
		draw_string(fu, Vector2(cx - w * 0.5, ry + sz * 1.5) + off, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sz,
			Color(0.106, 0.075, 0.125, 0.9 * settle))
	draw_string(fu, Vector2(cx - w * 0.5, ry + sz * 1.5), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sz,
		Color(Palette.GOLD_PALE, settle))
