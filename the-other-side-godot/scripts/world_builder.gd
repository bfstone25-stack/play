extends Node3D

## Built with MeshInstance3D + lights + decals + dust, not a black CSG cave.
## The Other Side: the same two flats as Across the Hall (402 is 401 mirrored in x), on the
## night palette (ops/adult_forks/UI_DIRECTION.md) — plum ground, hot accents. Each room of
## 402 holds one real thing where 401 holds a primitive.

## Albedo is the *unlit* colour, and these went round the houses twice.
##
## The first pass used a mid mauve (0.50/0.36/0.44) under a saturated magenta bulb and the
## screen came out a flat hot pink with no dark in it. The correction took the grounds to
## plum-black — and then ops/check_brightness.py, against the cached Nutaku top-100, said
## every frame of the game sat at 0.06-0.16 brightness and 0.68-0.92 saturation where the
## shelf reads 0.63 / 0.38. Both passes failed the same test from opposite ends: one hue,
## everywhere, doing all the work.
##
## So: surfaces are LIGHTER and LESS saturated than either attempt, the colour comes from
## the lights rather than from the paint, and the darkness is spent where it means
## something — the unlit half of the bathroom, the far end of the hall — instead of on
## wallpaper. UI_DIRECTION.md's "dark ground, hot accents" is a scene, not a basis.
##
## Third pass, 2026-09-19. The second pass was tuned to ops/check_brightness.py's 0.45
## floor applied to every capture, and hitting that floor took the flats from 02:17 to a
## warm lit interior — a horror game at two in the morning with the big light on. Blaze
## has since split the rule: the floor is for STORE ART and TITLE SCREENS, which compete
## as thumbnails, and an in-game frame answers to legibility instead
## (`check_brightness.py --scene`, 0.22/0.18). So the grounds come back down toward
## plum-black and the room is lit by ONE source with the doorway spill doing the work.
## The principle above survives unchanged: the colour still comes from the lights, the
## darkness is still spent where it means something. There is simply less light.
const WALL := Color(0.29, 0.25, 0.275)
const FLOOR := Color(0.2, 0.13, 0.15)
const WOOD := Color(0.24, 0.15, 0.1)
# Tile is the one surface the bathroom bulb hits square on, so it carries the highlight —
# and it stays COOL, or a warm bulb on a warm tile renders the bathroom as brown wood.
const TILE := Color(0.4, 0.43, 0.5)
const TRIM := Color(0.35, 0.28, 0.19)

var _plaster: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood: StandardMaterial3D
var _tile: StandardMaterial3D
var _trim: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_build()
	_dust()
	if OS.has_feature("web"):
		_compat_trim()

## The web build renders on GL compatibility, and it is not the same picture.
##
## Compat has no SSAO and no glow, and — the part that actually breaks the frame — its
## light falloff is softer and it has no bloom to absorb a highlight. The energies tuned
## against the desktop renderer arrive here as blown pools: the 2026-09-19 web capture of
## the beat-1 mirror is a single white ellipse across the bathroom wall with the mirror
## somewhere underneath it, and every flat reads as one hot pink.
##
## So the web build trims its own lights rather than the two builds keeping two copies of
## the numbers. The scale is deliberately not applied to `base_energy` alone: game.gd's
## _dim_hall() multiplies against that meta, so the meta has to come down with it or the
## first dim puts the energy straight back up.
func _compat_trim() -> void:
	for c in get_children():
		if not (c is Light3D):
			continue
		var l := c as Light3D
		l.light_energy *= 0.55
		if l.has_meta("base_energy"):
			l.set_meta("base_energy", float(l.get_meta("base_energy")) * 0.55)
		# Tighter falloff as well as less of it: on compat a pool that is merely dimmer is
		# still a pool the size of the wall, and "one light source, the doorway spill doing
		# the work" is a shape before it is a brightness.
		if l is OmniLight3D:
			(l as OmniLight3D).omni_attenuation = 1.8
		elif l is SpotLight3D:
			(l as SpotLight3D).spot_attenuation = 1.7

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

