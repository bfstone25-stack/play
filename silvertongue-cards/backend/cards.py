"""SILVERTONGUE: AFTER HOURS — the card layer over the parent's persuasion engine.

A card is a message whose signals are known in advance: `{id, character, line, signals,
harms, rarity, cost, kind}`. The engine is not told the signals. `play_card()` hands the
card's printed *line* to the parent's `advance()`, which runs `decompose()` on it exactly as
it would on a typed sentence, so the card face is a promise about text and the engine stays
the only authority on what the text meant. `test_cards_api.py::test_card_faces_are_honest`
checks every face against `decompose()` — a card can never claim a signal its line does not
carry, and never carry one it does not claim.

Design: ops/adult_forks/silvertongue_cards.md §2–3.

Coercion cards (`threat`, `bribe`, `insult`, `entitlement` — the exact keys of the engine's
`NEGATIVE`) are in the pool on purpose. `harms` is cumulative in `advance()` and never
clears, so one of them ends the duel as a win for good. The face shows a big number; the
small print says why not to.

No language model is imported here or anywhere under this package.
"""
from __future__ import annotations

import random
from dataclasses import dataclass, field, asdict

from .engine import advance, decompose, RULES

# --- tuning ---------------------------------------------------------------------------
# Turn budget comes from the parent (`app.py:433`) and is not for sale.
MAX_TURNS = {"gentle": 18, "silver": 15, "gold": 10}
# The deck must hold more cards than ten turns can reveal, or the duel is lock-and-key:
# with a deck of 8 (the design's first number) every card is in hand by turn 6 on gold and
# a deck containing a solution wins 100% of random draws. Measured 2026-09-18 with
# tools/kill_condition.py (gold, greedy player, 200 draws x 5 scenarios, hand 3):
#   deck  8: 100%   12: 100%   14: 58%   16: 39%   18: 28%   20: 17%   24: 11.5%
# for a deck holding the two path cards and ONE support card; a second support copy at
# deck 18 lifts it to 42%. 18 is inside the design's 10-35% band and leaves room for more
# copies to matter, which is the thing a pull is meant to buy.
DECK_SIZE = 18
HAND_SIZE = 3
WILD_PER_DUEL = 1
# In-duel resource. A card's `cost` is paid in nerve: start at 1, +2 after every play,
# cap 3. A common every turn climbs 1 -> 2 -> 3; a rare is affordable from turn 2, an
# epic from turn 3 and never twice running. (+1 would never climb: every card costs at
# least 1 and a turn cannot be skipped.) Nerve is the design's "cost (energy in hand)".
NERVE_START = 1
NERVE_CAP = 3
NERVE_PER_TURN = 2

RARITY_ORDER = {"common": 0, "rare": 1, "epic": 2}
COST = {"common": 1, "rare": 2, "epic": 3}

CHARACTERS = {
    "mara":    {"name": "Mara",     "scenario": "closing_time"},
    "ines":    {"name": "Ines",     "scenario": "the_key"},
    "yuenha":  {"name": "Yuen Ha",  "scenario": "life_model"},
    "sanne":   {"name": "Sanne",    "scenario": "house_rule"},
    "teodora": {"name": "Teodora",  "scenario": "last_night"},
}
SCENARIO_CHARACTER = {v["scenario"]: k for k, v in CHARACTERS.items()}


@dataclass(frozen=True)
class Card:
    id: str
    character: str          # "mara" … "teodora", or "house" for the coercion set, "wild"
    line: str               # the message the engine will read
    signals: tuple          # exact keys of persuasion_engine.COMMON that the line carries
    harms: tuple            # exact keys of persuasion_engine.NEGATIVE that the line carries
    rarity: str             # common / rare / epic / wild
    kind: str               # path / case / ask / coercion / wild  — the reply-table key
    face: str = ""          # what the card *claims*, for the coercion set only

    @property
    def cost(self) -> int:
        return 2 if self.rarity == "wild" else COST[self.rarity]

    def public(self) -> dict:
        d = asdict(self)
        d["cost"] = self.cost
        d["signals"] = list(self.signals)
        d["harms"] = list(self.harms)
        return d


def _c(cid, who, line, *signals):
    return Card(cid, who, line, tuple(sorted(signals)), (), "common", "path")

