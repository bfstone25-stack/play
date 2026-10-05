#!/usr/bin/env python3
"""Writes data/game.json and data/art_manifest.json (the rules tables for Confession Room).
Kept as code so the numbers have comments; the night files come from build_nights.py.

The standoff IS the interrogation. Re-skin of the core's meters (strings override the core
keys in tools/strings_sys.py): the suspect's Resolve is their *Composure*; Reyes's Composure
is the *Case* (a solo party, one member); the enemy's Suspicion meter is the *Stonewall* --
at 100 they stop talking and ask for a lawyer, which ends the interview (a loss, reload).
Actions: Press / Bluff / Show evidence / Offer a deal / Lean in / Threaten / Wait / Use item,
plus the skill-granted Read them / Lay out the case / A quiet word.

    python3 tools/build_data.py
"""
import json
from pathlib import Path
D = Path(__file__).resolve().parent.parent / "data"
A = D.parent / "assets"
RPG_OUT = Path("/home/frankstone/Products/ops/confession_art/out/rpg")

SUSPECTS = ("nikolai", "adaeze", "vee")

ACTIONS = {
    # kind attack unless said; power + stat*scale, x1.75 on a weakness, x0.5 on a resist
    "deflect":  {"kind": "guard", "cost": 0, "susp": 4},                                   # Hold back
    "observe":  {"kind": "observe", "cost": 2, "susp": 2},                                 # Read them (skill)
    "press":    {"cost": 3, "stat": "grt", "power": 8, "scale": 1.6, "susp": 4},
    "bluff":    {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},
    "evidence": {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "evidence"},
    "bribe":    {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "cash"},   # Offer a deal (a marker)
    "flirt":    {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},            # Lean in
    "threaten": {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},
    "stall":    {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},                   # Wait
    "item":     {"kind": "item", "cost": 0},
    "casefile": {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": -3},          # Lay out the case (skill)
    "quiet":    {"cost": 4, "stat": "cha", "power": 11, "scale": 1.8, "susp": -4},          # A quiet word (skill)
}
SKILLS = {
    # Reyes: Procedure / Street (one person, two ways of doing the job)
    "paperwork": {"branch": "procedure", "req": 2, "mult": {"evidence": 0.3}},
    "patience":  {"branch": "procedure", "req": 4, "stat": {"stl": 2}},
    "method":    {"branch": "procedure", "req": 6, "stat": {"wit": 2}},
    "casefile_sk": {"branch": "procedure", "req": 9, "grant": "casefile"},
    "captain":   {"branch": "procedure", "req": 12, "mult": {"casefile": 0.4, "evidence": 0.2}},
    "cheap":     {"branch": "street", "req": 2, "mult": {"bribe": 0.3}},
    "face":      {"branch": "street", "req": 4, "mult": {"bluff": 0.3}},
    "thick":     {"branch": "street", "req": 6, "stat": {"grt": 2}},
    "quiet_sk":  {"branch": "street", "req": 9, "grant": "quiet"},
    "hard":      {"branch": "street", "req": 12, "mult": {"threaten": 0.4, "bluff": 0.2}},
}
ITEMS = {
    "marker":      {"kind": "cash"},                                   # a favour owed; Offer a deal spends one
    "coffee":      {"kind": "consumable", "heal_comp": 16},
    "cigarettes":  {"kind": "consumable", "heal_nerve": 8},
    "whisky":      {"kind": "consumable", "heal_comp": 28},
    "aspirin":     {"kind": "consumable", "heal_nerve": 14},
    # evidence, by case
    "alarm_log":   {"kind": "evidence"}, "docket": {"kind": "evidence"}, "key_list": {"kind": "evidence"}, "shoe": {"kind": "evidence"},
    "photo1":      {"kind": "evidence"}, "photo2": {"kind": "evidence"}, "photo3": {"kind": "evidence"},
    "ledgers":     {"kind": "evidence"}, "autopsy": {"kind": "evidence"}, "timer": {"kind": "evidence"}, "sink_note": {"kind": "evidence"},
    "folder":      {"kind": "evidence"}, "safe_photo": {"kind": "evidence"}, "yard_light": {"kind": "evidence"}, "vent_note": {"kind": "evidence"},
    # gifts: one per suspect, found in the world
    "lighter":     {"kind": "gift", "gift": True, "gift_trust": 1, "gift_track": "vee"},
    "cufflinks":   {"kind": "gift", "gift": True, "gift_trust": 1, "gift_track": "nikolai"},
    "pen":         {"kind": "gift", "gift": True, "gift_trust": 1, "gift_track": "adaeze"},
    # equipment: outfit / accessory / tool, all Reyes's
    "coat":        {"kind": "equip", "slot": "outfit", "for": "reyes", "bonus": {"grt": 1}},
    "raincoat":    {"kind": "equip", "slot": "outfit", "for": "reyes", "bonus": {"grt": 2}},
    "suit":        {"kind": "equip", "slot": "outfit", "for": "reyes", "bonus": {"cha": 2}, "mult": {"bribe": 0.2}},
    "badge":       {"kind": "equip", "slot": "accessory", "for": "reyes", "bonus": {"cha": 1}},
    "watch":       {"kind": "equip", "slot": "accessory", "for": "reyes", "bonus": {"wit": 1}},
    "notebook":    {"kind": "equip", "slot": "tool", "for": "reyes", "bonus": {"wit": 1}, "mult": {"evidence": 0.2}},
    "flask":       {"kind": "equip", "slot": "tool", "for": "reyes", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
    "recorder":    {"kind": "equip", "slot": "tool", "for": "reyes", "bonus": {"wit": 2}, "mult": {"evidence": 0.3}},
}
# the route facts the nine optional routes put on the board (evidence too)
for _stid in ("nik_curtain", "ade_seal", "vee_hands", "nik2_light", "ade2_mop", "vee2_seen", "nik3_tired", "ade3_office", "vee3_slow"):
    ITEMS["fact_" + _stid] = {"kind": "evidence"}

# Weaknesses change per case: that is the strategy (DESIGN.md §2). c = case, p = pressure.
# (weak, resist) per suspect per case; threaten is the coercion trap almost everyone resists.
WEAK = {
    "nikolai": {1: (["evidence", "bribe"], ["threaten", "bluff"]),
                2: (["flirt", "evidence"], ["bribe", "threaten"]),
                3: (["evidence", "press"], ["bribe", "bluff", "flirt"])},       # guilty, patient
    "adaeze":  {1: (["bluff", "flirt"], ["bribe", "threaten"]),
                2: (["evidence", "press"], ["flirt", "bribe"]),                  # guilty
                3: (["flirt", "bluff"], ["threaten", "evidence"])},
    "vee":     {1: (["flirt", "press"], ["bribe", "threaten"]),                  # guilty
                2: (["bribe", "flirt"], ["threaten", "press"]),
                3: (["bluff", "flirt"], ["threaten", "bribe"])},
}
GUILTY = {1: "vee", 2: "adaeze", 3: "nikolai"}
# Composure (Resolve), atk, stonewall rate, xp per pressure level, per case: a solo Reyes at
# level ~1-5 / 6-10 / 11-15. The guilty suspect's pressure-3 standoff is the night's boss.
# A solo Reyes hits for ~14 at level 1-3, ~19 at 6-9, ~24 at 11-14 (power + Wits x scale), one
# action a round: fights are sized to 5-9 hits, 8-12 rounds, so a standoff is 3-5 minutes.
CURVE = {1: [(55, 4, 6, 40), (80, 5, 7, 55), (100, 6, 7, 90)],
         2: [(150, 6, 7, 70), (200, 7, 8, 85), (280, 8, 9, 120)],
         3: [(220, 8, 8, 95), (300, 9, 9, 110), (400, 10, 10, 150)]}
BOSS_BONUS = {1: 40, 2: 60, 3: 90}
DROPS = {("nikolai", 1): "cigarettes", ("adaeze", 1): "coffee", ("vee", 1): "cigarettes",
         ("nikolai", 2): "whisky", ("adaeze", 2): "pen", ("vee", 2): "aspirin",
         ("nikolai", 3): "marker", ("adaeze", 3): "coffee", ("vee", 3): "whisky"}

ENEMIES = {}
for sid in SUSPECTS:
    for c in (1, 2, 3):
        weak, resist = WEAK[sid][c]
        for p, (comp, atk, rate, xp) in enumerate(CURVE[c], 1):
            boss = p == 3 and GUILTY[c] == sid
            e = {"name_key": "e_" + sid, "sprite": sid, "sprite_pressured": sid + "_pressured",
                 "composure": comp + (BOSS_BONUS[c] if boss else 0), "atk": atk, "susp_rate": rate,
                 "weak": weak, "resist": resist, "xp": xp + (40 if boss else 0),
                 "trust_win": 1, "trust_track": sid, "barks": 3, "bark_set": sid,
                 "intro_key": f"ei_{sid}_p{p}", "win_key": f"ew_{sid}_p{p}"}
            if p == 3:
                e["drop"] = DROPS[(sid, c)]
            if boss:
                e["boss"] = True
                e["barks"] = 4
                e["bark_set"] = sid + "_boss"
            ENEMIES[f"{sid}_c{c}_p{p}"] = e
# three minor people, one per night, in the way of a room
ENEMIES["bouncer"] = {"name_key": "e_bouncer", "sprite": "bouncer", "composure": 60, "atk": 5, "susp_rate": 6,
                      "weak": ["bribe", "threaten"], "resist": ["evidence", "bluff"], "xp": 45, "drop": "marker",
                      "barks": 3, "intro_key": "ei_bouncer", "win_key": "ew_bouncer"}
ENEMIES["sergeant"] = {"name_key": "e_sergeant", "sprite": "sergeant", "composure": 130, "atk": 7, "susp_rate": 8,
                       "weak": ["evidence", "bluff"], "resist": ["bribe", "flirt"], "xp": 80, "drop": "raincoat",
                       "barks": 3, "intro_key": "ei_sergeant", "win_key": "ew_sergeant"}
ENEMIES["lawyer"] = {"name_key": "e_lawyer", "sprite": "lawyer", "composure": 210, "atk": 9, "susp_rate": 9,
                     "weak": ["evidence", "press"], "resist": ["bluff", "flirt", "bribe"], "xp": 100, "drop": "recorder",
                     "barks": 3, "intro_key": "ei_lawyer", "win_key": "ew_lawyer"}

# room id -> the RPG plate slot confession_gen.py renders (None = a VN background, used as is)
ROOMS = {"precinct": None, "interview": None, "club": None, "cooler": None,
         "corridor": "room_corridor_bench", "lockup": "room_evidence_lockup", "archive": "room_archive",
         "morgue": "room_morgue", "back_office": "room_back_office", "alley": "room_alley",
         "loading_bay": "room_loading_bay", "mop_room": "room_mop_room", "fire_stairs": "room_fire_stairs",
         "flat": "room_flat", "safe_house": "room_safe_house"}
VN_BG = {"precinct": "bg_precinct", "interview": "bg_room", "club": "bg_club", "cooler": "bg_locker"}

game = {
    "title_key": "title", "logo": "res://assets/title/logo.png", "title_bg": "res://assets/title/keyvisual.webp",
    "fonts": {"body": "res://assets/fonts/CourierPrime-Regular.ttf", "display": "res://assets/fonts/StardosStencil-Bold.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-Regular.otf"},
    "ui": {"dust": "res://assets/title/haze.png", "vignette": "res://assets/title/vignette.png", "scrim": "res://assets/title/scrim.png",
           "dim": "res://assets/title/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
        "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
        "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
        "bar_under": "choice_idle", "bar_fill": "namebox", "bar_fill_gold": "title_hover", "modal": "confirm"}.items()}},
    "title_mood": {"ambient": "#d8d4dc", "torch": True, "zoom": 1.1, "offset": [300, 0]},
    # title: the VN's noir bed. The five others are the RPG's own (ops/vn_music.py confession-rpg,
    # the Elena beds pitched into this game's E minor), copied in by tools/import_art.py.
    "music": {"title": "res://assets/audio/noir_theme.ogg", "explore": "res://assets/audio/explore.ogg",
              "battle": "res://assets/audio/standoff.ogg", "boss": "res://assets/audio/boss.ogg",
              "intimate": "res://assets/audio/intimate.ogg", "dawn": "res://assets/audio/dawn.ogg",
              "pressure": "res://assets/audio/pressure.ogg"},
    "audio": {"ambience": "res://assets/audio/room_tone.ogg", "click": "res://assets/audio/ui_click.ogg",
              "page_flip": "res://assets/audio/ui_hover.ogg", "heartbeat": "res://assets/audio/heartbeat.ogg",
              "sting": "res://assets/audio/title_sting.ogg", "camera": "res://assets/audio/ui_click.ogg"},
    "disclosure_key": "about_ai",
    "trial_last_night": "night1", "trial_locked_cgs": ["cg_nikolai_x", "cg_adaeze_x", "cg_vee_x"],
    "store_url": "https://www.dlsite.com/maniax/work/=/product_id/RJ01722985.html",
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5, 7, 9],
    "trust_tracks": list(SUSPECTS),
    "party": [
        # a detective reads people: Read them is a base action, not a skill
        {"id": "reyes", "base": {"wit": 4, "cha": 3, "grt": 4, "stl": 2}, "grow": ["wit", "grt", "cha", "stl"],
         "actions": ["deflect", "observe", "press", "bluff", "evidence", "bribe", "flirt", "threaten", "stall", "item"],
         "branches": {"procedure": ["paperwork", "patience", "method", "casefile_sk", "captain"],
                      "street": ["cheap", "face", "thick", "quiet_sk", "hard"]}, "start_equip": {"outfit": "coat", "accessory": "badge"}},
    ],
    "start_items": {"coffee": 1, "marker": 2},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["night1", "night2", "night3", "epilogue"], "story": ["cases", "interr", "board", "start"],
    "gallery": [{"id": c, "thumb": c + "_thumb", "locked": c + "_locked", "key": "g_" + c, "trust": t} for c, t in [
        ("cg_intake", 0), ("cg_rpg_paloma", 0), ("cg_evidence_x", 0), ("cg_nikolai_x", 3), ("cg_adaeze_x", 3), ("cg_vee_x", 3),
        ("cg_closing", 0), ("cg_rpg_bay", 0), ("cg_evidence2_x", 0), ("cg_trust5_adaeze", 5),
        ("cg_rpg_stairs", 0), ("cg_evidence3_x", 0), ("cg_trust7_nikolai", 7), ("cg_trust9_vee", 9), ("cg_board", 0)]],
}

