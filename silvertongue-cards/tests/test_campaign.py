"""The campaign (backend/campaign): words, rules and the duel the server replays.

    python -m pytest -q play/silvertongue-cards/tests/test_campaign.py
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend import campaign as K  # noqa: E402
from backend import cards as C  # noqa: E402
from backend.campaign import duel as D  # noqa: E402
from backend.campaign import progress as P  # noqa: E402
from backend.campaign.voices import CELESTE_CARDS  # noqa: E402


def test_shape():
    assert len(K.CHAPTERS) == 6 and all(len(ch["stages"]) == 12 for ch in K.CHAPTERS)
    assert len(K.STAGES) == 144 and K.STORY_COUNT == 72
    assert all(ch["stages"][-1]["is_boss"] and ch["stages"][-1]["mods"].get("boss") for ch in K.CHAPTERS)
    assert sum(1 for s in K.STAGES[:72] if s["who"] == "celeste") == 12      # the rival: once a chapter, then the Long Night


def test_audit_clean_and_catches_a_dishonest_face():
    assert K.audit() == []
    bad = C.Card("celeste_x", "celeste", "You're a legend. Will you?", ("specific_praise",), (), "rare", "case")
    CELESTE_CARDS.append(bad)
    try:
        assert any("celeste_x" in p for p in K.audit())      # claims one signal, carries two
    finally:
        CELESTE_CARDS.remove(bad)


def test_words():
    wc = K.word_counts()
    assert wc["total"] > 9000, wc


def test_engine_rows_registered_not_edited():
    for s in K.STAGES:
        assert s["rule_key"] in C.RULES
    assert C.RULES["closing_time"]["paths"] == [{"warmth", "respect"}]


def _play(stage, coll, stars, seed, skill=1.0):
    d = D.new(stage, D.auto_deck(stage, coll, stars), stars, seed)
    rng = random.Random(seed)
    plays = []
    while not d["over"]:
        c = D.greedy_choice(stage, d, skill, rng)
        plays.append({"card": c})
        D.play(stage, d, c)
    return d, plays


def test_every_stage_can_be_won_with_a_strong_collection():
    coll = {c.id: 3 for c in K.ALL_CARDS if c.character != "house"}
    stars = {cid: 3 for cid in coll}
    for s in K.STAGES:
        assert any(_play(s, coll, stars, seed)[0]["won"] for seed in range(12)), s["id"]


def test_replay_is_deterministic_and_rejects_forgery():
    s = K.BY_STAGE["c1s03"]
    coll, stars = C.starter_collection(), {}
    d, plays = _play(s, coll, stars, 7)
    deck = D.auto_deck(s, coll, stars)
    rep = D.replay(s, deck, stars, 7, plays)
    assert rep["ok"] and rep["duel"]["won"] == d["won"] and rep["duel"]["turns"] == d["turns"]
    forged = D.replay(s, deck, stars, 7, [{"card": "mara_11"}] * 3)
    assert not forged["ok"]


def test_resolve_is_what_ends_a_duel():
    s = K.BY_STAGE["c1s12"]
    d = D.new(s, ["mara_11"] * 18, {}, 1)
    d["nerve"] = 3
    D.play(s, d, "mara_11")            # completes her path and her support in one card
    assert d["state"]["eligible"] and not d["won"] and d["resolve"] > 0


def test_order_rule_closes_the_duel():
    s = K.BY_STAGE["c4s12"]
    d = D.new(s, ["teodora_04"] * 18, {}, 1)
    r = D.play(s, d, "teodora_04")      # an exchange before any accountability
    assert r["kind"] == "order" and d["over"] and not d["won"]


def test_gates():
    stars = [0] * 144
    assert P.gate(K.STAGES[0], stars, {}, {}) is None
    assert P.gate(K.STAGES[1], stars, {}, {})["kind"] == "locked"
    assert P.gate(K.BY_STAGE["c1s01L"], stars, {}, {})["kind"] == "locked"
    for i in range(11):
        stars[i] = 1
    assert P.gate(K.STAGES[11], stars, {"mara": 3}, {"bond": {"c1": 12}})["kind"] == "bond"
    assert P.gate(K.STAGES[11], stars, {"mara": 12}, {"bond": {"c1": 12}}) is None
    stars[11] = 1
    assert P.gate(K.STAGES[12], stars, {}, {"standing": {"c2": 20}})["kind"] == "standing"
    assert P.gate(K.BY_STAGE["c1s01L"], stars, {}, {}) is None
