extends StaticBody3D

@export var prompt := "Listen at the door"
@export var kind := "401"

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if kind == "401":
		if int(game.get("phase")) < 2:
			game.show_note("Deadbolted. No light in the keyhole.\nYou check your pockets: no key, and no seam where a pocket should be.")
		else:
			game.show_note("Someone inside is brushing with your cadence.\nTwenty strokes, a pause, twenty more.\nYou have counted your own. Identical.")
		game.knock_behind_401()
	else:
		game.show_note("It's open. An open door isn't breaking in.")
