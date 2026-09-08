#!/usr/bin/env python3
"""Serve the Godot Web export with WASM MIME and optional HTTPS.

Godot 4 refuses to start unless the page is a Secure Context (HTTPS or localhost).
Tailscale 100.x HTTP is not that, so phones must use --https.
"""

from __future__ import annotations

import argparse
import functools
import ssl
import subprocess
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }


def ensure_cert(cert: Path, key: Path, names: list[str]) -> None:
    if cert.is_file() and key.is_file():
        return
    san = []
    for n in names:
        if n.replace(".", "").isdigit() or ":" in n:
            san.append(f"IP:{n}")
        else:
            san.append(f"DNS:{n}")
    san_str = ",".join(san)
    cert.parent.mkdir(parents=True, exist_ok=True)
    subprocess.check_call(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-sha256",
            "-days",
            "825",
            "-nodes",
            "-keyout",
            str(key),
            "-out",
            str(cert),
            "-subj",
            "/CN=across-hall",
            "-addext",
            f"subjectAltName={san_str}",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument(
        "--dir",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    parser.add_argument("--https", action="store_true")
    parser.add_argument("--cert", default="")
    parser.add_argument("--key", default="")
    args = parser.parse_args()
    httpd = ThreadingHTTPServer(
        ("0.0.0.0", args.port),
        functools.partial(Handler, directory=args.dir),
    )
    scheme = "http"
    if args.https:
        cert = Path(args.cert or (Path(args.dir) / "dev-cert.pem"))
        key = Path(args.key or (Path(args.dir) / "dev-key.pem"))
        ensure_cert(
            cert,
            key,
            [
                "localhost",
                "blazeubuntu",
                "blazeubuntu.taile5a52e.ts.net",
                "127.0.0.1",
                "100.121.195.19",
            ],
        )
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(cert, key)
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
        scheme = "https"
    print(f"serving {args.dir} on {scheme}://0.0.0.0:{args.port}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
