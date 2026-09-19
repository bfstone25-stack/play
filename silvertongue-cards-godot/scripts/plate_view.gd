## PlateView — a plate shown in-scene, over everything, with its caption. Click or tap
## anywhere to close. Never a popup, never a new window: it is a Control in this tree.
class_name PlateView
extends Control

var _img: TextureRect
var _cap: Label
var _tag: Label


static func open(host: Node, tex: Texture2D, caption: String, tag: String = "") -> PlateView:
	var v := PlateView.new()
	host.add_child(v)
	v._show(tex, caption, tag)
	return v


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.03, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_img = TextureRect.new()
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_img.offset_top = 40
	_img.offset_bottom = -80
	_img.offset_left = 40
	_img.offset_right = -40
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_img)
	_tag = StudioTheme.mono_label("", 10, Palette.GOLD)
	_tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tag.position = Vector2(40, 14)
	add_child(_tag)
	_cap = StudioTheme.serif_label("", 17, Palette.TEXT)
	_cap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cap.offset_top = -70
	_cap.offset_bottom = -20
	_cap.offset_left = 60
	_cap.offset_right = -60
	_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_cap)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _show(tex: Texture2D, caption: String, tag: String) -> void:
	_img.texture = tex
	_cap.text = caption
	_tag.text = tag + "   · tap to close"


func _gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
		accept_event()
		close()


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
