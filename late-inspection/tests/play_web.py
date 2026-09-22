#!/usr/bin/env python3
"""Play Late Inspection: Flat 404 in a browser and photograph every stage it reaches.

    ops/remote_playtest.sh build/godot/late-inspection/web play/late-inspection/tests/play_web.py

Why this exists when ops/play_driver.py already walks every game in the studio: that driver
is a generic prober. It clicks the obvious places and presses the obvious keys, which is
the right instrument for a 2D game whose whole interface is on the canvas. This one is a
first-person 3D game. Its interface is a corridor: to reach a stage you have to STAND in
front of a prop and be LOOKING at it (scripts/player.gd interact_target(), FACE_DOT 0.80 —
a 36.9 degree half-angle), and no amount of clicking at (640, 400) does that.

So the shots the generic driver took were honest and the conclusion drawn from them was
not: three tiles, all of the title screen, reported as "reaches 3 stages". Two separate
faults were hiding in that one number and only one of them was the game's:

  * the primary button really was unreachable — ENTER THE BUILDING sat at x=26 in the left
    column and the driver only ever presses the middle of the canvas. That is fixed in the
    game (hud.gd ENTER_RECT), because a primary action a prober cannot find is one a
    player has to hunt for.
  * past the door, nothing a generic driver can do would have worked anyway. That is not a
    fault at all, it is what a first-person game is. It needs a driver that walks.

WHAT THIS DRIVER KNOWS THAT A GENERIC ONE CANNOT

Pointer lock. Godot's web build captures the pointer when the player enters the building,
and from then on mouse look is driven by `movementX`/`movementY`, not by page coordinates.
Playwright's mouse.move does deliver those under lock in Chromium, so look is a sequence of
small relative moves; a single large jump gets swallowed or clamped and reads as no look at
all, so every sweep here is stepped.

The route below is the opening of the game walked the way a player walks it, from the
positions in scripts/story_content.gd: the folio is behind and to the left of the spawn,
403's note and the fire plan are down the corridor, the access notice is on 404's door.
After each interaction the ADV bar has to be advanced, which is a click or Space, repeated
until the bar is gone.

NOTHING IS DISCARDED. Every frame is numbered and kept; ops/play_matrix.py decides
afterwards which are distinct. A driver that throws away what it thinks is a dud is how you
get a matrix of nine identical title screens.
"""
import asyncio
import os
import sys

from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"

# The canvas is 1280x720 inside the page; the build letterboxes to fit.
ENTER = (640, 513)          # hud.gd ENTER_RECT centre


async def shot(page, n, label):
    await page.screenshot(path=f"{OUT}/s{n:02d}_{label}.png")
    print(f"  s{n:02d}_{label}")


async def look(page, dx, dy, steps=12):
    """A stepped relative sweep. One big mouse.move under pointer lock is clamped by the
    browser and arrives as almost no rotation; twelve small ones arrive as all of it."""
    for _ in range(steps):
        await page.mouse.move(640 + dx / steps, 360 + dy / steps)
        await page.wait_for_timeout(16)


async def walk(page, key, ms):
    await page.keyboard.down(key)
    await page.wait_for_timeout(ms)
    await page.keyboard.up(key)
    await page.wait_for_timeout(120)


async def advance(page, times=6):
    """Clear the ADV bar. Space advances it; it takes as many presses as the note has
    pages, and pressing it when there is no bar is harmless."""
    for _ in range(times):
        await page.keyboard.press("Space")
        await page.wait_for_timeout(260)


async def main():
    os.makedirs(OUT, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch(args=[
            "--use-gl=angle", "--use-angle=gl-egl", "--enable-unsafe-swiftshader",
        ])
        page = await browser.new_page(viewport={"width": 1280, "height": 720})
        page.on("console", lambda m: print("  [console]", m.text[:160])
                if m.type == "error" else None)
        await page.goto(URL)
        # Godot's web build spends a while on the wasm and the pack before it draws.
        await page.wait_for_timeout(14000)
        n = 0
        await shot(page, n, "title"); n += 1

        # ---- in ----------------------------------------------------------------------
        await page.mouse.click(*ENTER)
        await page.wait_for_timeout(2500)
        await shot(page, n, "entered"); n += 1

        # The chapter card sits over the corridor for a beat.
        await advance(page, 2)
        await shot(page, n, "corridor"); n += 1

        # ---- stage 0: the sealed folio, behind and to the left of the spawn ----------
        await look(page, -260, 0)
        await walk(page, "KeyW", 900)
        await shot(page, n, "look_folio"); n += 1
        await page.keyboard.press("KeyE")
        await page.wait_for_timeout(700)
        await shot(page, n, "folio"); n += 1
        await advance(page)
        await shot(page, n, "folio_read"); n += 1

        # ---- stage 1: down the corridor — 403's note, the fire plan, 404's notice ----
        await look(page, 300, 0)
        await walk(page, "KeyW", 1400)
        await shot(page, n, "corridor_2"); n += 1
        await page.keyboard.press("KeyE")
        await page.wait_for_timeout(700)
        await advance(page)
        await shot(page, n, "note_403"); n += 1

        await look(page, 0, -90)
        await page.keyboard.press("KeyE")
        await page.wait_for_timeout(700)
        await advance(page)
        await shot(page, n, "fire_plan"); n += 1

        await look(page, 220, 90)
        await walk(page, "KeyW", 1100)
        await page.keyboard.press("KeyE")
        await page.wait_for_timeout(700)
        await advance(page)
        await shot(page, n, "notice"); n += 1

        # ---- whatever is next: sweep and press, and photograph all of it -------------
        for i, (dx, dy, fwd) in enumerate([
            (-140, 0, 800), (140, 0, 800), (0, 70, 600),
            (180, -70, 900), (-200, 0, 700), (0, 0, 1200),
        ]):
            await look(page, dx, dy)
            if fwd:
                await walk(page, "KeyW", fwd)
            await page.keyboard.press("KeyE")
            await page.wait_for_timeout(600)
            await advance(page, 4)
            await shot(page, n, f"sweep_{i}"); n += 1

        print(f"PLAY_WEB_DONE frames={n}")
        await browser.close()


asyncio.run(main())
