#!/usr/bin/env python3
"""Pick the 10 DLsite sample images from shots/latest -> ops/dlsite/room704_rpg_samples/NN_name.jpg
(1280x720 JPEG q92). 3 map/exploration, 3 battle, 2 growth, 2 CG; the CG samples carry no nudity."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
SRC = R / "shots/latest"
OUT = Path("/home/frankstone/Products/ops/dlsite/room704_rpg_samples")
PICKS = [
    ("01_floor_map", "en_map.png"), ("02_lobby_search", "en_room_lobby.png"), ("03_roof", "en_room_roof.png"),
    ("04_standoff_guest212", "en_battle.png"), ("05_standoff_gale_boss", "en_battle_boss.png"), ("06_level_up", "en_levelup.png"),
    ("07_party_equipment", "en_equip_menu.png"), ("08_gallery", "en_gallery_early.png"),
    ("09_cg_doors", "en_cg_cg_rpg_doors.png"), ("10_cg_roof_city", "en_cg_cg_rpg_roof_city.png"),
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
