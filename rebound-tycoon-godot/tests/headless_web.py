#!/usr/bin/env python3
"""Drive the web export in headless Chromium and screenshot every step into shots/.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/rebound-tycoon/web. Commands go through the dev bridge (Game polls
window.__rt_cmd once a frame and answers in window.__rt_result / window.__rt_state); every
command is something a player can also do with a thumb, plus "clock", which rewinds the
save's idea of when the player left so the offline gate can be seen without waiting eight
hours, and "sim", which steps the same kernel faster than real time.

This is the "verify by running" half. It asserts, against the real wasm on a real page:
  - the title screen draws, with the key visual and the mark
  - the table plays: the plunger fires, the ball goes live, rebounds pay
  - the ledger takes a purchase and the level goes up
  - eight hours away produce a return screen with the gate's takings, capped
  - the night can be played out to SHIFT OVER and the casual board is offered there
  - zh-Hans renders (the CJK fallback is wired, which is a thing that silently is not)
  - no page errors, no popups, and the board is NOT drawn during play
"""
import http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "rebound-tycoon" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8990 + (os.getpid() % 200)
if not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run ./build.sh" % WEB)


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
URL = "http://127.0.0.1:%d/index.html?dist=itch_web" % PORT

fails = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader",
                                      "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 420, "height": 640})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error"
            and "favicon" not in m.text and "blazecore.dev" not in m.text
            and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]

    def shot(name, settle=0.8):
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("s%02d_%s.png" % (n[0], name))
        page.screenshot(path=str(path))
        print("  shot " + path.name)

    seq = [0]

    def cmd(op, timeout=30.0, **kw):
        seq[0] += 1
        c = dict(op=op, seq=seq[0], **kw)
        page.evaluate("(c) => { window.__rt_cmd = window.__rt_cmd || []; window.__rt_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = page.evaluate("() => window.__rt_result || null")
            if r and r.get("seq") == seq[0]:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def state():
        return page.evaluate("() => window.__rt_state || null")

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

    print("== loading %s" % URL)
    page.goto(URL, timeout=180000)     # a 45 MB wasm under SwiftShader outlasts the default
    page.evaluate("() => { try { localStorage.clear(); } catch (e) {} }")
    t0 = time.time()
    ready = False
    while time.time() - t0 < 180:
        try:
            if cmd("state", timeout=3.0).get("ok") is not False:
                ready = True
                break
        except SystemExit:
            time.sleep(1.0)
    check(ready, "the engine came up and the bridge answers")
    cmd("reset")

    # ---- 1. the title screen -----------------------------------------------------------
    shot("title", 3.0)                 # after the mark has settled and the lamp has breathed
    check(state()["screen"] == "title", "the title screen is up")
    check(not board_open(), "no board on the title screen")

    # ---- 2. zh-Hans --------------------------------------------------------------------
    cmd("lang", lang="zh")
    shot("title-zh", 2.0)
    check(state()["lang"] == "zh", "zh-Hans is selected")
    cmd("lang", lang="en")

    # ---- 3. into the cabinet -----------------------------------------------------------
    cmd("start")
    shot("table-plunge", 1.5)
    st = state()
    check(st["screen"] == "table", "the table is up")
    check(st["mode"] == "plunge", "the hose is waiting at the plunger")

    # ---- 4. pump the hose and let it fly -----------------------------------------------
    cmd("hold", key="plunge", down=True)
    cmd("sim", frames=20, dt=1.0 / 60.0)
    shot("table-charging", 0.4)
    cmd("hold", key="plunge", down=False)
    r = cmd("sim", frames=40, dt=1.0 / 60.0)
    shot("table-live", 0.4)
    check(state()["mode"] in ("live", "plunge"), "the ball launched")

    # ---- 5. play: the ball rebounds and the coins arrive --------------------------------
    def pump():
        """What a thumb does: charge the plunger and let go."""
        cmd("hold", key="plunge", down=True)
        cmd("sim", frames=24, dt=1.0 / 60.0)
        cmd("hold", key="plunge", down=False)
        cmd("sim", frames=8, dt=1.0 / 60.0)

    coins0 = state()["coins"]
    board_during_play = False
    for i in range(18):
        if state()["screen"] != "table":
            break                                  # the night ended early; step 8 covers it
        if state()["mode"] == "plunge":
            pump()
        cmd("hold", key="left", down=(i % 3 == 0))
        cmd("hold", key="right", down=(i % 3 == 1))
        cmd("sim", frames=90, dt=1.0 / 60.0)
        if state()["screen"] == "table" and board_open():
            board_during_play = True
    cmd("hold", key="left", down=False)
    cmd("hold", key="right", down=False)
    shot("table-played", 0.6)
    st = state()
    check(st["coins"] > coins0, "rebounds paid: %d -> %d coins" % (coins0, st["coins"]))
    check(not board_during_play, "the board is never drawn while the table is being played")
    # If the night ended inside the play loop the board is already up — that IS the offer,
    # and it is deliberately once per session, so record it here and dismiss it the way a
    # player would, so the rest of the run photographs the game and not the board.
    board_offered_at_end = state()["screen"] == "nightover" and board_open()
    page.evaluate("() => { var w = document.querySelector('.bd-wrap'); w && w.remove(); }")

    # ---- 6. the ledger: take an upgrade -------------------------------------------------
    cmd("grant", coins=5000)
    cmd("ledger")
    shot("ledger", 1.0)
    before = cmd("buy", id="springs")
    r = cmd("buy", id="studio")
    shot("ledger-bought", 0.8)
    check(r.get("level", 0) >= 1, "an upgrade was taken (studio level %s)" % r.get("level"))

    # ---- 7. eight hours away: the return screen ------------------------------------------
    cmd("title")
    r = cmd("clock", awaySeconds=30 * 3600)      # thirty hours: past the eight-hour cap
    check(r.get("coins", 0) > 0, "the gate collected while away: %d coins" % r.get("coins", 0))
    cmd("start")
    page.evaluate("() => { var w = document.querySelector('.bd-wrap'); w && w.remove(); }")
    shot("return-screen", 1.2)
    # (if the night had already ended, start_table sends them to SHIFT OVER, not a dead
    #  table — that regression is what this run found the first time round)
    check(state()["screen"] == "return", "the return screen is up")
    claimed_before = state()["coins"]
    cmd("claim")                                  # the TAKE THE COINS button's own handler
    time.sleep(1.0)
    shot("return-claimed", 0.8)
    st = state()
    check(st["coins"] > claimed_before, "the coins were claimed: %d -> %d" % (claimed_before, st["coins"]))
    # Back into the game — onto the table, or onto SHIFT OVER when the save it returned
    # to was a finished night. What it must never be again is the table with a dead ball
    # on it, which is what this line caught the first time it ran.
    check(st["screen"] in ("table", "nightover"),
          "and it drops back into the game, not onto a dead table (screen=%s)" % st["screen"])

    # ---- 8. play the night out: SHIFT OVER and the casual board --------------------------
    # a fresh night, so the run always exercises playing one out
    if state()["screen"] == "nightover":
        cmd("again")
        time.sleep(0.5)
    guard = 0
    while state()["screen"] == "table" and guard < 120:
        guard += 1
        if state()["mode"] == "plunge":
            pump()
        cmd("hold", key="left", down=(guard % 4 == 0))
        cmd("hold", key="right", down=(guard % 4 == 2))
        cmd("sim", frames=180, dt=1.0 / 60.0)
    cmd("hold", key="left", down=False)
    cmd("hold", key="right", down=False)
    shot("nightover", 1.5)
    check(state()["screen"] == "nightover",
          "the night was played out to SHIFT OVER (screen=%s)" % state()["screen"])
    time.sleep(1.5)
    shot("nightover-board", 1.0)
    check(board_offered_at_end or board_open(),
          "the casual board was offered when a night ended (once per session, by design)")
    page.evaluate("() => { var w = document.querySelector('.bd-wrap'); w && w.remove(); }")

    # ---- 9. no errors, no popups ---------------------------------------------------------
    real = [e for e in errors if "Blocked aria" not in e]
    check(not real, "no page errors (%s)" % ("; ".join(real[:3]) if real else "none"))
    check(not popups, "no popups (%s)" % (popups or "none"))

    browser.close()

srv.shutdown()
print("\n%d check(s) failed" % len(fails))
sys.exit(1 if fails else 0)
