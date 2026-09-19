extends CharacterBody3D

const WALK := 2.35
const SPRINT := 3.55
const ACCEL := 12.0
const GRAVITY := 18.0
const SENS := 0.0022
const BOB_FREQ := 8.4
const BOB_AMP := 0.028
## Is the player actually facing the prop? The InteractRay above is the precise aim — it
## reaches 2.8 m straight down the middle of the screen. The 6.5 m radius below it is the
## forgiving fallback, and it had its facing gate stubbed to `var face_ok := true`, so it
## handed back the nearest prop in the room whether or not the player could see it. In a
## game whose whole verb is looking at the right thing, props could be taken from behind.
##
## The shape below is the ancestor's (across-hall's player.gd still has it intact); what
## did not survive is its number. There the fallback radius was 1.85 m, so a 0.12 dot — an
## 83 degree half-angle, very nearly a hemisphere — was harmless: everything in range was
## within arm's reach anyway. This game widened the radius to 6.5 m, which turns that same
## cone into most of the flat, and the gate was stubbed out rather than renumbered.
##
## 0.80 is the number for a 6.5 m radius: a 36.9 degree half-angle. Chosen by looking
## through it (tests/facing_probe.gd photographs the boundary). At 1280x720 the horizontal
## half-frame is 51.2 degrees, so a prop entering the cone sits 60% of the way to the edge
## of the picture — just outside the torch's 28 degree beam, still plainly in frame and
## identifiable. Wider and props start being offered from the unlit corners and, past 0.62,
## from off screen entirely, which is the stub again in a quieter form. Much tighter and it
## stops being a fallback and starts duplicating the ray.
const FACE_DOT := 0.80
## Underfoot the horizontal direction to a prop is meaningless, and the pitch clamp means
## a prop half a metre away cannot be centred at all. Inside this radius the test is the
## full 3D one instead: look down at it and it is yours, turn your back and it is not.
const FACE_NEAR := 0.35
const FACE_UNDERFOOT := -0.35

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var breath: AudioStreamPlayer3D = $Breath

var pitch := 0.0
var bob_t := 0.0
var has_flashlight := false
var light_on := false
var battery := 1.0
var captured := false
var locked := false

func _ready() -> void:
	flashlight.visible = false

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	captured = true

func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.pressed and not captured:
		capture_mouse()
	if event is InputEventMouseMotion and captured:
		rotate_y(-event.relative.x * SENS)
		pitch = clampf(pitch - event.relative.y * SENS, -1.25, 1.25)
		head.rotation.x = pitch
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		captured = false
	if event.is_action_pressed("flashlight") and has_flashlight:
		light_on = not light_on
		flashlight.visible = light_on and battery > 0.0
		get_tree().call_group("game", "click_sfx")

func give_flashlight() -> void:
	has_flashlight = true
	light_on = true
	flashlight.visible = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var wish := Vector3.ZERO
	if not locked:
		var input_dir := Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		)
		if Input.is_key_pressed(KEY_UP):
			input_dir.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			input_dir.y += 1.0
		if Input.is_key_pressed(KEY_LEFT):
			input_dir.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			input_dir.x += 1.0
		wish = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y))
		if wish.length() > 1.0:
			wish = wish.normalized()

	var speed := SPRINT if Input.is_physical_key_pressed(KEY_SHIFT) else WALK
	var target := wish * speed
	velocity.x = lerpf(velocity.x, target.x, ACCEL * delta)
	velocity.z = lerpf(velocity.z, target.z, ACCEL * delta)
	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.4 and is_on_floor() and not locked
	if moving:
		bob_t += delta * BOB_FREQ * (1.35 if speed > WALK + 0.1 else 1.0)
		if int(bob_t) != int(bob_t - delta * BOB_FREQ):
			get_tree().call_group("game", "footstep", global_position)
	var bob := sin(bob_t) * BOB_AMP if moving else 0.0
	camera.position.y = bob

	if light_on and has_flashlight:
		battery = maxf(0.0, battery - delta * 0.0065)
		flashlight.light_energy = 2.4 * battery * (0.92 + 0.08 * sin(Time.get_ticks_msec() * 0.012))
		if battery <= 0.0:
			flashlight.visible = false
			light_on = false

	if breath:
		var near := get_tree().get_first_node_in_group("tenant")
		if near and near is Node3D:
			var d: float = global_position.distance_to((near as Node3D).global_position)
			breath.volume_db = lerpf(-28.0, -6.0, clampf(1.0 - d / 9.0, 0.0, 1.0))

func facing() -> Vector3:
	return -camera.global_transform.basis.z

func interact_target() -> Node:
	if ray.is_colliding():
		var n := ray.get_collider() as Node
		while n:
			if n.has_method("interact") and n.get("taken") != true:
				return n
			n = n.get_parent()
	var best: Node = null
	# A generous focus radius keeps small paper props usable on controllers and
	# low-resolution Web builds; the nearest active story prop still wins.
	var best_d := 6.5
	var look := facing()
	var look_flat := Vector3(look.x, 0.0, look.z)
	if look_flat.length() > 0.001:
		look_flat = look_flat.normalized()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get("taken") == true:
			continue
		if n is Node3D:
			var to: Vector3 = (n as Node3D).global_position - global_position
			var d: float = to.length()
			if d >= best_d:
				continue
			var flat := Vector3(to.x, 0.0, to.z)
			var face_ok := true
			if flat.length() > FACE_NEAR:
				# Across the room: it has to be in front of you, and in frame.
				face_ok = look_flat.dot(flat.normalized()) >= FACE_DOT
			else:
				# Underfoot: looking down at it counts, having your back to it does not.
				face_ok = look.dot(to.normalized()) > FACE_UNDERFOOT
			if face_ok:
				best_d = d
				best = n
	return best
