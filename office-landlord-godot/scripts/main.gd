extends Control
## Office Landlord's whole loop in one screen tree: title -> floor -> panels.
##
## Rewritten 2026-09-21 to run on the REAL kernel (scripts/landlord.gd, ported from
## play/catharsis/kernel/landlord.js) via the `Grid` autoload (scripts/grid.gd), replacing
## the old six-flat-rectangle desk row and its fake per-second income tick. The title
## screen is now its own class (scripts/title_screen.gd) rather than built inline here —
## splitting it out matches the studio's per-screen-class convention (overtime's
## title_screen.gd) and keeps this file to the floor loop and its three panels.
##
## Stages a player (and ops/play_driver.py) can reach, in order:
##   1. TITLE   - OfficeTitle: "OPEN FOR BUSINESS"
##   2. FLOOR   - the real 5x4 grid: a tray of rollable symbols, live per-cell scores from
##                Landlord.settle_grid(), rent due for the current floor, a "collect rent"
##                action
##   3. SHOP    (key 1) - real offers from Grid.shop_offers() / Landlord.pick_shop()
##   4. STAFF   (key 2) - staff-tagged symbols actually on the board right now
##   5. REPORT  (key 3, or automatically after collecting rent) - the real settle_grid
##                breakdown: payout, rent, met/evicted, top scored events
##   6. FLOOR again, visibly different once rent is paid (grid clears, floor number bumps,
##      rent target grows per Landlord.rent_for_floor's RENT_GROWTH curve)

const ShapedButtonScript := preload("res://scripts/shaped_button.gd")
const GridCellScript := preload("res://scripts/grid_cell.gd")
const TitleScript := preload("res://scripts/title_screen.gd")

const COLS := 5
const ROWS := 4
const CELL_W := 104.0
const CELL_H := 92.0
const CELL_GAP := 8.0
const GRID_ORIGIN := Vector2(108, 96)

var title_screen: Control
var floor_layer: Control

var floor_label: Label
var rent_label: Label
var payout_label: Label
var banked_label: Label
var met_label: Label
var collect_button
var cell_nodes: Array = []
var tray_nodes: Array = []
var selected_tray_index := -1

var active_panel: Panel = null
var active_panel_kind := ""


func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.GROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	title_screen = TitleScript.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.start.connect(_show_floor)
	add_child(title_screen)

	_build_floor()

	Grid.changed.connect(_refresh)
	Grid.rent_paid.connect(_on_rent_paid)
	Grid.evicted.connect(_on_evicted)
	I18n.changed.connect(func(_l): _relabel())

	_refresh()
	_show_title()


