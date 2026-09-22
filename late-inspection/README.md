# Late Inspection: Flat 404（深夜验房：404室）

Standalone **3D Horror VN** (Godot 4.7). A complete six-zone episode with four decisions and three authored endings.

See [`PRODUCT_BIBLE.md`](PRODUCT_BIBLE.md) for the executable screenplay, state map, cues, and acceptance criteria.

## Run

```bash
/tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection
```

Smoke (xvfb):

```bash
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path late-inspection --import --headless
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path late-inspection -s res://tests/smoke.gd
```

## Controls

- WASD + mouse look
- E / click — interact, then advance the bottom ADV bar
- Esc — pause/resume and release/capture mouse
- Choices sit above the ADV bar — click or press A / B
- Diary / breakdown / endings use full-screen NVL (red filter + shake)
- R — restart after an ending

Progression verification:

```bash
godot --headless --path late-inspection -s res://tests/progression.gd
```

Interaction cone (needs a display — it photographs what it measures):

```bash
"$GODOT" --path late-inspection --resolution 1280x720 -s res://tests/facing_probe.gd
"$GODOT" --path late-inspection --resolution 1280x720 -s res://tests/facing_probe.gd -- --shots
```

`interact_target()`'s 6.5 m fallback asks whether the player is facing the prop. That gate
had been stubbed to `true`, so props could be taken from behind. `FACE_DOT` is 0.80 — a
36.9 degree half-angle, which puts a prop entering the cone 60% of the way to the edge of
the picture. The probe measures that mapping in the running game, checks every prop from
in front, from behind and from underfoot, and prints `FACING_OK`.

## Audits — run these after any translation, font or story edit

```bash
python3 tools/lang_audit.py --verbose    # is each story file written in its own language?
python3 tools/font_audit.py  --verbose   # does the bundled atlas have every glyph they need?
```

Both were added 2026-09-21 and both currently pass: all five locales are 100% in-language
across story prose AND the locale.gd UI tables (165/165 strings each, 29/29 prop keys), and
the 1924-glyph atlas covers every character all five need. That is worth stating because
the studio has shipped the opposite three times — Floor 13's ja/ko/es story files held
Chinese prose, and Beat the Monday's atlas carried 342 glyphs against the 696 its scripts
use, so Chinese rendered as tofu from the day it was written.

The language oracle is imported by path from `../floor-13/tools/lang_audit.py` rather than
re-implemented: its first version used a hand-typed "simplified-only" blacklist containing
机 着 当 数 — ordinary Japanese kanji — and reported 92 correct Japanese lines as Chinese.
EUC-JP encodability is the oracle now.

## Tests

```bash
"$GODOT" --headless --path . -s res://tests/smoke.gd          # SMOKE_OK
"$GODOT" --headless --path . -s res://tests/progression.gd    # PROGRESSION_OK
"$GODOT" --headless --path . -s res://tests/stage_walk.gd     # 13 distinct stages, both routes
"$GODOT" --headless --path . -s res://tests/bark_moments.gd   # BARK_MOMENTS_OK slots=9
"$GODOT" --headless --path . -s res://tests/content_audit.gd  # CONTENT_AUDIT_OK
"$GODOT" --headless --path . -s res://tests/locale_scan.gd    # LOCALE_SCAN_OK
```

`tests/choice_smoke.gd` and `tests/document_smoke.gd` **hang** and have done since before
the title-screen pass; the note at the top of `choice_smoke.gd` documents it. Do not read
a green suite as covering them.

`stage_walk.gd` exists because `progression.gd` did not prove what it looked like it
proved. Its routes go through `debug_complete_route()`, which sets the four ending flags
and calls `_finish()` directly — it never calls `_advance()` or `_spawn_stage()`, so it
reaches an ending without entering a single room. `stage_walk.gd` drives the authored
sequence itself (every `on_note`, every `_resolve_choice`, in order) and asserts that each
stage both advanced AND spawned props, which is the thing `ops/play_matrix.py` measures
visually.

`bark_moments.gd` replaces the ambience node's `bark()` with a recorder and asserts which
slots fire, because the bark layer no-ops until `assets/voice/barks.json` exists — so
"no error" would be identical for a game that never speaks. It also loads every script with
`CACHE_MODE_IGNORE` and requires a non-empty method list, because `load()` returns the
cached husk of a script whose reload failed and a suite can pass on a dead script.

## Not this repo folder

Legacy H5 Crazy Rant remains under `../crazy-rant/` as a stub pointer only.