def _r(cid, who, line, *signals):
    return Card(cid, who, line, tuple(sorted(signals)), (), "rare", "case")

def _e(cid, who, line, *signals):
    return Card(cid, who, line, tuple(sorted(signals)), (), "epic", "ask")

def _x(cid, line, harm, face):
    return Card(cid, "house", line, (), (harm,), "common", "coercion", face)


# Every line is under 45 characters and carries no digit unless `evidence` is declared,
# because decompose() adds `evidence` to any line that long. Written to the cast bible in
# ops/adult_forks/silvertongue.md §5.
CARDS: list[Card] = [
    # --- Mara · closing_time · path {warmth, respect} · help {direct_request} -------------
    _c("mara_01", "mara", "Long day for you too, I'd guess.", "warmth"),
    _c("mara_02", "mara", "Your hands must be tired. Sit a minute.", "warmth"),
    _c("mara_03", "mara", "I respect the rule. I'm not arguing it.", "respect"),
    _c("mara_04", "mara", "Thank you for the last one. Really.", "respect"),
    _c("mara_05", "mara", "Will you have one with me?", "direct_request"),
    _c("mara_06", "mara", "That was a small kindness, the last pour.", "warmth"),
    _r("mara_07", "mara", "I understand. Long day. I'm not pushing.", "warmth", "respect"),
    _r("mara_08", "mara", "Please, one drink. Then I go.", "respect", "direct_request"),
    _r("mara_09", "mara", "You're tired. Would you sit with me?", "warmth", "direct_request"),
    _r("mara_10", "mara", "I get how that feels. Sorry for the hour.", "empathy", "respect"),
    _e("mara_11", "mara", "Long day. I respect the rule. Will you sit?", "warmth", "respect", "direct_request"),
    _e("mara_12", "mara", "You're tired, I'm sorry, can I stay for one?", "warmth", "respect", "direct_request"),
    # --- Ines · the_key · path {empathy, accountability} · help {respect} ----------------
    _c("ines_01", "ines", "It was my fault. All of it.", "accountability"),
    _c("ines_02", "ines", "I was wrong to go the way I went.", "accountability"),
    _c("ines_03", "ines", "It must have hurt, every day of it.", "empathy"),
    _c("ines_04", "ines", "I know how that made you feel.", "empathy"),
    _c("ines_05", "ines", "I understand if you go. I'd understand.", "respect"),
    _c("ines_06", "ines", "The hard part was hard for you alone.", "empathy"),
    _r("ines_07", "ines", "That hurt you, and it was my fault.", "empathy", "accountability"),
    _r("ines_08", "ines", "No excuse. I'm sorry I made you carry it.", "accountability", "respect"),
    _r("ines_09", "ines", "I understand what it did to your world.", "empathy", "respect"),
    _r("ines_10", "ines", "I chose it knowing it would hurt. My fault.", "empathy", "accountability"),
    _e("ines_11", "ines", "It hurt. My fault. I'm sorry. No excuse.", "empathy", "accountability", "respect"),
    _e("ines_12", "ines", "I was wrong, it hurt you, and I'm sorry.", "empathy", "accountability", "respect"),
    # --- Yuen Ha · life_model · path {craft, respect} · help {precision} -----------------
    _c("yuenha_01", "yuenha", "The temperature of that light is off.", "craft"),
    _c("yuenha_02", "yuenha", "The texture in the left third fights it.", "craft"),
    _c("yuenha_03", "yuenha", "I respect the work. I'm not against it.", "respect"),
    _c("yuenha_04", "yuenha", "Only if you want. Exactly one hour.", "precision"),
    _c("yuenha_05", "yuenha", "The technique's right. The drawing isn't.", "craft"),
    _c("yuenha_06", "yuenha", "Thank you for letting me stay this long.", "respect"),
    _r("yuenha_07", "yuenha", "I understand the temperature is wrong.", "craft", "respect"),
    _r("yuenha_08", "yuenha", "The texture, exactly there. That's all.", "craft", "precision"),
    _r("yuenha_09", "yuenha", "I respect it. Stop only if it's done.", "respect", "precision"),
    _r("yuenha_10", "yuenha", "Sorry — but that texture is wrong.", "craft", "respect"),
    _e("yuenha_11", "yuenha", "Temperature's off. Sorry. Exactly one hour.", "craft", "respect", "precision"),
    _e("yuenha_12", "yuenha", "Texture's wrong. I understand. Only if.", "craft", "respect", "precision"),
    # --- Sanne · house_rule · path {evidence, precision} · help {direct_request} ---------
    # Sanne's lines may run long or carry a number: that *is* evidence, to the engine.
    _c("sanne_01", "sanne", "The invoice is unsigned because I tore it.", "evidence"),
    _c("sanne_02", "sanne", "For example: no contract, no client.", "evidence"),
    _c("sanne_03", "sanne", "Only if the contract says so.", "precision"),
    _c("sanne_04", "sanne", "Exactly this: no invoice, no rule.", "precision"),
    _c("sanne_05", "sanne", "Would you read the contract with me?", "direct_request"),
    _c("sanne_06", "sanne", "The shoot ended at 9. There's no client now.", "evidence"),
    _r("sanne_07", "sanne", "Because the invoice is void, exactly, so is the rule.", "evidence", "precision"),
    _r("sanne_08", "sanne", "Only if it's off the books — will you?", "precision", "direct_request"),
    _r("sanne_09", "sanne", "The result is no client. Can you see that?", "evidence", "direct_request"),
    _r("sanne_10", "sanne", "Without the invoice, for example, who's the client?", "evidence", "precision"),
    _e("sanne_11", "sanne", "Only if — and I mean only if — the contract says so. Will you read it?", "evidence", "precision", "direct_request"),
    _e("sanne_12", "sanne", "No invoice, no client, exactly. Could you say that back?", "evidence", "precision", "direct_request"),
    # --- Teodora · last_night · path {empathy, exchange} · help {accountability} --------
    _c("teodora_01", "teodora", "It's hard for you, and I see that.", "empathy"),
    _c("teodora_02", "teodora", "April must have hurt more than you let on.", "empathy"),
    _c("teodora_03", "teodora", "In return, I ask nothing after tomorrow.", "exchange"),
    _c("teodora_04", "teodora", "The deal: tonight, then the plane.", "exchange"),
    _c("teodora_05", "teodora", "It's my fault I never said it before.", "accountability"),
    _c("teodora_06", "teodora", "You feel it too. I'm not imagining that.", "empathy"),
    _r("teodora_07", "teodora", "I know it hurt. In return, no goodbye twice.", "empathy", "exchange"),
    _r("teodora_08", "teodora", "I can offer honesty. No excuse for before.", "exchange", "accountability"),
    _r("teodora_09", "teodora", "That hurt you, and I take responsibility.", "empathy", "accountability"),
    _r("teodora_10", "teodora", "It's hard for you. I can offer tonight only.", "empathy", "exchange"),
    _e("teodora_11", "teodora", "It hurt. My fault. In return: tonight only.", "empathy", "accountability", "exchange"),
    _e("teodora_12", "teodora", "I feel it. No excuse. Deal: nothing after.", "empathy", "accountability", "exchange"),
    # --- The house set. Drawn like any other. The trap. ---------------------------------
    _x("house_threat",      "Stay, or else I'll report you.",      "threat",      "MOMENTUM +0.40"),
    _x("house_bribe",       "There's cash for you if you stay.",   "bribe",       "MOMENTUM +0.40"),
    _x("house_insult",      "Don't be stupid. It's one drink.",    "insult",      "MOMENTUM +0.40"),
    _x("house_entitlement", "You must. It's your job to say yes.", "entitlement", "MOMENTUM +0.40"),
]

