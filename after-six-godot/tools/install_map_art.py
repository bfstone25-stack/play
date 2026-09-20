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
#
# ---- the rooms, re-picked 2026-09-19 (the brightness pass) --------------------------------
# The old rule here was "the frame where the ONE light source is doing the work". That rule
# is what produced a set measuring 0.22-0.44 brightness, and screens built on it measured
# 0.13-0.18 against a market at 0.63/0.38 (ops/check_brightness.py). The generator's style
# block has been rewritten (beat_monday_gen.py, STYLE_AS_ROOM) and every room re-rendered.
#
# The new rule: **the frame that is an office at night, lit, that a player could work in.**
# The night is carried by the windows and by what is switched off, not by underexposure.
#
# Two corrections are worth keeping, because both cost a re-render:
#   * v1 of the new style stacked "colorful / vivid / saturated" on neon-through-the-glass
#     and every room came back a magenta wash at saturation 0.55-0.63 — bright, and dyed.
#     Caught only by looking at native resolution; the meter was perfectly happy.
#   * Where two candidates both read, the pick goes to the one NEARER the market's 0.38
#     saturation rather than the brightest or the most colourful. Over-shooting the shelf
#     is its own failure — UI_DIRECTION was amended the same night after The Other Side's
#     02:17 interiors were lit until they stopped being 02:17.
#
#   lobby      02  the lit reception hall; 00 and 01 read the same, 02 has the cleanest floor
#   breakroom  01  vending machine glowing, ceiling lamps on, a laptop left open on the
#                  counter. 0.63/0.40, the closest frame in the whole set to the market
#   standup    00  open-plan at night: fluorescents on, monitors dark, the exit sign green,
#                  one desk lamp still burning. 01 is the one frame that still measures dark
#   corridor   00  doors closed down one wall, a water cooler, notice boards, the ceiling
#                  lights on and light spilling across the floor. 0.68/0.36, the nearest
#                  frame in the set to the market's saturation. (This slot was the last to
#                  land: its first v2 job was marked done having written nothing, which the
#                  queue warns about, so it sat on the v1 magenta wash until re-queued.)
#   inbox      00  desks, stacked paper, one lamp on over them — Mira's lamp. 01 is brighter
#                  but its saturation runs to 0.59
#   allhands   01  the window wall at 0.62/0.43; 00 and 02 read the same scene at 0.60 sat
#   review     02  the executive room: two chairs at the table, a document and a glass on
#                  it, lamps, the night city filling the glass wall. This is the room the
#                  offer and the confrontation happen in and it has to read as that room —
#                  00 lost the table entirely and 01 is brighter but emptier
#   deploy     00  the server aisle: racks both sides, blue status lights, a lit far wall
PICK = {
    "as_sky": (1, (512, 768)),
    "as_shell": (2, (512, 512)),
    "as_room_lobby": (2, (512, 384)),
    "as_room_breakroom": (1, (512, 384)),
    "as_room_standup": (0, (512, 384)),
    "as_room_corridor": (0, (512, 384)),
    "as_room_inbox": (0, (512, 384)),
    "as_room_allhands": (1, (512, 384)),
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
