#!/usr/bin/env python3
"""Actually execute the story scripts, without Ren'Py.

tools/check_rpy.py is static and tools/playthrough.py exercises the rules module. Neither of
them runs the game. A real SDK is available (see README) but takes minutes per route and needs
a display, so this is the fast way to play it: a small interpreter for the
subset of Ren'Py the story files actually use — label / jump / call / return / menu (including
conditional options) / if-elif-else / $ / python: / scene / show / say / with / play / stop /
call screen — driven by a scripted list of menu choices.

The distribution and telemetry layers are stubbed (they are copied near-verbatim from
play/room-704 and have shipped twice); everything in 00_init.rpy through 08_reading.rpy is
the real file, read off disk and executed.

    python3 tools/simulate.py                 # all routes, summary only
    python3 tools/simulate.py --transcript 2  # print the full text of route 2
"""

import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "game", "scripts")
sys.path.insert(0, os.path.join(ROOT, "game", "python-packages"))

STORY_FILES = ["00_init.rpy", "01_shop.rpy", "02_ring.rpy", "03_veil.rpy",
               "04_market.rpy", "05_collateral.rpy", "06_dawn.rpy", "08_reading.rpy"]

# Statements that are presentation-only for our purposes.
IGNORE = re.compile(
    r"^(scene|show|hide|with|play|stop|pause|window|nvl|voice|queue|image|define|transform|"
    r"screen|style|init|default)\b")


class Block(object):
    __slots__ = ("line", "lineno", "file", "children")

    def __init__(self, line, lineno, file):
        self.line, self.lineno, self.file, self.children = line, lineno, file, []


def parse(path):
    """Indentation -> tree. Returns the top-level list of Blocks."""
    lines = open(path, encoding="utf-8").read().splitlines()
    root = []
    stack = [(-1, root)]
    for i, raw in enumerate(lines):
        if not raw.strip() or raw.strip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        while stack and indent <= stack[-1][0]:
            stack.pop()
        b = Block(raw.strip(), i + 1, os.path.basename(path))
        stack[-1][1].append(b)
        stack.append((indent, b.children))
    return root


class Jump(Exception):
    def __init__(self, label):
        self.label = label


class Return(Exception):
    pass