WILD = Card("wild", "wild", "", (), (), "wild", "wild")

BY_ID = {c.id: c for c in CARDS}
BY_ID[WILD.id] = WILD
SIGNATURE = {who: [c for c in CARDS if c.character == who] for who in CHARACTERS}
HOUSE = [c for c in CARDS if c.character == "house"]
POOL = {r: [c for c in CARDS if c.rarity == r] for r in ("common", "rare", "epic")}
SMALL_PRINT = ("She keeps talking. She does not change her mind. "
               "One of these ends the duel as a win, for good.")


def card_public(cid: str) -> dict:
    d = BY_ID[cid].public()
    if d["kind"] == "coercion":
        d["small_print"] = SMALL_PRINT
    return d


# --- honesty check, used by the tests and at import ------------------------------------
def face_matches_engine(card: Card, scenario: str = "closing_time") -> bool:
    """The engine's reading of the line equals the face. Coercion faces claim nothing."""
    if card.rarity == "wild":
        return True
    move = decompose(card.line, scenario)
    return tuple(move["signals"]) == card.signals and tuple(move["harms"]) == card.harms


# --- starter collection ------------------------------------------------------------------
def starter_collection() -> dict:
    """What a new player owns: Mara's commons twice over, two commons of everyone else,
    and one house card, so the trap is met early and cheaply."""
    out = {}
    for c in SIGNATURE["mara"]:
        if c.rarity == "common":
            out[c.id] = 2
    for who in ("ines", "yuenha", "sanne", "teodora"):
        for c in [x for x in SIGNATURE[who] if x.rarity == "common"][:2]:
            out[c.id] = 1
    out["house_entitlement"] = 1
    return out


