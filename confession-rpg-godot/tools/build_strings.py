#!/usr/bin/env python3
"""Merge tools/strings_*.py tables into data/strings.json ({key: {en, ja, ...}}).
Other languages go in as extra tuple columns or a strings_<lang>.json overlay later."""
import json, importlib.util
from pathlib import Path
HERE = Path(__file__).resolve().parent
out = {}
for f in sorted(HERE.glob("strings_*.py")):
    spec = importlib.util.spec_from_file_location(f.stem, f); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    for k, v in m.S.items():
        if k in out: raise SystemExit(f"duplicate key {k} in {f.name}")
        out[k] = {"en": v[0], "ja": v[1]}
for ov in sorted((HERE.parent / "data/i18n").glob("*.json")) if (HERE.parent / "data/i18n").exists() else []:
    lang = ov.stem
    for k, v in json.loads(ov.read_text()).items():
        if k in out: out[k][lang] = v
(HERE.parent / "data/strings.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
print(len(out), "strings")
