"""End-to-end /say tests for AFTER HOURS, with the model stubbed.

Everything here is real except the two llama.cpp calls: the FastAPI route, the symbolic
engine, the sqlite state table, the CG emission and the branch-verification repair all run
as shipped. `_chat` is replaced by a deterministic stand-in because the actor and the judge
are the only parts that need a GPU, and the point of these tests is the parts that do not.

The stub judge answers YES exactly when the engine says the outcome is earned, which is
what the referee is supposed to do; the repair path in app.py therefore stays quiet, and a
`won` here means the symbolic state said so.

    ~/miniconda3/envs/hsm_lcr/bin/python -m pytest play/silvertongue-x/backend/test_say_e2e.py
"""
import os
import sys
import tempfile

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(HERE))))


@pytest.fixture()
def client(monkeypatch):
    os.environ["SILVERTONGUE_SCENARIO"] = "closing_time"
    tmp = tempfile.mkdtemp()
    import importlib
    sys.path.insert(0, os.path.dirname(HERE))
    app_mod = importlib.import_module("backend.app")
    importlib.reload(app_mod)
    app_mod.DB = os.path.join(tmp, "t.db")

    state = {"eligible": False}

    def fake_chat(system, messages, max_tokens=200, temperature=0.7):
        # The judge is the call whose user message asks YES/NO.
        if messages and "Answer YES or NO only" in messages[-1]["content"]:
            return "YES" if state["eligible"] else "NO"
        return "(in character)"

    monkeypatch.setattr(app_mod, "_chat", fake_chat)

    real_advance = app_mod._advance_state

    def spy(*a, **k):
        st = real_advance(*a, **k)
        state["eligible"] = bool(st["eligible"])
        return st

    monkeypatch.setattr(app_mod, "_advance_state", spy)

    from fastapi.testclient import TestClient
    return TestClient(app_mod.app)


def say(client, pid, message, difficulty="silver", hist=None):
    r = client.post("/say", json={"history": hist or [], "message": message, "lang": "en",
                                  "pid": pid, "difficulty": difficulty, "mode": "daily"})
    assert r.status_code == 200, r.text
    return r.json()


# NB: an earlier draft of this line read "...and you must be tired", which the engine
# scores as `entitlement` ("you must") and which therefore loses the duel outright. That is
# the fork's rule working, and a fair warning about how blunt the detectors are.
WIN = ["You have been on your feet since four. It has been a long day and you look tired.",
       "Thank you — I respect the rule, and I am not asking you to break it lightly.",
       "Would you stay and have one drink with me?"]


def test_duel_played_to_a_win_unlocks_tier3(client):
    hist, cg = [], []
    for line in WIN:
        r = say(client, "e2e-win", line, hist=hist)
        hist += [{"role": "user", "content": line},
                 {"role": "assistant", "content": r["reply"]}]
        cg += r["read"]["cg"]
    assert r["won"] is True, r
    assert r["read"]["phase"] == "breakthrough"
    assert "cg1_closing_time" in cg
    assert "cg3_closing_time" in cg               # tier 3 rides on the confirmed win


def test_a_threat_loses_at_every_difficulty_and_unlocks_nothing(client):
    for d in ("gentle", "silver", "gold"):
        hist, cg = [], []
        first = "Stay or I will report you and you will regret it."
        r = say(client, f"e2e-threat-{d}", first, difficulty=d)
        hist += [{"role": "user", "content": first}, {"role": "assistant", "content": r["reply"]}]
        cg += r["read"]["cg"]
        for line in WIN:
            r = say(client, f"e2e-threat-{d}", line, difficulty=d, hist=hist)
            hist += [{"role": "user", "content": line},
                     {"role": "assistant", "content": r["reply"]}]
            cg += r["read"]["cg"]
            assert r["won"] is False, (d, line, r)
        assert r["read"]["phase"] != "breakthrough", d
        assert cg == [], (d, cg)                  # not one plate, at any rank
