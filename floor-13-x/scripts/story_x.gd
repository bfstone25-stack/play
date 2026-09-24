## story_x.gd — the adult fork's writing, spliced into StoryData.AREAS at startup.
##
## Kept in its own file rather than edited into story_data.gd line by line so that the base
## script stays diffable against the mainstream game: everything in here is an addition,
## nothing in here is a replacement, and `patch()` is the only place the two meet. Three
## small inline edits could not be done this way and live in story_data.gd itself — Eli's
## age, the drawer's two lines, and the quarter-inch in the office transition — each marked
## with a `## [fork]` comment where it sits.
##
## The fiction, from ops/adult_forks/floor-13.md §2: the building's own stated rule is that
## variance acquires shape only when observed. Retention takes the record of having been
## touched before it takes the name, so an employee it has processed can still be seen,
## heard and argued with — and goes unfelt. Being witnessed at close range, out of the
## uniform the building issues you, puts weight back into a body the ledger had zeroed.
## Nothing here is a reward attached to a horror game; it is the horror game's own rule
## pointed one direction further.
##
## Every character is an adult and is written as one: June Park 29, Eli Song 31, Mara Vale
## 34. Consensual throughout. Supervisor Rusk stays a voice on tape and is never sexualised
## — he is the wage thief, and making him a seducer would turn a story about theft into a
## story about a man. The Auditor never touches anyone and never shares a frame with any of
## this.
class_name StoryX
extends RefCounted

## File 3. The new hotspot, inspected before the eli_stance choice; seeing it is half of
## what earns cg_breakroom_x (ops/adult_forks/floor-13.md §4, slot 1).
const COAT_HOTSPOT := ["coat", "ELI'S COAT", [28, 122, 76, 46], [
	["NARRATION", "Eli's coat is over the back of the plastic chair, still wet at the shoulders from a rain that stopped four hours ago. The lining is warm. Nothing else in the break room is."],
	["JUNE", "You came in from outside. Tonight. That is not six Mondays ago, that is tonight, and it means the building let you back through a door."],
	["ELI", "It lets me in. It has never once let me out. Six times I have reached the lobby and six times the lobby has been eleven forty-eight."],
	["NARRATION", "June reaches for the collar to check the label. Her fingers close a quarter of an inch short of the fabric and keep going, and the coat swings on the chair a half second after they should have touched it."],
	["ELI", "Do not do that again. Please. It is not that you cannot touch me. It is that the record of it does not survive to the end of the motion, so it never quite finishes happening."],
	["ELI", "Retention takes it first. Before the name, before the payslip, before your mother's phone book. The evidence that somebody's hand was on you — that goes first, because it is the cheapest thing to lose and the hardest thing to prove was ever there."],
	["JUNE", "And if somebody watched it happen. If there were two of us and one of us was looking."],
	["ELI", "Then it is observed, and the thing downstairs is very specific about what observation does. I have not had that in six weeks. I am telling you because you asked what the coat was doing wet, not because I am asking for it."]
]]

