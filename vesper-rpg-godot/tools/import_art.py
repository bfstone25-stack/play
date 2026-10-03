#!/usr/bin/env python3
"""Copy VESPER's existing art/audio into the RPG and cut placeholder room plates.

Sources (nothing here is drawn by code):
  * the 18 event CGs: the picked renders in ops/flutter_art/out/plates/<slot>/ (picks.json,
    1152x768, larger than the web build's 1024x576 webp), unless a re-render was installed
    into ops/flutter_art/out/rpg/cgs/<slot>.png (the third colour pass, install_rpg.py);
    the web build's covered tiles (<slot>_locked.webp) are the gallery's locked tiles.
  * the six men: the fork's picked portraits (por_<who>_x_{master,blush,smile},
    picks_portraits.json) cut out with rembg -> sprites/<who>_{neutral,blush,smile}.png.
    neutral/blush are his date-standoff sprites (blush = his guard going), smile is the
    figure on the stage at the venue.
  * title key visual + logotype (frontend/title), music (frontend/audio/bgm, mp3), ambience,
    the fork's 21 voiced barks (frontend/voice/*.ogg).
  * UI frames and fonts: Room 704's VN set (play/room-704/game), recoloured to VESPER's plum
    and rose here (a hue shift of rendered images, not drawn shapes).
  * RPG renders (rooms / enemies / outfits) from ops/flutter_art/out/rpg/ once picked and
    installed by ops/flutter_art/install_rpg.py; until then, placeholder plates are crops of
    the fork's own rendered art (openings, key visual, blurred CGs).
"""
import colorsys
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

HERE = Path(__file__).resolve().parent.parent
FORK = HERE.parent / "flutter-after-hours/frontend"
ART = Path("/home/frankstone/Products/ops/flutter_art")
VN704 = HERE.parent / "room-704/game"
RPG_OUT = ART / "out/rpg"
A = HERE / "assets"
ROUTES = ["guyan", "ethan", "luxingye", "liam", "adrian", "fushen"]
CGS = [f"cg_{r}_{k}" for r in ROUTES for k in ("ch2", "heat", "end")]
SHARED_ROOMS = ["v_home", "v_street", "v_cafe"]
VENUES = [f"v_{r}_{c}" for r in ROUTES for c in range(1, 6)]


def heal_cutout(src, dst: Path) -> None:
    """rembg leaves frayed mattes; fill enclosed holes with the nearest opaque colour."""
    from scipy import ndimage
    a = np.array((src if isinstance(src, Image.Image) else Image.open(src)).convert("RGBA"))
    solid = a[:, :, 3] > 8
    want = ndimage.binary_fill_holes(solid) | ndimage.binary_closing(solid, iterations=6)
    want &= ndimage.binary_dilation(solid, iterations=8)
    new = want & ~solid
    if new.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        a[new, :3] = a[iy[new], ix[new], :3]
        a[new, 3] = 255
    Image.fromarray(a).save(dst)


_SESSION = []


# per-sprite crops (fractions of the source) where a lamp or a desk touches the figure and
# the matte cannot tell them apart
SRC_CROP = {"luxingye_neutral": (0.25, 0.0, 1.0, 1.0), "liam_neutral": (0.06, 0.0, 0.96, 0.9)}


def cut(src: Path, dst: Path) -> None:
    """isnet-anime (u2net left furniture fragments and dropped a torso); keep the largest
    connected figure only, so a lamp or door frame the matte caught cannot ride along."""
    from rembg import new_session, remove
    from scipy import ndimage
    if not _SESSION:
        _SESSION.append(new_session("isnet-anime"))
    im = Image.open(src).convert("RGB")
    if dst.stem in SRC_CROP:
        l, t, r, b = SRC_CROP[dst.stem]
        im = im.crop((int(l * im.width), int(t * im.height), int(r * im.width), int(b * im.height)))
    im = remove(im, session=_SESSION[0])
    a = np.array(im)
    solid = a[:, :, 3] > 24
    lab, n = ndimage.label(solid)
    if n > 1:
        sizes = ndimage.sum(solid, lab, range(1, n + 1))
        solid = lab == (1 + int(np.argmax(sizes)))
    a[:, :, 3] = np.where(solid, 255, 0).astype(np.uint8)
    heal_cutout(Image.fromarray(a), dst)


def thumb(src: Path, dst: Path) -> None:
    im = Image.open(src).convert("RGB")
    im.thumbnail((400, 267), Image.LANCZOS)
    im.save(dst, quality=85)


def recolour(src: Path, dst: Path) -> None:
    """Room 704's navy/brass UI -> VESPER's plum/rose: rotate hue, keep value and alpha."""
    im = Image.open(src).convert("RGBA")
    a = np.asarray(im).astype(np.float32) / 255.0
    rgb = a[:, :, :3]
    import matplotlib.colors as mc
    hsv = mc.rgb_to_hsv(rgb)
    hsv[:, :, 0] = (hsv[:, :, 0] + 0.30) % 1.0       # navy (0.62) -> plum (0.92); brass (0.11) -> rose-gold (0.41?)
    gold = (np.abs(a[:, :, 0] - a[:, :, 2]) > 0.08) & (a[:, :, 0] > a[:, :, 2])
    hsv[:, :, 0] = np.where(gold, 0.97, hsv[:, :, 0])  # brass trim -> rose
    hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 1.15, 0, 1)
    out = np.dstack([mc.hsv_to_rgb(hsv), a[:, :, 3:]])
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(dst)


