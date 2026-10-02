class_name NRRules
extends RefCounted
## Standoff battle rules: pure functions over plain Dictionaries, no nodes, no I/O.
##
## Ported from SUASION's duel (play/silvertongue-cards, ops/adult_forks/silvertongue_cards.md)
## and re-skinned as an RPG battle. What carried over:
##   * a meter that only the enemy owns (SUASION's phase ladder -> Suspicion, 100 = loss);
##   * coercion is a trap: Threaten hits hard but marks the standoff, and the mark never
##     clears -- every enemy turn after it adds suspicion (SUASION's `harms`, which made
##     `eligible` impossible for the rest of the duel);
##   * each opponent is a rules row (weak / resist) the player learns, which is the strategy.
## The battle screen, the balance sim and the tests all call these same functions.

const SUSPICION_MAX := 100


static func xp_to_next(level: int) -> int:
	return 30 + 20 * (level - 1)


## A fresh battle state. `party` is the list of member dicts from RPG.battle_party().
static func new_battle(enemy_id: String, enemy: Dictionary, party: Array, seed_value: int) -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"enemy": enemy,
		"e_comp": int(enemy.get("composure", 40)),
		"e_comp_max": int(enemy.get("composure", 40)),
		"suspicion": int(enemy.get("suspicion_start", 0)),
		"party": party,            # [{id, stats, comp, comp_max, nerve, nerve_max, mult:{}, guard:false}]
		"threatened": false,
		"round": 1,
		"rng": seed_value,
		"log": [],
		"revealed": [],            # actions learned to be weak/resist this battle
		"result": "",              # "", "win", "lose"
	}


static func _rand(b: Dictionary) -> float:
	# Small LCG so a battle replays identically from its seed (sim + tests).
	b["rng"] = int((int(b["rng"]) * 1103515245 + 12345) % 2147483648)
	return float(b["rng"]) / 2147483648.0


static func affinity(enemy: Dictionary, action: String) -> String:
	if action in enemy.get("weak", []):
		return "weak"
	if action in enemy.get("resist", []):
		return "resist"
	return "normal"


## Can `member` use `action` now? Returns "" or a reason key.
## `kinds` counts the party's items by kind: {"evidence": 2, "cash": 1, ...}.
static func can_use(member: Dictionary, adef: Dictionary, kinds: Dictionary) -> String:
	if member["comp"] <= 0:
		return "r_rattled"
	if int(adef.get("cost", 0)) > member["nerve"]:
		return "r_nerve"
	var needs: String = adef.get("needs_kind", "")
	if needs != "" and int(kinds.get(needs, 0)) <= 0:
		return "r_needs_" + needs
	return ""


