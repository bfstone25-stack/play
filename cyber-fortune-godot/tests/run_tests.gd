extends Node
## Headless test scene:   $GODOT --headless --path . res://tests/run_tests.tscn
## A scene, not --script: the autoloads (Tx, Fortune, Gate, Sfx) exist here, so the
## machine under test is the one the game runs.
##   - merit.js conformance on the same inputs (tests/merit_conformance.json)
##   - the rank distribution and the pity force
##   - the daily free draw, the merit cost, keep / burn
##   - the timed 化解 with a moved clock, the bonus, the rack cap
##   - the four forces: every input path lands on the predicted answer
##   - pool sanity: 150 slips over 36 cells, 78 cards x 2 all reachable, no empty line

var passed := 0
var failed := 0


func ok(c: bool, m: String) -> void:
	if c:
		passed += 1
		print("  ok   " + m)
	else:
		failed += 1
		printerr("  FAIL " + m)


func eq(a, b, m: String) -> void:
	ok(a == b, m + " (got " + JSON.stringify(a) + ", want " + JSON.stringify(b) + ")")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	Fortune.persist_enabled = false
	Fortune.reset()
	_merit_conformance()
	_ladder()
	_daily_and_cost()
	_resolve()
	_reader()
	_pools()
	_teller_states()
	_persistence()
	print("\n%d checks passed, %d failed" % [passed, failed])
	print("TESTS_OK" if failed == 0 else "TESTS_FAILED")
	get_tree().quit(0 if failed == 0 else 1)


func _merit_conformance() -> void:
	print("merit.js conformance")
	var f := FileAccess.open("res://tests/merit_conformance.json", FileAccess.READ)
	var steps: Array = JSON.parse_string(f.get_as_text())
	var m := MeritCurve.new()
	var bad := 0
	for st in steps:
		var op: Array = st["op"]
		var ret
		match str(op[0]):
			"click": ret = m.click()
			"tick": ret = m.tick(float(op[1]))
			"upgrade": ret = m.try_upgrade()
			"load": ret = m.load(op[1])
		var snap := m.snapshot()
		var want: Dictionary = st["snap"]
		var same := true
		for k in want:
			if int(want[k]) != int(snap[k]):
				same = false
		if typeof(ret) == TYPE_BOOL or typeof(ret) == TYPE_INT:
			if typeof(st["ret"]) == TYPE_BOOL:
				same = same and (ret == st["ret"])
			else:
				same = same and (int(ret) == int(st["ret"]))
		if not same:
			bad += 1
			if bad < 4:
				printerr("    step %s: got %s want %s" % [JSON.stringify(op), JSON.stringify(snap), JSON.stringify(want)])
	eq(bad, 0, "%d steps of clicks/ticks/upgrades/loads match merit.js" % steps.size())
	eq(m.snapshot()["merit"], 142, "final merit as the JS run")


func _ladder() -> void:
	print("rank ladder")
	Fortune.reset()
	Fortune.rng.seed = 20260918
	var counts := {}
	for r in Fortune.RANKS:
		counts[r] = 0
	var run := 0
	var worst := 0
	var forced_seen := false
	for i in range(30000):
		var pity_before: int = Fortune.pity
		var r: String = Fortune.roll_rank()
		counts[r] += 1
		if r == "zhongji" or r == "daji":
			run = 0
		else:
			run += 1
		worst = maxi(worst, run)
		if pity_before == 9:
			forced_seen = true
			ok(r == "zhongji" or r == "daji", "the 10th draw without 中吉 is forced (%s)" % r) if i < 200 else null
	for r in Fortune.RANKS:
		var share: float = counts[r] / 30000.0
		var w: float = Fortune.WEIGHTS[r] / 100.0
		# the pity force lifts 中吉 above its weight and trims the rest; wide bounds, but
		# the shape has to hold: 末吉 most common, 大吉 rarest
		print("    %s %.3f (weight %.2f)" % [r, share, w])
	ok(counts["moji"] > counts["xiaoji"] and counts["xiaoji"] > counts["xiong"] and counts["xiong"] > counts["daxiong"] and counts["daxiong"] > counts["daji"], "the shape holds: 末吉 > 小吉 > 凶 > 大凶 > 大吉")
	ok(counts["daji"] / 30000.0 < 0.06, "大吉 stays rare: %.3f" % (counts["daji"] / 30000.0))
	eq(worst, 9, "never more than nine draws without 中吉 or better")
	ok(forced_seen, "the pity force fired")


