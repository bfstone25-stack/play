#!/usr/bin/env python3
"""Check one title's translations against data/i18n/_src.json.
Fails (exit 1) on: missing/empty unit, placeholder mismatch (%d %s %.2f {#x} [b] [i] newlines),
wrong script (zh needs Han, ko needs Hangul, de/fr/es must not be CJK), long line left in English.
usage: i18n_check.py play/<game> [lang ...]"""
import json, re, sys
from pathlib import Path

PH = re.compile(r"%[-0-9.]*[sdf]|\{#[^}]*\}|\[/?[bi]\]|\n")
HAN = re.compile(r"[一-鿿]")
HANGUL = re.compile(r"[가-힯]")
KANA = re.compile(r"[぀-ヿ]")


def ph(s):
    return sorted(PH.findall(s))


def check(en, tr, lang, where, errs):
    if not str(tr).strip():
        errs.append(f"{where}: empty"); return
    if ph(en) != ph(tr):
        errs.append(f"{where}: placeholders {ph(en)} != {ph(tr)}")
    bare = re.sub(r"\[[^\]]*\]+\]?|\{[^}]*\}|%[-+0-9.]*[sdf]", "", en)   # placeholders carry no words
    letters = re.sub(r"[^A-Za-z]", "", bare)
    if lang == "zh" and len(letters) > 6 and not HAN.search(tr):
        errs.append(f"{where}: no Han in zh")
    if lang == "zh" and KANA.search(tr):
        errs.append(f"{where}: kana in zh")
    if lang == "ko" and len(letters) > 6 and not HANGUL.search(tr):
        errs.append(f"{where}: no Hangul in ko")
    if lang in ("de", "fr", "es") and (HAN.search(tr) or HANGUL.search(tr) or KANA.search(tr)):
        errs.append(f"{where}: CJK in {lang}")
    if lang != "en" and len(en) > 40 and tr.strip() == en.strip():
        errs.append(f"{where}: left in English")


def main():
    g = Path(sys.argv[1]).resolve()
    langs = sys.argv[2:] or ["de", "fr", "es", "zh", "ko"]
    src = json.loads((g / "data/i18n/_src.json").read_text())
    bad = 0
    for lang in langs:
        errs = []
        sp = g / f"data/i18n/{lang}.json"
        s = json.loads(sp.read_text()) if sp.exists() else {}
        for k, v in src["strings"].items():
            check(v["en"], s.get(k, ""), lang, f"str {k}", errs)
        stp = g / f"data/i18n/story/{lang}.json"
        st = json.loads(stp.read_text()) if stp.exists() else {"lines": {}, "menus": {}}
        for k, v in src["story"].items():
            check(v["en"], st.get("lines", {}).get(k, ""), lang, f"line {k}", errs)
        for en in src["menus"]:
            check(en, st.get("menus", {}).get(en, ""), lang, f"menu {en[:30]}", errs)
        n = len(src["strings"]) + len(src["story"]) + len(src["menus"])
        print(f"{g.name} {lang}: {n - len(errs)}/{n} ok")
        for e in errs[:15]:
            print("   ", e)
        bad += len(errs)
    sys.exit(1 if bad else 0)


main()
