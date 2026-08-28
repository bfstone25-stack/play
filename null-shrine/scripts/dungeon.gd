extends Node2D
## One-room mini crypt — move + pick loot + extract.

var game: Node = null
var active: bool = false
var loot_nodes: Array = []

@onready var player: CharacterBody2D = $Player
@onready var exit_pad: Area2D = $ExitPad
@onready var loot_root: Node2D = $LootRoot
@onready var hint: Label = $Hint


func bind(g: Node) -> void:
	game = g
	exit_pad.body_entered.connect(_on_exit_body)
	if player.has_method("bind"):
		player.bind(self)


func activate() -> void:
	active = true
	visible = true
	player.position = Vector2(80, 200)
	player.velocity = Vector2.ZERO
	_clear_loot()
	_spawn_loot()
	hint.text = "WASD move · walk over loot · stand on EXIT or press E"
	hint.visible = true


func deactivate() -> void:
	active = false
	_clear_loot()
	hint.visible = false


func _clear_loot() -> void:
	for n in loot_nodes:
		if is_instance_valid(n):
			n.queue_free()
	loot_nodes.clear()
	for c in loot_root.get_children():
		c.queue_free()


func _spawn_loot() -> void:
	if game == null:
		return
	var drops: Array = game.spawn_night_loot()
	var positions := [
		Vector2(220, 140), Vector2(360, 220), Vector2(500, 160),
		Vector2(280, 300), Vector2(440, 300), Vector2(560, 240),
	]
	positions.shuffle()
	for i in drops.size():
		var item: Dictionary = drops[i]
		var node := _make_loot_node(item, positions[i % positions.size()])
		loot_root.add_child(node)
		loot_nodes.append(node)


func _make_loot_node(item: Dictionary, pos: Vector2) -> Area2D:
	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.set_meta("item", item)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14
	shape.shape = circle
	area.add_child(shape)
	var spr := ColorRect.new()
	spr.size = Vector2(16, 16)
	spr.position = Vector2(-8, -8)
	match str(item.get("tag", "mundane")):
		"curious":
			spr.color = Color(0.45, 0.75, 1.0)
		"cursed":
			spr.color = Color(0.85, 0.35, 0.7)
		_:
			spr.color = Color(0.85, 0.7, 0.3)
	area.add_child(spr)
	var label := Label.new()
	label.text = str(item.get("name_zh", item.get("name", "?")))
	label.position = Vector2(-24, -28)
	label.add_theme_font_size_override("font_size", 11)
	area.add_child(label)
	area.body_entered.connect(func(body): _pickup(area, body))
	return area


func _pickup(area: Area2D, body: Node) -> void:
	if not active:
		return
	if body != player:
		return
	if not area.has_meta("item"):
		return
	var item: Dictionary = area.get_meta("item")
	game.add_loot(item)
	area.set_meta("item", {})
	loot_nodes.erase(area)
	area.queue_free()


func _on_exit_body(body: Node) -> void:
	if active and body == player:
		_try_extract()


func _try_extract() -> void:
	if not active:
		return
	active = false
	game.return_from_dungeon()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact"):
		# Extract if near exit
		if player.global_position.distance_to(exit_pad.global_position) < 48.0:
			_try_extract()
