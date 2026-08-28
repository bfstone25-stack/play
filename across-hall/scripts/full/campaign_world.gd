extends Node3D

var episode := 2
var _wall: StandardMaterial3D
var _floor: StandardMaterial3D
var _wood: StandardMaterial3D
var _metal: StandardMaterial3D
var _paper: StandardMaterial3D
var _dark: StandardMaterial3D
var _accent: StandardMaterial3D
var _trim: StandardMaterial3D
var _glass: StandardMaterial3D

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
			_wall = CampaignMaterials.plaster(Color(0.42, 0.36, 0.28))
			_floor = CampaignMaterials.planks(Color(0.22, 0.14, 0.09), 0.8)
			_accent = CampaignMaterials.emissive(Color(0.72, 0.52, 0.24), 0.35)
		3:
			_wall = CampaignMaterials.concrete(Color(0.28, 0.3, 0.28))
			_floor = CampaignMaterials.concrete(Color(0.16, 0.17, 0.16), 0.9)
			_accent = CampaignMaterials.emissive(Color(0.62, 0.16, 0.08), 0.45)
		4:
			_wall = CampaignMaterials.plaster(Color(0.36, 0.4, 0.33))
			_floor = CampaignMaterials.carpet(Color(0.18, 0.14, 0.1))
			_accent = CampaignMaterials.emissive(Color(0.66, 0.54, 0.28), 0.32)
		_:
			_wall = CampaignMaterials.plaster(Color(0.46, 0.4, 0.33))
			_floor = CampaignMaterials.planks(Color(0.2, 0.15, 0.11), 0.78)
			_accent = CampaignMaterials.emissive(Color(0.52, 0.7, 0.72), 0.38)
	_wood = CampaignMaterials.planks(Color(0.28, 0.15, 0.08), 0.7)
	_metal = CampaignMaterials.metal(Color(0.26, 0.28, 0.27))
	_paper = CampaignMaterials.paper(Color(0.84, 0.78, 0.64))
	_dark = CampaignMaterials.flat(Color(0.03, 0.025, 0.02), 1.0)
	_trim = CampaignMaterials.planks(Color(0.18, 0.12, 0.08), 0.82)
	_glass = CampaignMaterials.flat(Color(0.55, 0.65, 0.72, 0.35), 0.08)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.albedo_color.a = 0.28

func _shell(title: String, subtitle: String) -> void:
	_box(Vector3(0, -0.05, 7), Vector3(8.0, 0.1, 18.0), _floor)
	_box(Vector3(0, 2.75, 7), Vector3(8.0, 0.12, 18.0), _wall)
	_box(Vector3(-4.0, 1.35, 7), Vector3(0.16, 2.8, 18.0), _wall)
	_box(Vector3(4.0, 1.35, 7), Vector3(0.16, 2.8, 18.0), _wall)
	_box(Vector3(0, 1.35, -2.0), Vector3(8.0, 2.8, 0.16), _wall)
	_box(Vector3(0, 1.35, 16.0), Vector3(8.0, 2.8, 0.16), _wall)
	_box(Vector3(-3.9, 0.08, 7), Vector3(0.08, 0.16, 17.6), _trim, false)
	_box(Vector3(3.9, 0.08, 7), Vector3(0.08, 0.16, 17.6), _trim, false)
	_box(Vector3(-3.9, 2.55, 7), Vector3(0.06, 0.1, 17.6), _trim, false)
	_box(Vector3(3.9, 2.55, 7), Vector3(0.06, 0.1, 17.6), _trim, false)
	_sign(Vector3(0, 2.05, -1.82), title, 52, Color(0.9, 0.76, 0.53))
	_sign(Vector3(0, 1.55, -1.8), subtitle, 26, Color(0.65, 0.6, 0.52))
	for z in [1.0, 5.0, 9.0, 13.0]:
		_fixture(Vector3(0, 2.55, z))

func _build_fifth_floor() -> void:
	_shell("FLOOR 5 — UNLISTED", "Every door says 401. Only one object remembers.")
	for z in [2.1, 5.8, 9.5]:
		_door(Vector3(-3.82, 1.05, z), "401")
		_door(Vector3(3.82, 1.05, z + 1.7), "401")
	_elevator(Vector3(0, 0.0, 13.0))
	var elevator_sign := _sign(Vector3(0, 1.35, 12.45), "ELEVATOR\n4   5   [ ]", 32, Color(0.8, 0.7, 0.48))
	elevator_sign.name = "ElevatorSign"
	_console(Vector3(-2.7, 0.0, 7.0))
	_console(Vector3(2.7, 0.0, 8.7))
	var present := _sign(Vector3(3.45, 1.55, 7.5), "401", 34, Color(0.72, 0.62, 0.48))
	present.name = "PresentDoor"
	present.rotation.y = -PI * 0.5

