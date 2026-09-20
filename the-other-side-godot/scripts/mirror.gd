extends StaticBody3D

## The bathroom mirror. In Across the Hall this was a metallic box; here it is a
## mirror-shaped surface carrying a rendered plate of the neighbour — the half of you
## that claimed what it wanted — and the figure moves only while you stand still.
##
## The plate is gated art (assets/plates_x/cg_mirror.png, absent from every web pack).
## What ships is the censored partner; the real bytes arrive through scripts/unlock.gd
## against a gateway ticket, after the page's gate says a sponsor creative rendered.

const SLOT := "cg_mirror"

@export var prompt := "Look in the mirror"

var quad: MeshInstance3D
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
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.04, 0.78, 0.53)
	frame.mesh = fb
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.12, 0.06, 0.09)
	fm.metallic = 0.6
	fm.roughness = 0.3
	frame.material_override = fm
	add_child(frame)
	glass = MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.03, 0.7, 0.45)
	glass.mesh = gb
	glass.position.x = 0.012
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.06, 0.03, 0.05)
	gm.metallic = 0.9
	gm.roughness = 0.05
	glass.material_override = gm
	add_child(glass)
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.43, 0.68)
	quad.mesh = qm
	quad.rotation.y = PI * 0.5
	quad.position.x = 0.035
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.85, 0.72, 0.8, 0.96)
	quad.material_override = mat
	add_child(quad)
	base_pos = quad.position
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.4, 0.9, 0.7)
	col.shape = sh
	add_child(col)
	var tag := Label3D.new()
	tag.text = prompt
	tag.font_size = 24
	tag.pixel_size = 0.0022
	tag.position = Vector3(0.1, 0.52, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(1.0, 0.24, 0.54)
	UiFont.apply_3d(tag)
	add_child(tag)
	_load_plate()


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
	quad.visible = tex != null


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
