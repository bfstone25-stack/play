extends Node2D
## A chain spark: a bright dot with a short tail, tweened along a link by FloorView.

var color: Color = Color(1, 0.7, 0.3)
var _trail: Array = []


func _process(_d: float) -> void:
	_trail.push_front(global_position)
	if _trail.size() > 8:
		_trail.pop_back()
	queue_redraw()


func _draw() -> void:
	for k in range(_trail.size()):
		var p: Vector2 = to_local(_trail[k])
		draw_circle(p, 3.5 - k * 0.35, Color(color, 0.9 - k * 0.1))
	draw_circle(Vector2.ZERO, 5.0, Color(color.lightened(0.5), 1.0))