## Plaster. The noise has to be ISOTROPIC or the walls do not read as plaster.
##
## The first version summed (x*19 + y*11) % 23 with an xor term, and both of those are
## linear in x and y, so their level sets are straight diagonal lines: the texture was a
## diagonal corduroy. Stretched across a 7 m wall at uv 1.6 and then mipmapped, it
## photographed as brushed wood panelling, which is why the flat looked like a sauna.
## A hash of the coordinates has no preferred direction, and a tighter uv scale keeps the
## grain at plaster size instead of smearing it the length of the room.
func _plaster_mat() -> StandardMaterial3D:
	var dim := 128 if OS.has_feature("web") else 256
	var img := Image.create(dim, dim, false, Image.FORMAT_RGB8)
	for y in dim:
		for x in dim:
			var h := (x * 374761393 + y * 668265263) & 0x7fffffff
			h = (h ^ (h >> 13)) * 1274126177
			var fine := float((h >> 8) & 255) / 255.0
			# A smooth two-frequency mottle rather than a second hash: hashing a shifted
			# coordinate quantises into visible 8 px squares, which read as mosaic tiling
			# across a whole wall. The product of two sines at different frequencies in x
			# and y has no straight level sets and no blocks.
			var mott := sin(x * 0.051 + 1.7) * sin(y * 0.043) + 0.5 * sin(x * 0.017) * sin(y * 0.023 + 0.9)
			var n := (fine - 0.5) * 0.05 + mott * 0.035
			var c := Color(
				clampf(WALL.r + n, 0.0, 1.0),
				clampf(WALL.g + n * 0.9, 0.0, 1.0),
				clampf(WALL.b + n * 0.75, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	return _tex_from(img, 0.95, Vector3(3.4, 3.0, 3.4))

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
	# Near-isotropic. The old (2.2, 0.45, 6.0) stretched the texture thirteen times harder
	# along one axis than the other, and on a floor box that is one long smear from wall to
	# wall — the planks are in the texture already and do not need the UVs to make them.
	return _tex_from(img, rough, Vector3(1.9, 1.9, 1.9))

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
	return _tex_from(img, 0.35, Vector3(2.4, 2.4, 2.4))

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
	_closed_door(Vector3(1.62, 1.08, 8.05), -PI * 0.5, "402")

	# Apartment 402
	_box(Vector3(5.3, -0.05, 8.05), Vector3(7.4, 0.1, 8.6), _floor_mat)
	_box(Vector3(5.3, 2.62, 8.05), Vector3(7.4, 0.12, 8.6), _plaster)
	_box(Vector3(5.3, 1.3, 3.8), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(5.3, 1.3, 12.25), Vector3(7.4, 2.7, 0.18), _plaster)
	_box(Vector3(8.9, 1.3, 8.05), Vector3(0.18, 2.7, 8.6), _plaster)
	# 402's bathroom is 401's mirrored in x: outer wall inner face 8.81, interior toward -x.
	_bathroom(8.81, -1.0, 10.43, 12.16, false)
	_box(Vector3(6.02, 1.3, 10.43), Vector3(1.55, 2.7, 0.14), _plaster)
	_box(Vector3(6.7, 1.3, 5.65), Vector3(2.9, 2.7, 0.14), _plaster)

	_window(Vector3(8.78, 1.5, 8.05))
	_couch(Vector3(5.9, 0.32, 6.35))
	_table(Vector3(3.25, 0.38, 8.05))
	_shoes(Vector3(2.25, 0.06, 8.05))
	_wardrobe(Vector3(3.55, 1.05, 4.85))
	_print(Vector3(4.4, 1.35, 4.05))
	_sign(Vector3(-1.52, 1.55, 6.2), "Do not knock after midnight")
	_wet(Vector3(7.4, 0.03, 10.6))
	_wet(Vector3(5.1, 0.03, 8.9))
	_wet(Vector3(2.6, 0.03, 8.1))

	_apt401()

	# Light, re-weighted to UI_DIRECTION.md's actual rule: most of the frame near-dark, and
	# the accent earned by contrast. The first pass hung a saturated magenta omni at energy
	# 2.0 inside a 1.1 m closet, which is how a night palette became a flat pink wash —
	# nothing dark and, because everything was the accent, nothing hot either.
	#
	# So the flats are lit by one dim warm practical each, and the ONE bright thing in the
	# game is the bulb over the 401 mirror: the bathroom light that is on when it should
	# not be. It is a spot, not an omni, because it is the only light that needs to throw a
	# shadow — the doorway spill is what makes the beat-1 frame read as a room.
	# Bright enough to read the room, which TITLE_SCREENS.md's playfield rule requires:
	# "dark is a choice, not a default". The corrective pass for the pink wash first took
	# these to 0.7-0.95 and the flats went to near-black — legibly dark and actually dark
	# are different pictures, and only the capture can tell you which one you made.
	# Warm white bulbs, not amber and magenta gels. A saturated light on a saturated wall
	# is how every frame came out at 0.8+ saturation in one hue; the magenta survives as
	# ONE fixture at the far end of the hall, where it is a colour note instead of a wash.
	# Energies re-cut for the --scene floor (see the palette note at the top): the hall is
	# a corridor at 02:17 lit by whatever is still on, not a lobby.
	_fixture(Vector3(0, 2.46, 3.2), Color(1.0, 0.78, 0.55), 3.6, 11.0)
	_fixture(Vector3(0, 2.46, 9.4), Color(1.0, 0.58, 0.72), 2.4, 9.0, true)
	_fixture(Vector3(4.6, 2.46, 8.05), Color(1.0, 0.8, 0.6), 4.4, 12.0)
	_fixture(Vector3(-4.6, 2.46, 2.4), Color(1.0, 0.77, 0.56), 3.4, 11.0)
	_bathroom_light(Vector3(-8.25, 2.3, 5.7), Vector3(-8.7, 1.15, 5.7))
	_bathroom_light(Vector3(8.15, 2.3, 11.3), Vector3(8.6, 1.15, 11.3), 0.85)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.4, 0.5, 0.78)
	moon.light_energy = 0.08
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-35, 110, 0)
	add_child(moon)

