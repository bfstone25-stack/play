# Across the Hall

Short first-person apartment horror in Godot 4.7. English is the first language.

You spawn on the 4th-floor landing. 401 is yours and shut. 402 is open. A tenant is only visible in peripheral vision.

## Play

Godot 4 will not run in Chrome unless the page is HTTPS (or localhost).
`http://100.x.x.x` on Tailscale is **not** a secure context.

```
godot --headless --path across-hall --export-release Web across-hall/build/web/index.html
python3 across-hall/scripts/serve_web.py --https --port 8443
```

Desktop: `godot --path across-hall` (needs a GPU window).

WASD move, mouse look, E interact, F flashlight, Shift walk faster, Esc free the mouse. After the ending, R restarts.

Loop: flashlight → listen at 401 → vacancy notice in 402 → cassette in the bathroom → tape deck. The neighbor lives in peripheral vision. Staring puts it behind you. Ending: you are the door across the hall.
