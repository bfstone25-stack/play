#!/usr/bin/env python3
"""TITLE_SCREENS.md's two legibility checks, mechanised as far as they can be: (1) the
captured frames are laid out on one contact sheet to be READ, (2) every frame is downscaled
to 390 px wide (a phone) into shots/phone/ and a second sheet is made of those. The
reading itself is done by looking; this only makes the looking cheap.
    python3 tools/phone_check.py
"""
from pathlib import Path
from PIL import Image
HERE = Path(__file__).resolve().parent.parent
shots = sorted((HERE / "shots").glob("*.png"))
phone = HERE / "shots" / "phone"; phone.mkdir(exist_ok=True)
for s in shots:
    im = Image.open(s); im.resize((390, int(im.height * 390 / im.width)), Image.LANCZOS).save(phone / s.name)
def sheet(paths, w, out):
    ims = [Image.open(p) for p in paths]
    if not ims: return
    ims = [im.resize((w, int(im.height * w / im.width))) for im in ims]
    cols = 6; rows = (len(ims) + cols - 1) // cols; h = max(i.height for i in ims)
    sh = Image.new("RGB", (cols * w, rows * h), (11, 5, 9))
    for i, im in enumerate(ims): sh.paste(im, ((i % cols) * w, (i // cols) * h))
    sh.save(out); print("sheet", out, len(ims), "frames")
sheet(shots, 300, HERE / "shots" / "_sheet_full.png")
sheet(sorted(phone.glob("*.png")), 195, HERE / "shots" / "_sheet_phone.png")
