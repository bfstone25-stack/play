"""Update pack 1 (week 6): THE SMALL HOURS -- Odile Varga, Radio Vell's night voice.

Path signals: calm_action + empathy (she hears people who slow down and notice how a thing
felt). Help: direct_request. Boss rule: nine turns, and slow down before you ask (an
order rule: a request before any calm ends the duel).

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety; no religion;
second person, present tense, noir. Every reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "odile", "Odile", "radio", 33
PATH_SIGNALS, HELP_SIGNAL = ("calm_action", "empathy"), "direct_request"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("odile_01", "Slowly. There's no rush tonight.", "calm_action"),
    _c("odile_02", "Say it quietly. Nobody else is up.", "calm_action"),
    _c("odile_03", "We can wait for the song to end.", "calm_action"),
    _c("odile_04", "That must feel lonely at this hour.", "empathy"),
    _c("odile_05", "It sounds like that night hurt.", "empathy"),
    _c("odile_06", "Will you play one more for me?", "direct_request"),
    _r("odile_07", "Slowly, then. How did it feel?", "calm_action", "empathy"),
    _r("odile_08", "Can I wait here till you're off air?", "calm_action", "direct_request"),
    _r("odile_09", "Would you tell me how it made you feel?", "direct_request", "empathy"),
    _r("odile_10", "Quietly: I think it hurt you too.", "calm_action", "empathy"),
    _e("odile_11", "Slowly. I feel it too. Will you stay?", "calm_action", "empathy", "direct_request"),
    _e("odile_12", "Take it slowly. I feel it. Can you stay?", "calm_action", "empathy", "direct_request"),
]

CHAPTER = {
    "id": "p1", "title": "The Small Hours", "house": "Radio Vell, Studio B", "who": WHO,
    "intro": (
        "The Night Ledger has a second page. Celeste shows it to you the week after the "
        "Long Night, in the back office of the Aurel, with the green book open between two "
        "coffee cups. 'Houses that were never asked,' she says. 'They can sign now, if the "
        "Silver Tongue can talk them into it. That's you, darling. Off you go.'\n\n"
        "The first name on her list is a voice. Every taxi in Vell has it on after one in "
        "the morning: Odile Varga, thirty-three, host of The Small Hours on Radio Vell, "
        "one till five, requests and the shipping forecast. Half the city falls asleep to "
        "her. Nobody has seen her off air in years."),
    "outro": (
        "She signs in the studio at ten past five, with the ON AIR light still warm and the "
        "morning man knocking on the glass. She uses the pencil she marks the running order "
        "with, and she signs small, as if the page might hear her.\n\n"
        "Then she walks you out through the empty building and stops at the street door. "
        "'Tomorrow,' she says, 'I'm going to say goodnight to the city. And I'm going to "
        "mean one person.' She does not say which. At one the next night, in every taxi in "
        "Vell, she plays the song you asked for on your first night, and does not say who "
        "asked."),
    "stages": [
        S("p1s01", "The Request Line", "odile",
          "Get Odile to put your call through on air.",
          [{"calm_action"}], {"empathy"}, "silver",
          "Twenty to two. You ring the request line from the phone box by the ferry and wait "
          "through three songs. When she picks up, her voice is the one from the taxis, only "
          "closer. 'Small Hours, you're on in thirty seconds. Make it worth the wait.'",
          "She puts you on air and lets you talk, which she never does, and when you finish "
          "she says, 'That one's for the caller by the ferry,' and plays it.",
          "'Thanks for calling.' The line clicks. On the radio in the phone box, she plays "
          "someone else's request."),
        S("p1s02", "Two Sugars", "odile",
          "Get Odile to let you into Studio B with the coffee.",
          [{"calm_action", "direct_request"}], {"empathy"}, "silver",
          "Radio Vell is a grey block behind the fish market. The night doorman sleeps. You "
          "have two coffees from the all-night stand, and Odile is on the other side of the "
          "studio glass, headphones round her neck, reading a card aloud. She sees you. She "
          "holds up one finger: one song.",
          "She opens the door during the long song and takes the cup with both hands. 'Two "
          "sugars. Who told you?' Nobody told you. She lets you sit on the stool by the "
          "record shelf.",
          "She taps the glass, shakes her head, smiles. The coffee goes cold on the ledge "
          "outside."),
        S("p1s03", "The Caller Who Can't Sleep", "odile",
          "Help Odile keep a regular caller talking through a bad night.",
          [{"empathy", "calm_action"}], {"respect"}, "silver",
          "Line three is Bettina, a night nurse in her fifties who rings every Thursday. "
          "Tonight she is not requesting anything. She is just on the line, breathing, and "
          "Odile has put a long song on and pulled the second microphone towards you. 'Help "
          "me,' she mouths. 'She likes new voices.'",
          "Bettina laughs at something you say, and then talks for twenty minutes, and then "
          "says she can sleep now. Odile does not look at you. She squeezes your wrist under "
          "the desk.",
          "Bettina says goodnight politely and hangs up. Odile plays her favourite song "
          "anyway, to nobody, twice."),
        S("p1s04", "The Needle Skips", "odile",
          "Ask Odile to let you choose the next record.",
          [{"direct_request", "empathy"}], {"calm_action"}, "silver",
          "At half past two the turntable skips on the same bar, over and over, and Odile "
          "lifts the needle with a face like a pilot landing in fog. Four seconds of dead "
          "air. On radio, four seconds is a long time. She is scanning the shelf and her "
          "hand is not steady.",
          "You hand her a sleeve. She reads it, looks at you, and drops the needle. It is the "
          "right song for the hour and she knows it. 'Show-off,' she says off mic, pleased.",
          "She finds one herself, fast, and the moment passes. She does not ask for help "
          "again that night."),
        S("p1s05", "The Shipping Forecast", "odile",
          "Get Odile to read one line of the forecast just for you.",
          [{"calm_action", "direct_request"}], {"empathy"}, "silver",
          "At three she reads the shipping forecast: every sea area around Vell, wind and "
          "visibility, in a voice that has put a generation of dockers to sleep. She reads it "
          "the same way every night. It is the one thing on the show she never plays with.",
          "'Harbour approaches,' she reads, 'light airs, visibility good, one ship waiting "
          "outside.' She looks straight at you through the glass as she says it.",
          "She reads it perfectly, exactly as written, and the sea areas go by like "
          "stations you do not stop at."),
        S("p1s06", "Mara Calls In", "mara",
          "Get Mara off the request line before she tells the city about you.",
          [{"warmth", "direct_request"}], {"respect"}, "gold",
          "Line one is flashing. It is the Low Tide: Mara, closing up, who has The Small Hours "
          "on behind the bar every night and has just heard your voice on it. 'Well, well,' "
          "she says, live, to half of Vell. 'Is that my tab talking?'",
          "Mara requests a song 'for the stranger in Studio B, who owes me a stout' and hangs up "
          "laughing. Odile plays it. It is, you have to admit, a very good song.",
          "Mara tells the city about the tab. In detail. Odile laughs so hard she has to "
          "play the station ident.",
          mods={"muted": 1}),
        S("p1s07", "Her Own Voice", "odile",
          "Get Odile to tell you why she never listens to her own show.",
          [{"empathy", "calm_action"}], {"direct_request", "respect"}, "gold",
          "The tapes of every show go into a cupboard and she has never played one. You ask "
          "why during the news, while the newsreader drones in the next booth. She takes her "
          "headphones off, which is a thing you have not seen her do.",
          "'Because on the tape she sounds fine,' she says, 'and I know what the night was "
          "really like.' Then she puts the headphones back on and says, 'You're the first "
          "person who asked.'",
          "'Vanity,' she says, too quickly, and the news ends, and the light goes red."),
        S("p1s08", "Off Air at Five", "odile",
          "Ask Odile to let you walk her home when the show ends.",
          [{"direct_request", "calm_action"}], {"empathy"}, "gold",
          "At five the morning man comes in with a bag of pastries and a voice like a "
          "brass band, and Odile hands over the chair without a word. Outside, the fish "
          "market is waking up. She is standing on the steps with her scarf, deciding which "
          "way to go.",
          "She takes the long way, along the harbour, and talks the whole time in her real "
          "voice, which is lower and quicker and swears more. At her door she says, 'Same "
          "time tomorrow?' as if it has been arranged for years.",
          "'I like to walk alone after,' she says, kindly, and does."),
        S("p1s09", "The Tape Cupboard", "odile",
          "Get Odile to play you the first show she ever did.",
          [{"empathy", "direct_request"}], {"calm_action"}, "gold",
          "There is one tape at the back of the cupboard with no date, only a pencil mark: "
          "1. She was twenty-two, she tells you, and terrified, and the station only kept her "
          "because nobody else would work those hours. She holds the tape like a letter she "
          "has not opened.",
          "She plays it on the studio deck during the news. A younger voice, too fast, "
          "brave. Halfway through she starts to laugh, and then she does not stop the tape.",
          "The tape goes back behind the others. 'Some other night,' she says.",
          mods={"stale_cost": 2}),
        S("p1s10", "Insomnia", "odile",
          "Talk Odile down from a night with no sleep in it.",
          [{"calm_action"}, {"empathy", "respect"}], {"direct_request"}, "gold",
          "Saturday, no show, and she rings you at two anyway, from her kitchen, where she "
          "has been sitting since midnight with the radio on and another host's voice in it. "
          "'I don't know how to be up at this hour without a microphone,' she says. 'Talk.'",
          "You talk until the other host signs off. She is quiet for a long time and then "
          "says, very sleepily, 'Keep going. You've got a good voice for this.' She is asleep "
          "before you finish the sentence.",
          "She says thank you and hangs up and, you suspect, sits there until dawn.",
          mods={"hand": 2}),
        S("p1s11", "Her Own Request", "odile",
          "Get Odile to name the one song she would request.",
          [{"empathy", "direct_request"}], {"calm_action"}, "gold",
          "Eleven years of other people's requests. You have noticed she hums one song under "
          "the ads that she has never played on air. When you ask her what she would request, "
          "if she could ring in, she laughs as if it is a trick question.",
          "She names it. Then she plays it, on air, and says only, 'Requested by the host.' "
          "Every taxi in Vell hears her singing along under it, very quietly.",
          "'I'd request a good night's sleep,' she says, which is a clever answer and not an "
          "answer.",
          mods={"steal_every": 4}),
        S("p1s12", "BOSS: Dead Air", "odile",
          "During the longest song of the night, get Odile to switch the microphone off and "
          "sign. Nine turns. Slow down before you ask.",
          [{"calm_action", "empathy"}], {"direct_request"}, "gold",
          "Four in the morning, the Long Song: nine minutes, the one she saves for the "
          "hardest hour. The green book is on the desk. You have until the song ends. She has "
          "never said yes to anything off air, because off air is where things are real. "
          "Hurry her and she will hear it.",
          "She reaches past you and flicks the switch, and the ON AIR light goes out, and for "
          "the first time in eleven years there is nobody listening but you. 'Yes,' she "
          "says. Just to you.",
          "The song ends. She leans into the microphone: 'That was the Long Song, Vell. "
          "Sleep well.' She means everyone. That is the trouble.",
          mods={"turns": 9, "order": [["calm_action", "direct_request"]],
                "boss": "Dead Air: nine turns, and slow down before you ask: a request before "
                        "any calm ends it."}),
    ],
}

# Her lines on every night of the chapter, keyed like replies.py (before, after, kind).
# path = one clear point (a common), case = two things at once (a rare), ask = a request
# with everything behind it (an epic), stale = a card that carries nothing she wants.
REPLIES = {
    ("open", "open", "open"): ["You again. Keep your voice down, the mic's live. Go on."],
    ("guarded", "guarded", "path"): [
        "Mm. That's a nice line. I get a lot of nice lines on the request card.",
        "Heard. Not moved. Most callers start there.",
        "That's one thing, said once. I'm still waiting for the caller behind it.",
    ],
    ("guarded", "guarded", "case"): [
        "Two points in one breath. You'd be good on air. That's not a compliment yet.",
        "That's a whole request card. Slow it down and I might actually hear it.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the ask. Callers who do that get the next song and a click.",
        "You asked before I knew you. Everyone does. I say no to everyone.",
    ],
    ("guarded", "guarded", "stale"): [
        "That one isn't for me. Wrong station, caller.",
        "Nothing in that for the small hours. Try again.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. You slowed down. Nobody slows down at this hour.",
        "Huh. That one landed. I've stopped reading the next card.",
    ],
    ("guarded", "engaged", "case"): [
        "All right. Two things, and both of them were true. Keep talking.",
        "That's more than a caller usually gives me. I'm listening properly now.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked nicely and you meant it. That's rarer than it should be.",
        "I didn't say yes. I did turn the fader down. That's something.",
    ],
    ("engaged", "engaged", "path"): [
        "Mm. Keep that pace. I like it.",
        "That's good. Say the next thing just as slowly.",
        "You noticed that. I'll remember you noticed that.",
    ],
    ("engaged", "engaged", "case"): [
        "You put those two together like a good running order.",
        "That's a proper thought, not a line. I can tell the difference on air.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like someone who'll take no for an answer. It makes me want to say yes.",
        "Not yet. Ask me again when the song's halfway.",
    ],
    ("engaged", "engaged", "stale"): [
        "You've said that. I liked it once. Give me something new.",
        "Repeat caller. I know that line already.",
    ],
    ("engaged", "wavering", "path"): [
        "…That's the thing I never say out loud. How did you hear it?",
        "I've taken the headphones off. I don't do that. Keep going.",
    ],
    ("engaged", "wavering", "case"): [
        "Slow and kind in one breath. That's my whole show, and you just did it to me.",
        "That was careful and it was true. I don't know what to do with both.",
    ],
    ("engaged", "wavering", "ask"): [
        "Ask me that again. Quieter. I want to be sure I heard it.",
        "Careful. If you ask like that I might answer like a person.",
    ],
    ("wavering", "wavering", "path"): [
        "You're very close to the part I keep off air.",
        "Say that one again. I'm not recording. I just want to hear it.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide in the running order, are you.",
        "That's two true things. I'm running out of songs to put on.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let the song get to the quiet bit.",
        "I'm deciding. You can hear me deciding. Let me.",
    ],
    ("wavering", "wavering", "stale"): [
        "I've heard that. I'm past it. Ask me the real thing.",
        "Not that again. The real one.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. You slowed down and I heard all of it. Yes.",
        "All right. Yes. Don't tell the taxis.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. You said it the way I'd say it on air, only to me.",
        "Yes. Two true things and a quiet voice. That's all it ever takes.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. Ask me like that every night and I'll never get any sleep.",
        "Yes. There. The fader's down. That was just for you.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Rough, but nobody wrote them for you. Go on."],
    ("*", "engaged", "wild"): ["That wasn't off a card. It had a pulse. I'm listening."],
    ("*", "wavering", "wild"): ["You made that up just now, didn't you. It's the best thing I've heard all night."],
    ("*", "guarded", "*"): ["Mm. The line's still open. Barely."],
    ("*", "engaged", "*"): ["Better. Keep your voice down and keep going."],
    ("*", "wavering", "*"): ["Slow down. I'm enjoying this and the song's nearly over."],
    ("coercion", "first", "*"): [
        "No. People ring in and try that. I cut them off. We can keep talking, but you've "
        "lost me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. I'm still here because it's my show. You're not persuading anyone.",
        "Again? I've got a button for callers like that. I'm not pressing it. Yet.",
    ],
    ("refusal", "*", "*"): ["That's the end of the song, caller. Goodnight from the Small Hours."],
}

# When the boss's order rule bites.
ORDER_LINES = ["'You asked before you slowed down.' She pushes the fader up. 'Back on air. We're done.'"]
MUTED_LINES = ["She holds up a finger: on air. Your line goes out under the song and nobody hears it."]

LAST_CALL = {
    "rule": {"steal_every": 4}, "extra_help": "respect",
    "intro": (
        "Odile has started a new segment on Thursdays: The Caller Who Came Back. It is you. "
        "Every week she plays a tape of one of your nights and makes you talk over it, "
        "live. 'Tell them how it really went,' she says. 'They'll know if you're lying. So "
        "will I.'"),
    "coda": (
        "The last Thursday she plays the tape of Dead Air, all nine minutes, with the "
        "microphone off for the last four. On the radio it is just a song. In Studio B she "
        "turns the volume up, and takes your hand, and neither of you says anything for "
        "the whole of it."),
}

# Her bond ladder: cg1 at the first rung, cg2 at the second, cg4 the placeholder rung
# (Blaze's own scene, text only until then).
BOND_SCENES = {
    "cg1": (
        "Between shows she sits on the mixing desk with a coffee in both hands and her feet "
        "on the chair, which she tells the morning man never to do. 'Ten minutes,' she "
        "says. 'Then it's the news. Tell me something that isn't a request.'"),
    "cg2": (
        "The headphones are off and so is the scarf, and the studio is hot from the valves, "
        "she says. The ON AIR light is out. She has put on a record neither of you picked "
        "and is not going to get up to change it."),
    "cg4": (
        "Five in the morning and the morning man has rung in sick. Nobody is coming. She "
        "leaves the transmitter playing the long tape and locks the studio door from inside."),
}

EVENT = {
    "id": "ev_p1", "title": "The Request Hour", "who": WHO, "currency": "request slips",
    "blurb": (
        "For two weeks The Small Hours takes requests in person. Win a slip from Odile on "
        "every duel of the hour; slips buy her cards, tickets and chips on the event track."),
    "rule": "Request Hour: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p1_1", "Request: Something Slow", WHO,
          "Get Odile to play a slow one for the late shift.",
          [{"empathy"}], {"calm_action"}, "silver",
          "The studio door is propped open for the Request Hour and there is a queue of "
          "taxi drivers on the stairs. You are fourth. 'Name it,' says Odile, 'and tell me "
          "who it's for.'",
          "She plays it for the bakers on Ropewalk, who have been up since two. A driver on "
          "the stairs applauds.",
          "'Next,' she says, not unkindly."),
        S("ev_p1_2", "Request: For the Harbour", WHO,
          "Ask Odile to dedicate the next song to the harbour pilots.",
          [{"direct_request", "empathy"}], {"calm_action"}, "silver",
          "The pilots bring the ships in at night and nobody thanks them. Odile has the "
          "pilot boat's radio on a second speaker, crackling. 'They listen,' she says. "
          "'Make it good.'",
          "She reads the dedication with her eyes on the harbour speaker, and a voice on it "
          "says, very faintly, 'Received.'",
          "She plays a good song for them. The dedication is somebody else's."),
        S("ev_p1_3", "Request: No Words", WHO,
          "Get Odile to play an instrumental and stop talking for four minutes.",
          [{"calm_action", "empathy"}], {"direct_request"}, "silver",
          "It is a talk show. She talks. Tonight you want four minutes where she does not "
          "have to, and you are going to have to talk her into silence.",
          "Four minutes of piano and no Odile. She leans back and closes her eyes, and you "
          "watch her breathe, and the city gets the best four minutes of the week.",
          "She talks over the piano, lightly, the way she always does."),
        S("ev_p1_4", "Request: The Wrong Song", WHO,
          "Get Odile to admit she played your request wrong on purpose.",
          [{"empathy", "direct_request"}, {"calm_action", "respect"}], {"calm_action"}, "gold",
          "Last week you asked for the slow version. She played the fast one. The phones "
          "lit up. She has been pretending ever since it was the only version in the building.",
          "'It was on the shelf,' she admits, 'next to the other one. I wanted you to ring "
          "and complain.' She plays the slow one. You do not complain.",
          "'Only version in the building,' she says, and it is a very straight face."),
        S("ev_p1_5", "Request: Last Song of the Hour", WHO,
          "Win the last request of the Request Hour. Eight turns, and she talks over your "
          "first card.",
          [{"calm_action", "empathy"}, {"empathy", "direct_request"}], {"calm_action", "respect"}, "gold",
          "Five to five. One request left and the whole queue wants it. Odile is doing the "
          "sign-off in her head already and not listening to anyone, including you.",
          "'Last song of the Request Hour,' she tells the city, 'for somebody who knows how "
          "to wait.' She does not look at you. She does not have to.",
          "The last song goes to the bakers. They deserve it. You still mind.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p1", "title": "On Air: Odile", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Odile's cards.",
    "featured": ["odile_11", "odile_12", "odile_07", "odile_08", "odile_09", "odile_10"],
}
