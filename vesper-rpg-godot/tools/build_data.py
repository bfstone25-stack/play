#!/usr/bin/env python3
"""Writes data/game.json and data/art_manifest.json (the rules tables for VESPER).
Kept as code so the numbers have comments. One party member (you) for the whole game, so the
curve is Room 704's solo first shift stretched over five chapters: a small stranger and a
first date in ch1 (70 / 110 Guard), a rival boss in ch4 (420) and his last wall in ch5 (500).

    python3 tools/build_data.py
"""
import json
from pathlib import Path

D = Path(__file__).resolve().parent.parent / "data"
A = D.parent / "assets"
RPG_OUT = Path("/home/frankstone/Products/ops/flutter_art/out/rpg")
ROUTES = ["guyan", "ethan", "luxingye", "liam", "adrian", "fushen"]

ACTIONS = {
    # kind attack unless said; power + stat*scale, x1.75 on one of his tells, x0.5 if he resists
    "deflect":  {"kind": "guard", "cost": 0, "susp": 4},             # Hold back
    "observe":  {"kind": "observe", "cost": 2, "susp": 2},           # Read him
    "banter":   {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},
    "tease":    {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},
    "remember": {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "keepsake"},
    "sweet":    {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "treat"},
    "push":     {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},  # the coercion trap
    "stall":    {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},                         # Breathe
    "item":     {"kind": "item", "cost": 0},
    "plain":    {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": -3},   # Say it plainly (skill)
    "linger":   {"cost": 4, "stat": "cha", "power": 11, "scale": 1.8, "susp": -4},   # A look that lingers (skill)
}
SKILLS = {
    # Sharp (Wit) / Sweet (Charm)
    "quick":     {"branch": "sharp", "req": 2, "mult": {"banter": 0.3}},
    "steady":    {"branch": "sharp", "req": 4, "max_comp": 10},
    "noticing":  {"branch": "sharp", "req": 6, "stat": {"wit": 2}, "mult": {"remember": 0.2}},
    "plain_sk":  {"branch": "sharp", "req": 9, "grant": "plain"},
    "candour":   {"branch": "sharp", "req": 12, "mult": {"plain": 0.4, "remember": 0.2}},
    "warm":      {"branch": "sweet", "req": 2, "mult": {"tease": 0.3}},
    "linger_sk": {"branch": "sweet", "req": 4, "grant": "linger"},
    "poise_sk":  {"branch": "sweet", "req": 6, "stat": {"cha": 2}},
    "unhurried": {"branch": "sweet", "req": 9, "mult": {"stall": 0.4, "linger": 0.2}},
    "glow":      {"branch": "sweet", "req": 12, "mult": {"tease": 0.4, "linger": 0.3}},
}
ITEMS = {
    "coffee":    {"kind": "consumable", "heal_comp": 16},
    "cake":      {"kind": "consumable", "heal_comp": 28},
    "tea":       {"kind": "consumable", "heal_nerve": 8},
    "wine":      {"kind": "consumable", "heal_nerve": 14},
    "macarons":  {"kind": "treat"},
    "transit":   {"kind": "key"},       # the night-bus pass: the street door from your flat
    # outfits (still-life art; the player is never drawn)
    "blouse":    {"kind": "equip", "slot": "outfit", "for": "you", "bonus": {"wit": 1}, "sprite": "outfit_blouse"},
    "trench":    {"kind": "equip", "slot": "outfit", "for": "you", "bonus": {"grt": 1, "stl": 1}, "mult": {"stall": 0.2}, "sprite": "outfit_trench"},
    "dress":     {"kind": "equip", "slot": "outfit", "for": "you", "bonus": {"cha": 2}, "mult": {"tease": 0.2}, "sprite": "outfit_dress"},
    "slip":      {"kind": "equip", "slot": "outfit", "for": "you", "bonus": {"cha": 3}, "mult": {"tease": 0.3, "linger": 0.2}, "sprite": "outfit_slip"},
    "his_shirt": {"kind": "equip", "slot": "outfit", "for": "you", "bonus": {"cha": 2, "grt": 2}, "mult": {"linger": 0.3, "plain": 0.2}, "sprite": "outfit_shirt"},
    # accessories / tools
    "earrings":  {"kind": "equip", "slot": "accessory", "for": "you", "bonus": {"cha": 1}},
    "scarf":     {"kind": "equip", "slot": "accessory", "for": "you", "bonus": {"grt": 1}, "mult": {"stall": 0.2}},
    "perfume":   {"kind": "equip", "slot": "accessory", "for": "you", "bonus": {"cha": 1}, "mult": {"tease": 0.2, "linger": 0.2}},
    "phone":     {"kind": "equip", "slot": "tool", "for": "you", "bonus": {"wit": 1}},
    "notebook":  {"kind": "equip", "slot": "tool", "for": "you", "bonus": {"wit": 1}, "mult": {"remember": 0.3}},
    "umbrella":  {"kind": "equip", "slot": "tool", "for": "you", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
}
# keepsakes (one per route chapter, the detail you bring up with Remember) and gifts (given
# from the Items menu: Trust +1)
KEEPSAKES = {r: [f"ks_{r}_{c}" for c in range(1, 6)] for r in ROUTES}
for r in ROUTES:
    for k in KEEPSAKES[r]:
        ITEMS[k] = {"kind": "keepsake"}
    ITEMS[f"gift_{r}"] = {"kind": "gift", "gift": True, "gift_trust": 1}

# his tells: (weak, resist) early (ch1-2) and late (ch3-5). Push is always resisted on a date.
TELLS = {
    "ethan":    ((["banter", "plain"], ["tease", "push"]), (["banter", "plain", "remember"], ["push"])),
    "luxingye": ((["tease", "sweet"], ["plain", "push"]), (["tease", "remember", "linger"], ["push"])),
    "guyan":    ((["remember", "linger"], ["banter", "push"]), (["remember", "tease", "linger"], ["push"])),
    "liam":     ((["banter", "sweet"], ["plain", "push"]), (["banter", "remember", "linger"], ["push"])),
    "adrian":   ((["remember", "plain"], ["tease", "push"]), (["plain", "linger", "remember"], ["push"])),
    "fushen":   ((["plain", "remember"], ["tease", "sweet", "push"]), (["plain", "linger", "remember"], ["sweet", "push"])),
}
RIVAL = {"ethan": "hale", "luxingye": "han", "guyan": "pratt", "liam": "morrow", "adrian": "sterling", "fushen": "fu_elder"}
RIVAL_TELLS = {"hale": (["remember", "plain"], ["tease", "sweet"]), "han": (["plain", "banter"], ["tease"]),
               "pratt": (["remember", "plain"], ["sweet"]), "morrow": (["plain", "linger"], ["banter"]),
               "sterling": (["remember", "banter"], ["sweet", "tease"]), "fu_elder": (["plain", "remember"], ["tease", "push"])}
GENERIC = {"doorman": (["banter", "sweet"], ["tease"]), "paparazzo": (["banter", "tease"], ["plain"]),
           "columnist": (["plain", "remember"], ["banter"])}
# chapter -> (stranger Guard, date Guard, atk, rate, xp stranger, xp date)
CURVE = {1: (80, 125, 5, 6, 35, 45), 2: (170, 215, 6, 6, 50, 60), 3: (250, 300, 7, 7, 65, 75),
         4: (0, 330, 9, 8, 0, 90), 5: (0, 500, 10, 8, 0, 200)}
STRANGER = {1: "doorman", 2: "paparazzo", 3: "columnist"}
DROPS = {1: "earrings", 2: "scarf", 3: "perfume"}


def enemy(eid, sprite, sprite_p, comp, atk, rate, weak, resist, xp, drop=None, boss=False, trust_win=0, bark=None, barks=3):
    e = {"name_key": "e_" + eid, "sprite": sprite, "sprite_pressured": sprite_p, "composure": comp, "atk": atk,
         "susp_rate": rate, "weak": weak, "resist": resist, "xp": xp, "barks": barks, "bark_set": bark or eid,
         "intro_key": "ei_" + eid, "win_key": "ew_" + eid}
    if drop:
        e["drop"] = drop
    if boss:
        e["boss"] = True
    if trust_win:
        e["trust_win"] = trust_win
    return e


ENEMIES = {}
for r in ROUTES:
    for c in range(1, 6):
        comp_s, comp_d, atk, rate, xp_s, xp_d = CURVE[c]
        weak, resist = TELLS[r][0 if c <= 2 else 1]
        # the date: his own sprite; blush = his guard going. Barks are his hold lines.
        ENEMIES[f"date_{r}_{c}"] = enemy(f"date_{r}_{c}", f"{r}_neutral", f"{r}_blush", comp_d, atk, rate, weak, resist, xp_d,
                                         drop=["coffee", "tea", "cake", None, None][c - 1], boss=(c == 5), trust_win=1,
                                         bark=f"hold_{r}", barks=4)
        ENEMIES[f"date_{r}_{c}"]["trust_win_max_susp"] = 60   # Trust only for a date won close
        if c in STRANGER:
            g = STRANGER[c]
            ENEMIES[f"{g}_{r}"] = enemy(f"{g}_{r}", f"enemy_{g}", f"enemy_{g}_pressured", comp_s, atk - 1, rate,
                                        *GENERIC[g], xp_s, drop=DROPS[c], bark=g)
    rv = RIVAL[r]
    ENEMIES[f"rival_{r}"] = enemy(f"rival_{r}", f"enemy_{rv}", f"enemy_{rv}_pressured", 420, 9, 7, *RIVAL_TELLS[rv], 140,
                                  drop="wine", boss=True, trust_win=1, bark=rv, barks=4)

VENUES = {r: [f"v_{r}_{c}" for c in range(1, 6)] for r in ROUTES}
ROOMS = ["v_home", "v_street", "v_cafe"] + [v for r in ROUTES for v in VENUES[r]]
CGS = [f"cg_{r}_{k}" for r in ROUTES for k in ("ch2", "heat", "end")]
OUTFIT_ART = ["outfit_blouse", "outfit_trench", "outfit_dress", "outfit_slip", "outfit_shirt"]
PEOPLE = ["hale", "han", "pratt", "morrow", "sterling", "fu_elder", "paparazzo", "doorman", "columnist"]

game = {
    "title_key": "title", "logo": "res://assets/title/logo.webp", "title_bg": "res://assets/title/keyvisual.webp",
    "fonts": {"body": "res://assets/fonts/JosefinSans-SemiBold.ttf", "display": "res://assets/fonts/Marcellus-Regular.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-Regular.otf"},
    "ui": {"dust": "res://assets/title/rain.png", "vignette": "res://assets/title/vignette.png", "scrim": "res://assets/title/scrim.png",
           "dim": "res://assets/title/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
               "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
               "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
               "bar_under": "choice_idle", "bar_fill": "namebox", "bar_fill_gold": "title_hover", "modal": "confirm"}.items()}},
    "title_mood": {"ambient": "#e8d8e4", "torch": True, "zoom": 1.06, "offset": [0, 0]},
    "music": {"title": "res://assets/audio/afterhours-theme.mp3", "explore": "res://assets/audio/en-main.mp3",
              "venue": "res://assets/audio/en-conversation.mp3", "battle": "res://assets/audio/en-tension.mp3",
              "boss": "res://assets/audio/en-tension.mp3", "intimate": "res://assets/audio/en-intimate.mp3",
              "ending": "res://assets/audio/afterhours-resolution.mp3", "sad": "res://assets/audio/en-melancholy.mp3"},
    "audio": {"ambience": "res://assets/audio/room_ambience.mp3", "click": "res://assets/audio/ui_click.ogg",
              "page_flip": "res://assets/audio/page_flip.ogg", "heartbeat": "res://assets/audio/heartbeat.ogg",
              "sting": "res://assets/audio/title_sting.ogg"},
    "disclosure_key": "about_ai",
    "trial_last_night": "guyan_c2", "trial_locked_cgs": [],
    # no DLsite work id yet (new work): the trial's product-page button opens the studio page
    # until Blaze fills the DLsite URL in after registration.
    "store_url": "",
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5, 7, 9],
    "heroine_flag": "with_him", "heroine_sprite": "",
    "party": [
        {"id": "you", "base": {"wit": 3, "cha": 3, "grt": 3, "stl": 3}, "grow": ["cha", "wit", "grt", "stl"],
         "actions": ["deflect", "observe", "banter", "tease", "remember", "sweet", "push", "stall", "item"],
         "branches": {"sharp": ["quick", "steady", "noticing", "plain_sk", "candour"],
                      "sweet": ["warm", "linger_sk", "poise_sk", "unhurried", "glow"]},
         "start_equip": {"outfit": "blouse", "tool": "phone"}},
    ],
    "heroine_barks": {"who": "you", "open": ["hb_open_1", "hb_open_2"], "read": ["hb_read_1", "hb_read_2"],
                      "win": ["hb_win_1", "hb_win_2", "hb_win_3"]},
    "voice": {
        "hb_open_1": {"v_en": "res://assets/voice/greet_0.ogg"}, "hb_open_2": {"v_en": "res://assets/voice/greet_1.ogg"},
        "hb_read_1": {"v_en": "res://assets/voice/near_0.ogg"}, "hb_read_2": {"v_en": "res://assets/voice/near_1.ogg"},
        "hb_win_1": {"v_en": "res://assets/voice/win_0.ogg"}, "hb_win_2": {"v_en": "res://assets/voice/win_1.ogg"},
        "hb_win_3": {"v_en": "res://assets/voice/win_2.ogg"},
        "vb_stage_1": {"v_en": "res://assets/voice/stage_0.ogg"}, "vb_stage_2": {"v_en": "res://assets/voice/stage_1.ogg"},
        "vb_stage_3": {"v_en": "res://assets/voice/stage_2.ogg"}, "vb_stage_4": {"v_en": "res://assets/voice/stage_3.ogg"},
        "vb_win_big_1": {"v_en": "res://assets/voice/win_big_0.ogg"}, "vb_win_big_2": {"v_en": "res://assets/voice/win_big_1.ogg"},
        "vb_unlock_1": {"v_en": "res://assets/voice/unlock_0.ogg"}, "vb_unlock_2": {"v_en": "res://assets/voice/unlock_1.ogg"},
        "vb_streak_1": {"v_en": "res://assets/voice/streak_0.ogg"}, "vb_streak_2": {"v_en": "res://assets/voice/streak_1.ogg"},
        "vb_fail_1": {"v_en": "res://assets/voice/fail_0.ogg"}, "vb_fail_2": {"v_en": "res://assets/voice/fail_1.ogg"},
        "vb_idle_1": {"v_en": "res://assets/voice/idle_0.ogg"}, "vb_idle_2": {"v_en": "res://assets/voice/idle_1.ogg"},
    },
    "start_items": {"coffee": 2, "tea": 1},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["prologue"] + [f"{r}_c{c}" for r in ROUTES for c in range(1, 6)],
    "story": [f"{r}_c{c}" for r in ROUTES for c in range(1, 6)] + [f"{r}_end" for r in ROUTES] + ["rpg"],
    "gallery": [{"id": f"cg_{r}_{k}", "thumb": f"cg_{r}_{k}_thumb", "locked": f"cg_{r}_{k}_locked", "key": f"g_cg_{r}_{k}",
                 "trust": {"ch2": 0, "heat": 5, "end": 0}[k]} for r in ROUTES for k in ("ch2", "heat", "end")],
}
art = {"rooms": {r: [f"res://assets/rpg/rooms/{r}.png", f"res://assets/placeholder/rooms/{r}.webp"] for r in ROOMS},
       "rooms_locked": {r: [f"res://assets/placeholder/rooms_locked/{r}.webp"] for r in ROOMS},
       "enemies": {}, "sprites": {}, "cg": {}, "maps": {"city": ["res://assets/rpg/rooms/v_city_map.png", "res://assets/title/keyvisual.webp"]}}
