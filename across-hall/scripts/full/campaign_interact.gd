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
				var short := next_prompt
				if next_prompt.length() > 14:
					short = next_prompt.substr(0, 12) + "…"
				(child as Label3D).text = short
				(child as Label3D).modulate = Color(0.55, 0.5, 0.42)
	for child in get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat := (child.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = mat.albedo_color.darkened(0.35)
			mat.emission_enabled = false
			child.material_override = mat
