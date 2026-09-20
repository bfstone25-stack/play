#!/usr/bin/env python3
"""Relight the day game's rendered plates for After Six, until the night-specific renders
land (ops/beat_monday_art/beat_monday_gen.py `night_*` slots, queued through
ops/render_queue.py). The same rooms seen from the other side of six o'clock: the plate is
pushed down two stops, shifted to plum-blue, and one hot lamp (magenta or amber) is laid
across it so a screenshot reads as the night game at a glance (UI_DIRECTION: dark ground,
hot accents). No shapes are drawn — every output is the rendered plate, re-lit.

    python3 tools/night_tint.py          # rewrites assets/art/plate_*.webp from ../beat-monday-godot
    python3 tools/night_tint.py --check  # lists what would be written

The offer/return CG slot gets a clearly labelled PLACEHOLDER card, the same convention as
Floor 13 X's tools/make_placeholder_plates.py: a tinted plate with the slot name printed
across it, so nobody mistakes it for a render.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
DAY = PROJ.parent / "beat-monday-godot" / "assets" / "art"
OUT = PROJ / "assets" / "art"

# plate -> (lamp colour, lamp anchor as a fraction of the plate, lamp radius fraction)
LAMPS = {
    "title": ((255, 61, 138), (0.62, 0.42), 0.55),
    "map_sky": ((60, 40, 120), (0.5, 0.2), 0.9),
    "map_building": ((255, 179, 71), (0.7, 0.55), 0.5),
    "lobby": ((255, 179, 71), (0.5, 0.5), 0.45),
    "breakroom": ((255, 111, 97), (0.35, 0.4), 0.45),
    "corridor": ((255, 61, 138), (0.5, 0.45), 0.35),
    "mon": ((120, 80, 255), (0.5, 0.35), 0.5),
    "tue": ((255, 179, 71), (0.5, 0.45), 0.42),
    "wed": ((255, 61, 138), (0.5, 0.3), 0.5),
    "thu": ((255, 61, 138), (0.55, 0.45), 0.45),
    "fri": ((255, 111, 97), (0.5, 0.5), 0.5),
    "sat": ((255, 179, 71), (0.3, 0.4), 0.5),
}


def relight(im: Image.Image, lamp, anchor, radius) -> Image.Image:
    im = im.convert("RGB")
    w, h = im.size
    # two stops down, desaturated, then the shadows pulled to plum-blue
    dark = ImageEnhance.Brightness(im).enhance(0.28)
    dark = ImageEnhance.Color(dark).enhance(0.55)
    plum = Image.new("RGB", im.size, (18, 8, 15))
    dark = Image.blend(dark, plum, 0.25)
    # the lamp: a radial falloff of the accent, screened over the dark plate
    mask = Image.new("L", im.size, 0)
    d = ImageDraw.Draw(mask)
    cx, cy = anchor[0] * w, anchor[1] * h
    r = radius * max(w, h)
    for i in range(24, 0, -1):
        rr = r * i / 24
        d.ellipse((cx - rr, cy - rr * 0.8, cx + rr, cy + rr * 0.8), fill=int(255 * (1 - i / 24) ** 1.6))
    mask = mask.filter(ImageFilter.GaussianBlur(w * 0.08))
    glow = Image.new("RGB", im.size, lamp)
    lit = Image.composite(Image.blend(dark, glow, 0.42), dark, mask)
    # the lamp also brings the plate's own detail back up under it
    detail = ImageEnhance.Brightness(im).enhance(0.62)
    lit = Image.composite(Image.blend(lit, detail, 0.45), lit, mask)
    return lit


def placeholder(base: Image.Image, slot: str, lines: list[str]) -> Image.Image:
    im = relight(base, (255, 61, 138), (0.5, 0.45), 0.5)
    im = ImageEnhance.Brightness(im).enhance(0.7)
    d = ImageDraw.Draw(im)
    w, h = im.size
    try:
        big = ImageFont.truetype(str(PROJ / "assets/fonts/LilitaOne-Regular.ttf"), 44)
        small = ImageFont.truetype(str(PROJ / "assets/fonts/Nunito.ttf"), 22)
    except OSError:
        big = small = ImageFont.load_default()
    y = h * 0.36
    for i, text in enumerate(["PLACEHOLDER", slot] + lines):
        f = big if i < 2 else small
        tw = d.textlength(text, font=f)
        d.text((w / 2 - tw / 2 + 2, y + 2), text, font=f, fill=(0, 0, 0))
        d.text((w / 2 - tw / 2, y), text, font=f, fill=(255, 244, 236) if i else (255, 61, 138))
        y += 56 if i < 2 else 32
    return im


def main() -> int:
    check = "--check" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (lamp, anchor, radius) in LAMPS.items():
        src = DAY / f"plate_{name}.webp"
        if not src.exists():
            print("  skip", name, "(no day plate)")
            continue
        dst = OUT / f"plate_{name}.webp"
        print("  relight", name, "->", dst.relative_to(PROJ))
        if not check:
            relight(Image.open(src), lamp, anchor, radius).save(dst, "WEBP", quality=88)
    # the tier-3 slot: a labelled card until the render lands
    src = DAY / "plate_thu.webp"
    dst = OUT / "cg_return_x_locked.webp"
    print("  placeholder cg_return_x ->", dst.relative_to(PROJ))
    if not check and src.exists():
        placeholder(Image.open(src), "cg_return_x", ["tier 3 · queued", "render_queue: beat_monday plates --only night_cg_return", "she came back on her own"]).save(dst, "WEBP", quality=88)
    return 0


if __name__ == "__main__":
    sys.exit(main())
