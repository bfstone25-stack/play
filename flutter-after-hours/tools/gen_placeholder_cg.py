#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Placeholder CG plates for VESPER — PIL only, no GPU.

The real plates come from `ops/flutter_art/flutter_gen.py` on the 3060 and are
NOT rendered here; this exists so the whole unlock flow — Gate, reveal, gallery,
the paid/free split — is testable months before any art exists. Every file it
writes is a labelled card that says which slot it stands in for and how that
slot is earned.

Layout, which is also the shipping rule:

    frontend/cg/<slot>_locked.webp   the covered plate — ships in every build
    frontend/cg/<slot>_thumb.webp    gallery thumbnail of the covered plate
    frontend/cg/full/<slot>.webp     the uncensored plate — PAID BUILD ONLY

`cg/full/` is excluded from the free package by tools/build_free.sh. That is the
Room 704 rule restated: editing a localStorage flag reveals nothing, because on
a free build the bytes are not on the device at all.

    python3 tools/gen_placeholder_cg.py            # all 18 plates + thumbs
    python3 tools/gen_placeholder_cg.py --only cg_ethan_heat
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "frontend", "cg")
W, H = 1024, 576
THUMB = (320, 180)

FONT_DIR = "/usr/share/fonts/truetype/dejavu"

# slot -> (route, how it is earned, one-line scene note from ops/adult_forks/flutter.md)
SLOTS = {
    "cg_ethan_ch2":     ("ethan",    "chapter 2 clear",      "open shirt, necktie in hand, the city behind him"),
    "cg_ethan_heat":    ("ethan",    "affection crosses 60", "from below, arm-braced, the control that stops"),
    "cg_ethan_end":     ("ethan",    "ending screen",        "asleep, bare back, morning light"),
    "cg_luxingye_ch2":  ("luxingye", "chapter 2 clear",      "shirt over his head, still talking through it"),
    "cg_luxingye_heat": ("luxingye", "affection crosses 60", "on his back, arm over his eyes, laughing"),
    "cg_luxingye_end":  ("luxingye", "ending screen",        "open shirt at a window, looking back, dawn"),
    "cg_guyan_ch2":     ("guyan",    "chapter 2 clear",      "glasses on the table, reaching, rain on the window"),
    "cg_guyan_heat":    ("guyan",    "affection crosses 60", "held, over the shoulder, foreheads together"),
    "cg_guyan_end":     ("guyan",    "ending screen",        "asleep against the headboard, a book and a cat"),
    "cg_liam_ch2":      ("liam",     "chapter 2 clear",      "string lights, shirt sleeves rolled, dancing badly"),
    "cg_liam_heat":     ("liam",     "affection crosses 60", "turnout coat on the floor, hands steady at last"),
    "cg_liam_end":      ("liam",     "ending screen",        "asleep on the new porch, dog across both their feet"),
    "cg_adrian_ch2":    ("adrian",   "chapter 2 clear",      "tour bus lamp, lyric sheets, shirt half off"),
    "cg_adrian_heat":   ("adrian",   "affection crosses 60", "guitar case shut, both hands finally occupied"),
    "cg_adrian_end":    ("adrian",   "ending screen",        "late morning, bare shoulder, guitar untouched"),
    "cg_fushen_ch2":    ("fushen",   "chapter 2 clear",      "cufflinks off, collar open, the city behind glass"),
    "cg_fushen_heat":   ("fushen",   "affection crosses 60", "the distance finally crossed, control set down"),
    "cg_fushen_end":    ("fushen",   "ending screen",        "dawn terrace, one chair moved, bad coffee"),
}

# One hue per route so a contact sheet of placeholders is still readable at a glance.
HUE = {"ethan": ((28, 34, 52), (86, 96, 126)),
       "luxingye": ((52, 26, 44), (140, 84, 118)),
       "guyan": ((46, 34, 24), (126, 96, 62)),
       "liam": ((24, 42, 34), (74, 118, 92)),
       "adrian": ((34, 24, 46), (100, 76, 132)),
       "fushen": ((22, 30, 38), (76, 92, 108))}


def font(size, mono=False):
    name = "DejaVuSansMono.ttf" if mono else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(os.path.join(FONT_DIR, name), size)
    except OSError:
        return ImageFont.load_default()


def gradient(top, bottom):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)],
               fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img


def plate(slot, locked):
    route, how, note = SLOTS[slot]
    img = gradient(*HUE[route])
    d = ImageDraw.Draw(img)

    # A figure-shaped block, so framing problems in the layout show up before art does.
    d.rounded_rectangle([W * 0.30, H * 0.20, W * 0.70, H + 40], 28,
                        fill=tuple(min(255, c + 26) for c in HUE[route][1]))
    d.ellipse([W * 0.41, H * 0.10, W * 0.59, H * 0.34],
              fill=tuple(min(255, c + 42) for c in HUE[route][1]))

    d.text((48, 40), "PLACEHOLDER", font=font(22, True), fill=(255, 255, 255, 220))
    d.text((48, 74), slot, font=font(40, True), fill=(255, 255, 255))
    d.text((48, 128), note, font=font(22), fill=(230, 224, 220))
    d.text((48, H - 96), f"earned: {how}", font=font(22, True), fill=(235, 215, 200))
    d.text((48, H - 62), "not final art — ops/flutter_art/flutter_gen.py renders the real plate",
           font=font(17), fill=(210, 200, 196))

    if locked:
        # The covered plate is a real cover, not a tint: blur first, then the band.
        img = img.filter(ImageFilter.GaussianBlur(18))
        d = ImageDraw.Draw(img)
        d.rectangle([0, H * 0.42, W, H * 0.58], fill=(12, 10, 16))
        d.text((W / 2, H * 0.50), "LOCKED", font=font(46, True),
               fill=(232, 122, 168), anchor="mm")
        d.text((W / 2, H * 0.66), how.upper(), font=font(20, True),
               fill=(226, 214, 210), anchor="mm")
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="one slot name")
    args = ap.parse_args()
    slots = [args.only] if args.only else list(SLOTS)
    for s in slots:
        if s not in SLOTS:
            raise SystemExit(f"unknown slot {s}; known: {', '.join(SLOTS)}")

    os.makedirs(os.path.join(OUT, "full"), exist_ok=True)
    for s in slots:
        plate(s, locked=False).save(os.path.join(OUT, "full", f"{s}.webp"), quality=86)
        cover = plate(s, locked=True)
        cover.save(os.path.join(OUT, f"{s}_locked.webp"), quality=86)
        cover.resize(THUMB).save(os.path.join(OUT, f"{s}_thumb.webp"), quality=80)
        print("wrote", s)
    print(f"{len(slots)} slots -> {OUT}")


if __name__ == "__main__":
    main()