# ---------------------------------------------------------------------------- floor ----
func _build_floor() -> void:
	floor_layer = Control.new()
	floor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_layer.visible = false
	add_child(floor_layer)

	floor_label = Label.new()
	floor_label.position = Vector2(40, 20)
	floor_label.add_theme_font_size_override("font_size", 26)
	floor_label.add_theme_color_override("font_color", Palette.TEXT)
	floor_layer.add_child(floor_label)

	rent_label = Label.new()
	rent_label.position = Vector2(260, 22)
	rent_label.add_theme_font_size_override("font_size", 18)
	rent_label.add_theme_color_override("font_color", Palette.GOLD_DEEP)
	floor_layer.add_child(rent_label)

	payout_label = Label.new()
	payout_label.position = Vector2(500, 22)
	payout_label.add_theme_font_size_override("font_size", 18)
	payout_label.add_theme_color_override("font_color", Palette.HEAT)
	floor_layer.add_child(payout_label)

	banked_label = Label.new()
	banked_label.position = Vector2(740, 22)
	banked_label.add_theme_font_size_override("font_size", 18)
	banked_label.add_theme_color_override("font_color", Palette.MUTED)
	floor_layer.add_child(banked_label)

	met_label = Label.new()
	met_label.position = Vector2(960, 20)
	met_label.add_theme_font_size_override("font_size", 22)
	floor_layer.add_child(met_label)

	# the 5x4 desk grid -- one GridCell per Landlord cell index, positioned to match
	# Landlord.idx()'s row-major layout so cell i sits at (i % COLS, i / COLS)
	for i in range(COLS * ROWS):
		var cell := GridCellScript.new()
		var p := Landlord.xy_of(i)
		cell.position = GRID_ORIGIN + Vector2(p.x * (CELL_W + CELL_GAP), p.y * (CELL_H + CELL_GAP))
		cell.size = Vector2(CELL_W, CELL_H)
		cell.pressed.connect(func(): _on_cell_pressed(i))
		floor_layer.add_child(cell)
		cell_nodes.append(cell)

	# the tray: rolled symbols waiting to be placed. Below the grid, same cell width.
	var tray_y: float = GRID_ORIGIN.y + ROWS * (CELL_H + CELL_GAP) + 18.0
	for i in range(Grid.TRAY_SIZE):
		var slot := GridCellScript.new()
		slot.show_score = false
		slot.position = Vector2(GRID_ORIGIN.x + i * (CELL_W + CELL_GAP), tray_y)
		slot.size = Vector2(CELL_W, CELL_H)
		slot.pressed.connect(func(): _on_tray_pressed(i))
		floor_layer.add_child(slot)
		tray_nodes.append(slot)

	var tray_hint := Label.new()
	tray_hint.text = I18n.t("tray_label")
	tray_hint.position = Vector2(GRID_ORIGIN.x, tray_y - 22)
	tray_hint.add_theme_font_size_override("font_size", 14)
	tray_hint.add_theme_color_override("font_color", Palette.MUTED)
	tray_hint.name = "TrayHintLabel"
	floor_layer.add_child(tray_hint)

	# bottom action row: collect (right) -- matches ops/play_driver.py's bottom-row probe
	# at y=671 across three x positions, same convention the old scaffold used.
	collect_button = ShapedButtonScript.new()
	collect_button.shape = ShapedButtonScript.Shape.TICKET
	collect_button.tint = Palette.HEAT
	collect_button.custom_minimum_size = Vector2(280, 80)
	collect_button.position = Vector2(780, 610)
	collect_button.pressed.connect(_on_collect)
	floor_layer.add_child(collect_button)

	var hint := Label.new()
	hint.text = I18n.t("shop_hint")
	hint.name = "PanelHintLabel"
	hint.position = Vector2(540, 630)
	hint.add_theme_color_override("font_color", Palette.MUTED)
	floor_layer.add_child(hint)

	var lang_btn := Button.new()
	lang_btn.text = I18n.ENDONYM[I18n.lang]
	lang_btn.position = Vector2(1120, 20)
	lang_btn.pressed.connect(func():
		I18n.cycle()
		lang_btn.text = I18n.ENDONYM[I18n.lang])
	lang_btn.name = "FloorLangButton"
	floor_layer.add_child(lang_btn)


func _on_cell_pressed(i: int) -> void:
	if selected_tray_index < 0:
		return
	if Grid.place(selected_tray_index, i):
		Sfx.place()
		selected_tray_index = -1
	_refresh()


func _on_tray_pressed(i: int) -> void:
	if i >= Grid.tray.size():
		return
	selected_tray_index = -1 if selected_tray_index == i else i
	_refresh()


func _on_collect() -> void:
	Grid.collect_rent()


func _on_rent_paid(_report: Dictionary) -> void:
	Sfx.rent_paid()
	Sfx.bark("win_big" if _report.get("payout", 0) - _report.get("rent", 0) >= 6 else "win")
	_open_report()


func _on_evicted(_report: Dictionary) -> void:
	Sfx.evict()
	Sfx.bark("fail")
	_open_report()


# --------------------------------------------------------------------------- panels ----
func _open_panel_shell(title_text: String) -> VBoxContainer:
	_close_panel()
	var p := Panel.new()
	p.custom_minimum_size = Vector2(760, 460)
	p.position = Vector2(260, 130)
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
	active_panel = p

	var v := VBoxContainer.new()
	v.position = Vector2(36, 26)
	v.custom_minimum_size = Vector2(690, 410)
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	v.add_child(t)

	# _open_panel_shell begins by closing whatever was open, and _close_panel publishes
	# "floor". Without this second publish the bridge reports "floor" for the whole time a
	# panel is on screen -- the mirror of the bug where it reported "title" after the floor
	# had opened. A read-only state view is only worth having if every transition writes it.
	_publish()
	return v


func _panel_close_button(v: VBoxContainer) -> void:
	var close := ShapedButtonScript.new()
	close.shape = ShapedButtonScript.Shape.TICKET
	close.tint = Palette.MUTED
	close.custom_minimum_size = Vector2(160, 56)
	close.text = I18n.t("close")
	close.pressed.connect(_close_panel)
	v.add_child(close)


