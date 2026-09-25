"""A campaign duel: the parent engine's `advance()`, the card layer's deck/hand/nerve, and
the campaign's special rules. Pure and deterministic: (stage, deck, stars, seed, plays)
always gives the same duel, so the server can replay a whole duel from the card sequence
and accept a win only if the replay wins.

Special rules (`stage["mods"]`), every one enforced here and nowhere else:

  turns: n         the duel ends after n turns (else the engine's gentle 18 / silver 15 /
                   gold 10)
  hand: n          hand size (else 3)
  muted: k         she talks over your first k cards: each is spent and costs a turn, and
                   the engine never hears it
  steal_every: n   after every n-th turn she takes the costliest card in your hand (first
                   of equals) and you draw a replacement -- Celeste's cut
  stale_cost: n    a card that adds no new signal costs n turns, not one
  support: n       a win needs n of the stage's help signals, not the engine's one
  order: [[a, b]]  signal a must land no later than signal b; b first ends the duel lost
  no_wild: true    the wild card is not in play

"pass" (Hold your tongue) is always legal: it spends a turn and the nerve refills as after
any play, the hand goes to the discard and a fresh hand is drawn. The engine hears nothing.

Resolve (the campaign's one addition to the duel, and the card-battle part of it): every
opponent has a resolve bar (`stage["resolve"]`). A card that lands wears it down by the
number of signals it carries that this stage wants (its paths and help), plus one per
evolution star above the first -- whether or not she has heard those signals before (a
point pressed again still wears her down; she will say so); the wild card scores what
decompose() reads in the typed line, plus one. The engine still decides *whether* she can
be persuaded (`eligible`: the path, the support, no coercion); resolve decides *when*.
A win needs both. So a stronger collection wins in fewer turns, not in a different way, and
nothing bought changes the engine's rules.

A card's nerve cost drops by one (never below one) once a rare or epic is evolved to three
stars.

Live cards (2026-09-24). A hand only ever holds cards that can act in THIS duel: a card
carrying at least one signal the night wants (a path or help signal), or a coercion card
(the design's trap, silvertongue_cards.md s2: "drawn like any other"). A card with none of
the night's signals can neither advance her path nor wear her resolve, so dealing it is a
dead draw: a fresh account's first duel with Mara used to deal Ines's and Teodora's cards.
Which woman a card belongs to does not matter -- her signals do: an Ines card that carries
warmth is live against Mara. `new()` drops dead cards from the deck before the shuffle, so
the replay (which calls `new()` with the stored deck) agrees with the duel that was played.
"""
from __future__ import annotations

import random

from .. import cards as C
from . import BY_ID, reply_for

HAND = C.HAND_SIZE
PHASES = {"guarded": 0, "engaged": 1, "wavering": 2, "breakthrough": 3}


class DuelError(ValueError):
    pass


def max_turns(stage: dict) -> int:
    return int(stage["mods"].get("turns") or C.MAX_TURNS[stage["difficulty"]])


def hand_size(stage: dict) -> int:
    return int(stage["mods"].get("hand") or HAND)


def cost(cid: str, stars: dict) -> int:
    c = BY_ID[cid]
    base = c.cost
    if c.rarity in ("rare", "epic") and int(stars.get(cid, 1)) >= 3:
        base -= 1
    return max(1, base)


def live(stage: dict, cid: str) -> bool:
    """Can this card act in this duel? (see "Live cards" above)"""
    c = BY_ID.get(cid)
    if c is None or cid == "wild":
        return False
    return c.kind == "coercion" or bool(set(c.signals) & _wanted(stage))


def new(stage: dict, deck: list, stars: dict, seed: int) -> dict:
    ids = [i for i in deck if i in BY_ID and i != "wild" and live(stage, i)][:C.DECK_SIZE]
    rng = random.Random(seed)
    rng.shuffle(ids)
    d = {"stage": stage["id"], "seed": seed, "deck": ids, "hand": [], "discard": [],
         "state": {}, "nerve": C.NERVE_START, "wild_left": 0 if stage["mods"].get("no_wild") else 1,
         "turns": 0, "max_turns": max_turns(stage), "over": False, "won": False,
         "reason": "", "first": {}, "stale": 0, "wild_used": 0, "muted_left": int(stage["mods"].get("muted") or 0),
         "log": [], "stars": dict(stars),
         "resolve": int(stage.get("resolve") or 0), "resolve_max": int(stage.get("resolve") or 0)}
    _draw(d, hand_size(stage))
    return d


def _wanted(stage: dict) -> set:
    return set().union(*map(set, stage["rule"]["paths"])) | set(stage["rule"]["help"])


