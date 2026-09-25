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
var panels := false        # --panels: also photograph the 2026-09-24 panels (lang_shots.py)
var stop_after_panels := false
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
		elif a == "--panels":
			panels = true
		elif a == "--panels-only":
			panels = true
			stop_after_panels = true
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
	# a line that cannot wrap widens the whole office card past its design width without
	# leaving the screen (ja, 2026-09-25): the checks above miss that, this does not
	for ov in [b.f2p_panel, b.story_view] if b != null else []:
		if ov != null and ov.is_open() and ov.card.size.x > ov.card_width + 2.0:
			print("FIT %s WIDE %s card %d > %d" % [name, ov.get_path(), int(ov.card.size.x), int(ov.card_width)])
			_widest(ov.card, ov.card_width - 40.0)


## Name the deepest controls whose minimum width is over `w` (what made a card wide).
func _widest(n: Node, w: float) -> void:
	for c in n.get_children():
		if c is Control and (c as Control).get_combined_minimum_size().x > w:
			var deeper := false
			for g in c.get_children():
				if g is Control and (g as Control).get_combined_minimum_size().x > w:
					deeper = true
			if not deeper:
				for g in c.get_children():
					if g is Control:
						print("    child %s %d \"%s\"" % [g.get_class(), int((g as Control).get_combined_minimum_size().x), (g.text if (g is Label or g is Button) else "").left(80)])
				var t: String = c.text if (c is Label or c is Button) else c.get_class()
				print("  WIDE_BY %s %d \"%s\"" % [c.get_path(), int((c as Control).get_combined_minimum_size().x), t.left(80)])
			_widest(c, w)


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


## Scroll the office panel so the section headed by a label starting with `head` is at the top.
func scroll_to(head: String) -> bool:
	var content: VBoxContainer = b.f2p_panel.content
	var sc := content.get_parent() as ScrollContainer
	await get_tree().process_frame
	await get_tree().process_frame
	for c in content.get_children():
		if c is Label and (c as Label).text.begins_with(head):
			sc.scroll_vertical = int((c as Control).position.y) - 4
			await get_tree().process_frame
			await get_tree().process_frame
			return true
	print("STEP_FAIL section not found: " + head)
	fails += 1
	return false


## The panels added on 2026-09-24 -- pack news, staff stories + StoryView, tenant crisis,
## the night floor, a pack's banner and event, floor build goals -- each opened and shot.
## Needs a live pack (lang_shots.py forces u1 on) and chapter one complete (night floor).
func panel_shots() -> void:
	cap("panels")
	await sleep(0.4)          # let the panel's close tween finish, or it hides the reopened panel
	b.f2p_panel.open_tab("story")
	await sleep(1.5)
	need(not (F2P.st().get("news", []) as Array).is_empty(), "news: no dispatches (is a pack live?)")
	if await scroll_to(I18n.t("f2p_news_hdr")):
		await shot("07a_story_news")
	b.f2p_panel.open_tab("daily")
	await sleep(1.2)
	var ss = F2P.st().get("stories")
	need(ss != null and not (ss.get("pending", []) as Array).is_empty(), "stories: none pending " + str(ss))
	need(F2P.st().get("crisis") != null, "crisis: none today")
	if await scroll_to(I18n.t("f2p_st_hdr").get_slice("{", 0).strip_edges()):
		await shot("07b_daily_stories_crisis")
	if await scroll_to(I18n.t("f2p_hf_hdr")):
		await shot("07c_daily_night_floor")
	if ss != null and not (ss.get("pending", []) as Array).is_empty():
		var st: Dictionary = ss["pending"][0]
		await b.f2p_panel._read(str(st["id"]), str(st["char"]))
		await sleep(1.2)
		need(b.story_view.is_open(), "story view did not open")
		await shot("07d_story_view")
		b.story_view.close()
		await sleep(0.5)
	b.f2p_panel.open_tab("staff")
	await sleep(1.5)
	need(F2P.st().get("banner") != null and F2P.st().get("pack_event") != null, "banner/event not running")
	(b.f2p_panel.content.get_parent() as ScrollContainer).scroll_vertical = 0     # the pack rows lead the tab
	await sleep(0.2)
	await shot("07e_staff_pack")
	b.f2p_panel.open_tab("upgrades")
	await sleep(1.2)
	if await scroll_to(I18n.t("f2p_fit_hdr")):
		await shot("07f_upgrades_goals")
	b.f2p_panel.close()
	await sleep(0.5)


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
	if panels:
		await panel_shots()
		if stop_after_panels:
			await _finish()
			return

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
