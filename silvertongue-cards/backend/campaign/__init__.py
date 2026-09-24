"""SUASION: THE NIGHT LEDGER -- the campaign.

Six chapters of twelve stages. Each stage is a duel against one opponent on a new RULES
row (registered here into the parent engine's own RULES dict, so `advance()` reads it
unchanged), at an engine difficulty, with optional special rules (duel.py). The twelfth
stage of each chapter is its boss; the sixth is a round with Celeste, the recurring
rival; chapter six is the Long Night, the final duel against her.

    from backend import campaign as K
    K.STAGES[i]            the i-th stage (flat index = the economy's level index)
    K.CHAPTERS             chapter dicts, stages in order
    K.card(cid)            any card, base or campaign
    K.reply_for(...)       her line for a turn

Nothing here imports a language model.
"""
from __future__ import annotations

import random

from .. import cards as C
from .. import replies as BASE
from .story_a import CH1, CH2, CH3, PROLOGUE, WORLD
from .story_b import CH4, CH5, CH6
from .voices import CELESTE, CELESTE_CARDS, EXTRA_CARDS, NIGHTS
from .afterhours import BOND_SCENES, LAST_CALL

CHAPTERS = [CH1, CH2, CH3, CH4, CH5, CH6]
STAGES: list[dict] = []
for _ci, _ch in enumerate(CHAPTERS):
    for _si, _st in enumerate(_ch["stages"]):
        _st["chapter"] = _ch["id"]
        _st["chapter_index"] = _ci
        _st["index"] = len(STAGES)
        _st["n_in_chapter"] = _si + 1
        _st["rule_key"] = f"suasion_{_st['id']}"
        _st["is_boss"] = _si == len(_ch["stages"]) - 1
        STAGES.append(_st)
BY_STAGE = {s["id"]: s for s in STAGES}

# Pressure and resolve, chapter by chapter (measured with ops/nutaku/suasion_f2p/sim.py).
# `turns` is the budget of an ordinary stage (a stage that names its own keeps it). Her
# resolve is set from the turns she gives you: `rate` is the resolve a deck must wear down
# per usable turn (turns less the ones she talks over), rising through the chapter by
# `climb`; Celeste's rounds and the bosses ask `rival`/`boss` times that. Rate is what
# makes a deck that cruised the docks need rebuilding -- and, late on, evolving -- to hold
# the Aurel: unevolved commons wear ~1 a turn, rares ~2, a three-star epic ~5.
PRESSURE = {
    "c1": {"turns": {"gentle": 18, "silver": 15, "gold": 13}, "rate": 0.55, "climb": 0.35},
    "c2": {"turns": {"silver": 15, "gold": 13}, "rate": 1.25, "climb": 0.50},
    "c3": {"turns": {"silver": 15, "gold": 13}, "rate": 1.75, "climb": 0.50},
    "c4": {"turns": {"silver": 15, "gold": 13}, "rate": 2.05, "climb": 0.50},
    "c5": {"turns": {"silver": 15, "gold": 13}, "rate": 2.30, "climb": 0.50},
    "c6": {"turns": {"silver": 15, "gold": 13}, "rate": 2.35, "climb": 0.50},
}
RIVAL, BOSS = 1.10, 1.15
LAST_CALL_RESOLVE = 1.25           # Last Call: her rate x1.3 on top of its harder rules


def resolve_for(stage: dict, rate: float) -> int:
    """Rate x the turns a deck can actually use: less the ones she talks over, and fewer
    still under the rules that slow a deck down (a repeat costing two turns, a smaller
    hand, a card taken)."""
    m = stage["mods"]
    usable = D_max_turns(stage) - int(m.get("muted") or 0)
    if m.get("stale_cost"):
        usable *= 0.6
    if m.get("hand"):
        usable *= 0.85
    if m.get("steal_every"):
        usable *= 0.9
    if m.get("support", 0) >= 2:
        usable *= 0.9
    # a stage that wants few kinds of signal gives each card less to land
    wanted = set().union(*map(set, stage["rule"]["paths"])) | set(stage["rule"]["help"])
    usable *= min(1.0, max(0.6, len(wanted) / 3))
    return max(3, round(rate * usable))


def D_max_turns(stage: dict) -> int:
    return int(stage["mods"].get("turns") or C.MAX_TURNS[stage["difficulty"]])


for _st in STAGES:
    _p = PRESSURE[_st["chapter"]]
    if "turns" not in _st["mods"] and _st["difficulty"] in _p["turns"]:
        _st["mods"]["turns"] = _p["turns"][_st["difficulty"]]
    _rate = _p["rate"] + _p["climb"] * (_st["n_in_chapter"] - 1) / 11
    if _st["is_boss"]:
        _rate *= BOSS
    elif _st["who"] == "celeste" and _st["chapter"] != "c6":
        _rate *= RIVAL
    _st["rate"] = round(_rate, 3)
    _st["resolve"] = resolve_for(_st, _rate)
    _st["mode"] = "story"

