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
import base64, http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
ROOT = PROJ.parent.parent
ITCH = "--itch" in sys.argv
WEB = ROOT / "build" / ("godot/after-six/web" if ITCH else "godot-ads/after-six")

# Driven remotely when given a URL. Blaze's desktop stopped allowing local browser tests on
# 2026-09-19 — headless Chromium on software rendering was taking four or five of his cores
# for a job that had no business being on his machine — so ops/remote_playtest.sh rsyncs the
# build to the GPU box, serves it there, and runs this file there with the URL as argv[1]:
#
#     ops/remote_playtest.sh build/godot-ads/after-six tests/night_web.py
#
# That box reports WebGL2 true, so Godot renders on the card instead of in software, which
# is also why the Light2D map stops stalling on ReadPixels. With no URL the old local path
# is unchanged, for whenever a machine is allowed to run it.
REMOTE_URL = next((a for a in sys.argv[1:] if a.startswith("http")), "")
SHOTS = Path("shots") if REMOTE_URL else PROJ / "shots"
SHOTS.mkdir(exist_ok=True, parents=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
if not REMOTE_URL and not (WEB / "index.html").exists():
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


if REMOTE_URL:
    # The remote runner is already serving the build with the cross-origin headers Godot
    # needs; starting a second server here would serve a build directory that is not there.
    URL = REMOTE_URL if REMOTE_URL.endswith((".html", "/")) else REMOTE_URL + "/"
else:
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
    # SHOT_SCALE=1 halves each axis of every captured frame. The capture goes through
    # ReadPixels under swiftshader, which is pure CPU, and on a loaded box a 840x1280
    # readback of the Light2D map stalls long enough for Chromium to kill the renderer —
    # "GPU stall due to ReadPixels", then TargetClosedError on the next evaluate. At scale
    # 1 the readback is a quarter of the work and the run completes. Default stays 2 so a
    # quiet box still produces the full-resolution set.
    page = browser.new_page(viewport={"width": 420, "height": 640},
                            device_scale_factor=float(os.environ.get("SHOT_SCALE", "2")))
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" and "favicon" not in m.text and "blazecore.dev" not in m.text and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]

    def shot(name, settle=0.6):
        """The engine's own frame (bridge op "snap"), not the compositor's: under swiftshader
        Playwright's screenshot of the Light2D map never returns. Fails loudly if no frame
        arrives — a run that printed "shot" with no file behind it is how a check lies."""
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("%02d-%s.png" % (n[0], name))
        page.evaluate("() => { window.__bm_snap = null; }")
        r = cmd("snap")
        b64 = page.evaluate("() => window.__bm_snap || null")
        if not b64:
            check(False, "no frame captured for %s" % name)
            return
        path.write_bytes(base64.b64decode(b64))
        check(path.stat().st_size > 20000, "frame %s captured (%d bytes)" % (path.name, path.stat().st_size))

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
        tapped = False
        for attempt in (1, 2):
            click(x, y, 0.5)
            if cmd("state")["map"]["walking"] or cmd("state")["screen"] != "map":
                tapped = True
                break
        if mid_shot:
            shot(mid_shot, 0.6)
        if not tapped:
            cmd("walk", id=node)      # fallback: the same path the tap would have taken
        st = wait_screen(["node", "breakroom", "event", "event_done"], timeout=90.0)
        check(st["map"]["at"] == node, "walked to %s (tap took: %s, screen %s)" % (node, tapped, st["screen"]))
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
    # The title is canvas-drawn, so there is no DOM node to find: try the menu rows a real
    # thumb would, then fall back to the engine's own "press the primary". The title screen
    # is being recomposed by a parallel pass (scripts/as_title.gd), so a hardcoded
    # coordinate is not something this driver may depend on — it reports which it got.
    real = False
    for y in (365, 420, 470, 520, 560, 600):
        click(210, y, 0.45)
        if cmd("state")["screen"] != "title":
            real = True
            break
    if not real:
        cmd("go")
    st = wait_screen(["map"], 8)
    check(st["screen"] == "map", "the title's first menu row starts the night (real click: %s)" % real)
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
    st = wait_screen(["offer"], 20)

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
    # gate.js enables its Continue button when the countdown reaches zero; the promise
    # resolves on that click. Watch the button, then press it — that is what a player does.
    clicked_gate = False
    t0 = time.time()
    while time.time() - t0 < 90:
        st = cmd("state")
        if st["cg"]["status"]:
            break
        if not clicked_gate:
            btns = page.evaluate("""() => Array.from(document.querySelectorAll('button'))
                .filter(b => !b.disabled && /continue|unlock/i.test(b.textContent)).map(b => b.textContent)""")
            if btns:
                page.evaluate("""() => { var b = Array.from(document.querySelectorAll('button'))
                    .filter(b => !b.disabled && /continue|unlock/i.test(b.textContent))[0]; b && b.click(); }""")
                clicked_gate = True
        time.sleep(0.5)
    check(clicked_gate, "the gate ran its countdown and its Continue button was pressed")
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
    bad = [u for u in popups if "flat404.workers.dev" not in u]
    check(not bad, "every popup is an adult-host board link, none elsewhere (%s)" % popups)
    browser.close()

print()
print("%d FAILED: %s" % (len(fails), fails) if fails else "NIGHT_OK — every step played; shots in %s" % SHOTS)
sys.exit(1 if fails else 0)
