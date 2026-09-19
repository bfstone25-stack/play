## Fold — the rules, and nothing else.
##
## A line-for-line port of the shipped game's inline script in
## play/fold/frontend/index.html: load(), move(), undo(), the win test and the star
## formula. No drawing, no sound, no storage, no engine types beyond Array/Dictionary,
## so tests/run_tests.gd can drive it headless and tests/conformance.json can pin it
## against the JavaScript move for move.
##
## Autoloaded as "Fold".
##
## Three things in here look odd and are deliberate, because the JS does them:
##
##  1. **Stable sort, descending.** JS `sort((a,b) => (b.r-a.r)*dr + (b.c-a.c)*dc)` is a
##     stable descending sort on `r*dr + c*dc`. Godot's `sort_custom` is NOT stable, so
##     ties would be resolved arbitrarily — and ties are the common case (a whole row
##     moving sideways has one key for every tile in it). Which of two equal tiles
##     survives a merge, and therefore which id the surviving tile carries, follows from
##     that order. So the port sorts on (key, original index) and gets JS's answer.
##
##  2. **`tiles` shrinks while `order` is walked.** The JS takes a snapshot array, then
##     filters the live one inside the loop. A merged-away tile is still visited later in
##     the snapshot and still has its r/c written — to an object nothing holds any more.
##     Harmless, and reproduced here rather than "cleaned up", because cleaning it up
##     changes nothing visible and makes the two sides stop being the same algorithm.
##
##  3. **Rows may be shorter than the grid.** C is the *widest* row; a short row's
##     missing cells are `undefined` in JS, which is neither "x" nor a positive number,
##     so they become empty. Levels in the shipped levels.json rely on this.
##
## Rounding: the trap documented in play/overtime-idle-godot/scripts/idle.gd — JS
## `toFixed` rounds ties away from zero where C rounds them to even — does not bite here,
## because every quantity in FOLD is an integer. Tile values double, the move counter
## increments, and the star thresholds are integer comparisons. There is no float in the
## rules at all, and the conformance test would catch it if one appeared.
extends Node

const DIRS := {"up": Vector2i(-1, 0), "down": Vector2i(1, 0), "left": Vector2i(0, -1), "right": Vector2i(0, 1)}

## The shipped page's two groupings, kept by number so the level picker and the gate line
## up with the web build: levels 1-50 are free (ops/DUAL_TRACK.md, FREE_LEVELS in
## index.html), and the picker splits "curated" from "endless" at index 51.
const FREE_LEVELS := 50
const CURATED := 51

## The web game's tile ramp, PAL in index.html — slate blue climbing into gold.
const TILE_COLORS := {
	2: Color("3c4657"), 4: Color("4a5a7a"), 8: Color("5b7bba"), 16: Color("c98a3e"),
	32: Color("d9a63f"), 64: Color("e0b356"), 128: Color("e6c674"), 256: Color("efd98f"),
}


static func tile_color(v: int) -> Color:
	return TILE_COLORS.get(v, Color("efd98f"))


## JS: `color: t.v <= 8 ? '#dfe6f0' : '#241a06'`.
static func tile_ink(v: int) -> Color:
	return Color("dfe6f0") if v <= 8 else Color("241a06")

## The 201 shipped levels, loaded from data/levels.json (a byte copy of the live one).
var levels: Array = []

# --- live board -------------------------------------------------------------------------
var level_index: int = 0
var rows: int = 0
var cols: int = 0
var walls: Array[Vector2i] = []
var tiles: Array = []          # [{id:int, r:int, c:int, v:int, merged:bool, spawned:bool}]
var moves: int = 0
var done: bool = false
var history: Array = []        # snapshots, newest last

signal moved(direction: Vector2i, merge_count: int)
signal refused(direction: Vector2i)
signal solved(stars: int, move_count: int, par: int)
signal board_changed


func _ready() -> void:
	load_levels()


func load_levels() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	if f == null:
		push_error("Fold: data/levels.json missing")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array and not parsed.is_empty():
		levels = parsed


func level_count() -> int:
	return levels.size()


func level(i: int) -> Dictionary:
	return levels[clampi(i, 0, levels.size() - 1)]


func target() -> int:
	return int(level(level_index)["target"])


func par() -> int:
	return int(level(level_index)["par"])


## The level's name is "中文 / English" in every entry; split it for the two languages.
func level_name(i: int, lang: String) -> String:
	var raw := str(level(i)["name"])
	var parts := raw.split(" / ")
	if parts.size() < 2:
		return raw
	return parts[0] if lang == "zh" else parts[1]