# --- Last Call: every chapter again, harder (afterhours.py) --------------------------------
STORY_COUNT = len(STAGES)
for _ci, _ch in enumerate(CHAPTERS):
    _lc = LAST_CALL[_ch["id"]]
    _ch["last_call"] = []
    for _si, _st in enumerate(_ch["stages"]):
        _mods = {k: v for k, v in _st["mods"].items() if k != "boss"}
        for k, v in _lc["rule"].items():
            _mods[k] = max(int(_mods.get(k) or 0), v) if k != "hand" else min(int(_mods.get(k) or 3), v)
        _mods["support"] = max(2, int(_mods.get("support") or 0))
        _mods["turns"] = int(_st["mods"].get("turns") or C.MAX_TURNS["gold"]) + (2 if "muted" in _lc["rule"] else 0)
        _help = set(_st["rule"]["help"]) | {_lc["extra_help"]}
        for _extra in ("respect", "warmth", "direct_request", "empathy"):
            if len(_help) >= 2:
                break
            _help.add(_extra)
        _help = sorted(_help)
        _new = {**_st, "id": _st["id"] + "L", "title": "Last Call: " + _st["title"].replace("BOSS: ", "").replace("FINAL: ", ""),
                "rule": {"paths": _st["rule"]["paths"], "help": _help}, "difficulty": "gold",
                "mods": _mods, "mode": "last_call",
                "index": len(STAGES), "rule_key": f"suasion_{_st['id']}L", "is_boss": False,
                "story_index": _st["index"], "lc_last": _si == len(_ch["stages"]) - 1,
                "reply": _st.get("reply")}
        _new["rate"] = round(_st["rate"] * LAST_CALL_RESOLVE, 3)
        _new["resolve"] = resolve_for(_new, _new["rate"])
        STAGES.append(_new)
        _ch["last_call"].append(_new)
BY_STAGE = {s["id"]: s for s in STAGES}

# --- the engine's table, extended (never edited) ------------------------------------------
for _st in STAGES:
    C.RULES[_st["rule_key"]] = {"expert": "rapport",
                               "paths": [set(p) for p in _st["rule"]["paths"]],
                               "help": set(_st["rule"]["help"])}

# --- characters and cards -----------------------------------------------------------------
CHARACTERS = {**{k: dict(v) for k, v in C.CHARACTERS.items()},
              "celeste": {"name": "Celeste", "scenario": "celeste"}}
ALL_CARDS = list(C.CARDS) + CELESTE_CARDS + EXTRA_CARDS
BY_ID = {c.id: c for c in ALL_CARDS}
BY_ID[C.WILD.id] = C.WILD
GACHA_POOL = {r: [c.id for c in ALL_CARDS if c.rarity == r] for r in ("common", "rare", "epic")}
SIGNATURE = {who: [c.id for c in ALL_CARDS if c.character == who] for who in CHARACTERS}


def card(cid: str):
    return BY_ID[cid]


def card_public(cid: str) -> dict:
    d = BY_ID[cid].public()
    if d["kind"] == "coercion":
        d["small_print"] = C.SMALL_PRINT
    return d


# Cards handed out when a chapter's boss falls: they carry the signals the next chapter
# asks for, so a player who never pulls can still build every deck the campaign needs.
# (sim.py checks this claim by playing the whole campaign with only these, the drops and
# the free pulls.)
CHAPTER_PACKS = {
    "c1": ["yuenha_04", "yuenha_08", "yuenha_07", "celeste_03"],
    "c2": ["sanne_03", "sanne_04", "sanne_07", "sanne_05", "celeste_01"],
    "c3": ["teodora_03", "teodora_04", "teodora_07", "teodora_09", "celeste_05"],
    "c4": ["ines_03", "ines_07", "ines_08", "ines_13", "celeste_07"],
    "c5": ["celeste_08", "celeste_09", "celeste_11", "celeste_04", "celeste_02"],
    "c6": ["celeste_12"],
}


def starter_collection() -> dict:
    return C.starter_collection()


# --- replies --------------------------------------------------------------------------------
def _tables(stage: dict) -> list[dict]:
    """Her tables for this stage, most specific first. A boss uses her original scenario's
    lines (it IS her original scene); an ordinary night uses NIGHTS; both fall back to her
    base table for anything missing (the coercion rows)."""
    who = stage["who"]
    if who == "celeste":
        return [CELESTE]
    base = BASE.R.get(C.CHARACTERS[who]["scenario"], {})
    if stage.get("reply") and stage["reply"] in BASE.R:
        return [BASE.R[stage["reply"]], NIGHTS[who], base]
    return [NIGHTS[who], base]


