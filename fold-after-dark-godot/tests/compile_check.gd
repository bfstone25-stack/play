extends Node
## Load every script with the autoloads up, so a parse error anywhere fails loudly (a
## --quit run only compiles what the title scene touches). Prints COMPILE_OK.
##   godot --headless --path . res://tests/compile_check.tscn
func _ready() -> void:
	var bad := 0
	for p in ["res://scenes/game.gd", "res://scenes/map.gd", "res://scenes/title.gd",
			"res://scripts/f2p.gd", "res://scripts/f2p_ui.gd", "res://scripts/nutaku_f2p.gd",
			"res://scripts/tiers.gd"]:
		var s := load(p) as Script
		if s == null or not s.can_instantiate():
			print("COMPILE_FAIL ", p)
			bad += 1
	if bad == 0:
		print("COMPILE_OK")
	get_tree().quit(1 if bad else 0)
