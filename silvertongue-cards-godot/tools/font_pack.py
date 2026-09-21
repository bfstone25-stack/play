#!/usr/bin/env python3
"""Build this game's CJK font subsets, from every string it can actually display.

    python3 play/silvertongue-cards-godot/tools/font_pack.py

Why this exists rather than calling ops/subset_cjk.py directly. That script reads ONE
i18n table and subsets to the literals in it, which is right for a game whose whole text
is a chrome table. It is wrong here: this game's chrome is 39 keys in scripts/loc.gd and
its TEXT — five scenario rows, ten ending beats, 225 reply lines and 64 card faces — lives
in assets/offline/data.json, generated from the backend by tools/export_offline.py. Subset
to loc.gd alone and every word Mara says renders as a blank box, with nothing anywhere
reporting an error. That is the `verification-that-lies` shape: the font pack exists, the
language is listed, and the game is unreadable.

So this collects the character set from BOTH sources, writes it out in the shape
ops/subset_cjk.py already parses, and hands it over. The subsetting, the one-face-per-
script rule (Japanese kanji must come from the JP face or a Japanese reader sees Chinese
glyph forms immediately) and the missing-glyph shouting all stay in the shared tool.

Re-run after either loc.gd or the export changes.

ONE EXPECTED WARNING. ops/subset_cjk.py shouts that ⚡ (U+26A1) is not in the Noto Sans
CJK faces, for zh-Hant and ja. That is true and it is fine: scripts/symbols.gd installs
the CJK subset and DejaVu Sans Bold as a two-deep fallback stack, CJK first, so a glyph
missing from the CJK face falls through to the symbols face that was bundled for exactly
these six characters (♥ ◆ ⚡ ★ ◈ ✕). Do not try to "fix" it by dropping ⚡ from the strings;
check the rendered frame instead. Any OTHER character in that warning is a real problem.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRODUCTS = ROOT.parent.parent
LOC = ROOT / "scripts" / "loc.gd"
DATA = ROOT / "assets" / "offline" / "data.json"
OUT = ROOT / "assets" / "fonts"
LANGS = ("zh", "zh-Hant", "ja")


def from_loc() -> dict[str, set[str]]:
    """The chrome table: `"ja": { ... }` blocks inside `const T := {...}`."""
    txt = LOC.read_text(encoding="utf-8")
    out = {l: set() for l in LANGS}
    starts = []
    for lang in LANGS:
        m = re.search(r'^\t"%s": \{' % re.escape(lang), txt, re.M)
        if m:
            starts.append((m.start(), lang))
    starts.sort()
    for i, (pos, lang) in enumerate(starts):
        end = starts[i + 1][0] if i + 1 < len(starts) else len(txt)
        for lit in re.finditer(r'"((?:[^"\\]|\\.)*)"', txt[pos:end]):
            out[lang] |= set(lit.group(1).replace("\\n", "").replace('\\"', '"'))
    return out


def from_data() -> dict[str, set[str]]:
    """Everything the offline package can put on screen, per locale."""
    d = json.loads(DATA.read_text(encoding="utf-8"))
    out = {l: set() for l in LANGS}

    for s in d.get("scenarios", []):
        for key in ("title", "character", "goal", "story", "cg1_caption", "cg2_caption",
                    "cg3_caption", "closing_beat", "refusal_beat"):
            for loc, text in (s.get(key) or {}).items():
                if loc in out:
                    out[loc] |= set(text)
        # `name` is printed in every language (they are proper nouns in Latin today, but
        # a renamed character must not silently fall outside the font).
        for loc in out:
            out[loc] |= set(str(s.get("name", "")))

    # Her replies. The ja table is its own; zh/zh-Hant still read the English one, so they
    # contribute no CJK here — which is exactly the gap loc.gd's header names.
    for scen in d.get("replies_ja", {}).values():
        for lines in scen.values():
            for ln in lines:
                out["ja"] |= set(ln)

    # The printed card faces.
    for c in d.get("cards", []):
        for k, v in c.items():
            if k.startswith("line_"):
                loc = k[5:]
                if loc in out:
                    out[loc] |= set(v)
    return out


def main() -> int:
    if not DATA.exists():
        print("no %s — run tools/export_offline.py first" % DATA, file=sys.stderr)
        return 2
    chars = from_loc()
    for lang, s in from_data().items():
        chars[lang] |= s

    # ops/subset_cjk.py parses `"<lang>": {` blocks and unions the string literals inside,
    # so one literal per language says everything. The characters are sorted for a stable
    # file, and " and \ are dropped rather than escaped — the shared tool's ALWAYS set
    # already carries the ASCII punctuation, and escaping here only creates ways to be
    # wrong.
    with tempfile.TemporaryDirectory() as td:
        gen = Path(td) / "chars.gd"
        body = ["const T := {"]
        for lang in LANGS:
            safe = "".join(sorted(c for c in chars[lang] if c not in '"\\' and c >= " "))
            body.append('"%s": {' % lang)
            body.append('\t"all": "%s",' % safe)
            body.append("},")
            print("  %-8s %5d chars" % (lang, len(safe)))
        body.append("}")
        gen.write_text("\n".join(body), encoding="utf-8")
        OUT.mkdir(parents=True, exist_ok=True)
        return subprocess.call([sys.executable, str(PRODUCTS / "ops" / "subset_cjk.py"),
                                str(gen), "--out", str(OUT)])


if __name__ == "__main__":
    raise SystemExit(main())
