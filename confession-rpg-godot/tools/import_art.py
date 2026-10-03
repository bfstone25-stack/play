#!/usr/bin/env python3
"""Copy Confession Room's existing art/audio/fonts into the RPG and cut placeholder room plates.

Placeholders are crops of existing rendered art (never code-drawn): the four VN backgrounds
and figure-free regions of the clothed CGs. Real room plates, standoff sprites and CGs arrive
in ops/confession_art/out/rpg/{rooms,enemies,cgs}/ from the render queue (picked by hand,
installed by ops/confession_art/install_rpg.py); when a file named in data/art_manifest.json
exists there, this script copies it to assets/rpg/ and the game prefers it over the
placeholder (core NRArt.tex()).

The six gated CGs (ops/gated_assets/confession-room/, the paid build's plates: the three
route scenes and the three evidence photographs) become assets/cg/cg_<x>_x.webp; the VN's
blurred stand-ins are their locked tiles. The VN has no character sprites (CG-only), so the
suspects' standoff renders double as their story sprites (art_manifest "sprites").
"""
import json, shutil
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageOps

HERE = Path(__file__).resolve().parent.parent
VN = Path("/home/frankstone/Products/play/confession-room/game")
GATED = Path("/home/frankstone/Products/ops/gated_assets/confession-room")
RPG_OUT = Path("/home/frankstone/Products/ops/confession_art/out/rpg")
RPG_AUDIO = Path("/home/frankstone/Products/ops/confession_rpg_audio")
CJK = Path("/home/frankstone/Products/.elena-wt/elena-suspense/game/fonts/NotoSansCJKjp-Regular.otf")
A = HERE / "assets"

CROPS = {  # room id -> (source image, crop box in the source's pixels, *fx)
    "precinct": ("images/bg/bg_precinct.webp", None),
    "interview": ("images/bg/bg_room.webp", None),
    "club": ("images/bg/bg_club.webp", None),
    "cooler": ("images/bg/bg_locker.webp", None),
    "corridor": ("images/cgs/cg_intake.webp", (0, 0, 1920, 1080)),
    "lockup": ("images/bg/bg_locker.webp", (480, 0, 1440, 540), "mirror"),
    "archive": ("images/bg/bg_precinct.webp", (960, 0, 1920, 540)),
    "morgue": ("images/bg/bg_room.webp", (0, 0, 960, 540), "mirror"),
    "back_office": ("images/bg/bg_precinct.webp", (0, 200, 1280, 920)),
    "alley": ("images/title/keyvisual.webp", (0, 0, 1280, 720)),
    "loading_bay": ("images/bg/bg_club.webp", (640, 0, 1920, 720)),
    "mop_room": ("images/bg/bg_locker.webp", (0, 300, 960, 840)),
    "fire_stairs": ("images/bg/bg_club.webp", (0, 0, 960, 540), "mirror"),
    "flat": ("images/cgs/cg_closing.webp", (0, 0, 1280, 720)),
    "safe_house": ("images/cgs/cg_closing.webp", (640, 300, 1920, 1020), "mirror"),
}
SLOTS = {"corridor": "room_corridor_bench", "lockup": "room_evidence_lockup", "archive": "room_archive", "morgue": "room_morgue",
         "back_office": "room_back_office", "alley": "room_alley", "loading_bay": "room_loading_bay", "mop_room": "room_mop_room",
         "fire_stairs": "room_fire_stairs", "flat": "room_flat", "safe_house": "room_safe_house"}
GATED_CGS = {"nikolai": "cg_nikolai_x", "adaeze": "cg_adaeze_x", "vee": "cg_vee_x",
             "evidence": "cg_evidence_x", "evidence2": "cg_evidence2_x", "evidence3": "cg_evidence3_x"}
NEW_CGS = ("cg_rpg_paloma", "cg_rpg_bay", "cg_rpg_stairs", "cg_trust5_adaeze", "cg_trust7_nikolai", "cg_trust9_vee")


