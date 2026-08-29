# Floor 13: Night Shift（13楼夜班）— Production Bible

## Production contract

Standalone Godot 4.7.2 Web game. Pure mouse/touch, choice-driven horror narrative; no typing, movement, combat, stealth, or artificial waits. English is the sole player-facing language so the Web export never depends on unavailable CJK system fonts.

- Native canvas: 640×360; nearest texture filtering; integer scaling.
- First-read target: 25–35 minutes at 170–190 words/minute, including exploration and choices.
- Protagonist: June Park, temporary payroll analyst at Meridian Ledger.
- Antagonist: The Auditor, a compliance process that edits people until the records balance.
- Supporting characters: Eli Song, an intern who has worked six Mondays; Mara Vale, the erased analyst whose employment record June inherited; Supervisor Rusk, heard through recordings.
- Structure: seven sequential chapters, seven illustrated areas, 28 authored hotspots, four binary choices, three endings.

## Runtime state and resolver

| Flag | Values | Delayed consequence |
|---|---|---|
| `eli_stance` | `TRUST`, `SUSPECT` | Eli opens the stair gate, or Compliance removes his face and leaves his phone ringing later. |
| `compliance` | `REFUSE`, `OBEY` | The original ledger survives, or June's employee record becomes permanent. |
| `escape_route` | `STAIRS`, `ELEVATOR` | Stair route finds the replacement list; elevator route sees Floor 0 and acquires Rusk's keycard. |
| `contract` | `RESIGN`, `SIGN` | June rejects inherited hours, or accepts Night Operations management. |

Ending resolver:

- **CLOCK OUT**: `TRUST + REFUSE + STAIRS + RESIGN`.
- **THE NEW MANAGER**: `SUSPECT + OBEY + ELEVATOR + SIGN`.
- **MONDAY FOREVER**: every other complete combination. This is an authored ending, not a failure stub.

Every choice sets a durable flag, changes at least one later screen, adds an evidence-log entry, and is covered by automated route tests. All routes reach a complete ending.

## Interaction and pacing model

Each area contains four visible point-click hotspots. Three are required; the fourth is optional but substantive. A large touch-friendly route button appears after required discoveries. Dialogue is paginated to one speaker and one short paragraph per page. Estimated first-read text is 4,700–5,300 words; visual inspection, decisions, and pagination add 4–7 minutes. There are no timer gates.

Persistent HUD:

- chapter / location / clock;
- current objective;
- `CASE LOG` overlay with discovered evidence and all four decisions;
- `PAUSE` overlay with resume, restart, and title controls;
- dialogue `CONTINUE` button and two 56-pixel-high choice buttons;
- hotspot labels and completed-state marks.

## Full executable screenplay

The following is the canonical story sequence. Implementation may wrap lines differently, but must not omit beats or reduce endings.

### 1 — 11:59 PM / June's cubicle

**Opening pages**

NARRATION: Sunday has narrowed Meridian Ledger to one lit cubicle. Rain combs the windows. The fluorescent tube over June Park's desk hums in a pitch that makes her teeth feel loose.

JUNE: One last ticket. Submit, clock out, never agree to “flexible close” again.

SYSTEM: OVERTIME TICKET 1313. Reconcile Employee 013 before 00:00. Failure to close transfers the outstanding hours to the active analyst.

**Hotspot: Last ticket**

The screen lists Mara Vale, payroll analyst, absent for 168 hours in a seven-day week. Her pay is withheld. The correction field has already been filled with `NEVER EMPLOYED`, but June's cursor waits over Submit.

June notices a second cursor moving half a beat behind hers. It circles Mara's name, then underlines the word `active`.

**Hotspot: Desk phone**

RUSK, voicemail: Park. Do not call back. Red rows are not people; they are variance. Correct, print three copies, put one in my outbox. If anyone asks you to restore a name, they are not on payroll.

The message metadata says it was recorded tomorrow at 08:04. Beneath Rusk's voice, forty people whisper the same employee number.

**Hotspot: Empty coffee**

The cup is still warm although June finished it at ten. A lipstick mark that is not hers forms a complete ring. On the cardboard sleeve someone wrote: `WHEN THE CLOCK LOSES A MINUTE, LOOK AT THE DIRECTORY`.

**Hotspot: Drawer**

Inside lies a resignation form bearing June's signature. Reason for leaving: `POSITION NEVER EXISTED`. The carbon copy underneath bears Mara Vale's signature in the same handwriting.

**Transition**

At 11:59, the office clock clicks backward to 11:58. Every monitor in the open office wakes. The elevator bell sounds from a floor the directory does not list.

