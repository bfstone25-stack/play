#!/usr/bin/env python3
"""Rasterize a one-bit CJK/Kana/Hangul/Latin-1 subset for Floor 13 locales."""
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
SIZE = 12
ATLAS_WIDTH = 1024
PADDING = 1
LINE_PAD = 6
EXTRAS = (
    "English简体中文日本語Español한국어言語언어Idioma"
    "ñáéíóúüÑÁÉÍÓÚÜ¿¡—–·"
)


def _font_path(name: str) -> Path | None:
    home = Path.home() / ".local/share/fonts"
    candidates = {
        "nanum": [
            home / "NanumGothic.ttf",
            Path("/usr/share/fonts/truetype/nanum/NanumGothic.ttf"),
        ],
        "dejavu": [Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")],
        "wqy": [SOURCE_FONT, Path("/usr/share/fonts/truetype/wqy/wqy-microhei.ttc")],
    }
    for path in candidates[name]:
        if path.is_file():
            return path
    return None


def source_charset() -> list[str]:
    chars = set(chr(codepoint) for codepoint in range(32, 127))
    chars.update(EXTRAS)
    for codepoint in range(0xA0, 0x100):
        chars.add(chr(codepoint))
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


def _is_hangul(char: str) -> bool:
    code = ord(char)
    return (
        0xAC00 <= code <= 0xD7AF
        or 0x1100 <= code <= 0x11FF
        or 0x3130 <= code <= 0x318F
    )


def _is_latin_ext(char: str) -> bool:
    code = ord(char)
    return 0xA0 <= code <= 0x24F or 0x1E00 <= code <= 0x1EFF


def _load_faces(size: int) -> dict[str, ImageFont.FreeTypeFont]:
    faces: dict[str, ImageFont.FreeTypeFont] = {}
    wqy = _font_path("wqy")
    if wqy:
        faces["wqy"] = ImageFont.truetype(str(wqy), size=size, index=0)
    nanum = _font_path("nanum")
    if nanum:
        faces["nanum"] = ImageFont.truetype(str(nanum), size=size)
    dejavu = _font_path("dejavu")
    if dejavu:
        faces["dejavu"] = ImageFont.truetype(str(dejavu), size=size)
    if "wqy" not in faces:
        raise SystemExit("WenQuanYi Micro Hei is required to build Floor 13 CJK")
    return faces


def _pick_face(faces: dict[str, ImageFont.FreeTypeFont], char: str) -> ImageFont.FreeTypeFont:
    if _is_hangul(char) and "nanum" in faces:
        return faces["nanum"]
    if _is_latin_ext(char) and "dejavu" in faces:
        return faces["dejavu"]
    return faces["wqy"]


def glyph_bitmap(font: ImageFont.FreeTypeFont, char: str, size: int):
    east_asian = unicodedata.east_asian_width(char) in {"W", "F"} or _is_hangul(char)
    advance = size if east_asian else max(3, round(font.getlength(char)))
    if char == " ":
        return Image.new("1", (1, 1), 0), 0, 0, advance
    canvas = Image.new("L", (size * 3, size * 4), 0)
    draw = ImageDraw.Draw(canvas)
    baseline = size + 4
    draw.text((size, baseline), char, font=font, fill=255, anchor="ls", stroke_width=0)
    mono = canvas.point(lambda value: 255 if value >= 96 else 0, mode="1")
    bbox = mono.getbbox()
    if bbox is None:
        return None
    if bbox[2] - bbox[0] <= 1 and bbox[3] - bbox[1] <= 1:
        return None
    crop = mono.crop(bbox)
    return crop, bbox[0] - size, bbox[1] - (baseline - size), advance


def main() -> None:
    chars = source_charset()
    faces = _load_faces(SIZE)
    glyphs = []
    skipped = 0
    for char in chars:
        rendered = glyph_bitmap(_pick_face(faces, char), char, SIZE)
        if rendered is None:
            skipped += 1
            continue
        glyphs.append((char, *rendered))
    row_height = SIZE + PADDING * 2 + LINE_PAD
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
    line_height = SIZE + LINE_PAD
    lines = [
        f'info face="Floor13 CJK {SIZE}" size={SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0 outline=0',
        f"common lineHeight={line_height} base={SIZE + 2} scaleW={ATLAS_WIDTH} scaleH={atlas_height} pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        'page id=0 file="floor13_cjk.png"',
        f"chars count={len(positions)}",
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
    print(
        f"Floor13 CJK glyphs={len(positions)} skipped={skipped} "
        f"atlas={ATLAS_WIDTH}x{atlas_height} lineHeight={line_height}"
    )


if __name__ == "__main__":
    main()
