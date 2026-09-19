## BMDeploy — the deploy node's placement phase and what the placed things do during the
## boss day. Six tiles over the server room; colleagues become turrets that hit what comes
## near their tile, owned equipment becomes an aura on its tile. Applied by main.gd AFTER
## BMCore.step each frame, never inside the core, so the reflex conformance stays exact:
## the core's own orbit dps (stats.partyDps) is zeroed for a deploy run and the turrets
## replace it.
class_name BMDeploy

const TILES := [
	Vector2(90, 250), Vector2(210, 250), Vector2(330, 250),
	Vector2(90, 380), Vector2(210, 380), Vector2(330, 380),
]
const MAX_GEAR := 2
const TURRET_RANGE := 110.0
const TURRET_MUL := 1.5
const AURA := {
	"stapler":    {"kind": "damage", "r": 80.0, "v": 8.0},
	"badge":      {"kind": "damage", "r": 80.0, "v": 10.0},
	"headphones": {"kind": "slow",   "r": 90.0, "v": 0.45},
	"lanyard":    {"kind": "slow",   "r": 90.0, "v": 0.35},
	"chair":      {"kind": "heal",   "r": 60.0, "v": 3.0},
	"coldbrew":   {"kind": "heal",   "r": 60.0, "v": 4.0},
}


static func new_placement() -> Dictionary:
	return {"tiles": {}}   # tile index (as int) -> {"kind": "party"|"gear", "id": ...}


static func what_can_go(profile: Dictionary) -> Array:
	var out: Array = []
	for pid in profile.get("party", []):
		out.append({"kind": "party", "id": pid})
	for eid in profile.get("owned", []):
		if AURA.has(eid):
			out.append({"kind": "gear", "id": eid})
	return out


static func placed_ids(pl: Dictionary) -> Array:
	var out: Array = []
	for k in pl["tiles"]:
		out.append(pl["tiles"][k]["id"])
	return out


static func gear_count(pl: Dictionary) -> int:
	var n := 0
	for k in pl["tiles"]:
		if pl["tiles"][k]["kind"] == "gear":
			n += 1
	return n


## Put a thing on a tile. "" when done, else why not. Placing on an occupied tile swaps
## the occupant out; placing something already placed moves it.
static func place(pl: Dictionary, profile: Dictionary, tile: int, kind: String, id: String) -> String:
	if tile < 0 or tile >= TILES.size():
		return "no_such_tile"
	var ok := false
	for c in what_can_go(profile):
		if c["kind"] == kind and c["id"] == id:
			ok = true
	if not ok:
		return "not_yours"
	for k in pl["tiles"].keys():
		if pl["tiles"][k]["id"] == id:
			pl["tiles"].erase(k)
	pl["tiles"].erase(tile)
	if kind == "gear" and gear_count(pl) >= MAX_GEAR:
		return "too_much_gear"
	pl["tiles"][tile] = {"kind": kind, "id": id}
	return ""


static func remove(pl: Dictionary, tile: int) -> void:
	pl["tiles"].erase(tile)


## Every frame of the deploy day, after the core stepped: turrets and auras.
static func apply(run: Dictionary, pl: Dictionary, dt: float) -> void:
	if run["over"] != null or run["pending"] != null:
		return
	var px: float = run["px"]
	var py: float = run["py"]
	for k in pl["tiles"]:
		var it: Dictionary = pl["tiles"][k]
		var tp: Vector2 = TILES[int(k)]
		if it["kind"] == "party":
			var row := BMData.find(BMData.PARTY, it["id"])
			var dps: float = float(row.get("dps", 0)) * TURRET_MUL
			_damage_near(run, tp, TURRET_RANGE, dps * dt)
			continue
		var a: Dictionary = AURA.get(it["id"], {})
		if a.is_empty():
			continue
		match a["kind"]:
			"damage":
				_damage_near(run, tp, a["r"], a["v"] * dt)
			"slow":
				# push foes in the aura back along their heading: the same as slowing them
				for f in run["foes"]:
					if BMCore.hypot(f["x"] - tp.x, f["y"] - tp.y) < a["r"]:
						var dx: float = px - f["x"]
						var dy: float = py - f["y"]
						var d := BMCore.hypot(dx, dy)
						if d > 0.0:
							f["x"] = f["x"] - dx / d * f["spd"] * a["v"] * dt
							f["y"] = f["y"] - dy / d * f["spd"] * a["v"] * dt
			"heal":
				if BMCore.hypot(px - tp.x, py - tp.y) < a["r"]:
					run["hp"] = minf(run["maxHp"], run["hp"] + a["v"] * dt)


## The nearest foe in range takes the damage (one target, like the core's orbit dps);
## the boss counts as a target too.
static func _damage_near(run: Dictionary, tp: Vector2, r: float, dmg: float) -> void:
	var best_i := -1
	var best_d := r
	for i in run["foes"].size():
		var f: Dictionary = run["foes"][i]
		var d := BMCore.hypot(f["x"] - tp.x, f["y"] - tp.y)
		if d < best_d:
			best_d = d
			best_i = i
	if best_i >= 0:
		var f: Dictionary = run["foes"][best_i]
		f["hp"] = f["hp"] - dmg
		f["hit"] = 1.0
		if f["hp"] <= 0:
			BMCore.kill_foe(run, best_i)
		return
	if run["boss"] != null and BMCore.hypot(run["boss"]["x"] - tp.x, run["boss"]["y"] - tp.y) < r:
		run["boss"]["hp"] = run["boss"]["hp"] - dmg
		run["boss"]["hit"] = 1.0
