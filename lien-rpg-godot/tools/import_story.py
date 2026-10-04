#!/usr/bin/env python3
"""LIEN's writing -> data/story/lien.json, line for line, with its Japanese.

The source is the Godot fork's scripts/story.gd (all ~9,300 words, carried there from the
Ren'Py fork). Every nar("...") / say("who", "...") call becomes one line whose `src` is its
line number in story.gd, so the nights reference the original by range ("lien:226-236")
exactly the way the other RPGs reference their VN by .rpy line. A branch in story.gd
(`if tier == "low":`) is a contiguous block of source lines, so a range picks one branch.

Lines built with Loc.s(...) % (...) interpolate run state (the till, a fee). They are kept
with "fmt": true and "skip": true so a range never prints a raw %d; the nights give each of
them an RPG string with a {#coin} counter instead (tools/strings_story.py).

JA comes from the fork's own locale/story_ja.json (English source -> translation), which
covers every story string; a missing one is an error, not a fallback.

    python3 tools/import_story.py
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SRC = HERE.parent / "midnight-pawn-collateral-godot"
STORY = SRC / "scripts/story.gd"
JA = json.loads((SRC / "locale/story_ja.json").read_text())

# One-word lines the fork's translation table keys elsewhere (its UI table, not story_ja):
# translated here by hand, in Nara's / the clients' register.
SHORT = {"...": "……", "Apparently.": "そうらしい。", "Calder.": "カルダーだ。", "Fine.": "いいわ。",
         "Forty.": "四十。", "Good.": "よし。", "Ivo?": "アイヴォ？", "No.": "いいえ。", "Nothing.": "何も。",
         "Quill.": "クイル。", "Voss.": "ヴォス。", "Well.": "さて。", "Well?": "それで？", "Why.": "なぜ。",
         "Yes.": "ええ。"}

CALL = re.compile(r'^\s*(?:out\.append\()?(nar|say)\((?:"(\w+)",\s*)?(Loc\.s\()?"((?:[^"\\]|\\.)*)"')


def main() -> int:
    lines = []
    missing = []
    for no, raw in enumerate(STORY.read_text().splitlines(), 1):
        m = CALL.match(raw)
        if not m:
            continue
        kind, who, locs, text = m.groups()
        text = text.encode().decode("unicode_escape").encode("latin-1").decode("utf-8")
        fmt = bool(locs) and "%" in raw.split(text, 1)[1][:40]
        ln = {"id": f"lien_{no}", "src": no, "who": "narrator" if kind == "nar" else who, "en": text}
        ja = JA.get(text, "") or SHORT.get(text, "")
        if not ja and not fmt:
            missing.append((no, text[:60]))
        ln["ja"] = ja
        if fmt:
            ln["fmt"] = True
            ln["skip"] = True
        lines.append(ln)
    out = HERE / "data/story/lien.json"
    out.write_text(json.dumps({"chapter": "lien", "lines": lines, "menus": {}}, ensure_ascii=False, indent=1))
    print(f"{len(lines)} lines, {sum(1 for l in lines if l.get('fmt'))} interpolated (skipped in ranges), "
          f"{len(missing)} without JA -> {out}")
    for m in missing:
        print("  !! no JA:", m)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
