extends SceneTree

## The front door, held open.
##
## On 2026-09-20 every build was given the title screen, guarded by
## `if not OS.has_feature("headless")`. That feature tag does not exist on Godot 4.7 --
## `OS.has_feature("headless")` is false under --headless, while
## `DisplayServer.get_name()` returns "headless" -- so the gate opened in the test
## harness too. `advance()` returns early while `splash_open`, so all five routes in
## tests/playthrough.gd spun their 4000-iteration guard and failed, and the matrix from
## ops/play_driver.py showed four tiles that were all the same screen.
##
## Both symptoms, one unverified string. So this asserts the three facts that fix
## depends on, separately, and it is written so it FAILS if the old guard comes back:
##
##   1. the display server really is named "headless" here (if this ever stops being
##      true the guard below is wrong and must be found again, not silently inverted);
##   2. OS.has_feature("headless") is NOT a usable stand-in for it -- the assertion is
##      on the trap, not on the fix, because the trap is what someone will reach for;
##   3. a game built under --headless comes up with no splash and CAN advance.
##
## 3 is the one that matters to a player: it is the same code path as "the gate opens".

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() != "headless":
		failures.append("this test must be run with --headless; display server is %s"
				% DisplayServer.get_name())

	# The trap, asserted as a trap. If a future engine DOES set this tag the assertion
	# fires, someone reads this comment, and the guard gets revisited on purpose.
	if OS.has_feature("headless"):
		failures.append("OS.has_feature(\"headless\") is true now — re-read scripts/game.gd's "
				+ "_ready() guard; it was written because this was false")

	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	if game.splash_open:
		failures.append("the splash opened under --headless: the tests cannot reach the game")

	# And it actually moves. A splash-free build that still will not advance is the same
	# outage with a different cause, and this test exists to catch the outage.
	var before: int = game.beat_index
	game.advance()
	if game.beat_index == before and not game.awaiting_choice and not game.finished:
		failures.append("advance() did nothing with no splash open (beat_index stuck at %d)" % before)

	game.free()
	for f in failures:
		push_error(f)
	print("HEADLESS_OK" if failures.is_empty() else "HEADLESS_FAIL %d" % failures.size())
	quit(0 if failures.is_empty() else 1)
