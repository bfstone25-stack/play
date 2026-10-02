#!/usr/bin/env python3
"""Writes data/game.json and data/art_manifest.json (the rules tables for Elena).
Kept as code so the numbers have comments; the night files are hand-written JSON."""
import json
from pathlib import Path
D = Path(__file__).resolve().parent.parent / "data"

ACTIONS = {
    # kind attack unless said; power + stat*scale, x1.75 on a weakness, x0.5 on a resist
    "deflect":  {"kind": "guard", "cost": 0, "susp": 4},
    "observe":  {"kind": "observe", "cost": 2, "susp": 2},
    "bluff":    {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},
    "evidence": {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "evidence"},
    "bribe":    {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "cash"},
    "flirt":    {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},
    "threaten": {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},
    "stall":    {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},
    "item":     {"kind": "item", "cost": 0},
    "lecture":  {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": 4},
    "recite":   {"cost": 4, "stat": "wit", "power": 10, "scale": 1.8, "susp": -4},
}
SKILLS = {
    # Vance: Scholar / Rogue
    "footnote":  {"branch": "scholar", "req": 2, "mult": {"evidence": 0.3}},
    "tenure":    {"branch": "scholar", "req": 4, "max_comp": 10},
    "recall":    {"branch": "scholar", "req": 6, "stat": {"wit": 2}},
    "lectern":   {"branch": "scholar", "req": 9, "grant": "lecture"},
    "emeritus":  {"branch": "scholar", "req": 12, "mult": {"lecture": 0.4, "evidence": 0.2}},
    "palm":      {"branch": "rogue", "req": 2, "mult": {"bribe": 0.3}},
    "poker":     {"branch": "rogue", "req": 4, "mult": {"bluff": 0.3}},
    "cold":      {"branch": "rogue", "req": 6, "stat": {"grt": 2}},
    "backstair": {"branch": "rogue", "req": 9, "mult": {"stall": 0.4}},
    "iron":      {"branch": "rogue", "req": 12, "mult": {"threaten": 0.4, "bluff": 0.2}},
    # Elena: Archivist / Accomplice
    "index":     {"branch": "archivist", "req": 2, "mult": {"evidence": 0.3}},
    "memory":    {"branch": "archivist", "req": 4, "stat": {"wit": 2}},
    "tongues":   {"branch": "archivist", "req": 6, "grant": "recite"},
    "lockwork":  {"branch": "archivist", "req": 9, "stat": {"stl": 2}},
    "provenance":{"branch": "archivist", "req": 12, "mult": {"evidence": 0.4, "recite": 0.3}},
    "smile":     {"branch": "accomplice", "req": 2, "mult": {"flirt": 0.3}},
    "poise":     {"branch": "accomplice", "req": 4, "max_comp": 10},
    "lie":       {"branch": "accomplice", "req": 6, "mult": {"bluff": 0.4}},
    "steady":    {"branch": "accomplice", "req": 9, "stat": {"grt": 2}},
    "alibi":     {"branch": "accomplice", "req": 12, "mult": {"stall": 0.4, "flirt": 0.2}},
}
ITEMS = {
    "cash":          {"kind": "cash"},
    "tea":           {"kind": "consumable", "heal_comp": 16},
    "sherry":        {"kind": "consumable", "heal_nerve": 8},
    "hip_flask":     {"kind": "gift", "gift": True, "gift_trust": 1},
    "override_key":  {"kind": "key"},
    "deaccession":   {"kind": "evidence"},
    "porter_rota":   {"kind": "evidence"},
    "ledger":        {"kind": "evidence"},
    "torch":         {"kind": "equip", "slot": "tool", "for": "vance", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
    "tweed":         {"kind": "equip", "slot": "outfit", "for": "vance", "bonus": {"grt": 1}},
    "signet":        {"kind": "equip", "slot": "accessory", "for": "vance", "bonus": {"cha": 1}},
    "raincoat":      {"kind": "equip", "slot": "outfit", "for": "elena", "bonus": {"grt": 1}},
    "cardigan":      {"kind": "equip", "slot": "outfit", "for": "elena", "bonus": {"cha": 1}, "mult": {"flirt": 0.2}, "sprite": "elena_soft"},
    "spectacles":    {"kind": "equip", "slot": "accessory", "for": "elena", "bonus": {"wit": 1}},
    "survey":        {"kind": "evidence"},
    "plan_1994":     {"kind": "evidence"},
    "page_two":      {"kind": "evidence"},
    "gift_pen":      {"kind": "gift", "gift": True, "gift_trust": 1},
    "brandy":        {"kind": "consumable", "heal_nerve": 14},
    "biscuits":      {"kind": "consumable", "heal_comp": 28},
    "keyring":       {"kind": "equip", "slot": "tool", "for": "vance", "bonus": {"stl": 2}},
    "gown":          {"kind": "equip", "slot": "outfit", "for": "elena", "bonus": {"wit": 1}, "mult": {"recite": 0.3}, "sprite": "outfit_gown"},
    "evening":       {"kind": "equip", "slot": "outfit", "for": "elena", "bonus": {"cha": 2}, "mult": {"flirt": 0.3}, "sprite": "outfit_evening"},
}
ENEMIES = {
    # weak/resist are what the player learns; xp/drop/trust_win are the reward
    "cobb":        {"name_key": "e_cobb", "sprite": "cobb", "composure": 55, "atk": 5, "susp_rate": 7,
                    "weak": ["bribe"], "resist": ["threaten"], "xp": 40, "drop": "porter_rota",
                    "barks": 3, "intro_key": "ei_cobb", "win_key": "ew_cobb"},
    "penhallow":   {"name_key": "e_penhallow", "sprite": "penhallow", "composure": 480, "atk": 7, "susp_rate": 11,
                    "weak": ["evidence", "flirt"], "resist": ["bribe", "threaten"], "xp": 55, "drop": "sherry",
                    "trust_win": 1, "barks": 3, "intro_key": "ei_penhallow", "win_key": "ew_penhallow"},
    "cobb_return": {"name_key": "e_cobb_return", "sprite": "cobb", "composure": 500, "atk": 7, "susp_rate": 11,
                    "weak": ["evidence", "recite", "stall"], "resist": ["bribe", "threaten"], "xp": 60, "drop": "cardigan",
                    "trust_win": 1, "barks": 3, "intro_key": "ei_cobb_return", "win_key": "ew_cobb_return"},
    # nights 2-5 (VN cast keep VN sprites; new people use the rendered RPG enemy art)
    **{eid: {"name_key": "e_" + eid, "sprite": spr, "composure": c, "atk": atk, "susp_rate": rate, "weak": w, "resist": r,
             "xp": xp, "drop": drop, "trust_win": 1 if boss else 0, "barks": 3, "bark_set": bark, "intro_key": "ei_" + bark, "win_key": "ew_" + bark,
             **({"boss": True, "barks": 4} if boss else {})}
       for eid, spr, c, atk, rate, w, r, xp, drop, bark, boss in [
        ("vey", "secretary", 560, 8, 11, ["evidence", "stall"], ["bribe", "bluff"], 70, "tea", "vey", False),
        ("hollis", "security_guard", 580, 9, 11, ["bribe", "flirt"], ["evidence", "threaten"], 70, "cash", "hollis", False),
        ("grice", "deans_man_a", 600, 10, 11, ["bluff", "flirt"], ["threaten", "bribe"], 75, "sherry", "grice", False),
        ("crane", "deans_man_b", 760, 10, 9, ["evidence", "recite"], ["bribe", "bluff", "threaten"], 150, "biscuits", "crane", True),
        ("grice_n3", "deans_man_a", 660, 11, 11, ["bluff", "flirt"], ["threaten", "bribe"], 90, "cash", "grice", False),
        ("sallis", "rival_archivist", 700, 10, 11, ["evidence", "bluff", "recite"], ["flirt", "bribe"], 95, "spectacles", "sallis", False),
        ("ambrose", "solicitor", 720, 10, 11, ["evidence", "threaten"], ["bluff", "bribe"], 95, "brandy", "ambrose", False),
        ("penhallow_boss", "penhallow", 900, 12, 9, ["evidence", "flirt"], ["bribe", "threaten"], 200, "signet", "penhallow_boss", True),
        ("vey_n4", "secretary", 760, 12, 11, ["evidence", "stall", "flirt"], ["bribe", "bluff"], 110, "tea", "vey", False),
        ("hollis_n4", "security_guard", 680, 12, 11, ["bribe", "flirt"], ["evidence", "threaten"], 110, "cash", "hollis", False),
        ("dean_tea", "dean_holloway", 1000, 12, 8, ["recite", "lecture", "evidence"], ["bluff", "flirt", "bribe", "threaten"], 240, "brandy", "dean_tea", True),
        ("crane_n4", "deans_man_b", 820, 12, 11, ["evidence", "recite"], ["bribe", "bluff", "threaten"], 120, "biscuits", "crane", False),
        ("crane_n5", "deans_man_b", 900, 13, 11, ["evidence", "recite"], ["bribe", "bluff", "threaten"], 130, "tea", "crane", False),
        ("grice_n5", "deans_man_a", 880, 13, 11, ["bluff", "flirt"], ["threaten", "bribe"], 130, "sherry", "grice", False),
        ("ambrose_n5", "solicitor", 920, 13, 11, ["evidence", "threaten"], ["bluff", "bribe"], 140, "brandy", "ambrose", False),
        ("penhallow_final", "penhallow", 1200, 14, 9, ["evidence", "recite", "lecture"], ["bribe", "threaten", "flirt"], 300, "biscuits", "penhallow_final", True),
    ]},
    "dean_dawn_solo": {"name_key": "e_dean", "sprite": "dean_holloway", "composure": 300, "atk": 7, "susp_rate": 7,
                    "boss": True, "weak": ["bluff", "stall"], "resist": ["bribe", "threaten"], "xp": 120,
                    "drop": "signet", "barks": 4, "bark_set": "dean_dawn", "intro_key": "ei_dean", "win_key": "ew_dean"},
    "dean_dawn":   {"name_key": "e_dean", "sprite": "dean_holloway", "composure": 520, "atk": 8, "susp_rate": 7,
                    "boss": True, "weak": ["bluff", "deflect", "stall"], "resist": ["flirt", "bribe", "threaten"], "xp": 120,
                    "drop": "signet", "barks": 4, "intro_key": "ei_dean", "win_key": "ew_dean"},
}
# our room id -> the RPG plate slot ops/elena_art/elena_gen.py renders (out/rpg/rooms/<slot>.png)
ROOMS = {"study": None, "vault": "room_sealed_vault", "corridor": "room_porters_lodge", "stair": "room_crypt_stair",
         "stacks": "room_stacks", "cellar": "room_coal_store", "dock": "room_records_basement", "muniment": "room_muniment_room",
         "reading_room": "room_reading_room", "common_room": "room_faculty_common_room", "deans_corridor": "room_deans_corridor",
         "annex": "room_chapel_annex", "deans_office": "room_deans_office", "carrel": "room_elena_carrel"}

game = {
    "title_key": "title", "logo": "res://assets/title/logo.png", "title_bg": "res://assets/title/keyvisual.webp",
    "fonts": {"body": "res://assets/fonts/CormorantGaramond-SemiBold.ttf", "display": "res://assets/fonts/Cinzel-Bold.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-Regular.otf"},
    "ui": {"dust": "res://assets/title/dust.png", "vignette": "res://assets/title/vignette.png", "scrim": "res://assets/title/scrim.png", "dim": "res://assets/title/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
        "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
        "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
        "bar_under": "choice_idle", "bar_fill": "namebox", "bar_fill_gold": "title_hover", "modal": "confirm"}.items()}},
    "title_mood": {"ambient": "#d8d0dc", "torch": True, "zoom": 1.12, "offset": [250, 0]},
    "music": {"title": "res://assets/audio/suspense_theme.ogg", "explore": "res://assets/audio/suspense_theme.ogg",
              "battle": "res://assets/audio/suspense_theme.ogg", "boss": "res://assets/audio/suspense_theme.ogg",
              "intimate": "res://assets/audio/ecchi_theme.ogg"},
    "audio": {"ambience": "res://assets/audio/rain_ambience.ogg", "click": "res://assets/audio/ui_click.ogg",
              "page_flip": "res://assets/audio/page_flip.ogg", "heartbeat": "res://assets/audio/heartbeat.ogg",
              "sting": "res://assets/audio/title_sting.ogg", "camera": "res://assets/audio/click.ogg"},
    "disclosure_key": "about_ai",
    "trial_last_night": "night1", "trial_locked_cgs": ["cg_climax_control", "cg_climax_pact"],
    "store_url": "https://www.dlsite.com/maniax/work/=/product_id/RJ01722365.html",
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5, 7, 9],
    "heroine_flag": "elena_joined", "heroine_sprite": "elena_neutral",
    "party": [
        {"id": "vance", "base": {"wit": 4, "cha": 2, "grt": 3, "stl": 2}, "grow": ["wit", "grt", "cha", "stl"],
         "actions": ["deflect", "bluff", "evidence", "bribe", "threaten", "stall", "item"],
         "branches": {"scholar": ["footnote", "tenure", "recall", "lectern", "emeritus"],
                      "rogue": ["palm", "poker", "cold", "backstair", "iron"]}, "start_equip": {"outfit": "tweed"}},
        {"id": "elena", "join_flag": "elena_joined", "base": {"wit": 3, "cha": 4, "grt": 2, "stl": 3},
         "grow": ["cha", "wit", "stl", "grt"],
         "actions": ["deflect", "observe", "bluff", "evidence", "flirt", "stall", "item"],
         "branches": {"archivist": ["index", "memory", "tongues", "lockwork", "provenance"],
                      "accomplice": ["smile", "poise", "lie", "steady", "alibi"]}, "start_equip": {"outfit": "raincoat"}},
    ],
    "start_items": {"tea": 1},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["night1", "night2", "night3", "night4", "night5"], "story": ["ch1", "ch2", "ch3", "ch4", "ch5"],
    "gallery": [{"id": c, "thumb": c + "_thumb", "locked": c + "_locked",
                 "key": "g_" + c, "trust": t} for c, t in [("cg_confrontation", 0), ("cg_climax_pact", 3), ("cg_climax_control", 3),
                                                          ("cg_aftermath", 0), ("cg_coal_store", 5), ("cg_ch2_office", 5), ("cg_ch3_crypt", 7),
                                                          ("cg_annex", 0), ("cg_ch4_chapel", 7), ("cg_muniment", 0), ("cg_ch5_muniment", 9),
                                                          ("cg_rpg_rain_arrival", 0), ("cg_rpg_map_room", 0), ("cg_rpg_lockpick", 0), ("cg_rpg_bell_chamber", 0),
                                                          ("cg_rpg_roof_dawn", 0), ("cg_rpg_gala", 0), ("cg_trust3_carrel", 3), ("cg_trust5_common_room", 5),
                                                          ("cg_trust7_bath", 7), ("cg_trust9_bed", 9)]]
}
for c in game["gallery"]:
    if not (D.parent / "assets/cg" / (c["locked"] + ".webp")).exists():
        c["locked"] = "cg_annex_locked"
