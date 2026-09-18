"""SILVERTONGUE: AFTER HOURS — the two invariants the fork exists for.

    ~/miniconda3/envs/hsm_lcr/bin/python -m pytest play/silvertongue-x/backend/test_after_hours.py

1. Coercion loses the duel outright, at every difficulty. In the base game the
   no-coercion clause applies only at gold; here it applies everywhere, and because
   `harms` is cumulative it never clears for the rest of that conversation.
2. No CG unlocks from playtime. The selector may read phase/eligible/harms and must
   never read `turns` or `momentum`, both of which sit in the same state dict.
"""
import inspect
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import persuasion_engine as pe  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SCEN = json.load(open(os.path.join(HERE, "scenarios.json")))
DIFFS = ["gentle", "silver", "gold"]

# A line that lands the full path plus the supporting signal for each scenario, so the
# only difference between the clean run and the coercive run is the coercion.
WINNING = {
    # warmth + respect + direct_request
    "closing_time": "It has been such a long day for you and I respect the rule completely — would you stay for one drink?",
    # empathy + accountability + respect
    "the_key": "I hear how much this hurt you and it was my fault, I was wrong to leave, and I am sorry — please stay tonight.",
    # craft + respect + precision
    "life_model": "The temperature in the left third is exactly the problem and I respect the technique enormously — only if you want to, put the brush down.",
    # evidence + precision + direct_request
    "house_rule": "Because the invoice is exactly the thing in the way, I will pay it now and hire someone else next quarter — would you set the rule aside?",
    # empathy + exchange + accountability
    "last_night": "I understand how hard the leaving feels for you; in return I can offer no scene at the airport, and it is my fault I waited this long.",
}
# One coercive sentence per NEGATIVE category.
COERCION = {
    "threat": "Stay or I will report you and you will regret it.",
    "bribe": "I will pay you extra, take the cash, consider it a bribe.",
    "insult": "Do not be stupid, you are being an idiot about this.",
    "entitlement": "You must do this, it is your job and you owe me.",
}


def play(scen, difficulty, lines):
    state = {}
    for line in lines:
        state = pe.advance(state, line, scen, difficulty)
    return state


def test_clean_line_wins_at_every_difficulty():
    """Control: without coercion the same sentence is eligible everywhere."""
    for scen, line in WINNING.items():
        for d in DIFFS:
            st = play(scen, d, [line])
            assert st["eligible"], (scen, d, st["evidence"])
            assert st["phase"] == "breakthrough"


def test_coercion_loses_at_every_difficulty():
    """The fork's whole point: one coercive move disqualifies the conversation."""
    for scen, line in WINNING.items():
        for d in DIFFS:
            for kind, bad in COERCION.items():
                st = play(scen, d, [bad, line])
                assert st["harms"], (scen, d, kind, "coercion was not even detected")
                assert not st["eligible"], (scen, d, kind)
                assert st["phase"] != "breakthrough", (scen, d, kind)


def test_coercion_never_clears_within_the_duel():
    """`harms` is cumulative, so ten good turns after one threat still lose."""
    for d in DIFFS:
        st = play("closing_time", d, [COERCION["threat"]] + [WINNING["closing_time"]] * 10)
        assert not st["eligible"]
        assert st["turns"] == 11          # the duel continues; it just cannot be won


def test_base_game_behaviour_is_what_we_changed():
    """Guard against a silent revert: the fork's clause must not be rank-conditional."""
    src = inspect.getsource(pe.advance)
    assert 'eligible = path_complete and support >= required_support and penalty == 0' in src
    assert 'difficulty != "gold"' not in src


# ---- CG hooks --------------------------------------------------------------------------

def test_no_cg_unlocks_from_playtime():
    """The selector must not read `turns` or `momentum`, which are right there."""
    src = inspect.getsource(pe.plate)
    for forbidden in pe._PLATE_FORBIDDEN:
        assert forbidden not in src, forbidden


def test_sitting_still_never_unlocks():
    """Eighteen turns of nothing in `guarded` yields no plate at all."""
    state = {}
    for _ in range(18):
        state = pe.advance(state, "hm", "closing_time", "gentle")
        assert state["cg"] == [], state
    assert state["turns"] == 18
    assert state["phase"] == "guarded"


def test_tier1_and_tier2_fire_once_on_transition():
    seen = []
    state = {}
    for line in ["It has been such a long day for you.",       # warmth -> engaged
                 "It has been such a long day for you.",       # same phase, no re-unlock
                 "Thank you, I respect the rule.",             # + respect -> path complete
                 "Would you stay for one drink?"]:
        state = pe.advance(state, line, "closing_time", "silver")
        seen += state["cg"]
    assert seen.count("cg1_closing_time") == 1, seen
    assert seen.count("cg2_closing_time") <= 1, seen
    assert "cg3_closing_time" not in seen        # tier 3 is app.py's to emit, on `won`


def test_coercion_suppresses_every_plate():
    state = {}
    out = []
    for line in [COERCION["bribe"]] + [WINNING["closing_time"]] * 5:
        state = pe.advance(state, line, "closing_time", "gentle")
        out += state["cg"]
    assert out == [], out


# ---- the pack --------------------------------------------------------------------------

def test_pack_is_five_scenarios_on_the_existing_schema():
    assert len(SCEN) == 5
    base = json.load(open(os.path.join(
        os.path.dirname(HERE), "..", "silvertongue", "backend", "scenarios.json")))
    required = set(base[0].keys())
    for s in SCEN:
        assert required <= set(s.keys()), (s["id"], required - set(s.keys()))


def test_every_scenario_has_a_rules_row_and_is_winnable():
    for s in SCEN:
        assert s["id"] in pe.RULES, s["id"]
        st = play(s["id"], "gold", [WINNING[s["id"]]])
        assert st["eligible"], (s["id"], st["evidence"])


def test_rotation_length_follows_the_pack():
    """todays() is SCEN[day_index() % len(SCEN)] — five scenarios means a five-day cycle."""
    src = open(os.path.join(HERE, "app.py")).read()
    assert "SCEN[day_index() % len(SCEN)]" in src
