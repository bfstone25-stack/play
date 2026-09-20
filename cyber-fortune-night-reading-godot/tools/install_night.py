#!/usr/bin/env python3
"""Install a rendered plate over its labelled placeholder.

    python3 tools/install_night.py --list
    python3 tools/install_night.py title_kv ops/night_reading_art/out/plates/title_kv/title_kv_02.png
    python3 tools/install_night.py --picks picks.json      # {"slot": "path", ...}

It resizes to the slot's size, writes assets/night/<slot>.png, and removes the slot from
assets/night/placeholders.json — which is the single place the game and the README read to
decide whether a plate is real. Then it tells you to reimport, because a replaced image
renders from the .godot cache with no error at all until you do (memory:
verification-that-lies).
"""
from __future__ import annotations
import argparse, json, pathlib, subprocess, sys
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
PROJ = HERE.parent
ART = PROJ / "assets" / "night"
MARKS = ART / "placeholders.json"
sys.path.insert(0, str(HERE))
from make_placeholders import SLOTS  # noqa: E402


def install(slot: str, src: pathlib.Path) -> None:
    if slot not in SLOTS:
        raise SystemExit("unknown slot %r; known: %s" % (slot, ", ".join(sorted(SLOTS))))
    if not src.exists():
        raise SystemExit("no such file: %s" % src)
    size = SLOTS[slot][0]
    im = Image.open(src).convert("RGB")
    # Cover, then centre-crop: a plate must fill its frame, and letterboxing a render into
    # the slot is how a picture ends up with bars the game then draws a border around.
    sc = max(size[0] / im.width, size[1] / im.height)
    im = im.resize((round(im.width * sc), round(im.height * sc)), Image.LANCZOS)
    left = (im.width - size[0]) // 2
    top = (im.height - size[1]) // 2
    im.crop((left, top, left + size[0], top + size[1])).save(ART / (slot + ".png"))
    marks = set(json.loads(MARKS.read_text())) if MARKS.exists() else set()
    marks.discard(slot)
    MARKS.write_text(json.dumps(sorted(marks), indent=1))
    print("  installed %s  <- %s  (%dx%d)" % (slot, src, size[0], size[1]))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("slot", nargs="?")
    ap.add_argument("src", nargs="?")
    ap.add_argument("--picks", help="JSON {slot: path}")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    marks = set(json.loads(MARKS.read_text())) if MARKS.exists() else set()
    if a.list:
        for slot, (size, tier, what) in sorted(SLOTS.items()):
            print("  %-22s %4dx%-4d tier %d  %s  %s" % (
                slot, size[0], size[1], tier,
                "PLACEHOLDER" if slot in marks else "real       ", what))
        return 0
    if a.picks:
        for slot, src in json.loads(pathlib.Path(a.picks).read_text()).items():
            install(slot, pathlib.Path(src))
    elif a.slot and a.src:
        install(a.slot, pathlib.Path(a.src))
    else:
        ap.error("give a slot and a file, or --picks, or --list")
    print("\nnow: $GODOT --headless --path . --import     (or the old image renders from cache)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
