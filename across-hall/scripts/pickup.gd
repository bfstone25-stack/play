extends StaticBody3D

@export var prompt := "Pick up"
@export var item_id := ""
@export var note_text := ""

var taken := false

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if taken:
		return
	taken = true
	visible = false
	for c in get_children():
		if c is CollisionShape3D:
			c.disabled = true
	if item_id != "":
		game.give_item(item_id)
	if note_text != "":
		game.show_note(note_text)
