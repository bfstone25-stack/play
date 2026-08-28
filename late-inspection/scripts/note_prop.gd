extends StaticBody3D

@export var prompt := "Read"
@export var note_id := ""
@export var note_text := ""

var taken := false

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if taken:
		return
	taken = true
	collision_layer = 0
	if game.has_method("show_note"):
		game.show_note(note_text if note_text != "" else note_id)
	if game.has_method("on_note"):
		game.on_note(note_id)
