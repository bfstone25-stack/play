extends StaticBody3D

@export var action_id := ""
@export var prompt := "Inspect"
@export var one_shot := false

var taken := false

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if taken or not game.has_method("perform_action"):
		return
	var consumed := bool(game.perform_action(action_id))
	if consumed and one_shot:
		taken = true
		visible = false
		collision_layer = 0
		collision_mask = 0
		for child in get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = true

func mark_used(next_prompt: String = "") -> void:
	if next_prompt != "":
		prompt = next_prompt
		for child in get_children():
			if child is Label3D:
				(child as Label3D).text = next_prompt
				(child as Label3D).modulate = Color(0.55, 0.5, 0.42)
