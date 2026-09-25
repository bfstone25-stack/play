#!/usr/bin/env python3
"""Rebuild assets/fonts/NotoSansCJK-subset.otf: every CJK character FOLD can put on
screen, and nothing else.

The web export carries no system font, so a Chinese glyph that is not in a bundled face
renders as tofu — silently, only in the zh build, only for players who read it. The full
Noto Sans CJK is 16 MB, which is not shippable in a web game. So: a subset, built from
the three places FOLD's Chinese actually comes from —

  data/levels.json    201 level names, "中文 / English"
  data/coach_tips.json  the coach's lines, all languages (zh is the one that matters)
  data/steps.json     the origami diagram step captions Origami reads (2026-09-21;
                       PLICATA's own file, not carried from the parent — this is the set
                       that went missing the first time the subset was rebuilt after
                       Origami shipped, 143 characters short, all of them in the her-band
                       fold vocabulary: 腰, 裾, 翻, 结 and the rest)
  scripts/*.gd, scenes/*.gd   the UI strings in scripts/i18n.gd
  data/i18n_f2p.json  the Nutaku F2P table (2026-09-24: it was never in this list, so
                       244 zh and 166 ja characters of the F2P layer drew as empty boxes;
                       ops/nutaku/fold_f2p/check_i18n.py now fails on that)
  assets/voice/companion/subtitles.json   Coco's subtitles

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

for name in ("levels.json", "coach_tips.json", "steps.json", "i18n_f2p.json"):
    chars |= set((HERE / "data" / name).read_text(encoding="utf-8"))
chars |= set((HERE / "assets/voice/companion/subtitles.json").read_text(encoding="utf-8"))

for p in list(HERE.glob("scripts/*.gd")) + list(HERE.glob("scenes/*.gd")):
    chars |= set(p.read_text(encoding="utf-8"))

# the wordmark, the star, and the punctuation the UI sets
# the wordmark and every non-Latin symbol the UI sets: the star row, the bullet in the
# rules, the sound and close glyphs, the arrow on "Next". None of these is in Nunito or
# Marcellus either, so they ride in the same fallback.
chars |= set("归一帰0123456789×·—…：；！？，。、（）「」★☆◆♪✕✓‹›→←↑↓")

HANGUL = lambda c: 0x1100 <= ord(c) <= 0x11FF or 0x3130 <= ord(c) <= 0x318F or 0xAC00 <= ord(c) <= 0xD7A3
cjk = "".join(sorted(c for c in chars if ord(c) > 0x2000 and not HANGUL(c)))
hangul = "".join(sorted(c for c in chars if HANGUL(c))) + "한국어"

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

# Korean (added 2026-09-24 with de/fr/es/ko): Hangul is not in the JP face, so it gets its
# own subset of Noto Sans CJK KR, hung after the JP one in StudioTheme's fallback chain.
TTC = pathlib.Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc")
OUT_KR = HERE / "assets/fonts/NotoSansCJKkr-subset.otf"
from fontTools.ttLib import TTCollection  # noqa: E402
from fontTools.subset import Subsetter  # noqa: E402
kr = next(f for f in TTCollection(str(TTC)).fonts if f["name"].getDebugName(1) == "Noto Sans CJK KR")
sub = Subsetter()
sub.populate(text=hangul + "·…“”‘’「」、。")
sub.subset(kr)
kr.save(str(OUT_KR))
print(f"{len(hangul)} Hangul -> {OUT_KR} ({OUT_KR.stat().st_size // 1024} KB)")

# The symbols no face here holds: ✕ (sound off, close), ∞ (a candle pass) and the macron
# in "plicāre". Neither Nunito, Lilita One nor Noto Sans CJK JP has ✕, so it drew as an
# empty box in every language until this. DejaVu Sans (Bitstream Vera licence, OFL-compatible
# terms; LICENSE-DejaVu.txt) is cut to just those.
DEJAVU = pathlib.Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
OUT_SYM = HERE / "assets/fonts/Symbols-subset.ttf"
subprocess.run(["pyftsubset", str(DEJAVU), "--text=✕∞āĀ★☆◆♪✓‹›→←↑↓×♥", "--no-hinting",
                "--output-file=" + str(OUT_SYM)], check=True)
print(f"symbols -> {OUT_SYM} ({OUT_SYM.stat().st_size // 1024} KB)")
