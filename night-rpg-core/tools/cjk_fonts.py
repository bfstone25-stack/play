#!/usr/bin/env python3
"""CJK/Hangul font coverage for one night-rpg title, then a glyph check for all 7 languages.

    python3 night-rpg-core/tools/cjk_fonts.py play/<game> [--check-only]

Writes, from the system Noto Sans CJK collection, one subset per script family so each
language gets its own glyph forms (a Chinese reader must not see Japanese kanji shapes, and
vice versa -- ops/subset_cjk.py explains the trap):
    assets/fonts/nr_cjk_sc.otf   every character the zh text uses   (Noto Sans CJK SC)
    assets/fonts/nr_cjk_kr.otf   every character the ko text uses   (Noto Sans CJK KR)
and, when the title's own "cjk" face is a *subset* file, re-cuts it from Noto Sans CJK JP
with every character the ja text uses. NRSkin puts the current language's face first in
the fallback chain. Then it proves every character of every language is drawn by the body
or display face or a fallback in that language's chain (exit 1 on any miss = tofu)."""
import json, sys, glob
from pathlib import Path
from fontTools.ttLib import TTFont, TTCollection
from fontTools import subset

TTC = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
FACE = {"ja": 0, "ko": 1, "zh": 2}
LANGS = ["en", "ja", "de", "fr", "es", "zh", "ko"]
g = Path(sys.argv[1]).resolve()
core = Path(__file__).resolve().parent.parent / "addons/night_rpg"
texts = {l: [] for l in LANGS}


def add_row(row):
    if isinstance(row, dict):
        for l in LANGS:
            v = row.get(l)
            if isinstance(v, str):
                texts[l].append(v)


for p in [core / "strings_core.json", g / "data/strings.json"]:
    for v in json.loads(p.read_text()).values():
        add_row(v)
for p in glob.glob(str(g / "data/story/*.json")):
    st = json.loads(Path(p).read_text())
    for ln in st.get("lines", []):
        add_row(ln)
    for en, ja in st.get("menus", {}).items():
        texts["en"].append(en); texts["ja"].append(str(ja))
for l in LANGS:
    ov = g / f"data/i18n/{l}.json"
    if ov.exists():
        texts[l] += [str(x) for x in json.loads(ov.read_text()).values()]
    so = g / f"data/i18n/story/{l}.json"
    if so.exists():
        d = json.loads(so.read_text())
        texts[l] += [str(x) for x in d.get("lines", {}).values()] + [str(x) for x in d.get("menus", {}).values()]
chars = {l: set("".join(texts[l])) - set("\n\t") for l in LANGS}
for l in LANGS:
    chars[l] |= {chr(c) for c in range(0x20, 0x7f)}
game = json.loads((g / "data/game.json").read_text())
fonts = game.get("fonts", {})


def res(p):
    return g / p.replace("res://", "")


def cut(face, keep, out):
    col = TTCollection(TTC)
    f = col.fonts[face]
    cmap = f.getBestCmap()
    uni = sorted(ord(c) for c in keep if ord(c) in cmap)
    opts = subset.Options(); opts.layout_features = ["*"]; opts.name_IDs = ["*"]; opts.notdef_outline = True
    s = subset.Subsetter(opts); s.populate(unicodes=uni); s.subset(f)
    f.save(out)
    print(f"  {out.name}: {len(uni)} glyphs, {out.stat().st_size // 1024} KB")


if "--check-only" not in sys.argv:
    (g / "assets/fonts").mkdir(parents=True, exist_ok=True)
    cut(FACE["zh"], chars["zh"], g / "assets/fonts/nr_cjk_sc.otf")
    cut(FACE["ko"], chars["ko"], g / "assets/fonts/nr_cjk_kr.otf")
    if "subset" in fonts.get("cjk", ""):
        keep = chars["ja"] | {chr(c) for c in TTFont(res(fonts["cjk"])).getBestCmap()}
        cut(FACE["ja"], keep, res(fonts["cjk"]))

cm = {}
for k, p in list(fonts.items()) + [("cjk_sc", "res://assets/fonts/nr_cjk_sc.otf"), ("cjk_ko", "res://assets/fonts/nr_cjk_kr.otf")]:
    if k in cm or not res(p).exists():
        continue
    cm[k] = set(chr(c) for c in TTFont(res(p), fontNumber=0).getBestCmap())
order = {"zh": ["cjk_sc", "cjk", "cjk_ko"], "ko": ["cjk_ko", "cjk", "cjk_sc"]}
bad = 0
for l in LANGS:
    chain = [cm.get(k, set()) for k in order.get(l, ["cjk", "cjk_sc", "cjk_ko"])]
    for primary in ("body", "display"):
        have = cm.get(primary, set()).union(*chain)
        miss = sorted(c for c in chars[l] if c not in have and not c.isspace() and ord(c) not in (0x200b, 0x200c, 0x200d, 0x2060, 0xfeff, 0xfe0f))
        if miss:
            bad += 1
            print(f"  TOFU {l} {primary}: {''.join(miss[:60])} ({len(miss)})")
    # the language's own face must carry its CJK, not a sibling's glyph forms
    if l in ("zh", "ko"):
        own = cm.get(chain and order[l][0], set())
        cjk = [c for c in chars[l] if ord(c) > 0x2e80]
        off = [c for c in cjk if c not in own]
        if off:
            bad += 1
            print(f"  {l}: {len(off)} CJK chars not in its own face: {''.join(off[:40])}")
print(g.name, "glyphs:", "ok" if not bad else f"{bad} problems", {l: len(chars[l]) for l in LANGS})
sys.exit(1 if bad else 0)
