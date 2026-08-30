extends Node2D
class_name OfficeBuilder

const W := 640
const H := 360
const BASE_SIZE := Vector2(320, 180)
const SCENES := {
	"cubicle": "res://assets/pixel/scene_cubicle.png",
	"office": "res://assets/pixel/scene_office.png",
	"breakroom": "res://assets/pixel/scene_breakroom.png",
	"server": "res://assets/pixel/scene_server.png",
	"lobby": "res://assets/pixel/scene_lobby.png",
	"stairs": "res://assets/pixel/scene_stairs.png",
	"manager": "res://assets/pixel/scene_manager.png",
}
const ENDINGS := {
	"CLOCK_OUT": "res://assets/pixel/ending_clock_out.png",
	"NEW_MANAGER": "res://assets/pixel/ending_new_manager.png",
	"MONDAY_FOREVER": "res://assets/pixel/ending_monday_forever.png",
}

var area_id := "cubicle"
var phase := 0.0
var state: Dictionary = {}
var scene_sprite: Sprite2D
var coworker: AnimatedSprite2D
var scanner: Line2D
var practical_lights: Array[PointLight2D] = []

func build(id: String, story_state := {}) -> void:
	area_id = id
	state = story_state.duplicate()
	for child in get_children():
		child.queue_free()
	practical_lights.clear()
	scene_sprite = Sprite2D.new()
	scene_sprite.name = "AuthoredPixelScene"
	scene_sprite.texture = load(SCENES.get(id, SCENES.cubicle))
	scene_sprite.centered = false
	scene_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_sprite.scale = Vector2(2, 2)
	add_child(scene_sprite)
	_add_location_animation()
	_apply_story_palette()

func _process(delta: float) -> void:
	phase += delta
	if is_instance_valid(scanner):
		var y := roundf(174.0 + sin(phase * 2.7) * 9.0)
		scanner.points = PackedVector2Array([Vector2(-24, y), Vector2(664, y)])
		scanner.modulate.a = 0.62 + 0.25 * sin(phase * 6.0)
	if is_instance_valid(coworker) and state.get("eli_stance", "") == "SUSPECT":
		coworker.modulate = Color(1.0, 0.55 + 0.12 * sin(phase * 9.0), 0.62)
	for i in practical_lights.size():
		if is_instance_valid(practical_lights[i]):
			practical_lights[i].energy = 0.60 + 0.08 * sin(phase * 2.0 + i)

func show_ending(ending_id: String) -> void:
	for child in get_children():
		child.queue_free()
	scene_sprite = Sprite2D.new()
	scene_sprite.name = "AuthoredPixelEnding"
	scene_sprite.texture = load(ENDINGS.get(ending_id, ENDINGS.MONDAY_FOREVER))
	scene_sprite.centered = false
	scene_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_sprite.scale = Vector2(2, 2)
	add_child(scene_sprite)

func _add_location_animation() -> void:
	if area_id == "breakroom":
		_add_coworker()
	if area_id in ["office", "server", "manager"]:
		scanner = Line2D.new()
		scanner.name = "AuditorScan"
		scanner.width = 2.0
		scanner.default_color = Color("#ef3b4f")
		scanner.antialiased = false
		scanner.z_index = 8
		add_child(scanner)
	if area_id in ["cubicle", "breakroom", "lobby"]:
		var light := PointLight2D.new()
		light.name = "PracticalFlicker"
		light.position = {"cubicle": Vector2(160, 45), "breakroom": Vector2(320, 48), "lobby": Vector2(320, 42)}[area_id]
		light.texture = _light_texture()
		light.texture_scale = 4.0
		light.color = Color("#b9d6c0" if area_id == "breakroom" else "#b6cfe1")
		light.energy = 0.65
		light.blend_mode = Light2D.BLEND_MODE_ADD
		add_child(light)
		practical_lights.append(light)

func _add_coworker() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.5)
	frames.set_animation_loop("idle", true)
	var corrupt: bool = str(state.get("eli_stance", "")) == "SUSPECT"
	var atlas: Texture2D = load("res://assets/pixel/office_atlas.png")
	for index in 4:
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(8 + index * 32, 193 if corrupt else 145, 24, 40)
		frames.add_frame("idle", frame)
	coworker = AnimatedSprite2D.new()
	coworker.name = "EliCorrupted" if corrupt else "EliNormal"
	coworker.sprite_frames = frames
	coworker.animation = "idle"
	coworker.position = Vector2(464, 176)
	coworker.scale = Vector2(2, 2)
	coworker.centered = false
	coworker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coworker.z_index = 4
	add_child(coworker)
	coworker.play()

func _apply_story_palette() -> void:
	var compliance := str(state.get("compliance", ""))
	if compliance == "REFUSE":
		scene_sprite.modulate = Color("#c4e8ff")
	elif compliance == "OBEY":
		scene_sprite.modulate = Color("#ffb0a7")
	if str(state.get("contract", "")) == "SIGN":
		scene_sprite.modulate = Color("#ff8c83")

func _light_texture() -> Texture2D:
	# Authored four-band 48x24 alpha ramp with a dithered edge. Keeping this
	# as a nearest-filtered PNG avoids a smooth runtime radial gradient.
	return load("res://assets/pixel/light_pool.png")
