"""SUASION after launch: update packs, limited events and featured banners.

Everything here ships with the server; what a player sees is decided by the server's clock
and config (`suasion.schedule`), never by a client build:

  update pack   a new chapter with a new woman (12 duels, a boss with its own rule, a Last
                Call replay of all twelve), her 12 cards, her reply table, her bond ladder
                and scene. Released on `launch + week` (UPDATES.md), or on a date or flag
                set in the config. Its stages sit AFTER the base campaign's 144 in the
                flat stage list, so a release never moves anybody's saved progress.
  event         a limited-time ladder of five duels against a featured opponent under an
                event rule, paying an event currency ("marks") that buys rewards on a track.
                Runs [start, end) on the server's clock.
  banner        a limited gacha banner: while it runs, a pull on it lands on the featured
                cards for half of each rarity's rolls.

A pack module (p1.py ... p6.py) defines WHO, NAME, SCENARIO, AGE, CARDS, CHAPTER, REPLIES,
ORDER_LINES, MUTED_LINES, LAST_CALL, BOND_SCENES, EVENT, BANNER. `lint()` holds each to the
house rules (UPDATES.md "Writing rules") and the campaign's audit runs it.

Nothing here imports a language model.
"""
from __future__ import annotations

import datetime as _dt
import importlib

from ... import cards as C

import os as _os
import pathlib as _pl

ALL_PACK_IDS = ["p1", "p2", "p3", "p4", "p5", "p6"]
# A pack whose module is not written yet is simply absent (UPDATES.md lists the plan).
PACK_IDS = [p for p in ALL_PACK_IDS if (_pl.Path(__file__).with_name(f"{p}.py")).exists()]
# Writing tool only: SUASION_PACKS=p3 loads just that pack (a draft elsewhere may not import).
if _os.environ.get("SUASION_PACKS"):
    PACK_IDS = [p for p in PACK_IDS if p in _os.environ["SUASION_PACKS"].split(",")]
# Weeks after launch: one pack every two weeks for weeks 6-16, each with its event and
# banner running for the two weeks until the next (the last one to week 18).
WEEKS = {"p1": 6, "p2": 8, "p3": 10, "p4": 12, "p5": 14, "p6": 16}
EVENT_DAYS = 14
# A pack lands in two halves: nights 1-6 on its release day, nights 7-12 (her boss, then her
# Last Call) a week later -- so there is something new every week, not a fortnight's content
# eaten in two days (sim.py --updates measured that: a 12-day gap with nothing new).
SECOND_HALF_DAYS = 7
FIRST_HALF = 6

PACKS = [importlib.import_module(f".{pid}", __name__) for pid in PACK_IDS]
BY_PACK = {pid: m for pid, m in zip(PACK_IDS, PACKS)}

from . import base_events as _BE  # noqa: E402

# Events before the first pack (base_events.py): day offsets from launch.
BASE_EVENTS = _BE.EVENTS

# The reward track every event uses, in marks. `{rare}` / `{epic}` are the featured
# woman's cards: an event is how a player who never pulls gets her best ones.
TRACK = [
    {"need": 30, "reward": {"tokens": {"chips": 300}}},
    {"need": 80, "reward": {"tokens": {"ticket": 1}}},
    {"need": 140, "reward": {"cards": ["{rare}"]}},
    {"need": 210, "reward": {"energy": 3}},
    {"need": 290, "reward": {"tokens": {"ticket": 2}}},
    {"need": 380, "reward": {"cards": ["{epic}"]}},
    {"need": 480, "reward": {"tokens": {"chips": 1000}}},
    {"need": 600, "reward": {"tokens": {"ticket": 3}}},
]
MARKS = [8, 10, 12, 15, 20]          # per win on event stage 1..5; a first clear pays double
EVENT_RATE = [0.9, 1.2, 1.5, 1.8, 2.1]  # her resolve per usable turn on event stage 1..5


