#!/usr/bin/env python3
"""VESPER's authored prose -> data/story/<route>_c<n>.json and <route>_end.json.

Source: play/flutter-after-hours/backend/stories_x/<route>.json (itself derived from the
parent play/flutter; never hand-edited). Every string is copied verbatim; nothing is
written here. Line numbering (`src`) per chapter file:

    1            the chapter opening (narrator)
    2            ch1 only: the cast/age note (narrator)
    10*i, 10*i+1 beat i: the event (narrator), his line
    100+20*j     choice j: his prompt;  100+20*j+1+k: his reply to option k
  <route>_end:   10*e+p   ending e, paragraph p (p=0 is the title)

`en` always; `zh` only for the four routes whose parent prose is really Chinese (liam and
adrian's _zh fields hold English in the parent, see the fork README); no `ja` exists in the
parent, so Loc.line() falls back to English for these lines in Japanese.

Writes data/story_index.json (the structure the night builder needs).
"""
import json
import re
from pathlib import Path

R = Path(__file__).resolve().parent.parent
SRC = R.parent / "flutter-after-hours/backend/stories_x"
OUT = R / "data/story"
ROUTES = ["guyan", "ethan", "luxingye", "liam", "adrian", "fushen"]
ZH_OK = {"ethan", "luxingye", "guyan", "fushen"}
CJK = re.compile(r"[一-鿿]")


def ln(src, lid, who, en, zh, route):
    d = {"src": src, "id": lid, "who": who, "en": en.strip()}
    if route in ZH_OK and zh and CJK.search(zh):
        d["zh"] = zh.strip()
    return d


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    index = {}
    n_lines = 0
    for r in ROUTES:
        st = json.loads((SRC / f"{r}.json").read_text())
        ri = {"title_en": st["title_en"], "title_zh": st.get("title_zh", ""), "logline_en": st["logline_en"],
              "cg_heat": st["cg_heat"], "hold_en": st.get("hold_en", []), "chapters": [], "endings": []}
        for ci, ch in enumerate(st["chapters"], 1):
            fid = f"{r}_c{ci}"
            lines = [ln(1, f"{fid}_open", "narrator", ch["opening_en"], ch.get("opening_zh", ""), r)]
            if ci == 1 and st.get("cast_note_en"):
                lines.append(ln(2, f"{fid}_cast", "narrator", st["cast_note_en"], st.get("cast_note_zh", ""), r))
            beats = []
            for bi, b in enumerate(ch["beats"], 1):
                lines.append(ln(10 * bi, f"{fid}_{b['id']}_ev", "narrator", b["event_en"], b.get("event_zh", ""), r))
                lines.append(ln(10 * bi + 1, f"{fid}_{b['id']}_he", r, b["text_en"], b.get("text_zh", ""), r))
                beats.append({"id": b["id"], "range": f"{fid}:{10*bi}-{10*bi+1}", "heat": b.get("heat", 0),
                              "added": bool(b.get("added_by_fork")), "aff_min": b["trigger"].get("aff_min", 0)})
            choices = []
            for cj, c in enumerate(ch["choices"]):
                base = 100 + 20 * cj
                lines.append(ln(base, f"{fid}_{c['id']}_q", r, c["prompt_en"], c.get("prompt_zh", ""), r))
                opts = []
                for k, o in enumerate(c["options"]):
                    lines.append(ln(base + 1 + k, f"{fid}_{c['id']}_r{k}", r, o["reply_en"], o.get("reply_zh", ""), r))
                    opts.append({"text_en": o["text_en"], "aff": o.get("aff", 0), "flag": o.get("flag", ""),
                                 "reply": f"{fid}:{base+1+k}-{base+1+k}", "added": bool(o.get("added_by_fork"))})
                choices.append({"id": c["id"], "prompt": f"{fid}:{base}-{base}", "options": opts})
            n_lines += len(lines)
            (OUT / f"{fid}.json").write_text(json.dumps({"lines": lines, "menus": {}}, ensure_ascii=False, indent=0))
            ri["chapters"].append({"file": fid, "title_en": ch["title_en"], "title_zh": ch.get("title_zh", ""),
                                   "goal_en": ch["goal_en"], "scene_en": ch["scene_en"], "cg": ch.get("cg"),
                                   "open": f"{fid}:1-{2 if ci == 1 else 1}", "beats": beats, "choices": choices})
        lines = []
        for ei, e in enumerate(st["endings"], 1):
            paras_en = [p for p in e["text_en"].split("\n\n") if p.strip()]
            paras_zh = [p for p in e.get("text_zh", "").split("\n\n") if p.strip()]
            lines.append(ln(10 * ei, f"{r}_end_{e['id']}_t", "narrator", e["title_en"], e.get("title_zh", ""), r))
            for p, para in enumerate(paras_en, 1):
                zh = paras_zh[p - 1] if len(paras_zh) == len(paras_en) else ""
                lines.append(ln(10 * ei + p, f"{r}_end_{e['id']}_{p}", "narrator", para, zh, r))
            assert len(paras_en) < 10, (r, e["id"])
            ri["endings"].append({"id": e["id"], "priority": e.get("priority", 9), "aff_min": e.get("aff_min", 0),
                                  "aff_max": e.get("aff_max"), "flags_any": e.get("flags_any", []), "cg": e.get("cg"),
                                  "title_en": e["title_en"], "range": f"{r}_end:{10*ei}-{10*ei+len(paras_en)}"})
        n_lines += len(lines)
        (OUT / f"{r}_end.json").write_text(json.dumps({"lines": lines, "menus": {}}, ensure_ascii=False, indent=0))
        index[r] = ri
    (R / "data/story_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1))
    print(f"import_story: {len(ROUTES)} routes, {n_lines} lines")


if __name__ == "__main__":
    main()
