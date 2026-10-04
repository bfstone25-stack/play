#!/usr/bin/env python3
"""Write <game>/data/i18n/_src.json: every translatable unit of one title (strings table, story
lines, story menus) with its EN and JA text, so translators work from one file.
Targets (filled per language, merged at load time / by build_strings.py):
  data/i18n/<lang>.json          {string_key: text}
  data/i18n/story/<lang>.json    {"lines": {line_id: text}, "menus": {en_menu_text: text}}
  data/i18n/glossary/<lang>.json {en_term: text}   (names, places, recurring terms)
usage: i18n_extract.py play/<game>"""
import json, sys
from pathlib import Path

g = Path(sys.argv[1]).resolve()
src = {"strings": {}, "story": {}, "menus": {}}
for k, v in json.loads((g / "data/strings.json").read_text()).items():
    if isinstance(v, dict) and str(v.get("en", "")).strip():
        src["strings"][k] = {"en": v["en"], "ja": v.get("ja", "")}
game = json.loads((g / "data/game.json").read_text())
story_dir = g / "data/story"
for ch in game.get("story", []):
    p = story_dir / f"{ch}.json"
    if not p.exists():
        continue
    st = json.loads(p.read_text())
    for ln in st.get("lines", []):
        if str(ln.get("en", "")).strip():
            src["story"][ln["id"]] = {"who": ln.get("who", ""), "en": ln["en"], "ja": ln.get("ja", "")}
    for en, ja in st.get("menus", {}).items():
        src["menus"][en] = ja
(g / "data/i18n").mkdir(exist_ok=True)
(g / "data/i18n/_src.json").write_text(json.dumps(src, ensure_ascii=False, indent=1))
print(g.name, len(src["strings"]), "strings", len(src["story"]), "lines", len(src["menus"]), "menus")
