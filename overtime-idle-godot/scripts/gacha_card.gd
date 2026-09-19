class_name GachaCard
extends Control
## One gacha card: a back (studio mark on plum, gold foil edge), a flip (scale.x through
## zero, swap faces), the rarity frame and glow — common a thin steel line, rare violet
## with an inner glow, epic gold with a double edge and a shine burst — and a coral
## +5% toast when it is a duplicate.
##
## Portrait-first: the face is a portrait frame sized for the piece sprite
## (piece_<id>.webp); until the sprite is installed the vector piece block sits in the
## frame, so the swap is a texture arriving, not a layout change.

const W := 104.0
const H := 152.0
const FRAME_H := 90.0    # the top ~60%: the portrait

var result: Dictionary = {}
var face: PanelContainer
var back: PanelContainer
var glow: Panel
var inner: Panel
var toast: Label
var shine: CPUParticles2D
var flipped := false


func setup(r: Dictionary) -> void:
	result = r
	var rarity := str(r["rarity"])
	var rc := Palette.rarity_color(rarity)
	custom_minimum_size = Vector2(W, H)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	# the outer glow: a rounded box with only a shadow, faded in on the flip
	glow = Panel.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.add_theme_stylebox_override("panel", StudioTheme.glow(StudioTheme.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12, 0, Vector2.ZERO), rc, 18, 0.85))
	glow.modulate.a = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	# the back
	back = PanelContainer.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, Palette.GOLD, 12, 2, Vector2(6, 6)))
	add_child(back)
	var bl := Label.new()
	bl.text = "OL"
	bl.add_theme_font_override("font", StudioTheme.font("display"))
	bl.add_theme_font_size_override("font_size", 40)
	bl.add_theme_color_override("font_color", Color(Palette.GOLD, 0.55))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_child(bl)
	# the face: the rarity frame around all of it
	face = PanelContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, rc, 12, 3 if rarity == "epic" else (2 if rarity == "rare" else 1), Vector2(0, 0)))
	face.visible = false
	add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	face.add_child(v)
	v.add_child(_portrait(str(r["id"]), rc))
	var nm := Label.new()
	nm.text = str(Roster.by(r["id"]).get("name", r["id"])).split(",")[0]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", StudioTheme.font("display"))
	nm.add_theme_font_size_override("font_size", 16)
	v.add_child(nm)
	var rr := Label.new()
	rr.text = rarity.to_upper()
	rr.theme_type_variation = "Tag"
	rr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rr.add_theme_color_override("font_color", Palette.rarity_text(rarity))
	v.add_child(rr)
	if rarity == "epic":
		# the second gold edge, inset
		inner = Panel.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 5
		inner.offset_top = 5
		inner.offset_right = -5
		inner.offset_bottom = -5
		inner.add_theme_stylebox_override("panel", StudioTheme.flat(Color(0, 0, 0, 0), Color(Palette.EPIC, 0.8), 9, 1, Vector2.ZERO))
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(inner)
		shine = CPUParticles2D.new()
		shine.emitting = false
		shine.one_shot = true
		shine.explosiveness = 1.0
		shine.amount = 26
		shine.lifetime = 0.9
		shine.position = size * 0.5
		shine.spread = 180.0
		shine.gravity = Vector2(0, 60)
		shine.initial_velocity_min = 90.0
		shine.initial_velocity_max = 220.0
		shine.scale_amount_min = 1.6
		shine.scale_amount_max = 3.2
		shine.color = Palette.EPIC
		var g := Gradient.new()
		g.set_color(0, Color(Palette.GOLD_PALE, 1.0))
		g.set_color(1, Color(Palette.EPIC, 0.0))
		shine.color_ramp = g
		add_child(shine)
	toast = Label.new()
	toast.text = "DUPE  +5%"
	toast.add_theme_font_override("font", StudioTheme.font("display"))
	toast.add_theme_font_size_override("font_size", 13)
	toast.add_theme_color_override("font_color", Palette.HEAT)
	toast.position = Vector2(8, 8)
	toast.visible = false
	add_child(toast)


## The portrait frame: the sprite when installed, the vector block until then; a dark
## gradient over the foot of the picture so the name reads on it; a rare card's inner
## glow lives here, on the picture.
func _portrait(id: String, rc: Color) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(W, FRAME_H)
	frame.clip_contents = true
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.PANEL_RAISED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(bg)
	var tex := Look.piece_portrait(id)
	if tex != null:
		var im := TextureRect.new()
		im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		im.texture = tex
		im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(im)
	else:
		var pc := Piece.new()
		pc.setup(id, 76, 40)
		pc.position = Vector2(W * 0.5, FRAME_H * 0.66)
		pc.show_score = false
		frame.add_child(pc)
	if result["rarity"] == "rare":
		var ig := TextureRect.new()
		ig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var gt := GradientTexture2D.new()
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 1.05)
		var g := Gradient.new()
		g.set_color(0, Color(rc, 0.0))
		g.set_color(1, Color(rc, 0.55))
		gt.gradient = g
		gt.width = 64
		gt.height = 64
		ig.texture = gt
		ig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(ig)
	var vig := TextureRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	vig.offset_top = -40
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var vt := GradientTexture2D.new()
	vt.fill_from = Vector2(0, 0)
	vt.fill_to = Vector2(0, 1)
	var vg := Gradient.new()
	vg.set_color(0, Color(Palette.GROUND, 0.0))
	vg.set_color(1, Color(Palette.GROUND, 0.85))
	vt.gradient = vg
	vt.width = 4
	vt.height = 32
	vig.texture = vt
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(vig)
	return frame


func flip() -> void:
	if flipped:
		return
	flipped = true
	var rarity := str(result["rarity"])
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		back.visible = false
		face.visible = true)
	tw.tween_property(self, "scale:x", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var strength := Palette.rarity_glow(rarity)
	if strength > 0.0:
		tw.parallel().tween_property(glow, "modulate:a", 1.0, 0.2)
		tw.tween_property(glow, "modulate:a", strength, 0.6)
	if rarity == "epic":
		tw.parallel().tween_property(self, "scale", Vector2(1.14, 1.14), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_callback(func() -> void:
			if shine:
				shine.restart()
				shine.emitting = true)
		tw.tween_property(self, "scale", Vector2(1, 1), 0.3)
	if bool(result["dupe"]):
		tw.tween_callback(func() -> void:
			toast.visible = true
			toast.modulate.a = 0.0
			var t2 := toast.create_tween()
			t2.tween_property(toast, "modulate:a", 1.0, 0.15)
			t2.parallel().tween_property(toast, "position:y", 2.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
