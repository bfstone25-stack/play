#!/usr/bin/env python3
"""Censored placeholder plates for SILVERTONGUE: AFTER HOURS — no GPU, no model.

The real art pipeline is ops/silvertongue_art/silvertongue_gen.py and needs the 3060.
This script needs PIL and nothing else, and exists so the gallery, the unlock keys and
the tier-3 censor path are testable before a single real plate has been rendered.

The plates are deliberately ugly: nobody should mistake one for finished art, and nothing
here is a nude. Tier 3 gets two files — `cg3_<scen>.png` (what the paid bundle would hold)
and `cg3_<scen>_locked.png` (the censored plate the free bundle actually ships).

    python3 play/silvertongue-x/tools/make_placeholders.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "frontend" / "assets" / "cg"
SCENARIOS = ["closing_time", "the_key", "life_model", "house_rule", "last_night"]
W, H = 1344, 768
TINT = {1: (44, 52, 66), 2: (66, 46, 44), 3: (30, 30, 34)}


def font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for tier in (1, 2, 3):
        for scen in SCENARIOS:
            key = f"cg{tier}_{scen}"
            for censored in ((False, True) if tier == 3 else (False,)):
                img = Image.new("RGB", (W, H), TINT[tier])
                d = ImageDraw.Draw(img)
                for y in range(0, H, 4):            # scanlines, so it reads as a stand-in
                    d.line([(0, y), (W, y)], fill=(0, 0, 0), width=1)
                d.rectangle([24, 24, W - 24, H - 24], outline=(120, 120, 130), width=3)
                d.text((60, 90), key, font=font(58), fill=(232, 228, 220))
                d.text((60, 172), f"tier {tier} · {scen}", font=font(34), fill=(170, 170, 178))
                d.text((60, H - 120), "PLACEHOLDER — no art rendered yet",
                       font=font(30), fill=(150, 150, 158))
                if censored:
                    box = [W // 2 - 300, 300, W // 2 + 300, 470]
                    d.rectangle(box, fill=(18, 18, 20), outline=(200, 60, 60), width=4)
                    d.text((box[0] + 40, box[1] + 62), "CENSORED — WIN TO UNLOCK",
                           font=font(36), fill=(220, 90, 90))
                img.save(OUT / f"{key}{'_locked' if censored else ''}.png")
                made += 1
    print(f"{made} placeholder plates -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
