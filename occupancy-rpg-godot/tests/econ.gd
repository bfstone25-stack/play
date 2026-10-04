extends Node
## Office economy probe: the greedy best layout's shift value for piece sets (tools: balance).
func _ready() -> void:
	var O = load("res://scripts/office.gd")
	var sets := {
		"start": [{"mara": 1, "dan": 1, "priya": 1}, {"coffee": 2, "mute": 1}],
		"start+coffee": [{"mara": 1, "dan": 1, "priya": 1}, {"coffee": 3, "mute": 1}],
		"start+mute": [{"mara": 1, "dan": 1, "priya": 1}, {"coffee": 2, "mute": 2}],
		"start+corner": [{"mara": 1, "dan": 1, "priya": 1}, {"coffee": 2, "mute": 1, "corner": 1}],
		"start+printer": [{"mara": 1, "dan": 1, "priya": 1}, {"coffee": 2, "mute": 1, "printer": 1}],
		"+nia": [{"mara": 1, "dan": 1, "priya": 1, "nia": 1}, {"coffee": 3, "mute": 1}],
		"+nia+sol": [{"mara": 1, "dan": 1, "priya": 1, "nia": 1, "sol": 1}, {"coffee": 3, "mute": 1}],
		"all": [{"mara": 1, "dan": 1, "priya": 1, "nia": 1, "sol": 1, "wes": 1}, {"coffee": 4, "mute": 2, "printer": 1, "corner": 2}],
		"all dupes": [{"mara": 4, "dan": 4, "priya": 4, "nia": 3, "sol": 2, "wes": 2}, {"coffee": 4, "mute": 2, "printer": 1, "corner": 2}],
	}
	for k in sets.keys():
		var o = O.new()
		o.st = {"owned": sets[k][0], "objects": sets[k][1], "pulls": 0}
		var best: Array = o.best_layout(Landlord.empty_cells())
		var r: Dictionary = o.settle(best)
		var rnd: Array = o.random_layout()
		print("%-14s best %5d/shift (payout %d chain %d)  random %5d" % [k, int(r["shift"]), int(r["payout"]), int(r["chain"]), o.shift_value(rnd)])
		o.free()
	get_tree().quit()
