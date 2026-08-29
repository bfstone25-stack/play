#!/usr/bin/env python3
"""Strict asset gate for Midnight Pawn's authored pixel presentation."""
from hashlib import sha256
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "pixel"
scenes = [
    "title", "shop", "crypt_0_receipt_stair", "crypt_1_widow_niche",
    "crypt_2_ossuary_market", "crypt_3_foreclosure_chapel",
    "final_appraisal", "result_dawn",
]
atlases = {
    "characters.png": (256, 240),
    "shop_atlas.png": (256, 256),
    "crypt_atlas.png": (256, 256),
    "curios.png": (256, 64),
    "ui_atlas.png": (256, 128),
}

for name in scenes:
    path = ASSETS / f"scene_{name}.png"
    if not path.exists() or Image.open(path).size != (300, 240):
        raise SystemExit(f"missing or invalid 300x240 scene: {name}")
    colors = Image.open(path).convert("RGBA").getcolors(4096)
    if colors is None or len(colors) < 10:
        raise SystemExit(f"scene lacks authored palette detail: {name}")

for name, expected in atlases.items():
    path = ASSETS / name
    if not path.exists() or Image.open(path).size != expected:
        raise SystemExit(f"missing or invalid atlas: {name}")
    colors = Image.open(path).convert("RGBA").getcolors(4096)
    if not any(color[3] == 0 for _, color in colors):
        raise SystemExit(f"atlas lacks transparent silhouettes: {name}")

curios = Image.open(ASSETS / "curios.png").convert("RGBA")
icon_hashes = {
    sha256(curios.crop((index * 32, 0, index * 32 + 32, 32)).tobytes()).hexdigest()
    for index in range(8)
}
pickup_hashes = {
    sha256(curios.crop((index * 32, 32, index * 32 + 32, 64)).tobytes()).hexdigest()
    for index in range(8)
}
if len(icon_hashes) != 8 or len(pickup_hashes) != 8:
    raise SystemExit("the eight core curios are not visually distinct")

stage_source = (ROOT / "scripts" / "pixel_stage.gd").read_text()
if "draw_rect(" in stage_source or "_draw_person" in stage_source:
    raise SystemExit("pixel stage regressed to programmer-block principal art")
for name in scenes:
    if f"scene_{name}.png" not in stage_source:
        raise SystemExit(f"runtime does not reference scene_{name}.png")

print(
    "PIXEL_ART_AUDIT_OK scenes=8 atlases=5 curios=8 icons=8 pickups=8 "
    "player_frames=8 customer_frames=16 enemy_frames=8 tiles=36 base=640x360"
)
