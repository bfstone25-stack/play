#!/usr/bin/env python3
"""Everything under assets/ (gitignored; rebuilt from sources by this script).

Rooms and figures are PIXEL art, the base game's form: renders from
ops/midnight_pawn_art/midnight_pawn_gen.py (steps rooms / sprites) converted onto the base
game's fixed palette by ops/midnight_pawn_art/build_pixel_assets.py's own functions -- rooms
at the stage's 640x360 then doubled with nearest-neighbour to the 1280x720 window (integer
scale, so nothing resamples a pixel), figures at 144x216 then doubled. The readings (CGs)
stay painted: a reading is a vision, and TWO_WORLDS.md lets a vision look unlike the room.

Which render becomes which asset is ops/midnight_pawn_art/rpg_picks.json (picked by eye
from the contact sheets) plus pixel_picks.json for the four rooms and five figures the
Godot fork already had. The fork's own shipped files are used where they exist: its three
pixel rooms, its four real plates and its key visual.

The UI frames are pixel frames in the same palette, made here (like ops/keyvisual_art/
logotype.py makes every other title's frames): a 2-pixel brass rule with stepped corners
over the palette's ink, then doubled.

    python3 tools/import_art.py
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

HERE = Path(__file__).resolve().parent.parent
PRODUCTS = HERE.parent.parent
FORK = HERE.parent / "midnight-pawn-collateral-godot"
ART = PRODUCTS / "ops/midnight_pawn_art"
sys.path.insert(0, str(ART))
sys.path.insert(0, str(PRODUCTS / "ops"))
import build_pixel_assets as bpa  # noqa: E402

A = HERE / "assets"
AUDIO = PRODUCTS / "ops/lien_rpg_audio/music"
CJK = PRODUCTS / "play/room-704/game/fonts/NotoSansCJKjp-Regular.otf"
PIXFONT = PRODUCTS / "ops/fonts/PixelifySans-Medium.ttf"
PAL = bpa.palette()
INK, INK2, BRASS, BRASS_HI, BRASS_LO, PAPER = PAL[1], PAL[3], PAL[29], PAL[30], PAL[27], PAL[15]

FORK_ROOMS = {"shop": "scene_shop.png", "market": "scene_crypt_2_ossuary_market.png", "dawn": "scene_result_dawn.png"}
NEW_ROOMS = ("stockroom", "street", "cellar", "receipt_stair", "toll_gate", "bone_arcade", "reliquary", "lantern_row",
             "archive", "counting_house", "heart_vault", "mirror_hall")
CAST = ("nara", "tamsin", "ivo", "mara", "calder")
ENEMIES = ("echo", "toll_keeper", "stair_clerk", "bone_haggler", "hollow_broker", "moth_widow", "bailiff", "archivist", "auditor")
FORK_CGS = {"cg_tamsin": "plates/cg_tamsin.png", "cg_finial": "plates_x/cg_finial.png",
            "cg_market": "plates_x/cg_market.png", "cg_collateral": "plates_x/cg_collateral.png"}
NEW_CGS = ("cg_ring", "cg_veil", "cg_descent", "cg_market_crowd", "cg_calder", "cg_tamsin_bath", "cg_maya",
           "cg_mara_letters", "cg_moth", "cg_heart", "cg_factor", "cg_solvent")
FIG = (144, 216)


def big(im, k=2):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def frame(w, h, fill=INK, edge=BRASS, hi=BRASS_HI, alpha=232, notch=2):
    """A pixel frame at 1x: stepped corners, a 1px highlight inside a 1px rule."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((notch, 0, w - 1 - notch, h - 1), fill=fill + (alpha,))
    d.rectangle((0, notch, w - 1, h - 1 - notch), fill=fill + (alpha,))
    for x0, y0, x1, y1 in ((notch, 0, w - 1 - notch, 0), (notch, h - 1, w - 1 - notch, h - 1),
                           (0, notch, 0, h - 1 - notch), (w - 1, notch, w - 1, h - 1 - notch)):
        d.line((x0, y0, x1, y1), fill=edge + (255,))
    for cx, cy, sx, sy in ((notch, notch, -1, -1), (w - 1 - notch, notch, 1, -1), (notch, h - 1 - notch, -1, 1), (w - 1 - notch, h - 1 - notch, 1, 1)):
        d.point((cx + sx, cy), fill=edge + (255,))
        d.point((cx, cy + sy), fill=edge + (255,))
    if hi:
        d.line((notch + 1, 1, w - 2 - notch, 1), fill=hi + (200,))
    return im


