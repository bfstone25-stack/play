extends RefCounted
class_name Story

## The writing. All 9,300 words of it, carried across from the Ren'Py fork's
## game/scripts/*.rpy unchanged except for the cast surnames (see README: the fork now uses
## the base game's canon — Tamsin Reed, Ivo Glass, Mara Voss).
##
## Shape: a Ren'Py `label` is a static function here, and it returns the beats that label
## emits. Labels are entered with the run state already decided, so branches resolve at
## generation time exactly as Ren'Py resolves them at execution time, and the interpolations
## ([run.till], [_fee]) become format calls. A label splits wherever Ren'Py had a `menu`:
## the options carry the label to jump to, and the mutation a choice performs is the first
## thing that label's generator does. game.gd calls each label exactly once.
##
## Beat kinds:
##   {"t":"nar",   "text":s}                 narration
##   {"t":"say",   "who":id, "text":s}       a named voice
##   {"t":"scene", "bg":key}                 background change
##   {"t":"customer", "id":key|""}           portrait at the counter
##   {"t":"plate", "item":key}               show a reading; the gate happens here
##   {"t":"ledger"}                          open the Reading Ledger
##   {"t":"gate",  "chapter":n}              the web track's chapter cut
##   {"t":"menu",  "prompt":s, "options":[{"text":s,"to":label}]}
##   {"t":"goto",  "label":s}
##   {"t":"end",   "ending":key}
##
## THE KILL CONDITION, restated here because this is the file that could break it:
## every vision is somewhere else, some other time, someone else's. The observer is fixed
## four feet up and behind, cannot speak, touch or intervene, and readings carry no sound.
## Nara is in exactly one erotic scene, the last, alone, looking at her own reflection. If
## these ever collapse into one woman at a counter, the fork is Room 704 and is cancelled.

const C := preload("res://scripts/collateral_core.gd")


static func nar(text: String) -> Dictionary:
	return {"t": "nar", "text": text}

static func say(who: String, text: String) -> Dictionary:
	return {"t": "say", "who": who, "text": text}

static func scene(bg: String) -> Dictionary:
	return {"t": "scene", "bg": bg}

static func customer(id: String) -> Dictionary:
	return {"t": "customer", "id": id}

static func plate(item: String) -> Dictionary:
	return {"t": "plate", "item": item}

static func menu(prompt: String, options: Array) -> Dictionary:
	return {"t": "menu", "prompt": prompt, "options": options}

static func goto(label: String) -> Dictionary:
	return {"t": "goto", "label": label}

static func opt(text: String, to: String) -> Dictionary:
	return {"text": text, "to": to}


## Every label in the night, in story order. game.gd walks this by name.
static func run_label(name: String, run: C.Run) -> Array:
	match name:
		"start": return l_start(run)
		"act_finial": return l_act_finial(run)
		"finial_read": return l_finial_read(run)
		"finial_blind": return l_finial_blind(run)
		"finial_after_reading": return l_finial_after_reading(run)
		"finial_price": return l_finial_price(run)
		"finial_low": return l_finial_result(run, "low")
		"finial_fair": return l_finial_result(run, "fair")
		"finial_high": return l_finial_result(run, "high")
		"act_ring": return l_act_ring(run)
		"ring_take": return l_ring_take(run)
		"ring_broke": return l_ring_broke(run)
		"ring_declined": return l_ring_declined(run)
		"ring_after_reading": return l_ring_after_reading(run)
		"ring_price": return l_ring_price(run)
		"ring_low": return l_ring_result(run, "low")
		"ring_fair": return l_ring_result(run, "fair")
		"ring_high": return l_ring_result(run, "high")
		"act_interlude": return l_act_interlude(run)
		"act_veil": return l_act_veil(run)
		"veil_take": return l_veil_take(run)
		"veil_broke": return l_veil_broke(run)
		"veil_declined": return l_veil_declined(run)
		"veil_after_reading": return l_veil_after_reading(run)
		"veil_price": return l_veil_price(run)
		"veil_low": return l_veil_result(run, "low")
		"veil_fair": return l_veil_result(run, "fair")
		"veil_high": return l_veil_result(run, "high")
		"act_market": return l_act_market(run)
		"market_offer": return l_market_offer(run)
		"market_sell": return l_market_sell(run)
		"market_refuse": return l_market_refuse(run)
		"market_leave": return l_market_leave(run)
		"act_collateral": return l_act_collateral(run)
		"act_dawn": return l_act_dawn(run)
		"ending_solvent": return l_ending_solvent(run)
		"ending_factor": return l_ending_factor(run)
		"ending_collateral": return l_ending_collateral(run)
		"dawn_outro": return l_dawn_outro(run)
	push_error("unknown label: " + name)
	return []


# ---------------------------------------------------------------------------
# The reading economy — the Ren'Py fork's 08_reading.rpy, as generators.
# ---------------------------------------------------------------------------

## Charge, show, and hand the fee back if the plate never arrived.
##
## Split out of the offer because tools/simulate.py on the Ren'Py side caught the scenes
## asking twice: a story menu that already states the fee already *is* the decision, and
## then the offer asked for the fee again on the next screen. A fee prompt that appears
## after the player has already said yes is exactly what a second paywall feels like. So a
## scene that has asked in its own voice calls this directly, and nobody is asked for the
## same money twice.
static func reading_take(run: C.Run, item: String, plate_item := "") -> Array:
	var out: Array = []
	if plate_item == "":
		plate_item = item
	var fee := C.fee_for(item)
	run.charge_reading(item)
	if fee:
		out.append(nar("She counts it out of the drawer before she touches anything, because Elsa's rule was that the shop pays first and looks second, and the one time Nara did it the other way round she saw a thing she could not afford to have seen."))
	run.record_reading(item)
	out.append(plate(plate_item))
	if fee:
		# Whether the plate arrived cannot be known here. On the web track the bytes are
		# fetched from the gateway *at the plate beat* — a ticket, a gate, a redeem — and
		# this list is generated before any of that has happened. Asking the question here
		# is how the first draft of the fork always answered "censored", even on a run that
		# was about to unlock. game.gd resolves this beat after the fetch.
		out.append({"t": "settle", "item": item, "plate": plate_item})
	return out


## The refund rule, resolved once the plate has actually been fetched or has failed to be.
##
## If the free track left the plate censored, the shop did not get what it paid for, and
## neither did the player. Returns the lines to splice in, or [] when the art arrived.
static func settle_reading(run: C.Run, item: String, plate_item: String) -> Array:
	if Collateral.delivered(plate_item):
		return []
	var back := run.refund_reading(item)
	return [
		nar("It does not come. Not all of it — a shape, a direction, the weather of the thing, and then the object goes quiet in her hand like a phone with the screen off."),
		say("nara", "That's not a reading. That's a receipt for one."),
		nar("She puts the %d back in the drawer. The shop does not charge for what it failed to show you." % back),
	]


## LOW / FAIR / HIGH. The base game's pricing verb, now aimed at a person whose worst or
## best hour you may have just watched.
static func price_menu(item: String, low_to: String, fair_to: String, high_to: String) -> Dictionary:
	return menu("What do you write on the ticket?", [
		opt("LOW — %d. They will take it." % C.price_of(item, "low"), low_to),
		opt("FAIR — %d. What it is worth." % C.price_of(item, "fair"), fair_to),
		opt("HIGH — %d. More than it is worth." % C.price_of(item, "high"), high_to),
	])


# ---------------------------------------------------------------------------
# 01_shop.rpy — cold open and Appraisal 1: Tamsin Reed, the finial.
# ---------------------------------------------------------------------------

