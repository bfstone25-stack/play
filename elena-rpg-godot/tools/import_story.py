#!/usr/bin/env python3
"""Port Elena's Ren'Py chapter text into RPG event data, keeping the writing.

Reads the English script, the Japanese translation file and the voice manifest from the
Ren'Py game, and writes data/story/chN.json: every say line in source order with its
Ren'Py translation id, source line number, speaker, EN text, JA text and voice files.
Night event files (data/nights/*.json) refer to these lines by source-line range, so a
re-import after an edit to the VN text flows straight into the RPG.

Also copies the voice files those lines use into assets/voice/.
"""
import json, re, shutil, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SRC = Path("/home/frankstone/Products/.elena-wt/elena-suspense/game")
CHAPTERS = {1: "02_script_ch1", 2: "05_script_ch2", 3: "06_script_ch3", 4: "07_script_ch4", 5: "08_script_ch5"}

def unq(s):
    return s.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in s else s

def parse_tl(path, stem):
    lines, menus = [], {}
    txt = path.read_text("utf-8-sig").splitlines()
    i = 0
    while i < len(txt):
        m = re.match(r"# game/scripts/%s\.rpy:(\d+)" % stem, txt[i])
        if m and i + 1 < len(txt) and txt[i + 1].startswith("translate japanese "):
            src = int(m.group(1)); tid = txt[i + 1].split()[2].rstrip(":")
            en_l = txt[i + 3].strip(); ja_l = txt[i + 4].strip()
            em = re.match(r'#\s*(\w+)\s+"(.*)"$', en_l); jm = re.match(r'(\w+)\s+"(.*)"$', ja_l)
            if em and jm:
                lines.append({"id": tid, "src": src, "who": em.group(1),
                              "en": unq(em.group(2)), "ja": unq(jm.group(2))})
            i += 5; continue
        m = re.match(r'\s*old "(.*)"$', txt[i])
        if m and i + 1 < len(txt):
            n = re.match(r'\s*new "(.*)"$', txt[i + 1])
            if n: menus[unq(m.group(1))] = unq(n.group(1))
        i += 1
    return lines, menus

def parse_source(path, ja):
    """Every say statement in source order, with the id Ren'Py gives it:
    label + '_' + md5(code + CRLF)[:8], suffixed _1, _2 on repeats."""
    import hashlib
    label, seen, lines = None, set(), []
    for n, raw in enumerate(path.read_text("utf-8").splitlines(), 1):
        m = re.match(r"label (\w+):", raw)
        if m: label = m.group(1); continue
        m = re.match(r'\s+((\w+)\s+)?"(.*)"\s*$', raw)
        if not m or label is None or raw.strip().startswith(("old", "new")): continue
        code = raw.strip()
        base = label + "_" + hashlib.md5((code + "\r\n").encode("utf-8")).hexdigest()[:8]
        tid, k = base, 0
        while tid in seen: k += 1; tid = f"{base}_{k}"
        seen.add(tid)
        if raw.rstrip().endswith('":'):  # menu choice, not a say
            continue
        lines.append({"id": tid, "src": n, "label": label, "who": m.group(2) or "narrator",
                      "en": unq(m.group(3)), "ja": ja.get(tid, "")})
    return lines

def main():
    man = json.loads((SRC / "audio/voice/manifest.json").read_text())
    by_id, by_ja = man["by_id"], man["by_lang"].get("japanese", {})
    out = HERE / "data/story"; out.mkdir(parents=True, exist_ok=True)
    vdir = HERE / "assets/voice"; vdir.mkdir(parents=True, exist_ok=True)
    chapters = [int(a) for a in sys.argv[1:]] or list(CHAPTERS)
    for ch in chapters:
        stem = CHAPTERS[ch]
        tl, menus = parse_tl(SRC / "tl/japanese/scripts" / (stem + ".rpy"), stem)
        ja = {l["id"]: l["ja"] for l in tl}
        lines = parse_source(SRC / "scripts" / (stem + ".rpy"), ja)
        voiced = 0
        for ln in lines:
            for key, table in (("v_en", by_id), ("v_ja", by_ja)):
                rel = table.get(ln["id"])
                if rel and (SRC / rel).exists():
                    dst = vdir / Path(rel).name
                    if not dst.exists(): shutil.copy2(SRC / rel, dst)
                    ln[key] = "res://assets/voice/" + dst.name
                    voiced += key == "v_en"
        (out / f"ch{ch}.json").write_text(json.dumps({"chapter": ch, "lines": lines, "menus": menus},
                                                     ensure_ascii=False, indent=1))
        print(f"ch{ch}: {len(lines)} lines, {voiced} voiced (EN), {len(menus)} menu strings")

if __name__ == "__main__":
    main()