## Real shop offers (Landlord.pick_shop via Grid.shop_offers), not static text. Buying a
## relic applies it to every future settle_grid() call; buying a symbol adds a copy to the
## deck, which only changes future tray odds -- see grid.gd's header for why.
func _open_shop() -> void:
	active_panel_kind = "shop"
	var v := _open_panel_shell(I18n.t("shop_title"))
	var offers: Array = Grid.shop_offers(3)
	for offer in offers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		v.add_child(row)

		var name_lbl := Label.new()
		var id: String = offer["id"]
		var label_text: String = I18n.relic(id) if offer["kind"] == "relic" else I18n.symbol(id)
		var desc: String = I18n.relic_desc(id) if offer["kind"] == "relic" else ""
		name_lbl.text = label_text
		name_lbl.custom_minimum_size = Vector2(220, 0)
		name_lbl.add_theme_color_override("font_color", Palette.TEXT)
		row.add_child(name_lbl)

		if desc != "":
			var desc_lbl := Label.new()
			desc_lbl.text = desc
			desc_lbl.custom_minimum_size = Vector2(280, 0)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.add_theme_font_size_override("font_size", 14)
			desc_lbl.add_theme_color_override("font_color", Palette.MUTED)
			row.add_child(desc_lbl)

		var buy_btn := ShapedButtonScript.new()
		buy_btn.shape = ShapedButtonScript.Shape.TAG
		buy_btn.tint = Palette.GOLD if Grid.can_buy(offer) else Palette.MUTED
		buy_btn.custom_minimum_size = Vector2(150, 52)
		buy_btn.text = "%s (%d)" % [I18n.t("buy_button"), Grid.price(offer)]
		buy_btn.disabled = not Grid.can_buy(offer)
		buy_btn.pressed.connect(func():
			if Grid.buy(offer):
				Sfx.buy()
				_open_shop())
		row.add_child(buy_btn)

	_panel_close_button(v)


## Which staff-tagged symbols (dev/intern/standup) are on the board RIGHT NOW, from live
## Grid state -- not a canned roster string.
func _open_staff() -> void:
	active_panel_kind = "staff"
	var v := _open_panel_shell(I18n.t("staff_title"))
	var staff: Array = Grid.staff_on_board()
	if staff.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = I18n.t("staff_empty")
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_lbl.custom_minimum_size = Vector2(660, 0)
		empty_lbl.add_theme_color_override("font_color", Palette.TEXT)
		v.add_child(empty_lbl)
	else:
		for entry in staff:
			var row := Label.new()
			row.text = I18n.f("staff_row", [int(entry["index"]) + 1, I18n.symbol(entry["id"])])
			row.add_theme_color_override("font_color", Palette.TEXT)
			v.add_child(row)
	_panel_close_button(v)


## The real settle_grid breakdown for the CURRENT board: payout, rent, met/evicted, and
## the top scored events (translated via I18n.ev()) -- not a canned string. Shows the
## last collect_rent() result when one exists (so the panel that pops up automatically
## after collecting reads as a report of what just happened), otherwise a live preview of
## the board as it stands.
func _open_report() -> void:
	active_panel_kind = "report"
	var v := _open_panel_shell(I18n.t("report_title"))
	var report: Dictionary = Grid.last_report if not Grid.last_report.is_empty() else Grid.settle()
	var rent: int = report.get("rent", Grid.current_rent())
	var payout: int = report.get("payout", 0)

	var payout_lbl := Label.new()
	payout_lbl.text = I18n.f("report_payout", [payout])
	payout_lbl.add_theme_font_size_override("font_size", 20)
	payout_lbl.add_theme_color_override("font_color", Palette.HEAT)
	v.add_child(payout_lbl)

	var rent_lbl := Label.new()
	rent_lbl.text = I18n.f("report_rent", [rent])
	rent_lbl.add_theme_font_size_override("font_size", 20)
	rent_lbl.add_theme_color_override("font_color", Palette.GOLD_DEEP)
	v.add_child(rent_lbl)

	if report.has("met"):
		var status_lbl := Label.new()
		if report["met"]:
			status_lbl.text = I18n.f("report_met", [Grid.floor_level])
			status_lbl.add_theme_color_override("font_color", Palette.SUCCESS)
		else:
			status_lbl.text = I18n.f("report_evicted", [rent - payout, int(report.get("penalty", 0))])
			status_lbl.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
		status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_lbl.custom_minimum_size = Vector2(660, 0)
		v.add_child(status_lbl)

	var events_lbl := Label.new()
	events_lbl.text = I18n.t("report_events_label")
	events_lbl.add_theme_font_size_override("font_size", 16)
	events_lbl.add_theme_color_override("font_color", Palette.MUTED)
	v.add_child(events_lbl)

	var events: Array = report.get("events", [])
	if events.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = I18n.t("report_no_events")
		none_lbl.add_theme_color_override("font_color", Palette.TEXT)
		v.add_child(none_lbl)
	else:
		# top 3, counted by frequency, so a board with six "tag-staff" links reads as one
		# line rather than six -- landlord.js's own `events` array logs one entry per
		# trigger, not per kind.
		var counts := {}
		for e in events:
			counts[e] = int(counts.get(e, 0)) + 1
		var kinds: Array = counts.keys()
		kinds.sort_custom(func(a, b): return counts[a] > counts[b])
		for i in range(min(3, kinds.size())):
			var k: String = kinds[i]
			var row := Label.new()
			row.text = "%s x%d" % [I18n.ev(k), counts[k]]
			row.add_theme_color_override("font_color", Palette.TEXT)
			v.add_child(row)

	_panel_close_button(v)


