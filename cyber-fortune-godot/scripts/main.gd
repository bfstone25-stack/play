extends Control
## Main — the shell: one screen at a time (home, tube, deck, reader, rack, shop), the
## HUD over it (merit, back, language), toasts, and the web dev bridge's UI commands.
## Portrait 720x1280 (PLAN.md's portrait lock), widened on a desktop window.

const SCREENS := {
	"home": preload("res://scripts/home_screen.gd"),
	"tube": preload("res://scripts/tube_screen.gd"),
	"deck": preload("res://scripts/deck_screen.gd"),
	"reader": preload("res://scripts/reader_screen.gd"),
	"rack": preload("res://scripts/rack_screen.gd"),
	"shop": preload("res://scripts/shop_screen.gd"),
}

var current: Control
var current_name := ""
var hud: Control
var merit_label: Label
var merit_tag: Label
var back_btn: Button
var lang_btn: Button
var toasts: VBoxContainer


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	Fortune.changed.connect(_refresh_hud)
	Fortune.toast.connect(toast)
	Tx.changed.connect(_on_lang)
	Fortune.bridge_handler = Callable(self, "_bridge")
	open("home")


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.offset_bottom = 72
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	back_btn = StudioTheme.button("‹", "Ghost")
	back_btn.add_theme_font_size_override("font_size", 34)
	back_btn.position = Vector2(12, 10)
	back_btn.custom_minimum_size = Vector2(56, 52)
	back_btn.pressed.connect(func(): open("home"))
	hud.add_child(back_btn)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(box)
	merit_label = StudioTheme.label("0", 30, Palette.GOLD, "black")
	merit_tag = StudioTheme.label("", 14, Palette.MUTED, "bold")
	merit_tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(merit_label)
	box.add_child(merit_tag)
	box.offset_left = -120
	box.offset_right = 120
	box.offset_top = 12
	box.offset_bottom = 60
	lang_btn = StudioTheme.button("", "Ghost")
	lang_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lang_btn.offset_left = -96
	lang_btn.offset_right = -14
	lang_btn.offset_top = 14
	lang_btn.offset_bottom = 58
	lang_btn.pressed.connect(func():
		Tx.set_lang("en" if Tx.lang == "zh" else "zh")
		Fortune.save_state())
	hud.add_child(lang_btn)
	toasts = VBoxContainer.new()
	toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-200, 84)
	toasts.size = Vector2(400, 0)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toasts)
	_refresh_hud()


func _refresh_hud() -> void:
	merit_label.text = str(Fortune.merit.merit)
	merit_tag.text = " " + Tx.t("focus" if current_name in ["deck", "reader"] else "merit")
	lang_btn.text = Tx.t("lang")
	back_btn.visible = current_name != "home"
	var west := current_name in ["deck", "reader"]
	merit_label.add_theme_color_override("font_color", Palette.CANDLE if west else Palette.GOLD)


func _on_lang() -> void:
	_refresh_hud()
	if current and current.has_method("relayout"):
		current.relayout()


func open(name: String) -> void:
	if current:
		current.queue_free()
		current = null
	current_name = name
	current = SCREENS[name].new()
	current.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(current)
	move_child(current, 0)
	_refresh_hud()


func toast(text: String) -> void:
	var p := PanelContainer.new()
	p.theme_type_variation = "Glass"
	var l := StudioTheme.label(text, 17, Palette.GOLD_PALE, "bold")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.modulate.a = 0.0
	toasts.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


## After the daily draw is read: the casual board, once a day, on the player's click.
func after_daily_read() -> void:
	if Fortune.seen_board_today == Fortune.day_key():
		return
	Fortune.seen_board_today = Fortune.day_key()
	Gate.board_offer_more("casual")


## Dev bridge UI commands (Fortune._poll_bridge hands the unknown ops here). Every one is
## a click a player can make; the tests drive the real screens through them.
func _bridge(cmd: Dictionary) -> Dictionary:
	var op := str(cmd.get("op", ""))
	if op == "ui_state":
		var s := {"screen": current_name}
		if current and current.has_method("dev_state"):
			s.merge(current.dev_state(), true)
		return s
	if op == "open":
		open(str(cmd.get("screen", "home")))
		return {"ok": true}
	if current and current.has_method("dev_cmd"):
		return current.dev_cmd(cmd)
	return {"ok": false, "why": "no_screen_handler"}
