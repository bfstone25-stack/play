# itch.io page kit — Floor 13: Night Shift

**Live:** https://bfstone25-stack.itch.io/floor-13
Game id `4951384`. Butler channels `html5` (free slice) + `windows` / `linux` / `macos` (paid full).
Replaces the old **Beat Monday** page (`beat-monday`, id 4922058 — retired to *restricted*).

## Store model

- **Paid** project mode, min price **$2.99**, suggested **$4.99**.
- **Free browser slice** — the `html5` embed is the Web Slice export
  (`custom_features="slice"`): Files 1–2 of 7 (June's cubicle + the open
  office), ending at the elevator lobby with a slice-complete card.
  Gate: `_on_route()` in `scripts/game.gd` stops at `SLICE_LAST_AREA = 1`;
  test `tests/slice_gate.gd`.
- **Paid download** — the full seven-file night shift (four choices, three
  endings) as desktop builds.

## Pricing rationale (researched 2026-08-29)

Comparable itch pricing for short pixel horror narratives:
- Midnight Scenes episodes (pixel horror shorts): **$3.99**
- Story-rich pixel horror on itch clusters at $3–10 for longer titles;
  polished shorts sit at $2–4
- Account tier: Tell / SilverTongue $2.99
- Yuppie Psycho-likes are AA-priced on Steam; itch shorts are far cheaper

Floor 13 is a 25–35 minute point-click narrative with 28 hotspots, four
persistent choices, three endings, and five languages. $2.99 undercuts
Midnight Scenes slightly as a new IP while matching the account's paid tier.
$1 would signal jam-grade; $3.99 is defensible but slower out of the gate.

## Packaging

- **Title:** Floor 13: Night Shift · **Genre:** Adventure (point-and-click)
- **Short:** The directory skips thirteen. The PA says otherwise. Point-click office horror · 3 endings.
- **Tags:** horror, pixel-art, point-and-click, atmospheric, psychological-horror, mystery, multiple-endings, short, 2d, supernatural
- **AI disclosure:** yes — text, code, listing graphics
- **Embed:** 1280×720 frame, fullscreen on, mobile friendly (pure mouse/touch)
- **Languages:** EN / ZH / JA / ES / KO
- **Media:** `tests/itch_shots.gd` area tour (7 areas + choice + NVL + ending).
  Theme: bg `#0c141f`, bg2 `#131e2c`, text `#d7e3ea`, link `#d64d55`,
  pixel (04b_03) large.

## Re-publishing

Same pipeline as `late-inspection/ITCH.md` (builds on blazeubuntu, butler
channels, `tools/itch/page_apply.py` on pop-os). Presets: `Web Slice`,
`Web`, `Windows`, `Linux`, `macOS` — create `build/<target>/` dirs first.
