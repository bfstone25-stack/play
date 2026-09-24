#!/usr/bin/env python3
"""Emit pool/*.json from the hand-written pools in tools/pool_*.py, then subset the CJK
font to exactly the characters the game can display (tools/subset_font.py)."""
import json, pathlib, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import pool_slips, pool_tarot, pool_reader, pool_ui  # noqa: E402

OUT = HERE.parent / "pool"
OUT.mkdir(exist_ok=True)

slips = []
for i, (rank, subj, vz, ve, rz, re_, dz, de) in enumerate(pool_slips.SLIPS):
    slips.append(dict(id="%s-%s-%d" % (rank, subj, i), rank=rank, subject=subj,
                      verse_zh=vz, verse_en=ve, read_zh=rz, read_en=re_, do_zh=dz, do_en=de))
# --- ja (2026-09-23) -----------------------------------------------------------------
# tools/pool_ja.json maps every English string to its Japanese. 923 of the 995 are the
# translations Night Reading (the adult fork) already ships for the same English source;
# the reader's four forces and four UI lines were written for this game. The layer is
# added as a <field>_ja / "ja" sibling of every <field>_en / "en", and the build REFUSES on
# a missing string or on prose with no kana -- a zh string pasted into a ja slot passes
# every completeness test, which is how Floor 13 once shipped Chinese as Japanese.
import re  # noqa: E402
JA = json.loads((HERE / "pool_ja.json").read_text("utf-8"))
KANA = re.compile(r"[\u3040-\u30ff]").search
_bad = []


def add_ja(x, where=""):
    if isinstance(x, dict):
        for k in list(x.keys()):
            v = x[k]
            if isinstance(v, str) and (k == "en" or k.endswith("_en")):
                jk = "ja" if k == "en" else k[:-3] + "_ja"
                j = JA.get(v, "")
                if not j:
                    _bad.append("%s.%s: missing -- %s" % (where, k, v[:40]))
                elif not k.startswith("verse") and len(re.findall(r"[A-Za-z]{3,}", v)) >= 5 and not KANA(j):   # prose only: 大吉 is Japanese too
                    _bad.append("%s.%s: no kana -- %s" % (where, k, j[:24]))
                x[jk] = j
            else:
                add_ja(v, "%s.%s" % (where, k))
    elif isinstance(x, list):
        for i, v in enumerate(x):
            add_ja(v, "%s[%d]" % (where, i))
    return x


for name, obj in (("slips", slips),):
    add_ja(obj, name)
(OUT / "slips.json").write_text(json.dumps(slips, ensure_ascii=False, indent=0), "utf-8")
cards = add_ja(pool_tarot.cards(), "tarot")
(OUT / "tarot.json").write_text(json.dumps(cards, ensure_ascii=False, indent=0), "utf-8")
(OUT / "reader.json").write_text(json.dumps(add_ja(pool_reader.READER, "reader"), ensure_ascii=False, indent=0), "utf-8")
(OUT / "ui.json").write_text(json.dumps(add_ja(pool_ui.UI, "ui"), ensure_ascii=False, indent=0), "utf-8")
if _bad:
    print("ja layer incomplete, NOT writing a font subset:\n  " + "\n  ".join(_bad[:20]))
    raise SystemExit(1)
print("slips %d, cards %d (%d readings), ui %d keys" % (len(slips), len(cards), len(cards) * 2, len(pool_ui.UI)))
subprocess.check_call([sys.executable, str(HERE / "subset_font.py")])
