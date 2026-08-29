#!/usr/bin/env python3
"""Audit all itch games on the account: publish state, pricing, assets, copy.

Run on pop-os. Prints one JSON line per game.
"""
from __future__ import annotations

import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jam_submit import fetch, firefox_itch_cookies, opener_for
from itch_publish import edit_page, embedded_state


class TextLen(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.total = 0

    def handle_data(self, data: str) -> None:
        self.total += len(data.strip())


def desc_len(html: str) -> int:
    m = re.search(r'name="game\[description\]"[^>]*>(.*?)</textarea>', html, re.S)
    if not m:
        return 0
    p = TextLen()
    p.feed(m.group(1))
    return p.total


def main() -> int:
    cookies = firefox_itch_cookies()
    if "itchio" not in cookies:
        print("NOT LOGGED IN")
        return 2
    opener = opener_for(cookies)
    code, _, dash = fetch(opener, "https://itch.io/dashboard")
    rows = []
    for m in re.finditer(r"<a href=\"https://bfstone25-stack\.itch\.io/([^\"]+)\" class=\"game_link\"[^>]*>([^<]+)</a>", dash):
        slug, title = m.group(1), m.group(2)
        tail = dash[m.end():m.end() + 3000]
        g = re.search(r"game/edit/(\d+)", tail)
        p = re.search(r"publish_status.*?>(\w+)</a>", tail, re.S)
        if g:
            rows.append((slug, title, g.group(1), p.group(1) if p else "?"))
    skip = {"across-the-hall", "late-inspection", "floor-13", "midnight-pawn"}
    for slug, title, gid, pub in rows:
        if slug in skip:
            continue
        html, _ = edit_page(opener, int(gid))
        state = embedded_state(html)
        uploads = state.get("uploads", [])
        out = {
            "id": gid,
            "slug": slug,
            "title": state.get("game", {}).get("title", title),
            "published": state.get("published"),
            "type": state.get("type"),
            "min_price": state.get("min_price"),
            "disable_payments": state.get("disable_payments"),
            "tags": len((state.get("game_tags") or {}).get("tags") or []),
            "cover": bool(state.get("cover_image")),
            "screenshots": len(state.get("game", {}).get("screenshots") or []),
            "desc_chars": desc_len(html),
            "uploads": [
                {"ch": u.get("channel_name"), "embed": u.get("embed"), "type": u.get("type"),
                 "state": u.get("state"), "size_mb": round((u.get("size") or 0) / 1e6, 1)}
                for u in uploads
            ],
            "ai": state.get("ai_disclosure", {}).get("ai_generated"),
        }
        print(json.dumps(out, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
