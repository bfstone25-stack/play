extends Node
## The OCCUPANCY walkthrough: the real client (scenes/building.tscn) against the real F2P
## server on an ACCELERATED config (prices / 10, rival bids / 100, a test clock). Driven by
## ops/nutaku/walkthroughs/occupancy/record.py, which starts the servers and runs this scene
## under Xvfb with --write-movie. It plays the first two chapters and the move to the second
## building, and prints markers the recorder turns into captions and cuts:
##   CAP <frame> <key>     a caption starts here (texts live in record.py, en + zh)
##   CUT <frame> on|off    frames between on and off are bookkeeping (fast-forward loops)
##   SHOT <frame> <name>   a still was saved to <shots>/<name>.png
##   WALK_OK / WALK_FAIL <why>
##
##   -- --nutaku-mock=<url> --nutaku-api=<url> --nutaku-user=<id> --shots=<dir> [--lang=en|zh|ja]
##
## --lang plays the game itself in that language (the zh video shows the zh build, not the
## English one with Chinese captions under it).

var b: Node
var api := ""
var shots := ""
var fails := 0
var _http: HTTPRequest


func _ready() -> void:
	Ticker.persist_enabled = false
	Economy.persist_enabled = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nutaku-api="):
			api = a.split("=", true, 1)[1].trim_suffix("/")
		elif a.begins_with("--shots="):
			shots = a.split("=", true, 1)[1]
		elif a.begins_with("--lang="):
			I18n.set_lang(a.split("=", true, 1)[1])
	_http = HTTPRequest.new()
	add_child(_http)
	_run.call_deferred()


func f() -> int:
	return Engine.get_frames_drawn()


func cap(key: String) -> void:
	print("CAP %d %s" % [f(), key])


func cut(on: bool) -> void:
	print("CUT %d %s" % [f(), "on" if on else "off"])


func shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shots.path_join(name + ".png"))
	print("SHOT %d %s" % [f(), name])
	for w in preload("res://tests/text_fit.gd").scan(get_tree().root):
		print("FIT %s %s" % [name, w])


func sleep(s: float) -> void:
	await get_tree().create_timer(s).timeout


func until(cond: Callable, timeout := 10.0) -> bool:
	var t := 0.0
	while t < timeout:
		if cond.call():
			return true
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	return false


func need(ok: bool, why: String) -> bool:
	if not ok:
		fails += 1
		print("STEP_FAIL " + why)
	return ok


## Move the server's test clock (the accelerated part), then read the building.
func clock(seconds: float) -> void:
	_http.request(api + "/f2p/_test/clock", ["Content-Type: application/json"], HTTPClient.METHOD_POST,
		JSON.stringify({"advance_s": seconds}))
	await _http.request_completed
	await F2P.refresh()
	F2P.clock_offset_ms = int(F2P.st().get("server_ms", 0)) - F2P.local_ms()


func bank() -> int:
	return int(F2P.st().get("bank", 0))


## Fast-forward 8 h at a time (the offline cap) until the bank holds `amount`. Cut from the video.
func earn_until(amount: int, cond := Callable()) -> void:
	cut(true)
	var guard := 0
	while guard < 400 and (bank() < amount if not cond.is_valid() else not cond.call()):
		await clock(8 * 3600)
		await F2P.act("/collect")
		guard += 1
	cut(false)


func place(i: int, id: String, pause := 0.55) -> void:
	b._bridge({"op": "place", "i": i, "id": id})
	await sleep(pause)


func view(n: int) -> void:
	b._bridge({"op": "view", "n": n})
	await sleep(0.3)


func buy_objects(counts: Dictionary) -> void:
	for k in counts:
		for _i in range(int(counts[k])):
			await F2P.act("/buy_object", {"id": k})


func panel(tab: String, hold := 2.5) -> void:
	b.f2p_panel.open_tab(tab)
	await sleep(hold)


