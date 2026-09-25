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
## On Nutaku, F2P appends levels 202-800 from data/levels_gen.json (load_extension).
var levels: Array = []
var base_count := 0

## The daily challenge is not in `levels`: the server hands its board over when it opens
## the day's attempt, and it plays under this sentinel index (F2P.begin_daily).
const DAILY := 100000
## The weekly event's bonus-track board plays the same way (F2P.begin_event).
const EVENT := 100001
## A hard-mode board (ops/nutaku/fold_f2p/hard.py): a cleared level turned a quarter turn,
## sent by the server when it opens the attempt (F2P.begin_hard).
const HARD := 100002
var daily_level: Dictionary = {}     # the server-sent board for DAILY, EVENT or HARD

# --- live board -------------------------------------------------------------------------
var level_index: int = 0
var rows: int = 0
var cols: int = 0
var walls: Array[Vector2i] = []
var tiles: Array = []          # [{id:int, r:int, c:int, v:int, ice:bool, merged:bool, spawned:bool}]
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
		base_count = levels.size()


## Levels 202-800 (ops/nutaku/fold_f2p/gen_levels.py): every one proven solvable and
## replayed by the server. Only the Nutaku build asks for them (scripts/f2p.gd), so the
## itch / ad-track game keeps its 201.
func load_extension() -> int:
	if levels.size() > base_count:
		return levels.size() - base_count
	var added := 0
	# levels_gen.json: the base game's 202-1100; levels_packs.json: the update packs'
	# chapters (1101+). All of it ships; the server's tiers say what is released.
	for path in ["res://data/levels_gen.json", "res://data/levels_packs.json"]:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_warning("Fold: %s missing" % path)
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Array:
			levels.append_array(parsed)
			added += parsed.size()
	return added


func is_daily() -> bool:
	return level_index == DAILY


func is_hard() -> bool:
	return level_index == HARD


## A server-sent board (the daily challenge, an event board or a hard board), not one of `levels`.
func is_special() -> bool:
	return is_sentinel(level_index)


static func is_sentinel(i: int) -> bool:
	return i == DAILY or i == EVENT or i == HARD


## The update-pack look of level `i` ("greenhouse", "frost", ...; Palette.LOOKS), or "".
func look_of(i: int) -> String:
	if is_sentinel(i) and daily_level.is_empty():
		return ""
	if not is_sentinel(i) and (i < 0 or i >= levels.size()):
		return ""
	return str(level(i).get("look", ""))


func level_count() -> int:
	return levels.size()


func level(i: int) -> Dictionary:
	if is_sentinel(i):
		return daily_level
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
	if lang == "zh":
		# the update packs' names carry an English id in the first half ("greenhouse 12 /
		# Greenhouse 12"), so zh takes the pack word from the table like the others
		if (LEVEL_WORDS["zh"] as Dictionary).has(parts[1].get_slice(" ", 0)):
			return _level_word(parts[1], "zh")
		return parts[0]
	return _level_word(parts[1], lang)


