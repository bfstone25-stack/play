#!/usr/bin/env python3
"""Install the reader's three states: ops/fortune_art/out/plates/<state>/<stem>.png
-> assets/reader/reader_<state>.webp, sized for the Teller's slot and with the edges
faded to transparent so the plate's rectangle vanishes into the drawn room.

    python3 tools/install_reader.py '{"calm": "reader_calm_01", "reveal": "reader_reveal_00", "giveback": "reader_giveback_02"}'
    python3 tools/install_reader.py picks.json --top 0.0 --width 0.86

Picking is by eye (a contact sheet per state); this only converts. The plates are
896x1152 portraits of her at her table; the Teller draws the sprite as a 448x520 portrait
standing on the drawn table ellipse, so the crop keeps the plate from --top (fraction of
height) down to --bottom (default 0.9: her table's top edge), and the alpha fades out
across the last stretch of that so her tabletop dissolves into the drawn cloth and her
hands land on it. --width is the fraction of the plate's width kept (centre).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
PLATES = PROJ.parent.parent / "ops" / "fortune_art" / "out" / "plates"
ASSETS = PROJ / "assets" / "reader"
STATES = ("calm", "reveal", "giveback")
OUT_W, OUT_H = 448, 520


def fade_mask(w: int, h: int, side: float = 0.16, top: float = 0.12, bottom: float = 0.14) -> Image.Image:
    """Alpha: opaque in the middle, easing to 0 at every edge; the bottom band is where her
    tabletop is, and it fades so the drawn cloth shows through under her hands."""
    m = Image.new("L", (w, h), 255)
    px = m.load()
    sw, th, bh = max(1, int(w * side)), max(1, int(h * top)), max(1, int(h * bottom))
    for x in range(w):
        fx = min(1.0, x / sw, (w - 1 - x) / sw)
        for y in range(h):
            fy = min(1.0, y / th, (h - 1 - y) / bh)
            a = min(fx, fy)
            a = a * a * (3 - 2 * a)      # smoothstep
            px[x, y] = int(255 * a)
    return m.filter(ImageFilter.GaussianBlur(6))


def convert(src: Path, dst: Path, top: float, width: float, bottom: float) -> None:
    im = Image.open(src).convert("RGB")
    w, h = im.size
    y0, y1 = int(h * top), int(h * bottom)
    ch = y1 - y0
    cw = min(int(w * width), int(ch * OUT_W / OUT_H))
    x0 = (w - cw) // 2
    im = im.crop((x0, y0, x0 + cw, y1)).resize((OUT_W, OUT_H), Image.LANCZOS)
    rgba = im.convert("RGBA")
    rgba.putalpha(fade_mask(OUT_W, OUT_H))
    dst.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(dst, "WEBP", quality=90, method=6)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("picks", help="JSON text or a path: {state: stem}")
    ap.add_argument("--top", type=float, default=0.0)
    ap.add_argument("--width", type=float, default=1.0)
    ap.add_argument("--bottom", type=float, default=0.9)
    a = ap.parse_args()
    picks = json.loads(Path(a.picks).read_text() if Path(a.picks).exists() else a.picks)
    bad = 0
    for state, stem in picks.items():
        if state not in STATES:
            print(f"  !! unknown state {state!r}; states: {', '.join(STATES)}", file=sys.stderr)
            bad += 1
            continue
        src = PLATES / f"reader_{state}" / f"{stem}.png"
        if not src.exists():
            print(f"  !! {state}: {src} missing", file=sys.stderr)
            bad += 1
            continue
        dst = ASSETS / f"reader_{state}.webp"
        convert(src, dst, a.top, a.width, a.bottom)
        print(f"  {state:9} <- {stem}  ({dst.stat().st_size // 1024} KB)")
    print("  then: $GODOT --headless --path . --import")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
