# REBOUND TYCOON · 老王逆袭记 — Godot 4.7

The engine rebuild of `play/rebound-tycoon` (the vanilla-JS build live at
<https://free.blazecore.dev/rebound-tycoon/>). The JS build is untouched and still serves;
this is the studio release of the same game — cabinet 06 of 情绪解药 / Emotional Catharsis,
the midlife / gig track (`play/catharsis/PLAN.md`).

A night-shift guard works a gate. He pumps a water hose to launch, every rebound soaks a
troublemaker and pays rent, and the coins buy the skyline he is standing in front of.

## Run it

    GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    $GODOT --path .                 # desktop
    ./build.sh                      # web + linux + windows -> ../../build/godot/rebound-tycoon
    tests/run.sh                    # the conformance suite (below)
    python3 tests/headless_web.py   # drive the web build in headless Chromium -> shots/
    python3 tests/headless_motion.py  # reduced motion, both ways -> shots/motion/

## What is where

| file | what |
|---|---|
| `scripts/kernel.gd` | the rules — an exact port of the JS `kernel.js`, bit for bit |
| `scripts/fdlibm.gd` | `sin`/`cos` the way V8 computes them, because the engine's differ |
| `scripts/idle.gd` | the offline gate — `play/catharsis/kernel/idle.js`, 8 h cap |
| `scripts/table_view.gd` | the cabinet: parallax backglass, Light2D, rendered pieces |
| `scripts/title_screen.gd` | the first second (`ops/adult_forks/TITLE_SCREENS.md`) |
| `scripts/logotype.gd` | REBOUND as a designed mark — neon tube over a brass plate |
| `scripts/palette.gd` / `studio_theme.gd` | the studio conventions, in this title's key |
| `tests/` | the JS↔GDScript conformance suite |

## Reduced motion

`Motion` on the title screen: **Auto / Calm / Full**, saved with sound and language. Auto
asks the platform — `DisplayServer.accessibility_should_reduce_animation()` on desktop,
`prefers-reduced-motion` on the web — and is re-read every frame, so flipping the system
switch with the game open calms the next frame. Calm and Full are the player overruling it.

Four things are gated on it: the title's parallax push, the logotype's neon flicker, the
table's sky drift, and the sparks a rebound throws. All four were written, and none of
them ran for the life of the project, because nothing ever assigned the flag. So
`tests/headless_motion.py` does not check that the flag is set — it checks what the four
branches *did to the scene*, in two Chromium contexts reporting opposite preferences, and
it was confirmed to fail against a build with the assignment removed before it was
believed.

## The conformance suite

`tests/conformance_gen.cjs` requires the **shipped** `play/rebound-tycoon/frontend/js/kernel.js`
and records what it does: 280 seeded economy states, 72 seeded physics runs (900 frames
each, a scripted input timeline, `Math.random` replaced by an LCG the GDScript side
reimplements), 160 offline-gate cases, and all 131 constants the table is built from.
`tests/run_tests.gd` replays every one of them against this port and compares **doubles
with `==`** — no epsilon.

    node tests/conformance_gen.cjs && tests/run.sh
    -> 56409 passed, 0 failed

Getting there turned up four things that each produce a *plausible* wrong number rather
than a crash, which is why the test compares exactly:

1. **`Math.hypot` is not `sqrt(x*x+y*y)`.** V8 scales by the largest term and sums with a
   Neumaier compensation; the two disagree in the last ulp for ~37% of inputs.
   `Kernel.hyp` replicates V8.
2. **V8 does not use the system libm for `sin`/`cos`.** It carries its own fdlibm; glibc's
   are a different implementation and differ by an ulp for ~6% of arguments. The only
   `sin`/`cos` in the kernel are the flipper's, and a flipper is a lever.
   `scripts/fdlibm.gd` is the port, verified bit-identical over 8000 samples.
3. **`Vector2` holds 32-bit floats.** The flipper pivots were a `Vector2`; `0.255` became
   `0.25499999523162842`. The game looked fine and four runs out of seventy-two drifted.
4. **Operator grouping is not algebra.** `x *= a / b` divides first; `x += A + B` sums the
   two terms before adding. Written the other way round, both are a different double, and
   both are applied every frame, so the error accumulates rather than cancelling.

Plus one in the harness itself: **Godot's decimal-to-double parser is not correctly
rounded** (it reads `19.349999999999998` an ulp high, and `String.to_float` agrees), so
every non-integer double crosses from node as its IEEE-754 bit pattern. An epsilon
comparison would have passed through all of this without a word.

## Tracks

Same two as every title (`ops/DUAL_TRACK.md`): nights 1–3 are free, night 4 onward goes
through `Gate` — a price on the itch build, one sponsor clip on `free.blazecore.dev`. The
casual cross-promotion board is offered once, when a night ends, never during play.
Mainstream / SFW; the board is asked for as `"casual"` explicitly so nothing adult can be
requested from an AdSense host (`ops/check_adsense_isolation.py`).

## Art

`ops/rebound_art/rebound_gen.py` (queued through `ops/render_queue.py`, tier 0 throughout).
The key visual, the parallax stack and the era skylines are rendered plates; the table
pieces are the rendered assets the JS build already shipped, re-lit for the night palette.