func _build_basement() -> void:
	_shell("B — SERVICE BASEMENT", "One circuit at a time. The complaints need power.")
	for x in [-2.8, 0.0, 2.8]:
		_pipe(Vector3(x, 2.2, 6.2), 13.0)
	_station(Vector3(-2.6, 0.0, 2.6), "LIFT", "lift")
	_station(Vector3(0.0, 0.0, 5.6), "ARCHIVE", "archive")
	_station(Vector3(2.6, 0.0, 8.6), "HALL", "hall")
	_cabinet(Vector3(-2.6, 0.0, 4.0), "ELEVATOR\nCABINET")
	_archive_rack(Vector3(2.4, 0.0, 10.8))
	_door(Vector3(0, 1.05, 14.9), "RECORDS")
	set_circuit("")

func _build_management() -> void:
	_shell("MANAGEMENT", "RETURN / RETAIN / REMOVE")
	_desk(Vector3(0, 0.0, 1.9), Vector3(5.4, 0.84, 0.7))
	_sign(Vector3(0, 1.05, 1.5), "INTAKE", 28, Color(0.78, 0.68, 0.48))
	for x in [-2.7, 0.0, 2.7]:
		_desk(Vector3(x, 0.0, 6.4), Vector3(1.6, 0.84, 0.85))
	_sign(Vector3(-2.7, 1.12, 5.9), "RETURN", 32, Color(0.72, 0.62, 0.34))
	_sign(Vector3(0, 1.12, 5.9), "RETAIN", 32, Color(0.72, 0.62, 0.34))
	_sign(Vector3(2.7, 1.12, 5.9), "REMOVE", 32, Color(0.72, 0.62, 0.34))
	for x in [-2.6, 2.6]:
		for z in [9.0, 11.0, 13.0]:
			_file_cabinet(Vector3(x, 0.0, z))
	_desk(Vector3(0, 0.0, 13.2), Vector3(3.0, 1.04, 1.0))
	_sign(Vector3(0, 1.28, 12.65), "NO MANAGER ON DUTY", 28, Color(0.72, 0.18, 0.12))

func _build_lobby() -> void:
	_shell("EXIT DIRECTORY", "Every name is now DOOR or OCCUPANT.")
	_box(Vector3(-2.55, 1.0, 4.2), Vector3(2.1, 2.0, 0.35), _wood)
	_sign(Vector3(-2.55, 1.25, 3.98), "DIRECTORY\n401  —\n402  —\nYOU  —", 28, Color(0.7, 0.78, 0.7))
	for row in 3:
		for column in 4:
			_box(
				Vector3(1.7 + column * 0.48, 0.45 + row * 0.45, 4.2),
				Vector3(0.4, 0.34, 0.34),
				_metal
			)
	_socket_stand(Vector3(-2.4, 0.0, 6.8), "ELEVATOR\nSOCKET")
	_socket_stand(Vector3(2.4, 0.0, 8.8), "MAILBOX\nSOCKET", true)
	_socket_stand(Vector3(0, 0.0, 11.0), "EXIT\nSOCKET")
	_door(Vector3(-1.5, 1.05, 14.8), "EXIT")
	_door(Vector3(1.5, 1.05, 14.8), "EXIT")
	_figure(Vector3(2.6, 0.0, 12.2))

func mark_present_room() -> void:
	var present := get_node_or_null("PresentDoor")
	if present is Label3D:
		(present as Label3D).text = "PRESENT 401"
		(present as Label3D).modulate = Color(0.98, 0.86, 0.42)
		(present as Label3D).font_size = 38
	var elevator := get_node_or_null("ElevatorSign")
	if elevator is Label3D:
		(elevator as Label3D).text = "ELEVATOR\n4   5   B?"
	var glow := OmniLight3D.new()
	glow.name = "PresentGlow"
	glow.position = Vector3(3.2, 1.4, 7.5)
	glow.light_color = Color(0.95, 0.78, 0.35)
	glow.light_energy = 2.4
	glow.omni_range = 3.5
	add_child(glow)

func show_waiting_tenant() -> void:
	if get_node_or_null("WaitingTenant"):
		return
	_figure(Vector3(0.8, 0.0, 12.4), "WaitingTenant")
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.8, 1.6, 12.4)
	glow.light_color = Color(0.55, 0.7, 0.85)
	glow.light_energy = 1.6
	glow.omni_range = 3.2
	add_child(glow)

