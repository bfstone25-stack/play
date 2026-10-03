#!/usr/bin/env python3
"""Cross-reference every night's data: strings, speakers, story ranges, enemies, items, doors,
events, labels, barks, trust tracks, music files, plates. Exit 1 on any problem.
JA: every RPG string must have a JA cell; the VN's lines have none (the VN was never
translated) and the game falls back to English for them -- reported as a count, not an error."""
import json, glob, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
S = json.load(open(R / "data/strings.json")); core = json.load(open(R / "addons/night_rpg/strings_core.json"))
G = json.load(open(R / "data/game.json"))
story = {k: json.load(open(R / f"data/story/{k}.json")) for k in G["story"]}
bad = []
tracks = set(G.get("trust_tracks", []))


def walk(steps, where):
    for s in steps:
        if "key" in s and s["key"] not in S and s["key"] not in core: bad.append((where, "key", s["key"]))
        if "say" in s and s["say"] != "narrator" and "n_" + s["say"] not in S: bad.append((where, "speaker", s["say"]))
        if "music" in s and s["music"] not in G["music"]: bad.append((where, "music key", s["music"]))
        if "show" in s and s["show"] and s["show"] not in art["sprites"]: bad.append((where, "sprite", s["show"]))
        if "cg" in s and s["cg"] not in art["cg"]: bad.append((where, "cg", s["cg"]))
        if "bg" in s and s["bg"] not in art["rooms"]: bad.append((where, "bg plate", s["bg"]))
        if "lines" in s:
            ch, r = s["lines"].split(":"); a, b = map(int, r.split("-"))
            ls = [l for l in story[ch]["lines"] if a <= l["src"] <= b]
            if not ls: bad.append((where, "empty range", s["lines"]))
            for l in ls:
                if "[" in l["en"] and "[b]" not in l["en"]: bad.append((where, "interpolated VN line used", l["id"]))
        if "battle" in s and s["battle"] not in G["enemies"]: bad.append((where, "enemy", s["battle"]))
        if "give" in s and s["give"] not in G["items"]: bad.append((where, "item", s["give"]))
        if "track" in s and s["track"] not in tracks: bad.append((where, "trust track", s["track"]))
        if "choice" in s:
            for o in s["choice"]:
                if "key" in o and o["key"] not in S and o["key"] not in core: bad.append((where, "choice key", o["key"]))
                if "req_track" in o and o["req_track"] not in tracks: bad.append((where, "req_track", o["req_track"]))
                walk(o.get("do", []), where)
        for k in ("then", "else"):
            if k in s: walk(s[k], where)
        if "event" in s and isinstance(s["event"], str) and s["event"] not in cur_events: bad.append((where, "event", s["event"]))


art = json.load(open(R / "data/art_manifest.json"))
for f in sorted(glob.glob(str(R / "data/nights/*.json"))):
    n = json.load(open(f)); f = Path(f).name
    cur_events = n["events"]
    if n["title_key"] not in S or n["sub_key"] not in S: bad.append((f, "night title", n["title_key"]))
    if n["start_event"] not in n["events"]: bad.append((f, "start event", n["start_event"]))
    for rid, r in n["rooms"].items():
        if r["name_key"] not in S: bad.append((f, "room name", r["name_key"]))
        if r["plate"] not in art["rooms"]: bad.append((f, "plate", r["plate"]))
        if rid not in n["map"]["rooms"]: bad.append((f, "room not on the map", rid))
        ids = set()
        for h in r["hotspots"]:
            if h["id"] in ids: bad.append((f, "duplicate hotspot id", rid, h["id"]))
            ids.add(h["id"])
            if h["kind"] == "enemy" and h["enemy"] not in G["enemies"]: bad.append((f, "enemy", h["enemy"]))
            if h["kind"] == "door" and h["to"] not in n["rooms"]: bad.append((f, "door", h["to"]))
            for it in h.get("gives", []):
                if it not in G["items"]: bad.append((f, "item", it))
            if h.get("event") and h["event"] not in n["events"]: bad.append((f, "event", h["event"]))
            if h.get("after") and h["after"] not in n["events"]: bad.append((f, "after", h["after"]))
            lk = h.get("label_key", "hs_" + h["id"])
            if h["kind"] in ("search", "event") and lk not in S: bad.append((f, "label", lk))
            if h["kind"] == "enemy" and "label_key" in h and lk not in S: bad.append((f, "label", lk))
        if r.get("enter_event") and r["enter_event"] not in n["events"]: bad.append((f, "enter", r["enter_event"]))
    for k, v in n["events"].items(): walk(v, f + ":" + k)
