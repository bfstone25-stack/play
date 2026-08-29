extends RefCounted
class_name StoryContent

static func n(id: String, prompt: String, pos: Vector3, text: String) -> Dictionary:
	return {"kind":"note", "id":id, "prompt":prompt, "pos":pos, "text":text}

static func c(id: String, prompt: String, pos: Vector3, text: String, a: String, b: String) -> Dictionary:
	return {"kind":"choice", "id":id, "prompt":prompt, "pos":pos, "text":text, "a":a, "b":b}

static func commentary(id: String) -> String:
	var pages := {
		"order": "MARA'S FIELD NOTE: Pell created urgency, removed the tenant name, and warned me away from neighbors before I arrived. Harrow's carbon copy proves this procedure has happened before. I will timestamp every finding locally; the building's case system cannot be my only record.",
		"dane": "MARA'S FIELD NOTE: Dane supplies a legal name, duration of residence, direct observation, and a falsifiable prediction about his door number. His language sounds frightened, not incoherent. I should preserve the note even if the corridor remains stable.",
		"fire_plan": "MARA'S FIELD NOTE: The apartment exists physically but not on the filed plan. The pencil route makes the service stack a boundary crossing, not merely plumbing. This explains why Iris chose the cavity and why Pell repeatedly calls the sound hydraulic.",
		"notice": "MARA'S FIELD NOTE: The notice attempts to turn my entry into consent. That wording has no normal inspection purpose. Iris's name survives only because moisture reversed the correction fluid—the damage Pell wants deleted is also the mechanism preserving her identity.",
		"checklist": "MARA'S FIELD NOTE: Two checklists show the same sequence diverging at the wall. Pell's clean version anticipates every finding and pre-authorizes its explanation. Harrow's version becomes panicked only after the third task. I should treat the order itself as a trap.",
		"frame": "MARA'S FIELD NOTE: The missing print connected Iris, Dane, and an inspector before tonight. Removing faces from photographs mirrors removal of names from records. The frame is not supernatural proof alone, but the dated inscription corroborates Dane's tenancy claim.",
		"shoes": "MARA'S FIELD NOTE: Wet footwear, a future train ticket, and an incomplete suitcase contradict abandonment. Iris planned an ordinary departure and expected to retrieve her passport. Someone wanted the appearance of flight without allowing the person to complete it.",
		"thermostat": "MARA'S FIELD NOTE: Occupancy is being measured as a system state. The times align with Pell's inspection stages rather than heating demand. When the count changes to two, the flat is registering me as a potential replacement before I sign anything.",
		"answering": "MARA'S FIELD NOTE: The messages establish coercion, Harrow's presence, and impossible foreknowledge of my route. More importantly, Iris anticipated deletion and deliberately distributed her evidence across media: voice, photograph, neighbor, pipe. No single correction can erase all of it.",
		"groceries": "MARA'S FIELD NOTE: Fresh food is weak evidence by itself, but the prescription timestamp is external and transactional. It places Iris alive after Pell's surrender claim. Photograph the pharmacy label separately from the kitchen report so Pell cannot classify both as contents.",
		"invoice": "MARA'S FIELD NOTE: Premeditation is now documentary. The cavity, latch, and acoustic treatment were ordered before the leak, and Harrow's impossible signature links construction to occupant substitution. Pell did not discover this phenomenon; he operationalized it.",
		"kettle": "MARA'S FIELD NOTE: Harrow left a personal work object inside 404, yet his employer denies him. His recorded sentence suggests the cavity projected Iris into his own home after he signed. The building may copy ownership before it copies physical space.",
		"mirror": "MARA'S FIELD NOTE: The reflection preserves the deleted photograph route as readily as the kept one. That means denial changes what the official report can prove, not what happened. The flat remembers both choices and is showing me the version I tried to discard.",
		"medicine": "MARA'S FIELD NOTE: Pell reframed a reproducible environmental sound as psychiatric illness. The clinician independently documented normal hearing and received Iris's recording. This is a second outside record; even if 404 disappears, the appointment should remain.",
		"drain": "MARA'S FIELD NOTE: Iris entered the cavity by choice, with Dane and Harrow present. That does not absolve Pell: the preordered construction forced her strategy. Harrow's button places him in the bathroom before his identity was transferred.",
		"service": "MARA'S FIELD NOTE: The incident log is a schedule, not maintenance history. Admission, audibility, transfer, signature, disappearance. My line is following it exactly. The next defensive action is not simply mechanical; it determines whether Iris remains an audible co-occupant.",
		"clock": "MARA'S FIELD NOTE: Seven erased inspectors imply a practiced cycle. The one-minute reset may be the interval in which the old and new versions overlap. My initials were scheduled before I accepted the job, suggesting Pell selected me rather than any available contractor.",
		"locket": "MARA'S FIELD NOTE: Details are resistance. Systems can duplicate a name or photograph, but Iris trusted Dane to preserve contradictions and preferences. If I testify, I must describe a person, not merely report an anomalous tenant record.",
		"letters": "MARA'S FIELD NOTE: Iris's plan is coherent: remain inside the legal boundary, use copper as a channel, force an inspector to preserve the name externally. Opening the final door is not rescue theater; it converts collected artifacts into witnessed testimony.",
		"wardrobe": "MARA'S FIELD NOTE: Marks on the room side prove Iris was not sealed in. The empty yellow hanger means either she crossed through the service boundary or the room has begun moving her belongings into another occupant's version. The cassette is the intended handoff.",
		"cassette": "MARA'S FIELD NOTE: Iris names the mechanism and predicts both moral routes. Witnessing requires photograph, reply, testimony, and threshold; compliance requires deletion, isolation, signature, and silence. Mixed conduct leaves the building an unresolved account—its preferred condition for erasing both parties.",
		"followup": "MARA'S FIELD NOTE: Pell never disputes the facts together. He separates each into an administrative category until no category contains a crime. His pause at the pipe proves he hears Iris. His threat confirms the final choice affects more than payment.",
		"final_evidence": "MARA'S FIELD NOTE: Every earlier action is now visible in the key, report, corridor, and voices. There is no neutral exit. Opening stakes my identity on Iris's evidence; ignoring ratifies Pell's rewritten record. Refusing to choose leaves the building to reconcile the contradiction."
	}
	return "\n---\n" + str(pages.get(id, "")) if pages.has(id) else ""

