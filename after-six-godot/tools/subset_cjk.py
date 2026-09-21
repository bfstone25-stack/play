#!/usr/bin/env python3
"""Retired. Use the studio tool instead:

    python3 ops/subset_cjk.py play/after-six-godot/scripts/strings.gd \\
        --out play/after-six-godot/assets/fonts

What this file used to do was cut ONE face -- assets/fonts/NotoSansCJK-subset.otf -- from a
Japanese Noto and use it for both languages. Two things were wrong with that, and running
it again would put both of them back:

  * It built the character set from `scripts/*.gd` read as raw text plus the old HTML
    game's strings.js, so the set was whatever those files happened to contain. When the
    Japanese table was added, the shipped face held 342 characters and not one kana; the
    zh strings all rendered, so nothing looked broken anywhere.
  * One face cannot serve zh and ja. Every regional Noto CJK covers the full unified
    repertoire, so a shared face throws no error and simply draws the shared kanji in one
    region's glyph forms -- Chinese forms to a Japanese reader, which no check on disk can
    see. ops/subset_cjk.py writes one subset per script family from its own regional face
    for exactly this reason, and main.gd picks between them by Game.lang.
"""
raise SystemExit(__doc__)
