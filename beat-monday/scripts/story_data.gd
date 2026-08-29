extends RefCounted
class_name StoryData

const AREAS := [
	{
		"id": "cubicle", "chapter": "1 / 7", "place": "JUNE'S CUBICLE", "clock": "11:59 PM",
		"objective": "Inspect the last ticket and the desk June is leaving behind.",
		"opening": [
			["NARRATION", "Sunday has narrowed Meridian Ledger to one lit cubicle. Rain combs the black windows. The fluorescent tube over June Park's desk hums in a pitch that makes her teeth feel loose. Beyond the partition, the office has emptied so completely that every tiny machine sounds alive."],
			["JUNE", "One last ticket. Submit it, clock out, and never agree to a “flexible close” again. Rusk promised the correction would take five minutes. Rusk has also promised three times that my temporary contract was almost finished."],
			["SYSTEM", "OVERTIME TICKET 1313. Reconcile Employee 013 before 00:00. Failure to close transfers all outstanding hours to the active analyst. Current active analyst: JUNE PARK. Outstanding balance: 168:00:00."],
			["NARRATION", "The clock above the emergency exit clicks forward, hesitates, and returns to 11:59. Somewhere across the floor, a printer wakes and begins feeding paper into an empty tray."]
		],
		"hotspots": [
			["ticket", "LAST TICKET", [82, 78, 105, 64], [
				["JUNE", "Employee 013: Mara Vale. Payroll analyst. Status: ABSENT. Hours this week: one hundred sixty-eight. There are only one hundred sixty-eight hours in a week. According to this, she worked every one of them and was absent for all of them."],
				["SYSTEM", "Suggested correction: NEVER EMPLOYED. This correction has been prepared for your convenience. Selecting Submit acknowledges that no labor, identity, or outstanding compensation existed."],
				["NARRATION", "A second cursor appears beside June's. It moves half a beat after hers, circles Mara's name, and underlines ACTIVE ANALYST. When June takes her hand off the mouse, the second cursor keeps moving."],
				["JUNE", "An error is evidence before it is a correction. That is what Dad used to say about tax audits. He meant numbers. He never had to clarify that he also meant people."]
			]],
			["phone", "DESK PHONE", [215, 70, 55, 44], [
				["RUSK / VOICEMAIL", "Park. Do not call me back. Red rows are not people; they are variance. Correct the row, print three copies, and put one in my outbox. If anyone asks you to restore a name, they are not on payroll."],
				["NARRATION", "The recording is timestamped Monday, 08:04—eight hours from now. Beneath Rusk's voice, a crowd whispers one employee number. Thirteen. Thirteen. Thirteen. Not in unison; in the ragged cadence of a roll call."],
				["RUSK / VOICEMAIL", "And Park? Do not use the stairs after midnight. Facilities has not certified the thirteenth landing. There is no thirteenth landing. If you see one, close your eyes and continue down."],
				["JUNE", "He knew I would still be here. He recorded instructions in the future because he knew. Either the timestamp is broken, or this company has found a way to schedule negligence retroactively."]
			]],
			["coffee", "WARM COFFEE", [26, 105, 47, 39], [
				["NARRATION", "June finished the coffee at ten, but the cup is warm and full again. A lipstick mark that is not hers forms a complete ring. The surface trembles whenever the fluorescent light flickers."],
				["MARA / HANDWRITING", "WHEN THE CLOCK LOSES A MINUTE, LOOK AT THE DIRECTORY. WHEN THE DIRECTORY GAINS A FLOOR, DO NOT LET IT LEARN WHICH WAY YOU PLAN TO LEAVE."],
				["JUNE", "The writing is pressed so hard through the sleeve that the cardboard split. Mara Vale. If this is a prank, somebody learned the name on a confidential payroll row and reheated bad coffee for atmosphere."],
				["NARRATION", "At the bottom of the cup, pale sediment arranges itself into tiny block letters: BEFORE. June blinks. It is only powdered creamer again."]
			]],
			["drawer", "LOCKED DRAWER", [198, 119, 75, 42], [
				["NARRATION", "The drawer was locked when June arrived. It opens now without resistance. Inside lies a resignation form bearing her full signature, dated Monday. Reason for leaving: POSITION NEVER EXISTED."],
				["JUNE", "I have never written my P like that. Except—no. I did, when I was sixteen. Before I trained myself to make it look more professional. Whoever signed this knew an older version of my hand."],
				["NARRATION", "The carbon copy underneath bears Mara Vale's name in the same handwriting. Both forms carry Supervisor Rusk's acceptance stamp. The ink smells fresh enough to sting."],
				["MARA / CARBON NOTE", "A resignation is not an exit. It is permission for them to tell the story without you. Keep your own copy. Keep everybody's names."]
			]]
		],
		"transition": [
			["NARRATION", "The clock clicks backward to 11:58. Forty vacant monitors wake beyond June's partition, each displaying a live view of her chair. In one view, somebody stands behind it."],
			["PA", "Night Operations staff: report to Floor 13 for close. Day Operations staff: disregard any voices, alarms, or personnel observed after scheduled departure."],
			["JUNE", "Meridian occupies eight through twelve. The directory skips thirteen. It has always skipped thirteen."],
			["NARRATION", "The elevator bell answers from the far lobby. Two notes: a clean chime followed by a lower note that seems to happen inside June's chest."]
		]
	},
	{
		"id": "office", "chapter": "2 / 7", "place": "OPEN OFFICE", "clock": "11:58 PM",
		"objective": "Find out why the directory added a floor.",
		"opening": [
			["NARRATION", "Forty chairs face forty monitors. Each screen shows June's abandoned cubicle from a slightly different angle. The angles should require cameras inside walls, beneath carpet, and directly behind her own eyes."],
			["JUNE", "Everyone left at eleven. Payroll waved. Facilities killed the music. I watched the elevator count down. So who pushed all these chairs away from their desks?"],
			["NARRATION", "A scanner-red line wakes at the far end of the office. It travels beneath partitions with patient mechanical precision, stops at each empty chair, and marks every monitor PRESENT."],
			["PA", "Unresolved absence detected. One active temporary replacement remains on premises. Thank you for volunteering to restore balance."]
		],
		"hotspots": [
			["printer", "RUNNING PRINTER", [35, 83, 74, 70], [
				["NARRATION", "The printer feeds a staff photograph on thick, warm paper. The date in the corner is 1998. June stands in the back row wearing a college sweater she donated four years ago."],
				["JUNE", "That is me. Younger than I am now, in a photograph taken before I was born. The woman beside me has been scratched away so deeply there is a person-shaped hole."],
				["MARA / PHOTO CAPTION", "MERIDIAN LEDGER CLOSE TEAM. Replacements are cheaper than overtime. Smile until the flash. If the flash stays red, hold still until Compliance finishes counting."],
				["NARRATION", "On the reverse, forty-two employee numbers are written in pencil. The first belongs to Mara. The last belongs to June. Between them, the handwriting gradually changes into June's."],
				["JUNE", "I am taking this. If I get outside, I want one physical thing that cannot update itself while I am reading it."]
			]],
			["attendance", "ATTENDANCE BOARD", [131, 62, 64, 82], [
				["NARRATION", "Magnetic name strips fill the attendance board: Mara, Eli, June, then thirty-nine blank rectangles. June moves her strip from IN to OUT. It snaps back hard enough to pinch her finger."],
				["SYSTEM", "JUNE PARK — IN. Start: Sunday 22:48. End: pending reconciliation. Accrued shift: 01:10. Inherited shift: 168:00."],
				["JUNE", "Inherited from whom? Mara? The ticket did not transfer money. It transferred time. The system is treating her missing week like a debt somebody has to inhabit."],
				["NARRATION", "Eli Song's strip is warm and damp. Under it, six older strips bear six different names and the same smudged employee number."]
			]],
			["directory", "ELEVATOR DIRECTORY", [231, 41, 65, 91], [
				["NARRATION", "Brass letters loosen and crawl across black felt. Floors eight through twelve become DAY OPERATIONS. The blank between twelve and fourteen opens like an eyelid: 13 — NIGHT OPERATIONS."],
				["JUNE", "There. The new line. And one below Basement: zero, Retention. Buildings do not have a Floor Zero. Payroll systems do. A zeroed record is one they can pretend never existed."],
				["NARRATION", "The Floor 13 label is old brass polished by many fingers. June remembers the directory as smooth. She also remembers passing this label every morning and deliberately not seeing it."],
				["MARA / SCRATCHED NOTE", "THE BUILDING DOES NOT HIDE THE FLOOR. IT HIDES YOUR MEMORY OF AGREEING TO IT."]
			]],
			["camera", "SECURITY MONITOR", [201, 128, 96, 43], [
				["NARRATION", "The lobby feed is one minute ahead. Future June stands before the elevator, staring at this screen. Behind her, a tall suit-colored shape unfolds from the narrow seam between cubicles."],
				["JUNE", "If that is a live feed, I have one minute. If it is a prediction, maybe I can refuse to stand there. If it is a memory, I have already failed to leave."],
				["NARRATION", "The shape has no head, only a red horizontal scan line. It passes through chairs, desks, and plaster. Where it crosses June's future reflection, her employee number replaces her face."],
				["SECURITY CAPTION", "AUDITOR PROCESS 13. Retention scan active. Variance acquires shape only when observed. Observation logged."],
				["NARRATION", "On the real floor, a cubicle partition creaks. The red line is closer now."]
			]]
		],
		"transition": [
			["NARRATION", "The elevator opens. Its mirrored wall reflects a young man crouched behind June. The actual car is empty. When she turns, he stands ten feet away in the office."],
			["ELI", "Do not scream. It counts sudden changes. And please do not scan my badge. The Auditor follows badge pings."],
			["JUNE", "Who are you? Everyone went home."],
			["ELI", "I am Eli Song. I went home six Mondays ago. It keeps bringing me back before I reach Tuesday. If you can still remember the directory changing, we have maybe twenty minutes."]
		]
	},
	{
		"id": "breakroom", "chapter": "3 / 7", "place": "BREAK ROOM", "clock": "11:46 PM",
		"objective": "Decide whether Eli is a witness or a trap.",
		"opening": [
			["NARRATION", "Eli leads June into the break room, where the refrigerator motor masks their voices. Under green emergency light he looks twenty-two and exhausted enough to be ancient."],
			["ELI", "The clock gives back minutes when it wants you to investigate. Do not mistake that for mercy. It is building a record that says you understood the conditions."],
			["JUNE", "You knew Mara Vale's name before I said it."],
			["ELI", "Mara taught me where to hide. Every loop she gets a little harder to remember. Every loop the company gets better at using her voice."]
		],
		"hotspots": [
			["badge", "ELI'S BLANK BADGE", [221, 71, 51, 72], [
				["NARRATION", "Eli holds the badge under the vending machine's ultraviolet tube. Six layers of names emerge beneath his own: temporary interns, all assigned to Absence Replacement."],
				["ELI", "They reuse the card after the person stops matching it. First the camera forgets your face. Then coworkers remember an empty desk. Then your mother calls the office and accepts that she dialed the wrong number."],
				["JUNE", "Why keep wearing it?"],
				["ELI", "Doors only open for employees, and exits only open for people. The trick is staying both until you reach the lobby. Mara almost did. Rusk corrected her while she was holding the door."],
				["NARRATION", "The badge photo is not merely blank. Its white space is deeper than the plastic, a tiny illuminated room with something standing at the back."]
			]],
			["rota", "BREAK-ROOM ROTA", [28, 35, 76, 79], [
				["NARRATION", "The rota assigns chores by weekday: coffee, dishwasher, missing-person report. Monday belongs to Mara. Tuesday belongs to Eli. Wednesday belongs to June. No columns exist after Wednesday."],
				["ELI", "At first I thought it was cruel office humor. Then Tuesday never came. The missing-person report is a real chore. You fill it out for whoever sat here before you, and Compliance files it under voluntary departure."],
				["JUNE", "My name is written in ink that has already faded. Somebody scheduled my disappearance before my first shift."],
				["MARA / MARGIN NOTE", "Do not let them isolate the names. A pattern is evidence. A single missing employee is a personal tragedy they can administratively misplace."]
			]],
			["fridge", "FORTY-TWO LUNCHES", [117, 43, 75, 103], [
				["NARRATION", "Forty-two lunch bags line the refrigerator, each dated this same Sunday. One labeled JUNE contains her house key, a severance cheque for zero dollars, and a molar wrapped in a payslip."],
				["JUNE", "The key has the blue thread I tied around it. I used it to enter my apartment this morning. The tooth has a silver filling in the same place as mine."],
				["ELI", "Do not open mine. Last loop it contained a birthday card from my sister. She wrote that she was relieved I had never existed. I cannot read it twice and remain useful."],
				["NARRATION", "The bag marked MARA contains only a coil of dot-matrix paper. On every perforated sheet, one sentence repeats: I WAS HERE LONG ENOUGH TO BE OWED."],
				["JUNE", "Then we make the debt visible. Hours, wages, names. We do not argue with the thing about souls. We give it numbers it cannot comfortably erase."]
			]],
			["compliance_phone", "COMPLIANCE PHONE", [120, 135, 71, 31], [
				["NARRATION", "The wall phone has no keypad, only a badge reader and two lamps: green LISTED, red VARIANCE. Lifting the receiver plays Rusk's voice without ringing."],
				["RUSK / RECORDING", "Unlisted staff must be reported. Silence is participation. Participation creates shared liability. Meridian protects employees who promptly identify records that do not belong."],
				["ELI", "That is how it got the others. Not by chasing. By offering each person a smaller share of the blame. Scan me and it will let you believe you bought time."],
				["COMPLIANCE", "Analyst Park: unlisted personnel detected nearby. Reporting is confidential. Advancement consideration is automatic."],
				["JUNE", "The receiver is warm. It has been waiting for my hand."]
			]]
		],
		"choice": {
			"id": "eli_stance", "prompt": "Is Eli a witness—or an unlisted variance?",
			"a": ["TRUST — Give Eli the visitor badge", "TRUST"],
			"b": ["SUSPECT — Scan Eli for Compliance", "SUSPECT"]
		},
		"after": {
			"TRUST": [
				["JUNE", "Take my spare visitor badge. It will cover the blank photo without sending a personnel ping."],
				["ELI", "You decided I am a person with almost no evidence. I will try to deserve the procedural irregularity. If you refuse Compliance, take the stairs. I can hold the gate."],
				["NARRATION", "Under June's visitor pass, Eli's face returns to the plastic one pixel at a time. The green lamp remains dark. The refrigerator motor releases a long, relieved shudder."]
			],
			"SUSPECT": [
				["JUNE", "I cannot verify anything you said. Step away from the reader."],
				["NARRATION", "June touches Eli's badge to the phone. The red lamp wakes. His photograph loses its eyes, then mouth. A scanner line crawls under the door."],
				["ELI", "It never needed you to trust me. It needed you to practice calling a person a discrepancy."],
				["NARRATION", "Eli runs. The receiver keeps breathing after he is gone. Compliance adds REPORTING INITIATIVE to June's personnel file."]
			]
		},
		"transition": [
			["NARRATION", "Behind the vending machine, a service door clicks open. Cold blue server light cuts across the linoleum. The corridor beyond is much longer than the building."],
			["MARA / TERMINAL", "JUNE PARK. If you can read this, Eli reached you or Compliance used him to reach you. Either way, come before the original ledger finishes forgetting ink."]
		]
	},
	{
		"id": "server", "chapter": "4 / 7", "place": "SERVER CORRIDOR", "clock": "11:53 PM",
		"objective": "Answer Compliance's demand for the original ledger.",
		"opening": [
			["NARRATION", "Server fans push winter air through a corridor that cannot fit inside Meridian's floor plan. Blue status lamps blink like distant apartment windows. A red scan line travels along the floor."],
			["COMPLIANCE", "Active Analyst Park. Employee 013 remains unresolved. Produce the original ledger for correction. Cooperation protects permanent staff from temporary errors."],
			["JUNE", "There are no permanent staff here. There are people who have not been replaced yet."],
			["NARRATION", "The scanner pauses at her shoes as if considering the distinction, then continues into the wall."]
		],
		"hotspots": [
			["rack", "PERSONNEL RACK 13", [29, 42, 72, 109], [
				["NARRATION", "Rack 13 contains paper folders instead of hardware. Forty-two folders use the same job code. Every temporary analyst replaced the previous analyst's unexplained absence and became the next unexplained absence."],
				["JUNE", "One position, forty-two hires, no overlap, no exit interviews. Rusk has been rolling unpaid hours forward and calling each replacement responsible for the balance."],
				["NARRATION", "The approval signatures begin as Rusk's compact block letters. By folder thirty, the signature is a red scanner stripe. The system has been approving its own corrections."],
				["CONDITIONAL", "ELI_FOLDER"],
				["MARA / TAB NOTE", "Evidence page 13: replacement chronology. Copy the whole pattern. Compliance survives by forcing every witness to defend only their own name."]
			]],
			["terminal", "MARA'S TERMINAL", [121, 55, 84, 71], [
				["MARA", "You have my hours. I have your exit authorization. The system permits one active identity at midnight, because Rusk designed payroll around one chair instead of the people he cycled through it."],
				["JUNE", "Are you alive?"],
				["MARA", "That is an HR category, not an answer. I am present wherever an uncorrected copy remembers me. Right now that includes this terminal, two photographs, and you."],
				["MARA", "The Auditor is not a ghost. It is policy with enough electricity to move. Rusk fed it exceptions until the exceptions learned to ask for bodies."],
				["CONDITIONAL", "MARA_ELI"],
				["JUNE", "Tell me how to leave."],
				["MARA", "Do not leave as one frightened employee. Leave as evidence of forty-two. The original ledger is behind the vent. Your final decision must agree with the route you take, or it will classify your truth as partial."]
			]],
			["ledger", "ORIGINAL LEDGER", [225, 91, 72, 60], [
				["NARRATION", "Behind a loose vent lies dot-matrix paper stamped BEFORE. It records forty-two names, original hours, and Rusk's approvals. Mara's name is not absent; it is overwritten by June's temporary ID."],
				["JUNE", "The money was paid to a holding account called Retention. Every replacement generated another week of withheld wages. The missing payroll is not a side effect. It is the business model."],
				["MARA / LEDGER NOTE", "If this copy reaches daylight, Floor 13 cannot call us isolated errors. If Compliance eats it, the record will still remember that you chose who benefited from forgetting."],
				["NARRATION", "The perforated edges flutter in the server wind. At each redacted name, pale blue letters rise through the ink and remain visible: PRESENT."],
				["JUNE", "I can preserve it, but carrying it makes me a target. Of course. Evidence is just a witness that cannot run."]
			]],
			["intercom", "EMERGENCY INTERCOM", [109, 139, 97, 29], [
				["RUSK / RECORDING", "Night Operations exists to make daylight's numbers possible. Somebody always owns unpaid hours. Sign the correction and it will not be you—at least, not tonight."],
				["RUSK / RECORDING", "I objected in the beginning. Then I understood continuity. One employee suffers; hundreds receive correct cheques. A manager accepts the arithmetic nobody else can bear."],
				["JUNE", "A manager who believed that would say it live. A coward records it for the next person and schedules the file after he is gone."],
				["RUSK / RECORDING", "Supervisor Park, when you hear this again, train the next temporary analyst before close. Use the language about flexibility. It tests well."],
				["NARRATION", "The recording ends with a contract stamp and June's own voice saying, “Red rows are not people.” She has never said those words. Not yet."]
			]]
		],
		"choice": {
			"id": "compliance", "prompt": "Compliance demands Mara's original ledger.",
			"a": ["REFUSE — Preserve the ledger", "REFUSE"],
			"b": ["OBEY — Submit the correction", "OBEY"]
		},
		"after": {
			"REFUSE": [
				["JUNE", "Request denied. I am preserving the original as evidence of wage theft and falsified personnel records."],
				["COMPLIANCE", "HOSTILE WITNESS. Temporary protections revoked. Exit eligibility suspended."],
				["NARRATION", "June folds the pages inside her coat. Server lamps turn spectral blue. Three erased names restore themselves to the case log. The red scanner begins moving faster."],
				["MARA", "Good. It understands refusal only as another category, but categories can be appealed. People erased without a record cannot."]
			],
			"OBEY": [
				["JUNE", "Submit correction. Mara Vale—never employed."],
				["NARRATION", "The printer eats the original one perforation at a time. It produces June's permanent badge, warm as skin. The scanner turns blood red."],
				["COMPLIANCE", "SUCCESSION ELIGIBLE. Initiative recognized. Outstanding hours conditionally deferred."],
				["MARA", "You did not erase me. You erased the proof that Rusk needed forty-one others before you. Remember that when he offers you his chair."],
				["NARRATION", "Mara's voice collapses into a dial-up shriek. The badge prints one additional line: REPORTS TO JUNE PARK."]
			]
		},
		"transition": [
			["PA", "Midnight close initiated. All exits locked until active identity and outstanding absence balance."],
			["NARRATION", "The elevator opens and closes by itself. The stair alarm flashes without making sound. June has two routes to Rusk's impossible office, and both are waiting to learn her preference."]
		]
	},
	{
		"id": "lobby", "chapter": "5 / 7", "place": "ELEVATOR LOBBY", "clock": "12:00 AM",
		"objective": "Choose an escape route and accept what it reveals.",
		"opening": [
			["NARRATION", "At midnight, the office doors lock in sequence. The elevator display alternates between 13 and 0. The stair sign points both up and down."],
			["COMPLIANCE", "Evacuation is not required. Remaining on premises constitutes acceptance of reasonable corrective duties."],
			["JUNE", "Then I am not evacuating. I am conducting an investigation while looking urgently for a door."],
			["NARRATION", "In the directory glass, June's reflection already wears Rusk's red tie."]
		],
		"hotspots": [
			["firemap", "FIRE MAP", [24, 49, 74, 91], [
				["NARRATION", "The map shows stairs descending from fourteen directly to twelve. A handwritten thirteenth landing appears when June touches the glass: DO NOT COUNT THE STEPS. IT COUNTS BACK."],
				["JUNE", "The route inspection was signed by Mara, then overwritten by Rusk. A second annotation names forty-two coats stored on the landing. Replacement property, do not discard."],
				["NARRATION", "A blue line marks a path around every badge reader. It ends at the manager office and continues, impossibly, through the painted window."],
				["MARA / MAP NOTE", "The stairs remember bodies. The elevator remembers permissions. Pick the kind of evidence your final answer can defend."]
			]],
			["seal", "ELEVATOR SEAL", [223, 47, 70, 78], [
				["NARRATION", "The inspection date advances as June reads it. The inspector signature changes from Rusk to Mara to June. Beneath the seal is a keycard slot stained by years of removed labels."],
				["SYSTEM", "Car 13 certified for downward travel to Retention. Upward service to Night Operations requires management credential or accepted succession status."],
				["JUNE", "The elevator route is designed for whoever agrees to become management. If I go down, I may find the machinery that prints the blank badges—or only give it mine."],
				["NARRATION", "A low bell sounds. The elevator doors part one inch. Through the gap is not the car but a row of empty suits extending into blue darkness."]
			]],
			["route_phone", "RINGING PHONE", [119, 118, 78, 39], [
				["CONDITIONAL", "ROUTE_PHONE"],
				["NARRATION", "The coiled cord leads into the wall and continues behind the plaster like a black vein. Every time the phone rings, the red scanner in the office pauses to listen."],
				["JUNE", "Whether that voice is Eli or Compliance, it wants me to understand that the route is not a neutral hallway. It is testimony. What I find determines what I can honestly do next."]
			]],
			["glass", "DIRECTORY GLASS", [109, 39, 82, 66], [
				["NARRATION", "June's reflection wears Rusk's tie. Mara stands beside her without a face. The Auditor appears only as the narrow darkness separating them."],
				["AUDITOR", "A witness who accepts benefit becomes staff. Staff who reject duty become absence. There are no other categories."],
				["JUNE", "That is the whole trick, isn't it? You make the categories too small, then punish people for spilling over the edges."],
				["MARA", "It cannot imagine solidarity because solidarity does not fit in one employee field. Make it process more names than one chair can hold."],
				["NARRATION", "For one second Mara has a face: tired eyes, cropped hair, a small scar at the chin. Then the directory updates and she is brass lettering again."]
			]]
		],
		"choice": {
			"id": "escape_route", "prompt": "Which route will June investigate?",
			"a": ["STAIRS — Follow the witness marks", "STAIRS"],
			"b": ["ELEVATOR — Descend to Floor 0", "ELEVATOR"]
		},
		"after": {
			"STAIRS": [
				["NARRATION", "June enters the concrete stairwell. The thirteenth landing appears after twelve and before twelve again. Forty-two coats hang from pipes, each with a name carved beneath it."],
				["CONDITIONAL", "STAIR_HELP"],
				["JUNE", "Mara Vale. Eli Song. Anika Bose. Tom Reyes. Leanne Wu. One name per step. I will not let the count turn them into a total."],
				["NARRATION", "Each spoken name restores a color to the landing. Beneath the last coat, June finds the complete replacement list and carries it upward."]
			],
			"ELEVATOR": [
				["NARRATION", "June enters the car. It descends below Basement without moving. Floor 0 opens on rows of badge printers stamping blank white faces."],
				["COMPLIANCE", "Retention stores reusable identity materials. Personal effects become company property upon voluntary absence."],
				["JUNE", "These are not materials. Teeth, keys, handwriting samples, family recordings—you kept enough of each person to manufacture consent."],
				["NARRATION", "An empty suit hangs before the last printer. Rusk's master keycard is clipped to its breast. June takes it. The suit collapses, relieved of its only remaining credential."],
				["NARRATION", "The doors close. When they reopen, the display reads 13 although the car never moved. Rusk's keycard pulses red in June's hand."]
			]
		},
		"transition": [
			["NARRATION", "The selected route delivers June to a walnut door that was never part of the office. Gold letters assemble across it: SUPERVISOR PARK."],
			["AUDITOR", "Final reconciliation prepared. Enter to accept resignation or succession."]
		]
	},
	{
		"id": "stairs", "chapter": "6 / 7", "place": "THIRTEENTH LANDING", "clock": "12:01 AM",
		"objective": "Carry the route's evidence through the impossible landing.",
		"opening": [
			["NARRATION", "Every route ends at the same impossible landing. Concrete steps climb behind the elevator doors; brass elevator panels gleam inside the stairwell. The building has stopped pretending these spaces are separate."],
			["JUNE", "This is where the choice becomes part of the record. Stairs gave me names. The elevator gave me authority. Either one can become evidence or an excuse."],
			["NARRATION", "Coats sway without wind. Blank badges tap against buttons. Above, false daylight shines beneath the manager-office door."],
			["AUDITOR", "Proceed. Outstanding hours increase during hesitation."]
		],
		"hotspots": [
			["coats", "FORTY-TWO COATS", [23, 49, 88, 99], [
				["NARRATION", "Forty-two coats range from winter wool to a thin summer cardigan. Pockets hold transit cards, cough drops, daycare receipts, and folded notes reminding someone to buy milk after work."],
				["JUNE", "Ordinary things. That is what the folders removed. Nobody was a replacement unit. They were people planning to go somewhere after this shift."],
				["CONDITIONAL", "COAT_EVIDENCE"],
				["MARA", "Rusk called personal details irrelevant. The Auditor learned that irrelevance meant permission. Carry something it cannot translate into hours."],
				["NARRATION", "June pockets a daycare drawing of forty-two stick figures under a blue sky. One red figure waits inside a square office."]
			]],
			["alarm", "SILENT ALARM", [131, 43, 55, 52], [
				["NARRATION", "The alarm flashes faster than a heartbeat but produces no sound. Its inspection tag says: SILENCE INDICATES EMPLOYEE CONSENT."],
				["JUNE", "Silence means the speaker was disconnected. Absence means somebody is missing. A blank field means someone deleted the answer. You built a company out of deliberate mistranslation."],
				["AUDITOR", "Objection is not a payroll state."],
				["JUNE", "Then your payroll is not large enough for what is happening to it."],
				["NARRATION", "The alarm emits one clear note. Across the office, every desk phone begins ringing."]
			]],
			["steps", "REPEATING STEPS", [203, 71, 85, 89], [
				["NARRATION", "The steps repeat in groups of thirteen. Counting backward returns June to the same landing. Speaking names advances the door; reciting employee numbers moves it farther away."],
				["JUNE", "Anika Bose. Tom Reyes. Leanne Wu. Devon Clarke. Halima Noor. I do not know your stories, but I know the system benefited from making me think there was only Mara."],
				["NARRATION", "Blue footprints appear ahead of June. Red prints follow behind. Neither set belongs to her shoes. At the final step, they overlap and become ordinary wet marks from the rain."],
				["MARA", "That is far enough. The rest is not escape. It is the answer you carry into Rusk's office."]
			]],
			["gate", "MANAGER GATE", [113, 117, 82, 44], [
				["NARRATION", "The gate has two readers: WITNESS and MANAGEMENT. June's evidence opens one. Her chosen route opens the other. The lock waits to see which identity she presents."],
				["CONDITIONAL", "GATE_RESULT"],
				["JUNE", "No route is pure. The stairs needed a badge. The elevator contained personal effects. The difference is what I claim those things authorize me to do."],
				["AUDITOR", "Authorization acknowledged. Moral interpretation discarded."],
				["JUNE", "Keep it. I am bringing my own interpretation."]
			]]
		],
		"transition": [
			["NARRATION", "The gate opens onto carpet and false sunlight. The smell of Rusk's cedar cologne survives him. A contract waits beneath a pen chained to the desk."],
			["MARA", "Whatever you choose, choose a whole story. Partial truths are how it keeps Monday alive."]
		]
	},
	{
		"id": "manager", "chapter": "7 / 7", "place": "MANAGER OFFICE", "clock": "12:02 AM",
		"objective": "End the shift: reject the inherited hours or accept the chair.",
		"opening": [
			["NARRATION", "Rusk's office is a perfect daylight set at midnight: painted sun on the windows, plastic plants, family photographs containing every temporary analyst. The desk nameplate waits blank."],
			["NARRATION", "The Auditor stands behind the chair as a column of suit-dark pixels crossed by a red scanner. It has no face because the company never needed one."],
			["AUDITOR", "One role. One active employee. One absence. Balance the record. Resignation transfers liability backward. Succession transfers liability forward."],
			["JUNE", "And telling the truth transfers liability to the people who designed this."]
		],
		"hotspots": [
			["outbox", "RUSK'S OUTBOX", [28, 106, 78, 51], [
				["NARRATION", "The outbox contains forty-one resignation forms and one empty slot. Every form cites voluntary abandonment at exactly midnight. The signatures begin differently, then converge into June's handwriting."],
				["JUNE", "The forms were not written by forty-one people. The system trained one signature from all of them, then printed whatever consent each correction required."],
				["AUDITOR", "Authenticated signature exceeds unreliable memory."],
				["JUNE", "A signature assembled from stolen samples authenticates the theft."],
				["NARRATION", "The empty slot labels itself JUNE PARK. The pre-signed form in June's pocket pulls toward it like a magnet."]
			]],
			["photos", "FAMILY PHOTOGRAPHS", [122, 45, 75, 69], [
				["NARRATION", "Each photograph shows Rusk with a different analyst and the same birthday cake. In the newest, June holds the knife. The candles spell 168."],
				["CONDITIONAL", "PHOTO_ROUTE"],
				["MARA", "He kept souvenirs while telling Payroll we were duplicate records. The photographs remember attachment. The cheques remember profit. Either can expose him if you refuse his framing."],
				["JUNE", "Or either can become the reason I tell myself taking his job is justice. That is the trap after the trap: confusing possession of evidence with permission to control the next person."]
			]],
			["contract", "MIDNIGHT CONTRACT", [203, 88, 91, 67], [
				["NARRATION", "The contract offers permanent manager status, health insurance, and responsibility for all unresolved hours. Final clause: MANAGER REMAINS UNTIL A QUALIFIED REPLACEMENT ACCEPTS ENTRY."],
				["AUDITOR", "Succession provides safety, compensation, and authority to improve future procedure. Refusal provides uncertainty, reputational risk, and no guaranteed exit."],
				["JUNE", "You have learned benefit language. You still mean that someone else enters the loop so I can step out."],
				["NARRATION", "The salary field equals the exact total of forty-two withheld paycheques. The pen is filled with red correction ink."],
				["MARA", "You can sign and free one person. You can refuse and try to free the record. Neither promise is safe. Only one makes the next worker pay for tonight."]
			]],
			["window", "PAINTED WINDOW", [101, 125, 87, 37], [
				["NARRATION", "Behind painted daylight is real rainy darkness. Far below, the lobby shutter is half open. Mara waits outside the glass, rendered in blue monitor light."],
				["CONDITIONAL", "WINDOW_ELI"],
				["JUNE", "The outside is still there. Monday is not a cosmic law. It is a locked door, a false record, and people with reasons to keep both closed."],
				["AUDITOR", "External conditions cannot be verified from active floor."],
				["JUNE", "Then I will verify them from outside."]
			]]
		],
		"choice": {
			"id": "contract", "prompt": "What story will June make complete?",
			"a": ["RESIGN — Reject all inherited hours", "RESIGN"],
			"b": ["SIGN — Accept Night Operations", "SIGN"]
		},
		"after": {
			"RESIGN": [
				["JUNE", "I reject the premise that absence transfers debt. I reject this forged resignation. I reject every correction that made stolen labor look like an empty cell."],
				["NARRATION", "June tears her pre-signed form in half and writes all forty-two names across the contract. Blue letters push through the red ink."],
				["AUDITOR", "Multiple active identities exceed role capacity. Processing delay."],
				["MARA", "A delay is enough, if you brought the whole record."]
			],
			"SIGN": [
				["JUNE", "I accept Night Operations and responsibility for close."],
				["NARRATION", "The pen moves easily. Rusk's keycard or June's permanent badge pulses in approval. The manager tie in the reflection becomes real cloth around her neck."],
				["AUDITOR", "Supervisor Park recognized. Previous absence eligible for release. Onboarding materials prepared."],
				["MARA", "Then remember this was a choice, even when it edits your reason."]
			]
		}
	}
]

