# SILVERTONGUE: AFTER HOURS — Cards (Godot 4.7 client)

The card-battle client, rebuilt in Godot over the unchanged Python backend in
`play/silvertongue-cards/backend` (FastAPI on :8929). The HTML prototype in
`play/silvertongue-cards/frontend` stays as the reference for what each screen must do; this
is the one that is meant to look like a game. Design: `ops/adult_forks/silvertongue_cards.md`.

No model anywhere: the client only talks to `/cards/*`. Every number on screen — momentum,
phase, evidence, nerve, the hand — came back from `/cards/play`; the client animates it.

## Run

```sh
cd play/silvertongue-cards && ./run.sh                     # backend on 127.0.0.1:8929
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
$GODOT --path play/silvertongue-cards-godot                # desktop, talks to :8929
$GODOT --path play/silvertongue-cards-godot -- --api=http://host:port --pid=me   # overrides
bash ops/godot_build.sh play/silvertongue-cards-godot silvertongue-cards       # web + linux + windows -> build/godot/silvertongue-cards/
python3 play/silvertongue-cards-godot/tools/serve_web.py   # serve the web export on :8930, same-origin proxy to the backend
```

On the web, `Api` uses `location.origin` (the dev server above, or the gateway path) and the
same `stc_pid` localStorage key as the prototype, so a player keeps their collection across
the two clients. On a foreign host (itch, Nutaku) it uses `https://apps.blazecore.dev/silvertongue-cards`.

## Verify

```sh
$GODOT --headless --path play/silvertongue-cards-godot res://tests/run_tests.tscn   # 69 checks: Api vs live backend, hand state machine, wild path, play to PERSUADED
DISPLAY=:0 $GODOT --path play/silvertongue-cards-godot res://tests/shots.tscn       # desktop screenshots -> shots/d*.png
python3 play/silvertongue-cards-godot/tools/e2e_web.py                              # web export in headless Chromium -> shots/w*.png
```

## Studio conventions (for play/overtime-idle-godot to reuse)

- `scripts/palette.gd` — `Palette.*` colours (the parent's dark room / lamp / amber).
- `scripts/studio_theme.gd` — `StudioTheme.build()` returns the Theme; `style_button(b, "primary"|"free"|"active"|"quiet")`; `mono_label / serif_label / display_label`.
- Autoloads: `Gate` (shared/godot/gate.gd, copied by the build), `Api` (HTTP + identity), `Sfx` (cue names; drop `.ogg` files in `assets/sfx/<cue>.ogg` to replace the synthesised placeholders).
- Headless tests are scenes (`tests/*.tscn`), never `--script`, so the autoloads are up.
- Web test bridge: `window.stc.call(cmd, arg)` / `window.stc.result()` (see `main.gd::bridge_command`).

## Stubbed / not yet

- Audio is synthesised placeholder tones; the cue hooks are wired.
- Account register/login exists in `Api` but has no screen; play is by pid.
- The tier-4 (affection 10) scene is a dashed placeholder, as in the prototype.
- No Nutaku SKU purchase UI in the client — Gold arrives through the gateway grant, and the
  `+1000 GOLD (dev)` button only works while the backend runs without `CARDS_PROD=1`.
