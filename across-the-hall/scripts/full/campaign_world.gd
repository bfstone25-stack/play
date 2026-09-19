extends Node3D

var episode := 2
var _wall: StandardMaterial3D
var _floor: StandardMaterial3D
var _wood: StandardMaterial3D
var _metal: StandardMaterial3D
var _paper: StandardMaterial3D
var _dark: StandardMaterial3D
var _accent: StandardMaterial3D

func build_episode(next_episode: int) -> void:
	episode = next_episode
	_clear_world()
	_make_materials()
	match episode:
		2:
			_build_fifth_floor()
		3:
			_build_basement()
		4:
			_build_management()
		5:
			_build_lobby()

func _clear_world() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _make_materials() -> void:
	match episode:
		2:
			_wall = _mat(Color(0.38, 0.32, 0.26), 0.9)
			_floor = _mat(Color(0.18, 0.11, 0.08), 0.78)
			_accent = _mat(Color(0.68, 0.48, 0.22), 0.55, true)
		3:
			_wall = _mat(Color(0.24, 0.27, 0.25), 0.96)
			_floor = _mat(Color(0.12, 0.14, 0.13), 0.92)
			_accent = _mat(Color(0.58, 0.14, 0.08), 0.5, true)
		4:
			_wall = _mat(Color(0.32, 0.38, 0.31), 0.94)
			_floor = _mat(Color(0.14, 0.12, 0.09), 0.86)
			_accent = _mat(Color(0.62, 0.52, 0.28), 0.58, true)
		_:
			_wall = _mat(Color(0.42, 0.38, 0.31), 0.88)
			_floor = _mat(Color(0.16, 0.13, 0.1), 0.8)
			_accent = _mat(Color(0.52, 0.68, 0.7), 0.45, true)
	_wood = _mat(Color(0.25, 0.13, 0.07), 0.72)
	_metal = _mat(Color(0.22, 0.24, 0.23), 0.38)
	_paper = _mat(Color(0.82, 0.77, 0.64), 0.92)
	_dark = _mat(Color(0.025, 0.022, 0.02), 1.0)

