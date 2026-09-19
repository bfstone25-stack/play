# Late Inspection: Flat 404（深夜验房：404室）

Standalone **3D Horror VN** (Godot 4.7). A complete six-zone episode with four decisions and three authored endings.

See [`PRODUCT_BIBLE.md`](PRODUCT_BIBLE.md) for the executable screenplay, state map, cues, and acceptance criteria.

## Run

```bash
/tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection
```

Smoke (xvfb):

```bash
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection --import --headless
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path late-inspection -s res://tests/smoke.gd
```

## Controls

- WASD + mouse look
- E / click — interact, then advance the bottom ADV bar
- Esc — pause/resume and release/capture mouse
- Choices sit above the ADV bar — click or press A / B
- Diary / breakdown / endings use full-screen NVL (red filter + shake)
- R — restart after an ending

Progression verification:

```bash
godot --headless --path late-inspection -s res://tests/progression.gd
```

Interaction cone (needs a display — it photographs what it measures):

```bash
"$GODOT" --path late-inspection --resolution 1280x720 -s res://tests/facing_probe.gd
"$GODOT" --path late-inspection --resolution 1280x720 -s res://tests/facing_probe.gd -- --shots
```

`interact_target()`'s 6.5 m fallback asks whether the player is facing the prop. That gate
had been stubbed to `true`, so props could be taken from behind. `FACE_DOT` is 0.80 — a
36.9 degree half-angle, which puts a prop entering the cone 60% of the way to the edge of
the picture. The probe measures that mapping in the running game, checks every prop from
in front, from behind and from underfoot, and prints `FACING_OK`.

## Not this repo folder

Legacy H5 Crazy Rant remains under `../crazy-rant/` as a stub pointer only.
