extends Node3D

## Built with MeshInstance3D + lights + decals + dust, not a black CSG cave.

const WALL := Color(0.62, 0.56, 0.46)
const FLOOR := Color(0.28, 0.20, 0.14)
const WOOD := Color(0.32, 0.18, 0.10)
const TILE := Color(0.55, 0.56, 0.53)
const TRIM := Color(0.45, 0.38, 0.28)

var _plaster: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood: StandardMaterial3D
var _tile: StandardMaterial3D
var _trim: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_build()
	_dust()

func _make_materials() -> void:
	_plaster = _plaster_mat()
	_floor_mat = _plank_mat(FLOOR, 0.82)
	_wood = _plank_mat(WOOD, 0.7)
	_tile = _tile_mat()
	_trim = _plank_mat(TRIM, 0.55)

func _tex_from(img: Image, rough: float, uv: Vector3) -> StandardMaterial3D:
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1)
	m.roughness = rough
	m.uv1_scale = uv
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func _plaster_mat() -> StandardMaterial3D:
	var dim := 128 if OS.has_feature("web") else 256
	var img := Image.create(dim, dim, false, Image.FORMAT_RGB8)
	for y in dim:
		for x in dim:
			var speck := float((x * 19 + y * 11) % 23) / 90.0
			var mott := 0.1 * (((x * 13) ^ (y * 7)) % 17) / 17.0
			var n := mott + speck * 0.25 - 0.08
			var c := Color(
				clampf(WALL.r + n, 0.0, 1.0),
				clampf(WALL.g + n * 0.85, 0.0, 1.0),
				clampf(WALL.b + n * 0.6, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	return _tex_from(img, 0.93, Vector3(1.6, 1.4, 1.6))

func _plank_mat(base: Color, rough: float) -> StandardMaterial3D:
	var dim := 128 if OS.has_feature("web") else 256
	var img := Image.create(dim, dim, false, Image.FORMAT_RGB8)
	for y in dim:
		for x in dim:
			var plank := int(y / 32.0)
			var groove := 0.0
			if y % 32 < 2:
				groove = -0.18
			var grain := 0.12 * sin(x * 0.4 + plank * 1.7) + 0.06 * sin(x * 1.3)
			var n := grain + groove + 0.04 * float((x * 7 + plank * 13) % 11) / 11.0
			var c := Color(
				clampf(base.r + n, 0.0, 1.0),
				clampf(base.g + n * 0.8, 0.0, 1.0),
				clampf(base.b + n * 0.55, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	return _tex_from(img, rough, Vector3(2.2, 0.45, 6.0))

func _tile_mat() -> StandardMaterial3D:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var grout := 0.0
			if x % 32 < 2 or y % 32 < 2:
				grout = -0.22
			var n := grout + 0.05 * sin(x * 0.2) + 0.04 * float((x + y) % 9) / 9.0
			var c := Color(
				clampf(TILE.r + n, 0.0, 1.0),
				clampf(TILE.g + n, 0.0, 1.0),
				clampf(TILE.b + n, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	return _tex_from(img, 0.35, Vector3(6, 6, 6))

func _noisy(base: Color, rough: float, uv: Vector3, amp: float) -> StandardMaterial3D:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var n := amp * (sin(x * 0.17 + y * 0.03) * 0.5 + sin(y * 0.31) * 0.35 + float((x * 13 + y * 7) % 17) / 80.0)
			var c := Color(
				clampf(base.r + n, 0.0, 1.0),
				clampf(base.g + n * 0.9, 0.0, 1.0),
				clampf(base.b + n * 0.7, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	return _tex_from(img, rough, uv)

func _build() -> void:
	# Hall along +Z. Player looks down +Z toward 402.
	_box(Vector3(0, -0.05, 6), Vector3(3.4, 0.1, 16.4), _floor_mat)
	_box(Vector3(0, 2.62, 6), Vector3(3.4, 0.12, 16.4), _plaster)
	# Hall -X wall with a 1m door cut at z=2.4 (401).
	_box(Vector3(-1.75, 1.3, -0.145), Vector3(0.22, 2.7, 4.01), _plaster)
	_box(Vector3(-1.75, 1.3, 8.545), Vector3(0.22, 2.7, 11.21), _plaster)
	_box(Vector3(-1.75, 2.28, 2.4), Vector3(0.22, 0.72, 1.08), _plaster)
	# Hall +X wall with a 1m door cut at z=8.05 (402).
	_box(Vector3(1.75, 1.3, 2.7), Vector3(0.22, 2.7, 9.7), _plaster)
	_box(Vector3(1.75, 1.3, 11.35), Vector3(0.22, 2.7, 5.6), _plaster)
	_box(Vector3(1.75, 2.28, 8.05), Vector3(0.22, 0.72, 1.08), _plaster)
	_box(Vector3(0, 1.3, -2.15), Vector3(3.5, 2.7, 0.18), _plaster)
	_box(Vector3(0, 1.3, 14.15), Vector3(3.5, 2.7, 0.18), _plaster)
	_box(Vector3(-1.62, 0.08, -0.15), Vector3(0.06, 0.16, 3.9), _trim)
	_box(Vector3(-1.62, 0.08, 8.4), Vector3(0.06, 0.16, 11.4), _trim)
	_box(Vector3(1.62, 0.08, 2.7), Vector3(0.06, 0.16, 9.6), _trim)
	_box(Vector3(1.62, 0.08, 11.35), Vector3(0.06, 0.16, 5.5), _trim)

	_closed_door(Vector3(-1.62, 1.08, 2.4), PI * 0.5, "401")
	_open_door(Vector3(1.62, 1.08, 8.05), "402", 1.0)

	# Apartment 402
	_box(Vector3(5.3, -0.05, 8.05), Vector3(7.4, 0.1, 8.6), _floor_mat)
	_box(Vector3(5.3, 2.62, 8.05), Vector3(7.4, 0.12, 8.6), _plaster)
	_box(Vector3(5.3, 1.3, 3.8), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(5.3, 1.3, 12.25), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(8.9, 1.3, 8.05), Vector3(0.18, 2.7, 8.6), _plaster)
	_box(Vector3(6.5, 1.3, 10.4), Vector3(2.6, 2.7, 0.14), _plaster)
	_box(Vector3(7.7, 1.3, 11.3), Vector3(0.14, 2.7, 1.9), _plaster)
	_box(Vector3(6.7, 1.3, 5.65), Vector3(2.9, 2.7, 0.14), _plaster)
	_box(Vector3(7.5, 0.02, 11.3), Vector3(2.5, 0.04, 1.85), _tile)

	_window(Vector3(8.78, 1.5, 8.05))
	_couch(Vector3(5.9, 0.32, 6.35))
	_table(Vector3(3.25, 0.38, 8.05))
	_sink(Vector3(8.25, 0.48, 11.4))
	_shoes(Vector3(2.25, 0.06, 8.05))
	_wardrobe(Vector3(3.55, 1.05, 4.85))
	_toothbrush(Vector3(8.05, 0.62, 11.15))
	_mirror(Vector3(8.72, 1.45, 11.35))
	_sign(Vector3(4.4, 1.35, 4.05), "VACANCY CONFIRMED  signed: you")
	_sign(Vector3(-1.52, 1.55, 6.2), "Do not knock after midnight")
	_wet(Vector3(7.4, 0.03, 10.6))
	_wet(Vector3(5.1, 0.03, 8.9))
	_wet(Vector3(2.6, 0.03, 8.1))

	_apt401()

	_fixture(Vector3(0, 2.46, 3.2), Color(1.0, 0.72, 0.35), 2.6, 9.0)
	_fixture(Vector3(0, 2.46, 9.4), Color(0.95, 0.98, 0.75), 1.4, 7.0, true)
	_fixture(Vector3(4.6, 2.46, 8.05), Color(1.0, 0.86, 0.62), 3.2, 8.0)
	_fixture(Vector3(7.4, 2.46, 11.3), Color(0.7, 0.85, 1.0), 1.8, 5.5)
	_fixture(Vector3(-4.6, 2.46, 2.4), Color(0.85, 0.7, 0.55), 2.8, 7.5)
	_fixture(Vector3(-7.4, 2.46, 5.65), Color(0.55, 0.7, 0.9), 1.6, 5.0, true)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.45, 0.55, 0.75)
	moon.light_energy = 0.08
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-35, 110, 0)
	add_child(moon)

	_stain(Vector3(0.2, 0.02, 6.8), Vector3(1.4, 1, 0.7))
	_stain(Vector3(6.2, 0.02, 9.6), Vector3(1.1, 1, 0.8))

func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	mi.add_child(body)
	return mi

func _apt401() -> void:
	_box(Vector3(-5.3, -0.05, 2.4), Vector3(7.4, 0.1, 8.6), _floor_mat)
	_box(Vector3(-5.3, 2.62, 2.4), Vector3(7.4, 0.12, 8.6), _plaster)
	_box(Vector3(-5.3, 1.3, -1.9), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(-5.3, 1.3, 6.7), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(-9.0, 1.3, 2.4), Vector3(0.18, 2.7, 8.6), _plaster)
	_box(Vector3(-6.5, 1.3, 4.75), Vector3(2.6, 2.7, 0.14), _plaster)
	_box(Vector3(-7.7, 1.3, 5.65), Vector3(0.14, 2.7, 1.9), _plaster)
	_box(Vector3(-6.7, 1.3, 0.0), Vector3(2.9, 2.7, 0.14), _plaster)
	_box(Vector3(-7.5, 0.02, 5.65), Vector3(2.5, 0.04, 1.85), _tile)
	_window(Vector3(-8.78, 1.5, 2.4))
	_couch(Vector3(-5.9, 0.32, 0.7))
	_table(Vector3(-3.25, 0.38, 2.4))
	_sink(Vector3(-8.25, 0.48, 5.75))
	_shoes(Vector3(-2.25, 0.06, 2.4))
	_wardrobe(Vector3(-3.55, 1.05, -0.8))
	_toothbrush(Vector3(-8.05, 0.62, 5.5))
	_mirror(Vector3(-8.72, 1.45, 5.7))
	_sign(Vector3(-4.4, 1.35, -1.65), "YOU LIVE HERE. YOU LEFT.")
	_wet(Vector3(-7.4, 0.03, 5.0))
	_wet(Vector3(-3.4, 0.03, 2.5))
	_stain(Vector3(-6.2, 0.02, 3.6), Vector3(1.1, 1, 0.8))

func open_401() -> void:
	if has_meta("apt401_open"):
		return
	set_meta("apt401_open", true)
	for n in get_tree().get_nodes_in_group("door_401_solid"):
		n.visible = false
		_disable_colliders(n)
	_open_door(Vector3(-1.62, 1.08, 2.4), "401", -1.0)

func swap_plates() -> void:
	for n in get_tree().get_nodes_in_group("door_plate"):
		if n is Label3D:
			var lab := n as Label3D
			if lab.text == "401":
				lab.text = "402"
			elif lab.text == "402":
				lab.text = "401"

func _disable_colliders(n: Node) -> void:
	if n is CollisionShape3D:
		(n as CollisionShape3D).disabled = true
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
	for c in n.get_children():
		_disable_colliders(c)

func _closed_door(pos: Vector3, yaw: float, label: String) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 2.12, 0.92)
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = yaw
	mi.material_override = _wood
	mi.add_to_group("door_401_solid")
	add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.07, 2.12, 0.92)
	col.shape = sh
	body.add_child(col)
	body.set_script(preload("res://scripts/door.gd"))
	body.set("prompt", "Listen at 401")
	body.set("kind", "401")
	body.collision_layer = 1
	body.collision_mask = 0
	mi.add_child(body)
	_plate(pos + Vector3(0.05, 0.48, 0) if yaw > 1.0 else pos + Vector3(-0.05, 0.48, 0), label, yaw)

func _open_door(pos: Vector3, label: String, inward_x: float = 1.0) -> void:
	for zoff in [-0.5, 0.5]:
		_box(pos + Vector3(0, 0.02, zoff), Vector3(0.1, 2.2, 0.08), _wood)
	_box(pos + Vector3(0, 1.12, 0), Vector3(0.1, 0.08, 1.1), _wood)
	var leaf := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 2.1, 0.92)
	leaf.mesh = mesh
	leaf.material_override = _wood
	leaf.position = pos + Vector3(0.48 * inward_x, 0, 0.42)
	leaf.rotation.y = deg_to_rad(-80.0 * inward_x)
	add_child(leaf)
	var plate_yaw := -PI * 0.5 if inward_x > 0.0 else PI * 0.5
	_plate(pos + Vector3(-0.08 * inward_x, 0.48, 0), label, plate_yaw)

func _plate(pos: Vector3, text: String, yaw: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 42
	l.pixel_size = 0.004
	l.modulate = Color(0.95, 0.82, 0.45)
	l.outline_modulate = Color(0.1, 0.08, 0.04)
	l.outline_size = 6
	l.position = pos
	l.rotation.y = yaw
	l.shaded = true
	l.add_to_group("door_plate")
	UiFont.apply_3d(l)
	add_child(l)

func _fixture(pos: Vector3, color: Color, energy: float, rng: float, flicker := false) -> void:
	var shade := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.18
	cyl.height = 0.08
	shade.mesh = cyl
	shade.position = pos
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.85, 0.8, 0.65)
	sm.emission_enabled = true
	sm.emission = color
	sm.emission_energy_multiplier = 2.4
	shade.material_override = sm
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shade)
	var li := OmniLight3D.new()
	li.position = pos + Vector3(0, -0.12, 0)
	li.light_color = color
	li.light_energy = energy
	li.omni_range = rng
	li.omni_attenuation = 1.35
	# Omni dual-paraboloid shadows on box halls look like starbursts.
	li.shadow_enabled = false
	li.add_to_group("hall_light")
	if flicker:
		li.set_script(preload("res://scripts/flicker_light.gd"))
	add_child(li)

func _window(pos: Vector3) -> void:
	var glass := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.04, 1.25, 1.7)
	glass.mesh = mesh
	glass.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.12, 0.18, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.25, 0.4, 0.7)
	m.emission_energy_multiplier = 1.6
	m.roughness = 0.08
	glass.material_override = m
	add_child(glass)
	_box(pos + Vector3(0, 0, -0.88), Vector3(0.08, 1.4, 0.06), _trim)
	_box(pos + Vector3(0, 0, 0.88), Vector3(0.08, 1.4, 0.06), _trim)

