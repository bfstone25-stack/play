class_name Landlord
## Port of play/catharsis/kernel/landlord.js — the CANONICAL kernel, byte-for-byte in
## behaviour: same COLS/ROWS/SIZE, same LANDLORD_CATALOG ids (coffee/dev/intern/meeting/
## mute/printer/standup/corner), same LANDLORD_RELICS, same settleGrid() cascade, same
## rentForFloor() curve.
##
## This is NOT copied from play/overtime-idle-godot/scripts/landlord.gd. That file is a
## sibling port of the SAME landlord.js with the cast's character-name ids (dan/priya/wes/
## mara) swapped in for dev/intern/meeting/standup, and it also carries FLOORS=9, which is
## a later, non-canonical drift on Overtime's side (Occupancy's own building has nine
## floors; the tower landlord.js describes has eight). Office Landlord uses the constants
## in landlord.js itself — FLOORS=8, START_RENT=8, RENT_GROWTH=1.45 — not overtime's.
## Structure (class_name, static funcs, `_id` null-safe read helper) mirrors overtime's
## file because that shape is a good one, not because the numbers do.
##
## shopPool()/pickShop() are NOT in overtime's port yet — they are added here, translated
## straight from landlord.js, so this file is a superset of the reference rather than a
## subset of it.
##
## Hand-checked against landlord.js before this was wired into any UI (see the header of
## grid.gd for the actual assertions run and their results):
##   * settle_grid() on an empty 20-cell grid -> payout 0
##   * a lone "coffee" -> payout 2 (raw_base, no neighbours to trigger anything)
##   * "coffee" at index 0, "dev" at index 1 (orthogonal neighbours) -> dev's cell scores
##     floor(3 * 3) = 9 (coffee-dev sets cellMult[dev] *= 3), coffee's cell stays 2
##   * "corner" off a corner cell (e.g. index 6, not one of 0/4/15/19) -> raw_base returns
##     0 because is_corner() is false there, so that cell scores 0
## No conformance harness (tests/run_tests.gd) exists yet in this repo — the task explicitly
## did not require building one, only sanity-checking a few hand cases, which is what the
## list above is.

const COLS := 5
const ROWS := 4
const SIZE := 20
const FLOORS := 8
const START_RENT := 8
const RENT_GROWTH := 1.45

