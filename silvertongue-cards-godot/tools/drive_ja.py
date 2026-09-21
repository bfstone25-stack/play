#!/usr/bin/env python3
"""Drive SilverTongue into Japanese and photograph it.

    REMOTE_NAME=stc-ja ops/remote_playtest.sh build/godot/silvertongue-cards/web \\
        play/silvertongue-cards-godot/tools/drive_ja.py

The point is not that the language switch works — it is that the text RENDERS. A missing
CJK face draws every character as a blank box and reports nothing anywhere, so this has to
be looked at, not asserted.
"""
import asyncio, os, sys
from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"
LANG_BUTTON = (883, 26)     # the top bar's language button, left of the nav


async def main():
    os.makedirs(OUT, exist_ok=True)
    errs, logs = [], []
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
        ctx = await b.new_context(viewport={"width": 1280, "height": 720})
        pg = await ctx.new_page()
        pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
        pg.on("console", lambda m: logs.append(f"{m.type}: {m.text}"[:200]))
        await pg.goto(URL, wait_until="load", timeout=150000)
        await pg.wait_for_timeout(13000)
        await pg.screenshot(path=f"{OUT}/j00_title_en.png")

        # any key leaves the title
        await pg.keyboard.press("Enter")
        await pg.wait_for_timeout(2500)
        await pg.screenshot(path=f"{OUT}/j01_home_en.png")

        # en -> ja
        await pg.mouse.click(*LANG_BUTTON)
        await pg.wait_for_timeout(2500)
        await pg.screenshot(path=f"{OUT}/j02_home_ja.png")

        # into a duel, in Japanese: digit 1 opens the first person on the roster
        await pg.keyboard.press("1")
        await pg.wait_for_timeout(3500)
        await pg.screenshot(path=f"{OUT}/j03_duel_ja.png")
        for i in range(3):
            await pg.keyboard.press("Enter")
            await pg.wait_for_timeout(2600)
            await pg.screenshot(path=f"{OUT}/j0{4+i}_turn_ja.png")

        print("page errors:", errs[:3] or "none")
        for l in logs:
            if "rror" in l:
                print("CONSOLE:", l)
        await b.close()

asyncio.run(main())
