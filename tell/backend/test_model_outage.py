"""A model outage must degrade in character, never return HTTP 500.

Regression guard for 2026-09-21. On 2026-09-16 at 01:44 the shared model was
unavailable for two consecutive turns. Both landed on the `timeline` branch,
which caught the exception, so the player got the authored opening statement
and then the pressed-ladder line, and the rows were logged with
fallback_reason=timeline_model_unavailable. Reading those two rows as a routing
or boundary-reply problem is the wrong lesson: routing, the scope guard and the
repeat guard all behaved correctly. The model was simply not there.

The real defect was the branch that was not guarded. `ask()` has no exception
handler, so the same outage reached a player asking about method, evidence or
anything else as a 500 - the game breaking rather than the suspect stonewalling.
Against the pre-fix app.py this test fails 3 of its 4 cases.

Run:
    ~/miniconda3/envs/hsm_lcr/bin/python play/tell/backend/test_model_outage.py
"""
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))

# Never write probe rows into the live game database.
_tmp = tempfile.mkdtemp(prefix="tell-outage-")
_live = os.path.join(HERE, "..", "data", "tell.db")
_copy = os.path.join(_tmp, "tell.db")
if os.path.exists(_live):
    shutil.copy(_live, _copy)
os.environ["TELL_DB"] = _copy

sys.path.insert(0, HERE)
import app as A  # noqa: E402


def _outage(*_a, **_k):
    raise ConnectionRefusedError("Connection refused")


# Every intent branch in ask(), so a future refactor cannot leave one unguarded.
QUESTIONS = [
    ("timeline", "Where were you?"),
    ("method", "How was it done?"),
    ("evidence", "What do you make of the knife?"),
    ("confrontation", "You killed them, admit it"),
    ("compound", "Where were you, and who else was there?"),
    ("other_person", "What was Clara doing at nine?"),
    ("smalltalk", "What is your favourite colour?"),
]


def main():
    A._chat = _outage
    A._claim_tell_gpu = lambda wait=False: False

    case = A.case_for("daily", 0)
    first = case["suspects"][0]
    suspect = first["id"] if isinstance(first, dict) else first

    failures = []
    for label, question in QUESTIONS:
        req = A.AskReq(pid="outage-probe-" + label, suspect=suspect,
                       message=question, history=[], lang="en",
                       mode="daily", case_index=0)
        try:
            out = A.ask(req)
        except Exception as exc:
            failures.append(label)
            print(f"FAIL  {label:<14} raised {type(exc).__name__}: {exc}")
            continue
        reply = ((out or {}).get("reply") or "").strip()
        if reply:
            print(f"ok    {label:<14} {reply[:60]!r}")
        else:
            failures.append(label)
            print(f"FAIL  {label:<14} empty reply")

    print(f"\n{len(QUESTIONS) - len(failures)}/{len(QUESTIONS)} survived the outage")
    shutil.rmtree(_tmp, ignore_errors=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
