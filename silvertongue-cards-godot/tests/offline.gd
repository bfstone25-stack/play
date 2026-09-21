## Does the GDScript offline engine agree with the Python that owns the rules?
##
## tools/export_offline.py plays a scripted duel with the backend's own cards.play_card()
## and writes every turn to assets/offline/transcript.json. This replays the same cards in
## the same order through scripts/offline.gd and compares phase, momentum, evidence,
## eligibility, nerve and the card kind, turn by turn.
##
## The point is the memory note `verification-that-lies`: a parity check that can only pass
## is not a check. `--prove-it-fails` corrupts one number on purpose and expects the run to
## fail, so the harness has been seen failing before anyone trusts it passing.
##
##   godot --headless --path play/silvertongue-cards-godot res://tests/offline.tscn
##   godot --headless --path . res://tests/offline.tscn -- --prove-it-fails
extends Node

const TRANSCRIPT := "res://assets/offline/transcript.json"

var fails := 0
var checks := 0


func _ready() -> void:
	var sabotage := "--prove-it-fails" in OS.get_cmdline_user_args()
	var f := FileAccess.open(TRANSCRIPT, FileAccess.READ)
	if f == null:
		_fail("transcript missing — run tools/export_offline.py")
		_done()
		return
	var t: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()

	# The duel is built by hand rather than by new_duel(), because the deck SHUFFLE is the
	# one thing the two engines cannot share: Python's random.Random and Godot's shuffle()
	# are different generators. What must agree is the rules, so the hand is loaded with
	# exactly the cards the Python played, in order.
	var d := {"scenario": str(t["scenario"]), "difficulty": str(t["difficulty"]),
			  "deck": [], "hand": (t["script"] as Array).duplicate(), "discard": [],
			  "state": {}, "nerve": int(Offline._t("nerve_start", 1)),
			  "wild_left": 1, "over": false, "won": false, "daily": false, "log": []}

	var i := 0
	for want in t["turns"]:
		var read := Offline.play_card(d, str(want["card"]))
		if read.has("error"):
			_fail("turn %d: %s" % [i, read["error"]])
			break
		var momentum := float(read["momentum"])
		if sabotage and i == 1:
			momentum += 0.11
		_eq("turn %d phase" % i, str(read["phase_after"]), str(want["phase"]))
		_eq("turn %d momentum" % i, "%.2f" % momentum, "%.2f" % float(want["momentum"]))
		_eq("turn %d evidence" % i, ",".join(read["evidence"]), ",".join(want["evidence"]))
		_eq("turn %d eligible" % i, str(bool(read["eligible"])), str(bool(want["eligible"])))
		_eq("turn %d nerve" % i, str(int(read["nerve"])), str(int(want["nerve"])))
		_eq("turn %d kind" % i, str(read["kind"]), str(want["kind"]))
		_eq("turn %d over" % i, str(bool(read["over"])), str(bool(want["over"])))
		i += 1

	# The tables themselves must be present and complete, or the engine is arithmetic over
	# nothing and every screen renders empty — which is the bug this whole file exists for.
	_eq("scenarios", str(Offline.data.get("scenarios", []).size()), "5")
	_true("cards exported", Offline.by_id.size() >= 60)
	_true("every scenario has an opening line",
		Offline.data.get("scenarios", []).all(func(s): return Offline.opening(str(s["id"])) != ""))
	_true("every scenario has a reply table",
		Offline.data.get("scenarios", []).all(func(s): return Offline.data["replies"].has(str(s["id"]))))
	# A fresh player can actually start: a collection, and an auto-deck big enough to deal.
	Offline.reset()
	_true("starter deck deals a hand",
		Offline.auto_deck("closing_time").size() >= int(Offline._t("hand_size", 3)))
	_true("state() has a roster", (Offline.state("en")["scenarios"] as Array).size() == 5)

	if sabotage:
		if fails > 0:
			print("PROVE-IT-FAILS: the harness caught the corrupted turn. %d failure(s)." % fails)
			get_tree().quit(0)
		else:
			print("PROVE-IT-FAILS: the harness did NOT catch a corrupted momentum. It cannot be trusted.")
			get_tree().quit(1)
		return
	_done()


func _eq(what: String, got: String, want: String) -> void:
	checks += 1
	if got != want:
		_fail("%s: got %s, want %s" % [what, got, want])


func _true(what: String, ok: bool) -> void:
	checks += 1
	if not ok:
		_fail(what)


func _fail(msg: String) -> void:
	fails += 1
	print("FAIL  ", msg)


func _done() -> void:
	print("offline parity: %d checks, %d failure(s)" % [checks, fails])
	get_tree().quit(1 if fails > 0 else 0)
