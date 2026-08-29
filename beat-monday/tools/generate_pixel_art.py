#!/usr/bin/env python3
"""Generate the original, deterministic Floor 13 pixel-art production assets.

The artwork is authored at 320x180. Every primitive lands on the pixel grid and
uses location-specific hand-picked ramps; there is no random/noise decoration.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "pixel"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 320, 180

INK = "#080a10"
NIGHT = ["#070a12", "#0d1320", "#151f2e", "#243247", "#3e5066", "#718197"]
STEEL = ["#111721", "#202a35", "#34414d", "#52616b", "#89969a", "#c1c4b8"]
WOOD = ["#1c1313", "#35201b", "#573426", "#7a5035", "#aa7950", "#d0a86e"]
CYAN = ["#07161b", "#0c2930", "#155064", "#258ba0", "#58d5d6", "#b4ffff"]
RED = ["#1b080d", "#3a0c16", "#701322", "#b42135", "#ed3b4f", "#ff9a8c"]
SPECTRAL = ["#07101d", "#0b213b", "#153d68", "#2d6da0", "#62b8d5", "#b4eff0"]
SKIN = ["#3a2527", "#68423a", "#9a6951", "#c99972", "#e8bd8e"]


def px(draw, box, fill, outline=None):
    draw.rectangle(box, fill=fill, outline=outline)


def line(draw, points, fill, width=1):
    draw.line(points, fill=fill, width=width)


def checker(draw, y0, a, b, tile=8):
    for y in range(y0, H, tile):
        for x in range(0, W, tile):
            px(draw, (x, y, x + tile - 1, y + tile - 1), a if (x // tile + y // tile) % 2 else b)
    for y in range(y0, H, tile * 2):
        line(draw, [(0, y), (W, y)], "#0a0d14")


def fluorescent(draw, x, y, w, cold=False):
    glow = SPECTRAL[4] if cold else "#d8d2a7"
    px(draw, (x - 3, y - 1, x + w + 3, y + 5), NIGHT[2])
    px(draw, (x, y, x + w, y + 2), glow)
    px(draw, (x + 3, y + 3, x + w - 3, y + 3), SPECTRAL[2] if cold else "#716c57")
    for xx in range(x + 2, x + w, 7):
        px(draw, (xx, y + 5, xx + 3, y + 5), NIGHT[3])


def window(draw, box, rainy=True, spectral=False):
    x, y, x2, y2 = box
    px(draw, box, "#050812", NIGHT[4])
    mid = (x + x2) // 2
    line(draw, [(mid, y), (mid, y2)], NIGHT[4], 2)
    line(draw, [(x, (y + y2) // 2), (x2, (y + y2) // 2)], NIGHT[3])
    if rainy:
        drops = [(7, 4, 8), (19, 10, 5), (31, 3, 10), (45, 14, 7), (58, 6, 12), (72, 17, 6)]
        for dx, dy, ln in drops:
            xx = x + 3 + dx % max(4, x2 - x - 7)
            yy = y + 2 + dy % max(4, y2 - y - ln - 2)
            line(draw, [(xx, yy), (xx - 2, yy + ln)], SPECTRAL[4] if spectral else "#315a87")
    px(draw, (x + 3, y2 - 7, x + 5, y2 - 4), "#a98254")
    px(draw, (x + 11, y2 - 11, x + 12, y2 - 8), "#a98254")


def crt(draw, x, y, on=True, red=False, scale=1):
    def b(x1, y1, x2, y2, c):
        px(draw, (x + x1 * scale, y + y1 * scale, x + x2 * scale, y + y2 * scale), c)
    b(1, 0, 28, 19, STEEL[0]); b(0, 2, 29, 17, STEEL[2]); b(3, 3, 26, 15, "#06100f" if on else "#090b0e")
    b(5, 5, 24, 13, RED[1] if red else CYAN[0])
    if on:
        col = RED[4] if red else CYAN[4]
        for i, ww in enumerate((16, 11, 18, 8)):
            b(6, 6 + i * 2, 6 + ww, 6 + i * 2, col)
    b(12, 18, 18, 22, STEEL[2]); b(8, 22, 23, 24, STEEL[1])
    b(26, 17, 27, 18, RED[4] if red else CYAN[4])


def desk(draw, x, y, w=74, clutter=True):
    px(draw, (x, y, x + w, y + 5), WOOD[4], INK)
    px(draw, (x + 2, y + 1, x + w - 2, y + 2), WOOD[5])
    px(draw, (x + 4, y + 6, x + 9, y + 31), WOOD[2], INK)
    px(draw, (x + w - 10, y + 6, x + w - 5, y + 31), WOOD[2], INK)
    px(draw, (x + 10, y + 6, x + w - 11, y + 9), WOOD[1])
    if clutter:
        px(draw, (x + w - 24, y - 4, x + w - 15, y - 1), "#d4c8a0", INK)
        line(draw, [(x + w - 23, y - 3), (x + w - 16, y - 3)], "#725c4c")


def chair(draw, x, y, facing=False):
    px(draw, (x + 4, y, x + 17, y + 15), STEEL[1], INK)
    px(draw, (x + 6, y + 2, x + 15, y + 12), STEEL[3] if facing else STEEL[2])
    px(draw, (x + 2, y + 14, x + 19, y + 18), STEEL[1], INK)
    line(draw, [(x + 10, y + 18), (x + 10, y + 27)], STEEL[3], 2)
    line(draw, [(x + 4, y + 27), (x + 17, y + 27)], STEEL[2])
    px(draw, (x + 2, y + 27, x + 4, y + 29), INK); px(draw, (x + 17, y + 27, x + 19, y + 29), INK)


def phone(draw, x, y, cursed=False):
    base = RED[2] if cursed else STEEL[1]
    px(draw, (x + 2, y + 5, x + 25, y + 15), base, INK)
    px(draw, (x, y + 2, x + 27, y + 7), STEEL[3] if not cursed else RED[4], INK)
    px(draw, (x + 4, y, x + 9, y + 3), STEEL[2]); px(draw, (x + 18, y, x + 23, y + 3), STEEL[2])
    for yy in range(9, 14, 3):
        for xx in range(7, 20, 4):
            px(draw, (x + xx, y + yy, x + xx + 1, y + yy + 1), STEEL[4])


def papers(draw, x, y, w=28, blood=False):
    px(draw, (x, y, x + w, y + 18), "#d7cbaa", INK)
    for yy in range(y + 4, y + 15, 3):
        line(draw, [(x + 4, yy), (x + w - 4 - (yy % 4), yy)], "#706954")
    if blood:
        line(draw, [(x + w - 6, y + 1), (x + w - 11, y + 16)], RED[4], 2)


def person(draw, x, y, corrupt=False, coat="#36465b", pose=0):
    # 18x36 readable silhouette, with one-pixel facial and clothing cues.
    if corrupt:
        px(draw, (x + 5, y, x + 12, y + 8), "#11131a", INK)
        px(draw, (x + 6, y + 2, x + 7, y + 3), RED[5]); px(draw, (x + 10, y + 2, x + 11, y + 3), RED[5])
        coat = "#17141f"
    else:
        px(draw, (x + 5, y, x + 12, y + 8), SKIN[3], INK)
        px(draw, (x + 4, y, x + 13, y + 3), "#171319")
        px(draw, (x + 6, y + 4, x + 6, y + 4), INK); px(draw, (x + 10, y + 4, x + 10, y + 4), INK)
        px(draw, (x + 8, y + 7, x + 10, y + 7), SKIN[1])
    px(draw, (x + 3, y + 9, x + 14, y + 25), coat, INK)
    px(draw, (x + 7, y + 10, x + 9, y + 24), "#b8a874" if not corrupt else RED[3])
    arm = 1 if pose % 2 else 0
    line(draw, [(x + 3, y + 11), (x + arm, y + 23)], coat, 3)
    line(draw, [(x + 14, y + 11), (x + 17 - arm, y + 23)], coat, 3)
    line(draw, [(x + 6, y + 25), (x + 5 - arm, y + 35)], NIGHT[1], 4)
    line(draw, [(x + 12, y + 25), (x + 13 + arm, y + 35)], NIGHT[1], 4)
    px(draw, (x + 2 - arm, y + 34, x + 7, y + 36), INK); px(draw, (x + 11, y + 34, x + 16 + arm, y + 36), INK)


def base(wall, floor_a, floor_b, trim):
    im = Image.new("RGBA", (W, H), wall)
    d = ImageDraw.Draw(im)
    checker(d, 110, floor_a, floor_b)
    px(d, (0, 104, W, 110), trim, INK)
    for x in range(0, W, 32):
        line(d, [(x, 0), (x, 104)], NIGHT[1])
    return im, d


def cubicle():
    im, d = base("#101824", "#171923", "#11141e", "#37404a")
    window(d, (208, 21, 302, 65))
    fluorescent(d, 25, 12, 109)
    # joined fabric partitions with trim and pinned memos
    for box in ((16, 42, 168, 49), (16, 42, 22, 123), (162, 42, 168, 123)):
        px(d, box, "#3e4858", INK)
    for x in range(29, 151, 15):
        px(d, (x, 51, x + 10, 53), "#7d6d72")
    papers(d, 34, 62, 24)
    desk(d, 37, 106, 126)
    crt(d, 78, 65, True)
    phone(d, 217, 73)
    papers(d, 202, 111, 40)
    px(d, (23, 103, 38, 126), "#a79258", INK)
    px(d, (25, 105, 36, 120), "#ddc779")
    line(d, [(27, 110), (34, 110)], RED[4])
    chair(d, 133, 121)
    for x, y in ((182, 134), (273, 126), (291, 151)):
        px(d, (x, y, x + 3, y + 2), "#5b5347")
    return im


def office():
    im, d = base("#0d1420", "#141a24", "#0f151f", "#35404b")
    fluorescent(d, 16, 10, 84, True); fluorescent(d, 184, 10, 95, True)
    for row in range(2):
        for col in range(5):
            x, y = 12 + col * 59 + row * 10, 47 + row * 46
            desk(d, x, y, 48, False); crt(d, x + 13, y - 24, True, red=(row == 1 and col == 3))
            chair(d, x + 20, y + 7, True)
    # printer with output photograph
    px(d, (20, 80, 74, 132), STEEL[4], INK); px(d, (25, 73, 69, 93), STEEL[5], INK)
    px(d, (29, 68, 66, 78), "#ddd6bd", INK); px(d, (33, 71, 61, 75), "#7b7060")
    px(d, (239, 28, 300, 103), WOOD[2], INK); px(d, (244, 34, 295, 96), "#080b12", STEEL[3])
    for i in range(7):
        line(d, [(249, 41 + i * 7), (287, 41 + i * 7)], "#bba066")
    px(d, (271, 60, 291, 67), RED[2]); line(d, [(273, 63), (289, 63)], RED[5])
    # Auditor silhouette beyond desks.
    person(d, 158, 34, True, pose=1)
    line(d, [(0, 89), (319, 89)], RED[4])
    return im


def breakroom():
    im, d = base("#17221f", "#1e2724", "#18211f", "#48534d")
    fluorescent(d, 104, 11, 111)
    papers(d, 23, 31, 73)
    for x in (40, 59, 78):
        line(d, [(x, 34), (x, 47)], "#6f6956")
    # refrigerator with forty-two labelled lunches
    px(d, (114, 27, 188, 126), STEEL[4], INK); px(d, (120, 33, 181, 69), STEEL[1], STEEL[5])
    px(d, (120, 74, 181, 119), STEEL[1], STEEL[5])
    for i in range(12):
        x, y = 124 + (i % 6) * 9, 38 + (i // 6) * 20
        px(d, (x, y, x + 6, y + 11), WOOD[4], INK)
        px(d, (x + 1, y + 2, x + 5, y + 3), "#d9cba4")
    # vending machine
    px(d, (213, 25, 276, 128), "#29213b", INK); px(d, (220, 32, 268, 88), "#17112c", "#7a4ba0")
    for i in range(12):
        x, y = 224 + (i % 4) * 11, 37 + (i // 4) * 15
        px(d, (x, y, x + 7, y + 10), ["#c55a55", "#628bb0", "#d29c51"][i % 3], INK)
    phone(d, 144, 134, True)
    px(d, (285, 108, 308, 133), "#675442", INK); px(d, (288, 112, 305, 131), "#1b2522")
    return im


def server():
    im = Image.new("RGBA", (W, H), "#040814")
    d = ImageDraw.Draw(im)
    for i in range(7):
        x = 7 + i * 45
        px(d, (x, 17, x + 36, 148), "#0a1527", INK); px(d, (x + 4, 21, x + 32, 142), "#102039", "#243958")
        for j in range(10):
            yy = 26 + j * 11
            px(d, (x + 7, yy, x + 29, yy + 6), "#07101e", "#1f3348")
            px(d, (x + 9, yy + 2, x + 10, yy + 3), CYAN[4] if (i + j) % 3 else "#82e7a9")
            line(d, [(x + 14, yy + 2), (x + 25, yy + 2)], "#29465c")
    px(d, (111, 51, 207, 111), STEEL[2], INK); crt(d, 122, 58, True, False, 2)
    papers(d, 224, 113, 61)
    for yy in range(152, 180, 8):
        line(d, [(0, yy), (319, yy)], "#101927")
    for x in range(0, 320, 16):
        line(d, [(x, 148), (x - 12, 180)], "#17243a")
    line(d, [(0, 157), (319, 157)], RED[4], 2)
    return im


def lobby():
    im, d = base("#1a1820", "#26222a", "#1e1b24", "#5a554f")
    fluorescent(d, 96, 10, 129)
    # fire map
    px(d, (20, 31, 94, 107), "#c5bca0", INK); px(d, (25, 36, 89, 101), "#242d31", "#e7dcc0")
    for x in (34, 48, 66, 80):
        line(d, [(x, 43), (x, 91)], STEEL[3], 4)
    line(d, [(57, 39), (57, 97)], SPECTRAL[4], 2); line(d, [(29, 77), (85, 77)], SPECTRAL[4])
    # elevator with joined brass frame, doors and indicator
    px(d, (201, 25, 294, 140), WOOD[4], INK); px(d, (207, 32, 288, 133), STEEL[1], WOOD[5])
    line(d, [(247, 32), (247, 133)], WOOD[5], 3)
    for yy in range(38, 130, 10):
        line(d, [(209, yy), (286, yy)], "#282b31")
    px(d, (233, 12, 260, 26), "#080a10", WOOD[4])
    # pixel seven-segment 13
    line(d, [(239, 16), (239, 22)], RED[4], 2)
    for seg in [((247, 15), (254, 15)), ((254, 16), (254, 21)), ((247, 22), (254, 22)), ((247, 18), (253, 18))]:
        line(d, seg, RED[4], 2)
    phone(d, 120, 109)
    px(d, (108, 28, 171, 88), WOOD[2], INK); px(d, (114, 34, 165, 82), "#080b10", WOOD[4])
    for i in range(6):
        line(d, [(121, 40 + i * 6), (157, 40 + i * 6)], "#d2b26f")
    # spectral reflection is a silhouette, not an overlay block.
    person(d, 259, 80, True, pose=0)
    line(d, [(200, 30), (200, 134)], SPECTRAL[4], 2)
    return im


def stairs():
    im = Image.new("RGBA", (W, H), "#111824")
    d = ImageDraw.Draw(im)
    for x in range(0, W, 56):
        px(d, (x, 0, x + 2, H), "#26313b")
    # hanging coats, each with silhouette details and a readable tag
    for i in range(7):
        x = 14 + i * 18
        line(d, [(x + 7, 22), (x + 7, 31)], STEEL[4])
        line(d, [(x + 3, 26), (x + 7, 22), (x + 11, 26)], STEEL[4])
        coat = ["#222938", "#3d3340", "#233a39", "#4b3d32"][i % 4]
        px(d, (x + 2, 31, x + 12, 86), coat, INK)
        line(d, [(x + 7, 34), (x + 7, 80)], STEEL[1])
        px(d, (x + 4, 45, x + 6, 48), WOOD[5])
    # alarm
    px(d, (143, 26, 181, 63), STEEL[2], INK); px(d, (152, 33, 171, 50), RED[4], RED[5])
    px(d, (156, 55, 167, 58), "#d9c99e")
    # rising coherent flight
    for i in range(10):
        x, y = 128 + i * 18, 144 - i * 10
        px(d, (x, y, min(319, x + 29), y + 8), STEEL[2], INK)
        line(d, [(x, y), (min(319, x + 29), y)], STEEL[4], 2)
    line(d, [(132, 117), (302, 22)], STEEL[4], 2)
    for x in range(136, 300, 18):
        line(d, [(x, 105 - (x - 136) * 5 // 9), (x, 130 - (x - 136) * 5 // 9)], STEEL[3])
    px(d, (232, 19, 301, 88), "#090d13", STEEL[4])
    for x in range(238, 300, 10):
        line(d, [(x, 22), (x, 85)], STEEL[4], 2)
    px(d, (194, 9, 247, 19), "#0a1727", SPECTRAL[4])
    line(d, [(201, 14), (238, 14)], SPECTRAL[5], 2)
    return im


def manager():
    im, d = base("#746b50", "#362c26", "#2e2622", WOOD[3])
    for i in range(3):
        x = 13 + i * 59
        px(d, (x, 18, x + 51, 70), WOOD[4], INK)
        px(d, (x + 4, 22, x + 47, 66), "#86a9a5", "#d1c17e")
        line(d, [(x + 25, 22), (x + 25, 66)], "#667c79", 2)
        line(d, [(x + 4, 44), (x + 47, 44)], "#667c79", 2)
    # framed analyst portraits
    for i in range(4):
        x = 204 + i * 22
        px(d, (x, 37, x + 18, 64), WOOD[2], INK)
        px(d, (x + 3, 40, x + 15, 60), "#ad987a")
        person(d, x + 1, 42, corrupt=(i == 3), coat="#53495d")
    desk(d, 59, 105, 193)
    papers(d, 122, 96, 66, True)
    px(d, (22, 107, 81, 142), WOOD[2], INK)
    for i in range(4):
        papers(d, 28 + i * 8, 99 - i * 2, 35)
    # pen chain and nameplate
    line(d, [(184, 107), (208, 99), (223, 107)], STEEL[4])
    px(d, (95, 109, 145, 119), WOOD[5], INK); line(d, [(100, 114), (140, 114)], RED[2], 2)
    person(d, 258, 67, True, pose=1)
    line(d, [(248, 81), (293, 81)], RED[4], 2)
    window(d, (4, 1, 10, 101), True, True)
    return im


def save_scene(name, image):
    image.save(OUT / f"scene_{name}.png", optimize=True)


def atlas():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 16x16 tile rows: carpet, linoleum, concrete, wall trims, server grille.
    for row, colors in enumerate([
        ("#171923", "#11141e"), ("#1e2724", "#18211f"), ("#343b43", "#202832"),
        ("#2c3440", "#3e4858"), ("#07101e", "#1f3348")
    ]):
        for col in range(8):
            x, y = col * 16, row * 16
            px(d, (x, y, x + 15, y + 15), colors[(row + col) % 2], INK)
            line(d, [(x, y + 7), (x + 15, y + 7)], colors[1])
            px(d, (x + (col * 3) % 12, y + 3 + row, x + (col * 3) % 12 + 1, y + 4 + row), colors[0])
    # Props occupy disciplined 32x32 cells.
    crt(d, 2, 87); phone(d, 35, 91); desk(d, 66, 104, 55); chair(d, 128, 91)
    papers(d, 160, 88, 28, True)
    fluorescent(d, 194, 92, 49, True)
    # 4-frame June row, 4-frame corrupted coworker row.
    for frame in range(4):
        person(d, 8 + frame * 32, 145, False, "#36465b", frame)
        person(d, 8 + frame * 32, 193, True, "#17141f", frame)
    # printer and cabinet.
    px(d, (146, 145, 190, 181), STEEL[4], INK); px(d, (151, 139, 185, 155), STEEL[5], INK)
    px(d, (202, 139, 239, 181), WOOD[2], INK)
    for yy in (147, 158, 169):
        line(d, [(207, yy), (234, yy)], WOOD[5])
    im.save(OUT / "office_atlas.png", optimize=True)


def ui_atlas():
    im = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 48px portraits: June, Eli, Mara, Auditor.
    portraits = [
        (False, "#36465b", SKIN[3], "#1b1720"),
        (False, "#304b50", SKIN[2], "#171319"),
        (False, "#31566a", SKIN[3], "#172b32"),
        (True, "#17141f", "#11131a", "#08090d"),
    ]
    for i, (corrupt, coat, face, hair) in enumerate(portraits):
        ox = i * 48
        px(d, (ox, 0, ox + 45, 45), "#09101a", SPECTRAL[3] if i in (1, 2) else RED[3])
        px(d, (ox + 14, 8, ox + 31, 25), face, INK)
        px(d, (ox + 12, 6, ox + 33, 12), hair)
        px(d, (ox + 9, 26, ox + 36, 44), coat, INK)
        if corrupt:
            line(d, [(ox + 8, 17), (ox + 37, 17)], RED[4], 2)
        else:
            px(d, (ox + 18, 16, ox + 19, 17), INK); px(d, (ox + 26, 16, ox + 27, 17), INK)
            line(d, [(ox + 20, 22), (ox + 26, 22)], SKIN[1])
    # Nine-patch panel and button skins in separate 32px cells.
    for i, (bg, edge, hi) in enumerate([
        ("#080d18", "#536b86", "#93b5ce"), ("#151c2b", "#526785", "#6ad9f1"),
        ("#26131b", "#9d2939", "#ef4757"), ("#0b2027", "#3c8a9b", "#74e1e7")
    ]):
        x = i * 64
        px(d, (x, 64, x + 63, 95), bg, edge)
        line(d, [(x + 2, 66), (x + 61, 66)], hi)
        px(d, (x + 3, 68, x + 4, 69), edge)
        px(d, (x + 59, 90, x + 60, 91), edge)
    # Icons: case file, pause, arrow, warning.
    px(d, (6, 104, 21, 123), "#d0c39d", INK); px(d, (10, 101, 18, 105), "#d0c39d", INK)
    for x in (72, 78):
        px(d, (x, 104, x + 3, 121), SPECTRAL[5], INK)
    line(d, [(136, 108), (149, 112), (136, 118)], SPECTRAL[5], 2)
    line(d, [(201, 121), (209, 103), (217, 121), (201, 121)], RED[4], 2)
    px(d, (208, 109, 210, 115), RED[5]); px(d, (208, 118, 210, 120), RED[5])
    im.save(OUT / "ui_atlas.png", optimize=True)


def title_and_endings():
    # Authored title underlay with office skyline, rain and the elevator seam.
    im = Image.new("RGBA", (W, H), "#050812")
    d = ImageDraw.Draw(im)
    window(d, (17, 16, 302, 134), True, True)
    for x, top in [(29, 85), (52, 72), (79, 93), (105, 62), (140, 79), (173, 57), (210, 87), (245, 68), (276, 91)]:
        px(d, (x, top, x + 20, 134), "#0b101a", NIGHT[2])
        for yy in range(top + 6, 130, 10):
            for xx in range(x + 4, x + 18, 7):
                px(d, (xx, yy, xx + 2, yy + 2), WOOD[4] if (xx + yy) % 3 else "#182130")
    px(d, (142, 45, 178, 135), "#080a10", WOOD[4]); line(d, [(160, 45), (160, 135)], RED[3])
    line(d, [(0, 137), (319, 137)], RED[4], 2)
    im.save(OUT / "title_backdrop.png", optimize=True)
    # Endings are full-scene epilogues, all visibly different.
    for name, palette in {
        "clock_out": SPECTRAL, "new_manager": RED, "monday_forever": NIGHT
    }.items():
        e = Image.new("RGBA", (W, H), palette[0]); ed = ImageDraw.Draw(e)
        checker(ed, 120, palette[1], palette[0])
        window(ed, (21, 18, 298, 109), True, name == "clock_out")
        for i in range(7):
            crt(ed, 28 + i * 40, 88, True, red=name == "new_manager")
        if name == "clock_out":
            for i in range(12):
                line(ed, [(27 + i * 23, 33), (27 + i * 23, 66)], palette[4], 2)
            person(ed, 149, 76, False, "#31566a")
        elif name == "new_manager":
            person(ed, 150, 66, True, "#38131d")
            line(ed, [(113, 83), (208, 83)], RED[4], 3)
        else:
            for i in range(6):
                person(ed, 54 + i * 39, 71, i % 2 == 1, "#242a3b", i)
            line(ed, [(0, 60), (319, 60)], RED[3])
        e.save(OUT / f"ending_{name}.png", optimize=True)


def main():
    for name, fn in {
        "cubicle": cubicle, "office": office, "breakroom": breakroom,
        "server": server, "lobby": lobby, "stairs": stairs, "manager": manager,
    }.items():
        save_scene(name, fn())
    atlas()
    ui_atlas()
    title_and_endings()
    print("generated 13 PNG assets at 320x180/atlas-grid resolution")


if __name__ == "__main__":
    main()
