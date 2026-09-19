class_name Landlord
## Port of play/office-landlord-x/frontend/js/landlord.js — settleGrid(), LANDLORD_CATALOG,
## rentForFloor(). The parent's rules, byte for byte in behaviour: the conformance test
## (tests/run_tests.gd, "conformance") runs the JS and this over the same seeded boards and
## asserts identical payouts, events, per-cell scores and links.
##
## Nothing sold in the shop changes anything in this file (design §5).

const COLS := 5
const ROWS := 4
const SIZE := 20
const FLOORS := 9
const START_RENT := 8
const RENT_GROWTH := 1.45

const CATALOG: Array = [
	{"id": "coffee", "payout": 2, "tag": "fuel"},
	{"id": "dan", "payout": 3, "tag": "staff"},
	{"id": "priya", "payout": 1, "tag": "staff"},
	{"id": "wes", "payout": 2, "tag": "noise"},
	{"id": "mute", "payout": 4, "tag": "noise"},
	{"id": "printer", "payout": 2, "tag": "infra"},
	{"id": "mara", "payout": 1, "tag": "staff"},
	{"id": "corner", "payout": 3, "tag": "infra"},
]
const CAST: Array = ["mara", "dan", "priya", "wes"]
const RELICS: Array = ["severance", "quiet", "pto", "glass", "badge", "army"]
const STARTER: Array = ["coffee", "coffee", "dan", "dan", "priya", "priya", "priya", "wes", "mute", "printer"]


static func idx(x: int, y: int) -> int:
	return y * COLS + x


static func xy_of(i: int) -> Vector2i:
	return Vector2i(i % COLS, i / COLS)


static func is_corner(i: int) -> bool:
	var p := xy_of(i)
	return (p.x == 0 or p.x == COLS - 1) and (p.y == 0 or p.y == ROWS - 1)


static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < COLS and y >= 0 and y < ROWS


static func neighbors_of(i: int) -> Array:
	var p := xy_of(i)
	var out: Array = []
	for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var nx: int = p.x + d[0]
		var ny: int = p.y + d[1]
		if in_bounds(nx, ny):
			out.append(idx(nx, ny))
	return out


static func neighbors_all(i: int) -> Array:
	var p := xy_of(i)
	var out: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = p.x + dx
			var ny: int = p.y + dy
			if in_bounds(nx, ny):
				out.append(idx(nx, ny))
	return out


static func catalog_by_id(catalog: Array) -> Dictionary:
	var by := {}
	for s in (catalog if catalog.size() else CATALOG):
		by[s["id"]] = s
	return by


static func raw_base(id: String, i: int, by: Dictionary) -> int:
	if not by.has(id):
		return 1
	if id == "corner" and not is_corner(i):
		return 0
	return int(by[id].get("payout", 1))