## The bulb over the mirror: the hot accent, and the only shadow-caster in the game.
## A SpotLight3D rather than an OmniLight3D — omni shadows on a box hall starburst (see
## _fixture), a single downward projection does not, and the cone is what puts a hard
## bar of light through the bathroom doorway and onto the front-room floor.
func _bathroom_light(pos: Vector3, target: Vector3, energy := 1.0) -> void:
	var shade := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.075
	cyl.height = 0.1
	shade.mesh = cyl
	shade.position = pos
	var sm := StandardMaterial3D.new()
	# Dark albedo, bright emission. A pale shade catches the cool fill from below and
	# renders as a blue disc stuck to the ceiling; the fitting should only ever be the
	# light it emits.
	sm.albedo_color = Color(0.16, 0.135, 0.12)
	sm.emission_enabled = true
	sm.emission = Color(1.0, 0.88, 0.78)
	# Kept under the glow threshold set in main.tscn: the bulb should read as a bulb, not
	# as the soft white blob that ate a third of the first frame.
	sm.emission_energy_multiplier = 0.9
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shade)
	var li := SpotLight3D.new()
	li.position = pos + Vector3(0, -0.08, 0)
	# Warm white with the magenta pulled through it, not magenta with a bulb behind it.
	li.light_color = Color(1.0, 0.87, 0.78)
	li.light_energy = 4.6 * energy
	li.spot_range = 6.5
	li.spot_angle = 68.0
	li.spot_angle_attenuation = 0.9
	li.spot_attenuation = 1.1
	li.shadow_enabled = true
	li.shadow_bias = 0.035
	li.shadow_normal_bias = 1.4
	add_child(li)
	# Aimed at the mirror rather than straight down. A vertical mirror under a vertical
	# cone gets grazing light and stays black; leaning the cone into the wall is what puts
	# the room's light ON the plate, which is the difference between a picture seated in
	# the glass and a picture floating in front of it.
	li.look_at(target, Vector3.UP)
	# A weak, shadowless, cool fill so the tiles the spot does not reach are dark rather
	# than absent. Without it the bathroom is a lit mirror floating in a black void: the
	# spot is a narrow cone and nothing else in the room bounces.
	var fill := OmniLight3D.new()
	fill.position = pos + Vector3(0, -0.9, 0)
	fill.light_color = Color(0.58, 0.66, 0.95)
	fill.light_energy = 0.6 * energy
	fill.omni_range = 3.4
	fill.omni_attenuation = 1.4
	fill.shadow_enabled = false
	fill.set_meta("base_energy", 0.6 * energy)
	fill.add_to_group("hall_light")
	add_child(fill)

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
	# 401's bathroom: outer wall inner face -8.91, interior toward +x. The one with the plate.
	_bathroom(-8.91, 1.0, 4.78, 6.61, true)
	_box(Vector3(-6.12, 1.3, 4.78), Vector3(1.55, 2.7, 0.14), _plaster)
	_box(Vector3(-6.7, 1.3, 0.0), Vector3(2.9, 2.7, 0.14), _plaster)
	_window(Vector3(-8.78, 1.5, 2.4))
	_couch(Vector3(-5.9, 0.32, 0.7))
	_table(Vector3(-3.25, 0.38, 2.4))
	_shoes(Vector3(-2.25, 0.06, 2.4))
	_wardrobe(Vector3(-3.55, 1.05, -0.8))
	_sign(Vector3(-4.4, 1.35, -1.65), "401 · YOU LIVE HERE")
	_wet(Vector3(-7.4, 0.03, 5.0))
	_wet(Vector3(-3.4, 0.03, 2.5))
	_stain(Vector3(-6.2, 0.02, 3.6), Vector3(1.1, 1, 0.8))

