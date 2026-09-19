extends Node3D

## Flat 404 production set: six connected, dressed zones built from standalone
## procedural geometry. Primitives are assembled into readable architecture and
## furniture rather than used as label-only placeholders.

var _plaster: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood: StandardMaterial3D
var _tile: StandardMaterial3D
var _trim: StandardMaterial3D
var _metal: StandardMaterial3D
var _dark: StandardMaterial3D
var _paper: StandardMaterial3D
var _fabric: StandardMaterial3D
var _red: StandardMaterial3D
var _glass: StandardMaterial3D
var zone_names: Array[String] = []

func _ready() -> void:
	_make_materials()
	_refresh_zone_names()
	_build()


func _refresh_zone_names() -> void:
	zone_names = [
		Loc.t("zone.0"), Loc.t("zone.1"), Loc.t("zone.2"),
		Loc.t("zone.3"), Loc.t("zone.4"), Loc.t("zone.5"),
	]


func refresh_locale() -> void:
	_refresh_zone_names()
	for child in get_children():
		if child is Label3D and child.has_meta("loc_key"):
			child.text = Loc.t(str(child.get_meta("loc_key")))

func _make_materials() -> void:
	_plaster = GameMaterials.plaster(Color(0.42, 0.38, 0.32))
	_floor_mat = GameMaterials.planks(Color(0.18, 0.12, 0.08), 0.85)
	_wood = GameMaterials.planks(Color(0.26, 0.14, 0.08), 0.72)
	_tile = GameMaterials.concrete(Color(0.4, 0.42, 0.38), 0.45)
	_trim = GameMaterials.planks(Color(0.32, 0.26, 0.18), 0.6)
	_metal = GameMaterials.metal(Color(0.22, 0.24, 0.23))
	_dark = GameMaterials.flat(Color(0.035, 0.03, 0.025), 1.0)
	_paper = GameMaterials.paper(Color(0.78, 0.72, 0.58))
	_fabric = GameMaterials.carpet(Color(0.16, 0.12, 0.1))
	_red = GameMaterials.carpet(Color(0.28, 0.045, 0.035))
	_glass = GameMaterials.metal(Color(0.12, 0.16, 0.18), 0.18)

func _build() -> void:
	_build_lobby()
	_build_corridor()
	_build_living()
	_build_kitchen()
	_build_bathroom()
	_build_bedroom()
	_fixture(Vector3(-5.2, 2.35, 4.0), Color(0.38, 0.78, 0.46), 1.0, 5.5, true)
	_fixture(Vector3(-1.0, 2.35, 2.0), Color(1.0, 0.66, 0.28), 1.25, 6.5, true)
	_fixture(Vector3(-1.0, 2.35, 8.0), Color(1.0, 0.72, 0.34), 1.0, 5.5, false)
	_fixture(Vector3(4.5, 2.35, 2.4), Color(1.0, 0.72, 0.35), 1.45, 7.0, false)
	_fixture(Vector3(9.4, 2.3, 2.5), Color(0.5, 0.82, 0.32), 0.8, 4.5, true)
	_fixture(Vector3(9.4, 2.3, 7.3), Color(0.35, 0.72, 0.33), 0.72, 4.0, true)
	_fixture(Vector3(4.9, 1.0, 8.2), Color(0.92, 0.24, 0.13), 0.8, 4.5, false)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.35, 0.42, 0.55)
	moon.light_energy = 0.05
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-40, 95, 0)
	add_child(moon)

func _build_lobby() -> void:
	_room_shell(Vector3(-5.2, 0, 4.0), Vector2(3.8, 5.2), _tile)
	# Lift surround, rain window, radiator and stair rail.
	_box(Vector3(-7.0, 1.25, 4.0), Vector3(0.15, 2.5, 5.1), _plaster)
	_box(Vector3(-5.8, 1.15, 1.48), Vector3(1.7, 2.3, 0.12), _metal)
	_box(Vector3(-6.7, 1.15, 1.38), Vector3(.08,2.45,.18), _trim, false)
	_box(Vector3(-4.9, 1.15, 1.38), Vector3(.08,2.45,.18), _trim, false)
	_box(Vector3(-5.8, 2.35, 1.38), Vector3(1.88,.08,.18), _trim, false)
	_box(Vector3(-5.8, 1.15, 1.4), Vector3(0.04, 2.1, 0.06), _dark, false)
	_sign(Vector3(-5.8, 2.05, 1.32), "04")
	_box(Vector3(-6.65, 1.25, 4.6), Vector3(0.08, 1.45, 1.5), _glass, false)
	_box(Vector3(-6.45, 0.5, 6.0), Vector3(0.3, 0.9, 1.4), _metal)
	for z in 4:
		_box(Vector3(-6.25, 0.34 + z * 0.16, 6.0), Vector3(0.45, 0.06, 1.3), _trim)
	_zone_label(Vector3(-5.2, 2.42, 2.0), "zone.0")

