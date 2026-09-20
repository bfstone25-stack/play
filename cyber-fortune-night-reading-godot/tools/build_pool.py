#!/usr/bin/env python3
"""Emit pool/*.json from the hand-written pools in tools/pool_*.py, then subset the CJK
font to exactly the characters the game can display (tools/subset_font.py)."""
import json, pathlib, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import pool_slips, pool_tarot, pool_ui, pool_night  # noqa: E402

OUT = HERE.parent / "pool"
OUT.mkdir(exist_ok=True)

slips = []
for i, (rank, subj, vz, ve, rz, re_, dz, de) in enumerate(pool_slips.SLIPS):
    slips.append(dict(id="%s-%s-%d" % (rank, subj, i), rank=rank, subject=subj,
                      verse_zh=vz, verse_en=ve, read_zh=rz, read_en=re_, do_zh=dz, do_en=de))
(OUT / "slips.json").write_text(json.dumps(slips, ensure_ascii=False, indent=0), "utf-8")
cards = pool_tarot.cards()
(OUT / "tarot.json").write_text(json.dumps(cards, ensure_ascii=False, indent=0), "utf-8")
(OUT / "night.json").write_text(json.dumps(pool_night.CAST, ensure_ascii=False, indent=0), "utf-8")
# The fork's strings win over the parent's where they collide (title, series).
ui = dict(pool_ui.UI)
ui.update(pool_night.UI_NIGHT)
(OUT / "ui.json").write_text(json.dumps(ui, ensure_ascii=False, indent=0), "utf-8")
print("slips %d, cards %d (%d readings), cast %d, ui %d keys" % (len(slips), len(cards), len(cards) * 2, len(pool_night.CAST), len(ui)))
subprocess.check_call([sys.executable, str(HERE / "subset_font.py")])
