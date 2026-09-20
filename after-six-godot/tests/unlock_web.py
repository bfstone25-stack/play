#!/usr/bin/env python3
"""Prove, in a real browser, that a cleared gate actually SHOWS the delivered plate.

    ./build.sh && python3 tests/unlock_web.py

## What this covers that tests/night_web.py does not

night_web.py proves the negative and it proves it well: on localhost no Adsterra creative
renders, so the fixed gate answers "unavailable" and the plate stays censored. That is the
half that protects the player from a gate that lies in our favour.

Nothing proved the positive, and the positive was broken. `as_cg.gd` ran the gate, recorded
"unlocked", and then drew the same censored plate, because the open bytes are excluded from
every web pack and nothing fetched them (README.md's honest list, item 3). A test that only
ever asserts "still censored" passes just as happily when the reveal can never happen —
which is the shape of check this studio has been bitten by before (memory:
verification-that-lies). So this harness makes the reveal happen and insists on seeing it.

## What is stubbed, and why that is honest

Two things stand in for production, and neither of them is the thing under test:

  * **The gateway.** A local stub serves /unlock/start and /unlock/fetch with the real
    staged bytes. The live gateway is not touched and nothing is deployed — the build only
    talks to the stub because `as_unlock.api_base()` accepts a `window.__as_unlock_api`
    override *and only when the page is served from localhost*.
  * **The gate's verdict.** `window.AfterSixGate.require` is replaced with one that
    resolves "unlocked". Whether a creative really rendered is exactly what night_web.py
    tests; forcing it here isolates the delivery path, which is what broke.

What is NOT stubbed is everything this exists to check: the ticket call, the fetch, the
decode, the write to user://, `is_unlocked` flipping over real bytes, and the engine
drawing the delivered texture instead of the locked one.

The last check is the one that matters most and the easiest to fake: it is not enough that
`censored` went false. The harness samples the engine's own frame and requires that the
pixels actually changed from the censored frame, because "the boolean flipped" is precisely
the lie this whole file is here to catch.
"""
import base64, http.server, io, json, socketserver, sys, threading, time, uuid
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
ROOT = PROJ.parent.parent
WEB = ROOT / "build" / "godot-ads" / "after-six"
SLOT = "cg_return_x"

# Driven remotely when given a URL, the same way tests/night_web.py is — Blaze's desktop no
# longer allows local browser tests. The stub gateway below still runs in *this* process,
# which is the remote box when the runner is driving, so the page reaches it on 127.0.0.1
# exactly as it would reach the real one. Send the plate over first, next to the driver:
#
#     scp play/after-six-godot/assets/cg_open/cg_return_x.webp \
#         bfs@100.121.195.19:~/playtest/cg_return_x.webp
#     PORT=8795 ops/remote_playtest.sh build/godot-ads/after-six \
#         play/after-six-godot/tests/unlock_web.py
#
# It has to be carried over rather than read out of the build, because the open plate is
# excluded from every web pack — which is the thing being tested.
REMOTE_URL = next((a for a in sys.argv[1:] if a.startswith("http")), "")

# The bytes the stub gateway serves: the staged gated asset if it exists, else the open
# plate out of the project. Never the _locked plate — serving the censored art as the
# delivered art would make this test pass while showing the player nothing new.
STAGED = ROOT / "ops/gated_assets/after-six" / (SLOT + ".webp")
OPEN = PROJ / "assets/cg_open" / (SLOT + ".webp")
CARRIED = Path("..") / (SLOT + ".webp")          # beside driver.py on the remote box

if not REMOTE_URL and not (WEB / "index.html").exists():
    sys.exit("no web build at %s — run ./build.sh" % WEB)
SRC = next((p for p in (CARRIED, STAGED, OPEN) if p.exists()), None)
if SRC is None:
    sys.exit("no open plate to deliver (looked for %s, %s and %s).\n"
             "This test needs real bytes and will not invent them." % (CARRIED, STAGED, OPEN))
PLATE = SRC.read_bytes()
fails = []


def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


class Quiet(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(WEB), **k)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *a):
        pass


