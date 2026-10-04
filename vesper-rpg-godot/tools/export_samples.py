#!/usr/bin/env python3
"""The 10 DLsite samples -> ops/dlsite/vesper_samples/NN_name.jpg (1280x720 JPEG q92), led by the
dating-sim side (route select, date planner), then map/venue, standoffs, growth, 2 clothed CGs.
No nudity on any sample. Also the main image (560x420) and thumbnail (300x300) from the title
key visual + logotype."""
import sys
from pathlib import Path
from PIL import Image
R = Path(__file__).resolve().parent.parent
S = R / "shots"
OUT = Path("/home/frankstone/Products/ops/dlsite/vesper_samples")
PICKS = [
    ("01_route_select", "extras/en_route_select.png"), ("02_date_planner", "extras/en_planner_guyan.png"),
    ("03_venue_with_him", "allart/en_venue_luxingye_3.png"), ("04_city_map", "latest/en_map.png"),
    ("05_standoff_stranger", "latest/en_battle_guyan_c1.png"), ("06_date_standoff_last_wall", "latest/en_battle_ethan_c5.png"),
    ("07_level_up", "latest/en_levelup.png"), ("08_equipment", "latest/en_equip_menu.png"),
    ("09_cg_fushen", "allart/en_cgall_cg_fushen_ch2.png"), ("10_cg_guyan", "allart/en_cgall_cg_guyan_ch2.png"),
]
def main():
    OUT.mkdir(parents=True, exist_ok=True)
    miss = [f for _, f in PICKS if not (S / f).exists()]
    if miss:
        sys.exit("missing shots: " + ", ".join(miss))
    lines = []
    for name, f in PICKS:
        im = Image.open(S / f).convert("RGB")
        assert im.size == (1280, 720), (f, im.size)
        im.save(OUT / f"{name}.jpg", quality=92)
        lines.append(f"{name}.jpg <- play/vesper-rpg-godot/shots/{f}")
    kv = Image.open(R / "assets/title/keyvisual.webp").convert("RGBA")
    logo = Image.open(R / "assets/title/logo.webp").convert("RGBA")
    w, h = kv.size
    crop = kv.crop(((w - int(h * 4 / 3)) // 2, 0, (w - int(h * 4 / 3)) // 2 + int(h * 4 / 3), h)).resize((560, 420), Image.LANCZOS)
    lg = logo.copy(); lg.thumbnail((300, 120))
    crop.alpha_composite(lg, (20, 420 - lg.height - 14))
    crop.convert("RGB").save(OUT.parent / "vesper_main_560x420.jpg", quality=92)
    sq = kv.crop(((w - h) // 2, 0, (w - h) // 2 + h, h)).resize((300, 300), Image.LANCZOS)
    lg2 = logo.copy(); lg2.thumbnail((200, 80)); sq.alpha_composite(lg2, (12, 300 - lg2.height - 8))
    sq.convert("RGB").save(OUT.parent / "vesper_thumb_300.jpg", quality=92)
    lines += ["../vesper_main_560x420.jpg <- title key visual + logotype", "../vesper_thumb_300.jpg <- title key visual + logotype"]
    (OUT / "index.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
if __name__ == "__main__":
    main()
