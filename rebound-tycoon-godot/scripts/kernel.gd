class_name Kernel
## Exact port of play/rebound-tycoon/frontend/js/kernel.js — the whole of REBOUND TYCOON's
## rules: the table, the physics, the economy, the eras, the prestige.
##
## Nothing here touches the scene tree. State is a Dictionary and the clock is handed in,
## so tests drive it with a fixed dt and a seeded RNG while TableView drives it with the
## real frame time. Presentation never owns a number (play/catharsis/PLAN.md).
##
## Ported *exactly*, which means a few things that look like bugs are kept:
##   - `hitFlipper` compares `pivot === LEFT_PIVOT` on a shared object; here the pivots
##     are values, so the port uses the `pivot.x < 0.5` half of the same expression, which
##     is what the JS actually evaluates to for both pivots.
##   - the plunge auto-fires at charge 0.78 on a tap and at 1.0 when held to full, and a
##     weak release below 0.08 does nothing — the comment in the JS about the ball dying
##     in the hose is why the launch floor `minVy` exists.
##   - coins are floored at 1 per award, so even a 0-point hit pays a coin.
##
## `Math.hypot` is NOT sqrt(x*x + y*y): V8 scales by the largest term and sums with a
## Neumaier compensation, and the two disagree in the last ulp for ~37% of inputs. Over a
## few thousand substeps that is enough to send a ball down a different lane, so `hyp()`
## below replicates V8's algorithm exactly. Verified over 300k random pairs: zero
## mismatches. (Same family of trap as the sibling's toFixed-vs-%.3f note in
## play/overtime-idle-godot/tests/run_tests.gd.)

const SAVE_VERSION := 2
const GRAVITY := 1.35
const DAMP := 0.996
const MAX_SPEED := 2.6
const BALL_R := 0.017
const FLIP_LEN := 0.155
const FLIP_R := 0.016
const BALLS := 3
const COMBO_WINDOW_S := 2.2
const COMBO_CAP := 8
const COMBO_STEP := 0.12
const PRESTIGE_MIN_ERA := 1
const PRESTIGE_COIN_DIV := 4000
const SUBSTEPS := 4

const TABLE := {
	"left": 0.075, "right": 0.855, "top": 0.055, "bottom": 0.965,
	"laneL": 0.875, "laneR": 0.955, "drainL": 0.40, "drainR": 0.60,
}

## Dictionaries, not Vector2. Godot's Vector2 holds 32-bit floats: storing 0.255 in one
## silently rounds it to 0.25499999523162842, and a pivot a quarter of a micron off is a
## flipper that returns the ball at a slightly different angle — which the conformance
## test caught as a 1e-7 drift in four runs out of seventy-two. Anything the kernel does
## arithmetic on stays a 64-bit float.
const LEFT_PIVOT := {"x": 0.255, "y": 0.865}
const RIGHT_PIVOT := {"x": 0.675, "y": 0.865}
const LEFT_REST := 0.42
const LEFT_UP := -0.70
const RIGHT_REST := PI - 0.42
const RIGHT_UP := PI + 0.70

const BUMPERS := [
	{"id": "courier", "x": 0.34, "y": 0.30, "r": 0.048, "score": 90},
	{"id": "party", "x": 0.58, "y": 0.30, "r": 0.048, "score": 90},
	{"id": "raccoon", "x": 0.46, "y": 0.44, "r": 0.052, "score": 120},
]

const TARGETS := [
	{"id": "booth", "x": 0.28, "y": 0.155, "w": 0.07, "h": 0.028, "score": 180},
	{"id": "lobby", "x": 0.46, "y": 0.125, "w": 0.07, "h": 0.028, "score": 180},
	{"id": "tower", "x": 0.64, "y": 0.155, "w": 0.07, "h": 0.028, "score": 180},
]

const SAUCER := {"x": 0.46, "y": 0.58, "r": 0.028, "score": 500}

const WALLS := [
	[0.075, 0.16, 0.075, 0.78],
	[0.075, 0.16, 0.38, 0.055],
	[0.38, 0.055, 0.70, 0.055],
	[0.70, 0.055, 0.82, 0.12],
	[0.855, 0.28, 0.855, 0.70],
	[0.075, 0.78, 0.230, 0.875],
	[0.700, 0.875, 0.855, 0.70],
	[0.875, 0.30, 0.875, 0.90],
	[0.955, 0.05, 0.955, 0.90],
	[0.855, 0.90, 0.955, 0.90],
	[0.82, 0.12, 0.70, 0.055],
	[0.18, 0.62, 0.075, 0.52],
	[0.75, 0.62, 0.855, 0.52],
]

