## Headless test of the Nutaku F2P path, against the real title server and the mock
## platform (ops/nutaku/suasion_f2p/test_godot_client.py starts both and passes the flags):
##
##   godot --headless --path play/silvertongue-cards-godot res://tests/f2p_client.tscn -- \
##       --nutaku-mock=http://127.0.0.1:8987 --nutaku-api=http://127.0.0.1:8986 --nutaku-user=me
##
## Boots through NutakuGI's three calls (mock path), lands on the campaign, claims the day,
## plays the first night through the duel screen card by card, pulls, buys charm with gold,
## and checks the Nutaku build shows no link to another platform. Prints CLIENT_OK.
extends Node

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		failures += 1


func _ready() -> void:
	Sfx.muted = true
	call_deferred("_run")


func _wait(cond: Callable, frames: int = 600) -> bool:
	var n := 0
	while not cond.call() and n < frames:
		await get_tree().process_frame
		n += 1
	return cond.call()


func _run() -> void:
	check(Nutaku.active and F2P.on(), "the desktop mock flags put the client in F2P mode")
	var m: Node = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	await _wait(func(): return m.current != "")
	check(Nutaku.session != "", "handshake through NutakuGI (mock) gave a session")
	check(not F2P.su.is_empty() and F2P.su.get("chapters", []).size() == 6, "the Night Ledger came from /suasion/state")
	m.go("home")
	await get_tree().process_frame
	check(m.current == "campaign", "'home' is the campaign map on Nutaku")
	await _wait(func(): return m.screen._stages.get_child_count() > 3)
	check(m.screen._stages.get_child_count() >= 13, "the chapter's twelve nights are listed")
	var c := await F2P.claim("daily")
	check(c["ok"], "day-1 reward claimed from the client")
	var t0 := int(Nutaku.state.get("tokens", {}).get("ticket", 0))
	check(t0 >= 1, "the calendar ticket arrived")

	# ---- the first night, card by card through the duel screen
	var r: Dictionary = await m.start_duel("c1s01", false)
	check(r.get("ok", false) and m.current == "duel", "PLAY opens the duel screen")
	var duel = m.screen
	await _wait(func(): return not duel.hand.cards.is_empty())
	check(duel._resolve_bar.get_parent().visible and int(duel._resolve_bar.max_value) > 0, "her resolve bar is shown")
	var last := {}
	var turns := 0
	while not duel.ended and turns < 30:
		await _wait(func(): return duel.hand.state == Hand.State.IDLE or duel.ended)
		if duel.ended:
			break
		var d: Dictionary = duel.duel
		var want := {}
		for p in d["needs"]["paths"]:
			for s in p:
				want[str(s)] = true
		for s in d["needs"]["help"]:
			want[str(s)] = true
		var pick := ""
		var best := -1
		for card in d["hand"]:
			if int(card["cost"]) > int(d["nerve"]) or not card["harms"].is_empty():
				continue
			var hit := 0
			for s in card["signals"]:
				if want.has(str(s)):
					hit += 1
			if hit > best:
				best = hit
				pick = str(card["id"])
		if pick == "" or best <= 0:
			last = await duel.drive_pass()
		else:
			last = await duel.drive_play(pick)
		check(not last.has("error"), "turn %d (%s)" % [turns + 1, pick if pick != "" else "pass"])
		turns += 1
	check(last.get("end", {}).get("won", false) == true, "PERSUADED: the server replayed the duel and recorded it")
	if not last.get("end", {}).get("won", false):
		print("  end: ", str(last.get("end", {})).left(300))
	check(int(last.get("duel", {}).get("resolve", 1)) == 0, "her resolve reached zero")
	await get_tree().create_timer(1.6).timeout
	var texts := []
	for b in duel._banner.find_children("*", "Button", true, false):
		texts.append((b as Button).text)
	check(not texts.has("MORE LIKE THIS"), "no cross-promotion board on Nutaku")
	await F2P.refresh()
	check(int(F2P.stage("c1s01").get("stars", 0)) >= 1, "the stage shows its stars on the map")

	# ---- a pull through the gacha screen
	m.go("gacha")
	await get_tree().process_frame
	var g: Dictionary = await m.screen.drive_pull(1)
	check(g.get("ok", false) and g.get("cards", []).size() == 1, "a one-pull on a ticket")
	check(int(Nutaku.state.get("tokens", {}).get("ticket", 0)) == t0 - 1, "the ticket was spent on the server")

	# ---- buy charm with Nutaku gold (the harness gave this user gold on the mock)
	var b2: Dictionary = await F2P.buy("charm_refill")
	check(str(b2.get("status", "")) == "success", "charm refill bought through NutakuGI.createPayment")
	check(int(Nutaku.state["energy"]["now"]) >= int(Nutaku.state["energy"]["max"]), "charm is full")
	m.go("store")
	await get_tree().process_frame
	check(m.screen._list.get_child_count() >= 8, "the store lists the SKUs from the catalogue")

	print("CLIENT_OK" if failures == 0 else "CLIENT_FAILED %d" % failures)
	# free the game before quitting, so exit does not report its live resources as leaks
	m.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if failures == 0 else 1)
