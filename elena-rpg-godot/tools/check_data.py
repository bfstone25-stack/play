#!/usr/bin/env python3
"""Cross-reference every night's data: strings, speakers, story ranges, enemies, items, doors,
events, labels, barks, JA menu translations. Exit 1 on any problem."""
import json, glob, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
S = json.load(open(R / "data/strings.json")); core = json.load(open(R / "addons/night_rpg/strings_core.json"))
G = json.load(open(R / "data/game.json"))
story = {f"ch{i}": json.load(open(R / f"data/story/ch{i}.json")) for i in range(1, 6)}
menus = {}
for c in story.values(): menus.update(c["menus"])
bad = []
def walk(steps, where):
    for s in steps:
        if "key" in s and s["key"] not in S and s["key"] not in core: bad.append((where, "key", s["key"]))
        if "say" in s and s["say"] != "narrator" and "n_" + s["say"] not in S: bad.append((where, "speaker", s["say"]))
        if s.get("say") == "elena" and "key" in s:   # every RPG-only Elena line is voiced (ops/elena_rpg_voice.py)
            v = G.get("voice", {}).get(s["key"], {}).get("v_en", "")
            if not v: bad.append((where, "elena line unvoiced", s["key"]))
            elif not (R / v.replace("res://", "")).exists(): bad.append((where, "voice file missing", v))
        if "music" in s and s["music"] not in G["music"]: bad.append((where, "music key", s["music"]))
        if "lines" in s:
            ch, r = s["lines"].split(":"); a, b = map(int, r.split("-"))
            ls = [l for l in story[ch]["lines"] if a <= l["src"] <= b]
            if not ls: bad.append((where, "empty range", s["lines"]))
            for l in ls:
                if not l.get("ja"): bad.append((where, "no JA", l["id"]))
        if "battle" in s and s["battle"] not in G["enemies"]: bad.append((where, "enemy", s["battle"]))
        if "give" in s and s["give"] not in G["items"]: bad.append((where, "item", s["give"]))
        if "choice" in s:
            for o in s["choice"]:
                if "menu" in o and o["menu"] not in menus: bad.append((where, "menu without JA", o["menu"][:40]))
                walk(o.get("do", []), where)
        for k in ("then", "else"):
            if k in s: walk(s[k], where)
for f in sorted(glob.glob(str(R / "data/nights/*.json"))):
    n = json.load(open(f)); f = Path(f).name
    for rid, r in n["rooms"].items():
        if r["name_key"] not in S: bad.append((f, "room name", r["name_key"]))
        for h in r["hotspots"]:
            if h["kind"] == "enemy" and h["enemy"] not in G["enemies"]: bad.append((f, "enemy", h["enemy"]))
            if h["kind"] == "door" and h["to"] not in n["rooms"]: bad.append((f, "door", h["to"]))
            for it in h.get("gives", []):
                if it not in G["items"]: bad.append((f, "item", it))
            if h.get("event") and h["event"] not in n["events"]: bad.append((f, "event", h["event"]))
            if h.get("after") and h["after"] not in n["events"]: bad.append((f, "after", h["after"]))
            lk = h.get("label_key", "hs_" + h["id"])
            if h["kind"] in ("search", "event") and lk not in S: bad.append((f, "label", lk))
        if r.get("enter_event") and r["enter_event"] not in n["events"]: bad.append((f, "enter", r["enter_event"]))
    for k, v in n["events"].items(): walk(v, f + ":" + k)
for eid, e in G["enemies"].items():
    for key in (e["name_key"], e.get("intro_key"), e.get("win_key")):
        if key and key not in S: bad.append(("enemy", eid, key))
    for i in range(1, e.get("barks", 0) + 1):
        if f"bark_{e.get('bark_set', eid)}_{i}" not in S: bad.append(("bark", eid, i))
for it in G["items"]:
    if "i_" + it not in S or "id_" + it not in S: bad.append(("item text", it))
for k, row in S.items():
    if not row.get("ja"): bad.append(("no JA string", k))
art = json.load(open(R / "data/art_manifest.json"))
used_plates = set()
for f in glob.glob(str(R / "data/nights/*.json")):
    n = json.load(open(f))
    for r in n["rooms"].values(): used_plates.add(r["plate"])
    txt = json.dumps(n["events"])
    for pl in art["rooms"]:
        if f'"bg": "{pl}"' in txt: used_plates.add(pl)
for pl in art["rooms"]:
    if pl not in used_plates: bad.append(("room plate never used", pl))
for pl, cands in art["rooms"].items():
    if not any((R / c.replace("res://", "")).exists() and "/rpg/" in c for c in cands) and pl != "study":
        bad.append(("room still on placeholder art", pl))
for slot, keys in G.get("heroine_barks", {}).items():   # her standoff barks: string + voice file
    for k in (keys if isinstance(keys, list) else []):
        if k not in S: bad.append(("heroine bark string", slot, k))
        v = G.get("voice", {}).get(k, {}).get("v_en", "")
        if not v or not (R / v.replace("res://", "")).exists(): bad.append(("heroine bark unvoiced", slot, k))
for k, pth in G["music"].items():
    if not (R / pth.replace("res://", "")).exists(): bad.append(("music file missing", k, pth))
for b in bad[:50]: print("BAD", b)
print(f"check_data: {len(bad)} problem(s)")
sys.exit(1 if bad else 0)
