# Late Inspection: Flat 404（深夜验房：404室）

Standalone **3D Horror VN** (Godot 4.7). Product pivot from Catharsis cabinet 06 Crazy Rant.

See [`PIVOT.md`](PIVOT.md) for naming, scope, scene list, endings, and Across the Hall reuse rules.

## Run

```bash
/tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection
```

Smoke (xvfb):

```bash
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection --import --headless
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path late-inspection -s res://tests/smoke.gd
```

## Prototype controls

- WASD + mouse look
- E / click — interact (notes, pipe, overnight clause)
- Esc — release mouse
- Choice panel — two hard options (mouse)

## Not this repo folder

Legacy H5 Crazy Rant remains under `../crazy-rant/` as a stub pointer only.
