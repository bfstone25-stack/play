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

## The server refuses in English (overtime_economy.py Reject / _no). A refusal is shown to
## the player as a banner, so each reason maps to an i18n key here, and
## ops/nutaku/overtime_f2p/check_i18n.py fails when the server gains a reason this table
## lacks. An unknown one shows the generic line, never the server's English.
const REASON := {
	"invalid or expired session": "f2p_rj_session",
	"client_ms must be a number": "f2p_rj_bad_request",
	"client clock is ahead of the server": "f2p_rj_clock",
	"nonce required (8-64 chars, single use)": "f2p_rj_bad_request",
	"replayed request": "f2p_rj_replay",
	"floor required": "f2p_rj_bad_request",
	"no such floor": "f2p_rj_no_floor",
	"not enough in the bank": "f2p_rj_no_bank",
	"index required": "f2p_rj_bad_request",
	"index out of range": "f2p_rj_bad_request",
	"cell occupied": "f2p_rj_cell_taken",
	"not in inventory": "f2p_rj_no_stock",
	"unknown piece": "f2p_rj_unknown",
	"nothing there": "f2p_rj_nothing",
	"unknown object": "f2p_rj_unknown",
	"unknown relic": "f2p_rj_unknown",
	"already owned": "f2p_rj_owned",
	"this building has no more floors": "f2p_rj_no_more_floors",
	"fit-out already at max": "f2p_rj_fit_max",
	"unknown staff": "f2p_rj_unknown",
	"not on the roster yet": "f2p_rj_not_owned",
	"already at max rank": "f2p_rj_max_rank",
	"hours must be 1-24": "f2p_rj_hours",
	"not enough time skips": "f2p_rj_no_skips",
	"the building is not ready to sell": "f2p_rj_not_ready_sell",
	"no rival bid in this chapter": "f2p_rj_no_bid",
	"that bid is for another building": "f2p_rj_bid_other",
	"the story is complete": "f2p_rj_story_done",
	"that chapter is in the next building": "f2p_rj_next_building",
	"the chapter's goals are not all met": "f2p_rj_goals_open",
	"n must be 1 or 10": "f2p_rj_pull_n",
	"not enough tickets": "f2p_rj_no_tickets",
	"unknown character": "f2p_rj_unknown",
	"already talked today": "f2p_rj_talked",
	"no request from them today": "f2p_rj_no_request",
	"already done today": "f2p_rj_done_today",
	"the board does not show it yet": "f2p_rj_board_not_yet",
	"no gift box": "f2p_rj_no_gift_box",
	"that's enough gifts for today": "f2p_rj_gifts_today",
	"no attempts left today": "f2p_rj_no_attempts",
	"start the daily floor first": "f2p_rj_df_start",
	"too fast": "f2p_rj_too_fast",
	"cells must be 20 entries": "f2p_rj_bad_request",
	"the board must hold exactly today's twelve pieces": "f2p_rj_df_pieces",
	"claim all five weekly goals first": "f2p_rj_claim_weekly",
	"bonus already claimed": "f2p_rj_claimed",
	"no such goal this week": "f2p_rj_no_goal",
	"already claimed": "f2p_rj_claimed",
	"goal not complete": "f2p_rj_goal_open",
	"claim all three missions first": "f2p_rj_claim_missions",
	"no such mission today": "f2p_rj_no_mission",
	"mission not complete": "f2p_rj_mission_open",
	"already claimed today": "f2p_rj_claimed_today",
	"no active Night Shift Pass": "f2p_rj_no_pass",
}
## Reasons with a value in them: the English prefix -> key (reason_text() fills the value).
const REASON_PREFIX := {
	"no free slot for ": "f2p_rj_no_slot",
	"rank ": "f2p_rj_rank_tier",
	"the bid is already ": "f2p_rj_bid_already",
}

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
		refused.emit(I18n.fmt("f2p_no_connect", {"e": Nutaku.last_error}))
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
		var why = r["body"].get("reason") if typeof(r["body"]) == TYPE_DICTIONARY else null
		refused.emit(reason_text(str(why)) if why != null else I18n.fmt("f2p_rj_http", {"code": int(r["status"])}))
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


# ---------------------------------------------------------------------- words
# Everything the server says that a player reads is looked up here by its id, never shown
# as the server's English: content.json and config are the English of record, and
# scripts/i18n.gd holds the same line under an f2p_* key in all three languages.

