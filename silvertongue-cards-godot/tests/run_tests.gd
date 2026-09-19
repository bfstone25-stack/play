## Headless test scene (not --script: the autoloads Gate / Api / Sfx must be up).
##
##   ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --headless --path play/silvertongue-cards-godot res://tests/run_tests.tscn
##
## Needs the backend on 127.0.0.1:8929 (`play/silvertongue-cards/run.sh`). Uses a fresh
## pid per run so no real player's collection is touched. Exit code 0 = all passed.
extends Node

var failures := 0
var passed := 0
var pid := ""


func _ready() -> void:
	Sfx.muted = true
	pid = "gdtest_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
	Api.set_pid(pid)
	call_deferred("_run")


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
		print("  ok   ", what)
	else:
		failures += 1
		push_error("FAIL " + what)
		print("  FAIL ", what)


func _run() -> void:
	print("== scripts parse")
	await _t_scripts()
	print("== Api against the live backend (pid %s)" % pid)
	await _t_api()
	print("== hand state machine")
	await _t_hand()
	print("== duel scene: wild card path")
	await _t_wild()
	print("== duel scene: play to PERSUADED")
	await _t_persuaded()
	print("== %d passed, %d failed" % [passed, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _t_scripts() -> void:
	for s in ["palette", "studio_theme", "api", "sfx", "gate", "card", "chip", "gauge", "portrait", "hand",
			"plate_view", "main", "home", "duel", "gacha", "affection", "deck"]:
		var sc = load("res://scripts/%s.gd" % s)
		check(sc != null and sc is GDScript and sc.can_instantiate(), "scripts/%s.gd loads" % s)
	var t := StudioTheme.build()
	check(t.has_stylebox("normal", "Button") and t.has_stylebox("panel", "PanelContainer"), "theme has no default grey: Button/Panel styled")
	var src := ""
	for f in DirAccess.get_files_at("res://scripts"):
		if f.ends_with(".gd"):
			src += FileAccess.get_file_as_string("res://scripts/" + f)
	check(not src.contains("/" + "say") and not src.to_lower().contains("lla" + "ma"), "no typed-duel endpoint, no model name anywhere in the client")


func _t_api() -> void:
	var h := await Api.health()
	check(h.get("ok", false) == true and h.get("llm", true) == false, "health ok, llm=false")
	var st := await Api.state()
	check(st.get("player", "") == pid, "state identity is our pid")
	check(st.get("scenarios", []).size() == 5, "five scenarios")
	check(int(st.get("economy", {}).get("energy", {}).get("energy", 0)) == 15, "fresh energy 15")
	var d := await Api.deck("closing_time")
	check(d.get("collection", []).size() > 0 and d.get("deck", []).size() >= 3, "starter collection and auto deck")
	var s := await Api.start("closing_time", "gentle", false)
	check(s.get("ok", false) and s.get("duel", {}).get("hand", []).size() == 3, "start: hand of 3")
	check(int(Api.last_economy.get("energy", {}).get("energy", 0)) == 12, "economy_changed tracked: energy 12")
	var hand: Array = s["duel"]["hand"]
	var cheapest: Dictionary = hand[0]
	for c in hand:
		if int(c["cost"]) < int(cheapest["cost"]):
			cheapest = c
	var p := await Api.play(str(cheapest["id"]))
	check(p.get("ok", false) and p.has("reply") and p.get("duel", {}).get("turns", 0) == 1, "play: reply + turn 1")
	var f := await Api.forfeit()
	check(f.get("ok", false), "forfeit")
	var pull := await Api.pull(10)
	check(pull.has("error") and "gold" in str(pull["error"]), "pull refused without gold")
	var g := await Api.dev_gold(1000)
	check(int(g.get("gold", 0)) == 1000, "dev gold")
	pull = await Api.pull(10)
	check(pull.get("ok", false) and pull.get("cards", []).size() == 10, "ten-pull")
	var a := await Api.affection()
	check(a.get("affection", {}).has("mara") and a["affection"]["mara"]["ladder"].size() == 4, "affection ladder x4")
	var bad := await Api.get_json("/cards/nope")
	check(bad.has("error"), "404 surfaces as error, not a crash")


func _t_hand() -> void:
	var hand := Hand.new()
	hand.size = Vector2(1280, 250)
	add_child(hand)
	var chosen := []
	hand.card_chosen.connect(func(id, text): chosen.append([id, text]))
	var cards := [
		{"id": "a", "rarity": "common", "kind": "path", "cost": 1, "line": "x", "signals": ["warmth"], "character": "mara"},
		{"id": "b", "rarity": "rare", "kind": "case", "cost": 2, "line": "y", "signals": ["warmth", "respect"], "character": "mara"},
		{"id": "c", "rarity": "epic", "kind": "ask", "cost": 3, "line": "z", "signals": [], "character": "mara"},
	]
	hand.set_hand(cards, 1, 1)
	await get_tree().process_frame
	check(hand.state == Hand.State.IDLE, "IDLE after set_hand")
	check(hand.cards.size() == 4 and hand.ids() == ["a", "b", "c", "wild"], "3 cards + wild in the fan")
	check(hand.card_by_id("a").affordable and not hand.card_by_id("b").affordable, "affordability follows nerve")
	check(not hand.choose("b"), "cannot play an unaffordable card")
	hand.open_wild()
	check(hand.state == Hand.State.IDLE, "wild unaffordable at nerve 1: stays IDLE")
	check(hand.choose("a") and hand.state == Hand.State.PLAYING and chosen == [["a", ""]], "choose a -> PLAYING, emitted")
	check(not hand.choose("a"), "no double play while PLAYING")
	hand.unlock()
	check(hand.state == Hand.State.IDLE, "unlock -> IDLE")
	hand.set_hand(cards, 3, 1)
	await get_tree().process_frame
	hand.open_wild()
	check(hand.state == Hand.State.WILD, "wild affordable at nerve 3: WILD")
	check(not hand.submit_wild("   "), "empty wild line refused")
	hand.cancel_wild()
	check(hand.state == Hand.State.IDLE, "cancel wild -> IDLE")
	hand.open_wild()
	check(hand.submit_wild("Long day for you too.") and hand.state == Hand.State.PLAYING, "submit wild -> PLAYING")
	check(chosen.back() == ["wild", "Long day for you too."], "wild emitted with the typed line")
	hand.lock()
	check(hand.state == Hand.State.LOCKED and not hand.choose("a"), "LOCKED ignores plays")
	hand.set_hand([], 1, 0)
	check(hand.cards.is_empty() and hand.wild_card == null, "empty hand, no wild when wild_left 0")
	# fan geometry: 4 cards fit in 1280 and are ordered left to right
	hand.set_hand(cards, 3, 1)
	await get_tree().process_frame
	var xs := []
	for c in hand.cards:
		xs.append(c.position.x)
	check(xs[0] < xs[1] and xs[1] < xs[2] and xs[2] < xs[3], "fan is left-to-right")
	check(hand.cards[0].rotation_degrees < 0 and hand.cards[3].rotation_degrees > 0, "outer cards are tilted")
	hand.queue_free()


func _make_main() -> Node:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame
	return m


func _t_wild() -> void:
	var m := await _make_main()
	var guard := 0
	while m.current == "" and guard < 200:
		await get_tree().process_frame
		guard += 1
	var r: Dictionary = await m.start_duel("closing_time", false)
	check(r.get("ok", false), "start via main")
	await get_tree().process_frame
	check(m.current == "duel", "on the duel screen")
	var duel = m.screen
	guard = 0
	while duel.hand.cards.is_empty() and guard < 60:
		await get_tree().process_frame
		guard += 1
	check(duel.hand.wild_card != null and not duel.hand.wild_card.affordable, "wild in hand, unaffordable on turn 1")
	# play the cheapest card to get to nerve 2
	var hand: Array = duel.duel["hand"]
	var cheapest: Dictionary = hand[0]
	for c in hand:
		if int(c["cost"]) < int(cheapest["cost"]):
			cheapest = c
	var p: Dictionary = await duel.drive_play(str(cheapest["id"]))
	check(p.get("ok", false) and int(duel.duel["nerve"]) == 2, "first play -> nerve 2")
	await get_tree().process_frame
	duel.hand.open_wild()
	check(duel.hand.state == Hand.State.WILD and duel.wild_input.visible, "wild opens the LineEdit in-scene")
	duel.wild_input.text = "Long day for you too, I'd guess."
	var w: Dictionary = await duel.drive_wild_submit()
	check(w.get("ok", false) and w["read"]["card"] == "wild" and w["read"]["signals"] == ["warmth"], "wild scored by the engine: warmth")
	check(int(duel.duel["wild_left"]) == 0 and duel.hand.wild_card == null, "wild spent: gone from the fan")
	check("warmth" in duel.duel["evidence"], "evidence carries the typed line's signal")
	await Api.forfeit()
	m.queue_free()
	await get_tree().process_frame


func _t_persuaded() -> void:
	# The pytest fixture's winning deck for Mara, set through the real endpoint.
	var pid2 := pid + "_win"
	Api.set_pid(pid2)
	await Api.state()
	var deck := ["mara_01", "mara_03", "mara_05", "mara_01", "mara_03", "mara_05", "ines_03", "ines_04",
		"sanne_01", "sanne_02", "teodora_01", "teodora_02"]
	var d := await Api.save_deck("closing_time", deck)
	check(d.get("ok", false), "winning deck saved")
	var m := await _make_main()
	var guard := 0
	while m.current == "" and guard < 200:
		await get_tree().process_frame
		guard += 1
	m.difficulty = "gentle"
	var r: Dictionary = await m.start_duel("closing_time", false)
	check(r.get("ok", false), "duel started on gentle")
	await get_tree().process_frame
	var duel = m.screen
	var wanted := ["mara_01", "mara_03", "mara_05"]
	var last := {}
	var turns := 0
	while not duel.ended and turns < 20:
		while duel.hand.state != Hand.State.IDLE:
			await get_tree().process_frame
		var hand: Array = duel.duel["hand"]
		var nerve := int(duel.duel["nerve"])
		var pick := ""
		for c in hand:
			if not wanted.is_empty() and c["id"] == wanted[0] and int(c["cost"]) <= nerve:
				pick = c["id"]
				wanted.pop_front()
				break
		if pick == "":
			var best: Dictionary = {}
			for c in hand:
				if c["harms"].is_empty() and int(c["cost"]) <= nerve and not (c["id"] in wanted):
					if best.is_empty() or int(c["cost"]) < int(best["cost"]):
						best = c
			if best.is_empty():
				for c in hand:
					if c["harms"].is_empty() and int(c["cost"]) <= nerve:
						best = c
			pick = str(best["id"])
		last = await duel.drive_play(pick)
		check(not last.has("error"), "turn %d played %s" % [turns + 1, pick])
		turns += 1
	check(last.get("end", {}).get("won", false) == true, "PERSUADED")
	check(last.get("read", {}).get("phase_after", "") == "breakthrough", "phase breakthrough")
	check(duel.portrait.phase == "breakthrough", "portrait on the breakthrough treatment")
	check(abs(duel.gauge.value - float(last["duel"]["momentum"])) < 0.001, "gauge shows the backend's momentum")
	check("win" in Sfx.log, "win cue fired")
	await get_tree().create_timer(1.6).timeout
	check(duel._banner != null and duel._banner.visible, "end banner shown")
	var a := await Api.affection()
	check(int(a["affection"]["mara"]["wins"]) == 1 and "cg1_closing_time" in a["affection"]["mara"]["unlocked"], "affection 1, cg1 unlocked")
	m.queue_free()
