#!/usr/bin/env python3
"""Every character an offered language needs must have a glyph in the bundled BMFont.

Font atlases lie, and the studio has now been burned three times by the same lie. After
Six shipped a 342-glyph face cut for Chinese with zero kana. Floor 13's atlas looked like
a healthy 1700-glyph font and was missing 318 of the characters its Japanese script needs,
43 of them kana. Beat the Monday's shipped 342 glyphs against the 696 its scripts use, so
Chinese had been rendering tofu since the day it was written.

Nothing about a font's name, file size or glyph count says any of that. Only asking "is
THIS character in there" does, and the question has to be asked of the actual shipped
prose rather than of a character range someone typed out by hand.

Late Inspection binds ONE atlas for every runtime label (scripts/ui_font.gd), deliberately,
to avoid Godot's WebGL SystemFont path -- which means there is no browser face to fall
through to and a missing glyph is a visible box in shipped prose.

    python3 tools/font_audit.py [--verbose]

Exit is non-zero if any language in Loc.ALLOWED needs a character the atlas lacks.
"""
import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from lang_audit import (SCRIPTS, FILES, allowed, p,  # noqa: E402
                        strings, ui_strings, _strip_comments, _dict_after)

FONTS = ["assets/fonts/late_inspection_pixel_16.fnt"]


def needed(loc):
    """Every character the game can actually put on screen in this language.

    Story prose and the locale.gd UI table, plus the language menu's own native names --
    the 日本語 / 한국어 buttons are drawn in the CURRENT locale's font, so an English
    player's atlas still has to carry them or the language picker is a row of boxes.
    """
    chars = set()
    path = p(FILES[loc][0])
    if os.path.exists(path):
        for _, text in strings(path):
            chars |= set(text)
    for _, text in ui_strings(loc):
        chars |= set(text)
    chars |= native_names()
    return {c for c in chars if ord(c) > 0x20}


def native_names():
    src = _strip_comments(open(p("locale.gd"), encoding="utf-8").read())
    m = re.search(r"\bconst NATIVE\s*:?=\s*", src)
    if not m:
        return set()
    return set("".join(ast.literal_eval(_dict_after(src, m.end())).values()))


def glyphs(fnt):
    src = open(os.path.join(ROOT, fnt), encoding="utf-8").read()
    return {int(x) for x in re.findall(r"^char id=(\d+)", src, re.M)}


def main():
    verbose = "--verbose" in sys.argv
    bad = 0
    for fnt in FONTS:
        have = glyphs(fnt)
        print(f"{fnt}  {len(have)} glyphs")
        for loc in allowed():
            want = needed(loc)
            miss = sorted((c for c in want if ord(c) not in have), key=ord)
            mark = "" if not miss else "  <-- TOFU IN SHIPPED PROSE"
            if miss:
                bad = 1
            print(f"  {loc:3s} needs {len(want):5d}   missing {len(miss):4d}{mark}")
            if miss and verbose:
                print("      " + " ".join(f"{c}(U+{ord(c):04X})" for c in miss[:60]))
    return bad


if __name__ == "__main__":
    sys.exit(main())
