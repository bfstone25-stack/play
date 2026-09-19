#!/usr/bin/env python3
"""Drive the web export through the whole week in headless Chromium and screenshot every
beat into shots/.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/beat-monday/web. Commands go through the dev bridge (Game polls
window.__bm_cmd once a frame; the main scene answers in window.__bm_result / __bm_state).
"simulate" steps the same core faster than real time with the kiting autopilot, stopping
at a level-up or the end of the day, so five days fit in one run. Asserts: no page errors,
no popups, every day reachable, the level-up cards, the rant projectiles on Wednesday,
the drops and the party on the desk, the Saturday screen, and zh-Hans rendering.
"""
import http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "beat-monday" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8810 + (os.getpid() % 200)
if not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run ./build.sh" % WEB)

DAYS = ["mon", "tue", "wed", "thu", "fri"]
DROP = {"mon": "stapler", "tue": "headphones", "wed": "lanyard", "thu": "chair", "fri": "badge"}


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
        page.screenshot(path=str(path))
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

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

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

    def play_day(i, want_shots):
        """Play day i to the end with the autopilot; screenshot the beats."""
        cmd("open", screen="brief", day=i)
        shot("brief-%s" % DAYS[i], 0.8)
        attempts = 0
        while attempts < 12:
            attempts += 1
            r = cmd("start", day=i)
            check(r["screen"] == "", "day %s started (attempt %d)" % (DAYS[i], attempts))
            first_lvl, mid, boss = True, False, False
            while True:
                r = cmd("simulate", seconds=4)
                run = r.get("run") or {}
                if r["screen"] == "lvup":
                    if first_lvl and want_shots:
                        shot("levelup-%s" % DAYS[i], 0.9)
                        first_lvl = False
                    pend = run.get("pending") or []
                    check(1 <= len(pend) <= 3, "skill cards offered (three until the pool runs dry): %s" % pend)
                    cmd("pick", id=pend[0])
                    continue
                if r["screen"] == "result":
                    break
                if want_shots and not mid and run.get("t", 0) >= 12:
                    shot("wave-%s" % DAYS[i], 0.3)
                    mid = True
                if want_shots and not boss and run.get("phase") == "boss":
                    cmd("simulate", seconds=2)
                    shot("boss-%s" % DAYS[i], 0.3)
                    boss = True
            st = cmd("state")
            run = st.get("run") or {}
            if run.get("over") == "clear":
                return st, attempts
            print("  ..   went home early on %s at t=%.0f, retrying" % (DAYS[i], run.get("t", 0)))
            want_shots = False
            cmd("go")   # TRY THE DAY AGAIN
            time.sleep(0.3)
            st = cmd("state")
            if st["screen"] == "":
                # already in the retried day: fall into the loop without re-opening the brief
                attempts += 1
                first_lvl, mid, boss = False, True, True
                while True:
                    r = cmd("simulate", seconds=4)
                    run = r.get("run") or {}
                    if r["screen"] == "lvup":
                        cmd("pick", id=(run.get("pending") or ["overtime"])[0])
                        continue
                    if r["screen"] == "result":
                        break
                st = cmd("state")
                if (st.get("run") or {}).get("over") == "clear":
                    return st, attempts
                cmd("go")
                time.sleep(0.3)
        return cmd("state"), attempts

    page.goto(URL, timeout=120000)
    dt = boot()
    check(dt is not None, "engine booted and the dev bridge answers (%.0fs)" % (dt or 0))
    cmd("reset")
    cmd("lang", code="en")
    d = cmd("diag")
    check(d.get("display_has") and d.get("ui_has"), "CJK fallback attached to the bundled faces: %s" % {k: v for k, v in d.items() if "cjk" in k or "has" in k or "display" in k})
    shot("title", 1.2)

    for i, d in enumerate(DAYS):
        st, attempts = play_day(i, True)
        run = st.get("run") or {}
        check(run.get("over") == "clear", "%s cleared in %d attempt(s), %d handled, level %d" % (d, attempts, run.get("kills", 0), run.get("level", 0)))
        if d == "wed":
            check(run.get("phrasesFired", 0) >= 50, "wednesday fired %d phrase projectiles (%s)" % (run.get("phrasesFired", 0), run.get("pattern")))
        if i == 0:
            t0 = time.time()
            while time.time() - t0 < 8.0 and not board_open():
                time.sleep(0.2)
            check(board_open(), "the casual board is offered after the first result (%.1fs)" % (time.time() - t0))
            shot("board-offer", 0.4)
            page.evaluate("() => { const w = document.querySelector('.bd-wrap'); w && w.remove(); }")
        shot("result-%s" % d, 0.4)
        prof = st["profile"]
        check(DROP[d] in prof["owned"], "%s dropped the %s" % (d, DROP[d]))
        if d == "fri":
            check(prof.get("week") == 1 and prof.get("day") == 0, "friday rolled into week 2")
            cmd("go")
            shot("saturday", 1.0)
            check(cmd("state")["screen"] == "weekend", "the Saturday screen")
        else:
            cmd("go")
            check(cmd("state")["screen"] == "week", "back on the week board")
            if d == "tue":
                shot("week-board", 0.8)
    st = cmd("open", screen="desk")
    shot("desk", 0.9)
    prof = st["profile"]
    check(len(prof["owned"]) == 5, "five items on the desk: %s" % prof["owned"])
    check(prof["party"] == ["intern", "pm", "hr"], "Riley, Morgan and Pat on the desk: %s" % prof["party"])
    r = cmd("equip", id="chair")
    check(r["profile"]["equipped"]["desk"] is None, "tapping the worn chair removes it")
    cmd("equip", id="chair")
    cmd("open", screen="week")
    shot("week-2-board", 0.8)
    cmd("start", day=0)
    cmd("simulate", seconds=10)
    shot("week-2-monday-party", 0.3)
    cmd("lang", code="zh")
    cmd("open", screen="title")
    shot("title-zh", 0.9)
    cmd("open", screen="brief", day=2)
    shot("brief-wed-zh", 0.8)
    cmd("start", day=2)
    cmd("simulate", seconds=14)
    shot("rant-zh", 0.3)
    st = cmd("state")
    check((st.get("run") or {}).get("phrasesFired", 0) > 0, "zh phrases fired")
    cmd("lang", code="en")
    time.sleep(7.0)   # user:// on the web is IndexedDB, synced on a ~5 s timer
    page.reload()
    boot()
    st = cmd("state")
    check(st["profile"].get("week") == 1 and len(st["profile"]["owned"]) == 5, "profile persisted across a reload")
    check(st["lang"] == "en", "language persisted (got %r)" % st.get("lang"))
    cmd("open", screen="title")
    shot("title-resume", 0.9)
    check(not popups, "no popups opened (%s)" % popups)
    check(not errors, "no page errors: %s" % errors[:3])
    browser.close()

print("\n%d checks failed" % len(fails) if fails else "\nHEADLESS_OK")
sys.exit(1 if fails else 0)
