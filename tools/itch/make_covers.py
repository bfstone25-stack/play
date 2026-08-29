#!/usr/bin/env python3
"""Compose itch cover images (1260x1000) from in-game captures."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SHOTS = Path("/tmp/itch-shots")
OUT = Path("/tmp/itch-covers")
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1260, 1000
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def cover_base(img: Image.Image) -> Image.Image:
    """Scale to fill WxH then center-crop."""
    scale = max(W / img.width, H / img.height)
    img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    x = (img.width - W) // 2
    y = (img.height - H) // 2
    return img.crop((x, y, x + W, y + H))


def vignette(img: Image.Image, strength: float = 0.55) -> Image.Image:
    """Darken edges + heavy bottom gradient for title legibility."""
    px = img.load()
    for yy in range(img.height):
        for xx in range(0, img.width, 1):
            pass
    # vectorized-ish: build gradient overlay once
    grad = Image.new("L", (1, H))
    for yy in range(H):
        # bottom 45% fades to black
        t = max(0.0, (yy - H * 0.45) / (H * 0.55))
        grad.putpixel((0, yy), int(255 * min(1.0, t * 1.25) * strength))
    grad = grad.resize((W, H))
    black = Image.new("RGB", (W, H), (0, 0, 0))
    return Image.composite(black, img, grad)


def draw_title(img: Image.Image, title_lines: list[str], sub: str, font_path: str, accent: tuple) -> Image.Image:
    d = ImageDraw.Draw(img)
    y = H - 96 - len(title_lines) * 86 - 70
    # accent bar
    d.rectangle([72, y - 28, 72 + 14, y + len(title_lines) * 86 + 26], fill=accent)
    x = 116
    for line in title_lines:
        font = ImageFont.truetype(font_path, 82)
        # shadow
        d.text((x + 3, y + 4), line, font=font, fill=(0, 0, 0))
        d.text((x, y), line, font=font, fill=(245, 240, 228))
        y += 86
    subfont = ImageFont.truetype(SANS, 34)
    d.text((x + 2, y + 14 + 2), sub, font=subfont, fill=(0, 0, 0))
    d.text((x, y + 14), sub, font=subfont, fill=accent)
    return img


def make(src: Path, out: str, title_lines: list[str], sub: str, font_path: str, accent: tuple, crop: tuple | None = None, darken: float = 0.55) -> None:
    img = Image.open(src).convert("RGB")
    if crop:
        img = img.crop(crop)
    img = cover_base(img)
    img = ImageEnhance.Contrast(img).enhance(1.06)
    img = vignette(img, darken)
    img = draw_title(img, title_lines, sub, font_path, accent)
    path = OUT / out
    img.save(path, "PNG")
    print("cover ->", path, img.size)


# Late Inspection: corridor shot, serif title, sickly green accent
make(SHOTS / "late-zone-corridor.png", "late-inspection.png",
     ["LATE INSPECTION:", "FLAT 404"], "FIRST-PERSON HORROR VN", SERIF, (0x9e, 0xc4, 0x6a))

# Floor 13: open office with red scanline, sans title, scanner-red accent
make(SHOTS / "floor13-area-office.png", "floor-13.png",
     ["FLOOR 13:", "NIGHT SHIFT"], "POINT-CLICK OFFICE HORROR", SANS, (0xff, 0x52, 0x64))

# Midnight Pawn: storefront art cropped from the title screen, gold accent
make(SHOTS / "mp-en" / "01-title-desktop.png", "midnight-pawn.png",
     ["MIDNIGHT PAWN", "& CRYPT"], "SHOP BY DAY · CRYPT BY NIGHT", SANS, (0xe8, 0xc8, 0x6a),
     crop=(100, 125, 700, 545), darken=0.5)
