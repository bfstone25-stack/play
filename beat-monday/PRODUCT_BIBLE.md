# Floor 13: Night Shift — Product Bible

## Production contract

- Standalone Godot 4.7 2D pixel office horror; implementation is explicitly **WAITING** until Flat 404 passes its production gate.
- Target: 35–45 minutes, keyboard/gamepad movement, contextual interact, dialogue choices, light stealth; no combat system.
- Structure: prologue plus four chapters, three major flags, three endings. Native canvas 384×216 scaled integer-nearest to 16:9.
- Player: **June Park**, temporary payroll analyst on her first night shift at Meridian Ledger.
- Antagonist: **The Auditor**, an office process that removes people whose records do not balance.

## Core state

| Flag | Values | Set |
|---|---|---|
| `ledger_action` | `COPY`, `CORRECT` | Chapter 1 payroll discrepancy |
| `intern_trust` | `WARN`, `REPORT` | Chapter 2 encounter with Eli |
| `badge_owner` | `JUNE`, `MARA` | Chapter 3 identity terminal |
| `has_red_stapler` | bool | optional supply-room puzzle |
| `saw_floor_zero` | bool | optional lift-camera reel |

Resolver:

- `COPY + WARN + JUNE` and completed evidence set → **CLOCK OUT**.
- `CORRECT + REPORT + MARA` → **PROMOTED**.
- all other combinations → **MONDAY FOREVER**.

## Chapter screenplay

### Prologue — Sunday, 22:48 / Lobby (4 minutes)

Security shutter closes after June enters. Rain loops outside. Guard desk holds an unsigned visitor book.

RECEPTION SPEAKER: “Welcome, temporary associate June Park. Your shift ends when Monday’s ledger balances.”

JUNE: “Payroll said midnight.”

Interaction: visitor book.

> 22:47 — JUNE PARK — IN  
> 22:48 — JUNE PARK — IN  
> 22:49 — JUNE PARK — IN

Elevator buttons show 1–12 and 14. A paper label reading `13 / NIGHT OPERATIONS` covers the alarm key. Pressing it starts title card.

### Chapter 1 — The discrepancy / Open office (9 minutes)

Zones: reception bullpen, cubicle maze, break room, print bay. Objective: print Monday payroll and reconcile one red row.

TERMINAL:

> EMPLOYEE 013: MARA VALE  
> HOURS: 168 / STATUS: ABSENT / PAY: WITHHELD  
> ERROR: EMPLOYEE HAS WORKED MORE HOURS THAN EXIST THIS WEEK.

Voicemail, Supervisor Rusk:

> “Do not call me. Correct red rows, print three copies, leave one in the outbox. If someone asks you to restore a name, they are not on payroll.”

The printer produces a staff photo with June standing in the back row although it is dated 1998.

Choice 1:

- `COPY`: Save the original ledger to a floppy marked `BEFORE`. JUNE: “An error is evidence before it is a correction.”
- `CORRECT`: Change Mara’s status to `TERMINATED / NEVER EMPLOYED`. SPEAKER: “Variance resolved. Initiative noted.”

Pressure: cubicle monitors wake in sequence behind June; each displays `MONDAY 00:00`.

Optional copy, break-room rota:

> COFFEE / DISHWASHER / MISSING-PERSON REPORT  
> Monday: Mara / Tuesday: Eli / Wednesday: June

### Chapter 2 — The intern / Records annex (9 minutes)

At 23:26, intern **Eli Song** crawls from under a desk. His badge photo is blank.

ELI: “Please don’t scan me. The Auditor follows badge pings.”

JUNE: “You work here?”

ELI: “I started Monday. I think it has been six Mondays.”

Objective: cross the dark records annex. Auditor is shown only as a tall column of suit-colored pixels and a moving red scan line. Hide behind shelving when scanner sound rises.

Eli dialogue at locked archive:

> “Mara found a floor beneath the basement. She copied everyone before Rusk balanced them out. Your temp record replaced hers.”

Choice 2:

- `WARN`: Give Eli June’s spare visitor badge and direct him to the stairwell. Sets trust. ELI: “If the elevator opens twice, take the second one.”
- `REPORT`: Scan Eli’s blank badge at the compliance phone. Red light sweeps under the door; Eli’s dialogue portrait loses its face. SPEAKER: “Unlisted variance removed.”

Archive memo:

> BALANCE PROTOCOL  
> One active identity per workstation. One absence permits one temporary replacement. At week close, unresolved replacements inherit all attendance debt.

Optional supply puzzle: retrieve red stapler from Rusk’s locked cabinet using drawer sequence 1-3-1-2 printed on copier jams. It pins a document so the Auditor cannot re-sort it.

### Chapter 3 — Identity audit / Executive floor (10 minutes)

At 23:51, the elevator opens onto executive offices whose windows show daytime. Family photographs on desks all contain June.

MARA appears through terminal chat:

MARA: “You have my hours. I have your exit badge. The system will allow one of us to be real at midnight.”

JUNE: “Are you alive?”

MARA: “That is an HR category, not an answer.”

Evidence terminals reveal:

1. Rusk has hired 42 temporary replacements for one permanent role.
2. Every replacement was marked absent after the first Sunday.
3. The Auditor is an automated retention routine executed through badge readers.

Choice 3, identity terminal:

