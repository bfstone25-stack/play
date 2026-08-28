extends SceneTree
## Headless smoke for Midnight Pawn & Crypt hybrid loop.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("MPC smoke starting…")
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load main.tscn")
		quit(1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	if not game.has_method("start_run"):
		push_error("Game missing start_run")
		quit(2)
		return

	game.start_run()
	await process_frame
	_expect(game.phase == game.Phase.DAY, "DAY after start")
	_expect(game.gold == game.STARTER_GOLD, "starter gold")

	if game.bag.size() > 0:
		game.stock_from_bag(0)
	await process_frame
	game.select_shelf(0)
	game.appraise_selected()
	var g1: int = game.gold
	game.sell_selected()
	await process_frame
	_expect(game.gold > g1, "sell increases gold")

	game.enter_night()
	await process_frame
	_expect(game.phase == game.Phase.NIGHT, "NIGHT")
	_expect(game.dungeon.visible == true, "dungeon visible")

	game.add_loot(game._make_curio("moon_coin"))
	game.return_from_dungeon()
	await process_frame
	_expect(game.phase == game.Phase.DAY, "DAY after night 1")

	game.enter_night()
	await process_frame
	game.add_loot(game._make_curio("void_shard"))
	game.return_from_dungeon()
	await process_frame
	_expect(game.phase == game.Phase.SETTLE, "SETTLE after night 2")

	while game.bag.size() > 0:
		game.stock_from_bag(0)
		for i in game.shelf.size():
			if game.shelf[i] != null:
				game.select_shelf(i)
				break
		game.appraise_selected()
		game.sell_selected()
		await process_frame

	game.finish_run()
	await process_frame
	_expect(game.phase == game.Phase.COMPLETE, "COMPLETE")
	_expect(game.score > 0, "positive score")

	print("SMOKE OK score=%d gold=%d looted=%d" % [game.score, game.gold, game.night_looted])
	quit(0)


func _expect(cond: bool, label: String) -> void:
	if not cond:
		push_error("ASSERT FAIL: " + label)
		quit(10)
