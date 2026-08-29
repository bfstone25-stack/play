extends StaticBody3D

## Hard choice hotspot. Opens the two-button VN panel.

@export var prompt := "Decide"
@export var choice_id := "stay_or_leave"
@export var prompt_text := "The lease says the inspection ends at midnight.\nIt is already later than that."
@export var option_a := "Stay overnight and finish the checklist"
@export var option_b := "Leave the key on the table and walk out"

var consumed := false
var taken := false

func _ready() -> void:
	add_to_group("interactable")

func interact(game: Node) -> void:
	if consumed:
		return
	if game.has_method("open_choice"):
		game.open_choice(choice_id, prompt_text, option_a, option_b, self)
