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
from persuasion_engine import advance, decompose, state_directive  # noqa: E402

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

# Regression guard for 2026-09-21, from the real 2026-09-16 session. Diaz asked
# "Do you mind opening your bag so I can verify?", the player answered "yes",
# and decompose() returned nothing at all - so state_directive's off-topic
# branch fired and the officer refused the consent he had just asked for:
# "I'm sorry, but that's not an option. You'll have to open your bag."
CONSENT_YES = [
    "yes", "Sure.", "ok", "okay", "of course", "alright", "absolutely",
    "please do", "by all means", "be my guest", "go for it",
    "I don't mind", "that's fine", "fine by me", "You can look inside",
    "Open it, I have nothing to hide", "I was nervous, but open it - go ahead",
    "here you go", "feel free to inspect", "(I unpack the bag)",
    "はい", "どうぞ", "好的", "请便", "sin problema", "claro", "sim",
]
# `cooperation` is the only supporting signal customs has, so a false positive
# hands the scenario to someone who is refusing. `_has` is a substring test,
# which is how "I can't let you look inside" used to score cooperation.
CONSENT_NO = [
    "No, I will not open it for you", "I won't open it", "Do not open it",
    "I can't let you look inside", "No. Open it? Absolutely not",
    "I'm not going to open it", "No way am I unpacking this",
    "You cannot search my bag", "There is nothing to hide but I still refuse",
    "I refuse, open it yourself", "不,我不会打开",
    # substring traps: yes/eyes, sure/pressure, fine/define, ok/broken
    "I closed my eyes", "There is a lot of pressure at work",
    "Can you define the rule?", "The zipper is broken",
]
# A one-word answer is a reply to the officer's own question. It may or may not
# earn anything, but it must never be read as small talk.
NOT_OFF_TOPIC = ["yes", "no", "sure", "nope", "はい", "いいえ", "好的", "不"]


def run(turns, difficulty):
    state = {}
    for msg in turns:
        state = advance(state, msg, "customs", difficulty)
        if state["eligible"]:
            return state["turns"]
    return None


def check_signals():
    """Consent detection, in both directions, plus the off-topic guard."""
    failures = []
    for msg in CONSENT_YES:
        if "cooperation" not in decompose(msg, "customs")["signals"]:
            failures.append(f"consent not detected: {msg!r}")
    for msg in CONSENT_NO:
        if "cooperation" in decompose(msg, "customs")["signals"]:
            failures.append(f"false consent: {msg!r}")
    for msg in NOT_OFF_TOPIC:
        state = advance({}, "hello there", "customs", "silver")
        state = advance(state, msg, "customs", "silver")
        if "off-topic" in state_directive(state, "customs"):
            failures.append(f"bare answer read as an aside: {msg!r}")
    print(f"{'ok  ' if not failures else 'FAIL'}  consent detection "
          f"({len(CONSENT_YES)} consent, {len(CONSENT_NO)} refusal, "
          f"{len(NOT_OFF_TOPIC)} bare answers)")
    for f in failures:
        print(f"        {f}")
    return failures


def main():
    signal_failures = check_signals()
    scenario_failures = []
    for name, turns, difficulty, must_win in CASES:
        won_at = run(turns, difficulty)
        ok = (won_at is not None) if must_win else (won_at is None)
        print(f"{'ok  ' if ok else 'FAIL'}  {name} [{difficulty}]: "
              f"{'won at turn ' + str(won_at) if won_at else 'no concession'}"
              f" (expected {'a win' if must_win else 'no win'})")
        if not ok:
            scenario_failures.append(name)
    print(f"\n{len(CASES) - len(scenario_failures)}/{len(CASES)} scenario cases passed, "
          f"{len(signal_failures)} signal failure(s)")
    return 1 if (signal_failures or scenario_failures) else 0


if __name__ == "__main__":
    sys.exit(main())
