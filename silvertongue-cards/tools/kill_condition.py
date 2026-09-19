"""§3 kill condition (ops/adult_forks/silvertongue_cards.md): is a gold duel lock-and-key?

Simulates random draws on gold (10 turns) with a greedy player who knows the RULES row and
plays the first affordable card that adds a needed signal, else the cheapest filler. Three
deck shapes, each measured over N random shuffles at several deck sizes:

  path_only        the two path cards, no support card anywhere      -> must be ~0 on gold
  path+1support    two path cards + one support card + fillers        -> the design's question
  path+2support    two path cards + two support copies + fillers      -> what buying more cards buys

Fillers are other characters' commons that carry none of this scenario's path/help signals.
The design wants path+1support in roughly 10–35 %: "a deck cannot guarantee the path in ten
turns without support cards" — and, read the other way, a deck *with* the support card
should still have to draw it.

    ~/miniconda3/envs/hsm_lcr/bin/python tools/kill_condition.py [--n 200] [--sizes 8,12,16,20]
"""
from __future__ import annotations

import argparse
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from backend import cards as C                                  # noqa: E402
from backend.engine import RULES                                # noqa: E402


def fillers_for(scen: str) -> list:
    rule = RULES[scen]
    avoid = set().union(*rule["paths"]) | set(rule["help"])
    who = C.SCENARIO_CHARACTER[scen]
    return [c.id for c in C.CARDS if c.character not in (who, "house") and c.rarity == "common"
            and not (set(c.signals) & avoid)]


def build(scen: str, support_copies: int, size: int, rng: random.Random) -> list:
    rule = RULES[scen]
    path = sorted(rule["paths"][0]); help_ = sorted(rule["help"])
    who = C.SCENARIO_CHARACTER[scen]
    mine = [c for c in C.SIGNATURE[who] if c.rarity == "common"]
    deck = []
    for sig in path:            # one common per path signal
        deck.append(next(c.id for c in mine if c.signals == (sig,)))
    sup = [c.id for c in mine if c.signals == (help_[0],)]
    if not sup:                 # some casts carry the help signal only on rares
        sup = [c.id for c in C.SIGNATURE[who] if help_[0] in c.signals and not (set(c.signals) & set(path))]
    deck += [sup[0]] * support_copies
    pool = fillers_for(scen)
    while len(deck) < size:
        deck.append(rng.choice(pool))
    return deck


def play_greedy(scen: str, deck: list, seed: int) -> bool:
    d = C.new_duel(scen, "gold", deck, seed=seed)
    rule = RULES[scen]
    need_path = set(rule["paths"][0]); need_help = set(rule["help"])
    while not d.over:
        have = set(d.state.get("evidence", []))
        missing = (need_path - have) | (set() if need_help & have else need_help)
        hand = [C.BY_ID[i] for i in d.hand]
        useful = [c for c in hand if (set(c.signals) & missing) and c.cost <= d.nerve and not c.harms]
        useful.sort(key=lambda c: (-len(set(c.signals) & missing), c.cost))
        if useful:
            pick = useful[0]
        else:
            fill = [c for c in hand if c.cost <= d.nerve and not c.harms]
            if not fill:
                break
            pick = min(fill, key=lambda c: c.cost)
        C.play_card(d, pick.id)
    return d.won


def measure(n: int, sizes: list) -> dict:
    out = {}
    for size in sizes:
        C.DECK_SIZE = size
        for shape, copies in (("path_only", 0), ("path+1support", 1), ("path+2support", 2)):
            wins = 0; total = 0
            for scen in RULES:
                if scen not in C.SCENARIO_CHARACTER:
                    continue
                for i in range(n):
                    rng = random.Random(size * 100003 + copies * 1009 + i)
                    deck = build(scen, copies, size, rng)
                    wins += play_greedy(scen, deck, seed=i * 7 + size)
                    total += 1
            out[(size, shape)] = wins / total
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=200)
    ap.add_argument("--sizes", default="8,12,16,20")
    a = ap.parse_args()
    sizes = [int(x) for x in a.sizes.split(",")]
    res = measure(a.n, sizes)
    print(f"gold, {a.n} random draws per scenario x 5 scenarios, hand {C.HAND_SIZE}, nerve start {C.NERVE_START}/cap {C.NERVE_CAP}")
    print(f"{'deck':>5} {'path_only':>10} {'path+1sup':>10} {'path+2sup':>10}")
    for size in sizes:
        print(f"{size:>5} {res[(size,'path_only')]:>10.1%} {res[(size,'path+1support')]:>10.1%} {res[(size,'path+2support')]:>10.1%}")
