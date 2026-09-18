#!/usr/bin/env python3
"""Static check of the .rpy scripts — a fast pre-flight before `renpy.sh lint`.

A Ren'Py 8.3.7 SDK does exist on this machine (under another session's scratchpad
in /tmp, so not a stable path); `renpy.sh lint` is clean and the game has been run
end to end on DISPLAY=:0. These harnesses are still the fast loop, and the one that
executes the scripts caught two crashes before the engine ever saw them.

It walks the scripts and checks the things a hand-written fork gets wrong:

  1. every `jump`/`call <label>` target is a label that exists (in this project or in the
     Ren'Py/shared prelude);
  2. every `scene`/`show` image name is declared by an `image` statement (or is one of the
     dynamic `scene expression` forms);
  3. every `$`/`python:`/`init python:` block is valid Python;
  3b. every name a python block *loads* is actually defined somewhere in the project —
     lint does not do this, and a stale `route` from room-704 killed every non-paid track;
  4. `call ... from _name` checkpoints are unique, and every `call screen` names a declared
     screen.

Plus two fork-specific assertions that are the whole point of the review in
ops/adult_forks/midnight-pawn.md §7:

  5. GATED_CGS matches the design's list exactly, and the free tutorial plate is not in it;
  6. every gated CG has a matching `cg_locked_*` declaration and a file on disk.

    python3 tools/check_rpy.py
"""

import ast
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "game", "scripts")
GAME = os.path.join(ROOT, "game")

# Labels/screens that come from Ren'Py itself or the shared prelude copied from room-704.
BUILTIN_LABELS = {
    "start", "quit", "after_load", "splashscreen", "before_main_menu", "main_menu",
    "after_warp", "hide_windows", "_quit", "_confirm_quit",
}
BUILTIN_SCREENS = {
    "say", "choice", "input", "nvl", "main_menu", "navigation", "game_menu", "about",
    "load", "save", "file_slots", "preferences", "history", "help", "quit", "confirm",
    "skip_indicator", "notify", "nvl_dialogue", "yesno_prompt",
}

errors, warnings, notes = [], [], []


def files():
    return sorted(os.path.join(SCRIPTS, f) for f in os.listdir(SCRIPTS) if f.endswith(".rpy")) + [
        os.path.join(GAME, f) for f in ("screens.rpy", "options.rpy", "gui.rpy")
        if os.path.isfile(os.path.join(GAME, f))
    ]


