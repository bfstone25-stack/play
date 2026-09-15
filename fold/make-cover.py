#!/usr/bin/env python3
"""Looping Fold cover GIF — grid snap, not a static still. No generative models."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
W, H = 630, 500
BG = (11, 14, 13)
PANEL = (20, 24, 22)
GOLD = (199, 164, 90)
PAPER = (232, 226, 211)
INK = (36, 26, 6)
TILES = [(60, 70, 87), (74, 90, 122), (91, 123, 186), (201, 138, 62)]


def lerp(a, b, t):
    return a + (b - a) * t


def ease(t):
    if t < 0:
        return 0
    if t > 1:
        return 1
    return t * t * (3 - 2 * t)


def frame(t: float) -> Image.Image:
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    # shelf card
    d.rounded_rectangle((40, 36, W - 40, H - 70), 28, fill=PANEL, outline=(42, 48, 44), width=2)
    # 2x2 board
    board = (165, 78, 465, 378)
    d.rounded_rectangle(board, 22, fill=(16, 19, 17), outline=(42, 48, 44), width=2)
    cx, cy = 315, 228
    cell, gap = 96, 18
    origins = [
        (cx - gap / 2 - cell, cy - gap / 2 - cell),
        (cx + gap / 2, cy - gap / 2 - cell),
        (cx - gap / 2 - cell, cy + gap / 2),
        (cx + gap / 2, cy + gap / 2),
    ]
    # t: 0-0.35 sit, 0.35-0.55 slide, 0.55-0.78 pop merged, 0.78-1 reset
    if t < 0.35:
        k = 0
        show_merge = False
        merge_s = 0
    elif t < 0.55:
        k = ease((t - 0.35) / 0.20)
        show_merge = k > 0.92
        merge_s = max(0, (k - 0.92) / 0.08)
    elif t < 0.82:
        k = 1
        show_merge = True
        merge_s = ease((t - 0.55) / 0.12)
    else:
        k = 1 - ease((t - 0.82) / 0.18)
        show_merge = k > 0.15
        merge_s = k

    if not show_merge or merge_s < 0.85:
        for i, (x0, y0) in enumerate(origins):
            x = lerp(x0, cx - cell / 2, k)
            y = lerp(y0, cy - cell / 2, k)
            alpha_scale = 1 - min(1, k * 1.05)
            if alpha_scale < 0.08:
                continue
            s = cell * (0.55 + 0.45 * alpha_scale)
            x = x + (cell - s) / 2
            y = y + (cell - s) / 2
            d.rounded_rectangle((x, y, x + s, y + s), 14, fill=TILES[i])
            d.text((x + s / 2, y + s / 2), "2", fill=PAPER if i < 3 else INK, anchor="mm")

    if show_merge:
        s = 88 + 36 * (1.15 if merge_s < 0.35 else 1)
        if merge_s < 0.35:
            s = 70 + 70 * ease(merge_s / 0.35)
        else:
            s = 140 - 20 * ease((merge_s - 0.35) / 0.65)
        x, y = cx - s / 2, cy - s / 2
        d.rounded_rectangle((x, y, x + s, y + s), 18, fill=GOLD)
        d.text((cx, cy), "8", fill=INK, anchor="mm")

    d.text((W / 2, H - 42), "FOLD  ·  snap perfectly", fill=GOLD, anchor="mm")
    d.text((W / 2, 58), "Fold the grid. Solve the shape.", fill=PAPER, anchor="mm")
    return im


def main() -> None:
    frames = [frame(i / 36) for i in range(36)]
    # try a slightly larger title font via default
    dest = OUT / "cover.gif"
    frames[0].save(
        dest,
        save_all=True,
        append_images=frames[1:],
        duration=70,
        loop=0,
        optimize=True,
        disposal=2,
    )
    # itch also likes a still
    frames[20].save(OUT / "cover.png")
    print("wrote", dest, dest.stat().st_size)


if __name__ == "__main__":
    main()