func _close_panel() -> void:
	if active_panel:
		active_panel.queue_free()
		active_panel = null
	active_panel_kind = ""
	_publish()


func _show_title() -> void:
	title_screen.visible = true
	_publish()
	floor_layer.visible = false
	_close_panel()


func _show_floor() -> void:
	title_screen.visible = false
	floor_layer.visible = true
	_close_panel()
	Sfx.bark("greet")
	# Publish on the transition, not only from _refresh(). _refresh() does not run when
	# the title is dismissed, so window.__ol_state kept reporting screen="title" while the
	# floor was plainly on screen -- the driver's clicks were landing and the bridge was
	# the thing lying about it. A read-only view that reports a stale screen is worse than
	# no view at all.
	_publish()


# --------------------------------------------------------------------------- refresh ----
func _refresh() -> void:
	_publish()
	if not is_instance_valid(floor_label):
		return
	floor_label.text = I18n.f("floor_label", [Grid.floor_level])
	var rent := Grid.current_rent()
	var report := Grid.settle()
	var payout: int = report["payout"]
	rent_label.text = "%s: %d" % [I18n.t("rent_due_label"), rent]
	payout_label.text = "%s: %d" % [I18n.t("payout_label"), payout]
	banked_label.text = "%s: %d" % [I18n.t("banked_label"), Grid.banked]
	var met := payout >= rent
	met_label.text = I18n.t("met_label") if met else I18n.t("not_met_label")
	met_label.add_theme_color_override("font_color", Palette.SUCCESS if met else Palette.ACCENT_DEEP)

	var scores: Array = report["cellScore"]
	for i in range(cell_nodes.size()):
		var cell = cell_nodes[i]
		cell.symbol_id = Landlord._id(Grid.cells, i)
		cell.score = int(scores[i]) if i < scores.size() else 0

	for i in range(tray_nodes.size()):
		var slot = tray_nodes[i]
		slot.symbol_id = Grid.tray[i] if i < Grid.tray.size() else ""
		slot.selected = (i == selected_tray_index)

	if active_panel_kind == "shop":
		_open_shop()
	elif active_panel_kind == "staff":
		_open_staff()
	elif active_panel_kind == "report":
		pass  # the report panel is a snapshot of the moment it opened; live board changes
	          # don't rewrite it out from under the player mid-read


func _relabel() -> void:
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if not floor_layer.visible:
		return
	match event.keycode:
		KEY_1:
			_open_shop()
		KEY_2:
			_open_staff()
		KEY_3:
			_open_report()
		KEY_ESCAPE:
			_close_panel()


## A read-only view of the floor on window.__ol_state, for tests/headless_web.py.
##
## Read-only, the same rule its sibling OCCUPANCY and FOLD both keep: the driver plays
## with real clicks and uses this only to see what happened. A command channel would let
## a test drive the rules directly and pass while the input handling was broken, which is
## the one failure a "does it work in a browser" test exists to catch.
##
## Added 2026-09-22 because Office Landlord was the only Godot title in the portfolio with
## no tests/ directory at all. Its matrix came from the generic click driver and read as
## 2 distinct stages out of 54 frames, against 15 for the sibling that has a driver --
## which looked like a shallow game and was actually an unmeasured one.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	var filled := 0
	for c in Grid.cells:
		if c != null and c != "":
			filled += 1
	JavaScriptBridge.eval("window.__ol_state=%s;" % JSON.stringify({
		"screen": ("title" if is_instance_valid(title_screen) and title_screen.visible
				else ("panel:" + active_panel_kind if active_panel != null else "floor")),
		"floor": Grid.floor_level,
		"banked": Grid.banked,
		"rent": Grid.current_rent(),
		"rent_met": Grid.rent_met(),
		"filled": filled,
		"cells": Grid.cells.size(),
		"tray": Grid.tray.size(),
		"relics": Grid.relics.size(),
		"lang": I18n.lang,
	}), true)
