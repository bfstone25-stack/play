#!/usr/bin/env python3
"""Photograph Floor 13 IN JAPANESE, by pressing the language button the player presses.

An on-disk check cannot tell you a font is right. After Six's bundled face passed every
string check while holding 342 glyphs cut for Chinese and no kana at all, and Floor 13's
own atlas was built before the Japanese translation and was missing 318 characters — 43 of
them kana — while looking, on disk, exactly like a working font. The only verification
that catches that is loading the build in the language and LOOKING at the frames.

It also exercises the path that was actually broken here: title_screen.gd chose the CJK
face on `Loc.is_zh()`, i.e. on the locale rather than on the string, so Japanese would have
been typed in WorkSans — which has no kana — and Godot cannot fall through to a browser
face on a web export.

Same viewport and same runner as ops/play_driver.py; only the click list differs.

    ops/remote_playtest.sh build/godot/floor-13/web play/floor-13/tools/ja_shots.py
"""
import asyncio
import os
import sys

from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"

# The canvas is 640x360 drawn into a 1280x720 viewport, so every game coordinate doubles.
# The language row is laid out by hud.gd: x = COL_X + i * (w + gap), y = 302, h = 30, with
# COL_X 402, COL_W 226 and three languages — en, zh, ja.
COL_X, COL_W, GAP, ROW_Y, ROW_H = 402.0, 226.0, 4.0, 302.0, 30.0


def lang_button(i, n=3):
    w = (COL_W - GAP * (n - 1)) / n
    return (int((COL_X + i * (w + GAP) + w / 2) * 2), int((ROW_Y + ROW_H / 2) * 2))


STEPS = [
    ("ja_title", "click", lang_button(2)),      # 日本語
    ("ja_start", "click", (int(515 * 2), int(251 * 2))),   # BEGIN NIGHT SHIFT
    ("ja_line1", "click", (640, 500)),
    ("ja_line2", "key", "Space"),
    ("ja_line3", "key", "Space"),
    ("ja_line4", "key", "Space"),
    ("ja_room", "key", "Space"),
    ("ja_hotspot", "click", (280, 340)),
    ("ja_hs_line", "key", "Space"),
    ("ja_hs_line2", "key", "Space"),
    ("ja_log", "click", (940, 40)),
]


async def main():
    os.makedirs(OUT, exist_ok=True)
    con = []
    errs = []
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
        ctx = await b.new_context(viewport={"width": 1280, "height": 720})
        pg = await ctx.new_page()
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.on("console", lambda m: con.append("%s: %s" % (m.type, m.text))
              if m.type in ("error", "warning") else None)
        await pg.goto(URL, wait_until="load")
        await pg.wait_for_timeout(14000)
        await pg.screenshot(path=os.path.join(OUT, "j00_boot.png"))
        for n, (label, kind, arg) in enumerate(STEPS, start=1):
            if kind == "click":
                await pg.mouse.click(arg[0], arg[1])
            else:
                await pg.keyboard.press(arg)
            await pg.wait_for_timeout(1600)
            await pg.screenshot(path=os.path.join(OUT, "j%02d_%s.png" % (n, label)))
        await b.close()
    print("page errors:", errs if errs else "none")
    print("console:", "\n  ".join(con) if con else "none")


asyncio.run(main())
