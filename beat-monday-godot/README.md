# BEAT THE MONDAY — Godot 4.7

The Godot rebuild of `play/beat-monday/` (the HTML version stays in place as the spec:
`frontend/rpg/{core,data,phrases,strings}.js`, `rpg-smoke.cjs`, `DESIGN.md`). Same design —
a work week as the campaign, one-thumb survivor-like days, XP and a pick-one-of-three
level-up, three equipment slots dropped by bosses, colleagues who orbit, Saturday into a
harder week, Wednesday as the absorbed Crazy Rant with `kernel/rant.js`'s
stream → spread → burst — same numbers, a different shell: a drawn office instead of a
web form.

## Run

```
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import          # once, and after new files
$GODOT --path .                              # desktop, portrait 420x640
bash tests/run.sh                            # 66 checks: units, a whole headless week, JS<->GDScript conformance
./build.sh                                   # web + linux + windows -> ../../build/godot/beat-monday/
python3 tests/headless_web.py                # drives the web build through five days, screenshots -> shots/
```

Conformance: `node tests/conformance_gen.cjs` runs the HTML spec's core over seeded inputs
into `tests/conformance.json` (60 profiles → computeStats, 40 seeded runs stepped at 1/60 s
for up to 75 s with a deterministic thumb and pending[0] picks, 3000 snapshots, rant
patterns, phrase text); `tests/run_tests.gd` runs the GDScript port over the same inputs and
asserts every integer (level, xp, kills, shots fired, phrases fired, live counts, rng
draws, pierce, skill offers, pattern, phase, reward, committed profile) is identical and
every continuous value (positions, hp, foe hp) within 1e-4 relative. The one deliberate
arithmetic alignment: the harness installs `Math.hypot = sqrt(a*a+b*b)` before the JS core
loads, matching the port (V8's hypot is a scaled Kahan sum). Residual float deviation is
libm's last-ulp differences in sin/cos/atan2.

## Layout

| | |
|---|---|
| `scripts/bm_data.gd` | every number — `data.js` row for row |
| `scripts/bm_core.gd` | the loop — `core.js` + the kernel functions it uses, pure |
| `scripts/bm_phrases.gd` | the Crazy Rant corpus, verbatim |
| `scripts/strings.gd` | UI copy, en + zh-Hans |
| `scripts/game.gd` | **Game** autoload — profile in `user://beatmonday.json`, language, telemetry (page TEL SDK), the web dev bridge |
| `scripts/gate.gd` | **Gate** autoload — copy of `shared/godot/gate.gd`; the casual board after a day ends |
| `scripts/sprites.gd` | the art: every enemy, boss, character, icon, the office floor and the desk, drawn as vectors |
| `scripts/arena.gd`, `hud.gd` | the day: plate + entities + phrase shatter; the top strip |
| `scripts/main.gd` | screens (title, week board, brief, level-up, result, desk, weekend), input, the loop wiring |
| `scripts/palette.gd`, `studio_theme.gd` | this title's colours under the studio's names; the shared Theme |
| `assets/art/plate_*.webp` | office plates per day, rendered by `ops/beat_monday_art/beat_monday_gen.py` |
| `assets/fonts/` | Lilita One, Nunito, Playfair Italic (OFL) + a 342-glyph Noto Sans CJK subset (`tools/subset_cjk.py`) |

## Rules kept

No popups, no redirects: the board (`Gate.board_offer_more("casual")`, once per session,
behind a 0.9 s timer after a result) and every screen change is an explicit tap. No adult
content. Telemetry is the page SDK stamped in by `ops/godot_build.sh`. Balance is the
spec's numbers, untuned by a human.
