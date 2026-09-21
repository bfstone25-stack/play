class_name ShopScreen
extends Overlay
## Procurement: objects and relics for rent; Gold SKUs; the mocked IAP row. Nothing sold
## touches settle_grid(). Every buy is behind its own click; nothing opens by itself.

signal bought(sku: String)
signal timeskip_report(rep: Dictionary)
signal need(what: String)

## Every display string here is an I18n key (scripts/i18n.gd). The English of record for
## each one lives in that table's "en" block, so there is exactly one place to edit a line.
const OBJECT_HINT := {"coffee": "h_coffee", "mute": "h_mute", "printer": "h_printer", "corner": "h_corner"}
const RELIC_NAME := {"severance": "rl_severance", "quiet": "rl_quiet", "pto": "rl_pto", "glass": "rl_glass", "badge": "rl_badge", "army": "rl_army"}
const RELIC_HINT := {"severance": "rh_severance", "quiet": "rh_quiet", "pto": "rh_pto", "glass": "rh_glass", "badge": "rh_badge", "army": "rh_army"}
const NAMES := {"coffee": "n_coffee_shop", "mute": "n_mute", "printer": "n_printer", "corner": "n_corner"}

var gold_tag: Label
var rent_row: GridContainer
var gold_row: GridContainer


func build() -> void:
	card_width = 980
	card.custom_minimum_size = Vector2(980, 0)
	tag(I18n.t("shop_tag"))
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := Label.new()
	t.text = I18n.t("shop_title")
	t.theme_type_variation = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(button(I18n.t("close"), "Ghost", close))
	para(I18n.t("shop_para"), 14)
	gold_tag = Label.new()
	gold_tag.theme_type_variation = "Value"
	gold_tag.add_theme_color_override("font_color", Palette.GOLD)
	body.add_child(gold_tag)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	rent_row = GridContainer.new()
	rent_row.columns = 5
	rent_row.add_theme_constant_override("h_separation", 8)
	rent_row.add_theme_constant_override("v_separation", 8)
	v.add_child(rent_row)
	var gt := Label.new()
	gt.text = I18n.t("shop_gold_row")
	gt.theme_type_variation = "Tag"
	v.add_child(gt)
	gold_row = GridContainer.new()
	gold_row.columns = 4
	gold_row.add_theme_constant_override("h_separation", 8)
	gold_row.add_theme_constant_override("v_separation", 8)
	v.add_child(gold_row)


func on_open() -> void:
	render()


func _card(kind: String, name: String, hint: String, price: String, off: bool, on: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(176, 118)
	b.disabled = off
	b.pressed.connect(on)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_top = 6
	v.offset_right = -8
	v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var k := Label.new()
	k.text = kind
	k.theme_type_variation = "Tag"
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(k)
	var n := Label.new()
	n.text = name
	n.add_theme_font_override("font", Look.font_ui_bold)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var h := Label.new()
	h.text = hint
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_theme_font_size_override("font_size", 12)
	h.add_theme_color_override("font_color", Palette.MUTED)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var p := Label.new()
	p.text = price
	p.theme_type_variation = "Value"
	p.add_theme_font_override("font", Look.font_display)
	p.add_theme_color_override("font_color", Palette.MUTED if off else Palette.GOLD)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(p)
	return b


func render() -> void:
	gold_tag.text = I18n.f("shop_gold_tag", [Economy.gold(), int(Ticker.B["bank"]), Economy.tickets(), Economy.shields()])
	clear(rent_row)
	clear(gold_row)
	for id in Roster.OBJECTS:
		var price: int = Ticker.OBJECT_PRICE[id]
		rent_row.add_child(_card(I18n.t("k_object"), "%s  ×%d" % [I18n.t(str(NAMES[id])), int(Ticker.B["inventory"].get(id, 0))], I18n.t(str(OBJECT_HINT[id])), I18n.f("price_rent", price), false, func() -> void:
			if Ticker.buy_object(id):
				Sfx.shop()
				bought.emit(id)
				render()
			else:
				need.emit("rent")))
	for rid in Landlord.RELICS:
		var have: bool = Ticker.B["relics"].has(rid)
		rent_row.add_child(_card(I18n.t("k_relic"), I18n.t(str(RELIC_NAME[rid])), I18n.t(str(RELIC_HINT[rid])), I18n.t("owned") if have else I18n.f("price_rent", Ticker.RELIC_PRICE), have, func() -> void:
			if Ticker.buy_relic(rid):
				Sfx.shop()
				bought.emit(rid)
				render()
			else:
				need.emit("rent")))
	for sku in ["timeskip_4h", "offline_cap_24h", "rent_shield", "pull_1", "pull_10"]:
		var d: Dictionary = Economy.SKUS[sku]
		var owned := Economy.is_owned(sku)
		gold_row.add_child(_card(I18n.t("k_sku"), sku, I18n.t("sku_" + sku), I18n.t("owned") if owned else I18n.f("price_gold", int(d["gold"])), owned, func() -> void:
			var r := Economy.buy(sku)
			if not r["ok"]:
				need.emit("gold" if r["why"] == "gold" else str(r["why"]))
				return
			Sfx.shop()
			bought.emit(sku)
			if sku == "timeskip_4h":
				var rep := Ticker.do_timeskip()
				close()
				timeskip_report.emit(rep)
				return
			render()))
	for sku in ["gold_s", "gold_m", "gold_l"]:
		var d: Dictionary = Economy.SKUS[sku]
		gold_row.add_child(_card(I18n.t("k_iap"), I18n.t("sku_" + sku), I18n.t("iap_note"), d["iap"], false, func() -> void:
			Economy.purchase(sku)
			Sfx.shop()
			bought.emit(sku)
			render()))
