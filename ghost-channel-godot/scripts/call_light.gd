## CallLight — one of the five lamps on the console: a labelled brass-bezel indicator that
## is dark until that channel transmits.
##
## It is the one piece of chrome in the build that is drawn rather than rendered, and for
## the same reason the plot is: it is an *indicator*, its state is live, and its whole job
## is to be the exact call-sign colour of the person on the air. The steel it is screwed to
## is the plate underneath.
##
## `lying` is the tell the title screen demonstrates: the lamp lights, but in the wrong
## colour for a beat before it corrects. On the console that is a channel whose carrier does
## not match its call-sign, which is precisely what a mimic is.
extends Control

@export var agent_id := "viper"
@export var live := false
@export var lying := false

var _t := 0.0
var _glow := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_glow = move_toward(_glow, 1.0 if live else 0.0, delta * (6.0 if live else 2.2))
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var col: Color = Palette.callsign(agent_id)
	if lying and fmod(_t, 0.5) < 0.25:
		# the wrong carrier: for a beat the lamp is not this channel's colour
		col = Palette.HEAT

	# the bezel: a plate screwed to the console
	draw_rect(r, Palette.PANEL, true)
	draw_rect(r, Palette.LINE_STRONG, false, 1.0)
	draw_rect(Rect2(2, 2, size.x - 4, 2), Color(Palette.TEXT, 0.06), true)

	# the lamp itself, inset
	var lamp := Rect2(5, 5, size.x - 10, size.y - 10)
	draw_rect(lamp, Color(col, 0.10 + 0.70 * _glow), true)
	if _glow > 0.02:
		# the spill onto the steel around it
		draw_rect(r.grow(3.0), Color(col, 0.18 * _glow), false, 3.0)

	var f := StudioTheme.font("bold")
	var nm: String = str(GCRules.AGENTS[[
		"viper", "moth", "hex", "raven", "quill"].find(agent_id)].name)
	var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	f.draw_string(get_canvas_item(), Vector2((size.x - w) * 0.5, size.y * 0.66), nm,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Palette.GROUND if _glow > 0.5 else Color(col, 0.55 + 0.45 * _glow))
