#!/usr/bin/env python3
"""Pick the 10 DLsite sample images from shots/latest -> ops/dlsite/lien_samples/NN_name.jpg
(1280x720 JPEG q92). No nudity on any sample: three counter/market screens lead (RPG x 経営/鑑定), then rooms,
standoffs, growth and two clothed CGs (the descent, the Market crowd)."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
SRC = R / "shots/latest"
OUT = Path("/home/frankstone/Products/ops/dlsite/lien_samples")
PICKS = [  # (sample name, shot file) -- RPG x management first, then the RPG; no nudity anywhere
    ("01_counter_appraise", "en_counter_h1.png"), ("02_counter_ledger", "en_counter_h3.png"),
    ("03_market_stalls", "en_counter_h4.png"), ("04_shop", "en_room_shop.png"),
    ("05_receipt_stair", "en_room_receipt_stair.png"), ("06_standoff", "en_battle.png"),
    ("07_standoff_boss", "en_battle_boss.png"), ("08_level_up", "en_levelup.png"),
    ("09_cg_descent", "en_cg_cg_descent.png"), ("10_cg_market", "en_cg_cg_market_crowd.png"),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    missing = [f for _, f in PICKS if not (SRC / f).exists()]
    if missing:
        sys.exit("missing shots: " + ", ".join(missing))
    for name, f in PICKS:
        im = Image.open(SRC / f).convert("RGB")
        assert im.size == (1280, 720), (f, im.size)
        im.save(OUT / f"{name}.jpg", quality=92)
        print("wrote", OUT / f"{name}.jpg")


if __name__ == "__main__":
    main()
