class_name Piece
extends Node2D
## One placed piece: an isometric furniture block on the floor with the character or
## object drawn on top. Drawn in code (the parent's icons.js badges were vector too), so
## it scales with the tile. drop_in() is the placement weight: falls, lands, settles.

const TOP := {
	"coffee": Color("#6b3f22"), "dan": Color("#2a5a44"), "priya": Color("#2f4f6e"), "wes": Color("#5a3030"),
	"mute": Color("#3a3f5a"), "printer": Color("#4a4f55"), "mara": Color("#4a3560"), "corner": Color("#3c5a3a"),
	"nia": Color("#5c3a56"), "sol": Color("#6e5a2a"),
}
const ACCENT := {
	"coffee": Color("#e0a14a"), "dan": Color("#7fd6b0"), "priya": Color("#8fc3ff"), "wes": Color("#ff8a6a"),
	"mute": Color("#9aa8ff"), "printer": Color("#d0d8dc"), "mara": Color("#d9a0ff"), "corner": Color("#a9e39a"),
	"nia": Color("#ff9ad0"), "sol": Color("#ffd36a"),
}
const STAFF := ["dan", "priya", "mara", "wes", "nia", "sol"]

var id := "coffee"
var tw := 96.0     # tile width
var th := 50.0     # tile height
var lift := 0.0    # drop animation offset
var squash := 1.0
var glow := 0.0
var score := 0
var show_score := true


func setup(piece_id: String, tile_w: float, tile_h: float) -> void:
	id = piece_id
	tw = tile_w
	th = tile_h
	queue_redraw()


## Placement has weight: drop from above, land with a squash, settle back.
func drop_in() -> void:
	lift = -140.0
	squash = 1.0
	glow = 1.0
	var t := create_tween()
	t.set_parallel(false)
	t.tween_property(self, "lift", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "squash", 0.72, 0.06)
	t.tween_property(self, "squash", 1.12, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "squash", 1.0, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "glow", 0.0, 0.6)


func pop() -> void:
	var t := create_tween()
	t.tween_property(self, "squash", 1.18, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "squash", 1.0, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var top: Color = TOP.get(id, Color("#2a3a44"))
	var acc: Color = ACCENT.get(id, Palette.GOLD)
	var hw := tw * 0.38
	var hh := th * 0.38
	var h := th * 0.55 * squash
	var y0 := lift
	# shadow on the floor
	draw_colored_polygon(PackedVector2Array([Vector2(0, -hh * 1.05), Vector2(hw * 1.05, 0), Vector2(0, hh * 1.05), Vector2(-hw * 1.05, 0)]), Color(0, 0, 0, 0.35))
	# block faces
	var left := PackedVector2Array([Vector2(-hw, y0), Vector2(0, hh + y0), Vector2(0, hh + y0 - h), Vector2(-hw, y0 - h)])
	var right := PackedVector2Array([Vector2(hw, y0), Vector2(0, hh + y0), Vector2(0, hh + y0 - h), Vector2(hw, y0 - h)])
	draw_colored_polygon(left, top.darkened(0.45))
	draw_colored_polygon(right, top.darkened(0.25))
	var topface := PackedVector2Array([Vector2(0, -hh + y0 - h), Vector2(hw, y0 - h), Vector2(0, hh + y0 - h), Vector2(-hw, y0 - h)])
	draw_colored_polygon(topface, top.lightened(0.08 + glow * 0.4))
	draw_polyline(PackedVector2Array([topface[0], topface[1], topface[2], topface[3], topface[0]]), Color(acc, 0.55 + glow * 0.45), 1.2, true)
	# the thing on the desk
	var c := Vector2(0, y0 - h - hh * 0.35)
	var s := tw * 0.11
	match id:
		"coffee":
			draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.9), Vector2(s * 1.4, s * 1.5)), acc.darkened(0.2))
			draw_arc(c + Vector2(s * 0.9, -s * 0.2), s * 0.45, -PI / 2, PI / 2, 8, acc, 2.0, true)
			draw_line(c + Vector2(-s * 0.2, -s * 1.3), c + Vector2(0, -s * 1.9), Color(1, 1, 1, 0.35), 1.5, true)
		"mute":
			draw_arc(c + Vector2(0, s * 0.1), s * 1.1, PI, TAU, 12, acc, 3.0, true)
			draw_rect(Rect2(c + Vector2(-s * 1.4, -s * 0.2), Vector2(s * 0.6, s * 0.9)), acc)
			draw_rect(Rect2(c + Vector2(s * 0.8, -s * 0.2), Vector2(s * 0.6, s * 0.9)), acc)
		"printer":
			draw_rect(Rect2(c + Vector2(-s * 1.3, -s * 0.6), Vector2(s * 2.6, s * 1.3)), acc.darkened(0.35))
			draw_rect(Rect2(c + Vector2(-s * 0.8, -s * 1.3), Vector2(s * 1.6, s * 0.8)), Color(0.95, 0.95, 0.9))
			draw_circle(c + Vector2(s * 0.9, -s * 0.1), s * 0.18, Palette.SUCCESS)
		"corner":
			draw_rect(Rect2(c + Vector2(-s * 1.4, -s * 0.9), Vector2(s * 0.9, s * 1.9)), acc.darkened(0.25))
			draw_rect(Rect2(c + Vector2(-s * 1.4, s * 0.2), Vector2(s * 2.8, s * 0.8)), acc.darkened(0.25))
			draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.7), Vector2(s * 1.0, s * 0.7)), Color(0.8, 0.9, 1.0, 0.8))
		_:
			# a person at the desk: head, shoulders, a lit monitor beside
			draw_circle(c + Vector2(0, -s * 1.15), s * 0.55, Color("#e8c8a8"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.1, s * 0.9), c + Vector2(-s * 0.8, -s * 0.35), c + Vector2(s * 0.8, -s * 0.35), c + Vector2(s * 1.1, s * 0.9)]), acc.darkened(0.15))
			draw_rect(Rect2(c + Vector2(s * 1.2, -s * 0.9), Vector2(s * 1.1, s * 0.8)), Color(0.65, 0.9, 1.0, 0.75 + glow * 0.25))
			draw_line(c + Vector2(-s * 0.85, -s * 1.5), c + Vector2(s * 0.85, -s * 1.5), acc.darkened(0.5), s * 0.45, true)
	if show_score and score != 0:
		var f := Look.font_mono_bold
		var txt := ("+" if score > 0 else "") + str(score)
		var col := Palette.GOLD if score > 0 else Palette.HEAT
		# above the block, so it reads as this desk's number and not the next one's
		var pos := Vector2(-20, y0 - h - hh - 8)
		draw_string(f, pos + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color(0, 0, 0, 0.8))
		draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 13, col)