const CATALOG: Array = [
	{"id": "coffee", "payout": 2, "tag": "fuel"},
	{"id": "dev", "payout": 3, "tag": "staff"},
	{"id": "intern", "payout": 1, "tag": "staff"},
	{"id": "meeting", "payout": 2, "tag": "noise"},
	{"id": "mute", "payout": 4, "tag": "noise"},
	{"id": "printer", "payout": 2, "tag": "infra"},
	{"id": "standup", "payout": 1, "tag": "staff"},
	{"id": "corner", "payout": 3, "tag": "infra"},
]
const RELICS: Array = ["severance", "quiet", "pto", "glass", "badge", "army"]
const STARTER: Array = [
	"coffee", "coffee", "dev", "dev",
	"intern", "intern", "intern",
	"meeting", "mute", "printer",
]
const STAFF_TAGS: Array = ["dev", "intern", "standup"]


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
	var staff := STAFF_TAGS
	var note := func(kind: String, a: int, b: int) -> void:
		events.append(kind)
		if a >= 0 and b >= 0:
			links.append({"a": a, "b": b, "kind": kind})

	# mute shields adjacent staff from meeting-tax (all 8 neighbours with the `quiet` relic)
	for i in range(SIZE):
		var id := _id(cells, i)
		if id != "mute":
			continue
		var ring: Array = neighbors_all(i) if has.call("quiet") else neighbors_of(i)
		for n in ring:
			if staff.has(_id(cells, n)):
				shielded[n] = true
				note.call("mute-shield", i, n)

	# base payout per cell: intern copies the best orthogonal neighbour, printer scores
	# +1 per other filled cell in its row
	for i in range(SIZE):
		var id := _id(cells, i)
		if id == "":
			continue
		var s: Dictionary = by.get(id, {"payout": 1})
		var base := raw_base(id, i, by)
		if id == "intern":
			var best: int = int(s.get("payout", 1))
			var from := -1
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if oid == "" or oid == "intern":
					continue
				var ob := raw_base(oid, n, by)
				if ob > best:
					best = ob
					from = n
			base = best
			if from >= 0:
				note.call("intern-copy", i, from)
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

	# adjacency multipliers/adds: coffee next to dev triples dev; dev next to mute +2 flat;
	# same-tag orthogonal neighbours x1.2 each; standup gives +1 flat to every neighbour
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
			if id == "coffee" and oid == "dev":
				cell_mult[i] *= 3
				note.call("coffee-dev", i, n)
			if id == "dev" and oid == "mute":
				cell_add[i] += 2
				note.call("dev-mute", i, n)
			if s.has("tag") and other.has("tag") and s["tag"] == other["tag"]:
				cell_mult[i] *= 1.2
				note.call("tag-" + str(s["tag"]), i, n)
		if id == "standup":
			for n in neighbors_of(i):
				if _id(cells, n) != "":
					cell_add[n] += 1
					note.call("standup-boost", i, n)

	# meeting taxes -1 from adjacent intern/dev unless shielded; disabled by `glass`
	if not has.call("glass"):
		for i in range(SIZE):
			if _id(cells, i) != "meeting":
				continue
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if (oid == "intern" or oid == "dev") and not shielded[n]:
					cell_tax[n] += 1
					note.call("meeting-tax", i, n)

	var cell_score: Array = []
	for _i in range(SIZE):
		cell_score.append(0)
	for i in range(SIZE):
		var id := _id(cells, i)
		if id == "":
			if has.call("severance"):
				cell_score[i] = 1
			continue
		cell_score[i] = int(floor(float(cell_base[i]) * cell_mult[i])) + cell_add[i] - cell_tax[i]

	# `army`: every intern copies the single best score on the board (not just orthogonal)
	if has.call("army"):
		var pre: Array = cell_score.duplicate()
		for i in range(SIZE):
			if _id(cells, i) != "intern":
				continue
			var best: int = pre[i]
			var from := -1
			for n in neighbors_of(i):
				var oid := _id(cells, n)
				if oid != "" and oid != "intern" and int(pre[n]) > best:
					best = pre[n]
					from = n
			cell_score[i] = best
			if from >= 0:
				note.call("intern-army", i, from)

	var payout := 0
	for v in cell_score:
		payout += int(v)
	# `badge`: +1 payout per non-tax event
	if has.call("badge"):
		var chain := 0
		for e in events:
			if e != "meeting-tax":
				chain += 1
		payout += chain

	return {"payout": payout, "events": events, "cellScore": cell_score,
		"cellMult": cell_mult, "cellBase": cell_base, "links": links}


## Null-safe cell read: cells[i] may be "" or null for empty; always returns "".
static func _id(cells: Array, i: int) -> String:
	var v = cells[i]
	if v == null:
		return ""
	return str(v)


static func place(cells: Array, id: String) -> Array:
	var empty := -1
	for i in range(cells.size()):
		if _id(cells, i) == "":
			empty = i
			break
	if empty < 0:
		return []
	return place_at(cells, id, empty)


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


## shopPool(ownedRelics, catalog) from landlord.js — NOT yet in overtime's port, added here.
## Every unowned relic plus every catalog symbol, as {kind:"relic"|"symbol", id:String}.
static func shop_pool(owned_relics: Array, catalog: Array = []) -> Array:
	var out: Array = []
	for r in RELICS:
		if not owned_relics.has(r):
			out.append({"kind": "relic", "id": r})
	for s in (catalog if catalog.size() else CATALOG):
		out.append({"kind": "symbol", "id": s["id"]})
	return out


## pickShop(ownedRelics, catalog, count) from landlord.js — also not yet in overtime's
## port. Guarantees at least one relic offer while relics remain unowned, then fills the
## rest of `count` from the combined pool without repeats.
static func pick_shop(owned_relics: Array, catalog: Array, count: int, rng: RandomNumberGenerator = null) -> Array:
	var n: int = max(1, count)
	var relics: Array = []
	for r in RELICS:
		if not owned_relics.has(r):
			relics.append({"kind": "relic", "id": r})
	var symbols: Array = []
	for s in (catalog if catalog.size() else CATALOG):
		symbols.append({"kind": "symbol", "id": s["id"]})
	var out: Array = []
	var _rng := rng if rng != null else RandomNumberGenerator.new()
	if relics.size() > 0:
		var pick: Dictionary = relics[_rng.randi() % relics.size()]
		out.append(pick)
	var bag: Array = []
	for c in relics + symbols:
		var dup := false
		for o in out:
			if o["kind"] == c["kind"] and o["id"] == c["id"]:
				dup = true
				break
		if not dup:
			bag.append(c)
	while out.size() < n and bag.size() > 0:
		var i: int = _rng.randi() % bag.size()
		out.append(bag[i])
		bag.remove_at(i)
	return out