static func l_start(_run: C.Run) -> Array:
	return [
		scene("black"),
		nar("There are two prices on everything. What the living will offer, and what the dead will demand. Elsa Quill had that painted on the window in 1961 and it is still there, backwards, in gold, shedding a little more of itself every winter."),
		nar("Nara has run the shop under it for three years."),
		scene("shop"),
		nar("Eleven fifty-eight. The rain has been going since four and has settled into the kind that does not fall so much as stand in the air and wait."),
		nar("She is closing out. Four columns, a stub of pencil, a drawer with two hundred and sixty in it, and a debt against the estate of two hundred that comes due tomorrow, which is a word that at this hour means in about six hours."),
		say("nara", "Two-sixty in. Two hundred out. Sixty to live on and a shop full of other people's decisions."),
		nar("The shop restocks itself at midnight. Not metaphorically. She has stopped finding it remarkable, the way you stop hearing a fridge."),
		nar("At 12:00 exactly, the shelves shuffle. A thing that has sat unclaimed for a decade goes quiet and dark and slides back, and a thing that somebody in this city is about to need a price for comes forward into the lamp."),
		nar("She has never once caught it happening. She has watched the second hand for twenty minutes straight and it happens anyway, in the part of the minute where she blinked."),
		say("shop", "..."),
		nar("And her hands. That is the other thing."),
		nar("Put a palm flat on an object and it gives up the last thing it was used for. Not the history — the last use. The most recent hour that mattered to it."),
		nar("Most nights that is a kettle. A coat on a hook. Somebody signing away a car in a kitchen with the radio on. Elsa called it the trade's one advantage and warned her it was not free."),
		say("nara", "It is not free. It costs the shop."),
		nar("She has never got a straight answer about why. The reading takes money out of the drawer the way a lamp takes oil, and if the drawer is empty the object stays a lump of brass."),
		nar("Elsa's theory was that you are paying for the attention of whatever files these things. Nara's theory is that it is a business and she is a customer."),
		nar("The rules, because tonight is going to test all three."),
		nar("Appraise. Read, or don't. Then price it — LOW, FAIR, or HIGH — and they either take the ticket or they don't."),
		nar("Lowball a stranger and you are ahead by a few. Lowball someone whose worst hour you have just watched from the inside and you are a different kind of thing."),
		nar("12:00. The lamp gutters and comes back."),
		nar("There is a woman at the glass."),
		goto("act_finial"),
	]


static func l_act_finial(_run: C.Run) -> Array:
	return [
		customer("tamsin"),
		nar("She has come through the rain without a coat and she is not shivering, which usually means somebody has been sitting in a car in a car park deciding for a while."),
		nar("Mid-thirties. Auburn, cut blunt at the jaw. Freckles right across the shoulders where the wet blouse has given up. She is holding something in both hands the way you hold a mug."),
		say("tam", "Do you buy brass?"),
		say("nara", "I buy anything I can price."),
		nar("She puts it on the counter. It is a finial — the knob off the corner post of a bed frame. Turned brass, about the size of a pear, with a flattened seam down one side where it was cast."),
		nar("There are four of them on a bed. There is one of them here."),
		say("nara", "Where are the other three?"),
		say("tam", "On the bed."),
		say("nara", "And the bed?"),
		say("tam", "In the flat. For another two days."),
		nar("She says it evenly. It is a sentence she has clearly said to a letting agent, twice, and got better at."),
		nar("She makes a small circle with one hand, taking in the counter, the shop, the hour."),
		say("tam", "Tamsin Reed. I'm not being coy. I just don't want to do the whole thing where you ask and I explain and you say you're sorry."),
		say("nara", "I wasn't going to say I'm sorry."),
		say("tam", "No. You were going to say twelve."),
		nar("Nara laughs before she decides whether to, which does not happen often."),
		say("nara", "I was going to say fourteen and let you get me to eighteen."),
		say("tam", "See, that's worse."),
		nar("The thread inside the finial is bright. Scored, actually — the bright of metal that has been turned against a tool that slipped, recently, in a hurry, by somebody who did not have the right spanner and used a table knife."),
		nar("You do not unscrew one finial off a bed slowly."),
		menu("You could put a hand on it.", [
			opt("Put a hand on it. (the shop is not charging for this one)", "finial_read"),
			opt("Leave it. Price the brass and let her go home.", "finial_blind"),
		]),
	]


static func l_finial_read(run: C.Run) -> Array:
	var out: Array = [
		nar(C.ITEMS["finial"]["clue"]),
		nar("This one is free, which she has learned means the shop wants her to see it. That is not a comfort."),
	]
	# cg_tamsin, not cg_finial. The first plate anybody sees on any track has to be the
	# uncensored one — 09_dist.rpy:17 is explicit that gating the opening CG is what made
	# Room 704's browser build read as a bait screen. cg_finial is the same vision further
	# in, and it arrives below, in the HIGH branch, as mercy's reward.
	out.append_array(reading_take(run, "finial", "tamsin"))
	out.append(goto("finial_after_reading"))
	return out


static func l_finial_blind(run: C.Run) -> Array:
	run.record_refusal("finial")
	return [
		nar("She turns it over with the backs of her fingers. Brass is brass. Twenty-two of anything, no story attached."),
		say("nara", "It's a nice casting. Somebody paid for that bed."),
		say("tam", "Somebody did."),
		say("nara", "Some nights you want the whole story. Some nights the story is a cost."),
		goto("finial_price"),
	]


## The reading. Everything here is *Tamsin's*, seen from outside, in her flat, on a morning
## Nara was not present for. The POV character is not in this scene and cannot get into it.
## That is the frame the whole fork stands on.
static func l_finial_after_reading(_run: C.Run) -> Array:
	return [
		nar("The brass goes warm, which it does not do, and then Nara is not holding it any more. She is about four feet up and slightly behind, the way you are in someone else's memory — present, uninvited, unable to look away and unable to help."),
		nar("Morning. Not this morning; a morning with a lot of light in it, coming through a curtain that is only half up because the other half of the rail has been unscrewed and put in a box."),
		nar("The room is nearly empty. Cardboard along one wall, labelled in marker in a hand that started neat. The bed is stripped down to the mattress and the mattress is on the floor, because the frame is in pieces against the radiator."),
		nar("Tamsin is sitting on it. Sheet pulled across her lap, shoulders bare, hair flat on one side from sleeping on a thing that is no longer a bed."),
		nar("She is holding the finial. Turning it. She has clearly been sitting there a while doing exactly that and nothing else."),
		nar("There is no one else in the room. That is the part that makes it hard to watch — not the bareness of her, which is simply what you look like at eight in the morning in a flat you are losing, but that the scene has been built by somebody and then everybody left."),
		nar("She says something. It does not carry; readings do not carry sound, they carry the shape of it. It was four words and it was addressed to the room."),
		nar("Then she puts the finial in the pocket of a coat and stands up, and the light goes."),
		scene("shop"),
		nar("Nara is at her own counter with her hand flat on a piece of brass and eleven seconds gone off the clock."),
		say("nara", "..."),
		say("tam", "You've gone a bit grey."),
		say("nara", "The lamp does that."),
		say("tam", "The lamp's been on the whole time."),
		goto("finial_price"),
	]


static func l_finial_price(_run: C.Run) -> Array:
	return [
		nar("Twenty-two is what it is worth. She could write fourteen and Tamsin would take fourteen, because people who have already decided to lose something will accept the terms of losing it."),
		nar("She could write thirty-three, which is not generosity, it is the shop paying for her to have seen the room."),
		price_menu("finial", "finial_low", "finial_fair", "finial_high"),
	]


