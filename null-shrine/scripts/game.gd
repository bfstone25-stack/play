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
var pause_title: Label
var pause_resume: Button
var pause_restart: Button
var pause_title_btn: Button
var pause_button: Button
var lang_caption: Label
var lang_en: Button
var lang_zh: Button
var lang_buttons: Dictionary = {}
var lang_box: VBoxContainer
var lang_host: VBoxContainer
var stage_panel: PanelContainer
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
	Loc.on_change(_on_locale_changed)
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
	root_margin.add_theme_constant_override("margin_top", 6)
	root_margin.add_theme_constant_override("margin_bottom", 6)
	add_child(root_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	root_margin.add_child(column)

	var top := HBoxContainer.new()
	top.clip_contents = false
	top.custom_minimum_size.y = 32
	column.add_child(top)
	phase_label = Label.new()
	phase_label.text = "MIDNIGHT PAWN"
	phase_label.clip_text = false
	phase_label.add_theme_color_override("font_color", GOLD)
	phase_label.add_theme_font_override("font", PixelDisplayFont)
	phase_label.add_theme_font_size_override("font_size", 16)
	top.add_child(phase_label)
	header = Label.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.clip_text = false
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.max_lines_visible = 2
	header.custom_minimum_size.y = 32
	header.add_theme_color_override("font_color", CREAM)
	header.add_theme_font_size_override("font_size", 12)
	top.add_child(header)
	pause_button = Button.new()
	pause_button.text = "Ⅱ"
	pause_button.tooltip_text = Loc.t("pause.tip")
	pause_button.custom_minimum_size = Vector2(42, 30)
	pause_button.pressed.connect(_toggle_pause)
	top.add_child(pause_button)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 300
	column.add_child(body)
	stage_panel = PanelContainer.new()
	stage_panel.custom_minimum_size = Vector2(300, 168)
	body.add_child(stage_panel)
	stage = PixelStageScript.new()
	stage.custom_minimum_size = Vector2(300, 168)
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
	title.clip_text = false
	title.custom_minimum_size.y = 28
	title.max_lines_visible = 2
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
	subtitle.clip_text = false
	subtitle.custom_minimum_size.y = 22
	subtitle.max_lines_visible = 2
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
	actions.clip_contents = false
	actions.add_theme_constant_override("separation", 5)
	actions.custom_minimum_size.y = 44
	column.add_child(actions)
	lang_host = VBoxContainer.new()
	lang_host.name = "LanguageHost"
	lang_host.clip_contents = false
	lang_host.add_theme_constant_override("separation", 4)
	lang_host.custom_minimum_size.y = 92
	lang_host.visible = false
	column.add_child(lang_host)
	footer_hint = Label.new()
	footer_hint.text = Loc.t("footer.play")
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
	pause_title = Label.new()
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_override("font", PixelDisplayFont)
	pause_title.add_theme_font_size_override("font_size", 16)
	pause_box.add_child(pause_title)
	pause_resume = Button.new()
	pause_resume.custom_minimum_size = Vector2(220, 44)
	pause_resume.pressed.connect(_resume)
	pause_box.add_child(pause_resume)
	pause_restart = Button.new()
	pause_restart.custom_minimum_size = Vector2(220, 44)
	pause_restart.pressed.connect(_restart)
	pause_box.add_child(pause_restart)
	pause_title_btn = Button.new()
	pause_title_btn.custom_minimum_size = Vector2(220, 44)
	pause_title_btn.pressed.connect(_title)
	pause_box.add_child(pause_title_btn)
	_refresh_pause_labels()


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


func _refresh_pause_labels() -> void:
	if pause_title:
		pause_title.text = Loc.t("pause.title")
	if pause_resume:
		pause_resume.text = Loc.t("pause.resume")
	if pause_restart:
		pause_restart.text = Loc.t("pause.restart")
	if pause_title_btn:
		pause_title_btn.text = Loc.t("pause.title_btn")
	if pause_button:
		pause_button.tooltip_text = Loc.t("pause.tip")


func _on_locale_changed() -> void:
	_refresh_pause_labels()
	if state == null:
		return
	match state.phase:
		MidnightStateScript.Phase.TITLE:
			_show_title()
		MidnightStateScript.Phase.OPENING:
			_show_opening()
		MidnightStateScript.Phase.DAY_1, MidnightStateScript.Phase.DAY_2:
			if state.customer_pending:
				_show_customer_offer()
			else:
				_show_shop()
		MidnightStateScript.Phase.NIGHT_1, MidnightStateScript.Phase.NIGHT_2:
			if encounter_open:
				_on_objective_reached_refresh()
			else:
				_start_room()
		MidnightStateScript.Phase.FINAL:
			_show_final()
		MidnightStateScript.Phase.RESULT:
			_show_result()


func _add_language_picker() -> void:
	if lang_host == null:
		return
	for child in lang_host.get_children():
		child.queue_free()
	lang_buttons.clear()
	lang_box = VBoxContainer.new()
	lang_box.name = "LanguagePicker"
	lang_box.clip_contents = false
	lang_box.add_theme_constant_override("separation", 6)
	var pad := Control.new()
	pad.custom_minimum_size.y = 4
	lang_box.add_child(pad)
	lang_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_caption = Label.new()
	lang_caption.text = Loc.t("lang.caption")
	lang_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lang_caption.clip_text = false
	lang_caption.custom_minimum_size.y = 22
	lang_caption.add_theme_color_override("font_color", MUTED)
	lang_box.add_child(lang_caption)
	var row := HBoxContainer.new()
	row.clip_contents = false
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size.y = 48
	lang_box.add_child(row)
	for code_v in Loc.ALLOWED:
		var code := str(code_v)
		var b := Button.new()
		b.clip_text = false
		b.text = str(Loc.NATIVE[code])
		b.custom_minimum_size = Vector2(108, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: Loc.set_code(code))
		row.add_child(b)
		lang_buttons[code] = b
		if code == "en":
			lang_en = b
		elif code == "zh":
			lang_zh = b
	lang_host.add_child(lang_box)
	lang_host.visible = true
	_set_title_layout(true)
	_mark_language_buttons()


func _set_title_layout(on_title: bool) -> void:
	var height := 150 if on_title else 240
	if stage_panel:
		stage_panel.custom_minimum_size = Vector2(300, height)
	if stage:
		stage.custom_minimum_size = Vector2(300, height)
	if footer_hint:
		footer_hint.visible = not on_title


func _hide_language_picker() -> void:
	if lang_host:
		lang_host.visible = false
	_set_title_layout(false)


func _mark_language_buttons() -> void:
	if lang_caption:
		lang_caption.text = Loc.t("lang.caption")
		lang_caption.clip_text = false
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		b.text = str(Loc.NATIVE[code])
		b.clip_text = false
		if str(code) == Loc.current():
			b.add_theme_color_override("font_color", GOLD)
		else:
			b.remove_theme_color_override("font_color")


func _show_title() -> void:
	state = MidnightStateScript.new()
	state.phase = MidnightStateScript.Phase.TITLE
	stage.set_scene("title")
	customer_portrait.visible = false
	_set_ambience("shop")
	item_grid.visible = false
	log_label.visible = false
	phase_label.text = Loc.t("brand")
	header.text = Loc.t("title.tag")
	title.text = Loc.t("title.name")
	subtitle.text = Loc.t("brand")
	detail.text = Loc.t("title.blurb") + "\n\n" + Loc.t("title.controls")
	_clear(item_grid)
	_clear(actions)
	_button(Loc.t("title.begin"), _start_run, true)
	_button(Loc.t("title.help"), _show_help)
	_add_language_picker()
	log_lines = [Loc.t("title.controls")]
	_refresh_log()
	footer_hint.text = Loc.t("footer.play")


func _show_help() -> void:
	detail.text = Loc.t("help.body")


func _start_run() -> void:
	state.reset()
	_play("bell")
	stage.set_scene("shop")
	_show_opening()


func _show_opening() -> void:
	phase_label.text = Loc.t("open.phase")
	item_grid.visible = true
	log_label.visible = true
	header.text = Loc.t("open.header")
	title.text = Loc.t("open.title")
	customer_portrait.visible = false
	subtitle.text = Loc.t("open.sub")
	detail.text = Loc.t("open.body")
	_clear(item_grid)
	_add_item_button(Loc.t("open.item"), func(): pass, true)
	_clear(actions)
	_hide_language_picker()
	_button(Loc.t("open.appraise"), func(): _opening_step(1))
	footer_hint.text = Loc.t("open.footer")
	_log(Loc.t("open.log"))


func _opening_step(step: int) -> void:
	if step == 1:
		_play("appraise")
		detail.text = Loc.t("open.identified")
		_clear(actions)
		_button(Loc.t("open.fair"), func(): _opening_step(2), true)
	else:
		state.tutorial_sale()
		_play("coin")
		_log(Loc.t("open.sale"))
		_show_shop()


func _show_shop() -> void:
	encounter_open = false
	stage.set_scene("shop")
	_set_ambience("shop")
	item_grid.visible = true
	log_label.visible = false
	stage.customer_id = str(state.current_customer().get("id", ""))
	stage.set_customer_expression(0)
	var day_text := Loc.t("shop.day1") if state.day == 1 else Loc.t("shop.day2")
	phase_label.text = day_text
	header.text = Loc.t("shop.header", [state.gold, state.health, state.resolve, state.curse, state.marks_bank])
	var customer: Dictionary = state.current_customer()
	_set_customer_portrait(customer, 0)
	title.text = Loc.t("shop.title")
	if customer.is_empty():
		subtitle.text = Loc.t("shop.done")
	else:
		subtitle.text = Loc.t("shop.next", [_customer_label(customer)])
	detail.text = _shop_detail(customer)
	_refresh_item_grid()
	_refresh_shop_actions()
	_hide_language_picker()
	footer_hint.text = Loc.t("shop.footer", [state.shelf.size(), state.transactions.size()])


func _item_label(item: Dictionary) -> String:
	if item.is_empty():
		return Loc.t("night.none")
	if str(item.get("id", "")) == "crypt_heart" and int(item.get("value", 40)) == 20:
		return Loc.t("item.crypt_heart_cracked")
	return Loc.item_name(str(item.get("id", "")))


func _customer_label(customer: Dictionary) -> String:
	if customer.is_empty():
		return ""
	return Loc.customer_name(str(customer.get("id", "")))


func _item_clue(item: Dictionary) -> String:
	return Loc.t("clue." + str(item.get("id", "")))


func _customer_behavior(customer: Dictionary) -> String:
	return Loc.t("beh." + str(customer.get("id", "")))


func _shop_detail(customer: Dictionary) -> String:
	var item: Dictionary = state.get_item(state.selected_id)
	if item.is_empty():
		return Loc.t("shop.empty")
	var mode_names := [Loc.t("shop.mode.low"), Loc.t("shop.mode.fair"), Loc.t("shop.mode.high")]
	var text := "[color=#e8b84a]%s[/color]\n" % _item_label(item)
	if item["appraised"]:
		text += Loc.t("shop.item.known", [item["value"], mode_names[item["price_mode"]], item["curse"], Loc.demand_name(str(item["demand"])), _item_clue(item)])
	else:
		text += Loc.t("shop.item.unknown")
	if not customer.is_empty():
		text += Loc.t("shop.wants", [_customer_label(customer), Loc.demand_name(str(customer["wants"])), _customer_behavior(customer)])
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
		var text := "%s%s\n%s%s" % [_item_label(item), shelf_mark, mark, curse_mark]
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
		_button(Loc.t("btn.appraise"), _appraise_selected, true)
	else:
		var modes := [Loc.t("shop.mode.low").get_slice(" ", 0), Loc.t("shop.mode.fair"), Loc.t("shop.mode.high").get_slice(" ", 0)]
		_button(Loc.t("btn.price", [modes[item["price_mode"]]]), _cycle_price)
		_button((Loc.t("btn.remove") if item["id"] in state.shelf else Loc.t("btn.display")), _toggle_display)
		if not state.current_customer().is_empty() and item["id"] in state.shelf:
			_button(Loc.t("btn.call"), _call_customer, true)
	if state.can_enter_night():
		_button(Loc.t("btn.descend"), _enter_night, true)


func _appraise_selected() -> void:
	if state.appraise(state.selected_id):
		_play("appraise")
		var identified: Dictionary = state.get_item(state.selected_id)
		_log(Loc.t("log.identified", [_item_label(identified), _item_clue(identified)]))
	_show_shop()


func _cycle_price() -> void:
	state.cycle_price(state.selected_id)
	_play("tick")
	_show_shop()


func _toggle_display() -> void:
	if not state.toggle_shelf(state.selected_id):
		_log(Loc.t("log.shelf_full"))
	else:
		_play("tick")
	_show_shop()


func _call_customer() -> void:
	if not state.call_customer(state.selected_id):
		_log(Loc.t("log.orin_refuse"))
	_show_customer_offer()


func _show_customer_offer() -> void:
	var customer: Dictionary = state.current_customer()
	var item: Dictionary = state.get_item(state.selected_id)
	stage.set_customer_expression(2)
	_set_customer_portrait(customer, 2)
	item_grid.visible = false
	log_label.visible = true
	title.text = _customer_label(customer)
	subtitle.text = _customer_behavior(customer)
	var offer_text := Loc.t("offer.refuse") if state.offer <= 0 else Loc.t("offer.pays", [state.offer, _item_label(item)])
	var modes := [Loc.t("shop.mode.low").get_slice(" ", 0), Loc.t("shop.mode.fair"), Loc.t("shop.mode.high").get_slice(" ", 0)]
	detail.text = Loc.t("offer.body", [offer_text, item["value"], modes[item["price_mode"]], Loc.t("yes") if item["demand"] == customer["wants"] else Loc.t("no"), item["curse"]])
	_clear(actions)
	_hide_language_picker()
	if customer["id"] == "tamsin" and not state.negotiated:
		_button(Loc.t("btn.negotiate"), _negotiate_offer, true)
	_button(Loc.t("btn.accept_warn"), func(): _resolve_offer(true, true), true)
	_button(Loc.t("btn.accept_hide"), func(): _resolve_offer(true, false))
	_button(Loc.t("btn.reject"), func(): _resolve_offer(false, true))


func _negotiate_offer() -> void:
	if state.negotiate_current():
		_play("coin")
		_log(Loc.t("log.negotiated"))
	else:
		_log(Loc.t("log.negotiate_fail"))
	_show_customer_offer()


func _resolve_offer(accept: bool, honest: bool) -> void:
	var customer_name := _customer_label(state.current_customer())
	var item_name := _item_label(state.get_item(state.selected_id))
	var amount: int = state.offer
	var sold: bool = state.resolve_customer(accept, honest)
	_play("coin" if sold else "tick")
	if sold:
		_log(Loc.t("log.sale_warn" if honest else "log.sale_hide", [amount, customer_name, item_name]))
	else:
		_log(Loc.t("log.reject", [customer_name, item_name]))
	_show_shop()


func _enter_night() -> void:
	if not state.enter_night(state.selected_id):
		_log(Loc.t("log.need_carry"))
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
	phase_label.text = Loc.t("night.phase", [state.night, state.room_index + 1])
	header.text = Loc.t("night.header", [state.gold, state.health, state.resolve, state.curse, state.marks_unbanked])
	title.text = Loc.t("room.%d" % state.room_index)
	subtitle.text = Loc.t("risk.%d" % state.room_index)
	detail.text = Loc.t("night.body", [Loc.t("risk.%d" % state.room_index), _item_label(state.get_item(state.carried_id))])
	_clear(item_grid)
	_clear(actions)
	_hide_language_picker()
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
	_button(Loc.t("btn.approach"), _on_objective_reached, true)
	footer_hint.text = Loc.t("night.footer")


func _on_floor_risk() -> void:
	state.trigger_floor_risk()
	_play("hit")
	_log(Loc.t("log.floor", [state.health, state.resolve, state.curse]))
	if state.phase == MidnightStateScript.Phase.DAY_2:
		_log(Loc.t("log.recover_day"))
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
	var enemy := Loc.t("enemy.%d" % state.room_index)
	title.text = Loc.t("fight.title", [enemy, state.enemy_hp, room["hp"]])
	subtitle.text = Loc.t("fight.sub", [room["damage"]])
	detail.text = Loc.t("fight.body", [enemy])
	_clear(actions)
	_button(Loc.t("btn.strike"), func(): _combat("strike"), true)
	_button(Loc.t("btn.guard"), func(): _combat("guard"))
	_button(Loc.t("btn.remember"), func(): _combat("remember"))
	_button(Loc.t("btn.item"), func(): _combat("item"))
	if state.room_index == 1 and state.carried_id == "wedding_ring":
		_button(Loc.t("btn.ring"), _peaceful_claimant, true)


func _peaceful_claimant() -> void:
	if state.peaceful_claimant():
		_play("loot")
		_log(Loc.t("log.mercy"))
		_room_cleared()


func _combat(action: String) -> void:
	var result: Dictionary = state.combat_action(action)
	if not result.get("ok", false):
		_log(Loc.t("log.no_res"))
		return
	_play("hit" if not result.get("won", false) else "loot")
	if state.phase == MidnightStateScript.Phase.DAY_2:
		_log(Loc.t("log.defeat_day"))
		_show_shop()
		return
	if state.phase == MidnightStateScript.Phase.FINAL:
		_log(Loc.t("log.defeat_final"))
		_show_final()
		return
	_log(Loc.t("log.combat", [Loc.t("btn." + action) if action != "item" else Loc.t("btn.item"), result.get("dealt", 0), result.get("damage", 0), state.enemy_hp, state.health]))
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
	title.text = Loc.t("clear.title")
	subtitle.text = Loc.t("clear.sub", [Loc.t("enemy.%d" % state.room_index)])
	var loot_text := ""
	if state.room_index == 0:
		loot_text = Loc.t("clear.loot0")
	elif state.room_index == 2 and state.carried_id == "bone_key":
		loot_text = Loc.t("clear.loot2")
	elif state.room_index == 3:
		loot_text = Loc.t("clear.loot3")
	detail.text = Loc.t("clear.body", [room["marks"] * (2 if state.carried_id == "black_ledger" else 1), loot_text])
	_clear(actions)
	_button(Loc.t("btn.continue"), _advance_room, true)


func _advance_room() -> void:
	var old_phase: int = state.phase
	state.advance_room()
	if state.phase == old_phase:
		_start_room()
	elif state.phase == MidnightStateScript.Phase.DAY_2:
		_play("coin")
		_log(Loc.t("log.extract", [state.marks_bank]))
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
	phase_label.text = Loc.t("final.phase")
	header.text = Loc.t("final.header", [state.gold, state.health, state.curse, state.mercy])
	title.text = Loc.t("final.title")
	subtitle.text = Loc.t("final.sub")
	detail.text = Loc.t("final.body")
	_clear(item_grid)
	_clear(actions)
	_hide_language_picker()
	_button(Loc.t("btn.sell", [state.get_item("crypt_heart").get("value", 20)]), func(): _choose_final("sell"), true)
	_button(Loc.t("btn.seal"), func(): _choose_final("seal"))
	_button(Loc.t("btn.keep"), func(): _choose_final("keep"))
	footer_hint.text = Loc.t("final.footer")


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
	phase_label.text = Loc.t("result.phase")
	header.text = Loc.t("result.header", [state.score, state.rank])
	title.text = Loc.t("ending." + state.outcome)
	var condition := ""
	match state.final_choice:
		"sell":
			condition = Loc.t("result.sell_clean" if state.curse <= 2 else "result.sell_debt")
		"seal":
			condition = Loc.t("result.seal_mercy" if state.mercy >= 3 else "result.seal_hold")
		"keep":
			condition = Loc.t("result.keep_own" if state.health >= 4 and state.curse <= 5 else "result.keep_owned")
	subtitle.text = condition
	detail.text = Loc.t("result.body", [state.gold, state.marks_bank, state.mercy, state.trust, state.clues, state.health, state.curse, state.recovered, state.rooms_cleared.size(), state.transactions.size(), Loc.t("yes") if state.optional_relic else Loc.t("no"), state.score, state.rank, state.elapsed_seconds() / 60.0, state.expected_normal_minutes()])
	_clear(item_grid)
	_clear(actions)
	_hide_language_picker()
	_button(Loc.t("btn.replay"), _start_run, true)
	_button(Loc.t("btn.title"), _show_title)
	footer_hint.text = Loc.t("result.footer")


func _log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 7:
		log_lines.pop_front()
	_refresh_log()
	print("[MPC] ", text)


func _refresh_log() -> void:
	if log_label == null:
		return
	log_label.text = Loc.t("log.title") + "\n".join(log_lines)
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
