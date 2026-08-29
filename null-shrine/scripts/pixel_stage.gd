class_name PixelStage
extends Control

signal objective_reached
signal floor_risk_triggered

var mode := "title"
var room_index := 0
var avatar := Vector2(42, 174)
var target := avatar
var objective := Vector2(386, 82)
var moving := false
var risk_done := false
var enemy_alive := true
var selected_curio := ""
var customer_id := ""
var pulse := 0.0

const INK := Color("#171225")
const NIGHT := Color("#241c35")
const STONE := Color("#39304d")
const MORTAR := Color("#211a2e")
const GOLD := Color("#e8b84a")
const CREAM := Color("#f1dfb0")
const RED := Color("#c54f5b")
const VIOLET := Color("#8b5bc7")
const TEAL := Color("#48a69a")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()


func set_scene(next_mode: String, room: int = 0) -> void:
	mode = next_mode
	room_index = room
	if mode == "dungeon":
		avatar = Vector2(42, 174)
		target = avatar
		objective = [Vector2(390, 76), Vector2(382, 174), Vector2(390, 82), Vector2(382, 150)][room_index]
		risk_done = false
		enemy_alive = true
	queue_redraw()


func nudge(direction: Vector2) -> void:
	if mode != "dungeon":
		return
	target = (avatar + direction * 34.0).clamp(Vector2(24, 40), Vector2(size.x - 24, size.y - 24))
	moving = true


func _gui_input(event: InputEvent) -> void:
	if mode == "dungeon" and event is InputEventMouseButton and event.pressed:
		target = event.position.clamp(Vector2(24, 40), Vector2(size.x - 24, size.y - 24))
		moving = true


func _process(delta: float) -> void:
	pulse += delta
	if mode == "dungeon" and moving:
		avatar = avatar.move_toward(target, 92.0 * delta)
		if avatar.distance_to(target) < 2.0:
			moving = false
		var hazard_x := 205.0 if room_index % 2 == 0 else 270.0
		if not risk_done and absf(avatar.x - hazard_x) < 46.0:
			risk_done = true
			floor_risk_triggered.emit()
		if avatar.distance_to(objective) < 34.0 and enemy_alive:
			moving = false
			objective_reached.emit()
	queue_redraw()


func mark_enemy_defeated() -> void:
	enemy_alive = false
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	match mode:
		"title":
			_draw_title()
		"shop":
			_draw_shop()
		"dungeon":
			_draw_dungeon()
		"final":
			_draw_final()
		"result":
			_draw_result()


func _draw_title() -> void:
	for y in range(24, int(size.y), 16):
		for x in range(8, int(size.x), 16):
			if (x + y) % 32 == 0:
				draw_rect(Rect2(x, y, 2, 2), Color("#4b3b62"))
	# Crooked pawn sign and crypt stair.
	draw_rect(Rect2(74, 44, size.x - 148, 70), Color("#33243f"))
	draw_rect(Rect2(80, 50, size.x - 160, 58), Color("#9b643f"))
	draw_rect(Rect2(88, 57, size.x - 176, 44), Color("#24192d"))
	for i in 6:
		draw_rect(Rect2(size.x / 2.0 - 74 + i * 10, 150 + i * 8, 148 - i * 20, 8), STONE)
	draw_circle(Vector2(size.x / 2.0, 132), 10 + sin(pulse * 2.0), Color(GOLD, 0.45))
	draw_circle(Vector2(size.x / 2.0, 132), 5, GOLD)