art = {"rooms": {r: ([f"res://assets/rpg/rooms/{slot}.png"] if slot else []) + [f"res://assets/placeholder/rooms/{r}.webp"]
                 for r, slot in ROOMS.items()},
       "rooms_locked": {r: [f"res://assets/placeholder/rooms_locked/{r}.webp"] for r in ROOMS},
       # the VN has no sprites: the rendered standoff art is the suspects' story sprite too
       "enemies": {**{s: [f"res://assets/rpg/enemies/enemy_{s}_neutral.png"] for s in SUSPECTS},
                   **{s + "_pressured": [f"res://assets/rpg/enemies/enemy_{s}_pressured.png"] for s in SUSPECTS},
                   **{m: [f"res://assets/rpg/enemies/enemy_{m}_neutral.png"] for m in ("bouncer", "sergeant", "lawyer")}},
       "sprites": {s: [f"res://assets/rpg/enemies/enemy_{s}_neutral.png"] for s in SUSPECTS + ("bouncer", "sergeant", "lawyer")},
       "maps": {"board": ["res://assets/rpg/rooms/floor_map.png"]},
       "cg": {}}
for f in sorted((A / "cg").glob("*.webp")) if (A / "cg").exists() else []:
    art["cg"][f.stem] = [f"res://assets/cg/{f.name}"]
