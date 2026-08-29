#!/usr/bin/env python3
"""Rasterize a one-bit CJK subset for Floor 13 Chinese locale."""
from __future__ import annotations

import ast
import math
import re
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = ROOT / "assets" / "fonts"
PIXEL_DIR = ROOT / "assets" / "pixel"
SOURCE_FONT = FONT_DIR / "wqy-microhei.ttc"
SOURCE_FILES = sorted((ROOT / "scripts").glob("*.gd"))
SIZE = 10
ATLAS_WIDTH = 1024
PADDING = 1


def source_charset() -> list[str]:
    chars = set(chr(codepoint) for codepoint in range(32, 127))
    quoted = re.compile(r'"(?:\\.|[^"\\])*"')
    triple = re.compile(r'"""(?:\\.|[^"\\])*"""', re.S)
    for path in SOURCE_FILES:
        source = path.read_text(encoding="utf-8")
        for match in list(quoted.finditer(source)) + list(triple.finditer(source)):
            try:
                value = ast.literal_eval(match.group(0))
            except (SyntaxError, ValueError):
                continue
            if not isinstance(value, str):
                continue
            chars.update(char for char in value if char >= " " and char != "\u007f")
    return sorted(chars, key=ord)


def glyph_bitmap(font: ImageFont.FreeTypeFont, char: str, size: int):
    east_asian = unicodedata.east_asian_width(char) in {"W", "F"}
    advance = size if east_asian else max(3, round(font.getlength(char)))
    if char == " ":
        return Image.new("1", (1, 1), 0), 0, 0, advance
    canvas = Image.new("L", (size * 3, size * 3), 0)
    draw = ImageDraw.Draw(canvas)
    baseline = size + 2
    draw.text((size, baseline), char, font=font, fill=255, anchor="ls", stroke_width=0)
    mono = canvas.point(lambda value: 255 if value >= 96 else 0, mode="1")
    bbox = mono.getbbox()
    if bbox is None:
        return Image.new("1", (1, 1), 0), 0, 0, advance
    crop = mono.crop(bbox)
    return crop, bbox[0] - size, bbox[1] - (baseline - size), advance


def main() -> None:
    chars = source_charset()
    font = ImageFont.truetype(str(SOURCE_FONT), size=SIZE, index=0)
    glyphs = [(char, *glyph_bitmap(font, char, SIZE)) for char in chars]
    row_height = SIZE + PADDING * 2 + 2
    positions = []
    x = PADDING
    y = PADDING
    for char, bitmap, x_offset, y_offset, advance in glyphs:
        width, height = bitmap.size
        if x + width + PADDING > ATLAS_WIDTH:
            x = PADDING
            y += row_height
        positions.append((char, bitmap, x_offset, y_offset, advance, x, y))
        x += width + PADDING * 2
    used_height = y + row_height
    atlas_height = 2 ** math.ceil(math.log2(max(32, used_height)))
    atlas = Image.new("RGBA", (ATLAS_WIDTH, atlas_height), (0, 0, 0, 0))
    for _, bitmap, _, _, _, gx, gy in positions:
        mask = bitmap.convert("L")
        ink = Image.new("RGBA", bitmap.size, (255, 255, 255, 255))
        atlas.paste(ink, (gx, gy), mask)
    atlas.save(PIXEL_DIR / "floor13_cjk.png", optimize=True)
    lines = [
        f'info face="Floor13 CJK {SIZE}" size={SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0 outline=0',
        f"common lineHeight={SIZE + 2} base={SIZE} scaleW={ATLAS_WIDTH} scaleH={atlas_height} pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        'page id=0 file="floor13_cjk.png"',
        f"chars count={len(chars)}",
    ]
    for char, bitmap, x_offset, y_offset, advance, gx, gy in positions:
        width, height = bitmap.size
        if char == " ":
            width = 0
            height = 0
        lines.append(
            "char id={id} x={x} y={y} width={width} height={height} "
            "xoffset={xoffset} yoffset={yoffset} xadvance={advance} page=0 chnl=15".format(
                id=ord(char), x=gx, y=gy, width=width, height=height,
                xoffset=x_offset, yoffset=y_offset, advance=advance,
            )
        )
    (PIXEL_DIR / "floor13_cjk.fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Floor13 CJK glyphs={len(chars)} atlas={ATLAS_WIDTH}x{atlas_height}")


if __name__ == "__main__":
    main()
