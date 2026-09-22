extends Control

const MidnightStateScript = preload("res://scripts/game_state.gd")
const PixelStageScript = preload("res://scripts/pixel_stage.gd")
const PixelBodyFont = preload("res://assets/fonts/midnight_pixel_12.fnt")
const PixelDisplayFont = preload("res://assets/fonts/midnight_pixel_16.fnt")
const TitleScreenScript = preload("res://scripts/title_screen.gd")
const TitleAudioScript = preload("res://scripts/title_audio.gd")

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
var log_lines: Array[String] = []
var encounter_open := false
var audio_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var title_card: Control
var title_screen: TitleScreen
var title_audio: TitleAudio
var title_nodes: Dictionary = {}

const BG := Color("#100d18")
const PANEL := Color("#201928")
const PANEL_2 := Color("#2b2133")
const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const MUTED := Color("#9f94ac")
## The panel's MUTED is too dim to carry a line of copy over a key visual on a phone; the
## title card's secondary lines get their own, lighter grey. See title_screen.gd.
const TITLE_MUTED := Color("#c3b8d2")
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
	_bark_ready()
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
	pause_resume = _ticket("", Callable(self, "_resume"), 16)
	pause_resume.custom_minimum_size = Vector2(220, 44)
	pause_box.add_child(pause_resume)
	pause_restart = _ticket("", Callable(self, "_restart"), 16)
	pause_restart.custom_minimum_size = Vector2(220, 44)
	pause_box.add_child(pause_restart)
	pause_title_btn = _ticket("", Callable(self, "_title"), 16)
	pause_title_btn.custom_minimum_size = Vector2(220, 44)
	pause_box.add_child(pause_title_btn)
	_refresh_pause_labels()



## ---- the control the player presses is a PAWN TICKET ---------------------------------
##
## STANDARD.md item 4: buttons are not rectangles, and the shape comes from the game's own
## world. This game's world hands you one object over and over — a numbered ticket tied to
## the thing you pledged — so that is the control. `ShapedButton.Shape.TAG` draws it:
## punched eyelet, string, printed rule, and the broker's stub past the perforation, and
## on hover it swings on the string and the stub starts to come away.
##
## Ticket card and ticket ink come from ops/palettes/midnight-pawn.json, so the buttons
## quantise onto the same 64 colours as every plate in the game.
const TICKET_CARD := Color("#caa569")
const TICKET_CARD_HOT := Color("#e4cb97")
const TICKET_INK := Color("#1c140c")


