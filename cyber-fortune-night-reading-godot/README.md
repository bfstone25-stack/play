# 夜读 / CYBER FORTUNE: NIGHT READING — Godot 4.7, 18+

The adult fork of `play/cyber-fortune-godot` (赛博求签 / Cyber Fortune). Design:
`ops/adult_forks/cyber_fortune_night_reading.md`, under `ops/adult_forks/TWO_WORLDS.md` —
copied from the parent, then diverged. The mainstream tree is not touched by anything here.

## The rule, in one sentence

> **By day you read people. After dark, what you read becomes true: the card you turn for
> her is the one she starts living.**

The divination is the mechanism, not the wrapping. The scene is the reward for the loop.
Cut the scenes and the loop has no terminal state — which is what TWO_WORLDS means by
*necessary*.

## Run

```
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import          # once, and after any new or replaced file
$GODOT --path .                              # desktop  (NOT on the work box: ops/on_game_monitor.sh)
bash tests/run.sh                            # 217 headless checks; fails on any engine error
ops/cyber_fortune_night_build.sh             # pools + web/linux/windows + the ad track
python3 tests/headless_web.py                # drives the real web build in headless Chromium -> shots/
python3 tests/headless_web.py --ads          # the same, against the ad track
python3 -m http.server -d ../../build/godot-ads/cyber-fortune-night-reading 8765
```

## What is playable

| | |
|---|---|
| **The table** | Three women, one at a time; each one's three tracks are three bars on her card, so her whole state is visible before you open her. |
| **A reading** | Choose the instrument — the tube, the deck, or mentalism — and draw. The rank comes off the parent's ladder (`scripts/fortune.gd`: 大吉…大凶, the pity force, the free daily draw, the merit cost); the slip's subject / the card's position / the force names **one of her three tracks**, and the rank gives it a strength: +3 / +2 / +1 / 0 / −1 / −2. |
| **She answers** | The consent gate. She takes a reading that opens something, or one she is already partway into. Otherwise she says no in her own words, the draw is spent, **nothing is written and the refusal is not remembered**. |
| **True now** | A track at 3 locks and she says it back. Three tracks at 3 and the night is hers to offer. |
| **The night** | The payoff, behind `Gate.require` — an ad that actually rendered a creative, or a purchase. No creative, no unlock; a refusal is not remembered, so the next press asks the page again. Three beats and a closing line. |
| **Clear** | Three women, three nights, then the adult board. |
| **Shared with the parent** | The whole machine: merit, the six-rank ladder with pity, the free draw, the collection, `user://` persistence only, no backend, zh-Hans / en. |

## Layout

| | |
|---|---|
| `scripts/night.gd` | **Night** autoload — the rule: the track a draw names, the strength, the consent gate, the lock, the scene, the save |
| `scripts/night_home_screen.gd` | the table: the three women and their nine tracks |
| `scripts/night_read_screen.gd` | the reading: instrument, draw, what was drawn, her answer |
| `scripts/night_scene_screen.gd` | the night, and the gate in front of it |
| `scripts/fortune.gd` | the parent's machine, unchanged except its save path |
| `scripts/palette.gd` | the parent's two rooms plus the night skin (UI_DIRECTION: dark ground, hot accents) |
| `tools/pool_night.py` | the cast, their tracks and every line they say; `build_pool.py` emits `pool/night.json` |
| `tools/make_placeholders.py` | the labelled placeholder plates and `assets/night/placeholders.json` |
| `tools/install_night.py` | install a rendered plate over a placeholder (`--list` shows what is real) |
| `ops/night_reading_art/night_gen.py` | the art: three casting refs, then four plates each plus the title |

## Measured

| | |
|---|---|
| `tests/run.sh` | **217 checks, 0 failed** — the ladder, the daily draw, the consent gate, a refusal writing nothing, the lock at 3, the scene at 9, the JSON round-trip, and that every art slot the game asks for exists |
| `tests/headless_web.py` | drives the real web export through the table → a reading → a refusal → all nine → the gate refused → the gate completed → the three beats → clear → reload |
| `ops/check_adsense_isolation.py` | green, run inside the build |
| `ops/check_two_worlds.py` | 0/13 of the fork's images are the parent's bytes |
| `ops/check_art_ceiling.py` | green on `ops/night_reading_art/night_gen.py` |
| brightness, in-game (`--scene`, floor 0.22) | the table 0.23/0.48, her room 0.35/0.37, a reading drawn 0.31/0.35 — all read |
| brightness, the shelf (floor 0.45/0.30) | the title screen is **0.23/0.48**, under the floor, because its key visual is still a placeholder. The home screen already uses `title_kv` as its ground the moment that slot is real |

## Honest list — what is a placeholder

Every art slot in this build is a **labelled placeholder**: a hatched plum frame with
`PLACEHOLDER`, the slot name and its tier written on its face. Nothing in this game can
display an unlabelled fake. `python3 tools/install_night.py --list` is the live list;
`assets/night/placeholders.json` is what both the game and that list read.

Also not done, and stated rather than hidden:

- **Mentalism is an instrument, not yet a performance.** The parent's four forces
  (`scripts/reader.gd`, ported and tested) are not staged here — choosing mentalism draws
  on the same ladder and picks the track by which force she sat through. The four scenes
  from the parent's reader screen have not been rewritten for this side of the table.
- **Every plate ships inside the `.pck`.** `Gate` gates what the game *displays*, not what
  the package contains. That is acceptable while every tier-3 slot is a placeholder, and
  the build script fails if a real tier-3 plate appears without the export-exclude +
  single-use-ticket model (`play/fold-after-dark-godot/scripts/unlock.gd`) being wired first.
- **One night per woman.** Nine tracks is the whole climb; there is no second night, no
  festival rack, and no shop on this side.
- **The pools are the parent's.** 150 slips and 78 cards are the day game's text, reused
  as the text of the draw. The fork's own writing is the cast, their tracks and the scenes.
