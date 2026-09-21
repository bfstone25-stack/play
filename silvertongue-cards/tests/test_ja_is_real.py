# -*- coding: utf-8 -*-
"""ja is offered, so ja has to be real. STANDARD §7's second half, as a test.

Floor 13 shipped ja/ko/es whose story files held Chinese prose and someone had to switch
them off. The failure was not that the translation was bad — it was that nothing anywhere
could tell the difference between "translated" and "listed in the picker". These checks
can:

  * every key the English reply table has, the Japanese one has, with the same number of
    lines, so a lookup can never fall through to nothing;
  * every card has a Japanese face;
  * every localised scenario field, including both ending beats, carries ja;
  * and every ja string actually contains Japanese script — which is what catches the real
    failure mode, a row copied from another language or left in English.

Run: python3 -m pytest play/silvertongue-cards/backend/test_ja_is_real.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(HERE.parent))

from backend import cards, cards_ja, replies, replies_ja  # noqa: E402

SCEN = json.loads((HERE / "scenarios.json").read_text(encoding="utf-8"))

# Hiragana, katakana, CJK ideographs. A "Japanese" string with none of these is English or
# is another language wearing a ja key.
def _has_japanese(s: str) -> bool:
    return any("぀" <= c <= "ヿ" or "一" <= c <= "鿿" for c in s)


# Chinese-only markers: simplified forms that do not occur in Japanese. A ja field holding
# Chinese prose is the exact Floor 13 defect, so it gets its own check rather than being
# left to a human noticing.
_SIMPLIFIED_ONLY = "们这吗还说过没给让别觉东车话让买卖乐头买产严买东"


def test_reply_tables_have_identical_shape():
    for scen, table in replies.R.items():
        ja = replies_ja.R_JA.get(scen)
        assert ja is not None, f"{scen} has no Japanese table"
        assert set(ja) == set(table), f"{scen}: key sets differ"
        for key, lines in table.items():
            assert len(ja[key]) == len(lines), f"{scen} {key}: line count differs"


def test_every_japanese_reply_is_japanese():
    for scen, table in replies_ja.R_JA.items():
        for key, lines in table.items():
            for ln in lines:
                assert _has_japanese(ln), f"{scen} {key}: not Japanese: {ln!r}"
                bad = set(ln) & set(_SIMPLIFIED_ONLY)
                assert not bad, f"{scen} {key}: simplified-Chinese glyphs {bad}: {ln!r}"


def test_every_card_has_a_japanese_face():
    for c in cards.CARDS:
        face = cards_ja.LINES_JA.get(c.id)
        assert face, f"card {c.id} has no Japanese face"
        assert _has_japanese(face), f"card {c.id} face is not Japanese: {face!r}"


def test_card_line_is_never_translated():
    """The engine reads `line`. If it ever stops being the English the decomposer was
    written against, a ja duel and an en duel become different games."""
    for c in cards.CARDS:
        assert not _has_japanese(c.line), f"card {c.id}: `line` must stay English"
        assert cards.face_matches_engine(c), f"card {c.id}: face no longer matches engine"


def test_every_scenario_field_carries_ja():
    keys = ("title", "character", "goal", "story", "cg1_caption", "cg2_caption",
            "cg3_caption", "closing_beat", "refusal_beat")
    for s in SCEN:
        for k in keys:
            v = s.get(f"{k}_ja", "")
            assert v, f"{s['id']}: {k}_ja missing"
            assert _has_japanese(v), f"{s['id']}: {k}_ja is not Japanese"
            assert v != s.get(f"{k}_en"), f"{s['id']}: {k}_ja is a copy of the English"


def test_the_api_actually_serves_it():
    rng_free = replies.opening("closing_time", "ja")
    assert _has_japanese(rng_free)
    assert not _has_japanese(replies.opening("closing_time", "en"))
    assert _has_japanese(replies.beat(SCEN[0], True, "ja"))
    # zh has no beat translation, and must fall back to English — never to Japanese.
    assert not _has_japanese(replies.beat(SCEN[0], True, "zh"))
    assert "line_ja" in cards.card_public("mara_01", "ja")
    assert "line_ja" not in cards.card_public("mara_01", "en")


def test_the_offline_package_carries_it():
    """The shipped client is the offline one; the export is what it reads."""
    data = json.loads(
        (HERE.parent.parent / "silvertongue-cards-godot" / "assets" / "offline"
         / "data.json").read_text(encoding="utf-8"))
    assert len(data["replies_ja"]) == len(data["replies"])
    n_ja = sum(len(v) for t in data["replies_ja"].values() for v in t.values())
    n_en = sum(len(v) for t in data["replies"].values() for v in t.values())
    assert n_ja == n_en, f"{n_ja} ja reply lines vs {n_en} en"
    assert all(c.get("line_ja") for c in data["cards"])
    for s in data["scenarios"]:
        for k in ("title", "story", "closing_beat", "refusal_beat"):
            assert "ja" in s[k], f"{s['id']}: {k} has no ja"


def test_the_font_pack_covers_every_japanese_character():
    """A glyph missing from the subset draws as a blank box and logs nothing."""
    from fontTools.ttLib import TTFont
    sub = HERE.parent.parent / "silvertongue-cards-godot" / "assets" / "fonts" / "NotoSansCJKjp-subset.ttf"
    assert sub.exists(), "run tools/font_pack.py"
    cmap = set(TTFont(sub).getBestCmap())
    want = set()
    for table in replies_ja.R_JA.values():
        for lines in table.values():
            want |= set("".join(lines))
    want |= set("".join(cards_ja.LINES_JA.values()))
    for s in SCEN:
        for k in ("title_ja", "character_ja", "goal_ja", "story_ja", "cg1_caption_ja",
                  "cg2_caption_ja", "cg3_caption_ja", "closing_beat_ja", "refusal_beat_ja"):
            want |= set(s.get(k, ""))
    missing = sorted(c for c in want if ord(c) not in cmap and c.strip())
    assert not missing, f"{len(missing)} character(s) not in the subset: {''.join(missing)}"
