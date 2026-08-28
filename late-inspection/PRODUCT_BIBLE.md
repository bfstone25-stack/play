# Flat 404 — Product Bible

## Production contract

- Public title: **Flat 404**. Internal folder remains `late-inspection/`.
- Format: standalone Godot 4.7 first-person 3D horror VN; English master script.
- Target run: 25–35 minutes on a first blind playthrough; 18–22 minutes when replaying and skipping optional reads.
- Content boundary: one complete episode, six investigation zones, three binary choice nodes, three authored endings.
- Save model: no mid-game save. Pause, resume, restart, and ending replay are required.
- Implementation order: spatial shell → interaction ledger → flags/gates → ending scenes → lighting/audio → tests/export.

## Cast and truth

- **Mara Venn**, player character, freelance move-out inspector. Her spoken lines appear as subtitles prefixed `MARA`.
- **Iris Vale**, missing tenant of Flat 404. Present only through notes, voicemail, pipe knocks, and the Witness ending.
- **Mr. Pell**, building manager. Polite, coercive, never physically seen.
- **Dane**, tenant of 403. Communicates under doors and through the shared bedroom wall.
- The building renews itself by making an inspector certify an occupied flat as vacant. Iris was pushed into the service cavity during Pell’s previous “inspection.” The pipe carries her voice. A signed overnight clause substitutes the inspector for the tenant unless evidence is preserved and the final door is opened.

## State and gates

| Flag | Set by | Later consequence |
|---|---|---|
| `order_read` | inspection order | unlocks 404 entry |
| `photo_kept` | Choice 1: photograph stain | Iris’s name remains visible; required for Witness |
| `photo_deleted` | Choice 1: wipe/delete | Pell praises compliance; contributes to Complicit |
| `pipe_answered` | Choice 2: answer three pipe knocks | Dane gives the wall code; required for Witness |
| `pipe_silenced` | Choice 2: close valve | drip stops and bedroom wardrobe opens clean; contributes to Complicit |
| `clause_signed` | Choice 3A | player accepts overnight substitution |
| `clause_refused` | Choice 3B | corridor geometry becomes unstable |
| `dane_note` | optional 403 note | changes final-knock copy and protects 404 eligibility |
| `iris_record` | bedroom cassette | names Pell and establishes truth |
| `final_open` | final choice | evaluates Witness if evidence flags qualify; otherwise 404 |
| `final_ignore` | final choice | evaluates Complicit if denial flags qualify; otherwise 404 |

Ending resolver:

1. `final_open && photo_kept && pipe_answered && iris_record` → **WITNESS**.
2. `final_ignore && photo_deleted && pipe_silenced && clause_signed` → **COMPLICIT**.
3. Every other combination → **404**.

## Pacing and chapter screenplay

Interaction text below is final production copy. A note remains readable after collection from the HUD log. Mandatory items are gated in order so no chapter can be skipped accidentally.

### Chapter 1 — Arrival / inspection order (4 minutes, 01:47)

**Zone A: exterior landing and lift lobby.** Rain-black windows, dead lift, blue exterior light. A green service lamp burns above the stair door.

Opening cards:

> 01:47 — Vesper Court  
> MOVE-OUT INSPECTION / UNIT 404  
> The manager said the tenant had already gone.

MARA: “Fourth floor. Photograph damage, read the meters, leave the key. Ten minutes.”

**I01, clipboard on radiator — mandatory**

> VESPER COURT / AFTER-HOURS INSPECTION 71-B  
> Unit: 404. Tenant: [name removed].  
> Confirm vacant. Record water damage. Do not contact adjoining tenants.  
> If work exceeds midnight, complete the overnight occupancy clause.  
> — M. Pell, Building Manager

MARA: “It exceeded midnight before he called me.”

Objective: `Find Flat 404. Check the door notice.`

Audio: distant lift cable, rain, one knock from a floor above. Lighting: cold window rim, sickly green stair fixture.

