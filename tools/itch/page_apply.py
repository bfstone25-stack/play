#!/usr/bin/env python3
"""Complete itch page applicator — superset field set, idempotent.

Runs on pop-os (Firefox itch session). Every edit POST carries the full
metadata field set because itch validates the whole game on save.

Subcommands:
  apply ID --profile P.json          full metadata/pricing/tags/AI/embed push
  cover ID FILE                      upload + assign cover image
  screenshots ID FILE [FILE...]      upload + order screenshots
  embedbg ID FILE                    upload embed background image
  theme ID --slug S --colors C.json  save full theme JSON (colors/fonts/embedbg)
  state ID                           dump current state JSON
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.parse
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
    m = re.search(r'"errors":\s*(\[[^\]]*\])', body, re.S)
    if m:
        try:
            return json.loads(m.group(1))
        except Exception:
            return [m.group(1)[:400]]
    return []


def theme_state(opener, cookies, pub_url: str) -> tuple[dict, str, str]:
    """Return (theme dict, submit_url, csrf) from the public page."""
    code, _, html = fetch(opener, pub_url)
    if code != 200:
        raise SystemExit(f"GET {pub_url} -> {code}")
    token = csrf_from(html, cookies)
    m = re.search(r"init_GameThemeEditor\('#[^']+', (\{.*)", html, re.S)
    if not m:
        raise SystemExit("no theme editor state on page")
    body = m.group(1)
    depth = 0
    end = 0
    for i, ch in enumerate(body):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    data = json.loads(body[:end])
    return data.get("theme") or {}, data["submit_url"], token


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
        "game[user_classification]": profile.get("classification", "game"),
        "game[type]": profile.get("type", "html"),
        "game[release_status]": profile.get("release_status", "released"),
        "game[classname]": "",
        "game[description]": desc,
        "game[noun]": "",
        "game[instructions]": instr,
        "game[community_type]": profile.get("community_type", "topic"),
        "game[video_url]": "",
        "game[published]": profile.get("published", "published"),
        "game[payment_mode]": profile.get("payment_mode", "free"),
        "game[min_price]": profile.get("min_price", "0.00"),
        "game[tags]": profile.get("tags", ""),
        # AI disclosure: LLM-assisted text/code, AI listing graphics.
        "ai_disclosure[ai_generated]": "yes",
        "ai_disclosure[ai_graphics]": "on",
        "ai_disclosure[ai_text]": "on",
        "ai_disclosure[ai_code]": "on",
        # Embed: 1280x720 frame with fullscreen, same bar as Across the Hall.
        "embed[embed_type]": "frame",
        "embed[size_type]": "manual",
        "embed[width]": "1280",
        "embed[height]": "720",
        "embed[fullscreen]": "on",
    }
    if profile.get("suggested_price"):
        fields["game[suggested_price]"] = profile["suggested_price"]
    if profile.get("genre"):
        fields["game[genre]"] = profile["genre"]
    if profile.get("mobile_friendly"):
        fields["embed[mobile_friendly]"] = "on"
    if profile.get("cover_image_id"):
        fields["game[cover_image_id]"] = str(profile["cover_image_id"])
    return fields


def cmd_apply(args) -> None:
    opener, _ = get_opener()
    profile = json.loads((ROOT / args.profile).read_text())
    html, token = edit_page(opener, args.id)
    before = embedded_state(html)
    fields = full_fields(profile, token)
    code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
    errs = errors_of(body)
    print(f"apply -> {code}", ("ERRORS " + json.dumps(errs, ensure_ascii=False)) if errs else "OK")
    html2, _ = edit_page(opener, args.id)
    after = embedded_state(html2)
    g = after.get("game") or {}
    print(json.dumps({
        "slug_before": (before.get("game") or {}).get("slug"),
        "slug_after": g.get("slug"),
        "title": g.get("title"),
        "min_price": after.get("min_price"),
        "suggested_price": after.get("suggested_price"),
        "published": after.get("published"),
        "genre": (after.get("game_tags") or {}).get("genre"),
        "tags": (after.get("game_tags") or {}).get("tags"),
        "ai": after.get("ai_disclosure"),
        "embed": after.get("embed_options"),
    }, ensure_ascii=False))


def _image_size(path, fallback):
    try:
        from PIL import Image  # type: ignore
        with Image.open(path) as im:
            return im.size
    except Exception:
        return fallback


def _s3_upload(opener, prepare_url: str, params: dict, file_path: Path, token: str,
               save_params: dict | None = None) -> dict:
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
    import urllib.request as ureq
    try:
        with ureq.urlopen(req, timeout=180) as resp:
            s3code = resp.status
    except Exception as exc:
        raise SystemExit(f"S3 upload failed: {exc}")
    if s3code >= 300:
        raise SystemExit(f"S3 upload -> {s3code}")
    success_url = data["success_url"]
    if success_url.startswith("/"):
        success_url = "https://itch.io" + success_url
    save = dict(save_params or {})
    save["csrf_token"] = token
    code, _, body = post_form(opener, success_url, save)
    if code != 200:
        raise SystemExit(f"success_url -> {code}: {body[:200]}")
    try:
        return json.loads(body)
    except Exception:
        return {"raw": body[:300]}


def cmd_cover(args) -> None:
    opener, _ = get_opener()
    p = Path(args.file)
    w, h = _image_size(p, (630, 500))
    _, token = edit_page(opener, args.id)
    res = _s3_upload(
        opener,
        f"https://itch.io/dashboard/upload-image?type=cover&game_id={args.id}",
        {"filename": p.name, "thumb_size": "original", "action": "prepare", "width": w, "height": h},
        p, token,
    )
    print("cover upload ->", json.dumps(res)[:240])
    img_id = res.get("id") or (res.get("image") or {}).get("id") or (res.get("upload") or {}).get("id")
    if not img_id:
        print("NO IMAGE ID")
        return
    html, token = edit_page(opener, args.id)
    state = embedded_state(html)
    fields = full_fields_current(html, token)
    fields["game[cover_image_id]"] = str(img_id)
    code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
    errs = errors_of(body)
    print(f"cover assign -> {code}", ("ERRORS " + json.dumps(errs)) if errs else "OK", "image_id", img_id)


def full_fields_current(html: str, token: str) -> dict:
    """Rebuild the current field set from the edit page so validation passes."""
    from html.parser import HTMLParser
    import html as htmlmod

    class F(HTMLParser):
        def __init__(self):
            super().__init__()
            self.fields = {}
            self._ta = None
            self._buf = []
            self._sel = None
            self._opt_val = None
            self._opt_sel = False

        def handle_starttag(self, tag, attrs):
            a = dict(attrs)
            name = a.get("name")
            if tag == "input" and name:
                typ = (a.get("type") or "text").lower()
                if typ in {"button", "submit", "file"}:
                    return
                if typ in {"radio", "checkbox"}:
                    if "checked" in a:
                        self.fields[name] = a.get("value") or "on"
                    return
                self.fields[name] = a.get("value") or ""
            elif tag == "textarea" and name:
                self._ta = name
                self._buf = []
            elif tag == "select" and name:
                self._sel = name
            elif tag == "option" and self._sel:
                self._opt_val = a.get("value") or ""
                self._opt_sel = "selected" in a

        def handle_data(self, data):
            if self._ta:
                self._buf.append(data)

        def handle_endtag(self, tag):
            if tag == "textarea" and self._ta:
                self.fields[self._ta] = htmlmod.unescape("".join(self._buf))
                self._ta = None
            elif tag == "option" and self._sel:
                if self._opt_sel or self._sel not in self.fields:
                    self.fields[self._sel] = self._opt_val or ""
                self._opt_val = None
            elif tag == "select":
                self._sel = None

    p = F()
    p.feed(html)
    fields = {k: v for k, v in p.fields.items() if k != "q"}
    fields["csrf_token"] = token
    # the JS-rendered fields must be re-supplied from the embedded state
    state = embedded_state(html)
    gt = state.get("game_tags") or {}
    if gt.get("tags"):
        fields["game[tags]"] = ",".join(gt["tags"])
    if gt.get("genre"):
        fields["game[genre]"] = gt["genre"]
    ai = state.get("ai_disclosure") or {}
    if ai.get("ai_generated"):
        fields["ai_disclosure[ai_generated]"] = "yes"
        for k in ("ai_graphics", "ai_text", "ai_code", "ai_audio"):
            if ai.get(k):
                fields[f"ai_disclosure[{k}]"] = "on"
    eo = state.get("embed_options") or {}
    if eo:
        fields["embed[embed_type]"] = str(eo.get("embed_type") or "frame")
        fields["embed[size_type]"] = str(eo.get("size_type") or "manual")
        fields["embed[width]"] = str(eo.get("width") or 1280)
        fields["embed[height]"] = str(eo.get("height") or 720)
        if eo.get("fullscreen"):
            fields["embed[fullscreen]"] = "on"
        if eo.get("mobile_friendly"):
            fields["embed[mobile_friendly]"] = "on"
    min_price = int(state.get("min_price") or 0)
    fields["game[payment_mode]"] = "paid" if min_price > 0 else "free"
    fields["game[min_price]"] = "%.2f" % (min_price / 100.0)
    if state.get("suggested_price"):
        fields["game[suggested_price]"] = "%.2f" % (int(state["suggested_price"]) / 100.0)
    if state.get("published"):
        fields["game[published]"] = "published"
    return fields


def cmd_screenshots(args) -> None:
    opener, _ = get_opener()
    ids = []
    for f in args.files:
        p = Path(f)
        w, h = _image_size(p, (1280, 720))
        _, token = edit_page(opener, args.id)
        res = _s3_upload(
            opener,
            f"https://itch.io/game/edit/{args.id}/upload/prepare",
            {"kind": "image", "filename": p.name, "width": w, "height": h,
             "type": "screenshot", "thumb_size": "editor_preview"},
            p, token,
            save_params={"type": "screenshot", "thumb_size": "editor_preview"},
        )
        sid = res.get("id") or (res.get("screenshot") or {}).get("id") or res.get("image_id")
        print(f"screenshot {p.name} -> id={sid} :: {json.dumps(res)[:160]}")
        if sid:
            ids.append(sid)
    if not ids:
        print("NO SCREENSHOT IDS")
        return
    html, token = edit_page(opener, args.id)
    fields = full_fields_current(html, token)
    for i, sid in enumerate(ids):
        fields[f"screenshot[{sid}][position]"] = str(i)
    code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
    errs = errors_of(body)
    print(f"screenshot assign -> {code}", ("ERRORS " + json.dumps(errs)) if errs else "OK", "ids", ids)


def cmd_embedbg(args) -> None:
    opener, _ = get_opener()
    p = Path(args.file)
    w, h = _image_size(p, (1280, 720))
    _, token = edit_page(opener, args.id)
    res = _s3_upload(
        opener,
        f"https://itch.io/dashboard/upload-image?game_id={args.id}",
        {"filename": p.name, "thumb_size": "original", "action": "prepare", "width": w, "height": h},
        p, token,
    )
    print("embedbg upload ->", json.dumps(res)[:240])
    out = {"id": res.get("id") or (res.get("image") or {}).get("id"), "raw": res}
    (ROOT / f"embedbg-{args.id}.json").write_text(json.dumps(res))
    print("embedbg image id:", out["id"])


def cmd_theme(args) -> None:
    """Full layout[...] form POST — the theme endpoint replaces unspecified
    fields with defaults, so always send the complete set."""
    opener, cookies = get_opener()
    pub_url = f"https://{args.user}.itch.io/{args.slug}"
    _, submit_url, token = theme_state(opener, cookies, pub_url)
    colors = json.loads((ROOT / args.colors).read_text())
    fields = {
        "csrf_token": token,
        "layout[bg_color]": colors["bg_color"],
        "layout[bg2_color]": colors["bg2_color"],
        "layout[text_color]": colors["text_color"],
        "layout[link_color]": colors["link_color"],
        "layout[font_family]": colors.get("font_family", "lato"),
        "layout[font_size]": colors.get("font_size", "large"),
        "layout[screenshots_loc]": colors.get("screenshots_loc", "sidebar"),
        "layout[default_screenshots_loc]": colors.get("default_screenshots_loc", "hidden"),
    }
    if colors.get("embed_color1"):
        fields["layout[embed_background_color1]"] = colors["embed_color1"]
    if colors.get("embed_color2"):
        fields["layout[embed_background_color2]"] = colors["embed_color2"]
    if colors.get("clear_embedbg"):
        fields["layout[embed_background_image][image_id]"] = ""
    if colors.get("button_color"):
        fields["layout[button_color]"] = colors["button_color"]
    if colors.get("header_font_family"):
        fields["layout[header_font_family]"] = colors["header_font_family"]
    if args.embedbg_id:
        saved = json.loads((ROOT / f"embedbg-{args.id}.json").read_text())
        img = saved.get("upload") or saved.get("image") or saved
        fields["layout[embed_background_image][image_id]"] = str(img.get("id"))
        fields["layout[embed_background_image][alpha]"] = "0"
    code, _, body = post_form(opener, submit_url, fields)
    print(f"theme -> {code} {body[:200]}")


def cmd_embedbg_apply(args) -> None:
    """ITCH.md-documented path: layout[embed_background_image][image_id] form field."""
    opener, cookies = get_opener()
    pub_url = f"https://{args.user}.itch.io/{args.slug}"
    _, submit_url, token = theme_state(opener, cookies, pub_url)
    saved = json.loads((ROOT / f"embedbg-{args.id}.json").read_text())
    img = saved.get("upload") or saved.get("image") or saved
    img_id = img.get("id")
    fields = {
        "csrf_token": token,
        "layout[embed_background_image][image_id]": str(img_id),
    }
    code, _, body = post_form(opener, submit_url, fields)
    print(f"embedbg-apply -> {code} {body[:200]} (image_id {img_id})")


def cmd_devlog(args) -> None:
    opener, _ = get_opener()
    url = f"https://itch.io/dashboard/game/{args.id}/new-devlog"
    code, _, html = fetch(opener, url)
    if code != 200:
        raise SystemExit(f"GET devlog form -> {code}")
    token = csrf_from(html, {})
    body_html = (ROOT / args.body).read_text()
    fields = {
        "csrf_token": token,
        "post[title]": args.title,
        "post[user_classification]": "major_update",
        "post[body]": body_html,
        "post[tags]": args.tags,
        "post[enable_comments]": "on",
    }
    if args.publish:
        fields["post[published]"] = "on"
    code, loc, body = post_form(opener, url, fields)
    errs = errors_of(body)
    print(f"devlog -> {code}", ("ERRORS " + json.dumps(errs)) if errs else "OK", loc[:120])


def cmd_retire(args) -> None:
    """Unlist an old page (restricted) without touching its content."""
    opener, _ = get_opener()
    html, token = edit_page(opener, args.id)
    fields = full_fields_current(html, token)
    fields["game[published]"] = "restricted"
    code, _, body = post_form(opener, f"https://itch.io/game/edit/{args.id}", fields)
    errs = errors_of(body)
    print(f"retire -> {code}", ("ERRORS " + json.dumps(errs)) if errs else "OK")
    html2, _ = edit_page(opener, args.id)
    state = embedded_state(html2)
    print(json.dumps({"slug": (state.get("game") or {}).get("slug"),
                      "published": state.get("published"),
                      "restricted": state.get("restricted")}))


def cmd_themestate(args) -> None:
    opener, cookies = get_opener()
    pub_url = f"https://{args.user}.itch.io/{args.slug}"
    theme, submit_url, _ = theme_state(opener, cookies, pub_url)
    print(json.dumps(theme, indent=1, ensure_ascii=False))


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
        "genre": (state.get("game_tags") or {}).get("genre"),
        "tags": (state.get("game_tags") or {}).get("tags"),
        "ai": state.get("ai_disclosure"),
        "embed": state.get("embed_options"),
        "cover_image": (state.get("cover_image") or {}).get("id"),
        "screenshots": [s.get("id") for s in (state.get("game", {}).get("screenshots") or [])],
        "uploads": [
            {"id": u.get("id"), "filename": u.get("filename"), "channel": u.get("channel_name"),
             "embed": u.get("embed"), "size": u.get("size"), "demo": u.get("demo"),
             "p_windows": u.get("p_windows"), "p_linux": u.get("p_linux"), "p_osx": u.get("p_osx")}
            for u in state.get("uploads", [])
        ],
    }
    print(json.dumps(out, indent=1, ensure_ascii=False))


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("apply")
    p.add_argument("id", type=int)
    p.add_argument("--profile", required=True)
    p.set_defaults(f=cmd_apply)

    p = sub.add_parser("cover")
    p.add_argument("id", type=int)
    p.add_argument("file")
    p.set_defaults(f=cmd_cover)

    p = sub.add_parser("screenshots")
    p.add_argument("id", type=int)
    p.add_argument("files", nargs="+")
    p.set_defaults(f=cmd_screenshots)

    p = sub.add_parser("embedbg")
    p.add_argument("id", type=int)
    p.add_argument("file")
    p.set_defaults(f=cmd_embedbg)

    p = sub.add_parser("theme")
    p.add_argument("id", type=int)
    p.add_argument("--slug", required=True)
    p.add_argument("--user", default="bfstone25-stack")
    p.add_argument("--colors")
    p.add_argument("--embedbg-id", action="store_true")
    p.set_defaults(f=cmd_theme)

    p = sub.add_parser("embedbg-apply")
    p.add_argument("id", type=int)
    p.add_argument("--slug", required=True)
    p.add_argument("--user", default="bfstone25-stack")
    p.set_defaults(f=cmd_embedbg_apply)

    p = sub.add_parser("devlog")
    p.add_argument("id", type=int)
    p.add_argument("--title", required=True)
    p.add_argument("--body", required=True)
    p.add_argument("--tags", default="")
    p.add_argument("--publish", action="store_true")
    p.set_defaults(f=cmd_devlog)

    p = sub.add_parser("retire")
    p.add_argument("id", type=int)
    p.set_defaults(f=cmd_retire)

    p = sub.add_parser("themestate")
    p.add_argument("--slug", required=True)
    p.add_argument("--user", default="bfstone25-stack")
    p.set_defaults(f=cmd_themestate)

    p = sub.add_parser("state")
    p.add_argument("id", type=int)
    p.set_defaults(f=cmd_state)

    args = ap.parse_args()
    args.f(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
