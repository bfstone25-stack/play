#!/usr/bin/env python3
"""Export F95zone cookies from a local Chrome profile into a secrets JSON file.

Chrome encrypts cookie values via the desktop keyring (libsecret/D-Bus).
This exporter uses browser-cookie3 against the live Chrome profile.

Never commit the output. Prefer ~/.config/f95zone/cookies.json (mode 0600).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def ensure_dbus() -> None:
    if os.environ.get("DBUS_SESSION_BUS_ADDRESS") not in (None, "", "disabled:", "autolaunch:"):
        return
    candidates = sorted(Path("/tmp").glob("dbus-*"))
    # Prefer sockets that actually decrypt (try later); set first existing for now.
    for p in reversed(candidates):  # newer sockets often last
        if p.exists():
            os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={p}"
            return


def export_with_dbus_fallback(domain: str):
    import browser_cookie3

    ensure_dbus()
    buses = []
    current = os.environ.get("DBUS_SESSION_BUS_ADDRESS")
    if current:
        buses.append(current)
    for p in sorted(Path("/tmp").glob("dbus-*")):
        addr = f"unix:path={p}"
        if addr not in buses:
            buses.append(addr)

    last_err: Exception | None = None
    for addr in buses:
        os.environ["DBUS_SESSION_BUS_ADDRESS"] = addr
        try:
            jar = browser_cookie3.chrome(domain_name=domain)
            cookies = []
            for c in jar:
                if domain not in (c.domain or ""):
                    continue
                cookies.append(
                    {
                        "domain": c.domain,
                        "name": c.name,
                        "value": c.value,
                        "path": c.path or "/",
                        "secure": bool(c.secure),
                        "expires": c.expires,
                    }
                )
            if cookies:
                return cookies, addr
        except Exception as e:  # try next bus
            last_err = e
            continue
    raise RuntimeError(f"cookie decrypt failed on all D-Bus sockets: {last_err!r}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", required=True, help="Output JSON path (keep outside git)")
    ap.add_argument("--names-only", action="store_true", help="Write names+lengths only")
    ap.add_argument("--domain", default="f95zone.to", help="Cookie domain filter")
    args = ap.parse_args()

    try:
        import browser_cookie3  # noqa: F401
    except ImportError:
        print("error: pip install browser-cookie3", file=sys.stderr)
        return 2

    try:
        cookies, bus = export_with_dbus_fallback(args.domain)
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    summary = {c["name"]: len(c["value"] or "") for c in cookies}
    print(f"dbus={bus}")
    print(f"cookie_names={sorted(summary)}")
    print(f"lengths={summary}")
    missing = sorted({"xf_user", "xf_session"} - set(summary))
    if missing:
        print(
            f"warning: missing auth cookies {missing} — is Chrome logged into f95zone.to?",
            file=sys.stderr,
        )

    out_path = Path(args.out).expanduser()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if args.names_only:
        payload = {
            "base_url": "https://f95zone.to",
            "cookies": [{"name": n, "length": summary[n]} for n in sorted(summary)],
        }
    else:
        payload = {"base_url": "https://f95zone.to", "cookies": cookies}
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    os.chmod(out_path, 0o600)
    print(f"wrote {out_path} (mode 0600)")
    return 0 if not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