## Resolve one party action. `item` is the item def for "item" actions.
## Returns an event dict for the log/animation; mutates b.
static func party_act(b: Dictionary, mi: int, action: String, adef: Dictionary, item: Dictionary = {}) -> Dictionary:
	var m: Dictionary = b["party"][mi]
	var e: Dictionary = b["enemy"]
	var ev := {"who": m["id"], "action": action, "dmg": 0, "susp": 0, "heal": 0, "aff": "normal"}
	m["nerve"] = max(0, m["nerve"] - int(adef.get("cost", 0)))
	var kind: String = adef.get("kind", "attack")
	if kind == "guard":
		m["guard"] = true
		ev["susp"] = _add_susp(b, -int(adef.get("susp", 4)))
	elif kind == "stall":
		var down := int(adef.get("susp_down", 10)) + int(round(float(m["stats"].get("stl", 0)) * 1.5))
		down = int(round(down * (1.0 + float(m["mult"].get(action, 0.0)))))
		ev["susp"] = _add_susp(b, -down)
		var h: int = min(int(adef.get("heal", 3)), m["comp_max"] - m["comp"])
		m["comp"] += h
		ev["heal"] = h
	elif kind == "observe":
		ev["reveal"] = e.get("weak", []).duplicate()
		for a in e.get("weak", []):
			if not (a in b["revealed"]):
				b["revealed"].append(a)
		ev["susp"] = _add_susp(b, int(adef.get("susp", 2)))
	elif kind == "item":
		var target: Dictionary = m
		if item.get("heal_nerve", 0) == 0:
			# composure items go to whoever is lowest, the way a player would use them
			for p in b["party"]:
				if p["comp"] > 0 and float(p["comp"]) / p["comp_max"] < float(target["comp"]) / target["comp_max"]:
					target = p
		var hc: int = min(int(item.get("heal_comp", 0)), target["comp_max"] - target["comp"])
		var hn: int = min(int(item.get("heal_nerve", 0)), target["nerve_max"] - target["nerve"])
		target["comp"] += hc
		target["nerve"] += hn
		ev["heal"] = hc + hn
		ev["target"] = target["id"]
		ev["susp"] = _add_susp(b, -int(item.get("susp_down", 0)))
	else:
		var aff := affinity(e, action)
		ev["aff"] = aff
		var stat_v := float(m["stats"].get(adef.get("stat", "wit"), 0))
		var base := float(adef.get("power", 6)) + stat_v * float(adef.get("scale", 1.0))
		var mult := 1.0 + float(m["mult"].get(action, 0.0))
		if aff == "weak":
			mult *= 1.75
		elif aff == "resist":
			mult *= 0.5
		var dmg := int(round(base * mult * (0.9 + 0.2 * _rand(b))))
		dmg = max(1, dmg)
		b["e_comp"] = max(0, b["e_comp"] - dmg)
		ev["dmg"] = dmg
		var s := int(adef.get("susp", 0))
		if aff == "resist":
			s += 8
		elif aff == "weak":
			s -= 2
		if adef.get("harm", false):
			b["threatened"] = true
		ev["susp"] = _add_susp(b, s)
		if aff != "normal" and not (action in b["revealed"]):
			b["revealed"].append(action)
	_check_end(b)
	b["log"].append(ev)
	return ev


## Enemy turn: suspicion climbs, then one member takes a hit to composure.
static func enemy_act(b: Dictionary) -> Dictionary:
	var e: Dictionary = b["enemy"]
	var ev := {"who": "enemy", "action": "press", "dmg": 0, "susp": 0, "target": ""}
	if b["result"] != "":
		return ev
	var rate := int(e.get("susp_rate", 6))
	if b["threatened"]:
		rate += 5
	if e.get("boss", false) and int(b["round"]) % 3 == 0:
		rate *= 2
		ev["action"] = "pressure"
	var guards := 0
	for p in b["party"]:
		if p.get("guard", false):
			guards += 1
	rate = max(1, rate - 2 * guards)
	ev["susp"] = _add_susp(b, rate)
	var alive := []
	for p in b["party"]:
		if p["comp"] > 0:
			alive.append(p)
	if not alive.is_empty():
		var t: Dictionary = alive[int(_rand(b) * alive.size()) % alive.size()]
		var dmg := float(e.get("atk", 6)) * (0.85 + 0.3 * _rand(b)) - float(t["stats"].get("grt", 0)) * 0.6
		if t.get("guard", false):
			dmg *= 0.4
		var d := int(max(1, round(dmg)))
		t["comp"] = max(0, t["comp"] - d)
		ev["dmg"] = d
		ev["target"] = t["id"]
	for p in b["party"]:
		p["guard"] = false
		p["nerve"] = min(p["nerve_max"], p["nerve"] + 3)
	b["round"] += 1
	_check_end(b)
	b["log"].append(ev)
	return ev


static func _add_susp(b: Dictionary, d: int) -> int:
	var before: int = b["suspicion"]
	b["suspicion"] = clampi(before + d, 0, SUSPICION_MAX)
	return b["suspicion"] - before


static func _check_end(b: Dictionary) -> void:
	if b["result"] != "":
		return
	if b["e_comp"] <= 0:
		b["result"] = "win"
		return
	if b["suspicion"] >= SUSPICION_MAX:
		b["result"] = "lose"
		return
	var any_up := false
	for p in b["party"]:
		if p["comp"] > 0:
			any_up = true
	if not any_up:
		b["result"] = "lose"