func _daily_and_cost() -> void:
	print("daily draw and the tube")
	Fortune.reset()
	Fortune.rng.seed = 7
	ok(Fortune.free_available(), "a fresh account has today's free draw")
	var r := Fortune.draw("slip", "work")
	ok(not r.is_empty() and r["free"], "the first draw is free")
	eq(r["subject"], "work", "the subject asked for")
	ok(not Fortune.slip(r["id"]).is_empty(), "the slip exists in the pool")
	ok(Fortune.draw("slip").is_empty(), "no second draw while one is unread")
	ok(Fortune.keep(), "kept")
	eq(Fortune.have_slips.size(), 1, "the collection has it")
	ok(Fortune.draw("card").is_empty(), "no merit: the deck will not turn")
	ok(not Fortune.free_available(), "one free draw a day, per account, not per instrument")
	for _i in range(100):
		Fortune.tap()
	eq(Fortune.merit.merit, 100, "100 taps at level 1 = 100 merit")
	var c := Fortune.draw("card")
	ok(not c.is_empty() and not c["free"], "a full tube turns a card")
	eq(Fortune.merit.merit, 0, "the draw cost 100")
	ok(not Fortune.card(c["id"]).is_empty(), "the card exists")
	ok(c.has("reversed") and c["position"] in Fortune.POSITIONS, "a card has an orientation and a position")
	var expect_rev: bool = Fortune.RANK_TIERS[c["rank"]]["reversed"]
	eq(c["reversed"], expect_rev, "orientation follows the rank")
	var back := Fortune.burn()
	eq(back, Fortune.BURN[c["rank"]], "burning gives the rank's merit back")
	Fortune.clock_offset_ms += 86400000
	ok(Fortune.free_available(), "tomorrow the free draw is back")
	Fortune.buy("extra_draw")
	Fortune.draw("slip")
	Fortune.keep()
	ok(Fortune.free_available(), "extra_draw: a second free draw today")
	Fortune.draw("slip")
	Fortune.keep()
	ok(not Fortune.free_available(), "and then it is spent")
	var before: int = Fortune.pity
	Fortune.buy("merit_l")
	eq(Fortune.pity, before, "buying merit does not touch the ladder")
	eq(Fortune.merit.merit, 2000 + back, "merit_l granted 2000")


