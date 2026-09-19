# Overtime Landlord: Idle — Godot 4.7

The Godot rebuild of the HTML prototype in `play/overtime-idle/` (kept as the reference).
Same design (`ops/adult_forks/overtime_idle.md`), same numbers, a different shell: a
16:9 room instead of a document.

## Run

```
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
python3 tools/sync_art.py                      # once: copies the parent's plates into assets/art/ (gitignored)
$GODOT --headless --path . --import            # once, and after new files
$GODOT --path .                                # desktop
bash tests/run.sh                              # 92 checks + JS<->GDScript conformance; fails on any engine error
./build.sh                                     # web + linux + windows -> ../../build/godot/overtime-idle/
python3 tests/headless_web.py                  # drives the web build headless, screenshots -> shots/
```

Conformance data: `node tests/conformance_gen.cjs` regenerates `tests/conformance.json`
from the JS prototype (200 seeded boards, 20 gacha runs); `tests/run_tests.gd` asserts
the GDScript port produces identical payouts, events, per-cell scores, links, ticker
reports, banks, evictions and pulls.

## Layout

| | |
|---|---|
| `scripts/landlord.gd` | `settle_grid()`, catalogue, `rent_for_floor()` — the parent's rules |
| `scripts/roster.gd` | roster, `settle_idle()`, chain multiplier, dupe bonus |
| `scripts/idle.gd` | `tick()`, offline cap, daily rent, eviction, timeskip, prestige |
| `scripts/economy.gd` | **Economy** autoload — Gold, gacha with pity, affection, idempotent SKU grants; JSON in `user://`; client-trusted, marked for the `shared/economy.py` swap |
| `scripts/ticker.gd` | **Ticker** autoload — building state, skill + affection ladders, daily floor, shop, persistence, dev hooks, the web dev bridge |
| `scripts/gate.gd` | **Gate** autoload — copy of `shared/godot/gate.gd` (refreshed by `ops/godot_build.sh`) |
| `scripts/palette.gd`, `scripts/studio_theme.gd` | **Palette** / **StudioTheme** — the studio colours and Theme per `ops/adult_forks/UI_DIRECTION.md` (dark ground, hot accents; Lilita One / Nunito / Playfair Italic in `assets/fonts/`, OFL licences beside them). The same API as `play/silvertongue-cards-godot`'s, so either title can carry both files |
| `scripts/look.gd` | **Look** autoload — the scenes' names for the palette (`Look.AMBER` → `Palette.GOLD`), the Theme, the art loader (`art`, `piece_portrait`, `portrait` with the mood alias) |
| `scripts/sfx.gd` | **Sfx** — the audio.js cue points, synthesised placeholders |
| `scenes/building.tscn` | the room: floor, HUD, tray, Mirei, overlays |
| `scenes/floor.tscn` | the 5x4 isometric floor with dropping pieces, links, sparks |
| `scenes/return_screen.tscn`, `roster.tscn`, `shop.tscn`, `gallery.tscn`, `daily_floor.tscn`, `prestige.tscn` | the overlays |

## Rules kept

No popups, no redirects: the board (`Gate.board_offer_more("casual")` after the daily
result, `board_offer_break()` after an eviction notice) and every buy open on an explicit
click. Art ceiling 3: nothing rendered here; `tools/sync_art.py` copies the parent's
installed plates by path. Nothing sold touches `settle_grid()`.
