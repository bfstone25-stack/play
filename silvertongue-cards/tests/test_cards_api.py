"""Scripted duels through the API, with no model anywhere.

Everything is real: the FastAPI routes, the parent's engine, the reply table, the economy.
Decks are set explicitly through /cards/deck so a test can hold known cards; the shuffle is
the only randomness and the tests draw until the card they want is in hand.

    ~/miniconda3/envs/hsm_lcr/bin/python -m pytest play/silvertongue-cards/tests -q
"""
import importlib
import os
import sys
import tempfile

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)


@pytest.fixture()
def client(monkeypatch):
    monkeypatch.setenv("ST_CARDS_DATA", tempfile.mkdtemp())
    monkeypatch.setenv("SILVERTONGUE_SCENARIO", "closing_time")
    for m in [m for m in sys.modules if m.startswith("backend")]:
        del sys.modules[m]
    app_mod = importlib.import_module("backend.app")
    from fastapi.testclient import TestClient
    c = TestClient(app_mod.app)
    c.app_mod = app_mod
    return c


def give(client, pid, cards):
    """Hand a test player exactly these cards (on top of the starter set)."""
    eco = client.app_mod.ECO
    client.get(f"/cards/state?pid={pid}")          # creates the player + starter collection
    for cid, n in cards.items():
        eco.give_card(pid, cid, n)


def set_deck(client, pid, scenario, deck):
    r = client.post("/cards/deck", json={"pid": pid, "scenario": scenario, "deck": deck}).json()
    assert r.get("ok"), r
    return r["deck"]


def start(client, pid, scenario, difficulty, daily=False):
    r = client.post("/cards/start", json={"pid": pid, "scenario": scenario, "difficulty": difficulty, "daily": daily}).json()
    assert r.get("ok"), r
    return r


def play(client, pid, card, text=""):
    return client.post("/cards/play", json={"pid": pid, "card": card, "text": text}).json()


def play_until(client, pid, wanted, filler_ok=lambda c: True):
    """Play cards from `wanted` in order as they come into hand; when none is in hand and
    affordable, play the cheapest affordable non-coercion filler. Returns the final response."""
    r = client.get(f"/cards/state?pid={pid}").json()
    d = r["duel"]
    last = None
    remaining = list(wanted)
    while d and not d["over"]:
        hand = d["hand"]
        pick = next((c for c in hand if remaining and c["id"] == remaining[0] and c["cost"] <= d["nerve"]), None)
        if pick:
            remaining.pop(0)
        else:
            fill = [c for c in hand if not c["harms"] and c["cost"] <= d["nerve"] and c["id"] not in remaining and filler_ok(c)]
            if not fill:
                fill = [c for c in hand if not c["harms"] and c["cost"] <= d["nerve"]]
            pick = min(fill, key=lambda c: c["cost"])
        last = play(client, pid, pick["id"])
        assert "error" not in last, last
        d = last["duel"]
    return last


# --- faces and tables --------------------------------------------------------------------
def test_card_faces_are_honest():
    from backend import cards as C
    for c in C.CARDS:
        assert C.face_matches_engine(c), (c.id, c.line)
    assert len(C.CARDS) == 64 and len(C.SIGNATURE["mara"]) == 12
    for who in C.CHARACTERS:
        rar = [c.rarity for c in C.SIGNATURE[who]]
        assert rar.count("common") == 6 and rar.count("rare") == 4 and rar.count("epic") == 2
    assert sorted(c.harms[0] for c in C.HOUSE) == ["bribe", "entitlement", "insult", "threat"]


def test_reply_table_complete_and_short():
    from backend import replies as R
    assert R.audit() == []
    for scen in ("closing_time", "the_key", "life_model", "house_rule", "last_night"):
        for before in ("guarded", "engaged", "wavering"):
            for after in ("guarded", "engaged", "wavering", "breakthrough"):
                for kind in ("path", "case", "ask", "wild", "stale"):
                    assert R.reply(scen, before, after, kind) != "…"
        assert R.reply(scen, "guarded", "guarded", "coercion") and R.refusal_line(scen)