## JS `load(l)`: build cells, walls and tiles from the grid, reset the counters.
func load_level(i: int) -> void:
	level_index = clampi(i, 0, levels.size() - 1)
	var grid: Array = level(level_index)["grid"]
	rows = grid.size()
	cols = 0
	for row in grid:
		cols = maxi(cols, (row as Array).size())
	walls = []
	tiles = []
	var id := 0
	for r in range(rows):
		var row: Array = grid[r]
		for c in range(cols):
			if c >= row.size():
				continue                       # short row: undefined in JS, empty here
			var v = row[c]
			if v is String and v == "x":
				walls.append(Vector2i(r, c))
			elif (v is int or v is float) and float(v) > 0.0:
				tiles.append({"id": id, "r": r, "c": c, "v": int(v), "merged": false, "spawned": false})
				id += 1
	moves = 0
	done = false
	history = []
	board_changed.emit()


func is_wall(r: int, c: int) -> bool:
	return Vector2i(r, c) in walls


## The piece at (r, c), or an empty Dictionary for "none". The JS returns undefined and
## tests it for truth; an empty Dictionary is the same test here, and typing it keeps the
## mutations below (`occ["v"] *= 2`) legal — a Variant-typed `occ` will not compile.
func tile_at(r: int, c: int) -> Dictionary:
	for t in tiles:
		if int(t["r"]) == r and int(t["c"]) == c:
			return t
	return {}


func snapshot() -> Array:
	var out := []
	for t in tiles:
		out.append({"id": int(t["id"]), "r": int(t["r"]), "c": int(t["c"]), "v": int(t["v"])})
	return out


func restore(snap: Array) -> void:
	tiles = []
	for o in snap:
		tiles.append({"id": int(o["id"]), "r": int(o["r"]), "c": int(o["c"]), "v": int(o["v"]),
			"merged": false, "spawned": false})


## The JS traversal order: stable descending sort on `r*dr + c*dc`.
func _order(dr: int, dc: int) -> Array:
	var keyed := []
	for i in range(tiles.size()):
		keyed.append({"i": i, "k": int(tiles[i]["r"]) * dr + int(tiles[i]["c"]) * dc, "t": tiles[i]})
	keyed.sort_custom(func(a, b):
		if a["k"] != b["k"]:
			return a["k"] > b["k"]          # descending
		return a["i"] < b["i"])             # stable: original order on a tie
	var out := []
	for e in keyed:
		out.append(e["t"])
	return out


## JS `move(dr, dc)`. Returns how many merges happened, or -1 if nothing moved.
func move(dr: int, dc: int) -> int:
	if done:
		return -1
	var snap := snapshot()
	var order := _order(dr, dc)
	var did_move := false
	var merge_count := 0
	var merged_ids := {}
	for t in order:
		var r := int(t["r"])
		var c := int(t["c"])
		while true:
			var nr := r + dr
			var nc := c + dc
			if nr < 0 or nr >= rows or nc < 0 or nc >= cols or is_wall(nr, nc):
				break
			var occ := tile_at(nr, nc)
			if occ.is_empty():
				r = nr
				c = nc
				continue
			if int(occ["v"]) == int(t["v"]) and not merged_ids.has(int(occ["id"])) and int(occ["id"]) != int(t["id"]):
				occ["v"] = int(occ["v"]) * 2
				occ["merged"] = true
				merged_ids[int(occ["id"])] = true
				var kept := []
				for x in tiles:
					if int(x["id"]) != int(t["id"]):
						kept.append(x)
				tiles = kept
				did_move = true
				merge_count += 1
			break
		if r != int(t["r"]) or c != int(t["c"]):
			t["r"] = r
			t["c"] = c
			did_move = true
	if not did_move:
		refused.emit(Vector2i(dr, dc))
		return -1
	history.append(snap)
	moves += 1
	moved.emit(Vector2i(dr, dc), merge_count)
	board_changed.emit()
	_check_win()
	return merge_count


## JS `undo()`: refuses once the level is done, and never takes the counter below zero.
func undo() -> bool:
	if done or history.is_empty():
		return false
	restore(history.pop_back())
	moves = maxi(0, moves - 1)
	board_changed.emit()
	return true


func reset() -> void:
	load_level(level_index)


func is_won() -> bool:
	return tiles.size() == 1 and int(tiles[0]["v"]) == target()


## JS: `moves <= par ? 3 : moves <= par + 2 ? 2 : 1`.
func stars_for(move_count: int, p: int) -> int:
	if move_count <= p:
		return 3
	if move_count <= p + 2:
		return 2
	return 1


func stars() -> int:
	return stars_for(moves, par())


func _check_win() -> void:
	if not is_won():
		return
	done = true
	solved.emit(stars(), moves, par())
