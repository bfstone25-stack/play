extends Control
class_name PixelStage

## The scene window — now the whole 640x360 canvas, and alive.
##
## What this was: a 300x240 picture in a panel with an info column beside it, a 32x48
## character sheet, and two pixels of bell animation. Three things were wrong with that and
## they were the same thing. 300x240 inside a 640x360 canvas means the art is a *stamp* on
## a form rather than the game; a 32x48 figure cannot carry a face, a coat or a hand; and a
## still picture with a two-frame bell on it reads as a slideshow.
##
## What it is now:
##
## * **Full bleed at 640x360.** The stage is the canvas, 1 art pixel to 1 canvas pixel to 2
##   screen pixels at the shipped window size. The grid is exactly as honest as it was —
##   nothing is resampled, ever — there is simply 2.9x more of it. The UI moved on top as
##   a translucent ink panel (game.gd), which is what an adventure game looks like and what
##   a form does not.
## * **72x108 actors** on a 576x540 sheet, eight columns by five rows. Same row order as
##   the base game (player / mara / orin / tamsin / ivo) — 5x the pixels per figure, and
##   framed from mid-thigh up, because a 48x72 full figure has a ten-pixel head and a
##   ten-pixel head has no face.
## * **Animation by layered deformation, not by frames.** No sprite here has a second
##   authored frame. Everything that moves, moves because this script draws a band of an
##   existing image one pixel off from where it drew it last: the chest rises, the hair
##   drags a frame behind it, the coat hem swings, the lamp breathes, the candle leans,
##   rain falls down the window in one-pixel streaks, dust drifts through the lamp cone.
##   That is how a 4-8 frame loop gets made for the price of a sine, and it is why the
##   shop reads as a room somebody is standing in rather than a screenshot of one.
##
## Every offset below is a whole number of pixels. A sub-pixel breath on a pixel sprite is
## a blur, and a blur is the thing the whole re-do exists to get away from.

const STAGE_SIZE := Vector2(640, 360)
const CELL := Vector2(72, 108)

const SCENES := {
	"title": preload("res://assets/pixel/scene_title.png"),
	"shop": preload("res://assets/pixel/scene_shop.png"),
	"market": preload("res://assets/pixel/scene_crypt_2_ossuary_market.png"),
	"dawn": preload("res://assets/pixel/scene_result_dawn.png"),
}
const CHARACTERS := preload("res://assets/pixel/characters.png")
const CURIOS := preload("res://assets/pixel/curios.png")

## The character sheet's row order. It was the base game's — mara / orin / tamsin / ivo
## — but `orin` is a base-game customer this fork's story never calls and Calder, who
## it does, had no row. Row 2 is his.
const CUSTOMER_ROWS := ["mara", "calder", "tamsin", "ivo"]
## Curio sheet columns, same order as CURIO_IDS in the base game.
const CURIO_COLUMNS := {
	"finial": 0,      # the brass finial rides the wedding_ring cell — both are small brass
	"ring": 0,
	"veil": 2,
	"market": 5,
	"collateral": 4,  # black_ledger
}

## Where the moving parts of each room are, in the room's own pixels.
##
## These are data rather than code because they are the one thing that has to be re-tuned
## when the art is re-rendered, and an artist re-tuning a rectangle should not have to read
## a draw call. `lamp` is the warm key light that breathes; `rain` is a window the streaks
## fall inside; `dust` is the volume motes drift through, and it is deliberately the lamp's
## cone rather than the whole room.
const ROOM_FX := {
	# Measured off the picked render rather than guessed: the lamp is the brightest pixel in
	# scene_shop.png, the window is the blue region, and the counter is the strong
	# horizontal edge at y=250. ops/midnight_pawn_art/build_pixel_assets.py records the crop
	# that puts them there.
	"shop": {
		"lamp": Rect2(272, -86, 142, 142),
		"lamp_color": Color(1.0, 0.76, 0.42),
		"rain": Rect2(56, 10, 180, 210),
		"dust": Rect2(196, 10, 300, 210),
		"motes": 16,
	},
	"market": {
		"lamp": Rect2(300, 60, 96, 96),
		"lamp_color": Color(0.62, 0.86, 0.80),
		"dust": Rect2(90, 70, 460, 240),
		"motes": 20,
	},
	# Dawn's key light is the window, not a lamp — cold, wide and soft. The flicker is the
	# same code and at 5% on something this large it reads as the light changing outside
	# rather than as a bulb.
	"dawn": {
		"lamp": Rect2(40, 20, 320, 320),
		"lamp_color": Color(0.76, 0.87, 1.0),
		"dust": Rect2(60, 30, 420, 200),
		"motes": 14,
	},
	"title": {
		"lamp": Rect2(558, 34, 78, 78),
		"lamp_color": Color(1.0, 0.86, 0.60),
		"rain": Rect2(0, 0, 640, 360),
		"dust": Rect2(300, 30, 340, 200),
		"motes": 8,
	},
}

