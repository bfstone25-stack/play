extends CharacterBody3D

## Peripheral-vision neighbor. Staring relocates it behind you. Catching you is recognition.
##
## The Other Side: the capsule is only the far form. Inside four metres it resolves into a
## rendered person (assets/plates/tenant.png on a billboard Sprite3D — a plate, never a
## code-drawn figure), and inside 1.7 m it stops hunting and turns to face you: the
## confrontation beat (game.confront()).

@onready var mesh: MeshInstance3D = $Mesh

## The opening in 402's bathroom partition (world_builder._bathroom): x 7.09..8.09 at
## z=10.43. Standing in it puts the lit bathroom behind him and the front room in front.
const DOORWAY_402 := Vector3(7.59, 0.95, 10.43)

var home := Vector3(7.1, 0.95, 11.15)
var speed := 0.42
var vanish_t := 0.0
var hidden := false
var activated := false
var sting_cd := 0.0
var figure: Sprite3D
var resolved := 0.0
var confronted := false

func _ready() -> void:
	add_to_group("tenant")
	global_position = home
	visible = false
	_dress()
	_figure()

func _dress() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.06, 0.055)
	mat.roughness = 0.95
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.13
	sph.height = 0.26
	head.mesh = sph
	head.position = Vector3(0, 0.72, 0)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.55, 0.48, 0.42)
	skin.roughness = 0.7
	head.material_override = skin
	add_child(head)
	for x in [-0.045, 0.045]:
		var eye := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.035, 0.012, 0.01)
		eye.mesh = box
		eye.position = Vector3(x, 0.74, -0.11)
		var em := StandardMaterial3D.new()
		em.albedo_color = Color(0.02, 0.02, 0.02)
		em.emission_enabled = true
		em.emission = Color(0.7, 0.15, 0.1)
		em.emission_energy_multiplier = 0.8
		eye.material_override = em
		add_child(eye)

func _figure() -> void:
	figure = Sprite3D.new()
	if ResourceLoader.exists("res://assets/plates/tenant.png"):
		figure.texture = load("res://assets/plates/tenant.png")
	figure.pixel_size = 0.00155
	figure.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	figure.shaded = false
	figure.transparent = true
	figure.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	figure.position = Vector3(0, 0.0, 0)
	figure.modulate = Color(1, 0.86, 0.92, 0.0)
	add_child(figure)

func _physics_process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game")
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or game == null:
		return
	if game.get("ending"):
		return
	var phase := int(game.get("phase"))
	sting_cd = maxf(0.0, sting_cd - delta)

	if phase < 1:
		visible = false
		return

	var in_402 := player.global_position.x > 1.85
	var in_401 := player.global_position.x < -1.85
	if not activated:
		if in_402 or in_401:
			activated = true
			visible = true
			global_position = Vector3(6.4, 0.95, 9.6) if in_402 else Vector3(-6.6, 0.95, 5.4)
		else:
			visible = false
			return
	# Beat 1 happens in 401, so the tenant activates there and hunts you in the corner of
	# your eye — that is the design. But `activated` is sticky, and nothing afterwards ever
	# moved him: cross to 402 and the whole confrontation played out back in 401, against
	# your own bathroom, which is the one room the beat is not about. Once you are in 402
	# and the chapter has turned, he is waiting in 402's bathroom doorway, which is what
	# NOTES["flat402"] has been telling the player all along.
	if phase >= 2 and in_402 and global_position.x < 1.85 and not confronted:
		global_position = DOORWAY_402
		hidden = false
		vanish_t = 0.0

	if confronted:
		visible = true
		# EVERY piece of the capsule, not just the body. The head sphere and the eye boxes
		# are separate children, and they were only being faded inside the resolve loop
		# further down — which this branch returns before reaching. The result was a grey
		# ball hanging in front of the rendered face for the whole exchange.
		mesh.transparency = 1.0
		for c in get_children():
			if c is MeshInstance3D and c != mesh:
				(c as MeshInstance3D).transparency = 1.0
		if figure:
			figure.modulate.a = 1.0
		return
	if hidden:
		vanish_t -= delta
		visible = false
		if vanish_t <= 0.0:
			hidden = false
			_relocate(player, phase)
		return

	visible = true
	var to_me := global_position - player.global_position
	to_me.y = 0.0
	var dist := to_me.length()
	var dir := to_me.normalized() if dist > 0.01 else Vector3.FORWARD
	var facing := Vector3.FORWARD
	if player.has_method("facing"):
		facing = player.facing()
		facing.y = 0.0
		if facing.length() > 0.01:
			facing = facing.normalized()
	var look_amt := facing.dot(dir)
	# Only readable in the corner of the eye.
	var vis := clampf(1.0 - (look_amt - 0.08) / 0.62, 0.08, 1.0)
	if look_amt > 0.55 and phase < 2:
		vis *= 0.25
	if phase >= 2:
		vis = 1.0
	mesh.transparency = 1.0 - vis
	if look_at_ok(player):
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	if look_amt > 0.78 and phase < 2:
		vanish_t += delta
		if sting_cd <= 0.0:
			get_tree().call_group("game", "on_tenant_seen")
			sting_cd = 1.4
		if vanish_t > 0.4:
			hidden = true
			vanish_t = 0.55 if phase < 3 else 0.28
	else:
		vanish_t = maxf(0.0, vanish_t - delta * 2.2)

	var hunt := speed + (0.35 if phase >= 2 else 0.0) + (0.55 if phase >= 3 else 0.0)
	if look_amt < 0.38 and dist > 1.05 and phase < 2:
		global_position += dir * -hunt * delta
		global_position.y = 0.95

	# Resolve: the closer you are, the more of the person there is and the less capsule.
	var want := clampf((4.2 - dist) / 2.4, 0.0, 1.0) if phase >= 2 else 0.0
	resolved = lerpf(resolved, want, delta * 2.5)
	if figure:
		figure.modulate.a = resolved
	mesh.transparency = maxf(mesh.transparency, resolved)
	for c in get_children():
		if c is MeshInstance3D and c != mesh:
			(c as MeshInstance3D).transparency = resolved
	if not confronted and phase >= 2 and dist < 1.7 and resolved > 0.6:
		confronted = true
		get_tree().call_group("game", "confront")
		return
	if confronted:
		return
	if dist < 1.0 and look_amt < 0.55 and phase < 2:
		get_tree().call_group("game", "caught")

func look_at_ok(player: Node3D) -> bool:
	var p := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	return p.distance_to(global_position) > 0.08

func _relocate(player: Node3D, phase: int) -> void:
	var back: Vector3 = player.global_position - player.facing() * (2.4 if phase < 3 else 1.7)
	back.y = 0.95
	if player.global_position.x > 1.85:
		back.x = clampf(back.x, 2.5, 8.3)
		back.z = clampf(back.z, 4.5, 11.7)
	elif player.global_position.x < -1.85:
		back.x = clampf(back.x, -8.3, -2.5)
		back.z = clampf(back.z, -1.2, 6.2)
	else:
		back.x = clampf(back.x, -1.2, 1.2)
		back.z = clampf(back.z, 0.4, 13.0)
	global_position = back
	visible = true
	mesh.transparency = 0.15
