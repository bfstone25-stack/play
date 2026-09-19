#!/usr/bin/env python3
"""Prove the reduced-motion path actually runs — in the browser, on the real wasm.

    ./build.sh && python3 tests/headless_motion.py

`reduce_motion` was declared in three scripts and gated four branches for months without
ever being assigned, so the branches compiled and never executed once. Checking that the
flag is set would not have caught that. This run checks the *consequences* instead: for
each of the four branches there is something the full-motion path writes to the scene and
the reduced path does not, accumulated frame by frame by main._probe_step():

    titleDrift    title_screen._process:215   the parallax layers offset from their base
    logoFlickers  logotype._process:39        the neon tube stuttering
    tableDrift    table_view._breathe:290     the sky sliding against the table
    sparks        table_view.spark:390        the particles a rebound throws

It runs the same session twice in two Chromium contexts — one reporting
`prefers-reduced-motion: no-preference`, one reporting `reduce` — with the game's own
setting left on "Auto" both times, so the platform read is under test too, end to end.
Then it checks the manual override and that it survives a reload.

Screenshots land in shots/motion/ as full/reduced pairs.
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
WEB = PROJ.parent.parent / "build" / "godot" / "rebound-tycoon" / "web"
SHOTS = PROJ / "shots" / "motion"
SHOTS.mkdir(parents=True, exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 9200 + (os.getpid() % 300)
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


class Session:
    """One Chromium context with a fixed prefers-reduced-motion, driven over the dev bridge."""

    def __init__(self, browser, reduced):
        self.ctx = browser.new_context(viewport={"width": 420, "height": 640},
                                       reduced_motion="reduce" if reduced else "no-preference")
        self.page = self.ctx.new_page()
        self.seq = 0
        self.errors = []
        self.page.on("pageerror", lambda e: self.errors.append(str(e)))
        self.page.on("dialog", lambda d: d.dismiss())
        self.page.goto(URL, timeout=180000)
        self.page.evaluate("() => { try { localStorage.clear(); } catch (e) {} }")
        t0 = time.time()
        while time.time() - t0 < 180:
            try:
                if self.cmd("state", timeout=3.0).get("ok") is not False:
                    return
            except SystemExit:
                time.sleep(1.0)
        raise SystemExit("engine never came up")

    def cmd(self, op, timeout=30.0, **kw):
        self.seq += 1
        c = dict(op=op, seq=self.seq, **kw)
        self.page.evaluate(
            "(c) => { window.__rt_cmd = window.__rt_cmd || []; window.__rt_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = self.page.evaluate("() => window.__rt_result || null")
            if r and r.get("seq") == self.seq:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def state(self):
        # window.__rt_state is only rewritten when a command is processed, so reading it
        # after a sleep hands back a snapshot from before the sleep. That is how the first
        # version of this file reported "still under the manual override" against a build
        # that was visibly moving: it was quoting the frame the probe had just been reset
        # on. Ask for a fresh frame first.
        self.cmd("state")
        return self.page.evaluate("() => window.__rt_state || null")

    def shot(self, name):
        self.page.screenshot(path=str(SHOTS / (name + ".png")))
        print("  shot motion/" + name + ".png")

    def close(self):
        self.ctx.close()


def run_session(browser, reduced, pref="auto"):
    """Sit on the title, then play the table, and return what the four branches did."""
    tag = "reduced" if reduced else "full"
    s = Session(browser, reduced)
    s.cmd("reset")
    s.cmd("title")
    s.cmd("motion", pref=pref)
    s.cmd("motion", reset=True)          # clear the probe, then let it accumulate

    # The title: the parallax push and the neon tube. Seven seconds because the tube's
    # own interval is randf_range(1.6, 5.5) — a shorter wait could see zero flickers in a
    # full-motion run and call the reduced path proven when nothing was proven.
    time.sleep(7.0)
    s.shot("title-" + tag)

    # The table: the sky drifting, and sparks off a rebound.
    s.cmd("start")
    time.sleep(1.0)
    for i in range(10):
        if s.state()["screen"] != "table":
            break
        if s.state()["mode"] == "plunge":
            s.cmd("hold", key="plunge", down=True)
            s.cmd("sim", frames=24, dt=1.0 / 60.0)
            s.cmd("hold", key="plunge", down=False)
            s.cmd("sim", frames=8, dt=1.0 / 60.0)
        s.cmd("hold", key="left", down=(i % 3 == 0))
        s.cmd("hold", key="right", down=(i % 3 == 1))
        s.cmd("sim", frames=90, dt=1.0 / 60.0)
        time.sleep(0.15)
    s.cmd("hold", key="left", down=False)
    s.cmd("hold", key="right", down=False)
    time.sleep(0.6)
    s.shot("table-" + tag)

    st = s.state()
    out = dict(st["motionProbe"])
    out["platform"] = st["platformReduceMotion"]
    out["reduceMotion"] = st["reduceMotion"]
    out["pref"] = st["motionPref"]
    out["errors"] = list(s.errors)
    s.close()
    return out


BRANCHES = [
    ("titleDrift", "title_screen._process:215   parallax push"),
    ("logoFlickers", "logotype._process:39        neon tube flicker"),
    ("tableDrift", "table_view._breathe:290      sky drift"),
    ("sparks", "table_view.spark:390         rebound sparks"),
]

with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader",
                                      "--enable-unsafe-swiftshader"])

    print("== full motion (prefers-reduced-motion: no-preference), setting on Auto")
    full = run_session(browser, reduced=False)
    print("   " + json.dumps(full))
    print("== reduced motion (prefers-reduced-motion: reduce), setting on Auto")
    red = run_session(browser, reduced=True)
    print("   " + json.dumps(red))

    print("-- the platform read")
    check(full["platform"] is False, "no-preference -> platform_reduce_motion() is false")
    check(red["platform"] is True, "reduce -> platform_reduce_motion() is true")
    check(full["reduceMotion"] is False and red["reduceMotion"] is True,
          "Auto resolves to the platform's answer in both directions")

    print("-- each gated branch, by what it did to the scene")
    for key, where in BRANCHES:
        check(full[key] > 0, "full motion runs the motion side of %s (%s = %s)"
              % (where, key, full[key]))
        check(red[key] == 0, "reduced motion takes the gated branch of %s (%s = %s)"
              % (where, key, red[key]))

    print("-- the manual override, and that it persists")
    s = Session(browser, reduced=False)
    s.cmd("reset")
    s.cmd("title")
    r = s.cmd("motion", pref="on")
    check(r["reduceMotion"] is True, "Motion: Calm forces reduced on a system that did not ask")
    s.shot("title-manual-calm")
    s.cmd("motion", reset=True)
    time.sleep(7.0)
    pr = s.state()["motionProbe"]
    check(all(pr[k] == 0 for k, _ in BRANCHES[:2]),
          "the title is still under the manual override (%s)" % json.dumps(pr))
    s.page.reload(timeout=180000)
    t0 = time.time()
    while time.time() - t0 < 180:
        try:
            if s.cmd("state", timeout=3.0).get("ok") is not False:
                break
        except SystemExit:
            time.sleep(1.0)
    check(s.state()["motionPref"] == "on", "the choice survived a reload (saved with sound/lang)")
    r = s.cmd("motion")                       # the booth button: on -> off
    check(r["pref"] == "off" and r["reduceMotion"] is False,
          "the button cycles Auto -> Calm -> Full (now %s)" % r["pref"])
    s.shot("title-manual-full")
    errs = [e for e in s.errors if "favicon" not in e]
    check(not errs, "no page errors (%s)" % errs)
    s.close()
    browser.close()

srv.shutdown()
print()
if fails:
    print("!! %d failed" % len(fails))
    for f in fails:
        print("   - " + f)
    sys.exit(1)
print("MOTION_OK")
