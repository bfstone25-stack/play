# 对门 / Across the Hall

Short first-person apartment horror in Godot 4.7. Not a canvas prototype.

You spawn on the 4th-floor landing. 401 is yours and shut. 402 is open. A tenant is only visible in peripheral vision.

## Play

**Browser (the one you can actually open from a headless Ubuntu box):** export the `Web` preset, then serve the folder. WASM needs `application/wasm`, so do not open `index.html` as a file.

```
godot --headless --path across-hall --export-release Web across-hall/build/web/index.html
python3 -m http.server 8060 --directory across-hall/build/web
```

Desktop Linux/Windows/macOS still use Forward+ if you have a GPU window (`godot --path across-hall`). A GPU-less SSH server cannot display that build.

Same project, two renderers: Forward+ on PC, GL Compatibility (WebGL 2) in the browser.

Smoke (needs a GPU window; `--headless` cannot dump a real Forward+ frame):

```
godot --path across-hall -s res://tests/smoke.gd
```

WASD move, mouse look, E interact, F flashlight, Shift walk faster, Esc free the mouse.

Loop: flashlight on the landing → note on the table in 402 → tape in the bathroom → play it on the radio.

## Why this instead of the H5 draft

The earlier AI pass never left colored rectangles. This one has a real scale hallway, sodium/flicker lights, a flashlight cone, spatial footsteps, and one creature rule (do not stare).
