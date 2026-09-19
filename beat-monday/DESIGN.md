# BEAT MONDAY — a work week RPG

Decision, 2026-09-18 (Blaze): Beat Monday becomes a workplace RPG, and CRAZY RANT
(`play/crazy-rant/`, 发疯文学 phrase auto-battler) is absorbed into it as one level.
Crazy Rant is deleted afterwards; its phrase corpus lives on at
`frontend/rpg/phrases.js`, moved verbatim.

Series: 情绪解药 / Emotional Catharsis (`play/catharsis/PLAN.md`, locked).
The wound this title treats is **the dread of the work week**. Not a fantasy RPG in
office clothes: every stat, item and enemy is something that actually happens at a job,
and the player wins against it.

## The spine

A **work week is the campaign**. Five days, five antagonists:

| Day | Antagonist | Mode |
| --- | --- | --- |
| MON | The Standup | horde |
| TUE | The Inbox | horde |
| WED | The All-Hands — **the breakdown** | rant / STG |
| THU | The Performance Review | horde |
| FRI | The Friday Deploy | horde |

Moment-to-moment it stays what it was good at: one-thumb, drag-to-move, auto-attack,
a horde closing in. On top of that sits the RPG scaffolding:

- **Levels and XP** — kills give XP, level-up pauses the day for a choice of 3 skills.
- **Stats** — HP, ATK, RATE (fire rate), SPD, plus flags (pierce, slow, multishot).
- **Equipment** — office objects in three slots (hand / desk / wear). Each day's boss
  drops one: stapler, noise-cancelling headphones, lanyard, ergonomic chair, door badge.
- **Party** — colleagues recruited by clearing days (Riley the intern, Morgan the PM,
  Pat from HR). They orbit and chip in damage.
- **Persistence** — level, skills, equipment and party carry between days via the kernel
  `save.js` schema (`localStorage`, key `blazecore.catharsis.v1`, field `beatMonday`).
- **The weekend** is the save/upgrade beat: after Friday you land on Saturday, re-kit at
  the desk, and next week starts harder.

## The Wednesday level (absorbed Crazy Rant)

On Wednesday you stop being polite. The auto-attack is replaced by **rant phrases fired
as projectiles** — the STG element. The corpus is Crazy Rant's, unchanged (zh / ja / en,
short CJK-safe glyphs). The kernel does the scoring: `kernel/rant.js` `rantPattern()`
turns your collected phrase loadout into `stream → spread → burst` (1 / 3 / 5
projectiles), and `rantShotPower()` sets the damage. New phrases drop from kills during
the level and join the combo permanently, so the weapon grows inside the level and
across the save. The All-Hands boss answers with slow aimed bullet fans — dodge them.

## Where content gets added later (the length argument)

An RPG is the genre that can keep growing; these are the seams, all of them data rows in
`frontend/rpg/data.js`, none of them new code:

- **More weeks** — `WEEKS` already carries `w2` (crunch) and `w3` (reorg) HP/damage
  multipliers. Beating Friday rolls the profile into the next week.
- **More days** — `DAYS` is a list. A sixth day (the on-call weekend) is one row plus a
  boss name and a string.
- **More roles / classes** — `ROLES` ships one (`ic`). Designer, manager, contractor are
  rows with different bases and growth.
- **A second company** — a new `DAYS`/`FOES`/`EQUIP` set under a company id: same loop,
  new antagonists, new drops. This is the natural "chapter two".
- **More equipment, skills, colleagues** — `EQUIP`, `SKILLS`, `PARTY`.

Copy for anything added goes in `frontend/rpg/strings.js` (en + zh-Hans ship together;
es / pt / ja fall back to en until translated).

## Form (locked by PLAN.md, honoured)

Vanilla JS + Canvas 2D, portrait 420×640, `localStorage` only, no backend, no React, no
physics library. Kernel modules are reused, not forked: `pool.js`, `rant.js`,
`economy.js`, `gacha.js`, `commerce.js`, `i18n.js`, `save.js` are vendored into
`frontend/kernel/` by `./sync-kernel.sh` so a shipped per-slug build can reach them, and
`rpg-smoke.cjs` fails if a vendored copy drifts from `play/catharsis/kernel/`.

Mainstream / SFW. No adult content in this title.

## Files

```
frontend/index.html      RPG shell (screens, overlays)
frontend/rpg/data.js     every number: days, foes, equipment, skills, party, weeks
frontend/rpg/core.js     pure logic, no DOM — the loop, stats, XP, drops (Node-testable)
frontend/rpg/render.js   Canvas 2D presentation, owns no numbers
frontend/rpg/main.js     screens, input, persistence
frontend/rpg/strings.js  UI copy, en + zh
frontend/rpg/phrases.js  the Crazy Rant corpus, moved verbatim
frontend/arcade.html     the previous 2D fighter, kept playable, no longer the entry point
```

Run: `python3 -m http.server 8765 --directory frontend` → http://127.0.0.1:8765/
Tests: `node rpg-smoke.cjs` (whole week headless), `node monday-smoke.cjs` (kernel pool).

## The Godot rebuild (2026-09-18)

Blaze's decision: every title goes through an engine — the HTML builds read as web forms.
`play/beat-monday-godot/` is this design in Godot 4.7 with a drawn office; this directory
stays as the spec, and `beat-monday-godot/tests/conformance_gen.cjs` runs the core here to
hold the port to the same numbers. The "Form (locked by PLAN.md)" section above describes
the HTML version only.
