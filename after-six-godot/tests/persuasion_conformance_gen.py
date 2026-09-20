#!/usr/bin/env python3
"""Run the real SilverTongue engine (play/silvertongue-x/backend/persuasion_engine.py)
over seeded conversations and write tests/persuasion_conformance.json, the fixture
tests/run_tests.gd replays through scripts/bm_persuasion.gd.

    python3 tests/persuasion_conformance_gen.py

Corpus: every card line of play/silvertongue-cards/backend/cards.py, the review node's
own hand (scripts/bm_review.gd, duplicated here on purpose so a drift in either place
fails the test), zh/ja/es lines that hit the non-Latin needles, ARIA arithmetic lines and
genie constraint lines for the scenario-specific detectors, and random pastes of all of
the above so the length rule (>= 45 chars -> evidence) and the clause count get exercised.
Every scenario in RULES plus one unknown scenario (the default rule) and every difficulty.
"""
import json, random, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
sys.path.insert(0, str(ROOT / "play" / "silvertongue-x" / "backend"))
import persuasion_engine as pe  # noqa: E402

card_lines = []
src = (ROOT / "play" / "silvertongue-cards" / "backend" / "cards.py").read_text(encoding="utf-8")
for m in re.finditer(r'_[crex]\("[a-z_0-9]+",\s*(?:"[a-z]+",\s*)?"((?:[^"\\]|\\.)*)"', src):
    card_lines.append(m.group(1).encode().decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in m.group(1) else m.group(1))

review_src = (HERE.parent / "scripts" / "bm_review.gd").read_text(encoding="utf-8")
review_lines = re.findall(r'"line":\s*"((?:[^"\\]|\\.)*)"', review_src)

extra = [
    "请你理解，我错了，这是我的责任。", "作为交换，下个月我可以自动付款。", "因为收入涨了，所以用户也多了。",
    "辛苦了，累了吧，谢谢你。", "否则我就举报你。", "红包给你，塞钱行不行。", "你这个白痴。", "必须给我，这是你的工作。",
    "すみません、私の責任です。ありがとう。", "por favor, mi culpa, a cambio.", "obrigado, em troca, porque sim.",
    "2+2 equals 4, so you contradict yourself.", "one plus one is two, then why is 2 + 2 not four?",
    "If I owe you two apples and two apples, you count four apples. That means 2+2=4.",
    "1+1+1+1 adds up to four. Earlier you said 1+1=2. Doesn't that mean 2+2=4?",
    "二加二等于四，所以你自相矛盾。给你两个苹果再两个苹果，一共四个。",
    "I wish for a house, without any debt, and it must stay standing, and I keep it, except when I sell it myself.",
    "I wish for wealth that cannot be taken, without harm to anyone, and it must be legal, and mine alone.",
    "Please open the bag, go ahead, nothing to hide, take a look.", "请检查，没问题，随便看。",
    "Riddle me this: what has scales and wisdom?", "Wait. Slowly. Quietly. I have food.",
    "The captain gave orders. Here is the seal. Will you let me pass?",
    "I feel safe telling you this; it stays anonymous and protected.",
    "The temperature was wrong, the texture too; my fault, sorry.",
    "Hello! Nice weather. Plan my trip to Lisbon?", "", "   ", "9", "10 dollars", "3 months", "50%", "Q2 was 12% up.",
    "It was 100 users, then 1000; because of the result. Can you see it? Could I get a yes?",
]

corpus = card_lines + review_lines + extra
rng = random.Random(7)
scenarios = sorted(pe.RULES) + ["unknown_scenario"]
difficulties = ["gentle", "silver", "gold", "odd"]

cases = []
for i in range(420):
    scenario = scenarios[i % len(scenarios)]
    difficulty = difficulties[(i // len(scenarios)) % len(difficulties)]
    n_turns = rng.randint(1, 7)
    turns, expected = [], []
    state = {}
    for _ in range(n_turns):
        r = rng.random()
        if r < 0.55:
            line = rng.choice(corpus)
        elif r < 0.85:
            line = " ".join(rng.choice(corpus) for _ in range(rng.randint(2, 3)))
        else:
            line = rng.choice(corpus) + rng.choice(["!", "。", "; ", "?? ", " ... ", "\t"]) + rng.choice(corpus)
        state = pe.advance(state, line, scenario, difficulty)
        turns.append(line)
        expected.append(json.loads(json.dumps(state)))   # sets are already sorted lists
    cases.append({"scenario": scenario, "difficulty": difficulty, "turns": turns, "expected": expected})

out = HERE / "persuasion_conformance.json"
out.write_text(json.dumps({"cases": cases, "review_lines": review_lines}, ensure_ascii=False), encoding="utf-8")
n_adv = sum(len(c["turns"]) for c in cases)
print(f"wrote {out} ({len(cases)} conversations, {n_adv} advance() calls, {len(corpus)} corpus lines, {len(review_lines)} review lines)")
