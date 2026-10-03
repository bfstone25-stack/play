#!/usr/bin/env python3
"""Merge tools/strings_*.py tables into data/strings.json ({key: {en, ja}}), plus his hold
lines as standoff barks (EN = the fork's own hold_en, JA in strings_routes.py), and the stranger
intros (the battle opens on the same line as the street event). Other languages go in as a
data/i18n/<lang>.json overlay later."""
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
out = {}
mods = {}
for f in sorted(HERE.glob("strings_*.py")):
    spec = importlib.util.spec_from_file_location(f.stem, f)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    mods[f.stem] = m
    for k, v in m.S.items():
        if k in out:
            raise SystemExit(f"duplicate key {k} in {f.name}")
        out[k] = {"en": v[0], "ja": v[1]}
idx = json.loads((HERE.parent / "data/story_index.json").read_text())
R = mods["strings_routes"].R
for r, ri in idx.items():
    assert len(ri["hold_en"]) == 4 == len(R[r]["hold"]), r
    for i, (en, ja) in enumerate(zip(ri["hold_en"], R[r]["hold"]), 1):
        out[f"bark_hold_{r}_{i}"] = {"en": en, "ja": ja}
    for g in ("doorman", "paparazzo", "columnist"):
        out[f"ei_{g}_{r}"] = dict(out[f"pre_{g}"])
i18n = HERE.parent / "data/i18n"
for ov in sorted(i18n.glob("*.json")) if i18n.exists() else []:
    for k, v in json.loads(ov.read_text()).items():
        if k in out:
            out[k][ov.stem] = v
(HERE.parent / "data/strings.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
print(len(out), "strings")