def main():
    for sub in ("cg", "sprites", "ui", "title", "fonts", "audio", "voice", "placeholder/rooms", "placeholder/rooms_locked"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    picks = json.loads((ART / "picks.json").read_text())
    rpg_cg = RPG_OUT / "cgs"
    for slot in CGS:
        src = rpg_cg / f"{slot}.png"
        if not src.exists():
            src = ART / "out/plates" / slot / f"{picks[slot]}.png"
        Image.open(src).convert("RGB").save(A / "cg" / f"{slot}.webp", quality=92)
        thumb(src, A / "cg" / f"{slot}_thumb.webp")
        locked = FORK / "cg" / f"{slot}_locked.webp"
        shutil.copy2(locked, A / "cg" / f"{slot}_locked.webp")
    # the six men: cut once (rembg is slow); re-cut by deleting the file
    pp = json.loads((ART / "picks_portraits.json").read_text())
    for r in ROUTES:
        for src_k, dst_k in (("master", "neutral"), ("blush", "blush"), ("smile", "smile")):
            dst = A / "sprites" / f"{r}_{dst_k}.png"
            if not dst.exists():
                k = f"por_{r}_x_{src_k}"
                cut(ART / "out/portraits" / k / f"{pp[k]}.png", dst)
                print("  cut", dst.name)
    shutil.copy2(FORK / "title/keyvisual.webp", A / "title/keyvisual.webp")
    shutil.copy2(FORK / "title/logotype.webp", A / "title/logo.webp")
    for f in ("afterhours-theme", "afterhours-resolution", "en-main", "en-tension", "en-intimate", "en-melancholy", "en-conversation"):
        shutil.copy2(FORK / "audio/bgm" / f"{f}.mp3", A / "audio" / f"{f}.mp3")
    shutil.copy2(FORK / "audio/ambience/en-room.mp3", A / "audio/room_ambience.mp3")
    for f in ("ui_click.ogg", "page_flip.ogg", "heartbeat.ogg", "title_sting.ogg"):
        shutil.copy2(VN704 / "audio" / f, A / "audio" / f)
    for f in (FORK / "voice").glob("*.ogg"):
        shutil.copy2(f, A / "voice" / f.name)
    for f in VN704.joinpath("fonts").glob("*"):
        if f.is_file():
            shutil.copy2(f, A / "fonts" / f.name)
    for f in VN704.joinpath("images/ui").glob("*.png"):
        if f.stem in ("btn_cash", "btn_register", "studio", "rating"):
            continue
        recolour(f, A / "ui" / f.name)
    # title scrim/vignette/rain from Room 704's title set (rendered overlays, neutral)
    for f in ("vignette.png", "scrim.png", "light.png"):
        shutil.copy2(VN704 / "images/title" / f, A / "title" / f)
    # dust: the key visual's own glow, blurred to motes would be code; reuse Room 704's rain
    shutil.copy2(VN704 / "images/title/rain.png", A / "title/rain.png")
    # placeholders: the fork's own renders, cropped / blurred
    ph = {"v_home": FORK / "openings/en-dawn-v1.webp", "v_street": FORK / "openings/zh-late-night-v1.webp",
          "v_cafe": FORK / "openings/ja-rain-train-v1.webp"}
    for r in ROUTES:
        for c in range(1, 6):
            ph[f"v_{r}_{c}"] = A / "cg" / f"cg_{r}_{['ch2', 'ch2', 'heat', 'end', 'end'][c - 1]}.webp"
    for rid, src in ph.items():
        im = Image.open(src).convert("RGB")
        w, h = im.size
        tw = int(h * 16 / 9)
        if tw <= w:
            im = im.crop(((w - tw) // 2, 0, (w - tw) // 2 + tw, h))
        im = im.resize((1600, 900), Image.LANCZOS)
        if rid not in SHARED_ROOMS:
            im = ImageOps.mirror(im).filter(ImageFilter.GaussianBlur(10))
        im.save(A / "placeholder/rooms" / f"{rid}.webp", quality=88)
    n = 0
    if RPG_OUT.exists():
        for f in RPG_OUT.rglob("*.png"):
            if f.parent.name == "cgs":
                continue
            dst = A / "rpg" / f.relative_to(RPG_OUT)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if f.parent.name == "enemies":
                heal_cutout(f, dst)
            else:
                shutil.copy2(f, dst)
            n += 1
    for rid in SHARED_ROOMS + VENUES:
        real = A / "rpg/rooms" / f"{rid}.png"
        im = Image.open(real if real.exists() else A / "placeholder/rooms" / f"{rid}.webp").convert("RGB")
        im = im.resize((480, 270)).filter(ImageFilter.GaussianBlur(6))
        ImageEnhance.Brightness(im).enhance(1.1).save(A / "placeholder/rooms_locked" / f"{rid}.webp", quality=85)
    print(f"import_art: {len(CGS)} CGs, {len(ROUTES) * 3} sprites, {len(ph)} placeholder plates, {n} rendered RPG assets")


if __name__ == "__main__":
    main()
