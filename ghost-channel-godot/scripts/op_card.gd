## One operation, as a card on the console: the op's name, what it adds, and either its best
## score, its lock, or its price.
##
## The three ops differ by exactly which lie is available to the ghost, so the card says that
## in a line of instrument shorthand rather than in prose — BOOK CLEAN / PLOT CLEAN / CAPTIVE
## ON NET — and the ones that are *not* clean are in the alarm colour. A player picking op 3
## should be able to see the three ways the room can lie to them before they press it.
extends Button

signal chosen(index: int)

@export var index := 0

var _t := 0.0
var _state := "open"          # open | locked | gated


func _ready() -> void:
	theme_type_variation = "Ghost"
	flat = true
	pressed.connect(func():
		Sfx.click()
		chosen.emit(index))
	mouse_entered.connect(func(): Sfx.squelch_open())
	set_process(true)
	refresh()


func refresh() -> void:
	var op: Dictionary = GCRules.OPS[index]
	if GCRules.op_locked(index, Game.wins, Game.best):
		_state = "locked"
	elif index > 0 and OS.has_feature("web") and not Gate.has("op" + str(int(op.id))):
		_state = "gated"
	else:
		_state = "open"
	disabled = false
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if is_hovered():
		queue_redraw()


func _draw() -> void:
	var op: Dictionary = GCRules.OPS[index]
	var meta := GCStrings.op_meta(Game.lang, index)
	var r := Rect2(Vector2.ZERO, size)
	var hot := is_hovered() and _state != "locked"
	var edge: Color = Palette.ACCENT if hot else Palette.PANEL_EDGE
	if _state == "locked":
		edge = Palette.FAINT

	draw_rect(r, Color(Palette.PANEL, 0.93), true)
	draw_rect(Rect2(0, 0, size.x, 4), Color(edge, 0.9), true)
	draw_rect(r, edge, false, 1.0)
	if hot:
		draw_rect(r.grow(2.0), Color(Palette.ACCENT, 0.18), false, 3.0)

	var pad := 16.0
	var y := 44.0
	# the op number, set big and faint behind the name: a card index, not a decoration
	var disp := StudioTheme.font("display")
	var num := str(int(op.id))
	disp.draw_string(get_canvas_item(), Vector2(size.x - 44, 62), num,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(Palette.TEXT, 0.07))

	disp.draw_string(get_canvas_item(), Vector2(pad, y), str(meta.name),
		HORIZONTAL_ALIGNMENT_LEFT, size.x - pad * 2, 24,
		Palette.TEXT if _state != "locked" else Palette.DIM)
	y += 18

	var body := StudioTheme.font("ui")
	draw_string_lines(body, str(meta.blurb), Vector2(pad, y + 14), size.x - pad * 2, 14,
		Color(Palette.MUTED, 1.0))
	y += 78

	# the three conditions, as instrument shorthand
	var mono := StudioTheme.font("mono")
	var rows := [
		["BOOK", not op.poison, "CLEAN", "POISONABLE"],
		["PLOT", not op.mapSpoof, "CLEAN", "SPOOFED"],
		["NET", not op.captured, "ALL FREE", "CAPTIVE"],
	]
	for row in rows:
		var good: bool = row[1]
		mono.draw_string(get_canvas_item(), Vector2(pad, y), str(row[0]).rpad(6),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.MUTED)
		mono.draw_string(get_canvas_item(), Vector2(pad + 52, y), str(row[2] if good else row[3]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.SUCCESS if good else Palette.HEAT)
		y += 17

	# the footer line: best / locked / price
	var foot := Rect2(0, size.y - 34, size.x, 34)
	draw_rect(foot, Color(Palette.GROUND_DEEP, 0.7), true)
	var text := ""
	var col := Palette.GOLD
	match _state:
		"locked":
			text = Game.t("locked")
			col = Palette.DIM
		"gated":
			text = "· " + _price()
			col = Palette.ACCENT
		_:
			text = Game.t("best", {"n": Game.best_for(int(op.id))})
	StudioTheme.font("bold").draw_string(get_canvas_item(), Vector2(pad, size.y - 12), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)


## What the gate will ask for on this distribution: a sponsor clip on the ad-supported
## site, the price on itch. Read from the page's GATE_CONFIG, the same source gate.js uses.
func _price() -> String:
	if not OS.has_feature("web"):
		return ""
	var dist := str(JavaScriptBridge.eval("(window.Gate && window.Gate.dist && window.Gate.dist()) || ''"))
	if dist == "ads_web":
		return "SPONSOR CLIP"
	var p := str(JavaScriptBridge.eval("(window.GATE_CONFIG && window.GATE_CONFIG.price) || ''"))
	return p if p != "" else "FULL GAME"


## draw_string with a width cap wraps, but does not return the rows; this draws up to three
## wrapped lines by hand so the card's geometry is predictable.
func draw_string_lines(f: Font, s: String, at: Vector2, width: float, fs: int, col: Color) -> void:
	var words := s.split(" ", false)
	var line := ""
	var y := at.y
	var drawn := 0
	for w in words:
		var probe := (line + " " + w).strip_edges() if line != "" else w
		if f.get_string_size(probe, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and line != "":
			f.draw_string(get_canvas_item(), Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			y += fs + 4
			drawn += 1
			line = w
			if drawn >= 3:
				return
		else:
			line = probe
	if line != "":
		f.draw_string(get_canvas_item(), Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
