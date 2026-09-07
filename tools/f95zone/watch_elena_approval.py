#!/usr/bin/env python3
"""Background F95 Elena approval watcher.

Polls the Elena Game Requests thread + related ticket using saved cookies.
Writes status to a log and a machine-readable state file. Optionally notifies
by appending actionable events when staff moves the thread or asks for fixes.

Designed to run unattended (tmux/systemd/cron). Does NOT print cookie values.
"""

from __future__ import annotations

import argparse
import html as H
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

DEFAULT_THREAD = (
    "https://f95zone.to/threads/renpy-elena-crimson-archives-v0-1-0-flat-404.313771/"
)
DEFAULT_TICKET = "https://f95zone.to/tickets/30281/"
UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 "
    "Flat404F95Watcher/1.0"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_session(cookies_file: Path) -> requests.Session:
    data = json.loads(cookies_file.read_text(encoding="utf-8"))
    cookies = data["cookies"] if isinstance(data, dict) else data
    if cookies and "value" not in cookies[0]:
        raise RuntimeError(f"{cookies_file} looks names-only; re-export full cookies")
    s = requests.Session()
    s.headers["User-Agent"] = UA
    for c in cookies:
        s.cookies.set(
            c["name"],
            c["value"],
            domain=c.get("domain") or ".f95zone.to",
            path=c.get("path") or "/",
        )
    return s


def textify(chunk: str) -> str:
    t = re.sub(r"<br\s*/?>", "\n", chunk)
    t = re.sub(r"</p>", "\n", t)
    t = re.sub(r"<[^>]+>", " ", t)
    t = H.unescape(t)
    return re.sub(r"\s+", " ", t).strip()


def check_once(session: requests.Session, thread_url: str, ticket_url: str) -> dict:
    out: dict = {"ts": utc_now(), "ok": True}

    home = session.get("https://f95zone.to/", timeout=60)
    out["logged_in"] = ('data-logged-in="true"' in home.text) or ("BlazeCore" in home.text)

    th = session.get(thread_url, timeout=60, allow_redirects=True)
    out["thread_http"] = th.status_code
    out["thread_url"] = th.url
    title_m = re.search(r"<title>([^<]+)", th.text)
    title = title_m.group(1) if title_m else ""
    out["thread_title"] = title[:160]
    crumbs = [H.unescape(x).strip() for x in re.findall(r'itemprop="name"[^>]*>([^<]+)', th.text)]
    out["crumbs"] = crumbs[:8]
    out["still_req"] = bool(re.search(r"\bREQ\b", title))
    out["in_games"] = ("/forums/games" in th.url) or any(c.lower() == "games" for c in crumbs)
    out["has_attach_imgs"] = "attachments.f95zone.to/2026/09/" in th.text
    out["has_itch_zone_imgs"] = "img.itch.zone" in th.text
    out["view_attachment_text"] = th.text.count("View attachment")
    out["bb_image_count"] = th.text.count("bbImage")

    # Games create permission
    gf = session.get("https://f95zone.to/forums/games.2/", timeout=60)
    out["games_post_button"] = ("Post thread" in gf.text) or ("Post Thread" in gf.text)
    gpt = session.get("https://f95zone.to/forums/games.2/post-thread", timeout=60)
    out["games_post_thread_http"] = gpt.status_code

    # Ticket
    tk = session.get(ticket_url, timeout=60)
    out["ticket_http"] = tk.status_code
    st = re.search(r"Status</[^>]*>\s*<[^>]+>([^<]+)", tk.text)
    out["ticket_status"] = st.group(1).strip() if st else None
    posts = [textify(p) for p in re.findall(r'class="bbWrapper">([\s\S]*?)</div>', tk.text)]
    out["ticket_posts"] = len(posts)
    out["ticket_latest"] = posts[-1][:400] if posts else None

    # Alerts that mention Elena/report/ticket
    al = session.get("https://f95zone.to/account/alerts", timeout=60)
    alerts = []
    for m in re.finditer(r"contentRow-main[\s\S]*?</div>\s*</div>", al.text):
        t = textify(m.group(0))
        if any(k in t.lower() for k in ["elena", "ticket", "report", "req -", "game request"]):
            alerts.append(t[:240])
    out["relevant_alerts"] = alerts[:8]

    # Derive attention flags
    needs = []
    if not out["logged_in"]:
        needs.append("reauth_cookies")
    if out["still_req"] and not out["in_games"]:
        needs.append("waiting_games_move")
    if out["has_itch_zone_imgs"] or out["view_attachment_text"] > 0:
        needs.append("images_may_be_broken")
    if not out["has_attach_imgs"] and not out["in_games"]:
        needs.append("missing_f95_attachments")
    latest = (out["ticket_latest"] or "").lower()
    if any(k in latest for k in ["fix", "template", "image", "broken", "follow this guide", "redo"]):
        # only if latest is from staff-ish content and not our own ack
        if "i updated the opening post" not in latest and "re-uploaded the cover" not in latest:
            needs.append("staff_requested_changes")
    if any("rejected" in a.lower() for a in alerts):
        needs.append("report_rejected")
    if out["in_games"]:
        needs = [n for n in needs if n != "waiting_games_move"]
        needs.append("APPROVED_MOVED_TO_GAMES")
    out["needs_attention"] = needs
    out["approved"] = bool(out["in_games"]) and not out["still_req"]
    return out


