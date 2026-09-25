extends Node
## The generated levels (202-800) and the daily challenge through the real game client,
## headless, against the title server running Fold's shipping config. Run by
## ops/nutaku/fold_f2p/test_godot_content.py, which clears levels 1-201 for this user over
## HTTP first (so the frontier is at 202) and passes
##   -- --nutaku-mock=<mock> --nutaku-api=<server> --nutaku-user=<id>
## Winning logs come from tests/gen_solutions.json (written by gen_levels.py; tests/ is not
## exported). Prints CLIENT_OK or CLIENT_FAIL; exits non-zero on any failure.

var fails := 0
var game: Node
var hard_logs := {}          # base level -> its winning log turned a quarter turn (the runner's --hard-logs)
const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}


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


func card_button(name: String) -> Button:
	var win: Control = game.get("_win")
	if win == null or not win.visible:
		return null
	return win.find_child(name, true, false) as Button


func play_log(log: String) -> void:
	await sleep(1.2)                      # the server refuses an impossibly fast solve
	for ch in log:
		var d: Vector2i = DIRS[ch]
		Fold.move(d.x, d.y)
		await sleep(0.22)


func open_game(level: int) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
		await sleep(0.2)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	game.set("start_level", level)
	get_tree().root.add_child(game)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hard-logs="):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(a.split("=", true, 1)[1]))
			if typeof(parsed) == TYPE_DICTIONARY:
				hard_logs = parsed
	I18n.set_lang("en")
	await run()
	print("CLIENT_OK" if fails == 0 else "CLIENT_FAIL %d" % fails)
	get_tree().quit(1 if fails else 0)


