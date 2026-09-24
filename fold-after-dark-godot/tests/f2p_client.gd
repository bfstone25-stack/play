extends Node
## The real game client against the real F2P server and the mock Nutaku platform — no
## browser. Run by ops/nutaku/fold_f2p/test_godot_client.py, which starts the servers and
## passes:  -- --nutaku-mock=<mock url> --nutaku-api=<server url> --nutaku-user=<id>
##
## It instantiates scenes/game.tscn and plays through the game's own code paths: the
## server opens each level (a candle), the folds go in as Fold.move() so game.gd's own
## signal handler records them, the solve goes to the server as a move log, the tier's
## trophy button fetches the plate from our server, an empty candle bank shows the
## out-of-candles card whose Refill button buys through the (mock) NutakuGI, an
## exhausted move budget shows the out-of-moves card, a second undo buys a token.
## Prints CLIENT_OK or CLIENT_FAIL lines; exits non-zero on any failure.

var fails := 0
var mock := ""
var game: Node


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


## Poll for a card button; returns it or null. (A lambda cannot assign an outer local —
## GDScript captures by value, ops/godot_lambda_capture.md — so the waiting is done here.)
func wait_button(name: String, timeout := 10.0) -> Button:
	var t := 0.0
	while t < timeout:
		var b := card_button(name)
		if b != null:
			return b
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	return null


func card_button(name: String) -> Button:
	var win: Control = game.get("_win")
	if win == null or not win.visible:
		return null
	var b := win.find_child(name, true, false)
	return b as Button


## A fold that moves something and does not win, found on a scratch copy of the rules,
## so wandering never solves the level by accident (a solve would go to the server).
func safe_fold() -> bool:
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var sim: Node = load("res://scripts/fold.gd").new()
		sim.levels = Fold.levels
		sim.level_index = Fold.level_index
		sim.rows = Fold.rows
		sim.cols = Fold.cols
		sim.walls = Fold.walls.duplicate()
		sim.restore(Fold.snapshot())
		var ok: bool = sim.move(d.x, d.y) >= 0 and not sim.is_won()
		sim.free()
		if ok:
			return Fold.move(d.x, d.y) >= 0
	return false


func post(url: String, body: Dictionary) -> Dictionary:
	var h := HTTPRequest.new()
	add_child(h)
	h.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	var res: Array = await h.request_completed
	h.queue_free()
	var p = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return p if typeof(p) == TYPE_DICTIONARY else {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nutaku-mock="):
			mock = a.split("=", true, 1)[1]
	await run()
	print("CLIENT_OK" if fails == 0 else "CLIENT_FAIL %d" % fails)
	get_tree().quit(1 if fails else 0)


func run() -> void:
	check("the Nutaku client is active on the mock path", Nutaku.active and F2P.on())
	check("handshake + login through the game's own client", await F2P.ensure(), Nutaku.last_error)
	check("the server's tiers replaced the local cut", Tier.count() == (Nutaku.state["tiers"] as Array).size()
		and Tier.length(1) == int(Nutaku.state["tiers"][1]["size"]), "%d tiers" % Tier.count())
	var e0 := int(F2P.energy()["now"])
	var d := await Nutaku.claim_daily()
	check("the login reward is claimed from the client", d["ok"])

	# ---- play tier 1 through the real game scene -------------------------------------
	var sols = JSON.parse_string(FileAccess.get_file_as_string("res://tests/solutions.json"))
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	game.set("start_level", 0)
	get_tree().root.add_child(game)
	for lv in range(5):
		var opened := await until(func(): return F2P.active_for(lv) and Fold.level_index == lv and not Fold.done)
		check("level %d opened by the server" % (lv + 1), opened)
		if not opened:
			return
		await sleep(1.4)                     # the server refuses an impossibly fast solve
		for dir in sols[str(lv)]["dirs"]:
			Fold.move(int(dir[0]), int(dir[1]))
			await sleep(0.25)
		var cleared := await until(func(): return int(Nutaku.state["progress"]["stars"][lv]) == 3)
		check("level %d accepted by the server with three stars" % (lv + 1), cleared)
	var e1 := int(F2P.energy()["now"])
	check("five levels cost five candles", e1 == e0 + 2 - 5, "%d -> %d" % [e0, e1])
	var first_scene := str(Nutaku.state["tiers"][0]["scene"]["id"])
	check("tier 1's scene is unlocked on the server", F2P.server_unlocked(first_scene))
	var unlock_btn: Button = await wait_button("Unlock")
	check("the trophy card offers the scene", unlock_btn != null)
	if unlock_btn:
		Unlock.clear(first_scene)
		unlock_btn.pressed.emit()
		check("the plate is delivered from our server and decodes", await until(func(): return Unlock.ready_for(first_scene)))
		check("the viewer opens on it", await until(func(): return game.get("_viewer") != null))
	game.queue_free()
	await sleep(0.2)

	# ---- run out of candles, then buy a refill through the platform ---------------------
	while true:
		var r := await Nutaku.start_level(5)
		if not r["ok"]:
			break
		await Nutaku.fail_level(str(r["body"]["attempt_id"]))
	check("candles run out", int(F2P.energy()["now"]) == 0)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	game.set("start_level", 5)
	get_tree().root.add_child(game)
	var refill: Button = await wait_button("Refill")
	check("an empty bank shows the out-of-candles card with a Refill offer", refill != null)
	await post(mock + "/mock/balance", {"userId": Nutaku.user_id, "gold": 1000})
	if refill:
		refill.pressed.emit()
		check("Refill buys through NutakuGI and the level opens", await until(func(): return F2P.active_for(5), 15.0))
		check("the server filled the candles (one already spent on this level)",
			int(F2P.energy()["now"]) == int(F2P.energy()["max"]) - 1, str(F2P.energy()))
		check("the gold ledger shows the purchase", int(Nutaku.state["gold"]["spent"]) == F2P.price(F2P.SKU_REFILL))

	# ---- undo: one free, the second buys a token ------------------------------------------
	check("a fold on level 6", safe_fold())
	var u1: bool = await game._try_undo()
	check("the first undo is free", u1 and F2P.tokens("undo") == 0)
	safe_fold()
	var ok2: bool = await game._try_undo()
	check("the second undo buys an undo pack and spends one",
		ok2 and F2P.tokens("undo") == 4 and int(F2P.attempt.get("undos_bought", 0)) == 1, str(Nutaku.state.get("tokens")))

	# ---- hint -----------------------------------------------------------------------------
	await game._f2p_hint()
	var hint_lbl: Label = game.get("_hint")
	check("the hint button buys hints and names a fold", hint_lbl.text.begins_with("Hint: fold ")
		and F2P.tokens("hint") == 2, hint_lbl.text)

	# ---- exhaust the move budget -------------------------------------------------------------
	var guard := 0
	while not F2P.out_of_moves() and guard < 50 and safe_fold():
		guard += 1
		await sleep(0.05)
	var more: Button = await wait_button("MoreMoves")
	check("an exhausted budget shows the out-of-moves card", more != null, "spent %d of %d" % [F2P.spent(), F2P.allowed()])
	if more:
		var left0 := F2P.moves_left()
		more.pressed.emit()
		check("+5 moves buys a token and the server grants five more",
			await until(func(): return F2P.moves_left() == left0 + 5), "left %d" % F2P.moves_left())
