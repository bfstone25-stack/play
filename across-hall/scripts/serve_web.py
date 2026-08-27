#!/usr/bin/env python3
"""Serve the Godot Web export with the WASM MIME type browsers require."""

from __future__ import annotations

import argparse
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument(
        "--dir",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    args = parser.parse_args()
    httpd = ThreadingHTTPServer(
        ("0.0.0.0", args.port),
        functools.partial(Handler, directory=args.dir),
    )
    print(f"serving {args.dir} on http://0.0.0.0:{args.port}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
