#!/usr/bin/env python3
"""Placeholder CG plates for Floor 13: Retention, drawn with PIL.

The real plates come out of ops/floor13_art/floor13_gen.py on the 3060 and are not
rendered here — this exists so that every hook, gate, presenter and gallery around the art
can be built, played and tested before a single GPU second is spent, and so that a missing
render is visible as a labelled placeholder rather than as a blank screen.

Sizes and filenames match floor13_gen.py exactly (1152x768, `<slot>.png` and
`<slot>_locked.png` under assets/cg/), so dropping the finished renders in is a copy and
nothing else. Drop them in and re-run nothing.

The locked plates follow the design doc's in-fiction rule: not a blur of the open plate,
but the same room with the person replaced by a white cut-out carrying an employee number.
A locked plate that is itself part of the fiction is the one kind of paywall art nobody
screenshots to complain about.

    python3 play/floor-13-x/tools/make_placeholder_plates.py
    python3 play/floor-13-x/tools/make_placeholder_plates.py --force
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1152, 768
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "cg"

# The floor-13 palette, taken from the scene tints in scripts/office_builder.gd and the
# HUD colours in scripts/hud.gd, so a placeholder sits in the same room as the pixel art.
INK = (5, 7, 13)
COLD = (30, 52, 74)
BLUE = (111, 220, 239)
PALE = (231, 237, 245)
RED = (239, 68, 85)
GREEN = (58, 92, 70)
GREY = (142, 155, 176)

# slot -> (tier, caption, room tint, where it is earned)
PLATES = {
    "cg_breakroom_x": (3, "BREAK ROOM", GREEN, "eli_stance = TRUST + coat inspected"),
    "cg_terminal_x": (3, "SERVER CORRIDOR", COLD, "compliance = REFUSE + terminal re-read"),
    "cg_landing_x": (3, "THIRTEENTH LANDING", (46, 44, 52), "escape_route = STAIRS + replacement_list"),
    "cg_retention_x": (3, "FLOOR 0 — RETENTION", (26, 46, 78), "escape_route = ELEVATOR + rusk_keycard"),
    "cg_desk_x": (3, "MANAGER OFFICE", (86, 60, 44), "contract = SIGN"),
    "cg_present_x": (2, "LOBBY, 12:03 AM", (74, 72, 66), "contract = RESIGN + ledger_preserved + TRUST"),
    "cg_monday_x": (2, "OPEN OFFICE, 11:59 PM", (34, 36, 50), "ending = MONDAY_FOREVER"),
}

# Only the tier-3 plates get a censored counterpart. Tier 2 is "free web after an ad watch"
# in ops/adult_forks/ART_DIRECTION.md, so there is no censored version to ship — the
# presenter draws its own locked card for those. floor13_gen.py defines exactly these five.
LOCKED = [s for s, spec in PLATES.items() if spec[0] >= 3]

EMPLOYEE_NO = {
    "cg_breakroom_x": "EMPLOYEE 041",
    "cg_terminal_x": "EMPLOYEE 013",
    "cg_landing_x": "EMPLOYEE 013 / 041",
    "cg_retention_x": "EMPLOYEE 013",
    "cg_desk_x": "EMPLOYEE 042",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = (
        ["DejaVuSansMono-Bold.ttf", "DejaVuSans-Bold.ttf"] if bold
        else ["DejaVuSansMono.ttf", "DejaVuSans.ttf"]
    )
    for name in names:
        for base in ("/usr/share/fonts/truetype/dejavu/", "/usr/share/fonts/TTF/", ""):
            try:
                return ImageFont.truetype(base + name, size)
            except OSError:
                continue
    return ImageFont.load_default()


def room(tint: tuple[int, int, int], seed: int) -> Image.Image:
    """A dark room with one practical light, in the game's own palette.

    Not an attempt at the composition — that would only invite reading a placeholder as a
    draft. It reads as "a lit room, and nobody has drawn what is in it yet"."""
    rng = random.Random(seed)
    img = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(img)
    # vertical falloff from the ceiling light
    for y in range(H):
        k = max(0.0, 1.0 - abs(y - H * 0.28) / (H * 0.85))
        d.line([(0, y), (W, y)], fill=tuple(int(INK[i] + (tint[i] - INK[i]) * k * 0.9) for i in range(3)))
    # one fluorescent tube, the light source every prompt in floor13_gen.py names
    d.rectangle([W * 0.30, 44, W * 0.70, 62], fill=(232, 240, 236))
    glow = Image.new("RGB", (W, H), INK)
    ImageDraw.Draw(glow).ellipse([W * 0.13, -180, W * 0.87, H * 0.72], fill=tuple(min(255, c + 46) for c in tint))
    img = Image.blend(img, glow.filter(ImageFilter.GaussianBlur(120)), 0.5)
    d = ImageDraw.Draw(img)
    # rain on the window, right-hand third
    d.rectangle([W * 0.70, 96, W - 58, H - 150], outline=(58, 70, 88), width=3)
    for _ in range(170):
        x = rng.uniform(W * 0.70, W - 58)
        y = rng.uniform(96, H - 150)
        d.line([(x, y), (x - 3, y + rng.uniform(12, 34))], fill=(96, 122, 148), width=1)
    return img


def grain_and_scanlines(img: Image.Image, seed: int) -> Image.Image:
    """The post pass floor13_gen.py's docstring commits to: grain, a 2-px scanline and a
    palette clamp, so the plate reads as something the building's cameras produced."""
    rng = random.Random(seed + 7919)
    px = img.load()
    for _ in range(W * H // 26):
        x, y = rng.randrange(W), rng.randrange(H)
        n = rng.randint(-20, 20)
        px[x, y] = tuple(max(0, min(255, px[x, y][i] + n)) for i in range(3))
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(0, H, 2):
        d.line([(0, y), (W, y)], fill=(0, 0, 0, 44))
    d.rectangle([0, 0, W - 1, H - 1], outline=(0, 0, 0, 180), width=10)
    return img


def silhouette(d: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, fill) -> None:
    """The person-shaped white cut-out. Head, shoulders, torso — a blank where a body was."""
    hr = 58 * scale
    d.ellipse([cx - hr, cy - hr * 3.2, cx + hr, cy - hr * 1.2], fill=fill)
    d.polygon(
        [
            (cx - hr * 2.5, cy + hr * 3.0),
            (cx - hr * 1.9, cy - hr * 0.7),
            (cx - hr * 0.8, cy - hr * 1.35),
            (cx + hr * 0.8, cy - hr * 1.35),
            (cx + hr * 1.9, cy - hr * 0.7),
            (cx + hr * 2.5, cy + hr * 3.0),
        ],
        fill=fill,
    )


def caption(img: Image.Image, lines: list[tuple[str, int, tuple[int, int, int], bool]]) -> None:
    """Bottom-left stack, the same shape as the game's own header."""
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, H - 168, W, H], fill=(5, 7, 13, 214))
    d.line([(0, H - 168), (W, H - 168)], fill=RED, width=3)
    y = H - 146
    for text, size, colour, bold in lines:
        d.text((46, y), text, font=font(size, bold), fill=colour)
        y += size + 12


