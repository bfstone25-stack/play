#!/usr/bin/env python3
"""Prove the cross-promotion board actually opens at the end of a run, per game.

Reading the wiring is not evidence: a board whose catalogue fetch fails still opens, still
records board_shown, and shows an empty grid. So this loads each game in a real browser,
drives it to its end-of-run state, and asserts

  * a .bd-wrap panel exists, and
  * it contains at least one .bd-tile (the empty-grid failure), and
  * nothing opened a window by itself (no popups, ever — the F95 lesson).

External requests are blocked on purpose, so what is asserted is the offline fallback path
— the one that used to fail silently. Pass --online to let the real catalogue load instead.

    python3 play/board_smoke.py [game ...] [--online] [--headed]
"""
from __future__ import annotations

import functools
import json
import http.server
import socket
import socketserver
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# path = the index.html served, drive = JS run in the page to reach the end of a run.
# A game whose end state cannot be reached from a script has drive=None and is reported
# as UNVERIFIED rather than quietly passing.
GAMES: dict[str, dict] = {
    "office-landlord": {          # the reference wiring, checked so the harness is honest
        "path": "office-landlord/frontend/index.html",
        "drive": """async () => {
            document.getElementById('startBtn').click();
            await new Promise(r => setTimeout(r, 300));
            document.querySelector('#offers .offer, #offers > *').click();
            const c = document.getElementById('game'), r = c.getBoundingClientRect();
            c.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true,
              clientX: r.left + r.width / 2, clientY: r.top + r.height / 2}));
            await new Promise(x => setTimeout(x, 200));
            document.getElementById('settleBtn').click();   // one piece never makes rent
        }""",
    },
    "fold": {
        "path": "fold/frontend/index.html",
        "drive": """() => { L = 0; load(0);
            tiles = [Object.assign({}, tiles[0], { v: LEVELS[0].target })];
            checkWin(); }""",
    },
    "ghost-channel": {
        "path": "ghost-channel/index.html",
        # The op ends on its own clock, so the clock is fast-forwarded rather than waited
        # out: the run really does reach endOp("timeout").
        "clock": True,
        "steps": [
            "clock:00:02",
            "() => document.getElementById('screen-boot').click()",
            "clock:00:01",
            "() => document.getElementById('btn-start').click()",
            "clock:05:00",
        ],
    },
    "tell": {
        "path": "tell/frontend/index.html",
        # Tell's case and verdict come from a backend this harness has no copy of, so those
        # two responses are stubbed at the network layer. Everything after the response —
        # the verdict screen and the board call on it — is the game's real code.
        "stub": {
            "/state": {
                "case_id": "t1", "title": "Case", "setup": "b", "victim": "V",
                "case_index": 0, "case_total": 7, "solved_today": 0, "clues": [],
                "questions": [{"id": "q1", "text": "q"}],
                "suspects": [{"id": "a", "name": "A", "role": "R", "portrait": 0, "line": "x"},
                             {"id": "b", "name": "B", "role": "R", "portrait": 1, "line": "y"}],
                "reasons": [{"id": "m", "label": "Motive", "text": "Motive"}],
            },
            "/accuse": {
                "correct": True, "suspect_correct": True, "reason_correct": True,
                "culprit_name": "A", "reveal": "r", "reveal_question": "q", "reveal_quote": "v",
            },
        },
        "drive": """async () => {
            await load();                       // the real case-load path, stubbed backend
            await accuse(S.suspects[0].id, S.reasons ? S.reasons[0].id : 'm');
        }""",
    },
    "silvertongue": {"path": "silvertongue/frontend/index.html", "drive": "() => window.win(3)"},
    "flutter": {
        "path": "flutter/frontend/index.html",
        "drive": "() => showEnding({ title: 'End', text: 'test' })",
    },
    "rebound-tycoon": {
        "path": "rebound-tycoon/frontend/index.html",
        "drive": """() => {
            // game.js calls the kernel through window.step, so a wrapper sees the live
            // run state and can end the night through the real nightover branch.
            const real = window.step;
            window.step = function (state) {
              const out = real.apply(this, arguments);
              if (!window.__forcedOver) { window.__forcedOver = 1;
                out.events = (out.events || []).concat([{ type: 'nightover' }]); }
              return out;
            };
            const b = document.getElementById('launchBtn') || document.querySelector('.launch');
            if (b) b.click();
        }""",
    },
    "beat-monday": {
        "path": "beat-monday/frontend/index.html",
        "drive": """async () => {
            const click = id => { const e = document.getElementById(id); if (e) e.click(); };
            click('btnDaily');                                   // home -> story card
            await new Promise(r => setTimeout(r, 400));
            click('storyGo');                                    // story -> match
            await new Promise(r => setTimeout(r, 1200));
            click('btnPause'); await new Promise(r => setTimeout(r, 400));
            click('btnQuit');                                    // quit == run over
        }""",
    },
    "word-pop": {
        "path": "word-pop/frontend/index.html",
        "drive": "() => document.getElementById('reportBtn').click()",
    },
    "slacker-ball": {
        "path": "slacker-ball/frontend/index.html",
        # The wall is cleared by play, which a script cannot do in a useful time, so the
        # kernel's collision call is wrapped to knock the wall down. Everything after that
        # — the wall-clear branch and the board on it — is the game's own code.
        "drive": """async () => {
            const real = window.hitBreakables;
            window.hitBreakables = function (ball, blocks) {
              blocks.forEach(b => { b.hp = 0; }); return real(ball, blocks);
            };
            const b = document.getElementById('launchBtn');
            b.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true}));
            await new Promise(r => setTimeout(r, 400));
            window.dispatchEvent(new PointerEvent('pointerup', {bubbles:true}));
        }""",
    },
    "cyber-merit": {
        "path": "cyber-merit/frontend/index.html",
        "drive": """async () => {
            const c = document.getElementById('game') || document.querySelector('canvas');
            const r = c.getBoundingClientRect();
            for (let i = 0; i < 400; i++) {
              const o = {bubbles:true, clientX:r.left+r.width/2, clientY:r.top+r.height/2};
              c.dispatchEvent(new PointerEvent('pointerdown', o));
              c.dispatchEvent(new PointerEvent('pointerup', o));
              c.dispatchEvent(new MouseEvent('mousedown', o));
              c.dispatchEvent(new MouseEvent('mouseup', o));
              c.dispatchEvent(new MouseEvent('click', o));
              if (document.querySelector('.bd-wrap')) return;
              if (i % 25 === 0) await new Promise(x => setTimeout(x, 30));
            }
        }""",
    },
    "null-shrine": {
        "path": "null-shrine/frontend/index.html",
        # A run here is 20 tickets fired into a WebGL table. Driving all twenty is what the
        # drive below does, but on this headless box the page either pegs the main thread
        # (no GPU) or kills the browser driver partway through, so it is reported PARTIAL:
        # the page is loaded and the board call made, which proves the wiring and the grid,
        # not that the twentieth ball reaches it. Run it --headed on a machine with a GPU
        # to close that gap.
        # Kept, but disabled: firing all twenty tickets under software GL either times out
        # or kills the browser driver on this box (EPIPE partway through the run), which
        # would read as "the board is broken" when it is the harness that died. Re-enable
        # by swapping "drive" for "drive_disabled" on a machine with a GPU.
        "drive": None,
        "why": "WebGL run kills the headless driver on this box; not driven to the end",
        "drive_disabled": """async () => {
            const b = document.getElementById('launchBtn');
            const ev = k => new PointerEvent(k, {bubbles:true, pointerId:1, button:0, isPrimary:true});
            for (let i = 0; i < 26; i++) {
              b.dispatchEvent(ev('pointerdown'));
              await new Promise(r => setTimeout(r, 150));
              b.dispatchEvent(ev('pointerup'));
              await new Promise(r => setTimeout(r, 400));
              if (document.querySelector('.bd-wrap')) return;
            }
            await new Promise(r => setTimeout(r, 6000));
        }""",
    },
    "extra-hook": {
        "path": "extra-hook/frontend/index.html",
        # Minified Vite bundle, no source tree, state held in a React ref that is never
        # exported: reaching the ending means counting hooks in a 3D scene across three
        # nights. Not driveable from a script, so this is reported unverified rather than
        # claimed. The wiring hangs off the one observable thing the run-end does — its
        # localStorage write — see extra-hook/frontend/index.html.
        "drive": None,
        "why": "3D bundle with no exported state; cannot reach night 3 from a script",
    },
}


