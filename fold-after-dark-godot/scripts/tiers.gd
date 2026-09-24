## Tier — what the fork turns on. Autoloaded as "Tier".
##
## FOLD: every fold is for the satisfaction of the snap. After Dark: every tier you clear
## folds one more layer off her. The 201 levels are cut into tiers — a short first one so
## the first reward is minutes away, then eight apiece — and at the end of every tier sits
## a scene card. Clear the tier, take the trophy, the scene unlocks.
##
## The reward pool is the frozen VNs' art (ops/adult_forks/TWO_WORLDS.md: the parents'
## material is the raw material): Room 704's and Confession Room's CGs, delivered through
## the same server-ticket path those games use (scripts/unlock.gd). The teaser on the card
## is the parent game's own *_x_locked plate, which ships in the pack; the real plate does
## not ship on the web at all.
##
## Also here, because Nutaku's top 100 has them in the frame even when nothing is
## networked: a daily mission, a streak, and a leaderboard. All three are LOCAL STUBS
## tonight and say so on screen.
extends Node

const FIRST_TIER := 5
const TIER_LEN := 8

## The scene pool, in the order the tiers hand them out. `app`/`key` are the gateway's
## names (ops/gated_assets/<app>/<key>.webp). `line` is the voice line that plays over
## the plate — a real line from the parent, so the scene has her voice, not a caption.
const SCENES := [
	{"id": "r704_bed", "app": "room704", "key": "bed", "title": "Room 704 · The bed",
		"from": "Room 704", "voice": "r704_mira", "line": "The car's gone.", "who": "Mira"},
	{"id": "cr_vee", "app": "confession-room", "key": "vee", "title": "Confession Room · Vee",
		"from": "Confession Room", "voice": "", "line": "", "who": "Vee"},
	{"id": "r704_window", "app": "room704", "key": "window", "title": "Room 704 · The window",
		"from": "Room 704", "voice": "r704_mira", "line": "Yes. He will.", "who": "Mira"},
	{"id": "cr_adaeze", "app": "confession-room", "key": "adaeze", "title": "Confession Room · Adaeze",
		"from": "Confession Room", "voice": "cr_adaeze",
		"line": "The only clean basin in this building is the mop room sink.", "who": "Adaeze"},
	{"id": "cr_nikolai", "app": "confession-room", "key": "nikolai", "title": "Confession Room · Nikolai",
		"from": "Confession Room", "voice": "", "line": "", "who": "Nikolai"},
	{"id": "cr_evidence", "app": "confession-room", "key": "evidence", "title": "Confession Room · Evidence I",
		"from": "Confession Room", "voice": "", "line": "", "who": ""},
	{"id": "cr_evidence2", "app": "confession-room", "key": "evidence2", "title": "Confession Room · Evidence II",
		"from": "Confession Room", "voice": "", "line": "", "who": ""},
	{"id": "cr_evidence3", "app": "confession-room", "key": "evidence3", "title": "Confession Room · Evidence III",
		"from": "Confession Room", "voice": "", "line": "", "who": ""},
]

var _tiers: Array = []      # [{first:int, last:int}] inclusive level indices
## On Nutaku the server owns the cut and the scene pool (ops/nutaku/fold_f2p/
## config.example.json: 5, then 14 apiece, 15 scenes). F2P._adopt() calls configure()
## with the server's tiers; off the platform this stays empty and SCENES is the pool.
var _server_scenes: Array = []


func _ready() -> void:
	_cut()


func _cut() -> void:
	_tiers.clear()
	var n := Fold.level_count()
	if n <= 0:
		return
	var i := 0
	var first := true
	while i < n:
		var len := FIRST_TIER if first else TIER_LEN
		first = false
		_tiers.append({"first": i, "last": mini(n - 1, i + len - 1)})
		i += len


func configure(tiers: Array) -> void:
	_tiers.clear()
	_server_scenes.clear()
	for t in tiers:
		_tiers.append({"first": int(t["first"]), "last": int(t["last"])})
		_server_scenes.append(t.get("scene"))


func count() -> int:
	if _tiers.is_empty():
		_cut()
	return _tiers.size()


func of_level(level: int) -> int:
	for t in range(count()):
		if level >= _tiers[t]["first"] and level <= _tiers[t]["last"]:
			return t
	return count() - 1


func first_level(t: int) -> int:
	return int(_tiers[clampi(t, 0, count() - 1)]["first"])


func last_level(t: int) -> int:
	return int(_tiers[clampi(t, 0, count() - 1)]["last"])


func length(t: int) -> int:
	return last_level(t) - first_level(t) + 1


