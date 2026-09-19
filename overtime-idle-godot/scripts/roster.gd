class_name Roster
## Port of play/overtime-idle/frontend/js/roster.js — the staff roster is the gacha, and
## the gacha extends the catalogue. settle_idle() wraps Landlord.settle_grid() and adds one
## named event per gacha character on top of the same result shape.

const ROSTER: Array = [
	{"id": "dan", "rarity": "rare", "slots": 2, "age": 41, "launch": true,
		"name": "Dan, 41", "rule": "Coffee beside him triples. Headphones beside him +2.",
		"bio": "The last engineer who never goes home. He says the build is green and the trains have stopped, and both are true. The coffee chain runs through him because he is the only one still drinking it at two in the morning."},
	{"id": "priya", "rarity": "common", "slots": 3, "age": 29, "launch": true,
		"name": "Priya, 29", "rule": "Copies the best base beside her.",
		"bio": "Facilities contractor, three nights a week. Covers whoever she is standing next to — it is her mechanic and her joke. She has keys she is not supposed to have and a very good reason for each."},
	{"id": "mara", "rarity": "common", "slots": 1, "age": 34, "launch": true,
		"name": "Mara, 34", "rule": "Every neighbour +1.",
		"bio": "Night-shift building manager. Keys to every floor, opinions about every tenant. Lifts everyone around her by one because she has already done their job once, quietly, before they got in."},
	{"id": "wes", "rarity": "rare", "slots": 1, "age": 36, "launch": true,
		"name": "Wes, 36", "rule": "Taxes unshielded Dan and Priya beside him. Tag: noise.",
		"bio": "The tenant on 7 who sublets space he does not have. His meetings are a tax on anyone who cannot put headphones on. He is charming for exactly as long as it takes."},
	{"id": "nia", "rarity": "rare", "slots": 1, "age": 33, "payout": 2, "tag": "staff", "event": "nia-audit",
		"name": "Nia, 33", "rule": "Audits Wes: each Wes beside her pays her his 2.",
		"bio": "Forensic accountant, brought in by Mirei to find out what the tenant on 7 is actually paying for. Sits down next to him on purpose. Wes has never once finished a sentence in her presence."},
	{"id": "sol", "rarity": "epic", "slots": 1, "age": 38, "payout": 3, "tag": "staff", "event": "sol-late", "floorEvent": "sol-floor",
		"name": "Sol, 38", "rule": "Coffee beside her +2 to her. Floor: every other staff +1.",
		"bio": "Night editor for a paper that stopped printing. Still files at four. The whole floor works later when she is on it, and nobody can say why, and nobody has asked her to leave."},
]

const OBJECTS: Array = ["coffee", "mute", "printer", "corner"]
const RARITY := {"common": 70, "rare": 25, "epic": 5}
const PITY := 30

const CHAIN_K := 0.35
const DUPE_STEP := 0.05
const DUPE_CAP := 10

static var _catalog: Array = []
static var _staff: Array = []


static func catalog() -> Array:
	if _catalog.is_empty():
		_catalog = Landlord.CATALOG.duplicate()
		for p in ROSTER:
			if not p.get("launch", false):
				_catalog.append({"id": p["id"], "payout": p["payout"], "tag": p["tag"]})
	return _catalog


static func staff_ids() -> Array:
	if _staff.is_empty():
		for p in ROSTER:
			_staff.append(p["id"])
	return _staff


static func by(id: String) -> Dictionary:
	for p in ROSTER:
		if p["id"] == id:
			return p
	return {}


static func pool(rarity: String) -> Array:
	var out: Array = []
	for p in ROSTER:
		if p["rarity"] == rarity:
			out.append(p["id"])
	return out


static func is_staff(id: String) -> bool:
	return staff_ids().has(id)


static func chain_of(r: Dictionary) -> int:
	var n := 0
	for e in r["events"]:
		if e != "wes-tax":
			n += 1
	return n


static func chain_mult(chain: int) -> float:
	return 1.0 + CHAIN_K * max(0, chain)


static func dupe_bonus(dupes: int) -> float:
	return 1.0 + DUPE_STEP * min(DUPE_CAP, max(0, dupes))


## The thin wrapper. `dupes` is {id: n} from the economy; pass {} for a plain settle.
static func settle_idle(cells: Array, relics: Array = [], dupes: Dictionary = {}) -> Dictionary:
	var r := Landlord.settle_grid(cells, catalog(), relics)
	var note := func(kind: String, a: int, b: int) -> void:
		r["events"].append(kind)
		if a >= 0 and b >= 0:
			r["links"].append({"a": a, "b": b, "kind": kind})
	for i in range(Landlord.SIZE):
		if Landlord._id(cells, i) != "nia":
			continue
		for n in Landlord.neighbors_of(i):
			if Landlord._id(cells, n) == "wes":
				r["cellScore"][i] += 2
				note.call("nia-audit", i, n)
	var sol_on := false
	for i in range(Landlord.SIZE):
		if Landlord._id(cells, i) != "sol":
			continue
		sol_on = true
		for n in Landlord.neighbors_of(i):
			if Landlord._id(cells, n) == "coffee":
				r["cellScore"][i] += 2
				note.call("sol-late", i, n)
	if sol_on:
		for i in range(Landlord.SIZE):
			var id := Landlord._id(cells, i)
			if id != "sol" and is_staff(id):
				r["cellScore"][i] += 1
		note.call("sol-floor", -1, -1)
	var payout := 0
	for v in r["cellScore"]:
		payout += int(v)
	r["payout"] = payout
	var extra := 0.0
	if not dupes.is_empty():
		for i in range(Landlord.SIZE):
			var id := Landlord._id(cells, i)
			var d: int = int(dupes.get(id, 0))
			if d > 0 and is_staff(id) and int(r["cellScore"][i]) > 0:
				extra += float(r["cellScore"][i]) * (dupe_bonus(d) - 1.0)
	r["dupeExtra"] = extra
	r["chain"] = chain_of(r)
	r["mult"] = chain_mult(r["chain"])
	r["shift"] = int(round((float(payout) + extra) * float(r["mult"])))
	return r
