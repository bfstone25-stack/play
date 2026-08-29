extends Control

const MidnightStateScript = preload("res://scripts/game_state.gd")
const PixelStageScript = preload("res://scripts/pixel_stage.gd")
const PixelBodyFont = preload("res://assets/fonts/midnight_pixel_12.fnt")
const PixelDisplayFont = preload("res://assets/fonts/midnight_pixel_16.fnt")

var state
var stage
var header: Label
var phase_label: Label
var title: Label
var subtitle: Label
var customer_portrait: TextureRect
var detail: RichTextLabel
var log_label: RichTextLabel
var item_grid: GridContainer
var actions: HBoxContainer
var footer_hint: Label
var pause_layer: ColorRect
var log_lines: Array[String] = []
var encounter_open := false
var audio_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

const BG := Color("#100d18")
const PANEL := Color("#201928")
const PANEL_2 := Color("#2b2133")
const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const MUTED := Color("#9f94ac")
const RED := Color("#d45b68")
const TEAL := Color("#52b4a6")
const UI_ATLAS = preload("res://assets/pixel/ui_atlas.png")
const CURIO_ATLAS = preload("res://assets/pixel/curios.png")
const CHARACTER_ATLAS = preload("res://assets/pixel/characters.png")
const CURIO_ORDER := [
	"wedding_ring", "bone_key", "music_box", "dueling_pistol",
	"black_ledger", "moon_coin", "saints_tooth", "crypt_heart",
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_theme()
	state = MidnightStateScript.new()
	state.phase = MidnightStateScript.Phase.TITLE
	stage.objective_reached.connect(_on_objective_reached)
	stage.floor_risk_triggered.connect(_on_floor_risk)
	get_viewport().size_changed.connect(_on_viewport_changed)
	_show_title()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 10)
	root_margin.add_theme_constant_override("margin_right", 10)
	root_margin.add_theme_constant_override("margin_top", 8)
	root_margin.add_theme_constant_override("margin_bottom", 8)
	add_child(root_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	root_margin.add_child(column)

	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 28
	column.add_child(top)
	phase_label = Label.new()
	phase_label.text = "MIDNIGHT PAWN"
	phase_label.add_theme_color_override("font_color", GOLD)
	phase_label.add_theme_font_override("font", PixelDisplayFont)
	phase_label.add_theme_font_size_override("font_size", 16)
	top.add_child(phase_label)
	header = Label.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_theme_color_override("font_color", CREAM)
	header.add_theme_font_size_override("font_size", 12)
	top.add_child(header)
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.tooltip_text = "Pause / 暂停"
	pause.custom_minimum_size = Vector2(42, 30)
	pause.pressed.connect(_toggle_pause)
	top.add_child(pause)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 300
	column.add_child(body)
	var stage_panel := PanelContainer.new()
	stage_panel.custom_minimum_size = Vector2(300, 240)
	body.add_child(stage_panel)
	stage = PixelStageScript.new()
	stage.custom_minimum_size = Vector2(300, 240)
	stage_panel.add_child(stage)

	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 8)
	body.add_child(info_margin)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info_margin.add_child(info)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 5)
	info.add_child(title_row)
	title = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_override("font", PixelDisplayFont)
	title.add_theme_font_size_override("font_size", 16)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_row.add_child(title)
	customer_portrait = TextureRect.new()
	customer_portrait.custom_minimum_size = Vector2(32, 48)
	customer_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	customer_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	customer_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	customer_portrait.visible = false
	title_row.add_child(customer_portrait)
	subtitle = Label.new()
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(subtitle)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.fit_content = false
	detail.scroll_active = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size.y = 72
	detail.add_theme_font_size_override("normal_font_size", 12)
	info.add_child(detail)
	item_grid = GridContainer.new()
	item_grid.columns = 2
	item_grid.add_theme_constant_override("h_separation", 4)
	item_grid.add_theme_constant_override("v_separation", 4)
	info.add_child(item_grid)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.custom_minimum_size.y = 42
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.add_theme_font_size_override("normal_font_size", 12)
	info.add_child(log_label)

	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	actions.custom_minimum_size.y = 42
	column.add_child(actions)
	footer_hint = Label.new()
	footer_hint.text = "Click/tap controls · 点击即可游玩"
	footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_hint.add_theme_color_override("font_color", MUTED)
	footer_hint.add_theme_font_size_override("font_size", 12)
	column.add_child(footer_hint)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.volume_db = -26
	add_child(ambience_player)

	pause_layer = ColorRect.new()
	pause_layer.color = Color(0.04, 0.03, 0.07, 0.94)
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.visible = false
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_layer)
	var pause_center := CenterContainer.new()
	pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(pause_center)
	var pause_box := VBoxContainer.new()
	pause_box.add_theme_constant_override("separation", 10)
	pause_center.add_child(pause_box)
	var paused := Label.new()
	paused.text = "PAUSED / 暂停"
	paused.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused.add_theme_font_override("font", PixelDisplayFont)
	paused.add_theme_font_size_override("font_size", 16)
	pause_box.add_child(paused)
	for spec in [["RESUME / 继续", "_resume"], ["RESTART RUN / 重开本局", "_restart"], ["TITLE / 返回标题", "_title"]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(220, 44)
		button.pressed.connect(Callable(self, spec[1]))
		pause_box.add_child(button)


func _atlas(source: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = region
	return texture


func _ui_style(region: Rect2) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _atlas(UI_ATLAS, region)
	style.texture_margin_left = 3
	style.texture_margin_top = 3
	style.texture_margin_right = 3
	style.texture_margin_bottom = 3
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return style


func _apply_theme() -> void:
	var theme := Theme.new()
	theme.default_font = PixelBodyFont
	theme.default_font_size = 12
	theme.set_stylebox("normal", "Button", _ui_style(Rect2(0, 0, 64, 32)))
	theme.set_stylebox("hover", "Button", _ui_style(Rect2(64, 0, 64, 32)))
	theme.set_stylebox("pressed", "Button", _ui_style(Rect2(192, 0, 64, 32)))
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_font_size("font_size", "Button", 12)
	theme.set_stylebox("panel", "PanelContainer", _ui_style(Rect2(0, 0, 64, 32)))
	self.theme = theme


func _button(text: String, callback: Callable, accent := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(92, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if accent:
		b.add_theme_color_override("font_color", GOLD)
	b.pressed.connect(callback)
	actions.add_child(b)
	return b


func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _show_title() -> void:
	state = MidnightStateScript.new()
	state.phase = MidnightStateScript.Phase.TITLE
	stage.set_scene("title")
	customer_portrait.visible = false
	_set_ambience("shop")
	item_grid.visible = true
	log_label.visible = true
	phase_label.text = "MIDNIGHT PAWN & CRYPT"
	header.text = "Complete free run · 15–20 min"
	title.text = "午夜典当行与地下密室"
	subtitle.text = "MIDNIGHT PAWN & CRYPT"
	detail.text = "[color=#f1dfb0]继承一间只在午夜进货的典当行。白天衡量价格，夜里衡量代价。[/color]\n\nAppraise cursed curios, read customers, cross four crypt rooms, and decide what no pawnbroker should own."
	_clear(item_grid)
	_clear(actions)
	_button("BEGIN INHERITANCE\n开始继承", _start_run, true)
	_button("HOW TO PLAY\n玩法说明", _show_help)
	log_lines = ["All controls support mouse, touch, and keyboard."]
	_refresh_log()


func _show_help() -> void:
	detail.text = "[color=#e8b84a]SHOP / 典当行[/color]\nAppraise → set LOW/FAIR/HIGH → display → read each customer → accept or reject.\n\n[color=#e8b84a]CRYPT / 地窖[/color]\nWASD/arrows, tap a destination, or use the D-pad. Reach the marked encounter. Strike, guard, remember, or use your carried curio.\n\n[color=#e8b84a]LOSS[/color]\nDefeat loses only unbanked loot and marks. Nara recovers and the story continues."


func _start_run() -> void:
	state.reset()
	_play("bell")
	stage.set_scene("shop")
	_show_opening()


func _show_opening() -> void:
	phase_label.text = "23:41 · INHERITANCE"
	item_grid.visible = true
	log_label.visible = true
	header.text = "18G  ♥12  ◆5"
	title.text = "The Last Receipt / 最后一张当票"
	customer_portrait.visible = false
	subtitle.text = "Opening + tutorial transaction"
	detail.text = "[color=#f1dfb0]AUNT ELSA'S WILL:[/color]\n“Every object has two prices: what the living offer, and what the dead return for.”\n\nThe Bell Child waits at the counter with a rusted bell. Appraise the maker's mark, choose a fair 10G price, then complete your first sale."
	_clear(item_grid)
	_add_item_button("锈蚀招魂铃\nRusted Bell · ? → 10G", func(): pass, true)
	_clear(actions)
	_button("APPRAISE\n鉴定", func(): _opening_step(1))
	footer_hint.text = "Tutorial: every transaction shows value, demand, and consequence."
	_log("The shop bell rings once, although the door never opened.")


func _opening_step(step: int) -> void:
	if step == 1:
		_play("appraise")
		detail.text = "[color=#e8b84a]IDENTIFIED[/color] · Rusted Bell / 锈蚀招魂铃\nValue 10G · Demand: MEMORY · Curse: none\nClue: Its last ring calls a child, not a ghost.\n\nThe Bell Child offers exactly 10G. This fair sale funds the lamps without exploiting a memory."
		_clear(actions)
		_button("PRICE: FAIR 10G\n公平定价", func(): _opening_step(2), true)
	else:
		state.tutorial_sale()
		_play("coin")
		_log("SALE +10G · Bell Child: “Now it knows where home is.”")
		_show_shop()


func _show_shop() -> void:
	encounter_open = false
	stage.set_scene("shop")
	_set_ambience("shop")
	item_grid.visible = true
	log_label.visible = false
	stage.customer_id = str(state.current_customer().get("id", ""))
	stage.set_customer_expression(0)
	var day_text := "DAY 1 · 10:12" if state.day == 1 else "DAY 2 · 09:47"
	phase_label.text = day_text
	header.text = "%dG  HP%d  RES%d  CURSE%d  BANK%d" % [state.gold, state.health, state.resolve, state.curse, state.marks_bank]
	var customer: Dictionary = state.current_customer()
	_set_customer_portrait(customer, 0)
	title.text = "Shop Floor / 典当营业"
	if customer.is_empty():
		subtitle.text = "Customers served. Choose what crosses midnight with you."
	else:
		subtitle.text = "NEXT: %s / %s" % [customer["name"], customer["zh"]]
	detail.text = _shop_detail(customer)
	_refresh_item_grid()
	_refresh_shop_actions()
	footer_hint.text = "Shelf %d/3 · Transactions %d/5 · Select a curio card" % [state.shelf.size(), state.transactions.size()]


func _shop_detail(customer: Dictionary) -> String:
	var item: Dictionary = state.get_item(state.selected_id)
	if item.is_empty():
		return "Select a curio. A run cannot softlock: unsold stock can always be carried."
	var mode_names := ["LOW −20%", "FAIR", "HIGH +25%"]
	var text := "[color=#e8b84a]%s / %s[/color]\n" % [item["name"], item["zh"]]
	if item["appraised"]:
		text += "Value %dG · Price %s · Curse %d · Demand %s\n%s\n" % [item["value"], mode_names[item["price_mode"]], item["curse"], str(item["demand"]).to_upper(), item["clue"]]
	else:
		text += "Value ? · Curse ? · Demand ?\nAppraise to reveal exact identity and tradeoffs.\n"
	if not customer.is_empty():
		text += "\n[color=#52b4a6]%s[/color] wants %s.\n%s" % [customer["name"], str(customer["wants"]).to_upper(), customer["behavior"]]
	return text


func _set_customer_portrait(customer: Dictionary, expression: int) -> void:
	if customer.is_empty():
		customer_portrait.visible = false
		return
	var index := ["mara", "orin", "tamsin", "ivo"].find(str(customer.get("id", "")))
	if index < 0:
		customer_portrait.visible = false
		return
	customer_portrait.texture = _atlas(CHARACTER_ATLAS, Rect2(clampi(expression, 0, 3) * 32, 48 + index * 48, 32, 48))
	customer_portrait.visible = true


func _refresh_item_grid() -> void:
	_clear(item_grid)
	for item in state.inventory:
		var mark := "?" if not item["appraised"] else ("%dG" % item["value"])
		var shelf_mark := " ◆" if item["id"] in state.shelf else ""
		var curse_mark := "" if not item["appraised"] or int(item["curse"]) == 0 else " ☾%d" % item["curse"]
		var text := "%s%s\n%s%s" % [item["zh"], shelf_mark, mark, curse_mark]
		var item_button := _add_item_button(text, func(id = item["id"]): _select_item(id), item["id"] == state.selected_id)
		var icon_index := CURIO_ORDER.find(str(item["id"]))
		if icon_index >= 0:
			item_button.icon = _atlas(CURIO_ATLAS, Rect2(icon_index * 32, 0, 32, 32))
			item_button.add_theme_constant_override("icon_max_width", 24)
			item_button.expand_icon = true


func _add_item_button(text: String, callback: Callable, selected := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(132, 42)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	if selected:
		b.add_theme_color_override("font_color", GOLD)
	item_grid.add_child(b)
	return b


func _select_item(id: String) -> void:
	state.selected_id = id
	stage.selected_curio = id
	stage.queue_redraw()
	_play("tick")
	_show_shop()


func _refresh_shop_actions() -> void:
	_clear(actions)
	var item: Dictionary = state.get_item(state.selected_id)
	if item.is_empty():
		return
	if not item["appraised"]:
		_button("APPRAISE\n鉴定", _appraise_selected, true)
	else:
		var modes := ["LOW", "FAIR", "HIGH"]
		_button("PRICE: %s\n调整定价" % modes[item["price_mode"]], _cycle_price)
		_button(("REMOVE\n撤下货架" if item["id"] in state.shelf else "DISPLAY\n上架"), _toggle_display)
		if not state.current_customer().is_empty() and item["id"] in state.shelf:
			_button("CALL CUSTOMER\n接待顾客", _call_customer, true)
	if state.can_enter_night():
		_button("CARRY & DESCEND\n携带并下楼", _enter_night, true)


func _appraise_selected() -> void:
	if state.appraise(state.selected_id):
		_play("appraise")
		_log("IDENTIFIED · %s — %s" % [state.get_item(state.selected_id)["name"], state.get_item(state.selected_id)["clue"]])
	_show_shop()


func _cycle_price() -> void:
	state.cycle_price(state.selected_id)
	_play("tick")
	_show_shop()


func _toggle_display() -> void:
	if not state.toggle_shelf(state.selected_id):
		_log("Shelf full: remove one of the three displayed curios.")
	else:
		_play("tick")
	_show_shop()


func _call_customer() -> void:
	if not state.call_customer(state.selected_id):
		_log("This customer refuses an unidentified cursed object.")
	_show_customer_offer()


func _show_customer_offer() -> void:
	var customer: Dictionary = state.current_customer()
	var item: Dictionary = state.get_item(state.selected_id)
	stage.set_customer_expression(2)
	_set_customer_portrait(customer, 2)
	item_grid.visible = false
	log_label.visible = true
	title.text = "%s / %s" % [customer["name"], customer["zh"]]
	subtitle.text = customer["behavior"]
	var offer_text := "REFUSES: identity evidence is incomplete." if state.offer <= 0 else "OFFERS %dG for %s." % [state.offer, item["name"]]
	detail.text = "[color=#52b4a6]%s[/color]\n\nValue %dG · Listed posture %s · Demand match: %s\nCurse %d: revealing it earns trust; concealing it adds debt to the ending." % [offer_text, item["value"], ["LOW", "FAIR", "HIGH"][item["price_mode"]], "YES" if item["demand"] == customer["wants"] else "NO", item["curse"]]
	_clear(actions)
	if customer["id"] == "tamsin" and not state.negotiated:
		_button("NEGOTIATE −1 RES\n议价", _negotiate_offer, true)
	_button("ACCEPT + WARN\n成交并告知诅咒", func(): _resolve_offer(true, true), true)
	_button("ACCEPT + HIDE\n隐瞒后成交", func(): _resolve_offer(true, false))
	_button("REJECT / 拒绝", func(): _resolve_offer(false, true))


func _negotiate_offer() -> void:
	if state.negotiate_current():
		_play("coin")
		_log("NEGOTIATED · Tamsin adds 5G after a direct warning.")
	else:
		_log("Negotiation needs 1 Resolve and can only be attempted once.")
	_show_customer_offer()


func _resolve_offer(accept: bool, honest: bool) -> void:
	var customer_name := str(state.current_customer().get("name", "Customer"))
	var item_name := str(state.get_item(state.selected_id).get("name", "curio"))
	var amount: int = state.offer
	var sold: bool = state.resolve_customer(accept, honest)
	_play("coin" if sold else "tick")
	if sold:
		_log("SALE +%dG · %s buys %s%s." % [amount, customer_name, item_name, " with a truthful warning" if honest else " — curse concealed"])
	else:
		_log("%s leaves; %s remains in inventory." % [customer_name, item_name])
	_show_shop()


func _enter_night() -> void:
	if not state.enter_night(state.selected_id):
		_log("Serve two customers this day and select a carried curio.")
		return
	_play("bell")
	_start_room()


func _start_room() -> void:
	encounter_open = false
	stage.set_scene("dungeon", state.room_index)
	customer_portrait.visible = false
	_set_ambience("crypt")
	item_grid.visible = false
	log_label.visible = true
	var room: Dictionary = MidnightStateScript.ROOMS[state.room_index]
	phase_label.text = "NIGHT %d · ROOM %d/4" % [state.night, state.room_index + 1]
	header.text = "%dG  HP%d  RES%d  CURSE%d  UNBANKED%d" % [state.gold, state.health, state.resolve, state.curse, state.marks_unbanked]
	title.text = "%s / %s" % [room["name"], room["zh"]]
	subtitle.text = room["risk"]
	detail.text = "Move Nara across the room to the pulsing encounter mark.\n\n[color=#d45b68]RISK:[/color] %s\n[color=#52b4a6]CARRIED:[/color] %s\n\nTap the floor, use WASD/arrows, or press the on-screen direction controls." % [room["risk"], state.get_item(state.carried_id).get("name", "none")]
	_clear(item_grid)
	_clear(actions)
	for spec in [
		[Vector2.LEFT, Rect2(0, 32, 64, 40)],
		[Vector2.UP, Rect2(64, 32, 64, 40)],
		[Vector2.DOWN, Rect2(128, 32, 64, 40)],
		[Vector2.RIGHT, Rect2(192, 32, 64, 40)],
	]:
		var move_button := _button("", func(direction = spec[0]): stage.nudge(direction))
		move_button.icon = _atlas(UI_ATLAS, spec[1])
		move_button.add_theme_constant_override("icon_max_width", 30)
		move_button.expand_icon = true
	_button("APPROACH\n接敌", _on_objective_reached, true)
	footer_hint.text = "Movement is required in normal play; APPROACH is an accessibility shortcut."


func _on_floor_risk() -> void:
	state.trigger_floor_risk()
	_play("hit")
	_log("FLOOR RISK triggered · Health %d · Resolve %d · Curse %d" % [state.health, state.resolve, state.curse])
	if state.phase == MidnightStateScript.Phase.DAY_2:
		_log("RECOVERY: unbanked loot lost; Nara returns with 3 health and emergency 5G.")
		_show_shop()
	elif state.phase == MidnightStateScript.Phase.FINAL:
		_show_final()
	else:
		_start_room()


func _on_objective_reached() -> void:
	if encounter_open or not state.room_active:
		return
	encounter_open = true
	var room: Dictionary = MidnightStateScript.ROOMS[state.room_index]
	title.text = "%s · HP %d/%d" % [room["enemy"], state.enemy_hp, room["hp"]]
	subtitle.text = "Deterministic pattern: attacks for %d; guard reduces the next hit." % room["damage"]
	detail.text = "[color=#d45b68]%s blocks extraction.[/color]\n\nSTRIKE deals 2. GUARD reduces damage and restores Resolve. REMEMBER costs 2 Resolve and reveals identity. CARRIED ITEM uses its room synergy or heals 2." % room["enemy"]
	_clear(actions)
	_button("STRIKE\n攻击", func(): _combat("strike"), true)
	_button("GUARD\n格挡", func(): _combat("guard"))
	_button("REMEMBER −2◆\n追忆", func(): _combat("remember"))
	_button("USE CARRIED\n使用古物", func(): _combat("item"))
	if state.room_index == 1 and state.carried_id == "wedding_ring":
		_button("RETURN RING\n归还婚戒", _peaceful_claimant, true)


func _peaceful_claimant() -> void:
	if state.peaceful_claimant():
		_play("loot")
		_log("MERCY +3 · Widow Voss remembers the missing song. No combat.")
		_room_cleared()


func _combat(action: String) -> void:
	var result: Dictionary = state.combat_action(action)
	if not result.get("ok", false):
		_log("Not enough Resolve for that action.")
		return
	_play("hit" if not result.get("won", false) else "loot")
	if state.phase == MidnightStateScript.Phase.DAY_2:
		_log("DEFEAT & RECOVERY · unbanked loot and marks lost; banked goods persist.")
		_show_shop()
		return
	if state.phase == MidnightStateScript.Phase.FINAL:
		_log("DEFEAT & RECOVERY · the cracked Heart still demands a decision.")
		_show_final()
		return
	_log("%s: dealt %d · received %d · enemy HP %d · Nara ♥%d" % [action.to_upper(), result.get("dealt", 0), result.get("damage", 0), state.enemy_hp, state.health])
	if result.get("won", false):
		_room_cleared()
	else:
		_on_objective_reached_refresh()


func _on_objective_reached_refresh() -> void:
	encounter_open = false
	_on_objective_reached()


func _room_cleared() -> void:
	stage.mark_enemy_defeated()
	var room: Dictionary = MidnightStateScript.ROOMS[state.room_index]
	title.text = "ROOM CLEARED / 房间已清理"
	subtitle.text = "%s cannot follow you." % room["enemy"]
	var loot_text := ""
	if state.room_index == 0:
		loot_text = "\nLoot: Moon Coin (unbanked)."
	elif state.room_index == 2 and state.carried_id == "bone_key":
		loot_text = "\nOPTIONAL CACHE: Saint's Tooth recovered."
	elif state.room_index == 3:
		loot_text = "\nCORE CURIO: Heart of the Crypt recovered."
	detail.text = "Marks +%d%s\n\nUnbanked rewards are lost on defeat. Extraction after the second room banks everything." % [room["marks"] * (2 if state.carried_id == "black_ledger" else 1), loot_text]
	_clear(actions)
	_button("CONTINUE / 继续", _advance_room, true)


func _advance_room() -> void:
	var old_phase: int = state.phase
	state.advance_room()
	if state.phase == old_phase:
		_start_room()
	elif state.phase == MidnightStateScript.Phase.DAY_2:
		_play("coin")
		_log("EXTRACTED · Loot and %d marks banked. New identities surface at dawn." % state.marks_bank)
		_show_shop()
	else:
		_play("appraise")
		_show_final()


func _show_final() -> void:
	stage.set_scene("final")
	stage.selected_curio = "crypt_heart"
	customer_portrait.visible = false
	_set_ambience("crypt")
	item_grid.visible = false
	log_label.visible = true
	phase_label.text = "00:17 · FINAL APPRAISAL"
	header.text = "%dG  HP%d  CURSE%d  MERCY%d" % [state.gold, state.health, state.curse, state.mercy]
	title.text = "Heart of the Crypt / 地窖之心"
	subtitle.text = "Value 40G · Curse 4 · Demand: your own"
	detail.text = "[color=#f1dfb0]“The shop is its coffin. Your name is its key.”[/color]\n\n[color=#e8b84a]SELL[/color] gains its appraised value; gold and concealed debt shape the business.\n[color=#52b4a6]SEAL[/color] costs 12G; mercy, clues, and low curse strengthen the ward.\n[color=#d45b68]KEEP[/color] preserves power; survival, health, optional relic, and curse decide who owns whom."
	_clear(item_grid)
	_clear(actions)
	_button("SELL +%dG\n出售核心" % state.get_item("crypt_heart").get("value", 20), func(): _choose_final("sell"), true)
	_button("SEAL −12G\n封印核心", func(): _choose_final("seal"))
	_button("KEEP\n保留核心", func(): _choose_final("keep"))
	footer_hint.text = "Final decision node · economy + choices + survival determine the result."


func _choose_final(choice: String) -> void:
	state.choose_final(choice)
	_play("bell")
	_show_result()


func _show_result() -> void:
	stage.set_scene("result")
	customer_portrait.visible = false
	_set_ambience("shop")
	item_grid.visible = false
	log_label.visible = true
	phase_label.text = "RUN COMPLETE"
	header.text = "SCORE %d · RANK %s" % [state.score, state.rank]
	title.text = state.outcome
	var condition := ""
	match state.final_choice:
		"sell":
			condition = "The lamps stay lit. %s" % ("No hidden debt follows the buyer." if state.curse <= 2 else "Red ink appears beneath tomorrow's profits.")
		"seal":
			condition = "The crypt falls quiet. %s" % ("Claimants find their names at dawn." if state.mercy >= 3 else "The seal holds, but nobody remembers why.")
		"keep":
			condition = "Nara keeps the Heart. %s" % ("It beats when she commands." if state.health >= 4 and state.curse <= 5 else "Some nights, it appraises her.")
	subtitle.text = condition
	detail.text = "[color=#e8b84a]ECONOMY[/color] %dG · Banked marks %d\n[color=#52b4a6]CHOICES[/color] Mercy %d · Trust %d · Clues %d\n[color=#d45b68]SURVIVAL[/color] Health %d · Curse %d · Recoveries %d\nRooms %d/4 · Customers %d · Optional relic %s\n\nSCORE %d · RANK %s\nMeasured session %.1f min · Normal reading route %.1f min" % [state.gold, state.marks_bank, state.mercy, state.trust, state.clues, state.health, state.curse, state.recovered, state.rooms_cleared.size(), state.transactions.size(), "YES" if state.optional_relic else "NO", state.score, state.rank, state.elapsed_seconds() / 60.0, state.expected_normal_minutes()]
	_clear(item_grid)
	_clear(actions)
	_button("REPLAY / 再来一局", _start_run, true)
	_button("TITLE / 返回标题", _show_title)
	footer_hint.text = "Replay with different pricing, truth, carried curio, relic route, and core choice."


func _log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 7:
		log_lines.pop_front()
	_refresh_log()
	print("[MPC] ", text)


func _refresh_log() -> void:
	if log_label == null:
		return
	log_label.text = "[color=#9f94ac]LEDGER LOG[/color]\n" + "\n".join(log_lines)
	log_label.scroll_to_line(maxi(0, log_lines.size() - 1))


func _play(kind: String) -> void:
	var specs := {
		"bell": [660.0, 0.22, 0.42],
		"appraise": [920.0, 0.12, 0.25],
		"coin": [1180.0, 0.10, 0.28],
		"hit": [130.0, 0.09, 0.34],
		"loot": [780.0, 0.16, 0.30],
		"tick": [440.0, 0.04, 0.18],
	}
	var spec: Array = specs.get(kind, specs["tick"])
	audio_player.stream = _tone(spec[0], spec[1], spec[2])
	audio_player.play()
	if kind == "hit" and is_instance_valid(stage):
		stage.position = Vector2(3, -2)
		var shake := create_tween()
		shake.tween_property(stage, "position", Vector2.ZERO, 0.09)


func _set_ambience(kind: String) -> void:
	var frequency := 72.0 if kind == "shop" else 48.0
	if ambience_player.has_meta("kind") and ambience_player.get_meta("kind") == kind:
		return
	var stream := _tone(frequency, 2.0, 0.035)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	ambience_player.stream = stream
	ambience_player.set_meta("kind", kind)
	ambience_player.play()


func _tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var frames := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var envelope := 1.0 - float(i) / frames
		var sample := sin(TAU * frequency * i / mix_rate) * envelope * volume
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav


func _toggle_pause() -> void:
	if state.phase == MidnightStateScript.Phase.TITLE:
		return
	pause_layer.visible = not pause_layer.visible
	get_tree().paused = pause_layer.visible
	pause_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _resume() -> void:
	pause_layer.visible = false
	get_tree().paused = false


func _restart() -> void:
	_resume()
	_start_run()


func _title() -> void:
	_resume()
	_show_title()


func _on_viewport_changed() -> void:
	var narrow := get_viewport_rect().size.x < 700
	var split := find_children("*", "HSplitContainer", true, false)
	if not split.is_empty():
		(split[0] as HSplitContainer).split_offset = 250 if narrow else 300


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		return
	if state.phase != MidnightStateScript.Phase.NIGHT_1 and state.phase != MidnightStateScript.Phase.NIGHT_2:
		return
	if event.is_action_pressed("move_left"):
		stage.nudge(Vector2.LEFT)
	elif event.is_action_pressed("move_right"):
		stage.nudge(Vector2.RIGHT)
	elif event.is_action_pressed("move_up"):
		stage.nudge(Vector2.UP)
	elif event.is_action_pressed("move_down"):
		stage.nudge(Vector2.DOWN)


# Test-facing deterministic route helpers.
func start_run() -> void:
	_start_run()


func complete_tutorial() -> void:
	state.tutorial_sale()
	_show_shop()


func test_enter_encounter() -> void:
	_on_objective_reached()


func test_finish_combat() -> void:
	while state.room_active and state.phase in [MidnightStateScript.Phase.NIGHT_1, MidnightStateScript.Phase.NIGHT_2]:
		state.combat_action("strike")
