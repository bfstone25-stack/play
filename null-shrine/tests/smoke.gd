extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(value: bool, label: String) -> void:
	if value:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _prepare_day_one(state: MidnightState) -> void:
	state.reset()
	state.tutorial_sale()
	for id in ["wedding_ring", "bone_key"]:
		_expect(state.appraise(id), "appraise " + id)
		_expect(state.toggle_shelf(id), "display " + id)
		_expect(state.call_customer(id), "call customer for " + id)
		state.resolve_customer(true, true)


func _fight_room(state: MidnightState, use_item := false) -> void:
	var safety := 30
	while state.room_active and safety > 0:
		if use_item:
			state.combat_action("item")
		else:
			state.combat_action("strike")
		safety -= 1
	_expect(safety > 0, "combat terminates")


func _complete_night_one(state: MidnightState) -> void:
	_expect(state.enter_night("music_box"), "enter night 1")
	_fight_room(state)
	_expect(state.advance_room(), "advance to room 2")
	_fight_room(state)
	_expect(state.advance_room(), "extract night 1")
	_expect(state.phase == MidnightState.Phase.DAY_2, "night 1 returns to day 2")


func _prepare_day_two(state: MidnightState) -> void:
	for id in ["dueling_pistol", "black_ledger"]:
		_expect(state.appraise(id), "appraise day2 " + id)
		_expect(state.toggle_shelf(id), "display day2 " + id)
		_expect(state.call_customer(id), "call day2 customer " + id)
		state.resolve_customer(true, true)


func _complete_night_two(state: MidnightState) -> void:
	_expect(state.enter_night("music_box"), "enter night 2")
	_fight_room(state)
	if state.phase == MidnightState.Phase.NIGHT_2:
		_expect(state.advance_room(), "advance to room 4")
		_fight_room(state, true)
		if state.phase == MidnightState.Phase.NIGHT_2:
			_expect(state.advance_room(), "extract night 2")
	_expect(state.phase == MidnightState.Phase.FINAL, "night 2 reaches final")


func _full_route(choice: String) -> MidnightState:
	var state: MidnightState = StateScript.new()
	_prepare_day_one(state)
	_complete_night_one(state)
	_prepare_day_two(state)
	_complete_night_two(state)
	_expect(state.choose_final(choice), "choose final " + choice)
	_expect(state.phase == MidnightState.Phase.RESULT, "result for " + choice)
	_expect(state.economy_valid(), "economy invariant " + choice)
	return state


func _test_loss_recovery() -> void:
	var state: MidnightState = StateScript.new()
	_prepare_day_one(state)
	state.enter_night("black_ledger")
	state.unbanked_loot = ["moon_coin"]
	state.marks_unbanked = 11
	var gold_before := state.gold
	state.health = 1
	state.combat_action("strike")
	_expect(state.phase == MidnightState.Phase.DAY_2, "night 1 defeat continues")
	_expect(state.unbanked_loot.is_empty() and state.marks_unbanked == 0, "defeat loses unbanked rewards")
	_expect(state.gold == gold_before + 5, "recovery grants emergency crowns")
	_expect(state.customer_index == 2 and state.transactions.size() >= 4, "banked customer state persists")
	_expect(state.economy_valid(), "recovery invariant")


func _test_shelf_and_offer_guards() -> void:
	var state: MidnightState = StateScript.new()
	state.reset()
	state.tutorial_sale()
	_expect(not state.toggle_shelf("wedding_ring"), "cannot display unidentified curio")
	for id in ["wedding_ring", "bone_key", "music_box", "dueling_pistol"]:
		state.appraise(id)
	_expect(state.toggle_shelf("wedding_ring"), "shelf slot 1")
	_expect(state.toggle_shelf("bone_key"), "shelf slot 2")
	_expect(state.toggle_shelf("music_box"), "shelf slot 3")
	_expect(not state.toggle_shelf("dueling_pistol"), "shelf capacity enforced")
	var gold_before := state.gold
	state.call_customer("wedding_ring")
	state.resolve_customer(false)
	_expect(state.gold == gold_before and state.has_item("wedding_ring"), "rejection preserves inventory and gold")
	_expect(state.economy_valid(), "shelf invariant")


func _test_scene_load() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_expect(game.state.phase == MidnightState.Phase.TITLE, "title phase renders")
	game.start_run()
	await process_frame
	_expect(game.state.phase == MidnightState.Phase.OPENING, "opening renders")
	game.complete_tutorial()
	await process_frame
	_expect(game.state.phase == MidnightState.Phase.DAY_1, "shop renders")
	game.queue_free()


func _run() -> void:
	print("MIDNIGHT PAWN production verification")
	_test_shelf_and_offer_guards()
	_test_loss_recovery()
	var sell := _full_route("sell")
	var seal := _full_route("seal")
	var keep := _full_route("keep")
	_expect(sell.outcome.begins_with("Dawn Broker"), "sell ending")
	_expect(seal.outcome.begins_with("Quiet Seal"), "seal ending")
	_expect(keep.outcome.begins_with("Midnight Keeper"), "keep ending")
	_expect(sell.outcome != seal.outcome and seal.outcome != keep.outcome, "three distinct outcomes")
	_expect(sell.transactions.size() >= 5, "four customers plus tutorial transaction")
	_expect(sell.rooms_cleared.size() == 4 and sell.recovered == 0, "automated route clears all four rooms")
	await _test_scene_load()
	if failures > 0:
		push_error("VERIFICATION FAILED: %d assertions" % failures)
		quit(1)
	else:
		print("VERIFICATION PASSED: all systems, invariants, recovery, and endings")
		quit(0)
