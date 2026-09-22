extends Control
class_name RouteSelect

## PORT_PLAN.md step 2 — "straight port of #cards". Loads the nine routes from
## backend/chars.json through Api.routes() rather than a second, hand-typed copy in the
## client: chars.json is already the one place those fields live, and a second copy is
## exactly how `itch-edit-form-repost` and the `_zh` field bug happened to other data in
## this same backend.
##
## Cards are StyleBoxFlat panels tinted by each route's `hue`, not rendered art. The
## portraits exist as JPGs under play/flutter/frontend/portraits but are served by
## whatever serves the HTML build's static files, not by an API path this client can
## reach — see PUNCHLIST.md. This is deliberately the "get the frame up" pass; bringing
## the art in is a separate, later decision.

signal picked(route: Dictionary)
signal back()

const FONT_REG := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")
const FONT_CJK := preload("res://assets/fonts/wqy-microhei.ttc")
var _fonts := [FONT_REG, FONT_BOLD]

var _grid: GridContainer
var _status: Label
var _loading := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_wire_fonts()
	_build()


func _wire_fonts() -> void:
	# See scripts/title_screen.gd:_wire_fonts — the fallback has to live on a font the
	# node itself holds a reference to, or it is gone on the web export.
	for f in _fonts:
		var fb: Array = f.fallbacks.duplicate()
		if not fb.has(FONT_CJK):
			fb.append(FONT_CJK)
			f.fallbacks = fb


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1c0a16")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "CHOOSE WHO TO TALK TO"
	title.add_theme_font_override("font", FONT_BOLD)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.82))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 64
	add_child(title)

	var back_btn := ShapedButton.new()
	back_btn.shape = ShapedButton.Shape.FOLD
	back_btn.compact = true
	back_btn.custom_minimum_size = Vector2(96, 32)
	back_btn.tint = Color("#7a3350")
	back_btn.ink = Color("#f4e6ea")
	back_btn.add_theme_font_override("font", FONT_REG)
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.label = "< back"
	back_btn.position = Vector2(24, 22)
	back_btn.pressed.connect(func(): back.emit())
	add_child(back_btn)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 90
	scroll.offset_bottom = -24
	scroll.offset_left = 48
	scroll.offset_right = -48
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	scroll.add_child(center)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	center.add_child(_grid)

	_status = Label.new()
	_status.add_theme_font_override("font", FONT_REG)
	_status.add_theme_color_override("font_color", Color(0.8, 0.72, 0.68))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_preset(Control.PRESET_CENTER)
	_status.offset_left = -200
	_status.offset_right = 200
	add_child(_status)


## Called every time the screen is shown — a fresh fetch, not a cache, so a route added
## or edited server-side (chars.json) shows up without a rebuild.
func reload() -> void:
	if _loading:
		return
	_loading = true
	_status.show()
	_status.text = "loading..."
	for c in _grid.get_children():
		c.queue_free()
	var res := await Api.routes("en")
	_loading = false
	if not is_inside_tree():
		return
	if res.has("error") or not (res.get("routes") is Array):
		_status.text = "could not reach the backend\n(%s)" % str(res.get("error", "unknown error"))
		return
	var route_list: Array = res["routes"]
	if route_list.is_empty():
		_status.text = "no routes returned"
		return
	_status.hide()
	for r in route_list:
		_grid.add_child(_make_card(r))


## A route is a person you might fall for — the card the studio's ShapedButton draws for
## that is CARD (a playing card, corner clipped): "pick a card" is exactly the fiction of
## route select. The button IS the card (tinted per route's own hue), not a shape hidden
## behind a StyleBoxFlat panel with an invisible click-catcher on top — see
## shaped_button.gd's own header on why a template rectangle with a label reads as "one
## screen rendered nine times" instead of nine different people.
func _make_card(r: Dictionary) -> Control:
	var hue := float(r.get("hue", 280)) / 360.0
	var panel := ShapedButton.new()
	panel.shape = ShapedButton.Shape.CARD
	panel.compact = true
	panel.custom_minimum_size = Vector2(260, 168)
	panel.tint = Color.from_hsv(hue, 0.42, 0.24)
	panel.ink = Color.from_hsv(hue, 0.5, 0.6)
	panel.focus_mode = Control.FOCUS_ALL
	panel.pressed.connect(func(): picked.emit(r))

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16
	vb.offset_right = -16
	vb.offset_top = 14
	vb.offset_bottom = -14
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var emoji := Label.new()
	emoji.text = str(r.get("emoji", "✦"))
	emoji.add_theme_font_size_override("font_size", 36)
	vb.add_child(emoji)

	var name_l := Label.new()
	name_l.text = str(r.get("name", "?"))
	name_l.add_theme_font_override("font", FONT_BOLD)
	name_l.add_theme_font_size_override("font_size", 19)
	name_l.add_theme_color_override("font_color", Color(0.97, 0.93, 0.89))
	vb.add_child(name_l)

	var title_l := Label.new()
	title_l.text = str(r.get("title", ""))
	title_l.add_theme_font_override("font", FONT_REG)
	title_l.add_theme_font_size_override("font_size", 13)
	title_l.add_theme_color_override("font_color", Color(0.86, 0.79, 0.75))
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(title_l)

	var tag_l := Label.new()
	tag_l.text = str(r.get("tag", ""))
	tag_l.add_theme_font_override("font", FONT_REG)
	tag_l.add_theme_font_size_override("font_size", 12)
	tag_l.add_theme_color_override("font_color", Color.from_hsv(hue, 0.4, 0.85))
	vb.add_child(tag_l)

	return panel