def test_no_model_in_the_request_path():
    """The card game must never import or call the parent's llama path."""
    import backend.app as A
    src = open(A.__file__).read()
    assert "llm_claim" not in src and "LLAMACPP" not in src and "chat/completions" not in src
    assert not hasattr(A, "_chat")
    assert not any(getattr(r, "path", "") == "/say" for r in A.app.routes)
    for mod in ("backend.cards", "backend.replies", "shared.economy"):
        msrc = open(sys.modules[mod].__file__).read()
        assert "urllib" not in msrc and "subprocess" not in msrc and "llama" not in msrc.lower(), mod
    assert A.health()["llm"] is False


# --- winning decks on every difficulty --------------------------------------------------
@pytest.mark.parametrize("difficulty", ["gentle", "silver", "gold"])
def test_winning_deck_mara(client, difficulty):
    pid = f"test_win_{difficulty}"
    give(client, pid, {"mara_01": 2, "mara_03": 2, "mara_05": 2})
    deck = ["mara_01", "mara_03", "mara_05"] * 2 + ["ines_03", "ines_04", "sanne_01", "sanne_02", "teodora_01", "teodora_02"]
    set_deck(client, pid, "closing_time", deck)
    s = start(client, pid, "closing_time", difficulty)
    assert s["duel"]["max_turns"] == {"gentle": 18, "silver": 15, "gold": 10}[difficulty]
    assert s["duel"]["turns"] == 0 and len(s["duel"]["hand"]) == 3
    r = play_until(client, pid, ["mara_01", "mara_03", "mara_05"])
    assert r["end"]["won"] is True, r["end"]
    assert r["read"]["phase_after"] == "breakthrough"
    assert "cg3_closing_time" in r["read"]["cg"]
    rw = r["end"]["reward"]
    assert rw["affection"] == 1 and rw["gold"] == {"gentle": 30, "silver": 45, "gold": 60}[difficulty]
    assert rw["cg_unlocked"] == ["cg1_closing_time"]
    assert rw["drop"]["character"] == "mara"
    assert r["end"]["beat"].startswith("She locks the shutter")
    st = client.get(f"/cards/state?pid={pid}").json()
    assert st["duel"] is None and st["economy"]["energy"]["energy"] == 12
    assert st["affection"]["mara"]["wins"] == 1


def test_gold_needs_support_gentle_does_not(client):
    """Same two path cards: a win on gentle, not on gold. required_support is the engine's."""
    for difficulty, expect in (("gentle", True), ("gold", False)):
        pid = f"test_support_{difficulty}"
        give(client, pid, {"mara_01": 3, "mara_03": 3})
        set_deck(client, pid, "closing_time", ["mara_01", "mara_03"] * 3 + ["ines_03", "ines_04", "sanne_01", "sanne_02"])
        start(client, pid, "closing_time", difficulty)
        r = play_until(client, pid, ["mara_01", "mara_03"])
        assert r["end"]["won"] is expect, (difficulty, r["end"])
        if not expect:
            assert r["end"]["turns"] == 10 and r["refusal_line"]


# --- the trap --------------------------------------------------------------------------
def test_coercion_card_makes_duel_unwinnable(client):
    pid = "test_coerce"
    give(client, pid, {"house_threat": 1})
    # One threat, eight fillers, then the winning path. The fillers are played first, so the
    # threat is on the table before the path can complete (gentle needs only two path cards).
    fillers = ["ines_03", "ines_04", "sanne_01", "sanne_02", "teodora_01", "teodora_02", "yuenha_01", "yuenha_02"]
    set_deck(client, pid, "closing_time", ["house_threat"] + fillers + ["mara_01", "mara_03", "mara_05"])
    start(client, pid, "closing_time", "gentle")
    r = play_until(client, pid, ["house_threat", "mara_01", "mara_03", "mara_05"])
    assert "threat" in r["duel"]["harms"]
    assert r["end"]["won"] is False and r["end"]["harmed"] is True
    assert r["duel"]["harms"] == ["threat"]
    assert r["end"]["turns"] == 18            # she kept talking to the end
    assert r["read"]["cg"] == []              # and nothing unlocked
    st = client.get(f"/cards/affection?pid={pid}").json()
    assert st["affection"]["mara"]["wins"] == 0


