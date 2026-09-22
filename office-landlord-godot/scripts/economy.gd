extends Node
## Office Landlord's numbers. Autoloaded as "Economy".
##
## Small idle loop, on purpose: rent accrues per second from filled desks, the player can
## hire a tenant (spends rent, raises income), and can collect a lump "big win" once the
## floor is full, which resets the floor at a higher multiplier (the prestige beat).

signal changed

const MAX_DESKS := 6
const HIRE_BASE_COST := 20.0
const HIRE_COST_GROWTH := 1.6

var rent := 0.0
var desks_filled := 0
var floor_level := 1
var income_mult := 1.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if desks_filled > 0:
		rent += income_per_second() * delta
		changed.emit()

func income_per_second() -> float:
	return desks_filled * 1.4 * income_mult

func hire_cost() -> int:
	return int(ceil(HIRE_BASE_COST * pow(HIRE_COST_GROWTH, desks_filled)))

func can_hire() -> bool:
	return desks_filled < MAX_DESKS and rent >= hire_cost()

func hire() -> bool:
	if not can_hire():
		return false
	rent -= hire_cost()
	desks_filled += 1
	changed.emit()
	return true

func floor_full() -> bool:
	return desks_filled >= MAX_DESKS

## The "move to a bigger building" beat: banks the floor, raises the multiplier, resets
## desks to zero so the loop starts again with a visibly higher ceiling.
func prestige() -> void:
	floor_level += 1
	income_mult += 0.5
	desks_filled = 0
	rent = floor(rent * 0.25)
	changed.emit()