func _draw_shop() -> void:
	draw_rect(Rect2(0, 0, size.x, 34), Color("#563522"))
	draw_rect(Rect2(0, 34, size.x, size.y - 34), Color("#291c22"))
	# Wallpaper and timber.
	for x in range(8, int(size.x), 24):
		for y in range(48, int(size.y), 24):
			draw_rect(Rect2(x, y, 2, 8), Color("#50323b"))
	draw_rect(Rect2(16, 112, size.x - 32, 9), Color("#8c5834"))
	draw_rect(Rect2(16, 120, size.x - 32, 5), Color("#3c251e"))
	for i in 3:
		var px := 44.0 + i * 92.0
		draw_rect(Rect2(px, 84, 46, 28), Color("#18121c"))
		_draw_curio_icon(Vector2(px + 23, 98), i)
	# Counter, clerk, customer silhouettes.
	draw_rect(Rect2(0, size.y - 52, size.x, 52), Color("#684329"))
	draw_rect(Rect2(0, size.y - 52, size.x, 6), Color("#ad7741"))
	_draw_person(Vector2(84, size.y - 55), CREAM, true)
	_draw_person(Vector2(size.x - 84, size.y - 55), VIOLET if customer_id == "ivo" else TEAL, false)
	# Hanging lamp.
	draw_line(Vector2(size.x / 2, 0), Vector2(size.x / 2, 26), Color("#6a506c"), 2)
	draw_circle(Vector2(size.x / 2, 31), 15 + sin(pulse * 3.0), Color(GOLD, 0.12))
	draw_rect(Rect2(size.x / 2 - 6, 25, 12, 9), GOLD)


func _draw_dungeon() -> void:
	draw_rect(Rect2(8, 28, size.x - 16, size.y - 36), NIGHT)
	for y in range(36, int(size.y - 12), 20):
		for x in range(16, int(size.x - 12), 24):
			var shift := 12 if (y / 20 as int) % 2 else 0
			draw_rect(Rect2(x + shift, y, 21, 17), STONE)
			draw_line(Vector2(x + shift, y + 17), Vector2(x + shift + 21, y + 17), MORTAR, 2)
	# Columns and room-specific pixel props.
	for px in [120.0, size.x - 126.0]:
		draw_rect(Rect2(px, 54, 18, 114), Color("#51445e"))
		draw_rect(Rect2(px - 4, 50, 26, 8), Color("#70607b"))
	if room_index == 0:
		for i in 5:
			draw_rect(Rect2(186 + i * 12, 118 + (i % 2) * 8, 10, 16), VIOLET)
	elif room_index == 1:
		draw_rect(Rect2(205, 48, 60, 94), Color("#2a2133"))
		draw_circle(Vector2(235, 82), 18, Color("#776282"))
	elif room_index == 2:
		for i in 7:
			var x := 188.0 + i * 17
			draw_colored_polygon(PackedVector2Array([Vector2(x, 150), Vector2(x + 8, 122), Vector2(x + 16, 150)]), RED)
	else:
		draw_circle(Vector2(size.x / 2.0, 62), 18, Color("#86745d"))
		draw_circle(Vector2(size.x / 2.0, 62), 12, INK)
		draw_line(Vector2(size.x / 2.0, 78), Vector2(size.x / 2.0, 96), GOLD, 3)
	if enemy_alive:
		_draw_enemy(objective)
	else:
		draw_rect(Rect2(objective - Vector2(14, 7), Vector2(28, 14)), Color("#315e59"))
		draw_rect(Rect2(objective - Vector2(8, 3), Vector2(16, 6)), GOLD)
	_draw_avatar(avatar)


func _draw_final() -> void:
	for i in 7:
		draw_circle(Vector2(size.x / 2.0, size.y / 2.0), 74 - i * 9, Color(VIOLET, 0.08 + i * 0.018))
	_draw_curio_icon(Vector2(size.x / 2.0, size.y / 2.0), 7)
	draw_rect(Rect2(size.x / 2.0 - 68, size.y - 52, 136, 12), Color("#6c442c"))
	draw_circle(Vector2(size.x / 2.0, size.y / 2.0), 24 + sin(pulse * 2.4) * 2, Color(RED, 0.22))


func _draw_result() -> void:
	draw_rect(Rect2(18, 24, size.x - 36, size.y - 48), Color("#21192b"))
	for i in 9:
		draw_rect(Rect2(30 + i * 42, size.y - 64 - (i % 3) * 8, 28, 36 + (i % 3) * 8), Color("#352b45"))
	draw_circle(Vector2(size.x / 2.0, 72), 28, Color(GOLD, 0.18))
	draw_circle(Vector2(size.x / 2.0, 72), 12, GOLD)