func open_401() -> void:
	open_door("401")

func open_door(label: String) -> void:
	if has_meta("apt%s_open" % label):
		return
	set_meta("apt%s_open" % label, true)
	for n in get_tree().get_nodes_in_group("door_%s_solid" % label):
		n.visible = false
		_disable_colliders(n)
	if label == "401":
		_open_door(Vector3(-1.62, 1.08, 2.4), "401", -1.0)
	else:
		_open_door(Vector3(1.62, 1.08, 8.05), "402", 1.0)

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
	mi.add_to_group("door_%s_solid" % label)
	add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.07, 2.12, 0.92)
	col.shape = sh
	body.add_child(col)
	body.set_script(preload("res://scripts/door.gd"))
	body.set("prompt", "Open 401" if label == "401" else "Knock at 402")
	body.set("kind", label)
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
	li.omni_attenuation = 1.0
	# Omni dual-paraboloid shadows on box halls look like starbursts.
	li.shadow_enabled = false
	# game._dim_hall() scales against this rather than assigning an absolute, so dimming
	# the hall no longer flattens every fixture in the building to one energy.
	li.set_meta("base_energy", energy)
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
	m.albedo_color = Color(0.04, 0.055, 0.085, 0.72)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	# The window is the only cool thing in the flat and it must stay the SECOND brightest.
	# At 0.45 on compat it renders as a pale blue panel that out-shouts the bathroom bulb,
	# which makes the one light source two and takes the doorway spill out of the frame.
	m.emission = Color(0.08, 0.13, 0.27)
	m.emission_energy_multiplier = 0.2
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

## The bathroom, built as a room you can stand in and see.
##
## It used to be a 1.14 m closet with the mirror 0.7 m from your face and no doorway
## header, so the beat-1 frame was a wall with a picture on it — the "there is no room"
## complaint. It is now 1.95 m across with a real 1.0 m doorway you look through from the
## front room: jamb, header, tiled floor, a vanity under the mirror. That doorway is what
## gives the shot depth, and it is what the bulb spills through.
##
## `wall_x` is the inner face of the flat's outer wall; `sx` points into the flat (+1 in
## 401, -1 in 402, which is 401 mirrored in x). `z0` is the partition wall, `z1` the back.
const BATH_W := 1.95
const BATH_DOOR := 1.0

func _bathroom(wall_x: float, sx: float, z0: float, z1: float, plate: bool) -> void:
	var zc := (z0 + z1) * 0.5
	var depth := z1 - z0
	# Side wall, floor to ceiling, closing the bathroom off from the rest of the flat.
	_box(Vector3(wall_x + sx * BATH_W, 1.3, zc), Vector3(0.14, 2.7, depth), _plaster)
	# Front partition: a jamb, a 1.0 m opening, a return, and a header over the opening.
	var d0 := 0.72                      # opening starts this far from the outer wall
	var d1 := d0 + BATH_DOOR
	_box(Vector3(wall_x + sx * d0 * 0.5, 1.3, z0), Vector3(d0, 2.7, 0.14), _plaster)
	_box(Vector3(wall_x + sx * (d1 + BATH_W) * 0.5, 1.3, z0), Vector3(BATH_W - d1, 2.7, 0.14), _plaster)
	_box(Vector3(wall_x + sx * (d0 + d1) * 0.5, 2.33, z0), Vector3(BATH_DOOR, 0.64, 0.14), _plaster)
	_box(Vector3(wall_x + sx * (d0 + d1) * 0.5, 0.06, z0), Vector3(BATH_DOOR, 0.12, 0.2), _trim)
	# Tiled floor, actually the size of the room this time.
	_box(Vector3(wall_x + sx * BATH_W * 0.5, 0.02, zc), Vector3(BATH_W - 0.06, 0.04, depth - 0.06), _tile)
	# Tiled splashback behind the vanity, so the wall under the bulb is not bare plaster.
	_box(Vector3(wall_x + sx * 0.03, 1.15, zc), Vector3(0.05, 1.5, depth - 0.3), _tile)
	_vanity(Vector3(wall_x + sx * 0.28, 0.45, zc), sx)
	_mirror(Vector3(wall_x + sx * 0.07, 1.48, zc), plate, sx)
	_toothbrush(Vector3(wall_x + sx * 0.2, 0.96, zc + 0.36))

