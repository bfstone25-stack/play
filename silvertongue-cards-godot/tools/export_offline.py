#!/usr/bin/env python3
"""Bake the backend's tables into assets/offline/data.json, for the offline engine.

Why this exists, 2026-09-21
---------------------------
This client is a thin skin over `play/silvertongue-cards/backend`: every number on screen
came back from `/cards/*`. That is the right design when the backend is there, and it is
the reason the game was scored BROKEN on the play board — the driver photographed twelve
interactions and the frame never changed, because the build it drove was served as static
files with no backend anywhere. `/cards/state` returned nothing, `home.gd` renders
`state.scenarios` and that list was empty, so there was no opponent card to click. Nothing
was wrong with the input handling; there was simply nothing on screen to press.

That is not only a test-harness problem. The itch download runs on a player's machine with
no backend, and a Nutaku/itch web build reaches the gateway or nothing at all. So the fix
is the one the fork strategy already calls for: the game plays offline, and the backend
becomes an enhancement (a shared collection across clients) rather than a precondition.

The offline engine must not be a second, drifting set of rules. So the tables are not
retyped in GDScript — they are exported from the Python that owns them, here, and
`scripts/offline.gd` is only arithmetic over what this file writes. `tests/offline.tscn`
replays a scripted duel and compares it against the transcript this script also writes, so
a rule change in the backend that nobody re-exports fails a test instead of shipping.

    python3 play/silvertongue-cards-godot/tools/export_offline.py
"""
from __future__ import annotations

import importlib.util
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRODUCTS = ROOT.parent.parent
BACKEND = PRODUCTS / "play" / "silvertongue-cards"
# `silvertongue-cards` has a hyphen in it, so `backend` is not importable by name. Import
# it as a package from its path, which is also what the backend's own tests do.
sys.path.insert(0, str(BACKEND))
spec = importlib.util.spec_from_file_location(
    "stc_backend", BACKEND / "backend" / "__init__.py",
    submodule_search_locations=[str(BACKEND / "backend")])
pkg = importlib.util.module_from_spec(spec)
sys.modules["stc_backend"] = pkg
spec.loader.exec_module(pkg)
C = importlib.import_module("stc_backend.cards")
R = importlib.import_module("stc_backend.replies")
E = importlib.import_module("stc_backend.engine")
ECON = importlib.import_module("shared.economy")

# app.py's two, which are not worth importing FastAPI for.
LADDER = [(1, "cg1"), (3, "cg2"), (6, "cg3"), (10, "cg4")]
WIN_GOLD = {"gentle": 30, "silver": 45, "gold": 60}

OUT = ROOT / "assets" / "offline"


def scenarios() -> list:
    rows = json.loads((BACKEND / "backend" / "scenarios.json").read_text())
    rows = rows["scenarios"] if isinstance(rows, dict) else rows
    out = []
    for s in rows:
        who = C.SCENARIO_CHARACTER[s["id"]]
        rule = C.RULES[s["id"]]
        row = {
            "id": s["id"], "who": who, "name": C.CHARACTERS[who]["name"],
            "stars": s.get("difficulty", 3),
            "needs": {"paths": [sorted(p) for p in rule["paths"]], "help": sorted(rule["help"])},
            # The two ending beats are localised the same way as everything else below:
            # a dict of locale -> text, written only where the row carries it.
            "closing_beat": {}, "refusal_beat": {},
        }
        # Every localised field the backend's _field() would serve, under its locale key,
        # so the client can switch language with no round trip. A locale is written ONLY
        # where the source row actually carries it: STANDARD §7 — never offer a language
        # you did not translate.
        for key in ("title", "character", "goal", "story", "cg1_caption", "cg2_caption",
                    "cg3_caption", "closing_beat", "refusal_beat"):
            row[key] = {}
            for loc, suffix in (("en", "_en"), ("zh", "_zh"), ("zh-Hant", "_zht"), ("ja", "_ja")):
                v = s.get(key + suffix) or (s.get(key) if loc == "en" else "")
                if v:
                    row[key][loc] = v
        out.append(row)
    return out


