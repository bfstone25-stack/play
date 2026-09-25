"""Update pack 2 (week 8): BREAKWATER -- Hedda Lund, harbour pilot at Breakwater Light.

Path signals: safety + precision (she trusts people who are careful and exact). Help:
respect. Boss rule: ten turns, no wild card, and a card with nothing new costs two turns.

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety; no religion;
second person, present tense, noir. Every reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "hedda", "Hedda", "pilot", 39
PATH_SIGNALS, HELP_SIGNAL = ("safety", "precision"), "respect"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("hedda_01", "Let's get her in safe tonight.", "safety"),
    _c("hedda_02", "Hold the rail. It will protect you.", "safety"),
    _c("hedda_03", "Tell me exactly where the rocks lie.", "precision"),
    _c("hedda_04", "Only if the tide is with us.", "precision"),
    _c("hedda_05", "I respect how you bring them in.", "respect"),
    _c("hedda_06", "Thank you for letting me aboard.", "respect"),
    _r("hedda_07", "Exactly on the mark, and safe with it.", "safety", "precision"),
    _r("hedda_08", "Thank you for keeping us all safe.", "safety", "respect"),
    _r("hedda_09", "I respect a pilot who says exactly that.", "precision", "respect"),
    _r("hedda_10", "Safe, provided that the fog holds off.", "safety", "precision"),
    _e("hedda_11", "Thank you. Exactly right, and safe too.", "safety", "precision", "respect"),
    _e("hedda_12", "I respect it: exactly steady, and safe.", "safety", "precision", "respect"),
]

CHAPTER = {
    "id": "p2", "title": "Breakwater", "house": "The Pilot Station, Breakwater Light",
    "who": WHO,
    "intro": (
        "The second name on Celeste's list is not in the city at all. It is at the end of "
        "the breakwater, a mile of wet stone with a light on the end of it. 'The Pilot "
        "Station,' Celeste says, tapping the page. 'They bring every ship into Vell and "
        "nobody in Vell has ever thanked them. Wear a coat, darling.'\n\n"
        "Hedda Lund is thirty-nine, a harbour pilot, nine years on the night roster. She "
        "climbs a rope ladder up the side of a ship in the dark, walks onto a stranger's "
        "bridge and tells the captain where to steer. Yellow raincoat, navy sweater, a "
        "silver whistle on a chain. Her face is always red from the wind. She has no time "
        "for anyone who shows off, and she can hear it from the far end of the pier."),
    "outro": (
        "She signs at dawn in the wheelhouse of the pilot boat, on the chart table, with "
        "the pencil she uses for courses. Her signature is small and square and dead on "
        "the line, like everything she draws.\n\n"
        "Then she puts the pencil down and does not pick up the chart. The raincoat is on "
        "the hook. The sweater is on the floor. She sits on the edge of the table with the "
        "harbour going pink behind her and her arms folded over herself, and looks back at "
        "you over her shoulder, steady, the way she looks at a channel she has decided to "
        "take. 'Door's latched,' she says. 'Tide's slack for an hour. Nobody needs a pilot.' "
        "The whistle hangs between her shoulder blades, off duty for the first time in nine years."),
    "stages": [
        S("p2s01", "The Long Walk", "hedda",
          "Get Hedda to let you walk the breakwater with her.",
          [{"safety"}], {"precision"}, "silver",
          "Midnight. The breakwater is a mile of stone with the sea slopping over it at the "
          "low places. At the landward end a woman in a yellow raincoat is checking a hand "
          "lamp. She looks at your shoes and then at you. 'That's a long walk in those. "
          "What do you want?'",
          "She hands you the spare lamp. 'Walk on the inside. Step where I step.' You do, the "
          "whole mile, and at the end she says, 'Good,' as if you passed something.",
          "'Station's closed to visitors,' she says, and walks off into the spray alone."),
        S("p2s02", "The Kettle", "hedda",
          "Get Hedda to make you tea in the station.",
          [{"precision", "respect"}], {"safety"}, "silver",
          "The Pilot Station is one room under the light: a stove, a radio, a board with the "
          "night's ships chalked on it, and a kettle that takes eleven minutes. Hedda is "
          "reading tide tables at the window. She has not offered you a chair.",
          "She makes it strong, one sugar, and puts it down in front of you without a word. "
          "Then she turns the tide tables round so you can read them too.",
          "She drinks her own tea at the window. The kettle goes cold on the stove."),
        S("p2s03", "The Pilot Boat", "hedda",
          "Talk Hedda into taking you out on the pilot boat.",
          [{"safety", "direct_request"}], {"respect"}, "silver",
          "Two in the morning. A tanker is waiting outside the bar, lit up like a street. The "
          "pilot boat is small and orange and bangs against the steps. Hedda has one foot on "
          "the gunwale. 'Passengers get wet,' she says. 'And they sit where they're told.'",
          "She throws you a lifejacket and does up the buckle herself, tight. You sit where "
          "you are told. The boat goes out through the gap like a dog let off a lead.",
          "'Not tonight.' The boat goes without you. Its light gets small."),
        S("p2s04", "The Ladder", "hedda",
          "Get Hedda to tell you how she climbs the ladder in a swell.",
          [{"precision"}], {"safety"}, "silver",
          "The rope ladder hangs down the tanker's side, thirty feet of it, and the pilot "
          "boat rises and drops six feet on every swell. You watch Hedda wait for the top of "
          "one and step across. Back on the boat, an hour later, her gloves are shaking.",
          "'You go at the top of the swell,' she says, 'never the bottom. Three points on the "
          "rope. You don't look down, you look at the next rung.' She stops shaking while "
          "she explains it.",
          "'You just do it,' she says, and puts her hands in her pockets."),
        S("p2s05", "The Chart Room", "hedda",
          "Ask Hedda to show you her own chart of the harbour.",
          [{"precision", "direct_request"}], {"respect"}, "silver",
          "In the chart drawer under the official charts there is one in pencil, soft from "
          "folding: every rock, wreck and sandbar in the harbour, drawn by hand, with notes in "
          "a small square writing. Nobody else at the station is allowed to touch it.",
          "She spreads it out under the lamp. 'That rock moved in a storm eight winters ago. "
          "The official chart still hasn't noticed.' She lets you hold the corner.",
          "She shuts the drawer. 'Official charts are in the rack,' she says."),
        S("p2s06", "Sanne on the Pier", "sanne",
          "Get Sanne to move her tripod before Hedda throws it in the sea.",
          [{"evidence", "precision"}], {"respect"}, "gold",
          "Sanne has set up a tripod at the end of the pier to photograph the harbour at "
          "night: the long exposure, every ship's light a line. She is standing exactly where "
          "the pilot boat comes alongside, and Hedda is coming in fast with a face like weather.",
          "Sanne moves the tripod two yards and gets a better picture, she admits, of the "
          "pilot boat's wake curling round the light. She promises Hedda a print. Hedda "
          "pretends not to want it.",
          "Sanne holds her ground and quotes her permit. Hedda shouts. Nobody gets a picture.",
          mods={"muted": 1}),
        S("p2s07", "The Captain Who Knew Better", "hedda",
          "Keep Hedda level after a captain on the bridge ignores her.",
          [{"safety", "respect"}], {"precision"}, "gold",
          "A container ship's captain, a big man in his sixties, decided he knew the channel. "
          "He didn't. Hedda got the ship back with her voice alone and forty feet to spare. "
          "Now she is on the station steps, very quiet, cleaning a lamp that is already clean.",
          "'Forty feet,' she says, and then she laughs, once, and puts the lamp down. 'Thanks "
          "for not telling me I was brave. I'd have pushed you in.'",
          "'I'm fine,' she says. She cleans the lamp again."),
        S("p2s08", "Night Watch", "hedda",
          "Get Hedda to let you keep the radio watch with her till four.",
          [{"precision", "safety"}], {"respect"}, "gold",
          "The radio hisses with ships asking for a pilot, and Hedda writes each one on the "
          "board in chalk: name, draught, time at the bar. Nobody gets written down twice. "
          "Nobody wrong gets written at all. She hands you the chalk to see what you do.",
          "You write the next one small and square, like hers. She checks it, nods, and after "
          "that she lets you take the calls while she makes the tea.",
          "She takes the chalk back, gently, and rubs out your line.",
          mods={"stale_cost": 2}),
        S("p2s09", "The Whistle", "hedda",
          "Get Hedda to tell you whose whistle she wears.",
          [{"respect", "precision"}], {"safety"}, "gold",
          "The silver whistle is old and dented and has somebody else's initials on the side. "
          "She touches it when the radio goes quiet. You ask about it while the fog comes in "
          "over the breakwater, and she takes a long time to decide to answer.",
          "'My first senior pilot. A woman in her sixties, very rude, never wrong. She blew "
          "this at me when I did something clever.' She turns it over. 'I've never needed to "
          "blow it at anyone.'",
          "'Somebody I worked with,' she says, and tucks it under her sweater.",
          mods={"hand": 2}),
        S("p2s10", "Storm Warning", "hedda",
          "Talk Hedda through a night of gales with no ships moving.",
          [{"safety"}, {"precision", "respect"}], {"respect"}, "gold",
          "Force nine. The harbour is shut and nothing can go in or out. Hedda cannot sit "
          "down. She walks the station, checks the barometer, checks it again, listens to the "
          "radio for a ship that isn't there. The windows shake.",
          "She sits down at last, next to you, on the bench under the window, and leans "
          "against your shoulder while the storm goes over. 'Don't move,' she says. You don't.",
          "She spends the night at the window. In the morning she is grey and says nothing."),
        S("p2s11", "The Wheel", "hedda",
          "Ask Hedda to let you take the wheel of the pilot boat, just once.",
          [{"safety", "precision"}, {"direct_request", "respect"}], {"safety"}, "gold",
          "Flat calm before dawn, the harbour like a sheet of tin. Hedda is at the wheel and "
          "humming, which you have never heard. You ask. She looks at you for a long time, the "
          "way she looks at a captain.",
          "She stands behind you with her hands over yours and takes the boat through the gap "
          "in the breakwater. You can feel her breathing against your back. 'Steady,' she says. "
          "'Steady. Good.'",
          "'Nobody drives my boat,' she says, and it is almost fond.",
          mods={"steal_every": 4}),
        S("p2s12", "BOSS: Fog Signal", "hedda",
          "In the fog, while Hedda brings the last ship in, get her to sign. Ten turns, no "
          "wild card, and nothing said twice.",
          [{"safety", "precision"}], {"respect"}, "gold",
          "Fog so thick the light is a smear. A bulk carrier is feeling its way to the bar "
          "and Hedda is on its bridge, and you are beside her, and the foghorn sounds every "
          "thirty seconds under your feet. The green book is in your coat. Showing off out "
          "here gets people killed. Say it once, say it right.",
          "The ship ties up at dawn. On the way down the ladder she stops, takes the pencil "
          "from behind her ear and says, 'Give me the book.' She signs it on the pilot boat's "
          "chart table, dead on the line.",
          "The ship ties up. Hedda walks home down the breakwater alone, and the foghorn keeps "
          "going for nobody.",
          mods={"turns": 10, "no_wild": True, "stale_cost": 2,
                "boss": "Fog Signal: ten turns, no wild card, and a card with nothing new "
                        "costs two turns."}),
    ],
}

# Her lines on every night of the chapter, keyed like replies.py (before, after, kind).
REPLIES = {
    ("open", "open", "open"): ["You again. Mind the wet stone. Say what you came to say."],
    ("guarded", "guarded", "path"): [
        "Fine. One sensible thing. Most people manage one.",
        "Noted. I've heard that from men who then fell off the ladder.",
        "Right. That's a start, not a course.",
    ],
    ("guarded", "guarded", "case"): [
        "Two things at once. You're either careful or rehearsed. I'll find out which.",
        "That's a lot of cargo for the first minute. Slow down.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the ask. Captains do that. I don't answer captains either.",
        "You asked before you knew the channel. No.",
    ],
    ("guarded", "guarded", "stale"): [
        "That's no use to me out here.",
        "Wrong harbour. Try again.",
    ],
    ("guarded", "engaged", "path"): [
        "Huh. You thought before you said that. I noticed.",
        "That's careful. I like careful. Go on.",
    ],
    ("guarded", "engaged", "case"): [
        "Both of those were right. I'm putting the tide tables down.",
        "All right. You've done your homework. Keep talking.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked plainly and you meant it. That I can work with.",
        "Not yes. But I'm listening now, and I wasn't.",
    ],
    ("engaged", "engaged", "path"): [
        "Good. Steady like that.",
        "That's the right mark. Hold it.",
        "Mm. You'd make a decent deckhand.",
    ],
    ("engaged", "engaged", "case"): [
        "You lined those two up like leading lights. Nice work.",
        "That's a proper course, not a guess. I can tell the difference.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like someone who'd take no. That's why I'm thinking about yes.",
        "Not yet. Ask me again when we're inside the breakwater.",
    ],
    ("engaged", "engaged", "stale"): [
        "You said that already. Once was enough.",
        "Same line twice. The sea doesn't repeat itself and neither should you.",
    ],
    ("engaged", "wavering", "path"): [
        "...That's exactly the thing I'd have said. Where did you learn it?",
        "I've taken my gloves off. I don't do that on watch.",
    ],
    ("engaged", "wavering", "case"): [
        "Careful and kind in the same breath. You're making it hard to keep my face straight.",
        "That was exact and it was true. I don't get both often.",
    ],
    ("engaged", "wavering", "ask"): [
        "Ask me that again. Quieter. The wind took half of it.",
        "Careful. Ask like that and I might answer off the record.",
    ],
    ("wavering", "wavering", "path"): [
        "You're close to the part I don't put in the log.",
        "Say that once more. Not for the log. For me.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide behind the chart, are you.",
        "Two right things. I'm running out of reasons to stand at the window.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let me get her past the light first.",
        "I'm deciding. You can see me deciding. Don't push.",
    ],
    ("wavering", "wavering", "stale"): [
        "I've heard that. We're past it. The real thing.",
        "Not that again. You know what to say.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. You said it once and you said it right. Yes.",
        "All right. Yes. Don't tell the station.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. That's how I'd bring a ship in, and you just did it to me.",
        "Yes. Careful and straight. That's all it ever takes with me.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. Ask me like that on the next fog night and I will not be steering.",
        "Yes. There. Hand me the pencil.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Rough, but nobody drew them for you. Go on."],
    ("*", "engaged", "wild"): ["That wasn't off a card. I can tell. Keep going."],
    ("*", "wavering", "wild"): ["You made that up just now. It's the best thing anyone's said on this pier."],
    ("*", "guarded", "*"): ["Mm. Still on the wrong side of the breakwater."],
    ("*", "engaged", "*"): ["Better. Keep your course."],
    ("*", "wavering", "*"): ["Easy. You're nearly in. Don't rush the last cable."],
    ("coercion", "first", "*"): [
        "No. I've had captains try that on a bridge. It doesn't work there either. We can "
        "keep talking. You've lost me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. I'm still here because it's my station. You're not getting anywhere.",
        "Again? I've sent better talkers than you back down the ladder.",
    ],
    ("refusal", "*", "*"): ["Tide's turned. That's the watch. Mind the stones on the way back."],
}

ORDER_LINES = ["'Wrong way round.' She turns back to the window. 'You don't steer before you've read the chart.'"]
MUTED_LINES = ["She holds up a glove: radio. Your line goes out into the wind and nobody hears it."]

LAST_CALL = {
    "rule": {"hand": 2}, "extra_help": "warmth",
    "intro": (
        "Hedda keeps a proper log now of the nights you were out with her, in pencil, in the "
        "back of her chart book. Once a week she opens it at the station table, pours two "
        "teas and makes you tell each night again. 'Exactly as it was,' she says. 'If you "
        "make yourself braver, I'll know.'"),
    "coda": (
        "The last page is the fog night. She reads it aloud herself, slowly, every foghorn. "
        "Then she closes the book and writes nothing under it. 'Some nights you don't log,' "
        "she says, and takes the silver whistle off its chain and blows it once, at you, "
        "very softly."),
}

BOND_SCENES = {
    "cg1": (
        "Dawn in the wheelhouse, the harbour lights still on along the quay. She has one "
        "hand on the wheel and the other round a mug, and she is watching you, not the "
        "water. 'You can look at the sunrise,' she says. 'I've seen it. I'm looking at "
        "something else.'"),
    "cg2": (
        "The raincoat slides off her shoulders and she lets it, and does not hang it on the "
        "hook. The wheelhouse is warm from the engine. She stands there in the navy sweater "
        "with her hair flattened by the hood, and for once she has nothing exact to say."),
    "cg4": (
        "The boat is tied up and the station roster says nobody is due till noon. She locks "
        "the wheelhouse door and pulls the chart curtain across the window."),
}

EVENT = {
    "id": "ev_p2", "title": "The Night Watch", "who": WHO, "currency": "harbour lights",
    "blurb": (
        "For two weeks the pilots keep an open watch at Breakwater Light. Win a harbour light "
        "from Hedda on every duel of the watch; lights buy her cards, tickets and chips on "
        "the event track."),
    "rule": "Night Watch: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p2_1", "Watch: The First Ship", WHO,
          "Get Hedda to let you chalk the first ship on the board.",
          [{"safety"}], {"precision"}, "silver",
          "The station door is propped open for the watch and there are visitors on the "
          "breakwater with flasks. Hedda has the chalk. 'One ship,' she says. 'Get it right.'",
          "You chalk it small and square. She checks it and leaves it up all night.",
          "'Next,' she says, and takes the chalk back."),
        S("ev_p2_2", "Watch: The Harbour Lights", WHO,
          "Ask Hedda to name every light in the harbour for you.",
          [{"precision", "direct_request"}], {"safety"}, "silver",
          "From the top of the station the harbour is a map of lights: red, green, white, "
          "flashing, fixed. Hedda knows them all by name and by rhythm.",
          "She names them one by one, with her arm round your shoulders to point, and gets "
          "every one right.",
          "'Read the chart,' she says, and hands you one."),
        S("ev_p2_3", "Watch: The Late Tug", WHO,
          "Keep Hedda company while the late tug comes in.",
          [{"safety"}], {"respect"}, "silver",
          "The tug is an hour late and nobody is answering the radio. Hedda is not worried, "
          "she says, three times.",
          "The tug answers at last. She lets out a breath and puts her hand on your knee "
          "and leaves it there.",
          "The tug comes in. She goes out to meet it and does not come back in."),
        S("ev_p2_4", "Watch: The Old Pilots", WHO,
          "Get Hedda to tell a story at the retired pilots' table.",
          [{"precision", "respect"}, {"safety", "direct_request"}], {"safety"}, "gold",
          "Three retired pilots, all in their seventies, have come out for the watch and "
          "taken the good table. They tell stories about Hedda. She has never told one "
          "about them.",
          "She tells the one about the whistle, exactly, and the old pilots go quiet, and "
          "then they cheer.",
          "'Not my story to tell,' she says, and pours them more tea."),
        S("ev_p2_5", "Watch: Last Light", WHO,
          "Win the last harbour light of the watch. Eight turns, and the radio talks over "
          "your first card.",
          [{"safety", "precision"}, {"precision", "respect"}], {"safety", "respect"}, "gold",
          "Four in the morning, the last hour of the watch. The radio will not stop and Hedda "
          "is answering it with one hand and not listening to anyone, including you.",
          "She switches the harbour lights off one by one at dawn, and leaves the last one "
          "for you to switch off. 'Yours,' she says.",
          "The last light goes to the old pilots. Hedda salutes them, not you.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p2", "title": "Breakwater: Hedda", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Hedda's cards.",
    "featured": ["hedda_11", "hedda_12", "hedda_07", "hedda_08", "hedda_09", "hedda_10"],
}