func _draw_avatar(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 7, pos.y - 11, 14, 18), Color("#273246"))
	draw_rect(Rect2(pos.x - 5, pos.y - 17, 10, 8), CREAM)
	draw_rect(Rect2(pos.x - 6, pos.y - 17, 3, 3), Color("#492c33"))
	draw_rect(Rect2(pos.x - 9, pos.y + 7, 7, 4), Color("#17131c"))
	draw_rect(Rect2(pos.x + 2, pos.y + 7, 7, 4), Color("#17131c"))


func _draw_person(pos: Vector2, color: Color, clerk: bool) -> void:
	draw_circle(pos - Vector2(0, 36), 11, Color("#d1a47d"))
	draw_rect(Rect2(pos.x - 13, pos.y - 26, 26, 30), color)
	if clerk:
		draw_rect(Rect2(pos.x - 14, pos.y - 48, 28, 5), Color("#32263b"))
		draw_rect(Rect2(pos.x - 9, pos.y - 54, 18, 8), Color("#32263b"))


func _draw_enemy(pos: Vector2) -> void:
	var bob := sin(pulse * 4.0) * 2.0
	if room_index == 0:
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-18, bob), pos + Vector2(0, -10 + bob), pos + Vector2(18, bob), pos + Vector2(0, 10 + bob)]), Color("#b594ce"))
		draw_rect(Rect2(pos.x - 3, pos.y - 3 + bob, 6, 6), GOLD)
	elif room_index == 1:
		draw_rect(Rect2(pos.x - 13, pos.y - 28 + bob, 26, 38), Color("#76637f"))
		draw_circle(pos + Vector2(0, -32 + bob), 10, Color("#bfaaa9"))
	elif room_index == 2:
		for i in 4:
			draw_line(pos, pos + Vector2(-20 + i * 13, -28 + abs(i - 2) * 4 + bob), Color("#c5b7a0"), 7)
		draw_circle(pos + Vector2(0, bob), 13, RED)
	else:
		draw_rect(Rect2(pos.x - 18, pos.y - 24 + bob, 36, 30), Color("#86745d"))
		draw_circle(pos + Vector2(0, -2 + bob), 11, INK)
		draw_rect(Rect2(pos.x - 3, pos.y + 6 + bob, 6, 18), GOLD)


func _draw_curio_icon(pos: Vector2, variant: int) -> void:
	var kind := variant
	if not selected_curio.is_empty():
		var ids := ["wedding_ring", "bone_key", "music_box", "dueling_pistol", "black_ledger", "moon_coin", "saints_tooth", "crypt_heart"]
		kind = maxi(0, ids.find(selected_curio))
	match kind:
		0:
			draw_arc(pos, 9, 0, TAU, 16, GOLD, 4)
		1:
			draw_circle(pos - Vector2(8, 0), 6, CREAM)
			draw_line(pos - Vector2(2, 0), pos + Vector2(12, 0), CREAM, 4)
			draw_line(pos + Vector2(7, 0), pos + Vector2(7, 6), CREAM, 3)
		2:
			draw_rect(Rect2(pos - Vector2(11, 8), Vector2(22, 16)), Color("#a66d45"))
			draw_circle(pos, 4, GOLD)
		3:
			draw_rect(Rect2(pos - Vector2(13, 3), Vector2(24, 6)), Color("#9b8b79"))
			draw_rect(Rect2(pos - Vector2(4, -3), Vector2(6, 10)), Color("#6a4431"))
		4:
			draw_rect(Rect2(pos - Vector2(10, 13), Vector2(20, 26)), Color("#171319"))
			draw_line(pos - Vector2(4, 9), pos + Vector2(4, 9), RED, 2)
		5:
			draw_circle(pos, 11, Color("#aab2bf"))
			draw_circle(pos + Vector2(4, -2), 8, INK)
		6:
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-8, -12), pos + Vector2(8, -8), pos + Vector2(4, 13), pos + Vector2(-5, 9)]), CREAM)
		_:
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18), pos + Vector2(15, -5), pos + Vector2(10, 15), pos + Vector2(0, 20), pos + Vector2(-10, 15), pos + Vector2(-15, -5)]), RED)
