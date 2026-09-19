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

Loop (5 chapters):

1. Hall — flashlight. 401 locked, 402 open.
2. Apt 402 — vacancy notice signed with your name.
3. 402 bath — cassette + 401 key.
4. Apt 401 — unlock your own door. Calendar stuck on Feb 17. Clock at 02:17.
5. Overlap — plates swap. Play the cassette on the 401 deck. Ending: you are the door across the hall.

The neighbor lives in peripheral vision. Staring puts it behind you. Caught = reset to the hall, same 02:17.
