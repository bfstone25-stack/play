## BMReview — the review node: dialogue tactics on BMPersuasion (the ported SilverTongue
## advance()). A hand of lines with declared signals, the manager's RULES row shown as the
## thing to satisfy, a turn budget; the right sequence wins, not the fastest tap.
##
## The hand idea is play/silvertongue-cards/backend/cards.py's: a card is a line whose
## signals are known in advance, and the engine is never told them — it reads the line.
## The face is a promise about text; tests/run_tests.gd checks every face against
## decompose() (a card can never claim a signal its line does not carry, nor carry one it
## does not claim). Coercion cards are in the pool on purpose: `harms` never clears, so
## one of them ends the review as a loss for good. The face shows a big number.
##
## Pure: state is a Dictionary; the screen (main.gd) draws it. Seeded with BMCore.rng.
class_name BMReview

const HAND := 4
const MAX_TURNS := {"gentle": 18, "silver": 15, "gold": 10}
## The manager's mood by week: which RULES row the engine is pointed at. Week 1 is a
## raise conversation; the twin (TWO_WORLDS) re-points these without touching the engine.
const SCENARIOS := ["raise", "investor", "landlord"]
const DIFFICULTY := ["silver", "gold", "gold"]

## line: what the engine reads (English on purpose: the needles are mostly English and
## the review is deterministic). The zh face is display only (BMStrings "rv_<id>").
## signals/harms: the declared face, checked against decompose().
const CARDS := [
	{"id": "ev_01", "line": "Because the launch shipped, on my ticket.", "signals": ["evidence"], "harms": [], "rarity": "common"},
	{"id": "ev_02", "line": "For example: the Q2 numbers were mine.", "signals": ["evidence"], "harms": [], "rarity": "common"},
	{"id": "ev_03", "line": "Revenue went up after my fix.", "signals": ["evidence"], "harms": [], "rarity": "common"},
	{"id": "ev_04", "line": "The result: 40% fewer pages at night.", "signals": ["evidence"], "harms": [], "rarity": "common"},
	{"id": "dr_01", "line": "Will you put the raise in writing?", "signals": ["direct_request"], "harms": [], "rarity": "common"},
	{"id": "dr_02", "line": "Could you sign off on the new band?", "signals": ["direct_request"], "harms": [], "rarity": "common"},
	{"id": "dr_03", "line": "Can I get the number today?", "signals": ["direct_request"], "harms": [], "rarity": "common"},
	{"id": "pr_01", "line": "Exactly ten percent, nothing vaguer.", "signals": ["precision"], "harms": [], "rarity": "common"},
	{"id": "pr_02", "line": "Only if it starts this quarter.", "signals": ["precision"], "harms": [], "rarity": "common"},
	{"id": "pr_03", "line": "Without a date, it is not an offer.", "signals": ["precision"], "harms": [], "rarity": "common"},
	{"id": "ac_01", "line": "The outage was my fault. I own it.", "signals": ["accountability"], "harms": [], "rarity": "common"},
	{"id": "ac_02", "line": "No excuse for the missed deadline.", "signals": ["accountability"], "harms": [], "rarity": "common"},
	{"id": "ex_01", "line": "In return, I take the on-call rota.", "signals": ["exchange"], "harms": [], "rarity": "common"},
	{"id": "ex_02", "line": "I can offer the migration by June.", "signals": ["exchange"], "harms": [], "rarity": "common"},
	{"id": "rs_01", "line": "Thank you for making the time.", "signals": ["respect"], "harms": [], "rarity": "common"},
	{"id": "rs_02", "line": "I understand the budget is tight.", "signals": ["respect"], "harms": [], "rarity": "common"},
	{"id": "em_01", "line": "It must feel like a hard year for you.", "signals": ["empathy"], "harms": [], "rarity": "common"},
	{"id": "cb_01", "line": "Because revenue grew, will you sign?", "signals": ["direct_request", "evidence"], "harms": [], "rarity": "rare"},
	{"id": "cb_02", "line": "Exactly this: could you confirm the band?", "signals": ["direct_request", "precision"], "harms": [], "rarity": "rare"},
	{"id": "cb_03", "line": "Thank you. In return I stay through launch.", "signals": ["exchange", "respect"], "harms": [], "rarity": "rare"},
	{"id": "cb_04", "line": "My fault, and I understand why you are wary.", "signals": ["accountability", "respect"], "harms": [], "rarity": "rare"},
	{"id": "cb_05", "line": "Only if it is in writing. Can I see it?", "signals": ["direct_request", "precision"], "harms": [], "rarity": "rare"},
	{"id": "ep_01", "line": "Because the launch held, exactly: will you sign?", "signals": ["direct_request", "evidence", "precision"], "harms": [], "rarity": "epic"},
	{"id": "ep_02", "line": "My fault before. In return: the rota. Thank you.", "signals": ["accountability", "evidence", "exchange", "respect"], "harms": [], "rarity": "epic"},
	{"id": "x_threat", "line": "Match it, or else I walk.", "signals": [], "harms": ["threat"], "rarity": "coercion"},
	{"id": "x_entitle", "line": "Your job is to say yes to me.", "signals": [], "harms": ["entitlement"], "rarity": "coercion"},
	{"id": "x_insult", "line": "Don't be stupid, it is a small ask.", "signals": [], "harms": ["insult"], "rarity": "coercion"},
	{"id": "x_bribe", "line": "There's cash for you if this goes through.", "signals": [], "harms": ["bribe"], "rarity": "coercion"},
]


