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
	var size := base_size
	# GHOST is set to the measure of CHANNEL: the block is a rectangle, like station signage.
	var w_bottom := _measure(text_bottom, size)
	var top_size := size
	var w_top := _measure(text_top, top_size)
	if w_top > 1.0:
		top_size = int(size * (w_bottom / w_top))
		w_top = _measure(text_top, top_size)

	var ease_in: float = 1.0 - pow(1.0 - _settle, 3.0)
	# the arrival: the three strikes come in far apart and close on the word
	var arrive: float = (1.0 - ease_in) * 26.0
	var breathe: float = sin(_t * 1.7) * 0.6
	var split: float = arrive + breathe + _tear * 7.0
	var alpha: float = ease_in

	var y_top := float(top_size) * 0.95
	var y_bottom := y_top + size * 1.02
	var pairs := [[text_top, Vector2(0, y_top), top_size], [text_bottom, Vector2(0, y_bottom), size]]

	for p in pairs:
		var s: String = p[0]
		var at: Vector2 = p[1]
		var sz: int = p[2]
		# the two ghosts, then the solid cut between them
		_draw_tracked(s, at + Vector2(-split, 0), sz, Color(Palette.ACCENT, 0.75 * alpha))
		_draw_tracked(s, at + Vector2(split, 0), sz, Color(Palette.HEAT, 0.75 * alpha))
		_draw_tracked(s, at, sz, Color(Palette.TEXT, alpha))

	# the rule: a hairline the width of the block, and the station's callsign under it
	var rule_y := y_bottom + size * 0.26
	draw_rect(Rect2(0, rule_y, w_bottom * ease_in, 2), Color(Palette.ACCENT, 0.55 * alpha), true)
	if rule_text != "":
		var rs := maxi(11, int(size * 0.14))
		# tracked out hard: this is a plate screwed to the console, not a sentence
		var x := 0.0
		for i in rule_text.length():
			_small.draw_string(get_canvas_item(), Vector2(x, rule_y + rs * 1.8), rule_text[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, rs, Color(Palette.MUTED, alpha))
			x += _small.get_string_size(rule_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, rs).x + rs * 0.34

	custom_minimum_size = Vector2(w_bottom, rule_y + size * 0.6)
