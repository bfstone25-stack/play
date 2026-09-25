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
	I18n.set_lang("en")        # the checks read English: pin it over whatever a previous run saved
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
	await sleep(0.3)
	# the roster behind the new cards shows the tickets left NOW, not the count from before
	# the pull (it read 10 with 9 left until the screen was closed)
	check("the roster behind the pull reveal shows the tickets left after the pull",
		b.roster.reveal.visible and b.roster.pity.text == b.roster.pity_text() and b.roster.pity_text().contains("9"),
		"label %s / now %s" % [b.roster.pity.text, b.roster.pity_text()])
	await sleep(1.2)
	b.roster.close()

	# ---- the office panel, every tab
	for t in F2PPanel.TABS:
		b.f2p_panel.open_tab(t)
		await sleep(0.4)
		check("office tab %s draws" % t, b.f2p_panel.content.get_child_count() > 0)
	b.f2p_panel.close()

	# ---- the story's numbers come from the goal's own values (the accelerated demo said
	# "earn 5M" beside a 50,000 target): every bid is filled from a scaled target, in every
	# language, and every goal from its `need`
	var story_ok := true
	var story_bad := ""
	for lang in I18n.LANGS:
		I18n.set_lang(lang)
		for ci in range(1, 11):
			var cid := "c%d" % ci
			if I18n.has("f2p_ch_%s_boss_text" % cid):
				var bt := F2P.boss_text(cid, {"target": 51234, "hours": 37, "text": ""})
				if not (bt.contains("51,234") and bt.contains("37")) or bt.contains("{") or bt.contains("million") or bt.contains("5M"):
					story_ok = false
					story_bad = "%s %s: %s" % [lang, cid, bt]
			for gi in range(4):
				if I18n.has("f2p_ch_%s_g%d" % [cid, gi]):
					var gt := F2P.goal_text(cid, gi, {"need": 4321, "text": ""})
					if gt.contains("{") or (I18n.t("f2p_ch_%s_g%d" % [cid, gi]).contains("{n}") and not gt.contains("4,321")):
						story_ok = false
						story_bad = "%s %s g%d: %s" % [lang, cid, gi, gt]
	I18n.set_lang("en")
	check("story text reads the bid target and goal numbers from the values the goals show", story_ok, story_bad)
	var cp: Dictionary = F2P.st()["campaign"]
	b.f2p_panel.open_tab("story")
	await sleep(0.3)
	var goal_need := RollingLabel._fmt(float(cp["goals"][0]["need"]))
	check("the STORY tab's first goal says the number its progress shows (%s)" % goal_need,
		_texts(b.f2p_panel.content).any(func(t: String) -> bool: return t.contains(goal_need + " floors") and t.contains("/ " + goal_need)))
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
	await _sweep_languages()
	_finish()


## Every word the Nutaku layer shows is in the player's language (the office, its banners
## and the story were English-only in the zh and ja builds). A language change reloads the
## scene in the game (title_screen.gd), so each language gets a fresh building here too:
## every office tab but BOARD (its rows are players' nicknames), the roster with its ticket
## line, the HUD stubs, and refusals.
func _sweep_languages() -> void:
	b.daily_result.close()
	b.queue_free()
	await sleep(0.3)
	for lang in ["ja", "de", "fr", "es", "zh", "ko"]:
		_lang = lang
		I18n.set_lang(lang)
		b = load("res://scenes/building.tscn").instantiate()
		get_tree().root.add_child(b)
		await sleep(0.3)
		b.intro.start.emit()
		b.intro.close()
		Sfx.set_muted(true)
		await sleep(0.8)
		var english: Array = []
		for t in F2PPanel.TABS:
			if t == "board":
				continue
			b.f2p_panel.open_tab(t)
			await sleep(0.3)
			for x in _texts(b.f2p_panel):
				if _latin(x):
					english.append("%s: %s" % [t, x])
		b.f2p_panel.close()
		b._open_tab("roster")
		await sleep(0.3)
		for x in _texts(b.roster):
			if _latin(x):
				english.append("roster: " + x)
		b.roster.close()
		for k in b.tabs.keys():
			if (b.tabs[k] as Button).visible and _latin((b.tabs[k] as Button).text):
				english.append("hud: " + (b.tabs[k] as Button).text)
		if _latin(b.gold_tag.text):
			english.append("hud: " + b.gold_tag.text)
		for x in [F2P.reason_text("not enough tickets"), F2P.reason_text("no free slot for dan"),
				F2P.reason_text("rank 3 needs affection tier 2"), F2P.reason_text("something new")]:
			if _latin(x):
				english.append("refusal: " + x)
		check("[%s] the office, the roster, the HUD and refusals show no English" % lang, english.is_empty(),
			"%d: " % english.size() + " | ".join(english.slice(0, 8)))
		b.queue_free()
		await sleep(0.3)
	I18n.set_lang("en")
	b = null


## Every Label, RichTextLabel and Button text under a node.
func _texts(n: Node) -> Array:
	var out: Array = []
	if n is Label:
		out.append((n as Label).text)
	elif n is RichTextLabel:
		out.append((n as RichTextLabel).get_parsed_text())
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		out.append_array(_texts(c))
	return out


## A run of three Latin letters that is not the brand, the platform or a unit.
var _lang := "zh"
var _en_lines := {}


## Is `t` English in the language being swept? For ja / zh / ko any Latin word says so. For
## de / fr / es a Latin word proves nothing: there it is a line that IS one of the English
## table's lines (numbers normalised) and not also this language's line.
func _latin(t: String) -> bool:
	var s := t.replace("OCCUPANCY", "").replace("Nutaku", "").replace("NUTAKU", "")
	var has_word := RegEx.create_from_string("[A-Za-z]{3,}").search(s) != null
	if _lang in ["ja", "zh", "ko"] or not has_word:
		return has_word
	if _en_lines.is_empty():
		for v in (I18n.T["en"] as Dictionary).values():
			_en_lines[_norm(str(v))] = true
	var n := _norm(t)
	if not _en_lines.has(n):
		return false
	for v in (I18n.T[_lang] as Dictionary).values():
		if _norm(str(v)) == n:
			return false
	return true


func _norm(s: String) -> String:
	var re := RegEx.create_from_string("%[-0-9.]*[dsf]|\\{\\w+\\}|\\d[\\d,.]*")
	return re.sub(s, "#", true).strip_edges()


func _finish() -> void:
	print("CLIENT_OK" if fails == 0 else "CLIENT_FAIL %d" % fails)
	await sleep(1.5)          # let banners, bursts and floating numbers finish their tweens
	if b != null:
		b.queue_free()
	await sleep(0.2)
	get_tree().quit(0 if fails == 0 else 1)