## `size` is the FONT size. compact is on everywhere: the canvas is 640x360 and
## ShapedButton's un-compact floor is a 56px control, a sixth of the screen.
func _ticket(text_: String, callback: Callable, size := 12, accent := false) -> ShapedButton:
	var b := ShapedButton.new()
	b.shape = ShapedButton.Shape.TAG
	b.compact = true
	b.tint = TICKET_CARD_HOT if accent else TICKET_CARD
	b.ink = TICKET_INK
	b.text = text_
	b.add_theme_font_override("font", PixelDisplayFont if size >= 16 else PixelBodyFont)
	b.add_theme_font_size_override("font_size", size)
	if callback.is_valid():
		b.pressed.connect(callback)
	# The hover tick and the press thud used to come from title_screen.style_button(),
	# which these tickets no longer go through. Without this the title's buttons went
	# silent — a regression that makes no error and that nobody notices in a screenshot.
	b.mouse_entered.connect(func() -> void: title_sound("hover"))
	b.button_down.connect(func() -> void: title_sound("press"))
	return b


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
	var b := _ticket(text, callback, 12, accent)
	b.custom_minimum_size = Vector2(92, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(b)
	return b


## The action row's plain control, for the four D-pad keys. Everything with a WORD on it
## goes through _button() and comes out a ticket.
func _plain_button(callback: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(92, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	lang_box = VBoxContainer.new()
	lang_box.name = "LanguagePicker"
	lang_box.add_theme_constant_override("separation", 4)
	lang_caption = Label.new()
	lang_caption.text = Loc.t("lang.caption")
	lang_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lang_caption.add_theme_color_override("font_color", MUTED)
	lang_box.add_child(lang_caption)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	lang_box.add_child(row)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	lang_box.add_child(row2)
	for i in Loc.ALLOWED.size():
		var code := str(Loc.ALLOWED[i])
		var b := _ticket(str(Loc.NATIVE[code]), func() -> void: Loc.set_code(code))
		b.custom_minimum_size = Vector2(88, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(row if i < 3 else row2).add_child(b)
		lang_buttons[code] = b
		if code == "en":
			lang_en = b
		elif code == "zh":
			lang_zh = b
	actions.add_child(lang_box)
	_mark_language_buttons()


func _mark_language_buttons() -> void:
	if lang_caption:
		lang_caption.text = Loc.t("lang.caption")
	# The chosen language is marked on the TICKET, not with a font colour: a ShapedButton
	# draws its own label in its own ink and ignores font_color overrides entirely, so the
	# old marking was invisible the moment these became tickets. The current locale's
	# ticket is the bright card — the one that has been stamped.
	for code in lang_buttons.keys():
		var b: Button = lang_buttons[code]
		b.text = str(Loc.NATIVE[code])
		if b is ShapedButton:
			(b as ShapedButton).tint = TICKET_CARD_HOT if str(code) == Loc.current() else TICKET_CARD
			b.queue_redraw()
		elif str(code) == Loc.current():
			b.add_theme_color_override("font_color", GOLD)
		else:
			b.remove_theme_color_override("font_color")


func _show_title() -> void:
	state = MidnightStateScript.new()
	state.phase = MidnightStateScript.Phase.TITLE
	stage.set_scene("title")
	customer_portrait.visible = false
	_set_ambience("shop")
	item_grid.visible = true
	log_label.visible = true
	phase_label.text = Loc.t("brand")
	header.text = Loc.t("title.tag")
	title.text = Loc.t("title.name")
	subtitle.text = Loc.t("brand")
	detail.text = Loc.t("title.blurb")
	_clear(item_grid)
	_clear(actions)
	_button(Loc.t("title.begin"), _start_run, true)
	_button(Loc.t("title.help"), _show_help)
	_add_language_picker()
	log_lines = [Loc.t("title.controls")]
	_refresh_log()
	footer_hint.text = Loc.t("footer.play")
	_open_title_card()


## The title card — ops/adult_forks/TITLE_SCREENS.md.
##
## The panel above is the game's own furniture; it is what the player sees the moment they
## press BEGIN. What they see FIRST is this: a full-frame composition over the whole
## 640x360 canvas, the same class of card the adult fork of this world already carries, so
## the two builds read as one studio. This function only places the copy and the buttons
## INTO that composition and lends them its type family — the composition itself lives in
## scripts/title_screen.gd.
##
## Mainstream: SFW art, the studio mark is `blazeCore Play` alone, and nothing here names
## a rating or another label.
func _open_title_card() -> void:
	if is_instance_valid(title_card):
		_refresh_title_card()
		return
	title_card = Control.new()
	title_card.name = "TitleCard"
	title_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# STOP, not IGNORE: the card is a door, and the panel behind it must not take clicks.
	title_card.mouse_filter = Control.MOUSE_FILTER_STOP
	title_card.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_card)
	title_card.move_to_front()

	title_screen = TitleScreenScript.new()
	title_screen.name = "TitleScreen"
	title_card.add_child(title_screen)

	title_audio = TitleAudioScript.new()
	title_audio.name = "TitleAudio"
	# Same reason as the title screen: a generator that is not processed pushes no frames,
	# and this card can be on screen while the tree is paused.
	title_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	title_card.add_child(title_audio)
	# One bed at a time. The panel's shop drone would beat against the title bed.
	if ambience_player:
		ambience_player.stop()
		ambience_player.remove_meta("kind")

	# The menu gets a plate of its own rather than floating over a lit counter: this
	# game's own age gate was once swallowed by the lamp glow.
	title_card.add_child(title_screen.make_plaque(8, 176, 336, 184, 16, 14, 0))
	title_card.add_child(title_screen.make_plaque(430, 332, 210, 28, 0, 10, 0))

	# The tag line is set in the display size: at 390 px wide — the phone check in
	# TITLE_SCREENS.md — a 12 px line of copy is seven pixels tall and you squint at it.
	var tag := _title_label("tag", Vector2(20, 185), 16, CREAM, true)
	var controls := _title_label("controls", Vector2(20, 207), 12, TITLE_MUTED)
	title_nodes["tag"] = tag
	title_nodes["controls"] = controls

	var begin := _ticket("", Callable(self, "_title_begin"), 16, true)
	begin.position = Vector2(20, 226)
	begin.size = Vector2(212, 34)
	title_card.add_child(begin)
	title_nodes["begin"] = begin

	var how := _ticket("", Callable(self, "_title_how_to_play"), 12)
	how.position = Vector2(20, 264)
	how.size = Vector2(212, 28)
	title_card.add_child(how)
	title_nodes["how"] = how

	title_nodes["lang_caption"] = _title_label("lang", Vector2(20, 294), 12, TITLE_MUTED)

	var lang_btns := {}
	for i in Loc.ALLOWED.size():
		var code := str(Loc.ALLOWED[i])
		var b := _ticket("", func() -> void: Loc.set_code(code))
		b.position = Vector2(20 + (i % 3) * 100, 308 + (i / 3) * 26)
		b.size = Vector2(96, 24)
		title_card.add_child(b)
		lang_btns[code] = b
	title_nodes["lang"] = lang_btns

	# The studio mark. blazeCore Play, alone — no rating badge on a mainstream build.
	var studio := Label.new()
	studio.text = "blazeCore Play"
	studio.position = Vector2(446, 339)
	title_screen.style_label(studio, 12, GOLD)
	title_card.add_child(studio)

	_refresh_title_card()
	title_screen.play_in()


func _title_label(key: String, at: Vector2, size: int, color: Color, display := false) -> Label:
	var l := Label.new()
	l.position = at
	l.size = Vector2(308, size + 4)
	title_screen.style_label(l, size, color, display)
	title_card.add_child(l)
	return l


## Locale can change while the card is up; the card is rebuilt-in-place rather than torn
## down, so the sting does not fire again on every language press.
func _refresh_title_card() -> void:
	if not is_instance_valid(title_card):
		return
	title_nodes["tag"].text = Loc.t("title.tag")
	title_nodes["controls"].text = Loc.t("title.controls")
	title_nodes["begin"].text = Loc.t("title.begin")
	title_nodes["how"].text = Loc.t("title.help")
	title_nodes["lang_caption"].text = Loc.t("lang.caption")
	for code in title_nodes["lang"].keys():
		var b: Button = title_nodes["lang"][code]
		b.text = str(Loc.NATIVE[code])
		if b is ShapedButton:
			(b as ShapedButton).tint = TICKET_CARD_HOT if str(code) == Loc.current() else TICKET_CARD
			b.queue_redraw()


func _close_title_card() -> void:
	if not is_instance_valid(title_card):
		return
	title_card.queue_free()   # takes the title screen and its generator with it
	title_card = null
	title_screen = null
	title_audio = null
	title_nodes = {}
	_set_ambience("shop")


## The title screen's sound hook. Synthesised, not an asset — see scripts/title_audio.gd.
func title_sound(kind: String) -> void:
	if title_audio == null:
		return
	if kind == "sting":
		title_audio.sting()
	else:
		title_audio.ui(kind)


func _title_begin() -> void:
	_close_title_card()
	_start_run()


func _title_how_to_play() -> void:
	_close_title_card()
	_show_help()


func _show_help() -> void:
	detail.text = Loc.t("help.body")


func _start_run() -> void:
	state.reset()
	_play("bell")
	bark("greet")
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
	if _bark_area != state.day:
		_bark_area = state.day
		bark("stage", state.day - 1)
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
		bark("unlock")
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
		# The streak is HONEST sales in a row, not sales in a row: concealing the curse
		# breaks it, which is the one thing the shop's voice is allowed to care about.
		_honest_run = _honest_run + 1 if honest else 0
		if amount >= 40:
			bark("win_big")
		elif _honest_run >= 3:
			bark("streak")
		else:
			bark("win")
	else:
		_log(Loc.t("log.reject", [customer_name, item_name]))
		bark("near")
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
	if _bark_area != 10 + state.room_index:
		_bark_area = 10 + state.room_index
		bark("stage", 2 + state.room_index)
	header.text = Loc.t("night.header", [state.gold, state.health, state.resolve, state.curse, state.marks_unbanked])
	title.text = Loc.t("room.%d" % state.room_index)
	subtitle.text = Loc.t("risk.%d" % state.room_index)
	detail.text = Loc.t("night.body", [Loc.t("risk.%d" % state.room_index), _item_label(state.get_item(state.carried_id))])
	_clear(item_grid)
	_clear(actions)
	for spec in [
		[Vector2.LEFT, Rect2(0, 32, 64, 40)],
		[Vector2.UP, Rect2(64, 32, 64, 40)],
		[Vector2.DOWN, Rect2(128, 32, 64, 40)],
		[Vector2.RIGHT, Rect2(192, 32, 64, 40)],
	]:
		# Not a ticket: these four carry an ARROW, not a word, and a pawn ticket with a
		# chevron stamped on it is a costume. A D-pad should look like a D-pad.
		var move_button := _plain_button(func(direction = spec[0]): stage.nudge(direction))
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
		bark("fail")
		_show_shop()
		return
	if state.phase == MidnightStateScript.Phase.FINAL:
		_log(Loc.t("log.defeat_final"))
		bark("fail")
		_show_final()
		return
	_log(Loc.t("log.combat", [Loc.t("btn." + action) if action != "item" else Loc.t("btn.item"), result.get("dealt", 0), result.get("damage", 0), state.enemy_hp, state.health]))
	if result.get("won", false):
		_room_cleared()
	else:
		if state.health <= 3 or state.enemy_hp <= 2:
			bark("near")
		_on_objective_reached_refresh()


func _on_objective_reached_refresh() -> void:
	encounter_open = false
	_on_objective_reached()


func _room_cleared() -> void:
	stage.mark_enemy_defeated()
	bark("win")
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
		Gate.block("day2", "Day 2")   # dual-track (ops/DUAL_TRACK.md)
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
	_button(Loc.t("btn.replay"), _start_run, true)
	_button(Loc.t("btn.title"), _show_title)
	footer_hint.text = Loc.t("result.footer")
	# End of the run: the cross-promotion board (play/_shared/board.js), the other small
	# games as links the player may click. Casual board only — mainstream title.
	Gate.board_offer_more("casual")


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



# --- barks -------------------------------------------------------------------------------
#
# STANDARD.md item 5. Nara's voice (ops/barks/lines.json -> "midnight-pawn", seed
# f_young_warm, all-ages, 25 lines), rendered by ops/barks/render_barks.py into
# assets/voice/. One voice for the whole game.
#
# It is written to NO-OP when assets/voice/barks.json is absent, which is the state the
# build ships in until a GPU window renders the set: no error, no silence-with-a-warning,
# just no bark. That is deliberate -- the alternative is a game that refuses to run
# because a sound file is missing.
#
# Three rules, each one the reason a bark set stops being charming:
#   * rotate, and never repeat a slot's line back to back;
#   * never overlap a bark with a bark -- the second is DROPPED, not queued, because by
#     the time the first has finished the moment it belonged to is over;
#   * every bark rides the same volume as the rest of the audio.
const BARK_DIR := "res://assets/voice/"

var bark_player: AudioStreamPlayer
var _bark_map: Dictionary = {}
var _bark_last: Dictionary = {}
## Which place the player is standing in, so a "stage" line fires once when they arrive
## and not again on every redraw of the same room. 1..2 are the shop days, 10.. the crypt
## rooms.
var _bark_area := -1
## Honest sales in a row. Concealing a curse resets it.
var _honest_run := 0
var _idle_since := 0.0


func _bark_ready() -> void:
	bark_player = AudioStreamPlayer.new()
	bark_player.volume_db = -4.0
	add_child(bark_player)
	var f := FileAccess.open(BARK_DIR + "barks.json", FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_bark_map = parsed


## `slot` is one of greet/stage/near/win/win_big/fail/idle/streak/unlock. `index` lets a
## caller ask for a PARTICULAR line rather than a rotated one -- "stage" is one line per
## area, so the receipt stair must always say the receipt stair's line and never the
## chapel's.
func bark(slot: String, index := -1) -> void:
	if bark_player == null or not _bark_map.has(slot):
		return
	if bark_player.playing:
		return                      # dropped, not queued
	var files: Array = _bark_map[slot]
	if files.is_empty():
		return
	var pick := 0
	if index >= 0:
		pick = index % files.size()
	else:
		pick = randi() % files.size()
		if files.size() > 1 and _bark_last.get(slot, -1) == pick:
			pick = (pick + 1) % files.size()
	_bark_last[slot] = pick
	var path: String = BARK_DIR + str(files[pick])
	if not ResourceLoader.exists(path):
		return
	bark_player.stream = load(path)
	bark_player.play()


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


## The idle bark. Nara talks to herself when the shop is quiet — which is the point of
## the slot, and the reason it is timed off the last INPUT rather than off a Timer: a bark
## that fires while the player is mid-click is an interruption, not an idle line.
##
## Only in the shop, and never while paused or on the title: an idle line over a paused
## game is the studio's own "verification that lies" in audio form — it says somebody is
## there when nobody is.
const IDLE_AFTER := 26.0


func _process(delta: float) -> void:
	if state == null or get_tree().paused:
		return
	if state.phase != MidnightStateScript.Phase.DAY_1 and state.phase != MidnightStateScript.Phase.DAY_2:
		_idle_since = 0.0
		return
	_idle_since += delta
	if _idle_since >= IDLE_AFTER:
		_idle_since = 0.0
		bark("idle")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	_idle_since = 0.0


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