def heal_cutout(src: Path, dst: Path) -> None:
    """rembg leaves frayed mattes: alpha holes inside a figure with black RGB under them.
    Fill enclosed holes and bridge small frays, painting new pixels with the nearest opaque colour."""
    import numpy as np
    from scipy import ndimage
    a = np.array(Image.open(src).convert("RGBA"))
    solid = a[:, :, 3] > 8
    want = ndimage.binary_fill_holes(solid) | ndimage.binary_closing(solid, iterations=6)
    want &= ndimage.binary_dilation(solid, iterations=8)
    new = want & ~solid
    if new.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        a[new, :3] = a[iy[new], ix[new], :3]
        a[new, 3] = 255
    Image.fromarray(a).save(dst)
    if new.sum():
        print(f"  healed {src.name}: {int(new.sum())} px")


def thumb_and_lock(im: Image.Image, stem: str) -> None:
    """Gallery tiles: a 480x270 thumbnail and a blurred, darkened locked tile."""
    t = im.convert("RGB").resize((480, 270), Image.LANCZOS)
    t.save(A / "cg" / f"{stem}_thumb.webp", quality=86)
    lk = ImageEnhance.Brightness(t.filter(ImageFilter.GaussianBlur(14))).enhance(0.45)
    lk.save(A / "cg" / f"{stem}_locked.webp", quality=80)


def main():
    for sub in ("cg", "ui", "title", "fonts", "audio", "placeholder/rooms", "placeholder/rooms_locked", "rpg"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    # clothed story CGs + the VN's locked stand-ins
    for f in (VN / "images/cgs").glob("*.webp"):
        shutil.copy2(f, A / "cg" / f.name)
    for stem in ("cg_intake", "cg_board", "cg_closing"):
        thumb_and_lock(Image.open(A / "cg" / f"{stem}.webp"), stem)
    # the gated set (paid build): full plates + thumbnails; the VN's blurred tile stays the locked one
    for src, stem in GATED_CGS.items():
        p = GATED / f"{src}.webp"
        if not p.exists():
            print("!! missing gated plate", p)
            continue
        shutil.copy2(p, A / "cg" / f"{stem}.webp")
        im = Image.open(p)
        im.convert("RGB").resize((480, 270), Image.LANCZOS).save(A / "cg" / f"{stem}_thumb.webp", quality=86)
    for d in ("ui", "title"):
        for f in (VN / "images" / d).glob("*.*"):
            shutil.copy2(f, A / d / f.name)
    for f in (VN / "fonts").glob("*"):
        shutil.copy2(f, A / "fonts" / f.name)
    if CJK.exists():
        shutil.copy2(CJK, A / "fonts" / CJK.name)
    for f in (VN / "audio").glob("*.ogg"):
        shutil.copy2(f, A / "audio" / f.name)
    for f in (RPG_AUDIO / "music").glob("*.ogg") if (RPG_AUDIO / "music").exists() else []:
        shutil.copy2(f, A / "audio" / f.name)
    # placeholder plates
    for room, (src, box, *fx) in CROPS.items():
        im = Image.open(VN / src).convert("RGB")
        if box:
            im = im.crop(box)
        if "mirror" in fx:
            im = ImageOps.mirror(im)
        im.resize((1600, 900), Image.LANCZOS).save(A / "placeholder/rooms" / f"{room}.webp", quality=90)
    # rendered RPG art
    n = 0
    if RPG_OUT.exists():
        for f in RPG_OUT.rglob("*.png"):
            dst = A / "rpg" / f.relative_to(RPG_OUT)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if f.parent.name == "enemies":
                heal_cutout(f, dst)
            else:
                shutil.copy2(f, dst)
            n += 1
    for slot in NEW_CGS:
        p = A / "rpg/cgs" / f"{slot}.png"
        if p.exists():
            thumb_and_lock(Image.open(p), slot)
    # the map's not-yet-visited tiles: blurred, darkened copies of each plate (real one if it has arrived)
    for room in CROPS:
        real = A / "rpg/rooms" / f"{SLOTS.get(room, '-')}.png"
        im = Image.open(real if real.exists() else A / "placeholder/rooms" / f"{room}.webp").convert("RGB")
        im = im.resize((480, 270)).filter(ImageFilter.GaussianBlur(6))
        ImageEnhance.Brightness(im).enhance(0.9).save(A / "placeholder/rooms_locked" / f"{room}.webp", quality=85)
    print(f"copied art; {len(CROPS)} placeholder plates; {n} rendered RPG files from {RPG_OUT}")


if __name__ == "__main__":
    main()
