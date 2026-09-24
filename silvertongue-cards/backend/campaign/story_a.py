"""SUASION: THE NIGHT LEDGER -- the campaign's words, part A: the world, the prologue,
chapters 1-3.

Every stage is one duel. `rule` is a new row for the parent engine's RULES table
(`paths`, `help`), registered at import by campaign/__init__.py -- the engine file is
extended, never edited, and no new detector is added: every signal named here is a key of
persuasion_engine.COMMON. `mods` are the campaign's special rules (campaign/duel.py), all
of them checked again when the server replays the duel.

House rules for the writing (ops/adult_forks/silvertongue.md s5, ART_DIRECTION.md):
every woman here is an adult and says so in her own way; persuasion is wit and attention,
never leverage over anyone's work, money or safety; affection is earned; no religion.
Second person, present tense, noir: short sentences, concrete objects, nobody explains
their feelings when a glass can do it for them.
"""
from __future__ import annotations


def S(sid, title, who, goal, paths, help_, diff, intro, win, lose, mods=None, reply=None):
    return {"id": sid, "title": title, "who": who, "goal": goal,
            "rule": {"paths": [sorted(p) for p in paths], "help": sorted(help_)},
            "difficulty": diff, "mods": mods or {}, "intro": intro, "win": win, "lose": lose,
            "reply": reply}


WORLD = {
    "city": "Vell",
    "premise": (
        "Vell keeps two sets of books. The day ledger is the one the harbour authority "
        "audits. The Night Ledger is a green cloth volume in the back office of the Hotel "
        "Aurel, and it records one thing: who is trusted after two in the morning."),
}

PROLOGUE = (
    "Vell keeps two sets of books. The day ledger is the one the harbour authority audits. "
    "The Night Ledger is a green cloth volume in the back office of the Hotel Aurel, and it "
    "records one thing: who is trusted after two in the morning.\n\n"
    "Five houses sign it. The Low Tide, a bar at the end of the docks. The Kilns, where the "
    "painters work until the light gives out and then keep going. The studio on Glass "
    "Street, which makes the faces the city puts on its posters. The front desk of the "
    "Aurel itself. And the Ledger's own keeper, who signs last and never early.\n\n"
    "Once a year, on the Long Night, the houses write one name on the first page: the "
    "Silver Tongue, the one person every door in Vell opens for. For seven years that name "
    "has been Celeste Marrow's.\n\n"
    "You left Vell eleven months ago with one bag and a reason you never said out loud. "
    "You are back with the same bag and no reason at all, except that you are good at "
    "one thing: talking to someone until they want to keep talking to you.\n\n"
    "Word travels fast after dark. By your second night back, somebody has left a card "
    "under your door. Heavy stock, silver ink, no name. Four lines.\n\n"
    "Threats. Bribes. Insults. Orders.\n"
    "That is how the last ones tried.\n"
    "Every one of them is still waiting at a door.\n"
    "Try it the other way. -- C.")

