#!/usr/bin/env python3
"""Port Confession Room's Ren'Py text into RPG story data, keeping the writing.

The VN keeps its three cases as data (01_case.rpy: CASES, with the 72 testimonies, the
openings, the public facts) and its scenes as script (02_interrogation.rpy: the press beats
and the nine optional routes; 03_board.rpy: the three clean endings and the two generic
ones; 05_start.rpy: the way in and the evidence locker). Four story tables come out:

  data/story/cases.json   the data, flattened to lines with synthetic source numbers:
                          case c -> opening c*1000+1..3, victim +10, public facts +11..14,
                          statement i at +100+i (in CASES order)
  data/story/interr.json  02_interrogation.rpy by real source line
  data/story/board.json   03_board.rpy
  data/story/start.json   05_start.rpy

Every line carries its Ren'Py translation id (label + md5 of the code, the way Ren'Py
makes it; statements use their own ids) so the VN's voice files attach by id. There is no
Japanese translation of this VN (no tl/ directory), so the "ja" cell is empty and the game
falls back to English for these lines; the RPG's own strings are EN + JA.
"""
import hashlib, json, re, shutil, sys, textwrap
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SRC = Path("/home/frankstone/Products/play/confession-room/game")
FILES = {"interr": "02_interrogation", "board": "03_board", "start": "05_start"}
WHO = {"nar": "narrator", "you": "protagonist", "nik": "nikolai", "ade": "adaeze", "vee": "vee", "dsp": "dispatch"}


def unq(s):
    # Ren'Py {b}..{/b} -> the event view's bbcode
    return s.replace('\\"', '"').replace("{b}", "[b]").replace("{/b}", "[/b]")


def parse_source(path):
    """Every say statement in source order with the id Ren'Py gives it."""
    label, seen, lines = None, set(), []
    for n, raw in enumerate(path.read_text("utf-8").splitlines(), 1):
        m = re.match(r"label (\w+)", raw)
        if m:
            label = m.group(1); continue
        if re.match(r"screen \w+", raw):
            label = None; continue
        m = re.match(r'\s+((\w+)\s+)?"(.*)"\s*$', raw)
        if not m or label is None or raw.strip().startswith(("old", "new")):
            continue
        code = raw.strip()
        base = label + "_" + hashlib.md5((code + "\r\n").encode("utf-8")).hexdigest()[:8]
        tid, k = base, 0
        while tid in seen:
            k += 1; tid = f"{base}_{k}"
        seen.add(tid)
        if raw.rstrip().endswith('":'):   # menu option, not a say
            continue
        who = m.group(2) or "nar"
        if who not in WHO:                # e.g. a menu caption with no speaker
            continue
        lines.append({"id": tid, "src": n, "label": label, "who": WHO[who], "en": unq(m.group(3)), "ja": ""})
    return lines


def load_cases():
    """Execute the CASES literal out of 01_case.rpy (it is plain Python data)."""
    txt = (SRC / "scripts/01_case.rpy").read_text("utf-8")
    a = txt.index("    CASES = [")
    b = txt.index("    CASE_COUNT = len(CASES)")
    block = textwrap.dedent(txt[a:b])
    ns = {"ROUTE": 99}
    exec(block, ns)
    return ns["CASES"]


def main():
    man = json.loads((SRC / "audio/voice/manifest.json").read_text())
    by_id = man["by_id"]
    out = HERE / "data/story"; out.mkdir(parents=True, exist_ok=True)
    vdir = HERE / "assets/voice"; vdir.mkdir(parents=True, exist_ok=True)

    def voice(ln):
        rel = by_id.get(ln["id"])
        if rel and (SRC / rel).exists():
            dst = vdir / Path(rel).name
            if not dst.exists():
                shutil.copy2(SRC / rel, dst)
            ln["v_en"] = "res://assets/voice/" + dst.name
            return 1
        return 0

    # the data file
    cases = load_cases()
    lines, index = [], {"cases": []}
    for c, case in enumerate(cases, 1):
        base = c * 1000
        meta = {"id": case["id"], "title": case["title"], "night": case["night"], "solution": case["solution"],
                "decisive": case["decisive"], "withheld": case["withheld"], "roles": case["roles"], "statements": []}
        for i, sid in enumerate(("nikolai", "adaeze", "vee"), 1):
            lines.append({"id": f"open{c}_{sid}", "src": base + i, "label": f"case{c}", "who": sid, "en": case["open"][sid], "ja": ""})
        lines.append({"id": f"victim{c}", "src": base + 10, "label": f"case{c}", "who": "narrator", "en": case["victim"], "ja": ""})
        for i, fact in enumerate(case["public"], 11):
            lines.append({"id": f"public{c}_{i - 10}", "src": base + i, "label": f"case{c}", "who": "narrator", "en": fact, "ja": ""})
        for i, (sid, stid, topic, need, text) in enumerate(case["statements"]):
            lines.append({"id": stid, "src": base + 100 + i, "label": f"case{c}", "who": sid, "en": text, "ja": ""})
            meta["statements"].append({"id": stid, "who": sid, "topic": topic, "need": need, "src": base + 100 + i})
        index["cases"].append(meta)
    voiced = sum(voice(ln) for ln in lines)
    (out / "cases.json").write_text(json.dumps({"chapter": "cases", "lines": lines, "menus": {}}, ensure_ascii=False, indent=1))
    (out / "cases_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1))
    print(f"cases: {len(lines)} lines, {voiced} voiced (EN), {len(index['cases'])} cases")

    for key, stem in FILES.items():
        ls = parse_source(SRC / "scripts" / (stem + ".rpy"))
        v = sum(voice(ln) for ln in ls)
        (out / f"{key}.json").write_text(json.dumps({"chapter": key, "lines": ls, "menus": {}}, ensure_ascii=False, indent=1))
        print(f"{key}: {len(ls)} lines, {v} voiced (EN)")


if __name__ == "__main__":
    main()
