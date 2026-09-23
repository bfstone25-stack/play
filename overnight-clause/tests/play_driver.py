#!/usr/bin/env python3
"""Play Overnight Clause in a browser and photograph every stage it reaches.

    REMOTE_NAME=play-overnight-clause ops/remote_playtest.sh \
        build/godot-ads/overnight-clause play/overnight-clause/tests/play_driver.py

Why this exists when ops/play_driver.py already does the job for 25 other titles.

ops/play_driver.py is deliberately game-blind: it clicks the middle of the screen a few
times, presses Space / Enter / ArrowRight, and photographs after each. That is the right
driver for a title screen with a button and a scene that advances on click, which is what
most of the catalogue is. It cannot play this one, and the reason is not a bug in either:

  * this is a FIRST-PERSON game. Its verbs are walk (WASD), look (mouse, under pointer
    lock) and use (E). None of those are in the blind driver's list, and none of them can
    be guessed from outside — a centre click in a pointer-locked game is a click into the
    middle distance.
  * the story only opens once the player is standing in front of something and facing it.
    scripts/player.gd:interact_target() wants the prop within 6.5 m AND inside a 36.9
    degree cone (FACE_DOT 0.80). Standing still, nothing is ever in reach.

So the blind driver's twelve frames were the title screen, twice: `2 stage(s) of 12
frames`. Not because the game was broken — tests/walkthrough.gd walks all three routes to
an ending on every build — but because nothing it pressed was an input this game has.

What this driver does NOT do is skip the input path. There is no warp, no autoplay flag,
no calling into GDScript. It presses keys and moves a mouse, exactly as a player does, and
that is the point: the bug it caught on 2026-09-21 was that the title screen swallowed
every click except one 400x54 button, so a real player's first click did nothing. A driver
that had warped past the title would have shown six healthy stages and told us nothing.

The shape of a session, and why it is a loop rather than a list of coordinates:
the corridor's props are at fixed world positions, but the player's own position after a
walk depends on collisions and framerate, so a fixed list of "now press E" moments goes
stale the first time the level changes (memory: godot-web-testing-traps). Instead each
beat is: sweep the torch across the arc in front, press E, walk on, and photograph. Over
enough beats that reaches what is reachable, and ops/play_matrix.py throws away the frames
that did not change.
"""
import asyncio
import os
import sys

from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"

# Godot's wasm build, the 3D world and the title's 28 s dolly all have to be up before the
# first frame is worth keeping. ops/play_driver.py waits 12 s for a 2D title; this one is a
# 3D scene with a second camera in it.
BOOT_MS = 15000
BEAT_MS = 1400


class Session:
    def __init__(self, page):
        self.page = page
        self.n = 0

    async def shot(self, label):
        self.n += 1
        await self.page.screenshot(path=os.path.join(OUT, "s%02d_%s.png" % (self.n, label)))

    async def key(self, k, ms=220):
        await self.page.keyboard.press(k)
        await self.page.wait_for_timeout(ms)

    async def hold(self, k, ms):
        """Walk. `press` is a tap and this game reads held keys in _physics_process, so a
        tap moves the player by roughly nothing — the first version of this driver did
        exactly that and never left the lobby."""
        await self.page.keyboard.down(k)
        await self.page.wait_for_timeout(ms)
        await self.page.keyboard.up(k)
        await self.page.wait_for_timeout(250)

    async def look(self, dx, dy=0):
        """Mouse look under pointer lock. The canvas has the pointer, so absolute
        coordinates mean nothing and only the delta between successive moves is read;
        moving in several steps is what makes the browser report a movement delta at all."""
        x, y = 640, 360
        for i in range(6):
            await self.page.mouse.move(x + dx * (i + 1) / 6.0, y + dy * (i + 1) / 6.0)
            await self.page.wait_for_timeout(40)
        await self.page.wait_for_timeout(200)

    async def sweep_and_use(self):
        """Look left, centre, right — pressing E and Space at each — then face front again.

        E is "use the thing you are looking at"; Space advances whatever that opened. Both
        are harmless when there is nothing there, which is what lets this be a sweep rather
        than a script of known prop positions."""
        for dx in (-260, 260, 260, -260):
            await self.look(dx)
            await self.key("e", 700)
            await self.key("Space", 400)


async def main():
    os.makedirs(OUT, exist_ok=True)
    errs = []
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
        ctx = await b.new_context(viewport={"width": 1280, "height": 720})
        pg = await ctx.new_page()
        pg.on("pageerror", lambda e: errs.append(str(e)))
        await pg.goto(URL, wait_until="load", timeout=150000)
        await pg.wait_for_timeout(BOOT_MS)
        s = Session(pg)
        await s.shot("title")

        # 1. Into the building. A click anywhere on the title does this as of 2026-09-21
        # (hud.gd _on_splash_input); the Space is the keyboard path, and pressing both
        # proves the second one is not the only one that works.
        await pg.mouse.click(640, 400)
        await pg.wait_for_timeout(BEAT_MS)
        await s.shot("entered")
        await s.key("Space", BEAT_MS)
        await s.shot("lobby")

        # 2. The torch. F is the flashlight; the opening beat hands it over, and a corridor
        # photographed without it is a black rectangle that ops/play_matrix.py will happily
        # count as a stage.
        await s.key("f", 600)
        await s.shot("torch")

        # 3. Walk the corridor, using whatever the sweep finds. Six beats of walk-and-use;
        # the story opens a full-screen VN over the 3D, so most distinct frames come from
        # here rather than from the walking itself.
        for i in range(6):
            await s.hold("w", 1500)
            await s.shot("walk_%d" % (i + 1))
            await s.sweep_and_use()
            await s.shot("use_%d" % (i + 1))
            # A choice is A or B and nothing else advances it; pressing both in order takes
            # whichever branch is offered and is a no-op when no choice is open.
            await s.key("a", 500)
            await s.key("Space", 600)

        # 4. The gallery is the reward screen: plates earned, plates still locked. It is the
        # "reward" step of ops/STANDARD.md item 1 and it is one key away at any time.
        await s.key("g", 1500)
        await s.shot("gallery")
        await s.key("Escape", 900)

        await b.close()
    print("  page errors:", "none" if not errs else errs[:3])
    print("  shots:", s.n)


asyncio.run(main())