# ==========================================================================================
CH1 = {
    "id": "c1", "title": "Last Orders", "house": "The Low Tide", "who": "mara",
    "intro": (
        "The Low Tide is the last light on the docks. It has one window, nine stools and a "
        "handwritten rule behind the till: THE BARTENDER DOES NOT DRINK WITH CUSTOMERS. "
        "Mara Cole has owned it for six years. She is thirty-one, she has a tattoo of a "
        "compass on her forearm that she will not explain, and she is the first signature "
        "anybody gets, because nobody in Vell gets past the docks without her knowing.\n\n"
        "She does not sign for strangers. You are a stranger. Start there."),
    "outro": (
        "She writes it on a beer mat first, to see how it looks. Then she takes the mat to "
        "the Aurel herself, in her apron, at four in the morning, and puts it on the "
        "night desk without a word.\n\n"
        "When she gets back she pours two. 'One,' she says. 'And you should know I am "
        "very bad at one.' The rule stays on the wall. It just has a footnote now."),
    "stages": [
        S("c1s01", "Wrong Side of the Shutter", "mara",
          "Get Mara to let you stay while she closes.",
          [{"warmth"}], {"respect"}, "gentle",
          "Two in the morning and the shutter is halfway down. You are inside it. Mara looks "
          "at you the way you look at a wet umbrella somebody has left on your floor: not "
          "angry, just deciding where to put it. 'We're closed,' she says, and keeps wiping.",
          "She tosses you a dry cloth. 'Glasses on the left, upside down. If you break one "
          "you're out.' It is not a welcome. It is the next best thing.",
          "'Go home, stranger.' The shutter comes down the rest of the way, and you are on "
          "the wrong side of it."),
        S("c1s02", "The Glass Rack", "mara",
          "Ask Mara to let you help her wash up.",
          [{"respect", "direct_request"}], set(), "gentle",
          "Night two. You come in at a quarter to two, order nothing, and sit where she can "
          "see you. The glasswasher is broken again. There are ninety glasses and one "
          "woman, and the woman is pretending there are not ninety glasses.",
          "She slides the rack down the bar. 'Hot water burns. Don't be brave about it.' You "
          "work side by side for an hour and she tells you nothing, which is a kind of trust.",
          "'I've got it.' She has not got it. She does it anyway, alone, and you watch "
          "from the door."),
        S("c1s03", "Who Drinks on the Docks", "mara",
          "Get Mara to tell you who her regulars are.",
          [{"empathy", "warmth"}], {"respect"}, "silver",
          "The stools have names you cannot see. The crane driver who drinks stout and "
          "cries at the football. The two nurses off the night shift. The man who pays in "
          "coins and never speaks. Mara knows every one of them, and she guards the list "
          "like a till.",
          "'Stool four is Deni. Don't sit there on a Friday.' She tells you all nine. By the "
          "end she is smiling at the ones she likes, and she likes more of them than she lets on.",
          "'They're customers.' She says it like a door closing, and polishes stool four "
          "until it shines."),
        S("c1s04", "The Tab", "mara",
          "Own up to the tab you ran up last week.",
          [{"accountability", "respect"}], {"direct_request"}, "silver",
          "There is a slip of paper under the till with your name on it and a number that "
          "is not small. You meant to pay it. You meant to do a lot of things. Mara has not "
          "mentioned it, which is worse than if she had.",
          "She tears the slip in half and writes the number again on a fresh one. 'Now "
          "it's a real tab. Real tabs get paid.' It is the first time she has used your name.",
          "'It's fine.' It is not fine. She moves the slip to where you can see it, and "
          "leaves it there."),
        S("c1s05", "The Late Delivery", "mara",
          "Help Mara make sense of the brewery's short order.",
          [{"evidence", "warmth"}], {"direct_request"}, "silver",
          "The brewery van came at midnight, three kegs short and with an invoice for "
          "twelve. Mara has been staring at the paperwork for twenty minutes with the "
          "expression of a woman who would rather fight the driver than the arithmetic.",
          "You find it: the kegs went to the Aurel by mistake. She laughs for the first time "
          "all week, the real one, head back. 'Celeste's drinking my stout. Of course she is.'",
          "'Leave it. I'll ring them.' She rings nobody. The invoice stays pinned to the "
          "wall, wrong."),
        S("c1s06", "A Regular Named Celeste", "celeste",
          "Win back your stool from the woman in grey.",
          [{"respect", "direct_request"}], {"warmth"}, "silver",
          "Your stool is taken. The woman on it is in a grey silk suit that has never "
          "been near a dock, and she is drinking Mara's stout. She does not turn round. "
          "'You're the one who came back,' Celeste Marrow says to the mirror. 'Sit if you "
          "can talk me off it.'",
          "She gets up, finishes the stout, and leaves the stool warm. 'Not bad. Your "
          "second sentence was better than your first.' At the door she adds: 'Mara hates "
          "being handled. Don't.'",
          "'No.' She orders another, on your tab. Mara, polishing, does not quite hide her grin.",
          mods={"muted": 1}),
        S("c1s07", "The Rule on the Wall", "mara",
          "Ask Mara why the rule behind the till exists.",
          [{"empathy", "respect"}], {"warmth"}, "silver",
          "You have read the rule a hundred times. Tonight, alone with her and the last "
          "of the ice, you ask about it. Mara goes still in the way people go still when "
          "a question has been waiting for them.",
          "'I drank with one once. He kept coming back as if I owed him the second one.' "
          "She says it to the tap, not to you. 'The rule's for me. Not for you.' Then: 'Thanks for asking.'",
          "'It's a rule.' She turns the radio up. The conversation is over, and the radio "
          "is playing something sad on purpose."),
        S("c1s08", "Burned Hands", "mara",
          "Get Mara to let you look after her burned hand.",
          [{"warmth", "empathy"}], {"direct_request"}, "gold",
          "The glasswasher door came down on her wrist at eleven. She kept working. Now, at "
          "two, the skin has gone angry and she is holding a pint glass of ice against it and "
          "insisting it is nothing.",
          "She lets you wrap it. She watches your hands the whole time, and when you are done "
          "she does not take hers back straight away.",
          "'It's nothing.' She finishes closing one-handed, slower, and does not say goodnight."),
        S("c1s09", "The Jukebox", "mara",
          "Ask Mara to dance after close.",
          [{"warmth", "direct_request"}], {"respect"}, "gold",
          "Somebody left a coin in the jukebox and walked out before it played. The song "
          "comes on in an empty bar: slow, old, a woman singing about a harbour. Mara stops "
          "stacking stools and does not start again.",
          "She dances the way she pours: no wasted movement, her hand flat and warm between "
          "your shoulders. When the song ends she steps back. 'Don't tell the crane driver.'",
          "'I don't dance.' She pulls the plug on the jukebox, and the harbour goes quiet."),
        S("c1s10", "Something New on the Menu", "mara",
          "Talk shop with Mara about the cocktail she is inventing.",
          [{"craft", "warmth"}], {"respect"}, "gold",
          "She has been working on a drink for the Long Night. Smoke, salt, something bitter "
          "at the back. It is nearly right. Nearly right is the thing that keeps bartenders "
          "awake, and she has pushed a glass across to you without a word.",
          "You name what is missing and she adds it, and it is right. She writes it on the "
          "board: THE STRANGER. Then she rubs out the second word. 'Not a stranger any more.'",
          "'It's fine as it is.' She pours it down the sink and makes the old one instead."),
        S("c1s11", "Why You Want It", "mara",
          "Tell Mara the truth about why you want the Ledger.",
          [{"accountability", "evidence"}, {"empathy", "direct_request"}], {"respect"}, "gold",
          "'Everyone wants the Ledger for a reason,' Mara says. 'Celeste wanted to be wanted. "
          "The ones before her wanted to be owed. What's yours?' She has put the good bottle "
          "on the bar and not opened it. That is the question she is really asking.",
          "She listens to all of it. Then she opens the bottle. 'That's a better reason than "
          "most. It's not good enough yet. It will be.'",
          "'Think about it,' she says, and puts the bottle back behind the espresso machine."),
        S("c1s12", "BOSS: Last Orders", "mara",
          "Get Mara to stay and have one drink with you. Eight turns. No second chances.",
          [{"warmth", "respect"}], {"direct_request"}, "gold",
          "The night the Ledger opens for signatures, Mara closes early. Eight minutes to two. "
          "The shutter is three-quarters down and you are the last one inside it. She has "
          "been on her feet since four, and there is a rule about customers, and she has not "
          "yet told you to go. You have until the clock says two.",
          "One drink. The shutter locks from inside. She signs the beer mat before the glass "
          "is empty.",
          "Two o'clock. 'Come back on a Tuesday,' she says, and means it, and that is the "
          "cruellest thing about it.",
          mods={"turns": 8, "boss": "Last Orders: the duel ends at eight turns."},
          reply="closing_time"),
    ],
}

