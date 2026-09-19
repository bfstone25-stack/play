# BEAT THE MONDAY — Godot 4.7

A work week as a **map of the building**, with nodes that ask different things of the
player (ops/adult_forks/beat_monday_map.md, 2026-09-18). The first Godot build's
survivor-like day is now one node type among seven; the building is the campaign.

| node | floor | play | engine |
|---|---|---|---|
| lobby | ground | where the week starts | — |
| break room | ground | equip · recruit · spend · save | the desk + coffee credits |
| **standup** | 1 | reflex: drag, auto-attack, invites and pings close in | `bm_core.gd` (DAYS[0]) |
| corridor | 1, 3 | one screen, one choice, one consequence | `bm_events.gd` |
| **inbox** | 2 | thinking: triage — a hand of 5 messages, 3 actions a turn, clear the desk before the clock | `bm_triage.gd` |
| **all-hands** | 2 | reflex: the rant level, phrases as projectiles | `bm_core.gd` (DAYS[2]) |
| **review** | 3 | thinking: dialogue tactics — a hand of lines against the manager's RULES row; the sequence wins | `bm_persuasion.gd` (SilverTongue `advance()`, ported) + `bm_review.gd` |
| **deploy** | 3 | both: place colleagues and gear on the server-room floor, then survive the boss | `bm_deploy.gd` + `bm_core.gd` (DAYS[4]) |

The graph (`bm_map.gd`): lobby → standup → {inbox | all-hands} → review → deploy. A player
bad at reflex routes through the inbox; one who hates menus goes through the all-hands.
Cleared rooms can be run again (XP, drops, a better result); the walk is back-and-forth
along the corridors and the lift. Friday rolls the week through the ported
`BMCore.commit_run`, the weekend screen leads to a fresh map, and Week 2 is harder the
way it always was.

**Progression is the ported one, untouched.** Thinking nodes commit through a pseudo-run
(`BMMap.commit_thinking`) so Tuesday's headphones and Morgan still arrive from the inbox,
Thursday's chair and Pat from the review; the JS↔GDScript conformance test over the reflex
core stays green (66 checks, bit-identical counts).

## Run

```
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import          # once, and after new files
$GODOT --path .                              # desktop, portrait 420x640
bash tests/run.sh                            # 196 checks, see below
./build.sh                                   # web + linux + windows -> ../../build/godot/beat-monday/
python3 tests/headless_web.py                # drives the web build across the whole route, screenshots -> shots/
```

## Tests (`tests/run.sh`, fails on any engine error)

- **units + a whole headless week + JS↔GDScript conformance** of the reflex core over
  `tests/conformance.json` (`node tests/conformance_gen.cjs`) — as before.
- **scene scripts compile**: main.gd, map_screen.gd, arena.gd, hud.gd are loaded so a
  parse error fails the run.
- **map graph invariants**: edges and requirements reference real nodes, every node
  reachable from the lobby once all is cleared, a fresh week opens only the lobby's
  neighbours, the branch exists, every DAYS row is owned by exactly one node, deploy needs
  the review; unlock logic, BFS paths both directions, JSON round-trip, the week reset,
  commit-through-progression, the XP-only grant.
- **triage rules**: hand of 5, 3 actions, seeded determinism, costs, refusals, snooze
  once and free, escalation (an ignored pager: +16 stress, cost capped at 3), sticky
  archive comes back angrier, delegate needs a colleague, the three endings, a greedy
  autoplayer smoke (wins ≥ 10/20 week-1 desks).
- **review engine conformance**: `tests/persuasion_conformance_gen.py` runs the real
  `play/silvertongue-x/backend/persuasion_engine.py` `advance()` over 420 seeded
  conversations (1714 calls: every cards.py line, the review's own 28 lines, zh/ja/es
  needles, ARIA arithmetic, genie constraints, random pastes, every RULES row + the default
  rule, every difficulty) into `tests/persuasion_conformance.json`; `run_tests.gd` replays
  them through `bm_persuasion.gd` and asserts phase, momentum, evidence, harms, last_move
  (signals, harms, clauses), cg, eligible, expert and turns are identical. **1714/1714.**
  Plus cards.py's rule: every review card face equals `decompose()` of its line.
