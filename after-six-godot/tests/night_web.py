#!/usr/bin/env python3
"""Play After Six's five prototype steps in headless Chromium against the real ads-track
build and screenshot each beat into shots/.

    ./build.sh && python3 tests/night_web.py [--itch]

Serves build/godot-ads/after-six (the ads page: DIST=ads_web, the 18+ unit, the fixed
CG gate) — or the itch page with --itch. Real mouse clicks wherever the canvas position is
known (the title button, the map rooms, the offer's buttons); the dev bridge
(window.__bm_cmd, the same commands a thumb makes) for the turn-by-turn play.

The five steps (the task of 2026-09-19):
  1. the night map — the same cells relit, who is still in the building on the map
  2. the thinking node — her desk (triage) -> the confrontation (review) -> the return (CG)
  3. the reflex node — the security round on the survivor-like arena
  4. the offer scene — refuse, and she comes back on her own
  5. the clear state and the adult board
Asserts: no page errors; the gate really gates (no creative on localhost => the plate
stays censored); the board draws on 127.0.0.1 (an adult host for board.js).
"""
import http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
ROOT = PROJ.parent.parent
ITCH = "--itch" in sys.argv
WEB = ROOT / "build" / ("godot/after-six/web" if ITCH else "godot-ads/after-six")
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
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
srv = socketserver.TCPServer(("127.0.0.1", 0), Quiet)
PORT = srv.server_address[1]
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = "http://127.0.0.1:%d/index.html" % PORT
fails = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


# BMMap.pos(): x = 40 + fx * 340, y = FLOOR_Y[floor]; the marker root is p + (-42, -92), 84x96
FLOOR_Y = [566.0, 434.0, 302.0, 170.0]
NODE_XY = {"standup": (0.34, 1), "inbox": (0.20, 2), "lobby": (0.5, 0), "review": (0.22, 3)}


def room_xy(node):
    fx, fl = NODE_XY[node]
    return (40 + fx * 340, FLOOR_Y[fl] - 44)


