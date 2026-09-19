extends Control
## HUD — the cabinet's display glass. Drawn, not stacked: the readouts sit on a brass rail
## across the top of the machine, the way a real backbox does, and the era bar under them
## is the skyline filling in. The duty line at the bottom is 老王 talking.
##
## Nothing here computes: every number comes from Kernel.

const W := 420.0
const H := 640.0

var state: Dictionary = {}
var line := ""
var _line_life := 0.0
var _coins_shown := 0.0
var _score_shown := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func say(text: String) -> void:
	line = text
	_line_life = 2.6


func _process(dt: float) -> void:
	if _line_life > 0.0:
		_line_life = maxf(0.0, _line_life - dt)
	# the numbers roll rather than snap — the sibling's rolling_label, inlined
	_coins_shown = lerpf(_coins_shown, float(state.get("coins", 0)), minf(1.0, dt * 7.0))
	_score_shown = lerpf(_score_shown, float(state.get("score", 0)), minf(1.0, dt * 7.0))
	queue_redraw()


## draw_string only honours `align` when it is given a positive width — with -1 it draws
## left-to-right from `at` and silently ignores the alignment, which is how the HOSES and
## NIGHT readouts ran off the right edge of the cabinet in the first screenshot run.
func _right(f: Font, at: Vector2, text: String, size: int, color: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(f, Vector2(at.x - w, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _stat(at: Vector2, tag: String, value: String, color: Color, right := false) -> void:
	var ft := StudioTheme.font("bold")
	var fd := StudioTheme.font("display")
	if right:
		_right(ft, at, tag, 9, Palette.MUTED)
		_right(fd, at + Vector2(0, 21), value, 20, color)
	else:
		draw_string(ft, at, tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.MUTED)
		draw_string(fd, at + Vector2(0, 21), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)


func _draw() -> void:
	if state.is_empty():
		return
	var era_id := Kernel.era_id(state)
	var e := Palette.era(era_id)

	# --- the brass rail across the backbox. 74 px, not 150: the backglass band below it,
	# between the rail and the table, is what makes the cabinet 2.5D, and the first cut
	# (an 88 px rail over a table starting at 96) buried the parallax stack entirely.
	var rail := Rect2(0, 0, W, 74)
	draw_rect(rail, Color(Palette.GROUND_DEEP, 0.88))
	draw_line(Vector2(0, 74), Vector2(W, 74), Color(Palette.BRASS, 0.9), 2.0)

	_stat(Vector2(14, 6), RTStrings.t("coins"), Kernel.format_coins(_coins_shown), Palette.GOLD)
	_stat(Vector2(126, 6), RTStrings.t("rent"), Kernel.format_coins(_score_shown), Palette.TEXT)
	_stat(Vector2(238, 6), RTStrings.t("combo"), "x%d" % int(state.get("combo", 0)),
		Palette.ACCENT if int(state.get("combo", 0)) > 0 else Palette.DIM)
	_stat(Vector2(W - 14, 6), RTStrings.t("balls"), str(maxi(0, int(state.get("balls", 0)))),
		Palette.WATER, true)

	# --- the era bar: the skyline filling in ---
	var idx := Kernel.era_index(state)
	var score := Kernel.skyline_score(state)
	var nxt: Dictionary = Kernel.ERAS[mini(Kernel.ERAS.size() - 1, idx + 1)]
	var prev: int = int(Kernel.ERAS[idx]["minScore"])
	var span: float = maxf(1.0, float(int(nxt["minScore"]) - prev))
	var fill: float = 1.0 if idx >= Kernel.ERAS.size() - 1 else clampf((score - prev) / span, 0.0, 1.0)
	var bar := Rect2(14, 66, W - 28, 3)
	draw_rect(bar, Color(Palette.PANEL, 0.9))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Color(e["rim"]))
	var ft := StudioTheme.font("bold")
	draw_string(ft, Vector2(14, 60), RTStrings.t("era") + " · " + RTStrings.tm("eras", era_id),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.GOLD_PALE)
	_right(ft, Vector2(W - 14, 60), RTStrings.t("night") + " " + str(int(state.get("night", 1))),
		9, Palette.MUTED)

	# --- 老王's line, over the road at the bottom ---
	var text := line if _line_life > 0.0 else RTStrings.tm("lines", era_id)
	var alpha: float = 1.0 if _line_life > 0.4 else (0.55 + (_line_life / 0.4) * 0.45 if _line_life > 0.0 else 0.55)
	var fu := StudioTheme.font("ui")
	var tw := fu.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var box := Rect2((W - tw) * 0.5 - 12, H - 46, tw + 24, 26)
	draw_rect(box, Color(Palette.GROUND_DEEP, 0.62 * alpha))
	draw_string(fu, Vector2((W - tw) * 0.5, H - 28), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(Palette.TEXT, alpha))

	# --- the plunge prompt, only while the hose is waiting ---
	if str(state.get("mode", "")) == "plunge":
		var fd := StudioTheme.font("display")
		var hint := RTStrings.t("space_hint")
		var hw := fd.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(fd, Vector2((W - hw) * 0.5, 172.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(Palette.ACCENT_SOFT, 0.65 + sin(Time.get_ticks_msec() / 260.0) * 0.3))
