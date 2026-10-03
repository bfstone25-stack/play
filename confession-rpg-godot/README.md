# Confession Room — RPG (Godot 4.7)

The Confession Room VN rebuilt as an exploration + standoff RPG on the shared core
`play/night-rpg-core/addons/night_rpg` (symlinked here as `addons/night_rpg`).
Design: `ops/rpg_conversion/DESIGN.md`. Nothing here has been uploaded anywhere.

## What it is

Three cases = three nights at the Paloma, plus an epilogue at the safe house. The standoff
IS the interrogation: pressing a suspect is a turn-based duel of the suspect's **Composure**
against Reyes's **Case** (the party meter) while their **Stonewall** climbs — at 100 they ask
for a lawyer and the interview is over (reload from the autosave taken at the door). Actions:
Hold back, Read them, Press, Bluff, Show evidence, Offer a deal (spends a marker), Lean in,
Threaten (the coercion trap: hits hard, stonewall climbs faster for the rest of the interview),
Wait, Use item, plus the skill-granted Lay out the case / A quiet word. Each suspect's
weaknesses change per case. The VN's 12-question budget is the night's move budget (the
captain's shift).

All 72 testimonies are **Ask** hotspots in the three interview rooms; the lines a suspect
only gives under pressure appear once that pressure is won (three standoffs per suspect per
case; the guilty one's third is the night's boss). "Close the door" — the VN's nine optional
adult routes, consent asked first every time — opens at pressure 3 and needs Trust 3 / 5 / 7
with that person in cases 1 / 2 / 3; each route still ends with a fact on the board, as the
VN insists. "Name someone" at your desk: who, then which heard line; the VN's clean /
right-name / wrong endings.

| | count |
|---|---|
| cases | 3 + epilogue (all cleared end to end by the sim, every route and epilogue scene reached) |
| rooms | 15 explorable: your desk, the corridor, three interview rooms, evidence lockup, records archive, the morgue, the alley, the club floor, the dead man's office, the walk-in cooler, the loading bay, the mop room, the fire stairs, the flat above the club, the safe house |
| standoffs | 27 (3 suspects x 3 pressures x 3 cases, 3 of them bosses) + 3 minor people (the bouncer, Sgt. Okafor, Ms. Halloran) |
| systems | level/XP (cap 20), 4 stats (Wits/Charm/Grit/Patience), two skill branches (Procedure/Street), 3 equipment slots, consumables, markers, evidence, gifts, Trust 0–10 **per suspect** (named tracks, a generic core feature added for this game) with scenes at 3/5/7/9, 6 save slots + autosave, gallery, settings, map (the case board) |
| CGs | 6 VN gated plates (3 route scenes, 3 evidence photographs) + 3 clothed VN CGs + 6 new (3 story, 3 Trust scenes at 5/7/9) |
| languages | EN complete. JA: every RPG string (UI, rooms, standoffs, narration, 72 Ask labels) is EN+JA; the VN's own lines (testimonies, routes, endings — 265 lines) were never translated and fall back to English. Settings shows the coverage. DE/FR/ES/ZH/KO columns wired, EN fallback |
| play time (sim) | cases 40 / 38 / 40 min + epilogue ≈ 2.0 h at the sim's floor pacing (16 chars/s, 12 s per action); a real player reads slower and reloads once or twice: 2.5–3 h |
| voice | the VN's 236 English voice clips follow their lines (testimonies, press beats, routes, endings); the RPG's new narration is unvoiced |

## Run

    GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
    python3 tools/import_story.py    # VN text -> data/story/ (cases, interr, board, start) + voice
    python3 tools/import_art.py      # VN art/audio/fonts + gated CGs -> assets/ (gitignored); placeholder plates
    python3 tools/build_strings.py && python3 tools/build_nights.py && python3 tools/build_data.py
    $GODOT --path play/confession-rpg-godot                 # play
    $GODOT --path play/confession-rpg-godot -- --trial      # the trial (case 1)

## Verify

    tools/verify_all.sh            # rules tests, data check, case 1 x10, whole game with every expected flag, reckless player must lose
    STRICT=1 tools/verify_all.sh   # also fails on any placeholder plate / missing sprite / missing CG
    MIN_SHOTS=0 tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke   # real clicks under Xvfb on the 3060
    tools/remote_shots.sh res://tests/shots.tscn shots/latest                # EN + JA screenshots + the JA trial end

## Package

    tools/package.sh 1.0.0   # -> build/dist/confession-room-rpg[-trial]-v1.0.0-{pc,mac}.zip + SHA256SUMS.txt

The trial pck excludes nights 2–3 and the epilogue, their rooms, Sgt. Okafor / Ms. Halloran,
the case 2–3 voice and CGs; the three route CGs of case 1 show as the VN's blurred tiles
(`trial_locked_cgs`). The case 2–3 *text* stays in the pck (one story file) — noted.

## Status (2026-10-03)

verify_all rc=0 (case 1 10/10 no loss, 39.8 min; whole game with every clean ending, route
and epilogue scene; reckless player loses). ui_smoke on the RTX 3060: 13/13 real clicks. 81
screenshots EN+JA+trial in `shots/latest/` (3060, Vulkan), looked at. All 27 renders installed,
`check_data.py --strict` clean. `tools/package.sh 1.0.0` built; both -pc zips booted from the
zip on the 3060 (`shots/exported/`). Trial pck checked with `tools/pck_list.py`. DLsite draft:
`ops/dlsite/confession_rpg_product_page.md`. Known: in sim/auto mode a choice's buttons linger
until the next line (core event_view), so a CG shot taken right after a choice shows them.

## Art

`ops/confession_art/confession_gen.py` steps `rooms` / `enemies` / `rpgcgs` (queued through
`ops/render_queue.py add confession ...`), picks installed by `ops/confession_art/install_rpg.py`
into `ops/confession_art/out/rpg/` with a manifest; `tools/import_art.py` copies them in and
the game prefers them over the placeholder crops. The four VN backgrounds (squad room,
interview room, club floor, cooler) are used as they are. The VN has no sprites: the
suspects' standoff renders (neutral / pressured) double as their story sprites.