func run() -> void:
	check("F2P mode is on", F2P.on())
	var n_files := 201 + _json_size("res://data/levels_gen.json") + _json_size("res://data/levels_packs.json")
	check("the generated levels are loaded on the platform: %d in all (the files' sum)" % n_files,
		Fold.level_count() == n_files and Fold.level_count() >= 1100, "%d" % Fold.level_count())
	check("login", await F2P.ensure(), Nutaku.last_error)
	check("53 server tiers with no pack released (42 of SCENES.md + 11 to level 1100), tier 42 18 long, the last 30",
		Tier.count() == 53 and Tier.length(41) == 18 and Tier.length(52) == 30,
		"%d tiers, last %d" % [Tier.count(), Tier.length(Tier.count() - 1)])
	var fr := int(Nutaku.state["progress"]["frontier"])
	check("the frontier is level 202 (1-201 cleared by the runner)", fr == 201, str(fr))
	var sols = JSON.parse_string(FileAccess.get_file_as_string("res://tests/gen_solutions.json"))
	check("gen_solutions.json fixture present", typeof(sols) == TYPE_DICTIONARY)
	if typeof(sols) != TYPE_DICTIONARY:
		return

	# ---- three generated levels through game.tscn -------------------------------------
	var e0 := int(F2P.energy()["now"])
	await open_game(fr)
	for lv in range(fr, fr + 3):
		var opened := await until(func(): return F2P.active_for(lv) and Fold.level_index == lv and not Fold.done, 12.0)
		check("level %d (generated) opened by the server" % (lv + 1), opened)
		if not opened:
			return
		var g := Fold.level(lv)
		var srv_lv: Dictionary = {}
		check("level %d's board in the client is the generated one (par %d)" % [lv + 1, int(g["par"])],
			str(g["name"]).ends_with("Midnight %d" % (lv + 1)))
		await play_log(str(sols["levels"][str(lv)]))
		var cleared := await until(func(): return int(Nutaku.state["progress"]["stars"][lv]) > 0, 12.0)
		check("level %d accepted by the server" % (lv + 1), cleared)
	check("wins keep their candles (candles burn only on a failure)", int(F2P.energy()["now"]) == e0,
		"%d -> %d" % [e0, int(F2P.energy()["now"])])

	# ---- the daily challenge ------------------------------------------------------------
	var r := await F2P.fetch_challenge()
	check("the map's daily challenge info comes from the server", r["ok"] and not F2P.challenge.is_empty()
		and F2P.challenge_next_in() > 0.0, str(r.get("body", {})).left(200))
	var idx := int(F2P.challenge.get("index", -1))
	var hint0 := F2P.tokens("hint")
	var en0 := int(F2P.energy()["now"])
	await open_game(Fold.DAILY)
	var opened := await until(func(): return F2P.active_for(Fold.DAILY) and Fold.is_daily() and not Fold.done, 12.0)
	check("the daily challenge opens in game.tscn with the server's board", opened
		and Fold.daily_level.get("grid") == F2P.challenge["level"]["grid"])
	check("the daily's bonus goal is shown", Juice.goal_text(Fold.DAILY) != "", Juice.goal_text(Fold.DAILY))
	await play_log(str(sols["daily"][str(idx)]))
	var done := await until(func(): return card_button("Again") != null, 20.0)
	check("the daily result card appears", done)
	check("the server paid the daily reward once (+1 candle, +1 hint) and marked it claimed",
		bool(F2P.challenge.get("claimed", false)) and F2P.tokens("hint") == hint0 + 1
		and int(F2P.energy()["now"]) == en0 + 1, "hint %d->%d, candles %d->%d" % [hint0, F2P.tokens("hint"), en0, int(F2P.energy()["now"])])
	var again := card_button("Again")
	if again:
		again.pressed.emit()
	opened = await until(func(): return F2P.active_for(Fold.DAILY) and not Fold.done, 12.0)
	check("Play again reopens today's board", opened)
	await play_log(str(sols["daily"][str(idx)]))
	done = await until(func(): return card_button("Again") != null, 20.0)
	check("a replay wins but pays nothing", done and not bool(game.get("_last_finish").get("rewarded", true))
		and F2P.tokens("hint") == hint0 + 1, str(game.get("_last_finish")).left(200))

	# ---- the weekly event: board 1 through game.tscn -----------------------------------
	r = await F2P.fetch_event()
	check("this week's event comes from the server", r["ok"] and not F2P.event.is_empty(), str(r.get("body", {})).left(200))
	var who := str(F2P.event.get("who", ""))
	var en1 := int(F2P.energy()["now"])
	F2P.event_board = 0
	await open_game(Fold.EVENT)
	opened = await until(func(): return F2P.active_for(Fold.EVENT) and Fold.is_special() and not Fold.is_daily() and not Fold.done, 12.0)
	check("event board 1 opens with the server's board", opened
		and Fold.daily_level.get("grid") == F2P.event["boards"][0]["level"]["grid"])
	await play_log(str(sols["event"][who][0]))
	done = await until(func(): return card_button("Map") != null and int(F2P.event.get("cleared", 0)) == 1, 20.0)
	check("the server cleared event board 1 and paid its reward", done and int(F2P.energy()["now"]) == en1 + 1,
		"cleared %d, candles %d->%d" % [int(F2P.event.get("cleared", 0)), en1, int(F2P.energy()["now"])])
	check("the event card offers the next board", card_button("NextBoard") != null)

	# ---- hard mode: levels 1-201 cleared, so the first chapter's hard boards are open --------
	await hard_mode()

	# ---- an ice level through game.tscn's own piece builder --------------------------------
	await ice_level()

	# ---- Coco's account lines: a lost login streak, and the streak won back ----------------
	coco_streak()

	# ---- the map shows the challenge panel with its countdown ----------------------------
	game.queue_free()
	await sleep(0.2)
	var map := (load("res://scenes/map.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(map)
	var found := await until(func(): return map.find_child("ChallengeCountdown", true, false) != null, 12.0)
	check("the map has the daily challenge panel", found and map.find_child("PlayDaily", true, false) != null)
	if found:
		var cd := map.find_child("ChallengeCountdown", true, false) as Label
		check("with a countdown to the next one", cd.text.begins_with("Next in ") and ":" in cd.text, cd.text)
		var st := map.find_child("Standing", true, false) as Label
		check("the map header shows the rise through the House (chapter and stage from the server)",
			st != null and "The Lounge" in st.text and "Closer" in st.text, st.text if st else "no header")
		var stages := map.find_children("Stage", "Label", true, false)
		check("every tier card names its relationship stage", stages.size() == 53
			and (stages[0] as Label).text.begins_with("Hello") and (stages[41] as Label).text.begins_with("Last fold")
			and (stages[52] as Label).text.begins_with("Keepsake"), "%d stage labels" % stages.size())
		check("the weekly event panel is on the map", map.find_child("WeeklyEvent", true, false) != null
			and map.find_child("PlayEvent", true, false) != null)
		var board_ok := await until(func():
			var b := map.find_child("DailyBoard", true, false)
			return b != null and b.get_child_count() > 0, 8.0)
		var rows := map.find_child("DailyBoard", true, false)
		check("the daily leaderboard shows today's server score", board_ok
			and (rows.get_child(0) as Label).text.begins_with("1."), (rows.get_child(0) as Label).text if board_ok else "")
		# the hard-mode panel: the door chapter's progress and Play for its next board
		var hp := map.find_child("HardMode", true, false)
		var row := map.find_child("HardRow_door", true, false) as Label
		check("the map has the hard-mode panel with the first chapter's progress (5 cleared)",
			hp != null and row != null and row.text.begins_with("Hard mode · The Door") and "5/" in row.text,
			row.text if row else "no row")
		var ph := map.find_child("PlayHard", true, false) as Button
		check("its Play button names the next uncleared hard board", ph != null
			and ph.text == "Play hard level %d" % (F2P.hard_next() + 1), ph.text if ph else "none")
		for lang in ["zh", "ja"]:
			I18n.set_lang(lang)
			await sleep(0.3)
			var hp2 := await until(func(): return map.find_child("HardMode", true, false) != null, 5.0)
			var latin := latin_words(map.find_child("HardMode", true, false)) if hp2 else ["no panel"]
			check("the hard-mode panel has no Latin words in %s" % lang, hp2 and latin.is_empty(), ", ".join(latin))
		I18n.set_lang("en")
	map.queue_free()


func _json_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Array).size() if parsed is Array else -1


const NAMES := ["coco", "june", "iris", "sable", "vesna", "wren", "rosa", "hana", "nadia", "freya", "amara", "lucia"]


## Latin words of three or more letters on the visible Labels/Buttons under `root`, minus the cast.
func latin_words(root: Node) -> Array:
	var out := []
	var re := RegEx.create_from_string("[A-Za-z]{3,}")
	var nodes := [root]
	nodes.append_array(root.find_children("*", "Control", true, false))
	for n in nodes:
		if (n is Label or n is Button) and (n as CanvasItem).is_visible_in_tree():
			for m in re.search_all(str(n.text)):
				if m.get_string().to_lower() not in NAMES:
					out.append(m.get_string())
	return out


## Five hard boards of the first chapter, each won from the level's stored log turned a
## quarter turn (fold_rules.ROTATE_MOVE); the fifth first clear pays the per_n reward
## (a candle), and a replay of it pays nothing.
func hard_mode() -> void:
	var r := await F2P.fetch_hard()
	check("the server's hard-mode view has the first chapter open", r["ok"] and not F2P.hard_open_chapters().is_empty()
		and str(F2P.hard_open_chapters()[0]["id"]) == "door", str(r.get("body", {})).left(200))
	check("the runner passed the rotated logs", not hard_logs.is_empty())
	if F2P.hard_open_chapters().is_empty() or hard_logs.is_empty():
		return
	var per_n := int(F2P.hard.get("per_n", 5))
	var en0 := int(F2P.energy()["now"])
	var last := -1
	for k in range(per_n):
		var lv := F2P.hard_next()
		last = lv
		F2P.hard_level = lv
		await open_game(Fold.HARD)
		var opened := await until(func(): return F2P.active_for(Fold.HARD) and Fold.is_hard() and not Fold.done, 12.0)
		if k == 0:
			var base: Array = Fold.level(lv)["grid"]
			var turned: Array = Fold.daily_level.get("grid", [])
			check("hard board %d opens with the server's board turned a quarter turn" % (lv + 1), opened
				and turned.size() == _width(base) and _width(turned) == base.size() and turned != base,
				"%s vs %s" % [str(turned).left(80), str(base).left(80)])
			check("a hard board allows no undo and is free", F2P.free_undos() == 0 and not F2P.can_undo()
				and int(F2P.energy()["now"]) == en0 and F2P.allowed() == int(Fold.par()) + 2,
				"budget %d par %d" % [F2P.allowed(), Fold.par()])
			check("the HUD names the hard board", str((game.get("_lvname") as Label).text) == "Level %d, turned" % (lv + 1),
				(game.get("_lvname") as Label).text)
		if not opened:
			check("hard board %d opened" % (lv + 1), false)
			return
		await play_log(str(hard_logs.get(str(lv), "")))
		var done := await until(func(): return card_button("Map") != null and not F2P.active_for(Fold.HARD), 20.0)
		var lf: Dictionary = game.get("_last_finish")
		check("hard board %d won from the rotated log (first clear)" % (lv + 1), done and bool(lf.get("first_clear", false)),
			str(lf).left(160))
	check("the %d-th first hard clear paid its candle, once" % per_n, int(F2P.energy()["now"]) == en0 + 1
		and int(F2P.hard.get("cleared_total", 0)) == per_n, "candles %d->%d" % [en0, int(F2P.energy()["now"])])
	check("the hard card offers the next hard board", card_button("NextHard") != null)
	# replay the fifth: it wins, but it is not a first clear and pays nothing
	F2P.hard_level = last
	await open_game(Fold.HARD)
	await until(func(): return F2P.active_for(Fold.HARD) and not Fold.done, 12.0)
	await play_log(str(hard_logs.get(str(last), "")))
	var again := await until(func(): return card_button("Map") != null and not F2P.active_for(Fold.HARD), 20.0)
	var lf2: Dictionary = game.get("_last_finish")
	check("a hard replay wins but pays nothing", again and not bool(lf2.get("first_clear", true))
		and (lf2.get("applied", {}) as Dictionary).is_empty() and int(F2P.energy()["now"]) == en0 + 1
		and int(F2P.hard.get("cleared_total", 0)) == per_n, str(lf2).left(160))


static func _width(g: Array) -> int:
	var w := 0
	for row in g:
		w = maxi(w, (row as Array).size())
	return w


## The first level that ships with ice, drawn by game.tscn: one Ice overlay per ice tile.
## Loaded locally (it is past this player's frontier; the server replays ice in its own
## suite), so this checks the client's drawing, not the attempt.
func ice_level() -> void:
	var idx := -1
	for i in range(Fold.level_count()):
		if Fold.level_has_ice(i):
			idx = i
			break
	check("a shipped level has ice", idx >= 0)
	if idx < 0:
		return
	await F2P.give_up()
	Fold.load_level(idx)
	game.call("_relayout")
	await sleep(0.1)
	var want := 0
	for t in Fold.tiles:
		if bool(t.get("ice", false)):
			want += 1
	var got := 0
	for n in (game.get("_pieces") as Node).get_children():
		if n.has_node("Ice") and not n.is_queued_for_deletion():
			got += 1
	check("ice level %d loads with its %d ice piece(s) drawn as ice" % [idx + 1, want], want > 0 and got == want,
		"%d drawn, %d ice tiles" % [got, want])
	var look := Fold.look_of(idx)
	if look != "":
		check("its pack look (%s) tints the tray" % look, str(game.get("_look")) == look
			and (game.get("_table") as TextureRect).modulate == Color(Palette.look_tray(look), 1.0))


func coco_streak() -> void:
	var keep := [Save.get_v("coco_streak_seen", 0), Save.get_v("coco_streak_lost", false)]
	F2P.coco_pending.clear()
	Save.set_v("coco_streak_seen", 4)
	F2P._watch_streak({"daily": {"streak": 1}})
	var lost := F2P.coco_pending.has("streak_lost")
	F2P._watch_streak({"daily": {"streak": 2}})
	check("a login streak reset from 4 to 1 queues streak_lost, and 2 after it streak_back",
		lost and F2P.coco_pending.has("streak_back"), str(F2P.coco_pending))
	F2P._watch_streak({"daily": {"streak": 3}})
	F2P.coco_pending.clear()
	F2P._watch_streak({"daily": {"streak": 2}})
	check("a streak at 2 with no loss before it says nothing", F2P.coco_pending.is_empty(), str(F2P.coco_pending))
	F2P.coco_pending.clear()
	Save.set_v("coco_streak_seen", keep[0])
	Save.set_v("coco_streak_lost", keep[1])
