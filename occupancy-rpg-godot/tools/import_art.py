#!/usr/bin/env python3
"""Install OCCUPANCY's art, audio and voice into assets/ (gitignored, rebuilt by this script).

Sources, all already rendered or committed elsewhere -- this script never renders:
  ops/overtime_art/out/plates/<slot>/<slot>_NN.png   the Overtime plates (CGs, pieces) and the
                                                      RPG slots added 2026-10-03 (rpg_*):
                                                      rooms, the party's two outfits each,
                                                      the standoff people, the board objects
  data/art_picks.json                                 which seed of each rpg_* slot ships
  ops/occupancy_rpg_audio/music/                      ops/vn_music.py occupancy(-rpg)
  assets/voice/*.ogg (committed, from overtime-idle)  Mirei's 21 barks -> assets/voice/v_*.ogg
  assets/title/keyvisual.webp (committed)             the title plate

Figures (party, Mirei, standoff people) are cut out with rembg and healed; the board's staff
tiles are head-and-shoulders crops of the same figures, so the face on the desk is the face in
the party. CGs get a 400x225 thumb and a blurred locked tile.

    python3 tools/import_art.py
"""
import json
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageOps

HERE = Path(__file__).resolve().parent.parent
PRODUCTS = HERE.parent.parent
PLATES = PRODUCTS / "ops/overtime_art/out/plates"
AUDIO = PRODUCTS / "ops/occupancy_rpg_audio/music"
A = HERE / "assets"
PICKS = json.loads((HERE / "data/art_picks.json").read_text())

import importlib.util
_spec = importlib.util.spec_from_file_location("bd", HERE / "tools/build_data.py")
BD = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(BD)

# palette for the UI skin: plum night, warm amber, rose accent (the Overtime studio colours)
INK = (34, 22, 40)
INK2 = (52, 34, 60)
AMBER = (240, 178, 92)
AMBER_HI = (255, 222, 160)
ROSE = (232, 96, 128)
CREAM = (250, 238, 222)


def pick(slot):
    i = PICKS.get(slot, 0)
    p = PLATES / slot / f"{slot}_{i:02d}.png"
    return p if p.exists() else None


def heal_cutout(im):
    import numpy as np
    from scipy import ndimage
    a = np.array(im.convert("RGBA"))
    solid = a[:, :, 3] > 8
    want = ndimage.binary_fill_holes(solid) | ndimage.binary_closing(solid, iterations=6)
    want &= ndimage.binary_dilation(solid, iterations=8)
    new = want & ~solid
    if new.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        a[new, :3] = a[iy[new], ix[new], :3]
        a[new, 3] = 255
    # keep only the largest connected figure (rembg leaves specks on a black ground)
    lab, n = ndimage.label(a[:, :, 3] > 8)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        keep = 1 + int(np.argmax(sizes))
        a[lab != keep, 3] = 0
    return Image.fromarray(a)


def cut(src: Path, dst: Path):
    if dst.exists() and dst.stat().st_mtime > src.stat().st_mtime:
        return Image.open(dst)
    from rembg import remove
    im = remove(Image.open(src).convert("RGB"))
    alpha = im.getchannel("A").point(lambda v: 255 if v > 24 else 0)
    im.putalpha(alpha)
    im = heal_cutout(im)
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst)
    return im


