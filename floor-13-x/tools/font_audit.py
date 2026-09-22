#!/usr/bin/env python3
"""Every character an offered language needs must have a glyph in the bundled BMFont.

The studio has now been burned twice by fonts that pass on-disk checks while being wrong.
After Six shipped a 342-glyph face cut for Chinese with zero kana. Floor 13's own atlas was
built before the Japanese translation landed: 1700 glyphs, 318 of the 943 characters the
Japanese script needs absent, 43 of them kana. Nothing about the file's name, size or
glyph count says so — only asking "is THIS character in there" does.

Godot cannot fall through to a browser face on WebGL, so a missing glyph is a visible box
in shipped prose, not a silent substitution. Run this after any translation edit:

    python3 tools/font_audit.py

Exit is non-zero if any language in Loc.ALLOWED needs a character the font lacks.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from story_parse import body_strings, p  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FONTS = ["assets/fonts/floor13_pixel_12.fnt", "assets/fonts/floor13_pixel_16.fnt"]
STORY = {"en": "story_data.gd", "zh": "story_zh.gd", "ja": "story_ja.gd",
         "es": "story_es.gd", "ko": "story_ko.gd"}
UI = {"en": "EN", "zh": "ZH", "ja": "JA", "es": "ES", "ko": "KO"}


def allowed():
    src = open(p("locale.gd"), encoding="utf-8").read()
    m = re.search(r"const ALLOWED := \[(.*?)\]", src, re.S)
    return re.findall(r'"([\w-]+)"', m.group(1)) if m else []


def ui_chars(dict_name):
    src = open(p("locale.gd"), encoding="utf-8").read()
    m = re.search(r"const %s := \{(.*?)\n\}" % dict_name, src, re.S)
    if not m:
        return set()
    out = set()
    for v in re.findall(r':\s*"((?:[^"\\]|\\.)*)"', m.group(1)):
        out |= set(v.replace("\\n", "").replace("\\t", ""))
    return out


def needed(loc):
    chars = set()
    path = p(STORY[loc])
    if os.path.exists(path):
        for _, text in body_strings(path):
            chars |= set(text)
    chars |= ui_chars(UI[loc])
    return {c for c in chars if ord(c) > 0x20}


def glyphs(fnt):
    src = open(os.path.join(ROOT, fnt), encoding="utf-8").read()
    return {int(x) for x in re.findall(r"^char id=(\d+)", src, re.M)}


def main():
    bad = 0
    for fnt in FONTS:
        have = glyphs(fnt)
        print(f"{fnt}  {len(have)} glyphs")
        for loc in allowed():
            want = needed(loc)
            miss = sorted((c for c in want if ord(c) not in have), key=ord)
            kana = [c for c in miss if 0x3040 <= ord(c) <= 0x30FF]
            if miss:
                bad = 1
                print(f"    {loc}: MISSING {len(miss)}/{len(want)}"
                      f" ({len(kana)} kana)  {''.join(miss[:40])}")
            else:
                print(f"    {loc}: all {len(want)} characters present")
    return bad


if __name__ == "__main__":
    sys.exit(main())