const ENDINGS := {
	"CLOCK_OUT": [
		["SYSTEM", "FULL RECORD ACCEPTED. FORTY-TWO CONCURRENT WITNESSES. AUDITOR CAPACITY EXCEEDED."],
		["NARRATION", "June feeds the original ledger and replacement list into Rusk's fax. Mara routes it to every payroll inbox and the labor board. Forty-two monitors wake, each restoring one name in spectral blue."],
		["ELI", "The stair gate is open. I can hold it, but I do not think it is trying to close anymore."],
		["NARRATION", "The Auditor's red scan line breaks into harmless copier light. Its suit silhouette separates into a coat rack, a dead scanner, and the shadow of an empty chair."],
		["MARA", "Forty-two names. Read them. Not because the machine needs them. Because we do."],
		["JUNE", "Mara Vale. Eli Song. Anika Bose. Tom Reyes. Leanne Wu. Halima Noor. The other names scroll beside them, no longer hidden behind employee numbers."],
		["NARRATION", "June walks through the open office. Chairs turn toward the rainy windows instead of her. Printer trays fill with wage statements, complaint forms, and copies that refuse to correct themselves."],
		["NARRATION", "In the lobby, the visitor book changes JUNE PARK from IN to OUT at Monday 00:03. Eli's line gains OUT. Mara's gains a different word: PRESENT."],
		["MARA", "I do not know what present means for me yet. It is enough that somebody else has to answer the question."],
		["NARRATION", "Outside, dawn is ordinary gray. Meridian opens with forty-two claims for back pay and no supervisor willing to explain Floor 13. June never accepts another flexible night shift."],
		["END", "CLOCK OUT\nTHE RECORD REMEMBERS\nMonday · 12:03 AM"]
	],
	"NEW_MANAGER": [
		["SYSTEM", "SUCCESSION COMPLETE. OUTSTANDING VARIANCE TRANSFERRED. WELCOME, SUPERVISOR PARK."],
		["NARRATION", "The painted sun snaps on. June's badge prints with a new title. The corrected ledger becomes white confetti that falls upward into the ceiling vents."],
		["NARRATION", "The elevator opens. Mara steps out, restored by June's accepted identity exchange. She pauses at the threshold but does not look back."],
		["MARA", "You freed me with the same correction that trapped you. That does not make it mercy. It makes the arithmetic complete."],
		["NARRATION", "Eli's blank badge slides from the compliance phone and lands in Rusk's outbox. June tries to remember whether she ever saw his face. The record supplies a confident no."],
		["AUDITOR", "First management duty: onboard active replacement. Use approved language. Emphasize flexibility and advancement."],
		["NARRATION", "The Auditor adjusts June's red tie in the window reflection and dissolves into her shadow. Warm office lights rise. Every clock remains at 11:59."],
		["NARRATION", "Downstairs, a new temporary analyst enters from the rain, shaking water from an umbrella. She signs the visitor book without noticing forty-two erased lines."],
		["JUNE", "Go home. Please. Do not take the elevator."],
		["NARRATION", "That is what June tries to say. The reception speaker uses her voice for different words."],
		["JUNE / RECEPTION", "Welcome to Meridian Ledger. Red rows are not people. They are variance. Your flexible close should take five minutes."],
		["END", "THE NEW MANAGER\nMONDAY NEEDS A SUPERVISOR\nCurrent time · 11:59 PM"]
	],
	"MONDAY_FOREVER": [
		["AUDITOR", "PARTIAL RECORD. ROUTE AND DECLARATION CONFLICT. Half a record rounds down."],
		["NARRATION", "June's evidence contradicts her contract. The ledger remembers people while her signature accepts replacement, or the manager credential promises authority while her resignation denies its cost."],
		["JUNE", "No. Let me restate it. Give me one minute."],
		["AUDITOR", "One minute granted."],
		["NARRATION", "June reaches the lobby at 00:01. The shutter rises, not onto the street, but onto the same office at Sunday 11:48 PM. Rain climbs upward outside."],
		["CONDITIONAL", "LOOP_COMPANION"],
		["NARRATION", "The visitor book adds another JUNE PARK — IN. The office palette loses one color. The case log keeps every choice, proof that the loop is consequence rather than mercy or reset."],
		["PA", "Temporary analyst June Park, please report to your assigned cubicle. One last ticket remains before close."],
		["NARRATION", "At her desk, Ticket 1313 opens. Employee 013 now reads JUNE PARK. Mara Vale is the active analyst assigned to correct her."],
		["MARA", "I feel as if we have done this before."],
		["JUNE", "We have. Next time I choose a whole story."],
		["NARRATION", "The clock changes to 11:59 and refuses to carry the promise any farther."],
		["END", "MONDAY FOREVER\nCURRENT SHIFT · 169:00:00\nVARIANCE PENDING"]
	]
}

