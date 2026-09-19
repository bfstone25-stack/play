extends SceneTree

## Five routes through the actual story files, driven through the real scene tree.
##
## This is the port of the Ren'Py fork's tools/simulate.py, which existed because there was
## no SDK on this machine to lint with. Here there is an engine, so the "interpreter" is
## just the game: every beat is walked, every label is entered, every line of prose is
## rendered into the RichTextLabel. It catches the same class of bug simulate.py caught —
## a label that never gets reached, a fee charged twice, a route that runs off the end.

const C := preload("res://scripts/collateral_core.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	failures.append(msg)


func _fresh() -> Node:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	return game


## Walk the night, taking the option whose index `picker` returns at each menu. Returns
## the number of lines of prose that were shown.
func _walk(game: Node, picker: Callable, stop_at_demo := false) -> int:
	var lines := 0
	var guard := 0
	while not game.finished:
		guard += 1
		if guard > 4000:
			_fail("route did not terminate")
			break
		if game.ledger_open:
			game.close_ledger()
			continue
		if game.awaiting_choice:
			var n: int = game.current_options.size()
			game.choose(clampi(picker.call(game, n), 0, n - 1))
			continue
		lines += 1
		game.advance()
	if stop_at_demo and game.ending_id != "DEMO":
		_fail("the demo build did not stop at the cut point, got %s" % game.ending_id)
	return lines


func _route(name: String, picker: Callable) -> Node:
	var game := _fresh()
	await process_frame
	var lines := _walk(game, picker)
	if lines < 40:
		_fail("%s: only %d lines of prose shown — a label is being skipped" % [name, lines])
	print("  %-10s ending=%-11s lines=%3d till=%4d net=%4d taken=%s refused=%s fees=%d refunded=%d cgs=%s" % [
		name, game.ending_id, lines, game.run.till, game.run.net_worth(),
		str(game.run.readings_taken), str(game.run.readings_refused),
		game.run.fees_paid, game.run.fees_refunded, str(C.unlocked_cgs(game.run))])
	return game


func _run() -> void:
	# 1. Mercy: look at everything, pay everyone above the odds, refuse Calder.
	var mercy := await _route("mercy", func(g: Node, n: int) -> int:
		if _is_calder(g):
			return 1                     # don't sell
		return 2 if n == 3 else 0)       # HIGH, and always look
	if mercy.ending_id != C.COLLATERAL:
		_fail("mercy route should end in Collateral, got %s" % mercy.ending_id)
	var mercy_cgs := C.unlocked_cgs(mercy.run)
	if mercy_cgs.size() != 5:
		_fail("mercy route should unlock five of six, got %s" % [mercy_cgs])
	if mercy_cgs.has("tamsin"):
		_fail("tamsin and finial are meant to be mutually exclusive in one run")
	mercy.free()

	# 2. Ruthless: refuse every reading, lowball everyone.
	var cold := await _route("ruthless", func(_g: Node, _n: int) -> int: return _n - 1 if _n == 2 else 0)
	if cold.ending_id != C.SOLVENT:
		_fail("the refusal route should end Solvent, got %s" % cold.ending_id)
	if not C.unlocked_cgs(cold.run).is_empty() and C.unlocked_cgs(cold.run) != ["collateral"]:
		_fail("a run that refused everything unlocked %s" % [C.unlocked_cgs(cold.run)])
	cold.free()

	# 3. Honest: look at everything, price everything FAIR, refuse Calder. The
	#    affordability guarantee, played rather than calculated.
	var honest := await _route("honest", func(g: Node, n: int) -> int:
		if n == 3:
			return 1                     # FAIR
		return 0 if g.run.sold_reading == "" and not _is_calder(g) else 1)
	if honest.run.net_worth() < C.DEBT:
		_fail("the honest route could not clear the debt: %d" % honest.run.net_worth())
	# 55 of shop cash is asked for across the ring and the veil (the finial's fee is 0).
	# How much of it stays asked-for depends on how much art is installed, and that is the
	# point: a reading whose plate never arrives is refunded on every track, paid included.
	# So the invariant is that the money is accounted for, not that it is kept.
	if honest.run.fees_paid + honest.run.fees_refunded != 55:
		_fail("the honest route lost track of the fees: paid %d refunded %d" % [
			honest.run.fees_paid, honest.run.fees_refunded])
	honest.free()

	# 4. Factor: look at things, then sell one to Calder.
	var factor := await _route("factor", func(_g: Node, n: int) -> int: return 0)
	if factor.ending_id != C.FACTOR:
		_fail("selling to Calder should end Factor, got %s" % factor.ending_id)
	if factor.run.sold_reading == "":
		_fail("the factor route did not record a sale")
	factor.free()

	# 5. The free browser sample: it must stop at the chapter-2 gate, with Tamsin and Ivo
	#    done, before the veil — and before any gated plate has been shown.
	var demo := _fresh()
	await process_frame
	demo.DEMO = true
	_walk(demo, func(_g: Node, _n: int) -> int: return 0, true)
	if demo.run.readings_taken.has("veil") or demo.run.readings_taken.has("collateral"):
		_fail("the demo reached past the second appraisal: %s" % [demo.run.readings_taken])
	if not demo.visited.has("act_ring"):
		_fail("the demo did not include the second appraisal")
	# act_veil is entered — the chapter gate is its first beat, exactly as chapter_gate(2)
	# was the first line of the Ren'Py label — but nothing in it may run past the gate.
	if demo.visited.has("veil_take") or demo.visited.has("veil_price"):
		_fail("the demo ran past the chapter-2 gate into the veil")
	if demo.plates.current != "":
		_fail("the demo left a plate on screen at the cut point")
	print("  demo       ending=DEMO       taken=%s till=%d" % [str(demo.run.readings_taken), demo.run.till])
	demo.free()

	# 6. The free web package: no assets/plates_x/, no bytes delivered, no network. Every
	#    gated plate falls back, every fee comes back, and the run still finishes. This is
	#    the route the refund rule exists for, and it is the one the old synchronous code
	#    answered before the fetch had happened rather than after it.
	Unlock.simulate_free = true
	for id in Collateral.PLATES.keys():
		Unlock.clear(id)
	var free_run := await _route("free-web", func(g: Node, n: int) -> int:
		if _is_calder(g):
			return 1
		return 2 if n == 3 else 0)
	if free_run.run.fees_paid != 0:
		_fail("the free track kept %d in fees for plates it never showed" % free_run.run.fees_paid)
	if free_run.run.fees_refunded != 55:
		_fail("the free track refunded %d, expected 55" % free_run.run.fees_refunded)
	if free_run.plates.current_source == free_run.plates.SRC_REAL:
		_fail("a free package resolved a real plate")
	# The ledger still credits what was earned; it just marks it censored.
	if C.unlocked_cgs(free_run.run).size() != 5:
		_fail("the free track lost ledger credit: %s" % [C.unlocked_cgs(free_run.run)])
	free_run.free()
	Unlock.simulate_free = false

	if failures.is_empty():
		print("PLAYTHROUGH_OK routes=6")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)


func _is_calder(game: Node) -> bool:
	return game.label == "market_offer"
