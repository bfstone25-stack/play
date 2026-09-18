#!/usr/bin/env python3
"""Placeholder plates for Midnight Pawn: Collateral.

Nothing is rendered by this script — the RTX 3060 is queued serially and owned by the main
session. These are flat PIL cards in the game's own palette (itch-analytics/themes/
midnight-pawn.json: #100d18 / #201928 / #f1dfb0 / #e8b84a) that stand in for the real plates
so the reading gate, the distribution gate and the Reading Ledger can all be exercised before
any art exists.

Every card prints the slot name, the unlock condition it is earned by, and the words
PLACEHOLDER in the corner, so one can never be mistaken for a finished plate in a build.

    python3 tools/make_placeholders.py            # writes game/images/{cgs,bg}
    python3 tools/make_placeholders.py --force    # overwrite real art too (asks first)
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CGS = os.path.join(ROOT, "game", "images", "cgs")
BGS = os.path.join(ROOT, "game", "images", "bg")

INK = "#100d18"
PANEL = "#201928"
CREAM = "#f1dfb0"
GOLD = "#e8b84a"
DIM = "#5c5468"

W, H = 1920, 1080
LOCK_W, LOCK_H = 960, 540

# slot -> (title, condition text, kind)
PLATES = [
    ("cg_tamsin", "The finial — what the room looked like",
     "prices['finial'] == 'fair' and 'finial' in readings_taken", "free"),
    ("cg_finial", "The finial — what she was doing in it",
     "prices['finial'] == 'high' and 'finial' in readings_taken", "gated"),
    ("cg_ring", "The ring — eleven months after",
     "'ring' in readings_taken and ivo_refused", "gated"),
    ("cg_veil", "The veil — the night before the funeral",
     "'veil' in readings_taken and paid['veil'] > value('veil')", "gated"),
    ("cg_market", "Calder's proof — somebody else's night",
     "len(client readings) >= 2", "gated"),
    ("cg_collateral", "The Black Ledger — your own hand",
     "'collateral' in readings_taken (unrefusable)", "gated"),
]

# The censored stand-ins declared in 00_init.rpy. Dark plates, not mosaics.
LOCKED = ["finial", "ring", "veil", "market", "collateral"]

BACKGROUNDS = [
    ("bg_shop", "The shop — counter, shelves, oil lamp, rain on the window"),
    ("bg_market", "The Ossuary Market — bone courses, stalls, lantern light"),
]


def _font(size):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if os.path.isfile(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _card(w, h, title, subtitle, condition, accent, tag):
    img = Image.new("RGB", (w, h), INK)
    d = ImageDraw.Draw(img)
    s = w / 1920.0

    # A lamp-ish pool so the card is not a flat rectangle and a mis-set tint is visible.
    for i in range(24, 0, -1):
        r = int(i * 34 * s)
        v = 6 + (24 - i)
        d.ellipse(
            [w * 0.5 - r * 1.6, h * 0.5 - r, w * 0.5 + r * 1.6, h * 0.5 + r],
            fill=(0x10 + v // 3, 0x0d + v // 4, 0x18 + v // 6),
        )

    d.rectangle([int(60 * s), int(60 * s), w - int(60 * s), h - int(60 * s)],
                outline=accent, width=max(2, int(4 * s)))

    d.text((int(96 * s), int(96 * s)), tag, font=_font(int(30 * s)), fill=DIM)
    d.text((int(96 * s), int(h * 0.40)), title, font=_font(int(62 * s)), fill=accent)
    d.text((int(96 * s), int(h * 0.40) + int(88 * s)), subtitle,
           font=_font(int(36 * s)), fill=CREAM)
    if condition:
        d.text((int(96 * s), int(h * 0.40) + int(150 * s)), "earned when:",
               font=_font(int(26 * s)), fill=DIM)
        d.text((int(96 * s), int(h * 0.40) + int(184 * s)), condition,
               font=_font(int(28 * s)), fill=GOLD)
    d.text((int(96 * s), h - int(130 * s)), "PLACEHOLDER — no art rendered",
           font=_font(int(30 * s)), fill=DIM)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true",
                    help="overwrite files that are larger than a placeholder (i.e. real art)")
    args = ap.parse_args()

    os.makedirs(CGS, exist_ok=True)
    os.makedirs(BGS, exist_ok=True)
    written, skipped = [], []

    def save(img, path):
        if os.path.isfile(path) and os.path.getsize(path) > 200_000 and not args.force:
            skipped.append(os.path.basename(path))
            return
        img.save(path, "WEBP", quality=88, method=4)
        written.append(os.path.basename(path))

    for slot, title, cond, kind in PLATES:
        accent = CREAM if kind == "free" else GOLD
        tag = "READING \u00b7 free on every track" if kind == "free" else "READING \u00b7 gated"
        card = _card(W, H, slot, title, cond, accent, tag)
        save(card, os.path.join(CGS, "%s.webp" % slot))
        # cg_pick() on the paid track loads images/cgs/cg_<name>_x.webp for every gated slot
        # (09_dist.rpy:190). Without these the paid build silently shows the censored plate,
        # which is the single easiest way to ship a fork that looks broken to the only people
        # who paid for it.
        if kind == "gated":
            save(_card(W, H, slot + "_x", title, cond, accent,
                       "READING \u00b7 uncensored (paid package only)"),
                 os.path.join(CGS, "%s_x.webp" % slot))

    for name in LOCKED:
        save(_card(LOCK_W, LOCK_H, "cg_%s (locked)" % name,
                   "silhouette stand-in — backlit, nudity tags dropped",
                   "", DIM, "CENSORED PLATE"),
             os.path.join(CGS, "cg_%s_x_locked.webp" % name))

    for slot, title in BACKGROUNDS:
        save(_card(W, H, slot, title, "", PANEL, "BACKGROUND · no people"),
             os.path.join(BGS, "%s.webp" % slot))

    print("wrote %d file(s): %s" % (len(written), ", ".join(written)))
    if skipped:
        print("skipped %d (look like real art; --force to replace): %s"
              % (len(skipped), ", ".join(skipped)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
