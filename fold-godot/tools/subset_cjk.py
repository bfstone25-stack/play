#!/usr/bin/env python3
"""Rebuild assets/fonts/NotoSansCJK-subset.otf: every CJK character FOLD can put on
screen, and nothing else.

The web export carries no system font, so a Chinese glyph that is not in a bundled face
renders as tofu — silently, only in the zh build, only for players who read it. The full
Noto Sans CJK is 16 MB, which is not shippable in a web game. So: a subset, built from
the three places FOLD's Chinese actually comes from —

  data/levels.json    201 level names, "中文 / English"
  data/coach_tips.json  the coach's lines, all languages (zh is the one that matters)
  scripts/*.gd, scenes/*.gd   the UI strings in scripts/i18n.gd

— plus the punctuation and the two glyphs the title screen draws by hand.

    python3 tools/subset_cjk.py      # needs fonttools (pyftsubset)

Same shape as play/beat-monday-godot/tools/subset_cjk.py, which is where the approach and
the source .otf come from. tests/run_tests.gd asserts the result is present and that
"归一" measures non-zero, because "I rebuilt the subset" and "the subset covers the text"
are different claims (memory note `verification-that-lies`).
"""
import json
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE.parent / "room-704/game/fonts/NotoSansCJKjp-Regular.otf"
OUT = HERE / "assets/fonts/NotoSansCJK-subset.otf"

chars: set[str] = set()

# steps.json and models.json joined this list on 2026-09-21 with the origami bridge and the
# ja/zh-Hant pass: the model names and the diagram steps are the MOST visible CJK in the
# game (they are the level's title and the line under the board) and they were not in the
# subset at all. Japanese also brings kana, which no previous string in this game needed --
# exactly the failure in the memory note about font atlases passing on-disk checks while
# missing kana, so tests/run_tests.gd measures a kana string as well as 归一.
for name in ("levels.json", "coach_tips.json", "steps.json", "models.json"):
    chars |= set((HERE / "data" / name).read_text(encoding="utf-8"))

for p in list(HERE.glob("scripts/*.gd")) + list(HERE.glob("scenes/*.gd")):
    chars |= set(p.read_text(encoding="utf-8"))

# the wordmark, the star, and the punctuation the UI sets
# the wordmark and every non-Latin symbol the UI sets: the star row, the bullet in the
# rules, the sound and close glyphs, the arrow on "Next". None of these is in Nunito or
# Marcellus either, so they ride in the same fallback.
chars |= set("归一帰折り紙0123456789×·—…：；！？，。、（）「」★☆◆♪✕✓‹›→←↑↓")

cjk = "".join(sorted(c for c in chars if ord(c) > 0x2000))

if not SRC.exists():
    sys.exit(f"source font missing: {SRC}")

with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
    f.write(cjk)
    text_file = f.name

subprocess.run(
    ["pyftsubset", str(SRC), "--text-file=" + text_file, "--layout-features=*",
     "--no-hinting", "--output-file=" + str(OUT)],
    check=True,
)
print(f"{len(cjk)} glyphs -> {OUT} ({OUT.stat().st_size // 1024} KB)")