const SLINGS := [
	{"ax": 0.16, "ay": 0.70, "bx": 0.27, "by": 0.80, "kick": 1.15},
	{"ax": 0.77, "ay": 0.70, "bx": 0.66, "by": 0.80, "kick": 1.15},
]

const ERAS := [
	{"id": "booth", "minScore": 0, "mult": 1.0},
	{"id": "lobby", "minScore": 4, "mult": 1.15},
	{"id": "towers", "minScore": 14, "mult": 1.35},
	{"id": "neon", "minScore": 32, "mult": 1.6},
]

const UPGRADES := [
	{"id": "springs", "group": "table", "baseCost": 40, "growth": 1.22, "skyline": 0},
	{"id": "flippers", "group": "table", "baseCost": 55, "growth": 1.24, "skyline": 0},
	{"id": "bumpers", "group": "table", "baseCost": 70, "growth": 1.23, "skyline": 0},
	{"id": "slings", "group": "table", "baseCost": 45, "growth": 1.22, "skyline": 0},
	{"id": "doorman", "group": "staff", "baseCost": 80, "growth": 1.2, "skyline": 0},
	{"id": "concierge", "group": "staff", "baseCost": 110, "growth": 1.22, "skyline": 0},
	{"id": "manager", "group": "staff", "baseCost": 160, "growth": 1.25, "skyline": 1},
	{"id": "studio", "group": "property", "baseCost": 90, "growth": 1.18, "skyline": 2},
	{"id": "loft", "group": "property", "baseCost": 180, "growth": 1.2, "skyline": 4},
	{"id": "penthouse", "group": "property", "baseCost": 320, "growth": 1.22, "skyline": 8},
	{"id": "cannon", "group": "table", "baseCost": 140, "growth": 1.26, "skyline": 1},
	{"id": "neon", "group": "amenity", "baseCost": 240, "growth": 1.24, "skyline": 3},
]

const PERKS := [
	{"id": "uniform", "tokenBase": 1, "tokenGrowth": 1.6, "income": 0.08},
	{"id": "legend", "tokenBase": 1, "tokenGrowth": 1.7, "cannon": 0.12},
	{"id": "switchboard", "tokenBase": 1, "tokenGrowth": 1.65, "spawn": 0.08},
	{"id": "empire", "tokenBase": 1, "tokenGrowth": 1.75, "idle": 0.12},
]


# ---- V8's Math.hypot, exactly -----------------------------------------------------------
static func hyp(x: float, y: float) -> float:
	var a := absf(x)
	var b := absf(y)
	var mx := maxf(a, b)
	if mx == 0.0:
		return 0.0
	var sum := 0.0
	var comp := 0.0
	for v in [a, b]:
		var n: float = v / mx
		var summand: float = n * n - comp
		var prelim: float = sum + summand
		comp = (prelim - sum) - summand
		sum = prelim
	return mx * sqrt(sum)


