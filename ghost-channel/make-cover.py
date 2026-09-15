#!/usr/bin/env python3
"""Hand-authored cover: cyan / magenta on black, matching the jam theme card."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
W, H = 630, 500
img = Image.new("RGB", (W, H), (7, 6, 12))
d = ImageDraw.Draw(img)

for y in range(0, H, 3):
    d.line((0, y, W, y), fill=(12, 10, 22))

d.rectangle((24, 24, W - 25, H - 25), outline=(45, 240, 240), width=2)
d.rectangle((32, 32, W - 33, H - 33), outline=(255, 61, 173), width=1)

try:
    font_lg = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 64)
    font_md = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
except OSError:
    font_lg = font_md = font_sm = ImageFont.load_default()

d.text((56, 70), "GHOST", fill=(45, 240, 240), font=font_lg)
d.text((56, 140), "CHANNEL", fill=(45, 240, 240), font=font_lg)
d.text((56, 230), "TRUST NO ONE", fill=(255, 61, 173), font=font_md)
d.text((56, 290), "Five callsigns. One mimic.", fill=(200, 214, 228), font=font_sm)
d.text((56, 318), "Brackeys Game Jam 2026.2", fill=(125, 142, 163), font=font_sm)
d.text((56, 420), "NET CONTROL  //  bfstone25-stack", fill=(45, 240, 240), font=font_sm)

img.save(OUT / "cover.png", optimize=True)
img.resize((315, 250)).save(OUT / "cover-315.png", optimize=True)
print("wrote", OUT / "cover.png")