func _couch(pos: Vector3) -> void:
	_box(pos, Vector3(1.7, 0.42, 0.72), _noisy(Color(0.22, 0.23, 0.24), 0.95, Vector3(2, 2, 2), 0.04))
	_box(pos + Vector3(0, 0.38, -0.28), Vector3(1.7, 0.42, 0.18), _noisy(Color(0.2, 0.21, 0.22), 0.95, Vector3(2, 2, 2), 0.04))

func _table(pos: Vector3) -> void:
	_box(pos, Vector3(1.15, 0.08, 0.7), _wood)
	_box(pos + Vector3(0.46, -0.22, 0.26), Vector3(0.07, 0.36, 0.07), _wood)
	_box(pos + Vector3(-0.46, -0.22, 0.26), Vector3(0.07, 0.36, 0.07), _wood)
	_box(pos + Vector3(0.46, -0.22, -0.26), Vector3(0.07, 0.36, 0.07), _wood)
	_box(pos + Vector3(-0.46, -0.22, -0.26), Vector3(0.07, 0.36, 0.07), _wood)

func _sink(pos: Vector3) -> void:
	_box(pos, Vector3(0.72, 0.1, 0.46), _tile)

func _wardrobe(pos: Vector3) -> void:
	_box(pos, Vector3(0.55, 2.05, 1.15), _wood)
	_box(pos + Vector3(0.3, 0.2, 0), Vector3(0.04, 1.6, 0.5), _wood)

