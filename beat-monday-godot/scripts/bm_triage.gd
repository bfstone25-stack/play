## BMTriage — the inbox node: turn-based triage. A hand of five messages, three actions a
## turn, each message a cost and a consequence; clear the desk before the clock.
## Design: beat_monday_map.md §1 ("keep it small: a hand of 5, 3 actions"). Pure; seeded
## with BMCore.rng so a test can replay it; the screen (main.gd) draws it.
##
## Actions on a message in the hand
##   reply     costs the message's `cost` actions; clears it; earns its xp; a thread pulls a
##             CC into the deck (the consequence of answering)
##   archive   1 action; clears it; a STICKY message (metric, pager) comes back at the
##             bottom of the deck, angrier (cost +1)
##   delegate  2 actions; clears anything; one colleague from the party, once each
##   snooze    free, once a turn; the message goes to the bottom of the deck, urgency -1
## End of turn: every message in the hand loses one urgency; at zero it escalates — it
## hits stress, its cost grows (max 3) and its urgency resets to 2. Then draw to five.
## Win: hand and deck empty. Lose: stress reaches 100, or the clock runs out.
class_name BMTriage

const HAND := 5
const ACTIONS := 3
const STRESS_MAX := 100

## kind -> cost (actions to reply), urg (turns before it escalates), hit (stress when it
## does), xp, sticky (archiving does not get rid of it), spawns (what replying pulls in).
const KINDS := {
	"ping":   {"cost": 1, "urg": 3, "hit": 6,  "xp": 2, "sticky": false, "spawns": ""},
	"invite": {"cost": 1, "urg": 2, "hit": 8,  "xp": 3, "sticky": false, "spawns": ""},
	"thread": {"cost": 2, "urg": 3, "hit": 12, "xp": 5, "sticky": false, "spawns": "cc"},
	"cc":     {"cost": 1, "urg": 4, "hit": 4,  "xp": 3, "sticky": false, "spawns": ""},
	"metric": {"cost": 2, "urg": 2, "hit": 14, "xp": 7, "sticky": true,  "spawns": ""},
	"pager":  {"cost": 3, "urg": 1, "hit": 16, "xp": 6, "sticky": true,  "spawns": ""},
}

## The deck per week: kinds drawn with these weights, this many. Untuned.
const WEEKS := [
	{"size": 12, "turns": 9, "weights": {"ping": 5, "invite": 3, "thread": 2, "cc": 2, "metric": 1, "pager": 1}},
	{"size": 14, "turns": 9, "weights": {"ping": 4, "invite": 3, "thread": 3, "cc": 2, "metric": 2, "pager": 2}},
	{"size": 16, "turns": 9, "weights": {"ping": 3, "invite": 3, "thread": 3, "cc": 2, "metric": 3, "pager": 3}},
]

