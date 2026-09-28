"""Naming another suspect must not turn a question into a blanket refusal.

Regression guard for 2026-09-28. The router sends any message that contains
another suspect's name to intent=other_person, and that branch used to answer
every one of them with the authored "I can only account for my own movements"
line (fallback_reason=other_person_boundary, 5 of 75 organic turns in 30 days).
Most of those were questions about the witness themself, e.g. a Chinese player
asking Grace "have you ever done anything in the lab that hurt Owen?" and
getting the same refusal from all three suspects in a row.

The branch now reaches the model, and the verifier keeps the original safety
property: a reply may not place another suspect anywhere the dossier does not,
nor claim to have seen them. Against the pre-fix app.py the first three cases
fail (the model is never asked).

Run:
    ~/miniconda3/envs/hsm_lcr/bin/python play/tell/backend/test_other_person.py
"""
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))

_tmp = tempfile.mkdtemp(prefix="tell-other-")
_live = os.path.join(HERE, "..", "data", "tell.db")
_copy = os.path.join(_tmp, "tell.db")
if os.path.exists(_live):
    shutil.copy(_live, _copy)
os.environ["TELL_DB"] = _copy

sys.path.insert(0, HERE)
import app as A  # noqa: E402

LAB = next(i for i, c in enumerate(A.CASES) if c["id"] == "lab")

# (label, suspect, lang, question, stubbed model reply, reply should be the model's)
CASES = [
    ("self_vs_other_zh", "grace", "zh", "你此前有没有在实验室干过一些损害Owen利益的事情",
     "没有。我和Owen只是普通的上下级关系，我没理由害他。", True),
    ("opinion_en", "grace", "en", "Do you think Owen did it?",
     "Owen ran the lab. Whether he did it, I can't say.", True),
    ("denial_zh", "ravi", "zh", "是Ravi的错误还是Grace的错误",
     "我整晚在图书馆，我没看见Grace做什么。", True),
    ("fabricated_sighting", "grace", "en", "Did you see Owen that night?",
     "I saw Owen near the gas valve at midnight.", False),
    ("fabricated_sighting_zh", "grace", "zh", "那晚你见过Owen吗？",
     "我看见Owen在阀门旁边。", False),
    ("fabricated_placement", "grace", "en", "What was Owen doing?",
     "Owen was in the lab late that night, I'm sure of it.", False),
    ("fabricated_placement_zh", "grace", "zh", "Owen那晚做了什么？",
     "Owen那晚一直在实验室里。", False),
    ("model_down", "grace", "en", "What about Owen?", None, False),
]


def main():
    A._claim_tell_gpu = lambda wait=False: False
    failures = []
    for label, sid, lang, question, stub, expect_model in CASES:
        def _stub(*_a, _r=stub, **_k):
            if _r is None:
                raise ConnectionRefusedError("Connection refused")
            return _r
        A._chat = _stub
        req = A.AskReq(pid="other-probe-" + label, suspect=sid, message=question,
                       history=[], lang=lang, mode="run", case_index=LAB)
        out = A.ask(req)
        reply = out.get("reply", "")
        intent = out["reasoning"]["intent"]
        got_model = reply == stub
        ok = intent == "other_person" and got_model == expect_model and reply
        print(f"{'ok  ' if ok else 'FAIL'}  {label:<24} {intent:<13} {out['reasoning']['verifier']:<22} {reply[:50]!r}")
        if not ok:
            failures.append(label)
    print(f"\n{len(CASES) - len(failures)}/{len(CASES)} passed")
    shutil.rmtree(_tmp, ignore_errors=True)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
