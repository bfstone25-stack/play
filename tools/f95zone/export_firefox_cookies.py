#!/usr/bin/env python3
"""Export F95zone cookies from a local Firefox profile (names+values to a secrets file).

Never commit the output. Prefer ~/.config/f95zone/cookies.json (mode 0600).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path

HOST_NEEDLES = ("f95zone.to", ".f95zone.to")
WANTED = {
    "xf_user",
    "xf_session",
    "xf_csrf",
    "cf_clearance",
    "__cf_bm",
}


def find_profiles(firefox_root: Path) -> list[Path]:
    if not firefox_root.is_dir():
        return []
    profiles = []
    for child in firefox_root.iterdir():
        if not child.is_dir():
            continue
        if (child / "cookies.sqlite").is_file():
            profiles.append(child)
    return sorted(profiles, key=lambda p: (p / "cookies.sqlite").stat().st_mtime, reverse=True)


def read_cookies(cookies_sqlite: Path) -> list[dict]:
    # Firefox locks cookies.sqlite; copy first.
    with tempfile.TemporaryDirectory(prefix="f95-cookies-") as tmp:
        tmp_db = Path(tmp) / "cookies.sqlite"
        shutil.copy2(cookies_sqlite, tmp_db)
        # WAL companions if present
        for suffix in ("-wal", "-shm"):
            side = Path(str(cookies_sqlite) + suffix)
            if side.is_file():
                shutil.copy2(side, Path(str(tmp_db) + suffix))
        con = sqlite3.connect(str(tmp_db))
        try:
            rows = con.execute(
                "SELECT host, name, value, path, isSecure, expiry "
                "FROM moz_cookies WHERE host LIKE '%f95zone%'"
            ).fetchall()
        finally:
            con.close()

    out = []
    for host, name, value, path, is_secure, expiry in rows:
        if not any(h in host for h in ("f95zone",)):
            continue
        if name not in WANTED and not name.startswith("xf_"):
            # Keep CF + XF family; skip unrelated trackers.
            if not name.startswith("__cf") and name not in WANTED:
                continue
        out.append(
            {
                "domain": host,
                "name": name,
                "value": value,
                "path": path or "/",
                "secure": bool(is_secure),
                "expires": int(expiry) if expiry else None,
            }
        )
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--firefox-root",
        default=os.path.expanduser("~/.mozilla/firefox"),
        help="Firefox profiles root",
    )
    ap.add_argument(
        "--profile",
        default=None,
        help="Optional profile directory name (e.g. xxxxx.default-release)",
    )
    ap.add_argument(
        "--out",
        required=True,
        help="Output JSON path (keep outside git)",
    )
    ap.add_argument(
        "--names-only",
        action="store_true",
        help="Write names+lengths only (safe for logs)",
    )
    args = ap.parse_args()

    root = Path(args.firefox_root)
    if args.profile:
        profile = root / args.profile
        if not (profile / "cookies.sqlite").is_file():
            print(f"error: no cookies.sqlite in {profile}", file=sys.stderr)
            return 2
        profiles = [profile]
    else:
        profiles = find_profiles(root)
        if not profiles:
            print(f"error: no Firefox profiles under {root}", file=sys.stderr)
            return 2

    cookies = read_cookies(profiles[0] / "cookies.sqlite")
    names = {c["name"] for c in cookies}
    missing = sorted({"xf_user", "xf_session"} - names)
    summary = {c["name"]: len(c["value"]) for c in cookies}
    print(f"profile={profiles[0]}")
    print(f"cookie_names={sorted(summary)}")
    print(f"lengths={summary}")
    if missing:
        print(
            f"warning: missing auth cookies {missing} — is Firefox logged into f95zone.to?",
            file=sys.stderr,
        )

    out_path = Path(args.out).expanduser()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if args.names_only:
        payload = {
            "base_url": "https://f95zone.to",
            "profile": str(profiles[0]),
            "cookies": [{"name": n, "length": summary[n]} for n in sorted(summary)],
        }
    else:
        payload = {
            "base_url": "https://f95zone.to",
            "profile": str(profiles[0]),
            "cookies": cookies,
        }
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    os.chmod(out_path, 0o600)
    print(f"wrote {out_path} (mode 0600)")
    return 0 if not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
