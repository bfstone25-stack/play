#!/usr/bin/env python3
"""Publish and polish itch game pages using the pop-os Firefox session.

The itch edit endpoint validates the whole game on every POST, so all
mutations go through `push` with a complete profile JSON:

  {
    "title": "...", "slug": "...", "short_text": "... (<=120)",
    "type": "html", "release_status": "released",
    "payment_mode": "paid", "min_price": "2.00", "suggested_price": "3.00",
    "tags": "a,b,c", "genre": "visual-novel",
    "description_file": "copy/x-desc.html", "instructions_file": "copy/x.txt",
    "published": "draft" | "published"
  }

Subcommands:
  create --title T --slug S --short TEXT [--payment-mode paid --min-price 2.00]
  push ID --profile FILE.json [--embed-channel NAME] [--publish]
  upload-cover ID FILE
  upload-screenshot ID FILE [FILE...]
  set-theme ID --slug S --bg C --bg2 C --text C --link C [--font F] [--size S]
  state ID
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jam_submit import csrf_from, fetch, firefox_itch_cookies, opener_for

ROOT = Path(__file__).resolve().parent


def get_opener():
    cookies = firefox_itch_cookies()
    if "itchio" not in cookies:
        print("NOT LOGGED IN")
        raise SystemExit(2)
    return opener_for(cookies), cookies


def post_form(opener, url, fields: dict) -> tuple[int, str, str]:
    data = urllib.parse.urlencode(fields).encode()
    return fetch(opener, url, data=data, method="POST")


def edit_page(opener, game_id: int) -> tuple[str, str]:
    code, _, html = fetch(opener, f"https://itch.io/game/edit/{game_id}")
    if code != 200:
        raise SystemExit(f"GET edit {game_id} -> {code}")
    return html, csrf_from(html, {})


def embedded_state(html: str) -> dict:
    m = re.search(r"init_EditGame\([^,]+, (\{.*?\})\);init_", html, re.S)
    if not m:
        m = re.search(r"init_EditGame\([^,]+, (\{.*\})\);\s*</script>", html, re.S)
    if not m:
        return {}
    try:
        return json.loads(m.group(1))
    except Exception:
        return {}


def errors_of(body: str) -> list:
    m = re.search(r'"errors":\s*(\[[^\]]*\])', body)
    if m:
        try:
            return json.loads(m.group(1))
        except Exception:
            return [m.group(1)]
    return []


def full_fields(profile: dict, token: str) -> dict:
    desc = ""
    if profile.get("description_file"):
        desc = (ROOT / profile["description_file"]).read_text()
    instr = ""
    if profile.get("instructions_file"):
        instr = (ROOT / profile["instructions_file"]).read_text()
    fields = {
        "csrf_token": token,
        "game[title]": profile["title"],
        "game[slug]": profile["slug"],
        "game[short_text]": profile.get("short_text", ""),
        "game[user_classification]": "game",
        "game[type]": profile.get("type", "html"),
        "game[release_status]": profile.get("release_status", "released"),
        "game[classname]": "",
        "game[description]": desc,
        "game[noun]": "",
        "game[instructions]": instr,
        "game[community_type]": profile.get("community_type", "topic"),
        "game[video_url]": "",
        "game[published]": profile.get("published", "draft"),
        "game[payment_mode]": profile.get("payment_mode", "free"),
        "game[min_price]": profile.get("min_price", "0.00"),
        "game[tags]": profile.get("tags", ""),
    }
    if profile.get("suggested_price"):
        fields["game[suggested_price]"] = profile["suggested_price"]
    if profile.get("genre"):
        fields["game[genre]"] = profile["genre"]
    if profile.get("cover_image_id"):
        fields["game[cover_image_id]"] = str(profile["cover_image_id"])
    return fields


def cmd_create(args) -> None:
    opener, cookies = get_opener()
    code, _, html = fetch(opener, "https://itch.io/game/new")
    token = csrf_from(html, cookies)
    fields = {
        "csrf_token": token,
        "game[title]": args.title,
        "game[slug]": args.slug,
        "game[short_text]": args.short,
        "game[user_classification]": "game",
        "game[type]": args.type,
        "game[release_status]": "released",
        "game[classname]": "",
        "game[description]": "",
        "game[noun]": "",
        "game[instructions]": "",
        "game[community_type]": "topic",
        "game[video_url]": "",
        "game[published]": "draft",
        "game[payment_mode]": args.payment_mode,
        "game[min_price]": args.min_price,
    }
    if args.payment_mode == "paid":
        fields["game[suggested_price]"] = args.suggested
    code, url, body = post_form(opener, "https://itch.io/game/new", fields)
    m = re.search(r'"id":(\d+)', body) or re.search(r"/game/edit/(\d+)", url)
    errs = errors_of(body)
    print(f"create -> {code}", "GAME_ID", m.group(1) if m else "?", ("ERRORS " + json.dumps(errs)) if errs else "")


def cmd_push(args) -> None:
    opener, _ = get_opener()
    profile = json.loads((ROOT / args.profile).read_text())
    if args.publish:
        profile["published"] = "published"
    html, token = edit_page(opener, args.id)
    state = embedded_state(html)
    fields = full_fields(profile, token)
    if args.embed_channel:
        for up in state.get("uploads", []):
            if up.get("channel_name") == args.embed_channel or args.embed_channel in (up.get("filename") or ""):
                fields[f"upload[{up['id']}][embed]"] = "on"
                print(f"embed flag on upload {up['id']} ({up.get('filename')})")
    code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
    errs = errors_of(body)
    print(f"push -> {code}", ("ERRORS " + json.dumps(errs, ensure_ascii=False)) if errs else "OK")


def _image_size(path, fallback):
    try:
        from PIL import Image  # type: ignore
        with Image.open(path) as im:
            return im.size
    except Exception:
        return fallback


def _s3_upload(opener, prepare_url: str, params: dict, file_path: Path, token: str) -> dict:
    params = dict(params)
    params["csrf_token"] = token
    code, _, body = post_form(opener, prepare_url, params)
    if code != 200:
        raise SystemExit(f"prepare -> {code}: {body[:200]}")
    data = json.loads(body)
    boundary = "----itchupload" + str(abs(hash(file_path.name)))
    payload = b""
    for k, v in data.get("post_params", {}).items():
        payload += f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode()
    blob = file_path.read_bytes()
    payload += f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{file_path.name}"\r\nContent-Type: application/octet-stream\r\n\r\n'.encode()
    payload += blob + f"\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(
        data["action"], data=payload, method="POST",
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}", "User-Agent": "Mozilla/5.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            s3code = resp.status
    except Exception as exc:
        raise SystemExit(f"S3 upload failed: {exc}")
    if s3code >= 300:
        raise SystemExit(f"S3 upload -> {s3code}")
    code, _, body = post_form(opener, data["success_url"], {"csrf_token": token})
    if code != 200:
        raise SystemExit(f"success_url -> {code}: {body[:200]}")
    try:
        return json.loads(body)
    except Exception:
        return {"raw": body[:300]}


def cmd_upload_cover(args) -> None:
    opener, _ = get_opener()
    w, h = _image_size(args.file, (630, 500))
    p = Path(args.file)
    _, token = edit_page(opener, args.id)
    res = _s3_upload(
        opener,
        f"https://itch.io/dashboard/upload-image?type=cover&game_id={args.id}",
        {"filename": p.name, "thumb_size": "original", "action": "prepare", "width": w, "height": h},
        p, token,
    )
    print("cover upload ->", json.dumps(res)[:300])
    img_id = res.get("id") or (res.get("image") or {}).get("id")
    if img_id:
        _, token = edit_page(opener, args.id)
        html, token = edit_page(opener, args.id)
        state = embedded_state(html)
        fields = {"csrf_token": token, "game[cover_image_id]": str(img_id)}
        code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
        errs = errors_of(body)
        print(f"cover assign -> {code}", ("ERRORS " + json.dumps(errs)) if errs else "OK")
    else:
        print("NO IMAGE ID IN RESPONSE")


def cmd_upload_screenshot(args) -> None:
    opener, _ = get_opener()
    _, token = edit_page(opener, args.id)
    for f in args.files:
        p = Path(f)
        w, h = _image_size(p, (1280, 720))
        res = _s3_upload(
            opener,
            f"https://itch.io/game/edit/{args.id}/upload/prepare",
            {"kind": "image", "filename": p.name, "width": w, "height": h,
             "type": "screenshot", "thumb_size": "editor_preview"},
            p, token,
        )
        print(f"screenshot {p.name} ->", json.dumps(res)[:200])


def cmd_set_theme(args) -> None:
    opener, cookies = get_opener()
    html, _ = edit_page(opener, args.id)
    state = embedded_state(html)
    slug = state.get("game", {}).get("slug") or args.slug
    user = state.get("user_slug", "bfstone25-stack")
    pub_url = f"https://{user}.itch.io/{slug}"
    code, _, pub_html = fetch(opener, pub_url)
    token = csrf_from(pub_html, cookies)
    theme = {
        "bg_color": args.bg,
        "bg2_color": args.bg2,
        "text_color": args.text,
        "link_color": args.link,
        "font_family": args.font,
        "font_size": args.size,
        "screenshots_loc": "sidebar",
        "default_screenshots_loc": "hidden",
        "embed_background_alpha": 0,
    }
    code, _, body = post_form(opener, pub_url + "/edit", {"csrf_token": token, "theme": json.dumps(theme)})
    print(f"set-theme -> {code} {body[:200]}")


def cmd_state(args) -> None:
    opener, _ = get_opener()
    html, _ = edit_page(opener, args.id)
    state = embedded_state(html)
    out = {
        "title": state.get("game", {}).get("title"),
        "slug": state.get("game", {}).get("slug"),
        "published": state.get("published"),
        "type": state.get("type"),
        "min_price": state.get("min_price"),
        "suggested_price": state.get("suggested_price"),
        "disable_payments": state.get("disable_payments"),
        "tags": (state.get("game_tags") or {}).get("tags"),
        "cover_image": bool(state.get("cover_image")),
        "screenshots": [s.get("id") for s in (state.get("game", {}).get("screenshots") or [])],
        "uploads": [
            {"id": u.get("id"), "filename": u.get("filename"), "channel": u.get("channel_name"),
             "type": u.get("type"), "embed": u.get("embed"), "size": u.get("size"),
             "p_windows": u.get("p_windows"), "p_linux": u.get("p_linux"), "p_osx": u.get("p_osx")}
            for u in state.get("uploads", [])
        ],
    }
    print(json.dumps(out, indent=1, ensure_ascii=False))


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("create")
    p.add_argument("--title", required=True)
    p.add_argument("--slug", required=True)
    p.add_argument("--short", required=True)
    p.add_argument("--type", default="html")
    p.add_argument("--payment-mode", default="free")
    p.add_argument("--min-price", default="0.00")
    p.add_argument("--suggested", default="3.00")
    p.set_defaults(f=cmd_create)

    p = sub.add_parser("push")
    p.add_argument("id", type=int)
    p.add_argument("--profile", required=True)
    p.add_argument("--embed-channel")
    p.add_argument("--publish", action="store_true")
    p.set_defaults(f=cmd_push)

    p = sub.add_parser("upload-cover")
    p.add_argument("id", type=int)
    p.add_argument("file")
    p.set_defaults(f=cmd_upload_cover)

    p = sub.add_parser("upload-screenshot")
    p.add_argument("id", type=int)
    p.add_argument("files", nargs="+")
    p.set_defaults(f=cmd_upload_screenshot)

    p = sub.add_parser("set-theme")
    p.add_argument("id", type=int)
    p.add_argument("--slug", required=True)
    p.add_argument("--bg", required=True)
    p.add_argument("--bg2", required=True)
    p.add_argument("--text", required=True)
    p.add_argument("--link", required=True)
    p.add_argument("--font", default="lato")
    p.add_argument("--size", default="large")
    p.set_defaults(f=cmd_set_theme)

    p = sub.add_parser("state")
    p.add_argument("id", type=int)
    p.set_defaults(f=cmd_state)

    args = ap.parse_args()
    args.f(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