func _build_corridor() -> void:
	_box(Vector3(-1.0, -0.05, 5.0), Vector3(4.5, 0.1, 10.0), _floor_mat)
	_box(Vector3(-1.0, 2.55, 5.0), Vector3(4.5, 0.1, 10.0), _plaster)
	_box(Vector3(-3.2, 1.25, 7.5), Vector3(0.16, 2.6, 5.0), _plaster)
	_box(Vector3(1.2, 1.25, 7.7), Vector3(0.16, 2.6, 4.6), _plaster)
	_box(Vector3(-1.0, 1.25, 10.0), Vector3(4.5, 2.6, 0.16), _plaster)
	_box(Vector3(-1.0, 0.015, 5.0), Vector3(1.25, 0.03, 8.8), _red, false)
	for z in [3.0, 5.5, 8.0]:
		_door_leaf(Vector3(-3.08, 1.05, z), str(398 + int(z)))
	_mailboxes(Vector3(-2.95, 1.25, 9.0))
	_open_door_leaf(Vector3(1.08, 1.05, 4.0), "404")
	# Maintenance cart and inspection case sell the working-building setting.
	_box(Vector3(-2.35,.42,1.0), Vector3(.9,.08,.48), _metal)
	_box(Vector3(-2.7,.78,1.0), Vector3(.08,.72,.48), _metal)
	for z in [.82,1.18]:
		_cylinder(Vector3(-2.65,.12,z), .12, .08, _dark, Vector3(90,0,0))
	_zone_label(Vector3(-1.0, 2.42, 6.5), "zone.1")

func _build_living() -> void:
	_room_shell(Vector3(4.4, 0, 3.4), Vector2(6.4, 6.6), _floor_mat)
	# Openings to corridor, kitchen and bedroom are deliberate wall gaps.
	_wall_segments_x(1.2, -0.1, 6.7, [Vector2(3.45, 4.55)])
	_wall_segments_x(7.6, -0.1, 6.7, [Vector2(1.6, 3.2), Vector2(5.7, 6.6)])
	_couch(Vector3(3.7, 0.28, 1.2))
	_table(Vector3(4.1, 0.35, 3.2))
	_lamp(Vector3(2.2, 0.0, 1.2))
	_box(Vector3(5.8, 0.48, 0.35), Vector3(1.5, 0.95, 0.4), _wood)
	_box(Vector3(5.8, 1.18, 0.32), Vector3(1.25, 0.72, 0.08), _dark, false)
	# Television bezel and feet.
	for x in [-.65,.65]:
		_box(Vector3(5.8+x,1.18,.27), Vector3(.06,.82,.1), _metal, false)
	for x in [-.48,.48]:
		_box(Vector3(5.8+x,.83,.15), Vector3(.08,.3,.08), _metal, false)
	_shoe_rack(Vector3(1.8, 0.2, 5.7))
	for i in 4:
		_box(Vector3(6.6, 0.3 + i * 0.5, 4.9), Vector3(0.7, 0.42, 0.7), _paper)
	_calendar(Vector3(4.4, 1.45, 0.14))
	_zone_label(Vector3(4.4, 2.42, 0.4), "zone.2")