func cleared_in(t: int) -> int:
	var n := 0
	for i in range(first_level(t), last_level(t) + 1):
		if Save.stars_at(i) > 0:
			n += 1
	return n


func is_cleared(t: int) -> bool:
	return cleared_in(t) >= length(t)


## A tier opens when the one before it is cleared. Tier 0 is always open.
func is_open(t: int) -> bool:
	return t == 0 or is_cleared(t - 1)


## The furthest open tier, and the first unsolved level in it.
func current() -> int:
	for t in range(count()):
		if not is_cleared(t):
			return t
	return count() - 1


func next_level_in(t: int) -> int:
	for i in range(first_level(t), last_level(t) + 1):
		if Save.stars_at(i) == 0:
			return i
	return first_level(t)


# ---- scenes -----------------------------------------------------------------------------

## The scene a tier pays out. Past the pool, a labelled placeholder: nothing fits yet.
func scene_for(t: int) -> Dictionary:
	if not _server_scenes.is_empty():
		var sc = _server_scenes[clampi(t, 0, _server_scenes.size() - 1)]
		if typeof(sc) == TYPE_DICTIONARY:
			return {"id": str(sc["id"]), "app": "", "key": "", "title": str(sc["title"]),
				"from": "", "voice": "", "line": "", "who": ""}
	if t < SCENES.size():
		return SCENES[t]
	return {"id": "pending_%02d" % (t + 1), "app": "", "key": "", "placeholder": true,
		"title": "Scene %d · not rendered yet" % (t + 1), "from": "placeholder",
		"voice": "", "line": "", "who": ""}


func scene_by_id(id: String) -> Dictionary:
	for t in range(_server_scenes.size()):
		var sc = _server_scenes[t]
		if typeof(sc) == TYPE_DICTIONARY and str(sc["id"]) == id:
			return scene_for(t)
	for s in SCENES:
		if s["id"] == id:
			return s
	return {}


func scene_app(id: String) -> String:
	return str(scene_by_id(id).get("app", ""))


func scene_key(id: String) -> String:
	return str(scene_by_id(id).get("key", ""))


func teaser_path(id: String) -> String:
	return "res://assets/scenes/%s_locked.webp" % id


## Unlocked means the bytes actually landed for this install (Unlock.ready_for) AND the
## player earned it. Earned-but-not-delivered is a locked card with a "retry" — never a
## picture.
func is_unlocked(id: String) -> bool:
	if F2P.on():
		# the server decides; the bytes still have to have landed for this install
		return F2P.server_unlocked(id) and Unlock.ready_for(id)
	return bool((Save.get_v("ad_scenes", {}) as Dictionary).get(id, false)) and Unlock.ready_for(id)


func mark_unlocked(id: String) -> void:
	var d: Dictionary = Save.get_v("ad_scenes", {})
	d[id] = true
	Save.set_v("ad_scenes", d)


# ---- streak / daily / leaderboard: local stubs ---------------------------------------------

var streak := 0            # consecutive clears this session, reset by a reset/undo-heavy fail


func streak_hit() -> void:
	streak += 1
	if streak > int(Save.get_v("ad_streak_best", 0)):
		Save.set_v("ad_streak_best", streak)
	_daily_tick()


func streak_break() -> void:
	streak = 0


func streak_best() -> int:
	return int(Save.get_v("ad_streak_best", 0))


const DAILY_GOAL := 3


func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func _daily_tick() -> void:
	var day := _today()
	var daily: Dictionary = Save.get_v("ad_daily", {})
	if str(daily.get("day", "")) != day:
		# a new day: the day-streak continues only if yesterday's mission was met
		var met := int(daily.get("n", 0)) >= DAILY_GOAL
		daily = {"day": day, "n": 0, "days": (int(daily.get("days", 0)) + 1) if met else 0}
	daily["n"] = int(daily.get("n", 0)) + 1
	Save.set_v("ad_daily", daily)


func daily_progress() -> int:
	var daily: Dictionary = Save.get_v("ad_daily", {})
	return int(daily.get("n", 0)) if str(daily.get("day", "")) == _today() else 0


func daily_days() -> int:
	return int((Save.get_v("ad_daily", {}) as Dictionary).get("days", 0))


## Score: stars are the currency. A local table with one row that is you; it says STUB.
func score() -> int:
	var s := 0
	for t in range(count()):
		for i in range(first_level(t), last_level(t) + 1):
			s += Save.stars_at(i) * 100
	return s + streak_best() * 50


func leaderboard() -> Array:
	# Seeded rows so the frame reads as a board; labelled as such on screen.
	var rows := [["you", score(), true], ["— stub —", 0, false], ["— stub —", 0, false]]
	rows.sort_custom(func(a, b): return a[1] > b[1])
	return rows