## The level names are 14 words ("Warmup", "Easy 12", "Midnight 502", ...), so the other
## languages are a word table rather than a column in levels.json (2026-09-24: ja had been
## showing the English half; de / fr / es / ko would have too). A name not in the table
## stays as it is -- ops/nutaku/fold_f2p/check_i18n.py fails on that.
const LEVEL_WORDS := {
	"ja": {"Warmup": "ウォームアップ", "Corner": "角", "Walls": "壁", "Fourfold": "四つ折り", "Island": "島",
		"Octet": "八つ合わせ", "Ladder": "はしご", "Maze": "迷路", "Easy": "やさしい", "Medium": "ふつう",
		"Hard": "むずかしい", "Expert": "エキスパート", "Endless": "エンドレス", "Midnight": "真夜中",
		"Daily": "デイリー", "Greenhouse": "温室", "Patisserie": "パティスリー", "Rooftop": "屋上", "Frost": "霜", "Observatory": "天文台", "Music": "音楽室"},
	"de": {"Warmup": "Aufwärmen", "Corner": "Ecke", "Walls": "Wände", "Fourfold": "Vierfach", "Island": "Insel",
		"Octet": "Oktett", "Ladder": "Leiter", "Maze": "Labyrinth", "Easy": "Leicht", "Medium": "Mittel",
		"Hard": "Schwer", "Expert": "Experte", "Endless": "Endlos", "Midnight": "Mitternacht",
		"Daily": "Tagesbrett", "Greenhouse": "Gewächshaus", "Patisserie": "Konditorei", "Rooftop": "Dachterrasse", "Frost": "Raureif", "Observatory": "Sternwarte", "Music": "Musikzimmer"},
	"fr": {"Warmup": "Échauffement", "Corner": "Coin", "Walls": "Murs", "Fourfold": "Quadruple", "Island": "Île",
		"Octet": "Octuor", "Ladder": "Échelle", "Maze": "Labyrinthe", "Easy": "Facile", "Medium": "Moyen",
		"Hard": "Difficile", "Expert": "Expert", "Endless": "Infini", "Midnight": "Minuit",
		"Daily": "Jour", "Greenhouse": "Serre", "Patisserie": "Pâtisserie", "Rooftop": "Toit", "Frost": "Givre", "Observatory": "Observatoire", "Music": "Musique"},
	"es": {"Warmup": "Calentamiento", "Corner": "Esquina", "Walls": "Muros", "Fourfold": "Cuádruple", "Island": "Isla",
		"Octet": "Octeto", "Ladder": "Escalera", "Maze": "Laberinto", "Easy": "Fácil", "Medium": "Medio",
		"Hard": "Difícil", "Expert": "Experto", "Endless": "Infinito", "Midnight": "Medianoche",
		"Daily": "Diario", "Greenhouse": "Invernadero", "Patisserie": "Pastelería", "Rooftop": "Azotea", "Frost": "Escarcha", "Observatory": "Observatorio", "Music": "Música"},
	# zh: levels.json carries its own first half; only the pack names need a word
	"zh": {"Greenhouse": "温室", "Patisserie": "甜品房", "Rooftop": "屋顶", "Frost": "霜雪", "Observatory": "观星台",
		"Music": "琴房"},
	"ko": {"Warmup": "워밍업", "Corner": "모서리", "Walls": "벽", "Fourfold": "네 겹", "Island": "섬",
		"Octet": "여덟 겹", "Ladder": "사다리", "Maze": "미로", "Easy": "쉬움", "Medium": "보통",
		"Hard": "어려움", "Expert": "전문가", "Endless": "무한", "Midnight": "자정",
		"Daily": "데일리", "Greenhouse": "온실", "Patisserie": "파티스리", "Rooftop": "옥상", "Frost": "서리", "Observatory": "천문대", "Music": "음악실"},
}


func _level_word(en: String, lang: String) -> String:
	var words: Dictionary = LEVEL_WORDS.get(lang, {})
	var head := en.get_slice(" ", 0)
	if not words.has(head):
		return en
	return str(words[head]) + en.substr(head.length())


## JS `load(l)`: build cells, walls and tiles from the grid, reset the counters.
func load_level(i: int) -> void:
	level_index = i if is_sentinel(i) and not daily_level.is_empty() else clampi(i, 0, levels.size() - 1)
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
				tiles.append({"id": id, "r": r, "c": c, "v": int(v), "ice": false, "merged": false, "spawned": false})
				id += 1
			elif ice_value(v) > 0:
				tiles.append({"id": id, "r": r, "c": c, "v": ice_value(v), "ice": true, "merged": false, "spawned": false})
				id += 1
	moves = 0
	done = false
	history = []
	board_changed.emit()


## Ice (2026-09-24; the rule is fold_rules.py's ICE): a grid cell "i<N>" is an ice tile of
## value N. Ice never slides and stops other tiles like a wall; a same-value tile sliding
## into it merges as usual and the merge thaws it. Pinned to the Python by
## tests/ice_conformance.gd over tests/ice_fixtures.json.
static func ice_value(v) -> int:
	if v is String and v.length() > 1 and v[0] == "i" and v.substr(1).is_valid_int():
		return int(v.substr(1))
	return 0


func level_has_ice(i: int) -> bool:
	for row in level(i)["grid"]:
		for v in row:
			if ice_value(v) > 0:
				return true
	return false


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
		out.append({"id": int(t["id"]), "r": int(t["r"]), "c": int(t["c"]), "v": int(t["v"]),
			"ice": bool(t.get("ice", false))})
	return out


func restore(snap: Array) -> void:
	tiles = []
	for o in snap:
		tiles.append({"id": int(o["id"]), "r": int(o["r"]), "c": int(o["c"]), "v": int(o["v"]),
			"ice": bool(o.get("ice", false)), "merged": false, "spawned": false})


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
	# "merged" is presentation (which piece pops, and Juice's score); it describes THIS
	# move only, so it is cleared here rather than trusting the board to clear it.
	for t0 in tiles:
		t0["merged"] = false
	var snap := snapshot()
	var order := _order(dr, dc)
	var did_move := false
	var merge_count := 0
	var merged_ids := {}
	for t in order:
		if bool(t.get("ice", false)):
			continue                           # ice never slides
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
				occ["ice"] = false                 # a merge thaws ice
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