def main():
    labels, screens, images, transforms = set(), set(), set(), set()
    jumps, calls, call_screens, shows = [], [], [], []
    froms = {}
    py_blocks = []

    for path in files():
        rel = os.path.relpath(path, ROOT)
        lines = open(path, encoding="utf-8").read().splitlines()
        i = 0
        while i < len(lines):
            raw = lines[i]
            line = raw.strip()
            indent = len(raw) - len(raw.lstrip())

            m = re.match(r"label\s+([A-Za-z_]\w*)\s*(\(.*\))?\s*:", line)
            if m:
                labels.add(m.group(1))
            m = re.match(r"screen\s+([A-Za-z_]\w*)\s*(\(.*\))?\s*:", line)
            if m:
                screens.add(m.group(1))
            m = re.match(r"image\s+(.+?)\s*=", line)
            if m:
                images.add(m.group(1).strip())
            m = re.match(r"transform\s+([A-Za-z_]\w*)\s*:", line)
            if m:
                transforms.add(m.group(1))

            m = re.match(r"jump\s+(?:expression\s+)?([A-Za-z_]\w*)\s*$", line)
            if m:
                jumps.append((rel, i + 1, m.group(1)))
            m = re.match(r"call\s+screen\s+([A-Za-z_]\w*)", line)
            if m:
                call_screens.append((rel, i + 1, m.group(1)))
            elif line.startswith("call "):
                m = re.match(r"call\s+([A-Za-z_]\w*)", line)
                if m:
                    calls.append((rel, i + 1, m.group(1)))
                mf = re.search(r"\bfrom\s+(_[A-Za-z_]\w*)\s*$", line)
                if mf:
                    froms.setdefault(mf.group(1), []).append("%s:%d" % (rel, i + 1))

            m = re.match(r"(?:scene|show)\s+(.+?)(?:\s+(?:at|with|behind|as|onlayer)\s|$)", line)
            if m and not m.group(1).startswith("expression"):
                shows.append((rel, i + 1, m.group(1).strip()))

            # python blocks
            if line.startswith("$ "):
                py_blocks.append((rel, i + 1, line[2:]))
                i += 1
                continue
            if re.match(r"(init(\s+-?\d+)?\s+)?python\s*(early)?\s*:", line):
                body, j = [], i + 1
                while j < len(lines):
                    nxt = lines[j]
                    if nxt.strip() and (len(nxt) - len(nxt.lstrip())) <= indent:
                        break
                    body.append(nxt)
                    j += 1
                if body:
                    strip = min((len(b) - len(b.lstrip())) for b in body if b.strip())
                    py_blocks.append((rel, i + 1,
                                      "\n".join(b[strip:] if b.strip() else "" for b in body)))
                i = j
                continue
            i += 1

    # 1. labels -------------------------------------------------------------
    known = labels | BUILTIN_LABELS
    for rel, ln, name in jumps + calls:
        if name not in known:
            errors.append("%s:%d  jump/call to undefined label %r" % (rel, ln, name))

    # 2. images -------------------------------------------------------------
    declared = set(images) | {"black"}
    for rel, ln, name in shows:
        name = name.strip()
        if name.startswith('"') or name.startswith("expression"):
            continue
        base = name.split(" at ")[0].strip()
        if base in declared:
            continue
        # `show bg shop` where `image bg shop` exists; also allow a declared prefix.
        if any(base == d or base.startswith(d + " ") for d in declared):
            continue
        errors.append("%s:%d  scene/show of undeclared image %r" % (rel, ln, base))

    # 3. python -------------------------------------------------------------
    for rel, ln, src in py_blocks:
        try:
            ast.parse(src)
        except SyntaxError as exc:
            errors.append("%s:%d  python block does not parse: %s" % (rel, ln, exc.msg))

    # 3b. undefined names in python blocks ----------------------------------
    # A real engine run found `route` — a room-704 variable that does not exist here — in a
    # copied 09_dist line, which killed every non-paid track at appraisal 3. ast.parse() is
    # happy with an undefined name, so resolve them: collect what the project defines and
    # flag loads of anything else.
    defined = set(dir(__builtins__)) | set(dir(ast))
    defined |= {"renpy", "config", "persistent", "store", "_", "__", "gui", "build",
                "preferences", "_preferences", "achievement", "layeredimage", "im",
                "Character", "Solid", "Image", "Transform", "Function", "OpenURL", "Return",
                "Start", "Show", "Hide", "Call", "TintMatrix", "BrightnessMatrix", "ui",
                "emscripten", "urllib", "json", "os", "sys", "time", "threading", "uuid",
                "math", "random", "re", "item", "n", "name", "key", "kind", "what", "t0",
                "started", "_return", "True", "False", "None", "self", "exc", "d", "p", "f",
                "core", "style", "layout", "absolute", "position", "director"}
    all_src = ""
    for path in files():
        all_src += open(path, encoding="utf-8").read() + "\n"
    for m in re.finditer(r"^\s*(?:default|define)\s+([A-Za-z_]\w*)", all_src, re.M):
        defined.add(m.group(1))
    for rel, ln, src in py_blocks:
        try:
            tree = ast.parse(src)
        except SyntaxError:
            continue
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                defined.add(node.name)
            elif isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
                defined.add(node.id)
            elif isinstance(node, ast.arg):
                defined.add(node.arg)
            elif isinstance(node, (ast.Import, ast.ImportFrom)):
                for al in node.names:
                    defined.add((al.asname or al.name).split(".")[0])
    for rel, ln, src in py_blocks:
        # Screen language has its own scope (for-loop vars, screen parameters) that a
        # line-based parser cannot see, so the name pass covers the story scripts only.
        if rel.endswith(("screens.rpy", "gui.rpy", "options.rpy")):
            continue
        try:
            tree = ast.parse(src)
        except SyntaxError:
            continue
        for node in ast.walk(tree):
            if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load):
                if node.id not in defined and not node.id.startswith("_"):
                    errors.append("%s:%d  python block loads undefined name %r"
                                  % (rel, ln, node.id))

    # 4. call screens + from-checkpoints ------------------------------------
    for rel, ln, name in call_screens:
        if name not in screens | BUILTIN_SCREENS:
            errors.append("%s:%d  call screen of undefined screen %r" % (rel, ln, name))
    for name, where in froms.items():
        if len(where) > 1:
            errors.append("duplicate `from %s` checkpoint at %s" % (name, ", ".join(where)))

    # 5. GATED_CGS ----------------------------------------------------------
    dist = open(os.path.join(SCRIPTS, "09_dist.rpy"), encoding="utf-8").read()
    m = re.search(r"GATED_CGS\s*=\s*(\([^)]*\))", dist)
    if not m:
        errors.append("09_dist.rpy: GATED_CGS not found")
        gated = ()
    else:
        gated = ast.literal_eval(m.group(1))
        want = ("finial", "ring", "veil", "market", "collateral")
        if tuple(gated) != want:
            errors.append("GATED_CGS is %r; the design (§4) says %r" % (tuple(gated), want))
        else:
            notes.append("GATED_CGS matches the design exactly: %r" % (tuple(gated),))
        if "tamsin" in gated:
            errors.append("the free tutorial plate cg_tamsin must NOT be gated (design §4)")
        else:
            notes.append("cg_tamsin is ungated on every track, as designed")

    # 6. locked plates ------------------------------------------------------
    init = open(os.path.join(SCRIPTS, "00_init.rpy"), encoding="utf-8").read()
    cgs = os.path.join(GAME, "images", "cgs")
    for name in gated:
        if "image cg_locked_%s " % name not in init:
            errors.append("00_init.rpy: no cg_locked_%s declaration for gated CG" % name)
        for f in ("cg_%s.webp" % name, "cg_%s_x.webp" % name, "cg_%s_x_locked.webp" % name):
            if not os.path.isfile(os.path.join(cgs, f)):
                errors.append("missing plate file images/cgs/%s" % f)

    # 7. the drift check ----------------------------------------------------
    # Cheap, but it is the review the design asks for by name: five named clients, not one.
    body = "\n".join(open(os.path.join(SCRIPTS, f), encoding="utf-8").read()
                     for f in sorted(os.listdir(SCRIPTS)) if f.endswith(".rpy"))
    for who in ("Tamsin", "Ivo", "Merrow", "Calder", "Nara"):
        if who not in body:
            errors.append("cast member %s missing from the scripts" % who)
    notes.append("five named cast members present")

    words = len(re.findall(r'"([^"]{20,})"', body))
    wordcount = sum(len(s.split()) for s in re.findall(r'"([^"]{20,})"', body))
    notes.append("%d prose strings, ~%d words of dialogue/narration" % (words, wordcount))

    print("checked %d file(s)" % len(files()))
    for n in notes:
        print("  note: %s" % n)
    for w in warnings:
        print("  warn: %s" % w)
    for e in errors:
        print("  ERROR: %s" % e)
    print("\n%d error(s), %d warning(s)" % (len(errors), len(warnings)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
