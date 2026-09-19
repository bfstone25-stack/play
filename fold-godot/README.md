# FOLD — Godot 4.7

The engine rebuild of `play/fold` (live at <https://free.blazecore.dev/fold/>). Mainstream,
all ages. The web original is untouched and still ships; this is the version that is meant
to look like a release rather than like a web page.

## Run it

```bash
ops/godot_build.sh play/fold-godot fold           # web + linux + windows into build/godot/fold
cd play/fold-godot && python3 tests/headless_web.py   # plays it in headless Chromium, shots/ 
```

or open `project.godot` in Godot 4.7 and press F5.

## What is where

| file | what |
|---|---|
| `scripts/fold.gd` | **the rules**, ported line for line from the shipped `play/fold/frontend/index.html`: `load`, `move`, `undo`, the win test, the star formula. No drawing, no sound, no storage. Autoload `Fold`. |
| `scripts/palette.gd` | FOLD's own colours on the studio's role table (`play/overtime-idle-godot/scripts/palette.gd`'s API). Sunlit cream, candy paper, tangerine — plus the playfield's measured contrast targets, which `run_tests.gd` asserts. |
| `scripts/studio_theme.gd` | the Theme, same API as the sibling's. Lilita One / Nunito, each with a Noto Sans CJK subset attached so the zh build is not tofu. |
| `scripts/vector_mark.gd` | the logotype. The page's own designed SVG mark (`FOLD`, `归一`) parsed and drawn as vector strokes, with a draw-on reveal. Never a Label. |
| `scripts/piece_view.gd` | how a piece looks — the folded-paper plate, tinted, with shadow, rim, number and its own light once it is up the gold ramp. Shared by the board and the title's attract loop. |
| `scripts/art.gd` | the rendered plates, and the stand-in a slot gets when its plate is not on disk yet. `Art.missing()` names them. |
| `scripts/i18n.gd`, `save.gd`, `sfx.gd`, `tel.gd` | en + zh; progress in the web build's localStorage shape; the page's procedural audio resynthesised; telemetry forwarded to `window.TEL` under the web build's event names. |
| `scenes/title.gd` | the title screen — `ops/adult_forks/TITLE_SCREENS.md`, all six items. |
| `scenes/game.gd` | the board: tilted plane, Light2D lamp, lit pieces, the crease, HUD, level picker, win card, the ad gate, the casual promo board. |
| `tools/subset_cjk.py` | rebuilds the CJK font subset from this project's own strings. |

## The palette is bright on purpose (2026-09-19)

The first Godot build of this game was a lamplit study: pine-black room, walnut table, one
gold lamp, Marcellus. Blaze sent it back — not to be polished, but redirected. FOLD is
all-ages, it sits on the CrazyGames and phone-store shelf, and it should be cute, bright
and energetic. `play/rebound-tycoon-godot` is the reference.

What that means concretely, and what it cost:

* **The page is bright; the board is not.** The tray is deep teal on a sunny cream page.
  Bright and legible are different properties — the first attempt at the repaint put light
  candy tiles on a light mint table and measured **1.00:1**, the identical defect to the
  walnut build. `Palette.legibility_targets()` now carries the targets as data and
  `run_tests.gd` asserts every one of them.
* **A tinted surface is multiplied by its plate.** `derive --neutral` centres a plate for
  a tinted slot on 0.92 of white, so `Palette.SURFACE_GAIN` is applied before anything is
  measured. Measured with the ideal constants the board passed; measured with the plates
  actually installed, two targets missed, and the colours were re-picked.
* **Juice is a feature, not polish.** A slide squashes the board along the fold axis and
  springs back, pieces settle with an overshoot, a merge pops and throws sparks in its own
  colour, a win bursts across the tray, and the logotype takes a shine sweep on a timer.

## Tests

```bash
./tests/run.sh              # regenerates the JS fixture, then the headless Godot scene
```

70 checks. The important one is the conformance replay: `tests/harness.cjs` lifts the
shipped game's inline `<script>` out of `play/fold/frontend/index.html` and runs it
unmodified in Node; `tests/conformance_gen.cjs` drives it over all 201 levels with 7,643
seeded moves, recording every tile's id/row/column/value after every move plus an undo
run; `tests/run_tests.gd` replays the identical sequence through `scripts/fold.gd` and
compares. Any divergence — including which of two equal pieces survives a merge, which is
decided by a *stable* sort the JS gets for free and GDScript does not — fails on the move
it happens.

`tests/solve.cjs` breadth-first solves a level with that same JavaScript, and
`tests/headless_web.py` plays those optimal solutions into the real wasm build with real
key events, checking the move counts and stars match.

The JS-vs-C tie-rounding trap that `play/overtime-idle-godot/scripts/idle.gd` documents
does not bite here: every quantity in FOLD is an integer. `_no_floats()` asserts that
rather than assuming it.

## Art

`ops/fold_art/fold_gen.py`, through `ops/render_queue.py`. Rendered and in the game:
`key`, `bg_far`, `bg_mid`, `piece`. Still stand-ins: `table`, `wall`, `foil` — Animagine XL
will not render a material swatch (see the note on `derive()` in the generator), and they
need a photo checkpoint or hand-made tiles.