### Chapter 2 — Corridor / 404 entry (4 minutes, 01:53)

**Zone B: fourth-floor corridor.** Doors 401–404, threadbare runner, mailboxes, framed fire plan, maintenance cart. Warm fixtures alternate with dead pools.

**I02, 403 floor slip — optional but tracked**

> INSPECTOR—  
> Pell will tell you 404 is empty. Ask why an empty room knocks back.  
> If the pipe calls three times, answer three times. Not two.  
> — D, 403

MARA: “Someone watched me come up.”

**I03, notice taped over 404 number — mandatory**

> FINAL ACCESS NOTICE  
> Premises surrendered. Contents abandoned.  
> Entry constitutes confirmation that no resident remains.

MARA: “That isn’t what entry means.”

Interaction `Unlock 404`:

> The key turns before it enters fully. Warm air pushes through the gap. It smells of wet copper and boiled oranges.

MARA: “Hello? Building inspection.”

No reply. Three slow drips answer from inside. Objective: `Enter. Locate the checklist in the living room.`

Audio: lock scrape, room tone crossfade, knock now from 403. The 404 sign swings after player crosses threshold.

### Chapter 3 — Living room / kitchen investigation (7 minutes, 02:01)

**Zone C: entry and living room.** Shoes still aligned, sagging sofa, standing lamp, boxed books, dead television, family-photo silhouettes removed from frames.

**I04, checklist on coffee table — mandatory**

> 1. Confirm all personal property removed.  
> 2. Kitchen wall dry.  
> 3. Bathroom service pipe closed.  
> 4. Bedroom wardrobe empty.  
> 5. Overnight clause completed if keys remain after 00:00.

MARA: “Shoes. Tea. Half the books. Nothing about this says vacant.”

**I05, answering machine — optional**

PELL (recording): “Iris, this is the last courtesy. Sign the surrender. We can correct the damp after access is returned. Please don’t involve 403 again.”

IRIS (older saved message): “Dane, if this records: the wall gets wet when Pell brings an inspector. It isn’t rain. Don’t let them erase my name.”

MARA: “Iris.”

**I06, empty photo frame — optional**

> Dust protects the rectangle where a photograph stood. On the backing, in blue pen: IRIS + DANE / FIRST NIGHT WITH HEAT.

**Zone D: kitchen.** Tile change, cabinets, sink, refrigerator, kettle, narrow service wall, green under-cabinet light. Black-red moisture blooms behind wallpaper.

**I07, kitchen stain — mandatory; Choice 1**

Prompt:

> The checklist app opens a damage report. In the camera preview, letters surface inside the stain: IRIS VALE — STILL HERE.

- A — `Keep the photograph and attach it to the report.`  
  MARA: “Evidence first. Pell can explain the impossible part.”  
  Sets `photo_kept`. The stain remains letter-shaped. Pell voicemail later becomes threatening.
- B — `Wipe the wall and delete the corrupted image.`  
  MARA: “A reflection. Bad compression. Finish the job.”  
  Sets `photo_deleted`. The letters smear into a handprint. Pell voicemail later praises efficiency.

Follow-up:

> Behind the loose wallpaper, the wet line runs toward the bathroom. Something taps once from inside the pipe.

Objective: `Follow the wet line to the bathroom.`

### Chapter 4 — Bathroom pipe event (5 minutes, 02:09)

**Zone E: bathroom / service closet.** Green fluorescent light, cracked mirror, tub curtain, exposed copper stack, valve wheel, drain, maintenance hatch.

**I08, mirror — optional**

MARA: “My reflection blinks late.”

Subtitle after two seconds:

> In the mirror, the bathroom door is closed. Behind you, it is open.

**I09, service tag — mandatory**

> STACK 4 / DO NOT ISOLATE WHILE OCCUPIED  
> Last service: 14 NOV / PELL  
> Reported voice transmission: “tenant misuse.”

