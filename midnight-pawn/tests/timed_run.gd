extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var pace_seconds := 24.5
var step := 0
var started := 0


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pace="):
			pace_seconds = float(arg.trim_prefix("--pace="))
	call_deferred("_run")


func _pace(label: String) -> void:
	step += 1
	print("TIMED STEP %02d · %s · elapsed %.1fs" % [step, label, (Time.get_ticks_msec() - started) / 1000.0])
	await create_timer(pace_seconds).timeout


func _combat(state, action: String, label: String) -> void:
	state.combat_action(action)
	await _pace(label)


func _run() -> void:
	started = Time.get_ticks_msec()
	var state = StateScript.new()
	state.reset()
	await _pace("read inheritance")
	state.tutorial_sale()
	await _pace("tutorial appraisal, fair price, sale")
	for id in ["wedding_ring", "bone_key"]:
		state.appraise(id)
		await _pace("read appraisal " + id)
		state.toggle_shelf(id)
		await _pace("set price and display " + id)
		state.call_customer(id)
		await _pace("read customer demand and offer " + id)
		state.resolve_customer(true, true)
		await _pace("complete honest transaction " + id)
	state.enter_night("music_box")
	await _pace("choose carried curio and descend night 1")
	await _pace("move across Receipt Stair and inspect curse")
	while state.room_active:
		await _combat(state, "strike", "fight Receipt Moth")
	state.advance_room()
	await _pace("enter Widow's Niche")
	await _pace("move to Widow Voss and read claimant memory")
	while state.room_active:
		await _combat(state, "strike", "resolve Widow encounter")
	state.advance_room()
	await _pace("extract and review banked loot")
	for id in ["dueling_pistol", "black_ledger"]:
		state.appraise(id)
		await _pace("read Day 2 identity " + id)
		state.toggle_shelf(id)
		await _pace("set price and display " + id)
		state.call_customer(id)
		await _pace("negotiate customer offer " + id)
		if id == "dueling_pistol":
			state.negotiate_current()
			await _pace("spend Resolve to improve Tamsin's offer")
		state.resolve_customer(true, true)
		await _pace("complete warned transaction " + id)
	state.enter_night("music_box")
	await _pace("choose build and descend night 2")
	await _pace("cross Ossuary Market spike route")
	while state.room_active:
		await _combat(state, "strike", "fight Debt Hand elite")
	state.advance_room()
	await _pace("enter Foreclosure Chapel")
	await _pace("approach Bell Warden and read pattern")
	while state.room_active:
		await _combat(state, "item", "use Music Box against Bell Warden")
	state.advance_room()
	await _pace("extract Heart and read final appraisal")
	state.choose_final("seal")
	await _pace("seal Heart and read score recap")
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	var valid: bool = state.phase == StateScript.Phase.RESULT and state.rooms_cleared.size() == 4 and state.economy_valid()
	print("TIMED RUN RESULT steps=%d elapsed_seconds=%.1f elapsed_minutes=%.2f outcome=%s score=%d valid=%s" % [step, elapsed, elapsed / 60.0, state.outcome, state.score, valid])
	var duration_valid: bool = pace_seconds == 0.0 or (elapsed >= 900.0 and elapsed <= 1200.0)
	quit(0 if valid and duration_valid else 1)