func _toothbrush(pos: Vector3) -> void:
	_box(pos, Vector3(0.08, 0.16, 0.08), _noisy(Color(0.75, 0.75, 0.78), 0.3, Vector3(1, 1, 1), 0.02))
	_box(pos + Vector3(0, 0.14, 0), Vector3(0.02, 0.18, 0.02), _noisy(Color(0.2, 0.45, 0.55), 0.4, Vector3(1, 1, 1), 0.01))

func _mirror(pos: Vector3) -> void:
	var glass := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.03, 0.7, 0.45)
	glass.mesh = mesh
	glass.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.38, 0.4)
	m.metallic = 0.85
	m.roughness = 0.08
	glass.material_override = m
	add_child(glass)

func _sign(pos: Vector3, text: String) -> void:
	_box(pos, Vector3(0.02, 0.28, 0.55), _noisy(Color(0.15, 0.14, 0.12), 0.8, Vector3(1, 1, 1), 0.02))
	var l := Label3D.new()
	l.text = text
	l.font_size = 28
	l.pixel_size = 0.0032
	l.modulate = Color(0.82, 0.78, 0.7)
	l.position = pos + Vector3(0.03, 0, 0)
	l.rotation.y = PI * 0.5 if pos.x > 0.0 else -PI * 0.5
	UiFont.apply_3d(l)
	add_child(l)

