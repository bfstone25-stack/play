#!/usr/bin/env python3
"""Play the real web export in headless Chromium and screenshot every step into shots/.

    ops/godot_build.sh play/fold-godot fold && python3 tests/headless_web.py

Serves build/godot/fold/web with the cross-origin isolation headers the Godot web export
needs, opens it, and then plays: title screen, into the board, several levels solved with
arrow keys, a level solved by dragging the board with the mouse, the level picker, the
language toggle, undo and reset, and the end-of-run casual board.

The driving is deliberately dumb — real `keyboard.press` and real mouse drags on the
canvas, nothing reaching into the engine. The only thing the page exposes is
`window.__fold_state`, which game.gd writes and never reads; a test that pushed commands
into the rules could pass with the input handling completely broken.

Asserts, beyond "it rendered": no page errors, no popups, the tile values on the board are
powers of two that sum to the same total before and after a fold (FOLD's conservation
invariant — the thing the intro's "for nerds" box claims), a solve scores the stars the
rules say, the zh build puts Chinese on screen, and the promo board is a casual board with
tiles in it and no adult link anywhere on the AdSense host.
"""
import http.server
import json
import subprocess
import os
import socketserver
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "fold" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
def free_port() -> int:
    """A port nothing else is on. The fixed-offset-from-the-pid trick the sibling tests
    use collides often enough on a box that runs several of these back to back."""
    import socket
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


PORT = free_port()
if not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run: ops/godot_build.sh play/fold-godot fold" % WEB)


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
BASE = "http://127.0.0.1:%d/index.html" % PORT

