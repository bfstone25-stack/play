extends Node
## Headless test scene for FOLD.
##
##   $GODOT --headless --path . res://tests/run_tests.tscn
##
## A scene rather than --script, following play/overtime-idle-godot/tests: the autoloads
## (Fold, Save, I18n, Sfx, Tel) exist here, so the rules under test are the ones the game
## runs, not a second copy constructed for the test.
##
## Two halves:
##   1. hand-written checks on the loader, the traversal order, undo and the stars — the
##      cases a reader would want named;
##   2. the JS <-> GDScript conformance replay over tests/conformance.json: all 201
##      shipped levels, 7,643 recorded moves, every tile's id/row/column/value compared
##      after every single move.
##
## The rounding trap that play/overtime-idle-godot/scripts/idle.gd documents — JS
## `toFixed` rounds ties away from zero, C's `%.f` rounds them to even — has no purchase
## in FOLD, because the rules are integer throughout. `_no_floats()` asserts that rather
## than assuming it: it walks every value the JSON pins and fails if a non-integer ever
## appears, so if someone later adds a float score the test says so on that commit
## instead of the port drifting quietly.

var passed := 0
var failed := 0
var _first_fail := ""


func ok(c: bool, m: String) -> void:
	if c:
		passed += 1
		print("  ok   " + m)
	else:
		failed += 1
		if _first_fail == "":
			_first_fail = m
		printerr("  FAIL " + m)


func eq(a, b, m: String) -> void:
	ok(a == b, m + " (got " + JSON.stringify(a) + ", want " + JSON.stringify(b) + ")")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_levels()
	_loader()
	_order()
	_undo()
	_stars()
	_fonts()
	_conformance()
	print("\n%d checks passed, %d failed" % [passed, failed])
	if failed > 0:
		print("first failure: " + _first_fail)
	print("TESTS_OK" if failed == 0 else "TESTS_FAILED")
	get_tree().quit(0 if failed == 0 else 1)


func _levels() -> void:
	print("levels")
	eq(Fold.level_count(), 201, "the shipped 201 levels loaded")
	eq(Fold.level_name(0, "en"), "Warmup", "English half of the name")
	eq(Fold.level_name(0, "zh"), "入门", "Chinese half of the name")
	eq(Fold.CURATED, 51, "the picker splits curated from endless at 51")
	eq(Fold.FREE_LEVELS, 50, "levels 1-50 are the free track")


func _loader() -> void:
	print("loader")
	Fold.load_level(0)
	eq(Fold.rows, 1, "level 1 is one row")
	eq(Fold.cols, 2, "level 1 is two columns")
	eq(Fold.tiles.size(), 2, "two pieces")
	eq(Fold.target(), 4, "target 4")
	Fold.load_level(2)                      # [[2,'x',2],[2,0,2]]
	eq(Fold.walls.size(), 1, "level 3 has one wall")
	ok(Fold.is_wall(0, 1), "the wall is at (0,1)")
	eq(Fold.tiles.size(), 4, "four pieces around it")
	# a level whose rows are not all the same length: C is the widest row and the short
	# row's missing cells are empty, as `undefined` is in the JS
	var widest := 0
	var ragged := -1
	for i in range(Fold.level_count()):
		var g: Array = Fold.level(i)["grid"]
		var lens := {}
		for row in g:
			lens[(row as Array).size()] = true
		if lens.size() > 1:
			ragged = i
			break
	if ragged >= 0:
		Fold.load_level(ragged)
		var g2: Array = Fold.level(ragged)["grid"]
		for row in g2:
			widest = maxi(widest, (row as Array).size())
		eq(Fold.cols, widest, "a ragged level takes its column count from the widest row")
	else:
		print("  ..   no ragged level in the shipped set (the rule is still ported)")
		passed += 1


