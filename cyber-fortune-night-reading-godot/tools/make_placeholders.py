#!/usr/bin/env python3
"""Labelled placeholder plates for every art slot the fork has.

Every one of these says PLACEHOLDER on its face, in the frame, at a size you cannot miss
on a screenshot — because the way placeholder art ships is that it stops being obvious
(memory: verification-that-lies, where a placeholder passed a check by file size, and
ops/check_two_worlds.py, which found nine PLACEHOLDER cards still in Flutter weeks on).

It also writes assets/night/placeholders.json: the list of slots that are still fake.
The game reads it (Night.is_placeholder) and the README's honest list is generated from
it, so a slot stops being called a placeholder only when it is actually replaced.

    python3 tools/make_placeholders.py            # write any slot that has no real art
    python3 tools/make_placeholders.py --force    # overwrite, including real art

After replacing any plate with a rendered one:
    $GODOT --headless --path . --import
or the old image renders from the .godot cache with no error at all.
"""
from __future__ import annotations
import argparse, json, pathlib
from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "assets" / "night"
FONTS = HERE.parent / "assets" / "fonts"

# slot -> (size, tier, what the rendered plate will be)
SLOTS: dict[str, tuple[tuple[int, int], int, str]] = {}
for cid, who in (("mirren", "the tarot reader — auburn, green eyes, the hood"),
                 ("qiao", "the temple attendant — the robe, incense, the tube"),
                 ("dagny", "the arcade owner — fair, blunt, the jacket")):
    SLOTS["%s_calm" % cid] = ((448, 560), 1, "%s · at the table, clothed, charged" % who)
    SLOTS["%s_turn" % cid] = ((448, 560), 2, "%s · the reading lands: a garment doing work" % who)
    SLOTS["%s_night" % cid] = ((896, 560), 3, "%s · the payoff, tier 3" % who)
    SLOTS["%s_night_locked" % cid] = ((896, 560), 2, "%s · the censored plate behind the gate" % who)
# Portrait, and 896x1152 rather than the old square 1024x1024, because the slot changed
# meaning on 2026-09-20. It used to be a square still life of the table and the two
# instruments — no subject — which is the title ops/adult_forks/TITLE_SCREENS.md opens by
# rejecting. It is now the key visual the title screen is built on: Mirren at the table,
# full bleed behind a 720x1280 portrait canvas. A square crop of that cuts her head off.
SLOTS["title_kv"] = ((896, 1152), 1, "Mirren at the night table — the title screen's key visual")

PLUM = (18, 8, 15)
HOT = (255, 61, 138)
AMBER = (255, 179, 71)
TEXT = (255, 244, 236)


def font(size: int):
    for p in (FONTS / "Nunito-VariableFont_wght.ttf", FONTS / "Nunito-Regular.ttf"):
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size)
            except OSError:
                pass
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except OSError:
        return ImageFont.load_default()


def plate(name: str, size: tuple[int, int], tier: int, what: str) -> Image.Image:
    w, h = size
    im = Image.new("RGB", size, PLUM)
    d = ImageDraw.Draw(im)
    # a diagonal hatch, so nobody mistakes it for a dark render
    for x in range(-h, w, 48):
        d.line([(x, h), (x + h, 0)], fill=(40, 18, 34), width=2)
    d.rectangle([6, 6, w - 7, h - 7], outline=HOT, width=3)
    d.text((22, 20), "PLACEHOLDER", font=font(max(22, w // 22)), fill=HOT)
    d.text((22, 20 + max(30, w // 18)), name, font=font(max(18, w // 30)), fill=AMBER)
    d.text((22, 20 + max(56, w // 11)), "tier %d" % tier, font=font(max(14, w // 42)), fill=TEXT)
    f = font(max(13, w // 46))
    y = h - 34 - 20 * (len(what) // 46)
    words, line = what.split(), ""
    for word in words:
        if len(line) + len(word) > 46:
            d.text((22, y), line, font=f, fill=TEXT)
            y += 20
            line = word
        else:
            line = (line + " " + word).strip()
    d.text((22, y), line, font=f, fill=TEXT)
    return im


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    marks = json.loads((OUT / "placeholders.json").read_text()) if (OUT / "placeholders.json").exists() else []
    marks = set(marks)
    for name, (size, tier, what) in SLOTS.items():
        p = OUT / (name + ".png")
        if p.exists() and not a.force and name not in marks:
            print("  kept (real art): %s" % name)
            continue
        plate(name, size, tier, what).save(p)
        marks.add(name)
        print("  placeholder: %s %dx%d tier %d" % (name, size[0], size[1], tier))
    (OUT / "placeholders.json").write_text(json.dumps(sorted(marks), indent=1))
    print("%d slots, %d still placeholder" % (len(SLOTS), len(marks)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