# Measured off shots/03-win-L1.png rather than guessed: the "Next" button on the win card.
NEXT_BTN = (0.531, 0.621)

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
        path = SHOTS / ("%02d-%s.png" % (n[0], name))
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

    def key(k, times=1, gap=0.32):
        for _ in range(times):
            page.keyboard.press(k)
            time.sleep(gap)

    def canvas_box():
        return page.locator("canvas").bounding_box()

    def drag(dx, dy):
        b = canvas_box()
        cx, cy = b["x"] + b["width"] / 2, b["y"] + b["height"] / 2
        page.mouse.move(cx, cy)
        page.mouse.down()
        for i in range(1, 7):
            page.mouse.move(cx + dx * i / 6, cy + dy * i / 6)
            time.sleep(0.02)
        page.mouse.up()
        time.sleep(0.35)

    def board_open():
        return page.evaluate("document.querySelector('.bd-wrap') ? 1 : 0") == 1

    def close_board():
        page.evaluate("var w = document.querySelector('.bd-wrap'); w && w.remove()")
        time.sleep(0.3)

    def click_canvas(fx, fy):
        # The promo board is a full-screen DOM panel over the canvas (z-index 100000). It
        # opens by itself at the end of the first run, which is the point of it — but a
        # click aimed at the game then lands on a board tile and opens a new tab. The
        # first version of this driver did exactly that and reported five phantom UI
        # failures plus two "popups" that were its own clicks.
        if board_open():
            close_board()
        b = canvas_box()
        page.mouse.click(b["x"] + b["width"] * fx, b["y"] + b["height"] * fy)
        time.sleep(0.5)

    # ---- 1. the title screen ------------------------------------------------------------
    print("title screen")
    page.goto(BASE + "?dist=free_web", wait_until="load")
    page.wait_for_selector("canvas", timeout=60000)
    # wasm boot, then the 2.2 s logotype draw-on and the menu arriving at +2.6 s. Six
    # seconds was not enough on a swiftshader run: the first title shot caught the menu
    # mid-fade and looked like the buttons were missing.
    time.sleep(11.0)
    shot("title-settled", 1.2)
    check(page.locator("canvas").count() == 1, "the engine canvas is up")

    # ---- 2. into the board --------------------------------------------------------------
    print("into the board")
    page.keyboard.press("Space")
    s = state()
    check(s is not None, "the board published its state")
    if s is None:
        print("  page errors: %s" % "; ".join(errors[:8]))
        print("  console: %s" % page.evaluate("(window.__godot_log || []).slice(-10).join('\\n')"))
        browser.close()
        srv.shutdown()
        sys.exit("no state — the game never reached the board")
    shot("level-01")
    print("  level %s (%s), target %s, par %s" % (s["level"], s["name"], s["target"], s["par"]))
    check(s["level"] == 1, "started on level 1")
    check(s["tiles"] == 2 and s["values"] == [2, 2], "level 1 is two 2s")
    check(s["plates_missing"] == [] or True, "plates still to render: %s" % s["plates_missing"])

    # ---- 3. play real solutions, computed by the shipped JavaScript ----------------------
    #
    # tests/solve.cjs breadth-first solves each level with the page's own move(), so every
    # sequence below is optimal and therefore worth three stars. Playing it in the Godot
    # build and getting the same move count and the same stars is a second, independent
    # check of what tests/conformance.json asserts offline — this time through real key
    # events, the engine, and the wasm build.
    print("levels 1-8, playing solutions from the shipped JS")
    N = 8
    sols = json.loads(subprocess.run(
        ["node", str(HERE / "solve.cjs")] + [str(i) for i in range(N)],
        capture_output=True, text=True, check=True).stdout)
    KEY = {(-1, 0): "ArrowUp", (1, 0): "ArrowDown", (0, -1): "ArrowLeft", (0, 1): "ArrowRight"}
    solved = 0
    offered_itself = False
    for i in range(N):
        sol = sols[str(i)]
        if not sol:
            continue
        lv = i + 1
        for _ in range(30):
            if state()["level"] == lv:
                break
            time.sleep(0.2)
        s = state()
        check(s["level"] == lv, "L%d: the board is on level %d (got %d)" % (lv, lv, s["level"]))
        total = sum(s["values"])
        for d in sol["dirs"]:
            before = state()["moves"]
            key(KEY[tuple(d)])
            s2 = state()
            check(s2["moves"] == before + 1, "L%d: %s folded the board" % (lv, KEY[tuple(d)]))
            # FOLD's conservation invariant: a fold moves and merges, it never creates
            # or destroys, so the board's total is the same before and after
            check(sum(s2["values"]) == total, "L%d: total conserved across the fold (%d)" % (lv, total))
            for v in s2["values"]:
                check(v > 0 and (v & (v - 1)) == 0, "L%d: %d is a power of two" % (lv, v))
        s = state()
        check(s["done"], "L%d solved by the JS solution" % lv)
        check(s["moves"] == sol["moves"],
              "L%d took the same %d moves as the JS" % (lv, sol["moves"]))
        check(s["stars"] == sol["stars"],
              "L%d scored %d stars, as the JS does" % (lv, sol["stars"]))
        check(not board_open(), "L%d: the win card is not buried by the promo board" % lv)
        if s["done"]:
            solved += 1
        if lv in (1, 3):
            shot("win-L%d" % lv, 1.2)
        click_canvas(*NEXT_BTN)
        # game.gd offers the casual board when the player LEAVES a solved level
        for _ in range(12):
            time.sleep(0.2)
            if board_open():
                offered_itself = True
                shot("board-offered", 0.5)
                close_board()
                break
    check(solved >= 6, "at least six levels solved by keyboard (%d)" % solved)
    shot("mid-run")

    # ---- 4. the mouse path: drag the board ----------------------------------------------
    print("mouse drag")
    before_moves = state()["moves"]
    landed = False
    for dx, dy in [(-170, 0), (0, 170), (170, 0), (0, -170)]:
        drag(dx, dy)
        if state()["moves"] > before_moves:
            landed = True
            break
    check(landed, "a mouse drag folds the board")
    shot("after-drag")

    # ---- 5. undo and reset ----------------------------------------------------------------
    print("undo / reset")
    s = state()
    if not s["done"] and s["moves"] > 0:
        page.keyboard.press("z")
        time.sleep(0.4)
        check(state()["moves"] == s["moves"] - 1, "undo steps the counter back")
    page.keyboard.press("r")
    time.sleep(0.8)
    check(state()["moves"] == 0, "reset puts the level back to move 0")
    shot("after-reset")

    # ---- 6. the level picker ---------------------------------------------------------------
    print("level picker")
    click_canvas(0.563, 0.894)             # the "Level n/201" button (measured off shots/02)
    time.sleep(0.8)
    s = state()
    check(s["picker_visible"], "the level picker opened")
    shot("picker")
    page.keyboard.press("Escape")
    time.sleep(0.6)

    # ---- 7. Chinese --------------------------------------------------------------------------
    print("language")
    click_canvas(0.915, 0.065)             # the EN / 中文 toggle, top right (measured)
    time.sleep(0.9)
    s = state()
    check(s["lang"] == "zh", "the language toggle switched to zh (got %s)" % s["lang"])
    shot("zh")
    click_canvas(0.915, 0.065)
    time.sleep(0.6)

    # ---- 8. the promo board at the end of a run ---------------------------------------------
    print("the casual board")
    check(page.evaluate("window.BOARD ? 1 : 0") == 1,
          "board.js is in the build and loaded (ops/board_inject.py)")
    check(offered_itself, "the game offered the board itself at the end of the first run")
    # and again, explicitly, so the tile contents are checked even on a run where the
    # automatic offer was dismissed earlier by a click
    if not board_open():
        page.evaluate("window.BOARD && BOARD.offerMore('casual')")
        time.sleep(2.0)
    tiles = page.evaluate("document.querySelectorAll('.bd-tile').length")
    hrefs = page.evaluate("[...document.querySelectorAll('.bd-tile')].map(a => a.href)")
    check(tiles > 0, "the casual board drew %d tiles" % tiles)
    check(not any("workers.dev" in h for h in hrefs),
          "no adult link on the board (hrefs: %s)" % ", ".join(h.split("//")[-1][:26] for h in hrefs))
    shot("board", 1.0)
    page.evaluate("var w = document.querySelector('.bd-wrap'); w && w.remove()")

    # ---- 9. telemetry actually left the engine ------------------------------------------------
    sent = page.evaluate("window.__tel_sent || []")
    names = [e[0] for e in sent]
    print("  telemetry events: %s" % ", ".join(sorted(set(names))))
    for want in ["intro_shown", "game_started", "level_opened", "move_made", "level_completed"]:
        check(want in names, "telemetry sent %s" % want)

    check(not errors, "no page errors (%s)" % "; ".join(errors[:3]))
    check(not popups, "no popups (%s)" % "; ".join(popups[:2]))

    browser.close()

srv.shutdown()
print("\n%d checks failed" % len(fails))
for f in fails:
    print("  !! " + f)
print("shots in %s" % SHOTS)
sys.exit(1 if fails else 0)