for r in ROUTES:
    for k in ("neutral", "blush", "smile"):
        art["sprites"][f"{r}_{k}"] = [f"res://assets/sprites/{r}_{k}.png"]
        art["enemies"][f"{r}_{k}"] = [f"res://assets/sprites/{r}_{k}.png"]
for w in PEOPLE:
    for p in ("", "_pressured"):
        art["enemies"][f"enemy_{w}{p}"] = [f"res://assets/rpg/enemies/enemy_{w}_{'pressured' if p else 'neutral'}.png"]
for o in OUTFIT_ART:
    art["sprites"][o] = [f"res://assets/rpg/outfits/{o}.png"]
for c in CGS:
    for suf in ("", "_thumb", "_locked"):
        art["cg"][c + suf] = [f"res://assets/cg/{c}{suf}.webp"]
# every installed asset must be reachable from the game: a renamed slot fails the build
man_p = RPG_OUT / "manifest.json"
if man_p.exists():
    used = set(ROOMS) | {"v_city_map"} | {f"enemy_{w}_{p}" for w in PEOPLE for p in ("neutral", "pressured")} | set(OUTFIT_ART) | set(CGS)
    missing = [a["id"] for a in json.loads(man_p.read_text())["assets"] if a["id"] not in used]
    if missing:
        raise SystemExit("manifest assets not referenced by the game: " + ", ".join(missing))
(D / "game.json").write_text(json.dumps(game, indent=1))
(D / "art_manifest.json").write_text(json.dumps(art, indent=1))
print("game.json + art_manifest.json written:", len(ENEMIES), "enemies,", len(ITEMS), "items,", len(ROOMS), "rooms")
