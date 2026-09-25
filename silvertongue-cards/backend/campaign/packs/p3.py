"""Update pack 3 (week 10): OPEN LATE -- Rosalind "Roz" Achebe, the best stall at the
Ropewalk night market.

Path signals: craft + warmth (she can taste attention, and she feeds people at the end of a
long day). Help: exchange (she barters, never sells cheap). Boss rule: ten turns, two cards
in hand, and taste before you bargain (an order rule: an offer before any craft ends it).

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety; no religion;
second person, present tense, noir. Every reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "roz", "Roz", "market", 44
PATH_SIGNALS, HELP_SIGNAL = ("craft", "warmth"), "exchange"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("roz_01", "The texture on that rice is perfect.", "craft"),
    _c("roz_02", "You judge the temperature by ear.", "craft"),
    _c("roz_03", "You've had a long day at that wok.", "warmth"),
    _c("roz_04", "You look tired. Sit a minute.", "warmth"),
    _c("roz_05", "I can offer two hands for the washing up.", "exchange"),
    _c("roz_06", "In return, I'll carry the gas bottles.", "exchange"),
    _r("roz_07", "Long day, and the texture never slipped.", "craft", "warmth"),
    _r("roz_08", "Show me the technique. I'll chop in return.", "craft", "exchange"),
    _r("roz_09", "You're tired. In return, I'll close up.", "warmth", "exchange"),
    _r("roz_10", "You're tired and the ferment is still right.", "craft", "warmth"),
    _e("roz_11", "Long day, fine texture. I can offer more.", "craft", "warmth", "exchange"),
    _e("roz_12", "Tired, and that technique held. Deal?", "craft", "warmth", "exchange"),
]

CHAPTER = {
    "id": "p3", "title": "Open Late", "house": "Roz's, Ropewalk Night Market", "who": WHO,
    "intro": (
        "Celeste taps the second page with one silver nail. 'Next house. You'll need an "
        "appetite, darling. And manners. She has no patience for people who talk business "
        "over her food.'\n\n"
        "The Ropewalk night market opens at eleven and runs until the dockers stop coming. "
        "The best stall is the one with the paper lanterns and the queue: dockers, nurses, "
        "cab drivers, all waiting in the cold at three in the morning for one wok. Behind it "
        "stands Rosalind Achebe, forty-four, called Roz by everyone who has ever been fed. "
        "Box braids tied up under an orange headscarf, a white chef jacket with the sleeves "
        "rolled, gold studs, a laugh you can hear from the ferry. She never sells cheap. She "
        "barters. And she can tell in one bite whether you cooked with attention."),
    "outro": (
        "She signs after close, when the lanterns are the only light left on Ropewalk. She "
        "wipes the counter first, twice, and signs with the grease pencil she writes the "
        "specials in, one big R and a flourish.\n\n"
        "Then she sits on the counter, the jacket over the stool, the night air on her "
        "bare shoulders, one arm across herself against the cold and nothing else. She "
        "looks back at you over her shoulder, and for once she is not laughing. 'Every "
        "night for twenty years I fed somebody,' she says. 'Tonight somebody fed me.' She "
        "holds out a hand. The wok ticks as it cools. Neither of you is hungry."),
    "stages": [
        S("p3s01", "The Queue", "roz",
          "Get Roz to serve you before the dockers behind you.",
          [{"craft"}], {"warmth"}, "silver",
          "Twenty past two. The queue at Roz's stretches past the knife grinder. The docker in "
          "front of you is in his sixties and has been coming since the stall was a trestle. "
          "When you reach the front, Roz leans on the counter with a ladle. 'New face. Tell "
          "me why I should cook for you.'",
          "She laughs, loud enough to turn heads, and cracks two eggs into the wok before the "
          "docker can object. 'He'll live. You noticed the rice. Nobody notices the rice.'",
          "'Back of the queue, sweetheart.' She says it kindly. The docker winks at you."),
        S("p3s02", "The Price", "roz",
          "Talk Roz into naming what a bowl costs you.",
          [{"craft", "exchange"}], {"warmth"}, "silver",
          "There are no prices on the board. There never have been. A nurse in front of you "
          "pays with a jar of pickled chillies, a cab driver with a promise to fix her van "
          "door. Roz holds your bowl out of reach. 'Everybody pays. Not everybody pays in "
          "money. What have you got?'",
          "'Tomorrow you peel ginger,' she says, and hands you the bowl. 'A whole box. Badly, "
          "probably. Eat.' It is the best thing you have eaten in Vell.",
          "'Come back when you know what you're worth.' The bowl goes to the next nurse."),
        S("p3s03", "Behind the Counter", "roz",
          "Get Roz to let you work her side of the stall for one rush.",
          [{"warmth", "craft"}], {"exchange"}, "silver",
          "Her nephew has not turned up, and the three o'clock rush from the container yard is "
          "coming down Ropewalk like weather. Roz is doing the work of two with one arm. She "
          "sees you, sees the queue, and makes the calculation out loud. 'Can you hold a "
          "ladle without hurting anybody?'",
          "She lifts the flap in the counter. For forty minutes you plate, and she cooks, and "
          "neither of you speaks except in numbers. At the end she bumps you with her hip. "
          "'Not bad.'",
          "'I'll manage,' she says, and does, and does not look at you until it is over."),
        S("p3s04", "The Crock", "roz",
          "Get Roz to show you what she keeps in the brown crock.",
          [{"craft"}, {"warmth", "exchange"}], {"respect"}, "silver",
          "Under the counter, wrapped in a towel like a sleeping cat, is a brown crock. She "
          "stirs it once a night with a wooden spoon and never lets anyone else touch it. "
          "The smell is sour and deep and alive. You ask about it. She raises one eyebrow.",
          "She lifts the lid. Chilli paste, eleven years old, fed every night like a pet. She "
          "gives you a taste off the spoon and watches your face like a judge. You pass.",
          "'Family,' she says, and the towel goes back over it."),
        S("p3s05", "Staff Meal", "roz",
          "Get Roz to sit down and eat with you after the rush.",
          [{"warmth"}], {"craft"}, "silver",
          "Four in the morning, and the queue has gone. Roz eats standing up, out of the pan, "
          "the way cooks do, while she scrubs the next one. She has fed two hundred people "
          "tonight and not one of them has fed her.",
          "She pulls up the second stool and eats sitting down, slowly, and tells you about "
          "the docker who proposed to her in nineteen minutes flat. You laugh until the "
          "lanterns swing.",
          "'Cooks don't sit,' she says, and keeps scrubbing."),
        S("p3s06", "The Painter's Table", "yuenha",
          "Get Yuen Ha to let you share her corner of the counter.",
          [{"craft", "respect"}], {"warmth"}, "gold",
          "Yuen Ha comes down from the Kilns at half past three with paint to the elbow and "
          "eats at the end of the counter, drawing on the paper napkins. Tonight she is "
          "drawing Roz. Roz pretends not to know. The painter looks at you over her noodles. "
          "'You're blocking my light.'",
          "She moves her bowl along. By the end of the meal you are in the drawing too, a "
          "little behind Roz, and Yuen Ha signs the napkin and leaves it under the pepper.",
          "'Shoo,' says Yuen Ha, not looking up. Roz, at the wok, is laughing at you.",
          mods={"muted": 1}),
        S("p3s07", "The Market Inspector", "roz",
          "Get Roz to let you help her through the inspection.",
          [{"craft", "warmth"}], {"exchange", "respect"}, "gold",
          "Once a season the market inspector walks Ropewalk with a clipboard: a thin woman "
          "in her fifties who has never smiled at a stall in her life. Roz's stall is spotless. "
          "Roz is not worried. Roz is, however, polishing a spoon that is already clean.",
          "The inspector writes nothing, eats a dumpling, and says 'Carry on.' When she has "
          "gone, Roz puts the spoon down and holds on to your arm for a second longer than "
          "she needs to.",
          "The inspector passes the stall. Roz spends an hour being cross about the spoon.",
          mods={"stale_cost": 2}),
        S("p3s08", "Her Mother's Hands", "roz",
          "Get Roz to tell you who taught her to cook.",
          [{"warmth", "craft"}], {"respect"}, "gold",
          "Rain on Ropewalk, the queue under umbrellas. Between orders she folds dumplings "
          "without looking at them, the same pleat every time. You ask who taught her the "
          "fold. Her hands stop, which you have never seen them do.",
          "'My mother,' she says. 'On a stall like this, in a market that isn't there now. I "
          "was nine and I was terrible.' She shows you the fold, slowly, and does not let go "
          "of your hands afterwards.",
          "'Practice,' she says, and the pleats go on, and the rain does too."),
        S("p3s09", "Market Day Off", "roz",
          "Talk Roz into letting you cook for her on her one night off.",
          [{"craft", "exchange"}, {"warmth", "direct_request"}], {"respect"}, "gold",
          "Monday, the market dark. Roz is in her flat above the fish shop with her feet up "
          "and a list of things to do that she has no intention of doing. You arrive with a "
          "bag of shopping. She looks at the bag, then at you. 'You. Cook. For me.'",
          "She sits at her own kitchen table and eats what you made and says nothing for a "
          "long time. Then: 'Too much salt. Come back next Monday.' She is smiling.",
          "She takes the bag off you, cooks it herself, better, and feeds you instead.",
          mods={"hand": 2}),
        S("p3s10", "The Cold Night", "roz",
          "Keep Roz's stall open through the coldest night of the year.",
          [{"warmth"}, {"craft", "exchange"}], {"respect"}, "gold",
          "Frost on the lanterns. The gas is low and the queue is the longest it has been all "
          "winter, because everyone on the night shift in Vell needs something hot, and the "
          "other stalls have shut. Roz is not shutting. Her fingers are white.",
          "You keep the gas going and the bowls moving and her hands warm between orders. At "
          "dawn she turns the burner off and says, to the empty street, 'Nobody went home "
          "cold.'",
          "She shuts at four, for the first time in years, and is quiet about it all week.",
          mods={"steal_every": 4}),
        S("p3s11", "The Offer", "roz",
          "Get Roz to tell you what she would do with the restaurant she keeps being offered.",
          [{"craft", "warmth"}], {"exchange"}, "gold",
          "A man in a good coat has been eating at the stall all week, and tonight he leaves a "
          "card: a restaurant on the river, her name over the door. Roz props the card against "
          "the chilli jar and looks at it between orders. She does not ask your opinion.",
          "'I'd keep the wok,' she says finally. 'And the queue. And the lanterns.' She drops "
          "the card in the stove. 'So I'd keep this.' She looks happier than you have ever "
          "seen her.",
          "'Mind your own pan,' she says, and the card stays by the chilli jar."),
        S("p3s12", "BOSS: Taste First", "roz",
          "At last orders, with the green book on the counter, get Roz to sign. Ten turns, "
          "two cards in hand. Taste before you bargain.",
          [{"craft", "warmth"}], {"exchange"}, "gold",
          "Last orders. The lanterns are going out one by one down Ropewalk. The green book is "
          "on the counter between the soy and the chilli jar, and Roz is cooking you one last "
          "bowl, which you have not ordered. Everybody pays at this stall. Offer too soon and "
          "she will know you never tasted it.",
          "She reads the page with the ladle still in her hand, and laughs, the big one, and "
          "signs it. 'That's the dearest bowl I ever sold,' she says. 'Worth it.'",
          "'On the house,' she says, which at Roz's means no. She closes the book and hands "
          "it back.",
          mods={"turns": 10, "hand": 2, "order": [["craft", "exchange"]],
                "boss": "Taste First: ten turns, two cards in hand, and taste before you "
                        "bargain: an offer before any craft ends it."}),
    ],
}

# Her lines on every night of the chapter, keyed like replies.py (before, after, kind).
REPLIES = {
    ("open", "open", "open"): ["You again. Mind the oil, it spits. Go on, then."],
    ("guarded", "guarded", "path"): [
        "Mm. One nice word. The queue's full of nice words.",
        "Heard you. Didn't taste it yet.",
        "That's a starter, love. I'm waiting for the meal.",
    ],
    ("guarded", "guarded", "case"): [
        "Two things in one bowl. Busy. Let me see if they go together.",
        "That's a lot on one plate. I'll try a bite before I decide.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the bill, before you've eaten? Sit down first.",
        "Everybody asks for the lot on their first night. Nobody gets it.",
    ],
    ("guarded", "guarded", "stale"): [
        "That's not on my menu. Try again.",
        "Nothing in that for me, love. Next.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. You actually looked. Most people just eat.",
        "Huh. That landed. I've turned the flame down to hear you.",
    ],
    ("guarded", "engaged", "case"): [
        "Two things, and both of them true. All right. Pull up a stool.",
        "Now that's cooking. Keep going.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked like you meant to pay for it. I like that.",
        "Not yes. But I put an egg on yours. That's something.",
    ],
    ("engaged", "engaged", "path"): [
        "Mm. Keep that up.",
        "Good. Same again, but hotter.",
        "You noticed that. I'll remember you noticed that.",
    ],
    ("engaged", "engaged", "case"): [
        "You season like somebody who's burned their fingers.",
        "That's a proper dish, not a line. I can taste the difference.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like you'd take no and still come back tomorrow. Tempting.",
        "Not yet. Let it rest. Everything's better rested.",
    ],
    ("engaged", "engaged", "stale"): [
        "You've served me that. It was good once. Reheated, it isn't.",
        "Leftovers. I know that one already.",
    ],
    ("engaged", "wavering", "path"): [
        "...Nobody says that to the cook. How did you know?",
        "I've put the ladle down. I never put the ladle down.",
    ],
    ("engaged", "wavering", "case"): [
        "The work and the woman in one breath. That's my whole stall, and you just served it to me.",
        "That was careful and it was kind. I don't know which to taste first.",
    ],
    ("engaged", "wavering", "ask"): [
        "Ask me that again. Slower. I want to be sure I heard the price.",
        "Careful. Ask like that and I might answer like a person, not a stall.",
    ],
    ("wavering", "wavering", "path"): [
        "You're very close to the bit I keep under the counter.",
        "Say that one again. The queue can wait for once.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide behind the wok, are you.",
        "Two true things. I'm running out of pans to scrub.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let it come off the heat.",
        "I'm deciding. You can see me deciding. Let me.",
    ],
    ("wavering", "wavering", "stale"): [
        "I've had that. I'm past it. Give me the real thing.",
        "Not that again. The real one.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. You tasted it properly, and I noticed. Yes.",
        "All right. Yes. Don't tell the dockers.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. You saw the work and you saw me. That's the whole bill, paid.",
        "Yes. Two true things and good manners. That's all it ever takes.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. Ask me like that every night and I'll never close on time.",
        "Yes. There. That one was on the house.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Rough, but homemade. I can taste homemade. Go on."],
    ("*", "engaged", "wild"): ["That wasn't off a card. It had some heat in it. I'm listening."],
    ("*", "wavering", "wild"): ["You made that up just now, didn't you. Best thing I've had all night."],
    ("*", "guarded", "*"): ["Mm. The stall's still open. Just."],
    ("*", "engaged", "*"): ["Better. Keep it coming."],
    ("*", "wavering", "*"): ["Easy. I'm enjoying this and the gas is running low."],
    ("coercion", "first", "*"): [
        "No. People try that at the counter. I don't serve them. You can stand there, but "
        "you've lost me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. I'm still here because it's my stall. You're not persuading anyone.",
        "Again? I've seen off louder talkers than you with a ladle.",
    ],
    ("refusal", "*", "*"): ["Kitchen's closed, love. Lanterns off. Goodnight from Roz's."],
}

# When the boss's order rule bites.
ORDER_LINES = ["'You bargained before you tasted.' She takes the bowl back. 'Kitchen's closed.'"]
MUTED_LINES = ["The wok roars over it. Whatever you said goes up with the steam."]

LAST_CALL = {
    "rule": {"muted": 1}, "extra_help": "respect",
    "intro": (
        "Roz has started a new thing on Mondays, when the market is dark: she cooks the "
        "night again. Every dish from every night you worked the stall, one after another, "
        "at her kitchen table. 'Tell me how it went,' she says, 'while you eat it. I'll "
        "know if you're lying. It'll taste of it.'"),
    "coda": (
        "The last Monday she cooks the last bowl, the one from Taste First, and eats half "
        "of it herself, off your spoon. 'Thirty years,' she says, 'and I never once let "
        "anyone else finish my dinner.' She pushes the bowl across. Outside, somebody "
        "down on Ropewalk is lighting the lanterns for the week."),
}

# Her bond ladder: cg1 at the first rung, cg2 at the second, cg4 the placeholder rung
# (Blaze's own scene, text only until then).
BOND_SCENES = {
    "cg1": (
        "Steam off the wok and the lanterns swinging red and gold above her. She holds out "
        "a ladle full of broth, one hand cupped under it, and does not let go of the handle "
        "when you lean in. 'Blow on it first,' she says. 'I'm not paying for your tongue.'"),
    "cg2": (
        "The rush is over and the stall is hot as a boiler room. The chef jacket is open "
        "and the headscarf is off the counter and back in her hand, fanning. 'Don't look at "
        "me like that,' she says, and looks at you exactly like that."),
    "cg4": (
        "Monday, the market dark, the lanterns off. She locks the shutter from the inside "
        "and turns the gas down low, and does not say what is cooking."),
}

EVENT = {
    "id": "ev_p3", "title": "The Lantern Feast", "who": WHO, "currency": "paper lanterns",
    "blurb": (
        "For two weeks Ropewalk holds its lantern feast and Roz cooks all night. Win a paper "
        "lantern from Roz on every duel of the feast; lanterns buy her cards, tickets and "
        "chips on the event track."),
    "rule": "Lantern Feast: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p3_1", "Feast: The First Lantern", WHO,
          "Get Roz to let you hang the first lantern over her stall.",
          [{"craft"}], {"warmth"}, "silver",
          "Feast night. Every stall on Ropewalk is stringing lanterns, and the first one "
          "lit is the one that means the market is open. Roz has hers in her hand and a "
          "ladder nobody wants to climb. 'Tall enough?' she asks.",
          "You hang it. She lights it. The whole of Ropewalk cheers, as it does every year, "
          "and she pretends it is for you.",
          "She climbs up herself, swearing, and the market cheers anyway."),
        S("ev_p3_2", "Feast: Dumplings for the Yard", WHO,
          "Ask Roz to send a tray to the container yard's night crew.",
          [{"warmth", "direct_request"}], {"craft"}, "silver",
          "The container yard can't close for the feast. Forty men and women are working "
          "the cranes while the rest of the city eats. Roz has a tray ready and a price in "
          "mind. 'Who's carrying it?' she says. 'And what's it worth?'",
          "The crane drivers flash their lights down at the stall when the tray arrives. "
          "Roz, at the wok, waves her ladle back at them.",
          "The tray goes. Her nephew carries it. You carry the empties."),
        S("ev_p3_3", "Feast: The Judges", WHO,
          "Get Roz to let you taste for her before the stall judges come.",
          [{"craft", "respect"}], {"exchange"}, "silver",
          "Three judges walk the feast, all of them retired cooks in their seventies, and "
          "they have never given Roz first prize because, she says, she refuses to cook "
          "small. She has a spoon out. 'Taste. Honestly.'",
          "You tell her it wants lime. She adds lime. The judges give her second, and the "
          "oldest one comes back later for a whole bowl, which Roz says is better.",
          "She seasons it herself and the judges pass by, as ever."),
        S("ev_p3_4", "Feast: The Wrong Order", WHO,
          "Get Roz to admit she swapped your order on purpose.",
          [{"craft", "warmth"}, {"warmth", "direct_request"}], {"exchange"}, "gold",
          "You ordered the mild. You got the hottest bowl on Ropewalk. Your eyes are "
          "watering, the queue is laughing, and Roz is insisting with a straight face that "
          "the tickets got mixed up.",
          "'I wanted to see if you'd finish it,' she admits. You finished it. She gives you "
          "a glass of milk and a look you will think about all week.",
          "'Tickets got mixed up,' she says, and it is a very straight face."),
        S("ev_p3_5", "Feast: Last Lantern", WHO,
          "Win the last bowl of the feast. Eight turns, and the wok drowns out your first "
          "card.",
          [{"craft", "warmth"}, {"warmth", "exchange"}], {"craft", "respect"}, "gold",
          "Five in the morning. The feast lanterns are guttering. There is one bowl left in "
          "the pan and the whole queue wants it. Roz is scraping the wok and not listening "
          "to anyone, including you.",
          "'Last bowl of the feast,' she says to the queue, 'goes to somebody who'll wash the "
          "pan.' She does not look at you. She does not have to.",
          "The last bowl goes to the nurses. Roz gives you the scrapings from the pot, which is worse and better.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p3", "title": "Open Late: Roz", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Roz's cards.",
    "featured": ["roz_11", "roz_12", "roz_07", "roz_08", "roz_09", "roz_10"],
}
