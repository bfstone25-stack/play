class_name NRPolicy
extends RefCounted
## A "normal player" for the balance sim, tests and screenshot runs. It knows only what a
## player could know: weaknesses it has seen (Read the room, or hitting one), the meters,
## its own inventory. It never reads the enemy's weak/resist table directly.


static func choose(b: Dictionary, mi: int) -> Array:
	var m: Dictionary = b["party"][mi]
	var e: Dictionary = b["enemy"]
	var kinds := RPG.kinds()
	var acts: Array = RPG.actions_for(m["id"])
	var usable := func(a: String) -> bool:
		return a in acts and NRRules.can_use(m, RPG.game["actions"][a], kinds) == ""
	# 1. suspicion is the loss condition: bring it down before it gets close
	if b["suspicion"] >= 68 and usable.call("stall"):
		return ["stall", ""]
	# 2. composure / nerve trouble -> a consumable
	if float(m["comp"]) / m["comp_max"] < 0.35:
		var it := _item_with(m, "heal_comp")
		if it != "":
			return ["item", it]
		if usable.call("deflect"):
			return ["deflect", ""]
	if m["nerve"] < 3:
		var it2 := _item_with(m, "heal_nerve")
		if it2 != "":
			return ["item", it2]
	# 3. a revealed weakness, strongest first
	var best := ""
	var best_v := -1.0
	for a in acts:
		if a in b["revealed"] and NRRules.affinity(e, a) == "weak" and usable.call(a):
			var v := _expected(m, a)
			if v > best_v:
				best_v = v
				best = a
	if best != "":
		return [best, ""]
	# 4. nothing known yet -> look before leaping, once per battle
	if usable.call("observe") and b["round"] <= 2 and b["revealed"].is_empty():
		return ["observe", ""]
	# 5. strongest action not known to be resisted; Threaten only as a finisher
	for a in acts:
		if a in ["deflect", "stall", "item", "observe"] or not usable.call(a):
			continue
		if a in b["revealed"] and NRRules.affinity(e, a) == "resist":
			continue
		var v := _expected(m, a)
		if RPG.game["actions"][a].get("harm", false) and v < b["e_comp"]:
			continue
		# spread nerve: an expensive action is worth it only if it is clearly stronger
		v -= float(RPG.game["actions"][a].get("cost", 0)) * 0.6
		if v > best_v:
			best_v = v
			best = a
	if best != "":
		return [best, ""]
	if usable.call("stall") and b["suspicion"] > 30:
		return ["stall", ""]
	return ["deflect", ""]


static func _expected(m: Dictionary, a: String) -> float:
	var ad: Dictionary = RPG.game["actions"][a]
	return (float(ad.get("power", 0)) + float(m["stats"].get(ad.get("stat", "wit"), 0)) * float(ad.get("scale", 1.0))) * (1.0 + float(m["mult"].get(a, 0.0)))


static func _item_with(_m: Dictionary, field: String) -> String:
	for id in RPG.s["items"].keys():
		var d := RPG.item_def(id)
		if d.get("kind", "") == "consumable" and int(d.get(field, 0)) > 0:
			return id
	return ""