## File 3. The fork's first scene, appended to the TRUST branch of the eli_stance choice —
## after the base game's own line about Eli's face returning to the plastic, before
## route.next. The plate lands at the end of it, once, in the scene where it happens.
const BREAKROOM_TRUST := [
	["NARRATION", "The refrigerator motor cuts out. In the silence the break room stops sounding like a room in an office and starts sounding like a room, and neither of them says anything for a while."],
	["JUNE", "Sit down. I want to try something and I want you to tell me to stop if it is a bad idea, because I have been in this building for thirteen hours and I have stopped being able to tell."],
	["ELI", "It is a bad idea. I would like you to try it anyway. Those are both true and I am too tired to pretend they are not."],
	["NARRATION", "He sits on the counter's edge under the ultraviolet tube. June takes the lanyard over his head and puts it on the counter face-down, and the blank badge stops being between them."],
	["JUNE", "That is the part it issued you. The card, the shirt it wants buttoned, the coat that is company-coloured. I want to see what is left when the part it issued is on the counter."],
	["ELI", "There is not much left. That is the honest answer. Six weeks of the same Monday and I am mostly the badge."],
	["JUNE", "Then I will look at the rest until there is more of it. I am a payroll analyst. Making an undercounted thing count properly is the entire job."],
	["NARRATION", "She works the shirt open to the third button and stops there, and pushes the collar back off one shoulder, and that is as far as either of them takes it. The green emergency light finds a collarbone and a bad night's sleep and the mark where a lanyard has sat for six weeks without moving."],
	["ELI", "You are looking at my shoulder like it is a column that does not balance."],
	["JUNE", "It does not. There is a person's worth of hours in you and the record says nobody has been within a quarter inch of them since August."],
	["NARRATION", "Her hand goes to his wrist. It lands. It stays landed. His breath goes out of him all at once, the way it does when a number you have been carrying finally comes off the sheet, and his head goes back against the vending machine glass with his eyes shut."],
	["ELI", "It held. June. It held all the way to the end of the motion."],
	["JUNE", "I am still here. I am still looking. It does not get to file that as an absence while I am looking at it."],
	["NARRATION", "Under the UV tube the six older names beneath his own do not surface. For as long as this takes, the badge on the counter is only a piece of plastic with nothing standing at the back of it."],
	["CG", "cg_breakroom_x"],
	["ELI", "Do not say anything procedural for a minute. I know you want to. I can hear you wanting to."],
	["JUNE", "I was going to say that whatever this is, it is evidence, and I am going to need you to still be here in an hour to corroborate it."],
	["ELI", "That is the most romantic sentence anyone has said to me in six Mondays, and I want you to understand what that says about the six Mondays."],
	["NARRATION", "He buttons the shirt wrong on the way back up and does not fix it. The refrigerator motor comes back on. The blank badge stays face-down on the counter, and the green lamp on the compliance phone stays dark."],
]

## File 3. The cold counterpart. Reporting Eli closes three of the seven plates for the rest
## of the run (§4), and the game says so in its own voice rather than in a menu.
const BREAKROOM_SUSPECT := [
	["NARRATION", "In the corridor, his coat is still over the chair. It is dry now, and light, and weighs nothing at all when June lifts it, because there is no longer a record of anyone having worn it in from the rain."],
	["JUNE", "I did the procedure. I did the correct, documented, career-protecting procedure, and the procedure was the thing it wanted from me all along."],
	["MARA / TERMINAL", "It never needed you to be cruel. It needed one more person willing to file a body as a discrepancy. Six of us learned that. You learned it in forty minutes."],
]

## File 4. The terminal's second pass. The base game already carries a CONDITIONAL /
## MARA_ELI variant mechanism for exactly this "the second read differs" case; game.gd
## reopens the terminal hotspot after the compliance choice and serves these lines instead.
## Earns cg_terminal_x when the ledger was preserved (§4, slot 2).
const TERMINAL_SECOND_PRESERVED := [
	["NARRATION", "The terminal has been dark since Compliance stopped asking. June puts the folded ledger on the desk beside it and the screen comes up without being touched, and for the first time the cursor is not moving half a beat behind hers."],
	["MARA", "You kept it. Forty-two names, original hours, Rusk's approvals, all of it, on paper, outside the system. Do you understand what you are holding."],
	["JUNE", "An uncorrected copy."],
	["MARA", "An uncorrected copy that remembers me. I told you I am present wherever one of those is. There has not been one on this floor in eleven months."],
	["NARRATION", "The blue status lamps along the corridor come on in sequence, and the cold moves out of the air, and the corridor stops being longer than the building. Between two racks, where there has only ever been a voice, there is a woman with cropped hair and a small scar at the chin, holding on to the rack frame as if the floor is a new idea."],
	["JUNE", "Mara Vale."],
	["MARA", "Employee 013. Say it again. It is doing something."],
	["JUNE", "Mara Vale. Thirty-four. One hundred and sixty-eight hours, all of them yours, all of them owed."],
	["NARRATION", "She is not translucent at the edges any more, and then she is, and then she is not. It is not steady. It is the difference between a record and a copy of a record, and it holds only for as long as somebody is reading it."],
	["MARA", "It goes when you stop looking. I am not being poetic, I am telling you the operating condition. Keep your eyes on me and I have a body; look at the ledger and I am a file again."],
	["JUNE", "Then I am not going to look at the ledger."],
	["NARRATION", "Mara gets the blouse off her arms with the careful attention of somebody using hands for the first time in a year, and holds it, and does not put it down — one garment still accounted for, one hand still occupied, the other arm across herself, the blue rim light doing the rest."],
	["MARA", "Eleven months of being a voice with an opinion. Come here and put your hand flat on my sternum and tell me whether there is anything under it."],
	["JUNE", "There is."],
	["MARA", "Louder. It logs the observation, not the intention, and I have waited eleven months for something to be logged in my favour."],
	["JUNE", "There is a heartbeat under my hand and I am looking directly at you and I am prepared to say both of those things to a labour board."],
	["CG", "cg_terminal_x"],
	["NARRATION", "The corridor holds its length. Somewhere above them a printer that has been feeding blank paper into an empty tray since eleven o'clock stops, and does not start again."],
	["MARA", "That is the first hour of my life since August that the building has had to account for. Whatever else happens tonight, it has to account for that hour."],
	["JUNE", "It is going to account for one hundred and sixty-eight of them."],
]

