#!/usr/bin/env python3
"""Drive the SHIPPING web build in headless Chromium and photograph all four beats.

Why this exists rather than tests/walkthrough.gd, which already does the same job in the
engine: on 2026-09-19 two rules landed that between them close the desktop route.

  * `ops/on_game_monitor.sh` refuses to open a visible game window unless SHOW_GAME=1,
    and `ops/keep_windows_off_docs.sh` kills any Godot window that appears without it —
    because a first-person build calls MOUSE_MODE_CAPTURED and takes Blaze's pointer.
  * Godot's headless display server forces the *dummy* rendering driver. Verified here
    both ways (`--headless`, and `--display-driver headless --rendering-driver vulkan`):
    the walkthrough runs green to WALKTHROUGH_OK and every `get_image()` returns null.
    A capture script that "passes" while photographing nothing is exactly the failure
    mode ops/adult_forks notes keep warning about, so it is written down here.

So the frames come from the browser, through the game's own `window.__cmd` drive hook and
real Playwright keyboard events. That has a second payoff, which is the reason the beat
list here is longer than the engine one: `Gate.board_offer_more("adult")` is drawn by
play/_shared/board.js ON THE PAGE. It does not exist in a desktop run at all, and it was
the one beat the 2026-09-19 report could not verify. It can be verified here.

Note what these frames ARE: the free ads-track web build, which runs on GL compatibility
and carries its own environment tweaks (game.gd, `if OS.has_feature("web")`). They are
what a browser player sees, and they are NOT identical to the desktop paid build.

    ops/other_side_build.sh
    python3 play/the-other-side-godot/tests/web_walkthrough.py --out ops/adult_forks/shots/other-side

localhost is an adult-board host (board.js ADULT_HOST), so the board draws here.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / "build/godot-ads/the-other-side"
PORT = 8061

# Seeded into localStorage before the game boots. Chapters 3 and 4 call Gate.block(),
# which PAUSES THE WHOLE TREE until the page answers; without these the run stalls on an
# ad countdown that is not what this script is testing. The gate itself is tested by
# ops/check_gate_fresh.py, not here.
UNLOCK_KEYS = ["ch3", "ch4", "cg"]

# "goto x z yaw pitch", one per camera position in tests/walkthrough.gd, so a frame here
# is comparable with a frame from there. The engine test aims with look_at(); the drive
# hook takes angles, so the yaw/pitch are precomputed from the same (position, target)
# pairs. Eye height is 1.60 (floor 0.05 + the player's 1.55 head).
#
# Getting this wrong is not a subtle failure and it does not announce itself: the first
# run sent three-number gotos, every frame was shot dead level at an invented yaw, and
# the captures were of walls. They looked like renders.
CAM = {
    "01_wake":          "-4.600 1.600 2.309 -0.067",
    "02_bathroom_door": "-6.800 3.400 2.516 -0.112",
    "03_mirror":        "-7.550 4.800 2.159 -0.116",
    "at_401_door":      "-0.900 2.400 1.571 -0.452",
    "05_401_open":      "-0.300 3.600 0.879 -0.132",
    "06_402_closed":    "0.000 6.400 -2.372 -0.108",
    "at_402_door":      "0.900 8.050 -1.571 -0.452",
    "08_402_inside":    "2.600 8.050 -1.571 -0.087",
    "09_402_print":     "4.500 5.600 0.067 -0.165",
    "approach_far":     "7.590 6.830 -3.142 -0.069",
    "approach_near":    "7.590 7.830 -3.142 -0.096",
    "confront":         "7.590 9.080 -3.142 -0.183",
}


def cmd(page, verb: str, args: str = "") -> None:
    """window.__cmd is read once a frame and cleared; the sequence prefix lets the same
    verb be sent twice in a row without the second one looking like a repeat."""
    cmd.n = getattr(cmd, "n", 0) + 1
    page.evaluate("window.__cmd = %r" % ("%d %s %s" % (cmd.n, verb, args)).strip())
    page.wait_for_timeout(450)


def state(page) -> dict:
    cmd(page, "state")
    page.wait_for_timeout(250)
    return page.evaluate("window.__state || {}") or {}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("/tmp/other-side-web"))
    ap.add_argument("--quick", action="store_true",
                    help="beat 1 only — the palette probe. A full run is minutes of "
                         "software rasterising; tuning light energies against it is not "
                         "a loop anyone will actually run twice.")
    ap.add_argument("--port", type=int, default=PORT)
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)

    if not (BUILD / "index.html").is_file():
        print("no web build at %s — run ops/other_side_build.sh" % BUILD, file=sys.stderr)
        return 2

    srv = subprocess.Popen(
        [sys.executable, str(ROOT / "play/the-other-side-godot/scripts/serve_web.py"),
         "--port", str(a.port), "--dir", str(BUILD)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1.5)
    try:
        return run(a)
    finally:
        srv.terminate()


def run(a) -> int:
    from playwright.sync_api import sync_playwright
    shots: list[tuple[str, Path]] = []
    with sync_playwright() as pw:
        br = pw.chromium.launch(headless=True, args=[
            "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
            "--disable-gpu-sandbox"])
        # 960x540, not 1280x720. There is no GPU in this browser — SwiftShader software
        # rasterises the whole 3D scene, and at 720p a single page.screenshot() runs past
        # its default 30 s timeout waiting for a frame. Same 16:9, a third of the pixels.
        ctx = br.new_context(viewport={"width": 960, "height": 540})
        page = ctx.new_page()
        errs: list[str] = []
        page.on("pageerror", lambda e: errs.append(str(e)))
        page.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
        # 127.0.0.1 rather than localhost: board.js's ADULT_HOST accepts both, but the
        # gate's dist() sniffing keys off the hostname and this is the one the build note
        # documents.
        url = "http://127.0.0.1:%d/" % a.port
        page.add_init_script(
            "try{localStorage.setItem('gate_unlocks',JSON.stringify(%s))}catch(e){}"
            % ("{" + ",".join('"%s":1' % k for k in UNLOCK_KEYS) + "}"))
        page.goto(url, wait_until="load")

        # Boot. The wasm is 40 MB under SwiftShader; the drive hook only answers once
        # game.gd is processing, so poll for it rather than sleeping a guessed amount.
        canvas = page.locator("canvas")
        for _ in range(240):
            page.wait_for_timeout(1000)
            if state(page).get("objective"):
                break
        else:
            print("the game never started; console: %s" % errs[:5], file=sys.stderr)
            return 1

        def shot(name: str) -> None:
            page.wait_for_timeout(900)
            p = a.out / ("%s.png" % name)
            # page.screenshot(clip=...) rather than canvas.screenshot(): an element
            # screenshot first waits for the element to be "stable", and this canvas is
            # NEVER stable — shaders/grain.gdshader animates every frame, so the wait
            # runs to its timeout and no frame is ever taken.
            box = canvas.bounding_box()
            page.screenshot(path=str(p), clip=box, timeout=180_000)
            s = state(page)
            print("SHOT %s  phase=%s chapter=%s choice=%s ending=%s"
                  % (p, s.get("phase"), s.get("chapter"), s.get("choice"), s.get("ending")))
            shots.append((name, p))

        # The splash is a click-to-start overlay on the canvas.
        canvas.click(position={"x": 480, "y": 270})
        page.wait_for_timeout(1200)

        def go(key: str) -> None:
            cmd(page, "goto", CAM[key])

        # ---- Beat 1 ------------------------------------------------------------------
        for name in ("01_wake", "02_bathroom_door", "03_mirror"):
            go(name)
            shot(name)

        cmd(page, "use")                       # look in the mirror
        page.wait_for_timeout(3500)
        shot("04_mirror_looked")

        if a.quick:
            br.close()
            print("\nQUICK  %d frames in %s" % (len(shots), a.out))
            return 0

        # ---- Beat 2 ------------------------------------------------------------------
        # The doors are opened by standing at them and interacting, not by calling
        # game.open_401() the way the engine test can: `use` goes through
        # player.interact_target(), so a door that stopped being reachable fails here.
        go("at_401_door")
        cmd(page, "use")
        page.wait_for_timeout(1500)
        go("05_401_open")                      # from the HALL: the plate faces this way
        shot("05_401_open")
        go("06_402_closed")
        shot("06_402_closed")
        go("at_402_door")
        cmd(page, "use")                       # knock
        page.wait_for_timeout(3000)
        shot("07_402_opens")
        go("08_402_inside")
        shot("08_402_inside")
        go("09_402_print")
        shot("09_402_print")

        # ---- Beat 3 ------------------------------------------------------------------
        # She takes up her post in 402's bathroom doorway once the chapter has turned.
        # Walk in on her and let tenant.gd resolve by distance — the resolve IS the beat,
        # so it is not poked. Her position is read back from the game, not assumed.
        go("approach_far")
        page.wait_for_timeout(2500)
        go("approach_near")
        page.wait_for_timeout(3000)
        print("  she is at %s" % (state(page).get("tenant"),))
        shot("10_tenant_resolving")
        go("confront")
        page.wait_for_timeout(1500)
        for _ in range(40):
            page.wait_for_timeout(500)
            if state(page).get("confronting"):
                break
        s = state(page)
        if not s.get("confronting"):
            print("!! she never triggered confront(); state=%s" % s, file=sys.stderr)
        shot("11_confront")

        # Four lines, click-advanced, then the choice on the last one. Real key events at
        # the page, which is the whole point of driving it here.
        for _ in range(3):
            page.keyboard.press("Space")
            page.wait_for_timeout(700)
        shot("12_choice")
        page.keyboard.press("Digit1")           # 1 = keep her in the mirror
        page.wait_for_timeout(2500)
        shot("13_after_choice")

        # ---- Beat 4 ------------------------------------------------------------------
        go("03_mirror")                        # deliberately the beat-1 framing again
        page.wait_for_timeout(2000)
        shot("14_mirror_after_kept")
        for _ in range(60):
            page.wait_for_timeout(1000)
            if state(page).get("ending"):
                break
        if not state(page).get("ending"):
            print("!! the ending never began", file=sys.stderr)
            return 1
        page.wait_for_timeout(2500)
        shot("15_end")

        # ---- The beat the desktop run cannot have ------------------------------------
        # Gate.board_offer_more("adult") -> BOARD.offerMore() in board.js, drawn as DOM on
        # top of the canvas. A full-page screenshot, not a canvas one: the board is not in
        # the canvas at all, which is precisely why it was never verified before.
        for _ in range(30):
            page.wait_for_timeout(500)
            if page.evaluate("!!document.querySelector('#bc-board, .bc-board, [id*=board]')"):
                break
        p = a.out / "16_board.png"
        page.screenshot(path=str(p))
        drawn = page.evaluate(
            "(function(){var e=document.querySelector('#bc-board, .bc-board, [id*=board]');"
            "if(!e)return null;var t=e.querySelectorAll('a').length;"
            "return {tiles:t, adult_ok:window.BOARD_ADULT_OK, text:(e.innerText||'').slice(0,200)};})()")
        print("SHOT %s  board=%s" % (p, drawn))
        if not drawn:
            print("!! the adult board did not draw", file=sys.stderr)
        shots.append(("16_board", p))
        if errs:
            print("page errors: %s" % errs[:6], file=sys.stderr)
        br.close()

    print("\nWEB_WALKTHROUGH_OK  %d frames in %s" % (len(shots), a.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
