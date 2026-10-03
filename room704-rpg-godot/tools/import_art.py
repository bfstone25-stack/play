#!/usr/bin/env python3
"""Copy Room 704's existing art/audio/fonts into the RPG and cut placeholder room plates.

Placeholders are crops of existing rendered art (never code-drawn): the three VN
backgrounds, the key visual and figure-free regions of CGs. Real room plates, enemy sprites,
outfits and CGs arrive in ops/room704_art/out/rpg/{rooms,enemies,outfits,cgs}/ from the
render queue (picked by hand, installed by ops/room704_art/install_rpg.py); when a file named
in data/art_manifest.json exists there, this script copies it to assets/rpg/ and the game
prefers it over the placeholder (see core Art.tex()).

The VN has no character sprites (it is CG-only), so Mira's three bust renders from
ops/room704_art/out/sprites/ are cut out with rembg here and become the story sprites.
The two gated love-scene CGs (ops/gated_assets/room704/, the sensual versions with no
genitals) become cg_bed / cg_window with thumbnails; the VN's blurred stand-ins are their
locked tiles.
"""
import shutil
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageOps

HERE = Path(__file__).resolve().parent.parent
VN = Path("/home/frankstone/Products/play/room-704/game")
ART = Path("/home/frankstone/Products/ops/room704_art")
GATED = Path("/home/frankstone/Products/ops/gated_assets/room704")
RPG_OUT = ART / "out/rpg"
A = HERE / "assets"

CROPS = {  # room id -> (source image, crop box in the source's pixels, *fx)
    "lobby": ("images/bg/bg_lobby.webp", None),
    "corridor4": ("images/bg/bg_corridor.webp", None),
    "room704": ("images/bg/bg_room.webp", None),
    "back_office": ("images/bg/bg_lobby.webp", (960, 0, 1920, 540)),
    "bar": ("images/bg/bg_lobby.webp", (0, 0, 960, 540), "mirror"),
    "kitchen": ("images/bg/bg_corridor.webp", (480, 0, 1440, 540)),
    "service_stair": ("images/bg/bg_corridor.webp", (0, 200, 960, 740), "mirror"),
    "lift": ("images/bg/bg_lobby.webp", (480, 100, 1440, 640)),
    "corridor_2": ("images/bg/bg_corridor.webp", None, "mirror"),
    "room_212": ("images/bg/bg_room.webp", (0, 0, 1280, 720)),
    "room_702": ("images/bg/bg_room.webp", None, "mirror"),
    "linen": ("images/bg/bg_room.webp", (960, 0, 1920, 540)),
    "roof": ("images/title/keyvisual.webp", (0, 0, 1280, 720)),
    "manager_flat": ("images/bg/bg_room.webp", (0, 300, 1280, 1020)),
    "boiler": ("images/bg/bg_corridor.webp", (960, 300, 1920, 840)),
    "laundry": ("images/bg/bg_room.webp", (480, 200, 1440, 740), "mirror"),
    "loading_bay": ("images/bg/bg_corridor.webp", (0, 0, 1280, 720)),
    "street": ("images/title/keyvisual.webp", None),
}
SLOTS = {"corridor4": "room_corridor4", "back_office": "room_back_office", "bar": "room_bar", "kitchen": "room_kitchen", "service_stair": "room_service_stair",
         "lift": "room_lift", "corridor_2": "room_corridor_2", "room_212": "room_212", "room_702": "room_702", "linen": "room_linen",
         "roof": "room_roof", "manager_flat": "room_manager_flat", "boiler": "room_boiler", "laundry": "room_laundry",
         "loading_bay": "room_loading_bay", "street": "room_street"}


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


def cut(src: Path, dst: Path) -> None:
    from rembg import remove
    im = remove(Image.open(src).convert("RGB"))
    alpha = im.getchannel("A").point(lambda v: 255 if v > 24 else 0)
    im.putalpha(alpha)
    im.save(dst)


