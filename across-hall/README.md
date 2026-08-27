# 对门 / Across the Hall

Short first-person apartment horror in Godot 4.7. Not a canvas prototype.

You spawn on the 4th-floor landing. 401 is yours and shut. 402 is open. A tenant is only visible in peripheral vision.

## Play

Godot 4 will not run in Chrome unless the page is HTTPS (or localhost).
`http://100.x.x.x` on Tailscale is **not** a secure context — that is the
“Secure Context missing” error on Pixel.

```
godot --headless --path across-hall --export-release Web across-hall/build/web/index.html
python3 across-hall/scripts/serve_web.py --https --port 8443
```

On Pixel Chrome open `https://100.121.195.19:8443/` (or `https://blazeubuntu:8443/`),
tap Advanced → Proceed for the self-signed cert, then wait for WASM.

Desktop Linux/Windows/macOS still use Forward+ if you have a GPU window (`godot --path across-hall`). A GPU-less SSH server cannot display that build.

Same project, two renderers: Forward+ on PC, GL Compatibility (WebGL 2) in the browser.

Smoke (needs a GPU window; `--headless` cannot dump a real Forward+ frame):

```
godot --path across-hall -s res://tests/smoke.gd
```

WASD move, mouse look, E interact, F flashlight, Shift walk faster, Esc free the mouse.

Loop: flashlight → 401 门缝 → 402 退租单 → 浴室磁带 → 录音机。邻居只在余光里。正视它会到你背后。结局：对门是你留下的那一半。

Itch-length apartment horror: analog grain, 02:17, knock/drip, peripheral enemy, one thesis.

## Why this instead of the H5 draft

The earlier AI pass never left colored rectangles. This one has a real scale hallway, sodium/flicker lights, a flashlight cone, spatial footsteps, and one creature rule (do not stare).