func build_floor_in_panel() -> void:
	b.f2p_panel.open_tab("upgrades")
	await sleep(1.6)
	await b.f2p_panel._act_juice("/build_floor", {}, "floor")
	await sleep(1.6)
	b.f2p_panel.close()
	await sleep(0.3)


func _run() -> void:
	# ---- title ------------------------------------------------------------------------
	b = load("res://scenes/building.tscn").instantiate()
	get_tree().root.add_child(b)
	cap("title")
	await sleep(3.5)
	await shot("01_title")
	b.intro.start.emit()
	b.intro.close()
	Sfx.set_muted(true)
	cut(true)
	var booted: bool = await until(func() -> bool: return not F2P.st().is_empty(), 20.0)
	if not need(booted, "boot: " + Nutaku.last_error):
		return _finish()
	# day-1 calendar, so the panel's DAILY tab is not the thing in the way
	await F2P.act("/daily/claim")
	await sleep(0.8)
	cut(false)

	# ---- floor 1: pieces, links, the Wes tax ------------------------------------------------
	cap("floor1")
	await sleep(2.5)
	cap("coffee_dan")
	await place(2, "dan", 0.8)
	await place(1, "coffee", 0.8)
	await place(3, "coffee", 1.4)
	cap("priya_copy")
	await place(6, "priya", 1.6)
	cap("wes_tax")
	await place(5, "wes", 2.2)
	await shot("02_wes_tax")
	await sleep(1.0)
	cap("mute_shield")
	await place(7, "mute", 2.0)
	await place(11, "mara", 1.2)
	await place(0, "printer", 1.2)
	var fl1: Dictionary = F2P.st()["floors"][0]
	print("INFO floor1 pay=%d chain=%s" % [int(fl1["pay"]), str(fl1.get("chain", "?"))])
	await shot("03_floor1_chain")
	await sleep(1.0)

	# ---- the clock: rent ----------------------------------------------------------------
	cap("accel_rent")
	await clock(8 * 3600)
	await F2P.act("/collect")
	await sleep(2.5)

	# ---- floors 2 and 3 --------------------------------------------------------------
	await earn_until(int(F2P.st()["building"]["next_floor_cost"]) + 3000)
	cap("floor2")
	await build_floor_in_panel()
	cut(true)
	await buy_objects({"coffee": 3, "printer": 2, "mute": 1, "corner": 2})
	cut(false)
	await view(2)
	cap("fill_floor2")
	for pc in [[1, "coffee"], [2, "dan"], [3, "coffee"], [0, "corner"], [4, "corner"], [7, "mute"], [6, "printer"], [8, "printer"], [12, "coffee"]]:
		await place(int(pc[0]), str(pc[1]), 0.4)
	await sleep(1.0)
	await earn_until(int(F2P.st()["building"]["next_floor_cost"]) + 3000)
	cap("floor3")
	await build_floor_in_panel()
	cut(true)
	await buy_objects({"coffee": 3, "printer": 3, "mute": 2, "corner": 2})
	cut(false)
	await view(3)
	for pc in [[0, "corner"], [1, "coffee"], [2, "priya"], [3, "coffee"], [4, "corner"], [5, "printer"], [6, "mute"], [7, "printer"], [8, "mute"], [9, "printer"]]:
		await place(int(pc[0]), str(pc[1]), 0.3)
	await sleep(1.0)
	await shot("04_floor3_strip")

	# ---- a pull ---------------------------------------------------------------------
	cap("pull")
	b._bridge({"op": "pull", "n": 10})
	await sleep(5.5)
	await shot("05_pull")
	await sleep(1.0)
	b.roster.close()
	await sleep(0.5)

	# ---- affection: talk and gifts -> tier 1 and 2 lines -------------------------------
	cut(true)
	await F2P.buy("gift_box_3")
	cut(false)
	cap("affection")
	b.f2p_panel.open_tab("staff")
	await sleep(1.5)
	# one gift box each for Dan and Priya: tiers 1-2 (lines) only, even in a week that
	# doubles one of them; the scene tier (3) needs 600
	for who in ["dan", "priya"]:
		await b.f2p_panel._talk(who)
		await sleep(1.3)
		await b.f2p_panel._gift(who, true)
		await sleep(2.2)
	for who in ["dan", "priya"]:
		need(int(F2P.char_row(who)["tier"]) <= 2, "affection stayed on the line tiers: " + str(F2P.char_row(who)))
	await shot("06_affection")
	b.f2p_panel.close()

	# ---- chapter 1 complete ------------------------------------------------------------
	cap("chapter1")
	b.f2p_panel.open_tab("story")
	await sleep(3.0)
	var cp: Dictionary = F2P.st()["campaign"]
	need(bool(cp["complete"]), "chapter 1 goals: " + JSON.stringify(cp["goals"]))
	await b.f2p_panel._act_juice("/chapter/complete", {}, "chapter")
	await sleep(3.5)
	await shot("07_chapter_complete")
	b.f2p_panel.close()

	# ---- chapter 2: floors 4 and 5, 8+ pieces everywhere, no Wes tax ----------------
	for n in [4, 5]:
		await earn_until(int(F2P.st()["building"]["next_floor_cost"]) + 4000)
		cap("floor%d" % n)
		await build_floor_in_panel()
		cut(true)
		await buy_objects({"coffee": 2, "printer": 3, "mute": 2, "corner": 2})
		cut(false)
		await view(n)
		for pc in [[0, "corner"], [1, "coffee"], [2, "mute"], [3, "coffee"], [4, "corner"], [5, "printer"], [6, "mute"], [7, "printer"], [8, "printer"]]:
			await place(int(pc[0]), str(pc[1]), 0.25)
		await sleep(0.8)
	await view(1)
	cap("inspection")
	b.f2p_panel.open_tab("story")
	await sleep(3.5)
	await shot("08_chapter2_goals")

	# ---- the rival bid --------------------------------------------------------------
	cap("bid")
	await b.f2p_panel._act_juice("/chapter/boss", {}, "boss")
	await sleep(2.5)
	b.f2p_panel.close()
	cap("bid_clock")
	for _i in range(5):
		await clock(8 * 3600)
		await F2P.act("/collect")
		await sleep(0.9)
	b.f2p_panel.open_tab("story")
	await sleep(1.5)
	var boss: Dictionary = F2P.st()["campaign"].get("boss", {})
	need(str(boss.get("status", "")) == "won", "bid: " + JSON.stringify(boss))
	cap("bid_won")
	await sleep(2.5)
	await shot("09_bid_won")
	await b.f2p_panel._act_juice("/chapter/complete", {}, "chapter")
	await sleep(3.0)
	b.f2p_panel.close()

	# ---- prestige -> building 2, its scene ------------------------------------------------
	await earn_until(0, func() -> bool: return bool(F2P.st()["building"]["can_prestige"]))
	cap("prestige")
	b.f2p_panel.open_tab("upgrades")
	await sleep(2.5)
	await b.f2p_panel._act_juice("/prestige", {}, "prestige")
	await sleep(1.0)
	b.f2p_panel.close()
	await sleep(2.5)
	need(int(F2P.st()["building"]["no"]) == 2, "prestige: " + JSON.stringify(F2P.st()["building"]))
	await shot("10_building2")
	cap("scene")
	b.f2p_panel.open_tab("scenes")
	await sleep(2.0)
	b.scene_view.show_scene("ot_b2", F2P.scene_title("ot_b2", "The glass office"))
	await until(func() -> bool: return b.scene_view.img.texture != null, 8.0)
	await sleep(3.5)
	await shot("11_scene")
	b.scene_view.close()
	b.f2p_panel.close()
	cap("outro")
	await sleep(5.0)
	_finish()


func _finish() -> void:
	print("WALK_OK" if fails == 0 else "WALK_FAIL %d" % fails)
	cap("end")
	await sleep(0.5)
	get_tree().quit(0 if fails == 0 else 1)