static func l_finial_result(run: C.Run, tier: String) -> Array:
	run.pay_client("finial", tier)
	var out: Array = []
	if tier == "low":
		out.append_array([
			nar("She writes fourteen. Tamsin looks at it for exactly as long as it takes to decide not to argue, and that is the whole transaction."),
			say("tam", "Fine."),
			say("nara", "It's brass."),
			say("tam", "It's fourteen pounds of my bed. That's fine. That's — yeah."),
			nar("She is gone before the bell has finished. Nara puts the finial on the shelf behind her and it sits there being worth twenty-two."),
			say("nara", "Eight up. Well done."),
		])
	elif tier == "fair":
		out.append_array([
			nar("Twenty-two. She writes it, turns the ticket, and does not explain it."),
			say("tam", "That's more than it's worth."),
			say("nara", "That's exactly what it's worth. What's less than it's worth is fourteen, which is what you came in expecting, which is why you didn't bring the other three."),
			nar("Tamsin takes the money and puts it in her back pocket without counting it, which is either trust or exhaustion."),
			say("tam", "If I bring the other three, will you do the same?"),
			say("nara", "If you bring the other three I'll do better, because four of anything is a set."),
			say("tam", "Right. Okay."),
			nar("At the door she stops with her hand on the glass and says the thing people say when the transaction was not the reason they came."),
			say("tam", "It was a good bed."),
			say("nara", "It sounded like one."),
			nar("Tamsin looks at her. Neither of them touches it."),
		])
	else:
		out.append_array([
			nar("Thirty-three. Tamsin looks at the ticket, then at her, and her face does something complicated and unwelcome."),
			say("tam", "Why."),
			say("nara", "Because I looked at it and now I know what it's worth to you, and that's a different number, and I'd rather be wrong in that direction."),
			say("tam", "You can't afford to be wrong in that direction. Look at this place."),
			say("nara", "I know what I can afford. Take the thirty-three."),
			nar("She takes it. At the door she turns round."),
			say("tam", "You saw it. Didn't you. The room."),
			say("nara", "Yes."),
			say("tam", "Was I —"),
			plate("finial"),
			say("nara", "You were sitting up. That's all. You were sitting up and it was a nice morning and the light was good."),
			nar("Tamsin nods once, hard, the way you nod at a thing you needed to be told, and goes out into the rain without a coat."),
		])
	out.append(goto("act_ring"))
	return out


# ---------------------------------------------------------------------------
# 02_ring.rpy — Appraisal 2: Ivo Glass, the ring. The fork's first transgression.
#
# He asks you not to look. Looking costs 35 out of the till and it is the only CG in the
# game whose unlock condition includes a person having said no — which is deliberate and is
# the thing the scene has to earn rather than enjoy.
# ---------------------------------------------------------------------------

static func l_act_ring(run: C.Run) -> Array:
	var out: Array = [
		scene("shop"),
		customer("ivo"),
		nar("Twelve twenty. The shelves have done their second shuffle of the night, quieter, the way a house settles."),
		nar("The man who comes in has been outside for a while. You can tell by the way he does not react to the warmth."),
		nar("Late thirties. Brown hair going back at the temples, short beard, forearms out of a rolled shirt with old ink on the left one that has gone the green of a tattoo somebody got at twenty-two."),
		nar("He puts a ring on the counter from about six inches up, so it lands and rolls and he has to stop it with one finger."),
		say("ivo", "How much."),
		say("nara", "Depends what it is."),
		say("ivo", "It's a ring. That's the whole of it."),
		nar("It is a woman's wedding band. Yellow gold, narrow, worn thin on the inside curve the way a ring goes when it has been worn every day for years and taken off for nothing."),
		nar("There is an engraving inside. She turns it to the lamp before he can stop her."),
		say("nara", "There's a date in it."),
		say("ivo", "There is."),
		nar("It is eleven months after the date Nara would put on a decree if she were putting one on a decree, which she is not, because she does not know this man."),
		nar("But you learn to read a date the way you read a hallmark. This one is not the date of a wedding. It is the date of a thing that happened after a wedding had finished happening."),
		say("nara", "Ivo?"),
		say("ivo", "How do you —"),
		say("nara", "It's on the card you're holding. You've been turning it over since you came in."),
		nar("He looks at his own hand. Pawn ticket from three years ago, another shop, softened at the corners."),
		say("ivo", "Ivo Glass. I've done this before, is what that means. Not here."),
		say("nara", "Most people have done it before. It's a shop, not a confession."),
		nar("She puts two fingers on the band, and it is not a gesture that means anything to anyone who does not know what she is, but he goes very still."),
		say("ivo", "Don't do that."),
		say("nara", "Do what."),
		say("ivo", "Elsa did that. Same face, same two fingers. She told me what it was and I have thought about it every week since and I am asking you not to do it."),
		nar("Nara takes her hand off the ring."),
		say("nara", "All right."),
		say("ivo", "It's mine to sell and it isn't mine to show you."),
		say("nara", "Whose is it?"),
		say("ivo", "Maya's. Not my wife. I want to be exact about that because everybody gets it wrong and then they look at me a certain way for the rest of the transaction."),
		say("ivo", "I was married. It ended. It ended properly — she left, we did the paperwork, we did it badly for a year and then we did it fine, and she is in Leeds and we speak at Christmas."),
		say("ivo", "Eleven months after all of that was finished, I bought that ring for someone else. And then I was an idiot about it in a way that had nothing to do with anybody but me."),
		say("nara", "So it's not —"),
		say("ivo", "It is not that. I want that said out loud in the shop before you write a number, because it is going to be the cheapest thing about tonight and I would still rather have it."),
		nar("Nara writes something in the margin of the ledger, which is not a number."),
		nar("Forty is what it is. Narrow band, low carat, a gram and a half of gold and no market for the sentiment."),
		nar("A reading costs the shop thirty-five, which is very nearly the price of the object, and that is not a coincidence — the shop has always charged most for the things somebody has just told her not to look at."),
	]
	run.ivo_refused = true

	var options: Array = []
	if run.can_afford(C.fee_for("ring")):
		options.append(opt("Take the reading anyway. (%d out of the till)" % C.fee_for("ring"), "ring_take"))
	else:
		options.append(opt("Take the reading anyway — but the drawer is short. (%d needed, %d in it)" % [C.fee_for("ring"), run.till], "ring_broke"))
	options.append(opt("Don't. He asked.", "ring_declined"))
	out.append(menu("He asked you not to.", options))
	return out


static func l_ring_take(run: C.Run) -> Array:
	var out: Array = [
		say("nara", "..."),
		nar("She waits until he has turned to look at the case of pocket watches, which takes about four seconds, and she puts her whole palm on it."),
		nar("That is the transgression and there is no version of it that is not one. She is not going to pretend otherwise later and neither is the ledger."),
	]
	out.append_array(reading_take(run, "ring"))
	out.append(goto("ring_after_reading"))
	return out


static func l_ring_broke(run: C.Run) -> Array:
	run.record_refusal("ring")
	return [
		nar("She puts her palm on it and the shop counts the drawer and declines. The gold stays gold."),
		say("nara", "Nothing."),
		nar("The first honest thing about the night is that she tried."),
		goto("ring_price"),
	]


static func l_ring_declined(run: C.Run) -> Array:
	run.record_refusal("ring")
	return [
		nar("She leaves her hands on the ledger where he can see both of them, which is a thing Elsa did and Nara has never admitted she copied."),
		say("nara", "I didn't look."),
		say("ivo", "I know. I was watching in the case glass."),
		say("nara", "Then why did you ask?"),
		say("ivo", "Because asking is the part I get to do."),
		goto("ring_price"),
	]


## Again: the vision is Ivo's, and Ivo is not the one it is really about. Nara is a fixed
## point four feet away with no ability to intervene, and the scene is framed from behind
## and past an object. Nobody in this room is at a counter at midnight.
static func l_ring_after_reading(_run: C.Run) -> Array:
	return [
		nar("A bedroom with the lamp on the floor because the nightstand is a stack of books, which is a flat somebody has lived in for four months and expects to leave."),
		nar("Rain on the window. Different rain, harder, further north."),
		nar("Two people asleep, or one asleep and one not. The sheet is up over both of them. Bare shoulder, bare back, an arm across. From behind and slightly above, the way readings always are, which is the only mercy in the whole arrangement."),
		nar("The reading is not interested in them. It is interested in the ring, because the ring is what she is holding, and the ring is on the stack of books next to the lamp, in focus, with the rest of the room going soft around it."),
		nar("That is what an object remembers. Not the night. The eleven centimetres of nightstand it spent the night on, and the hand that reached over at some point in it and moved it two centimetres to the left for no reason."),
		nar("It was a good hour. Nara wants that noted. Whatever happened after — and something clearly happened after, or it would not be on her counter with a man outside it asking her not to look — the last use of this object was somebody being happy and slightly careless with it at two in the morning."),
		nar("Then a hand takes it off the books. And the light goes."),
		scene("shop"),
		nar("Nara's palm is flat on the counter with nothing under it. Ivo has not turned round."),
		say("ivo", "Well?"),
		say("nara", "Forty."),
		say("ivo", "That isn't what I asked."),
		say("nara", "It's what I'm answering."),
		nar("He turns round then, and he looks at her hand, and he does the arithmetic that anybody would do."),
		say("ivo", "You did it."),
		say("nara", "I did it."),
		say("ivo", "What did you —"),
		say("nara", "No."),
		say("ivo", "That's not fair."),
		say("nara", "No. It isn't. I took a thing you asked me not to take and I'm not going to make it worse by making you pay to hear it described."),
		nar("There is a silence in which a clock that has been wrong since 1998 gets to be the loudest thing in the room."),
		say("ivo", "Was she happy."),
		say("nara", "..."),
		say("nara", "It was a nice room. The lamp was on the floor."),
		say("ivo", "It was always on the floor. She hated the — yeah."),
		nar("He laughs at nothing, once, and rubs his face with the heel of his hand."),
		say("ivo", "Right. Write your number."),
		goto("ring_price"),
	]


