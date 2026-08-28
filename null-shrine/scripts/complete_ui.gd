extends Control
## Run complete card.

var game: Node = null

@onready var score_label: Label = $Center/VBox/Score
@onready var detail: Label = $Center/VBox/Detail
@onready var btn: Button = $Center/VBox/Restart


func bind(g: Node) -> void:
	game = g
	btn.pressed.connect(func(): game.start_run())


func show_score(score: int, gold: int, looted: int) -> void:
	score_label.text = "RUN COMPLETE — Score %d" % score
	detail.text = "Gold %dG · Crypt extracts loot ×%d\nFree slice loop proven. Paid biomes later." % [gold, looted]