Pipe event: three metallic knocks: short, short, long. If `dane_note`, Dane whispers through wall: “Three back. Please.”

**I10, valve / pipe — Choice 2**

- A — `Answer with three knocks.`  
  MARA knocks three times. The pipe exhales.  
  IRIS (through pipe): “Bedroom. Behind the coats. Record… me.”  
  DANE (wall): “You heard her. Don’t let Pell make it maintenance.”  
  Sets `pipe_answered`; opens bedroom path; drip becomes heartbeat rhythm.
- B — `Close the valve and silence it.`  
  MARA: “It’s hydraulic shock. Close the line, record resolved.”  
  The valve resists like a held wrist, then turns.  
  PELL (phone): “Good. A quiet building is a safe building.”  
  Sets `pipe_silenced`; opens bedroom path; all room tone drops for three seconds.

Escalation sting:

> The bath curtain pulls inward although the room has no open window. A wet footprint appears outside the tub, then another toward the bedroom.

Objective: `Inspect the bedroom wardrobe.`

### Chapter 5 — Bedroom / neighbor escalation (5 minutes, 02:17)

**Zone F: bedroom.** Narrow bed, wardrobe, desk, boxed clothes, red bedside practical, bricked window, shared wall to 403. The clock is frozen at 02:17.

**I11, frozen clock — optional**

> The second hand reaches 17 and falls back to 16. Scratched beneath it: SHE GETS ONE MINUTE EACH INSPECTION.

**I12, wardrobe — mandatory**

Coats hang in front of a false plywood back. Behind it: cassette recorder, one woman-sized cavity, copper pipe crossing torn insulation.

MARA: “This wall was opened and closed from the room side.”

**I13, Iris cassette — mandatory; sets `iris_record`**

IRIS: “My name is Iris Vale. It is November fourteenth. Pell says the leak makes the flat uninhabitable, but he won’t let me leave with proof. Dane saw him bring the first inspector. When they signed ‘vacant,’ the corridor forgot my door. I stayed in the wall so somebody would hear me before it closed.”

IRIS: “If you are the next inspector: keep my name. Answer the pipe. At the final knock, open the flat from inside. A witness has to cross the threshold willingly.”

Sound: violent pounding from 403, then Dane shouting:

DANE: “Inspector! Pell is in the corridor. He doesn’t have a face in the peephole.”

Conditional phone call:

- If `photo_kept`: PELL: “You uploaded an image with a tenant name. Delete it. Your authorization does not include testimony.”
- If `photo_deleted`: PELL: “The kitchen correction came through clean. You understand how buildings survive.”

Objective: `Return to the living room. Read the overnight clause.`

### Chapter 6 — Overnight clause (3 minutes, 02:23)

**I14, clause on table — Choice 3**

> OVERNIGHT OCCUPANCY CLAUSE  
> The undersigned accepts temporary custodianship of Unit 404 and all unresolved contents until morning. Custodianship supersedes prior occupancy claims.

- A — `Sign as temporary custodian.`  
  Sets `clause_signed`. Ink crawls from signature toward the printed word “contents.”  
  MARA: “Mara Venn. Temporary. Until morning.”  
  Conditional PELL (`photo_deleted`): “Thank you, Ms. Venn. Welcome home.”  
  Conditional IRIS (`photo_kept`): “A signature is not a door. You can still open it.”
- B — `Refuse and tear the clause in half.`  
  Sets `clause_refused`. Both halves now read UNIT 404: NOT FOUND.  
  MARA: “No. This inspection is suspended.”  
  Corridor light outside changes from yellow to black-blue.

The front door slams. Four knocks from the corridor: 4–0–4–pause. Objective: `Go to the front door. Decide who leaves.`

### Chapter 7 — Final knock (2 minutes, 02:29)

At the peephole:

- With `dane_note`: DANE: “Whatever it shows you, the fourth knock is Iris.”
- Without it: PELL: “Open for management. We can settle your invoice now.”

