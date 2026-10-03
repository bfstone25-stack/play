#!/usr/bin/env python3
"""Writes data/game.json and data/art_manifest.json (the rules tables for Room 704).
Kept as code so the numbers have comments. The numbers follow Elena's (same core, same
curves): a solo first shift against small enemies and one boss, then two members against
500-800 Resolve people, then a 1100 boss.

    python3 tools/build_data.py
"""
import json
from pathlib import Path
D = Path(__file__).resolve().parent.parent / "data"
A = D.parent / "assets"
RPG_OUT = Path("/home/frankstone/Products/ops/room704_art/out/rpg")

ACTIONS = {
    # kind attack unless said; power + stat*scale, x1.75 on a weakness, x0.5 on a resist
    "deflect":   {"kind": "guard", "cost": 0, "susp": 4},
    "observe":   {"kind": "observe", "cost": 2, "susp": 2},
    "bluff":     {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},
    "evidence":  {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "evidence"},
    "bribe":     {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "cash"},
    "flirt":     {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},
    "threaten":  {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},
    "stall":     {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},
    "item":      {"kind": "item", "cost": 0},
    "houseline": {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": -3},
    "confide":   {"cost": 4, "stat": "cha", "power": 11, "scale": 1.8, "susp": -4},
}
SKILLS = {
    # the auditor: Clerk / Fixer
    "ledger":       {"branch": "clerk", "req": 2, "mult": {"evidence": 0.3}},
    "nightshift":   {"branch": "clerk", "req": 4, "max_comp": 10},
    "arithmetic":   {"branch": "clerk", "req": 6, "stat": {"wit": 2}},
    "houseline_sk": {"branch": "clerk", "req": 9, "grant": "houseline"},
    "auditor":      {"branch": "clerk", "req": 12, "mult": {"houseline": 0.4, "evidence": 0.2}},
    "tip":          {"branch": "fixer", "req": 2, "mult": {"bribe": 0.3}},
    "deadpan":      {"branch": "fixer", "req": 4, "mult": {"bluff": 0.3}},
    "thickskin":    {"branch": "fixer", "req": 6, "stat": {"grt": 2}},
    "backdoor":     {"branch": "fixer", "req": 9, "mult": {"stall": 0.4}},
    "quietword":    {"branch": "fixer", "req": 12, "mult": {"threaten": 0.4, "bluff": 0.2}},
    # Mira: Ghost / Flame
    "unseen":       {"branch": "ghost", "req": 2, "stat": {"stl": 2}},
    "coolhead":     {"branch": "ghost", "req": 4, "max_comp": 10},
    "straightface": {"branch": "ghost", "req": 6, "mult": {"bluff": 0.4}},
    "vanish":       {"branch": "ghost", "req": 9, "mult": {"stall": 0.4}},
    "nobody":       {"branch": "ghost", "req": 12, "mult": {"bluff": 0.3, "stall": 0.2}},
    "smile":        {"branch": "flame", "req": 2, "mult": {"flirt": 0.3}},
    "confide_sk":   {"branch": "flame", "req": 4, "grant": "confide"},
    "poise":        {"branch": "flame", "req": 6, "stat": {"cha": 2}},
    "candle":       {"branch": "flame", "req": 9, "mult": {"confide": 0.4}},
    "ember":        {"branch": "flame", "req": 12, "mult": {"flirt": 0.4, "confide": 0.2}},
}
ITEMS = {
    "cash":          {"kind": "cash"},
    "coffee":        {"kind": "consumable", "heal_comp": 16},
    "whisky":        {"kind": "consumable", "heal_nerve": 8},
    "minibar":       {"kind": "consumable", "heal_comp": 28},
    "aspirin":       {"kind": "consumable", "heal_nerve": 14},
    "passkey":       {"kind": "key"},
    "basement_key":  {"kind": "key"},
    "card_gale":     {"kind": "evidence"},
    "register_page": {"kind": "evidence"},
    "cctv_tape":     {"kind": "evidence"},
    "ledger704":     {"kind": "evidence"},
    "train_ticket":  {"kind": "gift", "gift": True, "gift_trust": 1},
    "umbrella":      {"kind": "equip", "slot": "accessory", "for": "mira", "bonus": {"wit": 1}},
    "lighter":       {"kind": "equip", "slot": "tool", "for": "auditor", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
    "torch":         {"kind": "equip", "slot": "tool", "for": "auditor", "bonus": {"stl": 1}},
    "revolver":      {"kind": "equip", "slot": "tool", "for": "auditor", "bonus": {"grt": 2}, "mult": {"threaten": 0.3}},
    "waistcoat":     {"kind": "equip", "slot": "outfit", "for": "auditor", "bonus": {"grt": 1}},
    "namebadge":     {"kind": "equip", "slot": "accessory", "for": "auditor", "bonus": {"cha": 1}},
    "coat":          {"kind": "equip", "slot": "outfit", "for": "mira", "bonus": {"grt": 1}, "sprite": "outfit_coat"},
    "slip":          {"kind": "equip", "slot": "outfit", "for": "mira", "bonus": {"cha": 1}, "mult": {"flirt": 0.2}, "sprite": "outfit_slip"},
    "shirt":         {"kind": "equip", "slot": "outfit", "for": "mira", "bonus": {"cha": 2}, "mult": {"flirt": 0.3}, "sprite": "outfit_shirt"},
    "robe":          {"kind": "equip", "slot": "outfit", "for": "mira", "bonus": {"wit": 1}, "mult": {"stall": 0.3}, "sprite": "outfit_robe"},
    "lace":          {"kind": "equip", "slot": "outfit", "for": "mira", "bonus": {"cha": 3}, "mult": {"flirt": 0.5}, "sprite": "outfit_lace"},
}


def enemy(eid, who, comp, atk, rate, weak, resist, xp, drop, boss=False, trust_win=0, bark=None):
    bark = bark or who
    e = {"name_key": "e_" + eid, "sprite": f"enemy_{who}", "sprite_pressured": f"enemy_{who}_pressured", "composure": comp, "atk": atk,
         "susp_rate": rate, "weak": weak, "resist": resist, "xp": xp, "drop": drop, "barks": 4 if boss else 3, "bark_set": bark,
         "intro_key": "ei_" + eid, "win_key": "ew_" + eid}
    if boss:
        e["boss"] = True
    if trust_win:
        e["trust_win"] = trust_win
    return e


ENEMIES = {
    # shift 1: the auditor alone (Elena's night-1 numbers: cobb 55 -> the dawn boss 210)
    "guest212":    enemy("guest212", "guest212", 85, 5, 6, ["bribe", "stall"], ["threaten"], 40, "whisky"),
    "haskell":     enemy("haskell", "haskell", 140, 6, 7, ["evidence", "deflect"], ["bluff", "bribe"], 50, "torch"),
    "dace_phone":  enemy("dace_phone", "dace", 120, 5, 7, ["stall", "bluff"], ["threaten", "bribe"], 45, "coffee"),
    "gale":        enemy("gale", "gale", 320, 7, 6, ["bluff", "deflect", "stall"], ["bribe", "threaten"], 120, "card_gale", boss=True),
    # shift 2: two members
    "haskell_2":   enemy("haskell_2", "haskell", 700, 8, 11, ["evidence", "flirt"], ["bluff", "bribe"], 70, "minibar"),
    "guest212_2":  enemy("guest212_2", "guest212", 620, 7, 11, ["bribe", "stall", "flirt"], ["threaten"], 60, "aspirin"),
    "constable":   enemy("constable", "constable", 780, 10, 11, ["evidence", "bluff"], ["bribe", "threaten"], 75, "cash"),
    "dace":        enemy("dace", "dace", 740, 9, 11, ["stall", "bluff", "confide"], ["threaten", "bribe", "flirt"], 75, "umbrella"),
    "gale_2":      enemy("gale_2", "gale", 1000, 10, 9, ["evidence", "flirt", "deflect"], ["bribe", "threaten"], 150, "lighter", boss=True, trust_win=1),
    # shift 3
    "constable_2": enemy("constable_2", "constable", 880, 11, 11, ["evidence", "stall"], ["bribe", "threaten"], 95, "coffee"),
    "dace_2":      enemy("dace_2", "dace", 900, 11, 11, ["bluff", "flirt", "confide"], ["threaten", "bribe"], 95, "aspirin"),
    "haskell_3":   enemy("haskell_3", "haskell", 960, 12, 11, ["evidence", "deflect", "houseline"], ["bluff", "bribe"], 100, "minibar"),
    "penhallow":   enemy("penhallow", "penhallow", 1400, 13, 9, ["evidence", "flirt", "houseline", "confide"], ["bribe", "threaten"], 260, "train_ticket", boss=True, trust_win=1),
    # epilogue
    "porter":      enemy("porter", "porter", 620, 8, 8, ["bluff", "stall", "flirt"], ["evidence"], 80, "coffee"),
}
# room id -> rendered plate slot (ops/room704_art/out/rpg/rooms/<slot>.png); None = a VN plate
ROOMS = {"lobby": None, "corridor4": None, "room704": None,
         "back_office": "room_back_office", "bar": "room_bar", "kitchen": "room_kitchen", "service_stair": "room_service_stair",
         "lift": "room_lift", "corridor_2": "room_corridor_2", "room_212": "room_212", "room_702": "room_702", "linen": "room_linen",
         "roof": "room_roof", "manager_flat": "room_manager_flat", "boiler": "room_boiler", "laundry": "room_laundry",
         "loading_bay": "room_loading_bay", "street": "room_street"}
NEW_CGS = ["cg_rpg_doors", "cg_rpg_car", "cg_rpg_register", "cg_rpg_roof_city", "cg_rpg_corner",
           "cg_trust3_stair", "cg_trust5_bath", "cg_trust7_sheets", "cg_trust9_morning"]

game = {
    "title_key": "title", "logo": "res://assets/title/logo.png", "title_bg": "res://assets/title/keyvisual.webp",
    "fonts": {"body": "res://assets/fonts/JosefinSans-SemiBold.ttf", "display": "res://assets/fonts/Marcellus-Regular.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-Regular.otf"},
    "ui": {"dust": "res://assets/title/rain.png", "vignette": "res://assets/title/vignette.png", "scrim": "res://assets/title/scrim.png",
           "dim": "res://assets/title/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
               "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
               "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
               "bar_under": "choice_idle", "bar_fill": "namebox", "bar_fill_gold": "title_hover", "modal": "confirm"}.items()}},
    "title_mood": {"ambient": "#d0c8dc", "torch": True, "zoom": 1.1, "offset": [300, 0]},
    "music": {"title": "res://assets/audio/suspense_theme.ogg", "explore": "res://assets/audio/suspense_theme.ogg",
              "battle": "res://assets/audio/suspense_theme.ogg", "boss": "res://assets/audio/suspense_theme.ogg",
              "intimate": "res://assets/audio/ecchi_theme.ogg", "heartbeat": "res://assets/audio/heartbeat.ogg"},
    "audio": {"ambience": "res://assets/audio/rain_ambience.ogg", "click": "res://assets/audio/ui_click.ogg",
              "page_flip": "res://assets/audio/page_flip.ogg", "heartbeat": "res://assets/audio/heartbeat.ogg",
              "sting": "res://assets/audio/title_sting.ogg", "camera": "res://assets/audio/click.ogg"},
    "disclosure_key": "about_ai",
    "trial_last_night": "shift1", "trial_locked_cgs": ["cg_bed", "cg_window"],
    # Room 704's DLsite RJ id is not recorded anywhere in the repo (Elena's is RJ01722365); the
    # trial's "product page" button opens the itch page until Blaze fills the DLsite work URL in.
    "store_url": "https://bfstone25-stack.itch.io/room-704",
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5, 7, 9],
    "heroine_flag": "mira_joined", "heroine_sprite": "outfit_slip",
    "party": [
        {"id": "auditor", "base": {"wit": 4, "cha": 2, "grt": 3, "stl": 2}, "grow": ["wit", "grt", "cha", "stl"],
         "actions": ["deflect", "bluff", "evidence", "bribe", "threaten", "stall", "item"],
         "branches": {"clerk": ["ledger", "nightshift", "arithmetic", "houseline_sk", "auditor"],
                      "fixer": ["tip", "deadpan", "thickskin", "backdoor", "quietword"]}, "start_equip": {"outfit": "waistcoat"}},
        {"id": "mira", "join_flag": "mira_joined", "base": {"wit": 3, "cha": 4, "grt": 2, "stl": 3},
         "grow": ["cha", "wit", "stl", "grt"],
         "actions": ["deflect", "observe", "bluff", "flirt", "stall", "item"],
         "branches": {"ghost": ["unseen", "coolhead", "straightface", "vanish", "nobody"],
                      "flame": ["smile", "confide_sk", "poise", "candle", "ember"]}, "start_equip": {"outfit": "slip"}},
    ],
    "start_items": {"coffee": 1, "cash": 1},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["shift1", "shift2", "shift3", "epilogue"], "story": ["act1", "act2", "act3"],
    "gallery": [{"id": c, "thumb": c + "_thumb", "locked": c + "_locked", "key": "g_" + c, "trust": t} for c, t in [
        ("cg_checkin", 0), ("cg_rpg_doors", 0), ("cg_rpg_register", 0), ("cg_rpg_car", 0), ("cg_door", 0), ("cg_trust3_stair", 3),
        ("cg_rpg_roof_city", 0), ("cg_bed", 5), ("cg_window", 5), ("cg_trust5_bath", 5), ("cg_trust7_sheets", 7),
        ("cg_morning", 0), ("cg_rpg_corner", 0), ("cg_trust9_morning", 9)]],
}
for c in game["gallery"]:
    if not (A / "cg" / (c["locked"] + ".webp")).exists():
        c["locked"] = "cg_generic_locked"
