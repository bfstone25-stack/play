extends Node
## Juice: the feel layer's settings and its one piece of arithmetic. Autoloaded as "Juice".
##
## Two player settings, each with its own switch because they are different complaints:
##   * reduced motion: no screen shake, no flying rewards, fewer sparks, a results card
##     that shows its final state at once. Sound and voice are untouched.
##   * voice: Coco's lines on or off, separate from the SFX/music switch.
##
## The score is DETERMINISTIC from the fold log (no timing, no randomness) because the
## "score N in X moves" goal is validated by the server: ops/nutaku/fold_f2p/fold_rules.py
## `score_log()` is the Python twin of `move_points()` here, and
## check_rules_conformance.py pins the two.
##
##   combo   = consecutive moves that merged anything (a move with no merge resets it to 0)
##   points  = sum of the merged tiles' NEW values x min(combo, 5)

const COMBO_CAP := 5
const COMBO_WORDS := ["", "", "x2", "x3 Great!", "x4 Amazing!", "x5 Incredible!"]

var reduced_motion := false
var voice_on := true

## live combo state for the board on screen; undo pops it back (same as fold_rules.replay)
var combo := 0
var score := 0
var max_combo := 0
var _hist: Array = []

## the alternate goals: level index -> {type: "score", score, moves} | {type: "combo", combo}
var goals := {}


func _ready() -> void:
	reduced_motion = str(Save.get_v("fold_reduced_motion", "0")) == "1"
	voice_on = str(Save.get_v("fold_voice", "1")) != "0"
	var f := FileAccess.open("res://data/goals.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			for k in parsed.keys():
				if not str(k).begins_with("_"):
					goals[int(k)] = parsed[k]


func goal_for(level: int) -> Dictionary:
	return goals.get(level, {})


## "Score 380 in 9 moves" / "Hit a x3 combo", or "" for a plain level.
func goal_text(level: int) -> String:
	var g := goal_for(level)
	if g.is_empty():
		return ""
	if str(g["type"]) == "score":
		return "Score %d in %d moves" % [int(g["score"]), int(g["moves"])]
	return "Hit a x%d combo" % int(g["combo"])


## Python twin: fold_rules.goal_met. {ok, why}
func goal_met(level: int, moves: int) -> Dictionary:
	var g := goal_for(level)
	if g.is_empty():
		return {"ok": true, "why": ""}
	if str(g["type"]) == "score":
		if moves > int(g["moves"]):
			return {"ok": false, "why": "%d moves: the goal was %d or fewer" % [moves, int(g["moves"])]}
		if score < int(g["score"]):
			return {"ok": false, "why": "Score %d: the goal was %d" % [score, int(g["score"])]}
		return {"ok": true, "why": ""}
	if max_combo < int(g["combo"]):
		return {"ok": false, "why": "Best combo x%d: the goal was x%d" % [max_combo, int(g["combo"])]}
	return {"ok": true, "why": ""}


func set_reduced_motion(v: bool) -> void:
	reduced_motion = v
	Save.set_v("fold_reduced_motion", "1" if v else "0")


func set_voice(v: bool) -> void:
	voice_on = v
	Save.set_v("fold_voice", "1" if v else "0")


func reset_board() -> void:
	combo = 0
	score = 0
	max_combo = 0
	_hist = []


func on_undo() -> void:
	if _hist.is_empty():
		return
	var h: Array = _hist.pop_back()
	score = int(h[0])
	combo = int(h[1])
	max_combo = int(h[2])


## Points for one move, given the merged tiles' new values. Advances the combo.
static func move_points(merged_values: Array, combo_before: int) -> Dictionary:
	var c := combo_before + 1 if merged_values.size() > 0 else 0
	var pts := 0
	for v in merged_values:
		pts += int(v)
	pts *= mini(c, COMBO_CAP)
	return {"combo": c, "points": pts}


## Called by the board right after Fold.move: reads the merged flags Fold just set.
func on_move() -> Dictionary:
	var vals := []
	for t in Fold.tiles:
		if bool(t.get("merged", false)):
			vals.append(int(t["v"]))
	_hist.append([score, combo, max_combo])
	var r := move_points(vals, combo)
	combo = int(r["combo"])
	score += int(r["points"])
	max_combo = maxi(max_combo, combo)
	r["merged"] = vals.size()
	return r


static func combo_word(c: int) -> String:
	return COMBO_WORDS[mini(c, COMBO_WORDS.size() - 1)] if c >= 2 else ""


## A short decaying shake on `node`'s position. Nothing under reduced motion.
func shake(node: Node2D, strength: float = 6.0, dur: float = 0.22) -> void:
	if reduced_motion or node == null:
		return
	var tw := node.create_tween()
	var steps := 6
	for i in range(steps):
		var k := 1.0 - float(i) / steps
		var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k
		tw.tween_property(node, "position", off, dur / steps)
	tw.tween_property(node, "position", Vector2.ZERO, dur / steps)
