#!/usr/bin/env python3
"""Play FOLD: After Dark's real ad-track web export in headless Chromium, end to end.

    ops/fold_after_dark_build.sh && python3 tests/headless_web.py

Serves build/godot-ads/fold-after-dark (the *.flat404.workers.dev page: DIST=ads_web, the
18+ ad unit config, gate.js, board.js) on 127.0.0.1 — which board.js treats as local QA, so
the adult board may draw — and clicks through the five steps of the brief with real key
events on the canvas and real clicks on the DOM gate:

  1. the night title screen, then the tier map with its locked scene cards
  2. tier 1 played with the shipped JavaScript's optimal solutions (tests/solve.cjs):
     levels auto-advance, the streak climbs
  3. the trophy card -> UNLOCK HER SCENE -> gate.js's sponsor gate (a QA slot: headless
     runs never request a real ad) -> the 30 s clock -> Continue -> the server ticket is
     redeemed against apps.blazecore.dev -> the scene viewer shows the delivered plate
  4. the map again: the card reads UNLOCKED; daily / streak / leaderboard stubs on screen
  5. the adult promo board offered after the viewer closes

Nothing here reaches into the engine: the only thing the page exposes is the read-only
window.__fold_state that game.gd and map.gd publish.
"""
import http.server
import json
import socket
import socketserver
import subprocess
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot-ads" / "fold-after-dark"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()

if not (WEB / "index.html").exists():
    sys.exit("no ad-track build at %s — run: ops/fold_after_dark_build.sh" % WEB)


def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


PORT = free_port()


class Quiet(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(WEB), **k)

    def log_message(self, *a):
        pass