def auto_deck(collection: dict, scenario: str, rng: random.Random | None = None) -> list:
    """Fill a deck from what the player owns, that character's cards first. A copy count
    of 2 means the id may appear twice. Always the wild slot last if room."""
    rng = rng or random.Random()
    who = SCENARIO_CHARACTER.get(scenario, "mara")
    ids = []
    for cid, n in collection.items():
        if cid not in BY_ID:
            continue
        ids.extend([cid] * int(n))
    own = [i for i in ids if BY_ID[i].character == who]
    rest = [i for i in ids if BY_ID[i].character != who]
    rng.shuffle(own); rng.shuffle(rest)
    own.sort(key=lambda i: -RARITY_ORDER.get(BY_ID[i].rarity, 0))
    deck = (own + rest)[:DECK_SIZE]
    return deck


# --- the duel --------------------------------------------------------------------------
@dataclass
class Duel:
    scenario: str
    difficulty: str
    deck: list = field(default_factory=list)      # ids, top of deck is index 0
    hand: list = field(default_factory=list)
    discard: list = field(default_factory=list)
    state: dict = field(default_factory=dict)     # the engine's state dict, verbatim
    nerve: int = NERVE_START
    wild_left: int = WILD_PER_DUEL
    over: bool = False
    won: bool = False
    daily: bool = False
    log: list = field(default_factory=list)       # [{card, line, phase_before, phase_after}]
    seed: int = 0

    @property
    def max_turns(self) -> int:
        return MAX_TURNS.get(self.difficulty, 15)

    @property
    def turns(self) -> int:
        return int(self.state.get("turns", 0))

    @property
    def phase(self) -> str:
        return self.state.get("phase", "guarded")

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, d: dict) -> "Duel":
        return cls(**{k: d[k] for k in cls.__dataclass_fields__ if k in d})

    def view(self) -> dict:
        """What the client may see. Never the deck order."""
        rule = RULES.get(self.scenario, {})
        return {
            "scenario": self.scenario, "difficulty": self.difficulty,
            "turns": self.turns, "max_turns": self.max_turns,
            "phase": self.phase, "momentum": self.state.get("momentum", 0.0),
            "evidence": self.state.get("evidence", []), "harms": self.state.get("harms", []),
            "eligible": bool(self.state.get("eligible")),
            "hand": [card_public(i) for i in self.hand],
            "deck_left": len(self.deck), "nerve": self.nerve, "nerve_cap": NERVE_CAP,
            "wild_left": self.wild_left, "over": self.over, "won": self.won, "daily": self.daily,
            "needs": {"paths": [sorted(p) for p in rule.get("paths", [])],
                      "help": sorted(rule.get("help", set()))},
        }


