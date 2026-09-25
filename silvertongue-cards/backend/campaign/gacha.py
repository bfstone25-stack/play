"""The gacha roll, shared by the server (ops/nutaku/suasion_f2p/suasion_economy.py) and the
pacing simulation, so the measured odds are the served odds. Weights common 70 / rare 25 /
epic 5 (the design's numbers); a ten-pull with no rare or better turns its last card rare;
the `every`-th pull without an epic is an epic.

A limited banner (campaign/packs) passes `featured`: when a roll lands on a rarity that has
featured cards, it is one of them `share` of the time (the odds of each rarity, and both
pities, are unchanged). Without `featured` the rng is called exactly as before."""
from __future__ import annotations


def roll(rng, pool: dict, weights: dict, n: int, since_epic: int, every: int,
         featured: list | None = None, share: float = 0.5):
    rar = [r for r in ("common", "rare", "epic") if pool.get(r)]
    out, got_rare = [], False
    for i in range(n):
        r = rng.choices(rar, weights=[weights[x] for x in rar])[0]
        pity = ""
        since_epic += 1
        if since_epic >= every and "epic" in pool:
            r, pity = "epic", "epic"
        elif n == 10 and i == n - 1 and not got_rare and r == "common":
            r, pity = "rare", "rare"
        if r == "epic":
            since_epic = 0
        got_rare = got_rare or r in ("rare", "epic")
        feat = [c for c in (featured or []) if c in pool[r]]
        if feat and rng.random() < share:
            out.append({"card": rng.choice(feat), "rarity": r, "pity": pity, "featured": True})
            continue
        out.append({"card": rng.choice(pool[r]), "rarity": r, "pity": pity})
    return out, since_epic