## A basin on a cabinet, against the outer wall under the mirror. Gives the bulb something
## with a top surface to land on — a lit horizontal is most of what says "room" in a frame.
func _vanity(pos: Vector3, sx: float) -> void:
	_box(pos + Vector3(0, 0.42, 0), Vector3(0.52, 0.06, 1.0), _tile)          # counter
	_box(pos + Vector3(sx * -0.02, 0.06, 0), Vector3(0.46, 0.66, 0.88), _wood) # cabinet
	_box(pos + Vector3(sx * 0.04, 0.47, 0), Vector3(0.34, 0.05, 0.42), _tile)  # basin lip
	var tap := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.018
	cyl.bottom_radius = 0.022
	cyl.height = 0.2
	tap.mesh = cyl
	tap.position = pos + Vector3(sx * -0.16, 0.55, 0)
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.32, 0.3, 0.31)
	tm.metallic = 0.85
	tm.roughness = 0.22
	tap.material_override = tm
	add_child(tap)

func _wardrobe(pos: Vector3) -> void:
	_box(pos, Vector3(0.55, 2.05, 1.15), _wood)
	_box(pos + Vector3(0.3, 0.2, 0), Vector3(0.04, 1.6, 0.5), _wood)

func _toothbrush(pos: Vector3) -> void:
	_box(pos, Vector3(0.08, 0.16, 0.08), _noisy(Color(0.75, 0.75, 0.78), 0.3, Vector3(1, 1, 1), 0.02))
	_box(pos + Vector3(0, 0.14, 0), Vector3(0.02, 0.18, 0.02), _noisy(Color(0.2, 0.45, 0.55), 0.4, Vector3(1, 1, 1), 0.01))

func _mirror(pos: Vector3, plate: bool, sx: float = 1.0) -> void:
	if plate:
		# 401's mirror: the rendered figure on a mirror-shaped surface (scripts/mirror.gd).
		# `sx` is which way the glass faces — 402 is mirrored in x, so it cannot be assumed.
		var m := StaticBody3D.new()
		m.set_script(preload("res://scripts/mirror.gd"))
		m.position = pos
		m.set("face_x", sx)
		add_child(m)
		return
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

## The one real thing in 402's front room, where 401 has a blank sign box: a framed
## print, a rendered plate (assets/plates/obj_402.png) on a quad. Never a code-drawn picture.
func _print(pos: Vector3) -> void:
	_box(pos, Vector3(0.03, 0.62, 1.04), _noisy(Color(0.1, 0.05, 0.08), 0.5, Vector3(1, 1, 1), 0.02))
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.96, 0.54)
	q.mesh = qm
	q.position = pos + Vector3(0.025, 0, 0)
	q.rotation.y = PI * 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.9, 0.82, 0.86)
	if ResourceLoader.exists("res://assets/plates/obj_402.png"):
		m.albedo_texture = load("res://assets/plates/obj_402.png")
	q.material_override = m
	add_child(q)
	var l := Label3D.new()
	l.text = "A photograph of a room you have never been in. It is this room."
	l.font_size = 22
	l.pixel_size = 0.003
	l.modulate = Color(1.0, 0.7, 0.28)
	l.position = pos + Vector3(0.04, -0.42, 0)
	l.rotation.y = PI * 0.5
	UiFont.apply_3d(l)
	add_child(l)

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
