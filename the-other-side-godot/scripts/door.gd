extends StaticBody3D

@export var prompt := ""
@export var kind := "401"

func _ready() -> void:
	add_to_group("interactable")
	# The prompt is localised, so it cannot be an @export default -- Loc is an autoload
	# and defaults are evaluated before it exists. An @export that IS set in the scene
	# still wins, which is what the empty check is for.
	if prompt == "":
		prompt = I18n.t("p_door")

func interact(game: Node) -> void:
	if kind == "401":
		if bool(game.get("apt401_open")):
			game.show_note(I18n.t("n_own_door"))
			return
		if int(game.get("phase")) < 1:
			game.show_note(I18n.t("n_not_yet"))
			return
		game.open_401()
	else:
		if bool(game.get("apt402_open")):
			game.show_note(I18n.t("n_already_open"))
			return
		game.open_402()
