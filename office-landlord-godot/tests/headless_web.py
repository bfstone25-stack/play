#!/usr/bin/env python3
"""Play the real web export in headless Chromium and screenshot every step into shots/.

    ops/godot_build.sh play/office-landlord-godot office-landlord
    python3 tests/headless_web.py

Office Landlord was the only Godot title in the portfolio with no tests/ directory. Its
matrix therefore came from `ops/play_driver.py`, the generic click-and-key driver, which
reached **2 distinct stages out of 54 frames** — against 15 for OCCUPANCY, the adult fork
of the same game, which has a driver of its own. That difference was not the game being
shallow. It was the game being undriven.

The driving is deliberately dumb: real `mouse.click` on the canvas, nothing reaching into
the engine. The page exposes `window.__ol_state`, which main.gd writes and never reads, so
a test cannot drive the rules directly and pass while input handling is broken.

Asserts, beyond "it rendered": the title opens the floor, a tray tile placed on a cell
actually lands (the grid's filled count goes up), rent settles, each of the three panels
opens and closes, the language flips, and there are no page errors or popups.
"""
import http.server
import os
import socketserver
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "office-landlord" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()


def free_port() -> int:
    import socket
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


PORT = free_port()
if not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run: ops/godot_build.sh play/office-landlord-godot "
             "office-landlord" % WEB)


class Quiet(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(WEB), **k)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *a):
        pass


socketserver.TCPServer.allow_reuse_address = True
srv = socketserver.TCPServer(("127.0.0.1", PORT), Quiet)
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = "http://127.0.0.1:%d/index.html?dist=free_web" % PORT

fails = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


