extends StaticBody3D

@export var prompt := "播放"

func interact(game: Node) -> void:
	game.play_tape()
