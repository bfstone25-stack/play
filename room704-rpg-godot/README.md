# Room 704 — RPG (Godot 4.7)

The Room 704 VN rebuilt as an exploration + standoff RPG on the shared core
`play/night-rpg-core/addons/night_rpg` (symlinked here as `addons/night_rpg`), the second
title on the core after `play/elena-rpg-godot` (its tools are the template for these).
Design: `ops/rpg_conversion/DESIGN.md`. Nothing here has been uploaded anywhere.

## What it is

One night in the Marbeck Residential Hotel as three shifts and an epilogue. Shift 1 is the
front desk alone (the VN's act 1: Mira checks in, the auditor's rounds, the man from the car
as the boss). Shift 2 is the fourth floor with Mira in the party (the VN's act 2 opens it; the
chair/bed/window choice closes it, with "say yes" as the Trust 5 branch and the VN's own
decline under it). Shift 3 is six-forty: the basement, the alley, Haskell with the register,
Penhallow for the owner, then the ending the night has earned. The epilogue is seven
o'clock and the day porter. All VN text is kept — say lines are referenced by source line
(`data/story/actN.json`, ported with their Japanese translation and the EN + JA voice) so
the writing and the three routes (cover / sold / stonewall) are the VN's own. New RPG text
(rooms, standoffs, barks) is in `tools/strings_*.py`, EN + JA.

| | count |
|---|---|
| shifts | 3 + epilogue (all reached by the sim on all three route/ending paths) |
| rooms | 18 explorable (16 rendered for the RPG, lobby and 704 are the VN's) (lobby, back office, bar, kitchen, lift, service stair, second-floor corridor, 212, fourth-floor corridor, 704, 702, linen room, roof, Mrs Dace's flat, boiler room, laundry, loading bay, the street) + the painted floor plan |
| standoffs | 11 standard + 3 bosses (Gale at the desk, Gale on the fourth floor, Penhallow at the doors) |
| systems | level/XP (cap 20), 4 stats (Wits/Charm/Grit/Discretion), two skill branches per character (Clerk/Fixer, Ghost/Flame), 3 equipment slots, consumables, keys, evidence, a gift, Trust 0–10 with scenes at 3/5/7/9, 6 save slots + autosave, gallery, settings, map |
| endings | together / train / alone (Trust 7+ and a desk that did not sell her; a sold register trust never repaired; the bus from the corner) |
| languages | EN and JA complete (UI, VN text, RPG text, voice per language); DE/FR/ES/ZH/KO columns wired with EN fallback |

**Standoff rules** are the core's (`addons/night_rpg/rules.gd`, SUASION's duel): Composure
(HP), Nerve (MP), the enemy's Resolve and Suspicion (100 = somebody picks up a phone =
loss). The auditor has Deflect, Bluff, Show the book, Bribe (her banknotes), Threaten (the
drawer revolver makes it land; it is never fired), Stall, items, and the skill-granted House
line. Mira has Read him, Bluff, Flirt, Stall and the skill-granted Tell him the truth. A loss
reloads the autosave taken just before the hotspot.

## Run

    GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    python3 tools/import_story.py    # VN act text + JA + voice -> data/story/, assets/voice/
    python3 tools/import_art.py      # VN art/audio/fonts, gated CGs, rembg sprite cutouts, placeholder plates, rendered RPG art
    python3 tools/build_strings.py && python3 tools/build_data.py && python3 tools/build_nights.py
    $GODOT --path play/room704-rpg-godot                     # play
    $GODOT --path play/room704-rpg-godot -- --trial          # play the trial (shift 1)

## Verify

    tools/verify_all.sh      # rules unit checks, data cross-reference, shift 1 x10 balance+pacing, the three route/ending paths, the reckless player that must lose
    MIN_SHOTS=0 tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke   # real mouse clicks under Xvfb on the 3060
    tools/remote_shots.sh res://tests/shots.tscn shots/latest   # EN + JA screenshots, then the JA trial end

## Package (DLsite, new work registration)

    tools/package.sh 1.0.0    # -> build/dist/room-704-rpg[-trial]-v1.0.0-{pc,mac}.zip + SHA256SUMS.txt

The trial is the same game with the `trial` feature: shift 1 to the boss, then the bilingual
end screen. Its pck carries no shift 2–3 data, voice, CGs, rooms, enemies or outfits
(`export_presets.cfg`).

## Art

Rendered by `ops/room704_art/room704_gen.py` steps `rooms` / `enemies` / `outfits` /
`rpgcgs` through the render queue, picked by eye (`ops/room704_art/sheets/`,
`rpg_picks.json`) and installed by `ops/room704_art/install_rpg.py` into
`ops/room704_art/out/rpg/` with a manifest; `tools/import_art.py` copies them in and
`build_data.py` fails if a manifest asset is not referenced. Kept from the VN by design: the
lobby and room 704 plates (the corridor was re-rendered: the VN plate has Mira painted in), the three story CGs, the two gated love scenes (the
sensual versions, no genitals), the title key visual and the music.
