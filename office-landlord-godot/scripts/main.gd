extends Control
## Office Landlord's whole loop in one screen tree: title -> floor -> panels -> report.
##
## Deliberately self-contained (no shared Overlay/Theme classes) so this small game builds
## and runs on its own. Stages a player (and ops/play_driver.py) can reach, in order:
##   1. TITLE   - "OPEN FOR BUSINESS"
##   2. FLOOR   - desks fill in, rent ticks up, hire tenants
##   3. SHOP    (key 1) - office shop panel
##   4. STAFF   (key 2) - staff directory panel
##   5. REPORT  (key 3, or "move to a bigger building" once full) - weekly report
##   6. FLOOR at floor_level 2+ - visibly different (desk count reset, label bumped)

const ShapedButtonScript := preload("res://scripts/shaped_button.gd")

var title_layer: Control
var floor_layer: Control
var panel_layer: Control

var rent_label: Label
var floor_label: Label
var desk_row: HBoxContainer
var hire_button: Button
var move_up_button: Button
var desk_nodes: Array = []

var active_panel: Panel = null

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.GROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_title()
	_build_floor()
	Economy.changed.connect(_refresh)
	I18n.changed.connect(func(_l): _relabel())
	_refresh()
	_show_title()

# ---------------------------------------------------------------------------- title ----
func _build_title() -> void:
	title_layer = Control.new()
	title_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title_layer)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(340, 220)
	v.add_theme_constant_override("separation", 18)
	title_layer.add_child(v)

	var t := Label.new()
	t.name = "TitleLabel"
	t.text = I18n.t("title")
	t.add_theme_font_size_override("font_size", 56)
	t.add_theme_color_override("font_color", Palette.ACCENT)
	v.add_child(t)

	var sub := Label.new()
	sub.name = "SubtitleLabel"
	sub.text = I18n.t("subtitle")
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Palette.TEXT)
	v.add_child(sub)

	var start := ShapedButtonScript.new()
	start.shape = ShapedButtonScript.Shape.TICKET
	start.tint = Palette.ACCENT
	start.custom_minimum_size = Vector2(320, 90)
	start.text = I18n.t("start")
	start.pressed.connect(_show_floor)
	v.add_child(start)

	var lang_btn := Button.new()
	lang_btn.text = I18n.ENDONYM[I18n.lang]
	lang_btn.position = Vector2(1120, 20)
	lang_btn.pressed.connect(func():
		I18n.cycle()
		lang_btn.text = I18n.ENDONYM[I18n.lang])
	title_layer.add_child(lang_btn)

# ---------------------------------------------------------------------------- floor ----
func _build_floor() -> void:
	floor_layer = Control.new()
	floor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_layer.visible = false
	add_child(floor_layer)

	floor_label = Label.new()
	floor_label.position = Vector2(40, 24)
	floor_label.add_theme_font_size_override("font_size", 28)
	floor_label.add_theme_color_override("font_color", Palette.TEXT)
	floor_layer.add_child(floor_label)

	rent_label = Label.new()
	rent_label.position = Vector2(40, 66)
	rent_label.add_theme_font_size_override("font_size", 24)
	rent_label.add_theme_color_override("font_color", Palette.GOLD_DEEP)
	floor_layer.add_child(rent_label)

	desk_row = HBoxContainer.new()
	desk_row.position = Vector2(80, 220)
	desk_row.add_theme_constant_override("separation", 24)
	floor_layer.add_child(desk_row)
	for i in Economy.MAX_DESKS:
		var d := Panel.new()
		d.custom_minimum_size = Vector2(150, 180)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.MUTED
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		d.add_theme_stylebox_override("panel", sb)
		desk_row.add_child(d)
		desk_nodes.append(sb)

	# bottom action row: hire (left), shop hint (mid), move-up (right) — matches
	# ops/play_driver.py's bottom-row probe at y=671 across three x positions.
	hire_button = ShapedButtonScript.new()
	hire_button.shape = ShapedButtonScript.Shape.TICKET
	hire_button.tint = Palette.HEAT
	hire_button.custom_minimum_size = Vector2(260, 80)
	hire_button.position = Vector2(200, 610)
	hire_button.pressed.connect(func(): Economy.hire())
	floor_layer.add_child(hire_button)

	var hint := Label.new()
	hint.text = "1: shop   2: staff   3: report"
	hint.position = Vector2(540, 630)
	hint.add_theme_color_override("font_color", Palette.MUTED)
	floor_layer.add_child(hint)

	move_up_button = ShapedButtonScript.new()
	move_up_button.shape = ShapedButtonScript.Shape.TICKET
	move_up_button.tint = Palette.GOLD
	move_up_button.custom_minimum_size = Vector2(300, 80)
	move_up_button.position = Vector2(780, 610)
	move_up_button.pressed.connect(_do_prestige)
	floor_layer.add_child(move_up_button)

