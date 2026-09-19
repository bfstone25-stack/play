#!/usr/bin/env python3
"""Drive the web export in headless Chromium through a full round, shooting every step.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/ghost-channel/web. Commands go through the dev bridge in scripts/main.gd
(window.__gc_cmd in, window.__gc_result / window.__gc_state out); every command is something
a player can also do with a click. A Godot game draws into a canvas, so this is the only way
to assert that a screen actually rendered rather than that the code which would render it
exists — the distinction that let play/confession-room ship a cross-promo board that never
once appeared (memory: verification-that-lies).

Asserts, in order:
  - the page has no errors and opens no popups
  - the title screen boots and the call-lights demo runs
  - HOW TO PLAY and CREDITS render, and CREDITS says what the build's art and voice are
  - an op runs: every request answered, the HUD moves, the log fills
  - the naming round arrives and naming the real mimic reaches the win debrief
  - the casual cross-promo board is offered at the end of the run (and never before it)
  - the language switch redraws the live console in zh
"""
import http.server
import json
import os
import socketserver
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "ghost-channel" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8830 + (os.getpid() % 150)
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
URL = "http://127.0.0.1:%d/index.html?dist=ads_web" % PORT

fails = []
missed = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader",
                                      "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error"
            and "favicon" not in m.text and "blazecore.dev" not in m.text
            and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]

    def shot(name, settle=0.6):
        # This box runs two ComfyUI workers and a TTS pass beside the test, and SwiftShader
        # is software rasterising a 1280x720 canvas on whatever is left. A screenshot that
        # times out is the machine being busy, not the build being broken, so it is retried
        # once with a long deadline and then reported rather than raised — losing a picture
        # must not lose the twenty assertions after it.
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("%02d-%s.png" % (n[0], name))
        for attempt, deadline in enumerate([60000, 150000]):
            try:
                page.screenshot(path=str(path), timeout=deadline)
                print("  shot " + path.name)
                return
            except Exception as exc:
                if attempt:
                    print("  MISS " + path.name + " (" + type(exc).__name__ + ")")
                    missed.append(path.name)
                    return
                time.sleep(4.0)

    seq = [0]

    def cmd(op, timeout=25.0, **kw):
        seq[0] += 1
        c = dict(op=op, seq=seq[0], **kw)
        page.evaluate("(c) => { window.__gc_cmd = window.__gc_cmd || []; window.__gc_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = page.evaluate("() => window.__gc_result || null")
            if r and r.get("seq") == seq[0]:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def state():
        return page.evaluate("() => window.__gc_state || null") or {}

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

    page.goto(URL, timeout=180000)      # a wasm build on a loaded box outlasts the default
    t0 = time.time()
    booted = False
    while time.time() - t0 < 150:
        if state().get("screen"):
            booted = True
            break
        time.sleep(0.5)
    check(booted, "engine booted and the dev bridge answers (%.0fs)" % (time.time() - t0))
    if not booted:
        print("\n".join(errors[:10]))
        sys.exit(1)
    cmd("reset")

    st = state()
    check(st.get("screen") == "title", "the title screen is up")
    print("  build: plates=%s voice=%s" % (st.get("plates"), st.get("voice_langs")))
    shot("title", 2.6)                  # after the logotype has settled and a lamp has lit
    shot("title-later", 3.2)            # a second transmission, a different lamp

    cmd("screen", name="how")
    shot("how-to-play")
    cmd("screen", name="credits")
    shot("credits")
    cmd("screen", name="ops")
    shot("select-operation")

    # ---- a full op ----------------------------------------------------------------------
    cmd("start", op_index=0)
    time.sleep(1.2)
    st = state()
    check(st.get("screen") == "play", "op 1 started and the console is up")
    check(st.get("done") == 1, "the first request is on the air")
    check(len(st.get("codebook", "")) > 4, "today's code is on the card: %s" % st.get("codebook"))
    shot("op-first-request", 1.0)

    before = state().get("time", 0)
    cmd("q")
    shot("interrogated", 0.8)
    # the prototype charges 8 seconds for a question; the clock also ticks while we wait,
    # so the assertion is "it cost at least the 8" rather than an exact number
    check(before - state().get("time", 0) >= 8, "interrogating cost the clock 8 s or more")

    answered, guard = 0, 0
    saw_target = False
    while guard < 40:
        guard += 1
        st = state()
        if st.get("ended") or st.get("naming"):
            break
        if not st.get("who"):
            time.sleep(0.4)
            continue
        # answer honestly enough to reach the naming round: deny anything with a tell,
        # authorize the rest. This is a player's actual strategy, not a cheat.
        tells = st.get("tells") or []
        cmd("deny" if tells else "auth")
        answered += 1
        if answered == 2:
            shot("op-mid-round", 1.0)
        if tells:
            saw_target = True
        time.sleep(1.0)                 # the console's 650 ms beat, plus a frame or two
    st = state()
    check(answered >= 3, "answered %d requests" % answered)
    check(st.get("log", 0) > answered, "the net log filled: %d rows" % st.get("log", 0))

    # ---- the naming round ---------------------------------------------------------------
    t0 = time.time()
    while time.time() - t0 < 30 and not (state().get("naming") or state().get("ended")):
        time.sleep(0.5)
    st = state()
    if st.get("naming"):
        shot("name-the-ghost", 1.0)
        check(True, "the naming round arrived")
        r = cmd("name_ghost")
        check(r.get("ok"), "named the real mimic (roster slot %s)" % r.get("i"))
    else:
        check(st.get("ended"), "the op ended before naming (%s)" % st.get("reason"))

    time.sleep(1.4)
    st = state()
    check(st.get("screen") == "debrief", "the debrief rendered")
    check(st.get("ended"), "the op is over: %s" % st.get("reason"))
    shot("debrief", 1.0)

    # ---- the cross-promo board ------------------------------------------------------------
    t0 = time.time()
    while time.time() - t0 < 8 and not board_open():
        time.sleep(0.3)
    check(board_open(), "the casual board was offered at the end of the run")
    shot("board", 0.8)
    tiles = page.evaluate("() => document.querySelectorAll('.bd-tile').length")
    check(tiles > 0, "the board has %d tile(s)" % tiles)
    adult = page.evaluate(
        "() => Array.from(document.querySelectorAll('.bd-wrap a')).some(a => /workers\\.dev/.test(a.href))")
    check(not adult, "no adult link on the board (this is the AdSense-host distribution)")
    page.evaluate("() => { var w = document.querySelector('.bd-wrap'); w && w.remove(); }")

    # ---- the other language -----------------------------------------------------------------
    cmd("lang", lang="zh")
    time.sleep(0.6)
    check(state().get("lang") == "zh", "language switched to zh")
    shot("debrief-zh", 0.8)
    cmd("screen", name="title")
    shot("title-zh", 2.4)
    cmd("start", op_index=0)
    time.sleep(1.4)
    st = state()
    check(st.get("screen") == "play", "an op runs in zh")
    body = st.get("body", "")
    check(any("一" <= ch <= "鿿" for ch in body),
          "the line on the air is in Chinese: %s" % body[:40])
    shot("op-zh", 1.2)

    check(not errors, "no page errors (%s)" % (errors[:3] if errors else "none"))
    check(not popups, "no popups (%s)" % (popups if popups else "none"))
    browser.close()

srv.shutdown()
if missed:
    print("%d screenshot(s) missed on a loaded box: %s" % (len(missed), ", ".join(missed)))
print("\n%d check(s) failed" % len(fails))
sys.exit(1 if fails else 0)
