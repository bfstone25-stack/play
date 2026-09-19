class_name Idle
## The gate keeps collecting while you are away.
##
## Port of play/catharsis/kernel/idle.js — the same `idleRate` / `offlineSeconds` /
## `offlineEarn` triple, same 8-hour cap, same `Math.floor` at the end. PLAN.md wave 4 for
## this title is literally "Offline earnings with timestamp clamp; IAA double stub; 8h away
## math documented", and this is that; the shipped JS build never got it, so this is the
## one place the Godot rebuild adds rather than ports.
##
## Everything it is fed comes out of the table's own numbers, so nothing new was invented:
##   level      the era index + 1 — the booth is level 1, the neon empire level 4
##   buildings  the property upgrades, at the rate their own score multiplier implies
##              (studio +8%, loft +10%, penthouse +12%, neon +10% -> 0.8 / 1.0 / 1.2 / 1.0
##              coins per second per level, i.e. a tenth of their percentage)
##   empire     PERKS already declares `empire: {idle: 0.12}` and the JS never read it.
##              It is the offline multiplier, +12% per rank.
##
## The rate is coins per second. Eight hours of a mid-run gate is a few thousand coins —
## one or two upgrades, not a run's worth. The return screen shows the number and the
## elapsed time, and the ad track can offer to double it (Economy.double_offline).

const CAP_HOURS := 8.0
const CAP_MS: int = int(CAP_HOURS * 3600.0 * 1000.0)

## coins/s per level of each property upgrade — a tenth of the score multiplier it grants.
const BUILDING_RATE := {"studio": 0.8, "loft": 1.0, "penthouse": 1.2, "neon": 1.0}


## idle.js `idleRate(level, buildings)`, verbatim: 1 + (level-1)*0.85, plus count*rate.
static func idle_rate(level: int, buildings: Array) -> float:
	var r := 1.0 + maxf(0.0, float(maxi(1, level)) - 1.0) * 0.85
	for b in buildings:
		r += float(b.get("count", 0)) * float(b.get("rate", 0.0))
	return r


## The buildings list this title feeds idle_rate: its property upgrades.
static func buildings_of(state: Dictionary) -> Array:
	var out: Array = []
	for id in BUILDING_RATE:
		out.append({"count": Kernel.level_of(state, id), "rate": BUILDING_RATE[id]})
	return out


## Coins per second while away.
static func rate_of(state: Dictionary) -> float:
	var base := idle_rate(Kernel.era_index(state) + 1, buildings_of(state))
	return base * (1.0 + Kernel.perk_of(state, "empire") * 0.12)


## idle.js `offlineSeconds`, verbatim, including the "clock went backwards" clamp.
static func offline_seconds(last_ms: int, now_ms: int, cap_hours: float = CAP_HOURS) -> float:
	var cap := cap_hours * 3600.0
	if last_ms == 0 or now_ms == 0:
		return 0.0
	if now_ms < last_ms:
		return 0.0
	var dt := float(now_ms - last_ms) / 1000.0
	if dt < 0.0:
		return 0.0
	return minf(cap, dt)


## idle.js `offlineEarn`, verbatim.
static func offline_earn(last_ms: int, now_ms: int, rate: float, cap_hours: float = CAP_HOURS) -> int:
	var sec := offline_seconds(last_ms, now_ms, cap_hours)
	return int(floorf(sec * maxf(0.0, rate)))


## The whole return: what the gate took in while the player was gone, and whether the cap
## cut it short. Does NOT mutate — the return screen shows it, the player claims it.
static func settle(state: Dictionary, last_ms: int, now_ms: int) -> Dictionary:
	var rate := rate_of(state)
	var sec := offline_seconds(last_ms, now_ms)
	var away := 0.0
	if last_ms != 0 and now_ms > last_ms:
		away = float(now_ms - last_ms) / 1000.0
	return {
		"coins": offline_earn(last_ms, now_ms, rate),
		"seconds": sec,
		"awaySeconds": away,
		"capped": away > sec + 0.001,
		"rate": rate,
	}


## Claim a settlement onto the state. Coins are run coins too: the gate's takings count
## toward the prestige token the same way a rebound's do.
static func claim(state: Dictionary, coins: int) -> void:
	if coins <= 0:
		return
	state["coins"] = int(state["coins"]) + coins
	state["lifetime"] = int(state["lifetime"]) + coins
	state["runCoins"] = int(state["runCoins"]) + coins
