# SUASION (Godot 4.7 client)

The card-battle client, rebuilt in Godot over the unchanged Python backend in
`play/silvertongue-cards/backend` (FastAPI on :8929). The HTML prototype in
`play/silvertongue-cards/frontend` stays as the reference for what each screen must do; this
is the one that is meant to look like a game. Design: `ops/adult_forks/silvertongue_cards.md`.

No model anywhere: the client only talks to `/cards/*`. Every number on screen — momentum,
phase, evidence, nerve, the hand — came back from `/cards/play`; the client animates it.

## How her replies work (they are not one script)

She does not read down a fixed list of lines. Every time you play a card, the game looks
up her answer in a table. The table is keyed on three things: the phase she was in before
the card (guarded, engaged, wavering, breakthrough), the phase she is in after it, and
what kind of card it was (a common that landed, a rare, an ask, your own typed line, a
repeat, or a pressure card). So the same card gets a cool answer when she is guarded and a
warmer one when it tips her into wavering: what she says follows the state of the duel,
not the order of turns. Most keys hold two or more lines and one is picked at random, so
two duels do not sound the same. If an exact key has no line, the lookup widens step by
step (any card kind, then any earlier phase) so she always has something to say.

The tables: `play/silvertongue-cards/backend/replies.py` (the five women's own scenes,
with the Japanese twin in `replies_ja.py`, line for line) and `backend/campaign/voices.py`
(Celeste, and each woman's lines for ordinary campaign nights). The offline build carries
a copy in `assets/offline/data.json`; regenerate it with `tools/export_offline.py` and then
`tools/font_pack.py` after changing any line.

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

## Art

`python3 tools/sync_art.py` cuts the faces (`assets/faces/`) and busts (`assets/portraits/`) out of the
installed tier-1 plates in `play/silvertongue-x/frontend/assets/cg/cg1_*.png`, using the rects in
`tools/face_crops.json`; `assets/art_sources.json` records the provenance and the tests refuse
anything that traces to `ops/`. Outputs are committed so the build needs no import step.

## Verify

```sh
$GODOT --headless --path play/silvertongue-cards-godot res://tests/run_tests.tscn   # ~80 checks: Api vs live backend, hand state machine, wild path, play to PERSUADED
DISPLAY=:0 $GODOT --path play/silvertongue-cards-godot res://tests/shots.tscn       # desktop screenshots -> shots/d*.png
python3 play/silvertongue-cards-godot/tools/e2e_web.py                              # web export in headless Chromium -> shots/w*.png
```

## Studio conventions (for play/overtime-idle-godot to reuse)

- `scripts/palette.gd` and `scripts/studio_theme.gd` are **shared verbatim** with play/overtime-idle-godot
  (copy, never fork): `Palette.*` is ops/adult_forks/UI_DIRECTION.md's hex table — dark plum ground,
  hot magenta / gold / coral accents — and `StudioTheme.build()` returns the Theme with the three
  bundled OFL faces in `assets/fonts/` (Lilita One for display, Nunito for UI, Playfair Display Italic
  for her spoken line only). `style_button(b, "primary"|"pull"|"free"|"active"|"quiet")`;
  `mono_label` / `serif_label` both resolve to Nunito now; `display_label` is Lilita.
- `scripts/symbols.gd` — this title's own: attaches `fallback_symbols.ttf` (DejaVu Sans Bold) to the three
  faces for ♥ ◆ ⚡ ★ ◈ ✕, which none of them carry and the web has no system font for.
- `scripts/counter.gd` — `Counter`, a Label whose number counts up, overshoots and settles (wallet,
  momentum readout, the end banner).
- Autoloads: `Gate` (shared/godot/gate.gd, copied by the build), `Api` (HTTP + identity), `Sfx` (cue names; drop `.ogg` files in `assets/sfx/<cue>.ogg` to replace the synthesised placeholders).
- Headless tests are scenes (`tests/*.tscn`), never `--script`, so the autoloads are up.
- Web test bridge: `window.stc.call(cmd, arg)` / `window.stc.result()` (see `main.gd::bridge_command`).

## Stubbed / not yet

- Audio is synthesised placeholder tones; the cue hooks are wired.
- Account register/login exists in `Api` but has no screen; play is by pid.
- The tier-4 (affection 10) scene is a dashed placeholder, as in the prototype.
- No Nutaku SKU purchase UI in the client — Gold arrives through the gateway grant, and the
  `+1000 GOLD (dev)` button only works while the backend runs without `CARDS_PROD=1`.