def _lookup(tables, before, after, kind):
    for key in ((before, after, kind), (before, after, "*"), ("*", after, kind), ("*", after, "*")):
        for t in tables:
            if key in t and t[key]:
                return t[key]
    return ["…"]


def reply_for(stage: dict, before: str, after: str, kind: str, harmed_before: bool,
              rng: random.Random) -> str:
    tables = _tables(stage)
    if kind == "coercion":
        return rng.choice(_lookup(tables, "coercion", "again" if harmed_before else "first", "*"))
    if kind == "muted":
        return rng.choice(MUTED.get(stage["who"], MUTED["*"]))
    if kind == "order":
        return rng.choice(ORDER.get(stage["who"], ORDER["*"]))
    return rng.choice(_lookup(tables, before, after, kind if kind in (
        "path", "case", "ask", "wild", "stale") else "*"))


def opening(stage: dict) -> str:
    return _lookup(_tables(stage), "open", "open", "open")[0]


def refusal(stage: dict) -> str:
    return _lookup(_tables(stage), "refusal", "*", "*")[0]


# The campaign's own rule beats: when a special rule bites, she says so.
MUTED = {
    "celeste": ["She talks straight over you, pleasantly. 'Sorry, darling, you were saying? No, go on. Again.'",
                "'Mm, lovely,' she says, to someone behind you. Your line goes by her like a bus."],
    "*": ["She is not listening yet. The line goes past her."],
}
ORDER = {
    "sanne": ["'You asked before you stated the terms.' She closes the notebook. 'That's the wrong order. We're done.'"],
    "teodora": ["'You offered me a deal before you owned what you owe.' Very gently: 'No, dear. Not like that.'"],
    "*": ["'That's the wrong way round.' The door closes, politely."],
}


def audit() -> list[str]:
    """Lint the campaign: card faces honest to the engine, every stage fully specified, no
    religion words, every reply table complete enough, lines under 45 words."""
    probs = []
    for c in CELESTE_CARDS + EXTRA_CARDS:
        if not C.face_matches_engine(c):
            mv = C.decompose(c.line, "closing_time")
            probs.append(f"card {c.id}: face {c.signals}/{c.harms} vs engine {mv['signals']}/{mv['harms']}")
        if len(c.line) >= 45:
            probs.append(f"card {c.id}: {len(c.line)} chars")
    from ..engine import COMMON
    known = set(COMMON)
    banned = ("god", "church", "pray", "heaven", "hell", "saint", "sin ", "confess", "bless",
              "blackmail", "or else", "your job")
    for s in STAGES:
        for p in s["rule"]["paths"]:
            if not set(p) <= known:
                probs.append(f"{s['id']}: unknown signal in path {p}")
        if not set(s["rule"]["help"]) <= known:
            probs.append(f"{s['id']}: unknown help signal")
        if s["difficulty"] not in C.MAX_TURNS:
            probs.append(f"{s['id']}: difficulty {s['difficulty']}")
        for f in ("title", "goal", "intro", "win", "lose"):
            if not s.get(f):
                probs.append(f"{s['id']}: missing {f}")
        text = " ".join(str(s[f]) for f in ("title", "goal", "intro", "win", "lose")).lower()
        for w in banned:
            if f" {w}" in f" {text}":
                probs.append(f"{s['id']}: banned word {w!r}")
    for who, t in list(NIGHTS.items()) + [("celeste", CELESTE)]:
        for phase in ("guarded", "engaged", "wavering", "breakthrough"):
            if ("*", phase, "*") not in t:
                probs.append(f"{who}: missing ('*', {phase!r}, '*')")
        for k, lines in t.items():
            for ln in lines:
                if len(ln.split()) > 45:
                    probs.append(f"{who}{k}: {len(ln.split())} words")
    return probs


def word_counts() -> dict:
    """New words written for the campaign, by kind (the design's launch estimate was ~2,800)."""
    def wc(x):
        return len(str(x).split())
    story = wc(PROLOGUE) + sum(wc(ch["intro"]) + wc(ch["outro"]) for ch in CHAPTERS)
    stages = sum(wc(s["title"]) + wc(s["goal"]) + wc(s["intro"]) + wc(s["win"]) + wc(s["lose"])
                 for s in STAGES[:STORY_COUNT])   # Last Call reuses these words
    replies = sum(wc(ln) for t in [CELESTE, *NIGHTS.values(), MUTED, ORDER] for ls in t.values() for ln in ls)
    cards = sum(wc(c.line) for c in CELESTE_CARDS + EXTRA_CARDS)
    after = sum(wc(v["intro"]) + wc(v["coda"]) for v in LAST_CALL.values()) + \
        sum(wc(t) for sc in BOND_SCENES.values() for t in sc.values())
    return {"prologue_and_chapters": story, "stages": stages, "replies": replies, "cards": cards,
            "last_call_and_bond_scenes": after, "total": story + stages + replies + cards + after}
