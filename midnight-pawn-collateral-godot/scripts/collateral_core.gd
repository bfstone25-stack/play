extends RefCounted
class_name CollateralCore

## collateral_core — the rules of Midnight Pawn: Collateral.
##
## A line-for-line port of the Ren'Py fork's game/python-packages/collateral_core.py. The
## numbers, the six CG conditions and the ending priority order are unchanged; only the
## language is different. It is kept as one file with no UI in it for the same reason the
## Python one was: the CG conditions are the part of this fork that must never quietly
## drift into "unlocks after enough clicking", and a rules module with no engine in it can
## be replayed and asserted by tests/rules.gd without drawing a frame.
##
## Canon carried over from the SFW Godot game (~/midnight-pawn-src/scripts/game_state.gd):
## Nara Quill owns the Black Ledger, the Heart of the Crypt is what the shop actually wants,
## the Ossuary Market is a real room, and the economy is deterministic integers. The fork
## keeps all four and throws away the combat.
##
## Cast note: the clients are the base game's, not the design doc's — Tamsin Reed, Ivo Glass
## and Mara Voss, exactly as CUSTOMERS reads in game_state.gd:18-23. See README.

const TILL_START := 260
const DEBT := 200          # what Elsa's estate still owes at dawn

## Every object that crosses the counter. `value` is what it is honestly worth; `fee` is
## what taking a reading costs out of the till. Deterministic — same numbers every run,
## like the base game.
const ITEMS := {
	"finial": {
		"client": "Tamsin Reed", "label": "Brass bed-frame finial", "value": 22, "fee": 0,
		"clue": "Unscrewed in a hurry. The thread is bright where the tool slipped.",
	},
	"ring": {
		"client": "Ivo Glass", "label": "Wedding ring, not his wife's", "value": 40, "fee": 35,
		"clue": "Inside the band: a date eleven months after the divorce was final.",
	},
	"veil": {
		"client": "Mara Voss", "label": "Mourning veil, black crepe", "value": 35, "fee": 20,
		"clue": "Pressed once, worn once, and never washed.",
	},
	"market": {
		"client": "Calder", "label": "A reading bought from another broker", "value": 0, "fee": 0,
		"clue": "Somebody else's night, resold. Proof the trade is real.",
	},
	"collateral": {
		"client": "Nara Quill", "label": "The Black Ledger", "value": 0, "fee": 0,
		"clue": "Owner: Nara Quill. Due date: tomorrow.",
	},
}

## What the midnight run in the Ossuary Market pays for the ordinary crypt haul — bone
## charms and unclaimed stock, nothing to do with readings.
const MARKET_HAUL := 30

## What Calder pays for a client's reading. The Factor ending's price.
const CALDER_READING_PRICE := 90

const PRICE_TIERS := ["low", "fair", "high"]

const SOLVENT := "solvent"
const FACTOR := "factor"
const COLLATERAL := "collateral"

const ENDING_NAMES := {
	SOLVENT: "Solvent",
	FACTOR: "Factor",
	COLLATERAL: "Collateral",
}

const CLIENT_ITEMS := ["finial", "ring", "veil"]


## What you hand the client. LOW cheats them, FAIR is the honest number, HIGH is mercy.
static func price_of(item: String, tier: String) -> int:
	var v: int = int(ITEMS[item]["value"])
	if tier == "low":
		return (v * 2) / 3
	if tier == "high":
		return (v * 3) / 2
	return v


static func value_of(item: String) -> int:
	return int(ITEMS[item]["value"])


static func fee_for(item: String) -> int:
	return int(ITEMS[item]["fee"])