## A server refusal, in the player's language.
func reason_text(why: String) -> String:
	if REASON.has(why):
		return I18n.t(REASON[why])
	for p in REASON_PREFIX:
		if why.begins_with(p):
			var key: String = REASON_PREFIX[p]
			match key:
				"f2p_rj_no_slot":
					return I18n.fmt(key, {"name": char_name(why.substr(p.length()))})
				"f2p_rj_rank_tier":
					var m := RegEx.create_from_string("^rank (\\d+) needs affection tier (\\d+)$").search(why)
					if m != null:
						return I18n.fmt(key, {"rank": m.get_string(1), "tier": m.get_string(2)})
				"f2p_rj_bid_already":
					var st := why.substr(p.length())
					return I18n.fmt(key, {"status": I18n.t("f2p_bid_" + st) if I18n.has("f2p_bid_" + st) else st})
	return I18n.t("f2p_rj_generic")


## An f2p_* key if the table has it, else what the server sent (a key that is missing is
## a check_i18n.py failure, so this fallback is for content newer than the client).
func tx(key: String, fallback) -> String:
	return I18n.t(key) if I18n.has(key) else str(fallback)


func char_name(id: String) -> String:
	return tx("who_" + id, char_row(id).get("name", id))


func building_name(no: int) -> String:
	return tx("f2p_bld_%d" % no, st().get("building", {}).get("name", ""))


func scene_title(id: String, fallback) -> String:
	return tx("f2p_sc_" + id, fallback)


func rival_name(ch: Dictionary) -> String:
	var rid = ch.get("rival_id")
	return tx("f2p_rival_" + str(rid), ch.get("rival", "")) if rid != null else str(ch.get("rival", ""))


## A chapter field (title, intro, outro, boss_title) in the player's language.
func chapter_text(ch_id: String, field: String, fallback) -> String:
	return tx("f2p_ch_%s_%s" % [ch_id, field], fallback)


## The bid's prose with its amount and window filled from the SAME values the bid row
## shows (the scaled target, not a number written into the story): the story cannot say
## "earn 5M" beside a 50,000 target.
func boss_text(ch_id: String, bs: Dictionary) -> String:
	var tmpl := tx("f2p_ch_%s_boss_text" % ch_id, bs.get("text", ""))
	return tmpl.format({"target": RollingLabel._fmt(float(bs["target"])), "hours": int(bs["hours"])})


## A chapter goal with its number filled from the goal's own `need` (the value the
## progress line beside it shows).
func goal_text(ch_id: String, i: int, g: Dictionary) -> String:
	var tmpl := tx("f2p_ch_%s_g%d" % [ch_id, i], g.get("text", ""))
	return tmpl.format({"n": RollingLabel._fmt(float(g.get("need", 0)))})


func tier_line(char_id: String, tier: int, fallback) -> String:
	return tx("f2p_tier_%s_%d" % [char_id, tier], fallback)


func mission_text(m: Dictionary) -> String:
	return tx("f2p_ms_" + str(m["id"]), m["text"]).format({"n": int(m["goal"])})


func weekly_text(g: Dictionary, ev: Dictionary) -> String:
	var id := str(g["id"])
	if id == "w_event":
		return I18n.fmt("f2p_wk_w_event", {"event": tx("f2p_ev_%s_title" % ev["id"], ev["title"]), "n": int(g["goal"]),
				"name": char_name(str(ev["char"]))})
	return tx("f2p_wk_" + id, g["text"]).format({"n": int(g["goal"])})


func request_text(char_id: String, rq: Dictionary) -> String:
	var who := char_name(char_id)
	match str(rq.get("kind", "")):
		"beside":
			var pc := str(rq["piece"])
			return I18n.fmt("f2p_rq_beside", {"name": who, "piece": tx("f2p_pc_" + pc, char_name(pc))})
		"chain":
			return I18n.fmt("f2p_rq_chain", {"name": who, "n": int(rq["n"])})
		"pay":
			return I18n.fmt("f2p_rq_pay", {"name": who, "n": int(rq["n"])})
	return str(rq.get("text", ""))


func sku_name(id: String) -> String:
	return tx("f2p_sku_%s_name" % id, Nutaku.sku(id).get("name", id))


func sku_desc(id: String) -> String:
	return tx("f2p_sku_%s_desc" % id, Nutaku.sku(id).get("description", ""))


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
