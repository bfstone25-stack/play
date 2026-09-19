#!/usr/bin/env python3
"""Rebuild assets/fonts/NotoSansCJK-subset.otf: every CJK character this title's strings
use, and nothing else. The web export ships no system font and the full Noto CJK is 16 MB.

Same tool as play/beat-monday-godot/tools/subset_cjk.py — but it has to be re-run *here*,
against *these* strings. The first build of this game borrowed that title's subset and the
zh-Hans menu came up as tofu boxes: 账本 rendered as 圝本, 岗 as a box. A subset is a
per-title artefact, and the only way to know it is wrong is to look at the screen.

    python3 tools/subset_cjk.py     # needs fonttools (pyftsubset)
"""
import pathlib, subprocess, tempfile

HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE.parent / "room-704/game/fonts/NotoSansCJKjp-Regular.otf"

chars: set = set()
for p in sorted(HERE.glob("scripts/*.gd")):
    chars |= set(p.read_text(encoding="utf-8"))
chars |= set((HERE / "README.md").read_text(encoding="utf-8"))
# punctuation the copy leans on even when a string happens not to use it today
chars |= set("0123456789×·—…：；！？，。、（）「」《》%+-")
cjk = "".join(sorted(c for c in chars if ord(c) > 0x2000))
with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
    f.write(cjk)
subprocess.run(["pyftsubset", str(SRC), "--text-file=" + f.name, "--layout-features=*",
                "--no-hinting", "--output-file=" + str(HERE / "assets/fonts/NotoSansCJK-subset.otf")],
               check=True)
print(len(cjk), "glyphs ->", HERE / "assets/fonts/NotoSansCJK-subset.otf")