for eid, e in G["enemies"].items():
    for key in (e["name_key"], e.get("intro_key"), e.get("win_key")):
        if key and key not in S: bad.append(("enemy", eid, key))
    for i in range(1, e.get("barks", 0) + 1):
        if f"bark_{e.get('bark_set', eid)}_{i}" not in S: bad.append(("bark", eid, i))
    if e.get("trust_track") and e["trust_track"] not in tracks: bad.append(("enemy trust track", eid))
    for k in ("sprite", "sprite_pressured"):
        if e.get(k) and e[k] not in art["enemies"]: bad.append(("enemy sprite slot", eid, e[k]))
    if e.get("drop") and e["drop"] not in G["items"]: bad.append(("enemy drop", eid, e["drop"]))
for it, d in G["items"].items():
    if "i_" + it not in S or "id_" + it not in S: bad.append(("item text", it))
    if d.get("gift_track") and d["gift_track"] not in tracks: bad.append(("gift track", it))
for sk, d in G["skills"].items():
    for key in ("sk_" + sk, "skd_" + sk, "br_" + d["branch"]):
        if key not in S: bad.append(("skill text", sk, key))
    if d.get("grant") and d["grant"] not in G["actions"]: bad.append(("skill grant", sk))
for a in G["actions"]:
    for key in ("a_" + a, "ad_" + a):
        if key not in S and key not in core: bad.append(("action text", a, key))
for st in G["stats"]:
    for key in ("s_" + st, "sd_" + st):
        if key not in S: bad.append(("stat text", key))
for tr in tracks:
    if "n_" + tr not in S: bad.append(("track name", tr))
for c in G["gallery"]:
    if c["key"] not in S: bad.append(("gallery key", c["key"]))
    if c["id"] not in art["cg"]: bad.append(("gallery cg", c["id"]))
for k, row in S.items():
    if not row.get("ja"): bad.append(("no JA string", k))
for k, pth in G["music"].items():
    if not (R / pth.replace("res://", "")).exists(): bad.append(("music file missing", k, pth))
for k, pth in {**G["fonts"], **G["ui"]}.items():
    if not (R / pth.replace("res://", "")).exists(): bad.append(("asset missing", k, pth))
used_plates = set()
for f in glob.glob(str(R / "data/nights/*.json")):
    n = json.load(open(f))
    for r in n["rooms"].values(): used_plates.add(r["plate"])
    txt = json.dumps(n["events"])
    for pl in art["rooms"]:
        if f'"bg": "{pl}"' in txt: used_plates.add(pl)
for pl in art["rooms"]:
    if pl not in used_plates: bad.append(("room plate never used", pl))
# art that has arrived vs placeholders: informational unless --strict (the DLsite build)
on_placeholder = [pl for pl, cands in art["rooms"].items()
                  if not any((R / c.replace("res://", "")).exists() and "/rpg/" in c for c in cands) and pl not in ("precinct", "interview", "club", "cooler")]
missing_enemy = [k for k, cands in art["enemies"].items() if not any((R / c.replace("res://", "")).exists() for c in cands)]
missing_cg = [c["id"] for c in G["gallery"] if not any((R / p.replace("res://", "")).exists() for p in art["cg"][c["id"]])]
if "--strict" in sys.argv:
    for pl in on_placeholder: bad.append(("room still on placeholder art", pl))
    for k in missing_enemy: bad.append(("enemy art missing", k))
    for k in missing_cg: bad.append(("cg missing", k))
vn_lines = sum(len(s["lines"]) for s in story.values())
vn_ja = sum(1 for s in story.values() for l in s["lines"] if l.get("ja"))
for b in bad[:60]: print("BAD", b)
print(f"check_data: {len(bad)} problem(s); {len(S)} RPG strings EN+JA; VN lines {vn_lines} ({vn_ja} with JA -> EN fallback for the rest); "
      f"rooms on placeholder {len(on_placeholder)}, enemy art missing {len(missing_enemy)}, cgs missing {len(missing_cg)}")
sys.exit(1 if bad else 0)