func _resolve() -> void:
	print("化解 on the rack")
	Fortune.reset()
	Fortune.rng.seed = 3
	Fortune.merit.merit = 1000
	# force an ill slip: roll until one lands
	var r := {}
	var guard := 0
	while guard < 200:
		guard += 1
		r = Fortune.draw("slip", "money")
		if Fortune.is_ill(r["rank"]):
			break
		Fortune.burn()
		Fortune.merit.merit = 1000
	ok(Fortune.is_ill(r["rank"]), "an ill slip drawn (%s)" % r["rank"])
	var m0: int = Fortune.merit.merit
	ok(Fortune.resolve(), "tied to the rack")
	eq(Fortune.merit.merit, m0 - Fortune.RESOLVE_COST[r["rank"]], "化解 cost the rank's merit")
	eq(Fortune.rack.size(), 1, "one on the rack")
	ok(not Fortune.rack_ready(0), "not ready at once")
	ok(not Fortune.claim(0), "cannot claim early")
	Fortune.clock_offset_ms += int(Fortune.RESOLVE_MS[r["rank"]]) - 1000
	ok(not Fortune.rack_ready(0), "not ready one second early")
	Fortune.clock_offset_ms += 1000
	ok(Fortune.rack_ready(0), "ready when the delay has passed")
	ok(Fortune.claim(0), "claimed")
	eq(Fortune.resolved_bonus, 1, "one permanent bonus")
	var gain := Fortune.tap()
	eq(gain, 2, "a tap now gives the curve's 1 plus the bonus 1")
	eq(Fortune.have_slips.size(), 1, "the resolved slip joined the collection")
	# the rack cap and resolve_now
	Fortune.merit.merit = 5000
	var tied := 0
	guard = 0
	while tied < 4 and guard < 400:
		guard += 1
		var d := Fortune.draw("card")
		if d.is_empty():
			break
		if Fortune.is_ill(d["rank"]):
			if Fortune.resolve():
				tied += 1
			else:
				Fortune.burn()
		else:
			Fortune.burn()
		Fortune.merit.merit = 5000
	eq(Fortune.rack.size(), 3, "the rack holds three by default; the fourth was refused")
	ok(Fortune.buy("rack_slot"), "rack_slot bought")
	eq(Fortune.rack_slots, 4, "four slots")
	ok(Fortune.buy("resolve_now"), "resolve_now")
	ok(Fortune.rack_ready(0), "the oldest is ready at once")
	ok(not Fortune.rack_ready(1), "the others still wait")
	ok(Fortune.rack[0]["kind"] == "card" and Fortune.rack[0]["reversed"], "a reversed card integrates the same way")


func _reader() -> void:
	print("the reader's forces")
	# binary: every number 1..63, answering honestly per card
	var bad := 0
	for n in range(1, 64):
		var answers := []
		for k in range(6):
			answers.append(n in ReaderForces.binary_card(k))
		if ReaderForces.binary_result(answers) != n:
			bad += 1
	eq(bad, 0, "binary force: all 63 numbers land")
	eq(ReaderForces.binary_card(0).size(), 32, "each card carries 32 numbers")
	eq(ReaderForces.binary_card(5)[0], 32, "the sixth card starts at 32")
	# math: integers, negatives, halves
	bad = 0
	for i in range(-200, 2001):
		if ReaderForces.math_result(i) != 4:
			bad += 1
		if ReaderForces.math_result(i + 0.5) != 4:
			bad += 1
	eq(bad, 0, "math force: every start from -200 to 2000 (and halves) lands on 4")
	eq(ReaderForces.math_trace(7), [7.0, 14.0, 22.0, 11.0, 4.0], "the trace for 7")
	eq(str(Fortune.reader["forces"]["math"]["symbols"][ReaderForces.MATH_ANSWER - 1]["en"]), "the lantern", "the fourth symbol on the table is the lantern")
	# princess
	bad = 0
	for c in ReaderForces.PRINCESS_SHOW:
		if not ReaderForces.princess_gone(c):
			bad += 1
	eq(bad, 0, "princess: whichever of the five is remembered, it is gone")
	eq(ReaderForces.PRINCESS_AFTER.size(), 4, "four come back")
	for c in ReaderForces.PRINCESS_SHOW + ReaderForces.PRINCESS_AFTER:
		ok(not Fortune.card(c).is_empty(), "card exists: " + c)
	# equivoque: 6 pairs x 2 hands
	bad = 0
	var paths := 0
	for pair in ReaderForces.equivoque_pairs():
		var s1 := ReaderForces.equivoque_push(pair)
		for h in s1["pair"]:
			paths += 1
			var s2 := ReaderForces.equivoque_hand(s1["pair"], h)
			if s2["result"] != "candle":
				bad += 1
			if not ("candle" in s1["pair"]):
				bad += 1
	eq(paths, 12, "twelve paths through the two choices")
	eq(bad, 0, "equivoque: every path ends on the candle")


