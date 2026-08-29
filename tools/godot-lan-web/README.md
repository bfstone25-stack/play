# Godot LAN HTTPS playtest server

Used on blazeubuntu (`10.0.0.4` / Tailscale `100.121.195.19`) in tmux session `godot-lan-web` on port 8443.

`serve.py` sets wasm MIME, Range support, COOP/COEP, and `Cache-Control: no-store` on `html` / `pck` / `wasm` / `js` so Pixel/Chrome do not keep a stale `index.pck`.

`stamp_web_build.py` writes `BUILD.txt`, puts the short commit in the HTML title, and points Godot `mainPack` at `index-<commit>.pck`.
