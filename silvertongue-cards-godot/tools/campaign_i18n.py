#!/usr/bin/env python3
"""The Night Ledger in Chinese and Japanese: every string the SUASION title server can put
on a Nutaku player's screen, and the table the client translates them with.

The server speaks English only, on purpose: card lines are rules (decompose() reads the
English), reply lines are picked by a seeded rng during replay, and one language on the
wire keeps the replay the only authority. The client translates what it is sent through
Loc (scripts/loc.gd), the same way it translates its own chrome: keyed on the exact
English string. So the whole job is a table, and this file owns it.

  sources   assets/i18n/src/zh.json, assets/i18n/src/ja.json   English -> translation,
            hand-written (not word for word); ja also inherits the base game's existing
            Japanese (backend/replies_ja.py, cards_ja.py) where src has no entry
  output    assets/i18n/campaign.json   {"ja": {...}, "zh": {...}, "zh-Hant": {...}}
            zh-Hant is converted from zh with OpenCC (s2twp)

    python3 tools/campaign_i18n.py              # build campaign.json; prints what is missing
    python3 tools/campaign_i18n.py --missing zh # the untranslated strings as JSON
    python3 tools/campaign_i18n.py --chunks 8 DIR   # split the untranslated for translators

ops/nutaku/suasion_f2p/check_i18n.py imports `english()` and fails on any gap.
"""
from __future__ import annotations

import ast
import json
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
PROJECT = HERE.parent
PLAY = PROJECT.parent
CARDS_ROOT = PLAY / "silvertongue-cards"
PRODUCTS = PLAY.parent
OPS = PRODUCTS / "ops" / "nutaku"
SRC = PROJECT / "assets" / "i18n" / "src"
OUT = PROJECT / "assets" / "i18n" / "campaign.json"
LANGS = ("zh", "ja")


def _campaign():
    if str(CARDS_ROOT) not in sys.path:
        sys.path.insert(0, str(CARDS_ROOT))
    os.environ.setdefault("ST_ENGINE_PATH", str(PLAY / "silvertongue-x" / "backend" / "persuasion_engine.py"))
    from backend import campaign as K
    from backend import cards as C
    from backend import replies as R
    return K, C, R


# What the servers can say to a player that is not campaign text: every refusal the
# client may show (it shows `reason` in a toast). Numbers are templated as %s, which is how
# Loc.t matches a reason with numbers in it. check_i18n.py reads the servers' source and
# fails if a _no(...) there is not covered here.
SERVER_REASONS = [
    "invalid or expired session", "no such stage", "a deck needs at least %s cards she will hear tonight",
    "today's rematch is already played", "stage locked", "needs more bond", "needs more standing",
    "no charm", "unknown duel", "duel is open", "duel is won", "duel is failed", "duel is abandoned",
    "duel is rejected", "the replayed duel does not win", "too fast (%ss for %s plays)",
    "no open duel", "n must be %s or %s", "pay with ticket or chips", "request_id required",
    "this pull was already made", "not enough tickets", "not enough chips", "you do not own that card",
    "already at full stars", "not enough copies", "no night pass", "already claimed today", "locked",
    "plate missing on server", "claim all three missions first", "bonus already claimed",
    "no such mission today", "already claimed", "mission not complete", "level required",
    "no such level", "level locked", "no energy", "unknown attempt", "attempt is won", "attempt is failed", "attempt is abandoned", "attempt is rejected", "no open attempt", "unknown item",
    "no token", "scene locked", "no such scene", "test clock disabled", "request failed",
    "duels are opened and closed by /suasion/duel/*",
    # the duel engine's refusals (campaign/duel.py DuelError), relayed by /suasion/duel/play
    "duel is over", "no wild left", "wild needs a line", "card not in hand", "needs %s nerve, have %s",
    "unknown card", "timeout", "unknown sku", "handshake: no session in the game server's answer",
    "server said %s",
]


def _config_strings() -> list[tuple[str, str]]:
    cfg = json.loads((OPS / "suasion_f2p" / "config.example.json").read_text())
    out = []
    for sid, s in cfg["skus"].items():
        out.append((s["name"], f"store item name ({sid})"))
        out.append((s["description"], f"store item description ({sid})"))
    for m in cfg["f2p"]["missions"]:
        out.append((m["text"], "daily mission"))
    for s in cfg["f2p"]["scenes"]:
        out.append((s["title"], "chapter scene title"))
    return out