func _build_kitchen() -> void:
	_room_shell(Vector3(9.4, 0, 2.45), Vector2(3.6, 4.5), _tile)
	_box(Vector3(11.2, 1.25, 2.45), Vector3(0.16, 2.6, 4.5), _plaster)
	_box(Vector3(9.4, 1.25, 0.2), Vector3(3.6, 2.6, 0.16), _plaster)
	_counter(Vector3(10.5, 0.0, 1.0))
	_counter(Vector3(10.5, 0.0, 3.8))
	# Fridge, sink, taps, cabinets and kettle.
	_box(Vector3(8.3, 0.95, 0.65), Vector3(1.0, 1.9, 0.8), GameMaterials.metal(Color(0.36, 0.4, 0.35)))
	_box(Vector3(8.28,1.38,.23), Vector3(.92,.03,.02), _dark, false)
	_box(Vector3(8.7,1.1,.2), Vector3(.035,.48,.04), _metal, false)
	_box(Vector3(10.5, 1.0, 3.78), Vector3(0.72, 0.06, 0.42), _metal, false)
	_box(Vector3(10.5, 1.18, 3.9), Vector3(0.05, 0.35, 0.05), _metal, false)
	_box(Vector3(9.2, 1.85, 0.35), Vector3(2.8, 0.6, 0.35), _wood)
	for x in [8.35,9.05,9.75,10.45]:
		_box(Vector3(x,1.85,.16), Vector3(.62,.52,.04), _trim, false)
		_cylinder(Vector3(x,1.85,.12), .025, .05, _metal, Vector3(90,0,0))
	_pipe_drip(Vector3(10.85, 0.65, 4.25))
	_zone_label(Vector3(9.4, 2.42, 0.32), "zone.3")

func _build_bathroom() -> void:
	_room_shell(Vector3(9.45, 0, 7.15), Vector2(3.5, 4.2), _tile)
	_box(Vector3(11.2, 1.25, 7.15), Vector3(0.16, 2.6, 4.2), _plaster)
	_box(Vector3(9.45, 1.25, 9.25), Vector3(3.5, 2.6, 0.16), _plaster)
	# Tub, translucent curtain, basin, toilet and service stack.
	_box(Vector3(10.35, 0.35, 8.45), Vector3(1.4, 0.7, 1.05), _paper)
	_box(Vector3(10.35,.68,8.45), Vector3(1.18,.08,.83), _tile, false)
	_cylinder(Vector3(10.72,.86,8.05), .035, .42, _metal)
	_box(Vector3(10.35, 1.45, 7.9), Vector3(1.5, 1.9, 0.03), GameMaterials.flat(Color(0.55, 0.62, 0.48, 0.55)), false)
	_box(Vector3(8.25, 0.48, 8.45), Vector3(0.75, 0.95, 0.8), _paper)
	_cylinder(Vector3(8.25,.84,8.45), .34, .25, _paper)
	_box(Vector3(8.25, 0.95, 8.7), Vector3(0.65, 0.4, 0.18), _paper)
	_box(Vector3(8.3, 0.82, 6.0), Vector3(0.85, 0.12, 0.55), _paper)
	_cylinder(Vector3(8.3,.9,6.0), .22, .1, _metal)
	_box(Vector3(8.3, 1.55, 5.75), Vector3(1.0, 0.85, 0.05), _glass, false)
	_box(Vector3(10.9, 1.1, 7.0), Vector3(0.1, 2.1, 0.1), _metal, false)
	_box(Vector3(10.92, 1.3, 7.35), Vector3(0.6, 0.8, 0.04), _metal)
	_zone_label(Vector3(9.4, 2.42, 9.05), "zone.4")

func _build_bedroom() -> void:
	_room_shell(Vector3(4.45, 0, 8.1), Vector2(6.4, 3.7), _floor_mat)
	_box(Vector3(1.2, 1.25, 8.1), Vector3(0.16, 2.6, 3.7), _plaster)
	_box(Vector3(4.45, 1.25, 9.95), Vector3(6.5, 2.6, 0.16), _plaster)
	_bed(Vector3(3.4, 0.22, 8.45))
	_wardrobe(Vector3(6.65, 1.05, 8.5))
	_table(Vector3(2.0, 0.42, 9.15))
	_box(Vector3(4.4, 1.5, 9.84), Vector3(1.9, 1.25, 0.08), _dark)
	# False wall cavity and exposed pipe.
	_box(Vector3(7.35, 1.1, 8.5), Vector3(0.06, 2.15, 1.6), _dark, false)
	_box(Vector3(7.25, 1.05, 8.5), Vector3(0.08, 2.0, 0.08), _metal, false)
	# Personal objects and scattered photographs around the cavity.
	for i in 5:
		_box(Vector3(6.85 + (i%2)*.18,.18+i*.025,8.0+i*.17), Vector3(.14,.012,.18), _paper, false)
	_zone_label(Vector3(4.5, 2.42, 9.78), "zone.5")

