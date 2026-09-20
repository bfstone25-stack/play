# FOLD: After Dark — Godot 4.7

The adult night twin of `play/fold-godot` (which stays the bright, all-ages CrazyGames
game and is not touched by anything here). A derivative under
`ops/adult_forks/TWO_WORLDS.md`: same board, same 201 levels, same rules file byte for
byte — and one rule the fork turns on.

**In FOLD you fold for the satisfaction of the snap. In After Dark every tier you clear
folds one more layer off her.** The reward is a scene; the loop exists to earn it. That is
14 of Nutaku's top 100 (`ops/market/nutaku_top100.md`, merge/match-3 with scene unlocks),
and sex there is the reward for a loop in 81 of 100, not the content.

## Run it

```bash
ops/fold_after_dark_build.sh                       # web (itch) + ad track + linux/windows (+ android when the SDK is configured)
cd play/fold-after-dark-godot && python3 tests/headless_web.py   # plays all five steps in headless Chromium -> shots/
python3 -m http.server -d build/godot-ads/fold-after-dark 8765   # then open http://127.0.0.1:8765/ and play it yourself
ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path play/fold-after-dark-godot   # a desktop window, on the right monitor
```

## What is where (only what differs from the parent)

| file | what |
|---|---|
| `scripts/palette.gd` | the night palette on the parent's role table: plum-black ground, magenta, gold, coral; a heat ramp for the tiles. Every legibility target is still measured and asserted by `tests/run_tests.gd`. |
| `scripts/tiers.gd` | **the rule.** Cuts the levels into tiers (5, then 8 apiece), assigns each tier its scene, tracks cleared/open/unlocked; the streak, daily-mission and leaderboard stubs live here too. Autoload `Tier`. |
| `scripts/unlock.gd` | the server-ticket path, copied from `play/midnight-pawn-collateral-godot` (itself from Room 704's `09_dist.rpy`). The uncensored plates are export-excluded from Web and Android; the browser build fetches them from `apps.blazecore.dev` against a single-use ticket or shows nothing. Autoload `Unlock`. |
| `scripts/scene_view.gd` | the reward: the delivered plate full-bleed, her line in the one italic, her voice, a mosaic toggle (DLsite) that is off by default (Nutaku, uncensored). Draws only what `Unlock` delivered. |
| `scenes/map.gd` | the tier map: cards with progress and a locked scene teaser at the end of each; the stubs in the right column, labelled LOCAL STUB. |
| `scenes/game.gd` | the parent's board with the juice tuned for speed (animations roughly halved), auto-advance inside a tier, a streak counter, and the trophy card at the end of a tier whose one button runs gate → ticket → viewer. |
| `assets/scenes/*_locked.webp` | the parents' own teaser plates (ship in the pack). |
| `assets/plates_x/*.webp` | the uncensored plates (desktop packages only; `ops/fold_after_dark_build.sh` audits the exported .pck to prove they are absent). |
| `assets/voice/` | two of the parents' rendered lines, Mira and Adaeze. |

## The reward pool

The frozen VNs' art, which is the whole economic point: Room 704's `bed` and `window`,
Confession Room's `vee`, `adaeze`, `nikolai`, `evidence`, `evidence2`, `evidence3` —
eight scenes for the first eight tiers, delivered under the app that owns them
(`ops/gated_assets/<app>/<key>.webp`). Tiers 9–26 show a card that says PLACEHOLDER in
as many words.

## What is placeholder (2026-09-19, the first night)

* The title key visual is Room 704's plate, labelled as a stand-in on screen. After
  Dark's own is queued: `ops/render_queue.py add keyvisual plates --only fold_after_dark`.
* Scenes 9–26: no art. The card says so.
* Voice on six of the eight scenes: none yet (the two that have lines use the parents').
* Daily mission, streak-best and leaderboard: local, honest stubs. The leaderboard has one
  real row (you) and two rows that say `— stub —`.
* Android: a preset, exported when the SDK/JDK/keystore are configured; not a package
  tonight.
* The ad-track page carries the 18+ Adsterra unit (`ops/adult_ads_config.js`) and is only
  ever served on `*.flat404.workers.dev`; `ops/check_adsense_isolation.py` runs in the
  build. Not deployed.

## Tests

`./tests/run.sh` — the parent's 70 checks (the JS↔GDScript conformance replay over all
201 levels, and the palette's legibility targets against *this* palette).
`tests/headless_web.py` — the five steps, in a real browser, against the real ad-track
page; the sponsor gate in a headless run gets gate.js's QA slot (it never requests a real
ad), and the scene comes through the live gateway's ticket or does not come.
