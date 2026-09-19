#!/usr/bin/env python3
"""Build the project-owned monochrome BMFont subsets used at runtime.

The redistributable Apache-2.0 WenQuanYi source is rasterized once into a
finite, one-bit glyph atlas. Godot never renders the vector source in-game.
"""
from __future__ import annotations

import ast
import math
import re
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = ROOT / "assets" / "fonts"
SOURCE_FONT = FONT_DIR / "wqy-microhei.ttc"
SOURCE_FILES = sorted((ROOT / "scripts").glob("*.gd"))
SIZES = (12, 16)
ATLAS_WIDTH = 1024
PADDING = 1


def source_charset() -> list[str]:
    chars = set(chr(codepoint) for codepoint in range(32, 127))
    quoted = re.compile(r'"(?:\\.|[^"\\])*"')
    for path in SOURCE_FILES:
        source = path.read_text(encoding="utf-8")
        for match in quoted.finditer(source):
            try:
                value = ast.literal_eval(match.group(0))
            except (SyntaxError, ValueError):
                continue
            chars.update(char for char in value if char >= " " and char != "\u007f")
    return sorted(chars, key=ord)


def glyph_bitmap(font: ImageFont.FreeTypeFont, char: str, size: int) -> tuple[Image.Image, int, int, int]:
    east_asian = unicodedata.east_asian_width(char) in {"W", "F"}
    advance = size if east_asian else max(3, round(font.getlength(char)))
    if char == " ":
        return Image.new("1", (1, 1), 0), 0, 0, advance

    canvas = Image.new("L", (size * 3, size * 3), 0)
    draw = ImageDraw.Draw(canvas)
    baseline = size + 2
    draw.text((size, baseline), char, font=font, fill=255, anchor="ls", stroke_width=0)
    # A hard threshold produces exactly transparent/opaque pixels: no AA,
    # subpixel coverage, MSDF, or runtime smoothing.
    mono = canvas.point(lambda value: 255 if value >= 96 else 0, mode="1")
    bbox = mono.getbbox()
    if bbox is None:
        return Image.new("1", (1, 1), 0), 0, 0, advance
    crop = mono.crop(bbox)
    x_offset = bbox[0] - size
    y_offset = bbox[1] - (baseline - size)
    return crop, x_offset, y_offset, advance


def build(size: int, chars: list[str]) -> tuple[int, tuple[int, int]]:
    font = ImageFont.truetype(str(SOURCE_FONT), size=size, index=0)
    glyphs = [(char, *glyph_bitmap(font, char, size)) for char in chars]
    row_height = size + PADDING * 2 + 2
    positions: list[tuple[str, Image.Image, int, int, int, int, int]] = []
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

    stem = f"midnight_pixel_{size}"
    atlas_name = f"{stem}.png"
    atlas.save(FONT_DIR / atlas_name, optimize=True)

    lines = [
        f'info face="Midnight Pixel {size}" size={size} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0 outline=0',
        # Godot's BMFont loader treats four zero channel descriptors as a
        # plain RGBA8 color atlas. Alpha-only channel metadata is interpreted
        # as a separate outline plane and is rejected without outline data.
        f"common lineHeight={size + 2} base={size} scaleW={ATLAS_WIDTH} scaleH={atlas_height} pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        f'page id=0 file="{atlas_name}"',
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
                id=ord(char),
                x=gx,
                y=gy,
                width=width,
                height=height,
                xoffset=x_offset,
                yoffset=y_offset,
                advance=advance,
            )
        )
    (FONT_DIR / f"{stem}.fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return len(chars), atlas.size


def main() -> None:
    chars = source_charset()
    for size in SIZES:
        count, atlas_size = build(size, chars)
        print(f"BMFont size={size} glyphs={count} atlas={atlas_size[0]}x{atlas_size[1]} mono=1bit")


if __name__ == "__main__":
    main()
