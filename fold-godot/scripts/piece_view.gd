## PieceView — how a playing piece is drawn, in one place.
##
## The board and the title screen's attract loop both draw pieces, and they have to be the
## same object: the title screen is a promise about what the game looks like, and a demo
## board drawn with a second, simpler renderer is how that promise quietly stops being
## true. So both call `PieceView.make()`.
##
## A piece is the `piece` plate (folded paper with a crease in it, ops/fold_art) tinted to
## its value from the web game's ramp, with:
##   - a drop shadow offset down the tilt, so it stands proud of the board;
##   - a rim along its top edge, brighter the further up the gold ramp it has climbed;
##   - its number in the display face;
##   - and, once it is into the gold end, a PointLight2D of its own, so a big piece lights
##     its neighbours. That is `lit` — the attract loop leaves it off, because eight small
##     lights behind a title screen buy nothing and cost a lot on a phone.
class_name PieceView


static func falloff(px: int, softness: float) -> Texture2D:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := float(px) * 0.5
	for y in range(px):
		for x in range(px):
			var d := Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, pow(a, 1.0 + softness * 4.0)))
	return ImageTexture.create_from_image(img)


## `px` is the piece's width on the tilted plane; `tilt` squashes it vertically. `room` is
## how much of the lamp-lit room's dimming the piece carries (1.0 = full brightness).
static func make(v: int, px: float, tilt: float, room: float = 1.0, lit: bool = true) -> Node2D:
	var holder := Node2D.new()
	var tex := Art.plate_or_stand_in("piece", Palette.PAPER)
	var sc := Vector2(px, px * tilt) / Vector2(tex.get_width(), tex.get_height())
	var col := Fold.tile_color(v) * room
	col.a = 1.0

	var shadow := Sprite2D.new()
	shadow.texture = tex
	shadow.scale = sc * 1.02
	shadow.position = Vector2(0, px * 0.10)
	shadow.modulate = Color(0, 0, 0, 0.5)
	shadow.z_index = -1
	holder.add_child(shadow)

	var face := Sprite2D.new()
	face.name = "Face"
	face.texture = tex
	face.scale = sc
	face.modulate = col
	holder.add_child(face)

	var rim := Line2D.new()
	rim.name = "Rim"
	rim.points = PackedVector2Array([
		Vector2(-px * 0.46, -px * tilt * 0.48), Vector2(px * 0.46, -px * tilt * 0.48)])
	rim.width = maxf(1.0, px * 0.04)
	rim.default_color = Color(Palette.GOLD_PALE, 0.28 + 0.4 * Palette.tile_glow(v))
	holder.add_child(rim)

	var num := Label.new()
	num.name = "Num"
	num.text = str(v)
	num.add_theme_font_override("font", StudioTheme.font("display"))
	num.add_theme_font_size_override("font_size", int(maxf(12.0, px * 0.42 - str(v).length() * 2.0)))
	num.add_theme_color_override("font_color", Fold.tile_ink(v))
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.size = Vector2(px, px * tilt)
	num.position = -num.size * 0.5
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(num)

	if lit:
		_add_light(holder, v, px)
	return holder


## A piece that has just doubled: new colour, number, rim and light.
static func repaint(holder: Node2D, v: int, px: float, room: float = 1.0, lit: bool = true) -> void:
	var col := Fold.tile_color(v) * room
	col.a = 1.0
	(holder.get_node("Face") as Sprite2D).modulate = col
	var num := holder.get_node("Num") as Label
	num.text = str(v)
	num.add_theme_color_override("font_color", Fold.tile_ink(v))
	(holder.get_node("Rim") as Line2D).default_color = Color(Palette.GOLD_PALE, 0.28 + 0.4 * Palette.tile_glow(v))
	for c in holder.get_children():
		if c is PointLight2D:
			c.queue_free()
	if lit:
		_add_light(holder, v, px)


static func _add_light(holder: Node2D, v: int, px: float) -> void:
	var glow := Palette.tile_glow(v)
	if glow <= 0.2:
		return
	var l := PointLight2D.new()
	l.texture = falloff(128, 0.5)
	l.color = Fold.tile_color(v)
	l.energy = glow * 0.9
	l.texture_scale = px / 44.0
	l.blend_mode = Light2D.BLEND_MODE_ADD
	holder.add_child(l)


## The lamp itself: a PointLight2D that lights the room, plus an additive glow sprite so
## the pool of light is *visible*. A Light2D on its own draws nothing — it only changes
## what other things look like — and over a near-black table that came to almost nothing
## on screen. The sprite is the light you can see; the Light2D is the light that works.
static func lamp(px: float, color: Color = Palette.GOLD_PALE, energy: float = 1.9) -> Node2D:
	var holder := Node2D.new()
	var tex := falloff(512, 0.75)

	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = tex
	glow.scale = Vector2.ONE * (px / 512.0)
	glow.modulate = Color(color, 0.30)
	glow.z_index = -3
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	holder.add_child(glow)

	var l := PointLight2D.new()
	l.name = "Light"
	l.texture = tex
	l.color = color
	l.energy = energy
	l.texture_scale = px / 512.0
	l.blend_mode = Light2D.BLEND_MODE_ADD
	holder.add_child(l)
	return holder