def open_plate(slot: str) -> Image.Image:
    tier, place, tint, earned = PLATES[slot]
    seed = sum(ord(c) for c in slot)
    img = room(tint, seed)
    d = ImageDraw.Draw(img, "RGBA")
    # A frame where the figure goes, so the composition reads as reserved, not forgotten.
    bx0, by0, bx1, by1 = W * 0.10, H * 0.16, W * 0.62, H * 0.74
    d.rectangle([bx0, by0, bx1, by1], outline=(PALE[0], PALE[1], PALE[2], 120), width=3)
    for x in range(int(bx0), int(bx1), 26):
        d.line([(x, by0), (x + 13, by0)], fill=(PALE[0], PALE[1], PALE[2], 40))
    silhouette(d, (bx0 + bx1) / 2, (by0 + by1) / 2 + 40, 1.28, (PALE[0], PALE[1], PALE[2], 34))
    d.text((bx0 + 26, by0 + 22), "PLATE RESERVED", font=font(30, True), fill=(PALE[0], PALE[1], PALE[2], 190))
    d.text((bx0 + 26, by0 + 62), "ops/floor13_art/floor13_gen.py plates --only " + slot,
           font=font(17), fill=(BLUE[0], BLUE[1], BLUE[2], 190))
    img = grain_and_scanlines(img, seed)
    caption(img, [
        (place, 30, PALE, True),
        (slot + "   ·   tier %d   ·   PLACEHOLDER, AWAITING ART" % tier, 19, RED, True),
        ("earned by: " + earned, 17, GREY, False),
    ])
    return img


