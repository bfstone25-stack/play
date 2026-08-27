extends CharacterBody3D

## Visible only in peripheral vision. Looking at it makes it leave and reappear behind you.

@onready var mesh: MeshInstance3D = $Mesh

var home := Vector3(6.8, 0.95, 11.4)
var speed := 0.55
var vanish_t := 0.0
var hidden := false

func _ready() -> void:
	add_to_group("tenant")
	global_position = home
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var to_me := (global_position - player.global_position)
	to_me.y = 0.0
	var dist := to_me.length()
	var dir := to_me.normalized() if dist > 0.01 else Vector3.FORWARD
	var facing := Vector3.FORWARD
	if player.has_method("facing"):
		facing = player.facing()
		facing.y = 0.0
		facing = facing.normalized()
	var look_amt := facing.dot(dir)  # 1 = staring at tenant

	if hidden:
		vanish_t -= delta
		visible = false
		if vanish_t <= 0.0:
			hidden = false
			_relocate(player)
		return

	# Fade when stared at
	var vis := clampf(1.0 - (look_amt - 0.15) / 0.55, 0.05, 1.0)
	mesh.transparency = 1.0 - vis
	if look_amt > 0.72:
		vanish_t += delta
		if vanish_t > 0.55:
			hidden = true
			vanish_t = 0.7
			get_tree().call_group("game", "on_tenant_seen")
	else:
		vanish_t = maxf(0.0, vanish_t - delta * 2.0)

	# Creep closer only when not looked at
	if look_amt < 0.35 and dist > 1.15:
		var step := dir * -speed * delta
		global_position += step

	if dist < 1.05 and look_amt < 0.5:
		get_tree().call_group("game", "caught")

func _relocate(player: Node3D) -> void:
	var back: Vector3 = player.global_position - player.facing() * 3.2
	back.y = 0.95
	# Keep inside 402 roughly
	back.x = clampf(back.x, 2.4, 8.2)
	back.z = clampf(back.z, 4.6, 11.6)
	global_position = back
	visible = true
	mesh.transparency = 0.2
