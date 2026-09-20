extends StaticBody3D

## The bathroom mirror. In Across the Hall this was a metallic box; here it is a
## mirror-shaped surface carrying a rendered plate of the neighbour — the woman across
## the hall, the life you did not claim standing in it — and she moves only while you
## stand still.
##
## The plate is gated art (assets/plates_x/cg_mirror.png, absent from every web pack).
## What ships is the censored partner; the real bytes arrive through scripts/unlock.gd
## against a gateway ticket, after the page's gate says a sponsor creative rendered.

const SLOT := "cg_mirror"

@export var prompt := "Look in the mirror"
## Which way the glass faces. 402 is 401 mirrored in x, so it cannot be assumed to be +x.
@export var face_x := 1.0

var quad: MeshInstance3D
var steam: MeshInstance3D
var mat: StandardMaterial3D
var glass: MeshInstance3D
var kept := true
var unlocked := false
var sway_t := 0.0
var still_t := 0.0
var base_pos := Vector3.ZERO
var looked := false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mirror")
	collision_layer = 1
	collision_mask = 0
	var sx := signf(face_x)
	# A bezel with an actual rebate, built as four sides rather than one slab, so the
	# plate sits INSIDE a recess and the frame crops its edges. The first pass hung a
	# 0.43x0.68 quad in front of a 0.45x0.70 slab: every edge of the render was visible,
	# which is what made it read as a photograph taped to the wall.
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.13, 0.07, 0.1)
	fm.metallic = 0.55
	fm.roughness = 0.34
	# The opening is 0.44 x 0.66 and the plate quad behind it is 0.48 x 0.70, so every edge
	# of the render is under a rail or a stile by 20 mm. That overlap is the whole trick:
	# a plate whose own border is visible reads as a picture ON the wall no matter how well
	# it is lit.
	for side in [
		{"p": Vector3(0, 0.355, 0), "s": Vector3(0.07, 0.05, 0.6)},    # top rail
		{"p": Vector3(0, -0.355, 0), "s": Vector3(0.07, 0.05, 0.6)},   # bottom rail
		{"p": Vector3(0, 0, 0.245), "s": Vector3(0.07, 0.76, 0.05)},   # near stile
		{"p": Vector3(0, 0, -0.245), "s": Vector3(0.07, 0.76, 0.05)},  # far stile
	]:
		var r := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = side["s"]
		r.mesh = rb
		r.position = side["p"]
		r.material_override = fm
		add_child(r)
	# The glass, set back behind the bezel face. Dark and sharp: it is what the plate is
	# seen *through*, and what is left when the choice empties it.
	glass = MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.025, 0.72, 0.5)
	glass.mesh = gb
	glass.position.x = sx * -0.012
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.05, 0.025, 0.045)
	gm.metallic = 0.92
	gm.roughness = 0.06
	glass.material_override = gm
	add_child(glass)
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.48, 0.70)
	quad.mesh = qm
	quad.rotation.y = sx * PI * 0.5
	quad.position.x = sx * 0.004
	mat = StandardMaterial3D.new()
	# Lit, not unshaded. An unshaded plate is drawn at full brightness no matter how dark
	# the room is, which is exactly the "floating" read — the figure has to be standing in
	# the same light as the tiles around it. Emission carries it in the dark without
	# letting it ignore the bulb.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.82, 0.79, 0.83, 0.97)
	mat.roughness = 0.8
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.05
	quad.material_override = mat
	add_child(quad)
	base_pos = quad.position
	_steam(sx)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.4, 0.9, 0.7)
	col.shape = sh
	add_child(col)
	# No Label3D tag. The HUD already prints "E / click  Look in the mirror" along the
	# bottom, and the billboard copy of it landed dead centre of frame on top of the
	# title card — two pieces of text in the same 80 px, neither readable.
	_load_plate()

## Condensation on the glass, in front of the plate: a breath of haze that belongs to a
## bathroom with the light left on, and the thing that makes the plate read as behind
## glass rather than printed on the wall.
func _steam(sx: float) -> void:
	steam = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.44, 0.66)
	steam.mesh = qm
	steam.rotation.y = sx * PI * 0.5
	steam.position.x = sx * 0.016
	var img := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		for x in 64:
			var dx := (x - 32) / 32.0
			var dy := (y - 48) / 48.0
			# Heavier at the edges, clear in the middle — wiped, or breathed around.
			var edge := clampf((dx * dx + dy * dy) * 0.9 - 0.12, 0.0, 1.0)
			var mott := 0.35 + 0.65 * float((x * 13 + y * 7) % 11) / 11.0
			img.set_pixel(x, y, Color(0.92, 0.84, 0.86, edge * 0.5 * mott))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1, 1, 1, 0.3)
	steam.material_override = m
	add_child(steam)


## The plate chain, the same shape as play/overnight-clause/scripts/plates.gd pick():
## real bytes if this install has them (paid package, or a redeemed ticket), else the
## censored partner. Nothing in this file can draw the figure itself.
func _load_plate() -> void:
	var tex: Texture2D = null
	var src := Unlock.source_for(SLOT)
	if src != "":
		if src.begins_with("res://") and ResourceLoader.exists(src):
			tex = load(src)
		else:
			tex = Unlock.decode_delivered(src)
	unlocked = tex != null
	if tex == null:
		var locked := "res://assets/plates/%s_locked.png" % SLOT
		if ResourceLoader.exists(locked):
			tex = load(locked)
	mat.albedo_texture = tex
	# Emission carries the same image, not a flat wash, so the figure stays readable in a
	# near-dark room without being lit from nowhere.
	mat.emission_texture = tex
	quad.visible = tex != null
	if steam:
		steam.visible = tex != null


func _process(delta: float) -> void:
	if not kept:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	var moving := player != null and Vector2(player.velocity.x, player.velocity.z).length() > 0.25
	if moving:
		still_t = 0.0
	else:
		still_t += delta
	# It moves only while you do not. The first half-second of stillness it is frozen,
	# then it leans, breathes, drifts a hand's width along the glass.
	if still_t > 0.5:
		sway_t += delta
		var k := clampf((still_t - 0.5) / 1.5, 0.0, 1.0)
		quad.position = base_pos + Vector3(0.0, sin(sway_t * 1.1) * 0.02 * k, sin(sway_t * 0.7) * 0.05 * k)
		quad.rotation.z = sin(sway_t * 0.5) * 0.06 * k
		mat.albedo_color.a = 0.96
	else:
		quad.position = base_pos
		quad.rotation.z = 0.0


func interact(game: Node) -> void:
	if game.has_method("look_in_mirror"):
		game.look_in_mirror(self)


## Web only: the page's gate (a sponsor creative that actually rendered) and then the
## gateway ticket. A gate that "succeeds" without bytes leaves the censored plate up.
func try_unlock(unlock: Node) -> bool:
	if unlocked:
		return true
	if not Gate.is_web():
		return false
	var started: bool = await unlock.start(SLOT)
	var ok: bool = await Gate.require(SLOT, "The mirror", "cg")
	if not ok or not started:
		return false
	var landed: bool = await unlock.redeem(SLOT)
	if landed:
		_load_plate()
	return landed


## The choice's consequence. Keep: the figure stays. Refuse: the glass goes black and
## the mirror is a mirror again — it shows nothing, because there is no camera body.
func set_kept(keep: bool) -> void:
	kept = keep
	if not keep:
		var tw := create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 2.4)
		tw.tween_callback(func(): quad.visible = false)