def english() -> dict[str, str]:
    """Every player-visible English string the server side can send -> a context note."""
    K, C, R = _campaign()
    out: dict[str, str] = {}

    def add(s, ctx):
        s = str(s)
        if s.strip() and s not in out:
            out[s] = ctx
    add(K.PROLOGUE, "prologue (narration, second person, noir)")
    for ch in K.CHAPTERS:
        who = ch["who"]
        add(ch["title"], f"chapter title ({who})")
        add(ch["house"], f"place name ({who}'s house)")
        add(ch["intro"], f"chapter intro narration ({who})")
        add(ch["outro"], f"chapter outro narration ({who})")
        add("Last Call: " + ch["title"], "Last Call chapter title")
        lc = K.LAST_CALL[ch["id"]]
        add(lc["intro"], f"Last Call intro narration ({who})")
        add(lc["coda"], f"Last Call coda narration ({who})")
    for s in K.STAGES:
        who = s["who"]
        for f in ("title", "goal", "intro", "win", "lose"):
            add(s[f], f"stage {f} ({who})" + (" narration" if f in ("intro", "win", "lose") else ""))
        if s["mods"].get("boss"):
            add(s["mods"]["boss"], "boss special rule")
    for who, sc in K.BOND_SCENES.items():
        for tier, text in sc.items():
            add(text, f"bond scene {tier} ({who}), intimate but tier-1/2: nothing explicit")
    tables = [("celeste", K.CELESTE)] + [(w, t) for w, t in K.NIGHTS.items()]
    tables += [(C.SCENARIO_CHARACTER[scen], t) for scen, t in R.R.items()]
    for who, t in tables:
        for key, lines in t.items():
            for ln in lines:
                add(ln, f"{who} speaking (reply line; key {key})")
    for who, lines in list(K.MUTED.items()) + list(K.ORDER.items()):
        for ln in lines:
            add(ln, f"{'celeste' if who == '*' else who} (rule beat)")
    for c in K.ALL_CARDS:
        add(c.line, f"card line the PLAYER says ({c.character} card; {c.rarity})")
    add(C.SMALL_PRINT, "small print on a coercion card")
    for c in K.ALL_CARDS:
        if getattr(c, "face", ""):
            add(c.face, "the big number printed on a coercion card (momentum is the game's term)")
    for w, m in K.CHARACTERS.items():
        add(m["name"], "character name")
    for s, ctx in _config_strings():
        add(s, ctx)
    for s in SERVER_REASONS:
        add(s, "server refusal shown in a toast (%s = a number)")
    return out


def _base_ja() -> dict[str, str]:
    """The base game's Japanese: replies_ja line for line with replies.R, cards_ja by id."""
    K, C, R = _campaign()
    from backend import replies_ja as RJ
    from backend import cards_ja as CJ
    out = {}
    for scen, t in R.R.items():
        tj = RJ.R_JA.get(scen, {})
        for key, lines in t.items():
            for en, ja in zip(lines, tj.get(key, [])):
                out.setdefault(en, ja)
    for c in C.CARDS:
        if c.id in CJ.LINES_JA:
            out.setdefault(c.line, CJ.LINES_JA[c.id])
    return out


def _load(lang: str) -> dict[str, str]:
    p = SRC / f"{lang}.json"
    return json.loads(p.read_text()) if p.exists() else {}


def tables() -> dict[str, dict[str, str]]:
    t = {lang: _load(lang) for lang in LANGS}
    for en, ja in _base_ja().items():
        t["ja"].setdefault(en, ja)
    return t


def missing(lang: str) -> dict[str, str]:
    t = tables()[lang]
    return {en: ctx for en, ctx in english().items() if not str(t.get(en, "")).strip()}


def build() -> dict:
    t = tables()
    want = english()
    out = {lang: {en: t[lang][en] for en in want if str(t[lang].get(en, "")).strip()} for lang in LANGS}
    try:
        import opencc
        cc = opencc.OpenCC("s2twp")
        out["zh-Hant"] = {en: cc.convert(v) for en, v in out["zh"].items()}
    except ImportError:
        print("!! opencc missing: zh-Hant falls back to zh in Loc", file=sys.stderr)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=0, sort_keys=True) + "\n")
    return out


def main() -> int:
    a = sys.argv[1:]
    if a[:1] == ["--missing"]:
        print(json.dumps(missing(a[1]), ensure_ascii=False, indent=1))
        return 0
    if a[:1] == ["--chunks"]:
        n, d = int(a[1]), pathlib.Path(a[2])
        d.mkdir(parents=True, exist_ok=True)
        todo = {lang: missing(lang) for lang in LANGS}
        keys = sorted(set(todo["zh"]) | set(todo["ja"]), key=list(english()).index)
        size, i = sum(len(k.split()) for k in keys) / n, 0
        chunk, words = [], 0
        for k in keys:
            chunk.append({"en": k, "ctx": english()[k], "need": [lang for lang in LANGS if k in todo[lang]]})
            words += len(k.split())
            if words >= size and i < n - 1:
                (d / f"chunk_{i:02d}.json").write_text(json.dumps(chunk, ensure_ascii=False, indent=1))
                i, chunk, words = i + 1, [], 0
        if chunk:
            (d / f"chunk_{i:02d}.json").write_text(json.dumps(chunk, ensure_ascii=False, indent=1))
        print(f"{len(keys)} strings in {i + 1} chunks -> {d}")
        return 0
    out = build()
    want = english()
    for lang in LANGS:
        gap = [en for en in want if en not in out[lang]]
        print(f"  {lang}: {len(want) - len(gap)}/{len(want)}" + (f"  missing {len(gap)}" if gap else ""))
    print(f"  -> {OUT.relative_to(PRODUCTS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
