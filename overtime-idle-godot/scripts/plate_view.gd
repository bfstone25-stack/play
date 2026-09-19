class_name PlateView
extends Overlay
## A plate, full-bleed, with its caption. A gated plate on the web shows the censored cut
## and hands the decision to the page's gate — on a click, never by itself.

var img: TextureRect
var cap: Label
var unlock_btn: Button
var _slot := ""
var _id := ""
var _caption := ""


func build() -> void:
	card_width = 1000
	card.custom_minimum_size = Vector2(1000, 0)
	img = TextureRect.new()
	img.custom_minimum_size = Vector2(960, 560)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(img)
	var row := HBoxContainer.new()
	body.add_child(row)
	cap = Label.new()
	cap.theme_type_variation = "Value"
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(cap)
	unlock_btn = button("UNLOCK THIS PLATE", "Amber", _unlock)
	unlock_btn.visible = false
	row.add_child(unlock_btn)
	row.add_child(button("CLOSE", "Ghost", close))


func show_plate(id: String, caption: String, gated: bool, slot: String) -> void:
	_slot = slot
	_id = id
	_caption = caption
	var open_now := not gated or not Gate.is_web() or Gate.has(slot)
	_show(open_now)
	open()


func _show(open_now: bool) -> void:
	img.texture = Look.art(_id if open_now else _id + "_locked")
	if img.texture == null:
		img.texture = Look.art("plate_unearned")
	cap.text = _caption + ("" if open_now else "  ·  LOCKED · IN THE FULL VERSION")
	unlock_btn.visible = not open_now


func _unlock() -> void:
	unlock_btn.disabled = true
	var ok := await Gate.require(_slot, "Plate — " + _caption.split(" — ")[0], "cg")
	unlock_btn.disabled = false
	if ok:
		_show(true)
