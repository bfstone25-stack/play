extends Control
## Title splash.

var game: Node = null

@onready var btn: Button = $Center/VBox/Start
@onready var subtitle: Label = $Center/VBox/Subtitle


func bind(g: Node) -> void:
	game = g
	btn.pressed.connect(func(): game.start_run())
	subtitle.text = "Day: tend the pawn · Night: dive the crypt · One 15-min run"


func _ready() -> void:
	if btn and not btn.pressed.is_connected(_noop):
		pass


func _noop() -> void:
	pass
