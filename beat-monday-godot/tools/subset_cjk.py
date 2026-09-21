#!/usr/bin/env python3
"""Rebuild assets/fonts/NotoSansCJK-subset.otf: every CJK character the zh/ja strings and
the rant corpus use, nothing else. The web export has no system font, and the full Noto
CJK is 16 MB.

2026-09-21: the shipped subset held 342 glyphs while scripts/ used 696. It had been built
once, from the old HTML spec, and every string added since — the whole map, the inbox, the
review, and now the ja bank — rendered as tofu boxes on the web build with no error
anywhere (the same failure SilverTongue shipped with). tests/run_tests.gd now asserts the
coverage, so this cannot drift silently again. Re-run it after touching strings.gd.

Kana is not optional now that ja ships: a subset built only from the characters the files
happen to contain would miss nothing today and break on the first new line, so the whole
kana block goes in (a few hundred glyphs, ~30 KB).
"""
import pathlib, subprocess, tempfile
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE.parent / "room-704/game/fonts/NotoSansCJKjp-Regular.otf"
chars = set()
for p in ["frontend/rpg/strings.js", "frontend/rpg/phrases.js"]:
    q = HERE.parent / "beat-monday" / p
    if q.exists():
        chars |= set(q.read_text())
for p in HERE.glob("scripts/*.gd"):
    chars |= set(p.read_text())
chars |= set("0123456789×·—…：；！？，。（）「」、〜％（）")
# the full kana blocks, so a new Japanese line never needs a font rebuild to be readable
chars |= set(chr(c) for c in range(0x3041, 0x30FF))
cjk = "".join(sorted(c for c in chars if ord(c) > 0x2000))
with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
    f.write(cjk)
subprocess.run(["pyftsubset", str(SRC), "--text-file=" + f.name, "--layout-features=*", "--no-hinting",
                "--output-file=" + str(HERE / "assets/fonts/NotoSansCJK-subset.otf")], check=True)
print(len(cjk), "glyphs")