func _pools() -> void:
	print("the pools")
	eq(Fortune.slips.size(), 150, "150 slips")
	var cells := {}
	var empty := 0
	for s in Fortune.slips:
		cells[s["rank"] + "/" + s["subject"]] = true
		for k in ["verse_zh", "verse_en", "read_zh", "read_en", "do_zh", "do_en"]:
			if str(s[k]).strip_edges() == "":
				empty += 1
		if str(s["verse_zh"]).length() != 4:
			empty += 1
	eq(cells.size(), 36, "all 6 ranks x 6 subjects have slips")
	eq(empty, 0, "every slip has four lines and a four-character 签文")
	eq(Fortune.cards.size(), 78, "78 cards")
	empty = 0
	for c in Fortune.cards:
		for k in ["up_zh", "up_en", "up_do_zh", "up_do_en", "rev_zh", "rev_en", "rev_do_zh", "rev_do_en", "name_zh", "name_en", "glyph"]:
			if str(c[k]).strip_edges() == "":
				empty += 1
	eq(empty, 0, "156 readings, all written")
	# reachability: every (card, orientation) is produced by some rank
	var reach := {}
	for rank in Fortune.RANKS:
		var spec: Dictionary = Fortune.RANK_TIERS[rank]
		for c in Fortune.cards:
			if c["tier"] in spec["tiers"]:
				reach[c["slug"] + (":rev" if spec["reversed"] else ":up")] = true
	eq(reach.size(), 156, "all 78 x 2 reachable from the ladder")
	# the free draw covers both instruments from the same pool of days
	for k in ["binary", "math", "princess", "equivoque"]:
		ok(Fortune.reader["forces"].has(k), "reader script has " + k)
		# Every force ends through reader_screen._reveal, which speaks a half-line before
		# the dim-and-hold. A force with no "beat" falls back to a bare "…" and its reveal
		# stops sharing the rhythm — that is the regression this catches.
		var bts: Array = Fortune.reader["forces"][k].get("beat", [])
		ok(bts.size() > 0, "reader force has a beat line before the hold: " + k)


func _persistence() -> void:
	print("persistence")
	Fortune.reset()
	Fortune.merit.merit = 77
	Fortune.have_slips["x"] = 2
	Fortune.rack.append({"kind": "slip", "id": "y", "rank": "xiong", "reversed": false, "at": 1, "ready_at": 2})
	var snap := Fortune.snapshot()
	var text := JSON.stringify(snap)
	Fortune.reset()
	Fortune.load_from(JSON.parse_string(text))
	eq(Fortune.merit.merit, 77, "merit round-trips through JSON")
	eq(int(Fortune.have_slips.get("x", 0)), 2, "collection round-trips")
	eq(Fortune.rack.size(), 1, "the rack round-trips")
	Fortune.reset()


## The reader's three states, checked on the class the game actually draws.
##
## The browser drive cannot pin this down: whether the eyes-closed plate is on screen
## depends on catching a 1-second hold at the right millisecond, and a shot taken a beat
## late shows the calm face and looks like a pass. So the swap is checked here instead —
## a Teller in a headless tree, each mood set, each resulting texture named.
func _teller_states() -> void:
	print("the reader's sprite")
	var Teller = load("res://scripts/reader_screen.gd").Teller
	var t = Teller.new()
	add_child(t)
	var want := {"waiting": "calm", "listening": "calm", "reveal": "reveal", "warm": "giveback"}
	ok(t.has_sprite(), "the reader has a rendered portrait (else the drawn figure is the fallback)")
	var seen := {}
	for mood in want:
		t.mood = mood
		var tex: Texture2D = t._cur
		ok(tex != null, "mood %s has a texture" % mood)
		if tex != null:
			var path := tex.resource_path
			ok(path.ends_with("reader_%s.webp" % want[mood]),
				"mood %s draws reader_%s (got %s)" % [mood, want[mood], path.get_file()])
			seen[want[mood]] = true
	eq(seen.size(), 3, "the three states are three named plates")
	# By path alone this passes when the same picture is installed three times — which is
	# exactly what a mis-typed picks JSON produces. Compare the pixels.
	var hashes := {}
	for st in ["calm", "reveal", "giveback"]:
		var tex: Texture2D = t._tex.get(st)
		if tex != null:
			hashes[hash(tex.get_image().get_data())] = st
	eq(hashes.size(), 3, "the three states are three different pictures")
	t.queue_free()
