#!/usr/bin/env python3
"""Generate original Midnight Pawn & Crypt production pixel art.

All stage art is authored on the game's 640x360 logical canvas inside a
300x240 scene window. Atlases use fixed 16/32px grids and transparent cells.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "pixel"
OUT.mkdir(parents=True, exist_ok=True)
SW, SH = 300, 240

INK = "#100d18"
OUTLINE = "#17121f"
SHOP = ["#1a1118", "#2a1820", "#46272a", "#68402d", "#94633c", "#c08a50", "#f0ca76"]
CRYPT = ["#090c14", "#111725", "#1e2735", "#303b4c", "#4b5867", "#73808a", "#b4b8ad"]
VIOLET = ["#160f24", "#28143e", "#4c246c", "#7a42a0", "#ad6bd1", "#e0b2ee"]
TEAL = ["#071a1b", "#0e3434", "#1d5b58", "#338c80", "#66c0a9", "#b7eed2"]
RED = ["#210a10", "#45101a", "#7a1726", "#b62b3c", "#ed5360", "#ffada1"]
GOLD = ["#261909", "#563a12", "#90621e", "#c99332", "#edc45f", "#fff0a8"]
SKIN = ["#3b2226", "#664038", "#9a6650", "#cc9770", "#edbd8c"]


def rect(d, box, fill, outline=None):
    d.rectangle(box, fill=fill, outline=outline)


def line(d, points, fill, width=1):
    d.line(points, fill=fill, width=width)


def dither(d, box, a, b, step=4):
    x1, y1, x2, y2 = box
    rect(d, box, a)
    for y in range(y1, y2 + 1, step):
        for x in range(x1 + ((y // step) % 2) * (step // 2), x2 + 1, step):
            rect(d, (x, y, x, y), b)


def cluster(d, x, y, color, mirror=False):
    """Small hand-shaped material chip; never a random noise field."""
    points = [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (3, 1), (1, 2), (2, 2)]
    for px, py in points:
        xx = x - px if mirror else x + px
        rect(d, (xx, y + py, xx, y + py), color)


def plaster_wear(d, box):
    x1, y1, x2, y2 = box
    # Panel seams establish scale; concentrated chips keep broad areas calm.
    for x in range(x1 + 58, x2, 59):
        line(d, [(x, y1 + 3), (x, y2 - 2)], SHOP[1])
        line(d, [(x + 1, y1 + 3), (x + 1, y2 - 2)], "#51303a")
    for x, y, mirror in [
        (x1 + 8, y1 + 15, False), (x1 + 43, y1 + 78, True),
        (x1 + 118, y1 + 27, False), (x2 - 16, y1 + 64, True),
        (x2 - 72, y2 - 20, False),
    ]:
        cluster(d, x, y, SHOP[1], mirror)
    # Two authored cracks, one cable run, and a vent replace empty plaster.
    line(d, [(x1 + 26, y1 + 95), (x1 + 29, y1 + 90), (x1 + 27, y1 + 84), (x1 + 31, y1 + 80)], SHOP[1])
    line(d, [(x2 - 92, y1 + 7), (x2 - 92, y1 + 30), (x2 - 83, y1 + 38)], OUTLINE, 2)
    rect(d, (x2 - 55, y1 + 9, x2 - 21, y1 + 24), SHOP[1], OUTLINE)
    for yy in range(y1 + 12, y1 + 22, 3):
        line(d, [(x2 - 51, yy), (x2 - 25, yy)], SHOP[4])


def plank_floor(d, y0=188):
    dither(d, (0, y0, SW - 1, SH - 1), SHOP[3], SHOP[2], 6)
    for y in range(y0, SH, 12):
        line(d, [(0, y), (SW, y)], SHOP[1], 2)
    for row, y in enumerate(range(y0, SH, 12)):
        for x in range((row % 2) * 22, SW, 44):
            line(d, [(x, y), (x, min(SH - 1, y + 11))], SHOP[1])
    for x, y in [(18, y0 + 8), (74, y0 + 29), (141, y0 + 14), (231, y0 + 39), (278, y0 + 19)]:
        line(d, [(x, y), (x + 9, y)], SHOP[5])
        cluster(d, x + 3, y + 2, SHOP[2])
    # Hard-edged counter shadow creates foreground separation.
    dither(d, (0, y0, SW - 1, y0 + 7), SHOP[1], SHOP[2], 4)


def stone_floor(d, y0=176, cold=0):
    colors = (CRYPT[2 + cold], CRYPT[1 + cold])
    rect(d, (0, y0, SW - 1, SH - 1), colors[0])
    for row, y in enumerate(range(y0, SH, 12)):
        shift = 12 if row % 2 else 0
        for x in range(-shift, SW, 24):
            rect(d, (x, y, x + 22, y + 10), colors[0], colors[1])
            line(d, [(x + 2, y + 2), (x + 12, y + 2)], CRYPT[3 + cold])
    for x, y in [(7, y0 + 9), (63, y0 + 31), (126, y0 + 15), (184, y0 + 46), (256, y0 + 24)]:
        cluster(d, x, y, CRYPT[0])
    dither(d, (0, y0, SW - 1, y0 + 8), CRYPT[0], CRYPT[1], 4)


def brick_wall(d, box, palette=CRYPT):
    x1, y1, x2, y2 = box
    rect(d, box, palette[1])
    for row, y in enumerate(range(y1 + 2, y2, 12)):
        shift = 9 if row % 2 else 0
        for x in range(x1 - shift, x2, 18):
            rect(d, (x, y, min(x + 16, x2), min(y + 9, y2)), palette[2], palette[0])
            line(d, [(x + 2, y + 2), (min(x + 11, x2), y + 2)], palette[3])
            if (row * 7 + x // 18) % 9 == 2:
                cluster(d, x + 5, y + 5, palette[1], (row % 2) == 0)
    # Localized damp ramps and cracks avoid a mechanically perfect tile wall.
    for xx, yy in [(x1 + 17, y1 + 28), (x1 + 143, y1 + 91), (x2 - 38, y1 + 55)]:
        dither(d, (xx, yy, min(xx + 18, x2), min(yy + 17, y2)), palette[1], palette[2], 4)
    line(d, [(x1 + 72, y1 + 17), (x1 + 75, y1 + 29), (x1 + 70, y1 + 38), (x1 + 74, y1 + 49)], palette[0])


def shelf(d, x, y, w, rows=2):
    rect(d, (x, y, x + w, y + rows * 42 + 8), SHOP[2], OUTLINE)
    for r in range(rows + 1):
        yy = y + 6 + r * 42
        rect(d, (x + 3, yy, x + w - 3, yy + 5), SHOP[5], OUTLINE)
        line(d, [(x + 5, yy + 1), (x + w - 5, yy + 1)], SHOP[6])
    rect(d, (x + 4, y + 5, x + 7, y + rows * 42 + 5), SHOP[3])
    rect(d, (x + w - 7, y + 5, x + w - 4, y + rows * 42 + 5), SHOP[3])


def cabinet(d, x, y, w=52, h=58):
    rect(d, (x, y, x + w, y + h), SHOP[3], OUTLINE)
    rect(d, (x + 4, y + 5, x + w - 4, y + h - 8), "#132026", GOLD[2])
    line(d, [(x + w // 2, y + 5), (x + w // 2, y + h - 8)], GOLD[3])
    rect(d, (x + 2, y + h - 8, x + w - 2, y + h - 3), SHOP[5])
    for xx in (x + 7, x + w - 9):
        rect(d, (xx, y + h - 2, xx + 3, y + h + 8), SHOP[2], OUTLINE)


def lamp(d, x, y, warm=True):
    line(d, [(x, y - 28), (x, y - 8)], SHOP[5] if warm else CRYPT[5], 2)
    rect(d, (x - 9, y - 9, x + 9, y - 2), GOLD[3] if warm else TEAL[3], OUTLINE)
    rect(d, (x - 4, y - 2, x + 4, y + 3), GOLD[5] if warm else TEAL[5], OUTLINE)
    for yy, ww in ((5, 18), (9, 24), (13, 30)):
        col = "#6d4e2633" if warm else "#1d5b5833"
        line(d, [(x - ww, y + yy), (x + ww, y + yy)], col)


def bottle(d, x, y, color):
    rect(d, (x + 3, y, x + 6, y + 4), color, OUTLINE)
    rect(d, (x, y + 4, x + 9, y + 16), color, OUTLINE)
    line(d, [(x + 2, y + 7), (x + 7, y + 7)], "#f4dca3")


def book(d, x, y, color, vertical=True):
    if vertical:
        rect(d, (x, y, x + 6, y + 18), color, OUTLINE)
        line(d, [(x + 2, y + 2), (x + 2, y + 15)], GOLD[4])
    else:
        rect(d, (x, y, x + 20, y + 6), color, OUTLINE)
        line(d, [(x + 3, y + 2), (x + 17, y + 2)], GOLD[4])


def curio(d, x, y, kind, scale=1):
    # Every silhouette is deliberately unique at inventory and world scale.
    def r(box, color, outline=None):
        rect(d, tuple(x + v * scale if i % 2 == 0 else y + v * scale for i, v in enumerate(box)), color, outline)
    if kind == 0:  # ring
        d.ellipse((x + 5 * scale, y + 5 * scale, x + 20 * scale, y + 20 * scale), outline=GOLD[4], width=max(1, 3 * scale))
        rect(d, (x + 11 * scale, y + 2 * scale, x + 14 * scale, y + 6 * scale), GOLD[5], OUTLINE)
    elif kind == 1:  # bone key
        d.ellipse((x + 2 * scale, y + 7 * scale, x + 10 * scale, y + 15 * scale), outline="#ead9b4", width=max(1, 2 * scale))
        line(d, [(x + 9 * scale, y + 11 * scale), (x + 25 * scale, y + 11 * scale)], "#ead9b4", 3 * scale)
        line(d, [(x + 20 * scale, y + 11 * scale), (x + 20 * scale, y + 17 * scale)], "#ead9b4", 2 * scale)
    elif kind == 2:  # music box
        r((3, 8, 24, 22), SHOP[4], OUTLINE); r((5, 5, 22, 9), SHOP[5], OUTLINE)
        r((11, 12, 16, 17), GOLD[4], OUTLINE)
        line(d, [(x + 25 * scale, y + 11 * scale), (x + 28 * scale, y + 8 * scale)], GOLD[3], scale)
    elif kind == 3:  # pistol
        r((2, 8, 23, 13), CRYPT[5], OUTLINE); r((17, 12, 23, 21), SHOP[4], OUTLINE)
        r((7, 13, 15, 16), CRYPT[4], OUTLINE); line(d, [(x + 3 * scale, y + 10 * scale), (x + 9 * scale, y + 10 * scale)], "#e2e4d8", scale)
    elif kind == 4:  # ledger
        r((5, 3, 23, 25), "#15121a", GOLD[2]); line(d, [(x + 10 * scale, y + 4 * scale), (x + 10 * scale, y + 24 * scale)], RED[4], scale)
        line(d, [(x + 14 * scale, y + 8 * scale), (x + 20 * scale, y + 19 * scale)], RED[3], scale)
    elif kind == 5:  # moon coin
        d.ellipse((x + 4 * scale, y + 4 * scale, x + 24 * scale, y + 24 * scale), fill=CRYPT[5], outline=GOLD[3], width=max(1, scale))
        d.ellipse((x + 11 * scale, y + 5 * scale, x + 24 * scale, y + 21 * scale), fill=CRYPT[1])
        rect(d, (x + 8 * scale, y + 19 * scale, x + 10 * scale, y + 21 * scale), TEAL[4])
    elif kind == 6:  # saint tooth
        pts = [(x + 7 * scale, y + 3 * scale), (x + 21 * scale, y + 5 * scale), (x + 18 * scale, y + 25 * scale), (x + 13 * scale, y + 20 * scale), (x + 8 * scale, y + 25 * scale)]
        d.polygon(pts, fill="#ead9b4", outline=OUTLINE)
        line(d, [(x + 10 * scale, y + 8 * scale), (x + 18 * scale, y + 9 * scale)], GOLD[3], scale)
    else:  # crypt heart
        pts = [(x + 14 * scale, y + 26 * scale), (x + 3 * scale, y + 13 * scale), (x + 5 * scale, y + 5 * scale), (x + 13 * scale, y + 8 * scale), (x + 20 * scale, y + 3 * scale), (x + 26 * scale, y + 9 * scale), (x + 24 * scale, y + 17 * scale)]
        d.polygon(pts, fill=RED[3], outline=OUTLINE)
        line(d, [(x + 14 * scale, y + 22 * scale), (x + 14 * scale, y + 11 * scale), (x + 20 * scale, y + 8 * scale)], RED[5], max(1, scale))


def humanoid(d, x, y, palette, frame=0, role="player"):
    # 24x42 silhouette with face, hands, coat folds, feet, and pose animation.
    step = -1 if frame % 4 == 1 else (1 if frame % 4 == 3 else 0)
    skin = palette.get("skin", SKIN[3])
    coat = palette.get("coat", "#344154")
    hair = palette.get("hair", "#251822")
    rect(d, (x + 8, y + 2, x + 17, y + 13), skin, OUTLINE)
    rect(d, (x + 6, y, x + 19, y + 5), hair, OUTLINE)
    rect(d, (x + 8, y + 7, x + 9, y + 8), OUTLINE); rect(d, (x + 15, y + 7, x + 16, y + 8), OUTLINE)
    line(d, [(x + 11, y + 11), (x + 15, y + 11)], SKIN[1])
    rect(d, (x + 5, y + 14, x + 20, y + 31), coat, OUTLINE)
    line(d, [(x + 12, y + 15), (x + 12, y + 30)], palette.get("trim", GOLD[3]))
    if role == "player":
        rect(d, (x + 2, y + 16, x + 6, y + 29), "#2f3949", OUTLINE)
        rect(d, (x + 19, y + 16, x + 23, y + 29), "#2f3949", OUTLINE)
    else:
        arm = 3 if frame == 2 else 0
        line(d, [(x + 5, y + 17), (x + 1, y + 27 - arm)], coat, 4)
        line(d, [(x + 20, y + 17), (x + 24, y + 27 - arm)], coat, 4)
    line(d, [(x + 9, y + 31), (x + 8 + step, y + 41)], CRYPT[1], 4)
    line(d, [(x + 16, y + 31), (x + 17 - step, y + 41)], CRYPT[1], 4)
    rect(d, (x + 4 + step, y + 40, x + 10 + step, y + 43), OUTLINE)
    rect(d, (x + 15 - step, y + 40, x + 21 - step, y + 43), OUTLINE)


def player(d, x, y, frame=0):
    humanoid(d, x, y, {"skin": SKIN[3], "coat": "#34465a", "hair": "#37202b", "trim": TEAL[4]}, frame, "player")
    rect(d, (x + 2, y + 12, x + 7, y + 18), SHOP[5], OUTLINE)  # appraisal loupe satchel


CUSTOMER_PALETTES = [
    {"skin": SKIN[2], "coat": "#3f374f", "hair": "#c1b0a0", "trim": VIOLET[4]},
    {"skin": SKIN[3], "coat": "#314c44", "hair": "#201b17", "trim": GOLD[4]},
    {"skin": SKIN[2], "coat": "#57353b", "hair": "#83746d", "trim": RED[4]},
    {"skin": SKIN[1], "coat": "#243b4e", "hair": "#101824", "trim": TEAL[4]},
]


def customer(d, x, y, index, frame=0):
    humanoid(d, x, y, CUSTOMER_PALETTES[index], frame, "customer")
    if index == 0:
        rect(d, (x + 4, y + 1, x + 7, y + 7), "#b8a99e")  # widow veil
    elif index == 1:
        line(d, [(x + 20, y + 17), (x + 25, y + 34)], GOLD[3], 2)  # cane
    elif index == 2:
        rect(d, (x + 2, y + 15, x + 5, y + 26), CRYPT[5])  # veteran badge/sleeve
    else:
        rect(d, (x + 8, y + 6, x + 17, y + 8), TEAL[4])  # occult spectacles


def enemy(d, x, y, kind, frame=0):
    bob = -2 if frame else 0
    if kind == 0:  # receipt moth
        d.polygon([(x + 15, y + 11 + bob), (x + 2, y + 3 + bob), (x + 6, y + 22 + bob)], fill="#d8c7ae", outline=OUTLINE)
        d.polygon([(x + 17, y + 11 + bob), (x + 30, y + 3 + bob), (x + 26, y + 22 + bob)], fill="#bea7ca", outline=OUTLINE)
        rect(d, (x + 13, y + 7 + bob, x + 18, y + 25 + bob), VIOLET[3], OUTLINE)
        for yy in (7, 12, 17):
            line(d, [(x + 4, y + yy + bob), (x + 12, y + yy + 4 + bob)], RED[3])
    elif kind == 1:  # widow
        d.polygon([(x + 16, y + bob), (x + 3, y + 38), (x + 29, y + 38)], fill=VIOLET[1], outline=OUTLINE)
        rect(d, (x + 11, y + 6 + bob, x + 21, y + 17 + bob), SKIN[1], OUTLINE)
        rect(d, (x + 8, y + 3 + bob, x + 24, y + 10 + bob), "#c1b0a0", OUTLINE)
        line(d, [(x + 6, y + 22), (x + 27, y + 22)], VIOLET[4])
    elif kind == 2:  # debt hand
        rect(d, (x + 11, y + 15 + bob, x + 23, y + 39 + bob), RED[2], OUTLINE)
        for i in range(5):
            line(d, [(x + 13 + i * 3, y + 18 + bob), (x + 3 + i * 7, y + 2 + (i % 2) * 5 + bob)], "#d7c8ae", 4)
        rect(d, (x + 13, y + 23 + bob, x + 21, y + 27 + bob), GOLD[2])
    else:  # bell warden
        rect(d, (x + 5, y + 6 + bob, x + 27, y + 34 + bob), GOLD[2], OUTLINE)
        d.pieslice((x + 3, y + bob, x + 29, y + 24 + bob), 180, 360, fill=GOLD[3], outline=OUTLINE)
        d.ellipse((x + 10, y + 12 + bob, x + 22, y + 24 + bob), fill=CRYPT[0], outline=RED[3])
        rect(d, (x + 13, y + 32 + bob, x + 19, y + 45 + bob), GOLD[4], OUTLINE)


def shop_scene():
    im = Image.new("RGBA", (SW, SH), SHOP[1])
    d = ImageDraw.Draw(im)
    dither(d, (0, 0, SW - 1, 187), SHOP[2], "#51303a", 8)
    plaster_wear(d, (0, 20, SW - 1, 187))
    rect(d, (0, 0, SW - 1, 19), SHOP[3]); line(d, [(0, 19), (SW, 19)], SHOP[5], 2)
    for x in range(8, SW, 42):
        rect(d, (x, 4, x + 25, 8), SHOP[2])
        cluster(d, x + 3, 10, SHOP[5])
    # Window, shelving, clock, tools, counter and visible stories.
    rect(d, (15, 30, 76, 102), SHOP[3], OUTLINE)
    rect(d, (20, 35, 71, 96), "#102126", GOLD[2])
    line(d, [(45, 35), (45, 96)], "#44656a", 2)
    for yy in (43, 59, 74):
        line(d, [(22, yy), (69, yy - 6)], TEAL[3])
    shelf(d, 88, 29, 103, 2)
    for i, (xx, yy) in enumerate([(99, 42), (128, 42), (158, 42), (99, 84), (128, 84), (158, 84)]):
        curio(d, xx, yy, i % 8)
    cabinet(d, 222, 50, 58, 74)
    curio(d, 237, 67, 7)
    bottle(d, 203, 91, TEAL[3]); bottle(d, 214, 96, RED[3])
    book(d, 199, 57, VIOLET[2]); book(d, 207, 57, RED[2])
    lamp(d, 150, 24, True)
    # Appraisal desk.
    rect(d, (13, 147, 287, 187), SHOP[3], OUTLINE)
    rect(d, (10, 142, 290, 151), SHOP[5], OUTLINE)
    line(d, [(13, 144), (287, 144)], SHOP[6])
    rect(d, (125, 153, 177, 182), "#34242c", OUTLINE)
    d.ellipse((132, 157, 150, 175), outline=GOLD[4], width=3)
    line(d, [(149, 173), (157, 181)], GOLD[4], 3)
    curio(d, 189, 154, 0)
    book(d, 78, 159, RED[2], False); book(d, 81, 153, VIOLET[2], False)
    for x in (31, 64, 211, 261):
        line(d, [(x, 155), (x + 14, 155)], SHOP[5])
        cluster(d, x + 4, 176, SHOP[2])
    plank_floor(d, 188)
    return im


def title_scene():
    im = Image.new("RGBA", (SW, SH), "#090b14")
    d = ImageDraw.Draw(im)
    # Rainy crooked storefront with deep crypt stair behind its display.
    brick_wall(d, (0, 0, 299, 259), [INK, "#151522", "#211c2c", "#33273c", "#4a3a50", "#746174", "#b49e9c"])
    rect(d, (40, 30, 260, 188), SHOP[2], OUTLINE)
    rect(d, (48, 38, 252, 178), SHOP[4], GOLD[2])
    rect(d, (57, 48, 243, 169), "#090f17", OUTLINE)
    line(d, [(150, 48), (150, 169)], SHOP[5], 3)
    for x in (68, 96, 183, 222):
        line(d, [(x, 52), (x - 8, 111)], TEAL[3])
    shelf(d, 67, 100, 72, 1); shelf(d, 162, 100, 72, 1)
    curio(d, 86, 113, 0); curio(d, 112, 113, 2); curio(d, 178, 113, 5); curio(d, 205, 111, 7)
    rect(d, (82, 17, 218, 45), SHOP[3], OUTLINE); rect(d, (88, 22, 212, 40), "#1a1118", GOLD[4])
    for x, y in [(12, 22), (25, 151), (271, 62), (280, 184), (57, 201)]:
        cluster(d, x, y, "#0c0b12")
    rect(d, (17, 12, 21, 198), "#10131c", CRYPT[4])
    for y in (38, 97, 157):
        rect(d, (14, y, 24, y + 3), CRYPT[3])
    rect(d, (91, 25, 94, 28), GOLD[2]); rect(d, (206, 25, 209, 28), GOLD[2])
    # Crypt stair visible under the shop threshold.
    for i in range(7):
        x1, x2, y = 76 + i * 12, 224 - i * 12, 184 + i * 9
        rect(d, (x1, y, x2, y + 7), CRYPT[3], OUTLINE)
        line(d, [(x1 + 2, y + 1), (x2 - 2, y + 1)], CRYPT[5])
    dither(d, (131, 203, 169, 259), VIOLET[1], VIOLET[2], 5)
    return im


def dungeon_scene(room):
    im = Image.new("RGBA", (SW, SH), CRYPT[0])
    d = ImageDraw.Draw(im)
    if room == 0:
        brick_wall(d, (0, 0, 299, 175))
        # Receipt stair and ink channels.
        for i in range(8):
            rect(d, (24 + i * 23, 155 - i * 13, 118 + i * 23, 164 - i * 13), CRYPT[4], OUTLINE)
            line(d, [(27 + i * 23, 157 - i * 13), (115 + i * 23, 157 - i * 13)], "#d8c7ae")
        for i in range(6):
            paper_x = 115 + i * 13
            rect(d, (paper_x, 116 + (i % 2) * 7, paper_x + 9, 137 + (i % 2) * 7), VIOLET[3], OUTLINE)
            line(d, [(paper_x + 2, 120 + (i % 2) * 7), (paper_x + 7, 120 + (i % 2) * 7)], RED[4])
        rect(d, (14, 29, 59, 84), "#121a26", CRYPT[4])
        for y in range(37, 78, 8):
            line(d, [(20, y), (52, y)], "#d8c7ae")
        # Ledger cables and wall receipts tell the route before combat.
        line(d, [(58, 18), (58, 98), (86, 124), (86, 166)], VIOLET[2], 2)
        for x, y in [(211, 23), (236, 49), (267, 72)]:
            rect(d, (x, y, x + 14, y + 20), "#d8c7ae", OUTLINE)
            line(d, [(x + 3, y + 5), (x + 11, y + 5)], RED[3])
    elif room == 1:
        brick_wall(d, (0, 0, 299, 175))
        # Widow niche, memorial flowers and ring plinth.
        rect(d, (99, 24, 201, 170), CRYPT[0], CRYPT[5])
        d.arc((112, 38, 188, 125), 180, 360, fill=CRYPT[5], width=4)
        rect(d, (112, 80, 188, 170), CRYPT[1], OUTLINE)
        for x in (44, 66, 232, 254):
            rect(d, (x, 111, x + 12, 169), CRYPT[3], OUTLINE)
            line(d, [(x + 6, 110), (x + 2, 94)], TEAL[3], 2)
            rect(d, (x - 2, 90, x + 5, 97), VIOLET[4])
        rect(d, (131, 137, 169, 170), CRYPT[4], OUTLINE); curio(d, 137, 140, 0)
        for x in (17, 281):
            line(d, [(x, 22), (x, 135)], TEAL[2], 2)
            for y in (46, 83, 122):
                cluster(d, x - 2, y, TEAL[3], x > 100)
    elif room == 2:
        brick_wall(d, (0, 0, 299, 175))
        # Ossuary market: coherent stalls, skull shelves and bone spike hazard.
        for x in (18, 102, 216):
            rect(d, (x, 49, x + 64, 132), SHOP[2], OUTLINE)
            rect(d, (x - 4, 43, x + 68, 52), SHOP[4], OUTLINE)
            for yy in (74, 100):
                line(d, [(x + 4, yy), (x + 59, yy)], CRYPT[5], 3)
            for i in range(6):
                sx, sy = x + 7 + (i % 3) * 17, 58 + (i // 3) * 26
                d.ellipse((sx, sy, sx + 10, sy + 9), fill="#d8ccb1", outline=OUTLINE)
                rect(d, (sx + 2, sy + 7, sx + 8, sy + 12), "#d8ccb1", OUTLINE)
        for i in range(7):
            x = 92 + i * 17
            d.polygon([(x, 176), (x + 8, 140 - (i % 2) * 9), (x + 16, 176)], fill=RED[3], outline=OUTLINE)
        for x in (31, 119, 233):
            line(d, [(x, 54), (x + 43, 54)], SHOP[5])
            cluster(d, x + 8, 123, SHOP[1])
    else:
        # Chapel architecture and bell hazards.
        brick_wall(d, (0, 0, 299, 175))
        for x in (25, 248):
            rect(d, (x, 35, x + 26, 175), CRYPT[3], OUTLINE)
            rect(d, (x - 5, 30, x + 31, 42), CRYPT[5], OUTLINE)
        rect(d, (88, 40, 212, 175), CRYPT[0], CRYPT[5])
        d.arc((102, 51, 198, 142), 180, 360, fill=CRYPT[5], width=4)
        for x in (76, 224):
            line(d, [(x, 0), (x, 45)], GOLD[3], 2)
            d.pieslice((x - 11, 35, x + 11, 55), 180, 360, fill=GOLD[3], outline=OUTLINE)
        rect(d, (111, 141, 189, 174), SHOP[3], OUTLINE)
        rect(d, (121, 132, 179, 145), RED[2], GOLD[3])
        line(d, [(127, 138), (173, 138)], RED[5])
        for x in (60, 239):
            line(d, [(x, 64), (x + (-7 if x < 100 else 7), 118)], VIOLET[2], 2)
            cluster(d, x - 2, 121, VIOLET[3], x > 100)
    stone_floor(d, 176)
    # Four location-specific exit doors.
    rect(d, (264, 111, 294, 177), CRYPT[1], CRYPT[5])
    d.arc((264, 96, 294, 132), 180, 360, fill=CRYPT[5], width=3)
    rect(d, (286, 143, 289, 146), GOLD[4])
    return im


def final_scene():
    im = dungeon_scene(3)
    d = ImageDraw.Draw(im)
    dither(d, (73, 43, 227, 175), VIOLET[0], VIOLET[1], 6)
    rect(d, (104, 132, 196, 177), SHOP[3], OUTLINE)
    rect(d, (114, 124, 186, 139), RED[1], GOLD[3])
    curio(d, 136, 83, 7, 1)
    for x in (94, 206):
        line(d, [(x, 30), (x, 118)], RED[3], 2)
        rect(d, (x - 3, 51, x + 3, 57), RED[5])
    return im


def result_scene():
    im = shop_scene()
    d = ImageDraw.Draw(im)
    # Dawn light and a completed ledger replace the midnight customer.
    rect(d, (20, 35, 71, 96), "#72939a", GOLD[3])
    line(d, [(22, 92), (69, 41)], GOLD[5], 2)
    for i in range(8):
        curio(d, 28 + (i % 4) * 35, 205 + (i // 4) * 27, i)
    rect(d, (178, 197, 276, 248), "#d8c9a6", OUTLINE)
    for yy in range(204, 241, 7):
        line(d, [(186, yy), (266 - (yy % 5), yy)], SHOP[3])
    return im


def characters_atlas():
    im = Image.new("RGBA", (256, 240), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for frame in range(8):
        player(d, frame * 32 + 3, 2, frame)
    for customer_id in range(4):
        for frame in range(4):
            customer(d, frame * 32 + 3, 48 + customer_id * 48 + 2, customer_id, frame)
    im.save(OUT / "characters.png", optimize=True)


def shop_atlas():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 16 shop floor/wall/trim tiles.
    for row in range(4):
        for col in range(4):
            x, y = col * 16, row * 16
            rect(d, (x, y, x + 15, y + 15), SHOP[1 + (row % 3)], OUTLINE)
            if row == 0:
                for xx in range(x + 2, x + 15, 5):
                    line(d, [(xx, y), (xx, y + 15)], SHOP[3])
            elif row == 1:
                line(d, [(x, y + 7), (x + 15, y + 7)], SHOP[4], 2)
            elif row == 2:
                line(d, [(x, y + 3), (x + 15, y + 3)], SHOP[5])
            else:
                rect(d, (x + 3, y + 3, x + 12, y + 12), "#132026", GOLD[2])
    shelf(d, 72, 4, 80, 2)
    cabinet(d, 163, 8, 50, 62)
    lamp(d, 232, 34, True)
    rect(d, (4, 96, 124, 132), SHOP[3], OUTLINE); rect(d, (2, 91, 126, 99), SHOP[5], OUTLINE)
    bottle(d, 139, 103, TEAL[3]); bottle(d, 153, 103, RED[3])
    for i in range(5):
        book(d, 176 + i * 9, 97, [RED[2], VIOLET[2], TEAL[2]][i % 3])
    # Appraisal tools, bell, till, crate, window.
    d.ellipse((8, 155, 31, 178), outline=GOLD[4], width=3); line(d, [(28, 175), (40, 188)], GOLD[4], 4)
    d.pieslice((52, 160, 79, 184), 180, 360, fill=GOLD[3], outline=OUTLINE)
    rect(d, (91, 153, 132, 184), CRYPT[4], OUTLINE)
    for yy in range(159, 178, 6):
        for xx in range(98, 127, 7):
            rect(d, (xx, yy, xx + 3, yy + 3), GOLD[4], OUTLINE)
    rect(d, (146, 149, 197, 187), SHOP[3], OUTLINE)
    line(d, [(150, 155), (193, 181)], SHOP[5]); line(d, [(193, 155), (150, 181)], SHOP[5])
    rect(d, (208, 146, 252, 196), "#102126", GOLD[2])
    line(d, [(230, 146), (230, 196)], TEAL[3], 2)
    im.save(OUT / "shop_atlas.png", optimize=True)


def crypt_atlas():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 20 disciplined stone/wall/corner/hazard tiles.
    for row in range(4):
        for col in range(5):
            x, y = col * 16, row * 16
            rect(d, (x, y, x + 15, y + 15), CRYPT[1 + row % 3], OUTLINE)
            if col == 0:
                line(d, [(x, y), (x + 15, y)], CRYPT[5], 2)
            elif col == 1:
                line(d, [(x, y), (x, y + 15)], CRYPT[5], 2)
            elif col == 2:
                line(d, [(x, y + 15), (x + 15, y)], CRYPT[4])
            elif col == 3:
                d.polygon([(x, y + 15), (x + 8, y + 2), (x + 15, y + 15)], fill=RED[3])
            else:
                for xx in range(x + 2, x + 15, 4):
                    line(d, [(xx, y + 2), (xx - 2, y + 13)], VIOLET[3])
    # Eight animated enemy frames, fixed 32x48 cells.
    for kind in range(4):
        for frame in range(2):
            enemy(d, kind * 64 + frame * 32, 72, kind, frame)
    # Door, column, stairs, chest, skull pile, curse glyph.
    rect(d, (5, 140, 42, 218), CRYPT[1], CRYPT[5]); d.arc((5, 124, 42, 165), 180, 360, fill=CRYPT[5], width=3)
    rect(d, (53, 139, 72, 222), CRYPT[3], OUTLINE); rect(d, (48, 134, 77, 146), CRYPT[5], OUTLINE)
    for i in range(5):
        rect(d, (88 + i * 9, 204 - i * 11, 158 - i * 4, 211 - i * 11), CRYPT[4], OUTLINE)
    rect(d, (168, 175, 207, 212), SHOP[3], OUTLINE); rect(d, (165, 171, 210, 184), GOLD[2], OUTLINE)
    for i in range(6):
        x, y = 216 + (i % 3) * 11, 181 + (i // 3) * 15
        d.ellipse((x, y, x + 9, y + 8), fill="#d8ccb1", outline=OUTLINE)
    line(d, [(226, 145), (244, 163), (226, 163), (244, 145), (226, 145)], VIOLET[4], 2)
    im.save(OUT / "crypt_atlas.png", optimize=True)


def curios_atlas():
    im = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for kind in range(8):
        curio(d, kind * 32 + 2, 2, kind)
        # World pickups use a plinth/shadow and shifted pose in second row.
        d.ellipse((kind * 32 + 3, 57, kind * 32 + 29, 62), fill="#080a1088")
        curio(d, kind * 32 + 2, 32, kind)
    im.save(OUT / "curios.png", optimize=True)


def ui_atlas():
    im = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, (bg, border, hi) in enumerate([
        ("#1c1524", "#5d4968", "#8d719a"), ("#271c30", "#8e6438", GOLD[4]),
        ("#131c25", "#376b69", TEAL[4]), ("#29131c", "#7a2330", RED[4]),
    ]):
        x = i * 64
        rect(d, (x, 0, x + 63, 31), bg, border)
        line(d, [(x + 2, 2), (x + 61, 2)], hi)
        rect(d, (x + 4, 5, x + 5, 6), border)
        rect(d, (x + 58, 25, x + 59, 26), border)
    # Integrated D-pad/action icons.
    for i, pts in enumerate([
        [(13, 55), (25, 44), (25, 66)], [(76, 44), (65, 56), (87, 56)],
        [(141, 66), (130, 54), (152, 54)], [(218, 44), (230, 55), (218, 66)],
    ]):
        d.polygon(pts, fill=GOLD[5], outline=OUTLINE)
    # Appraisal, price tag, guard and combat glyphs.
    d.ellipse((8, 88, 28, 108), outline=TEAL[5], width=3); line(d, [(25, 105), (36, 118)], TEAL[5], 4)
    d.polygon([(68, 91), (91, 91), (100, 103), (91, 115), (68, 115)], fill=GOLD[3], outline=OUTLINE)
    d.ellipse((74, 99, 78, 103), fill=INK)
    d.polygon([(140, 89), (155, 94), (153, 110), (140, 119), (127, 110), (125, 94)], fill=TEAL[3], outline=TEAL[5])
    line(d, [(203, 116), (230, 90)], RED[5], 4); line(d, [(205, 90), (232, 116)], RED[5], 4)
    im.save(OUT / "ui_atlas.png", optimize=True)


def main():
    scenes = {
        "title": title_scene(),
        "shop": shop_scene(),
        "crypt_0_receipt_stair": dungeon_scene(0),
        "crypt_1_widow_niche": dungeon_scene(1),
        "crypt_2_ossuary_market": dungeon_scene(2),
        "crypt_3_foreclosure_chapel": dungeon_scene(3),
        "final_appraisal": final_scene(),
        "result_dawn": result_scene(),
    }
    for name, image in scenes.items():
        image.save(OUT / f"scene_{name}.png", optimize=True)
    characters_atlas()
    shop_atlas()
    crypt_atlas()
    curios_atlas()
    ui_atlas()
    print("generated 8 stage scenes and 5 transparent pixel atlases")


if __name__ == "__main__":
    main()
