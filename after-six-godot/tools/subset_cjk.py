#!/usr/bin/env python3
"""Rebuild assets/fonts/NotoSansCJK-subset.otf: every CJK character the zh/ja strings and
the rant corpus use (from the HTML spec's strings.js + phrases.js), nothing else. The web
export has no system font, and the full Noto CJK is 16 MB."""
import pathlib, subprocess, tempfile
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE.parent / "room-704/game/fonts/NotoSansCJKjp-Regular.otf"
chars = set()
for p in ["frontend/rpg/strings.js", "frontend/rpg/phrases.js"]:
    chars |= set((HERE.parent / "beat-monday" / p).read_text())
for p in HERE.glob("scripts/*.gd"):
    chars |= set(p.read_text())
chars |= set("0123456789×·—…：；！？，。（）「」")
cjk = "".join(sorted(c for c in chars if ord(c) > 0x2000))
with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
    f.write(cjk)
subprocess.run(["pyftsubset", str(SRC), "--text-file=" + f.name, "--layout-features=*", "--no-hinting",
                "--output-file=" + str(HERE / "assets/fonts/NotoSansCJK-subset.otf")], check=True)
print(len(cjk), "glyphs")
