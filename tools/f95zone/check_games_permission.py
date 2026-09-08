#!/usr/bin/env python3
"""Check whether the logged-in F95 session can open Games → Post thread."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

import requests

UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
)


def main() -> int:
    raw = os.environ.get("F95ZONE_COOKIES_FILE", "").strip()
    path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else Path(raw).expanduser()
    if not path.is_file():
        print("error: set F95ZONE_COOKIES_FILE or pass cookie json path", file=sys.stderr)
        return 2
    data = json.loads(path.read_text(encoding="utf-8"))
    cookies = data["cookies"] if isinstance(data, dict) else data
    base = os.environ.get("F95ZONE_BASE_URL", "https://f95zone.to").rstrip("/")
    s = requests.Session()
    s.headers["User-Agent"] = UA
    for c in cookies:
        s.cookies.set(
            c["name"],
            c["value"],
            domain=c.get("domain") or ".f95zone.to",
            path=c.get("path") or "/",
        )
    forum = s.get(f"{base}/forums/games.2/", timeout=60)
    post = s.get(f"{base}/forums/games.2/post-thread", timeout=60)
    has_btn = ("Post thread" in forum.text) or ("Post Thread" in forum.text)
    report = {
        "forum_http": forum.status_code,
        "post_thread_http": post.status_code,
        "post_thread_button_visible": has_btn,
        "can_open_post_form": post.status_code == 200 and ("message" in post.text.lower()),
    }
    print(json.dumps(report, indent=2))
    return 0 if report["can_open_post_form"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