with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 420, "height": 640}, device_scale_factor=2)
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" and "favicon" not in m.text and "blazecore.dev" not in m.text and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]

    def shot(name, settle=0.6):
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("%02d-%s.png" % (n[0], name))
        for attempt in range(2):
            try:
                page.screenshot(path=str(path), timeout=60000)
                break
            except Exception as exc:
                print("  ..   screenshot %s stalled (%s), retrying" % (name, type(exc).__name__))
                cmd("state")
        print("  shot " + path.name)

    seq = [0]

    def cmd(op, timeout=90.0, **kw):
        seq[0] += 1
        c = dict(op=op, seq=seq[0], **kw)
        page.evaluate("(c) => { window.__bm_cmd = window.__bm_cmd || []; window.__bm_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = page.evaluate("() => window.__bm_result || null")
            if r and r.get("seq") == seq[0]:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def boot():
        t0 = time.time()
        while time.time() - t0 < 120:
            try:
                page.evaluate("() => { window.__bm_cmd = window.__bm_cmd || []; window.__bm_cmd.push({op: 'state', seq: 0}); }")
                time.sleep(0.5)
                if page.evaluate("() => window.__bm_result || null") is not None:
                    return time.time() - t0
            except Exception:
                time.sleep(0.5)
        return None

    def wait_screen(names, timeout=20.0):
        t0 = time.time()
        while time.time() - t0 < timeout:
            st = cmd("state")
            if st["screen"] in names and not st["map"]["walking"]:
                return st
            time.sleep(0.15)
        return cmd("state")

    def click(x, y, settle=0.5):
        page.mouse.click(x, y)
        time.sleep(settle)

    def tap_room(node, mid_shot=None):
        """A real tap on a lit window: the character walks there in real time."""
        x, y = room_xy(node)
        click(x, y, 0.3)
        if mid_shot:
            shot(mid_shot, 0.6)
        st = wait_screen(["node", "breakroom", "event", "event_done"], timeout=90.0)
        check(st["map"]["at"] == node, "walked to %s by tapping its window (screen %s)" % (node, st["screen"]))
        return st

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

    def gate_open():
        return page.evaluate("() => !!document.querySelector('[data-tel-ad=\"gate\"]')")

    print("== boot", "itch page" if ITCH else "ads page (DIST=ads_web)")
    page.goto(URL)
    t = boot()
    check(t is not None, "engine booted (%.1fs)" % (t or 0))
    check(page.evaluate("() => window.DIST || ''") == ("itch_web" if ITCH else "ads_web"), "the page is the %s track" % ("itch" if ITCH else "ads"))
    check(page.evaluate("() => !!window.AfterSixGate"), "aftersix_gate.js is on the page")
    check(page.evaluate("() => typeof window.AD_HTML === 'string' && window.AD_HTML.indexOf('highrevenueformat') >= 0") or ITCH, "the 18+ Adsterra unit is the page's AD_HTML")
    cmd("reset")
    cmd("lang", code="en")
    shot("title", 1.2)

    # ---- 1. the night map ------------------------------------------------------------
    print("== 1. the night map")
    click(210, 365, 0.8)          # STAY LATE: the Primary in the title's second panel
    st = wait_screen(["map"], 8)
    if st["screen"] != "map":
        cmd("open", screen="map")
        st = wait_screen(["map"], 5)
        check(False, "the title's STAY LATE button took a real click at (210,365)")
    else:
        check(True, "the title's STAY LATE button took a real click")
    states = st["map"]["states"]
    check(states["standup"] == "open" and states["inbox"] == "locked", "fresh night: the guard's round is lit, her desk is dark (%s)" % states)
    shot("night-map", 1.0)

    # ---- 3. the reflex node: the security round ---------------------------------------
    print("== 3. the security round (reflex)")
    st = tap_room("standup", mid_shot="night-walk")
    shot("round-brief", 0.5)
    attempts = 0
    while attempts < 10:
        attempts += 1
        st = cmd("enter", id="standup") if attempts == 1 else cmd("go")
        time.sleep(0.4)
        cmd("auto", on=True)
        cmd("simulate", seconds=6)
        if attempts == 1:
            shot("round-arena", 0.4)
        for _ in range(60):
            st = cmd("state")
            if st["screen"] == "lvup":
                cmd("pick", id=st["lvl"][0])
                st = cmd("simulate", seconds=8)
            elif st["screen"] == "result":
                break
            else:
                st = cmd("simulate", seconds=8)
        won = st["map"]["states"]["standup"] == "cleared"
        if won:
            break
        shot("round-lost-%d" % attempts, 0.3)
    check(won, "the security round survived on attempt %d" % attempts)
    shot("round-result", 0.6)
    cmd("go")
    st = wait_screen(["map"], 5)
    check(st["map"]["states"]["inbox"] == "open", "her desk is lit now: the case opens (%s)" % st["map"]["states"]["inbox"])
    shot("night-map-2", 0.8)

    # ---- 2. the thinking node: her desk -> the confrontation ------------------------
    print("== 2. the case (thinking)")
    st = tap_room("inbox")
    shot("case-brief", 0.5)
    tries = 0
    while tries < 8:
        tries += 1
        st = cmd("enter", id="inbox")
        if tries == 1:
            shot("desk-triage", 0.6)
        for _ in range(14):
            st = cmd("tri_auto")
            if st["screen"] != "triage":
                break
        if st["screen"] == "leverage":
            break
        cmd("go")   # try again
    check(st["screen"] == "leverage", "the leverage assembled on desk %d (screen %s)" % (tries, st["screen"]))
    shot("leverage", 0.6)
    cmd("go")
    st = wait_screen(["review"], 5)
    check(st["screen"] == "review" and st["review"]["scenario"] == "raise", "the confrontation opens on the engine's RULES row (%s)" % st.get("review", {}).get("scenario"))
    shot("confront-open", 0.6)
    for _ in range(20):
        st = cmd("say")
        if st["review"]["over"] is not None:
            break
    check(st["review"]["over"] == "clear", "the sequence exposed her (over=%s, phase=%s)" % (st["review"]["over"], st["review"]["phase"]))
    shot("confront-won", 0.5)
    st = wait_screen(["offer"], 6)

    # ---- 4. the offer scene ----------------------------------------------------------------
    print("== 4. the offer")
    check(st["screen"] == "offer", "she makes the offer (screen %s)" % st["screen"])
    shot("offer", 0.8)
    # the three buttons stack in the panel from y~40; the first (REFUSE) is the Primary.
    # Find it by probing: click down the panel until the screen changes.
    clicked = False
    for y in (330, 360, 390, 420, 450):
        click(210, y, 0.5)
        st = cmd("state")
        if st["screen"] == "offer_done":
            clicked = True
            break
    if not clicked:
        st = cmd("offer", c="refuse")
    check(st["case"].get("offer") == "refuse", "REFUSE took a real click (offer=%s, real=%s)" % (st["case"].get("offer"), clicked))
    shot("offer-refused", 0.8)
    cmd("go")
    st = wait_screen(["return"], 6)
    check(st["screen"] == "return" and st["cg"]["earned"], "the return: the slot is earned by state (earned=%s)" % st["cg"]["earned"])
    check(st["cg"]["censored"] and "_locked" in st["cg"]["plate"], "the free track draws the censored plate (%s)" % st["cg"]["plate"])
    shot("return-censored", 0.8)
    # the gate: SEE IT. On localhost gate.js takes its QA path (no Adsterra request); no
    # creative renders, so the fixed gate must answer "unavailable" and the plate stays censored.
    cmd("cg", do="see")
    t0 = time.time()
    while time.time() - t0 < 12 and not gate_open():
        time.sleep(0.2)
    check(gate_open(), "the gate overlay is on the page")
    shot("return-gate", 1.0)
    t0 = time.time()
    while time.time() - t0 < 60:
        st = cmd("state")
        if st["cg"]["status"]:
            break
        time.sleep(0.5)
    want = "unavailable" if not ITCH else "closed"
    check(st["cg"]["status"] in ("unavailable", "closed"), "no rendered creative => no unlock (status=%s, censored=%s)" % (st["cg"]["status"], st["cg"]["censored"]))
    check(st["cg"]["censored"], "the plate is still censored after the gate")
    if not gate_open():
        shot("return-after-gate", 0.6)
    else:
        page.evaluate("() => { var w = document.querySelector('[data-tel-ad=\"gate\"]'); w && w.closest('div') && w.closest('div').remove(); }")
    st = cmd("cg", do="skip")
    st = wait_screen(["result", "lvup"], 6)
    if st["screen"] == "lvup":
        cmd("pick", id=st["lvl"][0])
        st = wait_screen(["result"], 6)
    check(st["map"]["states"]["inbox"] == "cleared", "the case is closed on the map")
    shot("case-result", 0.6)
    cmd("go")
    st = wait_screen(["map"], 6)

    # ---- 5. clear / the board --------------------------------------------------------------
    print("== 5. the clear state and the board")
    check(st["night_clear"], "the night is clear: case + round")
    shot("night-map-clear", 0.8)
    click(210, 579, 0.6)   # CLOSE THE NIGHT (Primary at (110,556) 200x46)
    st = wait_screen(["clear"], 5)
    if st["screen"] != "clear":
        cmd("clear")
        st = wait_screen(["clear"], 5)
        check(False, "CLOSE THE NIGHT took a real click")
    else:
        check(True, "CLOSE THE NIGHT took a real click")
    shot("clear", 0.8)
    t0 = time.time()
    while time.time() - t0 < 8 and not board_open():
        time.sleep(0.2)
    check(board_open(), "the adult board is offered on the clear screen (127.0.0.1 is an adult host for board.js)")
    tiles = page.evaluate("() => document.querySelectorAll('.bd-tile').length")
    check(tiles > 0, "the board has %d tiles" % tiles)
    shot("board", 0.8)

    print("== page")
    check(not errors, "no page errors (%s)" % errors[:3])
    check(not popups, "no popups (%s)" % popups)
    browser.close()

print()
print("%d FAILED: %s" % (len(fails), fails) if fails else "NIGHT_OK — every step played; shots in %s" % SHOTS)
sys.exit(1 if fails else 0)
