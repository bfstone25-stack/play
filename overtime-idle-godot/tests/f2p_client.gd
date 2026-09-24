extends Node
## The real OCCUPANCY client against the real F2P server and the mock Nutaku platform, no
## browser. Run by ops/nutaku/overtime_f2p/test_godot_client.py, which starts the servers,
## gives the user some mock gold and passes
##   -- --nutaku-mock=<mock url> --nutaku-api=<server url> --nutaku-user=<id>
##
## It instantiates the main scene (scenes/building.tscn), starts the game from the title,
## and goes through the game's own code paths: the building mirrors the server, a piece
## placed on the board is placed on the server, the local dev clock pays nothing, a pull
## goes through the roster screen, the office panel draws all six tabs, a gold purchase
## goes through NutakuGI.createPayment (mock), gift boxes carry a character to a scene
## tier, the scene plate comes from the server into the viewer, the daily floor is scored
## by the server. Prints PASS/FAIL lines, then CLIENT_OK or CLIENT_FAIL.

var fails := 0
var b: Node


func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("" if ok or detail == "" else "   [" + detail + "]"))
	if not ok:
		fails += 1


func until(cond: Callable, timeout := 10.0) -> bool:
	var t := 0.0
	while t < timeout:
		if cond.call():
			return true
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	return false


