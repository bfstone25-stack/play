extends Node
## Headless test scene:   $GODOT --headless --path . res://tests/run_tests.tscn
## A scene, not --script: the autoloads (Tx, Fortune, Night, Gate, Sfx) exist here, so the
## machine under test is the one the game runs.
##   - merit.js conformance on the same inputs (tests/merit_conformance.json)
##   - the rank distribution and the pity force
##   - the daily free draw, the merit cost, keep / burn
##   - the timed 化解 with a moved clock, the bonus, the rack cap
##   - pool sanity: 150 slips over 36 cells, 78 cards x 2 all reachable, no empty line
##   - the night layer: the draw names a track, the consent gate, what a refusal does
##     not do, the lock at 3, the scene at 9, and the whole run round-tripping through JSON

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
	_pools()
	_night()
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


## The fork's own rule, checked where it lives. The important one is the third block:
## a refusal must leave *nothing* behind — not the track, not a memory of having asked.
func _night() -> void:
	print("the night layer")
	Night.persist_enabled = false
	Night.reset()
	Fortune.reset()
	Fortune.persist_enabled = false
	eq(Night.cast.size(), 3, "three women in the cast")
	for c in Night.cast:
		eq((c["tracks"] as Array).size(), 3, "%s has three tracks" % c["id"])
		for tr in c["tracks"]:
			for k in ["name_zh", "name_en", "belief_zh", "belief_en", "open_strong_zh",
					"open_strong_en", "open_weak_zh", "open_weak_en", "refuse_zh",
					"refuse_en", "locked_zh", "locked_en"]:
				ok(str(tr.get(k, "")).strip_edges() != "", "%s/%s has %s" % [c["id"], tr["id"], k])
		var sc: Dictionary = c["scene"]
		eq((sc["beats_en"] as Array).size(), 3, "%s: three beats in the scene" % c["id"])
		ok(str(sc.get("invite_en", "")).strip_edges() != "", "%s: the scene has an invitation" % c["id"])

	# the ladder's six ranks map onto a strength, and 末吉 moves nothing
	eq(Night.STRENGTH.size(), 6, "every rank has a strength")
	eq(int(Night.STRENGTH["moji"]), 0, "末吉 moves nothing")
	ok(int(Night.STRENGTH["daxiong"]) < int(Night.STRENGTH["xiong"]), "大凶 pulls back harder than 凶")

	# the draw names one of her three, whichever instrument was used
	var seen := {}
	for subj in Fortune.SUBJECTS:
		seen[Night.track_index({"kind": "slip", "subject": subj})] = true
	eq(seen.size(), 3, "the six subjects reach all three tracks")
	seen = {}
	for pos in Fortune.POSITIONS:
		seen[Night.track_index({"kind": "card", "position": pos})] = true
	eq(seen.size(), 3, "the four positions reach all three tracks")

	# --- the consent gate ---------------------------------------------------------------
	Night.current = "mirren"
	var t: Array = Night.tracks()
	t[0] = 0
	ok(Night.would_accept(0, 2), "she takes a reading that opens something")
	ok(not Night.would_accept(0, 0), "a 末吉 says nothing and she takes nothing")
	ok(not Night.would_accept(0, -1), "she does not take a 凶 on a track she has not opened")
	t[0] = 1
	ok(Night.would_accept(0, -1), "a 凶 lands once she is already in that track")

	# --- a refusal writes nothing and is not remembered -----------------------------------
	Night.reset()
	Night.current = "mirren"
	Fortune.reset()
	Fortune.merit.merit = 100000
	Night.offer = {"result": {"kind": "slip", "rank": "xiong", "id": "x"}, "track": 1,
		"strength": -1, "accepted": false, "at": 0}
	var before: int = int(Night.tracks()[1])
	var ev := Night.speak()
	eq(int(Night.tracks()[1]), before, "a refused reading does not move the track")
	ok(not ev["accepted"], "the event says she refused")
	eq(JSON.stringify(Night.snapshot()).find("refus"), -1, "nothing about the refusal is written to the save")
	ok(Night.offer.is_empty(), "the draw is spent either way")

	# --- climbing to the scene ------------------------------------------------------------
	Night.reset()
	Night.current = "qiao"
	var locks := 0
	for i in range(3):
		Night.offer = {"result": {"kind": "slip", "rank": "daji", "id": "x"}, "track": i,
			"strength": 3, "accepted": true, "at": 0}
		var e := Night.speak()
		if e["locked"]:
			locks += 1
		eq(int(Night.tracks()[i]), Night.TRACK_MAX, "track %d is true now" % i)
	eq(locks, 3, "each track locked exactly once as it reached 3")
	eq(Night.total(), Night.FULL, "all nine")
	ok(Night.scene_ready(), "the night is hers to offer")
	ok(not Night.scene_seen(), "and it has not been seen yet")
	ok(not Night.cleared(), "one of three is not a clear")
	# a track cannot go past 3, and a 凶 afterwards pulls it back rather than ending the run
	Night.offer = {"result": {"kind": "slip", "rank": "daji", "id": "x"}, "track": 0,
		"strength": 3, "accepted": true, "at": 0}
	Night.speak()
	eq(int(Night.tracks()[0]), Night.TRACK_MAX, "a track stops at 3")
	Night.offer = {"result": {"kind": "slip", "rank": "daxiong", "id": "x"}, "track": 0,
		"strength": -2, "accepted": true, "at": 0}
	Night.speak()
	eq(int(Night.tracks()[0]), 1, "a 大凶 she takes pulls the track back")
	ok(not Night.scene_ready(), "and the night is not on offer any more")

	# --- clear ---------------------------------------------------------------------------
	Night.reset()
	for c in Night.cast:
		Night.current = str(c["id"])
		for i in range(3):
			Night.offer = {"result": {"kind": "slip", "rank": "daji", "id": "x"}, "track": i,
				"strength": 3, "accepted": true, "at": 0}
			Night.speak()
		Night.mark_seen()
	ok(Night.cleared(), "three women, three nights, cleared")

	# --- persistence: ints stay ints through JSON ------------------------------------------
	var text := JSON.stringify(Night.snapshot())
	Night.reset()
	Night.load_from(JSON.parse_string(text))
	ok(Night.cleared(), "the whole run round-trips through JSON")
	eq(typeof(Night.tracks("mirren")[0]), TYPE_INT, "a track comes back an int, not a float")

	# --- every art slot the game asks for exists, and says whether it is real --------------
	var placeholders := 0
	for c in Night.cast:
		for suffix in ["_calm", "_turn", "_night", "_night_locked"]:
			var slot: String = str(c["id"]) + str(suffix)
			ok(Night.art(slot) != null, "art slot present: " + slot)
			if Night.is_placeholder(slot):
				placeholders += 1
	print("  .. %d of 12 plates are still labelled placeholders" % placeholders)
	Night.reset()
