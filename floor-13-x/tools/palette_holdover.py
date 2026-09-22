#!/usr/bin/env python3
"""HOLDOVER's palette — its own ramp, derived from Floor 13's by a declared transform.

Why a transform and not a second hand-painted set: the two games are the same building,
so the geometry in `tools/generate_pixel_art.py` is shared on purpose (the standard's
"parallel worlds sharing a core"). What must NOT be shared is the light. Floor 13: Night
Shift is a cold fluorescent office at 11:59 PM -- blue-steel shadows, cyan terminals,
one red wound. HOLDOVER is the same floor after the lease ran out: the building is on
emergency power, so the fluorescents are dead and the only light is sodium from the
stairwell and the lift, with the terminals burning magenta instead of cyan.

That is a hue story, so it is written as one. Every colour the parent generator emits is
pushed through `remap()` below:

  * hue     piecewise -- cold blues (180-260) swing to sodium amber, cyan swings to gold,
            the red accent swings to magenta, warm tones (wood, skin) barely move
  * sat     x1.42, because the adult shelf sells saturated and Floor 13's plates measure
            0.13-0.30 against a horror floor of 0.38 (ops/SHELF_STYLE.md)
  * val     lifted on the mids with a gamma, so the room reads as LIT-in-a-different-
            colour rather than as the parent with the lights down -- which is the exact
            failure the standard names

Source of truth is the PARENT's assets/pixel/, so this is re-runnable and the derivation
stays visible. Font sheets are excluded: they are white-on-transparent masks and the game
tints them at runtime (scripts/ui_font.gd).

    python3 tools/palette_holdover.py            # rewrite the fork's assets/pixel
    python3 tools/palette_holdover.py --check    # report only, touch nothing
"""
from __future__ import annotations

import colorsys
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parents[1]
SRC = HERE.parent / "floor-13" / "assets" / "pixel"
DST = HERE / "assets" / "pixel"

# Font sheets and their descriptors are masks, not art. Leave them alone.
SKIP = {"floor13_font.png", "floor13_cjk.png"}

SAT_GAIN = 1.42
VAL_GAMMA = 0.82          # <1 lifts the mids; the deep inks stay deep
VAL_CEIL = 0.97


def hue_shift(h: float) -> float:
    """Piecewise hue map, degrees in / degrees out. Anchors, linearly interpolated."""
    anchors = [
        (0.0, 338.0),     # the red wound -> magenta
        (20.0, 352.0),
        (45.0, 40.0),     # wood / brass stays brass, a touch hotter
        (90.0, 62.0),     # the rare green -> acid yellow
        (150.0, 30.0),
        (180.0, 42.0),    # CYAN terminals -> sodium gold
        (200.0, 28.0),    # SPECTRAL / NIGHT -> amber
        (225.0, 18.0),    # STEEL blue -> ember
        (260.0, 320.0),   # the violet in the break room -> hot plum
        (300.0, 326.0),
        (360.0, 338.0),
    ]
    for i in range(len(anchors) - 1):
        h0, o0 = anchors[i]
        h1, o1 = anchors[i + 1]
        if h0 <= h <= h1:
            t = 0.0 if h1 == h0 else (h - h0) / (h1 - h0)
            # interpolate the SHORT way round the wheel
            d = (o1 - o0 + 540.0) % 360.0 - 180.0
            return (o0 + d * t) % 360.0
    return h


def remap(r: int, g: int, b: int) -> tuple[int, int, int]:
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    if s < 0.045:
        # Near-neutral: no hue to rotate. Warm it slightly so nothing reads as blue-grey.
        h, s = 30.0 / 360.0, min(0.16, s + 0.10)
    else:
        h = hue_shift(h * 360.0) / 360.0
        s = min(1.0, s * SAT_GAIN)
    v = min(VAL_CEIL, v ** VAL_GAMMA)
    rr, gg, bb = colorsys.hsv_to_rgb(h, s, v)
    return round(rr * 255), round(gg * 255), round(bb * 255)


def convert(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    cols = img.getcolors(maxcolors=1 << 24) or []
    lut = {}
    for _, px in cols:
        r, g, b, a = px
        lut[px] = (*remap(r, g, b), a)
    out = Image.new("RGBA", img.size)
    out.putdata([lut[p] for p in img.getdata()])
    return out


def main() -> int:
    check = "--check" in sys.argv
    if not SRC.is_dir():
        print(f"parent pixel source missing: {SRC}", file=sys.stderr)
        return 2
    n = 0
    for p in sorted(SRC.glob("*.png")):
        if p.name in SKIP:
            continue
        target = DST / p.name
        if not target.exists():
            print(f"  skip (not in fork): {p.name}")
            continue
        src = Image.open(p)
        out = convert(src)
        if check:
            print(f"  would rewrite {p.name}  ({len(src.convert('RGBA').getcolors(1 << 24) or [])} colours)")
        else:
            out.save(target, optimize=True)
            print(f"  {p.name}")
        n += 1
    print(f"{'checked' if check else 'rewrote'} {n} plates into HOLDOVER's ramp")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