func _do_prestige() -> void:
	if not Economy.floor_full():
		return
	_show_report()
	Economy.prestige()

# --------------------------------------------------------------------------- panels ----
func _open_panel(title_key: String, body_key: String) -> void:
	_close_panel()
	var p := Panel.new()
	p.custom_minimum_size = Vector2(700, 420)
	p.position = Vector2(290, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.PANEL
	sb.border_color = Palette.PANEL_EDGE
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)

	var v := VBoxContainer.new()
	v.position = Vector2(36, 30)
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)

	var t := Label.new()
	t.text = I18n.t(title_key)
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	v.add_child(t)

	var body := Label.new()
	body.text = I18n.t(body_key)
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Palette.TEXT)
	body.custom_minimum_size = Vector2(620, 200)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(body)

	var close := ShapedButtonScript.new()
	close.shape = ShapedButtonScript.Shape.TICKET
	close.tint = Palette.MUTED
	close.custom_minimum_size = Vector2(180, 60)
	close.text = I18n.t("close")
	close.pressed.connect(_close_panel)
	v.add_child(close)

	active_panel = p

func _open_report() -> void:
	_close_panel()
	var p := Panel.new()
	p.custom_minimum_size = Vector2(700, 420)
	p.position = Vector2(290, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.PANEL
	sb.border_color = Palette.GOLD
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)

	var v := VBoxContainer.new()
	v.position = Vector2(36, 30)
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)

	var t := Label.new()
	t.text = I18n.t("result_title")
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	v.add_child(t)

	var body := Label.new()
	body.text = I18n.f("result_body", [int(Economy.rent), Economy.desks_filled, Economy.floor_level])
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Palette.TEXT)
	v.add_child(body)

	var close := ShapedButtonScript.new()
	close.shape = ShapedButtonScript.Shape.TICKET
	close.tint = Palette.MUTED
	close.custom_minimum_size = Vector2(180, 60)
	close.text = I18n.t("close")
	close.pressed.connect(_close_panel)
	v.add_child(close)

	active_panel = p

func _close_panel() -> void:
	if active_panel:
		active_panel.queue_free()
		active_panel = null

func _show_report() -> void:
	_open_report()

func _show_title() -> void:
	title_layer.visible = true
	floor_layer.visible = false
	_close_panel()

func _show_floor() -> void:
	title_layer.visible = false
	floor_layer.visible = true
	_close_panel()

func _refresh() -> void:
	if not is_instance_valid(rent_label):
		return
	rent_label.text = "%s: %d" % [I18n.t("rent_label"), int(Economy.rent)]
	floor_label.text = I18n.f("floor_label", [Economy.floor_level])
	for i in desk_nodes.size():
		var sb: StyleBoxFlat = desk_nodes[i]
		sb.bg_color = Palette.SUCCESS if i < Economy.desks_filled else Palette.MUTED
	if Economy.can_hire():
		hire_button.text = "%s\n%s" % [I18n.t("hire"), I18n.f("hire_cost", [Economy.hire_cost()])]
		hire_button.disabled = false
	else:
		hire_button.text = I18n.t("floor_full") if Economy.floor_full() else I18n.t("hire")
		hire_button.disabled = Economy.floor_full()
	move_up_button.text = I18n.t("move_up")
	move_up_button.disabled = not Economy.floor_full()

func _relabel() -> void:
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if not floor_layer.visible:
		return
	match event.keycode:
		KEY_1:
			_open_panel("shop_title", "shop_body")
		KEY_2:
			_open_panel("staff_title", "staff_body")
		KEY_3:
			_open_report()
		KEY_ESCAPE:
			_close_panel()
