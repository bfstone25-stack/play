#!/usr/bin/env python3
"""Drive the web export through a whole route on the map in headless Chromium and
screenshot every beat into shots/.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/beat-monday/web. Commands go through the dev bridge (Game polls
window.__bm_cmd once a frame; the main scene answers in window.__bm_result / __bm_state).
The route: title -> the map -> walk to the standup (a real walk, screenshotted mid-way)
-> the survivor-like day -> the corridor event -> the inbox (triage, greedy autoplay)
-> the all-hands (the rant) -> the review (the honest player on the ported engine)
-> the break room (a coffee) -> the deploy (placement, then the boss) -> Saturday ->
Week 2's fresh map -> zh-Hans on the map, the triage and the review -> a reload.
Asserts: no page errors, no popups, every node type reached and cleared, the drops and
the party through the ported progression, the week rollover, persistence.
"""
import http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
# Was "beat-monday" -- a copy-paste from the sibling driver, so After Six's own
# headless test has been opening Beat the Monday's build. Whatever it asserted, it
# asserted about the wrong game. Found 2026-09-22 while running every bespoke
# driver after their shot naming was fixed.
WEB = PROJ.parent.parent / "build" / "godot" / "after-six" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
if not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run ./build.sh" % WEB)

DROP = {"standup": "stapler", "inbox": "headphones", "allhands": "lanyard", "review": "chair", "deploy": "badge"}
JOIN = {"standup": "intern", "inbox": "pm", "review": "hr"}


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
        path = SHOTS / ("s%02d_%s.png" % (n[0], name))
        # under swiftshader a screenshot can stall while the engine is mid-frame; one
        # retry after a bridge round-trip has always been enough
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

    def wait_screen(names, timeout=20.0):
        t0 = time.time()
        while time.time() - t0 < timeout:
            st = cmd("state")
            if st["screen"] in names and not st["map"]["walking"]:
                return st
            time.sleep(0.15)
        return cmd("state")

    def walk_to(node, mid_shot=None):
        """Tap a room on the map: the character walks there in real time."""
        st = cmd("state")
        if st["screen"] != "map":
            cmd("open", screen="map")
        r = cmd("walk", id=node)
        check(r["ok"], "walk to %s allowed (path %s)" % (node, r.get("path")))
        if mid_shot and len(r.get("path", [])) > 1:
            shot(mid_shot, 0.7)
        st = wait_screen(["node", "breakroom", "event", "event_done"], timeout=90.0)
        check(st["map"]["at"] == node, "arrived at %s (screen %s)" % (node, st["screen"]))
        return st

    def run_reflex(node, want_shots, tag):
        """A reflex node from its brief: enter, autopilot, level-ups, retries."""
        attempts = 0
        while attempts < 12:
            attempts += 1
            if attempts == 1:
                st = cmd("enter", id=node)
            else:
                st = cmd("go")   # TRY THE DAY AGAIN
                time.sleep(0.3)
                st = cmd("state")
            if st["screen"] == "placement":
                return st, attempts
            check(st["screen"] == "", "%s started (attempt %d)" % (node, attempts))
            first_lvl, mid, boss = want_shots, False, False
            while True:
                r = cmd("simulate", seconds=4)
                run = r.get("run") or {}
                if r["screen"] == "lvup":
                    if first_lvl:
                        shot("levelup-%s" % tag, 0.9)
                        first_lvl = False
                    pend = run.get("pending") or []
                    check(1 <= len(pend) <= 3, "skill cards offered: %s" % pend)
                    cmd("pick", id=pend[0])
                    continue
                if r["screen"] == "result":
                    break
                if want_shots and not mid and run.get("t", 0) >= 12:
                    shot("wave-%s" % tag, 0.3)
                    mid = True
                if want_shots and not boss and run.get("phase") == "boss":
                    cmd("simulate", seconds=2)
                    shot("boss-%s" % tag, 0.3)
                    boss = True
            st = cmd("state")
            if (st.get("run") or {}).get("over") == "clear":
                return st, attempts
            print("  ..   went home early in %s at t=%.0f, retrying" % (node, (st.get("run") or {}).get("t", 0)))
            want_shots = False
        return cmd("state"), attempts

    def after_result(node, st):
        prof = st["profile"]
        check(node in st["map"]["cleared"], "%s marked cleared on the map" % node)
        if node in DROP:
            check(DROP[node] in prof["owned"], "%s dropped the %s (through commit_run)" % (node, DROP[node]))
        if node in JOIN:
            check(JOIN[node] in prof["party"], "%s brought %s into the party" % (node, JOIN[node]))

    # ---------------------------------------------------------------- boot, title, map
    page.goto(URL, timeout=120000)
    dt = boot()
    check(dt is not None, "engine booted and the dev bridge answers (%.0fs)" % (dt or 0))
    cmd("reset")
    cmd("lang", code="en")
    d = cmd("diag")
    check(d.get("display_has") and d.get("ui_has"), "CJK fallback attached to the bundled faces")
    print("  art  rendered sprites: %s" % {k: v for k, v in d["sprites"].items()})
    print("  art  rendered map plates: %s" % {k: v for k, v in d["plates"].items()})
    shot("title", 1.2)
    st = cmd("open", screen="map")
    check(st["screen"] == "map", "the map opens")
    check(st["map"]["at"] == "lobby", "the week starts in the lobby")
    check(st["map"]["states"]["standup"] == "open" and st["map"]["states"]["inbox"] == "locked" and st["map"]["states"]["deploy"] == "locked",
          "fresh map: standup open, inbox and deploy locked")
    shot("map-week1", 1.0)
    r = cmd("walk", id="deploy")
    check(not r["ok"], "a locked room refuses the walk")

    # ---------------------------------------------------------------- the standup (reflex)
    st = walk_to("standup", mid_shot="walk-to-standup")
    shot("node-standup", 0.8)
    st, attempts = run_reflex("standup", True, "standup")
    check((st.get("run") or {}).get("over") == "clear", "standup cleared in %d attempt(s), level %d" % (attempts, (st.get("run") or {}).get("level", 0)))
    t0 = time.time()
    while time.time() - t0 < 8.0 and not board_open():
        time.sleep(0.2)
    check(board_open(), "the casual board is offered after the first result (%.1fs)" % (time.time() - t0))
    shot("board-offer", 0.4)
    page.evaluate("() => { const w = document.querySelector('.bd-wrap'); w && w.remove(); }")
    shot("result-standup", 0.4)
    after_result("standup", st)
    st = cmd("go")
    check(cmd("state")["screen"] == "map", "back on the map")
    check(cmd("state")["map"]["states"]["inbox"] == "open" and cmd("state")["map"]["states"]["allhands"] == "open", "the branch opened: inbox and all-hands")
    shot("map-after-standup", 0.9)

    # ---------------------------------------------------------------- the corridor (event)
    st = walk_to("corridor1")
    check(st["screen"] == "event", "the corridor shows its event")
    shot("event", 0.8)
    st = cmd("choose", c="a")
    st = wait_screen(["event_done", "lvup"])
    while st["screen"] == "lvup":
        cmd("pick", id=(st.get("lvl") or ["overtime"])[0])
        st = wait_screen(["event_done", "lvup"])
    shot("event-done", 0.6)
    check("corridor1" in st["map"]["cleared"], "the corridor is cleared by choosing")
    cmd("go")

    # ---------------------------------------------------------------- the inbox (triage)
    st = walk_to("inbox")
    shot("node-inbox", 0.8)
    for attempt in range(1, 9):
        st = cmd("enter", id="inbox") if attempt == 1 else cmd("go")
        time.sleep(0.3)
        st = cmd("state")
        check(st["screen"] == "triage", "triage started (attempt %d)" % attempt)
        if attempt == 1:
            shot("triage-hand", 0.8)
            tri = st["triage"]
            check(tri["hand"] == 5 and tri["actions"] == 3, "a hand of five, three actions: %s" % tri)
            # one real action through the bridge, the way a thumb would
            st = cmd("tri", i=0, action="reply")
            check(st["triage"]["actions"] < 3, "reply spent an action")
            shot("triage-after-reply", 0.5)
        turns = 0
        while st["screen"] == "triage" and turns < 40:
            st = cmd("tri_auto")
            turns += 1
            time.sleep(0.05)
        st = wait_screen(["result", "lvup"])
        while st["screen"] == "lvup":
            if attempt == 1:
                shot("levelup-triage", 0.6)
            cmd("pick", id=(st.get("lvl") or ["boundary"])[0])
            st = wait_screen(["result", "lvup"])
        if "inbox" in st["map"]["cleared"]:
            break
        print("  ..   the desk won (attempt %d), retrying" % attempt)
    shot("result-inbox", 0.5)
    after_result("inbox", st)
    cmd("go")

    # ---------------------------------------------------------------- the all-hands (rant)
    st = walk_to("allhands")
    shot("node-allhands", 0.8)
    st, attempts = run_reflex("allhands", True, "allhands")
    run = st.get("run") or {}
    check(run.get("over") == "clear", "all-hands cleared in %d attempt(s)" % attempts)
    check(run.get("phrasesFired", 0) >= 50, "the rant fired %d phrase projectiles (%s)" % (run.get("phrasesFired", 0), run.get("pattern")))
    shot("result-allhands", 0.4)
    after_result("allhands", st)
    cmd("go")
    check(cmd("state")["map"]["states"]["review"] == "open", "the review opened")

    # ---------------------------------------------------------------- the review (tactics)
    st = walk_to("review")
    shot("node-review", 0.8)
    for attempt in range(1, 9):
        st = cmd("enter", id="review") if attempt == 1 else cmd("go")
        time.sleep(0.3)
        st = cmd("state")
        check(st["screen"] == "review", "review started (attempt %d, scenario %s)" % (attempt, st["review"]["scenario"]))
        if attempt == 1:
            shot("review-hand", 0.8)
            check(len(st["review"]["hand"]) == 4, "a hand of four lines")
        says = 0
        while st["screen"] == "review" and says < 20:
            st = cmd("say")
            says += 1
            if attempt == 1 and says == 2:
                shot("review-mid", 0.5)
            time.sleep(0.1)
        st = wait_screen(["result", "lvup"], timeout=8)
        while st["screen"] == "lvup":
            cmd("pick", id=(st.get("lvl") or ["caffeine"])[0])
            st = wait_screen(["result", "lvup"])
        if "review" in st["map"]["cleared"]:
            break
        print("  ..   not this quarter (attempt %d), retrying" % attempt)
    shot("result-review", 0.5)
    after_result("review", st)
    cmd("go")

    # ---------------------------------------------------------------- the break room
    st = walk_to("breakroom")
    check(st["screen"] == "breakroom", "the break room")
    shot("breakroom", 0.8)
    c0 = st["profile"]["credits"]
    st = cmd("buy", what="coffee")
    check(st["profile"]["credits"] == c0 - 3, "a coffee costs 3 credits (%d -> %d)" % (c0, st["profile"]["credits"]))
    check(abs(st["profile"]["map"].get("hpNext", 0) - 0.2) < 1e-6 or st["profile"]["map"].get("hpNext", 0) >= 0.2, "and buys +20%% HP for the next run (hpNext %s)" % st["profile"]["map"].get("hpNext"))
    cmd("open", screen="map")

    # ---------------------------------------------------------------- the deploy (both)
    st = walk_to("deploy")
    shot("node-deploy", 0.8)
    st = cmd("enter", id="deploy")
    check(st["screen"] == "placement", "the deploy opens on placement")
    shot("placement-empty", 0.7)
    party = st["profile"]["party"]
    for i, pid in enumerate(party):
        r = cmd("place", tile=i, kind="party", id=pid)
        check(r["why"] == "", "%s placed on tile %d" % (pid, i))
    r = cmd("place", tile=3, kind="gear", id="stapler")
    check(r["why"] == "", "the stapler placed on tile 3")
    r = cmd("place", tile=4, kind="gear", id="chair")
    check(r["why"] == "", "the chair placed on tile 4")
    r = cmd("place", tile=5, kind="gear", id="headphones")
    check(r["why"] == "too_much_gear", "a third gear is refused")
    shot("placement-done", 0.7)
    attempts = 0
    while attempts < 12:
        attempts += 1
        st = cmd("ship") if attempts == 1 else cmd("go")
        time.sleep(0.2)
        st = cmd("state")
        check(st["screen"] == "", "deploy day started (attempt %d)" % attempts)
        mid, boss = False, False
        while True:
            r = cmd("simulate", seconds=4)
            run = r.get("run") or {}
            if r["screen"] == "lvup":
                cmd("pick", id=(run.get("pending") or ["overtime"])[0])
                continue
            if r["screen"] == "result":
                break
            if attempts == 1 and not mid and run.get("t", 0) >= 10:
                shot("deploy-wave", 0.3)
                mid = True
            if attempts == 1 and not boss and run.get("phase") == "boss":
                cmd("simulate", seconds=2)
                shot("deploy-boss", 0.3)
                boss = True
        st = cmd("state")
        if (st.get("run") or {}).get("over") == "clear":
            break
        print("  ..   went home early on deploy, retrying")
    check((st.get("run") or {}).get("over") == "clear", "deploy cleared in %d attempt(s)" % attempts)
    shot("result-deploy", 0.4)
    prof = st["profile"]
    check("badge" in prof["owned"], "the deploy dropped the badge")
    check(prof.get("week") == 1 and prof.get("day") == 0, "friday rolled into week 2 (week %s day %s)" % (prof.get("week"), prof.get("day")))
    cmd("go")
    st = wait_screen(["weekend"])
    check(st["screen"] == "weekend", "the Saturday screen")
    shot("saturday", 1.0)
    cmd("go")
    st = wait_screen(["map"])
    check(st["screen"] == "map" and st["map"]["week"] == 1 and st["map"]["cleared"] == [] and st["map"]["at"] == "lobby", "week 2: a fresh map from the lobby (%s)" % st["map"])
    shot("map-week2", 1.0)
    check(len(prof["owned"]) == 5, "five items owned across the week: %s" % prof["owned"])
    check(prof["party"] == ["intern", "pm", "hr"], "Riley, Morgan and Pat: %s" % prof["party"])
    st = cmd("open", screen="desk")
    shot("desk", 0.9)
    cmd("open", screen="map")
    st = walk_to("standup")
    st = cmd("enter", id="standup")
    cmd("simulate", seconds=10)
    shot("week-2-standup-party", 0.3)

    # ---------------------------------------------------------------- zh-Hans
    cmd("lang", code="zh")
    cmd("open", screen="title")
    shot("title-zh", 0.9)
    cmd("open", screen="map")
    shot("map-zh", 0.9)
    cmd("open", screen="node", id="inbox")
    shot("node-inbox-zh", 0.8)
    cmd("enter", id="inbox")
    shot("triage-zh", 0.8)
    cmd("open", screen="node", id="review")
    cmd("enter", id="review")
    shot("review-zh", 0.8)
    cmd("lang", code="en")
    time.sleep(7.0)   # user:// on the web is IndexedDB, synced on a ~5 s timer
    page.reload()
    boot()
    st = cmd("state")
    check(st["profile"].get("week") == 1 and len(st["profile"]["owned"]) == 5, "profile persisted across a reload")
    check(st["profile"].get("map", {}).get("week") == 1, "the map slice persisted (week %s)" % st["profile"].get("map", {}).get("week"))
    check(st["lang"] == "en", "language persisted (got %r)" % st.get("lang"))
    cmd("open", screen="title")
    shot("title-resume", 0.9)
    check(not popups, "no popups opened (%s)" % popups)
    check(not errors, "no page errors: %s" % errors[:3])
    browser.close()

print("\n%d checks failed" % len(fails) if fails else "\nHEADLESS_OK")
sys.exit(1 if fails else 0)
