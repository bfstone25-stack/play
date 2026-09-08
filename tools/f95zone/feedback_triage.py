#!/usr/bin/env python3
"""Tier-1 community feedback filter for Elena / F95 loops.

Reads scraped reply JSON and splits ideological noise from actionable signal.
Does not auto-post arguments. Safe to run unattended.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

NOISE_PATTERNS = [
    r"\bai slop\b",
    r"\bslop\b",
    r"\bshitty business\b",
    r"\bpay for something you didn'?t\b",
    r"\b100% slop\b",
    r"\bsloppenheimer\b",
]

ACTIONABLE_PATTERNS = [
    (r"banner|title.*(small|tiny|microscop)|text size", "promo_banner_readability"),
    (r"lock(s|ed)? herself|getaway|vault", "plot_vault_motivation"),
    (r"overview|cliche|em dash|what begins", "overview_prose_quality"),
    (r"\bai tag\b|skip the ai", "tagging_disclosure"),
    (r"bug|crash|save|error|render|artifact|typo", "technical_bug"),
    (r"ui|font|text size|unreadable", "ui_readability"),
]


def classify(text: str) -> dict:
    low = text.lower()
    noise_hits = [p for p in NOISE_PATTERNS if re.search(p, low)]
    signals = []
    for pat, label in ACTIONABLE_PATTERNS:
        if re.search(pat, low):
            signals.append(label)
    # Pure thanks / reactions
    if re.fullmatch(r"(thx|thanks|thank you).*", low.strip()):
        return {"tier": "positive", "signals": ["thanks"], "noise": []}
    if signals:
        return {"tier": "actionable", "signals": sorted(set(signals)), "noise": noise_hits}
    if noise_hits:
        return {"tier": "noise", "signals": [], "noise": noise_hits}
    return {"tier": "review", "signals": [], "noise": []}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--in", dest="infile", required=True, help="JSON list of {author,text,...}")
    ap.add_argument(
        "--out",
        default=str(Path.home() / ".local/share/f95zone/elena_feedback_triage.json"),
    )
    args = ap.parse_args()
    rows = json.loads(Path(args.infile).read_text(encoding="utf-8"))
    out_rows = []
    for row in rows:
        text = row.get("text") or ""
        # skip OP/dev notes from BlazeCore unless reviewing own copy
        if row.get("author") == "BlazeCore" and "Overview" in text[:40]:
            continue
        cls = classify(text)
        out_rows.append({**row, **cls})
    Path(args.out).expanduser().parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).expanduser().write_text(json.dumps(out_rows, indent=2) + "\n", encoding="utf-8")
    summary = {}
    for r in out_rows:
        summary[r["tier"]] = summary.get(r["tier"], 0) + 1
    print(json.dumps({"wrote": args.out, "summary": summary, "items": len(out_rows)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