## Where the actors stand in the shop, and where the object sits between them.
const PLAYER_POS := Vector2(76, 118)
const CUSTOMER_POS := Vector2(452, 118)
const ITEM_POS := Vector2(288, 158)
const DAWN_POS := Vector2(76, 118)

const INK := Color(0.063, 0.051, 0.094)

var mode := "title"
var customer_id := ""
var counter_item := ""
var black := false
var pulse := 0.0

## Deterministic per-mote phases. Random() every frame is a snowstorm, not dust.
var _mote_seed := 0.0


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


# ---------------------------------------------------------------------------
# drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	if black:
		draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), INK)
		return
	var scene: Texture2D = SCENES.get(mode, SCENES["title"])
	# The authored rooms are 640x360 now, but a room that has not been re-rendered yet is
	# still 300x240 and must not tile or crash — it scales to the canvas with nearest
	# filtering, which is ugly and visible, which is the point: it is a to-do, not a bug.
	draw_texture_rect(scene, Rect2(Vector2.ZERO, STAGE_SIZE), false)
	var fx: Dictionary = ROOM_FX.get(mode, {})
	if mode == "shop":
		_draw_shop_actors()
	elif mode == "dawn":
		_draw_actor(DAWN_POS, 6, 0.0, 0.55)
	_draw_lamp(fx)
	_draw_rain(fx)
	_draw_dust(fx)


## The lamp. One additive radial bloom whose radius and brightness ride two sines of
## different periods — 1.7s and 0.43s — so the flicker never settles into a beat you can
## count. Drawn as eight concentric circles rather than a texture because eight circles is
## cheaper than an asset and it quantises into rings the pixel grid can hold.
func _draw_lamp(fx: Dictionary) -> void:
	if not fx.has("lamp"):
		return
	var r: Rect2 = fx["lamp"]
	var col: Color = fx.get("lamp_color", Color(1.0, 0.78, 0.45))
	var breath := 1.0 + 0.055 * sin(pulse * 3.7) + 0.030 * sin(pulse * 14.6)
	var centre := r.position + r.size * 0.5
	var radius := r.size.x * 0.5 * breath
	for i in range(8):
		var t := float(i) / 8.0
		draw_circle(centre, radius * (1.0 - t * 0.86),
			Color(col.r, col.g, col.b, 0.030 + 0.020 * t))


## Rain. Twenty-two streaks, each a 1x5 column falling at its own speed inside the window
## rect and wrapping at the bottom. Deterministic from the index, so it is the same rain
## every run and never resets when the scene changes.
func _draw_rain(fx: Dictionary) -> void:
	if not fx.has("rain"):
		return
	var r: Rect2 = fx["rain"]
	for i in range(22):
		var speed := 46.0 + float((i * 37) % 58)
		var x := r.position.x + float((i * 97) % int(max(1.0, r.size.x)))
		var y := r.position.y + fposmod(pulse * speed + float(i * 53), r.size.y)
		draw_rect(Rect2(floor(x), floor(y), 1, 5),
			Color(0.72, 0.82, 0.95, 0.18), true)


## Dust. Motes drift up and sideways through the lamp cone on a slow lissajous, one pixel
## each. At two screen pixels they are the thing that tells you the image is running.
func _draw_dust(fx: Dictionary) -> void:
	if not fx.has("dust"):
		return
	var r: Rect2 = fx["dust"]
	var n: int = int(fx.get("motes", 12))
	for i in range(n):
		var ph := float(i) * 1.618
		var x := r.position.x + fposmod(float(i) * 61.0 + sin(pulse * 0.31 + ph) * 26.0,
			r.size.x)
		var y := r.position.y + fposmod(r.size.y - pulse * (5.0 + float(i % 5)) + ph * 29.0,
			r.size.y)
		var a := 0.10 + 0.10 * (0.5 + 0.5 * sin(pulse * 1.4 + ph))
		draw_rect(Rect2(floor(x), floor(y), 1, 1), Color(1.0, 0.92, 0.78, a), true)


