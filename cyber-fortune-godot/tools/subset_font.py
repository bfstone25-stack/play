#!/usr/bin/env python3
"""Subset Noto Serif CJK SC (OFL) to the characters the game can show: everything in
pool/*.json and every string literal in scripts/*.gd, plus digits, punctuation and the
symbol glyphs. The full face is 26 MB; the subset is a few hundred KB, which is what lets
the web export stay under PLAN.md's 15 MB packet."""
import json, pathlib, re
from fontTools import subset
from fontTools.ttLib import TTCollection

HERE = pathlib.Path(__file__).resolve().parent
PROJ = HERE.parent
SRC = pathlib.Path("/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc")
OUT = PROJ / "assets/fonts/NotoSerifSC-subset.otf"

chars = set()
for p in (PROJ / "pool").glob("*.json"):
    chars.update(json.dumps(json.load(open(p, encoding="utf-8")), ensure_ascii=False))
for p in (PROJ / "scripts").glob("*.gd"):
    chars.update(p.read_text("utf-8"))
chars.update("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
chars.update("，。、：；！？「」『』（）《》…—·～％＋−×÷=+-/*%&#@$€¥£ ")
chars.update("❀∴☯♀♂✚♡⌘∞☆◉♁⊙†≈⊗♯★〇☉♪◎♧♥‡⊕■□▲△●○◆◇♠♣♦→←↑↓")
text = "".join(sorted(c for c in chars if ord(c) >= 32))

# SC is face 2 in the collection; write it out as a single font first
coll = TTCollection(str(SRC))
sc = coll.fonts[2]
tmp = HERE / ".noto_sc_full.otf"
sc.save(str(tmp))
opts = subset.Options()
opts.layout_features = ["*"]
opts.name_IDs = ["*"]
opts.notdef_outline = True
opts.drop_tables += ["vhea", "vmtx", "VORG"]
font = subset.load_font(str(tmp), opts)
sub = subset.Subsetter(opts)
sub.populate(text=text)
sub.subset(font)
subset.save_font(font, str(OUT), opts)
tmp.unlink()
cmap = font["cmap"].getBestCmap()
missing = sorted(set(c for c in text if ord(c) > 127 and ord(c) not in cmap))
print("subset: %d chars, %d KB, missing %s" % (len(text), OUT.stat().st_size // 1024, "".join(missing) or "none"))
