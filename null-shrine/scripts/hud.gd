extends CanvasLayer
## Top HUD — phase / gold / bag.

var game: Node = null

@onready var label: Label = $Root/Label


func bind(g: Node) -> void:
	game = g
	game.phase_changed.connect(func(_p): refresh())
	game.gold_changed.connect(func(_v): refresh())
	game.bag_changed.connect(func(_v): refresh())
	refresh()


func refresh() -> void:
	if game == null:
		return
	label.text = "Midnight Pawn & Crypt  ·  %s  ·  %dG  ·  bag %d" % [
		game.phase_name(), game.gold, game.bag.size()
	]
