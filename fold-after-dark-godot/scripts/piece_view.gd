## PieceView — how a playing piece is drawn, in one place.
##
## The board and the title screen's attract loop both draw pieces, and they have to be the
## same object: the title screen is a promise about what the game looks like, and a demo
## board drawn with a second, simpler renderer is how that promise quietly stops being
## true. So both call `PieceView.make()`.
##
## A piece is the `piece` plate (folded paper with a crease in it, ops/fold_art) tinted to
## its value from the view's candy ramp, with:
##   - a drop shadow offset down the tilt, so it stands proud of the board;
##   - a gloss along its top edge, brighter the further up the ramp it has climbed;
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
## `room` dims the piece for the *title screen's* attract loop, which is scenery and may be
## as moody as it likes. The board passes 1.0: on the playfield a piece is a thing the
## player reads, and dimming it was half of why the first build's tiles did not separate
## from the table (see the note on the playfield block in palette.gd).
static func make(v: int, px: float, tilt: float, room: float = 1.0, lit: bool = true) -> Node2D:
	var holder := Node2D.new()
	# surface_stand_in, not plate_or_stand_in: the stand-in must average white or the
	# modulate below silently comes out a third darker than Palette.tile_face says.
	var tex := Art.surface_stand_in("piece")
	var sc := Vector2(px, px * tilt) / Vector2(tex.get_width(), tex.get_height())
	var col := Palette.tile_face(v) * room
	col.a = 1.0

	var shadow := Sprite2D.new()
	shadow.texture = tex
	shadow.scale = sc * 1.02
	shadow.position = Vector2(0, px * 0.10)
	# a real drop shadow, now that there is a lit surface for it to fall on: it is
	# what makes a piece read as sitting *on* the table rather than cut into it
	# Warm, not black. On the deep teal tray a black shadow reads as a hole punched in
	# the board; a darker teal reads as the piece sitting on it. Same note as the theme's
	# `drop()` — a bright game has no pure-black anything.
	shadow.modulate = Color(Palette.WELL, 0.70)
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
	# White, not pale gold: on a candy ramp the highlight is the light source, and a gold
	# rim on a pink 256 read as a smudge of the wrong hue.
	rim.default_color = Color(1, 1, 1, 0.45 + 0.4 * Palette.tile_glow(v))
	holder.add_child(rim)

	var num := Label.new()
	num.name = "Num"
	num.text = str(v)
	num.add_theme_font_override("font", StudioTheme.font("display"))
	# The number is the single thing on the board that has to survive a phone screen, so
	# it is sized off the piece and floored well above the old 12 px — at the smallest
	# cell the board ever lays out (34 px) that floor *was* the size, and a 12 px display
	# glyph downscaled to 390 px wide is a smudge. A three-digit value narrows the face,
	# not the floor.
	var digits := str(v).length()
	var size := px * (0.50 if digits <= 2 else (0.40 if digits == 3 else 0.32))
	num.add_theme_font_size_override("font_size", int(maxf(17.0, size)))
	num.add_theme_color_override("font_color", Palette.tile_number_ink(v))
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
	var col := Palette.tile_face(v) * room
	col.a = 1.0
	(holder.get_node("Face") as Sprite2D).modulate = col
	var num := holder.get_node("Num") as Label
	num.text = str(v)
	# a merge can take a 2-digit piece to 3 digits, so the size is recomputed, not kept
	var digits := str(v).length()
	var size := px * (0.50 if digits <= 2 else (0.40 if digits == 3 else 0.32))
	num.add_theme_font_size_override("font_size", int(maxf(17.0, size)))
	num.add_theme_color_override("font_color", Palette.tile_number_ink(v))
	(holder.get_node("Rim") as Line2D).default_color = Color(1, 1, 1, 0.45 + 0.4 * Palette.tile_glow(v))
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
	l.color = Palette.tile_face(v)
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
