class_name PixelStage
extends Control

signal objective_reached
signal floor_risk_triggered

const STAGE_SIZE := Vector2(300, 240)
const SCENES := {
	"title": preload("res://assets/pixel/scene_title.png"),
	"shop": preload("res://assets/pixel/scene_shop.png"),
	"dungeon_0": preload("res://assets/pixel/scene_crypt_0_receipt_stair.png"),
	"dungeon_1": preload("res://assets/pixel/scene_crypt_1_widow_niche.png"),
	"dungeon_2": preload("res://assets/pixel/scene_crypt_2_ossuary_market.png"),
	"dungeon_3": preload("res://assets/pixel/scene_crypt_3_foreclosure_chapel.png"),
	"final": preload("res://assets/pixel/scene_final_appraisal.png"),
	"result": preload("res://assets/pixel/scene_result_dawn.png"),
}
const CHARACTERS := preload("res://assets/pixel/characters.png")
const CURIOS := preload("res://assets/pixel/curios.png")
const CRYPT_ATLAS := preload("res://assets/pixel/crypt_atlas.png")
const CURIO_IDS := [
	"wedding_ring", "bone_key", "music_box", "dueling_pistol",
	"black_ledger", "moon_coin", "saints_tooth", "crypt_heart",
]

var mode := "title"
var room_index := 0
var avatar := Vector2(35, 176)
var target := avatar
var objective := Vector2(250, 82)
var moving := false
var risk_done := false
var enemy_alive := true
var selected_curio := ""
var customer_id := ""
var customer_expression := 0
var pulse := 0.0
var action_flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = STAGE_SIZE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	queue_redraw()


func set_scene(next_mode: String, room: int = 0) -> void:
	mode = next_mode
	room_index = room
	if mode == "dungeon":
		avatar = Vector2(35, 176)
		target = avatar
		objective = [Vector2(250, 80), Vector2(244, 146), Vector2(250, 93), Vector2(241, 142)][room_index]
		risk_done = false
		enemy_alive = true
		action_flash = 0.0
	queue_redraw()


func nudge(direction: Vector2) -> void:
	if mode != "dungeon":
		return
	target = (avatar + direction * 34.0).clamp(Vector2(20, 42), Vector2(280, 222))
	moving = true


func _gui_input(event: InputEvent) -> void:
	if mode == "dungeon" and event is InputEventMouseButton and event.pressed:
		target = event.position.clamp(Vector2(20, 42), Vector2(280, 222))
		moving = true


func _process(delta: float) -> void:
	pulse += delta
	action_flash = maxf(0.0, action_flash - delta)
	if mode == "dungeon" and moving:
		avatar = avatar.move_toward(target, 92.0 * delta)
		if avatar.distance_to(target) < 2.0:
			moving = false
		var hazard_x := 150.0 if room_index % 2 == 0 else 205.0
		if not risk_done and absf(avatar.x - hazard_x) < 42.0:
			risk_done = true
			floor_risk_triggered.emit()
		if avatar.distance_to(objective) < 32.0 and enemy_alive:
			moving = false
			objective_reached.emit()
	queue_redraw()


func mark_enemy_defeated() -> void:
	enemy_alive = false
	action_flash = 0.35
	queue_redraw()


func set_customer_expression(expression: int) -> void:
	customer_expression = clampi(expression, 0, 3)
	queue_redraw()


func _draw() -> void:
	var scene_key := mode
	if mode == "dungeon":
		scene_key = "dungeon_%d" % room_index
	var scene: Texture2D = SCENES.get(scene_key, SCENES.title)
	# The scene window is authored at 300x240 and rendered 1:1 on the
	# 640x360 logical canvas. Any spare panel space remains letterboxed.
	draw_texture(scene, Vector2.ZERO)
	match mode:
		"shop":
			_draw_shop_actors()
		"dungeon":
			_draw_dungeon_actors()
		"final":
			_draw_player_frame(Vector2(39, 164), 6)


func _draw_shop_actors() -> void:
	_draw_player_frame(Vector2(43, 140), int(pulse * 2.0) % 2)
	if not customer_id.is_empty():
		var customer_index := ["mara", "orin", "tamsin", "ivo"].find(customer_id)
		if customer_index >= 0:
			var source := Rect2(customer_expression * 32, 48 + customer_index * 48, 32, 48)
			draw_texture_rect_region(CHARACTERS, Rect2(Vector2(231, 137), Vector2(32, 48)), source)
	if not selected_curio.is_empty():
		var curio_index := CURIO_IDS.find(selected_curio)
		if curio_index >= 0:
			draw_texture_rect_region(CURIOS, Rect2(Vector2(185, 154), Vector2(32, 32)), Rect2(curio_index * 32, 32, 32, 32))
	# Bell vibration is a two-pixel authored animation cue.
	if int(pulse * 4.0) % 2 == 0:
		draw_texture_rect_region(CURIOS, Rect2(Vector2(265, 159), Vector2(24, 24)), Rect2(64, 0, 24, 24))


func _draw_dungeon_actors() -> void:
	var walk_frame := 2 + (int(pulse * 8.0) % 4) if moving else int(pulse * 2.0) % 2
	_draw_player_frame(avatar - Vector2(16, 42), walk_frame)
	if enemy_alive:
		var enemy_frame := int(pulse * 4.0) % 2
		var source := Rect2(room_index * 64 + enemy_frame * 32, 72, 32, 48)
		draw_texture_rect_region(CRYPT_ATLAS, Rect2(objective - Vector2(16, 38), Vector2(32, 48)), source)
	else:
		var curio_index := [5, 0, 6, 7][room_index]
		draw_texture_rect_region(CURIOS, Rect2(objective - Vector2(16, 14), Vector2(32, 32)), Rect2(curio_index * 32, 32, 32, 32))
	if action_flash > 0.0:
		draw_texture_rect_region(CRYPT_ATLAS, Rect2(objective - Vector2(20, 20), Vector2(32, 32)), Rect2(224, 136, 32, 32))


func _draw_player_frame(position: Vector2, frame: int) -> void:
	var safe_frame := clampi(frame, 0, 7)
	draw_texture_rect_region(CHARACTERS, Rect2(position, Vector2(32, 48)), Rect2(safe_frame * 32, 0, 32, 48))
