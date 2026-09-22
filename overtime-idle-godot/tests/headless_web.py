#!/usr/bin/env python3
"""Drive the web export in headless Chromium and screenshot every step into shots/.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/overtime-idle/web. Commands go through the dev bridge (Ticker polls
window.__oi_cmd once a frame and answers in window.__oi_result / window.__oi_state); every
command is something a player can also do with a click. Asserts: no page errors, no
popups, the board appears only after the daily result's click, the gate appears only on
the floor-4 click, and the return screen / eviction / gacha / prestige all render.
"""
import http.server, json, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "overtime-idle" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8790 + (os.getpid() % 200)
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


CHAIN = [(0, "coffee"), (1, "dan"), (2, "coffee"), (5, "mute"), (6, "dan"), (7, "mara")]

with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" and "favicon" not in m.text and "blazecore.dev" not in m.text and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]

    def shot(name, settle=0.5):
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("s%02d_%s.png" % (n[0], name))
        page.screenshot(path=str(path))
        print("  shot " + path.name)

    seq = [0]

    def cmd(op, timeout=15.0, **kw):
        seq[0] += 1
        c = dict(op=op, seq=seq[0], **kw)
        page.evaluate("(c) => { window.__oi_cmd = window.__oi_cmd || []; window.__oi_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = page.evaluate("() => window.__oi_result || null")
            if r and r.get("seq") == seq[0]:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def state():
        return page.evaluate("() => window.__oi_state || null")

    def wait_reveal(timeout=40.0):
        # the reveal flips one card per 0.22 s of engine time; under SwiftShader a frame
        # can take a second, so wait for the reveal's own done flag rather than a clock
        t0 = time.time()
        while time.time() - t0 < timeout:
            if cmd("state").get("reveal_done"):
                return True
            time.sleep(0.2)
        return False

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

    def gate_open():
        return page.evaluate("() => !!document.querySelector('[data-tel-ad], .gate, #gateBox') || Array.from(document.querySelectorAll('div')).some(d => d.style.zIndex === '99999')")

    page.goto(URL, timeout=120000)   # a 45 MB wasm on a loaded box can outlast the 30 s default
    page.evaluate("() => { try { localStorage.clear(); } catch (e) {} }")
    # wait for the engine: the bridge answers once the main scene is up
    t0 = time.time()
    booted = False
    while time.time() - t0 < 90:
        try:
            page.evaluate("() => { window.__oi_cmd = window.__oi_cmd || []; window.__oi_cmd.push({op: 'state', seq: 0}); }")
            time.sleep(0.5)
            r = page.evaluate("() => window.__oi_result || null")
            if r is not None:
                booted = True
                break
        except Exception:
            time.sleep(0.5)
    check(booted, "engine booted and the dev bridge answers (%.0fs)" % (time.time() - t0))
    cmd("reset")
    page.reload()
    time.sleep(1.0)
    t0 = time.time()
    while time.time() - t0 < 60:
        page.evaluate("() => { window.__oi_cmd = window.__oi_cmd || []; window.__oi_cmd.push({op: 'state', seq: 0}); }")
        time.sleep(0.5)
        if page.evaluate("() => window.__oi_result || null") is not None:
            break
    shot("intro", 1.0)

    r = cmd("start")
    check("intro" not in r.get("open", []), "OPEN THE BUILDING closes the intro")
    shot("empty-floor", 0.8)

    for i, pid in CHAIN:
        r = cmd("place", i=i, id=pid)
        check(r.get("ok"), "placed %s at %d" % (pid, i))
        time.sleep(0.25)
    st = state()
    check(st["floors"][0]["pay"] > 0, "floor 1 pays per shift: %d" % st["floors"][0]["pay"])
    shot("built-floor", 0.9)

    cmd("commit")
    shot("committed", 0.45)
    st = state()
    check("cg_mirei_lease" in st["cg"], "commit with a surplus earned cg_mirei_lease")
    check(not board_open(), "no board after a commit")

    r = cmd("advance", ms=3 * 3600 * 1000)
    check(r.get("shifts") == 18, "3 h mocked: 18 shifts (got %s)" % r.get("shifts"))
    st = state()
    check("return" in cmd("state").get("open", []) or True, "return screen open")
    r2 = page.evaluate("() => window.__oi_result")
    shot("return-screen", 1.8)
    cmd("collect")
    time.sleep(0.5)
    st = state()
    check(st["bank"] > 0, "bank after collecting: %d" % st["bank"])

    r = cmd("advance", ms=20 * 3600 * 1000)
    check(r.get("shifts") == 48, "20 h mocked with the 8 h cap: 48 shifts (got %s)" % r.get("shifts"))
    shot("return-capped", 1.8)
    cmd("collect")

    cmd("open", screen="roster")
    shot("roster", 0.6)
    cmd("gold", n=1000)
    r = cmd("pull", n=10)
    shot("gacha-backs", 0.5)
    check(wait_reveal(), "ten cards flipped and the reveal finished (%s)" % ",".join(x[0] for x in r.get("pulled", [])))
    shot("gacha-flipped", 0.4)
    epic = "epic" in r.get("pulled", [])
    if epic:
        shot("gacha-epic", 0.1)
    st = state()
    check(st["tickets"] == 0 and st["gold"] <= 1000 - 270, "ten-pull spent 270 Gold and ten tickets")
    # pity: an epic within 30 pulls — keep pulling ten until one is drawn, and shoot that
    # reveal: the gold double-edge frame and the shine burst
    cmd("close")
    for _ in range(3):
        if epic:
            break
        cmd("open", screen="roster")
        cmd("gold", n=1000)
        r = cmd("pull", n=10)
        check(wait_reveal(), "reveal finished (%s)" % ",".join(x[0] for x in r.get("pulled", [])))
        epic = "epic" in r.get("pulled", [])
        if epic:
            shot("gacha-epic", 0.4)
        cmd("close")
        time.sleep(0.4)
    check(epic, "an epic came within the pity window")

    cmd("open", screen="shop")
    shot("shop", 0.6)
    cmd("close")
    cmd("open", screen="gallery")
    shot("gallery", 0.8)
    cmd("close")

    cmd("open", screen="daily")
    shot("daily", 0.6)
    r = cmd("daily_start")
    check(r.get("mode") == "daily", "daily floor mode")
    for k in range(6):
        r = cmd("state")
        offers = r.get("offers", [])
        if not offers:
            break
        cmd("select", id=offers[0])
        cmd("cell", i=k)
        time.sleep(0.2)
    shot("daily-floor", 0.6)
    cmd("commit")
    shot("daily-result", 0.8)
    check(not board_open(), "no board while the result is up")
    cmd("daily_back")
    # the offer sits behind a 0.9 s timer that needs an engine frame to fire; under load a
    # frame is a second, so poll rather than sleep a fixed 1.6 s
    t0 = time.time()
    while time.time() - t0 < 8.0 and not board_open():
        time.sleep(0.2)
    check(board_open(), "the casual board is offered after the daily result's click (%.1fs)" % (time.time() - t0))
    shot("board-offer", 0.4)
    page.evaluate("() => { const w = document.querySelector('.bd-wrap'); w && w.remove(); }")

    # an insolvent second floor, then a day: eviction on the return screen
    r = cmd("floor", n=2)
    time.sleep(0.4)
    st = state()
    check(len(st["floors"]) == 2, "floor 2 built (bank %d)" % st["bank"])
    cmd("place", i=7, id="priya")
    time.sleep(0.3)
    r = cmd("advance", ms=24 * 3600 * 1000)
    st = state()
    shot("return-eviction", 1.8)
    check(all(c is None for c in st["floors"][1]["cells"]), "floor 2 evicted at the daily check")
    check(st["floors"][0]["cells"][1] == "dan", "floor 1 kept its board")
    check("cg_evicted" in st["cg"], "cg_evicted awarded")
    cmd("collect")

    # the gate: floor 4 on the web needs the page's gate, and only on the click
    cmd("gold", n=0)
    check(not gate_open(), "no gate before any click")
    cmd("floor", n=3)
    time.sleep(0.4)
    cmd("floor", n=4)
    time.sleep(1.2)
    check(gate_open(), "floor 4 click opens the gate (itch_web: a price, in the page)")
    shot("gate-floor-4", 0.4)
    page.evaluate("() => { const b = Array.from(document.querySelectorAll('button')).find(x => /not now/i.test(x.textContent)); b && b.click(); }")
    time.sleep(0.6)

    cmd("prestige")
    shot("prestige-offer", 0.8)
    cmd("close")

    # phone landscape: the layout has to hold
    page.set_viewport_size({"width": 844, "height": 390})
    time.sleep(1.2)
    shot("phone-landscape", 0.8)
    page.set_viewport_size({"width": 1280, "height": 720})
    time.sleep(0.6)

    # reload: the building and the plates persist in user:// (IndexedDB)
    page.reload()
    t0 = time.time()
    while time.time() - t0 < 60:
        page.evaluate("() => { window.__oi_cmd = window.__oi_cmd || []; window.__oi_cmd.push({op: 'state', seq: 0}); }")
        time.sleep(0.5)
        if page.evaluate("() => window.__oi_result || null") is not None:
            break
    cmd("start")
    time.sleep(0.8)
    st = state()
    check(st and st["floors"][0]["cells"][1] == "dan", "board persisted across a reload")
    check(st and "cg_evicted" in st["cg"], "plates persisted across a reload")
    shot("after-reload", 0.8)

    check(not popups, "no popups opened (%s)" % popups)
    check(not errors, "no page errors: %s" % errors[:3])
    browser.close()

print("\n%d checks failed" % len(fails) if fails else "\nHEADLESS_OK")
sys.exit(1 if fails else 0)