func _order() -> void:
	print("traversal order and merge identity")
	# level 1: [2,2] pushed right. The JS visits the far tile first, so the tile that
	# SURVIVES is id 1 (the right-hand one) and id 0 is the one removed.
	Fold.load_level(0)
	eq(Fold.move(0, 1), 1, "one merge")
	eq(Fold.tiles.size(), 1, "one piece left")
	eq(int(Fold.tiles[0]["id"]), 1, "the far piece is the survivor — the JS id, not ours")
	eq(int(Fold.tiles[0]["v"]), 4, "and it doubled")
	ok(Fold.is_won(), "level 1 is solved by one swipe")
	# pushed left instead, id 0 survives
	Fold.load_level(0)
	Fold.move(0, -1)
	eq(int(Fold.tiles[0]["id"]), 0, "pushing the other way leaves the other id")
	# a refused move changes nothing and does not count
	Fold.load_level(3)                      # [[2,2],[2,2]]
	var before := Fold.snapshot()
	Fold.load_level(3)
	eq(Fold.moves, 0, "counter starts at zero")
	Fold.move(0, 1)
	var after_one := Fold.moves
	var r := Fold.move(0, 1)                # everything is already hard right
	eq(r, -1, "a move with nowhere to go is refused")
	eq(Fold.moves, after_one, "and does not increment the counter")
	ok(before.size() == 4, "the snapshot held all four pieces")


func _undo() -> void:
	print("undo")
	Fold.load_level(6)                      # Ladder, par 5 — several moves deep
	Fold.move(1, 0)
	Fold.move(0, 1)
	var mid := Fold.snapshot()
	Fold.move(-1, 0)
	ok(Fold.undo(), "undo returns true when there is history")
	eq(JSON.stringify(Fold.snapshot()), JSON.stringify(mid), "and puts the board back exactly")
	eq(Fold.moves, 2, "counter stepped back")
	Fold.undo()
	Fold.undo()
	eq(Fold.moves, 0, "back to the start")
	ok(not Fold.undo(), "undo at the start does nothing")
	eq(Fold.moves, 0, "and never goes below zero")
	# undo refuses once solved, as the JS does
	Fold.load_level(0)
	Fold.move(0, 1)
	ok(Fold.done, "solved")
	ok(not Fold.undo(), "undo is refused on a solved level")


func _stars() -> void:
	print("stars")
	eq(Fold.stars_for(1, 1), 3, "par exactly is three stars")
	eq(Fold.stars_for(2, 1), 2, "one over par is two")
	eq(Fold.stars_for(3, 1), 2, "two over par is still two")
	eq(Fold.stars_for(4, 1), 1, "three over par is one")
	eq(Fold.stars_for(0, 5), 3, "under par is three")


