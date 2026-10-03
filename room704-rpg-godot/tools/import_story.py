#!/usr/bin/env python3
"""Port Room 704's Ren'Py act text into RPG event data, keeping the writing.

Reads the English scripts, the Japanese translation files and the voice manifest from the
Ren'Py game, and writes data/story/actN.json: every say line in source order with its
Ren'Py translation id, source line number, speaker, EN text, JA text and voice files (EN and
JA). Shift files (data/nights/*.json) refer to these lines by source-line range, so a
re-import after an edit to the VN text flows straight into the RPG.

Also copies the voice files those lines use into assets/voice/.
"""
import json, re, shutil, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SRC = Path("/home/frankstone/Products/play/room-704/game")
ACTS = {1: "01_act1", 2: "02_act2", 3: "03_act3"}
WHO = {"nar": "narrator", "m": "mira", "you": "protagonist", "man": "man"}
# Act 1's menu captions and options were never translated in the VN (acts 2-3 were); these
# are the RPG's own translations, merged into the menus table.
MENU_JA = {
    "She wants off the ledger. The cash is on the counter.": "彼女は帳簿に載りたくない。現金はカウンターの上だ。",
    "Ask her why before you decide.": "決める前に、理由を聞く。",
    "Take the cash. Don't write anything.": "現金を受け取る。何も書かない。",
    "Do it properly. Name in the book.": "きちんとやる。帳簿に名前を。",
    "He is waiting. The register is on the counter between you.": "彼は待っている。宿帳は二人の間のカウンターの上だ。",
    "Tell him nobody's checked in.": "誰もチェックインしていないと言う。",
    "Slide the register at him and say nothing.": "宿帳を彼の方へ滑らせ、何も言わない。",
    "Tell him the hotel doesn't discuss guests.": "ホテルは宿泊客について話さないと言う。",
}


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
                lines.append({"id": tid, "src": src, "who": em.group(1), "en": unq(em.group(2)), "ja": unq(jm.group(2))})
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
        if re.match(r"screen \w+", raw): label = None; continue
        m = re.match(r'\s+((\w+)\s+)?"(.*)"\s*$', raw)
        if not m or label is None or raw.strip().startswith(("old", "new")): continue
        code = raw.strip()
        base = label + "_" + hashlib.md5((code + "\r\n").encode("utf-8")).hexdigest()[:8]
        tid, k = base, 0
        while tid in seen: k += 1; tid = f"{base}_{k}"
        seen.add(tid)
        if raw.rstrip().endswith('":'):  # menu choice, not a say
            continue
        lines.append({"id": tid, "src": n, "label": label, "who": WHO.get(m.group(2) or "nar", m.group(2)),
                      "en": unq(m.group(3)), "ja": ja.get(tid, "")})
    return lines


def main():
    man = json.loads((SRC / "audio/voice/manifest.json").read_text())
    by_id, by_ja = man["by_id"], man["by_lang"].get("japanese", {})
    out = HERE / "data/story"; out.mkdir(parents=True, exist_ok=True)
    vdir = HERE / "assets/voice"; vdir.mkdir(parents=True, exist_ok=True)
    acts = [int(a) for a in sys.argv[1:]] or list(ACTS)
    for ch in acts:
        stem = ACTS[ch]
        tl, menus = parse_tl(SRC / "tl/japanese/scripts" / (stem + ".rpy"), stem)
        for en, j in MENU_JA.items():
            menus.setdefault(en, j)
        ja = {l["id"]: l["ja"] for l in tl}
        lines = parse_source(SRC / "scripts" / (stem + ".rpy"), ja)
        for ln in lines:   # a menu caption is a say line in the source but an old/new pair in the tl
            if not ln["ja"] and ln["en"] in menus:
                ln["ja"] = menus[ln["en"]]
        voiced = 0
        for ln in lines:
            for key, table in (("v_en", by_id), ("v_ja", by_ja)):
                rel = table.get(ln["id"])
                if rel and (SRC / rel).exists():
                    dst = vdir / Path(rel).name
                    if not dst.exists(): shutil.copy2(SRC / rel, dst)
                    ln[key] = "res://assets/voice/" + dst.name
                    voiced += key == "v_en"
        missing = [l["id"] for l in lines if not l["ja"]]
        (out / f"act{ch}.json").write_text(json.dumps({"chapter": ch, "lines": lines, "menus": menus}, ensure_ascii=False, indent=1))
        print(f"act{ch}: {len(lines)} lines, {voiced} voiced (EN), {len(menus)} menu strings, {len(missing)} without JA {missing[:5]}")


if __name__ == "__main__":
    main()
