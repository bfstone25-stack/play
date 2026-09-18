# Overnight Clause

The 18+ fork of **Late Inspection: Flat 404** (Godot 4.7, first-person horror VN).
Design: [`ops/adult_forks/late-inspection.md`](../../ops/adult_forks/late-inspection.md).
House art rule: [`ops/adult_forks/ART_DIRECTION.md`](../../ops/adult_forks/ART_DIRECTION.md).
The base game's screenplay and state map are still [`PRODUCT_BIBLE.md`](PRODUCT_BIBLE.md);
this fork adds to it and changes none of its flags.

Separate project, separate slug, no shared store page and no crosslink from the portal
builds of the mainstream title (CrazyGames / Poki / GameDistribution / Newgrounds).

## What the fork adds

- **~5,600 words of new writing**, English only (`scripts/overnight_script.gd`, plus the
  fork's own evidence in `scripts/overnight.gd`). The base game's five locales are deleted
  rather than half-maintained: carrying 5,600 words through them turns three weeks into
  three months.
- **Dane Orlov on screen** — 403's tenant stops being a voice under a door.
- **Seven plates** (`scripts/plates.gd`), each hung on a flag write that already ran in
  the base game. Two are gated.
- **Flat 403** as a re-dress of the 404 geometry (`world_builder.gd: _build_403`).
- `SLICE_LAST_STAGE` 2 → 5, which lands the free/paid cut exactly one beat before the
  first gated plate.

## Iris

Iris Vale is a voice, a name, and — once, in `cg_witness` — a wet-coat silhouette behind
plastic with no facial features, exactly as the bible specifies her. She is not a body in
this fork anywhere. The adult content is Mara Venn (33) and Dane Orlov (34), both adults,
both choosing it, in two scenes reached by trusting the tenant rather than the manager.
Sexualising the woman the story is about erasing would land next to the non-consent line
the brief rules out, and would wreck the source's best idea.

## Plates and the gate

| plate | earned by | ships |
|---|---|---|
| `cg_mirror` | either branch of the stain choice (`game.gd:393/396`) | open |
| `cg_hatch` | `pipe_answered` (`game.gd:401`) | **gated** |
| `cg_cavity` | `iris_record`, the cassette (`game.gd:364`) | open, never censored |
| `cg_renewal` | `clause_signed` (`game.gd:409`) | open |
| `cg_403` | `clause_refused` + `pipe_answered` + `dane_note` (`:412`, `:401`, `:334`) | **gated** |
| `cg_witness` / `cg_complicit` / `cg_404` | resolver output (`game.gd:453`) | open |

Gating copies `play/room-704/game/scripts/09_dist.rpy`: **the uncensored bytes are not in
the free package at all.** `assets/plates_x/` is excluded from both Web presets in
`export_presets.cfg`; the free build ships the `_locked` plates, and the real files arrive
from `apps.blazecore.dev/unlock/fetch` against a single-use ticket and land in
`user://unlocked/`. Editing a flag reveals nothing, because there is nothing there to
reveal. The desktop download carries the files in its own package and therefore makes no
network call at all.

Only two of seven are gated, on purpose: `09_dist.rpy:22-25` records that a wider gate
promised something it never delivered across 75 browser plays and zero purchase clicks.

## Art status

Every plate in `assets/plates/` and `assets/plates_x/` is a **PIL placeholder card**, not a
render — the 3060 is serial and busy. Prompts are written and are booru tags already:
`ops/late_inspection_art/late_inspection_gen.py` (`refs` first, then `plates`).
`ops/late_inspection_art/make_placeholders.py` regenerates the placeholders; the real
renders overwrite them by filename and nothing in the game changes.

## Run

```bash
GODOT=.../Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import
for t in smoke progression plates playthrough choice_smoke slice_gate content_audit \
         document_smoke vn_chrome font_pipeline; do
  $GODOT --headless --path . --script tests/$t.gd
done
```

`tests/playthrough.gd` walks the whole Witness route twice — once as a free package with
both gated plates censored, once after delivering the unlock bytes — and is the test that
proves the gate has two real sides.