func _fonts() -> void:
	print("fonts (the zh build must not be tofu)")
	var fb = StudioTheme.cjk()
	ok(fb != null, "the CJK subset is present and loadable")
	if fb == null:
		return
	var disp := StudioTheme.font("display")
	var w := disp.get_string_size("归一", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	ok(w > 10.0, "a Chinese glyph measures non-zero in the display face (%.1f px)" % w)
	var ui := StudioTheme.font("ui")
	ok(ui.get_string_size("关卡", HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > 5.0, "and in the UI face")
	ok(StudioTheme.build() != null, "the theme builds")


# --- conformance ---------------------------------------------------------------------------

## `want` comes from the fixture as flat [id, r, c, v] arrays (see the note in
## tests/conformance_gen.cjs); `got` is _canonical()'s list of the same four numbers.
func _tiles_eq(got: Array, want: Array) -> bool:
	if got.size() != want.size():
		return false
	for i in range(got.size()):
		var w: Array = want[i]
		if got[i][0] != int(w[0]) or got[i][1] != int(w[1]) \
				or got[i][2] != int(w[2]) or got[i][3] != int(w[3]):
			return false
	return true


## The GDScript board in the JSON's canonical order: by row, then column, then id.
func _canonical() -> Array:
	var out := []
	for t in Fold.tiles:
		out.append([int(t["id"]), int(t["r"]), int(t["c"]), int(t["v"])])
	out.sort_custom(func(a, b):
		if a[1] != b[1]: return a[1] < b[1]
		if a[2] != b[2]: return a[2] < b[2]
		return a[0] < b[0])
	return out


## Every number the JS pinned is an integer. If that ever stops being true, the JS/C
## tie-rounding split becomes reachable and this test should be the thing that says so.
func _no_floats(data: Dictionary) -> void:
	var bad := 0
	for lv in data["levels"]:
		for s in lv["steps"]:
			for t in s["tiles"]:
				for v in t:
					if float(v) != floor(float(v)):
						bad += 1
			if float(s["moves"]) != floor(float(s["moves"])) or float(s["stars"]) != floor(float(s["stars"])):
				bad += 1
	eq(bad, 0, "every pinned quantity is an integer, so no JS/C tie-rounding split exists")


func _conformance() -> void:
	print("JS <-> GDScript conformance (tests/conformance.json)")
	var f := FileAccess.open("res://tests/conformance.json", FileAccess.READ)
	if f == null:
		ok(false, "tests/conformance.json missing — run: node tests/conformance_gen.cjs")
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Dictionary):
		ok(false, "conformance.json did not parse")
		return
	eq(int(data["levelCount"]), Fold.level_count(), "the fixture covers every shipped level")
	_no_floats(data)

	var bad_initial := 0
	var bad_move := 0
	var bad_stars := 0
	var bad_undo := 0
	var total_moves := 0
	var first := ""

	for lv in data["levels"]:
		var i := int(lv["index"])
		Fold.load_level(i)
		if not _tiles_eq(_canonical(), lv["initial"]["tiles"]):
			bad_initial += 1
			if first == "":
				first = "level %d initial: got %s want %s" % [i, JSON.stringify(_canonical()), JSON.stringify(lv["initial"]["tiles"])]
		if int(lv["target"]) != Fold.target() or int(lv["par"]) != Fold.par():
			bad_initial += 1

		for s in lv["steps"]:
			total_moves += 1
			var d: Array = s["dir"]
			var before_moves := Fold.moves
			var res := Fold.move(int(d[0]), int(d[1]))
			var did := Fold.moves != before_moves
			var same := did == bool(s["moved"]) and Fold.moves == int(s["moves"]) \
				and _tiles_eq(_canonical(), s["tiles"]) and Fold.done == bool(s["done"])
			if not same:
				bad_move += 1
				if first == "":
					first = "level %d move %d dir %s: got moved=%s moves=%d %s want moved=%s moves=%d %s" % [
						i, total_moves, JSON.stringify(d), str(did), Fold.moves, JSON.stringify(_canonical()),
						str(s["moved"]), int(s["moves"]), JSON.stringify(s["tiles"])]
			if bool(s["won"]):
				if not Fold.is_won() or Fold.stars() != int(s["stars"]):
					bad_stars += 1
					if first == "":
						first = "level %d stars: got %d want %d" % [i, Fold.stars(), int(s["stars"])]
			if res == -1 and bool(s["moved"]):
				bad_move += 1

		# undo run: replay the same directions on a fresh board, unwind them all
		Fold.load_level(i)
		for d in lv["dirs"]:
			Fold.move(int(d[0]), int(d[1]))
		if not _tiles_eq(_canonical(), lv["undo"]["from"]["tiles"]):
			bad_undo += 1
		for st in lv["undo"]["states"]:
			Fold.undo()
			if not _tiles_eq(_canonical(), st["tiles"]) or Fold.moves != int(st["moves"]):
				bad_undo += 1
				if first == "":
					first = "level %d undo: got %s/%d want %s/%d" % [i, JSON.stringify(_canonical()), Fold.moves, JSON.stringify(st["tiles"]), int(st["moves"])]
				break

	print("  replayed %d levels, %d moves" % [Fold.level_count(), total_moves])
	eq(bad_initial, 0, "every level's opening layout matches the JS loader")
	eq(bad_move, 0, "every recorded move matches the JS, tile for tile")
	eq(bad_stars, 0, "every win scores the same stars")
	eq(bad_undo, 0, "every undo unwinds to the same board")
	if first != "":
		printerr("  first divergence: " + first)
