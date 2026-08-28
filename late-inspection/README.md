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
- E / click — interact (notes, pipe, overnight clause)
- Esc — pause/resume and release/capture mouse
- Choice panel — two hard options (mouse)
- R — restart after an ending

Progression verification:

```bash
godot --headless --path late-inspection -s res://tests/progression.gd
```

## Not this repo folder

Legacy H5 Crazy Rant remains under `../crazy-rant/` as a stub pointer only.
