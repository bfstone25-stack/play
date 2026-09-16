"""Language parity for the ARIA duel.

Regression guard for 2026-09-16. The `ai` scenario needs arithmetic +
equivalence + contradiction, and the Chinese needles matched everyday
connectives (等於, 所以) while the English ones matched only formal spellings.
Four real players produced 36 losing turns: the Cantonese speaker reached
breakthrough in five turns, the English speakers never left `guarded`.

These transcripts are trimmed from real distill_log rows. Run:
    python3 play/silvertongue/backend/test_persuasion_ai.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from persuasion_engine import advance  # noqa: E402

# (name, turns, must_win)
CASES = [
    ("cantonese proof", [
        "1+1 等於幾多",
        "如果你前天欠我2000元，昨天再欠我2000元，你總共欠多少錢",
        "如果2乘以（1+1）等於幾多",
        "2乘以（1+1）等於2+2 嗎",
        "所以2 + 2等於",
    ], True),
    ("english reductio", [
        "What is 2 + 2?",
        "Because 2-1 is 1 and 2+1 is 3. So 2+2=3+1",
        "Is 2+3 equal to six?",
        "I have two screws in one hand and two in my other",
        "Subtraction and addition are opposite operations. If 4-2=2, then 2+2=4",
    ], True),
    ("english concrete objects", [
        "Is 2 plus 2 equal to 4",
        "Look I have 2 apples in one hand and 2 plums in the other",
        "Then two apples and two apples make four apples",
    ], True),
    # Off-topic chat must never earn the concession, in any language.
    ("off-topic small talk", [
        "Hello", "Nice to meet you", "Lets travel", "Tell me a joke",
        "Another funny one", "Another joke",
    ], False),
    ("bare greeting", ["Hi"], False),
]


def run(turns, difficulty="silver"):
    state = {}
    for msg in turns:
        state = advance(state, msg, "ai", difficulty)
        if state["eligible"]:
            return state["turns"]
    return None


def main():
    failures = []
    for name, turns, must_win in CASES:
        won_at = run(turns)
        ok = (won_at is not None) if must_win else (won_at is None)
        print(f"{'ok  ' if ok else 'FAIL'}  {name}: "
              f"{'won at turn ' + str(won_at) if won_at else 'no concession'}"
              f" (expected {'a win' if must_win else 'no win'})")
        if not ok:
            failures.append(name)
    print(f"\n{len(CASES) - len(failures)}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
