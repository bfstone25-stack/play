## BMMap — the building as a graph: floors, nodes, edges, what is cleared, what is open,
## where the character stands. Pure; the map screen (map_screen.gd) draws it and walks it.
## Design: ops/adult_forks/beat_monday_map.md §1. Node ids are stable so the night twin
## (TWO_WORLDS.md) can re-mean a node by id without touching this graph.
##
## Node types and what each one runs on:
##   start    the lobby, where the week begins
##   standup  the survivor-like day (BMCore, DAYS[0])          reflex
##   allhands the rant level (BMCore, DAYS[2])                 reflex
##   inbox    triage (BMTriage), rewards DAYS[1]               thinking
##   review   dialogue tactics (BMReview), rewards DAYS[3]     thinking
##   deploy   placement then the boss day (BMDeploy + DAYS[4]) both
##   event    one screen, one choice (BMEvents)                judgement
##   break    the break room: equip, recruit, spend, save      management
##
## Progression stays BMCore's: clearing a node commits the matching DAYS row through
## BMCore.commit_run (drops, party, XP, the week rollover on Friday), so the conformance
## test over the reflex core is untouched and Week 2 arrives the way it always did.
class_name BMMap

const FLOOR_Y := [566.0, 434.0, 302.0, 170.0]   # screen y of each floor's ground line
const LIFT_X := 372.0                            # the shaft on the right of the plate
const START := "lobby"

## x is a fraction across the floor; requires is any-of groups of all-of node ids.
const NODES := [
	{"id": "lobby",     "type": "start",    "floor": 0, "x": 0.50, "day": -1, "requires": []},
	{"id": "breakroom", "type": "break",    "floor": 0, "x": 0.14, "day": -1, "requires": [["lobby"]]},
	{"id": "standup",   "type": "standup",  "floor": 1, "x": 0.34, "day": 0,  "requires": [["lobby"]]},
	{"id": "corridor1", "type": "event",    "floor": 1, "x": 0.72, "day": -1, "requires": [["standup"]]},
	{"id": "inbox",     "type": "inbox",    "floor": 2, "x": 0.20, "day": 1,  "requires": [["standup"]]},
	{"id": "allhands",  "type": "allhands", "floor": 2, "x": 0.64, "day": 2,  "requires": [["standup"]]},
	{"id": "review",    "type": "review",   "floor": 3, "x": 0.22, "day": 3,  "requires": [["inbox"], ["allhands"]]},
	{"id": "corridor2", "type": "event",    "floor": 3, "x": 0.52, "day": -1, "requires": [["review"]]},
	{"id": "deploy",    "type": "deploy",   "floor": 3, "x": 0.80, "day": 4,  "requires": [["review"]]},
]

const EDGES := [
	["lobby", "breakroom"], ["lobby", "standup"], ["standup", "corridor1"],
	["standup", "inbox"], ["standup", "allhands"], ["inbox", "review"], ["allhands", "review"],
	["review", "corridor2"], ["review", "deploy"],
]

## Nodes that are never "cleared": you can always walk into them.
const ALWAYS_OPEN := ["start", "break"]


static func node(id: String) -> Dictionary:
	for n in NODES:
		if n["id"] == id:
			return n
	return {}


static func pos(id: String) -> Vector2:
	var n := node(id)
	if n.is_empty():
		return Vector2(BMCore.W / 2, FLOOR_Y[0])
	return Vector2(40.0 + float(n["x"]) * (BMCore.W - 80.0), FLOOR_Y[int(n["floor"])])


static func neighbors(id: String) -> Array:
	var out: Array = []
	for e in EDGES:
		if e[0] == id:
			out.append(e[1])
		elif e[1] == id:
			out.append(e[0])
	return out


## The map's own slice of the profile. Reset when the week changes: a new week is a new
## walk through the same building. `cleared` is the map's, not BMCore's `cleared` (which
## keeps day ids across weeks for the conformance test's committed-profile check).
static func ensure(profile: Dictionary) -> Dictionary:
	var week: int = int(profile.get("week", 0))
	var m = profile.get("map")
	if typeof(m) != TYPE_DICTIONARY or int(m.get("week", -1)) != week:
		m = {"week": week, "cleared": [], "at": START, "runs": {}, "events": {}}
		profile["map"] = m
	if not profile.has("credits"):
		profile["credits"] = 0
	return m


static func is_cleared(profile: Dictionary, id: String) -> bool:
	return ensure(profile)["cleared"].has(id)


static func unlocked(profile: Dictionary, id: String) -> bool:
	var n := node(id)
	if n.is_empty():
		return false
	var groups: Array = n["requires"]
	if groups.is_empty():
		return true
	for g in groups:
		var all := true
		for r in g:
			if not is_cleared(profile, r) and not ALWAYS_OPEN.has(node(r).get("type", "")):
				all = false
				break
		if all:
			return true
	return false


## "cleared" | "open" | "locked"
static func state(profile: Dictionary, id: String) -> String:
	if is_cleared(profile, id):
		return "cleared"
	return "open" if unlocked(profile, id) else "locked"


## Where the character can walk: unlocked nodes only, along the edges. BFS; [] when
## unreachable; [from] when already there.
static func path(profile: Dictionary, from: String, to: String) -> Array:
	if from == to:
		return [from]
	if not unlocked(profile, to) or not unlocked(profile, from):
		return []
	var prev := {from: ""}
	var queue: Array = [from]
	while queue.size():
		var cur: String = queue.pop_front()
		for nb in neighbors(cur):
			if prev.has(nb) or not unlocked(profile, nb):
				continue
			prev[nb] = cur
			if nb == to:
				var out: Array = [to]
				var c: String = to
				while prev[c] != "":
					c = prev[c]
					out.push_front(c)
				return out
			queue.append(nb)
	return []