socketserver.TCPServer.allow_reuse_address = True
srv = socketserver.TCPServer(("127.0.0.1", PORT), Quiet)
threading.Thread(target=srv.serve_forever, daemon=True).start()
BASE = "http://127.0.0.1:%d/index.html" % PORT

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
            s = page.evaluate("window.__fold_state || null")
            if s:
                return s
            time.sleep(0.25)
        return None

    def wait_for(pred, timeout=20.0, gap=0.25):
        t0 = time.time()
        while time.time() - t0 < timeout:
            s = state()
            if s and pred(s):
                return s
            time.sleep(gap)
        return state()

    def key(k, times=1, gap=0.22):
        for _ in range(times):
            page.keyboard.press(k)
            time.sleep(gap)

    def board_open():
        return page.evaluate("document.querySelector('.bd-wrap') ? 1 : 0") == 1

    # ---- 1. title, then the map ---------------------------------------------------------
    print("title screen")
    page.goto(BASE, wait_until="load")
    page.wait_for_selector("canvas", timeout=60000)
    time.sleep(11.0)
    shot("title-night", 1.2)
    check(page.locator("canvas").count() == 1, "the engine canvas is up")

    print("tier map")
    key("Space")
    s = wait_for(lambda s: s.get("screen") == "map")
    check(s is not None and s.get("screen") == "map", "Space opened the tier map")
    if s is None:
        print("  page errors: %s" % "; ".join(errors[:8]))
        browser.close(); srv.shutdown(); sys.exit("no state")
    check(s["tiers"] >= 25, "%d tiers cut from the level set" % s["tiers"])
    check(s["unlocked"] == [], "nothing unlocked on a fresh install")
    shot("tier-map-locked", 1.0)

    # ---- 2. play tier 1 -----------------------------------------------------------------
    print("tier 1: five levels, solutions from the shipped JS")
    key("Enter")
    s = wait_for(lambda s: s.get("screen") == "game")
    check(s.get("screen") == "game" and s["level"] == 1, "Enter opened level 1 of tier 1")
    shot("level-01-night")
    sols = json.loads(subprocess.run(
        ["node", str(HERE / "solve.cjs")] + [str(i) for i in range(5)],
        capture_output=True, text=True, check=True).stdout)
    KEY = {(-1, 0): "ArrowUp", (1, 0): "ArrowDown", (0, -1): "ArrowLeft", (0, 1): "ArrowRight"}
    for i in range(5):
        lv = i + 1
        s = wait_for(lambda s, lv=lv: s.get("screen") == "game" and s["level"] == lv and not s["done"])
        check(s["level"] == lv, "L%d: the board is on level %d (got %s)" % (lv, lv, s.get("level")))
        total = sum(s["values"])
        for d in sols[str(i)]["dirs"]:
            before = state()["moves"]
            key(KEY[tuple(d)])
            s2 = state()
            check(s2["moves"] == before + 1, "L%d: %s folded the board" % (lv, KEY[tuple(d)]))
            check(sum(s2["values"]) == total, "L%d: total conserved (%d)" % (lv, total))
        # the solved flag lands a frame or two after the last fold's tween; wait for it
        s = wait_for(lambda s: s["done"], timeout=4.0)
        check(s["done"], "L%d solved" % lv)
        check(s["streak"] == lv, "L%d: streak reads %d" % (lv, lv))
        if lv == 3:
            shot("mid-tier-streak", 0.3)
        if lv < 5:
            s = wait_for(lambda s, lv=lv: s["level"] == lv + 1, timeout=6.0)
            check(s["level"] == lv + 1, "L%d auto-advanced to %d without a card" % (lv, lv + 1))
    s = wait_for(lambda s: s.get("win_visible"), timeout=6.0)
    check(s.get("win_visible") and s.get("tier_last"), "tier 1 cleared: the trophy card is up")
    shot("trophy-tier-1", 1.0)

    # ---- 3. unlock the scene through the gate and the ticket -----------------------------
    print("unlock: the sponsor gate, then the server ticket")
    key("Enter")
    t0 = time.time()
    while time.time() - t0 < 10 and page.locator("[data-tel-ad=gate]").count() == 0:
        time.sleep(0.3)
    check(page.locator("[data-tel-ad=gate]").count() == 1, "gate.js drew the sponsor gate")
    check(page.locator("[data-tel-ad=gate]").inner_text().strip().startswith("Sponsor slot"),
          "headless run got the QA slot, not a live ad")
    shot("sponsor-gate", 0.8)
    cont = page.get_by_role("button", name="Continue")
    t0 = time.time()
    while time.time() - t0 < 45 and cont.is_disabled():
        time.sleep(1.0)
    check(not cont.is_disabled(), "the gate's clock ran down to Continue")
    cont.click()
    # the DOM gate took keyboard focus with it; give it back to the engine's canvas
    page.locator("canvas").focus()
    s = wait_for(lambda s: s.get("scene_visible"), timeout=40.0)
    check(bool(s.get("scene_visible")), "the delivered plate is on screen (server ticket redeemed)")
    shot("scene-unlocked", 1.2)
    check(len(popups) == 0, "no popups (%s)" % popups)

    # ---- 4. back to the map: unlocked card, the stubs ------------------------------------
    print("map after the unlock")
    page.locator("canvas").focus()
    key("Enter")     # Close
    s = wait_for(lambda s: s.get("screen") == "map", timeout=15.0)
    check(s.get("screen") == "map" or not s.get("scene_visible"), "Close left the viewer")
    # the adult board may be offered on the way back (local QA host): note it, close it
    offered = False
    for _ in range(12):
        if board_open():
            offered = True
            shot("promo-board-adult", 0.5)
            tiles = page.evaluate("document.querySelectorAll('.bd-tile').length")
            check(tiles > 0, "the adult board has %d tiles" % tiles)
            page.evaluate("var w = document.querySelector('.bd-wrap'); w && w.remove()")
            break
        time.sleep(0.25)
    s = state()
    check(s.get("screen") == "map", "back on the map")
    check("r704_bed" in s.get("unlocked", []), "tier 1's scene reads UNLOCKED on the map")
    check(s.get("daily", 0) >= 3, "daily mission stub counted today's clears (%s)" % s.get("daily"))
    shot("tier-map-unlocked", 1.0)

    # ---- 5. the promo board on the adult host -------------------------------------------
    print("promo board")
    check(offered, "the adult promo board was offered after the scene closed")

    check(not errors, "no page errors (%s)" % "; ".join(errors[:4]))
    try:
        browser.close()
    except Exception:
        pass

srv.shutdown()
print("\n%d checks failed" % len(fails) if fails else "\nALL OK")
for f in fails:
    print("  - " + f)
sys.exit(1 if fails else 0)
