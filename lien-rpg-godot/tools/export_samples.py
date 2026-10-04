#!/usr/bin/env python3
"""Pick the 10 DLsite sample images from shots/latest -> ops/dlsite/confession_rpg_samples/NN_name.jpg
(1280x720 JPEG q92). No nudity on any sample: the gallery is left out (the sim has every case-1 route open by then); the two CG samples are the club facade and the
clothed intake CG."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
SRC = R / "shots/latest"
OUT = Path("/home/frankstone/Products/ops/dlsite/confession_rpg_samples")
PICKS = [  # (sample name, shot file)
    ("01_board_map", "en_map.png"), ("02_desk", "en_room_precinct.png"), ("03_club_floor", "en_room_club.png"),
    ("04_standoff_nikolai", "en_battle.png"), ("05_standoff_boss", "en_battle_boss.png"), ("06_level_up", "en_levelup.png"),
    ("07_equipment", "en_equip_menu.png"), ("08_status", "en_party_menu.png"),
    ("09_cg_paloma", "en_cg_cg_rpg_paloma.png"), ("10_cg_intake", "en_cg_cg_intake.png"),
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