func _draw_shop_actors() -> void:
	_draw_actor(PLAYER_POS, 0, 0.0, 1.0)
	if not customer_id.is_empty():
		var row := CUSTOMER_ROWS.find(customer_id)
		if row >= 0:
			# A different phase per client, so two people in a room are not one metronome.
			_draw_actor(CUSTOMER_POS, -1, 1.9 + float(row) * 0.7, 1.0, row)
	if CURIO_COLUMNS.has(counter_item):
		_draw_curio()
	# The base game's bell cell used to be blinked here. At 2x on the new sheet it is a
	# brown crate floating in the dark, and what it was for — telling you the shop is awake
	# — is now carried by the lamp's flicker and the dust, which do it better and belong to
	# the room. Dropped rather than kept as decoration.


## The object on the counter, lifting one pixel on a slow beat — the shop is a place where
## things are not entirely inert, and this is the cheapest sentence saying so.
##
## The curio sheet keeps the base game's 32x32 cells and is drawn at 3x. Re-cutting it to
## 48x48 would have meant a 1.5x resample of hand-authored pixels, which is the dishonest
## grid this whole pass exists to avoid; an integer multiple of the original is not.
func _draw_curio() -> void:
	var lift := -2.0 if int(pulse * 1.5) % 2 == 0 else 0.0
	var col: int = int(CURIO_COLUMNS[counter_item])
	draw_texture_rect_region(CURIOS,
		Rect2(ITEM_POS + Vector2(0, lift), Vector2(64, 64)),
		Rect2(col * 32, 32, 32, 32))


## An actor, drawn in four horizontal bands so a still sprite can breathe.
##
## This is the whole animation idea in one function. The sheet holds one authored pose;
## the loop comes from where the bands are put:
##
##   rows   0-23  hair    drags one pixel behind the torso, on a slower sine
##   rows  24-67  chest   rises and falls 1px on a ~4s breath
##   rows  68-91  hips    half the chest's offset, so the body bends rather than hops
##   rows 92-107  hem     planted, plus a 1px coat-hem sway out of phase with the hair
##
## Four bands is the minimum that reads as a body and the maximum that stays free: the
## whole thing is four draw calls and no allocation.
func _draw_actor(pos: Vector2, player_frame: int, phase: float, amount: float,
		row: int = -1) -> void:
	var src_x := 0.0
	var src_y := 0.0
	if player_frame >= 0:
		src_x = float(clampi(player_frame, 0, 7)) * CELL.x
	else:
		src_y = CELL.y * float(row + 1)
	var breath := sin(pulse * 1.55 + phase)
	var drift := sin(pulse * 0.92 + phase * 1.3)
	var dy: float = round(breath * amount)                    # whole pixels only
	var sway: float = round(drift * amount)
	# Each band also carries the room's light. The sprites render under flat even studio
	# lighting — they have to, or IP-Adapter learns the shadow as part of the face — and
	# dropped into a room lit by one amber lamp from above they read as stickers on a
	# photograph. The fix is free here because the bands already exist: tint them down the
	# figure, warm and bright at the head where the lamp is, deep at the hem where the
	# counter shades it. It is the single change that puts the cast *in* the shop.
	var key: Color = ROOM_FX.get(mode, {}).get("lamp_color", Color(1.0, 0.82, 0.60))
	_band(src_x, src_y, pos, 0, 24, sway, dy, _tint(key, 1.00))
	_band(src_x, src_y, pos, 24, 44, 0.0, dy, _tint(key, 0.90))
	_band(src_x, src_y, pos, 68, 24, 0.0, round(dy * 0.5), _tint(key, 0.78))
	_band(src_x, src_y, pos, 92, 16, round(-drift * amount * 0.6), 0.0, _tint(key, 0.66))


## The key light at a given strength down the figure, kept off pure white so the top of a
## head never blows out to paper.
static func _tint(key: Color, v: float) -> Color:
	return Color(lerpf(1.0, key.r, 0.55) * v, lerpf(1.0, key.g, 0.55) * v,
		lerpf(1.0, key.b, 0.55) * v, 1.0)


## One horizontal band of a sprite, drawn `dx`/`dy` pixels off where the sheet has it.
func _band(src_x: float, src_y: float, pos: Vector2, row: float, h: float,
		dx: float, dy: float, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(CHARACTERS,
		Rect2(pos + Vector2(dx, row + dy), Vector2(CELL.x, h)),
		Rect2(src_x, src_y + row, CELL.x, h), tint)
