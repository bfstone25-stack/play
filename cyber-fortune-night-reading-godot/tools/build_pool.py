#!/usr/bin/env python3
"""Emit pool/*.json from the hand-written pools in tools/pool_*.py, then subset the CJK
font to exactly the characters the game can display (tools/subset_font.py)."""
import json, pathlib, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import pool_slips, pool_tarot, pool_ui, pool_night, pool_ja  # noqa: E402

KANA = lambda t: any("\u3041" <= c <= "\u30ff" for c in t)
_bad: list[str] = []


def ja(where: str, text: str, prose: bool = True) -> str:
    """One Japanese string, checked on the way through.

    Present is not translated. A zh string pasted into a ja slot passes every
    completeness test, which is how Floor 13 shipped three languages holding Chinese
    prose; the only cheap thing that tells them apart is kana. Verses are 漢語 in
    Japanese too, so they are checked for presence only."""
    if not text:
        _bad.append(where + ": empty")
    elif prose and not KANA(text):
        _bad.append(where + ": no kana -- " + text[:24])
    return text

OUT = HERE.parent / "pool"
OUT.mkdir(exist_ok=True)

slips = []
for i, (rank, subj, vz, ve, rz, re_, dz, de) in enumerate(pool_slips.SLIPS):
    sid = "%s-%s-%d" % (rank, subj, i)
    jv, jr, jd = pool_ja.SLIPS.get(sid, ("", "", ""))
    slips.append(dict(id=sid, rank=rank, subject=subj,
                      verse_zh=vz, verse_en=ve, read_zh=rz, read_en=re_, do_zh=dz, do_en=de,
                      verse_ja=ja("slip " + sid + " verse", jv, prose=False),
                      read_ja=ja("slip " + sid + " read", jr),
                      do_ja=ja("slip " + sid + " do", jd)))
(OUT / "slips.json").write_text(json.dumps(slips, ensure_ascii=False, indent=0), "utf-8")
cards = pool_tarot.cards()
for c in cards:
    nm, up, updo, rev, revdo = pool_ja.TAROT.get(c["slug"], ("", "", "", "", ""))
    c["name_ja"] = ja("card " + c["slug"] + " name", nm, prose=False)
    c["up_ja"] = ja("card " + c["slug"] + " up", up)
    c["up_do_ja"] = ja("card " + c["slug"] + " up_do", updo)
    c["rev_ja"] = ja("card " + c["slug"] + " rev", rev)
    c["rev_do_ja"] = ja("card " + c["slug"] + " rev_do", revdo)
(OUT / "tarot.json").write_text(json.dumps(cards, ensure_ascii=False, indent=0), "utf-8")
cast = json.loads(json.dumps(pool_night.CAST))       # a copy; the module stays zh/en
for c in cast:
    j = pool_ja.NIGHT.get(c["id"], {})
    c["name_ja"] = ja("cast " + c["id"] + " name", j.get("name", ""), prose=False)
    c["who_ja"] = ja("cast " + c["id"] + " who", j.get("who", ""))
    for tr in c["tracks"]:
        jt = j.get("tracks", {}).get(tr["id"], {})
        for f in ("name", "belief", "open_strong", "open_weak", "refuse", "locked"):
            tr[f + "_ja"] = ja("cast %s/%s %s" % (c["id"], tr["id"], f), jt.get(f, ""),
                               prose=(f != "name"))
    js = j.get("scene", {})
    c["scene"]["invite_ja"] = ja("cast " + c["id"] + " invite", js.get("invite", ""))
    c["scene"]["beats_ja"] = [ja("cast " + c["id"] + " beat", b) for b in js.get("beats", [])]
    if len(c["scene"]["beats_ja"]) != len(c["scene"]["beats_en"]):
        _bad.append("cast " + c["id"] + ": ja beats do not match en beats")
    c["scene"]["after_ja"] = ja("cast " + c["id"] + " after", js.get("after", ""))
(OUT / "night.json").write_text(json.dumps(cast, ensure_ascii=False, indent=0), "utf-8")
# The fork's strings win over the parent's where they collide (title, series).
ui = {k: dict(v) for k, v in pool_ui.UI.items()}
for k, v in pool_night.UI_NIGHT.items():
    ui[k] = dict(v)
for k, v in ui.items():
    # Chrome is mostly short labels and a few of them are bare numbers or {vars}; the
    # kana check would flag "{have} / {all}". Presence is what is enforced here.
    v["ja"] = ja("ui " + k, pool_ja.UI.get(k, ""), prose=False)
(OUT / "ui.json").write_text(json.dumps(ui, ensure_ascii=False, indent=0), "utf-8")
print("slips %d, cards %d (%d readings), cast %d, ui %d keys" % (len(slips), len(cards), len(cards) * 2, len(pool_night.CAST), len(ui)))
if _bad:
    print("\nja is not complete -- refusing to build a language the pools cannot answer in:",
          file=sys.stderr)
    for b in _bad[:20]:
        print("  " + b, file=sys.stderr)
    if len(_bad) > 20:
        print("  ... and %d more" % (len(_bad) - 20), file=sys.stderr)
    raise SystemExit(1)
subprocess.check_call([sys.executable, str(HERE / "subset_font.py")])
