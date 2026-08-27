extends StaticBody3D

@export var prompt := "放磁带"

func interact(game: Node) -> void:
	game.play_tape()