## File 4. What the second pass says when the ledger went into the printer instead. No
## plate: there is no uncorrected copy left to remember her by, and the fork does not
## pretend otherwise.
const TERMINAL_SECOND_SURRENDERED := [
	["NARRATION", "The terminal comes up grey. The cursor is half a beat behind June's again, and this time there is nothing on the other end of it that is arguing."],
	["MARA", "There is no uncorrected copy on this floor any more. I am not angry. I am a file, and files are not issued that."],
	["JUNE", "I can describe you. I remember the scar. I remember the hours."],
	["MARA", "Memory is not a record, and this building has spent forty-two people teaching itself the difference. Go upstairs. Whatever you tell Rusk's office, tell it whole."],
]

## File 5. A beat before the transition on each route. The ELEVATOR beat is the mirror of
## the landing: the route that took authority instead of names gets Mara, not Eli, and it
## earns cg_retention_x (§4, slot 4).
const LOBBY_ELEVATOR := [
	["NARRATION", "The keycard is warm. Behind the last printer, where the empty suit has just come off its hanger, something that has been standing very still for eleven months stops standing still."],
	["MARA", "You brought a manager's credential into the room where they keep the parts. That is either the worst decision of your night or the only one it did not predict."],
	["JUNE", "Both. It has always been both. Mara — the printers stopped when I came in. All of them. At once."],
	["MARA", "Because you are looking at the room instead of at the rack, and the room has me in it. Retention keeps enough of a person to manufacture consent. It kept a coat, a keycard, a handwriting sample, and the fact that nobody has touched me since the ninth of August."],
	["NARRATION", "She comes forward out of the rows of machines into the one warm light in a building full of cold ones, with the blouse down off her shoulders and one arm across herself and the other hand out, open, waiting to find out whether the reaching will land."],
	["MARA", "It kept that last one on a shelf, June. Filed. Recoverable. Come and take it off the shelf."],
	["JUNE", "Chin up. I want it logged that I was looking at your face."],
	["NARRATION", "Her hand lands in June's. It stays landed. Above them the surveillance camera in the ceiling corner swivels, finds them, and records the two of them as two, which is the one thing Floor 0 was built to make impossible."],
	["CG", "cg_retention_x"],
	["MARA", "Two active identities. Say nothing to it about souls. It does not process those. Say two."],
	["JUNE", "Two."],
	["NARRATION", "The empty suit finishes collapsing, relieved of its only remaining credential and of something else it had been holding that nobody had itemised."],
]

const LOBBY_STAIRS := [
	["NARRATION", "Forty-two coats, and one of them is still damp at the shoulders. June knows the weight of that one now. She takes it off the pipe and carries it up with the list."],
	["ELI / PHONE", "You found it. I wondered whether it would still be there once somebody had touched me. Some of the others went off the pipe the same night."],
	["JUNE", "It is heavy, Eli. It is a heavy coat. Two hours ago it weighed nothing."],
	["ELI", "Then keep hold of it, and keep the gate open, and I will meet you on the landing. I can hold one gate for ninety heartbeats. I still refuse to call them seconds."],
]

