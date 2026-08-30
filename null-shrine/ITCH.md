# itch.io page kit — Midnight Pawn & Crypt

**Live:** https://bfstone25-stack.itch.io/midnight-pawn
Game id `4951385`. Butler channels `html5` (free slice) + `windows` / `linux` / `macos` (paid full).
Replaces the old **NULL//SHRINE** page (`null-shrine`, id 4922023 — retired to *restricted*).

## Store model

- **Paid** project mode, min price **$1.99**, suggested **$2.99**.
- **Free browser slice** — the `html5` embed is the Web Slice export
  (`custom_features="slice"`): the tutorial sale, Day 1 customers, and the
  full Night 1 descent (both crypt rooms + extraction), then a
  slice-complete screen. Gate: every transition into Day 2 in
  `scripts/game.gd` routes to `_show_slice_end()`; test `tests/slice_gate.gd`.
- **Paid download** — the complete two-day run (Day 2, Night 2 elite rooms,
  final appraisal, three endings, score ranks) as desktop builds.

## Pricing rationale (researched 2026-08-29)

Comparable itch pricing for shop+dungeon micro-loops:
- Moonlighter-likes on itch are mostly free jam builds; paid comparables are
  scarce at this scope
- The account's shorter paid title GHOST CHANNEL sits at **$1.99**
- Longer narrative titles on the account: $2.99

Midnight Pawn is a tighter 15–20 minute deterministic run — shorter than the
two horror narratives, but systemic and replayable (score ranks S–D, three
endings, build synergies). $1.99 matches the account's short-form tier and
the run length; the mission's "don't default to $1" holds — $1.99 is
evidence-anchored, not a default. Suggested $2.99 for supporters.

## Packaging

- **Title:** Midnight Pawn & Crypt · **Genre:** Role Playing
- **Short:** Every object has two prices: the living's and the dead's. Pixel pawn-shop RPG · 3 endings.
- **Tags:** pixel-art, management, dungeon-crawler, rpg, horror, atmospheric, multiple-endings, short, 2d, dark-fantasy
- **AI disclosure:** yes — text, code, listing graphics
- **Embed:** 1280×720 frame, fullscreen on, mobile friendly (mouse/touch/keyboard)
- **Languages:** EN / ZH / JA / ES / KO
- **Media:** `tests/visual_walkthrough.gd -- --locale=en` (13 shots).
  Theme: bg `#100d18`, bg2 `#201928`, text `#f1dfb0`, link `#e8b84a`,
  pixel (04b_03) large.

## Re-publishing

Same pipeline as `late-inspection/ITCH.md`. NOTE: the title tag must not say
"free" — the run is the paid download; only the browser slice is free.