def replies(table_by_scen: dict) -> dict:
    """(before, after, kind) tuples flattened to "before|after|kind" strings."""
    return {scen: {"|".join(k): v for k, v in table.items()}
            for scen, table in table_by_scen.items()}


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    data = {
        "_generated_by": "tools/export_offline.py — do not hand-edit",
        "tuning": {
            "deck_size": C.DECK_SIZE, "hand_size": C.HAND_SIZE, "max_turns": C.MAX_TURNS,
            "nerve_start": C.NERVE_START, "nerve_cap": C.NERVE_CAP,
            "nerve_per_turn": C.NERVE_PER_TURN, "wild_per_duel": C.WILD_PER_DUEL,
            "cost": C.COST, "duel_cost": ECON.DUEL_COST, "win_gold": WIN_GOLD,
            "energy_pool": ECON.ENERGY_POOL, "energy_refill_s": ECON.ENERGY_REFILL_S,
            "pull_price": {str(k): v for k, v in ECON.PULL_PRICE.items()},
            "gacha_weights": ECON.GACHA_WEIGHTS,
            "pity_rare_every": ECON.PITY_RARE_EVERY, "pity_epic_every": ECON.PITY_EPIC_EVERY,
        },
        "characters": C.CHARACTERS,
        "scenarios": scenarios(),
        "cards": [C.card_public(c.id, "ja") for c in C.CARDS],
        "starter": C.starter_collection(),
        "gacha": C.gacha_pool(),
        "ladder": [[n, t] for n, t in LADDER],
        "rules": {k: {"expert": v["expert"], "paths": [sorted(p) for p in v["paths"]],
                      "help": sorted(v["help"])}
                  for k, v in E.RULES.items() if k in C.SCENARIO_CHARACTER},
        # The wild path is the one place the client must read free text, so the detector's
        # word lists come across too. Only the keys the five fork scenarios can use.
        "common": {k: list(v) for k, v in E.COMMON.items()},
        "negative": {k: list(v) for k, v in E.NEGATIVE.items()},
        "replies": replies(R.R),
        # Her lines in Japanese, same keys, line for line. Written as its own table rather
        # than folded into `replies` so the offline engine's lookup and fallback code stays
        # exactly the shape it already is, and so a ja build that is missing a key falls
        # through to the English table instead of to nothing.
        "replies_ja": replies(getattr(R, "R_JA", {})),
    }
    (OUT / "data.json").write_text(json.dumps(data, ensure_ascii=False, indent=1))

    # A scripted duel, played by the Python that owns the rules, for tests/offline.tscn to
    # replay against the GDScript. A check nobody can read the result of is not a check:
    # this one fails loudly when the two engines disagree on any turn.
    rng = random.Random(7)
    deck = [c.id for c in C.SIGNATURE["mara"]] * 2
    d = C.new_duel("closing_time", "silver", deck, seed=7)
    script, turns = [], []
    while not d.over and len(turns) < 12:
        cid = d.hand[0]
        read = C.play_card(d, cid)
        script.append(cid)
        turns.append({"card": cid, "phase": read["phase_after"], "momentum": read["momentum"],
                      "evidence": read["evidence"], "eligible": read["eligible"],
                      "won": read["won"], "over": read["over"], "nerve": read["nerve"],
                      "kind": read["kind"]})
    (OUT / "transcript.json").write_text(json.dumps(
        {"scenario": "closing_time", "difficulty": "silver", "seed": 7,
         "deck": deck, "script": script, "turns": turns}, indent=1))
    print("wrote %s (%d cards, %d scenarios) and a %d-turn transcript"
          % (OUT / "data.json", len(data["cards"]), len(data["scenarios"]), len(turns)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