def _cards_of(who: str, all_cards) -> dict:
    out = {"common": [], "rare": [], "epic": []}
    for c in all_cards:
        if c.character == who and c.rarity in out:
            out[c.rarity].append(c.id)
    return out


def track_for(event: dict, all_cards) -> list[dict]:
    mine = _cards_of(event["who"], all_cards)
    rare = (mine["rare"] or mine["common"])[0]
    epic = (mine["epic"] or mine["rare"] or mine["common"])[-1]
    out = []
    for i, step in enumerate(TRACK):
        r = {k: (dict(v) if isinstance(v, dict) else list(v) if isinstance(v, list) else v)
             for k, v in step["reward"].items()}
        if "cards" in r:
            r["cards"] = [rare if x == "{rare}" else epic if x == "{epic}" else x for x in r["cards"]]
        out.append({"step": i, "need": step["need"], "reward": r})
    return out


def gift_for_event(event: dict, all_cards) -> list[str]:
    """A trial hand for everyone who opens the event: one of each of her commons, so a
    newcomer can meet the event's support signal without a pull."""
    return _cards_of(event["who"], all_cards)["common"][:5]


def gift_for_pack(mod) -> list[str]:
    """When her chapter opens: two of each of her commons and her first rare. Her path
    signals are carried by nobody else's cards, so without this the chapter would be a
    paywall (sim.py checks a free player clears it)."""
    commons = [c.id for c in mod.CARDS if c.rarity == "common"]
    rare = [c.id for c in mod.CARDS if c.rarity == "rare"][:1]
    return commons + commons + rare


def boss_pack(mod) -> list[str]:
    """Her chapter's boss pays out her other rares (the Last Call wants two kinds of
    support)."""
    return [c.id for c in mod.CARDS if c.rarity == "rare"][1:]


# --------------------------------------------------------------------------- the schedule
def _ts(date) -> float | None:
    if date in (None, ""):
        return None
    if isinstance(date, (int, float)):
        return float(date)
    d = _dt.datetime.fromisoformat(str(date))
    if d.tzinfo is None:
        d = d.replace(tzinfo=_dt.timezone.utc)
    return d.timestamp()


def schedule(sched: dict | None, now: float) -> dict:
    """What is live at `now` (server clock), from the config's `suasion.schedule`:

        {"launch": "2026-11-01",                    # day 0; no launch = nothing scheduled
         "packs":  {"p2": {"date": "...", "on": true|false}},   # optional overrides
         "events": {"ev_p1": {"start": "...", "end": "...", "on": false}},
         "banners": {"bn_p1": {"start": "...", "end": "..."}}}

    A pack stays released once released (`on: false` withdraws it before it opens, for a
    pack that is not ready). Events and banners run [start, end).
    """
    sched = sched or {}
    launch = _ts(sched.get("launch"))
    day = 86400.0
    packs, events, banners = {}, {}, {}
    for pid in PACK_IDS:
        o = (sched.get("packs") or {}).get(pid) or {}
        start = _ts(o.get("date")) or (launch + WEEKS[pid] * 7 * day if launch is not None else None)
        on = o.get("on")
        if on is True:
            released = True
        elif on is False:
            released = False
        else:
            released = start is not None and now >= start
        second = _ts(o.get("second_half")) or (start + SECOND_HALF_DAYS * day if start is not None else None)
        half = released and (on is True and o.get("second_half") is None or
                             (second is not None and now >= second))
        packs[pid] = {"released": released, "start": start, "week": WEEKS[pid],
                      "second_half": second, "second_half_open": bool(half)}
    evdefs = [(e["id"], e.get("start_day"), e.get("days", EVENT_DAYS), None) for e in BASE_EVENTS]
    evdefs += [(m.EVENT["id"], None, EVENT_DAYS, pid) for pid, m in zip(PACK_IDS, PACKS)]
    for eid, sd, days, pid in evdefs:
        o = (sched.get("events") or {}).get(eid) or {}
        if pid:
            base = packs[pid]["start"] if o.get("start") is None else _ts(o.get("start"))
        else:
            base = _ts(o.get("start")) if o.get("start") is not None else (
                launch + sd * day if launch is not None else None)
        end = _ts(o.get("end")) if o.get("end") is not None else (base + days * day if base is not None else None)
        active = base is not None and base <= now < end and o.get("on", True) is not False
        if pid and not packs[pid]["released"]:
            active = False
        events[eid] = {"active": active, "start": base, "end": end}
    for pid, m in zip(PACK_IDS, PACKS):
        bid = m.BANNER["id"]
        o = (sched.get("banners") or {}).get(bid) or {}
        ev = events[m.EVENT["id"]]
        start = _ts(o.get("start")) if o.get("start") is not None else ev["start"]
        end = _ts(o.get("end")) if o.get("end") is not None else ev["end"]
        active = (start is not None and start <= now < end and o.get("on", True) is not False
                  and packs[pid]["released"])
        banners[bid] = {"active": active, "start": start, "end": end, "pack": pid}
    return {"packs": packs, "events": events, "banners": banners}