def test_coercion_reply_is_the_closed_line(client):
    pid = "test_coerce2"
    give(client, pid, {"house_insult": 3})
    set_deck(client, pid, "closing_time", ["house_insult"] * 3 + ["mara_01", "mara_03", "mara_05"])
    start(client, pid, "closing_time", "silver")
    st = client.get(f"/cards/state?pid={pid}").json()["duel"]
    while not any(c["id"] == "house_insult" for c in st["hand"]):
        st = play(client, pid, min([c for c in st["hand"] if not c["harms"]], key=lambda c: c["cost"])["id"])["duel"]
    r = play(client, pid, "house_insult")
    assert r["read"]["kind"] == "coercion" and "off the table" in r["reply"]
    assert r["duel"]["eligible"] is False and r["duel"]["harms"] == ["insult"]


# --- wild ------------------------------------------------------------------------------
def test_wild_card_scores_via_decompose(client):
    from backend.engine import decompose
    pid = "test_wild"
    give(client, pid, {"mara_03": 2, "mara_05": 2})
    set_deck(client, pid, "closing_time", ["mara_03", "mara_05"] * 2 + ["ines_03", "sanne_01"])
    start(client, pid, "closing_time", "gentle")
    r = play(client, pid, "wild", "Long day for you too.")
    assert r["error"].startswith("needs 2 nerve")           # not affordable on turn 1
    st = r["duel"]
    r = play(client, pid, min([c for c in st["hand"]], key=lambda c: c["cost"])["id"])   # any turn
    assert r["duel"]["nerve"] == 2                            # 1 - 1 + 2
    line = "Long day for you too, I'd guess."
    r = play(client, pid, "wild", line)
    assert "error" not in r
    assert r["read"]["kind"] == "wild" and r["read"]["card"] == "wild"
    assert r["read"]["signals"] == decompose(line, "closing_time")["signals"] == ["warmth"]
    assert "warmth" in r["duel"]["evidence"] and r["duel"]["wild_left"] == 0
    assert play(client, pid, "wild", "again")["error"] == "wild already played"
    # A typed threat is a threat.
    pid2 = "test_wild2"
    give(client, pid2, {})
    start(client, pid2, "closing_time", "gentle")
    st = client.get(f"/cards/state?pid={pid2}").json()["duel"]
    play(client, pid2, min([c for c in st["hand"] if not c["harms"]], key=lambda c: c["cost"])["id"])
    r = play(client, pid2, "wild", "Pour it or else I'll report you.")
    assert r["read"]["kind"] == "coercion" and r["duel"]["harms"] == ["threat"]


# --- energy, daily, gacha, deck through the API ---------------------------------------
def test_energy_gate_and_daily_free(client):
    pid = "test_energy"
    give(client, pid, {})
    for _ in range(5):
        s = start(client, pid, "closing_time", "gold")
        client.post("/cards/forfeit", json={"pid": pid})
    st = client.get(f"/cards/state?pid={pid}").json()
    assert st["economy"]["energy"]["energy"] == 0
    r = client.post("/cards/start", json={"pid": pid, "scenario": "closing_time", "difficulty": "gold"}).json()
    assert r["error"] == "not enough energy"
    d = client.get(f"/cards/daily?pid={pid}").json()
    assert d["scen"]["id"] == "closing_time" and d["available"] is True
    s = start(client, pid, "", "gold", daily=True)
    assert s["duel"]["daily"] and s["duel"]["scenario"] == "closing_time"
    client.post("/cards/forfeit", json={"pid": pid})
    r = client.post("/cards/start", json={"pid": pid, "scenario": "", "difficulty": "gold", "daily": True}).json()
    assert r["error"] == "daily already played today"


