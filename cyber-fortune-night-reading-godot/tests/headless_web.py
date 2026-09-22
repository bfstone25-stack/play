#!/usr/bin/env python3
"""Drive the real web export in headless Chromium through the whole night, shots -> shots/.

    ops/cyber_fortune_night_build.sh
    ops/remote_playtest.sh build/godot-ads/cyber-fortune-night-reading \
        play/cyber-fortune-night-reading-godot/tests/headless_web.py

Local browser tests are disabled on Blaze's desktop (they cost four cores of the machine
he works on, and the only local browser has no WebGL2 anyway), so the browser runs on the
GPU box: remote_playtest.sh rsyncs the build, serves it there, and passes this script the
URL as its first argument. Shots come back in ops/remote_shots/<slug>/.
Without a URL it serves build/godot/... itself, which only works where a browser is allowed.

No visible window is ever opened (ops/on_game_monitor.sh): this is headless Chromium with
real Playwright input, and every command goes through the dev bridge that Fortune polls
(window.__cf_cmd / __cf_result / __cf_state) — each one is something a player can also do
with a click.

What it asserts, in the order it plays:
  * the engine boots and the table screen names the three women
  * a reading is a real draw: the rank comes off Fortune's ladder and it names one of her
    three tracks
  * a reading she refuses moves nothing, and nothing about the refusal is in the save
  * a reading she takes moves the track it named, and a track at 3 locks
  * with all nine, the night is offered — and is gated: with no creative and no purchase
    the plate stays censored, the beats do not appear, and the refusal is NOT remembered
    (the next press asks again)
  * granting the gate opens the beats, and finishing marks the night seen
  * the save survives a reload, no page errors, no popups
"""
import argparse, http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

ap = argparse.ArgumentParser()
ap.add_argument("url", nargs="?", help="drive a page that is already served (ops/remote_playtest.sh "
                                       "passes this; it runs the browser on the GPU box because "
                                       "local browser tests are disabled on Blaze's desktop)")
ap.add_argument("--ads", action="store_true", help="drive the ad track instead of the itch one")
args = ap.parse_args()
REMOTE = bool(args.url)

pathlib_cwd = Path.cwd()
HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
ROOT = PROJ.parent.parent
WEB = (ROOT / "build/godot-ads/cyber-fortune-night-reading") if args.ads else \
      (ROOT / "build/godot/cyber-fortune-night-reading/web")
SHOTS = (pathlib_cwd / "shots") if REMOTE else (PROJ / "shots")
SHOTS.mkdir(parents=True, exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8830 + (os.getpid() % 150)
if not REMOTE and not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run ops/cyber_fortune_night_build.sh" % WEB)


class Quiet(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(WEB), **k)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *a):
        pass


srv = None
if REMOTE:
    # remote_playtest.sh is pointed at build/godot-ads/, so the ad track is the default
    # there: that is the build whose gate has to refuse when no creative renders.
    URL = args.url.rstrip("/") + "/index.html?dist=ads_web"
else:
    socketserver.TCPServer.allow_reuse_address = True
    srv = socketserver.TCPServer(("127.0.0.1", PORT), Quiet)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    URL = "http://127.0.0.1:%d/index.html?dist=%s" % (PORT, "ads_web" if args.ads else "itch_web")