static func total_hotspots() -> int:
	var total := 0
	for area in AREAS:
		total += area.hotspots.size()
	return total

static func resolve(flags: Dictionary) -> String:
	if flags.get("eli_stance") == "TRUST" and flags.get("compliance") == "REFUSE" and flags.get("escape_route") == "STAIRS" and flags.get("contract") == "RESIGN":
		return "CLOCK_OUT"
	if flags.get("eli_stance") == "SUSPECT" and flags.get("compliance") == "OBEY" and flags.get("escape_route") == "ELEVATOR" and flags.get("contract") == "SIGN":
		return "NEW_MANAGER"
	return "MONDAY_FOREVER"

static func word_count() -> int:
	var count := 0
	for area in AREAS:
		for line in area.opening:
			count += _words(line[1])
		for hotspot in area.hotspots:
			for line in hotspot[4]:
				count += _words(line[1])
		for line in area.get("transition", []):
			count += _words(line[1])
		for branch in area.get("after", {}).values():
			for line in branch:
				count += _words(line[1])
	for ending in ENDINGS.values():
		for line in ending:
			count += _words(line[1])
	return count

static func route_word_count(flags: Dictionary) -> int:
	var count := 0
	for area in AREAS:
		for line in area.opening:
			count += _words(line[1])
		for hotspot in area.hotspots:
			for line in hotspot[4]:
				if line[0] != "CONDITIONAL":
					count += _words(line[1])
		for line in area.get("transition", []):
			count += _words(line[1])
		if area.has("choice"):
			var chosen := str(flags.get(area.choice.id, area.choice.a[1]))
			for line in area.after.get(chosen, []):
				if line[0] != "CONDITIONAL":
					count += _words(line[1])
	var ending_id := resolve(flags)
	for line in ENDINGS[ending_id]:
		if line[0] != "CONDITIONAL":
			count += _words(line[1])
	# Conditional pages average 25 words and are always expanded at runtime.
	count += 10 * 25
	return count

static func _words(text: String) -> int:
	return text.replace("\n", " ").split(" ", false).size()
