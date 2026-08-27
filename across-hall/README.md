# 对门 / Across the Hall

Short first-person apartment horror in Godot 4.7. Not a canvas prototype.

You spawn on the 4th-floor landing. 401 is yours and shut. 402 is open. A tenant is only visible in peripheral vision.

## Play

On a machine with Godot 4.7:

```
godot --path across-hall
```

Smoke (needs a GPU window; `--headless` cannot dump a real Forward+ frame):

```
godot --path across-hall -s res://tests/smoke.gd
```

WASD move, mouse look, E interact, F flashlight, Shift walk faster, Esc free the mouse.

Loop: flashlight on the landing → note on the table in 402 → tape in the bathroom → play it on the radio.

## Why this instead of the H5 draft

The earlier AI pass never left colored rectangles. This one has a real scale hallway, sodium/flicker lights, a flashlight cone, spatial footsteps, and one creature rule (do not stare).
