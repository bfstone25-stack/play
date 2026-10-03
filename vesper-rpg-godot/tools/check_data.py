#!/usr/bin/env python3
"""Cross-reference every night: strings, speakers, story ranges, enemies, items, doors, events,
labels, barks, the JA columns, plates, CGs. Exit 1 on any problem.

JA rule (stated plainly in the README and on the store page): every RPG string and every RPG
menu is EN+JA; the parent's story prose (data/story/<route>_*.json lines and its choice texts)
has no Japanese and falls back to English. --strict also fails on a placeholder plate, a
missing enemy/outfit render or a missing CG."""
import glob
import json
import sys
from pathlib import Path

R = Path(__file__).resolve().parent.parent
STRICT = "--strict" in sys.argv
S = json.load(open(R / "data/strings.json"))
core = json.load(open(R / "addons/night_rpg/strings_core.json"))
G = json.load(open(R / "data/game.json"))
story = {c: json.load(open(R / f"data/story/{c}.json")) for c in G["story"]}
rpg_menus = story["rpg"]["menus"]
parent_menus = set()
idx = json.load(open(R / "data/story_index.json"))
for ri in idx.values():
    for ch in ri["chapters"]:
        for cj in ch["choices"]:
            for o in cj["options"]:
                parent_menus.add(o["text_en"])
bad = []


def walk(steps, where):
    for s in steps:
        if "key" in s and s["key"] not in S and s["key"] not in core:
            bad.append((where, "key", s["key"]))
        if "say" in s and s["say"] != "narrator" and "n_" + s["say"] not in S:
            bad.append((where, "speaker", s["say"]))
        if "lines" in s:
            ch, r = s["lines"].split(":")
            a, b = map(int, r.split("-"))
            ls = [ln for ln in story[ch]["lines"] if a <= ln["src"] <= b]
            if not ls:
                bad.append((where, "empty range", s["lines"]))
            for ln in ls:
                if ln["who"] != "narrator" and "n_" + ln["who"] not in S:
                    bad.append((where, "speaker", ln["who"]))
                if not ln.get("en"):
                    bad.append((where, "no EN", ln["id"]))
        if "battle" in s and s["battle"] not in G["enemies"]:
            bad.append((where, "enemy", s["battle"]))
        if "give" in s and s["give"] not in G["items"]:
            bad.append((where, "item", s["give"]))
        if "choice" in s:
            for o in s["choice"]:
                if "menu" in o and o["menu"] not in rpg_menus and o["menu"] not in parent_menus:
                    bad.append((where, "menu neither RPG (with JA) nor parent", o["menu"][:40]))
                if "if_night" in o and o["if_night"] not in G["nights"]:
                    bad.append((where, "if_night", o["if_night"]))
                walk(o.get("do", []), where)
        for k in ("then", "else"):
            if k in s:
                walk(s[k], where)


nights = {}
for f in sorted(glob.glob(str(R / "data/nights/*.json"))):
    n = json.load(open(f))
    f = Path(f).name
    nights[n["id"]] = n
    for k in (n["title_key"], n["sub_key"]):
        if k not in S:
            bad.append((f, "night card", k))
    for rid, r in n["rooms"].items():
        if r["name_key"] not in S:
            bad.append((f, "room name", r["name_key"]))
        if rid not in n["map"]["rooms"]:
            bad.append((f, "room not on map", rid))
        for h in r["hotspots"]:
            if h["kind"] == "enemy" and h["enemy"] not in G["enemies"]:
                bad.append((f, "enemy", h["enemy"]))
            if h["kind"] == "door" and h["to"] not in n["rooms"]:
                bad.append((f, "door", h["to"]))
            for it in h.get("gives", []):
                if it not in G["items"]:
                    bad.append((f, "item", it))
            for k in ("event", "after"):
                if h.get(k) and h[k] not in n["events"]:
                    bad.append((f, k, h[k]))
            lk = h.get("label_key", "hs_" + h["id"])
            if h["kind"] in ("search", "event", "door") and h.get("label_key") and lk not in S and lk not in core:
                bad.append((f, "label", lk))
        if r.get("enter_event") and r["enter_event"] not in n["events"]:
            bad.append((f, "enter", r["enter_event"]))
    for k, v in n["events"].items():
        walk(v, f + ":" + k)
    if n["start_event"] not in n["events"]:
        bad.append((n["id"], "start_event", n["start_event"]))
