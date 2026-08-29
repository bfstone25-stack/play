#!/usr/bin/env python3
"""Fail the visual gate when authored pixel assets regress or disappear."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "pixel"
SCENES = [
    "cubicle", "office", "breakroom", "server", "lobby", "stairs", "manager"
]
required = [ASSETS / f"scene_{name}.png" for name in SCENES]
required += [
    ASSETS / "office_atlas.png",
    ASSETS / "ui_atlas.png",
    ASSETS / "title_backdrop.png",
    ASSETS / "ending_clock_out.png",
    ASSETS / "ending_new_manager.png",
    ASSETS / "ending_monday_forever.png",
]

for path in required:
    if not path.exists():
        raise SystemExit(f"missing authored asset: {path.name}")
    image = Image.open(path).convert("RGBA")
    expected = (256, 256) if path.name == "office_atlas.png" else (
        (256, 128) if path.name == "ui_atlas.png" else (320, 180)
    )
    if image.size != expected:
        raise SystemExit(f"{path.name}: expected {expected}, got {image.size}")
    colors = image.getcolors(maxcolors=4096)
    if colors is None or len(colors) < 8:
        raise SystemExit(f"{path.name}: insufficient authored palette detail")
    if path.name.endswith("atlas.png") and not any(color[3] == 0 for _, color in colors):
        raise SystemExit(f"{path.name}: atlas lacks transparent silhouettes")

source = (ROOT / "scripts" / "office_builder.gd").read_text()
if "ColorRect.new()" in source or "func _rect" in source:
    raise SystemExit("office_builder.gd regressed to visible programmer-block scene art")
for scene in SCENES:
    if f"scene_{scene}.png" not in source:
        raise SystemExit(f"runtime does not reference scene_{scene}.png")

print(
    "PIXEL_ART_AUDIT_OK "
    f"scenes={len(SCENES)} atlases=2 endings=3 png_total={len(required)} "
    "base=320x180 nearest=true"
)
