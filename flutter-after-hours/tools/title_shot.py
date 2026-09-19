#!/usr/bin/env python3
"""Photograph the title screen and prove it is alive.

    python3 tools/title_shot.py [url] [--out DIR]

The three Godot forks each have a tests/title_shot.gd that takes two frames a second
apart and fails if they are byte-identical; this is the same check for the web VN, which
is the one title in the set whose motion is CSS and rAF rather than a Godot _process. A
still that draws is still a failure of the title pass.

It shoots both screens, because this game has two: the launch gate (the actual first
frame anyone sees) and the route-selection screen behind it. Both carry the key visual
and the mark, and both are checked.

The age wall is dismissed the way a player dismisses it — by clicking its own button —
rather than by writing its storage key, so the shot is of the page a player reaches.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent.parent


def shoot(url: str, out: Path) -> int:
    out.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as pw:
        # Headless chromium crashes on this page with the default GPU path (the
        # selection screen animates three card backdrops at once); software GL is
        # slower and does not fall over.
        b = pw.chromium.launch(args=["--disable-gpu", "--use-gl=swiftshader",
                                     "--disable-dev-shm-usage", "--no-sandbox"])
        pg = b.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
        pg.goto(url, wait_until="networkidle")

        # The 18+ wall, clicked.
        try:
            pg.get_by_role("button", name="I am 18 or older").first.click(timeout=4000)
        except Exception:
            pass
        pg.wait_for_timeout(2600)   # the mark settles at .6s + 1.8s

        # The launch gate IS this game's title screen — the first frame a player sees —
        # so it takes the title name; the route board is shot beside it.
        gate_a = out / "flutter-after-hours.png"
        pg.screenshot(path=str(gate_a))
        tmp = out / ".gate_b.png"
        pg.wait_for_timeout(1400)
        pg.screenshot(path=str(tmp))
        moving = gate_a.read_bytes() != tmp.read_bytes()
        tmp.unlink(missing_ok=True)

        # Then the selection screen.
        # Then the route board behind it. enterSelection() plays the opening cinematic on
        # the way, which an earlier version of this script photographed instead of the
        # board; going straight to the board is what is being photographed here.
        pg.evaluate("""() => {
            document.querySelectorAll('#opening,#brandIntro,#launchGate')
                    .forEach(e => e.style.display = 'none');
            const s = document.getElementById('select');
            s.classList.add('reveal');
            s.style.display = 'flex';
        }""")
        pg.wait_for_timeout(2600)
        sel = out / "flutter-after-hours-board.png"
        pg.screenshot(path=str(sel))

        marks = pg.evaluate("""() => {
            const q = s => !!document.querySelector(s);
            const kv = document.querySelector('#select .kv-layer');
            return {
                gateMark: q('#launchGate .gate-mark'),
                selMark: q('#select .brand-mark'),
                keyVisual: !!kv && getComputedStyle(kv).backgroundImage.indexOf('keyvisual') >= 0,
                rating: q('#select .title-marks .rating'),
                motionModule: !!window.FLUTTER_TITLE,
            };
        }""")
        b.close()

    bad = [k for k, v in marks.items() if not v]
    if bad:
        print(f"MISSING on the title screen: {', '.join(bad)}", file=sys.stderr)
        return 1
    if not moving:
        print("the launch gate is a still: two frames 1.4 s apart are identical", file=sys.stderr)
        return 1
    print(f"TITLE_SHOT_OK moving=true -> {gate_a} and {sel.name}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("url", nargs="?", default="http://localhost:8799/")
    ap.add_argument("--out", type=Path, default=HERE.parent.parent / "ops/adult_forks/shots/titles")
    a = ap.parse_args()
    return shoot(a.url, a.out)


if __name__ == "__main__":
    raise SystemExit(main())