- **review node**: the hand, the winning sequence at silver (evidence → ask → precision),
  coercion is permanent, the turn budget, the engine's cg keys pass through untouched
  (for the twin).
- **deploy + corridor**: placement validation, turret kills, chair heal capped, headphone
  push-back, nothing applies once a run is over; the event picks, persists per week,
  clears the node, its hp modifier is consumed once.

## Layout

| | |
|---|---|
| `scripts/bm_data.gd`, `bm_core.gd`, `bm_phrases.gd` | the reflex core — every number, the loop, the corpus (ported, unchanged) |
| `scripts/bm_map.gd` | the building: NODES, EDGES, unlock, BFS path, the profile's `map` slice, commit-through-progression |
| `scripts/bm_triage.gd` | the inbox: KINDS, WEEKS, act()/end_turn(), the greedy autoplayer |
| `scripts/bm_persuasion.gd` | `persuasion_engine.py` ported: COMMON, NEGATIVE, RULES, decompose(), advance(), plate() |
| `scripts/bm_review.gd` | the review: CARDS (line + declared face), the hand, play(), the manager's reply key, progress for the HUD |
| `scripts/bm_deploy.gd` | six tiles, what can go where, turrets and auras applied after the core's step |
| `scripts/bm_events.gd` | the corridor events and their consequences (xp, credits, next run's HP) |
| `scripts/map_screen.gd` | the map as a place: sky + building plates, room windows cut from each room's plate, PointLight2D per open room and on the walker, the walk tween along floors and the lift shaft, parallax on climb |
| `scripts/main.gd` | screens (title, map, node brief, triage, review, placement, event, break room, weekend, desk, level-up, result), the loop wiring, the web dev bridge |
| `scripts/arena.gd`, `hud.gd`, `sprites.gd` | the reflex day; `Sprites.actor()` draws a rendered sprite when `assets/art/sprite_<id>.webp` exists, the vector rigs remain as the fallback |
| `scripts/strings.gd` | UI copy, en + zh-Hans, every node |
| `assets/art/plate_*.webp` | rendered plates: the five days, title, Saturday, and the map's sky, building, lobby, corridor, break room |
| `assets/art/sprite_*.webp` | rendered actors: player, intern, pm, hr, and the five bosses — `ops/beat_monday_art/beat_monday_gen.py sprites` + `pick` (white ground keyed out with a border-connected label) |

## Art: rendered vs vector

Rendered (Animagine XL 4 through `ops/render_queue.py add beat_monday {plates,sprites} --host remote`):
every plate the map and the nodes play on; the player, the three colleagues, the five
bosses. Vector (unchanged from the first build, acceptable for this pass): the small
enemies (pings, invites, threads, cc, metrics, pagers), shots, phrase projectiles, the
skill and equipment icons, the desk screen, the HUD bars. The map itself draws no shapes:
plates, plate cuts, sprites, Theme panels, Labels and lights only. The one faint code-drawn
thing on a node plate is the translucent tile disc under a placed colleague on the deploy
day.

Known: the `map_building` plate rendered as a stairwell atrium (a place, not a cutaway
section); a `map_section` v2 slot with its own negative is in the generator for the next
pass. The map's rooms are windows cut from the rooms' own plates, so the building reads as
those rooms stacked either way.

## Rules kept

No popups, no redirects: the board (`Gate.board_offer_more("casual")`, once per session,
behind a 0.9 s timer after a result) and every screen change is an explicit tap. SFW.
Telemetry is the page SDK stamped in by `ops/godot_build.sh`. **Balance is untuned**: the
triage and review numbers, the auras, the credits and the event effects are first values,
not a difficulty — the autopilot clears the week, which is a number.

The night twin (ops/adult_forks/TWO_WORLDS.md) is a later step: node ids, the RULES row
the review points at (`BMReview.SCENARIOS`), the plate per node (`main.gd NODE_PLATE`) and
the engine's `cg` keys are the seams it re-means.
