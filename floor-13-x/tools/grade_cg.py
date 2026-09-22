#!/usr/bin/env python3
"""Light the CG plates with HOLDOVER's lamp instead of Floor 13's.

    python3 tools/grade_cg.py          # grades assets/cg/*.png IN PLACE from git HEAD

The plates were rendered under the parent's fluorescent key -- cold, teal, blue-shadowed
-- while the rooms, the interface and the wordmark all moved to sodium
(tools/palette_holdover.py). A plate still lit by the parent's tube reads as borrowed
from another game, which is the complaint this whole pass exists to answer.

Two attempts, and the first one is the lesson. It reused the HSV hue map the flat pixel
art takes. These plates are mostly TEAL, teal sits on the hinge of that map, and pushing
it toward 35 deg took entire frames through green: skin went sickly, the break room read
as lime. Every measured number cleared. ops/STANDARD.md: "a number can tell you a picture
is wrong; it cannot tell you it is right."

What is here instead is what a lamp actually does -- a per-channel curve, not a rotation.
It cannot invent green because it never moves a pixel across the wheel; it only changes
how much of each primary survives. Sodium also genuinely kills green, so green-dominant
pixels are pulled back explicitly -- but only by 0.55, deliberately. `cg_breakroom_x` and
its locked partner come out of this noticeably greener than every other plate, and that is
CORRECT: the break room's green emergency light is written into the prose ("Under green
emergency light he looks every one of his thirty-one years"). It is the only green in the
game, which is what makes it read as a named light source rather than a grading mistake.
Do not "fix" it.

This is a GRADE, not a render. The right answer is plates rendered under this lamp in the
first place; that is queued and on ops/PUNCHLIST.md. Re-run this after any new install.
"""
import pathlib
import numpy as np
from PIL import Image

GAIN = np.array([1.13, 0.985, 0.75])     # R up, G held, B down -- the lamp
LIFT = np.array([14.0, 7.0, 1.0])        # shadows toward amber, not toward black
SAT = 1.20

# The key visual is graded harder than the in-game plates, and the reason is the shelf
# rather than the story. A CG is looked at full-screen for as long as the player wants; the
# key visual has to survive as a thumbnail in a grid next to Nutaku's top 100, whose horror
# bucket sells at 0.62 brightness / 0.38 saturation (ops/SHELF_STYLE.md). At the in-game
# constants this plate measured 0.52/0.29 -- under the floor on both. Same lamp, turned up.
KV_GAIN = np.array([1.26, 1.01, 0.66])
KV_LIFT = np.array([30.0, 15.0, 2.0])
KV_SAT = 1.52
KV_GAMMA = 0.88                          # a little exposure, only on this plate


def grade(im: Image.Image, gain=GAIN, lift=LIFT, sat=SAT, gamma=1.0) -> Image.Image:
    x = np.asarray(im.convert("RGBA")).astype(np.float32)
    rgb, alpha = x[..., :3], x[..., 3:]
    rgb = rgb * gain + lift * (1.0 - rgb / 255.0)
    g_excess = np.clip(rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2]), 0, None)
    rgb[..., 1] -= g_excess * 0.55
    lum = (rgb * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True)
    rgb = lum + (rgb - lum) * sat
    # Contrast, not exposure. v1 of this line lifted the mids with a gamma as well and the
    # plates came back milky -- the highlights had nowhere left to go.
    n = np.clip(rgb / 255.0, 0, 1)
    n = n * n * (3 - 2 * n) * 0.62 + n * 0.38
    if gamma != 1.0:
        n = n ** gamma
    return Image.fromarray(
        np.concatenate([np.clip(n * 255, 0, 255), alpha], -1).astype(np.uint8), "RGBA")


def grade_keyvisual(path="assets/title/keyvisual.webp") -> None:
    im = grade(Image.open(path), KV_GAIN, KV_LIFT, KV_SAT, KV_GAMMA).convert("RGB")
    im.save(path, "WEBP", quality=92, method=6)
    print(" ", path, im.size)


if __name__ == "__main__":
    import sys
    if "--keyvisual" in sys.argv:
        grade_keyvisual()
    else:
        for p in sorted(pathlib.Path("assets/cg").glob("*.png")):
            grade(Image.open(p)).save(p, optimize=True)
            print(" ", p.name)