static func l_ring_price(_run: C.Run) -> Array:
	return [
		nar("Forty is the number. Twenty-six insults him and he will take it. Sixty is not a price, it is an apology with a receipt."),
		price_menu("ring", "ring_low", "ring_fair", "ring_high"),
	]


static func l_ring_result(run: C.Run, tier: String) -> Array:
	run.pay_client("ring", tier)
	var out: Array = []
	if tier == "low":
		out.append_array([
			nar("Twenty-six. He looks at the ticket and does not say anything about it, which is how you can tell."),
			say("ivo", "Fine."),
			say("nara", "It's a gram and a half."),
			say("ivo", "It's twenty-six quid and you know exactly what it is. That's what I came for."),
			nar("The bell. The door. The rain taking him back."),
		])
	elif tier == "fair":
		out.append_array([
			nar("Forty. He reads it twice."),
			say("ivo", "That's the real number."),
			say("nara", "That's the real number."),
			say("ivo", "Nobody gives me the real number. They give me the number they think I'll take because I look like a man who'll take it."),
			say("nara", "You do look like that. It's still forty."),
			nar("He puts the money in his shirt pocket rather than his trousers, which is what people do when they are not going to spend it tonight."),
			say("ivo", "If I come back in a month, is it still here?"),
			say("nara", "Thirty days on the ticket. After that it's the shop's."),
			say("ivo", "And the shop's is —"),
			say("nara", "The shop's."),
			nar("He nods like that was a straight answer, which it was, and goes."),
		])
	else:
		out.append_array([
			nar("Sixty. He does not pick the ticket up."),
			say("ivo", "No."),
			say("nara", "Take it."),
			say("ivo", "You're paying me for the thing you took. I can see you doing it. Don't."),
			say("nara", "I'm paying you sixty pounds for a gold ring, Mr Glass, and if you want to argue about the till you can come round this side of it."),
			nar("He takes it, eventually, and he is angry in a way that is mostly aimed inward, and at the door he says the sentence she will still be carrying at four in the morning."),
			say("ivo", "The thing about your aunt is she never once told me I could have it back."),
			say("nara", "It's thirty days on the ticket."),
			say("ivo", "That's not the same shape of sentence and you know it."),
		])
	out.append(goto("act_interlude"))
	return out


## The ledger balances. The dead's column is now non-zero, and Nara notices that she is
## also being priced.
static func l_act_interlude(run: C.Run) -> Array:
	var out: Array = [
		scene("shop"),
		customer(""),
		nar("One in the morning. She does the halfway count because Elsa did the halfway count."),
		say("nara", "Till: %d." % run.till),
		nar("Stock on the shelf behind her: %d of other people's brass and gold." % run.stock_value()),
		nar("Against the estate, due in five hours: %d." % C.DEBT),
	]
	if run.fees_paid > 0:
		out.append_array([
			nar("And in the fourth column, in Elsa's hand, in a ruled section Nara has never filled in and never had to explain: %d spent on knowing." % run.fees_paid),
			nar("The column has a heading. The heading is not in English and Nara has never looked it up, on the grounds that there is no version of the answer that improves her night."),
		])
	else:
		out.append_array([
			nar("And in the fourth column, in Elsa's hand, in a ruled section Nara has never filled in: nothing. Zero. Cleanest that column has been in three years."),
			say("nara", "Good."),
			nar("It does not feel like good. It feels like the shop is waiting."),
		])
	out.append_array([
		nar("She turns the page and finds, on the reverse, in pencil, in her own handwriting, which she does not remember doing:"),
		nar("[i]N. Quill — held against reading. Value: pending.[/i]"),
		say("nara", "..."),
		say("nara", "That's not funny."),
		say("shop", "..."),
		nar("She puts her hand flat on the ledger, because of course she does, and gets absolutely nothing, which is the first time an object in this building has ever declined her."),
		nar("Either it has no last use yet, or the last use has not finished."),
	])
	if run.readings_taken.has("ring"):
		out.append(nar("Downstairs, under the floor, something that is not the boiler makes the sound the boiler makes. It has been doing that since she looked at the ring."))
	else:
		out.append(nar("Downstairs, under the floor, the boiler makes the sound the boiler makes, and for once that is all it is."))
	out.append_array([
		nar("There is a hatch behind the stock room that Elsa called the stairs and everyone else called a hole. It goes down to the Receipt Stair and from there to the Market."),
		nar("She is not going down tonight. There is one more name in the book."),
		goto("act_veil"),
	])
	return out


# ---------------------------------------------------------------------------
# 03_veil.rpy — Appraisal 3: Widow Voss, the mourning veil.
#
# Grief, not shame. The vision is the night before the funeral, not the funeral. Per the
# design this is the scene that has to land emotionally or the whole fork reads as smut
# with a spreadsheet attached — so the erotic register here is entirely "a woman alone in a
# room deciding what she will be tomorrow", and the CG costs mercy rather than curiosity.
# ---------------------------------------------------------------------------

static func l_act_veil(run: C.Run) -> Array:
	var out: Array = [
		{"t": "gate", "chapter": 2},
		scene("shop"),
		customer("mara"),
		nar("Ten past one. The rain has stopped and left the street shining, which is worse."),
		nar("The woman who comes in does not hurry and does not apologise for the hour, and she closes the door behind her with two hands, quietly, the way you close a door in a hospital."),
		nar("Early forties. Tall, long-necked, black hair with one white streak in it that is not dye and is not age either — it is the other thing, the kind that arrives in a fortnight."),
		nar("Black dress, high collar, and a brooch at the throat that is worth more than the contents of this shop."),
		say("mara", "You are Elsa's girl."),
		say("nara", "I'm Elsa's niece."),
		say("mara", "That is what I said."),
		nar("She puts a folded square of black crepe on the counter and smooths it flat with the back of her hand, twice, which is a gesture that belongs to fabric and not to money."),
		say("nara", "A veil."),
		say("mara", "A mourning veil. There is a difference and you will want it for your ticket."),
		say("nara", "Voss."),
		say("mara", "Widow Voss, since about March. You may use either. I have not settled on which one I am."),
		nar("The crepe is old, good, and the pleating at the crown has been pressed exactly once. It has been worn exactly once. It has never been washed, and you do not wash crepe anyway, so that is not neglect, it is preservation."),
		say("nara", "It's been out of a box recently."),
		say("mara", "It has been out of a box for six months. It is on the chair in my bedroom and I go past it four times a day and I have decided that is a stupid way to run a house."),
		say("nara", "You could throw it away."),
		say("mara", "I could. That would be a decision about him. I would rather it were a transaction about a piece of cloth."),
		nar("Thirty-five. Antique crepe in this condition goes to a costumier for thirty-five, or to a collector of very specific and unwholesome things for more, and Nara does not sell to those."),
		nar("A reading costs the shop twenty, and she has not told her not to, and that is somehow worse than Ivo, because it means it is entirely Nara's to decide."),
	]
	var options: Array = []
	if run.can_afford(C.fee_for("veil")):
		options.append(opt("Read it. (%d out of the till)" % C.fee_for("veil"), "veil_take"))
	else:
		options.append(opt("Read it — the drawer is short. (%d needed, %d in it)" % [C.fee_for("veil"), run.till], "veil_broke"))
	options.append(opt("Don't. It's a widow's veil and she is standing right there.", "veil_declined"))
	out.append(menu("Nobody has said no.", options))
	return out


