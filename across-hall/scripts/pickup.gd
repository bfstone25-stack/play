extends StaticBody3D

@export var prompt := "拿起"
@export var item_id := ""
@export var note_text := ""

var taken := false

func interact(game: Node) -> void:
	if taken:
		return
	taken = true
	visible = false
	$CollisionShape3D.disabled = true
	if item_id != "":
		game.give_item(item_id)
	if note_text != "":
		game.show_note(note_text)
