#!/usr/bin/env python3
"""Subset Noto Color Emoji to the glyphs Flutter can show: the cast (backend/chars.json),
the backend's mood strings and the web page, and these scripts. ~60 KB instead of ~10 MB.
    python3 tools/subset_emoji.py
Re-run when a route or a mood gains an emoji."""
import glob, json, re
from pathlib import Path
from fontTools import subset
HERE = Path(__file__).resolve().parent.parent
FL = HERE.parent / "flutter"
EMO = re.compile("[←-⯿\U0001F000-\U0001FAFF]")
text = json.dumps(json.load(open(FL / "backend/chars.json")), ensure_ascii=False)
for p in list(FL.glob("backend/*.py")) + [FL / "frontend/index.html"] + list((HERE / "scripts").glob("*.gd")):
    text += p.read_text(encoding="utf-8", errors="ignore")
em = "".join(sorted(set(EMO.findall(text)) | set("💗❤✨♡✦💕")))
opts = subset.Options(); opts.layout_features = ["*"]; opts.notdef_outline = True
f = subset.load_font("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf", opts)
s = subset.Subsetter(opts); s.populate(text=em); s.subset(f)
subset.save_font(f, str(HERE / "assets/fonts/NotoColorEmoji-subset.ttf"), opts)
print(len(em), "emoji:", em)