fails = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=swiftshader", "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 720, "height": 1280})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error"
            and "favicon" not in m.text and "blazecore.dev" not in m.text
            and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n, seq = [0], [0]

    def shot(name, settle=0.7):
        time.sleep(settle)
        n[0] += 1
        # ops/play_matrix.py globs "s*.png" only -- the play_driver.py naming convention.
        # This used to write "01-table.png" etc, which that glob silently ignores: every
        # real run's frames were invisible to the matrix tool, which then either reported
        # "no frames" or fell back to stale s*.png leftovers from an old play_driver.py
        # pass sitting in the same directory. Match the convention so the matrix sees them.
        path = SHOTS / ("s%02d_%s.png" % (n[0], name))
        page.screenshot(path=str(path))
        print("  shot " + path.name)

    def cmd(op, timeout=25.0, **kw):
        seq[0] += 1
        c = dict(op=op, seq=seq[0], **kw)
        page.evaluate("(c) => { window.__cf_cmd = window.__cf_cmd || []; window.__cf_cmd.push(c); }", c)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = page.evaluate("() => window.__cf_result || null")
            if r and r.get("seq") == seq[0]:
                return r
            time.sleep(0.05)
        raise SystemExit("bridge timeout on %r" % c)

    def state():
        return page.evaluate("() => window.__cf_state || null")

    print("\n== boot")
    # A 40 MB wasm page: "load" can take minutes on a box that is also rendering, and the
    # engine is not up when the document is. So: wait for the document, then poll for the
    # bridge by pushing a command and watching for an answer.
    page.goto(URL, wait_until="domcontentloaded", timeout=180000)
    t0 = time.time()
    booted = False
    while time.time() - t0 < 300:
        if page.evaluate("() => !!window.__cf_state"):
            booted = True
            break
        page.evaluate("() => { window.__cf_cmd = window.__cf_cmd || []; "
                      "if (!window.__cf_cmd.length) window.__cf_cmd.push({op: 'state', seq: 0}); }")
        time.sleep(2)
    print("  booted after %.0fs" % (time.time() - t0), flush=True)
    check(booted, "the engine came up")
    cmd("state", timeout=60.0)
    cmd("reset")
    page.evaluate("() => { try { localStorage.clear(); } catch (e) {} }")
    s = state()
    check(s is not None, "the engine booted and the bridge answers")
    # Boot lands on the title screen, which has no dev_cmd handler of its own -- a player
    # gets to the table by clicking "title.read"/"title.again"; the bridge equivalent is
    # `open`. Without this the very next "pick" silently no-ops ({"ok": false,
    # "why": "no_screen_handler"}, never checked) and every check after it fails for a
    # reason that has nothing to do with the mechanics being tested -- the whole run
    # stayed on the title screen. Caught 2026-09-21: this test used to boot straight to
    # the table before the title screen existed, and nobody updated it when the title
    # screen was added.
    cmd("open", screen="home")
    shot("table")

    print("\n== a reading is a real draw")
    cmd("pick", client="mirren")
    shot("mirren-room")
    r = cmd("read", kind="slip")
    o = r.get("offer") or {}
    check(bool(o), "a draw happened")
    check(o.get("result", {}).get("rank") in
          ["daji", "zhongji", "xiaoji", "moji", "xiong", "daxiong"],
          "the rank came off the parent's six-rank ladder (%s)" % o.get("result", {}).get("rank"))
    check(o.get("track") in (0, 1, 2), "the reading names one of her three tracks")
    shot("reading-drawn")
    # Release it before the loop below draws again: Fortune.draw() refuses a second draw
    # while `pending` still holds this one ({"ok": false} every time, never checked), which
    # silently starved every "read" below of ever happening -- the refusal search spun 40
    # times doing nothing rather than 40 real draws. Caught 2026-09-21.
    cmd("hold")

    print("\n== what she does not take, nothing writes")
    # Drive to a refusal deterministically: keep drawing until one comes back unaccepted.
    tries, refused = 0, None
    while tries < 40 and refused is None:
        tries += 1
        cmd("merit", n=100000)
        o = (cmd("read", kind="slip", timeout=60.0).get("offer") or {})
        if o and not o.get("accepted"):
            refused = o
            break
        if o:
            cmd("speak", timeout=60.0)
    if refused:
        before = list(state()["night"]["clients"]["mirren"]["tracks"])
        ev = cmd("speak")
        after = list(state()["night"]["clients"]["mirren"]["tracks"])
        check(before == after, "a reading she refused moved nothing (%s -> %s)" % (before, after))
        check(not ev.get("event", {}).get("accepted"), "the event says she refused")
        save = page.evaluate("() => JSON.stringify(window.__cf_state.night)")
        check("refus" not in save.lower(), "the refusal is not written anywhere in the state")
        shot("refused")
    else:
        check(False, "no refusal in 40 draws — the consent gate never says no")

    print("\n== what she takes becomes true")
    # Draw, say it, repeat. The event that comes back off each "speak" carries whether
    # she is ready, so the climb costs two bridge round-trips a reading rather than five —
    # this box is usually running the render queue and a voice worker at the same time,
    # and a chatty driver simply does not finish.
    cmd("merit", n=100000)
    guard = 0
    ready = False
    while not ready and guard < 120:
        guard += 1
        cmd("read", kind=["slip", "card", "force"][guard % 3], timeout=60.0)
        ev = cmd("speak", timeout=60.0).get("event", {})
        ready = bool(ev.get("ready"))
        if guard % 4 == 0:
            cmd("merit", n=100000)
    m = state()["night"]["clients"]["mirren"]
    check(m["total"] == 9, "all three of her tracks are true (%s)" % m["tracks"])
    check(m["ready"], "the night is hers to offer")
    shot("all-three-true")

    print("\n== the gate")
    cmd("open", screen="scene")
    sc = state().get("scene", {})
    check(not sc.get("unlocked", True), "the scene starts locked")
    shot("scene-locked")

    # --- a refusal ---------------------------------------------------------------------
    # Press it, then decline. This is the half of the gate that has actually gone wrong
    # before: a "no" that gets remembered as an answer, or worse, unlocks anyway.
    cmd("ask")
    time.sleep(4)
    shot("gate-open")
    not_now = page.get_by_text("Not now")
    if not_now.count():
        not_now.first.click()
    else:
        page.keyboard.press("Escape")
    time.sleep(3)
    sc = state().get("scene", {})
    key = sc.get("key", "")
    check(not sc.get("unlocked", True), "declining the gate does not unlock the night")
    stored = page.evaluate("() => localStorage.getItem('gate_unlocks') || ''")
    check(key not in stored, "a refused unlock is not remembered (%s is not in the store)" % key)
    shot("gate-refused")

    # --- and it asks again --------------------------------------------------------------
    cmd("ask")
    time.sleep(4)
    check(page.get_by_text("Not now").count() > 0 or state().get("scene", {}).get("asking", False)
          or state().get("scene", {}).get("unlocked", False),
          "pressing again asks the page again rather than reusing the 'no'")
    # Let it run to the end: on this box the page serves gate.js's QA sponsor slot (no
    # Adsterra creative reaches an automated browser), which is the same path a real
    # completed clip takes — the countdown (gate.js's own 30s, cfg().seconds default),
    # then Continue. The button exists (and matches get_by_text) from the moment the
    # overlay opens -- it starts disabled, so the click has to land in the window after
    # the countdown actually finishes, not just find the element. Twice measured on this
    # box loaded with ~20 other agents' Chrome/Godot processes: real time to a landed
    # click ran past the previous 60s budget, which starved the poll below of ever
    # seeing "unlocked" even though the gate resolved correctly a bit later (proved by
    # "the night finishes" passing further down). Widened rather than guessed at once.
    t0 = time.time()
    while time.time() - t0 < 180:
        btn = page.get_by_text("Continue")
        if btn.count():
            try:
                btn.first.click(timeout=2000)
                break
            except Exception:
                pass
        time.sleep(2)
    # gate.gd's require() polls window.__gate every 0.4s for the page's Promise to
    # resolve -- a fixed 4s sleep here raced that poll under load and reported the gate
    # as still locked when "finish" a few lines later proved it wasn't. Poll instead.
    t0 = time.time()
    while time.time() - t0 < 30 and not state().get("scene", {}).get("unlocked", False):
        time.sleep(0.5)
    check(state().get("scene", {}).get("unlocked", False),
          "a completed sponsor slot opens the night")
    shot("scene-beat-1")
    cmd("beat"); shot("scene-beat-2")
    cmd("beat"); shot("scene-beat-3")
    cmd("beat"); shot("scene-after")
    r = cmd("finish")
    check(r.get("ok"), "the night finishes")
    check(state()["night"]["clients"]["mirren"]["seen"], "the night is marked seen")
    shot("table-after")

    print("\n== it survives a reload")
    # save_state()'s FS.syncfs(false, cb) is async and fire-and-forget on the GDScript
    # side -- it returns as soon as the eval is issued, not when IndexedDB has actually
    # been written. shot("table-after") above already gives it ~0.7s; a couple more
    # seconds of margin under a loaded shared box costs nothing a player would notice
    # (this reload is scripted, not a click) and removes a race the fix itself can't
    # close from the GDScript side without a real callback round-trip.
    time.sleep(3)
    page.reload()
    t0 = time.time()
    while time.time() - t0 < 90:
        if page.evaluate("() => !!window.__cf_state"):
            break
        time.sleep(0.5)
    cmd("state")
    m = state()["night"]["clients"]["mirren"]
    check(m["seen"] and m["total"] == 9, "her night and her nine survived the reload")
    shot("after-reload")

    print("\n== the page itself")
    check(not errors, "no page errors (%s)" % (errors[:2] or "none"))
    check(not popups, "no popups (%s)" % (popups[:2] or "none"))
    browser.close()

if srv is not None:
    srv.shutdown()
print("\n%d failed" % len(fails))
for f in fails:
    print("  !! " + f)
raise SystemExit(1 if fails else 0)
