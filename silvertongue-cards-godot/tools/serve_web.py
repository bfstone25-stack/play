#!/usr/bin/env python3
"""Serve a web export same-origin with the backend, the way the gateway does in production.

    python3 tools/serve_web.py [--dir ../../build/godot/silvertongue-cards/web] [--port 8930] [--backend http://127.0.0.1:8929]

Static files come from the export directory; /cards/*, /assets/*, /ref/* are proxied to the
backend, so the wasm build calls location.origin (Api's default on a non-itch host) and the
backend's CORS list never has to include a localhost origin.
"""
import argparse
import http.server
import os
import sys
import urllib.request
import urllib.error


class H(http.server.SimpleHTTPRequestHandler):
    backend = "http://127.0.0.1:8929"
    proxied = ("/cards/", "/assets/", "/ref/", "/x/", "/shared/")

    def log_message(self, *a):
        pass

    def end_headers(self):
        # No COOP/COEP: the export is single-threaded (no SharedArrayBuffer), and COEP would
        # block the board's cross-origin tile images, which is exactly the production shape.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def _proxy(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        req = urllib.request.Request(self.backend + self.path, data=body, method=self.command)
        for k in ("Content-Type", "Cookie", "Accept"):
            if self.headers.get(k):
                req.add_header(k, self.headers[k])
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
                self.send_response(r.status)
                for k, v in r.headers.items():
                    if k.lower() in ("content-type", "set-cookie"):
                        self.send_header(k, v)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", e.headers.get("Content-Type", "application/json"))
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:  # noqa: BLE001
            self.send_response(502)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def do_GET(self):
        if self.path.startswith(self.proxied):
            return self._proxy()
        return super().do_GET()

    def do_POST(self):
        if self.path.startswith(self.proxied):
            return self._proxy()
        self.send_response(405)
        self.end_headers()


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=os.path.join(here, "..", "..", "..", "build", "godot", "silvertongue-cards", "web"))
    ap.add_argument("--port", type=int, default=8930)
    ap.add_argument("--backend", default="http://127.0.0.1:8929")
    a = ap.parse_args()
    H.backend = a.backend
    os.chdir(a.dir)
    H.extensions_map.update({".wasm": "application/wasm", ".pck": "application/octet-stream"})
    print("serving", os.getcwd(), "on", a.port, "-> backend", a.backend, file=sys.stderr)
    http.server.ThreadingHTTPServer(("127.0.0.1", a.port), H).serve_forever()


if __name__ == "__main__":
    main()
