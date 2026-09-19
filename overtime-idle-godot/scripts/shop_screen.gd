class_name ShopScreen
extends Overlay
## Procurement: objects and relics for rent; Gold SKUs; the mocked IAP row. Nothing sold
## touches settle_grid(). Every buy is behind its own click; nothing opens by itself.

signal bought(sku: String)
signal timeskip_report(rep: Dictionary)
signal need(what: String)

const OBJECT_HINT := {"coffee": "Triples Dan beside it.", "mute": "Covers staff beside it from Wes's tax.", "printer": "+1 per occupied desk in its row.", "corner": "3, but only in a corner."}
const RELIC_NAME := {"severance": "Severance", "quiet": "Quiet Floor", "pto": "Unlimited PTO", "glass": "Glass Office", "badge": "Badge Reel", "army": "Intern Army"}
const RELIC_HINT := {"severance": "Empty desks pay 1 each.", "quiet": "Headphones cover diagonals too.", "pto": "First reroll per floor is free.", "glass": "Meetings no longer tax. Rent +10%.", "badge": "+1 per chain event.", "army": "Priya takes the best settled score beside her."}
const NAMES := {"coffee": "Coffee machine", "mute": "Headphones", "printer": "Printer", "corner": "Corner desk"}

var gold_tag: Label
var rent_row: GridContainer
var gold_row: GridContainer


func build() -> void:
	card_width = 980
	card.custom_minimum_size = Vector2(980, 0)
	tag("PROCUREMENT · PAID IN RENT")
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := Label.new()
	t.text = "Shop"
	t.theme_type_variation = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(button("CLOSE", "Ghost", close))
	para("Objects and relics are bought with rent. Gold buys time, pulls and a shield — never a rule.", 14)
	gold_tag = Label.new()
	gold_tag.theme_type_variation = "Mono"
	gold_tag.add_theme_color_override("font_color", Look.AMBER)
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
	gt.text = "GOLD · TIME, PULLS, A SHIELD.  IAP ROW IS MOCKED IN THIS BUILD."
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
	h.add_theme_color_override("font_color", Look.MUTED)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var p := Label.new()
	p.text = price
	p.theme_type_variation = "Mono"
	p.add_theme_color_override("font_color", Look.MUTED if off else Look.AMBER)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(p)
	return b


func render() -> void:
	gold_tag.text = "GOLD %d  ·  bank %d  ·  tickets %d  ·  shields %d" % [Economy.gold(), int(Ticker.B["bank"]), Economy.tickets(), Economy.shields()]
	clear(rent_row)
	clear(gold_row)
	for id in Roster.OBJECTS:
		var price: int = Ticker.OBJECT_PRICE[id]
		rent_row.add_child(_card("OBJECT", "%s  ×%d" % [NAMES[id], int(Ticker.B["inventory"].get(id, 0))], OBJECT_HINT[id], "rent %d" % price, false, func() -> void:
			if Ticker.buy_object(id):
				Sfx.shop()
				bought.emit(id)
				render()
			else:
				need.emit("rent")))
	for rid in Landlord.RELICS:
		var have: bool = Ticker.B["relics"].has(rid)
		rent_row.add_child(_card("RELIC", RELIC_NAME[rid], RELIC_HINT[rid], "owned" if have else "rent %d" % Ticker.RELIC_PRICE, have, func() -> void:
			if Ticker.buy_relic(rid):
				Sfx.shop()
				bought.emit(rid)
				render()
			else:
				need.emit("rent")))
	for sku in ["timeskip_4h", "offline_cap_24h", "rent_shield", "pull_1", "pull_10"]:
		var d: Dictionary = Economy.SKUS[sku]
		var owned := Economy.is_owned(sku)
		gold_row.add_child(_card("GOLD SKU", sku, d["en"], "owned" if owned else "Gold %d" % int(d["gold"]), owned, func() -> void:
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
		gold_row.add_child(_card("IAP (MOCKED)", d["en"], "Prototype: the store call is simulated. On Nutaku the GPHS PUT grants this.", d["iap"], false, func() -> void:
			Economy.purchase(sku)
			Sfx.shop()
			bought.emit(sku)
			render()))