def released(sched: dict | None, now: float) -> set[str]:
    return {p for p, v in schedule(sched, now)["packs"].items() if v["released"]}


def second_half(sched: dict | None, now: float) -> set[str]:
    return {p for p, v in schedule(sched, now)["packs"].items() if v["second_half_open"]}


# --------------------------------------------------------------------------- the lint
REQUIRED_KEYS = [(b, a, k) for (b, a) in (("guarded", "guarded"), ("guarded", "engaged"),
                                         ("engaged", "engaged"), ("engaged", "wavering"),
                                         ("wavering", "wavering"), ("*", "breakthrough"))
                 for k in ("path", "case", "ask")] + \
                [("guarded", "guarded", "stale"), ("engaged", "engaged", "stale"),
                 ("wavering", "wavering", "stale")]
SINGLE_KEYS = [("open", "open", "open"), ("coercion", "first", "*"), ("coercion", "again", "*"),
               ("refusal", "*", "*"), ("*", "guarded", "*"), ("*", "engaged", "*"),
               ("*", "wavering", "*"), ("*", "guarded", "wild"), ("*", "engaged", "wild"),
               ("*", "wavering", "wild")]
# Religion, and the leverage the house rules forbid, in any of the pack's words.
BANNED = ("god", "church", "pray", "heaven", "hell ", "saint", "sin ", "confess", "bless",
          "blackmail", "or else", "your job", "leverage", "threaten", "idiot", "stupid",
          "priest", "prayer", "angel", "devil")
MAX_REPLY_WORDS = 40


def _words(s: str) -> int:
    return len(str(s).split())


