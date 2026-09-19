extends Area2D
class_name Hotspot

signal activated(id: String)

@export var hotspot_id: String = ""
@export var prompt: String = "Inspect"
@export var enabled: bool = true

var _hover := false
var _highlight: ColorRect

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	input_event.connect(_on_input)
	_ensure_highlight()

func configure(id: String, p: String, rect: Rect2, color: Color = Color(0.12, 0.28, 0.95, 0.22)) -> void:
	hotspot_id = id
	prompt = p
	position = rect.position
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = rect.size * 0.5
	add_child(col)
	_ensure_highlight()
	_highlight.size = rect.size
	_highlight.color = color
	_highlight.visible = false

func _ensure_highlight() -> void:
	if _highlight:
		return
	_highlight = ColorRect.new()
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.z_index = 2
	add_child(_highlight)

func set_hotspot_enabled(v: bool) -> void:
	enabled = v
	visible = v
	input_pickable = v
	if not v:
		_hover = false
		if _highlight:
			_highlight.visible = false

func _on_enter() -> void:
	if not enabled:
		return
	_hover = true
	if _highlight:
		_highlight.visible = true
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("set_prompt"):
		game.set_prompt(prompt)

func _on_exit() -> void:
	_hover = false
	if _highlight:
		_highlight.visible = false
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("clear_prompt"):
		game.clear_prompt(prompt)

func _on_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activated.emit(hotspot_id)