def append_jsonl(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")


def write_state(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")


def maybe_refresh_cookies(export_script: Path, out_cookies: Path) -> None:
    if not export_script.is_file():
        return
    import subprocess

    env = os.environ.copy()
    # Prefer known desktop dbus socket if unset/disabled
    if env.get("DBUS_SESSION_BUS_ADDRESS") in (None, "", "disabled:", "autolaunch:"):
        for p in sorted(Path("/tmp").glob("dbus-*")):
            env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={p}"
            break
    subprocess.run(
        [sys.executable, str(export_script), "--out", str(out_cookies)],
        check=False,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--cookies",
        default=os.environ.get("F95ZONE_COOKIES_FILE", str(Path.home() / ".config/f95zone/cookies.json")),
    )
    ap.add_argument("--thread-url", default=DEFAULT_THREAD)
    ap.add_argument("--ticket-url", default=DEFAULT_TICKET)
    ap.add_argument("--interval-sec", type=int, default=1800, help="Default 30 minutes")
    ap.add_argument("--once", action="store_true")
    ap.add_argument(
        "--log",
        default=str(Path.home() / ".local/share/f95zone/elena_watch.jsonl"),
    )
    ap.add_argument(
        "--state",
        default=str(Path.home() / ".local/share/f95zone/elena_watch_state.json"),
    )
    ap.add_argument(
        "--events",
        default=str(Path.home() / ".local/share/f95zone/elena_watch_events.jsonl"),
    )
    ap.add_argument(
        "--refresh-cookies-each",
        type=int,
        default=6,
        help="Refresh Chrome cookies every N loops (0=never)",
    )
    ap.add_argument(
        "--export-script",
        default=str(Path(__file__).resolve().parents[2] / "tools/f95zone/export_chrome_cookies.py"),
    )
    args = ap.parse_args()

    cookies = Path(args.cookies).expanduser()
    log_path = Path(args.log).expanduser()
    state_path = Path(args.state).expanduser()
    events_path = Path(args.events).expanduser()
    export_script = Path(args.export_script).expanduser()

    prev_needs: set[str] | None = None
    loop = 0
    while True:
        loop += 1
        try:
            if args.refresh_cookies_each and loop % args.refresh_cookies_each == 1:
                maybe_refresh_cookies(export_script, cookies)
            session = load_session(cookies)
            status = check_once(session, args.thread_url, args.ticket_url)
        except Exception as e:
            status = {"ts": utc_now(), "ok": False, "error": f"{type(e).__name__}: {e}"}

        append_jsonl(log_path, status)
        write_state(state_path, status)

        needs = set(status.get("needs_attention") or [])
        if prev_needs is not None:
            new = sorted(needs - prev_needs)
            if new:
                append_jsonl(
                    events_path,
                    {
                        "ts": utc_now(),
                        "type": "needs_attention_changed",
                        "new": new,
                        "all": sorted(needs),
                        "approved": status.get("approved"),
                        "thread_url": status.get("thread_url"),
                        "ticket_latest": status.get("ticket_latest"),
                    },
                )
            if status.get("approved") and "APPROVED_MOVED_TO_GAMES" in needs:
                append_jsonl(
                    events_path,
                    {
                        "ts": utc_now(),
                        "type": "approved",
                        "thread_url": status.get("thread_url"),
                        "title": status.get("thread_title"),
                    },
                )
        prev_needs = needs

        # Human-readable one-liner to stdout for tmux logs
        if status.get("ok"):
            print(
                f"[{status['ts']}] approved={status.get('approved')} "
                f"req={status.get('still_req')} games_btn={status.get('games_post_button')} "
                f"needs={sorted(needs)}",
                flush=True,
            )
        else:
            print(f"[{status['ts']}] ERROR {status.get('error')}", flush=True)

        if args.once:
            return 0 if status.get("ok") else 1
        time.sleep(max(60, args.interval_sec))


if __name__ == "__main__":
    raise SystemExit(main())
