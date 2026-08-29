# itch.io page kit — Late Inspection: Flat 404

**Live:** https://bfstone25-stack.itch.io/late-inspection
Game id `4951380`. Butler channels `html5` (free slice) + `windows` / `linux` / `macos` (paid full).
Replaces the old **Crazy Rant** page (`crazy-rant`, id 4922055 — retired to *restricted*).

## Store model

- **Paid** project mode, min price **$2.99**, suggested **$4.99**.
- **Free browser slice** — the `html5` embed is the Web Slice export
  (`custom_features="slice"`): Chapters I–II plus entering Flat 404 and reading
  the checklist, then an authored slice-complete card. Gate: `_advance()` in
  `scripts/game.gd` stops at `SLICE_LAST_STAGE = 2`; test `tests/slice_gate.gd`.
- **Paid download** — full seven-chapter episode (three endings) as desktop
  builds. The embed stays free forever; the slice never unlocks chapter III+.

## Pricing rationale (researched 2026-08-29)

Comparable itch pricing for short first-person horror:
- Fears to Fathom ep.2 (Norwood Hitchhike, ~1 h): **$2.99**
- Fears to Fathom ep.4/5 (longer, higher production): $5.99 / $9.99
- Ossa (surreal psychological horror, short): **$2.99**
- Typical sub-20-minute horror: $0–2.99
- This account's own paid tier: Tell / SilverTongue at $2.99, GHOST CHANNEL $1.99

Flat 404 is a polished 25–35 minute episode with three authored endings and
five languages — squarely in the $2.99 bracket. $2.99 matches the strongest
direct comparables and the account tier; $1 would undersell the production,
$4.99+ is for longer episodes. Suggested $4.99 gives supporters headroom.

## Packaging

- **Title:** Late Inspection: Flat 404 · **Genre:** Visual Novel
- **Short:** Flat 404 is not vacant — the checklist knows. First-person horror VN · 7 chapters · 3 endings.
- **Tags:** horror, psychological-horror, 3d, first-person, visual-novel, atmospheric, multiple-endings, short, supernatural, mystery
- **AI disclosure:** yes — text, code, listing graphics (audio is synthesized in code)
- **Embed:** 1280×720 frame, fullscreen on, mobile off (mouse-look FP)
- **Languages:** EN / ZH / JA / ES / KO (in-game picker; single-locale UI)
- **Cover/screenshots/embed BG:** composed from in-game captures
  (`tests/itch_shots.gd`, xvfb on blazeubuntu). Theme: bg `#0d0f0a`,
  bg2 `#171a12`, text `#e3e0d2`, link `#8aa65e`, Lato large.

## Re-publishing after changes

```
# builds (on blazeubuntu, godot 4.7.2 + export templates)
godot --headless --path . --export-release "Web Slice"   # needs build/web-slice/
godot --headless --path . --export-release "Web"         # full (optional download)
godot --headless --path . --export-release "Windows"     # etc. Linux / macOS

# push (cloud VM or blazeubuntu; key lives on pop-os ~/.config/itch/api-key)
butler push late-inspection-html5.zip   bfstone25-stack/late-inspection:html5   --userversion X.Y.Z
butler push late-inspection-windows.zip bfstone25-stack/late-inspection:windows --userversion X.Y.Z
butler push late-inspection-linux.zip   bfstone25-stack/late-inspection:linux   --userversion X.Y.Z
butler push late-inspection-macos.zip   bfstone25-stack/late-inspection:macos   --userversion X.Y.Z
```

Page edits: `tools/itch/page_apply.py` on pop-os (Firefox cookie hop, keeps
`itchio_token` from GET). Subcommands: `apply` (full metadata incl. AI
disclosure + embed options), `cover`, `screenshots`, `embedbg` + `theme`
(layout[...] form POST — send the FULL field set, the endpoint resets
omissions to defaults), `state`, `themestate`, `retire`.

Pitfalls learned:
- Theme endpoint: `theme=` JSON save accepts the payload but silently keeps
  colors — use `layout[...]` form fields for colors/fonts/embed BG.
- Colors need `#` prefixes or the server rejects them ("must be a color").
- The edit endpoint validates the whole game per POST — always send complete
  fields (`page_apply.py full_fields*` do this).
- itch rate-limits aggressively (429) — space out writes, expect retries.
