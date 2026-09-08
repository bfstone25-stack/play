extends StaticBody3D

@export var prompt := "Look"
@export var inspect_id := ""
@export var note_text := ""

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if game.has_method("inspect"):
		game.inspect(inspect_id, note_text)
	elif note_text != "":
		game.show_note(note_text)