func set_circuit(which: String) -> void:
	for light in get_tree().get_nodes_in_group("campaign_light"):
		if light is OmniLight3D:
			var name_l := str(light.name).to_lower()
			var is_station := name_l.begins_with("circuit_")
			var on := false
			if which == "hall" and not is_station:
				on = true
			elif is_station and which != "" and name_l == "circuit_" + which:
				on = true
			elif not is_station and which == "":
				on = true
			(light as OmniLight3D).light_energy = (2.15 if on else 0.08)
			(light as OmniLight3D).light_color = (
				Color(0.78, 0.88, 1.0) if on else Color(0.28, 0.1, 0.07)
			)
	for marker in get_tree().get_nodes_in_group("circuit_marker"):
		if marker is MeshInstance3D:
			var live := which != "" and str(marker.name).to_lower() == "marker_" + which
			marker.material_override = CampaignMaterials.emissive(
				Color(0.85, 0.35, 0.12) if live else Color(0.28, 0.1, 0.08),
				0.7 if live else 0.08
			)

func _station(pos: Vector3, label: String, circuit: String) -> void:
	_box(pos + Vector3(0, 0.85, 0), Vector3(1.5, 1.7, 0.55), _metal)
	_box(pos + Vector3(0, 0.95, -0.28), Vector3(1.1, 0.9, 0.08), _dark, false)
	_sign(pos + Vector3(0, 1.55, -0.34), label, 28, Color(0.82, 0.32, 0.2))
	var marker := MeshInstance3D.new()
	marker.name = "marker_" + circuit
	var bulb := SphereMesh.new()
	bulb.radius = 0.1
	bulb.height = 0.2
	marker.mesh = bulb
	marker.material_override = CampaignMaterials.emissive(Color(0.28, 0.1, 0.08), 0.08)
	marker.position = pos + Vector3(0, 1.95, -0.05)
	marker.add_to_group("circuit_marker")
	add_child(marker)
	_station_light(circuit, pos + Vector3(0, 1.9, -0.2))

func _elevator(pos: Vector3) -> void:
	_box(pos + Vector3(0, 1.15, 0.1), Vector3(2.6, 2.3, 0.9), _metal)
	_box(pos + Vector3(0, 1.15, -0.38), Vector3(1.45, 1.9, 0.06), _dark, false)
	_box(pos + Vector3(-0.85, 1.3, -0.42), Vector3(0.18, 0.55, 0.08), _metal, false)
	_box(pos + Vector3(-0.85, 1.3, -0.48), Vector3(0.12, 0.45, 0.02), CampaignMaterials.emissive(Color(0.45, 0.55, 0.4), 0.25), false)

func _door(pos: Vector3, label: String) -> void:
	var side := absf(pos.x) >= 3.5
	var size := Vector3(0.14, 2.1, 1.05) if side else Vector3(1.05, 2.1, 0.14)
	_box(pos, size, _wood)
	# Frame
	if side:
		_box(pos + Vector3(0, 1.12, 0), Vector3(0.2, 0.1, 1.18), _trim, false)
		_box(pos + Vector3(0, -1.05, 0), Vector3(0.2, 0.1, 1.18), _trim, false)
	else:
		_box(pos + Vector3(0, 1.12, 0), Vector3(1.18, 0.1, 0.2), _trim, false)
		_box(pos + Vector3(0, -1.05, 0), Vector3(1.18, 0.1, 0.2), _trim, false)
	# Handle
	var handle_offset := Vector3(-0.08, 0.0, 0.35) if side and pos.x > 0 else Vector3(0.08, 0.0, 0.35)
	if not side:
		handle_offset = Vector3(0.38, 0.0, -0.08)
	elif pos.x < 0:
		handle_offset = Vector3(0.08, 0.0, -0.35)
	_box(pos + handle_offset, Vector3(0.04, 0.12, 0.04), _metal, false)
	var face := Vector3(0, 0.4, -0.1)
	var yaw := PI
	if pos.x <= -3.5:
		face = Vector3(0.1, 0.4, 0)
		yaw = PI * 0.5
	elif pos.x >= 3.5:
		face = Vector3(-0.1, 0.4, 0)
		yaw = -PI * 0.5
	var plate := _sign(pos + face, label, 32, Color(0.82, 0.7, 0.5))
	plate.rotation.y = yaw

func _console(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.35, 0), Vector3(1.4, 0.7, 0.55), _wood)
	_box(pos + Vector3(0, 0.72, -0.05), Vector3(1.1, 0.05, 0.4), _metal, false)

func _desk(pos: Vector3, size: Vector3) -> void:
	_box(pos + Vector3(0, size.y * 0.5, 0), size, _wood)
	_box(pos + Vector3(-size.x * 0.42, 0.18, -size.z * 0.35), Vector3(0.08, 0.36, 0.08), _trim, false)
	_box(pos + Vector3(size.x * 0.42, 0.18, -size.z * 0.35), Vector3(0.08, 0.36, 0.08), _trim, false)
	_box(pos + Vector3(-size.x * 0.42, 0.18, size.z * 0.35), Vector3(0.08, 0.36, 0.08), _trim, false)
	_box(pos + Vector3(size.x * 0.42, 0.18, size.z * 0.35), Vector3(0.08, 0.36, 0.08), _trim, false)

