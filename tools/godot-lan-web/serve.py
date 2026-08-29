#!/usr/bin/env python3
"""HTTPS static server for Godot Web playtests: wasm MIME + Range + no-cache."""
from __future__ import annotations

import argparse
import os
import ssl
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


NO_CACHE_EXT = {".html", ".htm", ".pck", ".wasm", ".js", ".txt"}


class GodotHandler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "application/javascript",
    }

    def end_headers(self) -> None:
        path = urlparse(self.path).path
        ext = os.path.splitext(path)[1].lower()
        if ext in NO_CACHE_EXT or path.endswith("/"):
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Expose-Headers", "Accept-Ranges, Content-Range, Content-Length")
        self.send_header("Accept-Ranges", "bytes")
        super().end_headers()

    def do_GET(self) -> None:
        if self.headers.get("Range"):
            self._send_range()
            return
        super().do_GET()

    def _parse_range(self, header: str, size: int) -> tuple[int, int] | None:
        header = header.strip()
        if not header.startswith("bytes="):
            return None
        spec = header[6:].strip()
        if "," in spec:
            return None
        start_s, _, end_s = spec.partition("-")
        try:
            if start_s == "" and end_s:
                length = int(end_s)
                if length <= 0:
                    return None
                start = max(0, size - length)
                end = size - 1
            elif start_s and end_s == "":
                start = int(start_s)
                end = size - 1
            else:
                start = int(start_s)
                end = int(end_s)
        except ValueError:
            return None
        if start < 0 or end < start or start >= size:
            return None
        return start, min(end, size - 1)

    def _send_range(self) -> None:
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            super().do_GET()
            return
        try:
            file_obj = open(path, "rb")
        except OSError:
            self.send_error(404, "File not found")
            return
        try:
            fs = os.fstat(file_obj.fileno())
            size = fs.st_size
            parsed = self._parse_range(self.headers["Range"], size)
            if parsed is None:
                self.send_error(416, "Requested Range Not Satisfiable")
                return
            start, end = parsed
            length = end - start + 1
            self.send_response(206)
            self.send_header("Content-Type", self.guess_type(path))
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(length))
            self.send_header("Last-Modified", self.date_time_string(int(fs.st_mtime)))
            self.end_headers()
            file_obj.seek(start)
            remaining = length
            while remaining > 0:
                chunk = file_obj.read(min(64 * 1024, remaining))
                if not chunk:
                    break
                self.wfile.write(chunk)
                remaining -= len(chunk)
        finally:
            file_obj.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8443)
    parser.add_argument("--dir", default=".")
    parser.add_argument("--cert", required=True)
    parser.add_argument("--key", required=True)
    args = parser.parse_args()

    handler = lambda *a, **k: GodotHandler(*a, directory=args.dir, **k)
    httpd = ThreadingHTTPServer((args.bind, args.port), handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile=args.cert, keyfile=args.key)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    print(f"serving HTTPS on {args.bind}:{args.port} dir={args.dir}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
