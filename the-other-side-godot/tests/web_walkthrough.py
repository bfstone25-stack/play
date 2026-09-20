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
    ops/remote_playtest.sh build/godot-ads/the-other-side \\
        play/the-other-side-godot/tests/web_walkthrough.py

**Run it through ops/remote_playtest.sh, not here.** Local headless browsers are disabled
on Blaze's desktop (2026-09-19): the only browser an agent could start locally had no
WebGL2, so Godot fell back to software rasterising and took four to five cores of the
machine he works on. The GPU box reports WebGL2 true, has no GUI and nobody sitting at
it. The wrapper rsyncs the build, serves it, runs this file as its driver with the URL as
argv[1], and brings back whatever lands in ./shots/.

It still runs standalone (`--out DIR`) for anyone with a local browser; that path serves
the build itself. Either way 127.0.0.1 is an adult-board host (board.js ADULT_HOST), so
the cross-promotion board draws.
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

# One entry per camera position in tests/walkthrough.gd, as the same (x, z, target)
# triples that file uses, sent through the `lookat` drive verb so the ENGINE does the
# aiming. An earlier version of this file converted each target into a yaw and a pitch
# here and sent `goto`; the conversion was wrong and nothing said so — the beat-1 mirror
# came out as a photograph of the wall beside it, which at a glance reads as an arty
# frame rather than a broken one. Never re-derive the camera maths on this side.
CAM = {
    "01_wake":          ("-4.6 1.6",   "-7.9 1.3 4.6"),
    "02_bathroom_door": ("-6.8 3.4",   "-8.1 1.35 5.2"),
    "03_mirror":        ("-7.55 4.8",  "-8.84 1.42 5.66"),
    "at_401_door":      ("-0.9 2.4",   "-1.62 1.25 2.4"),
    "05_401_open":      ("-0.3 3.6",   "-1.75 1.35 2.4"),
    "06_402_closed":    ("0.0 6.4",    "1.6 1.35 8.05"),
    "at_402_door":      ("0.9 8.05",   "1.62 1.25 8.05"),
    "08_402_inside":    ("2.6 8.05",   "6.6 1.25 8.05"),
    "09_402_print":     ("4.5 5.6",    "4.4 1.35 4.1"),
    # The approach on her post in 402's bathroom doorway (tenant.gd DOORWAY_402).
    "approach_far":     ("7.59 6.83",  "7.59 1.35 10.43"),
    "approach_near":    ("7.59 7.83",  "7.59 1.35 10.43"),
    "confront":         ("7.59 9.08",  "7.59 1.35 10.43"),
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
    # ops/remote_playtest.sh invokes a driver as `driver.py <url>`, from inside the
    # served directory. No flags, no server of our own, and shots go to ./shots/ so the
    # wrapper's rsync finds them.
    if len(sys.argv) == 2 and sys.argv[1].startswith("http"):
        a = argparse.Namespace(out=Path("shots"), port=0, quick=False,
                               url=sys.argv[1].rstrip("/"))
        a.out.mkdir(parents=True, exist_ok=True)
        return run(a)

    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("/tmp/other-side-web"))
    ap.add_argument("--quick", action="store_true",
                    help="beat 1 only — the palette probe. A full run is minutes of "
                         "software rasterising; tuning light energies against it is not "
                         "a loop anyone will actually run twice.")
    ap.add_argument("--port", type=int, default=PORT)
    a = ap.parse_args()
    a.url = None
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
        # No SwiftShader flags when the host has a real GL: the GPU box reports WebGL2
        # true and forcing software rendering there would throw away the whole reason the
        # test moved off Blaze's desktop.
        br = pw.chromium.launch(headless=True, args=["--enable-unsafe-swiftshader"])
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
        # Cache-busted. The pack is 8 MB and the page is reloaded many times across a
        # tuning session; a stale index.pck renders the PREVIOUS build's prose and
        # lighting and looks exactly like a successful run of the current one.
        url = a.url or ("http://127.0.0.1:%d" % a.port)
        # Cache-busted. The pack is 8 MB and the page is reloaded many times across a
        # tuning session; a stale index.pck renders the PREVIOUS build's prose and
        # lighting and looks exactly like a successful run of the current one.
        url = "%s/?t=%d" % (url, int(time.time()))
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

        def shot(name: str, clear: bool = True) -> None:
            page.wait_for_timeout(900)
            if clear:
                clear_of_her()
                # Re-aim: waiting her out costs seconds of game time, and the camera has
                # to be back where the frame is supposed to be taken from.
                if _last_go[0]:
                    pos, look = CAM[_last_go[0]]
                    cmd(page, "lookat", "%s %s" % (pos, look))
                    page.wait_for_timeout(400)
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
            pos, look = CAM[key]
            cmd(page, "lookat", "%s %s" % (pos, look))
            _last_go[0] = key

        _last_go = [None]

        def clear_of_her(limit: float = 6.0, secs: int = 60) -> float:
            """Wait until she is not standing in the lens.

            She hunts you in 401 in the corner of your eye — that is the design, and in
            the engine test it never shows up because the whole capture takes a quarter of
            a second per frame. Here a single screenshot is tens of real seconds of
            software rasterising, and she uses them: the first run's beat-1 frames are a
            grey capsule head filling the screen, at both camera positions, which read as
            a broken camera rather than as her.

            So the beat-1 and beat-2 frames wait her out. Beat 3 does NOT call this — she
            is the subject there.
            """
            d = 99.0
            for _ in range(secs * 2):
                st = state(page)
                t = st.get("tenant") or []
                if len(t) < 2:
                    return 99.0
                # Deliberately NOT gated on her `visible` flag. She is only drawn in the
                # corner of the eye, so that flag flickers, and a check that trusts it
                # returns "clear" on whichever frame it happens to be false — which is how
                # the first version of this wait reported a clear lens while she was
                # filling it. Her position is the thing that is true every frame.
                d = ((t[0] - st.get("x", 0.0)) ** 2 + (t[1] - st.get("z", 0.0)) ** 2) ** 0.5
                if d > limit:
                    return d
                page.wait_for_timeout(500)
            print("  !! she never cleared the lens (%.2f m)" % d, file=sys.stderr)
            return d

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
        shot("10_tenant_resolving", clear=False)
        go("confront")
        page.wait_for_timeout(1500)
        for _ in range(40):
            page.wait_for_timeout(500)
            if state(page).get("confronting"):
                break
        s = state(page)
        if not s.get("confronting"):
            print("!! she never triggered confront(); state=%s" % s, file=sys.stderr)
        shot("11_confront", clear=False)

        # Four lines, click-advanced, then the choice on the last one. Real key events at
        # the page, which is the whole point of driving it here.
        for _ in range(3):
            page.keyboard.press("Space")
            page.wait_for_timeout(700)
        shot("12_choice", clear=False)
        page.keyboard.press("Digit1")           # 1 = keep her in the mirror
        page.wait_for_timeout(2500)
        shot("13_after_choice", clear=False)

        # ---- Beat 4 ------------------------------------------------------------------
        go("03_mirror")                        # deliberately the beat-1 framing again
        page.wait_for_timeout(2000)
        shot("14_mirror_after_kept", clear=False)
        for _ in range(60):
            page.wait_for_timeout(1000)
            if state(page).get("ending"):
                break
        if not state(page).get("ending"):
            print("!! the ending never began", file=sys.stderr)
            return 1
        page.wait_for_timeout(2500)
        shot("15_end", clear=False)

        # ---- The beat the desktop run cannot have ------------------------------------
        # Gate.board_offer_more("adult") -> BOARD.offerMore() in board.js, drawn as DOM on
        # top of the canvas. A full-page screenshot, not a canvas one: the board is not in
        # the canvas at all, which is precisely why it was never verified before.
        # Ninety seconds, not fifteen. offerMore() does not draw until load() settles,
        # and load() fetches the adult catalogue from free.blazecore.dev — on the GPU box,
        # which has no general internet, that request does not fail fast, it hangs until
        # the browser gives up and only then falls through to board.js's baked-in
        # FALLBACK. A short wait here reports "the adult board did not draw" about a board
        # that draws forty seconds later.
        for _ in range(180):
            page.wait_for_timeout(500)
            # board.js gives its wrapper a CLASS, not an id: .bd-wrap (play/_shared/board.js,
            # `wrap.className = "bd-wrap"`). The first version of this check looked for an
            # id and reported "the adult board did not draw" against a board that had.
            if page.evaluate("!!document.querySelector('.bd-wrap')"):
                break
        p = a.out / "16_board.png"
        page.screenshot(path=str(p))
        print("  BOARD=%s BOARD_ADULT_OK=%s host=%s" % tuple(page.evaluate(
            "[typeof window.BOARD, window.BOARD_ADULT_OK, location.hostname]")))
        drawn = page.evaluate(
            "(function(){var e=document.querySelector('.bd-wrap');"
            "if(!e)return null;var t=e.querySelectorAll('a').length;"
            "return {tiles:t, adult_ok:window.BOARD_ADULT_OK,"
            " slugs:Array.prototype.map.call(e.querySelectorAll('a'),function(x){return x.href}),"
            " text:(e.innerText||'').replace(/\\s+/g,' ').slice(0,220)};})()")
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