Door interaction presents final choice:

- A — `Open the door and state what you witnessed.` Sets `final_open`.
- B — `Turn off the light and certify the flat vacant.` Sets `final_ignore`.

Resolver immediately starts one of the authored ending scenes.

## Ending scenes

### Ending A — WITNESS (4 minutes)

Eligibility: `final_open + photo_kept + pipe_answered + iris_record`.

The front door opens onto the bathroom service cavity, not the corridor. Iris stands behind translucent pipework, never shown as a detailed human model: wet coat silhouette, one hand against plastic, name badge readable.

MARA: “Iris Vale occupied this flat. I heard her. I recorded her. I am not certifying it vacant.”

IRIS: “Then look at me.”

Player regains control for a final three-step walk through the threshold. The geometry rotates into the real corridor. Door 404 now bears `IRIS VALE`; 403 opens one inch, warm light and Dane’s eye visible.

DANE: “Did she come out?”

MARA: “Her name did.”

Pell’s silhouette at the lift folds flat like paper. Dawn enters the end window. Phone report status changes from `DRAFT` to `WITNESS STATEMENT — SENT TO 17 RECIPIENTS`.

Final cards:

> ENDING: WITNESS  
> Vesper Court received seventeen inspection requests that morning.  
> Flat 404 was never listed as vacant again.

Credits: Design / code / procedural art; replay prompt and ending-condition hint.

### Ending B — COMPLICIT (3 minutes)

Eligibility: `final_ignore + photo_deleted + pipe_silenced + clause_signed`.

Mara turns off the standing lamp. Knocking stops mid-strike. Daylight appears without a transition. The flat is immaculate and newly furnished; family photographs now show Mara, face turned away.

PELL (phone): “Inspection accepted. No tenant found. Your renewal begins today.”

MARA: “Renewal?”

The front door will not open. The checklist displays:

> OCCUPANT: MARA VENN  
> MOVE-OUT INSPECTOR: [awaiting arrival]  
> Please keep the pipe quiet for the next guest.

A new inspector’s key enters from the corridor. Player can back away while the handle slowly turns.

Final cards:

> ENDING: COMPLICIT  
> You made the building quiet.  
> The building made you easy to replace.

### Ending C — 404 (3 minutes)

Eligibility: any mixed/incomplete moral route.

Mara opens or ignores the knock. Hard cut to the lift lobby. Every fourth-floor door reads 403. The key tag still reads 404, but the key passes through the wall.

MARA: “I was inside. Kitchen, bath, bedroom—”

Phone operator: “Vesper Court has no fourth unit on any floor. Who authorized your visit?”

Inventory text erases one item per beat: cassette, photo, clause, then `MARA VENN`. In the dark window, Iris’s silhouette stands where Mara’s reflection should be.

IRIS: “A witness who will not choose is only another missing room.”

The lift opens on a brick wall. A final knock sounds from inside the player’s headphones, centered rather than spatial.

Final cards:

> ERROR 404: INSPECTOR NOT FOUND  
> The next appointment is at 01:47.  
> Please bring identification.

## Spatial and prop specification

| Zone | Required readable dressing | Dominant palette / light |
|---|---|---|
| Lift lobby | lift doors, floor indicator, radiator, rain window, clipboard, stairs | blue exterior + green service |
| Corridor | four doors, runner, mailbox bank, fire plan, cart, 404 notice | alternating yellow practical/dead pools |
| Living/entry | shoe rack, sofa, lamp, table, boxes, phone, empty frames | warm amber, deep corners |
| Kitchen | counters, sink, fridge, kettle, cabinets, stained wall | green underlight + dirty amber |
| Bathroom | tub, curtain, toilet, basin, mirror, exposed stack, hatch | flickering sickly green |
| Bedroom | bed, wardrobe, desk, clock, cartons, blocked window, cavity | red bedside + cold wall seam |

