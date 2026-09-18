#!/usr/bin/env python3
"""Placeholder plates for Midnight Pawn: Collateral (Godot).

Ported from the Ren'Py fork's tools/make_placeholders.py. Nothing is rendered by this
script — the RTX 3060 is queued serially and owned by the main session. These are flat PIL
cards in the game's own palette (#100d18 / #201928 / #f1dfb0 / #e8b84a) that stand in for
the real plates so the reading gate, the distribution gate and the Reading Ledger can all be
exercised before any art exists.

Every card prints the slot name, the unlock condition it is earned by, and the word
PLACEHOLDER, so one can never be mistaken for a finished plate in a build.

The layout is the overnight-clause one, which the gate depends on:

    assets/plates/cg_tamsin.png          the one ungated reading, open in every package
    assets/plates/cg_<name>_locked.png   the censored stand-in that ships in free packages
    assets/plates_x/cg_<name>.png        the uncensored plate — export-excluded from web

    python3 tools/make_placeholders.py            # write missing placeholders
    python3 tools/make_placeholders.py --force    # overwrite real art too
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLATES = os.path.join(ROOT, "assets", "plates")
PLATES_X = os.path.join(ROOT, "assets", "plates_x")

INK = "#100d18"
CREAM = "#f1dfb0"
GOLD = "#e8b84a"
DIM = "#5c5468"

# The stage window is 300x240 (5:4), so the plates are authored to that aspect.
W, H = 960, 768

# slot -> (title, condition, gated)
SLOTS = [
    ("cg_tamsin", "The finial - what the room looked like",
     "prices['finial'] == 'fair' and 'finial' in readings_taken", False),
    ("cg_finial", "The finial - what she was doing in it",
     "prices['finial'] == 'high' and 'finial' in readings_taken", True),
    ("cg_ring", "The ring - eleven months after",
     "'ring' in readings_taken and ivo_refused", True),
    ("cg_veil", "The veil - the night before the funeral",
     "'veil' in readings_taken and paid['veil'] > value('veil')", True),
    ("cg_market", "Calder's proof - somebody else's night",
     "len(client readings) >= 2", True),
    ("cg_collateral", "The Black Ledger - your own hand",
     "'collateral' in readings_taken (unrefusable)", True),
]


def _font(size):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if os.path.isfile(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _card(title, subtitle, condition, accent, tag):
    img = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(img)

    # A lamp-ish pool so the card is not a flat rectangle and a mis-set tint is visible.
    for i in range(24, 0, -1):
        r = int(i * 17)
        v = 6 + (24 - i)
        d.ellipse([W * 0.5 - r * 1.6, H * 0.5 - r, W * 0.5 + r * 1.6, H * 0.5 + r],
                  fill=(0x10 + v // 3, 0x0d + v // 4, 0x18 + v // 6))

    d.rectangle([30, 30, W - 30, H - 30], outline=accent, width=3)
    d.text((52, 52), tag, font=_font(22), fill=DIM)
    d.text((52, int(H * 0.40)), title, font=_font(44), fill=accent)
    d.text((52, int(H * 0.40) + 62), subtitle, font=_font(24), fill=CREAM)
    if condition:
        d.text((52, int(H * 0.40) + 112), "earned when:", font=_font(19), fill=DIM)
        d.text((52, int(H * 0.40) + 138), condition, font=_font(20), fill=GOLD)
    d.text((52, H - 78), "PLACEHOLDER - no art rendered", font=_font(22), fill=DIM)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true",
                    help="overwrite files that look like real art")
    args = ap.parse_args()

    os.makedirs(PLATES, exist_ok=True)
    os.makedirs(PLATES_X, exist_ok=True)
    written, skipped = [], []

    def save(img, path):
        if os.path.isfile(path) and os.path.getsize(path) > 200_000 and not args.force:
            skipped.append(os.path.basename(path))
            return
        img.save(path, "PNG")
        written.append(os.path.relpath(path, ROOT))

    for slot, title, cond, gated in SLOTS:
        if gated:
            # The censored stand-in is the only plate a free package carries for this
            # slot. Dark, backlit, nudity tags dropped - not a mosaic.
            save(_card(slot + " (censored)",
                       "silhouette stand-in - backlit, nudity tags dropped",
                       cond, DIM, "CENSORED PLATE - ships in every package"),
                 os.path.join(PLATES, "%s_locked.png" % slot))
            # The real one. assets/plates_x/ is export-excluded from both Web presets, so
            # this file is simply not in the free download; tests/pack_audit.gd proves it.
            save(_card(slot, title, cond, GOLD,
                       "READING - uncensored (paid package only)"),
                 os.path.join(PLATES_X, "%s.png" % slot))
        else:
            save(_card(slot, title, cond, CREAM, "READING - free on every track"),
                 os.path.join(PLATES, "%s.png" % slot))

    print("wrote %d file(s):\n  %s" % (len(written), "\n  ".join(written)))
    if skipped:
        print("skipped %d (look like real art; --force to replace): %s"
              % (len(skipped), ", ".join(skipped)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
