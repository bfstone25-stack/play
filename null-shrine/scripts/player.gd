extends CharacterBody2D
## Tiny pixel pawnkeeper in the crypt.

const SPEED := 140.0

var dungeon: Node2D = null


func bind(d: Node2D) -> void:
	dungeon = d


func _physics_process(_delta: float) -> void:
	if dungeon == null or not dungeon.active:
		velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()
	# Soft clamp inside room
	position.x = clampf(position.x, 40, 700)
	position.y = clampf(position.y, 60, 380)