def make_ui():
    ui = A / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    big(frame(550, 39)).save(ui / "choice_idle.png")
    big(frame(550, 39, fill=PAL[33], edge=BRASS_HI, hi=PAPER, alpha=240)).save(ui / "choice_hover.png")
    big(frame(700, 450, alpha=236)).save(ui / "panel.png")
    big(frame(360, 160, alpha=246, edge=BRASS_HI)).save(ui / "modal.png")
    big(frame(620, 110, alpha=228)).save(ui / "textbox.png")
    big(frame(210, 26, fill=BRASS_LO, edge=BRASS_HI, hi=None, alpha=245)).save(ui / "namebox.png")
    big(frame(200, 160, alpha=220)).save(ui / "slot_idle.png")
    big(frame(200, 160, fill=PAL[33], edge=BRASS_HI, alpha=235)).save(ui / "slot_hover.png")
    big(frame(110, 9, fill=INK2, edge=BRASS_LO, hi=None, alpha=255, notch=1)).save(ui / "bar_under.png")
    big(frame(110, 9, fill=PAL[35], edge=PAL[34], hi=PAL[36], alpha=255, notch=1)).save(ui / "bar_fill.png")
    big(frame(110, 9, fill=BRASS, edge=BRASS_LO, hi=BRASS_HI, alpha=255, notch=1)).save(ui / "bar_fill_gold.png")
    # vignette + scrim: soft gradients (a light, not a shape)
    w, h = 1280, 720
    vig = Image.new("L", (w // 8, h // 8), 0)
    dv = ImageDraw.Draw(vig)
    dv.ellipse((-20, -16, w // 8 + 20, h // 8 + 16), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(14)).resize((w, h), Image.BILINEAR)
    vimg = Image.new("RGBA", (w, h), INK + (0,))
    vimg.putalpha(vig.point(lambda v: int((255 - v) * 0.75)))
    vimg.save(ui / "vignette.png")
    scrim = Image.new("RGBA", (w, h), INK + (0,))
    scrim.putalpha(Image.linear_gradient("L").rotate(90).resize((w, h)).point(lambda v: int(v * 0.85)))
    scrim.save(ui / "scrim.png")
    rain = PRODUCTS / "play/room704-rpg-godot/assets/title/rain.png"
    if rain.exists():
        shutil.copy2(rain, ui / "dust.png")
    else:
        Image.new("RGBA", (64, 64), (0, 0, 0, 0)).save(ui / "dust.png")


def room_src(name):
    if name in FORK_ROOMS:
        return Image.open(FORK / "assets/pixel" / FORK_ROOMS[name]).convert("RGB")
    pk = json.loads((ART / "rpg_picks.json").read_text()) if (ART / "rpg_picks.json").exists() else {}
    chosen = pk.get("rooms", {}).get(name)
    if not chosen:
        return None
    anchor = float(pk.get("anchors", {}).get(name, 0.5))
    return bpa.build_room(ART / "out/rooms" / name / chosen, 640, 360, anchor)


def figure(who):
    pk = json.loads((ART / "rpg_picks.json").read_text()) if (ART / "rpg_picks.json").exists() else {}
    chosen = pk.get("sprites", {}).get(who) or json.loads((ART / "pixel_picks.json").read_text())["sprites"].get(who)
    if not chosen:
        return None
    return big(bpa.build_sprite(ART / "out/sprites" / who / chosen, FIG))


def cg_out(im, cid):
    im = im.convert("RGB")
    im.save(A / "cg" / f"{cid}.png")
    t = im.resize((480, round(480 * im.height / im.width)), Image.LANCZOS)
    t.save(A / "cg" / f"{cid}_thumb.png")
    ImageEnhance.Brightness(t.filter(ImageFilter.GaussianBlur(14))).enhance(0.45).save(A / "cg" / f"{cid}_locked.png")


def main():
    for sub in ("rooms", "rooms_locked", "sprites", "enemies", "cg", "ui", "title", "fonts", "audio", "voice"):
        (A / sub).mkdir(parents=True, exist_ok=True)
    make_ui()
    missing = []
    for name in tuple(FORK_ROOMS) + NEW_ROOMS:
        im = room_src(name)
        if im is None:
            missing.append("room " + name)
            continue
        big(im).save(A / "rooms" / f"{name}.png")
        lk = ImageEnhance.Brightness(im.filter(ImageFilter.GaussianBlur(3))).enhance(0.7)
        big(lk.resize((240, 135), Image.BOX), 2).save(A / "rooms_locked" / f"{name}.png")
    # the ledger map: the archive plate, dimmed, under the room tiles
    arch = A / "rooms/archive.png"
    if arch.exists():
        ImageEnhance.Brightness(Image.open(arch)).enhance(0.45).save(A / "ui/map.png")
    for who in CAST + ENEMIES:
        try:
            im = figure(who)
        except Exception as exc:   # a render that does not cut cleanly is reported, not shipped
            print("!!", who, exc)
            im = None
        if im is None:
            missing.append("figure " + who)
            continue
        im.save(A / "enemies" / f"{who}.png")
        if who in CAST:
            im.save(A / "sprites" / f"{who}.png")
    for cid, rel in FORK_CGS.items():
        cg_out(Image.open(FORK / "assets" / rel), cid)
    pk = json.loads((ART / "rpg_picks.json").read_text()) if (ART / "rpg_picks.json").exists() else {}
    for cid in NEW_CGS:
        chosen = pk.get("plates", {}).get(cid)
        if not chosen:
            missing.append("cg " + cid)
            continue
        cg_out(Image.open(ART / "out/plates" / cid / chosen), cid)
    # title: the fork's key visual and logotype
    shutil.copy2(FORK / "assets/title/keyvisual.png", A / "title/keyvisual.png")
    shutil.copy2(FORK / "assets/title/logotype.png", A / "title/logo.png")
    # Pixelify Sans with its ligatures switched off: Godot shapes "fi" through the font's
    # liga lookup and this face's fi glyph reads as a capital A at game sizes ("The Anial's
    # hour", seen in the first battle screenshot). Emptying the liga/dlig features fixes it
    # in the file, for every label, without touching the shared core's font loading.
    from fontTools.ttLib import TTFont
    ft = TTFont(PIXFONT)
    for fr in ft["GSUB"].table.FeatureList.FeatureRecord:
        if fr.FeatureTag in ("liga", "dlig"):
            fr.Feature.LookupListIndex = []
            fr.Feature.LookupCount = 0
    ft.save(A / "fonts/display.ttf")
    ft.save(A / "fonts/body.ttf")
    shutil.copy2(PRODUCTS / "ops/fonts/PixelifySans-OFL.txt", A / "fonts/PixelifySans-OFL.txt")
    shutil.copy2(CJK, A / "fonts" / CJK.name)
    for f in AUDIO.glob("*.ogg"):
        shutil.copy2(f, A / "audio" / f.name)
    # Nara's voiced lines: the fork's rendered barks, renamed to the RPG string keys
    vm = HERE / "tools/strings_voice.py"
    if vm.exists():
        ns = {}
        exec(vm.read_text(), ns)
        for key, src in ns["CLIP"].items():
            shutil.copy2(FORK / "assets/voice" / src, A / "voice" / f"{key}.ogg")
    print(f"assets built; missing: {', '.join(missing) if missing else 'none'}")


if __name__ == "__main__":
    main()