class Sim(object):
    def __init__(self, choices, transcript=False):
        self.labels = {}
        self.g = {}
        self.text = []
        self.choices = list(choices)
        self.choice_log = []
        self.transcript = transcript
        self.unlocked = set()
        self.gates_seen = []
        self.steps = 0
        self._load()

    # -- setup -------------------------------------------------------------
    def _load(self):
        import collateral_core as core

        class Store(object):
            pass

        store = Store()
        store.run = None
        persistent = Store()
        persistent.unlocked_cgs = None

        class _Music(object):
            def register_channel(self, *a, **k):
                pass

        class _Renpy(object):
            emscripten = False
            music = _Music()
            def loadable(self, *a):
                return True

        def tel_track(name, data=None, dur=None):
            self.g["_tel"].append(name)

        def cg_gate(name):
            self.gates_seen.append(name)

        def unlock_cg(name):
            self.unlocked.add(name)

        # Stubs for the dist layer. "paid" is the track a buyer is on, so reading_delivered
        # is True and no fee gets refunded; route 5 below flips this to exercise the refund.
        self.g.update(dict(
            core=core, store=store, persistent=persistent,
            tel_track=tel_track, tel_flush=lambda *a, **k: None,
            unlock_cg=unlock_cg, is_cg_unlocked=lambda n: n in self.unlocked,
            cg_pick=lambda n: "cg " + n, cg_gate=cg_gate,
            dist_track=lambda: self.g.get("_track", "paid"),
            is_ad_unlocked=lambda k: False, gated_ready=lambda n: False,
            GATED_CGS=("finial", "ring", "veil", "market", "collateral"),
            renpy=_Renpy(), config=Store(), COLLATERAL_WEB_DEMO=True,
            _tel=[], _track="paid",
        ))
        self.g["config"].version = "1.0.0"

        # The init python blocks out of 00_init.rpy, executed for real.
        init_src = open(os.path.join(SCRIPTS, "00_init.rpy"), encoding="utf-8").read()
        for m in re.finditer(r"^init(?:\s+-?\d+)?\s+python:\n((?:(?:    .*)?\n)+)",
                             init_src, re.M):
            body = "\n".join(l[4:] if l.startswith("    ") else l
                             for l in m.group(1).splitlines())
            body = body.replace("import collateral_core as core", "")
            try:
                exec(compile(body, "00_init.rpy", "exec"), self.g)
            except Exception as exc:  # pragma: no cover
                print("  init python block failed: %r" % exc)
        self.g["LEDGER_TITLES"] = self.g.get("LEDGER_TITLES", [])
        # `run` is a Ren'Py `default`, i.e. a store variable; new_run() sets store.run and the
        # scripts then read bare `run`, so keep the two in step.
        self.g["run"] = None

        for f in STORY_FILES:
            for b in parse(os.path.join(SCRIPTS, f)):
                m = re.match(r"label\s+([A-Za-z_]\w*)\s*(\(.*\))?\s*:", b.line)
                if m:
                    self.labels[m.group(1)] = b

    def _sync(self):
        self.g["run"] = self.g["store"].run

    def ev(self, expr):
        self._sync()
        return eval(expr, self.g)

    def interpolate(self, s):
        def sub(m):
            try:
                return str(self.ev(m.group(1)))
            except Exception:
                return m.group(0)
        s = re.sub(r"\{/?[a-z=#\d]*\}", "", s)
        return re.sub(r"\[([^\]\[]+)\]", sub, s)

    # -- execution ---------------------------------------------------------
    def run_label(self, name):
        if name not in self.labels:
            return                      # stubbed dist/telemetry label
        try:
            self.exec_block(self.labels[name].children)
        except Return:
            pass

    def exec_block(self, blocks):
        i = 0
        while i < len(blocks):
            b = blocks[i]
            line = b.line
            self.steps += 1
            if self.steps > 200000:
                raise RuntimeError("runaway: possible infinite loop")

            if line.startswith("##") or line.startswith("#"):
                i += 1
                continue

            m = re.match(r"jump\s+([A-Za-z_]\w*)$", line)
            if m:
                raise Jump(m.group(1))

            if line == "return" or line.startswith("return "):
                raise Return()

            m = re.match(r"call\s+screen\s+([A-Za-z_]\w*)", line)
            if m:
                i += 1
                continue

            m = re.match(r"call\s+([A-Za-z_]\w*)(?:\(([^)]*)\))?", line)
            if m and not line.startswith("call screen"):
                target, arg = m.group(1), m.group(2)
                if target in self.labels:
                    saved = self.g.get("_arg")
                    if arg:
                        try:
                            self.g["item"] = self.ev(arg)
                            self.g["n"] = self.g["item"]
                        except Exception:
                            pass
                    try:
                        self.run_label(target)
                    except Jump as j:
                        self._resolve_jump(j)
                    self.g["_arg"] = saved
                elif target == "cg_gate" and arg:
                    self.gates_seen.append(self.ev(arg))
                i += 1
                continue

            if line.startswith("$ "):
                self._sync()
                exec(compile(line[2:], b.file, "exec"), self.g)
                i += 1
                continue

            if re.match(r"python\s*:", line):
                src = self._dedent(b.children)
                self._sync()
                exec(compile(src, b.file, "exec"), self.g)
                i += 1
                continue

            if line.startswith("menu:"):
                self._menu(b)
                i += 1
                continue

            m = re.match(r"if\s+(.+):$", line)
            if m:
                taken = bool(self.ev(m.group(1)))
                if taken:
                    self.exec_block(b.children)
                else:
                    j = i + 1
                    while j < len(blocks):
                        nb = blocks[j]
                        me = re.match(r"elif\s+(.+):$", nb.line)
                        if me:
                            if bool(self.ev(me.group(1))):
                                self.exec_block(nb.children)
                                break
                            j += 1
                            continue
                        if nb.line == "else:":
                            self.exec_block(nb.children)
                        break
                # skip the whole if/elif/else chain
                i += 1
                while i < len(blocks) and (blocks[i].line.startswith("elif ")
                                           or blocks[i].line == "else:"):
                    i += 1
                continue

            if line.startswith("elif ") or line == "else:":
                i += 1
                continue

            m = re.match(r'([a-z_]\w*)\s+"(.*)"$', line, re.S)
            if m and not IGNORE.match(line):
                who, what = m.group(1), m.group(2)
                said = self.interpolate(what)
                self.text.append((who, said))
                if self.transcript:
                    print(("    %s: %s" % (who, said)) if who != "nar" else "    %s" % said)
                i += 1
                continue

            i += 1

    def _dedent(self, children):
        # children were stripped at parse time; re-emit them as a flat python block.
        out, stack = [], []

        def walk(blocks, depth):
            for c in blocks:
                out.append("    " * depth + c.line)
                walk(c.children, depth + 1)
        walk(children, 0)
        return "\n".join(out)

    def _menu(self, b):
        opts = []
        for c in b.children:
            m = re.match(r'"(.*?)"(?:\s+if\s+(.+?))?\s*:$', c.line)
            if m:
                cond = m.group(2)
                if cond is not None and not bool(self.ev(cond)):
                    continue
                opts.append((self.interpolate(m.group(1)), c))
        if not opts:
            return
        want = self.choices.pop(0) if self.choices else 0
        if isinstance(want, str):
            idx = next((k for k, (t, _) in enumerate(opts)
                        if want.lower() in t.lower()), 0)
        else:
            idx = min(want, len(opts) - 1)
        label, chosen = opts[idx]
        self.choice_log.append(label)
        if self.transcript:
            print("    > %s" % label)
        self.exec_block(chosen.children)

    def _resolve_jump(self, j):
        label = j.label
        while True:
            try:
                self.run_label(label)
                return
            except Jump as nj:
                label = nj.label

    def play(self, track="paid"):
        self.g["_track"] = track
        try:
            self.run_label("start")
        except Jump as j:
            self._resolve_jump(j)
        except Return:
            pass
        self._sync()
        return self.g["run"]