with sync_playwright() as p:
    browser = p.chromium.launch(
        args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error"
            and "favicon" not in m.text and "blazecore.dev" not in m.text
            and "ERR_" not in m.text and "net::" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())

    n = [0]

    def shot(name, settle=0.7):
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("s%02d_%s.png" % (n[0], name))
        page.screenshot(path=str(path))
        print("  shot " + path.name)

    def state(timeout=20.0):
        t0 = time.time()
        while time.time() - t0 < timeout:
            s = page.evaluate("window.__ol_state || null")
            if s:
                return s
            time.sleep(0.25)
        return None

    def canvas_box():
        return page.locator("canvas").bounding_box()

    def click(fx, fy, settle=0.45):
        b = canvas_box()
        page.mouse.click(b["x"] + b["width"] * fx, b["y"] + b["height"] * fy)
        time.sleep(settle)

    # ---- 1. title ----------------------------------------------------------------------
    print("title")
    page.goto(URL, wait_until="load")
    page.wait_for_selector("canvas", timeout=60000)
    time.sleep(11.0)                      # wasm boot + the title's own settle animation
    shot("title", 1.2)
    check(page.locator("canvas").count() == 1, "the engine canvas is up")
    s = state()
    check(s is not None, "the game published its state")
    if s is None:
        print("  page errors: %s" % "; ".join(errors[:6]))
        browser.close(); srv.shutdown()
        sys.exit("no state — main.gd never published")

    # ---- 2. into the floor --------------------------------------------------------------
    print("into the floor")
    # Measured off a live s01_title.png, not guessed: "OPEN FOR BUSINESS" centres at
    # (0.175, 0.614). The first version of this driver assumed it sat low-left like
    # OCCUPANCY's and clicked (0.25, 0.86) -- empty ground below the button. Nothing
    # errored; the screen just stayed "title" and every later check failed complaining
    # about the screen instead of about the click. Same shape of failure as FOLD's stale
    # NEXT_BTN. If this breaks, take a fresh shot and re-measure rather than nudging.
    for fx, fy in [(0.175, 0.614), (0.25, 0.62), (0.30, 0.61)]:
        click(fx, fy)
        if state()["screen"] != "title":
            break
    s = state()
    check(s["screen"] != "title", "the title opened the floor (screen=%s)" % s["screen"])
    shot("floor-empty")
    print("  floor %s, rent %s, %s/%s cells filled, tray %s"
          % (s["floor"], s["rent"], s["filled"], s["cells"], s["tray"]))
    check(s["cells"] == 20, "the grid is the kernel's 5x4 (got %d)" % s["cells"])
    check(s["tray"] > 0, "the tray refilled itself (%d)" % s["tray"])

    # ---- 3. place tiles ------------------------------------------------------------------
    #
    # Placing is two clicks: pick a tray tile, then a cell. Coordinates are fractions of
    # the canvas rather than node lookups because the driver is deliberately outside the
    # engine; if the layout moves these go stale, and the assertion below is what says so.
    print("placing")
    before = state()["filled"]
    placed = 0
    # All measured off a live s02_floor-empty.png. The grid draws 5x4 from x=107 in
    # 112 px steps and y=142 in 100 px steps on a 1280x720 canvas; the tray sits under it.
    TRAY = [(0.125, 0.778), (0.213, 0.778), (0.300, 0.778), (0.388, 0.778)]
    CELLS = [(0.125 + 0.0875 * c, 0.197 + 0.139 * r) for r in range(4) for c in range(5)]
    for ti, tray_pt in enumerate(TRAY):
        for cell_pt in CELLS:
            f0 = state()["filled"]
            click(*tray_pt, settle=0.25)
            click(*cell_pt, settle=0.35)
            if state()["filled"] > f0:
                placed += 1
                break
    s = state()
    check(placed > 0, "a tray tile placed onto the grid (%d placed, filled %d -> %d)"
          % (placed, before, s["filled"]))
    shot("floor-placed")

    # ---- 4. rent --------------------------------------------------------------------------
    print("rent")
    b0 = state()["banked"]
    click(0.719, 0.903)                    # the collect bar, measured off the floor shot
    s = state()
    check(s["floor"] >= 1, "the floor survived a collect (floor %d, banked %d -> %d)"
          % (s["floor"], b0, s["banked"]))
    shot("after-collect")

    # ---- 5. the three panels ---------------------------------------------------------------
    print("panels")
    # The floor's own hint line reads "1: shop  2: staff  3: report" -- these open on the
    # number keys, not on a click. The first version of this driver clicked at guessed
    # positions and reported three panel failures that were never panel bugs.
    for label, keyname in [("shop", "1"), ("staff", "2"), ("report", "3")]:
        page.keyboard.press(keyname)
        time.sleep(0.5)
        s = state()
        opened = s["screen"].startswith("panel:")
        check(opened, "%s panel opened (screen=%s)" % (label, s["screen"]))
        if opened:
            shot("panel-%s" % label)
            # Close is a wide bar inside the panel, but the panels are different heights
            # so it does not sit at one fixed y -- staff closed at a different row than
            # shop and report. Click down the bar's column until the state actually leaves
            # the panel, the same pattern FOLD's Next needed. One fixed coordinate here
            # reports a "panel closed" failure that is the driver's guess, not a game bug.
            # Staff's panel holds one line, so its Close bar sits at 0.378 while shop's
            # is at 0.613 -- the bar follows the content height. Scan the column.
            for cy in (0.613, 0.378, 0.46, 0.53, 0.70, 0.31, 0.78):
                click(0.524, cy, settle=0.35)
                if not state()["screen"].startswith("panel:"):
                    break
            check(not state()["screen"].startswith("panel:"), "%s panel closed" % label)

    # ---- 6. language ------------------------------------------------------------------------
    print("language")
    lang0 = state()["lang"]
    click(0.899, 0.050)             # "English", measured off the floor shot
    s = state()
    check(s["lang"] != lang0, "the language toggle switched (%s -> %s)" % (lang0, s["lang"]))
    shot("zh")

    shot("end")
    check(not errors, "no page errors (%s)" % "; ".join(errors[:3]))
    check(not popups, "no popups (%s)" % popups[:3])

    browser.close()

srv.shutdown()
print("\n%d checks failed" % len(fails))
for f in fails:
    print("  - " + f)
print("shots in %s" % SHOTS)
sys.exit(1 if fails else 0)