art = {"rooms": {r: ([f"res://assets/rpg/rooms/{slot}.png"] if slot else []) + [f"res://assets/placeholder/rooms/{r}.webp"] for r, slot in ROOMS.items()},
       # VN-cast enemies keep their VN sprite (they appear in the VN CGs); new people use the
       # rendered RPG enemy art and have no placeholder (the standoff shows the room and name).
       "enemies": {"cobb": ["res://assets/sprites/cobb.webp"], "penhallow": ["res://assets/rpg/enemies/enemy_penhallow_neutral.png", "res://assets/sprites/penhallow.webp"],
                   "dean_holloway": ["res://assets/rpg/enemies/enemy_dean_neutral.png", "res://assets/sprites/dean_holloway.webp"],
                   **{w: [f"res://assets/rpg/enemies/enemy_{w}_neutral.png"] for w in ("secretary", "deans_man_a", "deans_man_b", "security_guard", "rival_archivist", "solicitor")}},
       "sprites": {s: [f"res://assets/rpg/outfits/{s}.png", f"res://assets/sprites/{s}.webp"] for s in
                   ("elena_neutral", "elena_flustered", "elena_soft", "cobb", "penhallow", "dean_holloway")},
       **{}}
art["sprites"].update({o: [f"res://assets/rpg/outfits/{o}.png"] for o in ("outfit_research", "outfit_raincoat", "outfit_gown", "outfit_evening", "outfit_nightwear")})
art.update({
       "cg": {}, "maps": {"blackwood": ["res://assets/rpg/rooms/floor_map.png"]}})
for f in sorted((D.parent / "assets/cg").glob("*.webp")):
    art["cg"][f.stem] = [f"res://assets/cg/{f.name}"]
for slot in ("cg_rpg_rain_arrival", "cg_rpg_map_room", "cg_rpg_lockpick", "cg_rpg_bell_chamber", "cg_rpg_roof_dawn",
             "cg_rpg_gala", "cg_trust3_carrel", "cg_trust5_common_room", "cg_trust7_bath", "cg_trust9_bed"):
    art["cg"][slot] = [f"res://assets/rpg/cgs/{slot}.png"]   # new RPG CGs: shown only once rendered
(D / "game.json").write_text(json.dumps(game, indent=1))
(D / "art_manifest.json").write_text(json.dumps(art, indent=1))
print("game.json + art_manifest.json written")