# ==========================================================================================
CH2 = {
    "id": "c2", "title": "Wet Paint", "house": "The Kilns", "who": "yuenha",
    "intro": (
        "The Kilns used to fire bricks. Now they fire painters: forty studios in a "
        "building with no heating and very good north light. Yuen Ha Lam has the top floor, "
        "which she took in exchange for fixing the roof herself. She is thirty-eight, she "
        "has not finished a painting she was happy with in three years, and she works as if "
        "the building is on fire.\n\n"
        "The Kilns sign as one house, and the house signs what Yuen Ha signs. Mara said it "
        "plainly: 'She doesn't care who you are. She cares whether you can see.'"),
    "outro": (
        "She paints your name into the corner of the blue canvas, very small, where only "
        "someone looking hard would find it. 'That's my signature,' she says. 'On the Ledger "
        "I'll use a pen. This one's the one that counts.'\n\n"
        "The left third is finished. She stands in front of it for a long time with her "
        "glasses pushed up into her hair, and then she turns off the worklamp for the "
        "first time in eleven hours."),
    "stages": [
        S("c2s01", "Five Flights", "yuenha",
          "Get Yuen Ha to open her studio door.",
          [{"respect"}], {"craft"}, "silver",
          "There is no lift. There is a sign on the fifth-floor door that says WORKING, and "
          "under it someone has written in pencil ALWAYS. You knock. Through the door, a "
          "brush keeps moving. 'If it's about the rent, I paid it in roof.'",
          "The door opens six inches. She looks at your shoes, your hands, your face, in that "
          "order. 'Don't touch anything wet. Everything's wet.'",
          "The brush does not stop. After a while you go back down the five flights."),
        S("c2s02", "Coffee, Black", "yuenha",
          "Get Yuen Ha to take a break long enough to drink a coffee.",
          [{"warmth", "respect"}], {"precision"}, "silver",
          "You brought coffee. She has not looked at it. It has gone cold on the windowsill "
          "next to four other cups, one of which has a brush standing in it. The painter has "
          "been standing for nine hours and her left hand is shaking slightly.",
          "She drinks it cold, in one go, like medicine. 'You noticed the hand.' She puts the "
          "cup down with the others. 'Nobody notices the hand.'",
          "'Later.' Later, the cup has a brush in it too."),
        S("c2s03", "Stretcher Bars", "yuenha",
          "Ask Yuen Ha to let you help build a frame.",
          [{"craft", "direct_request"}], {"respect"}, "silver",
          "A canvas the size of a door, and four lengths of pine that are supposed to hold it. "
          "She is trying to square the corners alone, which is a job for two people and a "
          "patient one. She has already sworn at the pine in two languages.",
          "You hold, she staples. The corners come square on the first try. She runs her thumb "
          "along the join and nods once, which from her is applause.",
          "'I'll manage.' She manages. One corner is a quarter-inch out and she will see it "
          "every day for a year."),
        S("c2s04", "The Left Third", "yuenha",
          "Tell Yuen Ha honestly what is wrong with the painting.",
          [{"craft", "respect"}], {"precision"}, "silver",
          "The big canvas is a harbour at night, and the left third is wrong. She knows it is "
          "wrong. She has been painting over it for a week. 'Everyone says it's lovely,' she "
          "says, without turning round. 'Say something that isn't lovely.'",
          "She listens with her whole back. Then she takes a rag to the left third and wipes "
          "a week away. 'Finally. Somebody rude.'",
          "'Lovely,' she repeats, flatly, and goes back to painting it wrong."),
        S("c2s05", "The Review", "yuenha",
          "Get Yuen Ha to talk about the critic's letter.",
          [{"empathy", "craft"}], {"respect"}, "silver",
          "The letter is pinned to the wall with a palette knife. A critic from the capital, "
          "two paragraphs, the word DERIVATIVE underlined in her own red. She says it doesn't "
          "matter. The palette knife says otherwise.",
          "'He's half right. That's what's unbearable.' She pulls the knife out and uses it to "
          "mix a colour. The letter falls behind the radiator, where it belongs.",
          "'It doesn't matter.' She says it three more times that night, to the canvas."),
        S("c2s06", "The Sitter", "celeste",
          "Get Celeste to give up the sitter's chair tonight.",
          [{"craft", "evidence"}], {"respect", "direct_request"}, "silver",
          "Someone is sitting for Yuen Ha. Grey silk on a paint-spattered chair, legs crossed, "
          "perfectly still. Celeste has been a sitter here for a month, which you did not "
          "know. 'She's painting me as the city,' she says, not moving her lips much. 'What "
          "are you here as?'",
          "She stands, stretches like a cat, and gives you the chair. 'Sit still. She hates "
          "fidgeting.' On her way out: 'She painted me in three sittings. See how long you take.'",
          "'Sit on the floor, then.' She holds the pose for two more hours, and you do.",
          mods={"muted": 1, "turns": 12}),
        S("c2s07", "Turpentine", "yuenha",
          "Persuade Yuen Ha to open a window before the fumes get her.",
          [{"precision", "respect"}], {"warmth"}, "gold",
          "The turpentine has been open since noon. The air in the studio is sweet and wrong, "
          "and she is swaying slightly in front of the canvas and calling it concentration. "
          "The windows were painted shut in a previous decade.",
          "You get one open with a palette knife and the night comes in, cold and clean. She "
          "sits on the floor under it and breathes. 'Exactly what I needed. Don't say anything.'",
          "'I'm fine.' She is not fine. She goes home at five with a headache the size of the Kilns."),
        S("c2s08", "Don't Sell the Blue One", "yuenha",
          "Talk Yuen Ha out of selling her best painting for rent money.",
          [{"evidence", "craft"}], {"precision"}, "gold",
          "A dealer is coming at nine to buy the blue painting for less than it cost to "
          "frame. She has decided. She has wrapped it in a sheet like a body. 'Rent is rent,' "
          "she says. 'Painting is only painting.'",
          "The sheet comes off. She hangs the blue one back on its nail and looks at it as "
          "if she had been about to lose a friend. 'I'll sell the small ones. The bad ones.'",
          "At nine, the dealer takes it down five flights under his arm. She watches from the window."),
        S("c2s09", "Hands", "yuenha",
          "Ask Yuen Ha if you can sit for her.",
          [{"respect", "direct_request"}, {"craft", "precision"}], {"warmth"}, "gold",
          "'I need hands,' she says suddenly, at three in the morning. 'Not a face. Faces "
          "lie. Hands.' She is looking at yours. She has been looking at them for a week.",
          "She draws your hands for an hour and does not speak. Her fingers adjust yours "
          "twice, light as a brush. When she is done she keeps hold of one a moment too long.",
          "'Forget it. I'll draw my own.' She does, left-handed, badly, and tears it up."),
        S("c2s10", "The Kiln Street Show", "yuenha",
          "Convince Yuen Ha to show the new work.",
          [{"craft", "precision"}], {"respect", "direct_request"}, "gold",
          "Every winter the Kilns open their doors for one night and the city comes up the "
          "stairs to look. Yuen Ha has not shown in three years. The flyer is printed. Her "
          "name is not on it.",
          "She writes her name on every flyer by hand. A hundred and forty of them. Her "
          "wrist aches after, and she lets you hold it.",
          "The show opens without her. Her door says WORKING. Nobody knocks."),
        S("c2s11", "Eleven Hours", "yuenha",
          "Get Yuen Ha to stop for the night.",
          [{"warmth", "craft", "respect"}], {"precision"}, "gold",
          "Eleven hours at the canvas and the left third is almost there. Almost is the "
          "most dangerous place a painter can stand, because it feels like one more hour. "
          "It is never one more hour.",
          "She puts the brush in the jar and does not pick it up again. 'Tomorrow it'll be "
          "right or it won't.' She has paint on her jaw. You do not mention it.",
          "'One more hour.' It is six more hours, and the left third is worse."),
        S("c2s12", "BOSS: Wet Paint", "yuenha",
          "Get Yuen Ha to put the brush down and let you stay. You hold only two cards.",
          [{"craft", "respect"}], {"precision"}, "gold",
          "The night before the Kiln Street show, the worklamp is the only light and it is "
          "aimed at the canvas, not at her. She has been at this eleven hours and the left "
          "third is still wrong. You brought her something to eat two hours ago and have not "
          "left. She has not asked you to. Everything in the room is wet, including the "
          "floor, and you are travelling light.",
          "The brush goes in the jar. The lamp goes off. In the dark she says, 'Stay. The "
          "paint won't dry till morning anyway.'",
          "'Go home. I mean it kindly.' She does, and you do, and the left third stays wrong.",
          mods={"hand": 2, "boss": "Wet Paint: you hold two cards, not three."},
          reply="life_model"),
    ],
}

