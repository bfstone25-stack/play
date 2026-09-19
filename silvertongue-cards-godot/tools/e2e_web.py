#!/usr/bin/env python3
"""Drive the web export in a headless browser against the live backend and screenshot it.

    ./run.sh                                             # backend on :8929 (play/silvertongue-cards)
    bash ops/godot_build.sh play/silvertongue-cards-godot silvertongue-cards
    python3 play/silvertongue-cards-godot/tools/e2e_web.py [--port 8930]

Starts tools/serve_web.py on the export (same-origin proxy to the backend), opens it in
Chromium, waits for the wasm to boot, then plays through window.stc — the bridge main.gd
installs on the web — a duel to PERSUADED, the gacha ten-pull, the affection ladder, and the
board offer. Screenshots land in shots/ next to the project. Exits 1 on any failed step.
"""
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.request

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(PROJ))
SHOTS = os.path.join(PROJ, "shots")
WEB = os.path.join(ROOT, "build", "godot", "silvertongue-cards", "web")
os.makedirs(SHOTS, exist_ok=True)


def post(url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=10).read())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=0, help="0 = pick a free port")
    ap.add_argument("--backend", default="http://127.0.0.1:8929")
    a = ap.parse_args()
    assert os.path.isfile(os.path.join(WEB, "index.html")), "no web export at " + WEB
    if not a.port:
        import socket
        s = socket.socket()
        s.bind(("127.0.0.1", 0))
        a.port = s.getsockname()[1]
        s.close()
    srv = subprocess.Popen([sys.executable, os.path.join(HERE, "serve_web.py"), "--dir", WEB, "--port", str(a.port), "--backend", a.backend])
    time.sleep(1.0)
    base = f"http://127.0.0.1:{a.port}"
    pid = "e2eweb_" + str(int(time.time()))
    fails = []

    def step(name, cond, detail=""):
        print(("  ok   " if cond else "  FAIL ") + name + (" " + detail if detail and not cond else ""))
        if not cond:
            fails.append(name)

    try:
        # the pytest fixture's winning deck, through the real endpoint
        urllib.request.urlopen(f"{a.backend}/cards/state?pid={pid}").read()
        post(f"{a.backend}/cards/dev/gold", {"pid": pid, "amount": 2000})
        deck = ["mara_01", "mara_03", "mara_05"] * 2 + ["ines_03", "ines_04", "sanne_01", "sanne_02", "teodora_01", "teodora_02"]
        r = post(f"{a.backend}/cards/deck", {"pid": pid, "scenario": "closing_time", "deck": deck})
        assert r.get("ok"), r

        with sync_playwright() as p:
            browser = p.chromium.launch(args=["--enable-unsafe-webgpu", "--use-gl=swiftshader", "--ignore-gpu-blocklist"])
            page = browser.new_page(viewport={"width": 1280, "height": 720})
            errors = []
            page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
            page.goto(base + "/index.html")

            def call(cmd, arg=None, timeout=30):
                page.evaluate("([c,a]) => window.stc.call(c, a)", [cmd, arg])
                t0 = time.time()
                while time.time() - t0 < timeout:
                    res = page.evaluate("() => window.stc.result()")
                    if res is not None:
                        return json.loads(res)
                    time.sleep(0.1)
                raise TimeoutError(cmd)

            # boot: the bridge appears once main._ready ran
            t0 = time.time()
            while time.time() - t0 < 90:
                if page.evaluate("() => !!(window.stc && window.stc.call)"):
                    break
                time.sleep(0.5)
            step("wasm booted, bridge present", page.evaluate("() => !!(window.stc && window.stc.call)"))
            call("mute")
            snap = call("set_pid", pid)
            step("identity swapped to the test pid", snap.get("pid") == pid, str(snap))
            call("go", "home")
            time.sleep(1.2)
            page.screenshot(path=os.path.join(SHOTS, "w01_home.png"))
            call("difficulty", "silver")
            r = call("start", {"scenario": "closing_time"})
            step("duel started", r.get("ok"), str(r))
            time.sleep(1.4)
            page.screenshot(path=os.path.join(SHOTS, "w02_duel_start.png"))

            wanted = ["mara_01", "mara_03", "mara_05"]
            turns = 0
            last = {}
            wild_done = False
            while turns < 20:
                snap = call("snapshot")
                d = snap.get("duel") or {}
                if snap.get("ended") or d.get("over"):
                    break
                if snap.get("hand_state") != 0:
                    time.sleep(0.2)
                    continue
                hand = d.get("hand", [])
                nerve = int(d.get("nerve", 1))
                if nerve >= 2 and int(d.get("wild_left", 0)) > 0 and not wild_done:
                    call("wild_open")
                    call("wild_type", "Long day for you too, I'd guess.")
                    time.sleep(0.4)
                    page.screenshot(path=os.path.join(SHOTS, "w03_wild_typed.png"))
                    last = call("wild_submit")
                    step("wild line scored by the engine", last.get("read", {}).get("card") == "wild", str(last)[:200])
                    wild_done = True
                    turns += 1
                    time.sleep(1.5)
                    page.screenshot(path=os.path.join(SHOTS, "w04_reply.png"))
                    continue
                pick = ""
                for c in hand:
                    if wanted and c["id"] == wanted[0] and int(c["cost"]) <= nerve:
                        pick = c["id"]
                        wanted.pop(0)
                        break
                if not pick:
                    fill = [c for c in hand if not c["harms"] and int(c["cost"]) <= nerve and c["id"] not in wanted]
                    if not fill:
                        fill = [c for c in hand if not c["harms"] and int(c["cost"]) <= nerve]
                    pick = min(fill, key=lambda c: int(c["cost"]))["id"]
                last = call("play", {"card": pick})
                step(f"turn {turns + 1}: {pick}", "error" not in last, str(last)[:200])
                turns += 1
                if turns == 3:
                    time.sleep(1.2)
                    page.screenshot(path=os.path.join(SHOTS, "w05_duel_midway.png"))
            step("PERSUADED", last.get("end", {}).get("won") is True, str(last.get("end"))[:200])
            time.sleep(2.4)
            page.screenshot(path=os.path.join(SHOTS, "w06_persuaded.png"))

            # the board, on the explicit MORE LIKE THIS press (here: the bridge's "board")
            call("board")
            time.sleep(1.5)
            has_board = page.evaluate("() => !!document.querySelector('.bd-wrap')")
            tiles = page.evaluate("() => document.querySelectorAll('.bd-tile').length")
            step("board offered in-page on explicit press", has_board, f"bd-wrap={has_board} tiles={tiles}")
            page.screenshot(path=os.path.join(SHOTS, "w07_board_offer.png"))
            page.evaluate("() => { var w = document.querySelector('.bd-wrap'); w && w.remove(); }")

            call("go", "gacha")
            time.sleep(1.0)
            page.screenshot(path=os.path.join(SHOTS, "w08_gacha.png"))
            r = call("pull", 10, timeout=60)
            step("ten-pull", r.get("ok") and len(r.get("cards", [])) == 10, str(r)[:200])
            time.sleep(1.0)
            page.screenshot(path=os.path.join(SHOTS, "w09_gacha_tenpull.png"))
            call("go", "affection")
            time.sleep(2.0)
            page.screenshot(path=os.path.join(SHOTS, "w10_affection.png"))
            call("go", "deck")
            time.sleep(1.5)
            page.screenshot(path=os.path.join(SHOTS, "w11_deck.png"))

            # phone landscape
            page.set_viewport_size({"width": 844, "height": 390})
            r = call("start", {"scenario": "the_key"})
            time.sleep(1.6)
            page.screenshot(path=os.path.join(SHOTS, "w12_phone_landscape_duel.png"))
            post(f"{a.backend}/cards/forfeit", {"pid": pid})

            bad = [e for e in errors if "favicon" not in e]
            step("no console errors", not bad, "; ".join(bad[:5]))
            src = page.content()
            step("no /say in the page", "/say" not in src)
            browser.close()
    finally:
        srv.terminate()
    print("== %s" % ("ALL OK" if not fails else "FAILED: " + ", ".join(fails)))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
