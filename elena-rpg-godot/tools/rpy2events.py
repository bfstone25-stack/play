#!/usr/bin/env python3
"""Compile a line range of an Elena Ren'Py chapter into night_rpg event steps.

Keeps the writing exactly: say lines become {"lines": "chN:a-b"} references into
data/story/chN.json (text, JA and voice come from there). Structure is kept too:
  menu            -> {"choice": [{"menu": <EN text>, "do": [...]}]}
  if/elif/else    -> {"if_flag": ...} chains (chosen_ending -> route_* / ending_* flags)
  $ elena_affection += n   -> {"trust": +1}   (affection is the VN's trust; one step per beat)
  $ dean_blackmail = True  -> {"flag": "dean_blackmail"} (same for the other booleans)
  scene expression cg_pick("x") / scene cg x -> {"cg": "cg_x"};  scene bg ... -> {"hide_cg": true}
  show elena flustered     -> {"show": "elena_flustered"} (dean/penhallow/cobb likewise)
  play music / play sound  -> {"music"} / {"sfx"}
Night source files (data/nights_src/*.json) use {"rpy": "ch2:18-110"} and are expanded by
tools/build_nights.py.
"""
import re
from pathlib import Path

VN = Path("/home/frankstone/Products/.elena-wt/elena-suspense/game/scripts")
FILES = {1: "02_script_ch1.rpy", 2: "05_script_ch2.rpy", 3: "06_script_ch3.rpy", 4: "07_script_ch4.rpy", 5: "08_script_ch5.rpy"}
SPRITES = {("elena", "neutral"): "elena_neutral", ("elena", "flustered"): "elena_flustered",
           ("elena", "soft"): "elena_soft", ("elena", "submission"): "elena_soft",
           ("dean", "neutral"): "dean_holloway", ("penhallow", "neutral"): "penhallow", ("cobb", "neutral"): "cobb"}
SAY = re.compile(r'^(?:(\w+)\s+)?"(.*)"$')
OPT = re.compile(r'^"(.*)"\s*:$')


def unq(s):
    return s.replace('\\"', '"')


def _lines(ch):
    out = []
    for n, raw in enumerate((VN / FILES[ch]).read_text("utf-8").splitlines(), 1):
        t = raw.strip()
        if not t or t.startswith("#"):
            continue
        out.append((n, len(raw) - len(raw.lstrip(" ")), t))
    return out


def cond_flag(c):
    c = c.strip()
    m = re.match(r'chosen_ending\s*(==|!=)\s*"(\w+)"', c)
    if m:
        name = m.group(2)
        flag = ("route_" + {"walk_away": "walk"}.get(name, name)) if name in ("control", "pact", "walk_away") else "ending_" + name
        return flag, m.group(1) == "!="
    if re.match(r"^\w+$", c):
        return c, False
    if c.startswith("not "):
        return c[4:].strip(), True
    raise ValueError("condition " + c)


def compile_range(ch, a, b):
    rows = [r for r in _lines(ch) if a <= r[0] <= b]
    steps, _ = _block(ch, rows, 0, rows[0][1] if rows else 0)
    return steps


def _block(ch, rows, i, indent):
    steps = []
    run = None  # [first, last] say lines

    def flush():
        nonlocal run
        if run:
            steps.append({"lines": f"ch{ch}:{run[0]}-{run[1]}"})
            run = None

    while i < len(rows):
        n, ind, t = rows[i]
        if ind < indent:
            break
        if ind > indent:  # stray deeper line (e.g. 'with dissolve' continuation) -> skip
            i += 1
            continue
        m = SAY.match(t)
        if m and not t.endswith(":"):
            run = [run[0], n] if run else [n, n]
            i += 1
            continue
        flush()
        if t == "menu:":
            i += 1
            opts = []
            sub_ind = rows[i][1] if i < len(rows) else indent + 4
            while i < len(rows) and rows[i][1] >= sub_ind:
                n2, ind2, t2 = rows[i]
                if ind2 == sub_ind and OPT.match(t2):
                    body_ind = rows[i + 1][1] if i + 1 < len(rows) else sub_ind + 4
                    do, i = _block(ch, rows, i + 1, body_ind)
                    opts.append({"menu": unq(OPT.match(t2).group(1)), "do": do})
                elif ind2 == sub_ind and SAY.match(t2):  # menu caption line
                    steps.append({"lines": f"ch{ch}:{n2}-{n2}"})
                    i += 1
                else:
                    i += 1
            steps.append({"choice": opts})
            continue
        if t.startswith("if ") and t.endswith(":"):
            chain = []
            cond = t[3:-1]
            body_ind = rows[i + 1][1]
            body, i = _block(ch, rows, i + 1, body_ind)
            chain.append((cond, body))
            else_body = []
            while i < len(rows) and rows[i][1] == indent and (rows[i][2].startswith("elif ") or rows[i][2] == "else:"):
                tt = rows[i][2]
                body_ind = rows[i + 1][1]
                body, i = _block(ch, rows, i + 1, body_ind)
                if tt == "else:":
                    else_body = body
                else:
                    chain.append((tt[5:-1], body))
            node = else_body
            for cond, body in reversed(chain):
                flag, neg = cond_flag(cond)
                node = [{"if_flag": flag, "then": node if neg else body, "else": body if neg else node}]
            steps.extend(node)
            continue
        steps.extend(_simple(t))
        i += 1
    flush()
    return steps, i


def _simple(t):
    m = re.match(r"\$\s*elena_affection\s*([+-])=\s*(\d+)", t)
    if m:
        # The VN hands out affection in ones for small kindnesses and twos/threes for the
        # beats that matter; RPG Trust (thresholds 3/5/7/9) counts only the beats that matter.
        n = int(m.group(2))
        if m.group(1) == "-":
            return [{"trust": -1}]
        return [{"trust": 1}] if n >= 2 else []
    m = re.match(r"\$\s*(dean_blackmail|ritual_interrupted|secret_ledger_discovered)\s*=\s*True", t)
    if m:
        return [{"flag": m.group(1)}]
    m = re.match(r'\$\s*chosen_ending\s*=\s*"(\w+)"', t)
    if m:
        return [{"flag": "ending_" + m.group(1)}]
    m = re.match(r'scene expression cg_pick\("(\w+)"\)', t)
    if m:
        return [{"cg": "cg_" + m.group(1)}]
    m = re.match(r"scene cg (\w+)", t)
    if m:
        return [{"cg": "cg_" + m.group(1)}]
    if t.startswith("scene bg") or t == "scene black":
        return [{"hide_cg": True}]
    m = re.match(r"show (\w+) (\w+)", t)
    if m and (m.group(1), m.group(2)) in SPRITES:
        x = 0.3 if " at left" in t else (0.75 if " at right" in t else 0.62)
        return [{"show": SPRITES[(m.group(1), m.group(2))], "x": x}]
    if t.startswith("hide "):
        return [{"show": ""}]
    m = re.match(r"play music (\w+)", t)
    if m:
        return [{"music": "intimate" if "ecchi" in m.group(1) else "explore"}]
    m = re.match(r"play sound (?:audio\.)?(\w+)", t)
    if m:
        return [{"sfx": {"click": "camera"}.get(m.group(1), m.group(1))}]
    return []


if __name__ == "__main__":
    import json, sys
    ch, rng = sys.argv[1].split(":")
    a, b = rng.split("-")
    print(json.dumps(compile_range(int(ch[2:]), int(a), int(b)), indent=1))
