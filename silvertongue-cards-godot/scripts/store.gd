## Store — Nutaku gold (Nutaku F2P only). Every row is a SKU from the title server's
## catalogue (/nutaku/catalog); pressing one opens Nutaku's own payment confirm through
## NutakuGI.createPayment, the platform charges the gold, our payment handler delivers
## inside its own transaction, and the screen re-reads the state. The client never grants
## anything itself. Nothing here sells a win: tickets, charm, chips and early scenes only.
extends Control

var main: Node
var _list: VBoxContainer


func setup(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 14
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	col.add_child(StudioTheme.display_label(Loc.t("STORE"), 34, Palette.GOLD))
	var sub := StudioTheme.serif_label(Loc.t("Paid in Nutaku gold (100 gold = $1). Everything in the story can be won without it; gold only makes it sooner."), 13, Palette.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	sc.add_child(_list)
	_render()


const ORDER := ["starter", "pull_10", "pull_1", "charm_refill", "charm_5", "night_pass", "chips_1500",
	"scene_c1", "scene_c2", "scene_c3", "scene_c4", "scene_c5", "scene_c6", "all_scenes"]


func _render() -> void:
	for c in _list.get_children():
		c.queue_free()
	var cat := {}
	for s in Nutaku.catalog:
		cat[str(s.get("skuId", ""))] = s
	for id in ORDER:
		if not cat.has(id):
			continue
		var s: Dictionary = cat[id]
		# a refill "to the top" when charm is already at or over its cap would take gold for
		# nothing (the server fills only up to the cap), so it is not offered then -- PLICATA's rule
		var e: Dictionary = Nutaku.state.get("energy", {})
		if id == "charm_refill" and int(e.get("now", 0)) >= int(e.get("max", 8)):
			continue
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, Palette.GOLD if id == "starter" else Palette.PANEL_EDGE, 10, 1, Vector2(14, 8)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(StudioTheme.display_label(Loc.s(s.get("name", id)), 20, Palette.TEXT))
		var d := StudioTheme.serif_label(Loc.s(s.get("description", "")), 13, Palette.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		h.add_child(v)
		var b := StudioTheme.card_button(Loc.t("%d GOLD") % int(s.get("price", 0)), "pull")
		b.custom_minimum_size = Vector2(150, 44)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _buy(id))
		h.add_child(b)
		_list.add_child(row)


func _buy(id: String) -> void:
	Sfx.play("ui_click")
	var r := await F2P.buy(id)
	match str(r.get("status", "error")):
		"success":
			Sfx.play("gold")
			main.toast(Loc.t("Delivered."), 2.0, Palette.SUCCESS)
		"cancel":
			main.toast(Loc.t("Cancelled."))
		"errorFromGPHS":
			main.toast(Loc.t("The purchase did not go through; Nutaku has refunded the gold."))
		_:
			main.toast(Loc.s(r["error"]) if r.has("error") else Loc.t("Purchase failed."))
