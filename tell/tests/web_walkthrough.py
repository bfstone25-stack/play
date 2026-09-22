#!/usr/bin/env python3
"""Drive the actual Tell interrogation loop in headless Chromium and photograph every beat.

Why this exists rather than ops/play_driver.py, which already walks every other title on the
board: Tell is not a Godot canvas. It is a hand-built DOM page (frontend/index.html) whose
core verb is a free-text chat turn -- type a question, press send, read the reply -- and the
generic driver only knows how to click bare coordinates and press control keys (Space,
Enter, arrows, digits, Escape). It never types text into anything.

ops/remote_shots/play/tell/ (captured 2026-09-21, before the driver grew its
menu-left/digit/escape steps) shows exactly what that produces: the driver's blind clicks
happened to land on the mode button and then on a suspect's mugshot -- so it DID reach the
interrogation screen -- but "INTERROGATION 0/12" never moved off zero in any frame, because
nothing ever put text in #inp and clicked #send. play_matrix.py then had only three frames
that differed enough to count as distinct stages: title, case-brief modal, and one suspect's
opening statement. That is a driver gap, not a broken loop -- exactly the pattern the
PUNCHLIST entry predicted and asked someone to go trace.

So this script drives the real DOM: pick a mode, open the casefile, read the brief, pick a
suspect, ask real questions (one typed by hand, the rest via the game's own quick-prompt
chips), swap suspects, accuse, and read the verdict. It is the same shape as
play/the-other-side-godot/tests/web_walkthrough.py -- a per-game driver for a per-game UI,
run through the same wrapper.

**Run it through ops/remote_playtest.sh, not locally.** Blaze's desktop has no headless
browser to spare for this (2026-09-19: it cost four to five cores rendering in software).
The GPU box has no GUI and nobody sitting at it:

    ops/remote_playtest.sh play/tell/frontend play/tell/tests/web_walkthrough.py

Tell's own config.js/index.html route API calls at apps.blazecore.dev whenever the page is
served from 127.0.0.1, localhost or file:// (its IS_PREVIEW check) -- so a plain static
serve of frontend/ on the GPU box still talks to the real, live backend. That means this
run is a real game session (real telemetry, a real /accuse call) against production, the
same as every other remote playtest on this board; it is not a mock.

It still runs standalone (`--out DIR`) for anyone with a local browser to point at a
locally-served frontend/ directory.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FRONTEND = ROOT / "play/tell/frontend"
PORT = 8091


def main() -> int:
    # ops/remote_playtest.sh invokes a driver as `driver.py <url>`, run from inside the
    # served directory, with no flags. Shots go to ./shots/ so the wrapper's rsync finds
    # them.
    if len(sys.argv) == 2 and sys.argv[1].startswith("http"):
        a = argparse.Namespace(out=Path("shots"), port=0, url=sys.argv[1].rstrip("/"))
        a.out.mkdir(parents=True, exist_ok=True)
        return run(a)

    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("/tmp/tell-web"))
    ap.add_argument("--port", type=int, default=PORT)
    a = ap.parse_args()
    a.url = None
    a.out.mkdir(parents=True, exist_ok=True)

    if not (FRONTEND / "index.html").is_file():
        print("no frontend at %s" % FRONTEND, file=sys.stderr)
        return 2

    srv = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(a.port), "--directory", str(FRONTEND)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1.0)
    try:
        return run(a)
    finally:
        srv.terminate()


def run(a) -> int:
    from playwright.sync_api import sync_playwright
    shots: list[str] = []
    with sync_playwright() as pw:
        br = pw.chromium.launch(headless=True, args=["--enable-unsafe-swiftshader"])
        ctx = br.new_context(viewport={"width": 1280, "height": 800})
        pg = ctx.new_page()
        errs: list[str] = []
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.on("console", lambda m: errs.append("%s: %s" % (m.type, m.text))
              if m.type == "error" else None)

        url = a.url or ("http://127.0.0.1:%d" % a.port)
        # NOT wait_until="load": index.html pulls
        # <script src="https://accounts.google.com/gsi/client" async defer> for optional
        # Google sign-in, and the GPU box's network doesn't reach that host cleanly -- the
        # request doesn't fail fast, it hangs, so "load" (which waits on every subresource,
        # async ones included) never fires and this timed out at 60s with the page fully
        # usable underneath. Same syndrome the-other-side's web_walkthrough.py documents
        # for free.blazecore.dev. domcontentloaded is what the game itself waits on to run
        # -- every inline <script> here is synchronous, none deferred to `load`.
        pg.goto(url, wait_until="domcontentloaded", timeout=60000)

        def shot(name: str) -> None:
            p = a.out / ("%s.png" % name)
            pg.screenshot(path=str(p))
            print("SHOT", p)
            shots.append(name)

        # ---- Title ---------------------------------------------------------------
        home = pg.locator("#home")
        home.wait_for(state="visible", timeout=15000)
        pg.wait_for_timeout(1500)          # let the title art / rain settle
        shot("00_title")

        # Run mode, not Daily: Daily writes into the shared "solved today" counter and
        # the percentile leaderboard every other player sees; Run is a private streak.
        pg.locator("#runMode").click()
        pg.wait_for_timeout(300)
        pg.locator("#homeGo").click()

        # ---- Casefile brief --------------------------------------------------------
        brief = pg.locator("#briefOv")
        brief.wait_for(state="visible", timeout=20000)
        shot("01_casefile_brief")

        begin = pg.locator("#briefOv .briefGo")
        begin.wait_for(state="visible", timeout=5000)
        begin.click()
        brief.wait_for(state="hidden", timeout=5000)

        # ---- Interrogation opens -----------------------------------------------------
        inp = pg.locator("#inp")
        inp.wait_for(state="visible", timeout=5000)
        shot("02_interrogation_open")

        # qUsed/cur/done/mode are `let` bindings at the top of a classic (non-module)
        # <script> tag -- they live in the page's global lexical environment, not as
        # properties on `window`, so `window.qUsed` silently reads back undefined. The
        # bare identifier is what actually resolves.
        def q_used() -> int:
            return int(pg.evaluate("qUsed") or 0)

        def cur_suspect() -> str:
            return str(pg.evaluate("cur") or "")

        def wait_for_reply(timeout_s: float = 20.0) -> None:
            # send()/quickAsk() bump qUsed and paint a "(......)" pending turn
            # SYNCHRONOUSLY, before the /ask fetch resolves -- so polling qUsed alone
            # would screenshot the pending placeholder, not the suspect's actual reply.
            deadline = time.time() + timeout_s
            while time.time() < deadline:
                if pg.evaluate("document.querySelectorAll('#line .turn.pending').length") == 0:
                    return
                pg.wait_for_timeout(300)

        first_suspect = cur_suspect()
        if not first_suspect:
            print("!! no suspect selected after load() -- the lineup never populated",
                  file=sys.stderr)
            print("console:", errs[:6], file=sys.stderr)
            return 1

        # ---- A hand-typed question, not a quick-prompt chip -------------------------
        # This is the exact turn play_driver.py can never make: real keyboard input into
        # a real text field, then a real click on #send.
        before = q_used()
        inp.click()
        inp.type("Where were you when it happened?", delay=20)
        pg.locator("#send").click()
        for _ in range(40):
            pg.wait_for_timeout(500)
            if q_used() > before:
                break
        if q_used() <= before:
            print("!! typed question never registered -- qUsed still %d" % q_used(),
                  file=sys.stderr)
            return 1
        wait_for_reply()
        shot("03_after_typed_question")

        # ---- A quick-prompt chip, the game's other input path -----------------------
        prompts = pg.locator("#prompts .prompt")
        if prompts.count() > 0:
            before = q_used()
            prompts.first.click()
            for _ in range(40):
                pg.wait_for_timeout(500)
                if q_used() > before:
                    break
            wait_for_reply()
            shot("04_after_quick_prompt")

        # ---- Swap suspects -----------------------------------------------------------
        mugs = pg.locator(".mug")
        if mugs.count() > 1:
            for i in range(mugs.count()):
                mug = mugs.nth(i)
                mid = mug.get_attribute("id") or ""
                if mid != ("mug-%s" % first_suspect):
                    mug.click()
                    break
            pg.wait_for_timeout(500)
            if cur_suspect() == first_suspect:
                print("!! clicking a second mugshot did not switch suspects",
                      file=sys.stderr)
            shot("05_suspect_switch")

        # ---- Accuse --------------------------------------------------------------
        pg.locator("#accuseBtn").click()
        verdict = pg.locator("#verdict")
        verdict.wait_for(state="visible", timeout=5000)
        shot("06_accuse_suspect_list")

        suspect_btn = verdict.locator("button.accuse").first
        suspect_btn.wait_for(state="visible", timeout=5000)
        suspect_btn.click()
        pg.wait_for_timeout(400)
        shot("07_accuse_reason_list")

        reason_btn = verdict.locator("button.accuse").first
        reason_btn.wait_for(state="visible", timeout=5000)
        reason_btn.click()

        # accuse() sets `done=true` synchronously, BEFORE it awaits the real fetch to
        # the live backend and repaints #verdict -- polling `done` would pass the instant
        # the button is clicked, screenshotting the reason list, not the verdict. The
        # ".rev" reveal div only exists once the response has come back and #verdict's
        # innerHTML has actually been replaced, so wait for that instead.
        try:
            verdict.locator(".rev").wait_for(state="visible", timeout=20000)
        except Exception:
            print("!! accusation never resolved -- no .rev reveal appeared", file=sys.stderr)
            print("console:", errs[:6], file=sys.stderr)
            return 1
        pg.wait_for_timeout(600)
        shot("08_verdict")

        state = pg.evaluate("({qUsed: qUsed, done: done, mode: mode})")
        print("  final state:", state)
        if errs:
            print("  console errors:", errs[:6], file=sys.stderr)
        br.close()

    print("\nTELL_WALKTHROUGH_OK  %d frames in %s" % (len(shots), a.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