## One night. Mutated by the script; read by the ending and the Reading Ledger.
class Run extends RefCounted:
	var till := CollateralCore.TILL_START
	var readings_taken: Array[String] = []      # items whose reading you paid for and received
	var readings_refused: Array[String] = []    # items you deliberately priced blind
	var prices := {}                            # item -> "low" / "fair" / "high"
	var paid := {}                              # item -> cash actually handed over
	var stock: Array[String] = []               # items now on the shelf (yours at dawn)
	var sold_reading := ""                      # which client's reading you sold to Calder
	var ivo_refused := false                    # Ivo asked you not to look
	var fees_paid := 0
	var fees_refunded := 0

	# -- money ------------------------------------------------------------
	func can_afford(n: int) -> bool:
		return till >= n

	func spend(n: int) -> int:
		till -= n
		return till

	func earn(n: int) -> int:
		till += n
		return till

	# -- appraisals -------------------------------------------------------
	## Take the fee out of the till. Returns the fee charged.
	func charge_reading(item: String) -> int:
		var fee := CollateralCore.fee_for(item)
		till -= fee
		fees_paid += fee
		return fee

	## Hand the fee back.
	##
	## This exists because of the second-paywall problem. On a free track the real
	## distribution gate may leave the plate censored; charging shop cash for a censored
	## plate is exactly the "paying customer feels cheated" failure the design flags. So
	## the fee is conditional on delivery, and the game says so out loud.
	func refund_reading(item: String) -> int:
		var fee := CollateralCore.fee_for(item)
		till += fee
		fees_paid -= fee
		fees_refunded += fee
		return fee

	func record_reading(item: String) -> void:
		if not readings_taken.has(item):
			readings_taken.append(item)
		readings_refused.erase(item)

	func record_refusal(item: String) -> void:
		if not readings_refused.has(item) and not readings_taken.has(item):
			readings_refused.append(item)

	func pay_client(item: String, tier: String) -> int:
		var cash := CollateralCore.price_of(item, tier)
		prices[item] = tier
		paid[item] = cash
		till -= cash
		if not stock.has(item):
			stock.append(item)
		return cash

	# -- dawn -------------------------------------------------------------
	func stock_value() -> int:
		var total := 0
		for k in stock:
			total += CollateralCore.value_of(k)
		return total

	func net_worth() -> int:
		return till + stock_value()

	func client_readings() -> Array:
		var out: Array = []
		for k in readings_taken:
			if CollateralCore.CLIENT_ITEMS.has(k):
				out.append(k)
		return out


## item key -> [unlocked, one-line reason shown in the Reading Ledger].
##
## Every entry is a pure function of run state. There is deliberately no clock, no scene
## counter and no "seen enough dialogue" term anywhere in this table: a CG that unlocks
## from playtime is the thing this fork is specifically not allowed to do, and keeping the
## whole table in one testable place is how that stays true.
static func cg_conditions(run: Run) -> Dictionary:
	var out := {}

	# 1. The tutorial reading, free on every track. Priced her honestly.
	out["tamsin"] = [
		run.prices.get("finial", "") == "fair" and run.readings_taken.has("finial"),
		"Read the finial and paid Tamsin what it was worth.",
	]

	# 2. The same vision, further in — only if you overpaid her for a bed she is selling
	#    out from under herself. Mercy costs cash and buys the deeper plate.
	out["finial"] = [
		run.prices.get("finial", "") == "high" and run.readings_taken.has("finial"),
		"Read the finial and paid Tamsin above its worth.",
	]

	# 3. Ivo asked you not to look. You paid the fee and looked anyway.
	out["ring"] = [
		run.readings_taken.has("ring") and run.ivo_refused,
		"Took the ring's reading after Ivo asked you not to.",
	]

	# 4. Mercy, again, and it has to cost: the offer must clear the veil's true value.
	out["veil"] = [
		run.readings_taken.has("veil") and int(run.paid.get("veil", 0)) > value_of("veil"),
		"Read the veil and offered Mara more than it was worth.",
	]

	# 5. Calder only demonstrates for a broker who is carrying something worth trading.
	out["market"] = [
		run.client_readings().size() >= 2,
		"Carried two client readings down to the Ossuary Market.",
	]

	# 6. The last object in the midnight restock is yours. No condition, no refusal.
	out["collateral"] = [
		run.readings_taken.has("collateral"),
		"The shop put your own ledger on the counter.",
	]
	return out


static func unlocked_cgs(run: Run) -> Array:
	var out: Array = []
	for k in cg_conditions(run):
		if bool(cg_conditions(run)[k][0]):
			out.append(k)
	out.sort()
	return out


## Three endings, resolved in priority order.
##
## Factor first because selling a client's reading is a thing you did that cannot be
## outweighed by arithmetic. Then Collateral, which is what taking everything costs you.
## Solvent is the one you have to actually refuse things to reach.
static func ending_of(run: Run) -> String:
	if run.sold_reading != "":
		return FACTOR
	if run.client_readings().size() >= 3:
		return COLLATERAL
	if run.readings_refused.size() >= 3 and run.net_worth() >= DEBT:
		return SOLVENT
	return SOLVENT if run.net_worth() >= DEBT else COLLATERAL
