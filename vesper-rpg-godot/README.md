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

**What the RPG replaces.** The web VN's free-text chat turn (type something, a keyword scorer
moves affection) has no counterpart in a downloaded game. The **date standoff** takes its
place: the turn-based duel of the core (`rules.gd`), re-skinned for a date.

| core term | in VESPER |
|---|---|
| party member | **you** (the player is never drawn; otome POV) |
| Composure (HP) / Nerve (MP) | your Composure / your Nerve |
| enemy Resolve | **his Guard** (or a rival's) — bring it to 0 and he lets you in |
| Suspicion, 100 = loss | **Distance**: at 100 he closes the door (or the rival has you shown out); the date reloads from the autosave taken at the hotspot |
| weak / resist table | **his tells**: Ethan answers Wit and resists Charm until ch3; Gu Yan answers Patience and a remembered detail; Lu Xingye answers Teasing; Liam answers Banter and Gifts; Adrian answers Confiding; Fu Shen answers Patience and a plain word. Learn them with *Read him*, or by hitting one |
| Threaten (the coercion trap) | **Push him** — hits hard, but marks the date: Distance climbs faster every turn after |

Actions: Hold back (guard), Read him (observe), Banter (Wit), Tease (Charm), Remember
(needs a keepsake), Bring a gift (needs a gift), Push him (the trap), Breathe (stall), items;
skills grant *Say it plainly* (Wit) and *A look that lingers* (Charm).

**Each chapter is one night, explored on painted rooms.** Four rooms per night: your flat
(wardrobe = equipment, a search spot), the city street (the painted city map; a stranger in
your way: the doorman, the paparazzo, the gossip columnist), the late café (consumables,
the chapter's keepsake), and the chapter's own venue (the office top floor, the bookshop,
the arena...). The venue runs the chapter: the opening on entry, then beats as hotspots in
the parent's order, a date standoff with him before the turn that opens him up, the
chapter-end choice, and the night ends. A turn budget (the clock to the last train) is
shown; it is generous — no hard wall.

**Trust = the parent's affection, gating the adult beats.** One Trust track 0-10 per run
(one route per run). Winning a date standoff +1; a choice option the parent scores aff >= 4
+1, aff <= 1 -1; giving him the gift found in the chapter +1. The fork's adult turn needs
**Trust 5** (ch4) and **Trust 7** (ch5) — offered as an explicit, consented choice, with the
parent's own decline beside it (decline is always open and never costs Trust). Endings: the
parent's best ending at Trust >= 8 with one of its flags, the middle ending at Trust >= 6,
the bittersweet one below.

**Growth.** Level / XP (cap 20), four stats (Wit, Charm, Poise, Patience), two skill
branches of five (Sweet / Sharp), three equipment slots (outfit, accessory, keepsake tool),
five outfits as equipment (shown as still-life art: the player is never drawn), consumables
from the café, keepsakes per route. 6 save slots + autosave, gallery, settings, map.

**First 10 minutes:** the route choice, the first night card with the turn budget, the
wardrobe (equip an outfit), the doorman standoff on the street (Read him, a weakness), the
café, his first date standoff, a level-up with a stat + skill pick.

**Voice.** The fork's 21 rendered barks (`f_low_controlled`, the narrator's voice) are the
battle barks (open / read / win). The parent prose was never voiced; the new RPG lines ship
**text-only**.

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
