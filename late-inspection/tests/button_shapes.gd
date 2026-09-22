extends SceneTree
func _init() -> void:
	await process_frame
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud := game.get_node("HUD")
	var bad: Array[String] = []
	var n := 0
	for name in ["Resume", "Restart", "EndingNext"]:
		var b: Node = hud.find_child(name, true, false)
		if b == null:
			bad.append("%s missing" % name); continue
		if not (b is ShapedButton):
			bad.append("%s is a plain Button, not a ShapedButton" % name); continue
		n += 1
	for name in ["ChoiceA", "ChoiceB"]:
		var b: Node = game.find_child(name, true, false)
		if b == null:
			bad.append("%s missing" % name); continue
		if not (b is ShapedButton):
			bad.append("%s is a plain Button" % name); continue
		n += 1
	# The words. A ShapedButton draws `label` and ignores `text`, and _draw()'s text->label
	# adoption only runs when the control is actually redrawn -- which in a headless run,
	# and for any button that is currently hidden, it is not. So every caller has to set
	# `label` explicitly, and this asserts the real call paths do.
	#
	# This check earned its place: it caught vn_chrome.open_choice() assigning `.text` on
	# two freshly-converted ShapedButtons, which would have shipped a choice screen with
	# two blank tags on it and nothing in the log.
	var vnc: Node = game.find_child("VnChrome", true, false)
	vnc.call("open_choice", "Keep it or wipe it?", "keep the photograph", "wipe it",
			func(_i: int) -> void: pass)
	await process_frame
	for nm in ["ChoiceA", "ChoiceB"]:
		var cb := game.find_child(nm, true, false) as ShapedButton
		if cb and cb.label == "":
			bad.append("%s has no label after open_choice -- it would draw NO words" % nm)
	# and the pause / ending buttons, which go through hud._btn_text
	var h := game.get_node("HUD")
	h.call("apply_locale")
	await process_frame
	for nm in ["Resume", "Restart", "EndingNext"]:
		var pb := h.find_child(nm, true, false) as ShapedButton
		if pb and pb.label == "":
			bad.append("%s has no label -- it would draw NO words" % nm)
	# and every ShapedButton anywhere in the tree must have a non-default shape
	for b in _all(game):
		if b is ShapedButton and (b as ShapedButton).shape != ShapedButton.Shape.TAG:
			bad.append("%s uses shape %d, not the game's TAG" % [b.name, (b as ShapedButton).shape])
	if bad.is_empty():
		print("BUTTONS_OK shaped=%d" % n); quit(0)
	for e in bad: push_error(e)
	quit(1)

func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