def rounded(w, h, fill, edge, r=14, alpha=236, edge_w=2, glow=None):
    """A soft rounded panel (a UI skin texture, drawn once and nine-sliced by the core)."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, w - 1, h - 1), r, fill=fill + (alpha,), outline=edge + (255,), width=edge_w)
    if glow:
        d.rounded_rectangle((edge_w + 2, edge_w + 2, w - 3 - edge_w, edge_w + 3), 2, fill=glow + (120,))
    return im


def make_ui():
    ui = A / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    rounded(1100, 78, INK2, AMBER, r=16, alpha=230).save(ui / "choice_idle.png")
    rounded(1100, 78, (92, 44, 74), AMBER_HI, r=16, alpha=242, glow=ROSE).save(ui / "choice_hover.png")
    rounded(1400, 900, INK, AMBER, r=22, alpha=232).save(ui / "panel.png")
    rounded(720, 320, INK, AMBER_HI, r=22, alpha=246).save(ui / "modal.png")
    rounded(1240, 220, INK, ROSE, r=22, alpha=226).save(ui / "textbox.png")
    rounded(420, 52, ROSE, AMBER_HI, r=14, alpha=245).save(ui / "namebox.png")
    rounded(400, 320, INK2, AMBER, r=16, alpha=220).save(ui / "slot_idle.png")
    rounded(400, 320, (92, 44, 74), AMBER_HI, r=16, alpha=235).save(ui / "slot_hover.png")
    rounded(220, 18, (24, 16, 28), (90, 70, 96), r=8, alpha=255, edge_w=1).save(ui / "bar_under.png")
    rounded(220, 18, ROSE, (255, 160, 180), r=8, alpha=255, edge_w=1).save(ui / "bar_fill.png")
    rounded(220, 18, AMBER, AMBER_HI, r=8, alpha=255, edge_w=1).save(ui / "bar_fill_gold.png")
    w, h = 1280, 720
    vig = Image.new("L", (w // 8, h // 8), 0)
    ImageDraw.Draw(vig).ellipse((-24, -20, w // 8 + 24, h // 8 + 20), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(14)).resize((w, h), Image.BILINEAR)
    vimg = Image.new("RGBA", (w, h), INK + (0,))
    vimg.putalpha(vig.point(lambda v: int((255 - v) * 0.45)))
    vimg.save(ui / "vignette.png")
    scrim = Image.new("RGBA", (w, h), INK + (0,))
    scrim.putalpha(Image.linear_gradient("L").rotate(90).resize((w, h)).point(lambda v: int(v * 0.8)))
    scrim.save(ui / "scrim.png")
    Image.new("RGBA", (64, 64), (0, 0, 0, 0)).save(ui / "dust.png")
    mp = pick("rpg_floor_map")
    if mp:
        ImageOps.fit(Image.open(mp).convert("RGB"), (1280, 720), Image.LANCZOS).save(ui / "map.png")


def cover(im, size):
    return ImageOps.fit(im.convert("RGB"), size, Image.LANCZOS, centering=(0.5, 0.45))


def main():
    for sub in ("rooms", "rooms_locked", "sprites", "enemies", "cg", "ui", "title", "audio", "board"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    make_ui()
    missing = []
    # rooms
    for r in BD.ROOMS:
        src = pick("rpg_" + r)
        if not src:
            missing.append("rpg_" + r)
            continue
        im = cover(Image.open(src), (1280, 720))
        im.save(A / "rooms" / f"{r}.png")
        lk = im.resize((480, 270)).filter(ImageFilter.GaussianBlur(6))
        ImageEnhance.Brightness(lk).enhance(0.9).save(A / "rooms_locked" / f"{r}.png")
    # party sprites + Mirei, standoff people
    figs = {}
    for s in BD.PARTY_SPRITES:
        slot = "rpg_mirei_suit" if s == "mirei" else "rpg_" + s
        src = pick(slot)
        if not src:
            missing.append(slot)
            continue
        figs[s] = cut(src, A / "sprites" / f"{s}.png")
    for e in BD.ENEMY_SPRITES:
        src = pick("rpg_e_" + e)
        if not src:
            missing.append("rpg_e_" + e)
            continue
        figs["e_" + e] = cut(src, A / "enemies" / f"{e}.png")
    # board tiles: head and shoulders of the same figure
    def bust(im, dst):
        w, h = im.size
        box = (0, 0, w, min(h, int(w * 1.15)))
        b = im.crop(box)
        bg = Image.new("RGBA", b.size, (250, 232, 214, 255))
        bg.alpha_composite(b)
        ImageOps.fit(bg.convert("RGB"), (240, 176), Image.LANCZOS, centering=(0.5, 0.2)).save(dst)
    for who in ("mara", "priya", "nia", "sol"):
        if who + "_work" in figs:
            bust(figs[who + "_work"], A / "board" / f"{who}.png")
    if "e_wes" in figs:
        bust(figs["e_wes"], A / "board" / "wes.png")
    dan = PLATES / "piece_dan" / "piece_dan_00.png"
    if dan.exists():
        bust(cut(dan, A / "board" / "_dan_cut.png"), A / "board" / "dan.png")
    for o in ("coffee", "mute", "printer", "corner"):
        src = pick("rpg_o_" + o)
        if not src:
            missing.append("rpg_o_" + o)
            continue
        ImageOps.fit(Image.open(src).convert("RGB"), (240, 176), Image.LANCZOS).save(A / "board" / f"{o}.png")
    # CGs: full, thumb, locked
    for cid, rel in BD.CG_SOURCES.items():
        src = PLATES / f"{rel}.png"
        if not src.exists():
            missing.append(rel)
            continue
        im = Image.open(src).convert("RGB")
        im.save(A / "cg" / f"{cid}.png")
        th = ImageOps.fit(im, (400, 225), Image.LANCZOS)
        th.save(A / "cg" / f"{cid}_thumb.png")
        lk = th.resize((100, 56)).filter(ImageFilter.GaussianBlur(4)).resize((400, 225), Image.BILINEAR)
        ImageEnhance.Brightness(lk).enhance(0.75).save(A / "cg" / f"{cid}_locked.png")
    # title
    kv = A / "title" / "keyvisual.webp"
    if kv.exists():
        cover(Image.open(kv), (1280, 720)).save(A / "title" / "keyvisual.png")
    mark = A / "title" / "mark.png"
    if mark.exists():
        m = Image.open(mark).convert("RGBA")
        # the Overtime mark says OCCUPANCY / IDLE / FREE TO PLAY: this edition is neither, so
        # only the wordmark row ships (rows 0-278 of the 1440x600 mark)
        m = m.crop((0, 0, m.width, 278))
        m = m.crop(m.getbbox())
        m.thumbnail((620, 300), Image.LANCZOS)
        m.save(A / "title" / "logo.png")
    # audio
    for f in AUDIO.glob("*.ogg"):
        shutil.copy2(f, A / "audio" / f.name)
    # voice: committed barks -> the RPG's voice keys
    ns = {}
    exec((HERE / "tools/strings_voice.py").read_text(), ns)
    for k, clip in ns["CLIP"].items():
        src = A / "voice" / clip
        if src.exists():
            shutil.copy2(src, A / "voice" / f"{k}.ogg")
        else:
            missing.append("voice " + clip)
    print(f"import_art: rooms {len(list((A / 'rooms').glob('*.png')))}, sprites {len(list((A / 'sprites').glob('*.png')))}, "
          f"enemies {len(list((A / 'enemies').glob('*.png')))}, cg {len(BD.CG_SOURCES)}, board {len(list((A / 'board').glob('*.png')))}")
    if missing:
        print("import_art: missing (placeholder until rendered/picked):", ", ".join(missing))


if __name__ == "__main__":
    main()