# ==========================================================================================
CH3 = {
    "id": "c3", "title": "Terms", "house": "Glass Street", "who": "sanne",
    "intro": (
        "The studio on Glass Street makes the faces Vell sees on its buses. Sanne de Vries "
        "runs it on rules: a contract for every client, an invoice for every hour, and no "
        "client in the studio after the lights go off. She is thirty-six, she shaved one "
        "side of her head the day she signed the lease, and she has never once been late.\n\n"
        "Glass Street signs on terms. Yuen Ha warned you: 'Sanne can't be charmed. She can "
        "be convinced. Bring facts, and say exactly what you mean.'"),
    "outro": (
        "She drafts it like a contract, because she cannot help it. Party of the first "
        "part, Glass Street. Party of the second part, you. Consideration: none. 'That's "
        "the clause that makes it valid,' she says. 'Nobody paid for this.'\n\n"
        "She signs it with the pen she uses for invoices, then takes the invoice from the "
        "stool, the one that was never signed, and folds it into a very small square."),
    "stages": [
        S("c3s01", "Contact Sheet", "sanne",
          "Get Sanne to show you the day's contact sheet.",
          [{"evidence"}, {"precision"}], {"respect"}, "silver",
          "Glass Street at midnight smells of hot bulbs and coffee. Sanne is bent over a "
          "light table with a loupe in her eye, marking frames with a red pencil. She has "
          "seen you. She has not stopped marking. 'Studio's closed to visitors.'",
          "She hands you the loupe. 'Frame nine. Tell me what's wrong with it.' You tell her. "
          "She circles it in red. 'Hm.'",
          "'Closed means closed.' The red pencil keeps moving."),
        S("c3s02", "The Shoot Ran Long", "sanne",
          "Get Sanne to let you carry the lights.",
          [{"evidence", "direct_request"}], {"respect"}, "silver",
          "The shoot ran two hours over and the assistant went home at ten. There are four "
          "stands, two softboxes and a generator to go back up the stairs, and one woman, and "
          "the woman has a rule about asking for help.",
          "You carry the generator. She carries the softboxes and a clipboard, and ticks you "
          "off the kit list like a piece of equipment. It is, from her, affectionate.",
          "She does four trips alone. The last one is at three."),
        S("c3s03", "Terms of Entry", "sanne",
          "Agree exact terms for being allowed in the studio after dark.",
          [{"precision", "respect"}], {"direct_request"}, "silver",
          "'If you're going to keep turning up,' Sanne says, 'we need terms.' She has typed "
          "them. There are eleven. Clause four is about coffee. Clause nine is about the "
          "darkroom door, and she reads it twice.",
          "You agree to eleven clauses and amend one. She initials the amendment. 'Nobody "
          "has ever amended my terms,' she says, and seems pleased about it.",
          "'Then no terms.' She puts the typed sheet in a drawer, and the drawer locks."),
        S("c3s04", "The Unpaid Invoice", "sanne",
          "Help Sanne work out why a client won't pay.",
          [{"evidence", "precision"}], {"direct_request"}, "silver",
          "A client owes Glass Street four months. Sanne has the contract, the invoice, the "
          "delivery note and a face like a closed shutter. 'I did everything right,' she says. "
          "'That's what makes it unbearable.'",
          "You find the clause the client is hiding behind, and the clause after it that kills "
          "the first. She rings them at nine sharp. They pay by noon.",
          "The invoice goes in a folder labelled PENDING. It is a very thick folder."),
        S("c3s05", "Portrait of the Photographer", "sanne",
          "Ask Sanne to let you take her photograph.",
          [{"direct_request", "respect"}], {"evidence"}, "silver",
          "In six years nobody has photographed Sanne. She is always behind the camera. "
          "There is not one picture of her in the studio, which has ten thousand pictures "
          "in it. You pick up the old Leica from the shelf.",
          "She sits on the stool under one bare bulb and looks straight down the lens, flat "
          "and unimpressed, and it is the best photograph ever taken in that room.",
          "'Put it down. Carefully.' You do. She checks it for fingerprints."),
        S("c3s06", "Lit From the Left", "celeste",
          "Win the last half-hour of studio time from Celeste.",
          [{"evidence", "precision"}], {"direct_request"}, "silver",
          "Celeste has booked the studio until two, for a portrait she will not explain. "
          "She is under Sanne's lights in a black dress, lit from the left, looking like "
          "the poster of herself. 'Half an hour left,' she says. 'Make an offer I can "
          "understand.'",
          "She steps out of the light. 'Precise. She'll like that.' Sanne, behind the camera, "
          "does not say anything, which means she agrees.",
          "'No sale.' She uses every minute. Sanne bills her for it, to the second.",
          mods={"steal_every": 4}),
        S("c3s07", "The Darkroom Door", "sanne",
          "Ask Sanne what clause nine is really about.",
          [{"empathy", "precision"}], {"respect"}, "gold",
          "Clause nine: nobody enters the darkroom while the red light is on. Tonight the "
          "red light is on and she has been inside for an hour, and there is no sound of "
          "work, and the clause suddenly looks less like a rule and more like a wall.",
          "She opens the door herself. Inside, pinned on a line, are prints of a woman who "
          "looks like her, older. 'My mother. I print her every year. That's clause nine.'",
          "The red light stays on until dawn. The clause holds."),
        S("c3s08", "Deadline", "sanne",
          "Convince Sanne to hand in the work she thinks isn't ready.",
          [{"evidence", "direct_request"}], {"precision"}, "gold",
          "The poster campaign is due at eight. It is four. Sanne has thirty frames she "
          "thinks are good and one she thinks is perfect, and she will not send the "
          "thirty without finding a second perfect one.",
          "She sends the thirty at seven fifty-nine. At nine the client rings to say frame "
          "twelve is the best thing they have ever seen. It is not the perfect one.",
          "She misses the deadline by an hour and pays the penalty clause herself."),
        S("c3s09", "Off the Books", "sanne",
          "Ask Sanne to let you watch her work on her own project.",
          [{"precision", "direct_request"}, {"evidence", "empathy"}], {"respect"}, "gold",
          "She has a project nobody pays for: every closed shop on Glass Street, "
          "photographed at four in the morning. It is not on an invoice. It is the only "
          "work she does that is not on an invoice, and she has never shown it to anyone.",
          "You follow her down Glass Street at four with the tripod. She lets you choose one "
          "frame. She prints it that night and gives it to you, unsigned.",
          "'It's not for anyone.' She goes out alone with the tripod."),
        S("c3s10", "Contact Print", "sanne",
          "Get Sanne to admit the contract has an exception.",
          [{"evidence", "precision", "respect"}], {"direct_request"}, "gold",
          "'Every contract has an exception clause,' you say. Sanne puts down the loupe. "
          "'Mine don't.' She is lying, and you both know it, and she knows you know, and "
          "the studio is very quiet.",
          "'Clause twelve,' she says finally. 'It's blank. I left it blank on purpose.' She "
          "does not say who it is for. She does not need to.",
          "'No exceptions.' She files the contract. The folder is labelled ALWAYS."),
        S("c3s11", "The Lens Case", "sanne",
          "Get Sanne to leave the lenses unpacked for once.",
          [{"precision", "warmth"}], {"direct_request", "respect"}, "gold",
          "Sanne always packs the lenses. Every one, in its foam, in order, before she does "
          "anything else. Tonight she has picked up the first one and is standing with it "
          "in her hand, not packing it.",
          "She puts the lens down on the stool, unpacked. It is the most reckless thing you "
          "have ever seen her do. She is aware of this.",
          "The lenses go in their foam, in order. It takes eleven minutes."),
        S("c3s12", "BOSS: Terms and Conditions", "sanne",
          "Get Sanne to break her rule about clients. Conditions first, then the ask.",
          [{"evidence", "precision"}], {"direct_request", "respect"}, "gold",
          "The last card is backed up and the softbox is still warm. She has told you the "
          "rule twice now, both times without heat, the way you would read out a shutter "
          "speed. The invoice is on the stool between you, unsigned. She has not started "
          "packing the lenses. Sanne will hear the conditions before she hears the question, "
          "and she wants both things she is owed: the ask, and the manners.",
          "'Conditions accepted.' She turns the studio lights off, one by one, and does not "
          "turn on the house lights.",
          "'The rule stands.' She packs the lenses. All of them. In order.",
          mods={"support": 2, "order": [["precision", "direct_request"]],
                "boss": "Terms and Conditions: state a condition (precision) before you ask "
                        "(direct request), and bring both kinds of support."},
          reply="house_rule"),
    ],
}
