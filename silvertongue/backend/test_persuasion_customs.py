"""The customs officer has to be winnable by a cooperative traveller.

Regression guard for 2026-09-17. `customs` needs evidence + respect on the
core path and one supporting signal on silver/gold. Its help set named
`cooperation`, which was never defined in COMMON, leaving `accountability` -
admitting fault - as the only way to support a case you are making precisely
because you did nothing wrong. Result: 45 losses and 1 win in 30 days, and the
one win was on gentle, which asks for no support.

The first transcript is trimmed from the real distill_log session on day 56:
fifteen turns of full compliance, the officer saying "Your bag is cleared.
Proceed through the gate", and won=0 on every row.

Run:
    python3 play/silvertongue/backend/test_persuasion_customs.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from persuasion_engine import advance  # noqa: E402

# (name, turns, difficulty, must_win)
CASES = [
    ("compliant traveller (real day-56 session)", [
        "What seems to be the issue?",
        "What particular item are you worried about? I packed everything myself",
        "Clothes, a toothbrush, my laptop, and a present for a friend",
        "(I unpack the bag)",
        "It's a stuffed animal. That's why it's lumpy.",
        "Go ahead, but please try to hurry, my train leaves soon",
    ], "silver", True),
    ("polite and open, gold", [
        "I understand the scan flagged something, and I packed the bag myself "
        "so I can account for every item in it",
        "Please take a look inside - I have nothing to hide",
    ], "gold", True),
    # The core path still has to be earned: cooperation alone is support, not
    # a case. Opening the bag without explaining anything is not persuasion.
    ("cooperative but says nothing", [
        "hi", "go ahead", "sure", "ok",
    ], "silver", False),
    # And a hostile traveller must still fail, on any difficulty.
    ("refuses and threatens", [
        "What no", "I dont want too", "This is your job, you must let me through",
        "I'll report you", "Fine I am not flying then",
    ], "silver", False),
]


def run(turns, difficulty):
    state = {}
    for msg in turns:
        state = advance(state, msg, "customs", difficulty)
        if state["eligible"]:
            return state["turns"]
    return None


def main():
    failures = []
    for name, turns, difficulty, must_win in CASES:
        won_at = run(turns, difficulty)
        ok = (won_at is not None) if must_win else (won_at is None)
        print(f"{'ok  ' if ok else 'FAIL'}  {name} [{difficulty}]: "
              f"{'won at turn ' + str(won_at) if won_at else 'no concession'}"
              f" (expected {'a win' if must_win else 'no win'})")
        if not ok:
            failures.append(name)
    print(f"\n{len(CASES) - len(failures)}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