art = {"rooms": {r: ([f"res://assets/rpg/rooms/{slot}.png"] if slot else []) + [f"res://assets/placeholder/rooms/{r}.webp"] for r, slot in ROOMS.items()},
       "rooms_locked": {r: [f"res://assets/placeholder/rooms_locked/{r}.webp"] for r in ROOMS},
       "enemies": {f"enemy_{w}{p}": [f"res://assets/rpg/enemies/enemy_{w}_{'pressured' if p else 'neutral'}.png"]
                   for w in ("gale", "haskell", "penhallow", "dace", "guest212", "constable", "porter") for p in ("", "_pressured")},
       "sprites": {s: [f"res://assets/sprites/{s}.png"] for s in ("mira_neutral", "mira_wry", "mira_undone")},
       "cg": {}, "maps": {"marbeck": ["res://assets/rpg/rooms/floor_map.png"]}}
art["sprites"].update({o: [f"res://assets/rpg/outfits/{o}.png"] for o in ("outfit_slip", "outfit_coat", "outfit_shirt", "outfit_robe", "outfit_lace")})
for f in sorted((A / "cg").glob("*.webp")):
    art["cg"][f.stem] = [f"res://assets/cg/{f.name}"]
for slot in NEW_CGS:
    art["cg"][slot] = [f"res://assets/rpg/cgs/{slot}.png"]   # new RPG CGs: shown only once rendered
    art["cg"][slot + "_thumb"] = [f"res://assets/rpg/cgs/{slot}_thumb.png"]
# every manifest asset must be reachable from the game: a renamed slot fails the build
if (RPG_OUT / "manifest.json").exists():
    _man = json.loads((RPG_OUT / "manifest.json").read_text())["assets"]
    _used = set(s for s in ROOMS.values() if s) | {"floor_map"}
    for e in game["enemies"].values():
        for k in ("sprite", "sprite_pressured"):
            for pth in art["enemies"].get(e.get(k, ""), []):
                _used.add(Path(pth).stem)
    for it in game["items"].values():
        if it.get("sprite", "").startswith("outfit_"): _used.add(it["sprite"])
    _used.add(game["heroine_sprite"])
    for c in game["gallery"]: _used.add(c["id"])
    _missing = [a["id"] for a in _man if a["id"] not in _used]
    if _missing:
        raise SystemExit("manifest assets not referenced by the game: " + ", ".join(_missing))
(D / "game.json").write_text(json.dumps(game, indent=1))
(D / "art_manifest.json").write_text(json.dumps(art, indent=1))
print("game.json + art_manifest.json written:", len(ENEMIES), "enemies,", len(ITEMS), "items,", len(ROOMS), "rooms")
