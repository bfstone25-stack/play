class_name GachaCard
extends Control
## One gacha card: a back, a flip (scale.x through zero, swap faces), the rarity glow,
## and a +5% toast when it is a duplicate.

var result: Dictionary = {}
var face: PanelContainer
var back: PanelContainer
var glow: ColorRect
var toast: Label
var flipped := false


func setup(r: Dictionary) -> void:
	result = r
	custom_minimum_size = Vector2(88, 128)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	glow = ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = -8
	glow.offset_top = -8
	glow.offset_right = 8
	glow.offset_bottom = 8
	glow.color = Color(RosterScreen.rarity_color(r["rarity"]), 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	back = PanelContainer.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := Look.flat(Color("#1a2230"), Look.LINE2, 8, 1, 6)
	back.add_theme_stylebox_override("panel", sb)
	add_child(back)
	var bl := Label.new()
	bl.text = "OL"
	bl.theme_type_variation = "Big"
	bl.add_theme_color_override("font_color", Look.LINE2)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_child(bl)
	face = PanelContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fs := Look.flat(Color("#141a20"), RosterScreen.rarity_color(r["rarity"]), 8, 2, 6)
	face.add_theme_stylebox_override("panel", fs)
	face.visible = false
	add_child(face)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	face.add_child(v)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(70, 60)
	var pc := Piece.new()
	pc.setup(r["id"], 70, 36)
	pc.position = Vector2(35, 44)
	pc.show_score = false
	icon.add_child(pc)
	v.add_child(icon)
	var nm := Label.new()
	nm.text = str(Roster.by(r["id"]).get("name", r["id"])).split(",")[0]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", Look.font_ui_bold)
	nm.add_theme_font_size_override("font_size", 13)
	v.add_child(nm)
	var rr := Label.new()
	rr.text = str(r["rarity"]).to_upper()
	rr.theme_type_variation = "Tag"
	rr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rr.add_theme_color_override("font_color", RosterScreen.rarity_color(r["rarity"]))
	v.add_child(rr)
	toast = Label.new()
	toast.text = "DUPE  +5%"
	toast.theme_type_variation = "Tag"
	toast.add_theme_color_override("font_color", Look.LAMP)
	toast.position = Vector2(10, 8)
	toast.visible = false
	add_child(toast)


func flip() -> void:
	if flipped:
		return
	flipped = true
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		back.visible = false
		face.visible = true)
	tw.tween_property(self, "scale:x", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var strength := 0.55 if result["rarity"] == "epic" else (0.35 if result["rarity"] == "rare" else 0.12)
	tw.parallel().tween_property(glow, "color:a", strength, 0.2)
	tw.tween_property(glow, "color:a", strength * 0.4, 0.6)
	if result["rarity"] == "epic":
		tw.parallel().tween_property(self, "scale", Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2(1, 1), 0.3)
	if bool(result["dupe"]):
		tw.tween_callback(func() -> void:
			toast.visible = true
			toast.modulate.a = 0.0
			var t2 := toast.create_tween()
			t2.tween_property(toast, "modulate:a", 1.0, 0.15)
			t2.parallel().tween_property(toast, "position:y", 2.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