static func _weighted(t: Dictionary, weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var r := BMCore.rng(t) * total
	for k in weights:
		r -= int(weights[k])
		if r < 0:
			return k
	return weights.keys()[0]


static func _msg(t: Dictionary, kind: String) -> Dictionary:
	t["serial"] = int(t.get("serial", 0)) + 1
	var k: Dictionary = KINDS[kind]
	return {"uid": t["serial"], "kind": kind, "cost": k["cost"], "urg": k["urg"], "esc": 0}


static func new_triage(profile: Dictionary, seed: int) -> Dictionary:
	var week: Dictionary = WEEKS[mini(int(profile.get("week", 0)), WEEKS.size() - 1)]
	var t := {
		"rng": seed & BMCore.MASK, "deck": [], "hand": [], "done": [],
		"turn": 1, "turns": int(week["turns"]), "actions": ACTIONS, "snoozed": false,
		"stress": 0, "xp": 0, "cleared": 0, "over": null,
		"helpers": Array(profile.get("party", [])).duplicate(), "log": [],
	}
	for i in int(week["size"]):
		t["deck"].append(_msg(t, _weighted(t, week["weights"])))
	_draw(t)
	return t


static func _draw(t: Dictionary) -> void:
	while t["hand"].size() < HAND and t["deck"].size():
		t["hand"].append(t["deck"].pop_front())


static func _find(t: Dictionary, uid: int) -> int:
	for i in t["hand"].size():
		if int(t["hand"][i]["uid"]) == uid:
			return i
	return -1


static func _finish_if(t: Dictionary) -> void:
	if t["over"] != null:
		return
	if t["hand"].is_empty() and t["deck"].is_empty():
		t["over"] = "clear"
	elif t["stress"] >= STRESS_MAX:
		t["over"] = "lost"


static func _clear(t: Dictionary, i: int, how: String) -> Dictionary:
	var m: Dictionary = t["hand"][i]
	t["hand"].remove_at(i)
	t["done"].append(m["kind"])
	t["cleared"] = t["cleared"] + 1
	t["log"].append({"how": how, "kind": m["kind"]})
	return m


## reply | archive | delegate | snooze on the message with this uid. Returns "" when it
## happened, else why not (for the screen and the tests).
static func act(t: Dictionary, action: String, uid: int) -> String:
	if t["over"] != null:
		return "over"
	var i := _find(t, uid)
	if i < 0:
		return "no_such_message"
	var m: Dictionary = t["hand"][i]
	var k: Dictionary = KINDS[m["kind"]]
	match action:
		"reply":
			if t["actions"] < int(m["cost"]):
				return "not_enough_actions"
			t["actions"] = t["actions"] - int(m["cost"])
			_clear(t, i, "reply")
			t["xp"] = t["xp"] + int(k["xp"])
			if k["spawns"] != "":
				t["deck"].append(_msg(t, k["spawns"]))
		"archive":
			if t["actions"] < 1:
				return "not_enough_actions"
			t["actions"] = t["actions"] - 1
			_clear(t, i, "archive")
			t["xp"] = t["xp"] + 1
			if k["sticky"]:
				var back := _msg(t, m["kind"])
				back["cost"] = mini(3, int(m["cost"]) + 1)
				back["esc"] = int(m["esc"]) + 1
				t["deck"].append(back)
		"delegate":
			if t["helpers"].is_empty():
				return "nobody_to_delegate_to"
			if t["actions"] < 2:
				return "not_enough_actions"
			t["actions"] = t["actions"] - 2
			var who: String = t["helpers"].pop_front()
			_clear(t, i, "delegate:" + who)
			t["xp"] = t["xp"] + int(k["xp"]) / 2
		"snooze":
			if t["snoozed"]:
				return "already_snoozed"
			t["snoozed"] = true
			t["hand"].remove_at(i)
			m["urg"] = maxi(1, int(m["urg"]) - 1)
			t["deck"].append(m)
			t["log"].append({"how": "snooze", "kind": m["kind"]})
		_:
			return "unknown_action"
	_finish_if(t)
	return ""


## The clock ticks: urgency down, escalations hit, the hand refills, actions reset.
static func end_turn(t: Dictionary) -> void:
	if t["over"] != null:
		return
	var hits := 0
	for m in t["hand"]:
		m["urg"] = int(m["urg"]) - 1
		if int(m["urg"]) <= 0:
			hits += int(KINDS[m["kind"]]["hit"])
			m["urg"] = 2
			m["cost"] = mini(3, int(m["cost"]) + 1)
			m["esc"] = int(m["esc"]) + 1
	t["stress"] = mini(STRESS_MAX, int(t["stress"]) + hits)
	t["lastHit"] = hits
	t["turn"] = t["turn"] + 1
	t["actions"] = ACTIONS
	t["snoozed"] = false
	_draw(t)
	_finish_if(t)
	if t["over"] == null and t["turn"] > t["turns"]:
		t["over"] = "lost"


## The greedy desk-clearer the tests and the headless run use: reply to what it can
## afford, cheapest first; archive what it cannot; snooze the dearest; end the turn.
static func autoplay_turn(t: Dictionary) -> void:
	var guard := 0
	while t["over"] == null and guard < 20:
		guard += 1
		var hand: Array = t["hand"].duplicate()
		hand.sort_custom(func(a, b): return int(a["cost"]) < int(b["cost"]))
		var did := false
		for m in hand:
			if int(m["cost"]) <= int(t["actions"]):
				act(t, "reply", int(m["uid"]))
				did = true
				break
		if did:
			continue
		if t["actions"] >= 2 and not t["helpers"].is_empty() and hand.size():
			act(t, "delegate", int(hand[hand.size() - 1]["uid"]))
			continue
		if t["actions"] >= 1 and hand.size():
			var cheapest: Dictionary = hand[0]
			if not KINDS[cheapest["kind"]]["sticky"] or t["actions"] == 1:
				act(t, "archive", int(cheapest["uid"]))
				continue
		if not t["snoozed"] and hand.size():
			act(t, "snooze", int(hand[hand.size() - 1]["uid"]))
			continue
		break
	end_turn(t)