static func upgrade_by_id(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func perk_by_id(id: String) -> Dictionary:
	for p in PERKS:
		if p["id"] == id:
			return p
	return {}


static func empty_owned() -> Dictionary:
	var o := {}
	for u in UPGRADES:
		o[u["id"]] = 0
	return o


static func empty_perks() -> Dictionary:
	var o := {}
	for p in PERKS:
		o[p["id"]] = 0
	return o


static func clone(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


static func fresh_ball() -> Dictionary:
	return {"x": 0.915, "y": 0.82, "vx": 0.0, "vy": 0.0}


static func new_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0, "score": 0,
		"owned": empty_owned(), "perks": empty_perks(),
		"tokens": 0, "combo": 0, "comboLeft": 0.0,
		"balls": BALLS, "night": 1, "prestiges": 0,
		"lifetime": 0, "runCoins": 0, "rebounds": 0, "buys": 0,
		"mode": "plunge", "plunge": 0.0,
		"flipL": LEFT_REST, "flipR": RIGHT_REST, "flipLv": 0.0, "flipRv": 0.0,
		"ball": fresh_ball(),
		"bumperFlash": [0.0, 0.0, 0.0],
		"targetDown": [false, false, false],
		"saucerHold": 0.0, "ballSave": 0.0,
		"inPlay": false, "savedAt": 0,
	}


## JS `Number(x) || 0` — NaN, null and 0 all become 0.
static func _num(v, dflt: float = 0.0) -> float:
	if v == null:
		return dflt
	match typeof(v):
		TYPE_INT, TYPE_FLOAT:
			var f := float(v)
			return dflt if (is_nan(f) or f == 0.0) else f
		TYPE_STRING:
			var s := str(v)
			return float(s) if s.is_valid_float() and float(s) != 0.0 else dflt
	return dflt


static func hydrate(raw) -> Dictionary:
	var state := new_state()
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", 0)) != SAVE_VERSION:
		return state
	state["coins"] = int(maxf(0.0, _num(raw.get("coins"))))
	state["score"] = int(maxf(0.0, _num(raw.get("score"))))
	state["tokens"] = int(maxf(0.0, _num(raw.get("tokens"))))
	state["combo"] = int(maxf(0.0, _num(raw.get("combo"))))
	state["comboLeft"] = maxf(0.0, _num(raw.get("comboLeft")))
	state["balls"] = int(maxf(0.0, _num(raw.get("balls"))))
	state["night"] = int(maxf(1.0, _num(raw.get("night"), 1.0)))
	state["prestiges"] = int(maxf(0.0, _num(raw.get("prestiges"))))
	state["lifetime"] = int(maxf(0.0, _num(raw.get("lifetime"))))
	state["runCoins"] = int(maxf(0.0, _num(raw.get("runCoins"))))
	state["rebounds"] = int(maxf(0.0, _num(raw.get("rebounds"))))
	state["buys"] = int(maxf(0.0, _num(raw.get("buys"))))
	var mode := str(raw.get("mode", ""))
	state["mode"] = mode if (mode == "live" or mode == "nightover") else "plunge"
	state["plunge"] = minf(1.0, maxf(0.0, _num(raw.get("plunge"))))
	state["inPlay"] = bool(raw.get("inPlay", false))
	var owned = raw.get("owned", {})
	for u in UPGRADES:
		var lv := 0
		if typeof(owned) == TYPE_DICTIONARY:
			lv = int(owned.get(u["id"], 0))
		state["owned"][u["id"]] = maxi(0, lv)
	var perks = raw.get("perks", {})
	for p in PERKS:
		var lv := 0
		if typeof(perks) == TYPE_DICTIONARY:
			lv = int(perks.get(p["id"], 0))
		state["perks"][p["id"]] = maxi(0, lv)
	var b = raw.get("ball")
	if typeof(b) == TYPE_DICTIONARY:
		state["ball"] = {
			"x": _num(b.get("x"), 0.915), "y": _num(b.get("y"), 0.82),
			"vx": _num(b.get("vx")), "vy": _num(b.get("vy")),
		}
	if state["mode"] == "live" and state["ball"] != null and not state["inPlay"] and float(state["ball"]["x"]) > 0.86:
		state["mode"] = "plunge"
		state["plunge"] = 0.0
		state["ball"] = fresh_ball()
	if state["mode"] == "nightover":
		state["ball"] = null
	return state


static func snapshot(state: Dictionary, now_ms: int) -> Dictionary:
	var out := clone(state)
	out["version"] = SAVE_VERSION
	out["savedAt"] = now_ms
	return out


static func level_of(state: Dictionary, id: String) -> int:
	if state == null or not state.has("owned"):
		return 0
	return int(state["owned"].get(id, 0))


static func perk_of(state: Dictionary, id: String) -> int:
	if state == null or not state.has("perks"):
		return 0
	return int(state["perks"].get(id, 0))


static func scale_cost(base: float, growth: float, level: int) -> int:
	return int(floorf(base * pow(growth, float(maxi(0, level)))))


static func upgrade_cost(id: String, level: int) -> int:
	var u := upgrade_by_id(id)
	return scale_cost(float(u["baseCost"]), float(u["growth"]), level) if u else 1 << 62


static func perk_cost(id: String, level: int) -> int:
	var p := perk_by_id(id)
	if p.is_empty():
		return 1 << 62
	return maxi(1, int(floorf(float(p["tokenBase"]) * pow(float(p["tokenGrowth"]), float(maxi(0, level))))))


static func skyline_score(state: Dictionary) -> int:
	var s := 0
	for u in UPGRADES:
		s += level_of(state, u["id"]) * int(u.get("skyline", 0))
	return s


static func era_index(state: Dictionary) -> int:
	var score := skyline_score(state)
	var idx := 0
	for i in range(ERAS.size()):
		if score >= int(ERAS[i]["minScore"]):
			idx = i
	return idx


static func era_id(state: Dictionary) -> String:
	return str(ERAS[era_index(state)]["id"])


static func era_mult(state: Dictionary) -> float:
	return float(ERAS[era_index(state)]["mult"])


static func prestige_mult(state: Dictionary) -> float:
	return 1.0 + perk_of(state, "uniform") * 0.08 + perk_of(state, "empire") * 0.12


static func score_mult(state: Dictionary) -> float:
	var studio := 1.0 + level_of(state, "studio") * 0.08
	var loft := 1.0 + level_of(state, "loft") * 0.1
	var pent := 1.0 + level_of(state, "penthouse") * 0.12
	var neon := 1.0 + level_of(state, "neon") * 0.1
	var concierge := 1.0 + level_of(state, "concierge") * 0.06
	return studio * loft * pent * neon * concierge * era_mult(state) * prestige_mult(state)


static func combo_mult(combo: int) -> float:
	return 1.0 + mini(COMBO_CAP, maxi(0, combo)) * COMBO_STEP


static func flip_power(state: Dictionary) -> float:
	return 10.0 + level_of(state, "flippers") * 2.2


static func bumper_kick(state: Dictionary) -> float:
	return 0.55 + level_of(state, "bumpers") * 0.12


static func sling_kick(state: Dictionary) -> float:
	return 0.85 + level_of(state, "slings") * 0.15


static func plunge_power(state: Dictionary) -> float:
	return 1.7 + level_of(state, "springs") * 0.22


static func cannon_kick(state: Dictionary) -> float:
	return 1.5 + level_of(state, "cannon") * 0.25 + perk_of(state, "legend") * 0.2


static func start_balls(state: Dictionary) -> int:
	return BALLS + (1 if level_of(state, "manager") > 0 else 0)


static func save_time(state: Dictionary) -> float:
	return level_of(state, "doorman") * 1.4


static func award(state: Dictionary, base: float) -> int:
	var pts := int(floorf(base * score_mult(state) * combo_mult(int(state["combo"]))))
	state["score"] = int(state["score"]) + pts
	var coins := maxi(1, int(floorf(float(pts) / 12.0)))
	state["coins"] = int(state["coins"]) + coins
	state["lifetime"] = int(state["lifetime"]) + coins
	state["runCoins"] = int(state["runCoins"]) + coins
	state["combo"] = mini(COMBO_CAP, int(state["combo"]) + 1)
	state["comboLeft"] = float(COMBO_WINDOW_S)
	state["rebounds"] = int(state["rebounds"]) + 1
	return pts


static func clamp_ball(ball: Dictionary) -> void:
	var sp := hyp(ball["vx"], ball["vy"])
	if sp > MAX_SPEED:
		# JS is `ball.vx *= MAX_SPEED / sp` — the division happens FIRST and the result is
		# multiplied in. Writing it as (vx * MAX_SPEED) / sp is algebraically the same and
		# a different double, and it is applied on every over-speed frame, so the error
		# accumulates instead of cancelling.
		var k := MAX_SPEED / sp
		ball["vx"] = float(ball["vx"]) * k
		ball["vy"] = float(ball["vy"]) * k


static func hit_wall(ball: Dictionary, ax: float, ay: float, bx: float, by: float, bounce: float) -> bool:
	var abx := bx - ax
	var aby := by - ay
	var apx: float = float(ball["x"]) - ax
	var apy: float = float(ball["y"]) - ay
	var ab2 := abx * abx + aby * aby
	if ab2 == 0.0:
		ab2 = 1.0
	var t := (apx * abx + apy * aby) / ab2
	t = maxf(0.0, minf(1.0, t))
	var cx := ax + abx * t
	var cy := ay + aby * t
	var dx: float = float(ball["x"]) - cx
	var dy: float = float(ball["y"]) - cy
	var dist := hyp(dx, dy)
	if dist >= BALL_R or dist < 1e-8:
		return false
	var nx := dx / dist
	var ny := dy / dist
	ball["x"] = cx + nx * BALL_R
	ball["y"] = cy + ny * BALL_R
	var vn: float = float(ball["vx"]) * nx + float(ball["vy"]) * ny
	if vn < 0.0:
		ball["vx"] = float(ball["vx"]) - (1.0 + bounce) * vn * nx
		ball["vy"] = float(ball["vy"]) - (1.0 + bounce) * vn * ny
	return true


static func hit_circle(ball: Dictionary, cx: float, cy: float, cr: float, kick: float) -> bool:
	var dx: float = float(ball["x"]) - cx
	var dy: float = float(ball["y"]) - cy
	var dist := hyp(dx, dy)
	var mn := BALL_R + cr
	if dist >= mn:
		return false
	var nx: float = 0.0 if dist < 1e-8 else dx / dist
	var ny: float = -1.0 if dist < 1e-8 else dy / dist
	ball["x"] = cx + nx * mn
	ball["y"] = cy + ny * mn
	var vn: float = float(ball["vx"]) * nx + float(ball["vy"]) * ny
	if vn < 0.0:
		ball["vx"] = float(ball["vx"]) - 1.85 * vn * nx
		ball["vy"] = float(ball["vy"]) - 1.85 * vn * ny
	ball["vx"] = float(ball["vx"]) + nx * kick
	ball["vy"] = float(ball["vy"]) + ny * kick
	return true


## Fdlibm.sin/cos, not the engine's: V8 does not call the system libm, and the one-ulp
## disagreement between the two is enough to change where a ball leaves a flipper. See
## scripts/fdlibm.gd.
static func flipper_end(pivot: Dictionary, angle: float) -> Dictionary:
	return {"x": float(pivot["x"]) + Fdlibm.cos(angle) * FLIP_LEN,
		"y": float(pivot["y"]) + Fdlibm.sin(angle) * FLIP_LEN}


static func hit_flipper(ball: Dictionary, pivot: Dictionary, angle: float, omega: float, power: float) -> bool:
	var px: float = pivot["x"]
	var py: float = pivot["y"]
	var tip := flipper_end(pivot, angle)
	if not hit_wall(ball, px, py, float(tip["x"]), float(tip["y"]), 0.25):
		return false
	var rx: float = float(ball["x"]) - px
	var ry: float = float(ball["y"]) - py
	var fx := -omega * ry
	var fy := omega * rx
	# `ball.vx += A + B` in JS sums A and B first and adds the sum to vx. Writing it as
	# ((vx + A) + B) is a different double — the flipper is where the two sides last
	# disagreed, three runs out of seventy-two, at frame 150.
	ball["vx"] = float(ball["vx"]) + (fx * 0.35 + Fdlibm.cos(angle - PI / 2.0) * maxf(0.0, omega) * power * 0.012)
	ball["vy"] = float(ball["vy"]) + (fy * 0.35 + Fdlibm.sin(angle - PI / 2.0) * maxf(0.0, -omega) * power * 0.012)
	if omega != 0.0:
		var nx := Fdlibm.cos(angle - PI / 2.0)
		var ny := Fdlibm.sin(angle - PI / 2.0)
		# JS: `pivot === LEFT_PIVOT || pivot.x < 0.5 ? -1 : 1`. Both pivots are passed as
		# the module's own objects, so the identity test and the x test agree; the x test
		# is the one that survives being a value type here.
		var sign_x: float = -1.0 if px < 0.5 else 1.0
		ball["vx"] = float(ball["vx"]) + nx * absf(omega) * 0.08 * sign_x
		ball["vy"] = float(ball["vy"]) + ny * absf(omega) * 0.08
	return true


static func hit_target(ball: Dictionary, t: Dictionary) -> bool:
	var x: float = maxf(float(t["x"]), minf(float(t["x"]) + float(t["w"]), float(ball["x"])))
	var y: float = maxf(float(t["y"]), minf(float(t["y"]) + float(t["h"]), float(ball["y"])))
	return hyp(float(ball["x"]) - x, float(ball["y"]) - y) < BALL_R


## charge_override < 0 means "not supplied" (the JS passes undefined).
static func launch_ball(state: Dictionary, charge_override: float = -1.0) -> float:
	if state["mode"] != "plunge" or state["ball"] == null:
		return 0.0
	var charge: float = maxf(0.55, charge_override if charge_override >= 0.0 else float(state["plunge"]))
	var min_vy := 1.48
	state["ball"]["x"] = 0.915
	state["ball"]["y"] = 0.78
	state["ball"]["vx"] = 0.04
	state["ball"]["vy"] = -maxf(min_vy, plunge_power(state) * charge)
	state["mode"] = "live"
	state["plunge"] = 0.0
	state["inPlay"] = false
	state["ballSave"] = save_time(state)
	return charge


static func drain_ball(state: Dictionary) -> String:
	if float(state["ballSave"]) > 0.0 and state["ball"] != null:
		state["ball"]["x"] = 0.46
		state["ball"]["y"] = 0.72
		state["ball"]["vx"] = 0.0
		state["ball"]["vy"] = -0.9
		state["ballSave"] = 0.0
		return "save"
	state["balls"] = int(state["balls"]) - 1
	state["combo"] = 0
	state["comboLeft"] = 0.0
	state["targetDown"] = [false, false, false]
	if int(state["balls"]) <= 0:
		state["mode"] = "nightover"
		state["ball"] = null
		return "nightover"
	state["mode"] = "plunge"
	state["ball"] = fresh_ball()
	state["plunge"] = 0.0
	state["inPlay"] = false
	return "drain"


static func new_night(state: Dictionary) -> Dictionary:
	var next := clone(state)
	next["mode"] = "plunge"
	next["balls"] = start_balls(next)
	next["score"] = 0
	next["combo"] = 0
	next["comboLeft"] = 0.0
	next["plunge"] = 0.0
	next["ball"] = fresh_ball()
	next["inPlay"] = false
	next["targetDown"] = [false, false, false]
	next["saucerHold"] = 0.0
	next["night"] = int(next["night"]) + 1
	return next


## step(state, input, dt, rng) -> {state, events}
## `input` is {left, right, plunge, fire}. `rng` is a Callable() -> float in [0,1) standing
## in for Math.random(); the only draw is the saucer's exit angle.
static func step(state: Dictionary, input: Dictionary, dt: float, rng: Callable = Callable()) -> Dictionary:
	var next := clone(state)
	var events: Array = []
	var seconds := maxf(0.0, minf(0.05, dt if not is_nan(dt) else 0.0))
	if float(next["comboLeft"]) > 0.0:
		next["comboLeft"] = maxf(0.0, float(next["comboLeft"]) - seconds)
		if float(next["comboLeft"]) == 0.0:
			next["combo"] = 0
	var flash: Array = []
	for v in next["bumperFlash"]:
		flash.append(maxf(0.0, float(v) - seconds * 4.0))
	next["bumperFlash"] = flash
	if float(next["ballSave"]) > 0.0:
		next["ballSave"] = maxf(0.0, float(next["ballSave"]) - seconds)

	var speed := flip_power(next)
	var target_l: float = LEFT_UP if bool(input.get("left", false)) else LEFT_REST
	var target_r: float = RIGHT_UP if bool(input.get("right", false)) else RIGHT_REST
	var prev_l := float(next["flipL"])
	var prev_r := float(next["flipR"])
	next["flipL"] = prev_l + (target_l - prev_l) * minf(1.0, seconds * speed)
	next["flipR"] = prev_r + (target_r - prev_r) * minf(1.0, seconds * speed)
	next["flipLv"] = (float(next["flipL"]) - prev_l) / seconds if seconds != 0.0 else 0.0
	next["flipRv"] = (float(next["flipR"]) - prev_r) / seconds if seconds != 0.0 else 0.0

	if next["mode"] == "plunge":
		if next["ball"] == null:
			next["ball"] = fresh_ball()
		next["ball"]["x"] = 0.915
		next["ball"]["y"] = 0.82 - float(next["plunge"]) * 0.08
		next["ball"]["vx"] = 0.0
		next["ball"]["vy"] = 0.0
		if bool(input.get("fire", false)):
			var charge := launch_ball(next, maxf(float(next["plunge"]), 0.78))
			events.append({"type": "launch", "charge": charge})
			return {"state": next, "events": events}
		if bool(input.get("plunge", false)):
			next["plunge"] = minf(1.0, float(next["plunge"]) + seconds * 2.4)
			if float(next["plunge"]) >= 1.0:
				events.append({"type": "launch", "charge": launch_ball(next, 1.0)})
		elif float(next["plunge"]) > 0.08:
			events.append({"type": "launch", "charge": launch_ball(next)})
		else:
			next["plunge"] = 0.0
		return {"state": next, "events": events}

	if next["mode"] != "live" or next["ball"] == null:
		return {"state": next, "events": events}

	if float(next["saucerHold"]) > 0.0:
		next["saucerHold"] = maxf(0.0, float(next["saucerHold"]) - seconds)
		next["ball"]["x"] = float(SAUCER["x"])
		next["ball"]["y"] = float(SAUCER["y"])
		next["ball"]["vx"] = 0.0
		next["ball"]["vy"] = 0.0
		if float(next["saucerHold"]) == 0.0:
			next["ball"]["vy"] = -cannon_kick(next)
			var r: float = (rng.call() if rng.is_valid() else randf())
			next["ball"]["vx"] = (r - 0.5) * 0.3
			events.append({"type": "cannon"})
		return {"state": next, "events": events}

	var h := seconds / float(SUBSTEPS)
	var ball: Dictionary = next["ball"]
	for _i in range(SUBSTEPS):
		ball["vy"] = float(ball["vy"]) + GRAVITY * h
		var d := pow(DAMP, h * 60.0)
		ball["vx"] = float(ball["vx"]) * d
		ball["vy"] = float(ball["vy"]) * d
		ball["x"] = float(ball["x"]) + float(ball["vx"]) * h
		ball["y"] = float(ball["y"]) + float(ball["vy"]) * h
		if not bool(next["inPlay"]) and float(ball["x"]) > 0.86 and float(ball["y"]) < 0.40:
			ball["vx"] = -1.7
			ball["vy"] = minf(float(ball["vy"]), -0.2)
		if not bool(next["inPlay"]) and float(ball["x"]) < 0.84 and float(ball["y"]) < 0.50:
			next["inPlay"] = true
			ball["vx"] = minf(float(ball["vx"]), -0.85)
			if float(ball["vy"]) > 0.7:
				ball["vy"] = 0.55
		if not bool(next["inPlay"]) and float(ball["x"]) > 0.86 and float(ball["y"]) > 0.86 and float(ball["vy"]) >= 0.0:
			next["mode"] = "plunge"
			next["plunge"] = 0.0
			next["ball"] = fresh_ball()
			events.append({"type": "reload"})
			break
		if bool(next["inPlay"]):
			hit_wall(ball, 0.86, 0.05, 0.86, 0.32, 0.2)
		clamp_ball(ball)

		for w in WALLS:
			hit_wall(ball, w[0], w[1], w[2], w[3], 0.42)

		for idx in range(BUMPERS.size()):
			var b: Dictionary = BUMPERS[idx]
			if hit_circle(ball, float(b["x"]), float(b["y"]), float(b["r"]), bumper_kick(next)):
				next["bumperFlash"][idx] = 1.0
				var pts := award(next, float(b["score"]))
				events.append({"type": "bumper", "i": idx, "id": b["id"], "pts": pts})

		for s in SLINGS:
			if hit_wall(ball, float(s["ax"]), float(s["ay"]), float(s["bx"]), float(s["by"]), 0.1):
				var nx: float = float(s["bx"]) - float(s["ax"])
				var ny: float = float(s["by"]) - float(s["ay"])
				var ln := hyp(nx, ny)
				if ln == 0.0:
					ln = 1.0
				var px := -ny / ln
				var _py := nx / ln
				var kick := sling_kick(next)
				ball["vx"] = float(ball["vx"]) + px * kick * (1.0 if float(s["ax"]) < 0.5 else -1.0)
				ball["vy"] = float(ball["vy"]) - kick * 0.35
				var pts2 := award(next, 25.0)
				events.append({"type": "sling", "pts": pts2})

		for idx in range(TARGETS.size()):
			var t: Dictionary = TARGETS[idx]
			if not bool(next["targetDown"][idx]) and hit_target(ball, t):
				next["targetDown"][idx] = true
				ball["vy"] = absf(float(ball["vy"])) * 0.4 + 0.2
				var pts3 := award(next, float(t["score"]))
				events.append({"type": "target", "i": idx, "id": t["id"], "pts": pts3})
		var all_down := true
		for v in next["targetDown"]:
			if not bool(v):
				all_down = false
		if all_down:
			next["targetDown"] = [false, false, false]
			var pts4 := award(next, 800.0)
			events.append({"type": "gate", "pts": pts4})

		if hit_circle(ball, float(SAUCER["x"]), float(SAUCER["y"]), float(SAUCER["r"]), 0.0) \
				and hyp(float(ball["vx"]), float(ball["vy"])) < 1.4:
			next["saucerHold"] = 0.35
			var pts5 := award(next, float(SAUCER["score"]))
			events.append({"type": "saucer", "pts": pts5})

		hit_flipper(ball, LEFT_PIVOT, float(next["flipL"]), float(next["flipLv"]), flip_power(next))
		hit_flipper(ball, RIGHT_PIVOT, float(next["flipR"]), float(next["flipRv"]), flip_power(next))

		if float(ball["y"]) > float(TABLE["bottom"]) and float(ball["x"]) > float(TABLE["drainL"]) \
				and float(ball["x"]) < float(TABLE["drainR"]):
			events.append({"type": drain_ball(next)})
			break
		if float(ball["y"]) > 1.08 or float(ball["x"]) < -0.05 or float(ball["x"]) > 1.05:
			events.append({"type": drain_ball(next)})
			break

	return {"state": next, "events": events}


static func can_buy(state: Dictionary, id: String) -> bool:
	return not upgrade_by_id(id).is_empty() \
		and float(state["coins"]) + 1e-9 >= float(upgrade_cost(id, level_of(state, id)))


static func buy(state: Dictionary, id: String) -> Dictionary:
	if not can_buy(state, id):
		return {"ok": false, "state": clone(state), "spent": 0}
	var cost := upgrade_cost(id, level_of(state, id))
	var next := clone(state)
	next["coins"] = int(next["coins"]) - cost
	next["owned"][id] = level_of(state, id) + 1
	next["buys"] = int(next["buys"]) + 1
	return {"ok": true, "state": next, "spent": cost}


static func can_buy_perk(state: Dictionary, id: String) -> bool:
	return not perk_by_id(id).is_empty() and int(state["tokens"]) >= perk_cost(id, perk_of(state, id))


static func buy_perk(state: Dictionary, id: String) -> Dictionary:
	if not can_buy_perk(state, id):
		return {"ok": false, "state": clone(state), "spent": 0}
	var cost := perk_cost(id, perk_of(state, id))
	var next := clone(state)
	next["tokens"] = int(next["tokens"]) - cost
	next["perks"][id] = perk_of(state, id) + 1
	return {"ok": true, "state": next, "spent": cost}


static func prestige_tokens_for(state: Dictionary) -> int:
	if era_index(state) < PRESTIGE_MIN_ERA:
		return 0
	return int(floorf(sqrt(maxf(0.0, float(state["runCoins"])) / float(PRESTIGE_COIN_DIV))))


static func can_prestige(state: Dictionary) -> bool:
	return prestige_tokens_for(state) >= 1


static func do_prestige(state: Dictionary) -> Dictionary:
	var tokens := prestige_tokens_for(state)
	if tokens < 1:
		return {"ok": false, "state": clone(state), "tokens": 0}
	var next := new_state()
	next["perks"] = state["perks"].duplicate(true)
	next["tokens"] = int(state["tokens"]) + tokens
	next["prestiges"] = int(state["prestiges"]) + 1
	next["lifetime"] = int(state["lifetime"])
	next["night"] = int(state["night"]) + 1
	next["rebounds"] = int(state["rebounds"])
	next["buys"] = int(state["buys"])
	next["balls"] = start_balls(next)
	return {"ok": true, "state": next, "tokens": tokens}


## JS `(v/1e9).toFixed(2)` etc. toFixed rounds ties away from zero, where GDScript's
## "%.2f" rounds to even — the sibling hit exactly this (5.0625 -> 5.063 vs 5.062), so
## the rounding is done by hand rather than by a format string.
static func _to_fixed(x: float, digits: int) -> String:
	var p := pow(10.0, float(digits))
	var scaled := x * p
	var n := floorf(scaled)
	if scaled - n >= 0.5:
		n += 1.0
	var s := str(int(n))
	var neg := s.begins_with("-")
	if neg:
		s = s.substr(1)
	while s.length() <= digits:
		s = "0" + s
	var out := s.substr(0, s.length() - digits) + "." + s.substr(s.length() - digits)
	return ("-" if neg else "") + out


static func format_coins(n: float) -> String:
	var v := n if not is_nan(n) else 0.0
	if v >= 1e9:
		return _to_fixed(v / 1e9, 2) + "B"
	if v >= 1e6:
		return _to_fixed(v / 1e6, 2) + "M"
	if v >= 10000.0:
		return _to_fixed(v / 1000.0, 1) + "K"
	return str(int(floorf(v)))