### 2 — The directory changes / Open office and elevator lobby

**Opening pages**

June steps into the open office. Forty vacant chairs face their monitors. Each screen shows her cubicle from a slightly different angle. In one view, somebody stands behind her.

The overhead announcement calmly asks all Night Operations staff to report to Floor 13. Meridian Ledger occupies floors 8 through 12. The brass directory has always skipped thirteen.

**Hotspot: Printer**

The printer feeds a 1998 staff photograph. June stands in the back row wearing clothes she donated in college. Mara is beside her, scratched away so deeply the paper has a hole.

On the reverse: `REPLACEMENTS ARE CHEAPER THAN OVERTIME`.

**Hotspot: Attendance board**

Magnetic names fill the board: Mara, Eli, June, then thirty-nine blank strips. Moving June's strip to OUT makes it snap back to IN. Eli's strip is warm and damp.

**Hotspot: Elevator directory**

The directory lettering rearranges itself. Floors 8–12 become `DAY OPERATIONS`; the blank between 12 and 14 becomes `13 — NIGHT OPERATIONS`. Below Basement, a blue-lit line reads `0 — RETENTION`.

**Hotspot: Security camera**

The lobby feed is delayed by one minute. Future June waits before the elevator. Behind her, a tall shape in a suit unfolds from the seam between two cubicles. Its red scanner line passes through chairs without touching them.

**Transition**

The elevator opens. Inside, the mirrored wall reflects an intern crouched behind June. The real elevator is empty. When she turns around, he is standing in the lobby.

### 3 — The coworker who should not be there / Break room

**Opening pages**

ELI: Don't scan my badge. Please. It tells the Auditor where the mistakes are.

Eli Song looks twenty-two and exhausted enough to be ancient. His plastic badge has a photograph-shaped blank. He says he started last Monday and has watched six Mondays arrive without a Tuesday.

He leads June into the break room, where the refrigerator motor masks their voices. He knows Mara's name before June says it.

**Hotspot: Eli's badge**

The badge serial matches June's except for the final digit. Under ultraviolet vending-machine light, six layers of names show beneath Eli's: six temporary interns, all marked `ABSENCE REPLACEMENT`.

ELI: They reuse the card after the person stops matching it.

**Hotspot: Break-room rota**

The rota assigns chores by weekday: coffee, dishwasher, missing-person report. Monday belongs to Mara. Tuesday belongs to Eli. Wednesday belongs to June. There are no columns after Wednesday.

**Hotspot: Refrigerator**

Forty-two lunch bags line the shelves, each dated the same Sunday. One labeled JUNE contains a house key, a severance cheque for zero dollars, and a molar wrapped in a payslip.

Eli refuses to look inside the bag labeled ELI.

**Hotspot: Compliance phone**

The wall phone has no keypad, only a badge reader and two lamps: green `LISTED`, red `VARIANCE`. Lifting the receiver plays Rusk's voice: “Unlisted staff must be reported. Silence is participation.”

**Choice 1 — Trust or suspect**

ELI: Mara copied the original ledger. She hid it in the server corridor. I can get you there, but you have to decide whether I am a person or another trap wearing a badge.

- `TRUST — Give Eli the visitor badge.` June covers Eli's blank badge with her spare visitor pass. He promises to open the stair gate if she refuses Compliance.
- `SUSPECT — Scan Eli at the compliance phone.` The red lamp wakes. Eli's portrait on the badge loses its eyes, then mouth. He runs before the scanner reaches his name. The receiver keeps breathing after he is gone.

### 4 — Compliance request / Server corridor

**Opening pages**

Server fans push cold air through a corridor that should not fit inside the building. Blue status lamps blink like distant windows. A red scan line travels along the floor, pauses at June's shoes, and continues.

COMPLIANCE: Active Analyst Park. Employee 013 remains unresolved. Produce the original ledger for correction.

**Hotspot: Server rack**

Rack 13 contains personnel folders instead of hardware. Forty-two folders use the same job code. Every temporary analyst replaced the previous analyst's unexplained absence. Each replacement became the next absence.

If Eli was trusted, his folder is still labeled ACTIVE but its pages are fading. If reported, it is empty except for a wet badge outline.

**Hotspot: Mara's terminal**

MARA: You have my hours. I have your exit authorization. The system permits one active identity at midnight.

MARA: Rusk fed it corrections until the corrections learned to ask for people. The Auditor is not a ghost. It is policy with enough electricity to move.

If Eli was trusted, Mara confirms he carried her warning through six loops. If reported, she says Compliance now speaks with his breath.

**Hotspot: Original ledger**

