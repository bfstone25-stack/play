extends Node
## Office Landlord's real game state. Autoloaded as "Grid". Everything the old fake
## per-second income tick (`Economy`) used to fake is now the actual `Landlord` kernel:
## a 20-cell board, `Landlord.settle_grid()` for payout, `Landlord.rent_for_floor()` for
## the gate.
##
## `economy.gd`/`Economy` (the old per-second fake income tick) is DELETED, not kept
## alongside this -- it modelled a loop the real kernel replaces outright (hire a desk,
## tick rent/sec), and an autoload nothing references is confusion waiting to be read as
## still-live game state by the next person who opens this file.
##
## ---- decisions landlord.js does not make, and why these were picked ----
##
## landlord.js defines settleGrid/rentForFloor/shopPool/pickShop and nothing about what
## happens BETWEEN settlements — no "next floor" transition, no eviction consequence, no
## shop price list. Those are Office Landlord's own, kept deliberately small (this is the
## all-ages sibling, not OCCUPANCY's full idle/prestige/gacha system):
##
##   * Paying rent (payout >= rent_for_floor) BANKS the surplus, advances floor_level by
##     one, and CLEARS the grid for the new floor. Relics and the deck (and therefore the
##     tray's future rolls) carry over -- floors get harder (RENT_GROWTH=1.45) so a board
##     that keeps its shop investments is the only way a floor after 3-4 is winnable at
##     all. Clearing rather than keeping the board is the simplest honest reading of
##     "move up a floor": last floor's placement doesn't help you on new carpet.
##   * MISSING rent is a real, visible consequence: `evicted` fires, the current floor's
##     placements are lost (grid clears, so the player starts that floor over) and banked
##     currency takes a 25% haircut -- enough to sting, not a permanent game-over. This
##     mirrors the shape of `overtime-idle-godot/scripts/building.gd`'s `Ticker.evicted`
##     signal (fires a bark, shows a report) at a much smaller scale: no multi-tenant
##     eviction roster, just "this floor failed, try again poorer."
##   * Shop prices (RELIC_PRICE=10, SYMBOL_PRICE=4) are invented here, not in landlord.js.
##     A symbol purchase adds one more copy of that id to `deck`, which only changes the
##     ODDS of future tray rolls (`Landlord.CATALOG` itself is fixed at 8 entries; nothing
##     in the kernel lets a shop invent a ninth). A relic purchase applies immediately and
##     permanently to every future `settle_grid` call.
##   * The tray always holds TRAY_SIZE symbols: placing one immediately rolls a
##     replacement from `deck` into its slot, so the player is never holding zero
##     placeable pieces. landlord.js's own `rollFrom` is what rolls it.

signal changed
signal evicted(report: Dictionary)
signal rent_paid(report: Dictionary)

const TRAY_SIZE := 4
const RELIC_PRICE := 10
const SYMBOL_PRICE := 4
const EVICTION_PENALTY := 0.25   # fraction of banked currency lost on a missed rent

var cells: Array = []
var relics: Array = []
var deck: Array = []
var tray: Array = []
var floor_level := 1
var banked := 0
var last_report: Dictionary = {}     # most recent settle_grid() result, for the report panel
var last_evicted := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	reset()

func reset() -> void:
	cells = Landlord.empty_cells()
	relics = []
	deck = Landlord.STARTER.duplicate()
	floor_level = 1
	banked = 0
	last_report = {}
	last_evicted = false
	_refill_tray()
	changed.emit()

func _refill_tray() -> void:
	while tray.size() < TRAY_SIZE:
		tray.append(_roll_one())

func _roll_one() -> String:
	if deck.is_empty():
		return Landlord.STARTER[_rng.randi() % Landlord.STARTER.size()]
	return deck[_rng.randi() % deck.size()]

## Live payout for the board as it stands right now -- called freely by the UI to show
## per-cell scores and a running total before the player commits to collect_rent().
func settle() -> Dictionary:
	return Landlord.settle_grid(cells, Landlord.CATALOG, relics)

func current_rent() -> int:
	return Landlord.rent_for_floor(floor_level, relics)

func rent_met() -> bool:
	var r := settle()
	return int(r["payout"]) >= current_rent()

func can_place(tray_index: int, cell_index: int) -> bool:
	if tray_index < 0 or tray_index >= tray.size():
		return false
	if cell_index < 0 or cell_index >= Landlord.SIZE:
		return false
	return Landlord._id(cells, cell_index) == ""

func place(tray_index: int, cell_index: int) -> bool:
	if not can_place(tray_index, cell_index):
		return false
	var id: String = tray[tray_index]
	var next := Landlord.place_at(cells, id, cell_index)
	if next.is_empty():
		return false
	cells = next
	tray.remove_at(tray_index)
	tray.append(_roll_one())
	changed.emit()
	return true

## The rent-collection beat. Settles the board, and either pays (bank the surplus,
## advance a floor, clear the board) or evicts (lose the floor's placements, lose a slice
## of the bank). Either way the report is kept for the weekly-report panel.
func collect_rent() -> Dictionary:
	var report := settle()
	var rent := current_rent()
	report["rent"] = rent
	report["floor"] = floor_level
	var met: bool = int(report["payout"]) >= rent
	report["met"] = met
	last_report = report
	if met:
		var surplus: int = int(report["payout"]) - rent
		banked += surplus
		floor_level += 1
		cells = Landlord.empty_cells()
		last_evicted = false
		rent_paid.emit(report)
	else:
		var penalty := int(floor(banked * EVICTION_PENALTY))
		banked = max(0, banked - penalty)
		report["penalty"] = penalty
		cells = Landlord.empty_cells()
		last_evicted = true
		evicted.emit(report)
	_refill_tray()
	changed.emit()
	return report

## Real shop offers, from Landlord.pick_shop -- not static text. `count` mirrors the 3
## offers a landlord.js-style shop screen would show at once.
func shop_offers(count: int = 3) -> Array:
	return Landlord.pick_shop(relics, Landlord.CATALOG, count, _rng)

func price(offer: Dictionary) -> int:
	return RELIC_PRICE if offer.get("kind") == "relic" else SYMBOL_PRICE

func can_buy(offer: Dictionary) -> bool:
	if offer.get("kind") == "relic" and relics.has(offer.get("id")):
		return false      # already owned; pick_shop excludes these but be defensive
	return banked >= price(offer)

func buy(offer: Dictionary) -> bool:
	if not can_buy(offer):
		return false
	banked -= price(offer)
	if offer.get("kind") == "relic":
		relics.append(offer.get("id"))
	else:
		deck.append(offer.get("id"))
	changed.emit()
	return true

## Which staff-tagged symbols (dev/intern/standup) are actually on the board right now,
## for the staff-directory panel. Real, live grid state -- not a canned roster.
func staff_on_board() -> Array:
	var out: Array = []
	for i in range(cells.size()):
		var id: String = Landlord._id(cells, i)
		if Landlord.STAFF_TAGS.has(id):
			out.append({"index": i, "id": id})
	return out