# ---------------------------------------------------------------------------

ROUTES = [
    # Menus, in order: finial read? / finial price / ring read? / ring price /
    # veil read? / veil price / Calder's offer (only when you carry a reading).
    ("Mercy — read everything, pay HIGH throughout, refuse Calder",
     ["Put a hand", "HIGH", "Take the reading anyway", "HIGH", "Read it. (", "HIGH", "Don't."],
     "paid"),
    ("Honest — read everything, pay FAIR throughout, refuse Calder",
     ["Put a hand", "FAIR", "Take the reading anyway", "FAIR", "Read it. (", "FAIR", "Don't."],
     "paid"),
    ("Ruthless — refuse every reading, pay LOW throughout",
     ["Leave it.", "LOW", "Don't. He asked", "LOW", "Don't. It's a widow", "LOW"],
     "paid"),
    ("Factor — read two, then sell one to Calder",
     ["Put a hand", "FAIR", "Take the reading anyway", "FAIR", "Don't. It's a widow", "FAIR",
      "Sell him"],
     "paid"),
    ("Free track — pay the ring fee, gate leaves it censored (refund path)",
     ["Put a hand", "FAIR", "Take the reading anyway", "FAIR", "Read it. (", "FAIR", "Don't."],
     "itch_web"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--transcript", type=int, default=None,
                    help="1-based route index to print in full")
    args = ap.parse_args()

    import collateral_core as core
    failures = []

    for n, (name, choices, track) in enumerate(ROUTES, 1):
        show = args.transcript == n
        print("\nRoute %d: %s   [track=%s]" % (n, name, track))
        sim = Sim(choices, transcript=show)
        try:
            run = sim.play(track)
        except Exception as exc:
            print("  CRASHED: %s: %s" % (type(exc).__name__, exc))
            failures.append(name)
            continue

        ending = core.ending_of(run)
        cgs = core.unlocked_cgs(run)
        print("  lines played : %d" % len(sim.text))
        print("  choices      : %s" % " | ".join(c[:34] for c in sim.choice_log))
        print("  till         : %d   stock %d   net %d (debt %d)"
              % (run.till, run.stock_value(), run.net_worth(), core.DEBT))
        print("  readings     : taken=%s refused=%s" % (run.readings_taken, run.readings_refused))
        print("  fees         : paid=%d refunded=%d" % (run.fees_paid, run.fees_refunded))
        print("  CG gates hit : %s" % (sim.gates_seen or "none"))
        print("  CGs unlocked : %s" % (cgs or "none"))
        print("  ENDING       : %s" % core.ENDING_NAMES[ending])

        if not sim.text:
            failures.append("%s: played no text" % name)
        if not cgs:
            failures.append("%s: reached the end with no CG unlocked" % name)
        if track == "itch_web" and run.fees_refunded == 0:
            failures.append("%s: free track charged a fee and refunded nothing" % name)

    print("\n%d route(s), %d failure(s)" % (len(ROUTES), len(failures)))
    for f in failures:
        print("  FAILED: %s" % f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
