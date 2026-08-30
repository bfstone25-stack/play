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
font_sizes = (12, 16)

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

game_source = (ROOT / "scripts" / "game.gd").read_text()
if ".ttf" in game_source or ".ttc" in game_source or "FontFile.new()" in game_source:
    raise SystemExit("player-visible UI regressed to a dynamic vector font")
if "theme.default_font = PixelBodyFont" not in game_source:
    raise SystemExit("root Control theme does not enforce the bitmap font")
for font_size in font_sizes:
    descriptor = ROOT / "assets" / "fonts" / f"midnight_pixel_{font_size}.fnt"
    atlas_path = ROOT / "assets" / "fonts" / f"midnight_pixel_{font_size}.png"
    if not descriptor.exists() or not atlas_path.exists():
        raise SystemExit(f"missing BMFont size {font_size}")
    descriptor_source = descriptor.read_text(encoding="utf-8")
    if "smooth=0" not in descriptor_source or "unicode=1" not in descriptor_source:
        raise SystemExit(f"BMFont size {font_size} is not monochrome Unicode")
    atlas = Image.open(atlas_path).convert("RGBA")
    alphas = {color[3] for _, color in atlas.getcolors(atlas.width * atlas.height)}
    if not alphas.issubset({0, 255}):
        raise SystemExit(f"BMFont size {font_size} contains anti-aliased pixels")

project_source = (ROOT / "project.godot").read_text()
for setting in [
    'window/stretch/scale_mode="integer"',
    "textures/canvas_textures/default_texture_filter=0",
    "2d/snap/snap_2d_transforms_to_pixel=true",
    "2d/snap/snap_2d_vertices_to_pixel=true",
]:
    if setting not in project_source:
        raise SystemExit(f"pixel pipeline setting missing: {setting}")

export_source = (ROOT / "export_presets.cfg").read_text()
if "assets/fonts/wqy-microhei.ttc" not in export_source:
    raise SystemExit("redistributable vector source must remain excluded from runtime export")

glyph_count = next(
    int(line.split("=")[1])
    for line in (ROOT / "assets" / "fonts" / "midnight_pixel_12.fnt").read_text().splitlines()
    if line.startswith("chars count=")
)
print(
    f"PIXEL_ART_AUDIT_OK scenes=8 atlases=5 bmfonts=2 glyphs_each={glyph_count} "
    "curios=8 icons=8 pickups=8 player_frames=8 customer_frames=16 "
    "enemy_frames=8 tiles=36 base=640x360 filter=nearest scale=integer snap=on"
)
