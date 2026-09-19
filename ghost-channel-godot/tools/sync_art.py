#!/usr/bin/env python3
"""Copy the picked plates out of ops/ghost_art into assets/art/.

The renders are big and they are generated, so they live under ops/ and are not committed
twice; this is the one place that decides which candidate is the shipping one. Run by
build.sh before every export, and safe to run when nothing has rendered yet — a missing
plate is a plate the client draws around (scripts/station.gd, scripts/portrait.gd).

    python3 tools/sync_art.py            # picked/ if it exists, else the best candidate
    python3 tools/sync_art.py --list     # what is available and what would be taken
"""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
ART = HERE / "assets/art"
SRC = HERE.parent.parent / "ops/ghost_art"
SLOTS = ["keyvisual", "title_far", "title_mid", "title_fore", "console_bed",
         "voice_viper", "voice_moth", "voice_hex", "voice_raven", "voice_quill"]


def source_for(slot: str) -> Path | None:
    picked = SRC / "picked" / f"{slot}.png"
    if picked.is_file():
        return picked
    # no pick made yet: take the first candidate, so a build during a render pass still
    # shows the art rather than the placeholder slots
    cands = sorted((SRC / "out/plates" / slot).glob("*.png"))
    return cands[0] if cands else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    ART.mkdir(parents=True, exist_ok=True)
    have, missing = [], []
    for slot in SLOTS:
        src = source_for(slot)
        if src is None:
            missing.append(slot)
            continue
        have.append(f"{slot} <- {src.relative_to(SRC.parent.parent)}")
        if not a.list:
            shutil.copy2(src, ART / f"{slot}.png")
    for line in have:
        print("  " + line)
    if missing:
        print("  missing (the client draws around these): " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
