class_name GridCell
extends Control
## One square of the 5x4 desk grid, or one slot in the tray — same component either way,
## since both just show a catalog symbol (or nothing) and take a click.
##
## Deliberately hand-drawn vector glyphs (`_draw()`, in the spirit of shaped_button.gd's
## custom drawing) rather than flat colour rectangles: a coffee cup silhouette, a monitor
## for `dev`, a headphone shape for `mute`, and so on — eight visually distinct symbols
## readable at cell scale. See ops/PUNCHLIST.md's Office Landlord row for the honest
## caveat this file's header comment insists on: these are vector glyphs, NOT rendered
## art. The headline ask ("没有真实美术") is about the title key visual, which is a real
## ops/render_queue.py render; a full GPU render pass for eight icons this small was
## judged not worth the queue time, and that judgement call is recorded here and in the
## PUNCHLIST rather than left for someone to assume otherwise from a screenshot.

signal pressed

@export var symbol_id: String = "":
	set(v):
		symbol_id = v
		queue_redraw()
@export var score: int = 0:
	set(v):
		score = v
		queue_redraw()
@export var selected: bool = false:
	set(v):
		selected = v
		queue_redraw()
@export var show_score: bool = true

var _hover := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _hover = true; queue_redraw())
	mouse_exited.connect(func(): _hover = false; queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _tag_color(tag: String) -> Color:
	match tag:
		"fuel": return Palette.GOLD
		"staff": return Palette.HEAT
		"noise": return Palette.ACCENT
		"infra": return Palette.SKY
		_: return Palette.MUTED


func _catalog_tag(id: String) -> String:
	for s in Landlord.CATALOG:
		if s["id"] == id:
			return str(s["tag"])
	return ""


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var empty := symbol_id == ""
	var bg := Palette.PANEL if not empty else Palette.PANEL_RAISED
	if _hover:
		bg = bg.lightened(0.08)
	draw_rect(r, bg, true)
	var edge := Palette.PANEL_EDGE if not selected else Palette.ACCENT_DEEP
	draw_rect(r, edge, false, 3.0 if selected else 1.5)

	if empty:
		return

	var tag := _catalog_tag(symbol_id)
	var ink := _tag_color(tag)
	var c := size * 0.5
	var s: float = minf(size.x, size.y)

	match symbol_id:
		"coffee":
			# a cup: rounded body + a handle arc
			var cup := Rect2(c.x - s * 0.22, c.y - s * 0.14, s * 0.40, s * 0.32)
			draw_rect(cup, ink, true)
			draw_arc(Vector2(cup.position.x + cup.size.x, c.y), s * 0.12, -PI * 0.5, PI * 0.5, 10, ink, s * 0.05)
			draw_rect(Rect2(cup.position.x - s * 0.02, cup.position.y - s * 0.05, cup.size.x + s * 0.04, s * 0.05), ink.darkened(0.15), true)
		"dev":
			# a monitor on a stand
			var mon := Rect2(c.x - s * 0.26, c.y - s * 0.22, s * 0.52, s * 0.34)
			draw_rect(mon, ink, true)
			draw_rect(Rect2(c.x - s * 0.06, mon.position.y + mon.size.y, s * 0.12, s * 0.10), ink, true)
			draw_rect(Rect2(c.x - s * 0.16, mon.position.y + mon.size.y + s * 0.10, s * 0.32, s * 0.05), ink, true)
		"intern":
			# a small figure: circle head + triangle body, deliberately smaller than dev
			draw_circle(Vector2(c.x, c.y - s * 0.16), s * 0.10, ink)
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x, c.y - s * 0.04), Vector2(c.x + s * 0.16, c.y + s * 0.22),
				Vector2(c.x - s * 0.16, c.y + s * 0.22)]), ink)
		"meeting":
			# a table (oval) with chairs (small dots) around it
			draw_rect(Rect2(c.x - s * 0.22, c.y - s * 0.10, s * 0.44, s * 0.20), ink, true)
			for a in [0.0, PI * 0.5, PI, PI * 1.5]:
				var p := c + Vector2(cos(a), sin(a)) * s * 0.32
				draw_circle(p, s * 0.045, ink.darkened(0.1))
		"mute":
			# a headphone: an arc band + two ear cups
			draw_arc(c, s * 0.24, PI * 1.05, PI * 1.95, 16, ink, s * 0.045)
			draw_rect(Rect2(c.x - s * 0.30, c.y - s * 0.02, s * 0.10, s * 0.20), ink, true)
			draw_rect(Rect2(c.x + s * 0.20, c.y - s * 0.02, s * 0.10, s * 0.20), ink, true)
		"printer":
			# a box with a paper tray line
			draw_rect(Rect2(c.x - s * 0.24, c.y - s * 0.14, s * 0.48, s * 0.26), ink, true)
			draw_rect(Rect2(c.x - s * 0.16, c.y + s * 0.10, s * 0.32, s * 0.06), ink.lightened(0.2), true)
			draw_rect(Rect2(c.x - s * 0.10, c.y - s * 0.24, s * 0.20, s * 0.10), ink.darkened(0.1), true)
		"standup":
			# an upward arrow/starburst — energy, momentum
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x, c.y - s * 0.26), Vector2(c.x + s * 0.16, c.y + s * 0.06),
				Vector2(c.x + s * 0.06, c.y + s * 0.06), Vector2(c.x + s * 0.06, c.y + s * 0.22),
				Vector2(c.x - s * 0.06, c.y + s * 0.22), Vector2(c.x - s * 0.06, c.y + s * 0.06),
				Vector2(c.x - s * 0.16, c.y + s * 0.06)]), ink)
		"corner":
			# a pennant/diamond — marks the "only pays on a corner cell" rule
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x, c.y - s * 0.26), Vector2(c.x + s * 0.22, c.y),
				Vector2(c.x, c.y + s * 0.26), Vector2(c.x - s * 0.22, c.y)]), ink)
		_:
			draw_circle(c, s * 0.18, ink)

	if show_score and score != 0:
		var f := ThemeDB.fallback_font
		var txt := str(score)
		var pos := Vector2(size.x - 8.0 - f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, size.y - 6.0)
		draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.ACCENT_DEEP)
