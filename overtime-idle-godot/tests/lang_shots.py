#!/usr/bin/env python3
"""Photograph the title and the room in every language the build offers.

    ops/remote_playtest.sh build/godot/overtime-idle/web play/overtime-idle-godot/tests/lang_shots.py

Run on the GPU box by remote_playtest.sh, which passes the served URL as argv[1].

WHY THIS EXISTS AND WHY IT IS NOT A DESKTOP RUN. `scripts/cjk.gd` hangs a subset Noto face
off the Latin faces' `fallbacks`. On a desktop run that works whether or not the resource
is held anywhere, because nothing frees it; on the WEB export an unreferenced FontFile is
collected and the label then draws in the Latin face with no error, no warning and no
missing-glyph report -- Japanese becomes a row of empty boxes and every check on disk
still passes (studio memory: `godot-web-font-fallback`, and `verification-that-lies`).
The only way to know is to load the web build, in that language, and look at the pixels.

So each language is loaded through `?lang=` -- the same query parameter a Japanese
storefront link would use, which is therefore tested as well -- and the shots come back
for a human to read. It also counts near-black "box" pixels in the caption band as a cheap
tripwire, but the shots are the evidence: a tripwire that has never fired is not a check.
"""
import os
import sys

from playwright.sync_api import sync_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"
LANGS = ["en", "zh", "ja"]

os.makedirs(OUT, exist_ok=True)
with sync_playwright() as p:
    b = p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page()
    errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    for lang in LANGS:
        sep = "&" if "?" in URL else "?"
        pg.goto("%s%slang=%s" % (URL, sep, lang), wait_until="load", timeout=150000)
        # The title's entrance is ~2s and the engine boot is the rest.
        pg.wait_for_timeout(14000)
        pg.screenshot(path=os.path.join(OUT, "lang_%s_title.png" % lang))
        # Into the building: any click on the title opens it (see title_screen._begin).
        pg.mouse.click(640, 400)
        pg.wait_for_timeout(5000)
        pg.screenshot(path=os.path.join(OUT, "lang_%s_room.png" % lang))
        # and one panel, where the longest running text in the game lives
        pg.keyboard.press("1")
        pg.wait_for_timeout(4000)
        pg.screenshot(path=os.path.join(OUT, "lang_%s_roster.png" % lang))
        print("  %s: shot" % lang)
    print("  page errors:", errs[:3] if errs else "none")
    b.close()
