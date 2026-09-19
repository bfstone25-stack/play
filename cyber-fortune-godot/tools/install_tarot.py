#!/usr/bin/env python3
"""Install picked tarot faces: ops/tarot_art/out/faces/<slug>/<stem>.png -> assets/tarot/<slug>.webp.

    python3 tools/install_tarot.py picks.json            # {"the_fool": "the_fool_01", ...}
    python3 tools/install_tarot.py picks.json --dry-run  # say what would happen, write nothing
    python3 tools/install_tarot.py --list                # which of the 78 have candidates yet

The picks file is a JSON object {slug: stem}; a stem is the candidate's filename without
.png (the generator writes <slug>_00, <slug>_01, ...). Picking is by eye and is NOT done
here — this only converts what a picks file names, so it can be run again as the set
fills in. Slugs not in the file are left alone; a slug in the file whose candidate is
missing is reported and skipped.

Size: CardView draws the face in a frame of (inner.w - 16) x (inner.h * 0.58) where inner
is the card grown by -8; the largest card is the deck's 230x380 top card, so the frame is
198x211. The plates are 832x1216 portraits; they are centre-cropped to the frame's aspect
and written at 2x (396x422) so a phone at DPR 2 gets a full-resolution face. The frame
is drawn with `draw_texture_rect(tex, frame)`, which stretches, so the aspect here must
match the frame's, not the plate's.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
FACES = PROJ.parent.parent / "ops" / "tarot_art" / "out" / "faces"
ASSETS = PROJ / "assets" / "tarot"

CARD_W, CARD_H = 230, 380
FRAME_W = CARD_W - 16 - 16           # inner (card - 8 each side) minus 8 each side
FRAME_H = int((CARD_H - 16) * 0.58)  # 211
SCALE = 2
OUT_W, OUT_H = FRAME_W * SCALE, FRAME_H * SCALE   # 396 x 422
QUALITY = 88


def all_slugs() -> list[str]:
    """The generator's slugs (the_fool, ace_of_wands). The game's are hyphenated
    (the-fool, ace-of-wands) and card_view.gd loads assets/tarot/<game slug>.webp, so the
    installed filename is game_slug(); picks may use either spelling."""
    sys.path.insert(0, str(HERE))
    import pool_tarot  # noqa: E402
    return [c["slug"].replace("-", "_") for c in pool_tarot.cards()]


def game_slug(slug: str) -> str:
    return slug.replace("_", "-")


def convert(src: Path, dst: Path) -> None:
    im = Image.open(src).convert("RGB")
    w, h = im.size
    want = OUT_W / OUT_H
    if w / h > want:
        nw = int(h * want)
        x0 = (w - nw) // 2
        im = im.crop((x0, 0, x0 + nw, h))
    else:
        nh = int(w / want)
        # the composition's weight sits a little above centre on these plates; keep the
        # upper part of the frame rather than a dead centre crop
        y0 = max(0, int((h - nh) * 0.42))
        im = im.crop((0, y0, w, y0 + nh))
    im = im.resize((OUT_W, OUT_H), Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, "WEBP", quality=QUALITY, method=6)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("picks", nargs="?", help="JSON {slug: stem}")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    slugs = all_slugs()
    if a.list:
        have = 0
        for s in slugs:
            cands = sorted(p.stem for p in (FACES / s).glob(f"{s}_*.png")) if (FACES / s).exists() else []
            done = (ASSETS / f"{game_slug(s)}.webp").exists()
            have += bool(cands)
            print(f"  {'inst' if done else '    '} {s:22} {', '.join(cands) if cands else '-'}")
        print(f"\n  {have}/{len(slugs)} with candidates, {sum((ASSETS / f'{game_slug(s)}.webp').exists() for s in slugs)} installed")
        return 0
    if not a.picks:
        ap.error("picks JSON required (or --list)")
    picks = json.loads(Path(a.picks).read_text(encoding="utf-8"))
    bad = 0
    n = 0
    for slug, stem in picks.items():
        slug = slug.replace("-", "_")
        if slug not in slugs:
            print(f"  !! unknown slug {slug!r}", file=sys.stderr)
            bad += 1
            continue
        src = FACES / slug / f"{stem}.png"
        if not src.exists():
            print(f"  !! {slug}: candidate {src.name} not rendered yet", file=sys.stderr)
            bad += 1
            continue
        dst = ASSETS / f"{game_slug(slug)}.webp"
        if a.dry_run:
            print(f"  would {src.relative_to(FACES.parent.parent)} -> {dst.relative_to(PROJ)} {OUT_W}x{OUT_H}")
        else:
            convert(src, dst)
            print(f"  {slug:22} <- {stem}  ({dst.stat().st_size // 1024} KB)")
        n += 1
    print(f"\n  {n} face(s) {'checked' if a.dry_run else 'installed'} at {OUT_W}x{OUT_H}, {bad} problem(s)")
    if not a.dry_run and n:
        print("  then: $GODOT --headless --path . --import   (new files need an import pass)")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