def impact(stage: dict, cid: str, signals, stars: dict) -> int:
    """How much of her resolve this card wears down."""
    rel = len(set(signals) & _wanted(stage))
    if rel == 0:
        return 0
    return rel + (1 if cid == "wild" else max(0, int(stars.get(cid, 1)) - 1))


def _draw(d: dict, n: int) -> None:
    for _ in range(n):
        if not d["deck"] and d["discard"]:
            rng = random.Random(d["seed"] + d["turns"] * 7919 + len(d["log"]))
            d["deck"] = list(d["discard"])
            rng.shuffle(d["deck"])
            d["discard"] = []
        if not d["deck"]:
            return
        d["hand"].append(d["deck"].pop(0))


def _support(stage: dict, evidence) -> int:
    return len(set(stage["rule"]["help"]) & set(evidence))


def play(stage: dict, d: dict, card_id: str, text: str = "") -> dict:
    """One turn. Mutates `d`; returns the turn's read."""
    if d["over"]:
        raise DuelError("duel is over")
    mods = stage["mods"]
    if card_id == "pass":
        return _pass(stage, d)
    if card_id == "wild":
        if d["wild_left"] <= 0:
            raise DuelError("no wild left")
        line = " ".join((text or "").split())[:400]
        if not line:
            raise DuelError("wild needs a line")
        c_cost = 2
    else:
        if card_id not in d["hand"]:
            raise DuelError("card not in hand")
        line = BY_ID[card_id].line
        c_cost = cost(card_id, d["stars"])
    if c_cost > d["nerve"]:
        raise DuelError(f"needs {c_cost} nerve, have {d['nerve']}")

    before = dict(d["state"])
    phase_before = before.get("phase", "guarded")
    harmed_before = bool(before.get("harms"))
    d["nerve"] = min(C.NERVE_CAP, d["nerve"] - c_cost + C.NERVE_PER_TURN)
    if card_id == "wild":
        d["wild_left"] -= 1
        d["wild_used"] += 1
    else:
        d["hand"].remove(card_id)
        d["discard"].append(card_id)

    signals: list = []
    if d["muted_left"] > 0:
        d["muted_left"] -= 1
        kind = "muted"
        spend = 1
        state = before or {"phase": "guarded", "momentum": 0.0, "evidence": [], "harms": [],
                           "eligible": False}
    else:
        state = C.advance(before, line, stage["rule_key"], stage["difficulty"])
        move = state.get("last_move") or {}
        signals = list(move.get("signals", []))
        new_sig = set(signals) - set(before.get("evidence", []))
        if move.get("harms"):
            kind = "coercion"
        elif card_id == "wild":
            kind = "wild"
        elif not new_sig:
            # nothing new: "press" if it still carries something this stage wants (it wears
            # her down; she says she has heard it), "stale" if it carries nothing she wants
            kind = "press" if set(signals) & _wanted(stage) else "stale"
        else:
            kind = BY_ID[card_id].kind
        spend = int(mods.get("stale_cost") or 1) if kind in ("stale", "press") else 1
        if kind == "stale":
            d["stale"] += 1
        for s in signals:
            d["first"].setdefault(s, d["turns"] + 1)
    d["state"] = state
    d["turns"] = min(d["max_turns"], d["turns"] + spend)
    dmg = 0
    if kind not in ("muted", "coercion"):
        dmg = impact(stage, card_id, signals, d["stars"])
        d["resolve"] = max(0, d["resolve"] - dmg)

    # order rule: the later signal landing first closes the duel
    order_broken = False
    for a, b in mods.get("order") or []:
        fb, fa = d["first"].get(b), d["first"].get(a)
        if fb is not None and (fa is None or fa > fb):
            order_broken = True
    eligible = bool(state.get("eligible")) and not state.get("harms")
    need = int(mods.get("support") or 0)
    if need and _support(stage, state.get("evidence", [])) < need:
        eligible = False
    won = eligible and not order_broken and d["resolve"] <= 0
    phase_after = "breakthrough" if won else ("wavering" if state.get("phase") == "breakthrough"
                                              else state.get("phase", "guarded"))
    if order_broken and kind not in ("coercion",):
        kind = "order"
    d["won"] = won
    d["over"] = won or order_broken or d["turns"] >= d["max_turns"]
    if order_broken:
        d["reason"] = "order"
    elif state.get("harms"):
        d["reason"] = "coercion"
    elif d["over"] and not won:
        d["reason"] = "turns"

    stolen = None
    if not d["over"]:
        _draw(d, max(0, hand_size(stage) - len(d["hand"])))
        n = int(mods.get("steal_every") or 0)
        if n and d["turns"] % n == 0 and d["hand"]:
            stolen = max(d["hand"], key=lambda i: (cost(i, d["stars"]), -d["hand"].index(i)))
            d["hand"].remove(stolen)
            d["discard"].append(stolen)
            _draw(d, 1)

    rng = random.Random(d["seed"] * 31 + len(d["log"]))
    line_out = reply_for(stage, phase_before, phase_after, kind, harmed_before, rng)
    read = {"card": card_id, "line": line, "kind": kind, "signals": signals,
            "phase_before": phase_before, "phase_after": phase_after,
            "momentum": state.get("momentum", 0.0), "evidence": state.get("evidence", []),
            "harms": state.get("harms", []), "turns": d["turns"], "max_turns": d["max_turns"],
            "won": won, "over": d["over"], "stolen": stolen, "reply": line_out,
            "support": _support(stage, state.get("evidence", [])), "impact": dmg,
            "resolve": d["resolve"], "resolve_max": d["resolve_max"]}
    d["log"].append({"card": card_id, "text": line if card_id == "wild" else "", "kind": kind,
                     "before": phase_before, "after": phase_after})
    return read


