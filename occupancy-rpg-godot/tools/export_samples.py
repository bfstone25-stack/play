#!/usr/bin/env python3
"""Pick the 10 DLsite sample images from shots/latest -> ops/dlsite/occupancy_samples/NN_name.jpg
(1280x720 JPEG q92). No nudity on any sample: art first (Mirei's lease, clothed), then the office
(RPG x 経営 x ガチャ: the board, the recruit pull, supplies/dress-up), then play (standoffs, the
party's outfits, a floor) and the clothed ending art."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
SRC = R / "shots/latest"
OUT = Path("/home/frankstone/Products/ops/dlsite/occupancy_samples")
PICKS = [  # (sample name, shot file)
    ("01_cg_mirei_lease", "en_cgview_cg_mirei_lease.png"), ("02_office_board", "en_office_built_n4.png"),
    ("03_recruit", "en_recruit10_n1.png"), ("04_standoff_party", "en_battle.png"),
    ("05_rent_crisis_boss", "en_battle_boss.png"), ("06_dress_up", "en_equip_menu.png"),
    ("07_office_n2", "en_office_built_n2.png"), ("08_floor_lobby", "en_room_lobby.png"),
    ("09_level_up", "en_levelup.png"), ("10_cg_full_occupancy", "en_cgview_cg_keys.png"),
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
