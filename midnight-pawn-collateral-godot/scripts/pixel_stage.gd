extends Control
class_name PixelStage

## The 300x240 scene window, cut down from ~/midnight-pawn-src/scripts/pixel_stage.gd.
##
## What survives from the base game: the authored 300x240 window drawn 1:1 on the 640x360
## logical canvas, nearest-neighbour filtering, the same scene PNGs out of the same
## assets/pixel/, and the same character sheet with the same 32x48 frames and the same
## row order (mara / orin / tamsin / ivo). What is gone is the dungeon half: no avatar
## movement, no hazard tiles, no enemy — the fork keeps one crypt room and no combat, so
## the Market is a backdrop the scene plays in front of rather than a floor you cross.
##
## The plate layer is a separate Control on top of this one (scripts/plates.gd), so a
## missing plate file degrades to the scene still showing, never to a black rectangle.

const STAGE_SIZE := Vector2(300, 240)
const SCENES := {
	"title": preload("res://assets/pixel/scene_title.png"),
	"shop": preload("res://assets/pixel/scene_shop.png"),
	"market": preload("res://assets/pixel/scene_crypt_2_ossuary_market.png"),
	"dawn": preload("res://assets/pixel/scene_result_dawn.png"),
}
const CHARACTERS := preload("res://assets/pixel/characters.png")
const CURIOS := preload("res://assets/pixel/curios.png")

## The character sheet's row order, straight out of the base game's _draw_shop_actors().
const CUSTOMER_ROWS := ["mara", "orin", "tamsin", "ivo"]
## Curio sheet columns, same order as CURIO_IDS in the base game. The fork shows the one
## object that is on the counter in the current appraisal.
const CURIO_COLUMNS := {
	"finial": 0,      # the brass finial rides the wedding_ring cell — both are small brass
	"ring": 0,
	"veil": 2,
	"market": 5,
	"collateral": 4,  # black_ledger
}

var mode := "title"
var customer_id := ""
var counter_item := ""
var black := false
var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = STAGE_SIZE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	queue_redraw()


func set_scene(next_mode: String) -> void:
	# "black" is the between-scenes hold the Ren'Py script used as `scene bg black`: the
	# stair, the fade into the market, the cut to dawn. There is no PNG for it.
	black = next_mode == "black"
	if not black:
		mode = next_mode
	queue_redraw()


func set_customer(id: String) -> void:
	customer_id = id
	queue_redraw()


func set_counter_item(item: String) -> void:
	counter_item = item
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	if black:
		draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color(0.063, 0.051, 0.094))
		return
	var scene: Texture2D = SCENES.get(mode, SCENES["title"])
	draw_texture(scene, Vector2.ZERO)
	if mode == "shop":
		_draw_shop_actors()
	elif mode == "dawn":
		_draw_player_frame(Vector2(39, 164), 6)


func _draw_shop_actors() -> void:
	_draw_player_frame(Vector2(43, 140), int(pulse * 2.0) % 2)
	if not customer_id.is_empty():
		var row := CUSTOMER_ROWS.find(customer_id)
		if row >= 0:
			draw_texture_rect_region(
				CHARACTERS,
				Rect2(Vector2(231, 137), Vector2(32, 48)),
				Rect2(0, 48 + row * 48, 32, 48))
	if CURIO_COLUMNS.has(counter_item):
		draw_texture_rect_region(
			CURIOS,
			Rect2(Vector2(185, 154), Vector2(32, 32)),
			Rect2(int(CURIO_COLUMNS[counter_item]) * 32, 32, 32, 32))
	# The bell's two-pixel authored animation cue, kept because it is the one thing on this
	# screen that tells you the shop is awake.
	if int(pulse * 4.0) % 2 == 0:
		draw_texture_rect_region(CURIOS, Rect2(Vector2(265, 159), Vector2(24, 24)), Rect2(64, 0, 24, 24))


func _draw_player_frame(pos: Vector2, frame: int) -> void:
	draw_texture_rect_region(CHARACTERS, Rect2(pos, Vector2(32, 48)), Rect2(clampi(frame, 0, 7) * 32, 0, 32, 48))