- `JUNE`: Keep June Park active and restore Mara as witness-only. Requires entering the three printed evidence page numbers by interaction, not typing. JUNE: “We leave as two names or the record goes public.”
- `MARA`: Reassign active identity to Mara Vale and mark June `TEMPORARY RESOURCE / DISPOSABLE`. MARA: “You should not have balanced this for them.”

Conditional lines:

- `COPY`: Mara confirms the floppy can expose Rusk.
- `CORRECT`: Terminal reports the source row permanently overwritten.
- `WARN`: Eli opens the stair gate remotely.
- `REPORT`: the compliance phone rings from inside June’s inventory.

### Chapter 4 — Midnight close / Floor 13 (8 minutes)

At 00:00 all doors lock. The Auditor walks the cubicle lanes. Player must carry three documents to one of two endpoints:

- Roof transmitter: evidence upload route.
- Rusk’s office outbox: compliance route.

Final interactions:

> TIMESHEET: 168 hours worked  
> OVERTIME REASON: “WAITING FOR MONDAY TO END”  
> EMPLOYEE SIGNATURE: the line is already signed in June’s handwriting.

If `has_red_stapler`, player can pin the original ledger to the transmitter and shorten the final stealth loop. If `saw_floor_zero`, elevator offers a hidden escape route but resolves to Monday Forever unless the primary route qualifies.

## Ending scenes

### CLOCK OUT

Requirements: `COPY + WARN + JUNE`, original ledger, archive memo, replacement list.

June uploads the evidence. Office windows change from fake noon to rainy midnight. Eli holds the stair door; Mara’s portrait resolves on every monitor.

MARA: “Forty-two names. Read them.”

June reads six aloud; the remaining names scroll during a playable walk to the lobby. The Auditor separates into ordinary coat racks and scanner lights.

Outside clock: Monday 00:03. June’s visitor book line finally gains `OUT`.

Cards:

> ENDING: CLOCK OUT  
> Meridian Ledger opened Monday with forty-two employees demanding back pay.  
> June never accepted another “flexible” night shift.

### PROMOTED

Requirements: `CORRECT + REPORT + MARA`.

June puts corrected pages in Rusk’s outbox. Daylight snaps on. Rusk’s office chair turns; it is empty except for June’s permanent badge.

SPEAKER: “All discrepancies resolved. Supervisor Park, please onboard tonight’s temporary associate.”

Mara exits through the elevator without looking back. June’s sprite gains Rusk’s red tie. A new applicant waits in the lobby below.

Cards:

> ENDING: PROMOTED  
> The floor balanced perfectly.  
> Monday needed a supervisor.

### MONDAY FOREVER

Mixed routes trigger a loop. June reaches the lobby at 00:01; shutter rises onto the same office at 22:48. The visitor book adds another `IN`.

ELI or MARA (depending flags): “You saved half a record. The Auditor rounds halves down.”

Each loop removes one color from the palette until only red scan lines remain.

Cards:

> ENDING: MONDAY FOREVER  
> CURRENT SHIFT: 169:00:00  
> Variance pending.

## Room and encounter sequence

1. Lobby tutorial; inspect book, call elevator.
2. Reception/open office; collect task list and reach assigned cubicle.
3. Print bay puzzle; route paper between two jammed printers.
4. Break room optional lore and cabinet code.
5. Records annex stealth encounter 1; learn scan-line timing.
6. Archive interaction and Eli choice.
7. Executive floor exploration; three evidence terminals.
8. Identity terminal choice.
9. Cubicle maze reversal with Auditor encounter 2.
10. Roof transmitter or outbox endpoint; resolver and ending walk.

## Visual/audio specification

- 16×16 tile grid; characters 24×32; portraits 96×96 with 4–6 facial variants.
- Palette by chapter: nicotine beige → fluorescent cyan → executive daylight → emergency red.
- Distinct sets: lobby, cubicles, print bay, break room, archive, executive suite, roof.
- Audio: fluorescent 60 Hz loop, printer rhythm, distant office phone, badge chirp, scanner sweep, rain, elevator bell variants.
- Auditor never uses a full monster portrait; fear comes from scan line, suit silhouette, and office machinery converging.

## Interaction copy inventory

- 18 mandatory interactables, 12 optional documents/props, 3 binary choices.
- 4 Mara terminal conversations, 3 Eli conversations, 2 Rusk voicemails.
- Every picked document remains in a pause-menu evidence tab.
- No typing: codes use ordered object interaction or selectable number chips.

## Implementation checklist — WAITING

- [ ] Do not begin until Flat 404 verification gate is accepted.
- [ ] Replace prototype combat remnants with exploration controller.
- [ ] Build seven tile sets and room maps.
- [ ] Implement state ledger and three choices.
- [ ] Implement scanner-cone stealth and checkpoint reset.
- [ ] Implement all screenplay copy and evidence log.
- [ ] Implement three multi-beat endings.
- [ ] Add unit tests for resolver, flags, and chapter gates.
- [ ] Import/export and complete GPU manual playthroughs only after authorization.

## Acceptance criteria

1. 35–45 minute first run and 20–25 minute replay.
2. Seven visually distinct office zones and two readable Auditor encounters.
3. 30 total authored interactions, three choices, three independently triggerable endings.
4. Early ledger and Eli choices alter chapter 3 dialogue, available assistance, and eligibility.
5. All routes are completable with keyboard or gamepad and require no typed input.
6. Pixel scaling remains crisp at 720p and 1080p.
7. Automated tests cover all endings plus at least three mixed-route loop cases.
8. No implementation commit is made before Product 1 passes its gate.