func _file_cabinet(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.9, 0), Vector3(1.45, 1.8, 0.62), _metal)
	for i in 3:
		_box(pos + Vector3(0, 0.35 + i * 0.5, -0.32), Vector3(1.25, 0.38, 0.04), _dark, false)
		_box(pos + Vector3(0, 0.35 + i * 0.5, -0.35), Vector3(0.18, 0.04, 0.04), _metal, false)

func _cabinet(pos: Vector3, label: String) -> void:
	_box(pos + Vector3(0, 0.55, 0), Vector3(1.15, 1.1, 0.55), _metal)
	_box(pos + Vector3(0, 0.55, -0.28), Vector3(0.9, 0.8, 0.04), _dark, false)
	_sign(pos + Vector3(0, 1.25, -0.32), label, 22, Color(0.72, 0.62, 0.4))

func _archive_rack(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.7, 0), Vector3(2.4, 1.4, 0.8), _metal)
	_box(pos + Vector3(0, 0.85, -0.35), Vector3(1.8, 0.9, 0.08), _dark, false)
	_sign(pos + Vector3(0, 1.05, -0.48), "COMPLAINT ARCHIVE\n02:17", 24, Color(0.62, 0.72, 0.62))
	# Reel
	var reel := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.22
	cyl.height = 0.08
	reel.mesh = cyl
	reel.material_override = _wood
	reel.position = pos + Vector3(0.35, 0.85, -0.42)
	reel.rotation.x = PI * 0.5
	add_child(reel)

func _socket_stand(pos: Vector3, label: String, wood := false) -> void:
	_box(pos + Vector3(0, 0.55, 0), Vector3(1.2, 1.1, 0.4), _wood if wood else _metal)
	_box(pos + Vector3(0, 0.7, -0.18), Vector3(0.7, 0.45, 0.05), _dark, false)
	_sign(pos + Vector3(0, 1.2, -0.25), label, 22, Color(0.55, 0.7, 0.7))

func _pipe(pos: Vector3, length: float) -> void:
	var pipe := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.11
	cylinder.bottom_radius = 0.11
	cylinder.height = length
	pipe.mesh = cylinder
	pipe.material_override = _metal
	pipe.position = pos
	pipe.rotation.x = PI * 0.5
	add_child(pipe)
	# Hangers
	for side in [-1.0, 1.0]:
		_box(pos + Vector3(0, 0.18, side * length * 0.28), Vector3(0.08, 0.2, 0.08), _metal, false)

func _fixture(pos: Vector3) -> void:
	var shade := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.18
	cylinder.bottom_radius = 0.32
	cylinder.height = 0.1
	shade.mesh = cylinder
	shade.material_override = _accent
	shade.position = pos
	add_child(shade)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.03
	stem_mesh.bottom_radius = 0.03
	stem_mesh.height = 0.18
	stem.mesh = stem_mesh
	stem.material_override = _metal
	stem.position = pos + Vector3(0, 0.12, 0)
	add_child(stem)
	var light := OmniLight3D.new()
	light.name = "ceiling_%d" % int(pos.z)
	light.position = pos - Vector3(0, 0.18, 0)
	light.light_color = Color(0.95, 0.75, 0.48)
	light.light_energy = 1.55
	light.omni_range = 6.0
	light.shadow_enabled = false
	light.add_to_group("campaign_light")
	add_child(light)

func _station_light(circuit: String, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "circuit_" + circuit
	light.position = pos
	light.light_color = Color(0.35, 0.12, 0.08)
	light.light_energy = 0.08
	light.omni_range = 4.2
	light.shadow_enabled = false
	light.add_to_group("campaign_light")
	add_child(light)

func _figure(pos: Vector3, node_name := "TenantFigure") -> void:
	var body := MeshInstance3D.new()
	body.name = node_name
	var box := BoxMesh.new()
	box.size = Vector3(0.38, 1.55, 0.28)
	body.mesh = box
	body.material_override = _dark
	body.position = pos + Vector3(0, 0.95, 0)
	add_child(body)
	var shoulders := MeshInstance3D.new()
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(0.55, 0.22, 0.22)
	shoulders.mesh = shoulder_mesh
	shoulders.material_override = _dark
	shoulders.position = Vector3(0, 0.55, 0)
	body.add_child(shoulders)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	head.mesh = sphere
	head.material_override = _dark
	head.position = Vector3(0, 0.98, 0)
	body.add_child(head)

func _sign(pos: Vector3, text: String, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.004
	label.width = 900
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = 0.0 if pos.z < 0.0 else PI
	UiFont.apply_3d(label)
	add_child(label)
	return label

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