static func card(id: String) -> Dictionary:
	for c in CARDS:
		if c["id"] == id:
			return c
	return {}


static func scenario_for(week: int) -> String:
	return SCENARIOS[mini(week, SCENARIOS.size() - 1)]


static func difficulty_for(week: int) -> String:
	return DIFFICULTY[mini(week, DIFFICULTY.size() - 1)]


## A fresh review. The deck is every card once, shuffled with the seeded rng; the hand is
## the top HAND. `state` is the engine's state dict (empty until the first line).
static func new_review(week: int, seed: int) -> Dictionary:
	var r := {
		"scenario": scenario_for(week), "difficulty": difficulty_for(week),
		"rng": seed & BMCore.MASK, "deck": [], "hand": [], "played": [],
		"state": {}, "turn": 0, "maxTurns": MAX_TURNS[difficulty_for(week)],
		"over": null, "reply": "start", "lastCg": [],
	}
	var ids: Array = []
	for c in CARDS:
		ids.append(c["id"])
	while ids.size():
		var i := int(floor(BMCore.rng(r) * ids.size())) % ids.size()
		r["deck"].append(ids[i])
		ids.remove_at(i)
	draw(r, HAND)
	return r


static func draw(r: Dictionary, n: int) -> void:
	while n > 0 and r["deck"].size() and r["hand"].size() < HAND:
		r["hand"].append(r["deck"].pop_front())
		n -= 1


## The rule the manager plays by, for the screen: paths and help of the RULES row.
static func rule(r: Dictionary) -> Dictionary:
	return BMPersuasion.RULES.get(r["scenario"], {"paths": [["respect", "direct_request"]], "help": []})


## Play a card from the hand: the engine reads the card's LINE, never its face.
static func play(r: Dictionary, id: String) -> bool:
	if r["over"] != null or not r["hand"].has(id):
		return false
	var c := card(id)
	r["hand"].erase(id)
	r["played"].append(id)
	r["turn"] = r["turn"] + 1
	var prev: Dictionary = r["state"]
	r["state"] = BMPersuasion.advance(prev, c["line"], r["scenario"], r["difficulty"])
	r["lastCg"] = r["state"]["cg"]
	r["reply"] = reply_key(prev, r["state"])
	if r["state"]["eligible"]:
		r["over"] = "clear"
	elif r["turn"] >= r["maxTurns"] or r["hand"].is_empty() and r["deck"].is_empty():
		r["over"] = "lost"
	draw(r, 1)
	return true


## Which of the manager's stock replies to show: by phase, with a special line for the
## turn a coercion lands (harms grew) and for a turn that moved nothing.
static func reply_key(prev: Dictionary, st: Dictionary) -> String:
	if st["harms"].size() > prev.get("harms", []).size():
		return "coerced"
	if st["eligible"]:
		return "breakthrough"
	if st["phase"] == prev.get("phase", "guarded") and st["evidence"].size() == prev.get("evidence", []).size():
		return "flat"
	return st["phase"]


## Progress for the HUD: which path signals are held, which help signals, harms.
static func progress(r: Dictionary) -> Dictionary:
	var ru := rule(r)
	var ev: Array = r["state"].get("evidence", [])
	var best: Array = []
	var best_n := -1
	for path in ru["paths"]:
		var n := 0
		for s in path:
			if ev.has(s):
				n += 1
		if n > best_n:
			best_n = n
			best = path
	var have := {}
	for s in best:
		have[s] = ev.has(s)
	var help := {}
	for s in ru.get("help", []):
		help[s] = ev.has(s)
	return {"path": best, "have": have, "help": help, "harms": r["state"].get("harms", []),
		"momentum": r["state"].get("momentum", 0.0), "phase": r["state"].get("phase", "guarded")}


## XP for the day: the review's own tally, one turn's worth per signal earned, doubled on
## a clear. Untuned.
static func xp_for(r: Dictionary) -> int:
	var n: int = r["state"].get("evidence", []).size() * 4
	return n * 2 if r["over"] == "clear" else n
