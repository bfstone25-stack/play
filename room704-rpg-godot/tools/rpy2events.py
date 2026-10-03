#!/usr/bin/env python3
"""Compile a Room 704 Ren'Py label (or a line range of one act) into night_rpg event steps.

Keeps the writing exactly: say lines become {"lines": "actN:a-b"} references into
data/story/actN.json (text, JA and voice come from there). Structure is kept too:
  menu                      -> {"choice": [{"menu": <EN text>, "do": [...]}]}
  if/elif/else              -> {"if_flag": ...} / {"if_trust": n} chains
  jump X                    -> {"event": "vn_X"}  (dropped when X is in `cut`, so the RPG can
                               put exploration between two VN beats)
  $ trust += n / -= n       -> {"trust": +n / -n}   (the VN's trust IS the RPG's Trust)
  $ covered_for_her = True  -> {"flag": "covered"};  $ route = "cover" -> {"flag": "route_cover"}
  $ route = route + "_yes"  -> {"flag": "scene_yes"} (same for _no)
  scene cg x / scene expression cg_pick("x") -> {"cg": "cg_x"}; scene bg lobby -> {"bg": "lobby"}
  play music theme / warm / heartbeat -> {"music": explore / intimate / heartbeat}
Everything else (telemetry, gates, transitions, screens) is dropped.
"""
import re
from pathlib import Path

VN = Path("/home/frankstone/Products/play/room-704/game/scripts")
FILES = {1: "01_act1.rpy", 2: "02_act2.rpy", 3: "03_act3.rpy"}
BG = {"lobby": "lobby", "corridor": "corridor4", "room": "room704"}
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


def label_range(ch, label):
    rows = _lines(ch)
    start = None
    for i, (n, ind, t) in enumerate(rows):
        if ind == 0 and t == f"label {label}:":
            start = i
        elif start is not None and i > start and ind == 0 and (t.startswith("label ") or t.startswith("screen ")):
            return rows[start + 1][0], rows[i - 1][0]
    if start is None:
        raise KeyError(label)
    return rows[start + 1][0], rows[-1][0]


def cond(c):
    c = c.strip()
    m = re.match(r'route\s*==\s*"(\w+)"', c)
    if m:
        return ("flag", "route_" + m.group(1), False)
    m = re.match(r"trust\s*>=\s*(-?\d+)", c)
    if m:
        return ("trust", int(m.group(1)), False)
    if c == "covered_for_her":
        return ("flag", "covered", False)
    raise ValueError("condition " + c)


def compile_label(ch, label, cut=(), lines=None):
    a, b = label_range(ch, label)
    if lines:
        a, b = lines
    rows = [r for r in _lines(ch) if a <= r[0] <= b]
    steps, _ = _block(ch, rows, 0, rows[0][1] if rows else 0, set(cut))
    return steps


def compile_range(ch, a, b, cut=()):
    rows = [r for r in _lines(ch) if a <= r[0] <= b]
    steps, _ = _block(ch, rows, 0, rows[0][1] if rows else 0, set(cut))
    return steps


def _block(ch, rows, i, indent, cut):
    steps = []
    run = None

    def flush():
        nonlocal run
        if run:
            steps.append({"lines": f"act{ch}:{run[0]}-{run[1]}"})
            run = None

    while i < len(rows):
        n, ind, t = rows[i]
        if ind < indent:
            break
        if ind > indent:
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
                    do, i = _block(ch, rows, i + 1, body_ind, cut)
                    opts.append({"menu": unq(OPT.match(t2).group(1)), "do": do})
                elif ind2 == sub_ind and SAY.match(t2):  # menu caption
                    steps.append({"lines": f"act{ch}:{n2}-{n2}"})
                    i += 1
                else:
                    i += 1
            steps.append({"choice": opts})
            continue
        if t.startswith("if ") and t.endswith(":"):
            chain = []
            body_ind = rows[i + 1][1]
            body, i = _block(ch, rows, i + 1, body_ind, cut)
            chain.append((t[3:-1], body))
            else_body = []
            while i < len(rows) and rows[i][1] == indent and (rows[i][2].startswith("elif ") or rows[i][2] == "else:"):
                tt = rows[i][2]
                body_ind = rows[i + 1][1]
                body, i = _block(ch, rows, i + 1, body_ind, cut)
                if tt == "else:":
                    else_body = body
                else:
                    chain.append((tt[5:-1], body))
            node = else_body
            for c, body in reversed(chain):
                kind, v, _neg = cond(c)
                node = [{"if_flag": v, "then": body, "else": node}] if kind == "flag" else [{"if_trust": v, "then": body, "else": node}]
            steps.extend(node)
            continue
        steps.extend(_simple(t, cut))
        i += 1
    flush()
    return steps, i


def _simple(t, cut):
    m = re.match(r"jump (\w+)", t)
    if m:
        return [] if m.group(1) in cut else [{"event": "vn_" + m.group(1)}]
    m = re.match(r"\$\s*trust\s*([+-])=\s*(\d+)", t)
    if m:
        n = int(m.group(2))
        return [{"trust": n if m.group(1) == "+" else -n}]
    m = re.match(r"\$\s*covered_for_her\s*=\s*(True|False)", t)
    if m:
        return [{"flag": "covered", "value": m.group(1) == "True"}]
    m = re.match(r'\$\s*route\s*=\s*"(\w+)"', t)
    if m:
        return [{"flag": "route_" + m.group(1)}]
    m = re.match(r'\$\s*route\s*=\s*route\s*\+\s*"_(\w+)"', t)
    if m:
        return [{"flag": "scene_" + m.group(1)}]
    m = re.match(r'scene expression cg_pick\("(\w+)"\)', t)
    if m:
        return [{"cg": "cg_" + m.group(1)}]
    m = re.match(r"scene cg (\w+)", t)
    if m:
        return [{"cg": "cg_" + m.group(1)}]
    m = re.match(r"scene bg (\w+)", t)
    if m:
        return [{"hide_cg": True}] if m.group(1) == "black" else [{"hide_cg": True}, {"bg": BG[m.group(1)]}]
    m = re.match(r"play music (\w+)", t)
    if m:
        return [{"music": {"theme": "explore", "warm": "intimate", "heartbeat": "heartbeat"}[m.group(1)]}]
    return []


if __name__ == "__main__":
    import json, sys
    ch, label = sys.argv[1].split(":")
    print(json.dumps(compile_label(int(ch[3:]), label), indent=1))