static func l_veil_take(run: C.Run) -> Array:
	var out: Array = [
		say("nara", "May I."),
		say("mara", "May you what?"),
		say("nara", "Elsa will have told you what this shop does. May I."),
		nar("She looks at her for a long moment and then does a thing with her chin that in her family has meant yes for four generations."),
		say("mara", "She said it costs you. Is that true, or is it a thing you say to make people feel bought?"),
		say("nara", "It's true. It comes out of the drawer."),
		say("mara", "Then spend it, and afterwards you will tell me what you saw, because I was there and I want to know if it is the same."),
	]
	out.append_array(reading_take(run, "veil"))
	out.append(goto("veil_after_reading"))
	return out


static func l_veil_broke(run: C.Run) -> Array:
	run.record_refusal("veil")
	return [
		nar("She asks the shop and the shop looks at the drawer and says no, in the way it says no: nothing at all happens, expensively."),
		say("nara", "I can't. I haven't got it tonight."),
		say("mara", "That is the most honest thing anyone has said to me since March."),
		goto("veil_price"),
	]


static func l_veil_declined(run: C.Run) -> Array:
	run.record_refusal("veil")
	return [
		say("nara", "I'll price it as cloth."),
		say("mara", "You are allowed to look. Elsa looked."),
		say("nara", "Elsa looked at everything and died owing two hundred pounds and knowing what every object in this building had been doing. I'm not sure those are unrelated."),
		nar("She almost smiles, which on her is an event."),
		say("mara", "No. I don't imagine they are."),
		goto("veil_price"),
	]


static func l_veil_after_reading(_run: C.Run) -> Array:
	return [
		nar("The night before, not the day of."),
		nar("That is the first thing and it reorganises everything, because Nara had braced for a church."),
		nar("A bedroom with the furniture wrong — a bed slept in by one person in the middle rather than two people at the edges, and a chair with a black dress laid out on it flat, sleeves arranged, the way you lay out a thing you are frightened of."),
		nar("Candles, because the electricity in that house is Victorian and so is the house. A lily in a jug that somebody has sent and somebody else has put somewhere without thinking about it."),
		nar("She is at the mirror, and she is trying it on."),
		nar("The veil first. Over the face, then lifted, then over again, and the third time she leaves it and stands there looking at the shape of herself through black crepe, which is a thing a person does the night before, alone, in order to find out whether they can get through the day."),
		nar("The dress is not on yet. She has come to the mirror in the middle of undressing and got stopped by the veil, so the dress is at her waist and her arms are down at her sides and she is not holding anything, and that stillness is the whole scene."),
		nar("It is not modesty and it is not the other thing either. It is a woman looking at her own bare shoulders in a mirror, under a black veil, twelve hours before the worst appointment of her life, working out whether she is going to be able to stand up straight."),
		nar("The mirror does most of the work. You are watching the reflection and the reflection is watching her and Nara is a third thing, four feet up, with no right to be there at all."),
		nar("She is composed. That is what makes it hard. There is no crying in this scene, and the reading does not offer any, and the total absence of it is the most naked thing in the room."),
		nar("After about a minute she lifts the veil back off her face, and looks at herself without it, and says one word to the mirror."),
		nar("Then she folds the veil over the arm of the chair and blows the candle out."),
		scene("shop"),
		nar("The lamp. The counter. The crepe under her palm, cool."),
		say("mara", "Well."),
		say("nara", "You were at the mirror."),
		say("mara", "Yes."),
		say("nara", "You had it over your face and then you took it off."),
		say("mara", "Yes."),
		say("nara", "You said something."),
		say("mara", "..."),
		say("mara", "I said his name. To check that I could."),
		nar("Nara does not say anything, because there is nothing that is not worse than nothing."),
		say("mara", "And could I, in your version?"),
		say("nara", "You said one word. The reading doesn't carry sound."),
		say("mara", "Good. That is exactly the correct amount of it to have."),
		nar("She smooths the crepe flat again with the back of her hand. Twice."),
		say("mara", "I will tell you what I expected, since I have paid for the right to be embarrassed. I expected the funeral. I have been dreading that you would see me at the funeral, where I was very badly behaved."),
		say("nara", "I got the night before."),
		say("mara", "The night before I was alone and had my arms down and was frightened. That is the version I can stand a stranger having."),
		say("nara", "It wasn't frightened."),
		say("mara", "Wasn't it."),
		say("nara", "It was somebody finding out they could do it. That's a different picture."),
		nar("She looks at the veil on the counter for a while."),
		say("mara", "Thirty-five, Elsa would have said."),
		goto("veil_price"),
	]


static func l_veil_price(_run: C.Run) -> Array:
	return [
		nar("Thirty-five is the number. Twenty-three is what a costumier pays a stranger. Fifty-two is not a price for cloth."),
		nar("And this is the one where the arithmetic is honest about itself: to unlock what she just saw — to have any right to it — the shop has to go above the number. Mercy costs, or it was only curiosity wearing a better coat."),
		price_menu("veil", "veil_low", "veil_fair", "veil_high"),
	]


static func l_veil_result(run: C.Run, tier: String) -> Array:
	run.pay_client("veil", tier)
	var out: Array = []
	if tier == "low":
		out.append_array([
			nar("Twenty-three. She reads the ticket and her face does not move at all, which is a skill and she has had six months to practise it."),
			say("mara", "That is a costumier's number."),
			say("nara", "It's a fair trade number."),
			say("mara", "It is a number for a woman who does not know what she has. Thank you for the demonstration."),
			nar("She takes it. At the door she does not turn round."),
		])
	elif tier == "fair":
		out.append_array([
			nar("Thirty-five. She writes it, and Mara nods once."),
			say("mara", "Elsa's number."),
			say("nara", "It's the right number."),
			say("mara", "It is the right number. You will find that the right number is very rarely the whole of what is owed, but it is a good place to start and I am glad you started there."),
			nar("At the door she pauses with a hand on the glass."),
			say("mara", "You will not tell anyone."),
			say("nara", "No."),
			say("mara", "No. I did not think you would. That is a different thing from not being able to."),
		])
	else:
		out.append_array([
			nar("Fifty-two. She turns the ticket round and pushes it across the crepe."),
			say("mara", "That is seventeen pounds more than it is worth."),
			say("nara", "Yes."),
			say("mara", "Why."),
			say("nara", "Because I went into your bedroom on the worst night of your life without asking properly and I looked at you, and thirty-five is what the cloth costs and seventeen is what I owe."),
			say("mara", "That is not how a shop works."),
			say("nara", "It's how this one works after one in the morning."),
			nar("She takes the money, and then does something nobody has done across this counter in three years: she puts her hand flat on the back of Nara's, on the crepe, for about two seconds."),
			say("mara", "You will want to be careful, Elsa's girl. That column adds up in both directions."),
			say("nara", "Which column?"),
			say("mara", "The fourth one."),
			nar("And she is gone, and the veil is on the shelf, and the shop is very quiet in the specific way it is quiet when it has got what it wanted."),
		])
	out.append(goto("act_market"))
	return out


# ---------------------------------------------------------------------------
# 04_market.rpy — the descent. One crypt room: the Ossuary Market.
#
# The base game had four crypt rooms and a combat loop; this keeps the one room with people
# in it (scene_crypt_2_ossuary_market — the same PNG, out of the same assets/pixel/) and
# throws the combat away. Calder buys readings. Selling him one is the Factor ending.
# ---------------------------------------------------------------------------

