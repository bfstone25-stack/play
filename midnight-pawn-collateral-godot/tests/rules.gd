extends SceneTree

## The rules module, with no engine in it. The GDScript twin of the Ren'Py fork's
## tools/playthrough.py: the economy, the six CG conditions, the affordability guarantee,
## the refund arithmetic and all three endings, asserted without drawing a frame.

const C := preload("res://scripts/collateral_core.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	failures.append(msg)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)


func _run() -> void:
	_test_prices()
	_test_cg_conditions()
	_test_affordable_honest_run()
	_test_refund()
	_test_endings()
	if failures.is_empty():
		print("RULES_OK")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)


func _test_prices() -> void:
	# The exact numbers the prose says out loud: 14 / 22 / 33, 26 / 40 / 60, 23 / 35 / 52.
	_check(C.price_of("finial", "low") == 14, "finial low should be 14")
	_check(C.price_of("finial", "fair") == 22, "finial fair should be 22")
	_check(C.price_of("finial", "high") == 33, "finial high should be 33")
	_check(C.price_of("ring", "low") == 26, "ring low should be 26")
	_check(C.price_of("ring", "fair") == 40, "ring fair should be 40")
	_check(C.price_of("ring", "high") == 60, "ring high should be 60")
	_check(C.price_of("veil", "low") == 23, "veil low should be 23")
	_check(C.price_of("veil", "fair") == 35, "veil fair should be 35")
	_check(C.price_of("veil", "high") == 52, "veil high should be 52")


func _test_cg_conditions() -> void:
	# Not one of these may be satisfiable by playtime. The test that enforces it is this
	# one: a run that has done nothing unlocks nothing, no matter how long it took.
	var empty := C.Run.new()
	_check(C.unlocked_cgs(empty).is_empty(), "an untouched run unlocked something")

	# cg_tamsin: read the finial and price it FAIR.
	var a := C.Run.new()
	a.record_reading("finial")
	a.pay_client("finial", "fair")
	_check(C.unlocked_cgs(a) == ["tamsin"], "FAIR finial should unlock tamsin alone, got %s" % [C.unlocked_cgs(a)])

	# cg_finial: the same vision, further in — HIGH only. Mutually exclusive with tamsin.
	var b := C.Run.new()
	b.record_reading("finial")
	b.pay_client("finial", "high")
	_check(C.unlocked_cgs(b) == ["finial"], "HIGH finial should unlock finial alone, got %s" % [C.unlocked_cgs(b)])

	# cg_ring requires the refusal as well as the reading.
	var c := C.Run.new()
	c.record_reading("ring")
	_check(not bool(C.cg_conditions(c)["ring"][0]), "ring unlocked without Ivo having said no")
	c.ivo_refused = true
	_check(bool(C.cg_conditions(c)["ring"][0]), "ring did not unlock after the refusal")

	# cg_veil requires the offer to clear the veil's true value: mercy has to cost.
	var d := C.Run.new()
	d.record_reading("veil")
	d.pay_client("veil", "fair")
	_check(not bool(C.cg_conditions(d)["veil"][0]), "veil unlocked at FAIR — mercy did not cost")
	var e := C.Run.new()
	e.record_reading("veil")
	e.pay_client("veil", "high")
	_check(bool(C.cg_conditions(e)["veil"][0]), "veil did not unlock at HIGH")

	# cg_market needs two client readings carried down.
	var f := C.Run.new()
	f.record_reading("finial")
	_check(not bool(C.cg_conditions(f)["market"][0]), "market unlocked on one reading")
	f.record_reading("veil")
	_check(bool(C.cg_conditions(f)["market"][0]), "market did not unlock on two readings")

	# cg_collateral is unrefusable and has no other condition.
	var g := C.Run.new()
	g.record_reading("collateral")
	_check(bool(C.cg_conditions(g)["collateral"][0]), "collateral did not unlock")

	# Six slots, five of them gated, exactly as GATED_CGS specifies.
	_check(Collateral.PLATES.size() == 6, "expected six plates, got %d" % Collateral.PLATES.size())
	_check(Collateral.GATED.size() == 5, "expected five gated plates, got %d" % Collateral.GATED.size())
	_check(not Collateral.is_gated("cg_tamsin"), "cg_tamsin must be ungated on every track")


## Check 1 from the Ren'Py fork: price everything FAIR and you can pay all three optional
## fees and still clear the debt. The fee punishes cheating the clients, not curiosity —
## if this ever fails, the reading gate has become a second paywall by arithmetic.
func _test_affordable_honest_run() -> void:
	var run := C.Run.new()
	for item in ["finial", "ring", "veil"]:
		_check(run.can_afford(C.fee_for(item)), "could not afford the %s fee on an honest run" % item)
		run.charge_reading(item)
		run.record_reading(item)
		run.pay_client(item, "fair")
	run.earn(C.MARKET_HAUL)
	run.charge_reading("collateral")
	run.record_reading("collateral")
	_check(run.net_worth() >= C.DEBT,
		"an honest run that looked at everything came out at %d against a debt of %d" % [run.net_worth(), C.DEBT])
	_check(run.net_worth() - C.DEBT == 35,
		"the honest route's margin moved: %d, expected 35" % (run.net_worth() - C.DEBT))


## The refund rule, in arithmetic. A fee charged and handed back must leave the till
## exactly where it started and must show up as refunded rather than paid, because the
## dawn outro reports both numbers.
func _test_refund() -> void:
	var run := C.Run.new()
	var before := run.till
	run.charge_reading("ring")
	_check(run.till == before - 35, "the ring fee did not come out of the till")
	_check(run.fees_paid == 35, "fees_paid did not record the ring fee")
	run.refund_reading("ring")
	_check(run.till == before, "the refund did not put the money back")
	_check(run.fees_paid == 0, "a refunded fee is still counted as paid")
	_check(run.fees_refunded == 35, "the refund was not recorded")


func _test_endings() -> void:
	# Factor wins over everything: selling a client's reading is a thing you did.
	var factor := C.Run.new()
	factor.record_reading("finial")
	factor.record_reading("ring")
	factor.record_reading("veil")
	factor.sold_reading = "veil"
	_check(C.ending_of(factor) == C.FACTOR, "selling a reading did not give Factor")

	# Three client readings and no sale is Collateral, however rich you are.
	var coll := C.Run.new()
	coll.record_reading("finial")
	coll.record_reading("ring")
	coll.record_reading("veil")
	coll.earn(1000)
	_check(C.ending_of(coll) == C.COLLATERAL, "three readings did not give Collateral")

	# Refusing three and clearing the debt is Solvent.
	var solv := C.Run.new()
	solv.record_refusal("finial")
	solv.record_refusal("ring")
	solv.record_refusal("veil")
	solv.pay_client("finial", "fair")
	_check(C.ending_of(solv) == C.SOLVENT, "the refusal route did not give Solvent")

	# Broke and not solvent falls to Collateral.
	var broke := C.Run.new()
	broke.spend(260)
	_check(C.ending_of(broke) == C.COLLATERAL, "a broke run did not fall to Collateral")
