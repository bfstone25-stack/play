extends StaticBody3D

@export var prompt := "放磁带"

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	game.play_tape()