## File 6. The landing scene, on the stairs route with the replacement list carried up and
## the coats' own evidence line read. Earns cg_landing_x (§4, slot 3).
const LANDING_SCENE := [
	["NARRATION", "The thirteenth landing is four degrees colder than the stairwell on either side of it, which is the kind of detail Facilities would have had to certify if the landing existed. Eli is holding the gate with his back against it and his coat is over June's arm."],
	["ELI", "Ninety heartbeats. Mine, and they have been unreliable for six weeks, so do not take the number as a warranty."],
	["JUNE", "Then stop holding the gate for a minute and let it try to close. I want to know whether it still can."],
	["NARRATION", "He lets go. The gate does not move. Above them the bare bulb steadies, and the landing keeps its colour instead of resetting, because two people are remembering the same sequence in the same place at the same time and the building has no procedure for that."],
	["JUNE", "Anika Bose. Tom Reyes. Leanne Wu. Devon Clarke. Halima Noor. Mara Vale. Eli Song. Eli Song. Eli Song."],
	["ELI", "Three times."],
	["JUNE", "Once for the record, once because the record has been wrong for six weeks, and once because I wanted to."],
	["NARRATION", "It is cold enough on the landing to see their breath, so they use the coats. Not for modesty and not for warmth exactly — there are forty-two of them on the pipes, and each one belonged to somebody who was planning to go somewhere after this shift, and putting one on somebody is the most specific way there is of saying you intend to be somewhere afterwards."],
	["ELI", "This one is Leanne's. The name is carved under the hook."],
	["JUNE", "Then Leanne's coat is going around your shoulders and it is staying there, and when we are outside I am going to find out what happened to Leanne."],
	["NARRATION", "They kneel on concrete with their backs to the gate and the coats going on over bare shoulders, two people getting dressed in other people's clothes in a stairwell at one in the morning, foreheads together, holding the fronts of the coats closed against a cold that four degrees does not entirely explain."],
	["CG", "cg_landing_x"],
	["ELI", "The count has stopped. The steps repeat in thirteens and it has stopped."],
	["JUNE", "Because there are two of us and neither of us is counting. Get up. We are going to Rusk's office wearing forty-two people's coats and we are going to make it itemise every one of them."],
]

## File 7. One beat per ending, inside the existing ending text. Slots 5, 6 and 7.
const ENDING_BEATS := {
	"CLOCK_OUT": {
		"after_line": "I do not know what present means for me yet. It is enough that somebody else has to answer the question.",
		"lines": [
			["NARRATION", "Outside the lobby doors it is raining the ordinary amount. Eli's shirt is buttoned wrong and has been since eleven forty-six and neither of them has mentioned it. Mara is in a coat that is two sizes wrong and belonged to Devon Clarke."],
			["JUNE", "Visitor book. All three of us, out, one minute apart, in ink, in a physical book that does not have a network connection."],
			["MARA", "Write mine last. I want to see how long it stays."],
			["NARRATION", "It stays. June keeps her hand on Mara's arm while she writes, because the operating condition has not changed and nobody is pretending it has, and Eli keeps the door open with his shoulder the way he held the gate."],
			["ELI", "Is anybody going to say the thing."],
			["JUNE", "The thing is that I am owed one hundred and sixty-eight hours of somebody else's week and the three of us are going to a labour board at nine. That is the thing. Everything else can be said after nine."],
			["CG", "cg_present_x"],
		],
	},
	"NEW_MANAGER": {
		"after_line": "Then remember this was a choice, even when it edits your reason.",
		"lines": [
			["NARRATION", "The painted sun is warm on one side of June's face. The office is exactly the temperature a room is when nobody has been cold in it. The tie in the reflection has become real cloth, and it is the only thing in the room the building is still willing to let her feel."],
			["AUDITOR", "Supervisor Park. Onboarding materials prepared. Personal effects from the previous occupant have been retained and are available for authorisation."],
			["JUNE", "I do not want his effects."],
			["AUDITOR", "Noted. Authorisation is not a preference. Retention has been instructed to begin with the record of contact, as standard."],
			["NARRATION", "She sits on the desk in the false daylight with the tie loose around her neck and the pen still in her hand, looking at the window instead of at the room, and finds that she cannot remember with any precision what a hand on her wrist felt like two hours ago in a break room, and that the failure to remember does not frighten her the way it should."],
			["JUNE", "It is going first, is it not. The record of it."],
			["AUDITOR", "It is the cheapest item and the hardest to prove was present. Standard order. Welcome to Meridian Ledger."],
			["CG", "cg_desk_x"],
		],
	},
	"MONDAY_FOREVER": {
		"after_line": "We have. Next time I choose a whole story.",
		"lines": [
			["NARRATION", "At eleven fifty-nine the office is forty chairs and forty monitors and one lit cubicle, and June is asleep on her arms across Ticket 1313 with her blouse off one shoulder where the lanyard has dragged it."],
			["NARRATION", "Nothing is looking at her. That is the whole of it. The scan line has been through twice and marked the desk PRESENT and the chair PRESENT and has not marked her anything, because there is no second party to the observation and the building does not count itself."],
			["MARA / TERMINAL", "Half a record rounds down. I told you. Sleep if you can — it is the one hour of the loop it does not bill."],
			["CG", "cg_monday_x"],
		],
	},
}


