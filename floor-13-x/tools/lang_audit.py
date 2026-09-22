#!/usr/bin/env python3
"""Hold every translated story file to the script it claims to be written in.

Floor 13 shipped ja/ko/es whose story files held Chinese prose. A file named
story_ja.gd is not evidence; kana in its strings is. Exit non-zero if any locale
listed in Loc.ALLOWED is not actually written in its own language."""
import os, re, sys
from story_parse import body_strings, p, SCRIPTS

KANA = re.compile(r"[぀-ヿ]")
HANGUL = re.compile(r"[가-힯ᄀ-ᇿ]")
HAN = re.compile(r"[一-鿿㐀-䶿]")
LATIN = re.compile(r"[A-Za-z]")


# Telling Japanese from Chinese, when both are written in Han characters.
#
# The first version of this check carried a hand-typed "simplified-only" blacklist, and
# that blacklist contained 机 着 当 数 — ordinary Japanese kanji. It reported 92 correct
# Japanese lines as Chinese. A check that lies in this direction is worse than no check:
# it sends you re-translating prose that was already right.
#
# The oracle here is JIS X 0208 via the euc_jp codec, which ships with Python. A Han
# character that cannot be encoded in EUC-JP is not in the Japanese writing system at
# all, so 这 说 电 话 录 时 间 车 东 玛 are conclusive, while 机 着 当 数 国 会 体 点 pass.
# euc_jisx0213 is tried as a second chance for rarer kanji.
#
# That alone misses Chinese written in characters Japanese also uses, so the second
# signal stays: a long run of Han uninterrupted by kana. Japanese prose cannot go far
# without particles and okurigana; a Chinese clause carries none. Short kana-free runs
# (監査官, 午前, 給与課) are correct Japanese and must not fire, hence the threshold.

KANA_FREE_RUN_MAX = 10  # 退勤予定時刻以降 is a legitimate 8-kanji Japanese run


def _jp_encodable(ch):
    for enc in ("euc_jp", "euc_jisx0213"):
        try:
            ch.encode(enc)
            return True
        except (UnicodeEncodeError, LookupError):
            continue
    return False


_JP_CACHE = {}


def non_japanese_han(s):
    """Han characters in s that do not exist in the Japanese writing system."""
    out = []
    for ch in s:
        if not HAN.match(ch):
            continue
        ok = _JP_CACHE.get(ch)
        if ok is None:
            ok = _JP_CACHE[ch] = _jp_encodable(ch)
        if not ok and ch not in out:
            out.append(ch)
    return out


LABEL_MAX = 12
CJK_RUN = re.compile(r"[\u4e00-\u9fff\u3400-\u4dbf]+")


def longest_kanaless_run(s):
    """Longest stretch of Han characters uninterrupted by kana OR punctuation."""
    worst = 0
    for chunk in KANA.split(s):
        for run in CJK_RUN.findall(chunk):
            worst = max(worst, len(run))
    return worst


def chinese_marks(s):
    return non_japanese_han(s)


def script_of(s):
    if HANGUL.search(s):
        return "ko"
    if HAN.search(s):
        if chinese_marks(s):
            return "zh"
        if KANA.search(s):
            return "zh" if longest_kanaless_run(s) > KANA_FREE_RUN_MAX else "ja"
        return "zh" if len(s.strip()) > LABEL_MAX else "cjk-label"
    if KANA.search(s):
        return "ja"
    if LATIN.search(s):
        return "latin"
    return "neutral"


FILES = {
    "ja": ("story_ja.gd", "ja"),
    "ko": ("story_ko.gd", "ko"),
    "es": ("story_es.gd", "latin"),
    "zh": ("story_zh.gd", "zh"),
    "en": ("story_data.gd", "latin"),
}


def allowed():
    src = open(p("locale.gd"), encoding="utf-8").read()
    m = re.search(r"const ALLOWED := \[(.*?)\]", src, re.S)
    return re.findall(r'"(\w[\w-]*)"', m.group(1)) if m else []


def report(loc, verbose=False):
    fname, want = FILES[loc]
    path = p(fname)
    if not os.path.exists(path):
        return None
    rows = body_strings(path)
    wrong = []
    ok = 0
    for route, text in rows:
        sc = script_of(text)
        if sc == "neutral":
            continue
        # A kana-free label is correct in ja and zh alike; count it for whichever asked.
        if sc == "cjk-label" and want in ("ja", "zh"):
            sc = want
        if sc == want:
            ok += 1
        else:
            wrong.append((route, sc, text))
    total = ok + len(wrong)
    if verbose:
        for route, sc, text in wrong:
            print(f"    {route:44s} [{sc}] {text[:70]}")
    return ok, total, wrong


def main():
    verbose = "--verbose" in sys.argv
    on = allowed()
    print(f"Loc.ALLOWED = {on}")
    bad = 0
    for loc in FILES:
        r = report(loc, verbose and loc in on)
        if r is None:
            continue
        ok, total, wrong = r
        live = "ON " if loc in on else "off"
        pct = 100.0 * ok / total if total else 0.0
        flag = ""
        if loc in on and wrong:
            flag = "  <-- OFFERED BUT NOT TRANSLATED"
            bad = 1
        print(f"  [{live}] {loc:3s} {ok:4d}/{total:4d} in-language ({pct:5.1f}%){flag}")
    return bad


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main())
