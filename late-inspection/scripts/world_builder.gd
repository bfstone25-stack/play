extends Node3D

## Flat 404 — corridor stub + entry + living + wet kitchen.
## Copy-adapted lighting approach from Across the Hall; layout is inspection-specific.

var _plaster: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood: StandardMaterial3D
var _tile: StandardMaterial3D
var _trim: StandardMaterial3D
var _metal: StandardMaterial3D
var _dark: StandardMaterial3D
var _paper: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_build()

func _make_materials() -> void:
	_plaster = GameMaterials.plaster(Color(0.42, 0.38, 0.32))
	_floor_mat = GameMaterials.planks(Color(0.18, 0.12, 0.08), 0.85)
	_wood = GameMaterials.planks(Color(0.26, 0.14, 0.08), 0.72)
	_tile = GameMaterials.concrete(Color(0.4, 0.42, 0.38), 0.45)
	_trim = GameMaterials.planks(Color(0.32, 0.26, 0.18), 0.6)
	_metal = GameMaterials.metal(Color(0.22, 0.24, 0.23))
	_dark = GameMaterials.flat(Color(0.035, 0.03, 0.025), 1.0)
	_paper = GameMaterials.paper(Color(0.78, 0.72, 0.58))

func _build() -> void:
	# Corridor outside 404 (along +Z, door on +X).
	_box(Vector3(0, -0.05, 2.0), Vector3(2.4, 0.1, 8.0), _floor_mat)
	_box(Vector3(0, 2.55, 2.0), Vector3(2.4, 0.1, 8.0), _plaster)
	_box(Vector3(-1.25, 1.25, 2.0), Vector3(0.16, 2.6, 8.0), _plaster)
	_box(Vector3(1.25, 1.25, -0.4), Vector3(0.16, 2.6, 3.2), _plaster)
	_box(Vector3(1.25, 1.25, 4.8), Vector3(0.16, 2.6, 3.2), _plaster)
	_box(Vector3(0, 1.25, -2.05), Vector3(2.5, 2.6, 0.16), _plaster)
	_box(Vector3(0, 1.25, 6.05), Vector3(2.5, 2.6, 0.16), _plaster)
	_box(Vector3(-1.15, 0.08, 2.0), Vector3(0.05, 0.14, 7.8), _trim)
	_box(Vector3(1.15, 0.08, -0.4), Vector3(0.05, 0.14, 3.1), _trim)
	_box(Vector3(1.15, 0.08, 4.8), Vector3(0.05, 0.14, 3.1), _trim)

	_door_leaf(Vector3(1.18, 1.05, 2.2), "404")
	_sign(Vector3(1.16, 1.72, 2.2), "LATE INSPECTION")

	# Apartment interior (+X from door).
	_box(Vector3(4.6, -0.05, 2.2), Vector3(6.6, 0.1, 7.2), _floor_mat)
	_box(Vector3(4.6, 2.55, 2.2), Vector3(6.6, 0.1, 7.2), _plaster)
	_box(Vector3(4.6, 1.25, -1.35), Vector3(6.6, 2.6, 0.16), _plaster)
	_box(Vector3(4.6, 1.25, 5.75), Vector3(6.6, 2.6, 0.16), _plaster)
	_box(Vector3(7.85, 1.25, 2.2), Vector3(0.16, 2.6, 7.2), _plaster)
	_box(Vector3(1.35, 1.25, -0.05), Vector3(0.16, 2.6, 2.5), _plaster)
	_box(Vector3(1.35, 1.25, 4.45), Vector3(0.16, 2.6, 2.5), _plaster)
	_box(Vector3(1.35, 2.35, 2.2), Vector3(0.16, 0.45, 1.05), _plaster)

	_box(Vector3(6.6, 0.02, 4.4), Vector3(2.2, 0.04, 2.0), _tile)
	_counter(Vector3(6.9, 0.0, 4.85))
	_pipe_drip(Vector3(7.45, 0.55, 5.15))

	_couch(Vector3(3.4, 0.28, 0.1))
	_table(Vector3(3.5, 0.35, 1.5))
	_lamp(Vector3(2.6, 0.0, 0.35))
	_calendar(Vector3(4.2, 1.45, -1.25))

	_fixture(Vector3(0.0, 2.35, 2.0), Color(1.0, 0.72, 0.32), 1.15, 7.5, true)
	_fixture(Vector3(3.8, 2.35, 1.6), Color(1.0, 0.78, 0.42), 1.55, 8.0, false)
	_fixture(Vector3(7.2, 0.35, 5.1), Color(0.45, 0.85, 0.35), 0.85, 3.8, true)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.35, 0.42, 0.55)
	moon.light_energy = 0.05
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-40, 95, 0)
	add_child(moon)