def _pass(stage: dict, d: dict) -> dict:
    before = dict(d["state"])
    phase = before.get("phase", "guarded")
    if phase == "breakthrough":
        phase = "wavering"
    d["nerve"] = min(C.NERVE_CAP, d["nerve"] + C.NERVE_PER_TURN)
    d["turns"] = min(d["max_turns"], d["turns"] + 1)
    d["discard"].extend(d["hand"])
    d["hand"] = []
    d["over"] = d["turns"] >= d["max_turns"]
    if d["over"]:
        d["reason"] = d["reason"] or ("coercion" if before.get("harms") else "turns")
    else:
        _draw(d, hand_size(stage))
    d["stale"] += 0
    rng = random.Random(d["seed"] * 31 + len(d["log"]))
    line_out = rng.choice(PASS_LINES)
    d["log"].append({"card": "pass", "text": "", "kind": "pass", "before": phase, "after": phase})
    return {"card": "pass", "line": "", "kind": "pass", "signals": [], "phase_before": phase,
            "phase_after": phase, "momentum": before.get("momentum", 0.0),
            "evidence": before.get("evidence", []), "harms": before.get("harms", []),
            "turns": d["turns"], "max_turns": d["max_turns"], "won": False, "over": d["over"],
            "stolen": None, "reply": line_out, "support": _support(stage, before.get("evidence", [])),
            "impact": 0, "resolve": d["resolve"], "resolve_max": d["resolve_max"]}


PASS_LINES = ["You say nothing. She lets the silence sit, and so do you.",
              "You hold your tongue. The clock does not.",
              "A pause. She watches you choose not to speak."]


def stars_for(d: dict) -> int:
    """1 for the win; 2 with at least 30% of the turns unused; 3 with at least half unused.
    Read off the replayed duel, never from the client."""
    if not d["won"]:
        return 0
    spare = (d["max_turns"] - d["turns"]) / max(1, d["max_turns"])
    return 3 if spare >= 0.5 else 2 if spare >= 0.3 else 1


def replay(stage: dict, deck: list, stars: dict, seed: int, plays: list) -> dict:
    """Replay a whole duel from its card sequence. `plays` = [{"card": id, "text": str?}].
    Returns {ok, duel, reads, reason?}; ok=False means the sequence is not a legal duel."""
    d = new(stage, deck, stars, seed)
    reads = []
    if not isinstance(plays, list) or len(plays) > 40:
        return {"ok": False, "reason": "malformed plays", "duel": d, "reads": reads}
    for i, p in enumerate(plays):
        if not isinstance(p, dict):
            return {"ok": False, "reason": f"play {i} malformed", "duel": d, "reads": reads}
        try:
            reads.append(play(stage, d, str(p.get("card") or ""), str(p.get("text") or "")))
        except DuelError as e:
            return {"ok": False, "reason": f"play {i}: {e}", "duel": d, "reads": reads}
    return {"ok": True, "duel": d, "reads": reads}


