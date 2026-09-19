## Portrait — one of the five faces.
##
## The plate (ops/ghost_art/ghost_gen.py: voice_<id>) is the face. The frame around it is
## the console's, not the painter's: a hairline in the call-sign colour, a lit strip under
## the name, and a wash of that colour over the image so the five read apart at roster size
## even in peripheral vision.
##
## When a plate has not landed, this draws a *slot* — the call-sign letter on a dark panel
## with the frame and the name still in place — rather than the prototype's code-drawn
## cartoon face. A missing asset should look like a missing asset, not like a decision.
extends Control

@export var agent_id := "viper"
@export var display_name := ""
@export var alive := true
@export var suspect := false
@export var live := false             # this person is on the air right now

var _tex: Texture2D
var _t := 0.0
var _have := false


func _ready() -> void:
	_reload()
	set_process(true)


func setup(id: String, nm: String) -> void:
	agent_id = id
	display_name = nm
	_reload()
	queue_redraw()


func _reload() -> void:
	var p := "res://assets/art/voice_%s.png" % agent_id
	_have = ResourceLoader.exists(p)
	_tex = load(p) if _have else null


func _process(delta: float) -> void:
	_t += delta
	if live or suspect:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var col := Palette.callsign(agent_id)
	draw_rect(r, Palette.GROUND_DEEP, true)

	if _tex:
		# cover-crop: the plate is 3:4, the slot is usually not
		var ts := _tex.get_size()
		var k: float = maxf(size.x / ts.x, size.y / ts.y)
		var draw_size := ts * k
		var at := (size - draw_size) * 0.5
		at.y = minf(at.y, 0.0)                       # bias to the top: keep the eyes in
		draw_texture_rect(_tex, Rect2(at, draw_size), false,
			Color(1, 1, 1, 1) if alive else Color(0.42, 0.46, 0.5, 1))
		# the call-sign wash, so five faces read apart at 56 px
		draw_rect(r, Color(col, 0.13 if alive else 0.05), true)
	else:
		draw_rect(r, Palette.PANEL, true)
		var f := StudioTheme.font("display")
		var letter := display_name.substr(0, 1) if display_name != "" else agent_id.substr(0, 1).to_upper()
		var fs := int(size.y * 0.42)
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		f.draw_string(get_canvas_item(), Vector2((size.x - w) * 0.5, size.y * 0.58), letter,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, 0.5 if alive else 0.2))

	# the strip under the name, and the frame
	var strip := Rect2(0, size.y - maxf(14.0, size.y * 0.2), size.x, maxf(14.0, size.y * 0.2))
	draw_rect(strip, Color(Palette.GROUND_DEEP, 0.85), true)
	if display_name != "":
		var nf := StudioTheme.font("bold")
		var ns := int(clampf(strip.size.y * 0.66, 9.0, 15.0))
		var nw := nf.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		nf.draw_string(get_canvas_item(), Vector2((size.x - nw) * 0.5, strip.position.y + strip.size.y * 0.78),
			display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, col if alive else Palette.DIM)

	var edge := col if alive else Palette.FAINT
	var width := 1.0
	if live:
		# on air: the frame breathes
		edge = Palette.ACCENT
		width = 2.0 + sin(_t * 6.0) * 0.6
	elif suspect:
		edge = Palette.HEAT
		width = 2.0
	draw_rect(r, edge, false, width)

	if not alive:
		# struck through, not greyed out: this person was killed, it is not a disabled button
		draw_line(Vector2(4, 4), size - Vector2(4, 4), Color(Palette.HEAT, 0.8), 2.0)
		draw_rect(r, Color(Palette.GROUND, 0.45), true)
