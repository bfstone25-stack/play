# VESPER — RPG (Godot 4.7)

VESPER (the 18+ otome fork of Flutter, `play/flutter-after-hours`) rebuilt as an exploration +
date-standoff RPG on the shared core `play/night-rpg-core/addons/night_rpg` (symlinked here as
`addons/night_rpg`), the fourth title on the core after Elena, Room 704 and Confession Room.
Nothing here has been uploaded anywhere. Everyone depicted is an adult and is stated as one
in-scene; everything is consensual.

## DESIGN (written first, 2026-10-03)

**What is kept, all of it.** Six routes (Ethan, Lu Xingye, Gu Yan, Liam, Adrian, Fu Shen) x
five chapters, every beat (his authored line and the event it answers), every chapter-end
choice with his reply, every flag, the three endings per route with their adult coda, the
cast/age note, the fork's added adult turn (two beats per route) and its explicit decline,
and the 18 event CGs (ch2 / heat / ending per route). The prose is imported verbatim from
`play/flutter-after-hours/backend/stories_x/*.json` by `tools/import_story.py`; nothing is
re-written.

**RPG + its own second genre: an otome dating sim** (`ops/rpg_conversion/HYBRIDS.md`). The
RPG floor is the shared core: map, date standoffs, levels, Trust. On top of it, every night
opens with the **date planner** in your flat: his schedule line for that weekday (Mon–Fri =
chapters 1–5) hints at his taste; you choose **where to go first** (the late café / the long way
through the city / straight to him), **how to be with him** (playful / sincere / patient) and
**what you are wearing** (the outfit equipped from the wardrobe). Each man has his own taste
table (`TASTE` in `tools/build_nights.py`): 2 of 3 right is a well-planned evening — Trust +1
and that night's date starts at his lower-guard variant (Guard x0.75). The way to him in the
city only opens once the evening is planned.

**The date standoff replaces the web VN's free-text chat turn** (type something, a keyword
scorer moves affection), which a downloaded game cannot have. It is the core's turn-based duel
(`rules.gd`), re-skinned for a date:

