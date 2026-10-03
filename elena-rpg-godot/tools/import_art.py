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

HEAVY_HEAL = {"enemy_deans_man_a_pressured.png": (0.55, 0.42, 1.0, 1.0, 28)}
# black-background remnants rembg kept as foreground: (x0, y0, x1, y1) box in px; an
# opaque near-black component whose bounding box lies wholly inside is deleted
BLOB_REMOVE = {"outfit_gown.png": [(455, 610, 610, 910)]}


def heal_cutout(src: Path, dst: Path) -> None:
    """rembg leaves frayed mattes: alpha holes inside a figure with black RGB under them
    (enemy_deans_man_a_pressured, right coat edge). Fill enclosed holes and bridge small
    frays, painting the new pixels with the nearest opaque colour."""
    import numpy as np
    from scipy import ndimage
    a = np.array(Image.open(src).convert("RGBA"))
    solid = a[:, :, 3] > 8
    want = ndimage.binary_fill_holes(solid) | ndimage.binary_closing(solid, iterations=6)
    want &= ndimage.binary_dilation(solid, iterations=8)   # never grow a new outline far from the figure
    # per-file heavy repair where the matte is shredded over a wide band (right coat edge)
    for name, (x0, y0, x1, y1, it) in HEAVY_HEAL.items():
        if src.name == name:
            h, w = solid.shape
            box = np.zeros_like(solid); box[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)] = True
            # convex hull of the figure inside the band: a hanging coat edge is convex there
            from scipy.spatial import ConvexHull
            from matplotlib.path import Path as MPath
            ys, xs = np.where(solid & box)
            if len(xs) > 10:
                hull = ConvexHull(np.c_[xs, ys])
                yy, xx = np.mgrid[0:h, 0:w]
                inside = MPath(np.c_[xs, ys][hull.vertices]).contains_points(np.c_[xx.ravel(), yy.ravel()]).reshape(h, w)
                want |= inside & box
    new = want & ~solid
    if new.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        a[new, :3] = a[iy[new], ix[new], :3]
        a[new, 3] = 255
    removed = 0
    for (x0, y0, x1, y1) in BLOB_REMOVE.get(src.name, []):
        dark = (a[:, :, :3].max(axis=2) < 16) & (a[:, :, 3] > 100)
        lab, nlab = ndimage.label(dark)
        for sl_i, sl in enumerate(ndimage.find_objects(lab), 1):
            if sl is None:
                continue
            if sl[0].start >= y0 and sl[0].stop <= y1 and sl[1].start >= x0 and sl[1].stop <= x1:
                comp = lab == sl_i
                if comp.sum() > 60:
                    a[comp, 3] = 0
                    removed += int(comp.sum())
    Image.fromarray(a).save(dst)
    if removed:
        print(f"  removed {removed} px of matte remnant from {src.name}")
    print(f"  healed {src.name}: {int(new.sum())} px")


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
            dst.parent.mkdir(parents=True, exist_ok=True)
            if f.parent.name in ("enemies", "outfits"):
                heal_cutout(f, dst)
            else:
                shutil.copy2(f, dst)
            n += 1
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
