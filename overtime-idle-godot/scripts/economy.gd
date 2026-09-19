extends Node
## Economy autoload — port of play/overtime-idle/frontend/js/economy.js.
##
## ============================ CLIENT-TRUSTED, ON PURPOSE ============================
## This is the client-side stand-in for the server-side economy (shared/economy.py: Gold /
## energy / gacha / affection with idempotent SKU grants keyed by transaction id). The
## interface below is the one the game code calls; when the server lands, every method
## here becomes an HTTPRequest to the same-named endpoint and the user:// JSON goes away.
## Nothing in the scenes reaches into `state` directly — go through the methods, so the
## swap is a transport change and not a rewrite.
##
## An idle game with Gold in it cannot trust the client's clock or bank (design §7); this
## build does, on purpose, and says so here.        // swap for shared/economy.py
## =====================================================================================

const SAVE_PATH := "user://economy.json"
const H: int = 3600 * 1000
const SCENE_SKIP_GOLD := 80
const AFF_TIERS: Array = [20, 60, 150, 300]

## `gold` is the price in Gold; `iap` SKUs are bought with money and *grant* Gold.
const SKUS := {
	"timeskip_4h":     {"gold": 40,  "en": "Collect four hours of shifts now"},
	"offline_cap_24h": {"gold": 120, "en": "Offline earnings cap 8h -> 24h, forever", "once": true},
	"pull_1":          {"gold": 30,  "en": "One pull"},
	"pull_10":         {"gold": 270, "en": "Ten pulls"},
	"rent_shield":     {"gold": 50,  "en": "Skip one eviction"},
	"gold_s":          {"iap": "$0.99",  "grants": 100,  "en": "100 Gold"},
	"gold_m":          {"iap": "$4.99",  "grants": 600,  "en": "600 Gold"},
	"gold_l":          {"iap": "$19.99", "grants": 3000, "en": "3000 Gold"},
}

var state: Dictionary = {}
var persist_enabled := true

signal changed


func _ready() -> void:
	state = _fresh()
	load_state()


func _fresh() -> Dictionary:
	var owned := {}
	var dupes := {}
	var affection := {}
	for p in Roster.ROSTER:
		owned[p["id"]] = 1 if p.get("launch", false) else 0
		dupes[p["id"]] = 0
		affection[p["id"]] = 0
	return {"gold": 0, "tickets": 0, "pulls": 0, "sinceEpic": 0, "owned": owned, "dupes": dupes, "affection": affection,
		"shields": 0, "offlineCap24": false, "timeskipMs": 0, "grants": {}, "sceneSkips": {}, "txn": 0, "ledger": []}


func load_state() -> void:
	if not persist_enabled:
		return
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				for k in parsed.keys():
					state[k] = parsed[k]
	for p in Roster.ROSTER:
		if not state["owned"].has(p["id"]):
			state["owned"][p["id"]] = 1 if p.get("launch", false) else 0
			state["dupes"][p["id"]] = 0
			state["affection"][p["id"]] = 0


func save() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state))
		f.close()
	changed.emit()


func reset() -> void:
	state = _fresh()
	save()


func _log(kind: String, meta: Dictionary) -> void:
	var row := {"t": Time.get_unix_time_from_system() * 1000.0, "kind": kind}
	row.merge(meta)
	state["ledger"].append(row)
	if state["ledger"].size() > 200:
		state["ledger"].pop_front()


func sku_of(sku: String) -> Dictionary:
	if SKUS.has(sku):
		var d: Dictionary = SKUS[sku].duplicate()
		d["id"] = sku
		return d
	if sku.begins_with("scene_skip_"):
		return {"id": sku, "gold": SCENE_SKIP_GOLD, "en": "See the scene now", "once": true, "who": sku.substr("scene_skip_".length())}
	return {}


func _effect(def: Dictionary) -> void:
	match def["id"]:
		"timeskip_4h": state["timeskipMs"] = int(state["timeskipMs"]) + 4 * H
		"offline_cap_24h": state["offlineCap24"] = true
		"pull_1": state["tickets"] = int(state["tickets"]) + 1
		"pull_10": state["tickets"] = int(state["tickets"]) + 10
		"rent_shield": state["shields"] = int(state["shields"]) + 1
		"gold_s": state["gold"] = int(state["gold"]) + 100
		"gold_m": state["gold"] = int(state["gold"]) + 600
		"gold_l": state["gold"] = int(state["gold"]) + 3000
		_:
			if def.has("who"):
				state["sceneSkips"][def["who"]] = true


## grant(sku, txId): apply a SKU's effect exactly once per transaction id. This is the
## call the GPHS PUT (gateway/nutaku.py) will make server-side; the same txId twice is a
## no-op.
func grant(sku: String, tx_id: String = "") -> Dictionary:
	var def := sku_of(sku)
	if def.is_empty():
		return {"ok": false, "why": "unknown_sku"}
	if tx_id != "" and state["grants"].has(tx_id):
		return {"ok": false, "why": "duplicate", "sku": state["grants"][tx_id]}
	if def.get("once", false) and is_owned(sku):
		return {"ok": false, "why": "already_owned"}
	_effect(def)
	if tx_id != "":
		state["grants"][tx_id] = sku
	_log("grant", {"sku": sku, "txId": tx_id})
	save()
	return {"ok": true, "sku": sku}