func _mat(color: Color, roughness: float, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission:
		material.emission_enabled = true
		material.emission = color * 0.42
	return material

func _shell(title: String, subtitle: String) -> void:
	_box(Vector3(0, -0.05, 7), Vector3(8.0, 0.1, 18.0), _floor)
	_box(Vector3(0, 2.75, 7), Vector3(8.0, 0.12, 18.0), _wall)
	_box(Vector3(-4.0, 1.35, 7), Vector3(0.16, 2.8, 18.0), _wall)
	_box(Vector3(4.0, 1.35, 7), Vector3(0.16, 2.8, 18.0), _wall)
	_box(Vector3(0, 1.35, -2.0), Vector3(8.0, 2.8, 0.16), _wall)
	_box(Vector3(0, 1.35, 16.0), Vector3(8.0, 2.8, 0.16), _wall)
	_sign(Vector3(0, 1.72, -1.82), title, 58, Color(0.9, 0.76, 0.53))
	_sign(Vector3(0, 1.18, -1.8), subtitle, 30, Color(0.65, 0.6, 0.52))
	for z in [1.0, 5.0, 9.0, 13.0]:
		_fixture(Vector3(0, 2.55, z))

func _build_fifth_floor() -> void:
	_shell("FLOOR 5 — UNLISTED", "Every door says 401. Only one object remembers.")
	for z in [2.1, 5.8, 9.5]:
		_door(Vector3(-3.82, 1.05, z), "401")
		_door(Vector3(3.82, 1.05, z + 1.7), "401")
	_box(Vector3(0, 0.42, 12.8), Vector3(2.3, 0.84, 0.7), _metal)
	_sign(Vector3(0, 1.18, 12.35), "ELEVATOR\n4   5   [ ]", 34, Color(0.8, 0.7, 0.48))
	_box(Vector3(-2.7, 0.34, 7.0), Vector3(1.4, 0.68, 0.55), _wood)
	_box(Vector3(2.7, 0.34, 8.7), Vector3(1.4, 0.68, 0.55), _wood)

func _build_basement() -> void:
	_shell("B — SERVICE BASEMENT", "One circuit at a time. The complaints need power.")
	for x in [-2.8, 0.0, 2.8]:
		var pipe := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.12
		cylinder.bottom_radius = 0.12
		cylinder.height = 13.0
		pipe.mesh = cylinder
		pipe.material_override = _metal
		pipe.position = Vector3(x, 2.2, 6.2)
		pipe.rotation.x = PI * 0.5
		add_child(pipe)
	_box(Vector3(-2.6, 0.8, 3.3), Vector3(1.6, 1.6, 0.45), _metal)
	_sign(Vector3(-2.6, 1.1, 3.0), "LIFT\nARCHIVE\nHALL", 30, Color(0.8, 0.28, 0.18))
	_box(Vector3(2.4, 0.7, 8.3), Vector3(2.4, 1.4, 0.8), _metal)
	_sign(Vector3(2.4, 1.05, 7.82), "COMPLAINT ARCHIVE\n02:17", 28, Color(0.62, 0.72, 0.62))
	_door(Vector3(0, 1.05, 14.9), "RECORDS")

func _build_management() -> void:
	_shell("MANAGEMENT", "RETURN / RETAIN / REMOVE")
	for x in [-2.7, 0.0, 2.7]:
		_box(Vector3(x, 0.42, 5.0), Vector3(1.7, 0.84, 0.75), _wood)
	for x in [-2.6, 2.6]:
		for z in [8.0, 10.0, 12.0]:
			_box(Vector3(x, 0.9, z), Vector3(1.5, 1.8, 0.65), _metal)
	_sign(Vector3(-2.7, 1.05, 4.55), "RETURN", 34, Color(0.72, 0.62, 0.34))
	_sign(Vector3(0, 1.05, 4.55), "RETAIN", 34, Color(0.72, 0.62, 0.34))
	_sign(Vector3(2.7, 1.05, 4.55), "REMOVE", 34, Color(0.72, 0.62, 0.34))
	_box(Vector3(0, 0.52, 13.0), Vector3(3.2, 1.04, 1.0), _wood)
	_sign(Vector3(0, 1.25, 12.5), "NO MANAGER ON DUTY", 30, Color(0.72, 0.18, 0.12))

func _build_lobby() -> void:
	_shell("EXIT DIRECTORY", "Every name is now DOOR or OCCUPANT.")
	_box(Vector3(-2.55, 1.0, 5.0), Vector3(2.1, 2.0, 0.35), _wood)
	_sign(Vector3(-2.55, 1.2, 4.78), "DIRECTORY\n401  —\n402  —\nYOU  —", 30, Color(0.7, 0.78, 0.7))
	for row in 3:
		for column in 4:
			_box(
				Vector3(1.7 + column * 0.48, 0.45 + row * 0.45, 5.0),
				Vector3(0.4, 0.34, 0.34),
				_metal
			)
	_door(Vector3(-1.5, 1.05, 14.8), "EXIT")
	_door(Vector3(1.5, 1.05, 14.8), "EXIT")
	# The tenant finally stands in direct view.
	_box(Vector3(2.6, 0.88, 10.8), Vector3(0.36, 1.75, 0.3), _dark, false)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = _dark
	head.position = Vector3(2.6, 1.9, 10.8)
	add_child(head)

func set_circuit(which: String) -> void:
	for light in get_tree().get_nodes_in_group("campaign_light"):
		if light is OmniLight3D:
			var on := which == "hall" or str(light.name).to_lower().contains(which)
			(light as OmniLight3D).light_energy = 2.2 if on else 0.12
			(light as OmniLight3D).light_color = (
				Color(0.78, 0.88, 1.0) if on else Color(0.35, 0.12, 0.08)
			)

func _door(pos: Vector3, label: String) -> void:
	_box(pos, Vector3(1.15, 2.1, 0.16), _wood)
	_sign(pos + Vector3(0, 0.25, -0.12), label, 38, Color(0.82, 0.7, 0.5))

func _fixture(pos: Vector3) -> void:
	var shade := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.22
	cylinder.bottom_radius = 0.34
	cylinder.height = 0.12
	shade.mesh = cylinder
	shade.material_override = _accent
	shade.position = pos
	add_child(shade)
	var light := OmniLight3D.new()
	light.name = "hall_%d" % int(pos.z)
	light.position = pos - Vector3(0, 0.18, 0)
	light.light_color = Color(0.95, 0.75, 0.48)
	light.light_energy = 1.55
	light.omni_range = 6.0
	light.shadow_enabled = false
	light.add_to_group("campaign_light")
	add_child(light)

func _sign(pos: Vector3, text: String, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.004
	label.width = 900
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	UiFont.apply_3d(label)
	add_child(label)

func _box(
	pos: Vector3,
	size: Vector3,
	material: Material,
	collide := true
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = material
	add_child(mesh_instance)
	if collide:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		mesh_instance.add_child(body)
	return mesh_instance
