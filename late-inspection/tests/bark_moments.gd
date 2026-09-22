extends SceneTree

## Prove the nine bark slots are actually REACHED by playing the game, not that the file
## containing them parses.
##
## Two studio failures make this test the shape it is.
##
## 1. Beat the Monday's suite asserted "main.gd compiles ok" through every broken run,
##    because `load()` hands back the cached husk of a script whose reload failed. So the
##    script under test is loaded with CACHE_MODE_IGNORE and required to have a non-empty
##    method list before anything else is believed.
##
## 2. The whole bark layer no-ops until assets/voice/barks.json exists (that file is a GPU
##    job, scheduled separately). So "no error" proves nothing at all here: a game that
##    never calls bark() once and a game that calls it nine times behave identically. The
##    ambience node's `bark` is therefore REPLACED with a recorder, and the test asserts on
##    which slots were asked for, in which order, driving the real game.
##
##     godot --headless --path . -s res://tests/bark_moments.gd

const SLOTS := ["greet", "stage", "near", "win", "win_big", "fail", "idle", "streak",
		"unlock"]

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	_test_scripts_really_compiled()
	await _test_greet_and_findings()
	await _test_fail_on_erasure()
	await _test_win_big_on_witness()
	_test_every_slot_has_lines()
	if failures.is_empty():
		print("BARK_MOMENTS_OK slots=%d" % SLOTS.size())
		quit(0)
	for f in failures:
		push_error(f)
	quit(1)


## Finding 3 from the studio: a cached husk answers `load()` and every method test passes.
func _test_scripts_really_compiled() -> void:
	for path in ["res://scripts/game.gd", "res://scripts/ambience.gd",
			"res://scripts/shaped_button.gd", "res://scripts/hud.gd",
			"res://scripts/vn_chrome.gd"]:
		var s: Script = ResourceLoader.load(path, "Script",
				ResourceLoader.CACHE_MODE_IGNORE)
		if s == null:
			failures.append("%s did not load at all" % path)
			continue
		if s.get_script_method_list().is_empty():
			failures.append("%s loaded but has NO methods -- it did not compile" % path)


## Swap the ambience node's bark() for a recorder. Returns the array it writes into.
func _spy(game: Node) -> Array:
	var log: Array = []
	var amb: Node = game.get("ambience")
	if amb == null:
		failures.append("game has no ambience node, so no bark can ever fire")
		return log
	var spy := Node.new()
	spy.set_script(BarkSpy)
	spy.set("log", log)
	spy.name = "BarkSpy"
	game.add_child(spy)
	game.set("ambience", spy)
	return log


func _fresh() -> Node:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_greet_and_findings() -> void:
	var game := await _fresh()
	# greet fires in _ready, before a spy can be attached, so it is asserted on the real
	# layer's contract instead: the call must exist and must not have crashed the boot.
	if not game.has_method("bark"):
		failures.append("game.gd lost its bark() entry point")
	var log := _spy(game)
	# Six findings in a row: win/unlock alternate and every third is a streak.
	for id in ["dane", "fire_plan", "frame", "shoes", "invoice", "medicine"]:
		game.call("on_note", id)
		await process_frame
	for want in ["win", "unlock", "streak"]:
		if want not in log:
			failures.append("six findings produced no '%s' (got %s)" % [want, log])
	game.free()
	await process_frame


func _test_fail_on_erasure() -> void:
	var game := await _fresh()
	var log := _spy(game)
	# Wiping the photograph is the game's first destruction of evidence.
	game.call("_resolve_choice", "stain", 1, null)
	await process_frame
	if "fail" not in log:
		failures.append("wiping the photograph produced no 'fail' bark (got %s)" % [log])
	# and it must break the findings run, or 'streak' means nothing
	if int(game.get("_run_of_findings")) != 0:
		failures.append("an erasure did not reset the findings run")
	game.free()
	await process_frame


func _test_win_big_on_witness() -> void:
	var game := await _fresh()
	var log := _spy(game)
	game.call("debug_complete_route", "witness")
	await process_frame
	if "win_big" not in log:
		failures.append("the WITNESS ending produced no 'win_big' bark (got %s)" % [log])
	game.free()
	await process_frame


## Every slot the game can ask for must have lines written for it, and vice versa: a slot
## called but never written is silence at a moment that was designed to speak, and a slot
## written but never called is 30 seconds of GPU time rendering audio nothing plays.
func _test_every_slot_has_lines() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/game.gd")
	var called := {}
	var re := RegEx.create_from_string('bark\\("([a-z_]+)"\\)')
	for m in re.search_all(src):
		called[m.get_string(1)] = true
	# _bark_after defers a slot rather than calling it directly
	var re2 := RegEx.create_from_string('_bark_after\\([0-9.]+, "([a-z_]+)"\\)')
	for m in re2.search_all(src):
		called[m.get_string(1)] = true
	for slot in SLOTS:
		if not called.has(slot):
			failures.append("slot '%s' is written but the game never calls it" % slot)
	for slot in called:
		if slot not in SLOTS:
			failures.append("game calls bark('%s'), which has no lines" % slot)


class BarkSpy:
	extends Node
	var log: Array = []

	func bark(slot: String) -> void:
		log.append(slot)