func _wet(pos: Vector3) -> void:
	_stain(pos, Vector3(0.35, 0.4, 0.22))

func _shoes(pos: Vector3) -> void:
	_box(pos + Vector3(-0.08, 0, 0), Vector3(0.1, 0.07, 0.26), _noisy(Color(0.08, 0.08, 0.09), 0.9, Vector3(1, 1, 1), 0.02))
	_box(pos + Vector3(0.1, 0, 0.02), Vector3(0.1, 0.07, 0.26), _noisy(Color(0.08, 0.08, 0.09), 0.9, Vector3(1, 1, 1), 0.02))

func _stain(pos: Vector3, size: Vector3) -> void:
	var d := Decal.new()
	d.position = pos
	d.size = size
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var dx := (x - 32) / 32.0
			var dy := (y - 32) / 32.0
			var a := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0) * 0.45
			img.set_pixel(x, y, Color(0.12, 0.1, 0.08, a))
	var tex := ImageTexture.create_from_image(img)
	d.texture_albedo = tex
	d.modulate = Color(0.25, 0.18, 0.1)
	add_child(d)

func _dust() -> void:
	var p := GPUParticles3D.new()
	p.position = Vector3(0, 1.4, 6)
	p.amount = 40
	p.lifetime = 7.0
	p.preprocess = 3.0
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(12, 4, 18))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(1.2, 0.8, 6)
	mat.gravity = Vector3(0, -0.02, 0)
	mat.initial_velocity_min = 0.01
	mat.initial_velocity_max = 0.06
	mat.scale_min = 0.015
	mat.scale_max = 0.04
	mat.color = Color(0.7, 0.62, 0.5, 0.35)
	p.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.04, 0.04)
	p.draw_pass_1 = qm
	add_child(p)
