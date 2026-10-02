#!/usr/bin/env python3
"""Copy Elena's existing art/audio/fonts into the RPG and cut placeholder room plates.

Placeholders are crops of existing rendered art (never code-drawn): the two VN
backgrounds plus figure-free regions of CGs. Real room plates, enemy sprites and outfits
arrive in ops/elena_art/out/rpg/{rooms,enemies,outfits}/ from the render queue; when a
file named in data/art_manifest.json exists there, this script copies it to assets/rpg/
and the game prefers it over the placeholder (see core Art.tex()).
"""
import shutil
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent.parent
VN = Path("/home/frankstone/Products/.elena-wt/elena-suspense/game")
RPG_OUT = Path("/home/frankstone/Products/ops/elena_art/out/rpg")
A = HERE / "assets"

CROPS = {  # room id -> (source image, crop box in 1920x1080)
    "study":    ("images/bg/study_normal.webp", None),
    "vault":    ("images/bg/study_dark.webp", None),
    "corridor": ("images/cgs/cg_ch3_crypt.webp", (1300, 0, 1920, 349)),
    "stair":    ("images/cgs/cg_ch5_muniment.webp", (1250, 0, 1920, 377)),
    "stacks":   ("images/title/keyvisual.webp", (0, 0, 640, 360)),
    "cellar":   ("images/cgs/cg_coal_store.webp", (0, 100, 600, 437)),
    "muniment": ("images/cgs/cg_muniment.webp", (0, 80, 720, 485)),
    "dock": ("images/bg/study_dark.webp", (900, 0, 1700, 450)),
    "reading_room": ("images/title/keyvisual.webp", (0, 0, 640, 360)),
    "common_room": ("images/bg/study_normal.webp", (0, 0, 1100, 619)),
    "deans_corridor": ("images/cgs/cg_annex.webp", (0, 0, 560, 315)),
    "annex": ("images/bg/study_dark.webp", (0, 200, 900, 706)),
    "deans_office": ("images/bg/study_normal.webp", (700, 300, 1920, 986), "mirror"),
    "carrel": ("images/cgs/cg_aftermath.webp", (1300, 0, 1920, 349)),
}

def main():
    for sub in ("cg", "sprites", "ui", "title", "fonts", "audio", "placeholder/rooms", "rpg"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    for f in (VN / "images/cgs").glob("*.webp"):
        shutil.copy2(f, A / "cg" / f.name)
    for f in (VN / "images/characters").glob("*.webp"):
        shutil.copy2(f, A / "sprites" / f.name)
    for d in ("ui", "title"):
        for f in (VN / "images" / d).glob("*.*"):
            shutil.copy2(f, A / d / f.name)
    for f in (VN / "fonts").glob("*"):
        shutil.copy2(f, A / "fonts" / f.name)
    for f in (VN / "audio").glob("*.ogg"):
        shutil.copy2(f, A / "audio" / f.name)
    from PIL import ImageOps
    for room, (src, box, *fx) in CROPS.items():
        im = Image.open(VN / src).convert("RGB")
        if box: im = im.crop(box)
        if "mirror" in fx: im = ImageOps.mirror(im)
        im.resize((1600, 900), Image.LANCZOS).save(A / "placeholder/rooms" / f"{room}.webp", quality=90)
    n = 0
    if RPG_OUT.exists():
        for f in RPG_OUT.rglob("*.png"):
            dst = A / "rpg" / f.relative_to(RPG_OUT)
            dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(f, dst); n += 1
    # blurred, darkened copy of each room for the map's not-yet-visited tiles; made from the
    # real plate when it has arrived, else from the placeholder
    from PIL import ImageFilter, ImageEnhance
    slots = {"vault": "room_sealed_vault", "corridor": "room_porters_lodge", "stair": "room_crypt_stair",
             "stacks": "room_stacks", "cellar": "room_coal_store", "dock": "room_records_basement",
             "muniment": "room_muniment_room", "reading_room": "room_reading_room",
             "common_room": "room_faculty_common_room", "deans_corridor": "room_deans_corridor",
             "annex": "room_chapel_annex", "deans_office": "room_deans_office", "carrel": "room_elena_carrel"}
    (A / "placeholder/rooms_locked").mkdir(parents=True, exist_ok=True)
    for room in CROPS:
        real = A / "rpg/rooms" / f"{slots.get(room, '-')}.png"
        im = Image.open(real if real.exists() else A / "placeholder/rooms" / f"{room}.webp").convert("RGB")
        im = im.resize((480, 270)).filter(ImageFilter.GaussianBlur(6))
        ImageEnhance.Brightness(im).enhance(1.1).save(A / "placeholder/rooms_locked" / f"{room}.webp", quality=85)
    print(f"copied art; {len(CROPS)} placeholder plates; {n} new RPG plates from {RPG_OUT}")

if __name__ == "__main__":
    main()
