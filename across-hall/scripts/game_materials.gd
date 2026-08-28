extends RefCounted
class_name GameMaterials

## Procedural surfaces for Episode I and the full campaign.
## Generated ImageTexture planks / plaster / metal — no external asset pack.

static func dim() -> int:
	return 96 if OS.has_feature("web") else 192

static func plaster(base: Color, rough := 0.92) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var speck := float((x * 19 + y * 11) % 23) / 90.0
			var mott := 0.1 * float(((x * 13) ^ (y * 7)) % 17) / 17.0
			var n := mott + speck * 0.25 - 0.08
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n * 0.85, 0.0, 1.0),
					clampf(base.b + n * 0.6, 0.0, 1.0)
				)
			)
	return _tex(img, rough, Vector3(1.8, 1.5, 1.8))

static func planks(base: Color, rough := 0.78) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var band := maxi(size / 8, 8)
	for y in size:
		for x in size:
			var plank := int(y / float(band))
			var groove := -0.18 if y % band < 2 else 0.0
			var grain := 0.12 * sin(x * 0.4 + plank * 1.7) + 0.06 * sin(x * 1.3)
			var n := grain + groove + 0.04 * float((x * 7 + plank * 13) % 11) / 11.0
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n * 0.8, 0.0, 1.0),
					clampf(base.b + n * 0.55, 0.0, 1.0)
				)
			)
	return _tex(img, rough, Vector3(2.4, 0.5, 6.0))

static func concrete(base: Color, rough := 0.94) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var crack := 0.0
			if absf(sin(x * 0.07 + y * 0.02) * 40.0 - float(y % 40)) < 1.2:
				crack = -0.14
			var n := (
				0.08 * sin(x * 0.21 + y * 0.05)
				+ 0.06 * sin(y * 0.33)
				+ 0.05 * float((x * 9 + y * 5) % 13) / 13.0
				+ crack
			)
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n, 0.0, 1.0),
					clampf(base.b + n * 0.9, 0.0, 1.0)
				)
			)
	return _tex(img, rough, Vector3(3.2, 3.2, 3.2))

static func carpet(base: Color, rough := 0.95) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var n := 0.07 * float((x * 3 + y * 5) % 7) / 7.0 + 0.04 * sin(x * 0.9) * sin(y * 0.7)
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n * 0.9, 0.0, 1.0),
					clampf(base.b + n * 0.7, 0.0, 1.0)
				)
			)
	return _tex(img, rough, Vector3(4.5, 4.5, 4.5))

static func metal(base: Color, rough := 0.34) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var brush := 0.1 * sin(y * 0.55) + 0.04 * float((x + y * 3) % 9) / 9.0
			var n := brush - 0.05
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n, 0.0, 1.0),
					clampf(base.b + n, 0.0, 1.0)
				)
			)
	var m := _tex(img, rough, Vector3(2.0, 4.0, 2.0))
	m.metallic = 0.72
	return m

static func paper(base: Color) -> StandardMaterial3D:
	var size := dim()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var n := 0.04 * float((x * 11 + y * 3) % 15) / 15.0
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n, 0.0, 1.0),
					clampf(base.b + n * 0.8, 0.0, 1.0)
				)
			)
	return _tex(img, 0.9, Vector3(1.2, 1.2, 1.2))

static func emissive(base: Color, strength := 0.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = base * strength
	return m

static func flat(base: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = rough
	return m

static func _tex(img: Image, rough: float, uv: Vector3) -> StandardMaterial3D:
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1)
	m.roughness = rough
	m.uv1_scale = uv
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m
