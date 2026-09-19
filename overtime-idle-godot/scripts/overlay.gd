class_name Overlay
extends Control
## Base for every full-screen panel: a dim over the room, a card that scales in, and a
## close path. Nothing here opens by itself — every open() is behind a click.

signal closed

var dim: ColorRect
var card: PanelContainer
var body: VBoxContainer
var card_width := 760.0
var _open := false


func _ready() -> void:
	# Overlays sit on a CanvasLayer, which breaks the Control parent chain the root theme
	# propagates through — so the theme is set here, explicitly.
	theme = Look.theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Palette.GROUND_DEEP, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(card_width, 0)
	center.add_child(card)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	card.add_child(body)
	build()


## Subclasses put their widgets into `body` here.
func build() -> void:
	pass


func tag(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = "Tag"
	body.add_child(l)
	return l


func title(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = "Title"
	body.add_child(l)
	return l


func para(txt: String, size: int = 15) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = txt
	r.add_theme_font_size_override("normal_font_size", size)
	body.add_child(r)
	return r


func button(txt: String, variation: String = "", on: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = txt
	if variation != "":
		b.theme_type_variation = variation
	if on.is_valid():
		b.pressed.connect(on)
	return b


func open() -> void:
	if _open:
		return
	_open = true
	visible = true
	dim.modulate.a = 0.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.94, 0.94)
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.18)
	tw.tween_property(card, "scale", Vector2(1, 1), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.18)
	on_open()


func on_open() -> void:
	pass


func close() -> void:
	if not _open:
		return
	_open = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.14)
	tw.tween_property(card, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(func() -> void:
		visible = false
		closed.emit())


func is_open() -> bool:
	return _open


func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