| core term | in VESPER |
|---|---|
| party member | **you** (never drawn; otome POV) — Composure (HP) / Nerve (MP) |
| enemy Resolve | **his Guard** (or a rival's) — bring it to 0 and he lets you in |
| Suspicion, 100 = loss | **Distance**: at 100 he closes the door; reload from the autosave at the hotspot |
| weak / resist table | **his tells**, per man, shifting from ch3 (`TELLS` in `tools/build_data.py`): Ethan answers Banter and plain words and resists teasing early; Lu Xingye answers Teasing and something sweet; Gu Yan a remembered detail and a lingering look; Liam Banter and something sweet; Adrian a remembered detail and plain words; Fu Shen plain words and memory, and resists sweets. Learn them with *Read him* or by hitting one |
| Threaten (coercion trap) | **Push him** — hits hard, always resisted on a date, and Distance climbs faster every turn after |

Actions: Hold back, Read him, Banter (Wit), Tease (Charm), Remember (needs a keepsake), Something
sweet (needs a café treat), Push him, Breathe, items; skills grant *Say it plainly* and *A look
that lingers*. Strangers on the street (doorman ch1, paparazzo ch2, gossip columnist ch3), one
rival boss per route in ch4 (the board's man, his manager, the developer's agent, the fire chief,
the label, the patriarch), his last wall as the ch5 boss: 54 standoffs, 12 bosses.

**Each chapter is one night on four painted rooms**: your flat (planner, wardrobe, desk), the
city (the painted city map), the late café (treats, consumables, the chapter's keepsake, a gift
in ch2) and the chapter's own venue (30 venues), where the parent's chapter runs in order:
opening on entry, each beat as a hotspot, the date standoff after the first beat (the rival
before it in ch4), the adult turn, the chapter-end choices with his replies, the ch2 CG, and in
ch5 the ending. A turn budget to the last train is shown; it is generous.

**Trust (0–10, one per run = the parent's affection).** A date won close (Distance under 60)
+1, the rival won +1, a well-planned evening +1, a choice the parent scores aff >= 5 +1, aff <= 2
-1, aff <= -3 -2, the gift +1 (Items menu). The fork's adult turn needs **Trust 5** (ch4) and
**Trust 7** (ch5), offered as an explicit yes with the parent's own decline beside it (always
open, costs nothing). Endings: best at Trust >= 8 with one of the parent's best-ending flags,
middle at Trust >= 5, the low one below.

**Growth.** Level / XP (cap 20), four stats (Wit, Charm, Poise, Patience), two skill
branches of five (Sweet / Sharp), three equipment slots (outfit, accessory, keepsake tool),
five outfits as equipment (shown as still-life art: the player is never drawn), consumables
from the café, keepsakes per route. 6 save slots + autosave, gallery, settings, map.

**First 10 minutes:** the route choice, the night card with the turn budget, the wardrobe
(equip an outfit), the date planner, the doorman standoff (Read him, a weakness), a level-up
with a stat + skill pick, the café, his first date standoff.

**Voice.** The fork's 21 rendered barks (`f_low_controlled`, the narrator's voice; the "302
clips" figure is the whole studio's bark render across 21 games, this game's set is 21 lines) are
used as standoff barks (open / read / win) and scene stings (after each date, chapter end, best
ending). The parent prose was never voiced; the new RPG lines ship **text-only**.

**Languages.** EN complete. JA: every RPG string (UI, rooms, standoffs, items, skills, night
cards, route select) is EN+JA; the parent prose (beats, choices, endings) has no Japanese
and **falls back to English** — stated on the store page and in Settings' coverage figure.
The parent's real Chinese for four routes (Ethan, Lu Xingye, Gu Yan, Fu Shen) is carried in
the story files; DE/FR/ES/ZH/KO UI columns are wired with EN fallback.

**Trial:** route 1 (Gu Yan) chapters 1-2, ending on the chapter-2 date; the other routes and
chapters are not in the trial pck.

**Adult content.** Kept at the fork's ceiling (ART_DIRECTION tier 3): male toplessness, bare
backs, sheets, a scene that implies the rest. No genitals, clean anatomy, all adults,
consent on the page every time.

## Run

    GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    python3 tools/import_story.py      # stories_x -> data/story/ + data/story_index.json
    python3 tools/import_art.py        # CGs, cut-out men, title, music, barks, UI, rendered RPG art
    python3 tools/build_strings.py && python3 tools/build_nights.py && python3 tools/build_data.py
    $GODOT --path play/vesper-rpg-godot              # play
    $GODOT --path play/vesper-rpg-godot -- --trial   # the trial (Gu Yan ch1-2)

Art: `ops/flutter_art/flutter_gen.py` steps `rpgrooms` / `rpgenemies` / `rpgoutfits` / `cgfix`
through `ops/render_queue.py`, picked by eye into `ops/flutter_art/rpg_picks.json`, installed by
`ops/flutter_art/install_rpg.py` (60 assets: 33 room plates + city map, 9 people x 2 poses,
5 outfits, the 3 CGs re-rendered in colour — cg_ethan_ch2, cg_ethan_heat, cg_fushen_ch2).

## Verify

    STRICT=1 tools/verify_all.sh   # rules, data (strict: no placeholder/missing art), Gu Yan ch1 x10, 12 route/ending paths, reckless loses
    MIN_SHOTS=0 tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke     # real clicks, RTX 3060
    tools/remote_shots.sh res://tests/shots.tscn shots/latest                   # full playthrough shots (2 routes fit in its budget)
    REMOTE_DIR=rpgtestvesper3 tools/remote_shots.sh res://tests/shots.tscn shots/allart --allart   # every venue + CG + gallery, EN+JA
    REMOTE_DIR=rpgtestvesper3 tools/remote_shots.sh res://tests/shots.tscn shots/extras --extras   # route select + date planner, EN+JA
    tools/zip_boot.sh build/dist/vesper-rpg-trial-v1.0.0-pc.zip
    tools/package.sh 1.0.0 && python3 tools/export_samples.py

## Status (2026-10-04)

- `STRICT=1 tools/verify_all.sh` rc=0: Gu Yan ch1 10/10 no loss (9.3 min at sim pace); all six
  routes cleared end to end by the normal player (best ending each); Lu Xingye 5/5 runs no loss
  on every chapter; endings asserted: best x6, middle (Gu Yan, Lu Xingye, Fu Shen), low (Gu Yan,
  Ethan, Fu Shen); the reckless player loses ch1 every run.
- Endings honestly: 12 of 18 are asserted by scripted players. Ethan's middle is reached in about
  half the seeds; Lu Xingye's low and Liam's / Adrian's middle and low need Trust lost on dates
  (winning far, declining plans) because the parent wrote every one of those men's choices warm.
- Real-click smoke on the RTX 3060: 14/14 (`shots/smoke/`), incl. picking the route, equipping,
  planning the evening, winning the doorman standoff by clicks, level-up, save/load.
- Screenshots on the 3060 (Vulkan): `shots/latest/` (EN, Gu Yan + Ethan full playthroughs, 69),
  `shots/latest2/` (Lu Xingye ch1-4, 30; the run lost the ch4 rival once with the harness's seeds
  and was cut off), `shots/allart/` (all 30 venues with him + all 18 CGs + full gallery, EN and
  JA, 98), `shots/extras/` (route select + planner, EN/JA). Contact sheets: `shots/contact_cgs.jpg`,
  `shots/contact_venues.jpg`. Every CG looked at: no genitals; tier-3 male toplessness.
- Trial zip unzipped and booted on the 3060: `shots/exported/trial_zip_v1.0.0_boot.png`. Trial pck
  holds only prologue + Gu Yan ch1-2 (no other nights, story, venues, rivals, full CGs).
- Packages `build/dist/` (sha256 in `build/dist/SHA256SUMS.txt`); DLsite page
  `ops/dlsite/vesper_product_page.md`; samples `ops/dlsite/vesper_samples/` + main/thumb.
- **Not registrable as 女性向け right now**: DLsite has paused new AI-generated 女性向け works
  (see the product page). Nothing was uploaded or registered.
- Known: the night card of each route's chapter 1 shows on a black stage (the prologue leaves no
  room drawn); play time 1 route ≈ 50 min at sim floor pace, ~1–1.5 h for a reader.