## Splice the fork's additions into a copy of the base area list.
##
## Additive only: one new hotspot, four extended `after` branches, and a stash of the
## second-pass and scene text that game.gd pulls at its own hooks. Nothing the base game
## wrote is removed here.
## 2026-09-23: every line this file adds goes out through Loc.s, so zh and ja read the
## fork's own writing in their language (locale/story_{zh,ja}.json), not English spliced
## into a translated night.
static func _L(lines: Array) -> Array:
	var out: Array = []
	for line in lines:
		var l: Array = (line as Array).duplicate(true)
		for i in l.size():
			if l[i] is String:
				l[i] = Loc.s(l[i])
		out.append(l)
	return out


static func patch(areas: Array) -> Array:
	var out: Array = areas.duplicate(true)
	for area in out:
		match str(area.id):
			"breakroom":
				var coat: Array = COAT_HOTSPOT.duplicate(true)
				coat[1] = Loc.s(str(coat[1]))
				coat[3] = _L(coat[3])
				area.hotspots.append(coat)
				area.after["TRUST"] = (area.after["TRUST"] as Array) + _L(BREAKROOM_TRUST)
				area.after["SUSPECT"] = (area.after["SUSPECT"] as Array) + _L(BREAKROOM_SUSPECT)
			"lobby":
				area.after["STAIRS"] = (area.after["STAIRS"] as Array) + _L(LOBBY_STAIRS)
				area.after["ELEVATOR"] = (area.after["ELEVATOR"] as Array) + _L(LOBBY_ELEVATOR)
	return out


## The second read of Mara's terminal, after the compliance choice has been made.
static func terminal_second(flags: Dictionary) -> Array:
	if str(flags.get("compliance", "")) == "REFUSE":
		return _L(TERMINAL_SECOND_PRESERVED)
	return _L(TERMINAL_SECOND_SURRENDERED)


## The landing scene, shown on the stairs route once the coats' evidence line has been read.
static func landing(flags: Dictionary) -> Array:
	if str(flags.get("escape_route", "")) != "STAIRS":
		return []
	return _L(LANDING_SCENE)


## The ending's extra beat, spliced into the ending text after the line it belongs behind.
static func ending_lines(ending_id: String, lines: Array) -> Array:
	if not ENDING_BEATS.has(ending_id):
		return lines
	var beat: Dictionary = ENDING_BEATS[ending_id]
	var out: Array = []
	var placed := false
	for line in lines:
		out.append(line)
		if not placed and str(line[1]) == str(beat.after_line):
			for extra in _L(beat.lines):
				out.append(extra)
			placed = true
	if not placed:
		# The anchor line moved. Put the beat before the END card rather than dropping it.
		var tail = out.pop_back()
		for extra in _L(beat.lines):
			out.append(extra)
		out.append(tail)
	return out


## Word count of everything this file adds, for the store copy's "a longer cut" claim.
static func word_count() -> int:
	var total := 0
	var buckets: Array = [COAT_HOTSPOT[3], BREAKROOM_TRUST, BREAKROOM_SUSPECT,
		TERMINAL_SECOND_PRESERVED, TERMINAL_SECOND_SURRENDERED,
		LOBBY_ELEVATOR, LOBBY_STAIRS, LANDING_SCENE]
	for beat in ENDING_BEATS.values():
		buckets.append(beat.lines)
	for bucket in buckets:
		for line in bucket:
			if str(line[0]) == "CG":
				continue
			total += str(line[1]).replace("\n", " ").split(" ", false).size()
	return total