No zone may be represented only by labeled primitive blocks. Primitive meshes are allowed when combined into recognizable furniture with material, silhouette, and local lighting.

## Interaction inventory

14 authored inspection interactions: 9 mandatory, 5 optional. Four decision presentations: stain, pipe, clause, final door. Three ending-specific interactive/camera sequences. HUD includes objective, crosshair/prompt, timed subtitle card, chapter/time, evidence log, pause overlay, restart, and mouse capture state.

## Audio cue sheet

| Cue | Construction | Trigger |
|---|---|---|
| `room_tone` | 42 Hz + 21 Hz loop, low amplitude | apartment interior |
| `rain_window` | filtered seeded noise | lobby proximity |
| `pipe_drip` | 1.68 kHz 30 ms decay | random 0.7–1.9 s until valve route |
| `knock_far` | 92 Hz wood transient, low-pass impression | chapters 1–2 |
| `knock_404` | three layered 78/104 Hz transients | chapter gates / final |
| `fluoro_hum` | 60/120 Hz loop with periodic dropout | bathroom |
| `cassette` | hiss loop under subtitle sequence | Iris record |
| `ending_witness` | rising 220 Hz fifth + dawn room tone | Witness reveal |
| `ending_complicit` | total silence, then lock latch | Complicit reveal |
| `ending_404` | centered knock + 35 Hz fall | identity erase |

All synthesized streams must use deterministic seeds where noise is generated so automated captures are reproducible.

## Lighting and camera pass

- Environment ambient energy ≤ 0.28 desktop, ≤ 0.45 Web fallback; fog density 0.006–0.018.
- Every playable route has navigable pools of light without requiring a flashlight.
- At least seven local practical lights: two corridor amber, lobby green, living lamp amber, kitchen green, bathroom green, bedroom red.
- Ending scenes change exposure/palette and physically alter visible geometry.
- Interactions never steal camera control except ending tableaux; choice UI releases mouse and restores capture after selection.

## Implementation checklist

- [ ] Build six collision-safe zones and recognizable furniture listed above.
- [ ] Spawn all 14 ledger interactions at distinct, reachable positions.
- [ ] Implement ordered chapter gating and objective text.
- [ ] Implement four choice presentations and ten state flags.
- [ ] Implement resolver and three multi-beat ending scenes.
- [ ] Add persistent read log for collected copy.
- [ ] Add pause/resume/restart and mouse capture guidance.
- [ ] Synthesize and spatialize cue sheet.
- [ ] Apply lighting targets and Web performance fallback.
- [ ] Add deterministic test API that uses the same resolver as play.
- [ ] Add progression tests for all endings and flag-dependent dialogue.
- [ ] Import, validate, export, and visually run on `blazeubuntu`.
- [ ] Host verified Web export under `/late-inspection/`.

## Objective acceptance criteria

1. Fresh player can complete without developer keys, typing, console, or external instructions.
2. A first read of all mandatory and most optional copy measures 25–35 minutes at 170–210 English words/minute plus traversal.
3. Six zones are visually distinguishable in screenshots by architecture, dressing, palette, and practical light.
4. At least 14 reachable authored interactions and four choice presentations exist.
5. Early stain and pipe flags alter later Pell/Dane/Iris copy and ending eligibility.
6. Witness, Complicit, and 404 each require a distinct route and each delivers at least three staged beats plus final cards.
7. Automated tests instantiate the production scene and assert each ending, mixed-route 404, gating, and conditional dialogue.
8. Godot 4.7 imports with no parse errors and exports Web successfully on `blazeubuntu`.
9. One full normal playthrough and two deterministic ending-route playthroughs complete on the GPU machine.
10. Captures show at least four zones, one early choice, final choice, and one full ending tableau.
11. Pause, resume, restart, mouse release/recapture, readable objective, subtitles, and choice buttons work at 1280×720.
12. Remaining placeholder art, measured playtime, interaction/choice/zone counts, test commands, and LAN URL are reported honestly.