func sleep(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	Ticker.persist_enabled = false
	Economy.persist_enabled = false
	Sfx.muted = true         # headless: nothing to hear, and a cue still playing at quit leaks
	_run.call_deferred()


func _run() -> void:
	check("F2P mode is on (the desktop mock path)", F2P.on())
	b = load("res://scenes/building.tscn").instantiate()
	get_tree().root.add_child(b)
	await sleep(0.3)
	b.intro.start.emit()
	b.intro.close()
	Sfx.set_muted(true)      # the title's start re-applies the saved sound setting (and starts the drone)
	var booted: bool = await until(func() -> bool: return not F2P.st().is_empty(), 15.0)
	check("boot: handshake -> session -> login -> /ot/state", booted, Nutaku.last_error)
	if not booted:
		_finish()
		return
	var s := F2P.st()
	check("the building mirrors the server: one floor, bank 0", Ticker.B["floors"].size() == 1 and int(Ticker.B["bank"]) == 0)
	check("the welcome tickets show in the HUD's economy", Economy.tickets() == 10, str(Economy.tickets()))
	check("the office panel exists and the dev clock column does not", b.f2p_panel != null)
	# the HUD row fits 1280 with a late-game bank in it (the SOUND stub used to fall off the edge)
	b.rate_l.set_now(8200000)
	b.bank_l.set_now(350000000)
	b.gold_l.set_now(1234)
	await sleep(0.2)
	var row_end: float = b.hud_row.get_global_rect().end.x if b.get("hud_row") != null else 0.0
	var last_end: float = b.sound_btn.get_global_rect().end.x
	check("the HUD row fits 1280 with a 350M bank", maxf(row_end, last_end) <= 1270.0, "row ends at %d, sound at %d" % [row_end, last_end])
	b.hud()

	# ---- place through the board's own path
	b._bridge({"op": "place", "i": 6, "id": "dan"})
	b._bridge({"op": "place", "i": 5, "id": "coffee"})
	b._bridge({"op": "place", "i": 7, "id": "coffee"})
	var placed: bool = await until(func() -> bool:
		var c: Array = F2P.st()["floors"][0]["cells"]
		return c[6] == "dan" and c[5] == "coffee" and c[7] == "coffee")
	check("pieces placed on the board are placed on the server", placed, str(F2P.st()["floors"][0]["cells"]))
	var pay := int(F2P.st()["floors"][0]["pay"])
	check("the floor strip shows the server's pay for the floor", pay > 0 and Ticker.floor_pay(Ticker.B["floors"][0]) == pay, str(pay))
	var refused := [0]
	F2P.refused.connect(func(_r: String) -> void: refused[0] += 1)
	b._bridge({"op": "place", "i": 8, "id": "coffee"})       # none left in the tray
	await sleep(0.5)
	check("a piece the tray does not hold is not placed", F2P.st()["floors"][0]["cells"][8] == null
		and Ticker.B["floors"][0]["cells"][8] == null)

	# ---- the local clock pays nothing
	var bank0 := int(F2P.st()["bank"])
	Ticker.dev_advance(8 * 3600000)
	await sleep(1.0)
	await F2P.refresh()
	check("the local dev clock cannot pay: the server's bank is unchanged", int(F2P.st()["bank"]) == bank0,
		"%d -> %d" % [bank0, int(F2P.st()["bank"])])

	# ---- a pull through the roster screen
	b._open_tab("roster")
	await sleep(0.3)
	b.roster._pull(1)
	var pulled: bool = await until(func() -> bool: return int(F2P.st()["pity"]["pulls"]) == 1)
	check("PULL x1 on the roster screen is rolled by the server", pulled and Economy.tickets() == 9, str(Economy.tickets()))
	await sleep(1.5)
	b.roster.close()

	# ---- the office panel, every tab
	for t in F2PPanel.TABS:
		b.f2p_panel.open_tab(t)
		await sleep(0.4)
		check("office tab %s draws" % t, b.f2p_panel.content.get_child_count() > 0)
	b.f2p_panel.close()

	# ---- buy with (mock) Nutaku gold
	var r: Dictionary = await F2P.buy("ticket_10")
	check("buying ten tickets goes through NutakuGI.createPayment and arrives", str(r.get("status", "")) == "success"
		and Economy.tickets() == 19, JSON.stringify(r).left(200))
	r = await F2P.buy("gift_box_3")
	r = await F2P.buy("gift_box_3")
	check("gift boxes bought (two packs of three)", int(F2P.st()["gift_boxes"]) == 6)

	# ---- affection -> a scene, with juice
	var tiers_seen := []
	F2P.tiers_reached.connect(func(l: Array) -> void: tiers_seen.append_array(l))
	await b.f2p_panel._talk("wes")
	for i in range(6):
		await b.f2p_panel._gift("wes", true)
	await sleep(0.3)
	check("talk + six gift boxes: Wes reaches the scene tier", int(F2P.char_row("wes")["tier"]) >= 3, str(F2P.char_row("wes")))
	check("the tier-up signal fired for each tier", tiers_seen.size() >= 3, str(tiers_seen.size()))
	check("the juice layer drew the burst", b.fx.get_child_count() > 0, str(b.fx.get_child_count()))
	b.scene_view.show_scene("ot_wes_1", "Moving day")
	var shown: bool = await until(func() -> bool: return b.scene_view.img.texture != null)
	check("the scene plate is fetched from the server into the viewer", shown)
	b.scene_view.close()

	# ---- building a floor the bank cannot pay for is refused, and said so
	var before: int = refused[0]
	await b.build_floor(2)
	check("a floor the bank cannot pay for is refused and announced", refused[0] > before and F2P.st()["floors"].size() == 1)

	# ---- the daily floor, scored by the server
	await b.start_daily()
	check("the daily floor deals the server's twelve pieces", b.mode == "daily" and (b.daily["seq"] as Array).size() == 12)
	var seq: Array = b.daily["seq"]
	for i in range(seq.size()):
		b.daily["cells"][i] = seq[i]
	b.daily["at"] = seq.size()
	b.view = b.daily
	await sleep(8.5)
	var t0 := Economy.tickets()
	await b.do_commit()
	await until(func() -> bool: return b.daily_result.is_open(), 5.0)
	check("the daily floor result comes from the server (and pays the first-play ticket)", b.daily_result.is_open()
		and int(F2P.st()["daily_floor"]["attempts"]) == 1 and Economy.tickets() == t0 + 1)
	_finish()


func _finish() -> void:
	print("CLIENT_OK" if fails == 0 else "CLIENT_FAIL %d" % fails)
	await sleep(1.5)          # let banners, bursts and floating numbers finish their tweens
	if b != null:
		b.queue_free()
	await sleep(0.2)
	get_tree().quit(0 if fails == 0 else 1)
