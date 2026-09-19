# Flutter 怦然 — the Godot 4.7 build

Today this is **a title screen and nothing else**. The game that ships is still the web
PWA in `play/flutter/`. See `PORT_PLAN.md` for what porting the rest costs and why the
engine is Godot rather than Ren'Py.

## Run it

    ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path play/flutter-godot

## Capture the title frame (the check TITLE_SCREENS.md requires)

The legibility check is done by *looking*, at a real frame, at both sizes. `--headless`
cannot draw one, so this runs a visible window, waits out the entrance, saves a PNG and
quits:

    G=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    $G --path play/flutter-godot --resolution 1280x720 -- --shot user://t.png --shot-after 2.6
    $G --path play/flutter-godot --resolution 390x844  -- --shot user://p.png --shot-after 2.6

Both land under `~/.local/share/godot/app_userdata/Flutter 怦然/`. Read them. If you have
to squint at your own screenshot, it is not done.

The 390x844 run is not a downscale of the desktop one and must not be replaced by one:
the portrait state loads a **different crop** of the key visual and lays the menu out as a
2x2 block on a different base canvas. The first version of this screen passed a downscaled
desktop capture and had a six-pixel menu on the actual phone.

## Build

    ops/godot_build.sh play/flutter-godot flutter

## Where the art comes from — do not edit the PNGs

| asset | source |
| --- | --- |
| `assets/title/logotype.png` | `ops/title_logotypes_mainstream.py` → `flutter()` |
| `assets/title/overlay.png` | same file → `overlay_flutter()` |
| `assets/title/lamp.png` | same file → `lamp_flutter()` |
| `assets/title/keyvisual*.webp` | `ops/render_queue.py` → `ops/install_keyvisual.py flutter --pick …` |
| `assets/sfx/*.wav` | `ops/title_sfx_flutter.py` |

Never run an art generator in a loop by hand — queue it (`ops/render_queue.py add flutter
plates --n 4 --only keyvisual_main`). There is one GPU and several games sharing it.

`install_keyvisual.py` writes the key visual to **both** this project and the web PWA, and
refuses any frame that hashes to a known adult-fork render. That refusal is the cheap
half of the check; two different frames of the same shoot still have to be caught by
looking.

## This is the MAINSTREAM build

SFW art, the mainstream ad unit, and the studio mark is `blazeCore Play` alone — no 18+
badge and no Flat 404, which is the adult label. `ops/check_adsense_isolation.py` is the
proof and it runs before this is called done. The adult fork is `play/flutter-after-hours/`
and nothing here refers to it.

## Fonts

Work Sans (OFL 1.1) and WenQuanYi Micro Hei (GPLv2 + font exception) ship inside the
export, licences beside them. Parisienne draws the logotype in the ops script and is
deliberately **not** in this project — the mark is baked to PNG. Details, and how to check
a built `.pck` actually contains its faces, in `ops/adult_forks/FONT_LICENCES.md`.
