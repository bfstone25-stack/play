#!/usr/bin/env python3
"""Check the public URL and live short_text for a game id (run on pop-os)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jam_submit import fetch, firefox_itch_cookies, opener_for
from page_apply import embedded_state


def main() -> int:
    game_id = sys.argv[1]
    cookies = firefox_itch_cookies()
    opener = opener_for(cookies)
    code, _, html = fetch(opener, f"https://itch.io/game/edit/{game_id}")
    if code != 200:
        print(f"edit -> {code}")
        return 1
    state = embedded_state(html)
    game = state.get("game") or {}
    slug = game.get("slug")
    user = state.get("user_slug") or "bfstone25"
    print("slug:", slug, "| published:", state.get("published"), "| short_text:", game.get("short_text"))
    pub = f"https://{user}.itch.io/{slug}"
    code2, final2, body2 = fetch(opener, pub)
    print(f"public -> {code2} (final {final2})")
    if code2 == 200:
        m = re.search(r'<meta property="og:description" content="([^"]*)"', body2)
        if m:
            print("og:description:", m.group(1))
        Path(f"/tmp/pub-{game_id}.html").write_text(body2, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
