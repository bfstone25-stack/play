class_name NREventView
extends Control
## Shows VN-style lines and choices over the stage: a CG layer, the game's textbox art,
## name plate, typewriter text, voice. Driven by main.gd's step runner.

signal advanced
signal chosen(index: int)

var cg: TextureRect
var box: PanelContainer
var name_panel: PanelContainer
var name_lbl: Label
var text: RichTextLabel
var choices: VBoxContainer
var typing := false
var full := false
var fast := false
var auto_mode := false   # tests / sim
var auto_choice := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	cg = TextureRect.new()
	cg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cg.visible = false
	cg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cg)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", NRSkin.box("textbox", 18, 26))
	box.anchor_left = 0.0; box.anchor_right = 1.0; box.anchor_top = 1.0; box.anchor_bottom = 1.0
	box.offset_top = -200; box.offset_left = 0; box.offset_right = 0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 140)
	m.add_theme_constant_override("margin_right", 140)
	m.add_theme_constant_override("margin_top", 34)
	box.add_child(m)
	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.add_theme_font_size_override("normal_font_size", 25)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(text)
	name_panel = PanelContainer.new()
	name_panel.add_theme_stylebox_override("panel", NRSkin.box("namebox", 6, 8))
	name_panel.position = Vector2(120, 720 - 222)
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_panel)
	name_lbl = Label.new()
	name_lbl.add_theme_font_override("font", NRSkin.font("display"))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_panel.add_child(name_lbl)
	choices = VBoxContainer.new()
	choices.set_anchors_preset(Control.PRESET_CENTER)
	choices.custom_minimum_size = Vector2(900, 0)
	choices.position = Vector2(190, 170)
	choices.add_theme_constant_override("separation", 12)
	add_child(choices)
	visible = false


func show_cg(tex: Texture2D) -> void:
	cg.texture = tex
	cg.visible = tex != null
	if tex != null:
		cg.modulate.a = 0.0
		create_tween().tween_property(cg, "modulate:a", 1.0, 0.6)


func say(who: String, body: String, voice_secs: float = 0.0) -> void:
	visible = true
	box.visible = true
	for c in choices.get_children():
		c.queue_free()
	name_panel.visible = who != ""
	name_lbl.text = who
	text.text = body
	if auto_mode:
		text.visible_ratio = 1.0
		return
	text.visible_ratio = 0.0
	typing = true
	full = false
	var cps := float(RPG.persist.get("text_speed", 45))
	var dur: float = max(0.05, body.length() / cps)
	var tw := create_tween()
	tw.tween_property(text, "visible_ratio", 1.0, dur)
	tw.tween_callback(func(): typing = false)
	await advanced
	Sound.stop_voice()


func choose(opts: Array) -> int:
	visible = true
	box.visible = false
	name_panel.visible = false
	for c in choices.get_children():
		c.queue_free()
	for i in opts.size():
		var o: Dictionary = opts[i]
		var b := NRSkin.button(o["text"], func(): chosen.emit(i), 22)
		b.custom_minimum_size = Vector2(900, 58)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = o.get("locked", false)
		choices.add_child(b)
	if auto_mode:
		return min(auto_choice, opts.size() - 1)
	var idx: int = await chosen
	for c in choices.get_children():
		c.queue_free()
	return idx


func close() -> void:
	visible = false
	cg.visible = false


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_click()


func _unhandled_input(ev: InputEvent) -> void:
	if not visible:
		return
	if ev.is_action_pressed("ui_accept"):
		_click()


func _process(_d: float) -> void:
	if visible and box.visible and Input.is_key_pressed(KEY_CTRL):
		_click()


func _click() -> void:
	if not box.visible or choices.get_child_count() > 0:
		return
	if typing:
		typing = false
		text.visible_ratio = 1.0
		return
	advanced.emit()
