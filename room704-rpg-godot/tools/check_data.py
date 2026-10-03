#!/usr/bin/env python3
"""Cross-reference every shift's data: strings, speakers, story ranges, enemies, items, doors,
events, labels, barks, JA menu translations, plates. Exit 1 on any problem."""
import json, glob, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
S = json.load(open(R / "data/strings.json")); core = json.load(open(R / "addons/night_rpg/strings_core.json"))
G = json.load(open(R / "data/game.json"))
story = {c: json.load(open(R / f"data/story/{c}.json")) for c in G["story"]}
menus = {}
for c in story.values(): menus.update(c["menus"])
bad = []
def walk(steps, where):
    for s in steps:
        if "key" in s and s["key"] not in S and s["key"] not in core: bad.append((where, "key", s["key"]))
        if "say" in s and s["say"] != "narrator" and "n_" + s["say"] not in S: bad.append((where, "speaker", s["say"]))
        if "lines" in s:
            ch, r = s["lines"].split(":"); a, b = map(int, r.split("-"))
            ls = [l for l in story[ch]["lines"] if a <= l["src"] <= b]
            if not ls: bad.append((where, "empty range", s["lines"]))
            for l in ls:
                if not l.get("ja"): bad.append((where, "no JA", l["id"]))
                if l["who"] != "narrator" and "n_" + l["who"] not in S: bad.append((where, "speaker", l["who"]))
        if "battle" in s and s["battle"] not in G["enemies"]: bad.append((where, "enemy", s["battle"]))
        if "give" in s and s["give"] not in G["items"]: bad.append((where, "item", s["give"]))
        if "show" in s and s["show"]: pass
        if "choice" in s:
            for o in s["choice"]:
                if "menu" in o and o["menu"] not in menus: bad.append((where, "menu without JA", o["menu"][:40]))
                walk(o.get("do", []), where)
        for k in ("then", "else"):
            if k in s: walk(s[k], where)
nights = {}
for f in sorted(glob.glob(str(R / "data/nights/*.json"))):
    n = json.load(open(f)); f = Path(f).name; nights[n["id"]] = n
    for rid, r in n["rooms"].items():
        if r["name_key"] not in S: bad.append((f, "room name", r["name_key"]))
        if rid not in n["map"]["rooms"]: bad.append((f, "room not on map", rid))
        for h in r["hotspots"]:
            if h["kind"] == "enemy" and h["enemy"] not in G["enemies"]: bad.append((f, "enemy", h["enemy"]))
            if h["kind"] == "door" and h["to"] not in n["rooms"]: bad.append((f, "door", h["to"]))
            for it in h.get("gives", []):
                if it not in G["items"]: bad.append((f, "item", it))
            if h.get("needs") and h["needs"] not in G["items"]: bad.append((f, "needs", h["needs"]))
            if h.get("event") and h["event"] not in n["events"]: bad.append((f, "event", h["event"]))
            if h.get("after") and h["after"] not in n["events"]: bad.append((f, "after", h["after"]))
            lk = h.get("label_key", "hs_" + h["id"])
            if h["kind"] in ("search", "event") and lk not in S and lk not in core: bad.append((f, "label", lk))
        if r.get("enter_event") and r["enter_event"] not in n["events"]: bad.append((f, "enter", r["enter_event"]))
    for k, v in n["events"].items(): walk(v, f + ":" + k)
# every {"event": x} resolves in some night (the core searches all nights)
all_events = set()
for n in nights.values(): all_events |= set(n["events"])
def walk_ev(steps, where):
    for s in steps:
        if "event" in s and s["event"] not in all_events: bad.append((where, "no such event", s["event"]))
        if "choice" in s:
            for o in s["choice"]: walk_ev(o.get("do", []), where)
        for k in ("then", "else"):
            if k in s: walk_ev(s[k], where)
for n in nights.values():
    for k, v in n["events"].items(): walk_ev(v, n["id"] + ":" + k)
    if n["start_event"] not in n["events"]: bad.append((n["id"], "start_event", n["start_event"]))
for eid, e in G["enemies"].items():
    for key in (e["name_key"], e.get("intro_key"), e.get("win_key")):
        if key and key not in S: bad.append(("enemy", eid, key))
    for i in range(1, e.get("barks", 0) + 1):
        if f"bark_{e.get('bark_set', eid)}_{i}" not in S: bad.append(("bark", eid, i))
for it in G["items"]:
    if "i_" + it not in S or "id_" + it not in S: bad.append(("item text", it))
for sk in G["skills"]:
    if "sk_" + sk not in S or "skd_" + sk not in S: bad.append(("skill text", sk))
    if "br_" + G["skills"][sk]["branch"] not in S: bad.append(("branch text", sk))
for a in G["actions"]:
    if "a_" + a not in S or "ad_" + a not in S: bad.append(("action text", a))
for st in G["stats"]:
    if "s_" + st not in S or "sd_" + st not in S: bad.append(("stat text", st))
for m in G["party"]:
    if "n_" + m["id"] not in S: bad.append(("member name", m["id"]))
for c in G["gallery"]:
    if c["key"] not in S: bad.append(("gallery text", c["key"]))
for k, row in S.items():
    if not row.get("ja"): bad.append(("no JA string", k))
art = json.load(open(R / "data/art_manifest.json"))
used_plates = set()
for n in nights.values():
    for r in n["rooms"].values(): used_plates.add(r["plate"])
    txt = json.dumps(n["events"])
    for pl in art["rooms"]:
        if f'"bg": "{pl}"' in txt: used_plates.add(pl)
for pl in art["rooms"]:
    if pl not in used_plates: bad.append(("plate never used", pl))
    if not any((R / p.replace("res://", "")).exists() for p in art["rooms"][pl]): bad.append(("plate has no file", pl))
for pl in sorted(used_plates):
    have = [p for p in art["rooms"].get(pl, []) if (R / p.replace("res://", "")).exists()]
    if have and "/placeholder/" in have[0]: print(f"note: {pl} still on a placeholder plate")
for e in G["enemies"].values():
    for k in ("sprite", "sprite_pressured"):
        sp = e.get(k, "")
        if sp and not any((R / p.replace("res://", "")).exists() for p in art["enemies"].get(sp, [])): print(f"note: enemy art missing: {sp}")
for c in G["gallery"]:
    if not any((R / p.replace("res://", "")).exists() for p in art["cg"].get(c["id"], [])): print(f"note: CG not rendered yet: {c['id']}")
for lang in ("ja",):
    cov = sum(1 for r in S.values() if r.get(lang)) / len(S)
    if cov < 0.999: bad.append(("coverage", lang, cov))
for b in bad: print("BAD", *b)
print(f"check_data: {len(bad)} problem(s)")
sys.exit(1 if bad else 0)