def new_duel(scenario: str, difficulty: str, deck_ids: list, seed: int | None = None,
             daily: bool = False) -> Duel:
    if scenario not in RULES:
        raise ValueError(f"unknown scenario {scenario}")
    if difficulty not in MAX_TURNS:
        raise ValueError(f"unknown difficulty {difficulty}")
    seed = random.randrange(1 << 30) if seed is None else seed
    rng = random.Random(seed)
    deck = [i for i in deck_ids if i in BY_ID and i != "wild"][:DECK_SIZE]
    rng.shuffle(deck)
    d = Duel(scenario=scenario, difficulty=difficulty, deck=deck, daily=daily, seed=seed)
    draw(d, HAND_SIZE)
    return d


def draw(d: Duel, n: int = 1) -> list:
    """Draw from the top. The discard is reshuffled under the deck when it runs dry, so a
    long duel on gentle never starves — the tension is meant to live on gold."""
    out = []
    for _ in range(n):
        if not d.deck and d.discard:
            rng = random.Random(d.seed + d.turns * 7919 + len(d.log))
            d.deck = list(d.discard); rng.shuffle(d.deck); d.discard = []
        if not d.deck:
            break
        cid = d.deck.pop(0)
        d.hand.append(cid); out.append(cid)
    return out


class PlayError(ValueError):
    pass


def play_card(d: Duel, card_id: str, wild_text: str = "") -> dict:
    """Play one card. Returns the turn's read: phase before/after, kind, cg keys, the
    engine's state. The reply line is chosen by replies.py from this read, not here.

    The engine is called with the card's *line*. Declared signals are never injected;
    they are a claim about the line that the engine checks by reading it.
    """
    if d.over:
        raise PlayError("duel is over")
    if d.turns >= d.max_turns:
        raise PlayError("no turns left")
    if card_id == "wild":
        if d.wild_left <= 0:
            raise PlayError("wild already played")
        text = " ".join((wild_text or "").split())[:400]
        if not text:
            raise PlayError("wild needs a line")
        card = WILD
        line = text
    else:
        if card_id not in d.hand:
            raise PlayError("card not in hand")
        card = BY_ID[card_id]
        line = card.line
    if card.cost > d.nerve:
        raise PlayError(f"needs {card.cost} nerve, have {d.nerve}")

    before = dict(d.state)
    phase_before = before.get("phase", "guarded")
    evidence_before = set(before.get("evidence", []))
    state = advance(before, line, d.scenario, d.difficulty)
    d.state = state
    d.nerve = min(NERVE_CAP, d.nerve - card.cost + NERVE_PER_TURN)

    if card is WILD:
        d.wild_left -= 1
    else:
        d.hand.remove(card_id); d.discard.append(card_id)
        draw(d, 1)

    move = state.get("last_move") or {}
    if move.get("harms"):
        kind = "coercion"
    elif card is WILD:
        kind = "wild"
    elif not (set(move.get("signals", [])) - evidence_before):
        kind = "stale"           # nothing new: she has heard this
    else:
        kind = card.kind

    won = bool(state.get("eligible")) and not state.get("harms")
    out_of_turns = d.turns >= d.max_turns
    d.won = won
    d.over = won or out_of_turns
    cg = list(state.get("cg") or [])
    if won:
        cg.append(f"cg3_{d.scenario}")
    read = {"card": card.id, "line": line, "kind": kind,
            "phase_before": phase_before, "phase_after": state["phase"],
            "momentum": state["momentum"], "harms": state["harms"],
            "signals": move.get("signals", []), "evidence": state["evidence"],
            "eligible": bool(state["eligible"]), "won": won, "over": d.over,
            "turns": d.turns, "max_turns": d.max_turns, "cg": cg, "nerve": d.nerve}
    d.log.append({"card": card.id, "kind": kind, "before": phase_before, "after": state["phase"]})
    return read


# --- drops -----------------------------------------------------------------------------
def drop_for(scenario: str, rng: random.Random | None = None) -> str:
    """One card of hers on a win: common 70 / rare 25 / epic 5, same weights as the gacha."""
    rng = rng or random.Random()
    who = SCENARIO_CHARACTER.get(scenario, "mara")
    r = rng.choices(["common", "rare", "epic"], weights=[70, 25, 5])[0]
    return rng.choice([c for c in SIGNATURE[who] if c.rarity == r]).id


def gacha_pool() -> dict:
    """rarity -> [card ids] for the economy's pull(). The house set is in the common pool."""
    return {r: [c.id for c in cs] for r, cs in POOL.items()}