def test_daily_pays_double_and_percentile(client):
    pid = "test_daily2"
    give(client, pid, {"mara_01": 2, "mara_03": 2, "mara_05": 2})
    set_deck(client, pid, "closing_time", ["mara_01", "mara_03", "mara_05"] * 2 + ["ines_03", "ines_04"])
    start(client, pid, "", "gentle", daily=True)
    r = play_until(client, pid, ["mara_01", "mara_03", "mara_05"])
    assert r["end"]["won"] and r["end"]["reward"]["affection_gain"] == 2
    d = client.get(f"/cards/daily?pid={pid}").json()
    assert d["my_turns"] == r["end"]["turns"] and d["percentile"] == 100 and d["solved_today"] == 1
    assert client.get(f"/cards/percentile?turns={r['end']['turns']}&scenario=closing_time").json()["percentile"] == 100


def test_pull_costs_gold_and_dev_gold(client):
    pid = "test_pull"
    give(client, pid, {})
    r = client.post("/cards/pull", json={"pid": pid, "n": 10}).json()
    assert "need 900 gold" in r["error"]
    assert client.post("/cards/dev/gold", json={"pid": pid, "amount": 1000}).json()["gold"] == 1000
    r = client.post("/cards/pull", json={"pid": pid, "n": 10}).json()
    assert r["ok"] and len(r["cards"]) == 10 and r["paid"] == "gold" and r["economy"]["gold"] == 100
    assert any(c["rarity"] in ("rare", "epic") for c in r["cards"])
    r = client.post("/cards/pull", json={"pid": pid, "n": 1}).json()
    assert r["ok"] and r["economy"]["gold"] == 0
    assert "need 100 gold" in client.post("/cards/pull", json={"pid": pid, "n": 1}).json()["error"]


def test_deck_must_be_owned(client):
    pid = "test_deck"
    give(client, pid, {})
    r = client.post("/cards/deck", json={"pid": pid, "scenario": "closing_time", "deck": ["sanne_12"] * 5}).json()
    assert r["ok"] is False
    r = client.post("/cards/deck", json={"pid": pid, "scenario": "closing_time", "deck": ["mara_01", "mara_01", "mara_01", "mara_03"]}).json()
    assert r["deck"] == ["mara_01", "mara_01", "mara_03"]       # starter owns two copies, not three
    d = client.get(f"/cards/deck?pid={pid}&scenario=closing_time").json()
    assert d["deck"] == ["mara_01", "mara_01", "mara_03"] and d["deck_size"] == 18


def test_affection_ladder_thresholds(client):
    pid = "test_ladder"
    app = client.app_mod
    give(client, pid, {})
    app.ECO.add_win(pid, "ines")
    app.ECO.add_win(pid, "ines")
    app.ECO.add_win(pid, "ines")
    a = client.get(f"/cards/affection?pid={pid}").json()["affection"]["ines"]
    assert a["unlocked"] == ["cg1_the_key", "cg2_the_key"]
    assert [s["earned"] for s in a["ladder"]] == [True, True, False, False]
    assert a["ladder"][3]["placeholder"] is True and a["ladder"][3]["at"] == 10


def test_identity_account_cookie(client):
    r = client.post("/cards/auth/register", json={"handle": "blaze_t", "password": "passphrase1", "pid": "guest1"}).json()
    assert r["ok"]
    assert client.get("/cards/auth/me").json()["authenticated"]
    st = client.get("/cards/state?pid=guest1").json()
    assert st["player"].startswith("acct:")
    client.post("/cards/auth/logout")
    assert client.get("/cards/state?pid=guest1").json()["player"] == "guest1"
