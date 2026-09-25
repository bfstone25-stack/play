"""Update pack 6 (week 16): LAST CROSSING -- Vesna Kaur, captain of the last ferry.

Path signals: authority + warmth (she likes being asked permission, and being noticed at
the end of a long shift). Help: calm_action. Boss rule: eleven turns, she talks over your
first card, and notice the long night before you ask her permission (an order rule:
authority before any warmth ends the duel).

The last pack of the three-month plan: the outro closes the Second Page arc with Celeste
on the pier, and leaves the city running.

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety; no religion;
second person, present tense, noir. Every reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "vesna", "Vesna", "ferry", 37
PATH_SIGNALS, HELP_SIGNAL = ("authority", "warmth"), "calm_action"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("vesna_01", "Permission to come aboard, Captain?", "authority"),
    _c("vesna_02", "Your ship. Your orders.", "authority"),
    _c("vesna_03", "That was a long day on the water.", "warmth"),
    _c("vesna_04", "You look tired. Sit a minute.", "warmth"),
    _c("vesna_05", "Slowly. The bay isn't going anywhere.", "calm_action"),
    _c("vesna_06", "I brought food for the crossing.", "calm_action"),
    _r("vesna_07", "Long day, Captain. Permission to sit?", "authority", "warmth"),
    _r("vesna_08", "Quietly, Captain. Where do I stand?", "authority", "calm_action"),
    _r("vesna_09", "You're tired. Eat. The food's still hot.", "warmth", "calm_action"),
    _r("vesna_10", "Your orders. I'll stand here and wait.", "authority", "calm_action"),
    _e("vesna_11", "Long day, Captain. Slowly. Permission?", "authority", "warmth", "calm_action"),
    _e("vesna_12", "Tired, Captain? Food first, then orders.", "authority", "warmth", "calm_action"),
]

CHAPTER = {
    "id": "p6", "title": "Last Crossing", "house": "The Last Ferry, Bay Pier", "who": WHO,
    "intro": (
        "The last name on Celeste's list has no address, only a timetable. 'Bay Pier, half "
        "past two,' she says, and taps the Second Page with one silver nail. 'She has "
        "never signed anything that wasn't a manifest. Mind the gangway, darling. She "
        "won't wait.'\n\n"
        "The Last Crossing leaves Vell at half past two and comes back at five, whatever the "
        "weather, whoever is on it: night cooks, dockers, a band with its drums, people "
        "who missed everything else. Its captain is Vesna Kaur, thirty-seven, in a navy "
        "peacoat with gold buttons and a white cap she wears like she was born in it. Long "
        "black hair, a small ring in her nose, an easy grin. She runs a tight ship and "
        "knows every passenger by the way they climb aboard. Most climb aboard as if the "
        "boat owes them."),
    "outro": (
        "She signs on the chart table at ten to five, with the engine idling and the pier "
        "lights coming up out of the dark. She signs the way she signs the log: fast, "
        "firm, a little flourish at the end that nobody is supposed to notice.\n\n"
        "Then she takes you out on deck, and the wind is cold, and she opens the peacoat "
        "and wraps it round you both. There is nothing under it but her. She looks back at "
        "the city, not at you. 'Every night I bring them home,' she says. 'Nobody ever "
        "asked who brings me.'\n\n"
        "On the pier, under the lamp, Celeste is waiting with two coffees. She reads the "
        "last signature, closes the book, and smiles. 'That's the page, darling,' she says. "
        "Behind her the first bus of the morning starts, and Vell goes on."),
    "stages": [
        S("p6s01", "The Gangway", "vesna",
          "Get Vesna to let you aboard the Last Crossing.",
          [{"authority"}], {"warmth"}, "silver",
          "Twenty-five past two. The gangway is already rattling. A man in a good suit shoves "
          "past you, waving a ticket, and Vesna lets him on without a word and without a "
          "look. Then she turns her grin on you, and waits, one boot on the rail, to see "
          "which kind of passenger you are.",
          "'Now that,' she says, 'is how you board a ship.' She takes your hand on the last "
          "step, which she does not do for the man in the suit.",
          "She waves you on with the others. You are cargo tonight, and she does not look "
          "back."),
        S("p6s02", "The Wheelhouse Door", "vesna",
          "Get Vesna to let you stand in the wheelhouse for the crossing.",
          [{"warmth"}], {"authority"}, "silver",
          "The wheelhouse is warm and smells of diesel and oranges. A sign on the door says "
          "CREW ONLY in letters older than you. Vesna is inside with the wheel under one hand "
          "and a mug in the other, and the whole bay black in front of her.",
          "She kicks the door open with one heel. 'Stand by the chart table. Touch nothing. "
          "Talk to me.' It is the best offer you have had all week.",
          "She taps the sign with her mug and smiles. The door stays shut all the way over."),
        S("p6s03", "The Hat Overboard", "vesna",
          "Help Vesna calm a passenger who has lost his hat to the bay.",
          [{"warmth"}], {"calm_action"}, "silver",
          "Halfway across, a drummer in his forties loses his hat to the wind and wants the "
          "boat turned round. He is loud. The band is louder. Vesna comes down the ladder "
          "with her jaw set and her grin gone. 'Help me,' she says, low. 'Before I throw "
          "him in after it.'",
          "The drummer ends up laughing, and buys the band tea from the hatch, and forgets "
          "the hat. Vesna leans on the rail beside you. 'Crew,' she says, like a medal.",
          "The drummer sulks to the far shore. Vesna handles it herself, and does not "
          "thank you."),
        S("p6s04", "The Log", "vesna",
          "Ask Vesna to let you write tonight's entry in the ship's log.",
          [{"authority", "calm_action"}], {"warmth"}, "silver",
          "The log is a green book with a cracked spine and forty years of weather in it. "
          "Every entry is in capitals: WIND, SEA, PASSENGERS, NOTES. Vesna writes hers with "
          "a pencil stub she keeps behind her ear. NOTES is always empty.",
          "She hands you the pencil. You write the wind and the sea, and under NOTES, "
          "something small. She reads it upside down and does not rub it out.",
          "'Captain's hand only,' she says, and writes NOTES: NONE."),
        S("p6s05", "The Turning Buoy", "vesna",
          "Get Vesna to let you take the wheel past the turning buoy.",
          [{"authority", "warmth"}], {"calm_action"}, "silver",
          "The turning buoy is a red light that blinks every four seconds, and every night "
          "at three Vesna brings the ferry round it without looking. Tonight she is looking "
          "at you instead. 'Nobody touches her wheel,' she says. 'Nobody's ever asked.'",
          "She stands behind you with her hands over yours, and the ferry comes round the "
          "buoy wide and a little clumsy. 'Terrible,' she says in your ear. 'Again tomorrow.'",
          "She keeps the wheel. The buoy blinks past on the right side of the boat, exactly "
          "where it always is."),
        S("p6s06", "Odile Rides Home", "odile",
          "Get Odile to stop narrating the crossing before Vesna hears it.",
          [{"calm_action", "empathy"}], {"respect"}, "gold",
          "Friday, after her show, Odile takes the Last Crossing home to the far shore, and "
          "tonight she has spotted you in the wheelhouse. She is on the bench below the "
          "window with a paper cup, reading the ferry to the passengers in her radio voice. "
          "'And there, Vell, at the chart table...'",
          "Odile lowers the cup, and her voice, and says only, 'Good crossing, captain,' "
          "on her way off. Vesna watches her go. 'I like her,' she says. 'She talks less "
          "than the radio.'",
          "Odile finishes the report for the whole deck. The band applauds. Vesna turns "
          "the wheel very slightly, so the spray reaches the bench.",
          mods={"muted": 1}),
        S("p6s07", "The Crew", "vesna",
          "Get Vesna to introduce you to her crew as one of them.",
          [{"warmth", "authority"}], {"calm_action"}, "gold",
          "Her crew is two people: Marek, the engineer, in his sixties, who has not come up "
          "from the engine room in daylight since anyone can remember, and Pia, the deckhand, "
          "twenty-four, who coils rope like it owes her money. Vesna would die for both of "
          "them. She tells them nothing.",
          "At the hatch, over tea, she says, 'This one's crew,' and Marek grunts, which Pia "
          "says is a speech. Vesna does not look at you. Her grin says the rest.",
          "'A passenger,' she tells them. Pia shrugs. Marek goes back down to his engine."),
        S("p6s08", "Fog on the Bay", "vesna",
          "Keep Vesna company through a crossing in thick fog.",
          [{"warmth", "calm_action"}, {"authority"}], {"calm_action"}, "gold",
          "The fog comes in off the sea at two and swallows the bay whole. Vesna takes the "
          "ferry out anyway, on the horn and the compass and her own ears. The passengers "
          "have gone quiet. So has she. Her knuckles on the wheel are pale.",
          "Two hours of horn and fog and your voice. When the far lights come through, she "
          "breathes out for what feels like the first time. 'Stay next to me,' she says. "
          "'Every foggy night.'",
          "You talk and she stops listening, because she has to. The pier comes up out of "
          "the fog anyway, and she says nothing on it.",
          mods={"stale_cost": 2}),
        S("p6s09", "The Coat", "vesna",
          "Ask Vesna where the peacoat came from.",
          [{"authority", "warmth"}], {"calm_action"}, "gold",
          "The peacoat is older than the ferry. The gold buttons do not match: one is new. "
          "She wears it in summer. She has never taken it off on the boat, not in the "
          "hottest August, and every regular has a theory, and every theory is wrong.",
          "It was her mother's, who ran this crossing for thirty years and taught her the "
          "wheel at nine. The new button is the one Vesna lost the night she took over. She "
          "lets you touch it.",
          "'Second-hand shop,' she says, and buttons it to the collar.",
          mods={"hand": 2}),
        S("p6s10", "Night Off", "vesna",
          "Get Vesna to take a night off the wheel and be a passenger.",
          [{"warmth"}, {"authority", "calm_action"}], {"calm_action"}, "gold",
          "Once a month the relief captain takes the Last Crossing: a solid man in his "
          "fifties who never lets anyone board early. Vesna is supposed to be asleep. "
          "Instead she is on the pier at two, in the peacoat, watching her boat go without "
          "her. 'He's too gentle with the throttle,' she says.",
          "She buys a ticket. She sits on the passenger bench beside you with her boots up "
          "and does not criticise the relief captain once, out loud. Halfway over she falls "
          "asleep on your shoulder.",
          "She walks home along the harbour to not watch it. You watch the ferry go alone."),
        S("p6s11", "The Five o'Clock Pier", "vesna",
          "Get Vesna to stay on deck after the last passenger is off.",
          [{"warmth", "authority"}], {"calm_action"}, "gold",
          "Five in the morning, back at Bay Pier. The band has gone, the cooks have gone, "
          "Marek has gone up the ladder into daylight blinking like an owl. Vesna has the "
          "log under her arm and the keys in her hand, and usually she is the first one "
          "home.",
          "She sits on the bollard at the end of the pier and pats the cold iron beside "
          "her, and you watch the sun hit the city from the water side, which is the side "
          "that nobody sees.",
          "She locks the wheelhouse and salutes you with the keys and goes.",
          mods={"steal_every": 4}),
        S("p6s12", "BOSS: Rough Water", "vesna",
          "Across the roughest crossing of the year, get Vesna to sign the Second Page. "
          "Eleven turns. Notice the long night before you ask her permission.",
          [{"authority", "warmth"}], {"calm_action"}, "gold",
          "The first gale of autumn, and she takes the Last Crossing out because the night "
          "cooks need to get home. Spray over the wheelhouse, the ferry climbing every "
          "wave. The green book is in your coat. She is not listening to anyone, and she "
          "has been on her feet for nineteen hours. Ask her for anything before you see "
          "that, and she will hear a passenger.",
          "In the lee of the far pier the boat goes quiet. She takes her cap off, for the "
          "first time you have ever seen, and shakes her hair loose. 'You saw the night "
          "first,' she says. 'Permission granted. Give me the pen.'",
          "She brings them all home, soaked and safe. At the pier she touches her cap to "
          "you, the way she does to every passenger. That is the trouble.",
          mods={"turns": 11, "muted": 1, "order": [["warmth", "authority"]],
                "boss": "Rough Water: eleven turns, she talks over your first card, and notice "
                        "the long night before you ask her permission: authority before any "
                        "warmth ends it."}),
    ],
}

REPLIES = {
    ("open", "open", "open"): ["Boarding closes in two minutes. Talk while you climb."],
    ("guarded", "guarded", "path"): [
        "Mm. Nice line. The bay hears a lot of nice lines.",
        "One point, said once. Everybody on this pier has one.",
        "Noted. Logged. Not moved.",
    ],
    ("guarded", "guarded", "case"): [
        "Two things in one go. Somebody's been practising on the gangway.",
        "That's a lot of cargo for a first trip. Stow some of it.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the big ask. Passengers do that. Crew wait.",
        "You haven't even found your sea legs and you're asking for the wheel.",
    ],
    ("guarded", "guarded", "stale"): [
        "That's not for me. Wrong boat.",
        "Nothing in that for a ferry at three in the morning. Try again.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. You asked. Nobody asks. Keep going.",
        "Huh. That one came aboard properly.",
    ],
    ("guarded", "engaged", "case"): [
        "All right. Two true things. I'm listening now, not steering.",
        "That's more than a passenger gives me. Stand closer, it's windy.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked like you'd take no for an answer. That's why I'm thinking about yes.",
        "Not yet. But I heard it over the engine, which is saying something.",
    ],
    ("engaged", "engaged", "path"): [
        "Good. Hold that course.",
        "That's it. Steady. I like steady.",
        "You noticed that. Most people only notice the fare.",
    ],
    ("engaged", "engaged", "case"): [
        "You put those two together like a proper knot. Pia would approve.",
        "That's crew talk, not passenger talk. Careful, I might keep you.",
    ],
    ("engaged", "engaged", "ask"): [
        "Ask me again at the buoy. I want to see if you still mean it.",
        "Close. Not yet. The far lights aren't up.",
    ],
    ("engaged", "engaged", "stale"): [
        "You said that one on the way out. Give me something for the way back.",
        "Repeat passenger. I know that line.",
    ],
    ("engaged", "wavering", "path"): [
        "...Nobody says that to the captain. How did you know to?",
        "I've let go of the wheel with one hand. I never do that.",
    ],
    ("engaged", "wavering", "case"): [
        "You saw the night and you asked nicely. In one breath. That's not fair.",
        "That was careful and it was kind. I don't have a drill for both.",
    ],
    ("engaged", "wavering", "ask"): [
        "Say that again when the wind drops. I want to hear all of it.",
        "Careful. Ask like that and I'll answer like a woman, not a captain.",
    ],
    ("wavering", "wavering", "path"): [
        "You're very close to the part I keep below deck.",
        "Say it again. Nobody's logging this.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide behind the wheel, are you.",
        "Two true things. I'm running out of weather to look at.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let me get us past the buoy.",
        "I'm deciding. You can see me deciding. Let me.",
    ],
    ("wavering", "wavering", "stale"): [
        "Heard that. I'm past it. Ask me the real thing.",
        "Not that again. The real one.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. You asked, and you saw me. Yes.",
        "All right. Yes. Don't tell the crew.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. You noticed the night and you asked the captain. That's the whole trick.",
        "Yes. Permission granted, and more besides.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. Ask me like that every crossing and I'll never get this boat home.",
        "Yes. There. Cap off. That was for you.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Rough as the bay, but nobody wrote them for you."],
    ("*", "engaged", "wild"): ["That wasn't off a card. It had salt in it. Go on."],
    ("*", "wavering", "wild"): ["You made that up just now. It's the best thing I've heard on this boat."],
    ("*", "guarded", "*"): ["Mm. You're still aboard. Barely."],
    ("*", "engaged", "*"): ["Better. Hold on to the rail and keep going."],
    ("*", "wavering", "*"): ["Steady. I'm enjoying this and the far pier's close."],
    ("coercion", "first", "*"): [
        "No. People try that on my gangway. I put them ashore. You can ride, but you've lost "
        "me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. You're still aboard because it's a long swim. That's all.",
        "Again? I have a pier for people like that. We're nearly at it.",
    ],
    ("refusal", "*", "*"): ["That's the far pier. All ashore that's going ashore. Goodnight."],
}

ORDER_LINES = ["'You asked for the captain before you saw the woman.' She turns to the wheel. 'Passenger. Sit down.'"]
MUTED_LINES = ["She is shouting orders down the hatch. Your line goes out into the wind."]

LAST_CALL = {
    "rule": {"steal_every": 3}, "extra_help": "respect",
    "intro": (
        "Vesna has a new rule on the Last Crossing. The passenger in the wheelhouse pays "
        "the fare in stories: one of your nights, told again from the chart table, while "
        "Pia and Marek listen from the hatch. 'Tell it straight,' Vesna says. 'The crew "
        "will know if you're lying. So will I.'"),
    "coda": (
        "The last story is Rough Water. Pia has heard it twice and still gasps at the gale. "
        "Marek comes up from the engine room to hear the end. When you finish, Vesna logs "
        "it under NOTES, the first entry there in forty years, and does not show you what "
        "she wrote."),
}

BOND_SCENES = {
    "cg1": (
        "Three in the morning, on the open deck. She has one hand on the railing and the "
        "other round a mug, and behind her the harbour and all the lights of Vell are "
        "sliding past. 'Ten minutes,' she says. 'Pia has the wheel. Tell me something that "
        "isn't about the weather.'"),
    "cg2": (
        "The wheelhouse heater is stuck on full and she has finally unbuttoned the peacoat, "
        "all the way, gold buttons catching the compass light. Underneath is less than you "
        "expected. The ferry is on its buoy. She is not in a hurry to do the buttons up."),
    "cg4": (
        "Five in the morning, the pier empty, the crew gone home. She locks the wheelhouse "
        "from the inside and hangs her cap on the wheel."),
}

EVENT = {
    "id": "ev_p6", "title": "The Lantern Crossing", "who": WHO, "currency": "boarding passes",
    "blurb": (
        "For two weeks the Last Crossing carries paper lanterns out for the bay's autumn "
        "night. Win a boarding pass from Vesna on every duel; passes buy her cards, tickets "
        "and chips on the event track."),
    "rule": "Lantern Crossing: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p6_1", "Lanterns: The Queue", WHO,
          "Get Vesna to let you aboard with a box of lanterns.",
          [{"authority"}], {"warmth"}, "silver",
          "Half of Vell is on Bay Pier with a paper lantern, and the Last Crossing can take "
          "two hundred. You are two hundred and one, with a box of forty. Vesna is counting "
          "heads at the gangway with a clicker.",
          "She clicks you in as crew. 'Carry those to the stern,' she says, 'and don't set "
          "fire to my boat.'",
          "'Next crossing,' she says, and means it kindly."),
        S("ev_p6_2", "Lanterns: The Stern", WHO,
          "Get Vesna to let the passengers light the lanterns early.",
          [{"warmth"}], {"calm_action"}, "silver",
          "The lanterns go out at the turning buoy. The passengers want to light them now, "
          "in the harbour, and Vesna has already said no twice, from the ladder, with the "
          "grin that means the third no is coming.",
          "She sighs, laughs, and hands you her lighter. The stern goes gold, and the "
          "passengers cheer her, and she pretends not to hear.",
          "Rules are rules. The lanterns wait for the buoy, and so do you."),
        S("ev_p6_3", "Lanterns: The Wind", WHO,
          "Keep Vesna company while she holds the boat steady for the launch.",
          [{"calm_action"}], {"authority"}, "silver",
          "The wind has come round, and a lantern in the wrong wind goes straight into the "
          "sea. Vesna holds the ferry across it, engine low, and does not want talk. She "
          "wants quiet, and the right hand on the rail.",
          "Two hundred lanterns go up in one breath and drift over the bay towards the city. "
          "Vesna watches them from the wheel, and then she watches you.",
          "Half the lanterns go up. Half go in the water. The passengers cheer anyway."),
        S("ev_p6_4", "Lanterns: Her Own", WHO,
          "Get Vesna to light a lantern of her own.",
          [{"warmth", "authority"}, {"calm_action", "respect"}], {"calm_action"}, "gold",
          "Fifteen years of lantern nights and she has never sent one up. There is one left "
          "in the box, a little crushed. She holds it like a manifest she has not checked.",
          "She writes something on it with the pencil from behind her ear, and lights it, "
          "and lets it go. She does not tell you what she wrote. She does hold your hand.",
          "'Captains steer,' she says, and gives it to Pia."),
        S("ev_p6_5", "Lanterns: The Last One Up", WHO,
          "Win the last lantern of the night. Eight turns, and she talks over your first "
          "card.",
          [{"authority", "warmth"}, {"warmth", "calm_action"}], {"calm_action", "respect"}, "gold",
          "Five to five, on the way home. One lantern left and every passenger wants it. "
          "Vesna is bringing the ferry in to the pier in her head already and not listening "
          "to anyone, including you.",
          "'Last lantern of the crossing,' she calls down, 'for the one who asked properly.' "
          "She does not look at you. She does not have to.",
          "The last lantern goes to the night cooks. Vesna tips her hat to you from the bridge, which is almost as good.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p6", "title": "Last Crossing", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Vesna's cards.",
    "featured": ["vesna_11", "vesna_12", "vesna_07", "vesna_08", "vesna_09", "vesna_10"],
}
