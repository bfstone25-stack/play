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

	# ---- charm above its cap (ECONOMY.md): "15 (refills to 8)", never "15/8"
	var e0: Dictionary = Nutaku.state.get("energy", {})
	await get_tree().process_frame
	m.render_wallet(F2P.economy())
	m.screen._render()
	var bar: String = m._energy_n.text
	var head: String = m.screen._head.text
	var over := int(e0.get("now", 0)) > int(e0.get("max", 8))
	check(over, "the day-1 gift took charm past its cap (%d over %d)" % [int(e0.get("now", 0)), int(e0.get("max", 8))])
	var frac := RegEx.create_from_string("CHARM (\\d+)/(\\d+)")
	var bad_frac := func(t: String) -> bool:
		var mm := frac.search(t)
		return mm != null and int(mm.get_string(1)) > int(mm.get_string(2))
	check(not bad_frac.call(bar) and "(refills to %d)" % int(e0.get("max", 8)) in bar,
		"top bar reads charm over the cap as 'N (refills to MAX)': " + bar)
	check(not bad_frac.call(head) and "(refills to %d)" % int(e0.get("max", 8)) in head,
		"the Ledger's header agrees: " + head)
	m.go("store")
	await get_tree().process_frame
	check(not m.screen._list.get_children().any(func(row): return "Refill charm" in str(row.find_children("*", "Label", true, false).map(func(l): return l.text))),
		"the store does not offer a refill while charm is over its cap")
	m.go("home")
	await _wait(func(): return m.current == "campaign" and m.screen._stages.get_child_count() > 3)

	# ---- the deck screen and the duel agree about which cards are live tonight
	F2P.stage_id = "c1s01"
	m.go("deck")
	await _wait(func(): return m.screen.live != null)
	var dk = m.screen
	check(dk.live != null and not dk.live.is_empty(), "deck screen knows which cards can act in Mara's first night")
	check(dk.deck.all(func(id): return dk.live.has(id)), "the night's deck holds only live cards")
	var dead_ids := []
	for d in dk.collection:
		if not dk.live.has(str(d["id"])):
			dead_ids.append(str(d["id"]))
	check(not dead_ids.is_empty() and dk._night.visible and dk._night.text != "",
		"deck screen names the night and marks %d cards that will not be dealt" % dead_ids.size())

	# ---- the first night, card by card through the duel screen
	var r: Dictionary = await m.start_duel("c1s01", false)
	check(r.get("ok", false) and m.current == "duel", "PLAY opens the duel screen")
	var duel = m.screen
	await _wait(func(): return not duel.hand.cards.is_empty())
	check(duel._resolve_bar.get_parent().visible and int(duel._resolve_bar.max_value) > 0, "her resolve bar is shown")
	# the duel's story text is the whole text, never cut with an ellipsis
	await get_tree().process_frame
	await get_tree().process_frame
	var st: Dictionary = F2P._stage
	var full := Loc.s(st.get("chapter_intro", ""))
	full = (full + "\n\n" if full != "" else "") + Loc.s(st.get("intro", ""))
	var brief: Label = duel._brief
	check(brief.text == full and full.length() > 200, "the duel shows the night's whole story (%d chars)" % full.length())
	check(brief.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and brief.max_lines_visible < 0
		and brief.get_visible_line_count() >= brief.get_line_count(),
		"no truncation: %d of %d lines visible, overrun %d" % [brief.get_visible_line_count(), brief.get_line_count(), brief.text_overrun_behavior])
	var dead_seen := []
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
		for card in d["hand"]:
			var hits := false
			for s in card["signals"]:
				hits = hits or want.has(str(s))
			if not hits and str(card.get("kind", "")) != "coercion":
				dead_seen.append(str(card["id"]))
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
	check(dead_seen.is_empty(), "no hand in the duel held a card that cannot act tonight: %s" % str(dead_seen))
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
	# (charm is still over its cap from the day-1 gift, so the refill is not the SKU to buy)
	var c_before := int(Nutaku.state["energy"]["now"])
	var b2: Dictionary = await F2P.buy("charm_5")
	check(str(b2.get("status", "")) == "success", "five charm bought through NutakuGI.createPayment")
	check(int(Nutaku.state["energy"]["now"]) == c_before + 5, "charm +5 arrived (%d -> %d)" % [c_before, int(Nutaku.state["energy"]["now"])])
	m.go("store")
	await get_tree().process_frame
	check(m.screen._list.get_child_count() >= 8, "the store lists the SKUs from the catalogue")

	# ---- Japanese and Chinese: the campaign's own words, not only the chrome
	var cjk := RegEx.create_from_string("[\\x{3040}-\\x{30ff}\\x{4e00}-\\x{9fff}]")
	for lang in ["ja", "zh"]:
		Loc.set_code(lang)
		await get_tree().create_timer(0.4).timeout
		m.go("home")
		await _wait(func(): return m.current == "campaign" and m.screen._stages.get_child_count() > 3)
		await get_tree().process_frame
		var labels := []
		for n in m.screen.find_children("*", "", true, false):
			if n is Button or n is Label:
				labels.append(str(n.text))
		var joined := "\n".join(labels)
		var en_title := str(F2P.su["chapters"][0]["stages"][0]["title"])
		check(cjk.search(joined) != null and not (en_title in joined) and not ("THE NIGHT LEDGER" in joined),
			"%s: the Ledger's chrome and its stage titles are translated" % lang)
		m.go("store")
		await get_tree().process_frame
		var st_txt := []
		for n in m.screen.find_children("*", "Label", true, false):
			st_txt.append(str(n.text))
		check(not ("Paid in Nutaku gold" in "\n".join(st_txt)) and cjk.search("\n".join(st_txt)) != null,
			"%s: the store's items and its note are translated" % lang)
	Loc.set_code("en")
	await get_tree().create_timer(0.4).timeout

	print("CLIENT_OK" if failures == 0 else "CLIENT_FAILED %d" % failures)
	# free the game before quitting, so exit does not report its live resources as leaks
	m.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if failures == 0 else 1)