class Gateway(http.server.BaseHTTPRequestHandler):
    """The two calls, with the gateway's real semantics: a ticket is single-use, and it is
    refused before its dwell has run down (HTTP 425). Both are honoured rather than
    smoothed over, so the client's waiting and retry code is exercised, not bypassed."""
    tickets = {}

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self):
        if not self.path.startswith("/unlock/start"):
            self.send_error(404)
            return
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        if body.get("app") != "after-six" or body.get("key") != SLOT:
            self.send_response(404)
            self._cors()
            self.end_headers()
            self.wfile.write(b'{"ok":false,"error":"unknown asset"}')
            return
        tk = uuid.uuid4().hex
        Gateway.tickets[tk] = {"key": body["key"], "ready_at": time.time() + 1.0}
        out = json.dumps({"ok": True, "ticket": tk, "wait": 1}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.end_headers()
        self.wfile.write(out)

    def do_GET(self):
        from urllib.parse import urlparse, parse_qs
        q = parse_qs(urlparse(self.path).query)
        tk = (q.get("ticket") or [""])[0]
        t = Gateway.tickets.get(tk)
        if not t or (q.get("key") or [""])[0] != t["key"]:
            self.send_response(403)
            self._cors()
            self.end_headers()
            self.wfile.write(b"no")
            return
        if time.time() < t["ready_at"]:
            self.send_response(425)          # too soon; the client waits and retries
            self._cors()
            self.end_headers()
            self.wfile.write(b"too soon")
            return
        del Gateway.tickets[tk]              # single use
        self.send_response(200)
        self.send_header("Content-Type", "image/webp")
        self.send_header("Content-Length", str(len(PLATE)))
        self._cors()
        self.end_headers()
        self.wfile.write(PLATE)

    def log_message(self, *a):
        pass


socketserver.TCPServer.allow_reuse_address = True
srv = None
if REMOTE_URL:
    # The runner already serves the build, with the cross-origin headers Godot needs.
    URL = REMOTE_URL if REMOTE_URL.endswith((".html", "/")) else REMOTE_URL + "/"
else:
    srv = socketserver.TCPServer(("127.0.0.1", 0), Quiet)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    URL = "http://127.0.0.1:%d/index.html" % srv.server_address[1]
# The stub gateway is always ours, and always in this process — on the remote box that is
# still 127.0.0.1 from the page's point of view, which is what as_unlock.api_base() will
# accept an override for.
gw = socketserver.TCPServer(("127.0.0.1", 0), Gateway)
GW_PORT = gw.server_address[1]
threading.Thread(target=gw.serve_forever, daemon=True).start()
GW = "http://127.0.0.1:%d" % GW_PORT
print("== serving build on %s, stub gateway on %s (%d bytes of plate)" % (URL, GW, len(PLATE)))

with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader",
                                      "--enable-unsafe-swiftshader"])
    page = browser.new_page(viewport={"width": 420, "height": 640}, device_scale_factor=2)
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("dialog", lambda d: d.dismiss())

    # Both overrides go in before the engine boots, so the wasm never sees the real gateway.
    page.add_init_script("window.__as_unlock_api = %s;" % json.dumps(GW))
    page.add_init_script("""
        window.addEventListener('load', function () {
          var t = setInterval(function () {
            if (!window.AfterSixGate) return;
            clearInterval(t);
            window.AfterSixGate.require = function () { return Promise.resolve('unlocked'); };
            window.__gate_forced = true;
          }, 50);
        });
    """)

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

    def frame():
        page.evaluate("() => { window.__bm_snap = null; }")
        cmd("snap")
        b64 = page.evaluate("() => window.__bm_snap || null")
        return base64.b64decode(b64) if b64 else b""

    def boot():
        t0 = time.time()
        while time.time() - t0 < 120:
            try:
                page.evaluate("() => { window.__bm_cmd = window.__bm_cmd || []; "
                              "window.__bm_cmd.push({op: 'state', seq: 0}); }")
                time.sleep(0.5)
                if page.evaluate("() => window.__bm_result || null") is not None:
                    return time.time() - t0
            except Exception:
                time.sleep(0.5)
        return None

    page.goto(URL)
    t = boot()
    check(t is not None, "engine booted (%.1fs)" % (t or 0))
    check(page.evaluate("() => window.__gate_forced === true"), "the gate's verdict is stubbed to 'unlocked'")
    cmd("reset")
    cmd("lang", code="en")

    # Drive to the return beat: open the offer and refuse it. `_offer_choose` is what sets
    # case_won and the offer flag, so this earns the slot by exactly the state the game
    # earns it by — no test-only back door into AsCg. night_web.py already plays the whole
    # route with real clicks; this test is about what happens after the slot is earned.
    print("== reach the return, censored")
    cmd("open", screen="offer")
    st = cmd("offer", c="refuse")
    # Refusing lands on offer_done, which waits on its GO button — it is not on a timer, and
    # a harness that only sleeps here sits on the wrong screen while the CG state changes
    # underneath it. That is exactly what the pixel check at the end caught the first time.
    t0 = time.time()
    while time.time() - t0 < 30 and cmd("state").get("screen") != "return":
        cmd("go")
        time.sleep(0.4)
    st = cmd("state")
    check(st.get("screen") == "return", "refusing the offer reaches the return (screen=%s)" % st.get("screen"))
    check(st["case"].get("case_won") and st["case"].get("offer") == "refuse",
          "the slot is earned by real story state (%s)" % st["case"])

    check(st["cg"]["earned"], "the slot is earned by state")
    check(st["cg"]["censored"], "before the gate: the plate is censored")
    check("_locked" in st["cg"]["plate"], "before the gate: the locked plate is what draws (%s)" % st["cg"]["plate"])
    before = frame()
    check(len(before) > 20000, "captured the censored frame (%d bytes)" % len(before))

    print("== clear the gate, and require the delivered bytes to arrive AND draw")
    cmd("cg", do="see", timeout=120.0)
    t0 = time.time()
    st = cmd("state")
    while time.time() - t0 < 60 and not st["cg"]["status"]:
        time.sleep(0.3)
        st = cmd("state")

    check(st["cg"]["status"] == "unlocked", "a cleared gate reports unlocked (status=%s)" % st["cg"]["status"])
    check(not st["cg"]["censored"], "the plate is no longer censored")
    check(st["cg"]["plate"].startswith("user://"), "what draws is the DELIVERED file, not a packed one (%s)" % st["cg"]["plate"])
    after = frame()
    check(len(after) > 20000, "captured the revealed frame (%d bytes)" % len(after))
    # The check that cannot be satisfied by a boolean.
    check(after != before, "the frame actually changed: the delivered image is on screen")
    # "shots" relative when driven remotely: the runner rsyncs that directory back.
    out_dir = Path("shots") if REMOTE_URL else PROJ / "shots"
    out_dir.mkdir(exist_ok=True, parents=True)
    (out_dir / "unlock-delivered.png").write_bytes(after)

    check(not errors, "no page errors (%s)" % (errors[:2] or "none"))
    browser.close()

srv and srv.shutdown()
gw.shutdown()
print("\n%s" % ("UNLOCK_OK" if not fails else "UNLOCK_FAILED: %d" % len(fails)))
sys.exit(1 if fails else 0)
