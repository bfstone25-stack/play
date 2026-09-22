class_name CfMark
extends Control
## The logotype for 赛博求签 / Cyber Fortune, and the sky it sits on.
##
## ops/adult_forks/TITLE_SCREENS.md item 2: "one display face chosen for the theme,
## letter-spacing and weight decided, a treatment that belongs to the world. Exported as
## an image or drawn with the engine's text effects, NEVER a plain Label."
##
## What was here was a plain Label:
##
##     var title := StudioTheme.label(Tx.t("title"), 54, Palette.GOLD_PALE, "serif")
##
## — the title of the game, set 54 px in NotoSerifSC on a drawn black rectangle. Two
## separate rules, both explicit:
##
##   TITLE_SCREENS.md, "No book serif by default": Blaze, 2026-09-19, the Times-ish serifs
##   make the games "look too serious, academic". A detective or crime world can carry a
##   serif; a bright fortune machine cannot, and this one was reading as a dissertation
##   about divination rather than as a thing you tap.
##
##   Studio rule 2, no code-drawn shapes: the ground under it was Backdrop's "home" mode,
##   which is draw_rect(INK) plus five concentric 1.8%-alpha gold circles. Measured, the
##   whole screen came in at 0.14 brightness against a shelf floor of 0.45.
##
## The treatment. The world is a fortune stall — paper, gold leaf, lanterns, a machine that
## tells you your luck — so the mark is a **gold-leaf stamp on paper**: the Latin wordmark
## in Lilita One (round, heavy, and the studio's display face per UI_DIRECTION.md) with a
## lacquer-red under-shadow, a paper-white keyline and a gold face, over a struck rule with
## the series line beneath it. Letters land one at a time and the gold takes a slow shine.
##
## The CJK cut is NOT set in Lilita One, which has no CJK at all: 赛博求签 falls through to
## NotoSerifSC, and a Chinese seal-script-adjacent serif is the right face for a Chinese
## wordmark in a way it was never the right face for the Latin one. The two scripts get
## the treatment in common and the face each one actually wants.

@export var word := "Cyber Fortune"
@export var series := ""
@export var size_px := 54
@export var track := 2.0
@export var cjk := false

var settle := 0.0
var _t := 0.0
var _shine := -1.0
var _shine_clock := 0.0
## Held fonts: the web export frees an unreferenced FontFile and re-reads it with its
## fallbacks gone, which is a screen of tofu with no error anywhere. See the memory
## "Godot web font fallback" and play/after-six-godot/scripts/as_title.gd's _kept.
var _kept: Array = []

const DISPLAY := "res://assets/fonts/LilitaOne-Regular.ttf"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, size_px * 2.5)
	set_process(true)


func _face() -> Font:
	# The Latin mark takes the display face; the Chinese mark takes the serif, because
	# Lilita One contains no CJK and asking it for 赛博求签 returns four empty boxes.
	if cjk:
		var s := StudioTheme.font("serif")
		if not _kept.has(s):
			_kept.append(s)
		return s
	if _kept.is_empty() or not (_kept[0] is FontFile):
		var f: Font = load(DISPLAY) if ResourceLoader.exists(DISPLAY) else StudioTheme.font("black")
		_kept.insert(0, f)
	return _kept[0]


func _process(dt: float) -> void:
	_t += dt
	settle = minf(1.8, settle + dt)
	if settle >= 1.8:
		if _shine >= 0.0:
			_shine += dt * 0.9
			if _shine > 1.0:
				_shine = -1.0
				_shine_clock = 0.0
		else:
			_shine_clock += dt
			if _shine_clock >= 4.0:
				_shine = 0.0
	queue_redraw()


func _letters(f: Font, text: String, sz: int) -> Array:
	var out: Array = []
	var total := 0.0
	for i in range(text.length()):
		out.append({"ch": text[i],
			"w": f.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x})
		total += out[i]["w"] + (track if i < text.length() - 1 else 0.0)
	return [out, total]


func _word(f: Font, text: String, sz: int, at: Vector2, color: Color, drop := Vector2.ZERO) -> void:
	var r := _letters(f, text, sz)
	var glyphs: Array = r[0]
	var x: float = at.x - float(r[1]) * 0.5
	for i in range(glyphs.size()):
		var g: Dictionary = glyphs[i]
		var d := clampf((settle - i * 0.04) * 2.2, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - d, 3.0)
		if e <= 0.002:
			x += float(g["w"]) + track
			continue
		draw_string(f, Vector2(x, at.y + (1.0 - e) * -18.0) + drop, str(g["ch"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(color, color.a * e))
		x += float(g["w"]) + track


func _draw() -> void:
	var f := _face()
	var cx := size.x * 0.5
	var base := Vector2(cx, size_px * 1.05)

	# the stamp, back to front: lacquer under-shadow, paper keyline, gold face, pale lift
	# Under-shadow 0.55 -> 0.85, 2026-09-22. This stamp was designed against the dark
	# ground it used to sit on; the title plate is now a lit lantern scene (graded for the
	# clicker shelf, which is bright and saturated) and a pale gold face over a soft red
	# shadow stopped separating from it. Deepening the shadow rather than darkening the
	# plate keeps the shelf number and gives the mark its edge back.
	_word(f, word, size_px, base, Color(Palette.LACQUER_DEEP, 0.85), Vector2(0, 6))
	for i in range(10):
		var a := TAU * float(i) / 10.0
		_word(f, word, size_px, base, Color(Palette.PAPER, 0.95),
			Vector2(cos(a), sin(a)) * 3.0)
	_word(f, word, size_px, base, Palette.GOLD)
	_word(f, word, size_px, base, Color(Palette.GOLD_PALE, 0.9), Vector2(0, -2.0))

	# the shine: a soft band crossing the gold, the way leaf catches light
	if _shine >= 0.0:
		var band := 46.0
		var span := size.x + band * 2.0
		var sx := -band + span * _shine
		for i in range(6):
			var t := float(i) / 5.0
			draw_line(Vector2(sx + t * band - 14.0, base.y - size_px),
				Vector2(sx + t * band + 14.0, base.y + size_px * 0.3),
				Color(1, 1, 1, sin(t * PI) * 0.26), 6.0)

	# the struck rule and the series line under it
	var ry := base.y + size_px * 0.42
	var half := size.x * 0.26 * clampf((settle - 0.4) * 1.5, 0.0, 1.0)
	if half > 1.0:
		draw_line(Vector2(cx - half, ry), Vector2(cx + half, ry),
			Color(Palette.GOLD_DEEP, 0.85), 1.5)
	if series != "":
		var fu := StudioTheme.font("bold")
		if not _kept.has(fu):
			_kept.append(fu)
		var sz := int(size_px * 0.26)
		var w := fu.get_string_size(series, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_string(fu, Vector2(cx - w * 0.5, ry + sz * 1.7), series,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz,
			Color(Palette.PAPER_INK, 0.85 * clampf((settle - 0.7) * 1.6, 0.0, 1.0)))
