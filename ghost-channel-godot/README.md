# GHOST CHANNEL — Godot 4.7

Five voices on a dead relay station. One of them is a mimic. You are Net Control: you
authorize, you deny, you interrogate, and when the net goes quiet you name the ghost.

The engine rebuild of `play/ghost-channel/` (vanilla JS, live at
<https://free.blazecore.dev/ghost-channel/>). The prototype is untouched and stays the
reference: the rules here are a line-for-line port of its `game.js`, and a test proves it.

## Run it

```
./build.sh && python3 tests/headless_web.py     # build both tracks, then drive a full round
bash tests/run.sh                               # the rules, against 300 recorded JS games
~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path .        # or just play it
```

## What is where

| | |
|---|---|
| `scripts/gc_rules.gd` | the whole game. Pure and static: every random draw goes through `s.rng`, nothing touches a node. This is the port. |
| `scripts/gc_strings.gd` + `gc_strings_data.gd` | the prototype's `i18n.js`, en + zh. The data file is **generated** — `tools/gen_strings.sh` re-reads the JS. |
| `scripts/main.gd` | the client: the station behind, the screens on top, the CRT over the lot, and the dev bridge the headless test drives. |
| `scripts/palette.gd`, `studio_theme.gd` | the studio's conventions (`Palette.X`, `StudioTheme.build()`) with this title's own colours and faces. |
| `scripts/station.gd`, `rain.gd`, `crt.gd`, `logotype.gd`, `call_light.gd` | the presentation: three parallax planes with real `Light2D`, weather on the glass, the driven scanline treatment, and the title mark. |
| `tests/` | the conformance harness and the headless browser drive. |
| `assets/art/` | **generated, not committed**: `build.sh` syncs the picked plates in from `ops/ghost_art/`. |
| `assets/voice/` | the five voices, baked by `ops/ghost_voice.py`. |

## The split that makes the test possible

`GCRules` decides everything and draws nothing; the scenes draw everything and decide
nothing. So `tests/conformance_gen.cjs` can run the prototype's **real `game.js`** under a
stub DOM with a seeded LCG, record 300 games — every button press, and the full panel, HUD,
log, roster and debrief after each one — and `tests/run_tests.gd` can replay the same
presses through the GDScript and assert the player would have seen the identical thing,
down to the telemetry payloads and the save file.

The one thing deliberately *not* compared is the view's own telemetry (`screen`, `layout`,
`lang`, `hotstart`), which the DOM page emitted and the Godot scenes emit for themselves.

## The two tracks

`ops/godot_build.sh` builds both (ops/DUAL_TRACK.md): operation 1 is free, 2 and 3 go
through `Gate` — a price on itch, a sponsor clip on the ad-supported site, open on the
desktop download. The end of a run offers the **casual** cross-promo board (`board.js`,
injected and verified by `ops/board_inject.py`); a mainstream title that asked for the adult
one would get silence, which is the failure `play/confession-room` actually shipped.

## Art and voice

Both are generated and the credits screen says so.

- **Art**: `ops/ghost_art/ghost_gen.py`, SDXL (Animagine XL 4.0) through the shared serial
  render queue. Ten slots, all tier 1: the key visual, three parallax planes, the console
  bed, and the five faces. `python3 ops/render_queue.py add ghost plates --n 3 --only <slot> --host remote`.
- **Voice**: `ops/ghost_voice.py`, CosyVoice2-0.5B, then a radio chain (300–3400 Hz band,
  compression, overdrive, a noise floor under it). Five distinct people come out of two
  consented prompt speakers by stacking an `instruct2` direction with a pitch-and-formant
  resample per character. Resumable — a key that has a file is skipped.

Every plate slot and every voice key is optional at runtime: a missing plate draws a slot,
a missing clip plays the call-sign tone, and the title screen says which so a player never
wonders whether their sound is broken.