static func l_act_market(run: C.Run) -> Array:
	var out: Array = [
		{"t": "gate", "chapter": 3},
		scene("black"),
		customer(""),
		nar("Two o'clock. The book is empty until five and the drawer has %d in it against a debt of %d, so she goes down." % [run.till, C.DEBT]),
		nar("Behind the stock room, under a rug that Elsa never bothered to nail: the Receipt Stair."),
		nar("Forty-one steps cut into what the surveyor's report from 1974 calls [i]made ground[/i] and what everybody who has ever been down it calls the other thing. The treads are paper. Compressed, laminated, decades of pawn tickets pressed into something that takes a boot."),
		nar("On the way down you can read them side-on if you want to. She does not want to."),
		nar("She does anyway, about a third of the way, because the mind is a stupid animal that reads what is in front of it."),
		nar("[i]Silver christening cup. Held 30 days. Unredeemed.[/i] [i]Trombone, case. Redeemed, 14 days, no interest charged, E.Q.[/i] [i]Overcoat, wool, good. Unredeemed.[/i]"),
		nar("Nobody ever comes and gets the overcoats. Elsa had a theory about that too — that a coat is the thing you pawn when there is no longer a version of the winter in which you need it."),
		nar("The air changes at about step twenty-five. Not colder; drier, and with the faint mineral smell of a cellar that has never had water in it, which in this city is not possible and is nonetheless the case."),
		nar("The last sixteen steps she takes with her hand on the wall, and the wall is not stone, and she has known that for three years and still checks."),
		scene("market"),
		nar("And then the Market."),
		nar("A vaulted room the size of a swimming bath, walled floor to ceiling in bone — femurs stacked in courses like brick, skulls set in as a decorative band at head height, which whoever did it clearly thought was tasteful."),
		nar("Between the pillars, stalls. Trestles, awnings, lanterns burning something that is not oil. Thirty or forty traders, none of whom are precisely present, all of whom are precisely busy."),
		nar("They deal in unclaimed collateral. Everything down here defaulted on a ticket somewhere and came to the only market that will take it."),
		nar("Nara comes down about once a fortnight with whatever the shop's thirty days have eaten, and comes back up with cash, and the whole arrangement is so ordinary that she has stopped bringing a light."),
		nar("The stalls, in order, because she does the same circuit every time and the circuit is the only thing down here she controls."),
		nar("Teeth. Not a metaphor and not a curiosity stall — a trestle of human teeth sorted by decade, which somebody buys, which she has never asked about."),
		nar("Doors. Six of them, freestanding, none of them attached to anything, all of them locked. The trader sells the doors. He does not sell the keys and becomes unpleasant if you mention them."),
		nar("Instruments, all of them unstrung. Bottles of things that are almost certainly water. A woman who will buy a name off you, cash, no questions, and who Nara crosses the aisle to avoid."),
		nar("And at the end, past the pillar where the femurs give way to something longer than a femur, the factor's stall."),
		nar("The traders are not solid in the way a person is solid. If you look directly at one they are a man in an apron weighing out charms. If you look at the next stall along and let him sit at the edge of your eye, he is a shape doing the motions of weighing, with no weights and no scale and no hands."),
		nar("The first year, that stopped her sleeping. The second year she worked out the trick, which is simply to look at people when you are talking to them, the same as upstairs."),
	]
	run.earn(C.MARKET_HAUL)
	out.append_array([
		nar("Tonight's unclaimed: two bone charms, a moon coin with the ward still legible under the tarnish, and a cracked dueling pistol she is glad to see the back of."),
		nar("The stalls take the lot for %d. Till: %d." % [C.MARKET_HAUL, run.till]),
		nar("And then a man at the end stall says her name, which nobody down here does."),
		say("cal", "Quill."),
		nar("Forty-five, heavy through the shoulders, an apron over good clothes. He is the only trader down here who is entirely solid and the only one who has ever been rude to her."),
		nar("Calder. A factor — he does not sell, he buys, and then other people find they own what he bought."),
		say("nara", "Calder."),
		say("cal", "You've been up there three years and you still come down here with charms and coins."),
		say("nara", "That's the stock."),
		say("cal", "That's the [i]stock[/i]. That is not the inventory."),
		nar("He taps the trestle twice with one knuckle."),
		say("cal", "You've got four columns in that book. You sell me the contents of three of them. Nobody has ever asked you about the fourth."),
		say("nara", "..."),
		say("nara", "The fourth column's not stock."),
		say("cal", "The fourth column is the only thing in that shop that isn't replaceable, and you're giving it away free with every purchase."),
		say("nara", "It's not mine to sell."),
		say("cal", "Neither's the ring. You sold me that man's pistol last month and his fingerprints were still on the grip and you didn't ask him."),
		say("nara", "A pistol is an object."),
		say("cal", "And a reading is a thing you have in your head that came out of an object. Where exactly is the line, and did you draw it before or after you found out what it was worth?"),
		say("nara", "I haven't found out what it's worth."),
		say("cal", "You're about to. That's the part people mind."),
		nar("He wipes the trestle down with a cloth, which is a thing he does when he is about to be reasonable, and Nara has learned to mind that more than the rudeness."),
		say("cal", "Let me put the objection for you, so you don't have to. It's theirs. They didn't consent. They came in out of the rain with a problem and they left with a ticket and somewhere in the middle of that you went into a room they were in six years ago."),
		say("nara", "Yes. That's the objection."),
		say("cal", "It's a good one. It is also an objection to the [i]looking[/i], Quill, not to the selling, and you did the looking upstairs half an hour ago for free."),
		say("nara", "Not for free. It cost the shop."),
		say("cal", "It cost the shop. It didn't cost you. Do you know what the difference is?"),
		say("nara", "I know what the difference is."),
		say("cal", "Then say it."),
		say("nara", "..."),
		say("cal", "No. I didn't think so."),
		nar("Which is the closest Nara has come, in three years, to being genuinely got at, and the worst of it is that she does not know the answer and has not known it since about half past eleven."),
	])

	# The demonstration CG.
	if run.client_readings().size() >= 2:
		out.append_array([
			nar("He can tell. She does not know how — something about the hands, or the fourth column has a smell."),
			say("cal", "You're carrying two. Maybe three. Let me show you the shape of the trade before you decide you're above it."),
			say("nara", "I don't want —"),
			say("cal", "You do. Everybody does. It's free and it's not one of yours."),
			nar("He puts a bone charm on the trestle and turns it over so the flat side is up, and it is not a charm, it is a plate — a reading fixed in something, bought off some other broker in some other city, wrapped and stacked like herring."),
		])
		# Calder's plate is not one of hers: it is not recorded in readings_taken, exactly
		# as 04_market.rpy did not record it. It unlocks a ledger slot and nothing else.
		out.append(plate("market"))
		out.append_array([
			nar("Two people, very small in the frame, a long way down the vault between the stalls. Holding on to each other and nothing else."),
			nar("You cannot see their faces. There are no faces to see — whoever sold this took the reading and the reading came out with the people in it as light and mist and the suggestion of bare shoulders, and that is all anyone will ever get of them now."),
			nar("They are somebody's worst or best hour, and they are for sale, at head height, between a stall selling teeth and a stall selling doors."),
			say("nara", "Who are they?"),
			say("cal", "No idea. That's the product. Nobody's ever going to know and that's why it's worth anything."),
			say("nara", "That's obscene."),
			say("cal", "That's inventory. You've got the same thing in your head about a woman and a bed frame, and the only difference is yours is doing nothing for anybody."),
		])
	else:
		out.append_array([
			nar("He watches her hands for a moment and then makes a small dismissive noise."),
			say("cal", "You've not got enough on you to be worth the demonstration. Come back when you've looked at something."),
			nar("Which stings more than it should, and she files that."),
		])
	out.append(goto("market_offer"))
	return out


static func l_market_offer(run: C.Run) -> Array:
	var out: Array = [scene("market")]
	var client_readings := run.client_readings()
	if client_readings.is_empty():
		out.append_array([
			nar("Calder waits for her to offer something and she has nothing to offer, because she has not looked at anything tonight, and that is either integrity or an empty fourth column and she genuinely cannot tell which."),
			say("cal", "Then we're wasting each other's night."),
			say("nara", "Apparently."),
			goto("market_leave"),
		])
		return out

	var sellable: String = client_readings[client_readings.size() - 1]
	var seller: String = str(C.ITEMS[sellable]["client"])
	out.append_array([
		nar("He names a price without being asked, which is how you know he has been waiting to."),
		say("cal", "Ninety. For one. Your pick, and I'd take the newest, they come out cleaner."),
		nar("%d would clear the estate on its own and leave her with change and a shop." % C.CALDER_READING_PRICE),
		nar("The newest one is %s's." % seller),
		menu("Ninety pounds, for a thing that is already in your head.", [
			opt("Sell him %s's reading. (%d)" % [seller, C.CALDER_READING_PRICE], "market_sell"),
			opt("Don't. Go back up the stairs.", "market_refuse"),
		]),
	])
	return out


