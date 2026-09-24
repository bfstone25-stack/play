extends Node
## F2P — OCCUPANCY's side of the Nutaku free-to-play build. Autoloaded as "F2P".
##
## The reusable half is the "Nutaku" autoload (scripts/nutaku_f2p.gd, copied from
## shared/godot/nutaku_f2p.gd by ops/nutaku/overtime_f2p/build_web.sh): the platform bridge
## and the HTTP plumbing. This file is what only this game knows: that the economy lives
## under /ot/* (ops/nutaku/overtime_f2p/overtime_economy.py), how the server's building maps
## onto Ticker.B and Economy.state (which the scenes already draw), and which SKUs exist.
##
## Off the platform (itch, the ad track, desktop) `on()` is false and every caller keeps its
## old client-side behaviour. On it the server is the authority on everything with a
## number: the clock, the bank, shifts, pulls, affection, unlocks. The client asks, draws
## what it is told, and never advances a shift itself.
##
## Every write carries a fresh nonce (the server refuses a replay) and the client's idea
## of the server's time (the server refuses a clock that runs ahead of its own).

signal ot_changed
signal tiers_reached(list: Array)      # [{char, tier, kind, text, scene, title}]
signal refused(reason: String)
signal report(rep: Dictionary)         # a /collect or /timeskip report with shifts in it

const POLL_S := 15.0

var clock_offset_ms := 0               # server_ms - local ms, from the last answer
var _poll := 0.0
var _booted := false
var _rng := RandomNumberGenerator.new()


func on() -> bool:
	return Nutaku.active


func _ready() -> void:
	_rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS


## Boot the platform session, then read the whole building. Everything waits on this.
func ensure() -> bool:
	if not on():
		return false
	if _booted:
		return true
	Nutaku.state_path = "/ot/state"
	if not await Nutaku.boot():
		refused.emit(Nutaku.last_error)
		return false
	await refresh()
	_booted = not st().is_empty()
	return _booted


func st() -> Dictionary:
	return Nutaku.state if Nutaku.state.has("floors") else {}


func local_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func server_now_ms() -> int:
	return local_ms() + clock_offset_ms


func nonce() -> String:
	return "%08x%08x%08x" % [_rng.randi(), _rng.randi(), _rng.randi()]


func refresh() -> Dictionary:
	await Nutaku.api("GET", "/ot/state")
	_adopt()
	return st()


## POST /ot<path>. Returns {ok, status, body}. A refusal is announced (refused signal) and
## the server's state is re-read, so an optimistic local move is always undone.
func act(path: String, body: Dictionary = {}) -> Dictionary:
	var b := body.duplicate()
	b["nonce"] = nonce()
	b["client_ms"] = server_now_ms()
	var r: Dictionary = await Nutaku.api("POST", "/ot" + path, b)
	if r["ok"]:
		_adopt()
		var rb: Dictionary = r["body"]
		if rb.has("tiers") and typeof(rb["tiers"]) == TYPE_ARRAY and not (rb["tiers"] as Array).is_empty():
			tiers_reached.emit(rb["tiers"])
		if rb.has("report") and int(rb["report"].get("shifts", 0)) > 0:
			report.emit(rb["report"])
	else:
		refused.emit(str(r["body"].get("reason", "the server said no (%d)" % int(r["status"]))))
		await refresh()
	return r


func _process(delta: float) -> void:
	if not on() or not _booted:
		return
	_poll += delta
	var due := int(st().get("next_shift_ms", 0))
	if _poll >= POLL_S or (due > 0 and server_now_ms() > due + 1500 and _poll > 2.0):
		_poll = 0.0
		refresh()


# ---------------------------------------------------------------------- the mirror

## Server state -> Ticker.B and Economy.state, in place: building.gd holds a reference to
## the floor it is drawing, so floors are updated, not replaced.
func _adopt() -> void:
	var s := st()
	if s.is_empty():
		return
	clock_offset_ms = int(s.get("server_ms", local_ms())) - local_ms()
	var B: Dictionary = Ticker.B
	B["bank"] = int(s["bank"])
	B["relics"] = (s["relics"] as Array).duplicate()
	B["inventory"] = (s["inventory"] as Dictionary).duplicate()
	B["building"] = int(s["building"]["no"])
	B["mult"] = float(s["building"]["mult"])
	B["nextShift"] = int(s.get("next_shift_ms", 0)) - clock_offset_ms   # Ticker.now() is local
	B["clockOffset"] = 0
	B["lastSeen"] = local_ms()
	var floors: Array = B["floors"]
	var srv: Array = s["floors"]
	while floors.size() > srv.size():
		floors.pop_back()
	for i in range(srv.size()):
		var f: Dictionary = srv[i]
		if i >= floors.size():
			floors.append({"n": int(f["n"]), "cells": [], "builtAt": 0, "earnedToday": 0, "shifts": 0, "evictions": 0, "best": 0})
		var d: Dictionary = floors[i]
		d["n"] = int(f["n"])
		d["cells"] = (f["cells"] as Array).duplicate()
		d["fit"] = int(f["fit"])
		d["pay"] = int(f["pay"])
		d["earnedToday"] = int(f["earned_today"])
		d["evictions"] = int(f["evictions"])
	for ch in s["roster"]:
		var id := str(ch["id"])
		Economy.state["affection"][id] = int(ch["aff"])
		if ch.has("owned"):
			Economy.state["owned"][id] = int(ch["owned"])
			Economy.state["dupes"][id] = int(ch["dupes"])
	Economy.state["tickets"] = int(s["tickets"])
	Economy.state["offlineCap24"] = bool(s.get("night_manager", false))
	Economy.state["sinceEpic"] = int(s["pity"]["since_epic"])
	Economy.state["pulls"] = int(s["pity"]["pulls"])
	ot_changed.emit()
	Ticker.changed.emit()


# ------------------------------------------------------------------------- queries

func char_row(id: String) -> Dictionary:
	for ch in st().get("roster", []):
		if str(ch["id"]) == id:
			return ch
	return {}


func slots(id: String) -> int:
	return int(char_row(id).get("slots", 0))


func floor_pay(f: Dictionary) -> int:
	return int(f.get("pay", 0))


func income_h() -> int:
	return int(st().get("income_h", 0))


func tokens(k: String) -> int:
	return int(((st().get("f2p", {}) as Dictionary).get("tokens", {}) as Dictionary).get(k, 0))


func price(sku_id: String) -> int:
	return int(Nutaku.sku(sku_id).get("price", 0))


# ------------------------------------------------------------------------- actions

func place(n: int, index: int, id: String) -> Dictionary:
	return await act("/place", {"floor": n, "index": index, "piece": id})


func take(n: int, index: int) -> Dictionary:
	return await act("/take", {"floor": n, "index": index})


func pull(n: int) -> Dictionary:
	var r := await act("/pull", {"n": n})
	if not r["ok"]:
		return {"ok": false, "why": str(r["body"].get("reason", ""))}
	var out: Array = []
	for x in r["body"].get("results", []):
		out.append({"id": str(x["id"]), "rarity": str(x["rarity"]), "dupe": not bool(x["new"]), "dupes": int(x["dupes"])})
	return {"ok": true, "results": out}


func buy(sku_id: String) -> Dictionary:
	var r := await Nutaku.buy(sku_id)
	await refresh()
	return r
