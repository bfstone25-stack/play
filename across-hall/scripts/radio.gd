extends StaticBody3D

@export var prompt := "Play cassette"
@export var deck := "402"

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if game.has_method("play_tape"):
		game.play_tape(deck)