func is_owned(sku: String) -> bool:
	if sku == "offline_cap_24h":
		return bool(state["offlineCap24"])
	if sku.begins_with("scene_skip_"):
		return bool(state["sceneSkips"].get(sku.substr("scene_skip_".length()), false))
	return false


## buy(sku): spend Gold on a Gold-priced SKU. IAP SKUs go through the store, not here.
func buy(sku: String) -> Dictionary:
	var def := sku_of(sku)
	if def.is_empty():
		return {"ok": false, "why": "unknown_sku"}
	if def.has("iap"):
		return {"ok": false, "why": "iap_only"}
	if def.get("once", false) and is_owned(sku):
		return {"ok": false, "why": "already_owned"}
	var price: int = int(def["gold"])
	if int(state["gold"]) < price:
		return {"ok": false, "why": "gold", "need": price - int(state["gold"])}
	state["gold"] = int(state["gold"]) - price
	state["txn"] = int(state["txn"]) + 1
	var r := grant(sku, "local-" + str(state["txn"]))
	if not r["ok"]:
		state["gold"] = int(state["gold"]) + price
		save()
	return r


## Store purchase of an IAP SKU. The dev button and the mocked store call this; on Nutaku
## the GPHS PUT calls grant() with the platform's transaction id.
func purchase(sku: String, tx_id: String = "") -> Dictionary:
	var def := sku_of(sku)
	if def.is_empty() or not def.has("iap"):
		return {"ok": false, "why": "not_iap"}
	if tx_id == "":
		state["txn"] = int(state["txn"]) + 1
		tx_id = "iap-" + str(state["txn"])
	return grant(sku, tx_id)


# ---- gacha -------------------------------------------------------------------------

func _roll_rarity(rng: Callable) -> String:
	if int(state["sinceEpic"]) >= Roster.PITY - 1:
		return "epic"
	var x: float = float(rng.call()) * 100.0
	if x < Roster.RARITY["epic"]:
		return "epic"
	if x < Roster.RARITY["epic"] + Roster.RARITY["rare"]:
		return "rare"
	return "common"


## pull(n, rng): consumes n tickets; returns {ok, results:[{id, rarity, dupe, dupes}]}.
func pull(n: int, rng: Callable = Callable()) -> Dictionary:
	if not rng.is_valid():
		rng = func() -> float: return randf()
	n = max(1, n)
	if int(state["tickets"]) < n:
		return {"ok": false, "why": "tickets", "need": n - int(state["tickets"])}
	state["tickets"] = int(state["tickets"]) - n
	var out: Array = []
	for _i in range(n):
		var rarity := _roll_rarity(rng)
		var pool := Roster.pool(rarity)
		var id: String = pool[int(floor(float(rng.call()) * pool.size()))]
		state["pulls"] = int(state["pulls"]) + 1
		state["sinceEpic"] = 0 if rarity == "epic" else int(state["sinceEpic"]) + 1
		var dupe: bool = int(state["owned"][id]) > 0
		state["owned"][id] = int(state["owned"][id]) + 1
		if dupe:
			state["dupes"][id] = int(state["dupes"][id]) + 1
		out.append({"id": id, "rarity": rarity, "dupe": dupe, "dupes": int(state["dupes"][id])})
	var ids: Array = []
	for o in out:
		ids.append(o["id"])
	_log("pull", {"n": n, "ids": ids})
	save()
	return {"ok": true, "results": out}


# ---- affection ---------------------------------------------------------------------

func add_shifts(id: String, n: int) -> void:
	state["affection"][id] = int(state["affection"].get(id, 0)) + n


func affection_tier(id: String) -> int:
	var a := int(state["affection"].get(id, 0))
	var t := 0
	for x in AFF_TIERS:
		if a >= int(x):
			t += 1
	return t


func can_see_scene(id: String) -> bool:
	return affection_tier(id) >= 4 or (affection_tier(id) >= 3 and bool(state["sceneSkips"].get(id, false)))


# ---- getters -----------------------------------------------------------------------

func gold() -> int: return int(state["gold"])
func tickets() -> int: return int(state["tickets"])
func pulls() -> int: return int(state["pulls"])
func since_epic() -> int: return int(state["sinceEpic"])
func owned(id: String) -> int: return int(state["owned"].get(id, 0))
func dupes(id: String) -> int: return int(state["dupes"].get(id, 0))
func dupe_map() -> Dictionary: return state["dupes"].duplicate()
func affection(id: String) -> int: return int(state["affection"].get(id, 0))
func shields() -> int: return int(state["shields"])
func ledger() -> Array: return state["ledger"].duplicate()


func use_shield() -> bool:
	if int(state["shields"]) <= 0:
		return false
	state["shields"] = int(state["shields"]) - 1
	_log("shield", {})
	save()
	return true


func offline_cap_ms() -> int:
	return (24 if bool(state["offlineCap24"]) else 8) * H


func take_timeskip() -> int:
	var ms := int(state["timeskipMs"])
	state["timeskipMs"] = 0
	save()
	return ms


func dev_add_gold(n: int) -> void:
	state["gold"] = int(state["gold"]) + n
	_log("dev_gold", {"n": n})
	save()
