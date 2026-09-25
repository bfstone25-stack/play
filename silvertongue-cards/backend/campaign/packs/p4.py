"""Update pack 4 (week 12): THE OWL -- Mireille Sato, conductor of the night sleeper.

Path signals: cooperation + respect (she likes passengers who cooperate gracefully and ask
properly). Help: precision. Boss rule: she punches your costliest card every third turn,
and a win needs two kinds of support.

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety; no religion;
second person, present tense, noir. Every reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "mireille", "Mireille", "sleeper", 29
PATH_SIGNALS, HELP_SIGNAL = ("cooperation", "respect"), "precision"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("mireille_01", "Go ahead. Take a look at my ticket.", "cooperation"),
    _c("mireille_02", "Here it is. Punch it wherever you like.", "cooperation"),
    _c("mireille_03", "Thank you for keeping the night so neat.", "respect"),
    _c("mireille_04", "I appreciate a train that runs to time.", "respect"),
    _c("mireille_05", "Exactly as printed. Car four, berth two.", "precision"),
    _c("mireille_06", "Wake me only if we're early.", "precision"),
    _r("mireille_07", "Go right ahead. Thank you for asking.", "cooperation", "respect"),
    _r("mireille_08", "Check the bag, exactly as the rules say.", "cooperation", "precision"),
    _r("mireille_09", "Thank you. Exactly the berth I wanted.", "respect", "precision"),
    _r("mireille_10", "Nothing to hide. I appreciate the care.", "cooperation", "respect"),
    _e("mireille_11", "Go ahead, exactly as you like. Thank you.", "cooperation", "precision", "respect"),
    _e("mireille_12", "Here you go: only if it's you. Thank you.", "cooperation", "precision", "respect"),
]

CHAPTER = {
    "id": "p4", "title": "The Owl", "house": "The Night Sleeper, Car Four", "who": WHO,
    "intro": (
        "Celeste taps the next name on the second page with a gloved finger. 'This one "
        "never stays in Vell long enough to be asked,' she says. 'She leaves at twenty to "
        "midnight and comes back the next evening. Buy a ticket, darling. A good one.'\n\n"
        "The Owl is the night sleeper: twelve cars of burgundy and brass, out of Vell "
        "Central at twenty to midnight, into the coast at dawn. Its conductor is Mireille "
        "Sato, twenty-nine, long black ponytail, straight bangs, peaked cap, white gloves "
        "and a ticket punch she wears like a badge. She knows every berth by the sound of "
        "its door. She is polite to everyone and exact with everyone, and the regulars say "
        "that under the manners she is laughing at all of them. She has never signed "
        "anything that was not a timetable."),
    "outro": (
        "She signs at the last stop before dawn, on the fold-down table in berth two, with "
        "her own pen and the cap set beside the book like a witness. Then she takes the "
        "gloves off, one finger at a time.\n\n"
        "Later she sits on the edge of the berth with the uniform folded on the rack and "
        "her arms crossed over her chest, the blind up an inch, the grey coast going by. "
        "She looks back at you over her shoulder, ponytail loose for once. 'We arrive in "
        "forty minutes,' she says. 'I have never been late in seven years.' She does not "
        "move. The train slows, and she lets it, and when the guard in car one calls the "
        "station over the speaker, she laughs and says, 'Exactly on time. Stay where you "
        "are.'"),
    "stages": [
        S("p4s01", "Tickets, Please", "mireille",
          "Get Mireille to punch your ticket without a lecture.",
          [{"cooperation"}], {"respect"}, "silver",
          "Twenty to midnight, Vell Central, steam on the platform. The Owl's doors close on "
          "the second. Mireille comes down the corridor of car four with the punch in one "
          "white glove, and she stops at you. 'Ticket,' she says, pleasantly, 'and the "
          "reservation, and whatever story goes with the reservation.'",
          "Click. A small neat hole, dead centre. 'Welcome aboard the Owl,' she says, and "
          "for a moment the manners slip into a grin.",
          "She punches it correctly and moves on. You get the regulation smile and nothing "
          "else."),
        S("p4s02", "The Wrong Berth", "mireille",
          "Get Mireille to move you to the berth you actually booked.",
          [{"respect"}], {"cooperation"}, "silver",
          "Berth two has a man in it already, a retired schoolmaster in his seventies, "
          "asleep in his shoes. Your ticket says berth two. His says berth two. Mireille "
          "reads both with the patience of someone who has seen this every week for years.",
          "She lets the schoolmaster sleep, walks you to the end of the car and opens a "
          "berth nobody is sold. 'Conductor's spare,' she says. 'Don't make me regret it.'",
          "She finds you a seat in the lounge car. It is a very nice seat. It does not lie "
          "flat."),
        S("p4s03", "Bag Check", "mireille",
          "Help Mireille through a spot check without slowing the train.",
          [{"cooperation", "respect"}], {"precision"}, "silver",
          "At the border halt the rules want a random bag check, and Mireille picks yours, "
          "because of course she does. She sets it on the corridor rail and pulls on a fresh "
          "pair of gloves with a snap. 'Standard procedure,' she says. 'Probably.'",
          "She finds nothing but a paperback and a clean shirt, and she folds the shirt "
          "better than you did. 'Very tidy,' she says. 'Suspiciously tidy.'",
          "She does the check by the book, slowly, and the halt runs four minutes over. She "
          "does not forgive you for the four minutes."),
        S("p4s04", "The Dining Car", "mireille",
          "Ask Mireille to take her half-hour break at your table.",
          [{"respect", "direct_request"}], {"cooperation"}, "silver",
          "One in the morning. The dining car is empty but for the cook, a big woman in her "
          "forties who plays cards against herself. Mireille eats standing up at the "
          "pantry hatch, cap on, as if the timetable might catch her sitting.",
          "She sits. She takes the cap off and puts it on the chair beside her, where it "
          "watches you both. She eats the cook's soup slowly and steals your bread.",
          "'Regulations,' she says, and finishes her soup at the hatch, standing."),
        S("p4s05", "The Timetable", "mireille",
          "Get Mireille to show you the one stop that isn't printed.",
          [{"cooperation", "precision"}], {"respect"}, "silver",
          "Her timetable is a small black book, every halt in her own handwriting. Between "
          "two stations there is a line with no name, just a time: ten past two. You ask. "
          "She closes the book on your fingers, gently.",
          "At ten past two the Owl slows by a field with one lamp in it, and she opens the "
          "door and lets you smell the night. 'Nobody gets on,' she says. 'I just like to "
          "stop.'",
          "'Signals,' she says. The train slows at ten past two anyway, and she does not "
          "let you see why."),
        S("p4s06", "First Class", "celeste",
          "Get Celeste to stop telling Mireille stories about you.",
          [{"riddle", "specific_praise"}], {"respect"}, "gold",
          "Car one, first class, velvet and brass: Celeste Marrow, travelling of course in the "
          "best compartment, with a glass of something pale and your conductor sitting "
          "opposite, laughing. 'Darling,' says Celeste, 'I was just telling Mireille about "
          "the night you lost a duel to a sommelier.'",
          "Celeste raises her glass. 'Fine. Keep your secrets, darling. She'll get them out "
          "of you by dawn anyway.' Mireille punches Celeste's ticket twice, for luck.",
          "Celeste finishes the story. It has a sommelier in it. Mireille has to go and stand "
          "in the vestibule for a minute.",
          mods={"muted": 1}),
        S("p4s07", "The Punch", "mireille",
          "Get Mireille to tell you what the punch is really for.",
          [{"respect", "cooperation"}], {"precision"}, "gold",
          "The punch cuts a shape, not a hole. Every conductor has their own. Hers is a "
          "small owl, and you have now counted seven of them in your ticket, one for each "
          "night. She says the other passengers get one.",
          "'One for a passenger,' she says. 'Two for a regular. Seven is something I haven't "
          "decided the name of yet.' She punches an eighth, right on the edge.",
          "'Faulty punch,' she says, deadpan, and polishes it on her sleeve."),
        S("p4s08", "Night Shift", "mireille",
          "Get Mireille to let you walk the train with her on her rounds.",
          [{"cooperation", "direct_request"}], {"respect"}, "gold",
          "Three in the morning is her rounds: every car, every door, every lamp. She walks "
          "the swaying corridors without touching the rail. Passengers are not allowed past "
          "the vestibule of car six, and she makes that sound like a compliment.",
          "You walk the whole train, to the guard's van at the end, where the lamp shows the "
          "track running back to Vell. 'This is the best seat,' she says. 'Nobody buys it.'",
          "She walks her rounds alone. You hear her boots go all the way to the end and all "
          "the way back.",
          mods={"stale_cost": 2}),
        S("p4s09", "The Stopped Clock", "mireille",
          "Get Mireille to admit why her watch runs two minutes fast.",
          [{"respect", "cooperation"}], {"precision", "empathy"}, "gold",
          "She checks her watch at every halt. It is a man's watch, heavy, and it runs two "
          "minutes fast, which in a conductor is like a surgeon who hums. You notice. She "
          "notices you notice.",
          "'My grandfather's,' she says. 'He drove the Owl for forty years. He said a "
          "conductor should always be two minutes early for her own life.' She does not "
          "reset it.",
          "'Manufacturing fault,' she says, and puts her glove over it.",
          mods={"hand": 2}),
        S("p4s10", "Snow on the Line", "mireille",
          "Keep Mireille company while the Owl waits out a snowdrift.",
          [{"cooperation"}, {"respect", "precision"}], {"empathy"}, "gold",
          "The Owl stops in white nothing between two stations. Snow on the line. The heating "
          "ticks. For the first time in her career the train is going to be late, and "
          "Mireille stands in the corridor with the timetable open, as if it might argue.",
          "You get her to close the book. She sits down beside you on the corridor seat and "
          "watches the snow, and says, after a while, 'It's quite beautiful when you're not "
          "in charge of it.'",
          "She stands at the window all night, timetable open, and the snow does not "
          "listen to her either."),
        S("p4s11", "Her Own Ticket", "mireille",
          "Get Mireille to ride one night as a passenger.",
          [{"respect", "direct_request"}], {"cooperation", "precision"}, "gold",
          "She has worked the Owl for seven years and has never once slept on it. On her "
          "night off you buy two tickets, car four, and hold one out on the platform at "
          "twenty to midnight. The relief conductor is waiting to punch it.",
          "She gets on without her cap. She lets another conductor check her ticket, and "
          "watches him like a hawk, and then laughs and lies down in a berth for the first "
          "time in her life.",
          "She takes the ticket, thanks you, and gives it to the relief conductor as a "
          "souvenir.",
          mods={"steal_every": 4}),
        S("p4s12", "BOSS: Last Stop", "mireille",
          "Before the Owl reaches the coast, get Mireille to sign. She punches your best "
          "card every third turn, and she wants both kinds of support.",
          [{"cooperation", "respect"}], {"precision", "empathy"}, "gold",
          "The last stop before dawn. Twenty minutes of track, the green book on the "
          "fold-down table, and Mireille in the doorway of berth two with the punch in her "
          "hand. 'Ask properly,' she says. 'Exactly as you mean it. And if you show me a "
          "card you're proud of, I'm afraid I'll have to punch it.'",
          "She sets the punch down on the table, beside the book, very precisely, and does "
          "not pick it up again. 'Yes,' she says. 'On time, and properly asked.'",
          "The Owl pulls into the coast at dawn to the second. She punches your ticket one "
          "last time: an ordinary hole. It hurts more than it should.",
          mods={"steal_every": 3, "support": 2,
                "boss": "Last Stop: she punches your costliest card every third turn, and she "
                        "wants both kinds of support."}),
    ],
}

# Her lines on every night of the chapter, keyed like replies.py (before, after, kind).
REPLIES = {
    ("open", "open", "open"): ["Good evening. Ticket in hand, voice down, the car is sleeping. Go on."],
    ("guarded", "guarded", "path"): [
        "Noted. Politely. That's all it gets for now.",
        "Correct, as far as it goes. Most passengers get that far.",
        "One point, cleanly made. I'll punch it and keep walking.",
    ],
    ("guarded", "guarded", "case"): [
        "Two things in one sentence. Very efficient. I'm not a timetable, passenger.",
        "That's a lot of ticket for one stop. Slow down and I might read it.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the request at this hour? The dining car closed at one.",
        "You've asked before the train's left the platform. I say no to everyone on the platform.",
    ],
    ("guarded", "guarded", "stale"): [
        "That's not valid on this train.",
        "Wrong ticket, passenger. Nothing on it I can punch.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. You did what I asked, and nicely. People never do both.",
        "Hm. That was graceful. I've stopped walking.",
    ],
    ("guarded", "engaged", "case"): [
        "Well. Two things, both in order. I'll give you a minute of my rounds.",
        "That's neatly done. I notice neat.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked properly. I'm not saying yes. I am taking my glove off.",
        "That was a good request. Wrong hour. Keep it warm.",
    ],
    ("engaged", "engaged", "path"): [
        "Mm. Keep being that easy to deal with. It's very disarming.",
        "Good. I like a passenger who doesn't argue with the rules.",
        "That's twice you've been gracious. I'm keeping count.",
    ],
    ("engaged", "engaged", "case"): [
        "You fit those together like carriages. Very tidy.",
        "That's properly thought through. I could set my watch by it.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like a regular. I haven't decided if you are one.",
        "Not yet. Ask me again after the next halt.",
    ],
    ("engaged", "engaged", "stale"): [
        "You've shown me that one. Already punched.",
        "Same ticket twice. I remember every ticket.",
    ],
    ("engaged", "wavering", "path"): [
        "Careful. Keep doing as you're told and I'll start doing as I'm asked.",
        "I've taken the cap off. I never take the cap off on duty.",
    ],
    ("engaged", "wavering", "case"): [
        "Polite and exact in one breath. That's my whole job, and you just did it to me.",
        "That was gracious and it was precise. I'm running out of regulations.",
    ],
    ("engaged", "wavering", "ask"): [
        "Ask me that again, quieter. The car is sleeping and I want to be sure.",
        "If you ask like that I might answer off the timetable.",
    ],
    ("wavering", "wavering", "path"): [
        "You're very close to the stop I don't print.",
        "Say that again. Nobody's checking tickets now but me.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide behind the rule book, are you.",
        "Two good things. I've run out of reasons to keep walking.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let the train reach the next signal.",
        "I'm deciding. You can hear the punch clicking. Let me.",
    ],
    ("wavering", "wavering", "stale"): [
        "That one's expired. Show me the real ticket.",
        "Not that again. The one you're hiding.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. You did it gracefully and I noticed every step. Yes.",
        "All right. Yes. Don't tell the guard.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. Polite, precise, and exactly on time. Yes.",
        "Yes. Two good things and not a word out of place.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. That's how you ask a conductor. Nobody ever does.",
        "Yes. There. Consider yourself punched.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Not in the regulations, but valid. Go on."],
    ("*", "engaged", "wild"): ["That wasn't off a card. I can tell. It's rather charming."],
    ("*", "wavering", "wild"): ["You made that up between stations, didn't you. Best thing I've heard all night."],
    ("*", "guarded", "*"): ["Mm. Your ticket's still valid. Barely."],
    ("*", "engaged", "*"): ["Better. Mind the gap and keep going."],
    ("*", "wavering", "*"): ["Gently. We're nearly at the signal and I'm enjoying this."],
    ("coercion", "first", "*"): [
        "No. Passengers try that sometimes. I stay polite and they stay on the platform. "
        "We can talk, but you've lost me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. I'm still here because it's my train. You're not persuading anyone.",
        "Again? There's a guard's van for passengers like you. I'm being generous.",
    ],
    ("refusal", "*", "*"): ["That's the last stop, passenger. Please mind the step."],
}

# When the boss's rule bites (her boss has no order rule; this is the generic line).
ORDER_LINES = ["'Wrong way round,' she says, and punches the air where your card was. 'Try again properly.'"]
MUTED_LINES = ["The train goes into a tunnel. Your line vanishes in the roar and she only sees your lips move."]

LAST_CALL = {
    "rule": {"stale_cost": 2}, "extra_help": "empathy",
    "intro": (
        "Mireille keeps a logbook for the Owl, and there is a page for you now. Every week "
        "on the last stretch before dawn she opens it at one of your nights and makes you "
        "tell it back to her, exactly. 'Every stop,' she says. 'If you skip one, I'll know. "
        "I was there.'"),
    "coda": (
        "The last page is Last Stop. She reads it aloud herself, in the voice she uses for "
        "the station calls, and when she gets to the end she closes the logbook and does "
        "not punch it. She puts it under her pillow in berth two and falls asleep before "
        "the coast, for the first time in seven years."),
}

# Her bond ladder: cg1 at the first rung, cg2 at the second, cg4 the placeholder rung.
BOND_SCENES = {
    "cg1": (
        "She stands in the corridor of car four with the ticket punch held up by her cheek, "
        "the city lights of Vell smearing past the window behind her. 'Ticket,' she says, "
        "and clicks the punch twice in the air, and waits, very politely, to see whether "
        "you will hand it over or make her ask."),
    "cg2": (
        "Three in the morning in the guard's van. The heating is on too high, she says, and "
        "the uniform jacket hangs open over her blouse, the brass buttons undone one by "
        "one. The gloves are on the brake wheel. 'Off duty for ten minutes,' she says. "
        "'Precisely ten.'"),
    "cg4": (
        "Snow on the line again, and nobody is going anywhere till morning. She locks the "
        "door of berth two from inside and pulls the blind all the way down."),
}

EVENT = {
    "id": "ev_p4", "title": "The Night Timetable", "who": WHO, "currency": "ticket stubs",
    "blurb": (
        "For two weeks the Owl runs extra night services. Win a stub from Mireille on every "
        "duel of the timetable; stubs buy her cards, tickets and chips on the event track."),
    "rule": "Night Timetable: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p4_1", "Service: The Late Mail", WHO,
          "Get Mireille to let you ride the mail car.",
          [{"cooperation"}], {"respect"}, "silver",
          "The mail runs at one, three cars and no berths. Mireille is signing out sacks on "
          "the platform with a clipboard. 'Passengers don't ride the mail,' she says. 'Unless "
          "they make themselves useful.'",
          "You sort sacks until the coast. She brings you tea at four and calls you 'my "
          "assistant' to the guard.",
          "'Next service is at six,' she says, pleasantly."),
        S("ev_p4_2", "Service: The Quiet Car", WHO,
          "Get Mireille to seat you in the quiet car.",
          [{"respect"}], {"cooperation"}, "silver",
          "The quiet car has a waiting list and a rule of silence, and Mireille enforces it "
          "with one raised glove. You will have to get in without raising your voice.",
          "She seats you by the window and puts a finger to her lips, and then, very softly, "
          "sits down across from you for the whole of the next halt.",
          "She points at the next car with her punch. The next car has a choir."),
        S("ev_p4_3", "Service: The Milk Train", WHO,
          "Get Mireille to stop at the farm halt nobody uses.",
          [{"cooperation"}], {"respect"}, "silver",
          "The milk train stops everywhere except the one halt you want, where the orchard "
          "comes down to the rails. Mireille has the list of stops in her glove. 'It's not "
          "on the list,' she says. 'Lists are lists.'",
          "The milk train stops for ninety seconds by the orchard, and she picks you both an "
          "apple, and the driver pretends not to see.",
          "The orchard goes by in the dark. She waves at it."),
        S("ev_p4_4", "Service: The Missed Connection", WHO,
          "Get Mireille to hold the Owl one minute for a late passenger.",
          [{"respect", "cooperation"}, {"cooperation", "precision"}], {"precision"}, "gold",
          "A woman in her sixties is running down the platform with a hatbox. The Owl leaves "
          "on the second. Mireille has the whistle at her lips and her watch in her other "
          "hand, and she has never held a train in her life.",
          "Mireille lowers the whistle. The woman climbs aboard with the hatbox and fifty "
          "seconds to spare, and Mireille writes 'signal delay' in the log with a straight "
          "face.",
          "She blows the whistle on the second. The woman waves the hatbox at the empty "
          "rails."),
        S("ev_p4_5", "Service: The Last Owl", WHO,
          "Win the last seat on the last Owl of the timetable. Eight turns, and the tunnel "
          "swallows your first card.",
          [{"cooperation", "respect"}, {"respect", "precision"}], {"precision", "cooperation"}, "gold",
          "The last extra service, fully booked, and one berth left. Everyone on the platform "
          "wants it. Mireille is walking the queue with her punch, polite to each of them, "
          "not looking at you at all.",
          "'Last berth on the Owl,' she tells the platform, 'for the passenger who asked "
          "properly.' She punches your ticket with a little owl, and then a second one.",
          "The last berth goes to a retired sea captain. Mireille punches your ticket anyway, twice, for luck.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p4", "title": "All Aboard: Mireille", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Mireille's cards.",
    "featured": ["mireille_11", "mireille_12", "mireille_07", "mireille_08", "mireille_09", "mireille_10"],
}