def view(stage: dict, d: dict) -> dict:
    """What the client may see. Never the deck order."""
    st = d["state"]
    return {"stage": stage["id"], "turns": d["turns"], "max_turns": d["max_turns"],
            "phase": "breakthrough" if d["won"] else ("wavering" if st.get("phase") == "breakthrough"
                                                      else st.get("phase", "guarded")),
            "momentum": st.get("momentum", 0.0), "evidence": st.get("evidence", []),
            "harms": st.get("harms", []), "hand": [card_view(i, d["stars"]) for i in d["hand"]],
            "deck_left": len(d["deck"]), "nerve": d["nerve"], "nerve_cap": C.NERVE_CAP,
            "wild_left": d["wild_left"], "muted_left": d["muted_left"], "over": d["over"],
            "won": d["won"], "reason": d["reason"],
            "resolve": d["resolve"], "resolve_max": d["resolve_max"],
            "needs": {"paths": stage["rule"]["paths"], "help": stage["rule"]["help"],
                      "support": int(stage["mods"].get("support") or (0 if stage["difficulty"] == "gentle" else 1))},
            "mods": stage["mods"]}


def card_view(cid: str, stars: dict) -> dict:
    from . import card_public
    v = card_public(cid)
    v["stars"] = int(stars.get(cid, 1))
    v["cost"] = cost(cid, stars)
    return v


# --- a player, for measurement and tests --------------------------------------------------
def greedy_choice(stage: dict, d: dict, skill: float = 1.0, rng: random.Random | None = None) -> str | None:
    """The card a sensible player picks: the affordable card adding the most still-missing
    path/help signals, respecting the stage's order rule and never a house card. `skill` < 1
    makes a random affordable pick that often instead (a player who hasn't learned the
    table yet). Returns None if nothing in hand is affordable (cannot happen: every hand
    holds a cost-1 card or the nerve is >= 2 -- but guard anyway)."""
    rng = rng or random.Random(0)
    ev = set(d["state"].get("evidence", []))
    paths = [set(p) for p in stage["rule"]["paths"]]
    helps = set(stage["rule"]["help"])
    order = stage["mods"].get("order") or []
    affordable = [i for i in d["hand"] if cost(i, d["stars"]) <= d["nerve"]
                  and BY_ID[i].character != "house"]
    if not affordable:
        affordable = [i for i in d["hand"] if cost(i, d["stars"]) <= d["nerve"]]
    if not affordable:
        return "pass"
    if rng.random() > skill:
        return rng.choice(affordable)

    def score(cid):
        sig = set(BY_ID[cid].signals)
        new = sig - ev
        for a, b in order:
            if b in sig and a not in ev and a not in sig:
                return -10
        best_path = max((len(p & new) - 0.01 * len(p - ev - sig) for p in paths), default=0)
        h = len(helps & new)
        need_help = int(stage["mods"].get("support") or 1)
        have_help = len(helps & ev)
        s = best_path * 2 + (1.5 * h if have_help < max(1, need_help) else 0.2 * h)
        s += 0.6 * impact(stage, cid, sig, d["stars"])
        if d["muted_left"] > 0:        # she is not listening yet: spend the cheapest card
            return -cost(cid, d["stars"]) - 0.1 * len(sig)
        return s - 0.05 * cost(cid, d["stars"])
    best = max(affordable, key=score)
    left = d["max_turns"] - d["turns"]
    if score(best) <= 0.3 and d["muted_left"] == 0 and left > 3:
        return "pass"
    return best


def auto_deck(stage: dict, collection: dict, stars: dict | None = None) -> list:
    """A sensible deck for this stage from what the player owns. Coverage first: for every
    signal the stage wants, up to PER_SIGNAL cards carrying it (the ones carrying most of
    what the stage wants, then the cheapest); then the remaining useful cards, cheap
    first. Never a card that cannot act tonight (no filler: a dead card is a dead draw),
    never a house card. At most DECK_SIZE."""
    stars = stars or {}
    need = set().union(*map(set, stage["rule"]["paths"])) | set(stage["rule"]["help"])
    pool = []
    for cid, n in sorted(collection.items()):
        if cid in BY_ID and cid != "wild" and BY_ID[cid].character != "house" and live(stage, cid):
            pool += [cid] * int(n)

    def hits(i):
        return len(set(BY_ID[i].signals) & need)
    pool.sort(key=lambda i: (-hits(i), cost(i, stars), i))
    deck: list = []
    left = list(pool)
    per_signal = max(3, C.DECK_SIZE // max(1, len(need)))
    for sig in sorted(need):
        carriers = [i for i in left if sig in BY_ID[i].signals][:per_signal]
        for i in carriers:
            if len(deck) < C.DECK_SIZE:
                deck.append(i)
                left.remove(i)
    for i in list(left):
        if len(deck) >= C.DECK_SIZE:
            break
        deck.append(i)
        left.remove(i)
    return deck
