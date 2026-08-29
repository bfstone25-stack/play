#!/usr/bin/env python3
"""Stamp a Godot web export with build id, hashed pck name, and BUILD.txt."""
from __future__ import annotations

import argparse
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path


def stamp(web_dir: Path, *, slug: str, commit: str, branch: str, title: str, godot: str) -> None:
    html_path = web_dir / "index.html"
    pck_path = web_dir / "index.pck"
    if not html_path.is_file() or not pck_path.is_file():
        raise SystemExit(f"missing index.html or index.pck in {web_dir}")

    pck_bytes = pck_path.stat().st_size
    hashed_name = f"index-{commit}.pck"
    hashed_path = web_dir / hashed_name
    shutil.copy2(pck_path, hashed_path)

    exported_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    html = html_path.read_text(encoding="utf-8")
    html = re.sub(r"<title>[^<]*</title>", f"<title>{title} [{commit}]</title>", html, count=1)
    if "mainPack" not in html:
        html = html.replace(
            '"executable":"index"',
            f'"executable":"index","mainPack":"{hashed_name}"',
            1,
        )
    html = html.replace('"index.pck":', f'"{hashed_name}":', 1)
    html = html.replace('<script src="index.js">', f'<script src="index.js?v={commit}">', 1)
    if "<!-- playtest-build" not in html:
        html = html.replace(
            "<head>",
            (
                "<head>\n"
                f"\t<!-- playtest-build {slug} {commit} {exported_at} -->\n"
                '\t<meta http-equiv="Cache-Control" content="no-store, no-cache, must-revalidate">\n'
                '\t<meta http-equiv="Pragma" content="no-cache">\n'
            ),
            1,
        )
    html_path.write_text(html, encoding="utf-8")

    (web_dir / "BUILD.txt").write_text(
        (
            f"slug={slug}\n"
            f"commit={commit}\n"
            f"branch={branch}\n"
            f"exported_at={exported_at}\n"
            f"pck={hashed_name}\n"
            f"pck_bytes={pck_bytes}\n"
            f"godot={godot}\n"
        ),
        encoding="utf-8",
    )
    print(f"stamped {slug} {commit} pck_bytes={pck_bytes} -> {hashed_name}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("web_dir")
    parser.add_argument("--slug", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--branch", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    stamp(
        Path(args.web_dir),
        slug=args.slug,
        commit=args.commit,
        branch=args.branch,
        title=args.title,
        godot=args.godot,
    )


if __name__ == "__main__":
    main()
