# Elena: Crimson Archives — RPG (Godot 4.7)

The Elena VN rebuilt as an exploration + standoff RPG on the shared core
`play/night-rpg-core/addons/night_rpg` (symlinked here as `addons/night_rpg`).
Design: `ops/rpg_conversion/DESIGN.md`. Nothing here has been uploaded anywhere.

## What it is

Five nights = the VN's five chapters. Each night: a turn budget shown as a clock to dawn,
painted rooms with hotspots (search spots, doors, locked doors, events), standoffs, a boss,
then the chapter's story beats. All VN text is kept — say lines are referenced by source line
(`data/story/chN.json`, ported with their Japanese translation and voice files), so the
writing, the three routes (control / pact / walk away) and the three endings (The Record /
Daylight / The Sea) are the VN's own. New RPG text (rooms, standoffs, barks) is in
`tools/strings_*.py`, EN + JA.

| | count |
|---|---|
| nights | 5 (all playable end to end; every route and ending reached by the sim) |
| rooms | 20 explorable (study, vault, porter's lodge, entrance hall, Blackwood stair, lower stacks, coal store, loading dock, main hall, map room, bell tower stair, bell chamber, common room, Dean's corridor, annex, bindery, conservation lab, Dean's file room, Elena's carrel, muniment room) + the roof leads at dawn |
| standoffs | 17 standard + 5 bosses (Dean at dawn, Crane, Penhallow, the Dean at tea, Penhallow in the strongroom) |
| systems | level/XP (cap 20), 4 stats (Wit/Charm/Grit/Stealth), two skill branches per character (Scholar/Rogue, Archivist/Accomplice), 3 equipment slots, consumables, keys, evidence, gifts, Trust 0–10 with scenes at 3/5/7/9, 6 save slots + autosave, gallery, settings, map |
| languages | EN and JA complete (UI, VN text, RPG text, voice per language); DE/FR/ES/ZH/KO columns wired with EN fallback, settings shows each one's coverage |
| play time (sim) | nights 41 / 33 / 29 / 29 / 26 min ≈ 2.6 h for one route at measured pacing |

**Standoff rules** (`addons/night_rpg/rules.gd`, port of SUASION's duel): Composure (HP),
Nerve (MP), the enemy's Resolve and Suspicion (100 = they call the Dean = loss). Actions:
Deflect, Read the room (Elena; reveals weaknesses), Bluff, Show evidence, Bribe, Flirt,
Threaten, Stall, Use item, plus skill-granted Lecture / Recite in Latin. Weak ×1.75,
resist ×0.5 and +8 suspicion. Threaten is SUASION's coercion trap: it hits hard and marks the
standoff, +5 suspicion every enemy turn after, for good. A loss reloads the autosave taken
just before the hotspot — never more than a few minutes back.

## Run

    GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    python3 tools/import_art.py      # copies the VN art/audio/fonts into assets/ (gitignored) + cuts placeholder plates
    python3 tools/import_story.py    # VN chapter text + JA + voice -> data/story/, assets/voice/
    $GODOT --path play/elena-rpg-godot                     # play
    $GODOT --path play/elena-rpg-godot -- --trial          # play the trial

Rebuild data after editing: `tools/build_data.py` (rules tables, art manifest),
`tools/build_strings.py` (strings), `tools/build_nights.py` (nights 2–5; night 1 is
`data/nights/night1.json`, hand-written).

## Verify

    tools/verify_all.sh      # everything headless below, in one go (rc=0 last run)
    MIN_SHOTS=0 tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke   # real mouse clicks under Xvfb: title -> study -> hotspot -> door -> standoff -> level-up -> save/load
    python3 tools/check_data.py   # every key, speaker, story range, enemy, item, door, bark and JA string resolves

    $GODOT --headless --path play/night-rpg-core -s tests/rules_test.gd              # rules unit checks
    $GODOT --headless --path . res://tests/sim.tscn -- --nights=night1 --runs=10     # balance + pacing
    $GODOT --headless --path . res://tests/sim.tscn -- --nights=night1,night2,night3,night4,night5 --runs=2 \
        "--prefer=hand over hers|Every name goes back" --expect=route_pact,ending_rewrite   # route/ending coverage
    $GODOT --headless --path . res://tests/sim.tscn -- --nights=night1 --policy=reckless   # must FAIL (proves the check can)
    tools/remote_shots.sh res://tests/shots.tscn shots/latest   # screenshots on the RTX 3060 under Xvfb, Vulkan forced

The sim plays the real game code (`main.gd` in auto mode) with `NRPolicy`, a "normal
player" that knows only what a player can see (weaknesses it has revealed, the meters, its
items) and an explorer that does every reachable hotspot. Pacing: voice clip length or
16 chars/s reading per line, 12 s per party action, 4 s per enemy turn, 8 s per choice,
20 s per level-up. Last results: all five nights cleared with no loss on all three
route/ending paths; Night 1 40–41 min; the reckless policy loses every run.

## Package (DLsite)

    tools/package.sh 1.0.0    # -> build/dist/elena-crimson-archives-rpg[-trial]-v1.0.0-{pc,mac}.zip + SHA256SUMS.txt

`-pc.zip` holds the Windows .exe and the Linux binary plus one shared .pck, like the VN's pc zip;
`-mac.zip` holds the universal .app (ad-hoc signed, not notarized). Sizes: full pc 167 MB / mac
163 MB, trial pc 113 MB / mac 109 MB. The trial .pck contains no data, voice or CG from
nights 2–5 and no unblurred climax CG (checked by listing the pck's imported files). Both
exported Linux builds were booted on the RTX 3060 under Xvfb (`shots/exported/*_boot.png`). No dist.txt. The trial is
the same game with the `trial` feature: Night 1 to the dawn boss, the two climax CGs
blurred (as the VN trial does), then a bilingual JA/EN end screen with the product link.
The AI disclosure (text from `ops/dlsite/elena_product_page*.md`) is shown at every launch
and from the title's "About this work".

## Art

All 52 rendered RPG assets from `ops/elena_art/out/rpg/manifest.json` are in the game:
20 room plates + the painted floor map, 8 enemies in neutral and pressured poses (the
pressured pose shows under half Resolve or Suspicion 60+), Elena's 5 outfits (research is
her default; raincoat/gown/evening/nightwear are equipment that changes her sprite), and 10
new CGs (6 story, 4 Trust scenes at 3/5/7/9). `tools/build_data.py` fails if a manifest
asset is not referenced; `tools/check_data.py` fails if a room plate is unused or still on
placeholder art. `tools/import_art.py` also heals rembg mattes (enclosed holes, a
convex-hull repair on the shredded coat edge of `enemy_deans_man_a_pressured`, and a
black-background remnant in `outfit_gown`).

Still from the VN by design: the study plate (a rendered VN background), Cobb's and
Penhallow's sprites (they appear in the VN CGs), Elena's expression sprites in story
scenes, the 6 VN CGs, and the two music tracks.

## Known gaps

- DE/FR/ES/ZH/KO: only the columns exist (the VN's story text is translated to JA only).
- Battle feedback is text + meters; no hit animation yet.
- Web export is not set up (DLsite needs desktop builds only).
- headless Godot routes no GUI input, so the click test must run under Xvfb (remote_shots.sh does).
- First launch follows the OS language (JA on a Japanese system); the choice is remembered.
