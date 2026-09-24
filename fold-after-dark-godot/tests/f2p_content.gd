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
	await run()
	print("CLIENT_OK" if fails == 0 else "CLIENT_FAIL %d" % fails)
	get_tree().quit(1 if fails else 0)


func run() -> void:
	check("F2P mode is on", F2P.on())
	check("the generated levels are loaded on the platform: 800 in all", Fold.level_count() == 800,
		"%d" % Fold.level_count())
	check("login", await F2P.ensure(), Nutaku.last_error)
	check("42 server tiers (SCENES.md), the last one 18 levels long", Tier.count() == 42 and Tier.length(41) == 18,
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
			str(g["name"]).ends_with("After Dark %d" % (lv + 1)))
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
		check("every tier card names its relationship stage", stages.size() == 42
			and (stages[0] as Label).text.begins_with("Hello") and (stages[41] as Label).text.begins_with("Last fold"),
			"%d stage labels" % stages.size())
		check("the weekly event panel is on the map", map.find_child("WeeklyEvent", true, false) != null
			and map.find_child("PlayEvent", true, false) != null)
		var board_ok := await until(func():
			var b := map.find_child("DailyBoard", true, false)
			return b != null and b.get_child_count() > 0, 8.0)
		var rows := map.find_child("DailyBoard", true, false)
		check("the daily leaderboard shows today's server score", board_ok
			and (rows.get_child(0) as Label).text.begins_with("1."), (rows.get_child(0) as Label).text if board_ok else "")
	map.queue_free()
