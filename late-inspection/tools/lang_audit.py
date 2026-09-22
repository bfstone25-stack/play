#!/usr/bin/env python3
"""Hold every translated story file to the script it claims to be written in, and to the
key set the English original actually has.

Two separate lies are possible and Floor 13 shipped both:

  * a file named story_ja.gd whose prose is Chinese. The name is not evidence; kana is.
  * a file that is genuinely Japanese but only covers half the ids, so the other half
    silently falls back to English mid-scene and nobody notices in a smoke test.

The language oracle is lifted from play/floor-13/tools/lang_audit.py, deliberately and
without changes: its first version carried a hand-typed "simplified-only" blacklist which
contained 机 着 当 数 -- ordinary Japanese kanji -- and reported 92 correct Japanese lines
as Chinese. EUC-JP encodability is the oracle instead.

Late Inspection's story files are shaped differently from Floor 13's (a `commentary()`
function holding a `pages` dictionary, plus a module-level TEXTS dictionary of prop
entries), so the extraction below is this game's, and only the verdict is shared.
"""
import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.join(HERE, "..", "scripts")
# Loaded by path, not by sys.path: this file has the same basename as Floor 13's, so a
# plain import finds *itself* and fails with a circular-import error.
import importlib.util as _ilu  # noqa: E402

_spec = _ilu.spec_from_file_location(
    "floor13_lang_audit",
    os.path.join(HERE, "..", "..", "floor-13", "tools", "lang_audit.py"))
_f13 = _ilu.module_from_spec(_spec)
sys.path.insert(0, os.path.join(HERE, "..", "..", "floor-13", "tools"))
_spec.loader.exec_module(_f13)
script_of = _f13.script_of  # the shared oracle, unmodified


def p(name):
    return os.path.join(SCRIPTS, name)


def _strip_comments(src):
    """Drop `#` comments without cutting inside a string literal.

    Triple-quoted blocks are prose and routinely contain `#` (`# 404`, checklist items),
    so the scanner has to know it is inside one.
    """
    out = []
    i = 0
    n = len(src)
    while i < n:
        if src.startswith('"""', i):
            j = src.find('"""', i + 3)
            j = n if j < 0 else j + 3
            out.append(src[i:j])
            i = j
            continue
        ch = src[i]
        if ch == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j + 1])
            i = j + 1
            continue
        if ch == "#":
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _dict_after(src, start):
    """Slice the balanced {...} beginning at or after `start`, as Python source."""
    i = src.index("{", start)
    depth = 0
    j = i
    while j < len(src):
        if src.startswith('"""', j):
            j = src.find('"""', j + 3) + 3
            continue
        ch = src[j]
        if ch == '"':
            j += 1
            while j < len(src) and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return src[i:j + 1]
        j += 1
    raise ValueError("unbalanced dictionary")


def tables(path):
    """(commentary pages, TEXTS) for one story file, as real Python dicts."""
    src = _strip_comments(open(path, encoding="utf-8").read())
    pages = {}
    m = re.search(r"\bvar pages\s*:?=\s*", src)
    if m:
        pages = ast.literal_eval(_dict_after(src, m.end()))
    texts = {}
    m = re.search(r"\bconst TEXTS\s*:?=\s*", src)
    if m:
        texts = ast.literal_eval(_dict_after(src, m.end()))
    return pages, texts


def strings(path):
    """Every player-readable string as (route, text). Ids and flags are not prose."""
    pages, texts = tables(path)
    out = [(f"commentary.{k}", v) for k, v in pages.items() if isinstance(v, str)]
    for pid, entry in texts.items():
        if not isinstance(entry, dict):
            continue
        for field in ("prompt", "text", "a", "b"):
            if isinstance(entry.get(field), str):
                out.append((f"{pid}.{field}", entry[field]))
    return out


def keys(path):
    pages, texts = tables(path)
    return set(pages), set(texts)


def english_keys():
    """The ids the English story actually emits, which is the set a translation must cover.

    story_content.gd has no TEXTS dictionary -- its props are `n(...)`/`c(...)` calls inside
    stage(). And StoryOverlay rewrites two of those ids before the lookup: `followup`
    becomes followup_yes/followup_no and `final_evidence` becomes final_signed/
    final_refused, depending on the player's flags. A translation that covers the literal
    id list is therefore still missing the four branch keys, and the miss is invisible --
    the overlay simply leaves the English text in place mid-scene.
    """
    src = _strip_comments(open(p("story_content.gd"), encoding="utf-8").read())
    pages = set(ast.literal_eval(
        _dict_after(src, re.search(r"\bvar pages\s*:?=\s*", src).end())))
    ids = set(re.findall(r'\b[nc]\("([a-z_]+)"', src))
    for literal, branches in (("followup", ("followup_yes", "followup_no")),
                              ("final_evidence", ("final_signed", "final_refused"))):
        if literal in ids:
            ids.discard(literal)
            ids.update(branches)
    return pages, ids


