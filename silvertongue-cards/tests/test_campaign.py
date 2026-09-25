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
    assert K.BASE_COUNT == 144 and K.STORY_COUNT == 72
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


# --- after launch: update packs, events, banners, the missing pages (2026-09-24) ------------
from backend.campaign import packs as PK  # noqa: E402
from backend.campaign import gacha as GA  # noqa: E402
from backend.campaign import ledger as LG  # noqa: E402

DAY = 86400.0


def test_packs_shape_and_indices():
    assert [m.CHAPTER["id"] for m in PK.PACKS] == ["p1", "p2", "p3", "p4", "p5", "p6"]
    i = K.BASE_COUNT
    for ch in K.PACK_CHAPTERS:
        assert len(ch["stages"]) >= 12 and len(ch["last_call"]) == len(ch["stages"])
        for s in ch["stages"] + ch["last_call"]:
            assert s["index"] == i and K.STAGES[i] is s      # appended, never moving a saved index
            i += 1
        boss = ch["stages"][-1]
        assert boss["is_boss"] and boss["mods"].get("boss") and set(boss["mods"]) - {"boss", "turns"}
    assert len(K.STAGES) == i
    assert all(len(e["stages"]) == 5 for e in K.EVENTS) and len(K.EVENTS) == 9


def test_pack_lint_catches_a_dishonest_card_and_a_long_line():
    m = PK.BY_PACK["p1"]
    from backend.engine import COMMON
    assert PK.lint(m, set(COMMON), set()) == []
    bad = C.Card("odile_x", "odile", "Slowly. Will you?", ("calm_action",), (), "rare", "case")
    m.CARDS.append(bad)
    key = ("guarded", "guarded", "path")
    m.REPLIES[key].append("word " * 41)
    try:
        probs = PK.lint(m, set(COMMON), set())
        assert any("odile_x" in p for p in probs) and any("41 words" in p for p in probs), probs
    finally:
        m.CARDS.remove(bad)
        m.REPLIES[key].pop()


def test_every_pack_and_event_stage_can_be_won():
    coll = {c.id: 3 for c in K.ALL_CARDS if c.character != "house"}
    stars = {cid: 3 for cid in coll}
    for s in list(K.STAGES[K.BASE_COUNT:]) + list(K.EVENT_STAGES.values()):
        assert any(_play(s, coll, stars, seed)[0]["won"] for seed in range(12)), s["id"]


def test_schedule_releases_on_the_server_clock():
    sched = {"launch": "2026-11-01"}
    t0 = PK._ts("2026-11-01")
    live = PK.schedule(sched, t0 + 41 * DAY)
    assert not live["packs"]["p1"]["released"] and not live["events"]["ev_p1"]["active"]
    live = PK.schedule(sched, t0 + 42 * DAY + 1)
    assert live["packs"]["p1"]["released"] and not live["packs"]["p1"]["second_half_open"]
    assert live["events"]["ev_p1"]["active"] and live["banners"]["bn_p1"]["active"]
    assert not live["packs"]["p2"]["released"]
    live = PK.schedule(sched, t0 + 49 * DAY + 1)
    assert live["packs"]["p1"]["second_half_open"]
    live = PK.schedule(sched, t0 + 56 * DAY + 1)
    assert live["packs"]["p1"]["released"] and not live["events"]["ev_p1"]["active"]    # it stays; its event ends
    assert live["events"]["ev_p2"]["active"]
    assert PK.schedule({}, t0 + 400 * DAY)["packs"]["p1"]["released"] is False          # no launch, nothing
    off = PK.schedule({"launch": "2026-11-01", "packs": {"p1": {"on": False}}}, t0 + 50 * DAY)
    assert not off["packs"]["p1"]["released"] and not off["events"]["ev_p1"]["active"]
    early = PK.schedule({"packs": {"p3": {"on": True}}}, t0)
    assert early["packs"]["p3"]["released"] and early["packs"]["p3"]["second_half_open"]
    assert PK.schedule(sched, t0 + 7 * DAY + 1)["events"]["ev_room_service"]["active"]


def test_pack_gates():
    stars = [0] * len(K.STAGES)
    s1 = K.BY_STAGE["p1s01"]
    assert P.gate(s1, stars, {}, {})["kind"] == "unreleased"
    assert P.gate(s1, stars, {}, {"released": ["p1"]})["kind"] == "locked"          # the Long Night first
    for i in range(K.STORY_COUNT):
        stars[i] = 1
    g = {"released": ["p1", "p2"], "second_half": ["p1"], "bond": {"p1": 18}}
    assert P.gate(s1, stars, {}, g) is None
    assert P.gate(K.BY_STAGE["p2s01"], stars, {}, g)["kind"] == "locked"            # pack 1's boss first
    assert P.gate(K.BY_STAGE["p1s02"], stars, {}, g)["kind"] == "locked"
    for s in K.BY_STAGE["p1s01"], *K.PACK_CHAPTERS[0]["stages"][1:11]:
        stars[s["index"]] = 1
    assert P.gate(K.BY_STAGE["p1s12"], stars, {"odile": 3}, g)["kind"] == "bond"
    assert P.gate(K.BY_STAGE["p1s12"], stars, {"odile": 18}, g) is None
    assert P.gate(K.BY_STAGE["p1s07"], stars, {}, {**g, "second_half": []})["kind"] == "opens"
    assert P.gate(K.BY_STAGE["p1s01L"], stars, {}, g)["kind"] == "locked"


def test_the_pool_holds_a_pack_only_once_released():
    base = K.gacha_pool(set())
    assert not any(cid.startswith("odile") for r in base.values() for cid in r)
    assert any(cid.startswith("odile") for r in K.gacha_pool({"p1"}).values() for cid in r)
    assert base == K.GACHA_POOL


def test_banner_share_and_unchanged_standard_roll():
    import random as R
    pool = K.gacha_pool({"p1"})
    feat = PK.BY_PACK["p1"].BANNER["featured"]
    a, _ = GA.roll(R.Random(5), pool, {"common": 70, "rare": 25, "epic": 5}, 10, 0, 30)
    b, _ = GA.roll(R.Random(5), pool, {"common": 70, "rare": 25, "epic": 5}, 10, 0, 30, None)
    assert a == b                                        # no banner: the rng is used exactly as before
    got, _ = GA.roll(R.Random(9), pool, {"common": 70, "rare": 25, "epic": 5}, 4000, 0, 30, feat, 0.5)
    hi = [g for g in got if g["rarity"] in ("rare", "epic")]
    share = sum(1 for g in hi if g["card"] in feat) / len(hi)
    assert 0.45 < share < 0.6, share                      # half, plus the odd natural hit
    assert all(g["card"] in feat for g in got if g.get("featured"))


def test_ledger_pages_one_per_chapter_and_the_last_is_about_you():
    assert LG.audit() == []
    assert list(LG.ORDER) == [c["id"] for c in K.CHAPTERS] + [c["id"] for c in K.PACK_CHAPTERS]
    assert "about you" in LG.PAGES["p6"]["text"]
    for w in ("blackmail", "bribe", "threat"):
        assert all(w not in p["text"].lower() for p in LG.PAGES.values())
