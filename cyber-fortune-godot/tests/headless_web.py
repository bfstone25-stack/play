#!/usr/bin/env python3
"""Drive the web export in headless Chromium through the whole loop, screenshots -> shots/.

    ./build.sh && python3 tests/headless_web.py

Serves build/godot/cyber-fortune/web. Commands go through the dev bridge (Fortune polls
window.__cf_cmd once a frame, answers in window.__cf_result / window.__cf_state); every
command is something a player can also do with a click. Asserts: the engine boots, the
free draw is free and the second costs 100 merit, a 凶 ties to the rack and converts
after the clock moves, the deck turns, each of the reader's four forces reveals the
predicted answer, the board is offered after the daily read (and only then), the shop
grants, the language flips, the save survives a reload, no page errors, no popups.
"""
import http.server, os, socketserver, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
WEB = PROJ.parent.parent / "build" / "godot" / "cyber-fortune" / "web"
SHOTS = PROJ / "shots"
SHOTS.mkdir(exist_ok=True)
for old in SHOTS.glob("*.png"):
    old.unlink()
PORT = 8810 + (os.getpid() % 200)
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
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 720, "height": 1280})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" and "favicon" not in m.text and "blazecore.dev" not in m.text and "ERR_" not in m.text else None)
    page.on("dialog", lambda d: d.dismiss())
    n = [0]
    seq = [0]

    def shot(name, settle=0.6):
        time.sleep(settle)
        n[0] += 1
        path = SHOTS / ("%02d-%s.png" % (n[0], name))
        page.screenshot(path=str(path))
        print("  shot " + path.name)

    def cmd(op, timeout=20.0, **kw):
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

    def wait_for(pred, timeout=40.0, what="state"):
        t0 = time.time()
        while time.time() - t0 < timeout:
            cmd("state")
            if pred(state()):
                return True
            time.sleep(0.2)
        print("  .. timed out waiting for " + what)
        return False

    def board_open():
        return page.evaluate("() => !!document.querySelector('.bd-wrap')")

    def boot():
        t0 = time.time()
        while time.time() - t0 < 120:
            try:
                page.evaluate("() => { window.__cf_cmd = window.__cf_cmd || []; window.__cf_cmd.push({op: 'state', seq: 0}); }")
                time.sleep(0.5)
                if page.evaluate("() => window.__cf_result || null") is not None:
                    return time.time() - t0
            except Exception:
                time.sleep(0.5)
        return None

    page.goto(URL, timeout=180000)
    page.evaluate("() => { try { localStorage.clear(); } catch (e) {} }")
    t = boot()
    check(t is not None, "engine booted and the dev bridge answers (%.0fs)" % (t or 0))
    cmd("reset")
    cmd("lang", lang="en")
    page.reload()
    boot()
    shot("home", 1.2)
    st = state()
    check(st["free_available"], "a fresh account has today's free draw")

    # ---- the slip tube -----------------------------------------------------------------
    cmd("open", screen="tube")
    shot("tube-empty", 0.8)
    for _ in range(12):
        cmd("tap_fish")
        time.sleep(0.05)
    shot("tube-tapping", 0.15)
    st = state()
    check(st["merit"]["merit"] == 12, "twelve taps, twelve merit (got %s)" % st["merit"]["merit"])
    cmd("subject", subject="love")
    r = cmd("shake")
    check(r["ok"], "the free shake starts with 12 merit in the tube")
    time.sleep(0.6)
    shot("tube-shaking", 0.0)
    check(wait_for(lambda s: s.get("shake_done") and s.get("result_open"), 30, "the slip"), "a stick fell out and the slip is up")
    res = cmd("result")["result"]
    check(res.get("free") and res.get("subject") == "love", "the first draw was free and about 情 (%s)" % res.get("rank"))
    shot("slip-read", 0.9)
    check(not board_open(), "no board while the slip is being read")
    cmd("keep")
    time.sleep(0.5)
    st = state()
    check(st["counts"]["slips"] == 1, "kept: the collection has one slip")
    t0 = time.time()
    while time.time() - t0 < 8 and not board_open():
        time.sleep(0.2)
    check(board_open(), "the casual board is offered after the daily read (%.1fs)" % (time.time() - t0))
    shot("board-after-daily", 0.4)
    page.evaluate("() => { const w = document.querySelector('.bd-wrap'); w && w.remove(); }")

    # the second draw costs the tube; hunt an ill slip for the rack
    ill = None
    for i in range(30):
        cmd("merit", n=1000)
        r = cmd("shake")
        if not r["ok"]:
            break
        wait_for(lambda s: s.get("shake_done") and s.get("result_open"), 30, "slip %d" % i)
        res = cmd("result")["result"]
        if i == 0:
            check(not res.get("free"), "the second draw of the day is not free")
            check(state()["merit"]["merit"] == 900, "and cost 100 merit")
        if res["rank"] in ("xiong", "daxiong"):
            ill = res
            break
        cmd("burn")
        time.sleep(0.3)
    check(ill is not None, "an ill slip came within thirty draws (%s)" % (ill and ill["rank"]))
    if ill:
        shot("slip-ill", 0.9)
        ok = cmd("resolve")["ok"]
        check(ok, "化解: tied to the rack")
        time.sleep(0.4)
        check(not board_open(), "no board after a paid draw")
        cmd("open", screen="rack")
        shot("rack-tied", 0.9)
        st = state()
        check(len(st["rack"]) == 1 and not st["rack_ready"][0], "one tied, not ready")
        cmd("advance", ms=61 * 60 * 1000)
        time.sleep(1.2)
        st = state()
        check(st["rack_ready"][0], "after the clock moved an hour it is ready")
        shot("rack-ready", 0.6)
        cmd("claim", i=0)
        time.sleep(0.4)
        st = state()
        check(st["resolved_bonus"] == 1, "claimed: one permanent bonus")
        shot("rack-claimed", 0.6)

    # ---- the deck --------------------------------------------------------------------------
    cmd("open", screen="deck")
    shot("deck", 0.9)
    cmd("cut")
    time.sleep(0.9)
    cmd("merit", n=500)
    r = cmd("turn")
    check(r["ok"], "the deck turns for 100 merit")
    check(wait_for(lambda s: s.get("turn_done") and s.get("result_open"), 30, "the card"), "a card is up")
    res = cmd("result")["result"]
    check(res["kind"] == "card" and "reversed" in res, "a card: %s %s" % (res["id"], "reversed" if res["reversed"] else "upright"))
    shot("card-read", 0.9)
    cmd("keep")
    time.sleep(0.4)
    check(state()["counts"]["cards"] == 1, "the card joined the same collection")

    # ---- the reader ---------------------------------------------------------------------------
    cmd("open", screen="reader")
    shot("reader-door", 1.0)

    def press_text(text):
        r = cmd("buttons")
        texts = r.get("texts", [])
        for i, t in enumerate(texts):
            if t == text:
                return cmd("press", i=i)
        raise SystemExit("no button %r among %r" % (text, texts))

    def wait_reveal(name):
        okk = wait_for(lambda s: s.get("revealed"), 60, name + " reveal")
        return okk

    # binary: think of 37
    cmd("reader", force="binary")
    time.sleep(0.5)
    shot("reader-binary-intro", 0.6)
    press_text("Begin"); time.sleep(0.3)
    press_text("Go on"); time.sleep(0.3)
    for k in range(6):
        if k == 2:
            shot("reader-binary-card", 0.5)
        press_text("It is" if (37 >> k) & 1 else "It is not")
        time.sleep(0.25)
    check(wait_reveal("binary"), "binary: she revealed")
    st = state()
    check(st.get("answer") == "37", "binary force landed on 37 (got %s)" % st.get("answer"))
    shot("reader-binary-reveal", 2.5)
    press_text("Another"); time.sleep(0.4)

    # math
    cmd("reader", force="math"); time.sleep(0.4)
    press_text("Begin"); time.sleep(0.3)
    for k in range(5):
        if k == 4:
            shot("reader-math-table", 0.6)
        press_text("Done"); time.sleep(0.3)
    check(wait_reveal("math"), "math: she revealed")
    check(state().get("answer") == "lantern", "math force landed on the lantern")
    shot("reader-math-reveal", 2.5)
    press_text("Another"); time.sleep(0.4)

    # princess
    cmd("reader", force="princess"); time.sleep(0.4)
    shot("reader-princess-five", 0.8)
    press_text("I have it"); time.sleep(0.3)
    press_text("I have it"); time.sleep(0.3)
    check(wait_reveal("princess"), "princess: she revealed")
    check(state().get("answer") == "gone", "princess: yours is gone")
    shot("reader-princess-reveal", 2.5)
    press_text("Another"); time.sleep(0.4)

    # equivoque: push key + coin, then hand her the feather -> she still has the candle
    cmd("reader", force="equivoque"); time.sleep(0.4)
    press_text("Begin"); time.sleep(0.3)
    press_text("Go on"); time.sleep(0.3)
    shot("reader-equivoque-table", 0.6)
    press_text("key"); time.sleep(0.3)
    press_text("coin")
    check(wait_for(lambda s: s.get("step") == 4, 20, "her aside"), "she spoke about the pushed pair")
    r = cmd("buttons")
    check(sorted(r["texts"]) == ["candle", "feather"], "she set the pushed pair aside; the candle stays (%s)" % r["texts"])
    press_text("feather")
    check(wait_for(lambda s: s.get("step") == 6, 20, "her line on the hand"), "she said which one you kept")
    press_text("Open the note")
    check(wait_reveal("equivoque"), "equivoque: the note opened")
    check(state().get("answer") == "candle", "equivoque landed on the candle")
    shot("reader-equivoque-reveal", 2.5)
    press_text("Thank her and go"); time.sleep(0.5)
    check(state()["screen"] == "home", "thanked her, back home")

    # ---- shop, collection, language ---------------------------------------------------------
    cmd("open", screen="shop")
    shot("shop", 0.9)
    m0 = state()["merit"]["merit"]
    cmd("buy", sku="merit_s")
    time.sleep(0.3)
    check(state()["merit"]["merit"] == m0 + 100, "merit_s granted 100 (mock)")
    cmd("open", screen="rack")
    shot("collection-rack", 0.8)
    cmd("lang", lang="zh")
    time.sleep(0.5)
    cmd("open", screen="home")
    shot("home-zh", 1.0)
    cmd("open", screen="tube")
    cmd("merit", n=500)
    cmd("shake")
    wait_for(lambda s: s.get("shake_done") and s.get("result_open"), 30, "zh slip")
    shot("slip-read-zh", 0.9)
    cmd("keep")
    time.sleep(0.3)
    cmd("open", screen="reader")
    shot("reader-door-zh", 1.0)
    cmd("lang", lang="en")

    # phone width: the layout has to hold
    page.set_viewport_size({"width": 390, "height": 844})
    time.sleep(1.2)
    cmd("open", screen="tube")
    shot("phone-tube", 1.0)
    page.set_viewport_size({"width": 720, "height": 1280})
    time.sleep(0.6)

    # reload: the save persists in user:// (IndexedDB)
    before = state()
    page.reload()
    boot()
    time.sleep(0.8)
    st = state()
    check(st and st["counts"]["slips"] == before["counts"]["slips"] and st["resolved_bonus"] == before["resolved_bonus"], "collection and rack bonus persisted across a reload")
    shot("after-reload", 0.8)

    check(not popups, "no popups opened (%s)" % popups)
    check(not errors, "no page errors: %s" % errors[:3])
    browser.close()

print("\n%d checks failed" % len(fails) if fails else "\nHEADLESS_OK")
sys.exit(1 if fails else 0)