static func l_market_sell(run: C.Run) -> Array:
	var client_readings := run.client_readings()
	var sellable: String = client_readings[client_readings.size() - 1]
	run.sold_reading = sellable
	run.earn(C.CALDER_READING_PRICE)
	return [
		nar("It does not take long and it does not hurt, and both of those are the problem."),
		nar("He puts a blank charm in her palm and closes her fingers on it and says something short, and the reading goes out of her the way a word goes when you have been trying to remember it and then stop trying."),
		nar("She can still describe the room. She cannot see it. It has become a thing she knows rather than a thing she has."),
		say("nara", "That's it?"),
		say("cal", "That's it. You'll notice in about a week that you've stopped being able to picture it. Most people say that's an improvement."),
		say("nara", "And them?"),
		say("cal", "They'll never know. Nobody ever knows. That's the entire business, Quill, that's why it's worth ninety and not nine."),
		nar("He counts it out in notes that are warm, which she decides not to think about."),
		nar("Till: %d." % run.till),
		goto("market_leave"),
	]


static func l_market_refuse(_run: C.Run) -> Array:
	return [
		say("nara", "No."),
		say("cal", "Say a number."),
		say("nara", "There isn't one. That's not me being noble, it's me telling you the column doesn't have prices in it."),
		say("cal", "Everything has prices in it. That's painted on your own window."),
		say("nara", "[i]What the living will offer, and what the dead will demand.[/i] You're neither. You're a man with an apron who found a gap."),
		nar("Calder laughs, genuinely, for the first time in three years of doing business."),
		say("cal", "That's Elsa's line. Word for word, same flat delivery. She said no as well."),
		say("nara", "Then you've had your answer twice."),
		say("cal", "I've had it twice from the same shop. Come back in March."),
		goto("market_leave"),
	]


static func l_market_leave(_run: C.Run) -> Array:
	return [
		scene("black"),
		nar("Forty-one steps back up, and on the way up the tickets are readable the other way round, which she has never noticed before."),
		nar("About two-thirds of the way she stops, because one of the treads near the top is newer than the others. Cleaner. Not yet walked flat."),
		nar("It has a name on it and the name is hers and the date on it is tomorrow's."),
		say("nara", "..."),
		nar("She steps on it, because the alternative is to stand in a stairwell until morning."),
		goto("act_collateral"),
	]


# ---------------------------------------------------------------------------
# 05_collateral.rpy — Appraisal 5: the thing you pawned.
#
# The only CG with the POV character in it and the only one the player cannot refuse. The
# Reading Ledger is shown *before* it, with its greyed slots visible, which is the design's
# stated mitigation for the hoarding failure: refusal has to feel like a decision that was
# made, not an accident that happened.
# ---------------------------------------------------------------------------

static func l_act_collateral(run: C.Run) -> Array:
	var out: Array = [
		{"t": "gate", "chapter": 4},
		scene("shop"),
		nar("Three forty. The shop has done its last shuffle of the night, and there is one object forward in the lamp that was not there when she went down."),
		nar("Before she looks at it she does the thing Elsa did at the end of a night, which is to turn to the back of the book where the readings are kept."),
		{"t": "ledger"},
	]
	var taken := run.readings_taken.size()
	var refused := run.readings_refused.size()
	if refused >= 2:
		out.append_array([
			nar("Two lines with nothing after them. Three, if you count the one the drawer refused."),
			say("nara", "Those stay blank. That's allowed. That's the whole point of a column — you're allowed to not fill it in."),
			nar("It does not look like a principle in the book. In the book it looks like a gap."),
		])
	elif taken >= 3:
		out.append_array([
			nar("Every line filled, in her own hand, in the ruled section she has never used."),
			say("nara", "Well. I've had a night."),
			nar("The fourth column is full and the drawer is thin and those two facts are the same fact wearing different hats."),
		])
	else:
		out.append(nar("Some of it filled in and some of it not, which is what most nights look like and is somehow the hardest version to feel anything about."))

	out.append_array([
		nar("And now the counter."),
		nar("It is a book. Black, quarter-bound, about the size of a hand, with a strap and no lock — Elsa never trusted a lock she could not pick, on the grounds that then she could not pick it."),
		nar("It is the Black Ledger. It has been on the shop's shelves as stock since before Nara was born, priced at thirty, unsold, because nobody who has ever picked it up has wanted to own it once they have opened it."),
		nar("Nara has opened it twice. Once at nineteen, on the day of the funeral, when it was a list of debtors in four hands going back to 1889 and the last entry was blank."),
		nar("And once at twenty-five, on a bad night, when it was the same list and the last entry had a date in it and the date was six years out."),
		nar("The strap is done up. The card tucked under it is not a card. It is a pawn ticket, the shop's own, the ones Elsa had printed in 1981 and never reordered because there were nine hundred of them."),
		say("nara", "You can't pawn this. You're the shop. I'm the shop. This is —"),
		say("shop", "..."),
		nar("There is a ticket under it. Filled in, in her handwriting, in pencil, which she has not done."),
		nar("[i]Item: N. Quill. Holder: the premises. Terms: thirty days from the date of first reading.[/i]"),
		nar("[i]Date of first reading: tonight.[/i]"),
		say("nara", "No, that's — I've been reading things for three years."),
		nar("[i]First reading of this item.[/i]"),
		say("nara", "..."),
		nar("She works it out standing up, which she is proud of afterwards."),
		nar("The fourth column was never a cost. It was a schedule of payments. Every time she spent the shop's money to look inside something, she was not buying a view — she was making an instalment on a thing that was being bought, on terms, by the premises, from the premises."),
		nar("And the thing being bought is on the counter with a strap round it."),
	])
	if run.sold_reading != "":
		out.append(nar("And she sold one down there for ninety pounds, which she now understands was not a sale. It was a payment [i]accelerated[/i]. Calder is not a factor because he factors debts. He is a factor because he is the reason yours comes due early."))
	elif run.fees_paid > 0:
		out.append(nar("%d paid in tonight, out of a drawer she thought was hers." % run.fees_paid))
	else:
		out.append(nar("Nothing paid in tonight. Zero instalments. The terms are still the terms, but the balance is where it was at midnight, and for the first time in three years the shop has got nothing off her."))

	out.append_array([
		nar("She thinks, for about ninety seconds, about the door."),
		nar("It is a real thought and she gives it a real hearing, because she is not a character in a story about a haunted shop, she is a woman with a coat on a hook and a sister in Sheffield and forty pounds in her own pocket that is hers and not the till's."),
		nar("She could walk. The estate would take the building. Somebody would buy it, and the shelves would shuffle at midnight for whoever that was, and the fourth column would open an account in a new name."),
		say("nara", "..."),
		say("nara", "And then I'd spend the rest of my life not knowing what was in it."),
		nar("That is the whole of it, said out loud in an empty shop at three forty in the morning, and she hears herself say it and understands that this was never a trap. A trap requires a mechanism. This required only a woman who wanted to know things."),
		nar("There is no menu here. The shop has not offered her a choice, because the shop does not have to — she has had her hand on every other object in this building all night, and this is the one that has been waiting."),
		say("nara", "Fine."),
		say("nara", "Let's see what I've been using myself for."),
	])

	# The unrefusable reading.
	run.charge_reading("collateral")
	run.record_reading("collateral")
	out.append(plate("collateral"))
	out.append_array([
		nar("It is this room. It is this hour. It is now, or near enough — the reading has caught up with itself, because the last use of Nara Quill was the last four hours and there is nothing else on the reel."),
		nar("She is standing where she is standing, on the customer's side of her own counter, four feet up and slightly behind, looking at her own back and her own hands."),
		nar("The waistcoat is open and off one shoulder because she has been reaching across a counter all night and nobody straightens their clothes at four in the morning in an empty shop."),
		nar("The monocle on its chain. Ink on three fingers. The bun that went a while ago."),
		nar("And the mirror behind the counter, which she has not looked into properly in about a year, which is doing what mirrors have been doing all night in every single one of these readings."),
		nar("In the glass she is looking straight out. At the vantage point. At the place where the person watching a reading stands."),
		say("nara", "..."),
		nar("That is not how a reading works. Nobody in a reading has ever once looked at her."),
		nar("The Nara in the mirror is not startled and is not frightened and is not apologising. She looks like someone who has been waiting at a counter for a long time and has finally been served."),
		nar("Then she says four words, and readings do not carry sound, so Nara gets the shape of it and the shape is unmistakable, because it is the shape of the thing painted backwards in gold on her own window."),
		nar("[i]What the dead will demand.[/i]"),
		nar("And then — because a reading runs to the end of the last use and this one has not finished — the Nara in the mirror reaches out of frame, and brings her hand back with a pencil in it, and writes on a ticket."),
		nar("She is left-handed in the glass, which is what a mirror does, and Nara watches her own hand form her own name backwards with the ease of somebody who has done it nine hundred times."),
		nar("She writes the item. She writes the holder. She writes the terms."),
		nar("And at the bottom, in the space where the broker signs to say the goods were received in good order, she writes, in the same hand, the thing that is painted on the window."),
		nar("Then she puts the pencil down and looks up, and for the first time in three years of doing this to other people, Nara finds out what it is like on the other side of a reading: to be the room, and to know somebody is standing in it, and to have no way at all of telling them to get out."),
		nar("The light goes."),
		scene("shop"),
		nar("Four twelve. The Black Ledger is on the counter with the strap done up and the ticket is gone."),
		goto("act_dawn"),
	])
	return out


