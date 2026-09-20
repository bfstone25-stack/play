#!/usr/bin/env python3
"""Install the cutaway map's own art: the chosen candidate of each `as_*` slot, out of
ops/beat_monday_art/out/plates/, into assets/art/plate_<slot>.webp.

Why this exists rather than a copy command in a shell history. The map screen
(scripts/map_screen.gd) names eleven plates — a night sky, the concrete the section is cut
out of, and one night interior per room — and every one of them is a *chosen* frame out of
three candidates. Which frame was chosen is a decision someone made by looking at all three
at native resolution, and it has to survive into the repo, or the next re-render silently
installs a different room. PICK below is that record.

    python3 tools/install_map_art.py          # install the picks
    python3 tools/install_map_art.py --list   # print the candidates and exit

The generator writes 1024x768 (rooms), 1024x1024 (the concrete) and 832x1216 (the sky) PNGs.
They go in at the size the screen actually samples them at, times a little headroom for the
web build's 2x, as WebP — the format every other plate in assets/art/ is in.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

PROJ = Path(__file__).resolve().parent.parent
SRC = PROJ.parent.parent / "ops/beat_monday_art/out/plates"
DST = PROJ / "assets/art"

# slot -> (candidate index, installed size). Chosen by looking at all three at native
# resolution, 2026-09-19:
#   as_sky        01  the far city glow with a lit horizon; 00 is empty haze and 02's
#                     towers compete with the section standing in front of them
#   as_shell      02  plain poured concrete; 00 cracks too hard, 01 is a riveted plate
# The rooms, all chosen on one rule: the frame where the ONE light source is doing the
# work, because at 80 px a lit cell has to read as a lit cell and nothing else.
#   lobby      01  reception desks with their lamps on, a lit door at the end of the hall
#   breakroom  02  the vending machine glowing and two warm ceiling lamps: Riley stayed
#   standup    01  rows of dark desks with window-light bars across the carpet
#   corridor   00  doors closed and light spilling under one of them
#   inbox      00  one desk lamp over papers and an open drawer — Mira's lamp is on
#   allhands   00  the window wall, benches, warm lamps: everyone waiting on the last train
#   review     02  two chairs across a small table, one lamp, the city behind the glass
#   deploy     00  the server aisle, amber racks, one lit door
PICK = {
    "as_sky": (1, (512, 768)),
    "as_shell": (2, (512, 512)),
    "as_room_lobby": (1, (512, 384)),
    "as_room_breakroom": (2, (512, 384)),
    "as_room_standup": (1, (512, 384)),
    "as_room_corridor": (0, (512, 384)),
    "as_room_inbox": (0, (512, 384)),
    "as_room_allhands": (0, (512, 384)),
    "as_room_review": (2, (512, 384)),
    "as_room_deploy": (0, (512, 384)),
}


def main() -> int:
    if "--list" in sys.argv:
        for slot in PICK:
            found = sorted(SRC.glob(slot + "_*.png"))
            print(f"{slot:22s} {len(found)} candidates: {[p.stem for p in found]}")
        return 0
    missing, done = [], 0
    for slot, (idx, size) in PICK.items():
        src = SRC / f"{slot}_{idx:02d}.png"
        if not src.exists():
            missing.append(src.name)
            continue
        im = Image.open(src).convert("RGB")
        im = im.resize(size, Image.LANCZOS)
        out = DST / f"plate_{slot}.webp"
        im.save(out, "WEBP", quality=88, method=6)
        print(f"  {slot:22s} <- {src.name}  {size[0]}x{size[1]}  {out.stat().st_size // 1024} KB")
        done += 1
    if missing:
        print("MISSING (not rendered yet): " + ", ".join(missing))
    print(f"{done}/{len(PICK)} installed into {DST}")
    print("now: $GODOT --headless --path . --import")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