FILES = {
    "en": ("story_content.gd", "latin"),
    "zh": ("story_zh.gd", "zh"),
    "ja": ("story_ja.gd", "ja"),
    "es": ("story_es.gd", "latin"),
    "ko": ("story_ko.gd", "ko"),
}


UI_TABLES = {"en": "EN", "zh": "ZH", "ja": "JA", "es": "ES", "ko": "KO"}


def ui_strings(loc):
    """The UI table in locale.gd for one locale, as (route, text).

    The story files are not the whole game: menu labels, the pause screen, the endings
    chrome and every hint live in locale.gd's per-language dictionaries. Floor 13's
    half-translated ko/es were caught in the story files, but a UI table can drift on its
    own -- a locale can be 100% translated in its prose and still show English buttons.
    """
    src = _strip_comments(open(p("locale.gd"), encoding="utf-8").read())
    m = re.search(r"\bconst %s\s*:?=\s*" % UI_TABLES[loc], src)
    if not m:
        return []
    table = ast.literal_eval(_dict_after(src, m.end()))
    return [(f"ui.{k}", v) for k, v in table.items()
            if isinstance(v, str) and k not in KEYCAP_STRINGS]


# Strings that are correctly Latin in every language because they name physical keys.
# `vn.choose` is "A / B" -- the A and B keys on the keyboard, not English words. Without
# this the audit reports ja and ko at 99.4% for ever and the real failures hide behind a
# permanent red row, which is how a check stops being read.
KEYCAP_STRINGS = {"vn.choose"}


def allowed():
    src = open(p("locale.gd"), encoding="utf-8").read()
    m = re.search(r"const ALLOWED := \[(.*?)\]", src, re.S)
    return re.findall(r'"([\w-]+)"', m.group(1)) if m else []


def main():
    verbose = "--verbose" in sys.argv
    on = allowed()
    print(f"Loc.ALLOWED = {on}")
    base_pages, base_texts = english_keys()
    print(f"english story: {len(base_pages)} commentary pages, {len(base_texts)} props")
    bad = 0
    for loc, (fname, want) in FILES.items():
        path = p(fname)
        if not os.path.exists(path):
            print(f"  [---] {loc:3s} no file")
            continue
        rows = strings(path) + ui_strings(loc)
        wrong = [(r, script_of(t), t) for r, t in rows
                 if script_of(t) not in ("neutral", want)
                 and not (script_of(t) == "cjk-label" and want in ("ja", "zh"))]
        scored = [t for _, t in rows if script_of(t) != "neutral"]
        # UI key coverage: a locale missing a key falls back silently, same as the story.
        ui_here = {r for r, _ in ui_strings(loc)}
        miss_ui = {r for r, _ in ui_strings("en")} - ui_here
        pages_here, texts_here = keys(path)
        # en IS the baseline, and its props live in stage() rather than a TEXTS table,
        # so comparing it against itself reports all 29 as missing. Meaningless noise.
        if loc == "en":
            miss_p, miss_t = set(), set()
        else:
            miss_p = base_pages - pages_here
            miss_t = base_texts - texts_here
        live = "ON " if loc in on else "off"
        total = len(scored)
        ok = total - len(wrong)
        pct = 100.0 * ok / total if total else 0.0
        flag = ""
        if loc in on and loc != "en" and (wrong or miss_p or miss_t or miss_ui):
            flag = "  <-- OFFERED BUT INCOMPLETE"
            bad = 1
        print(f"  [{live}] {loc:3s} {ok:4d}/{total:4d} in-language ({pct:5.1f}%)"
              f"  missing {len(miss_p)} pages / {len(miss_t)} props"
              f" / {len(miss_ui)} ui keys{flag}")
        if verbose:
            for route, sc, text in wrong[:20]:
                print(f"        {route:34s} [{sc}] {text[:70]}")
            for k in sorted(miss_p)[:20]:
                print(f"        MISSING commentary page: {k}")
            for k in sorted(miss_t)[:20]:
                print(f"        MISSING prop: {k}")
            for k in sorted(miss_ui)[:20]:
                print(f"        MISSING ui key: {k}")
    return bad


if __name__ == "__main__":
    sys.exit(main())