def thumb(src: Path, dst: Path) -> None:
    im = Image.open(src).convert("RGB")
    im.thumbnail((400, 225), Image.LANCZOS)
    im.save(dst, quality=85)


def main():
    for sub in ("cg", "sprites", "ui", "title", "fonts", "audio", "placeholder/rooms", "placeholder/rooms_locked", "rpg/cgs"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    for f in (VN / "images/cgs").glob("*.webp"):
        shutil.copy2(f, A / "cg" / f.name)
    # the gated love scenes: full, thumb, and the VN's blurred stand-in as the locked tile
    for scene in ("bed", "window"):
        src = GATED / f"{scene}.webp"
        if not src.exists():
            print("!! missing gated CG", src)
            continue
        shutil.copy2(src, A / "cg" / f"cg_{scene}.webp")
        thumb(src, A / "cg" / f"cg_{scene}_thumb.webp")
        locked = VN / "images/cgs" / f"cg_{scene}_x_locked.webp"
        if locked.exists():
            shutil.copy2(locked, A / "cg" / f"cg_{scene}_locked.webp")
    # one generic locked tile for the new CGs: the lobby, blurred past recognition
    im = Image.open(VN / "images/bg/bg_lobby.webp").convert("RGB").resize((400, 225)).filter(ImageFilter.GaussianBlur(14))
    ImageEnhance.Brightness(im).enhance(0.5).save(A / "cg" / "cg_generic_locked.webp", quality=80)
    for d in ("ui", "title"):
        for f in (VN / "images" / d).glob("*.*"):
            shutil.copy2(f, A / d / f.name)
    for f in (VN / "fonts").glob("*"):
        if f.is_file():
            shutil.copy2(f, A / "fonts" / f.name)
    for f in (VN / "audio").glob("*.ogg"):
        shutil.copy2(f, A / "audio" / f.name)
    # Mira's bust sprites: the VN never drew them; cut them out once
    for f in sorted((ART / "out/sprites").glob("mira_*.png")):
        dst = A / "sprites" / f.name
        if not dst.exists():
            cut(f, dst)
            print("  cut", dst.name)
    for rid, (src, box, *fx) in CROPS.items():
        im = Image.open(VN / src).convert("RGB")
        if box:
            im = im.crop(box)
        if "mirror" in fx:
            im = ImageOps.mirror(im)
        im.resize((1600, 900), Image.LANCZOS).save(A / "placeholder/rooms" / f"{rid}.webp", quality=90)
    # the VN's own lobby and room 704 plates are final art, not placeholders
    (A / "vn/rooms").mkdir(parents=True, exist_ok=True)
    for rid, src in (("lobby", "bg_lobby"), ("room704", "bg_room")):
        Image.open(VN / f"images/bg/{src}.webp").convert("RGB").save(A / "vn/rooms" / f"{rid}.webp", quality=92)
    n = 0
    if RPG_OUT.exists():
        for f in RPG_OUT.rglob("*.png"):
            dst = A / "rpg" / f.relative_to(RPG_OUT)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if f.parent.name in ("enemies", "outfits"):
                heal_cutout(f, dst)
            else:
                shutil.copy2(f, dst)
            if f.parent.name == "cgs" and not f.stem.endswith("_thumb"):
                thumb(f, dst.with_name(f.stem + "_thumb.png"))
            n += 1
    # blurred, darkened copy of each room for the map's not-yet-visited tiles
    for rid in CROPS:
        real = A / "rpg/rooms" / f"{SLOTS.get(rid, '-')}.png"
        im = Image.open(real if real.exists() else A / "placeholder/rooms" / f"{rid}.webp").convert("RGB")
        im = im.resize((480, 270)).filter(ImageFilter.GaussianBlur(6))
        ImageEnhance.Brightness(im).enhance(1.1).save(A / "placeholder/rooms_locked" / f"{rid}.webp", quality=85)
    print(f"copied art; {len(CROPS)} placeholder plates; {n} rendered RPG assets from {RPG_OUT}")


if __name__ == "__main__":
    main()
