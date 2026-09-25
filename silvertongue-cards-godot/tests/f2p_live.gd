## Headless test of what the server's clock releases after launch, against the real title
## server (ops/nutaku/suasion_f2p/test_godot_client.py starts it with a schedule whose pack 1
## and its event are live, and a veteran player who has won the Long Night):
##
##   the pack's chapter on the map, the event button and panel with its five stages and its
##   track, a claim, auto-battle from the night's panel, the missing pages, the banner in
##   the gacha, and the server's strings merged under the build's table.
##
## Prints LIVE_OK.
extends Node

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		failures += 1


func _ready() -> void:
	Sfx.muted = true
	Loc.set_code("en")
	call_deferred("_run")


func _wait(cond: Callable, frames: int = 600) -> bool:
	var n := 0
	while not cond.call() and n < frames:
		await get_tree().process_frame
		n += 1
	return cond.call()


func _texts(root: Node) -> String:
	var out := []
	for n in root.find_children("*", "", true, false):
		if n is Button or n is Label:
			out.append(str(n.text))
	return "\n".join(out)


func _run() -> void:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	await _wait(func(): return m.current != "")
	m.go("home")
	await _wait(func(): return m.current == "campaign" and m.screen._stages.get_child_count() > 3)
	var cp = m.screen
	var chs: Array = F2P.su.get("chapters", [])
	check(chs.size() == 7 and str(chs[6].get("pack", "")) == "p1", "the server's clock put pack 1 on the map (%d chapters)" % chs.size())
	check(cp._ch == 6, "a veteran lands on the new chapter, not chapter one")
	var left := _texts(cp._chapters)
	check("✦ 7 · THE SMALL HOURS" in left and "NEW" in left, "the new chapter is marked on the list")

	# ---- the event
	check(cp._events_btn.visible and "THE REQUEST HOUR" in cp._events_btn.text, "the event button names the running event: " + cp._events_btn.text)
	cp._show_events()
	await get_tree().process_frame
	var panel: Node = cp.get_node_or_null("Events")
	check(panel != null, "the event panel opens")
	if panel != null:
		var t := _texts(panel)
		check("REWARD TRACK" in t and "Request: Something Slow" in t and "ENDS IN" in t, "the panel lists the stages, the track and the time left")
		var plays := panel.find_children("*", "Button", true, false).filter(func(b): return b.text == "PLAY · 1 CHARM")
		var claims := panel.find_children("*", "Button", true, false).filter(func(b): return b.text == "CLAIM" or b.text == "CLAIMED")
		check(plays.size() == 5 and claims.size() == 8, "five event nights and eight track steps (%d, %d)" % [plays.size(), claims.size()])
		check(not plays[0].disabled and plays[1].disabled, "event nights open in order")
		panel.queue_free()
	if F2P.events().is_empty():
		check(false, "no event is running: the rest of this test needs one")
		await _finish(m)
		return
	# marks come from the server; the harness gave this player 40 on the Request Hour
	var ev: Dictionary = F2P.events()[0]
	var cl: Dictionary = await F2P.event_claim(str(ev["id"]), 0)
	check(cl["ok"] and int(cl["applied"].get("tokens", {}).get("chips", 0)) == 300, "a track step claimed from the client pays 300 chips")
	var cl2: Dictionary = await F2P.event_claim(str(ev["id"]), 0)
	check(not cl2["ok"], "...and not twice: " + str(cl2.get("error", "")))

	# ---- auto-battle from the night's panel
	cp._ch = 0
	cp._sel = "c1s01"
	cp._render()
	await get_tree().process_frame
	var autos: Array = cp._detail.find_children("*", "Button", true, false).filter(func(b): return "AUTO" in b.text)
	check(autos.size() == 2, "a three-starred night offers AUTO ×1 and AUTO ×5")
	var e0 := int(Nutaku.state["energy"]["now"])
	var a: Dictionary = await F2P.auto("c1s01", 2)
	check(a["ok"] and a["runs"].size() == 2 and int(Nutaku.state["energy"]["now"]) == e0 - 2,
		"auto ×2: two duels run and replayed by the server, two charm spent")
	check(int(a["won"]) >= 1, "...and won (%d of 2)" % int(a["won"]))

	# ---- the missing pages
	check(cp._pages_btn.visible and "THE MISSING PAGES · 6" in cp._pages_btn.text, "six pages kept on the Ledger: " + cp._pages_btn.text)
	var before: int = cp.get_child_count()
	cp._show_pages()
	await get_tree().process_frame
	var reader: Node = cp.get_child(cp.get_child_count() - 1)
	var rt := _texts(reader)
	check(cp.get_child_count() == before + 1 and "PAGE ONE: STOOL FOUR" in rt and "PAGE SIX: WHAT CELESTE SAID" in rt,
		"the pages read in order in the reader")
	reader.queue_free()

	# ---- the banner
	m.go("gacha")
	await get_tree().process_frame
	var gs = m.screen
	gs._render_prices()
	check(gs._banner_btn.visible and "ON AIR: ODILE" in gs._banner_btn.text, "the gacha offers the running banner: " + gs._banner_btn.text)
	gs._banner_btn.emit_signal("pressed")
	check(gs.banner == "bn_p1", "tapping it puts the next pull on the banner")
	var g: Dictionary = await gs.drive_pull(1)
	check(g.get("ok", false) and str(g.get("banner", "")) == "bn_p1", "a pull made on the banner, as the server recorded it")

	# ---- words newer than the build: the server's table fills the gap
	var key := str(F2P.su["chapters"][6]["title"])
	var ja: Dictionary = Loc._campaign.get("ja", {})
	var had = ja.get(key)
	ja.erase(key)
	Loc.set_code("ja")
	await F2P.strings()
	check(had != null and Loc.s(key) == str(had), "a pack string missing from the build is merged from /suasion/strings (ja)")
	Loc.set_code("en")

	await _finish(m)


func _finish(m: Node) -> void:
	print("LIVE_OK" if failures == 0 else "LIVE_FAILED %d" % failures)
	m.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if failures == 0 else 1)