## Mark a node cleared, count the run, pay the credits. Returns true the first time.
static func clear(profile: Dictionary, id: String) -> bool:
	var m := ensure(profile)
	m["runs"][id] = int(m["runs"].get(id, 0)) + 1
	profile["credits"] = int(profile["credits"]) + 3
	if m["cleared"].has(id) or ALWAYS_OPEN.has(node(id).get("type", "")):
		return false
	m["cleared"].append(id)
	return true


static func set_at(profile: Dictionary, id: String) -> void:
	ensure(profile)["at"] = id


static func at(profile: Dictionary) -> String:
	return str(ensure(profile).get("at", START))


## The room the night should go to next: the first unlocked room that has not been
## cleared and that actually runs something.
##
## ALWAYS_OPEN types are skipped deliberately. The lobby is "where the night starts" and
## its brief has one button on it, BACK — it is a place, not a stage. It is also the first
## entry in NODES and therefore the first Button in the map's tree, which is how the
## keyboard forward action used to land on it: pressing Enter on the map opened the lobby,
## pressing Enter again went back to the map, and a player on a keyboard could ride that
## loop forever without ever entering a room. The matrix showed exactly that — title, map,
## lobby, map, and then sixteen more frames of the same two screens.
##
## Returns "" when the night has nothing left, which is the caller's cue to leave the key
## alone rather than invent a destination.
static func next_room(profile: Dictionary) -> String:
	for n in NODES:
		var id: String = n["id"]
		if ALWAYS_OPEN.has(str(n["type"])):
			continue
		if unlocked(profile, id) and not is_cleared(profile, id):
			return id
	return ""


## Nodes the week needs before Friday: everything with a day, in day order, for the
## screens that list what is left.
static func day_nodes() -> Array:
	var out: Array = []
	for n in NODES:
		if int(n["day"]) >= 0:
			out.append(n)
	out.sort_custom(func(a, b): return int(a["day"]) < int(b["day"]))
	return out


## Commit a cleared THINKING node the way a cleared day is committed: a pseudo-run with
## the day's row, over="clear", the day's drop, this node's XP, through BMCore.gain_xp and
## BMCore.commit_run — so drops, party, levels and the Friday rollover are the ported ones.
## Returns the pseudo-run (its `pending` may hold a level-up to pick).
static func commit_thinking(profile: Dictionary, id: String, xp: int, won: bool) -> Dictionary:
	var n := node(id)
	var day_index: int = int(n["day"])
	var run := BMCore.create_run(profile, day_index, 1)
	run["over"] = "clear" if won else "lost"
	run["reward"] = run["day"]["drop"] if won else null
	BMCore.gain_xp(run, xp)
	# the map's clear goes BEFORE commit_run: Friday's commit rolls the week, and
	# ensure() would then hand a fresh map that this clear must not land on
	if won:
		clear(profile, id)
	BMCore.commit_run(profile, run)
	return run


## XP with no day attached (the corridor): a pseudo-run that only carries what
## BMCore.gain_xp / skill_choices / apply_skill read, written back to the profile.
static func grant_xp(profile: Dictionary, xp: int, seed: int = 1) -> Dictionary:
	var run := {"level": int(profile["level"]), "xp": int(profile["xp"]), "pending": null,
		"profile": profile, "rng": seed & BMCore.MASK, "hp": 0.0, "maxHp": 0.0,
		"stats": BMCore.compute_stats(profile), "over": "clear", "reward": null, "kills": 0}
	BMCore.gain_xp(run, xp)
	profile["level"] = run["level"]
	profile["xp"] = run["xp"]
	return run


## Everything a test wants to know is true of the graph, as one dictionary of booleans.
static func invariants() -> Dictionary:
	var ids := {}
	for n in NODES:
		ids[n["id"]] = true
	var edges_ok := true
	for e in EDGES:
		if not ids.has(e[0]) or not ids.has(e[1]) or e[0] == e[1]:
			edges_ok = false
	var requires_ok := true
	for n in NODES:
		for g in n["requires"]:
			for r in g:
				if not ids.has(r):
					requires_ok = false
	# every node reachable from the lobby once everything is cleared
	var full := BMCore.new_profile()
	ensure(full)
	for n in NODES:
		full["map"]["cleared"].append(n["id"])
	var all_reachable := true
	for n in NODES:
		if path(full, START, n["id"]).is_empty():
			all_reachable = false
	# the fresh week: only the lobby's neighbours are open
	var fresh := BMCore.new_profile()
	var fresh_ok := state(fresh, "standup") == "open" and state(fresh, "breakroom") == "open" \
		and state(fresh, "inbox") == "locked" and state(fresh, "deploy") == "locked"
	# a branch: two nodes whose only requirement is the standup
	var branch := 0
	for n in NODES:
		if n["requires"] == [["standup"]] and n["day"] >= 0:
			branch += 1
	# every day 0..4 owned by exactly one node
	var days := {}
	for n in NODES:
		if int(n["day"]) >= 0:
			days[int(n["day"])] = days.get(int(n["day"]), 0) + 1
	var days_ok := days.size() == BMData.DAYS.size()
	for d in days:
		if days[d] != 1:
			days_ok = false
	var types_ok := true
	for n in NODES:
		if not ["start", "standup", "allhands", "inbox", "review", "deploy", "event", "break"].has(n["type"]):
			types_ok = false
	return {"edges": edges_ok, "requires": requires_ok, "all_reachable": all_reachable,
		"fresh": fresh_ok, "branch": branch >= 2, "days": days_ok, "types": types_ok,
		"deploy_needs_review": node("deploy")["requires"] == [["review"]]}