def locked_plate(slot: str) -> Image.Image:
    tier, place, tint, _ = PLATES[slot]
    seed = sum(ord(c) for c in slot) + 313
    img = room(tuple(int(c * 0.62) for c in tint), seed)
    d = ImageDraw.Draw(img, "RGBA")
    # The same room, the person replaced by a white cut-out with a number on it.
    silhouette(d, W * 0.36, H * 0.46, 1.34, (246, 248, 252, 232))
    num = EMPLOYEE_NO.get(slot, "EMPLOYEE 000")
    f = font(23, True)
    tw = d.textlength(num, font=f)
    d.text((W * 0.36 - tw / 2, H * 0.46 + 36), num, font=f, fill=(24, 28, 38, 255))
    # The Auditor's scan line, the one thing the base game already draws over a scene.
    y = H * 0.55 + math.sin(seed) * 40
    d.line([(0, y), (W, y)], fill=(RED[0], RED[1], RED[2], 190), width=3)
    img = grain_and_scanlines(img, seed)
    caption(img, [
        ("RETENTION — RECORD WITHHELD", 30, PALE, True),
        (slot + "_locked   ·   censored plate, free tracks only", 19, RED, True),
        ("Observation logged. Variance acquires shape only when observed.", 17, GREY, False),
    ])
    return img


def withheld_card() -> Image.Image:
    """The fallback for a locked slot with no censored counterpart of its own.

    Tier 2 has no censored plate by design — ART_DIRECTION.md puts it at "free web after an
    ad watch", so there is nothing to censor, only something not yet paid for. Without this
    card the presenter drew an empty frame, which reads as a bug rather than as a gate."""
    img = room((40, 44, 58), 4242)
    d = ImageDraw.Draw(img, "RGBA")
    silhouette(d, W * 0.40, H * 0.46, 1.34, (246, 248, 252, 40))
    d.rectangle([W * 0.14, H * 0.20, W * 0.72, H * 0.70], outline=(RED[0], RED[1], RED[2], 150), width=3)
    d.text((W * 0.17, H * 0.24), "RECORD WITHHELD", font=font(44, True), fill=PALE)
    d.text((W * 0.17, H * 0.33), "This record exists. It has not been released to this terminal.",
           font=font(20), fill=GREY)
    img = grain_and_scanlines(img, 4242)
    caption(img, [
        ("RETENTION — PENDING RELEASE", 30, PALE, True),
        ("cg_withheld  ·  shown for any locked plate with no censored counterpart", 19, RED, True),
        ("Observation logged. Variance acquires shape only when observed.", 17, GREY, False),
    ])
    return img


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="overwrite plates that already exist")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for slot in PLATES:
        for path, build in ((OUT / f"{slot}.png", open_plate),
                            (OUT / f"{slot}_locked.png", locked_plate)):
            if path.name.endswith("_locked.png") and slot not in LOCKED:
                continue
            if path.exists() and not a.force:
                print(f"  keep    {path.name}")
                continue
            build(slot).save(path)
            made += 1
            print(f"  wrote   {path.name}  {W}x{H}")
    generic = OUT / "cg_withheld.png"
    if not generic.exists() or a.force:
        withheld_card().save(generic)
        made += 1
        print(f"  wrote   {generic.name}  {W}x{H}")
    print(f"\n{made} plate(s) written to {OUT}")
    print("Real renders replace these file-for-file; no other change is needed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
