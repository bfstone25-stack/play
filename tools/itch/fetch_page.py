#!/usr/bin/env python3
"""Fetch an itch page with the Firefox session and save raw HTML locally.

Usage (on pop-os): python3 fetch_page.py <url> <out_path>
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jam_submit import fetch, firefox_itch_cookies, opener_for


def main() -> int:
    url, out = sys.argv[1], sys.argv[2]
    cookies = firefox_itch_cookies()
    if "itchio" not in cookies:
        print("NOT LOGGED IN")
        return 2
    opener = opener_for(cookies)
    code, final_url, body = fetch(opener, url)
    Path(out).write_text(body, encoding="utf-8")
    print(f"{code} {len(body)} -> {out} (final: {final_url})")
    return 0 if code == 200 else 1


if __name__ == "__main__":
    raise SystemExit(main())