func _room_shell(center: Vector3, footprint: Vector2, floor_mat: Material) -> void:
	_box(Vector3(center.x, -0.05, center.z), Vector3(footprint.x, 0.1, footprint.y), floor_mat)
	_box(Vector3(center.x, 2.55, center.z), Vector3(footprint.x, 0.1, footprint.y), _plaster)

func _wall_segments_x(x: float, z0: float, z1: float, gaps: Array[Vector2]) -> void:
	var cursor := z0
	for gap in gaps:
		if gap.x > cursor:
			_box(Vector3(x, 1.25, (cursor + gap.x) * 0.5), Vector3(0.16, 2.6, gap.x - cursor), _plaster)
		cursor = gap.y
	if cursor < z1:
		_box(Vector3(x, 1.25, (cursor + z1) * 0.5), Vector3(0.16, 2.6, z1 - cursor), _plaster)

func _zone_label(pos: Vector3, key: String) -> void:
	var lab := Label3D.new()
	lab.set_meta("loc_key", key)
	lab.text = Loc.t(key)
	lab.font_size = 18
	lab.modulate = Color(0.48, 0.42, 0.32, 0.55)
	lab.position = pos
	lab.pixel_size = 0.003
	UiFont.apply_3d(lab)
	add_child(lab)

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

