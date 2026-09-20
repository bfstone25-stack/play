extends StaticBody3D

@export var prompt := "Open the door"
@export var kind := "401"

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if kind == "401":
		if bool(game.get("apt401_open")):
			game.show_note("It's your door. It is already open from this side.")
			return
		if int(game.get("phase")) < 1:
			game.show_note("You are not going anywhere before you have looked.\nThe bathroom light is on. You did not leave it on.")
			return
		game.open_401()
	else:
		if bool(game.get("apt402_open")):
			game.show_note("It's open. It has been open since you looked.")
			return
		game.open_402()
