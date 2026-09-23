## Logotype — the title set as a designed mark, not a Label.
##
## ops/adult_forks/TITLE_SCREENS.md item 2: "one display face chosen for the theme,
## letter-spacing and weight decided, a treatment that belongs to the world. Exported as an
## image or drawn with the engine's text effects, never a plain Label."
##
## The treatment here is the game's own premise. A ghost channel is a second voice arriving
## on the same frequency a fraction late, so the mark is struck three times: a cyan copy
## pushed left, a magenta copy pushed right, and the solid white cut between them. When the
## station is quiet the three sit almost on top of each other and the word reads clean; when
## the signal slips they separate, and for a moment there are visibly two names where there
## should be one. That is the RF ghost the title is named after, and it is also exactly what
## the player has to hear five times a round.
##
## Two rules keep it a mark rather than an effect:
##   - the tracking is fixed and wide (0.16 em), so GHOST and CHANNEL set to the same
##     measure and the block is a rectangle, the way station signage is;
##   - the split has a ceiling. It breathes at ~0.6 px and tears to 7 px only on a scheduled
##     dropout, a few seconds apart. A permanently split logo is a lens flare.
extends Control

const MARK_PATH := "res://assets/art/logotype.png"
var _mark: Texture2D = load(MARK_PATH) if ResourceLoader.exists(MARK_PATH) else null

@export var text_top := "GHOST"
@export var text_bottom := "CHANNEL"
@export var base_size := 96
@export var tracking := 0.16          # em, applied between every pair of glyphs
@export var rule_text := ""           # the small line under the rule (the studio's mark)

var _t := 0.0
var _tear := 0.0                      # 0..1, how far the three strikes are pulled apart
var _next_tear := 2.0
var _settle := 0.0                    # 0 -> 1 over the first beat; the mark arrives
var _font: Font
var _small: Font
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_font = StudioTheme.font("display")
	_small = StudioTheme.font("mono")
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


## Play the arrival again (used when the title screen is re-entered).
func settle() -> void:
	_settle = 0.0
	_t = 0.0
	_next_tear = 2.0


func _process(delta: float) -> void:
	_t += delta
	_settle = minf(1.0, _settle + delta / 1.1)
	if _t >= _next_tear:
		_tear = 1.0
		_next_tear = _t + _rng.randf_range(3.2, 6.5)
	_tear = maxf(0.0, _tear - delta * 4.5)
	queue_redraw()


## Width of `s` at `size` with the mark's tracking applied.
func _measure(s: String, size: int) -> float:
	var w := 0.0
	for i in s.length():
		w += _font.get_string_size(s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if i < s.length() - 1:
			w += size * tracking
	return w


func _draw_tracked(s: String, pos: Vector2, size: int, color: Color) -> void:
	var x := pos.x
	for i in s.length():
		_font.draw_string(get_canvas_item(), Vector2(x, pos.y), s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		x += _font.get_string_size(s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * tracking


func _draw() -> void:
	# 2026-09-23. The RF-ghost idea is kept and the TYPE is gone. What was struck three
	# times was the display face; what is struck three times now is the mark built in
	# ops/title_logotypes.py::ghost_channel — phosphor letters cut by scanlines with one
	# band torn sideways by interference, the O replaced by the set's tuning dial (needle
	# off station) and the T of GHOST by the relay mast itself, guy wires and red beacon.
	# Two letters, not one: picking the letter by its shape is the rule, always taking the
	# O is a formula (ops/STANDARD.md).
	#
	# The split still breathes at ~0.6 px and tears to 7 px on a dropout, because that is
	# the premise of the game — a second voice arriving a fraction late on the same
	# frequency — and it was the good part of the old mark.
	var ease_in: float = 1.0 - pow(1.0 - _settle, 3.0)
	var arrive: float = (1.0 - ease_in) * 26.0
	var breathe: float = sin(_t * 1.7) * 0.6
	var split: float = arrive + breathe + _tear * 7.0
	var alpha: float = ease_in
	var w_bottom := size.x
	var y_bottom := 0.0

	if _mark != null:
		var mw := size.x
		var mh := mw * float(_mark.get_height()) / float(_mark.get_width())
		var r := Rect2(Vector2(0, 0), Vector2(mw, mh))
		y_bottom = mh * 0.74
		w_bottom = mw
		draw_texture_rect(_mark, Rect2(r.position + Vector2(-split, 0), r.size), false,
			Color(Palette.ACCENT, 0.55 * alpha))
		draw_texture_rect(_mark, Rect2(r.position + Vector2(split, 0), r.size), false,
			Color(Palette.HEAT, 0.55 * alpha))
		draw_texture_rect(_mark, r, false, Color(1, 1, 1, alpha))

	# the rule: a hairline the width of the block, and the station's callsign under it.
	# `base` replaces the old int `size`: since the mark became a texture, `size` is the
	# Control's own Vector2 and multiplying it by a float is a type error, not a scale.
	var base := float(base_size)
	var rule_y := y_bottom + base * 0.26
	draw_rect(Rect2(0, rule_y, w_bottom * ease_in, 2), Color(Palette.ACCENT, 0.55 * alpha), true)
	if rule_text != "":
		var rs := maxi(11, int(base * 0.14))
		# tracked out hard: this is a plate screwed to the console, not a sentence
		var x := 0.0
		for i in rule_text.length():
			_small.draw_string(get_canvas_item(), Vector2(x, rule_y + rs * 1.8), rule_text[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, rs, Color(Palette.MUTED, alpha))
			x += _small.get_string_size(rule_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, rs).x + rs * 0.34

	custom_minimum_size = Vector2(w_bottom, rule_y + base * 0.6)
