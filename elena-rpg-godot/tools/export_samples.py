#!/usr/bin/env python3
"""Pick the 10 DLsite sample images from shots/latest -> ops/dlsite/elena_rpg_samples/NN_name.jpg
(1280x720 JPEG q92, same family as the 1344x768 samples used for the VN listing).
The two CG samples must carry no nudity: cg_trust3_carrel (lace bra, covered) and cg_rpg_gala."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
SRC = R / "shots/latest"
OUT = Path("/home/frankstone/Products/ops/dlsite/elena_rpg_samples")
PICKS = [  # (sample name, shot file)
    ("01_floor_map", "en_map.png"), ("02_study_search", "en_room_study.png"), ("03_bell_chamber", "en_room_bell_chamber.png"),
    ("04_standoff_porter", "en_battle.png"), ("05_standoff_dean_boss", "en_battle_boss.png"), ("06_level_up", "en_levelup.png"),
    ("07_party_equipment", "en_equip_menu.png"), ("08_gallery", "en_gallery_early.png"),
    ("09_cg_carrel", "en_cg_cg_trust3_carrel.png"), ("10_cg_gala", "en_cg_cg_rpg_gala.png"),
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