func _cylinder(pos: Vector3, radius: float, height: float, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = mat
	add_child(mi)
	return mi

func _door_leaf(pos: Vector3, label: String) -> void:
	_box(pos, Vector3(0.08, 2.05, 0.92), _wood)
	for z in [-.32,.32]:
		_box(pos + Vector3(-.045,.38,z), Vector3(.025,.55,.22), _trim, false)
	_box(pos + Vector3(-0.07, 0.0, 0.32), Vector3(0.07, 0.07, 0.07), _metal, false)
	_box(pos + Vector3(0,0,-.55), Vector3(.16,2.25,.08), _trim, false)
	_box(pos + Vector3(0,0,.55), Vector3(.16,2.25,.08), _trim, false)
	_box(pos + Vector3(0,1.1,0), Vector3(.16,.08,1.18), _trim, false)
	_sign(pos + Vector3(-0.05, 0.55, 0.0), label)

func _open_door_leaf(pos: Vector3, label: String) -> void:
	var leaf := _box(pos + Vector3(0.45, 0, 0.42), Vector3(0.08, 2.05, 0.92), _wood, false)
	leaf.rotation_degrees.y = -62.0
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
	for x in [-.82,.82]:
		_box(pos + Vector3(x,.28,0), Vector3(.18,.5,.78), _fabric, false)
	for x in [-.42,.42]:
		_box(pos + Vector3(x,.25,.06), Vector3(.72,.12,.58), GameMaterials.carpet(Color(.22,.17,.13)), false)

func _table(pos: Vector3) -> void:
	_box(pos, Vector3(0.85, 0.05, 0.55), _wood)
	_box(pos + Vector3(-0.35, -0.2, -0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(0.35, -0.2, -0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(-0.35, -0.2, 0.2), Vector3(0.05, 0.4, 0.05), _wood)
	_box(pos + Vector3(0.35, -0.2, 0.2), Vector3(0.05, 0.4, 0.05), _wood)

func _mailboxes(pos: Vector3) -> void:
	for row in 3:
		for col in 2:
			_box(
				pos + Vector3(0.0, (row - 1) * 0.32, (col - 0.5) * 0.48),
				Vector3(0.16, 0.26, 0.4),
				_metal
			)

func _shoe_rack(pos: Vector3) -> void:
	for shelf in 2:
		_box(pos + Vector3(0, shelf * 0.28, 0), Vector3(0.95, 0.05, 0.38), _wood)
	for x in [-0.28, 0.28]:
		_box(pos + Vector3(x, 0.08, 0), Vector3(0.28, 0.14, 0.52), _dark, false)

func _bed(pos: Vector3) -> void:
	_box(pos, Vector3(2.2, 0.38, 1.35), _wood)
	_box(pos + Vector3(0, 0.25, 0), Vector3(2.05, 0.25, 1.25), _fabric)
	_box(pos + Vector3(-0.7, 0.43, 0), Vector3(0.55, 0.15, 1.05), _paper, false)
	_box(pos + Vector3(1.05, 0.55, 0), Vector3(0.1, 1.15, 1.45), _wood)

func _wardrobe(pos: Vector3) -> void:
	_box(pos, Vector3(1.05, 2.1, 1.45), _wood)
	_box(pos + Vector3(-0.53, 0, 0), Vector3(0.04, 1.9, 1.25), _dark, false)
	_box(pos + Vector3(-0.57, 0.1, -0.3), Vector3(0.08, 0.08, 0.08), _metal, false)

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
	lab.set_meta("loc_key", "world.tonight")
	lab.text = Loc.t("world.tonight")
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
	for x in [-.58,0,.58]:
		_box(pos + Vector3(x,.46,-.29), Vector3(.53,.76,.035), _trim, false)
		_cylinder(pos + Vector3(x+.18,.46,-.32), .025, .04, _metal, Vector3(90,0,0))

func _pipe_drip(pos: Vector3) -> void:
	_box(pos, Vector3(0.08, 0.9, 0.08), _metal, false)
	_box(pos + Vector3(-0.15, -0.52, 0.1), Vector3(0.55, 0.02, 0.4), GameMaterials.flat(Color(0.12, 0.02, 0.02), 0.95), false)
	var drip_mat: StandardMaterial3D = GameMaterials.emissive(Color(0.45, 0.08, 0.06), 0.25)
	_box(pos + Vector3(0, -0.2, 0.06), Vector3(0.04, 0.12, 0.04), drip_mat, false)
	for i in 7:
		_box(pos + Vector3(-.2 + (i%3)*.16,-.5, -.05+i*.09), Vector3(.12,.008,.22), GameMaterials.flat(Color(.14,.018,.012), .95), false)

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

func stage_event(stage: int, flags: Dictionary) -> void:
	if stage == 5:
		# Wet footprints lead from tub toward the bedroom, readable without UI.
		for i in 5:
			var print := _box(Vector3(9.7-i*.62,.012,7.9-i*.28), Vector3(.18,.012,.34), GameMaterials.flat(Color(.16,.025,.018), .9), false)
			print.rotation_degrees.y = -18.0 if i % 2 == 0 else 18.0
	if stage == 7:
		if flags["pipe_answered"]:
			_fixture(Vector3(6.9,1.2,8.5), Color(.55,.08,.045), 1.2, 3.2, true)
		else:
			for child in get_children():
				if child is Light3D and (child as Node3D).position.x > 7.5:
					(child as Light3D).light_energy *= .35
	if stage == 9:
		# One controlled peripheral reveal, framed by the apartment doorway.
		_box(Vector3(.25,.9,4.02), Vector3(.22,1.8,.38), _dark, false)
		_cylinder(Vector3(.25,1.92,4.02), .16,.3,_dark)
	if stage == 11 and flags["clause_refused"]:
		_sign(Vector3(1.02,1.72,4.0), "40_")

func apply_ending(id: String) -> void:
	# Each ending changes the physical set behind the authored card sequence.
	match id:
		"WITNESS":
			var dawn := DirectionalLight3D.new()
			dawn.light_color = Color(1.0, 0.62, 0.32)
			dawn.light_energy = 1.15
			dawn.rotation_degrees = Vector3(-28, -72, 0)
			add_child(dawn)
			_sign(Vector3(1.02, 1.72, 4.0), Loc.t("world.iris"))
			# Iris: deliberate obscured silhouette behind service pipework.
			_box(Vector3(10.55, 0.85, 7.65), Vector3(0.55, 1.7, 0.3), _dark, false)
			_box(Vector3(10.55, 1.85, 7.65), Vector3(0.32, 0.32, 0.28), _dark, false)
		"COMPLICIT":
			for child in get_children():
				if child is Light3D:
					(child as Light3D).light_energy *= 0.28
			_fixture(Vector3(4.4, 2.2, 3.4), Color(0.96, 0.92, 0.82), 2.4, 9.0, false)
			for i in 5:
				_box(Vector3(5.8, 1.0 + (i % 2) * 0.42, 0.25 + i * 0.12), Vector3(0.3, 0.36, 0.04), _paper, false)
		_:
			for child in get_children():
				if child is Light3D:
					(child as Light3D).light_color = Color(0.18, 0.32, 0.46)
			_sign(Vector3(1.02, 1.72, 4.0), "403")
			# Brick over the lift aperture.
			for row in 5:
				for col in 4:
					_box(
						Vector3(-5.8 + (col - 1.5) * 0.4, 0.25 + row * 0.42, 1.32),
						Vector3(0.36, 0.18, 0.16),
						_red,
						false
					)
