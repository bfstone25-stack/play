# Elena: Crimson Archives

A short dark-academia suspense / softcore romance visual novel (Ren'Py 8.3+).
Chapter 1 is a ~15–25 minute draft with three branches, a small CG gallery, and desktop + web builds.

Quality feedback from F95/itch is treated as a production backlog (see `FEEDBACK_LOOP.md`), not a debate thread.

---

## Project Structure

```
elena-suspense/
├── raw_assets/               # Source generation assets (1920x1080 / high-res)
│   ├── sprites/              # Character sprites (neutral, flustered, submission)
│   ├── bg/                   # Backgrounds (study normal, study dark)
│   └── cgs/                  # Event CGs (confrontation, climax, aftermath)
├── tools/
│   ├── process_assets.py     # rembg + 1080p resize + WebP conversion (85% quality) + thumbnail generator
│   └── requirements.txt      # Python toolchain dependencies
├── game/
│   ├── audio/                # BGM, ambient rain, and SFX
│   ├── images/
│   │   ├── bg/               # Optimized 1080p WebP backgrounds
│   │   ├── characters/       # Optimized 1080p WebP character sprites
│   │   └── cgs/              # Optimized 1080p WebP event CGs & thumbnails
│   ├── scripts/
│   │   ├── 00_init.rpy       # Variables, persistent flags, character definitions, audio channels
│   │   ├── 01_gallery.rpy    # 3-slot persistent CG Gallery screen with modal display
│   │   ├── 02_script_ch1.rpy # 15-min branching narrative with choices & CG unlocks
│   │   └── 03_endscreen.rpy  # High-conversion CTA screen (Patreon / Store links)
│   ├── options.rpy           # Ren'Py 8 build & game metadata configuration
│   ├── screens.rpy           # UI screens (say, choice, quick menu, main menu, preferences)
│   └── gui.rpy               # Dark Academia styling & 1080p canvas metrics
```

---

## Asset Processing Toolchain

### Setup
```bash
pip install -r tools/requirements.txt
```

### Run Pipeline
```bash
# Process all raw assets into optimized WebP and generate CG thumbnails
python3 tools/process_assets.py --project-root . --all

# Or generate stylized baseline assets directly:
python3 tools/process_assets.py --project-root . --generate-baseline --all
```

---

## Ren'Py SDK Lint & Execution

```bash
# Run Ren'Py 8 Lint
renpy . lint
```
