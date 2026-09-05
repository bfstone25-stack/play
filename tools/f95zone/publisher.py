#!/usr/bin/env python3
"""F95zone XenForo session publisher (cookie + _xfToken form posts).

The public REST API at /api/ requires an admin-issued XF-Api-Key. Normal
members cannot create one. This tool automates the member UI instead.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urljoin, urlparse

import requests

try:
    import yaml  # type: ignore
except ImportError:  # pragma: no cover - optional until PyYAML installed
    yaml = None


DEFAULT_BASE = "https://f95zone.to"
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 "
    "Flat404F95Publisher/1.0"
)


class PublisherError(RuntimeError):
    pass


@dataclass
class SessionInfo:
    logged_in: bool
    username: str | None
    user_id: str | None
    csrf: str | None
    template: str | None


def load_cookies(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "cookies" in data:
        cookies = data["cookies"]
        if cookies and "length" in cookies[0] and "value" not in cookies[0]:
            raise PublisherError(
                f"{path} looks like a names-only export. Re-run export without --names-only."
            )
        return cookies
    if isinstance(data, list):
        return data
    raise PublisherError(f"Unrecognized cookie file shape: {path}")


def cookie_file_from_env() -> Path:
    raw = os.environ.get("F95ZONE_COOKIES_FILE", "").strip()
    if not raw:
        raise PublisherError(
            "Set F95ZONE_COOKIES_FILE to a JSON cookie export "
            "(see tools/f95zone/README.md)."
        )
    path = Path(raw).expanduser()
    if not path.is_file():
        raise PublisherError(f"Cookie file not found: {path}")
    return path


def build_session(cookies: list[dict[str, Any]], base_url: str) -> requests.Session:
    s = requests.Session()
    s.headers.update(
        {
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        }
    )
    host = urlparse(base_url).hostname or "f95zone.to"
    for c in cookies:
        name = c.get("name")
        value = c.get("value")
        if not name or value is None:
            continue
        domain = c.get("domain") or host
        path = c.get("path") or "/"
        s.cookies.set(name, value, domain=domain.lstrip("."), path=path)
    return s


def extract_csrf(html: str) -> str | None:
    m = re.search(r'data-csrf="([^"]+)"', html)
    if m:
        return m.group(1)
    m = re.search(r'name="_xfToken"\s+value="([^"]+)"', html)
    if m:
        return m.group(1)
    return None


def extract_session_info(html: str) -> SessionInfo:
    csrf = extract_csrf(html)
    logged = bool(re.search(r'data-logged-in="true"', html, re.I))
    template_m = re.search(r'data-template="([^"]+)"', html)
    # Common patterns on XF member pages
    user_id = None
    username = None
    m = re.search(r'data-user-id="(\d+)"', html)
    if m:
        user_id = m.group(1)
    m = re.search(
        r'class="[^"]*p-navgroup-link--user[^"]*"[^>]*>\s*<span[^>]*class="p-navgroup-linkText"[^>]*>([^<]+)</span>',
        html,
    )
    if m:
        username = m.group(1).strip()
    if not username:
        m = re.search(r'class="p-navgroup-linkText">([^<]+)</span>', html)
        if m and m.group(1).strip().lower() not in {"profile", "inbox", "alerts", "what's new"}:
            username = m.group(1).strip()
    if not username:
        m = re.search(r'/members/([^/]+)\.(\d+)/', html)
        if m:
            user_id = user_id or m.group(2)
            username = m.group(1)
    if not username:
        m = re.search(r'"username"\s*:\s*"([^"]+)"', html)
        if m:
            username = m.group(1)
    return SessionInfo(
        logged_in=logged,
        username=username,
        user_id=user_id,
        csrf=csrf,
        template=template_m.group(1) if template_m else None,
    )


def get_html(session: requests.Session, url: str) -> tuple[requests.Response, str]:
    r = session.get(url, timeout=60)
    text = r.text
    if "Just a moment" in text or "cf-browser-verification" in text:
        raise PublisherError(
            "Cloudflare challenge page returned. Re-export cookies from a "
            "browser that already passed CF (include cf_clearance)."
        )
    return r, text


def read_text_arg(value: str | None, file_path: str | None) -> str:
    if bool(value) == bool(file_path):
        raise PublisherError("Provide exactly one of --message/--title or --*-file")
    if file_path:
        return Path(file_path).read_text(encoding="utf-8").strip() + "\n"
    return (value or "").strip() + "\n"


class F95Publisher:
    def __init__(self, base_url: str, session: requests.Session):
        self.base_url = base_url.rstrip("/")
        self.session = session

    def url(self, path: str) -> str:
        return urljoin(self.base_url + "/", path.lstrip("/"))

    def whoami(self) -> SessionInfo:
        r, html = get_html(self.session, self.url("/"))
        if r.status_code >= 400:
            raise PublisherError(f"GET / failed: HTTP {r.status_code}")
        info = extract_session_info(html)
        if not info.logged_in:
            # Account page sometimes clearer
            r2, html2 = get_html(self.session, self.url("/account/"))
            info = extract_session_info(html2)
        return info

    def probe_api(self) -> dict[str, Any]:
        r = self.session.get(self.url("/api/"), timeout=30)
        try:
            body = r.json()
        except Exception:
            body = {"raw": r.text[:500]}
        return {"http_status": r.status_code, "body": body}

    def _csrf_from(self, path: str) -> tuple[str, str]:
        r, html = get_html(self.session, self.url(path))
        if r.status_code >= 400:
            raise PublisherError(f"GET {path} failed: HTTP {r.status_code}")
        info = extract_session_info(html)
        if not info.logged_in:
            raise PublisherError(
                "Session cookies are not authenticated (data-logged-in=false). "
                "Re-export from the logged-in Firefox profile."
            )
        if not info.csrf:
            raise PublisherError(f"No CSRF token found on {path}")
        return info.csrf, path

    def reply(
        self,
        thread_id: int,
        message: str,
        *,
        dry_run: bool = False,
        thread_url: str | None = None,
    ) -> dict[str, Any]:
        path = thread_url or f"/threads/{thread_id}/"
        csrf, request_uri = self._csrf_from(path)
        endpoint = self.url(f"/threads/{thread_id}/add-reply")
        payload = {
            "message": message.rstrip() + "\n",
            "attachment_hash": "",
            "last_date": "",
            "last_known_date": "",
            "_xfToken": csrf,
            "_xfRequestUri": request_uri if request_uri.startswith("/") else f"/threads/{thread_id}/",
            "_xfWithData": "1",
            "_xfResponseType": "json",
        }
        if dry_run:
            return {
                "dry_run": True,
                "endpoint": endpoint,
                "thread_id": thread_id,
                "message_chars": len(message),
                "csrf_present": True,
            }
        r = self.session.post(
            endpoint,
            data=payload,
            headers={
                "X-Requested-With": "XMLHttpRequest",
                "Referer": self.url(path),
            },
            timeout=60,
        )
        return self._parse_xf_response(r, action="reply")

    def create_thread(
        self,
        forum_id: int,
        title: str,
        message: str,
        *,
        dry_run: bool = False,
        tags: str | None = None,
        prefix_id: int | None = None,
    ) -> dict[str, Any]:
        path = f"/forums/{forum_id}/"
        csrf, request_uri = self._csrf_from(path)
        # XF accepts both numeric and slug.numeric; numeric works for POST.
        endpoint = self.url(f"/forums/{forum_id}/post-thread")
        payload = {
            "title": title.strip(),
            "message": message.rstrip() + "\n",
            "attachment_hash": "",
            "discussion_open": "1",
            "_xfSet[discussion_open]": "1",
            "_xfToken": csrf,
            "_xfRequestUri": request_uri if request_uri.startswith("/") else path,
            "_xfWithData": "1",
            "_xfResponseType": "json",
        }
        if tags:
            payload["tags"] = tags
        # XenForo + SV multi-prefix expects repeated prefix_id[] fields.
        # requests encodes dict values fine for scalars, but for list fields we
        # must pass a sequence of tuples or the [] name is dropped/ignored.
        data_items: list[tuple[str, str]] = [(k, str(v)) for k, v in payload.items()]
        if prefix_id is not None:
            data_items.append(("prefix_id[]", str(prefix_id)))
        if dry_run:
            return {
                "dry_run": True,
                "endpoint": endpoint,
                "forum_id": forum_id,
                "title": title.strip(),
                "message_chars": len(message),
                "prefix_id": prefix_id,
                "csrf_present": True,
            }
        r = self.session.post(
            endpoint,
            data=data_items,
            headers={
                "X-Requested-With": "XMLHttpRequest",
                "Referer": self.url(path),
            },
            timeout=60,
        )
        return self._parse_xf_response(r, action="create-thread")

    @staticmethod
    def _parse_xf_response(r: requests.Response, action: str) -> dict[str, Any]:
        out: dict[str, Any] = {"action": action, "http_status": r.status_code}
        ctype = r.headers.get("content-type", "")
        if "json" in ctype:
            try:
                out["json"] = r.json()
            except Exception:
                out["text"] = r.text[:1000]
        else:
            out["text"] = r.text[:1000]
            if "Just a moment" in r.text:
                raise PublisherError("Cloudflare blocked the POST. Refresh browser cookies.")
        # XF often returns 200 with errors in JSON html/message
        data = out.get("json") or {}
        if isinstance(data, dict):
            errors = data.get("errors")
            if errors:
                out["ok"] = False
                out["errors"] = errors
                return out
            # success shapes vary: redirect, html, messageHtml
            if r.status_code < 400:
                out["ok"] = True
                if "redirect" in data:
                    out["redirect"] = data["redirect"]
                return out
        out["ok"] = 200 <= r.status_code < 300
        return out


def load_job(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() in {".yaml", ".yml"}:
        if yaml is None:
            raise PublisherError("PyYAML required for YAML jobs: pip install pyyaml")
        return yaml.safe_load(text)
    return json.loads(text)


def resolve_job_text(job_dir: Path, item: dict[str, Any], key: str) -> str | None:
    if key in item and item[key] is not None:
        return str(item[key])
    file_key = f"{key}_file"
    if file_key in item and item[file_key]:
        p = Path(item[file_key])
        if not p.is_absolute():
            p = (job_dir / p).resolve()
        return p.read_text(encoding="utf-8")
    return None


def cmd_whoami(pub: F95Publisher) -> int:
    info = pub.whoami()
    print(
        json.dumps(
            {
                "logged_in": info.logged_in,
                "username": info.username,
                "user_id": info.user_id,
                "csrf_present": bool(info.csrf),
                "template": info.template,
            },
            indent=2,
        )
    )
    return 0 if info.logged_in else 1


def cmd_probe_api(pub: F95Publisher) -> int:
    result = pub.probe_api()
    print(json.dumps(result, indent=2))
    print(
        textwrap.dedent(
            """
            Note: /api/ is enabled on F95zone but rejects requests without an
            admin-issued XF-Api-Key. Member automation must use cookie + _xfToken
            form posts (this tool), not the REST API.
            """
        ).strip()
    )
    return 0


def make_publisher(args: argparse.Namespace) -> F95Publisher:
    base = args.base_url or os.environ.get("F95ZONE_BASE_URL", DEFAULT_BASE)
    cookies_path = Path(args.cookies).expanduser() if args.cookies else cookie_file_from_env()
    cookies = load_cookies(cookies_path)
    session = build_session(cookies, base)
    return F95Publisher(base, session)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base-url", default=None)
    ap.add_argument("--cookies", default=None, help="JSON cookie file (else F95ZONE_COOKIES_FILE)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("whoami", help="Verify session; print username/id only")
    sub.add_parser("probe-api", help="Show why /api/ is unusable without admin key")

    p_reply = sub.add_parser("reply", help="Reply to a thread")
    p_reply.add_argument("--thread-id", type=int, required=True)
    p_reply.add_argument("--thread-url", default=None, help="Optional full path for CSRF GET")
    p_reply.add_argument("--message", default=None)
    p_reply.add_argument("--message-file", default=None)
    p_reply.add_argument("--dry-run", action="store_true")

    p_new = sub.add_parser("create-thread", help="Create a forum thread")
    p_new.add_argument("--forum-id", type=int, required=True)
    p_new.add_argument("--title", default=None)
    p_new.add_argument("--title-file", default=None)
    p_new.add_argument("--message", default=None)
    p_new.add_argument("--message-file", default=None)
    p_new.add_argument("--tags", default=None)
    p_new.add_argument("--prefix-id", type=int, default=None, help="Forum prefix id (e.g. 24=REQ)")
    p_new.add_argument("--dry-run", action="store_true")

    p_job = sub.add_parser("run-job", help="Run a YAML/JSON job of posts")
    p_job.add_argument("--job", required=True)
    p_job.add_argument("--dry-run", action="store_true")

    p_guest = sub.add_parser(
        "self-test-guest",
        help="No cookies: prove CSRF scrape + API key requirement against live F95",
    )

    args = ap.parse_args(argv)

    if args.cmd == "self-test-guest":
        return self_test_guest(args.base_url or DEFAULT_BASE)

    try:
        pub = make_publisher(args)
        if args.cmd == "whoami":
            return cmd_whoami(pub)
        if args.cmd == "probe-api":
            return cmd_probe_api(pub)
        if args.cmd == "reply":
            message = read_text_arg(args.message, args.message_file)
            result = pub.reply(
                args.thread_id,
                message,
                dry_run=args.dry_run,
                thread_url=args.thread_url,
            )
            print(json.dumps(result, indent=2))
            return 0 if result.get("ok", args.dry_run) else 1
        if args.cmd == "create-thread":
            title = read_text_arg(args.title, args.title_file).strip()
            message = read_text_arg(args.message, args.message_file)
            result = pub.create_thread(
                args.forum_id,
                title,
                message,
                dry_run=args.dry_run,
                tags=args.tags,
                prefix_id=args.prefix_id,
            )
            print(json.dumps(result, indent=2))
            return 0 if result.get("ok", args.dry_run) else 1
        if args.cmd == "run-job":
            return run_job(pub, Path(args.job), dry_run=args.dry_run)
    except PublisherError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    except requests.RequestException as e:
        print(f"error: network: {e}", file=sys.stderr)
        return 2
    return 2


def run_job(pub: F95Publisher, job_path: Path, *, dry_run: bool) -> int:
    job = load_job(job_path)
    job_dir = job_path.parent
    steps = job.get("steps") or job.get("posts") or []
    if not steps:
        raise PublisherError(f"No steps in job: {job_path}")
    results = []
    ok_all = True
    for i, step in enumerate(steps, 1):
        if step.get("enabled") is False:
            results.append({"step": i, "skipped": True, "reason": "enabled=false"})
            continue
        kind = step.get("type") or step.get("action")
        if kind == "reply":
            if int(step.get("thread_id") or 0) <= 0:
                raise PublisherError(
                    f"step {i}: set a real thread_id (placeholder 0 is not allowed)"
                )
            message = resolve_job_text(job_dir, step, "message")
            if not message:
                raise PublisherError(f"step {i}: reply needs message or message_file")
            result = pub.reply(
                int(step["thread_id"]),
                message,
                dry_run=dry_run,
                thread_url=step.get("thread_url"),
            )
        elif kind in {"create-thread", "thread"}:
            title = resolve_job_text(job_dir, step, "title")
            message = resolve_job_text(job_dir, step, "message")
            if not title or not message:
                raise PublisherError(f"step {i}: create-thread needs title(+file) and message(+file)")
            result = pub.create_thread(
                int(step["forum_id"]),
                title.strip(),
                message,
                dry_run=dry_run,
                tags=step.get("tags"),
                prefix_id=(int(step["prefix_id"]) if step.get("prefix_id") is not None else None),
            )
        else:
            raise PublisherError(f"step {i}: unknown type {kind!r}")
        results.append({"step": i, "type": kind, "result": result})
        if not (result.get("ok") or result.get("dry_run")):
            ok_all = False
            break
    print(json.dumps({"job": str(job_path), "dry_run": dry_run, "results": results}, indent=2))
    return 0 if ok_all else 1


def self_test_guest(base_url: str) -> int:
    """Live checks that do not require member cookies."""
    s = requests.Session()
    s.headers["User-Agent"] = USER_AGENT
    api = s.get(urljoin(base_url + "/", "api/"), timeout=30)
    api_json = api.json()
    codes = [e.get("code") for e in api_json.get("errors", [])]
    thread = s.get(
        urljoin(base_url + "/", "threads/underrated-genres-in-h-games.313472/"),
        timeout=60,
    )
    csrf = extract_csrf(thread.text)
    info = extract_session_info(thread.text)
    report = {
        "api_http_status": api.status_code,
        "api_error_codes": codes,
        "thread_http_status": thread.status_code,
        "csrf_scraped": bool(csrf),
        "guest_logged_in": info.logged_in,
        "conclusion": (
            "REST /api/ requires admin XF-Api-Key; member posts must use "
            "cookie session + data-csrf/_xfToken form POST."
        ),
    }
    print(json.dumps(report, indent=2))
    ok = (
        api.status_code == 400
        and "no_api_key_in_request" in codes
        and thread.status_code == 200
        and bool(csrf)
        and info.logged_in is False
    )
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
