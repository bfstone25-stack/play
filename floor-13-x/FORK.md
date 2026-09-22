# HOLDOVER — the adult fork of Floor 13: Night Shift

**Renamed by Blaze, 2026-09-21.** It was *HOLDOVER*, and a suffix tells the
shelf it is a variant of something else (`ops/STANDARD.md`, "Adult fork vs all-ages
parent"). A holdover is a tenant who stays past the lease, which is the game.

The **slug stays `floor-13-retention`** and the ad track stays `floor-13-x.flat404.workers.dev`:
both are live URLs on DLsite, Nutaku and flat404. The name is everywhere a player reads it
— the wordmark, `project.godot`, the desktop binaries (`holdover.exe`, `holdover.x86_64`),
the SEO entry, the itch copy and the forum templates.

## What makes it a different game from its parent, and not the same build with the lights down

On 2026-09-21, 20 of the 32 files the two share names for were byte-identical, including
the entire scene tree and every pixel plate. What changed:

| | Floor 13: Night Shift | HOLDOVER |
|---|---|---|
| light | 11:59 PM, fluorescent. Blue-steel shadows, cyan terminals, one red wound | the lease has run out and the floor is on emergency power. Sodium from the lift and the stairwell, magenta terminals, no blue anywhere |
| wordmark | FLOOR 13 set in Work Sans Bold over the plate | the lift's floor indicator: a dot-matrix panel with the word burning in it and the car stopped at 13, its direction arrow dead. `ops/title_logotypes.py :: holdover` |
| palette | its own | `scripts/palette.gd` + `tools/palette_holdover.py` — the parent's geometry under a different lamp |
| buttons | ShapedButton.TIMECARD | the same card, in manila against sodium rather than against blue |
| title | bright 0.27 / sat 0.36 — under the horror bucket's floor on both | bright 0.62 / sat 0.50 — clears it |

`ops/check_two_worlds.py` measured 9% shared after this pass, and the three remaining
files are font ATLASES, which are white-on-transparent masks the game tints at runtime.

Slug `floor-13-retention`. Built 2026-09-17 from the design in
[`ops/adult_forks/floor-13.md`](../../ops/adult_forks/floor-13.md), the house art rule in
[`ART_DIRECTION.md`](../../ops/adult_forks/ART_DIRECTION.md), and the real Godot source on
the GPU box (`bfs@100.121.195.19:~/floor13-src`), which is where the mainstream game lives.

**The mainstream game is untouched.** This is a copy with changes on top, the same way
`play/office-landlord-x/` was forked from `play/office-landlord/`. Nothing here is a patch
to `~/floor13-src`, and nothing here is ever submitted to a portal.

It keeps the original's form, per the form rule in `ops/adult_forks/README.md`: still
Godot 4.7, still a pixel point-and-click, still seven authored offices and a case log. It
is not a visual novel.

## What is waiting on art — and only on art

Everything else is finished, tested and playable **now**, against PIL placeholders.

| Waiting on | Where it goes | What is already in place |
|---|---|---|
| 7 plates | `assets/cg/<slot>.png`, 1152×768 | placeholder at the exact path and size |
| 5 censored plates | `assets/cg/<slot>_locked.png` | placeholder, in-fiction (white cut-out + employee number) |
| 1 withheld card | `assets/cg/cg_withheld.png` | placeholder; the fallback for a locked tier-2 slot |
| 3 IP-Adapter refs | `ops/floor13_art/ref/{june,eli,mara}.png` | prompts written, not run |
| cover + store sizes | `build/covers/`, `play/stage/assets/` | not started |

Render with the pipeline that already exists — **do not rewrite it**, its prompts are
already converted to booru tags and two of its traps cost a pass to find:

```bash
ssh -N -L 8188:127.0.0.1:8188 bfs@100.121.195.19     # in another shell
python3 ops/floor13_art/floor13_gen.py refs   --n 6  # pick one per character into ref/
python3 ops/floor13_art/floor13_gen.py plates --n 6
```

Finished renders replace the placeholders **file for file**. Nothing else changes: no code
edit, no config, no rebuild step beyond the normal one. `tools/make_placeholder_plates.py`
will not overwrite a real plate unless you pass `--force`.

## What the fork adds

**Writing** — `scripts/story_x.gd`, ~2,750 new English words, spliced into a copy of
`StoryData.AREAS` by `StoryX.patch()`. Additive only, so the base script stays diffable
against the mainstream game. Three edits could not be done that way and sit inline in
`scripts/story_data.gd`, each marked `## [fork]`: Eli's age, the drawer's two lines
establishing the unfelt-touch rule, and the quarter-inch in File 2.

Eli reads as 31 in **all five locale files** and says so out loud in the break room. The
base line had him looking twenty-two; `tests/fork_cg.gd` fails the build if it comes back.

English only. `locale.gd` is untouched; the language bar is hidden and the locale pinned to
`en`, because translating the new writing four ways is a bigger job than writing it.

**Seven CG slots**, six earned by a stance toward a person, one by the ending you land in.
`scripts/cg_gate.gd` holds the conditions as data (`EARN`) and re-checks them at
presentation, so reaching a line is not enough to open a slot. **Nothing unlocks from
playtime** — that is the house rule across every fork, and `tests/fork_cg.gd` proves it by
playing the same route twice, once skipping the optional `coat` hotspot, and asserting the
shorter run earns strictly less.

**The gate.** Free slice is Files 1–3, ending on the break-room decision, keyed
`f13r_area*` so it cannot collide with the mainstream title's unlocks on the shared origin.
On top of that, `CgGate.request_unlock()` gates each tier-3 plate, and `web/floor13x_gate.js`
adds the three-state result GDScript did not have: a missing sponsor creative is
**"unavailable"**, not "watched" — the story continues, the plate stays censored. That hole
is real in `shared/gate.js`, which resolves `"unlocked"` after its countdown whether or not
anything was served.

**Downloads carry no third-party calls.** `CgGate` returns before touching
`JavaScriptBridge` on every branch when `OS.has_feature("web")` is false, the desktop
presets exclude `web/`, and `ops/floor13x_build.sh` greps both binaries for sponsor strings
and fails the build if it finds any. An Adsterra popunder cost the studio its F95 account.

**The free packages do not contain the uncensored art.** The Web preset excludes the five
tier-3 plates, and the build script parses the exported `.pck` and refuses to ship if one
is in there. A `.pck` unzips in four lines of Python, so a flag would hide nothing.

## Build and test

```bash
# on the GPU box, where Godot 4.7 lives
rsync -a play/floor-13-x/ bfs@100.121.195.19:floor13-retention/
ssh bfs@100.121.195.19 'cd ~/floor13-retention && godot --headless --import .'

godot --headless res://tests/fork_cg.tscn      # plays four routes, asserts the hooks
xvfb-run -a godot --rendering-driver opengl3 res://tests/fork_shot.tscn   # photographs them

ops/floor13x_build.sh ~/floor13-retention '$3.99'
```

Run the tests as a **scene**, never with `--script`: `--script` starts a bare SceneTree
with no autoloads, so `Gate` and `CgGate` do not resolve and `game.gd` will not compile.
That is also why every test in the mainstream game's `tests/` has been failing since the
`Gate` autoload was introduced — reported, not fixed here.

## Content lines

Everyone is an adult and is written as one: June Park 29, Eli Song 31, Mara Vale 34.
Consensual throughout. No loli/shota, no guro, no NTR, no sexual violence. Supervisor Rusk
stays a voice on tape and is never sexualised — he is the wage thief, and making him a
seducer would turn a story about theft into a story about a man. The Auditor never touches
anyone and never shares a frame with any of it.

Prompts stop at tier 3. The explicit tier-4 variants are Blaze's own and are not in this
directory or in `ops/floor13_art/`.
