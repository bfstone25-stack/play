extends SceneTree
## Rules unit checks: pure NRRules, no content. Run:
##   godot --headless --path play/night-rpg-core -s tests/rules_test.gd
## (rules.gd needs no autoloads, so a --script run is fine here.)

var fails := 0

func check(c: bool, what: String) -> void:
	if c:
		print("ok   ", what)
	else:
		fails += 1
		print("FAIL ", what)

func _init() -> void:
	var enemy := {"composure": 30, "atk": 6, "susp_rate": 8, "weak": ["bribe"], "resist": ["bluff"]}
	var party := [{"id": "a", "stats": {"wit": 4, "cha": 2, "grt": 3, "stl": 2}, "comp": 40, "comp_max": 40, "nerve": 20, "nerve_max": 20, "mult": {}, "guard": false}]
	var bluff := {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 2}
	var bribe := {"cost": 2, "stat": "cha", "power": 8, "scale": 1.0, "susp": 0, "needs_kind": "cash"}
	var b := NRRules.new_battle("x", enemy, party.duplicate(true), 11)
	var ev := NRRules.party_act(b, 0, "bluff", bluff)
	check(ev["aff"] == "resist" and ev["susp"] == 10, "resisted bluff costs suspicion +10 (got %s)" % ev["susp"])
	var b2 := NRRules.new_battle("x", enemy, party.duplicate(true), 11)
	var ev2 := NRRules.party_act(b2, 0, "bribe", bribe)
	check(ev2["aff"] == "weak" and ev2["dmg"] > ev["dmg"] * 2, "weakness hits harder than a resisted action")
	check("bribe" in b2["revealed"], "hitting a weakness reveals it")
	var b3 := NRRules.new_battle("x", enemy, party.duplicate(true), 11)
	NRRules.party_act(b3, 0, "threaten", {"cost": 4, "stat": "grt", "power": 12, "scale": 2.0, "susp": 12, "harm": true})
	var s0: int = b3["suspicion"]
	NRRules.enemy_act(b3)
	check(b3["suspicion"] - s0 == 13, "threat mark adds 5 per enemy turn, for good (got %d)" % (b3["suspicion"] - s0))
	var b4 := NRRules.new_battle("x", {"composure": 999, "atk": 1, "susp_rate": 30}, party.duplicate(true), 3)
	for i in 4:
		NRRules.enemy_act(b4)
	check(b4["result"] == "lose", "suspicion 100 is a loss")
	var b5 := NRRules.new_battle("x", enemy, party.duplicate(true), 3)
	b5["e_comp"] = 1
	NRRules.party_act(b5, 0, "bribe", bribe)
	check(b5["result"] == "win", "resolve 0 is a win")
	check(NRRules.can_use(party[0], bribe, {}) == "r_needs_cash", "bribe needs cash")
	check(NRRules.xp_to_next(1) == 30 and NRRules.xp_to_next(5) == 110, "xp curve")
	print("rules: %d failure(s)" % fails)
	quit(1 if fails > 0 else 0)