for slot in ("cg_rpg_paloma", "cg_rpg_bay", "cg_rpg_stairs", "cg_trust5_adaeze", "cg_trust7_nikolai", "cg_trust9_vee"):
    art["cg"][slot] = [f"res://assets/rpg/cgs/{slot}.png"]   # new RPG CGs: shown only once rendered
    for suf in ("_thumb", "_locked"):
        art["cg"][slot + suf] = [f"res://assets/cg/{slot}{suf}.webp"]
for c in game["gallery"]:
    if not (A / "cg" / (c["locked"] + ".webp")).exists():
        c["locked"] = "cg_intake_locked"
# every installed render must be reachable from the game: a renamed slot fails the build
_mf = RPG_OUT / "manifest.json"
if _mf.exists():
    _used = set(s for s in ROOMS.values() if s) | {"floor_map"}
    for e in game["enemies"].values():
        for k in ("sprite", "sprite_pressured"):
            for pth in art["enemies"].get(e.get(k, ""), []):
                _used.add(Path(pth).stem)
    for c in game["gallery"]:
        _used.add(c["id"])
    _missing = [a["id"] for a in json.loads(_mf.read_text())["assets"] if a["id"] not in _used]
    if _missing:
        raise SystemExit("manifest assets not referenced by the game: " + ", ".join(_missing))
(D / "game.json").write_text(json.dumps(game, indent=1))
(D / "art_manifest.json").write_text(json.dumps(art, indent=1))
print(f"game.json ({len(ENEMIES)} enemies, {len(ITEMS)} items) + art_manifest.json written")


def _wire_voice():
    """Voice packs (ops/dlsite/voice_bulk.py wire): point the heroine lines at assets/voice/<lang>/.
    Idempotent; re-applied after every rebuild so a regenerated file keeps the packs."""
    import subprocess as _sp
    _w = Path(__file__).resolve().parents[3] / "ops/dlsite/voice_bulk.py"
    if _w.exists():
        _sp.run(["python3", str(_w), "wire", "confession"], check=False)


_wire_voice()