## cells: Array of 20 entries, "" or null for empty, else a catalogue id.
## Returns {payout:int, events:Array[String], cellScore:Array[int], cellMult:Array[float],
##          cellBase:Array[int], links:Array[{a,b,kind}]}
static func settle_grid(cells: Array, catalog: Array = [], relics: Array = []) -> Dictionary:
	var by := catalog_by_id(catalog)
	var has := func(id: String) -> bool: return relics.has(id)
	var events: Array = []
	var links: Array = []
	var cell_base: Array = []
	var cell_add: Array = []
	var cell_mult: Array = []
	var cell_tax: Array = []
	var shielded: Array = []
	for _i in range(SIZE):
		cell_base.append(0)
		cell_add.append(0)
		cell_mult.append(1.0)
		cell_tax.append(0)
		shielded.append(false)
	var staff := ["dan", "priya", "mara"]
	var note := func(kind: String, a: int, b: int) -> void:
		events.append(kind)
		if a >= 0 and b >= 0:
			links.append({"a": a, "b": b, "kind": kind})

	for i in range(SIZE):
		var id := _id(cells, i)
		if id != "mute":
			continue
		var ring: Array = neighbors_all(i) if has.call("quiet") else neighbors_of(i)
		for n in ring:
			if staff.has(_id(cells, n)):
				shielded[n] = true
				note.call("mute-shield", i, n)

	for i in range(SIZE):
		var id := _id(cells, i)
		if id == "":
			continue
		var s: Dictionary = by.get(id, {"payout": 1})
		var base := raw_base(id, i, by)
		if id == "priya":
			var best: int = int(s.get("payout", 1))
			var from := -1
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if oid == "" or oid == "priya":
					continue
				var ob := raw_base(oid, n, by)
				if ob > best:
					best = ob
					from = n
			base = best
			if from >= 0:
				note.call("priya-copy", i, from)
		if id == "printer":
			var y: int = i / COLS
			var extras := 0
			for x in range(COLS):
				var j := idx(x, y)
				if j != i and _id(cells, j) != "":
					extras += 1
			base += extras
			if extras:
				note.call("print-job", i, i)
		cell_base[i] = base

	for i in range(SIZE):
		var id := _id(cells, i)
		if id == "":
			continue
		var s: Dictionary = by.get(id, {})
		for n in neighbors_of(i):
			var oid := _id(cells, n)
			if not by.has(oid):
				continue
			var other: Dictionary = by[oid]
			if id == "coffee" and oid == "dan":
				cell_mult[i] *= 3
				note.call("coffee-dan", i, n)
			if id == "dan" and oid == "mute":
				cell_add[i] += 2
				note.call("dan-mute", i, n)
			if s.has("tag") and other.has("tag") and s["tag"] == other["tag"]:
				cell_mult[i] *= 1.2
				note.call("tag-" + str(s["tag"]), i, n)
		if id == "mara":
			for n in neighbors_of(i):
				if _id(cells, n) != "":
					cell_add[n] += 1
					note.call("mara-boost", i, n)

	if not has.call("glass"):
		for i in range(SIZE):
			if _id(cells, i) != "wes":
				continue
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if (oid == "priya" or oid == "dan") and not shielded[n]:
					cell_tax[n] += 1
					note.call("wes-tax", i, n)

	var cell_score: Array = []
	for i in range(SIZE):
		cell_score.append(0)
	for i in range(SIZE):
		var id := _id(cells, i)
		if id == "":
			if has.call("severance"):
				cell_score[i] = 1
			continue
		cell_score[i] = int(floor(float(cell_base[i]) * cell_mult[i])) + cell_add[i] - cell_tax[i]

	if has.call("army"):
		var pre: Array = cell_score.duplicate()
		for i in range(SIZE):
			if _id(cells, i) != "priya":
				continue
			var best: int = pre[i]
			var from := -1
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if oid != "" and oid != "priya" and int(pre[n]) > best:
					best = pre[n]
					from = n
			cell_score[i] = best
			if from >= 0:
				note.call("priya-army", i, from)

	var payout := 0
	for v in cell_score:
		payout += int(v)
	if has.call("badge"):
		var chain := 0
		for e in events:
			if e != "wes-tax":
				chain += 1
		payout += chain

	return {"payout": payout, "events": events, "cellScore": cell_score, "cellMult": cell_mult, "cellBase": cell_base, "links": links}


static func _id(cells: Array, i: int) -> String:
	var v = cells[i]
	if v == null:
		return ""
	return str(v)


static func place_at(cells: Array, id: String, index: int) -> Array:
	if id == "" or index < 0 or index >= SIZE:
		return []
	if _id(cells, index) != "":
		return []
	var next := cells.duplicate()
	next[index] = id
	return next


static func rent_for_floor(floor_n: int, relics: Array = []) -> int:
	var f: int = max(1, floor_n)
	var rent := int(floor(START_RENT * pow(RENT_GROWTH, f - 1)))
	if relics.has("glass"):
		rent = int(ceil(rent * 1.1))
	return rent


static func empty_cells() -> Array:
	var c: Array = []
	for _i in range(SIZE):
		c.append(null)
	return c