static func stage(s: int, flags: Dictionary) -> Array[Dictionary]:
	match s:
		0:
			return [n("order", "Open the sealed inspection folio", Vector3(-5.0, .52, 4.0), """VESPER COURT / AFTER-HOURS INSPECTION 71-B
Unit 404. Tenant: [name removed]. Confirm vacant; record water damage; do not contact adjoining tenants. If work exceeds midnight, complete the overnight occupancy clause. — M. Pell

MARA: It exceeded midnight before he called me. Pell said the previous inspector abandoned the job and offered double rate if I came before the cleaners.
---
The reverse carries a carbon impression:
INSPECTOR E. HARROW / ARRIVAL 01:47 / DEPARTURE — / DISPOSITION: OCCUPANT SUBSTITUTED.

The final words were struck through hard enough to tear the sheet. Beneath them: DO NOT SIGN AFTER THE FOURTH KNOCK.
---
Harrow was the name in Pell's voicemail—the inspector who supposedly quit. Yet his form is dated tonight.

The sealed lift indicator changes from 4 to 0 and back. Wood answers wood somewhere above: one deliberate knock.""")]
		1:
			return [
				n("dane", "Unfold the note from 403", Vector3(-2.72,.14,5.5), """INSPECTOR—Pell will say 404 is empty. Ask why an empty room knocks back. If the pipe calls three times, answer three times. Not two.

The first knock is the manager. The second is the building copying him. The third is whoever the last inspector replaced. — D, 403
---
My name is Dane Orlov. Iris Vale lived beside me for eleven months. She did not surrender the flat. I watched Pell carry plasterboard upstairs after midnight.

If my door says 402 when you return, take this note downstairs. Remember us in details the building cannot improve."""),
				n("fire_plan", "Compare the altered fire plan", Vector3(-2.88,1.2,7.8), """The official fourth-floor plan shows three units. A fourth rectangle was added in blue pencil beside the service shaft. Its door opens into a corridor too narrow on paper and ordinary in front of you.
---
The legend YOU ARE HERE has become SHE IS HERE. A pencil route runs from 404's bathroom stack into the lift shaft.

MARA: The graphite is fresh. Whoever changed this expected an inspector to look."""),
				n("notice", "Examine the 404 access notice", Vector3(.72,.82,4.0), """FINAL ACCESS NOTICE. Premises surrendered. Contents abandoned. Entry constitutes confirmation that no resident remains.

Correction fluid covers the tenant line, but damp raises four letters beneath it: IRIS.
---
Entry does not constitute confirmation. A signature does. Pell knows that.

The brass digits are warm. Touching the second 4 makes a woman inhale behind the door.
---
The key turns before it enters fully. Warm air pushes through the gap, smelling of wet copper and oranges boiled dry.

MARA: Building inspection. Iris Vale?

Three drips answer. Behind you, Dane's chain moves, but 403 stays closed.""")
			]
		2:
			return [n("checklist", "Review both room checklists", Vector3(4.1,.48,3.2), """MOVE-OUT CONDITION CHECKLIST
Personal property removed. Kitchen wall dry. Bathroom stack closed. Bedroom wardrobe empty. Overnight clause complete.

Pell pre-checked every line except your signature.
---
An older checklist is stapled beneath:
1 Shoes warm. 2 Kettle warm. 3 Wall says a name.
4 THERE IS A WOMAN BETWEEN THE ROOMS.
5 I did not leave I did not leave—

The signature half was cut away.
---
MARA: Shoes, tea, books, a cardigan. Abandoned flats sag. This one is holding its breath.

Personal effects can establish occupancy, but Pell will call them debris. I need dates, a name, and something he cannot revise.""")]
		3:
			return [
				n("frame", "Inspect the stripped photo frame", Vector3(6.45,.7,4.9), """Dust protects the missing photograph. On the backing: IRIS + DANE / FIRST NIGHT WITH HEAT / OCT 2025.
---
A torn corner shows Dane laughing and Iris's yellow sleeve. In the dark glass the picture appears complete for one blink. A third figure between them wears an inspector lanyard; his face is another removed rectangle."""),
				n("shoes", "Inspect shoes and half-packed suitcase", Vector3(1.9,.22,5.7), """Work boots dusted with plaster and yellow trainers wet at the soles sit below the rack. A suitcase is half packed.
---
Inside: three shirts, an empty passport wallet, an unsigned surrender form, and a train ticket for tomorrow—after Iris allegedly left.

MARA: Someone separated proof of departure from the person who needed it."""),
				n("thermostat", "Read the thermostat history", Vector3(2.25,1.25,.28), """01:47 18°C / 01:53 19°C / 02:01 21°C / 02:09 24°C / 02:17 OCCUPIED.

The last value is not a temperature.
---
Service mode reads PROFILE 404 / BODY HEAT COMPENSATION / TARGET OCCUPANTS: 1.

While your hand remains on it, the target changes to 2."""),
				n("answering", "Play all five machine messages", Vector3(5.8,1.28,.36), """MESSAGE 1 — PELL: Iris, sign the surrender. We can correct damp after access returns. Do not involve 403. The stack noise is hydraulic shock, not a voice.

IRIS: You called my machine to tell me the machine is wrong.
---
MESSAGE 2 — IRIS: Dane, the wall gets wet when Pell brings an inspector. The stain makes letters in photographs. He deletes them before upload. Keep a copy where the building cannot revise it.

DANE: Somebody is outside.
IRIS: Then let them hear my name.
---
MESSAGE 3 — PELL: Inspector Harrow certified the unit vacant.
IRIS: He never entered the bedroom.
PELL: He signed.
IRIS: That is not the same thing.

A crash. Four knocks. Harrow whispers: Who put my coat in the wall?
---
MESSAGE 4 begins one minute after your order:

MARA'S VOICE: Fourth floor. Photograph damage, read meters, leave the key. Ten minutes.

Another voice says it with you, half a breath late.
---
MESSAGE 5 records footsteps crossing the living room and entering the kitchen—footsteps you have not taken yet.

MARA: Iris Vale. Dane Orlov. Elias Harrow. Three names Pell removed from three documents.""")
			]
		4:
			return [
				n("groceries", "Check the fresh groceries", Vector3(8.25,.55,1.1), """The unplugged refrigerator is cold. Milk expires next week; half an orange waits on a plate. Labels face inward like a staged inspection photo.
---
Behind the milk: medication for Iris Vale, collected 14 November at 23:11—two hours after Pell claims she surrendered the keys."""),
				n("invoice", "Read the concealed repair invoice", Vector3(9.1,1.75,.38), """PELL PROPERTY SERVICES / UNIT 404-S
Open service cavity; install acoustic insulation; replace tenant-side plasterboard. Scheduled six days before the reported leak.
---
Materials: plasterboard, vapor barrier, copper pipe, interior latch, disposable coverall.

Instruction: CAVITY MUST OPEN FROM UNIT ONLY UNTIL INSPECTION COMPLETE.
---
Pell signed as contractor. Customer signature: Elias Harrow, dated tomorrow.

MARA: This was prepared before Iris vanished. Harrow signed after his own records disappeared."""),
				n("kettle", "Inspect the burned kettle and cups", Vector3(10.35,1.15,1.0), """The kettle boiled dry after at least four refills. One cup holds orange peel; the other bears Harrow's inspection-company logo.
---
The empty cup leaves a fresh wet ring. From inside it, a man whispers: I signed because she was knocking from the wrong side."""),
				c("stain", "Document the name in the damp", Vector3(10.82,1.08,4.18), """The checklist camera reveals IRIS VALE — STILL HERE inside the hand-shaped stain. The report app classifies it as tenant decoration and offers correction.

Keeping the image uploads Iris's name outside 404. Deleting it marks the kitchen dry and releases Pell's payment.""", "Keep and upload the photograph", "Wipe the wall and delete it")
			]
		5:
			return [
				n("mirror", "Study the delayed mirror", Vector3(8.25,1.52,5.72), """Your reflection blinks late. In the mirror the bathroom door is closed; behind you it is open.
---
Reflected Mara holds the kitchen photo even if you deleted it. A yellow sleeve withdraws through the reflected service hatch. One damp print appears over your reflected mouth."""),
				n("medicine", "Read Iris's medicine label", Vector3(8.45,1.0,8.68), """IRIS VALE — collected 14 NOV. For panic caused by persistent environmental noise. Contact housing authority if symptoms coincide with boiler operation.
---
A clinician confirms normal hearing. Iris supplied a recording: three pipe knocks followed by a woman repeating Iris's full name."""),
				n("drain", "Inspect the bath drain", Vector3(10.25,.12,8.7), """The dry drain caught blue pencil shavings, a photographic negative, and a brass button stamped E.H.
---
Against the light, the negative shows Iris entering the service cavity while Dane braces the panel. Pell watches from the doorway. Iris points at Harrow, whose badge reflects in the mirror."""),
				n("service", "Read the stack incident log", Vector3(9.4,1.25,6.2), """STACK 4 / DO NOT ISOLATE WHILE OCCUPIED. Reported voice transmission: “tenant misuse.”

Copper is warm only at shoulder height, as though a hand grips it inside the wall.
---
01:47 Harrow admitted. 02:04 tenant audible. 02:17 transfer initiated. 02:23 Harrow signed. 02:29 Unit 404 unavailable.

Tonight a line writes itself: 01:47 Venn admitted.
---
Three knocks travel up the copper: short, short, long. Breath fogs the valve from the wall side.""")
			]
		6:
			return [c("pipe", "Answer or isolate the pipe", Vector3(9.4,.9,6.2), """The stack knocks three times. Answering establishes a second witness but invites the voice farther into the room. Closing it satisfies Pell's checklist and isolates whatever crosses the room boundary.""", "Answer with three knocks", "Close and silence the valve")]
		7:
			return [
				n("clock", "Inspect the frozen clock", Vector3(2.0,.78,9.12), """The second hand reaches 02:17 and falls back. Every reset knocks in the shared wall.
---
Seven alarm dates match seven late inspections. Initials remain beside erased names. Tonight's alarm says M.V. / 02:29—the time Harrow's unit became unavailable."""),
				n("locket", "Open the locket beneath the pillow", Vector3(3.35,.62,8.4), """One side holds Iris's portrait; the other a square of mirror.
---
Dane—remember me in details it cannot copy. I hate marmalade. I sing flat. I lie about finishing books. I chose yellow because you said it made winter temporary.
---
MARA: Not court evidence. Evidence for a person.

The mirror reflects the wardrobe open. In the room it remains shut."""),
				n("letters", "Read Iris's unsent complaints", Vector3(2.0,.68,9.15), """DRAFT 1: Damp returns only when management schedules an inspection. Photographs show handwriting. Pell deletes tickets and calls it delusion.
---
DRAFT 2: Harrow believed me until he entered the cavity. He emerged asking why his apartment held my belongings. Pell made him sign at 02:23. His employer now denies he existed.
---
DRAFT 3: I will remain inside the flat boundary while Dane loosely seals the panel. The pipe crosses every version of this room and may carry my voice.
---
Inspector—do not rescue me by removing the proof I remained. Keep the image. Answer the pipe. Open the front door from inside and state what you witnessed."""),
				n("wardrobe", "Open wardrobe and false wall", Vector3(6.08,1.0,8.5), """Coats hang grey, brown, yellow, then an empty hanger still moving.
---
The invoiced interior latch opens newer plywood onto insulation, copper, a recorder, and a cavity wide enough for one seated person.
---
No body. Fingernail marks score the apartment side, not the cavity side.

MARA: Iris could leave. She stayed because the room required an occupant the inspection could not see.""")
			]
		8:
			return [n("cassette", "Play Iris's complete testimony", Vector3(7.02,.7,8.5), """IRIS: My name is Iris Vale. It is November fourteenth. I rent Flat 404. Management removed my name while I remained inside.
---
Every inspector sees my things and calls them abandoned. They hear me and call it hydraulic shock. Harrow believed me—then signed vacant. For one minute I saw his flat where mine should be.
---
This building does not remove rooms. It balances occupants. A vacant certificate leaves a blank; the overnight clause fills it with the inspector.

Harrow is not dead. Death leaves a record. He is the knock after mine.
---
I entered the cavity willingly. An inspector cannot certify an empty unit while a tenant remains inside its boundary. Copper passes through the boundary when doors move.
---
Keep my name outside this flat. Answer three knocks. At the final knock, open from inside and state what you witnessed.

If you erase, isolate, and sign, the building accepts the cleaner story.
---
PELL: Ms. Vale? Inspector Harrow is here.
HARROW: Why is there a coat in the wall?

Four knocks. One soft scream.

DANE, now through the wall: Inspector! Pell is in the corridor. He does not have a face in the peephole.""")]
		9:
			var evidence_route: bool = bool(flags["photo_kept"]) or bool(flags["pipe_answered"])
			var text := """PELL: Your report contains a former tenant's name. Delete it before synchronization.
---
MARA: Iris collected medicine after surrender. You ordered this wall before the leak. Harrow signed tomorrow's invoice.

PELL: Objects retain dates badly in damp buildings. You assess condition, not narrative.
---
Iris knocks beneath his voice. Pell pauses at the third strike.

PELL: Close the valve. A voice without a unit has no standing.
MARA: A witness gives it standing.
---
PELL: Then understand the cost. Open that door and the building reconciles two accounts. It may choose yours.

In the black television, a tall faceless man stands framed in the doorway. Turning reveals only the swinging 404 plate.""" if evidence_route else """PELL: The corrected photograph and closed valve came through clean. You understand condition versus story.
---
MARA: I found medication and letters.
PELL: Abandoned contents. Complete the clause; payment releases before morning.
---
Behind Pell, Iris's tape says: It always prefers a cleaner story.
MARA: Where are you?
PELL: The corridor.
---
A shadow crosses under the front door twice in the same direction. Your report replaces TENANT IRIS VALE with CUSTODIAN MARA VENN."""
			return [n("followup", "Answer Pell's live call", Vector3(5.82,1.28,.36), text)]
		10:
			return [c("clause", "Decide the overnight clause", Vector3(4.1,.49,3.2), """The undersigned accepts custodianship of Unit 404 and unresolved contents until morning. Custodianship supersedes prior occupancy.

Signing preserves the room but names you sole occupant. Refusing rejects Pell's order but lets the corridor challenge whether 404 exists.""", "Sign as temporary custodian", "Tear and refuse the clause")]
		11:
			var signed: bool = bool(flags["clause_signed"])
			var final_text := """The key tag now says TENANT — MARA VENN. Your report calls Iris's shoes yours and her cassette an appliance fault.
---
DANE: A signature is not a door. Open it. Say her name before the building finishes yours.
---
Four knocks: one strike, a pause, silence where zero belongs, four fingertips.

Pell has no face in the peephole. A yellow sleeve waits behind him.""" if signed else """Both torn halves read UNIT 404: NOT FOUND. The key teeth are smooth.
---
DANE: You broke the clause, not the inspection. Open and name her, or stay quiet and let the corridor choose.
---
In the peephole are three doors. Where 404 stood, you see the back of your own head. A yellow sleeve touches your reflected shoulder."""
			return [n("final_evidence", "Inspect the altered key and peephole", Vector3(.94,.7,4.0), final_text)]
		12:
			return [c("final", "Answer the final knock", Vector3(.82,1.0,4.0), """Four knocks: 4 — silence — 4. Opening converts evidence into testimony and exposes you to the threshold. Ignoring submits the report exactly as every earlier choice has rewritten it.""", "Open and state what you witnessed", "Certify vacant and ignore the door")]
	return []