func _box(pos: Vector3, size: Vector3, mat: Material, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		col.shape = sh
		body.add_child(col)
		mi.add_child(body)
	return mi

func _door_leaf(pos: Vector3, label: String) -> void:
	_box(pos, Vector3(0.08, 2.05, 0.92), _wood)
	_box(pos + Vector3(-0.06, 0.0, 0.32), Vector3(0.06, 0.06, 0.06), _metal, false)
	_sign(pos + Vector3(-0.05, 0.55, 0.0), label)

func _sign(pos: Vector3, text: String) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 28
	lab.modulate = Color(0.75, 0.68, 0.52, 0.95)
	lab.position = pos
	lab.rotation_degrees = Vector3(0, -90, 0)
	lab.pixel_size = 0.0045
	UiFont.apply_3d(lab)
	add_child(lab)

func _couch(pos: Vector3) -> void:
	_box(pos, Vector3(1.8, 0.42, 0.75), GameMaterials.carpet(Color(0.18, 0.16, 0.14)))
	_box(pos + Vector3(0, 0.35, -0.28), Vector3(1.8, 0.45, 0.18), GameMaterials.carpet(Color(0.16, 0.14, 0.12)))

func _table(pos: Vector3) -> void:
	_box(pos, Vector3(0.85, 0.05, 0.55), _wood)
	_box(pos + Vector3(-0.35, -0.2, -0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(0.35, -0.2, -0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(-0.35, -0.2, 0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(0.35, -0.2, 0.2), Vector3(0.05, 0.4, 0.05), _wood)

func _lamp(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), _metal, false)
	_box(pos + Vector3(0, 0.95, 0), Vector3(0.35, 0.22, 0.35), GameMaterials.emissive(Color(1.0, 0.85, 0.55), 0.55), false)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.48)
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.shadow_enabled = true
	light.position = pos + Vector3(0, 1.05, 0)
	add_child(light)

func _calendar(pos: Vector3) -> void:
	_box(pos, Vector3(0.45, 0.55, 0.02), _paper, false)
	var lab := Label3D.new()
	lab.text = "TONIGHT"
	lab.font_size = 42
	lab.modulate = Color(0.35, 0.12, 0.1, 1)
	lab.position = pos + Vector3(0, 0, 0.03)
	lab.rotation_degrees = Vector3(0, 180, 0)
	lab.pixel_size = 0.0035
	UiFont.apply_3d(lab)
	add_child(lab)

func _counter(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.45, 0), Vector3(1.8, 0.9, 0.55), _wood)
	_box(pos + Vector3(0, 0.92, 0), Vector3(1.85, 0.05, 0.58), _tile)

func _pipe_drip(pos: Vector3) -> void:
	_box(pos, Vector3(0.08, 0.9, 0.08), _metal, false)
	_box(pos + Vector3(-0.15, -0.52, 0.1), Vector3(0.55, 0.02, 0.4), GameMaterials.flat(Color(0.12, 0.02, 0.02), 0.95), false)
	var drip_mat: StandardMaterial3D = GameMaterials.emissive(Color(0.45, 0.08, 0.06), 0.25)
	_box(pos + Vector3(0, -0.2, 0.06), Vector3(0.04, 0.12, 0.04), drip_mat, false)

func _fixture(pos: Vector3, color: Color, energy: float, range_m: float, flicker: bool) -> void:
	_box(pos, Vector3(0.35, 0.08, 0.35), _metal, false)
	var light: OmniLight3D
	if flicker:
		light = OmniLight3D.new()
		light.set_script(preload("res://scripts/flicker_light.gd"))
	else:
		light = OmniLight3D.new()
		light.light_energy = energy
	light.light_color = color
	light.omni_range = range_m
	light.shadow_enabled = not flicker
	light.position = pos + Vector3(0, -0.12, 0)
	if not flicker:
		light.light_energy = energy
	add_child(light)
