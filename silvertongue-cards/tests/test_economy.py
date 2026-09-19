"""shared/economy.py: energy arithmetic with a mocked clock, pity guarantees, idempotent grant.

    ~/miniconda3/envs/hsm_lcr/bin/python -m pytest play/silvertongue-cards/tests -q
"""
import os
import random
import sys
import tempfile

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from shared import economy as E   # noqa: E402


class Clock:
    def __init__(self, t=1_800_000_000.0):
        self.t = t
    def __call__(self):
        return self.t
    def tick(self, s):
        self.t += s


@pytest.fixture()
def eco():
    clock = Clock()
    e = E.Economy(os.path.join(tempfile.mkdtemp(), "eco.db"), clock=clock)
    e.clock_obj = clock
    return e


def test_energy_refill_arithmetic(eco):
    clk = eco.clock_obj
    assert eco.energy("u")["energy"] == E.ENERGY_POOL
    assert eco.spend_energy("u", 3)
    assert eco.energy("u")["energy"] == 12
    assert eco.energy("u")["next_in_s"] == E.ENERGY_REFILL_S
    clk.tick(E.ENERGY_REFILL_S - 1)
    assert eco.energy("u")["energy"] == 12
    assert eco.energy("u")["next_in_s"] == 1
    clk.tick(1)
    assert eco.energy("u")["energy"] == 13
    clk.tick(E.ENERGY_REFILL_S * 2 + 5)                 # two more, 5 s into the next
    e = eco.energy("u")
    assert e["energy"] == 15 and e["next_in_s"] == 0     # capped at the pool, clock idle
    clk.tick(E.ENERGY_REFILL_S * 10)
    assert eco.energy("u")["energy"] == 15               # never overflows
    assert not eco.spend_energy("u", 16)
    for _ in range(5):
        assert eco.spend_energy("u", 3)
    assert eco.energy("u")["energy"] == 0
    assert not eco.spend_energy("u", 3)
    clk.tick(E.ENERGY_REFILL_S * 3 + 7)
    assert eco.energy("u")["energy"] == 3                # partial pool keeps its own clock
    assert eco.energy("u")["next_in_s"] == E.ENERGY_REFILL_S - 7
    assert eco.refill_energy("u") == 15


def test_daily_flag_rolls_with_the_clock(eco):
    assert eco.daily_available("u")
    assert eco.use_daily("u")
    assert not eco.daily_available("u")
    assert not eco.use_daily("u")
    eco.clock_obj.tick(86400)
    assert eco.daily_available("u")


def test_gold_ledger(eco):
    assert eco.balance("u") == 0
    eco.add_gold("u", 100, "dev")
    assert eco.spend_gold("u", 40, "pull") == 60
    with pytest.raises(E.Insufficient):
        eco.spend_gold("u", 61, "pull")
    assert eco.balance("u") == 60
    assert sum(r["delta"] for r in eco.ledger("u")) == 60


POOL = {"common": [f"c{i}" for i in range(10)], "rare": [f"r{i}" for i in range(4)], "epic": ["e0", "e1"]}


def test_pity_rare_in_every_ten_pull(eco):
    # Force the weighted draw to always say "common"; the tenth card must still be rare.
    class Rng(random.Random):
        def choices(self, population, weights=None, k=1):
            return ["common"]
    for batch in range(3):
        got = eco.pull("u", POOL, 10, rng=Rng(batch))
        assert sum(1 for g in got if g["rarity"] in ("rare", "epic")) >= 1
        # the tenth is the rare pity, unless the epic pity (every 30th) claimed that slot
        assert got[9]["rarity"] in ("rare", "epic") and got[9]["pity"] in ("rare", "epic")
    assert [g["pity"] for g in got].count("epic") == 1        # pull 30 of 30


def test_pity_epic_every_thirty(eco):
    class Rng(random.Random):
        def choices(self, population, weights=None, k=1):
            return ["common"]
    rng = Rng(1)
    got = []
    for _ in range(60):
        got += eco.pull("u", POOL, 1, rng=rng)
    epics = [i for i, g in enumerate(got) if g["rarity"] == "epic"]
    assert epics == [29, 59]
    assert all(got[i]["pity"] == "epic" for i in epics)
    assert eco.pity_state("u")["epic_pity_in"] == 30
    # A natural epic resets the counter.
    class RngE(random.Random):
        def choices(self, population, weights=None, k=1):
            return ["epic"]
    eco.pull("u", POOL, 1, rng=RngE(2))
    assert eco.pity_state("u")["epic_pity_in"] == 30


def test_pull_weights_roughly_70_25_5(eco):
    rng = random.Random(7)
    got = []
    for _ in range(200):
        got += eco.pull("u", POOL, 10, rng=rng)
    n = len(got)
    common = sum(g["rarity"] == "common" for g in got) / n
    rare = sum(g["rarity"] == "rare" for g in got) / n
    epic = sum(g["rarity"] == "epic" for g in got) / n
    assert 0.60 < common < 0.76 and 0.20 < rare < 0.33 and 0.03 < epic < 0.09
    assert sum(eco.collection("u").values()) == n


def test_grant_is_idempotent_on_payment_id(eco):
    a = eco.grant("u", "gold_m", "np_1")
    assert a["ok"] and a["applied"]["gold"] == 1200 and not a["duplicate"]
    b = eco.grant("u", "gold_m", "np_1")
    assert b["duplicate"] and eco.balance("u") == 1200          # nothing applied twice
    c = eco.grant("u", "gold_s", "np_1")                          # same id, different sku: still the first
    assert c["duplicate"] and c["sku"] == "gold_m" and eco.balance("u") == 1200
    eco.spend_energy("u", 9)
    r = eco.grant("u", "energy_refill", "np_2")
    assert r["applied"]["energy"] == E.ENERGY_POOL and eco.energy("u")["energy"] == E.ENERGY_POOL
    p = eco.grant("u", "pull_10", "np_3")
    assert p["applied"]["pull_credits"] == 10 and eco.pity_state("u")["pull_credits"] == 10
    assert eco.pay_for_pull("u", 10) == "credits" and eco.pity_state("u")["pull_credits"] == 0
    assert eco.pay_for_pull("u", 1) == "gold" and eco.balance("u") == 1100
    ch = eco.grant("u", "char_teodora", "np_4")
    assert ch["applied"]["unlock"] == "char_teodora" and eco.has_unlock("u", "char_teodora")
    assert not eco.grant("u", "nope", "np_5")["ok"]
    with pytest.raises(ValueError):
        eco.grant("u", "gold_s", "")


def test_affection_is_wins(eco):
    assert eco.affection("u", "mara") == 0
    assert eco.add_win("u", "mara") == 1
    assert eco.add_win("u", "mara", double=True) == 3
    assert eco.affection_all("u") == {"mara": 3}