Behind a loose vent is a dot-matrix ledger stamped BEFORE. It records forty-two names, original hours, and Rusk's approvals. Mara's name is not absent; it is overwritten by June's temporary ID.

June can feel the printer paper trembling in time with the scanner.

**Hotspot: Emergency intercom**

RUSK, recording: Night Operations exists to make daylight's numbers possible. Somebody always owns the unpaid hours. Sign the correction and it won't be you—at least, not tonight.

The recording ends with Rusk asking someone named June to train the next hire.

**Choice 2 — Obey or refuse**

COMPLIANCE: Surrender the original. Confirm Mara Vale never worked here. Permanent employment will be issued.

- `REFUSE — Preserve the ledger.` June folds the pages inside her coat. The server lamps turn spectral blue. Compliance marks her `HOSTILE WITNESS`; Mara restores three erased names to the case log.
- `OBEY — Submit the correction.` The printer eats the original and produces June's permanent badge. The scanner turns blood red. Compliance marks her `SUCCESSION ELIGIBLE`; somewhere, Mara screams through a dial-up tone.

### 5 — Escape route / Elevator lobby and stairs

**Opening pages**

At midnight, all office doors lock. The elevator opens and closes by itself. The stair alarm rings without making sound. June has one route to Rusk's office on the impossible floor.

The selected route provides unique evidence and changes the final confrontation.

**Hotspot: Fire map**

The map shows stairs descending from 14 directly to 12. A handwritten thirteenth landing appears only when June touches the glass. `DO NOT COUNT THE STEPS. IT COUNTS BACK.`

**Hotspot: Elevator inspection seal**

The inspection date advances while June reads it. The inspector signature changes from Rusk to Mara to June. Beneath the seal is a keycard slot stained with old adhesive.

**Hotspot: Ringing phone**

If Eli was trusted, he whispers that he has reached the stair control and can hold one gate for ninety heartbeats—he refuses to call them seconds.

If Eli was reported, the phone rings from inside June's coat. Eli's compliance-clean voice says, “Variance is a lonely word. You made it mine.”

**Hotspot: Directory glass**

June's reflection wears Rusk's red manager tie. Mara's reflection stands beside her without a face. The Auditor appears only as the narrow space separating them.

**Choice 3 — Stairs or elevator**

- `STAIRS — Follow the fire route.` On the thirteenth landing, June finds the replacement list carved beneath forty-two coats. Eli opens the upper gate if trusted; otherwise June uses the resignation-form staple to bridge the alarm contacts. Each landing repeats with one fewer color until she speaks Mara's name aloud.
- `ELEVATOR — Descend before going up.` The elevator travels below the basement to Floor 0. Rows of badge printers stamp blank faces. June takes Rusk's master keycard from an empty suit. When the doors reopen, the display reads 13 although the car has not moved.

### 6 — Final resignation / Manager office

**Opening pages**

Rusk's office is a perfect daylight set at midnight: painted sun on the windows, plastic plants, family photographs containing every temporary analyst. The desk nameplate waits blank.

The Auditor stands behind the chair as a column of suit-dark pixels crossed by a red scanner. It never raises its voice.

AUDITOR: One role. One active employee. One absence. Balance the record.

**Hotspot: Rusk's outbox**

The outbox contains forty-one resignation forms and one empty slot. Every form cites voluntary abandonment at exactly 00:00. The signatures begin differently, then converge into June's handwriting.

**Hotspot: Family photographs**

Each photo shows Rusk with a different analyst and the same birthday cake. In the newest, June holds the knife. If she came by stairs, all forty-two names are written on the frame. If by elevator, Rusk's keycard opens the backing to reveal severance cheques totaling the missing wages.

**Hotspot: Midnight contract**

The contract offers permanent manager status, full benefits, and responsibility for all unresolved hours. Its final clause: `MANAGER CONSENTS TO REMAIN UNTIL A QUALIFIED REPLACEMENT ACCEPTS ENTRY`.

**Hotspot: Window**

Behind the painted daylight is real rainy darkness. Far below, the lobby shutter is half open. Mara waits outside the glass, rendered in blue monitor light. If Eli was trusted, he waits with her. If not, only his blank badge lies on the pavement.

**Choice 4 — Resign or sign**

- `RESIGN — Reject inherited hours.` June tears her pre-signed resignation in half and writes all forty-two names across the contract. If she preserved the ledger and took the stairs with Eli's help, the Auditor must process each witness before it can process her.
- `SIGN — Accept Night Operations.` June uses Rusk's keycard or the permanent badge to sign. The manager tie in the reflection turns real. The Auditor steps backward into her shadow.

### 7 — Staged closures

#### Ending A — CLOCK OUT