# ---------------------------------------------------------------------------
# 06_dawn.rpy — dawn. Three endings, resolved from the ledger and nothing else.
#
# No romance decides this and no affection meter exists. What you own at dawn, and what owns
# you. CollateralCore.ending_of() is the whole rule; tests/playthrough.gd asserts all three
# are reachable.
# ---------------------------------------------------------------------------

static func l_act_dawn(run: C.Run) -> Array:
	var ending := C.ending_of(run)
	var out: Array = [
		scene("dawn"),
		nar("Five ten. The window goes from black to the colour of a bruise going down, and the gold letters come back the right way round for about four minutes, which they do every morning and she has seen perhaps six times."),
		nar("The count."),
		nar("Till: %d. On the shelf: %d — a finial, a ring, a veil, none of them claimed, all of them thirty days from being the shop's." % [run.till, run.stock_value()]),
		nar("Against the estate: %d." % C.DEBT),
		nar("Net: %d." % run.net_worth()),
	]
	if ending == C.FACTOR:
		out.append(goto("ending_factor"))
	elif ending == C.COLLATERAL:
		out.append(goto("ending_collateral"))
	else:
		out.append(goto("ending_solvent"))
	return out


static func l_ending_solvent(run: C.Run) -> Array:
	var out: Array = [
		nar("Clear. Not comfortable — clear."),
		nar("At eight she walks the two hundred to the estate office in an envelope, because Elsa never trusted a transfer, and the man behind the glass stamps a thing and the shop stops being a debt and starts being a shop."),
	]
	if run.readings_refused.size() >= 3:
		out.append_array([
			nar("In the back of the book, in the ruled section, three lines with nothing after them."),
			nar("She looks at them for a while on the walk back."),
			say("nara", "I could have. That's the bit. It wasn't that I couldn't."),
			nar("She did not see Tamsin's room, or Ivo's, or Mara's mirror. She priced three strangers on the evidence of brass, gold and crepe, and she got two of the three roughly right, and the third one she will never know about, which is the cost and she has decided she can carry it."),
		])
	else:
		out.append(nar("In the back of the book, some lines filled in and some not, and a balance that came out on the correct side of the line by an amount that would not survive one bad week."))
	out.append_array([
		nar("Nothing comes due. The stair behind the stock room has forty-one treads on it and the newest one near the top has her name on it and a date that was yesterday, and yesterday has now been and gone and nothing happened."),
		nar("That is what an unpaid instalment looks like from the outside. Nothing happening, indefinitely."),
		say("nara", "Thirty days on the ticket."),
		nar("She says it to the shop, out loud, at eight forty in the morning, and the shop does not answer, which she has decided to read as terms accepted."),
		nar("Tamsin Reed comes back on the Thursday with the other three finials. Nara pays her for a set."),
		goto("dawn_outro"),
	])
	return out


static func l_ending_factor(run: C.Run) -> Array:
	var sold_client: String = str(C.ITEMS[run.sold_reading]["client"])
	return [
		nar("The estate is settled by nine with sixty-odd left over, which is more money than this shop has had at one time since Elsa was upright."),
		nar("And a week later, exactly as advertised, she stops being able to picture it."),
		nar("She can still say the sentence. [i]%s — the room, the light, what happened in it.[/i] She can tell you the facts in the flat voice you use for facts." % sold_client),
		nar("But the picture is gone, and what is worse is that it was not taken from her. She sold it. She has a receipt, in the fourth column, in the credit side, which she did not know the fourth column had."),
		nar("In March, Calder comes up the stairs."),
		nar("He has never done that. Nobody from down there has ever done that. He stands on the customer's side of the counter in an apron over good clothes and looks around at the stock with the expression of a man doing a survey."),
		say("cal", "You've had a good quarter."),
		say("nara", "I've had a quiet one."),
		say("cal", "Same thing at your end. I'll take three this time."),
		say("nara", "I've only got —"),
		say("cal", "You'll have looked at more by now. You always do after the first. That's not a criticism, Quill, it's inventory forecasting."),
		nar("And the thing that finishes it is that he is right, and she knows he is right before he has got to the door, because she has spent three months taking readings she did not need and telling herself it was diligence."),
		nar("The shop is solvent. It has one supplier and one customer and they are the same man, and the product is other people, and it was never going to be anything else from the moment she found out what the fourth column was for."),
		say("nara", "Come back in March."),
		say("cal", "I did."),
		goto("dawn_outro"),
	]


static func l_ending_collateral(run: C.Run) -> Array:
	var out: Array = []
	if run.net_worth() >= C.DEBT:
		out.append(nar("The estate is settled, narrowly, out of a drawer that spent most of the night going the wrong way."))
	else:
		out.append(nar("The estate is not settled. She is %d short and she signs the extension at nine fifteen, which she is told is routine and which the man behind the glass does not look up for." % (C.DEBT - run.net_worth())))
	out.append_array([
		nar("But that was never what the night was about, and she knew it standing at the counter with her hand on a book."),
		nar("Four readings. Five. Every line in the ruled section filled in, every instalment paid, on terms she agreed to by putting her palm on things."),
		nar("The ticket said thirty days from the date of first reading. The date of first reading was last night. She has done the arithmetic and she is not going to do it again."),
		nar("Nothing dramatic happens on the thirtieth day. That is not the shape of this."),
		nar("What happens is that around the twenty-second she notices she has stopped going upstairs to the flat, and around the twenty-sixth she notices the shelves have stopped shuffling at midnight because they no longer need to do it while she is not looking."),
		nar("And on the thirtieth she is behind the counter at eleven fifty-eight with a stub of pencil and four columns, and the bell goes, and it is a woman in the rain with something in both hands."),
		nar("Nara says the sentence. It comes out in Elsa's cadence, which she has never managed before and will never manage otherwise again."),
		say("nara", "I buy anything I can price."),
		nar("And somewhere behind her in the dark of the case glass, the shop has her exactly where it has always had every single thing in this building: forward, in the lamp, priced, and waiting for whoever it is that will need her."),
		say("shop", "Thirty days on the ticket."),
		goto("dawn_outro"),
	])
	return out


static func l_dawn_outro(run: C.Run) -> Array:
	var ending := C.ending_of(run)
	var out: Array = [
		scene("dawn"),
		nar("[b]%s.[/b]" % C.ENDING_NAMES[ending]),
		nar("Readings taken: %d of 5. Refused: %d." % [run.readings_taken.size(), run.readings_refused.size()]),
	]
	if run.fees_refunded:
		out.append(nar("Refunded by the shop for readings it failed to deliver: %d." % run.fees_refunded))
	out.append({"t": "ledger"})
	out.append({"t": "end", "ending": ending})
	return out
