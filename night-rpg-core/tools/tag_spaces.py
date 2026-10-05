#!/usr/bin/env python3
"""Tag every room of every night_rpg title with an acoustic space (Sound.SPACES) in
data/game.json "room_audio"[plate].space. Rooms with no room_audio entry get one holding only
"space" (their ambience still falls back as before). An existing "space" is kept unless --force.

    python3 play/night-rpg-core/tools/tag_spaces.py [title ...] [--force] [--dry]

Rule order: name keywords first (the room's name says what it is built of), then the
ambience bed, then small_office. Print the table so a wrong guess is easy to spot and fix by
hand in game.json (or per room with "space" in the night file).
"""
import json, sys
from pathlib import Path

PLAY = Path(__file__).resolve().parents[2]
TITLES = ["occupancy", "lien", "room704", "elena", "confession", "vesper"]
KEYS = [  # (substring, space) -- first hit wins
    ("stair", "stairwell"), ("bell_chamber", "stairwell"),
    ("bath", "bathroom"), ("shower", "bathroom"), ("mop", "bathroom"), ("laundry", "bathroom"),
    ("morgue", "bathroom"), ("cooler", "bathroom"), ("kitchen", "bathroom"),
    ("street", "outdoor"), ("alley", "outdoor"), ("roof", "outdoor"), ("dock", "outdoor"),
    ("loading", "outdoor"), ("lantern_row", "outdoor"), ("market", "outdoor"), ("toll_gate", "outdoor"),
    ("archive", "archive"), ("records", "archive"), ("librar", "archive"), ("stacks", "archive"),
    ("reading", "archive"), ("map_room", "archive"), ("muniment", "archive"), ("carrel", "archive"),
    ("bindery", "archive"), ("counting", "archive"), ("annex", "archive"),
    ("open_plan", "open_plan"), ("newsroom", "open_plan"), ("precinct", "open_plan"), ("print_room", "open_plan"),
    ("lobby", "hall"), ("entrance", "hall"), ("corridor", "hall"), ("hall", "hall"), ("bar", "hall"),
    ("club", "hall"), ("cafe", "hall"), ("common_room", "hall"), ("arcade", "hall"), ("boardroom", "hall"),
    ("bedroom", "bedroom"), ("flat", "bedroom"), ("penthouse", "bedroom"), ("room_", "bedroom"),
    ("room7", "bedroom"), ("safe_house", "bedroom"), ("sublet", "bedroom"), ("home", "bedroom"), ("linen", "bedroom"),
    ("cellar", "cellar"), ("vault", "cellar"), ("boiler", "cellar"), ("lockup", "cellar"), ("reliquary", "cellar"),
    ("lift", "car"), ("_car", "car"),
    ("office", "small_office"), ("accounts", "small_office"), ("meeting", "small_office"), ("break_room", "small_office"),
    ("stockroom", "small_office"), ("shop", "small_office"), ("study", "small_office"), ("interview", "small_office"),
    ("lab", "small_office"), ("copy_room", "small_office"), ("server", "small_office"),
]
# Rooms whose id says nothing (VESPER date venues): by the room's English title.
EXACT = {
    "boardroom": "open_plan",
    "v_adrian_1": "hall",        # the empty stage
    "v_adrian_2": "car",         # the back of the tour bus
    "v_adrian_3": "hall",        # the arena encore
    "v_adrian_4": "open_plan",   # the label's boardroom
    "v_adrian_5": "cellar",      # the underground livehouse
    "v_ethan_1": "open_plan",    # the top floor at midnight
    "v_ethan_2": "small_office", # his office lounge
    "v_ethan_3": "small_office", # the noodle shop
    "v_ethan_4": "hall",         # the gala
    "v_ethan_5": "open_plan",    # the top floor, lights off
    "v_fushen_1": "small_office",# the penthouse study
    "v_fushen_2": "hall",        # the gala hall
    "v_fushen_3": "hall",        # the Fu estate
    "v_fushen_4": "hall",        # the great hall
    "v_fushen_5": "outdoor",     # the terrace at dawn
    "v_guyan_1": "archive",      # the bookshop at dusk
    "v_guyan_2": "archive",      # the bookshop, afternoon
    "v_guyan_3": "outdoor",      # the corner in the rain
    "v_guyan_4": "archive",      # behind the counter (bookshop)
    "v_guyan_5": "archive",      # the shop, reopened
    "v_liam_1": "outdoor",       # his tailgate at sunset
    "v_liam_2": "outdoor",       # the backyard cookout
    "v_liam_3": "outdoor",       # the fire on your street
    "v_liam_4": "hall",          # the station garage
    "v_liam_5": "outdoor",       # the new porch
    "v_luxingye_1": "small_office", # backstage
    "v_luxingye_2": "small_office", # the rehearsal room
    "v_luxingye_3": "hall",      # the arena, row seven
    "v_luxingye_4": "hall",      # outside the boardroom (corridor)
    "v_luxingye_5": "cellar",    # the little livehouse
}
AMB = {"amb_rain_window": "bedroom", "amb_rain_street": "outdoor", "amb_street_night": "outdoor",
       "amb_wind": "stairwell", "amb_office": "open_plan", "amb_server": "small_office", "amb_hotel_hall": "hall",
       "amb_cellar": "cellar", "amb_library": "archive", "amb_club": "hall", "amb_boiler": "cellar",
       "amb_room_tone": "small_office", "amb_cafe": "hall"}


def guess(name, amb):
    if name in EXACT:
        return EXACT[name], "exact"
    for k, sp in KEYS:
        if k in name:
            return sp, "name"
    if amb in AMB:
        return AMB[amb], "amb"
    return "small_office", "default"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force, dry = "--force" in sys.argv, "--dry" in sys.argv
    for t in args or TITLES:
        gp = PLAY / f"{t}-rpg-godot/data/game.json"
        g = json.loads(gp.read_text())
        ra = g.setdefault("room_audio", {})
        plates = set(k for k in ra if k != "_steps")
        for nf in sorted((gp.parent / "nights").glob("*.json")):
            for rid, r in json.loads(nf.read_text()).get("rooms", {}).items():
                if not r.get("space"):
                    plates.add(r.get("plate", rid))
        print(f"== {t}")
        for p in sorted(plates):
            e = ra.setdefault(p, {})
            if e.get("space") and not force:
                print(f"  {p:22s} {e['space']:13s} (kept)")
                continue
            sp, why = guess(p, e.get("amb", ""))
            e["space"] = sp
            print(f"  {p:22s} {sp:13s} ({why}; amb {e.get('amb', '-')})")
        if not dry:
            gp.write_text(json.dumps(g, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
    main()