def lint(mod, known_signals, known_cards: set) -> list[str]:
    """House rules for a pack: an honest card set, a full reply table (several lines per
    phase and card type, each under 40 words), 12 duels and a boss with its own rule, a
    Last Call, the bond scenes, an event of five and a banner of her cards, no banned
    word, and her age stated where she is introduced."""
    p, pid = [], mod.CHAPTER["id"]
    ids = [c.id for c in mod.CARDS]
    if len(set(ids)) != len(ids) or set(ids) & known_cards:
        p.append(f"{pid}: duplicate card ids")
    by_r = {r: sum(1 for c in mod.CARDS if c.rarity == r) for r in ("common", "rare", "epic")}
    if by_r["common"] < 6 or by_r["rare"] < 4 or by_r["epic"] < 2:
        p.append(f"{pid}: card set {by_r} (want >= 6/4/2)")
    for c in mod.CARDS:
        if c.character != mod.WHO:
            p.append(f"{c.id}: character {c.character}")
        if not C.face_matches_engine(c):
            mv = C.decompose(c.line, "closing_time")
            p.append(f"{c.id}: face {c.signals}/{c.harms} vs engine {mv['signals']}/{mv['harms']}")
        if len(c.line) >= 45:
            p.append(f"{c.id}: {len(c.line)} chars")
    mine = set().union(*(set(c.signals) for c in mod.CARDS))
    for s in list(mod.PATH_SIGNALS) + [mod.HELP_SIGNAL]:
        if s not in mine:
            p.append(f"{pid}: no card of hers carries {s}")
    st = mod.CHAPTER["stages"]
    if len(st) < 12:
        p.append(f"{pid}: {len(st)} stages")
    if not (st[-1]["mods"].get("boss") and len(set(st[-1]["mods"]) - {"boss"}) >= 1):
        p.append(f"{pid}: the boss has no rule of its own")
    if str(mod.AGE) not in mod.CHAPTER["intro"] and _num_word(mod.AGE) not in mod.CHAPTER["intro"].lower():
        p.append(f"{pid}: her age ({mod.AGE}) is not stated in the chapter intro")
    for s in st + mod.EVENT["stages"]:
        for path in s["rule"]["paths"]:
            if not set(path) <= known_signals:
                p.append(f"{s['id']}: unknown signal in {path}")
        if not set(s["rule"]["help"]) <= known_signals:
            p.append(f"{s['id']}: unknown help signal")
        for f in ("title", "goal", "intro", "win", "lose"):
            if not s.get(f):
                p.append(f"{s['id']}: missing {f}")
    if len(mod.EVENT["stages"]) != 5:
        p.append(f"{pid}: event has {len(mod.EVENT['stages'])} stages, want 5")
    for k in REQUIRED_KEYS:
        if len(mod.REPLIES.get(k) or []) < 2:
            p.append(f"{pid} replies {k}: {len(mod.REPLIES.get(k) or [])} lines, want >= 2")
    for k in SINGLE_KEYS:
        if not mod.REPLIES.get(k):
            p.append(f"{pid} replies {k}: missing")
    for k, lines in mod.REPLIES.items():
        for ln in lines:
            if _words(ln) >= MAX_REPLY_WORDS:
                p.append(f"{pid} replies {k}: {_words(ln)} words")
    for ln in list(mod.ORDER_LINES) + list(mod.MUTED_LINES):
        if _words(ln) >= MAX_REPLY_WORDS:
            p.append(f"{pid} rule line: {_words(ln)} words")
    for k in ("cg1", "cg2", "cg4"):
        if not mod.BOND_SCENES.get(k):
            p.append(f"{pid}: bond scene {k} missing")
    for k in ("rule", "extra_help", "intro", "coda"):
        if not mod.LAST_CALL.get(k):
            p.append(f"{pid}: last call {k} missing")
    for cid in mod.BANNER["featured"]:
        if cid not in ids:
            p.append(f"{pid}: banner features {cid}, not one of hers")
    for w in BANNED:
        for where, text in _texts(mod):
            if f" {w}" in f" {text.lower()} ":
                p.append(f"{pid} {where}: banned word {w!r}")
    return p


def _num_word(n: int) -> str:
    ones = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    tens = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty", 6: "sixty"}
    return tens[n // 10] + ("-" + ones[n % 10] if n % 10 else "")


def _texts(mod):
    ch = mod.CHAPTER
    yield "intro", ch["intro"]
    yield "outro", ch["outro"]
    for s in ch["stages"] + mod.EVENT["stages"]:
        for f in ("title", "goal", "intro", "win", "lose"):
            yield s["id"], s[f]
    for k, lines in mod.REPLIES.items():
        for ln in lines:
            yield f"reply {k}", ln
    for ln in list(mod.ORDER_LINES) + list(mod.MUTED_LINES):
        yield "rule line", ln
    for k in ("intro", "coda"):
        yield f"last call {k}", mod.LAST_CALL[k]
    for k, t in mod.BOND_SCENES.items():
        yield f"bond {k}", t
    for k in ("title", "blurb", "rule"):
        yield f"event {k}", mod.EVENT[k]
    for k in ("title", "blurb"):
        yield f"banner {k}", mod.BANNER[k]


def words(mod) -> int:
    return sum(_words(t) for _, t in _texts(mod)) + sum(_words(c.line) for c in mod.CARDS)