class Handler(http.server.SimpleHTTPRequestHandler):
    """Serves play/ the way the gateway does: the shared kernel at /kernel, and the games
    that reference themselves absolutely (extra-hook) under their own prefix."""

    def translate_path(self, path: str) -> str:  # noqa: D102
        clean = path.split("?", 1)[0]
        if clean.startswith("/kernel/"):
            return str(ROOT / "catharsis" / clean.lstrip("/"))
        if clean.startswith("/extra-hook/"):
            return str(ROOT / "extra-hook/frontend" / clean[len("/extra-hook/"):])
        return super().translate_path(path)

    def log_message(self, *a, **k):  # noqa: D102, ANN002
        pass


def serve() -> tuple[int, socketserver.ThreadingTCPServer]:
    handler = functools.partial(Handler, directory=str(ROOT))
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", port), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return port, httpd


PORTAL_HOST = "portal.crazygames.example"   # stands in for a portal build's host


def check(pw, port: int, name: str, spec: dict, online: bool, headed: bool,
          portal: bool = False) -> tuple[str, str]:
    """portal=True runs the same drive on a host that is neither ours nor local QA — a
    portal build. Nothing adult may appear there: that agreement is for the game they
    reviewed, and an adult link inside it is what got the F95 account banned."""
    # Software GL: without it the WebGL games (null-shrine) peg the main thread in this
    # headless box and every evaluate() times out — which reads as "broken game", not as
    # "no GPU here".
    args = ["--enable-unsafe-swiftshader", "--disable-gpu", "--no-sandbox", "--disable-dev-shm-usage"]
    if portal:
        args.append(f"--host-resolver-rules=MAP {PORTAL_HOST} 127.0.0.1")
    browser = pw.chromium.launch(headless=not headed, args=args)
    ctx = browser.new_context(viewport={"width": 1100, "height": 800})
    stub = spec.get("stub") or {}

    def handle(route):
        url = route.request.url
        for frag, body in stub.items():
            if frag in url:
                route.fulfill(status=200, content_type="application/json", body=json.dumps(body))
                return
        if online or "127.0.0.1" in url or PORTAL_HOST in url or url.startswith("data:"):
            route.continue_()
        else:
            route.abort()

    ctx.route("**/*", handle)
    if spec.get("clock"):
        ctx.clock.install()   # games whose run ends on a timer are fast-forwarded, not waited on
    page = ctx.new_page()
    popups: list[str] = []
    page.on("popup", lambda p: popups.append(p.url))
    errors: list[str] = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    try:
        host = PORTAL_HOST if portal else "127.0.0.1"
        page.goto(f"http://{host}:{port}/{spec['path']}", wait_until="domcontentloaded", timeout=30000)
        page.wait_for_timeout(600)
        steps = spec.get("steps") or ([spec["drive"]] if spec.get("drive") else [])
        if not steps:
            return "UNVERIFIED", spec.get("why", "no scriptable path to the end of a run")
        for step in steps:
            if step.startswith("clock:"):
                page.clock.run_for(step.split(":", 1)[1])
            else:
                page.evaluate(step)
        if portal:
            page.wait_for_timeout(3000)
            if page.query_selector(".promo-card"):
                return "FAIL", "a portal build showed the adult card"
            adult = page.evaluate("() => !!(window.BOARD && BOARD.adultAllowed())")
            if adult:
                return "FAIL", "a portal build would draw the adult board"
            wrap = page.query_selector(".bd-wrap")
            if wrap and page.eval_on_selector_all(
                    ".bd-wrap .bd-tile", "els => els.some(a => !/free\\.blazecore\\.dev/.test(a.href))"):
                return "FAIL", "a portal build's board carries off-catalogue links"
            return "PASS", "no adult promotion on a portal host"
        page.wait_for_selector(".bd-wrap", timeout=15000)
        tiles = page.eval_on_selector_all(".bd-wrap .bd-tile", "els => els.length")
        if tiles < 1:
            return "FAIL", "board opened with an empty grid"
        blank = page.eval_on_selector_all(
            ".bd-wrap .bd-tile", "els => els.every(a => a.target === '_blank' && a.href)")
        if not blank:
            return "FAIL", "a tile is not a plain link"
        if popups:
            return "FAIL", f"something opened a window by itself: {popups}"
        # the offer must be refusable, and refusing must return the player to the game
        page.eval_on_selector(".bd-wrap .bd-x, .bd-wrap .bd-no", "el => el.click()")
        page.wait_for_timeout(300)
        if page.query_selector(".bd-wrap"):
            return "FAIL", "the board cannot be dismissed"
        if spec.get("partial"):
            return "PARTIAL", f"{tiles} tiles, dismissable — {spec.get('why', '')}"
        return "PASS", f"{tiles} tiles, dismissable" + (f"; page errors: {errors[:1]}" if errors else "")
    except Exception as exc:  # noqa: BLE001
        return "FAIL", f"{type(exc).__name__}: {str(exc)[:160]}"
    finally:
        ctx.close()
        browser.close()


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    online = "--online" in sys.argv
    headed = "--headed" in sys.argv
    portal = "--portal" in sys.argv
    names = args or list(GAMES)
    port, httpd = serve()
    from playwright.sync_api import sync_playwright

    rows = []
    with sync_playwright() as pw:
        for name in names:
            status, note = check(pw, port, name, GAMES[name], online, headed, portal)
            print(f"{status:10} {name:16} {note}", flush=True)
            rows.append((status, name))
    httpd.shutdown()
    bad = [n for s, n in rows if s == "FAIL"]
    unver = [n for s, n in rows if s in ("UNVERIFIED", "PARTIAL")]
    print(f"\n{len(rows) - len(bad) - len(unver)} pass, {len(bad)} fail, "
          f"{len(unver)} not fully verified")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