for nid in G["nights"]:
    if nid not in nights:
        bad.append(("game", "night file missing", nid))
# every story line is reached by some night
used = {}
for n in nights.values():
    for m in json.dumps(n["events"]).split('"lines": "')[1:]:
        rng = m.split('"')[0]
        ch, r = rng.split(":")
        a, b = map(int, r.split("-"))
        used.setdefault(ch, set()).update(range(a, b + 1))
for ch, st in story.items():
    for ln in st["lines"]:
        if ln["src"] not in used.get(ch, set()):
            bad.append(("story line never shown", ln["id"]))
for eid, e in G["enemies"].items():
    for key in (e["name_key"], e.get("intro_key"), e.get("win_key")):
        if key and key not in S:
            bad.append(("enemy", eid, key))
    for i in range(1, e.get("barks", 0) + 1):
        if f"bark_{e.get('bark_set', eid)}_{i}" not in S:
            bad.append(("bark", eid, i))
for it in G["items"]:
    if "i_" + it not in S or "id_" + it not in S:
        bad.append(("item text", it))
for sk in G["skills"]:
    if "sk_" + sk not in S or "skd_" + sk not in S:
        bad.append(("skill text", sk))
for a in G["actions"]:
    if "a_" + a not in S or "ad_" + a not in S:
        bad.append(("action text", a))
for st in G["stats"]:
    if "s_" + st not in S or "sd_" + st not in S:
        bad.append(("stat text", st))
for c in G["gallery"]:
    if c["key"] not in S and c["key"] not in core:
        bad.append(("gallery text", c["key"]))
for k, row in S.items():
    if not row.get("ja") and row.get("en"):
        bad.append(("no JA string", k))
for en, ja in rpg_menus.items():
    if not ja:
        bad.append(("RPG menu without JA", en[:40]))
for k in G.get("voice", {}):
    p = G["voice"][k]["v_en"].replace("res://", "")
    if not (R / p).exists():
        bad.append(("voice file missing", p))
art = json.load(open(R / "data/art_manifest.json"))


def exists(group, i):
    return [p for p in art[group].get(i, []) if (R / p.replace("res://", "")).exists()]


used_plates = set()
for n in nights.values():
    for r in n["rooms"].values():
        used_plates.add(r["plate"])
        if r.get("heroine_pose") and not exists("sprites", r["heroine_pose"]):
            bad.append(("figure missing", r["heroine_pose"]))
for pl in art["rooms"]:
    if pl not in used_plates:
        bad.append(("plate never used", pl))
    have = exists("rooms", pl)
    if not have:
        bad.append(("plate has no file", pl))
    elif STRICT and "/placeholder/" in have[0]:
        bad.append(("placeholder plate", pl))
for e in G["enemies"].values():
    for k in ("sprite", "sprite_pressured"):
        sp = e.get(k, "")
        if sp and not exists("enemies", sp) and STRICT:
            bad.append(("enemy art missing", sp))
for it in G["items"].values():
    if it.get("sprite") and not exists("sprites", it["sprite"]) and STRICT:
        bad.append(("outfit art missing", it["sprite"]))
if STRICT and not exists("maps", "city")[0].endswith("v_city_map.png"):
    bad.append(("city map is the placeholder",))
alltxt = json.dumps([n["events"] for n in nights.values()])
for c in G["gallery"]:
    if not exists("cg", c["id"]):
        bad.append(("CG missing", c["id"]))
    if f'"cg": "{c["id"]}"' not in alltxt:
        bad.append(("gallery CG never shown", c["id"]))
for b in bad:
    print("BAD", *b)
print(f"check_data: {len(bad)} problem(s){' (strict)' if STRICT else ''}")
sys.exit(1 if bad else 0)
