## BMEvents — the corridor: one screen, one choice, one consequence. Slay the Spire's "?"
## node, kept to what the profile can carry: XP, coffee credits, and a modifier on the
## next run's starting HP (`profile.map.hpNext`, read once by main.gd when a reflex run
## starts). Which event a corridor shows is seeded by week and node, so a re-run of the
## corridor shows the same encounter until the week turns.
class_name BMEvents

const EVENTS := [
	{"id": "lift", "a": {"xp": 8, "hpNext": -0.15}, "b": {"credits": 3}},
	{"id": "cake", "a": {"hpNext": 0.15}, "b": {"xp": 2, "credits": 1}},
	{"id": "printer", "a": {"xp": 5, "credits": -1}, "b": {"credits": 1}},
	{"id": "recruiter", "a": {"credits": 6, "hpNext": -0.1}, "b": {"xp": 4}},
	{"id": "plant", "a": {"credits": 2}, "b": {"xp": 3, "hpNext": 0.05}},
]


static func pick(profile: Dictionary, node_id: String) -> Dictionary:
	var m := BMMap.ensure(profile)
	var key := node_id
	if m["events"].has(key):
		return event(str(m["events"][key]))
	var seed: int = (int(profile.get("week", 0)) + 1) * 7919 + node_id.hash() % 1000
	var t := {"rng": seed & BMCore.MASK}
	var e: Dictionary = EVENTS[int(floor(BMCore.rng(t) * EVENTS.size())) % EVENTS.size()]
	m["events"][key] = e["id"]
	return e


static func event(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return EVENTS[0]


## Apply choice "a" or "b". Returns the effect applied, for the screen.
static func choose(profile: Dictionary, node_id: String, choice: String) -> Dictionary:
	var e := pick(profile, node_id)
	var fx: Dictionary = e[choice] if e.has(choice) else {}
	var m := BMMap.ensure(profile)
	if fx.has("credits"):
		profile["credits"] = maxi(0, int(profile.get("credits", 0)) + int(fx["credits"]))
	if fx.has("hpNext"):
		m["hpNext"] = clampf(float(m.get("hpNext", 0.0)) + float(fx["hpNext"]), -0.4, 0.4)
	var run := BMMap.grant_xp(profile, int(fx.get("xp", 0)), node_id.hash())
	BMMap.clear(profile, node_id)
	return {"event": e["id"], "choice": choice, "fx": fx, "run": run}


## The next reflex run's starting HP multiplier, consumed once.
static func take_hp_mod(profile: Dictionary) -> float:
	var m := BMMap.ensure(profile)
	var v: float = float(m.get("hpNext", 0.0))
	m["hpNext"] = 0.0
	return 1.0 + v