Eligibility: `TRUST + REFUSE + STAIRS + RESIGN`.

1. June feeds the original ledger and replacement list into Rusk's fax. Mara routes it to every payroll inbox and the labor board. Forty-two monitors wake, each restoring one name.
2. Eli holds the stair door while the Auditor's red scan line breaks into harmless copier light. Mara appears first as a portrait, then as a woman reflected in the rainy windows.
3. June walks through the open office. She reads six names aloud; the others scroll in the case log. Empty chairs turn toward the windows, no longer toward her.
4. In the lobby, the visitor book finally changes June Park from IN to OUT at Monday 00:03. Eli's line gains OUT. Mara's gains `PRESENT`.
5. Outside, dawn is ordinary gray. Meridian opens with forty-two claims for back pay. June never accepts another flexible night shift. Final card: `ENDING — CLOCK OUT / THE RECORD REMEMBERS`.

#### Ending B — THE NEW MANAGER

Eligibility: `SUSPECT + OBEY + ELEVATOR + SIGN`.

1. The painted sun snaps on. June's badge prints with the title SUPERVISOR PARK. The corrected ledger is shredded into white confetti that falls upward.
2. The elevator opens. Mara, restored by June's accepted identity exchange, walks out without looking back. Eli's blank badge is swept into Rusk's outbox.
3. The Auditor adjusts June's red tie in the window reflection and dissolves into her shadow. The office fills with warm daytime color, but the clocks remain at 11:59.
4. Downstairs, a new temporary analyst enters out of the rain. June hears her own voice through Reception: “Red rows are not people. They are variance.”
5. She tries to warn the applicant. The only words Compliance permits are onboarding instructions. Final card: `ENDING — THE NEW MANAGER / MONDAY NEEDS A SUPERVISOR`.

#### Ending C — MONDAY FOREVER

Eligibility: any other complete route.

1. June's chosen evidence contradicts her chosen contract. The Auditor stamps both `PARTIAL`. Half a record is rounded down.
2. She reaches the lobby at 00:01. The shutter rises onto the same office at Sunday 11:48 PM. Rain climbs upward outside.
3. Eli or Mara, depending on June's choices, remembers the previous loop in fragments. One asks her to choose a whole truth next time. The other repeats Compliance's greeting.
4. The visitor book adds another June Park — IN. The office palette loses one color. The case log retains all flags, proving the loop is consequence rather than reset.
5. June sits at her cubicle. Ticket 1313 opens with Employee 013 changed to JUNE PARK and Mara listed as active analyst. Final card: `ENDING — MONDAY FOREVER / CURRENT SHIFT 169:00:00 / VARIANCE PENDING`.

## Visual direction

Seven illustrated areas: cubicle, open office, break room, server corridor, elevator lobby, stairwell, manager office. Procedural pixel art uses 8/16-pixel geometry, silhouette characters, localized red scanner light, blue monitor glow, rain, printer paper, server LEDs, and animated fluorescent flicker. Red and blue communicate Compliance and witness evidence; neither is a global decorative tint.

Palette:

- cubicle: navy, nicotine beige, CRT green;
- open office: charcoal and monitor cyan;
- break room: sickly green with vending ultraviolet;
- server corridor: black-blue with spectral LEDs and a moving red scan line;
- elevator lobby: brass, concrete, emergency blue;
- stairs: raw concrete, blue exit lamps, isolated blood-red landings;
- manager office: false cream daylight invaded by red scanner and rainy blue.

## Audio direction

Procedural low-volume fluorescent hum runs after first interaction. Authored cues: printer clack, desk phone pulse, elevator double bell, badge chirp, server throb, scanner sweep, stair alarm, contract stamp, and rain. Audio reinforces reveals and never blocks progression.

## Verification gate

- [ ] 7 distinct areas and 28 hotspots visible and reachable.
- [ ] 4 choices persist; delayed consequence assertions pass.
- [ ] All 16 flag combinations terminate; three target routes independently trigger all endings.
- [ ] First-read word count and measured normal run fall within 25–35 minutes.
- [ ] No clipped dialogue at 1280×720 and 1920×1080; touch targets remain at least 44 CSS pixels.
- [ ] Pause, case log, restart, and return-to-title work; no dead ends.
- [ ] Godot 4.7.2 GPU import/run/Web export succeeds on blazeubuntu.
- [ ] Hosted `/floor-13/` returns HTML 200; `.wasm` MIME is `application/wasm`; byte ranges work.
- [ ] Screenshots cover all seven visual areas; short video proves choices, consequence, transition, and ending.
- [ ] Product 3 / Null Shrine remains untouched.
