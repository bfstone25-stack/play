"""Update pack 5 (week 14): THE DAY LEDGER -- Dagny Holt, the Harbour Authority's night auditor.

Path signals: evidence + accountability (she respects people who show their working and own
their mistakes). Help: precision. Boss rule: ten turns, two kinds of support, and own your
part before you show your working (an order rule: evidence before any accountability ends
the duel).

Same house rules as story_a.py: every woman is an adult and the text says so; persuasion
is wit and attention, never leverage over anyone's work, money or safety -- nothing in any
ledger is ever used against anyone; no religion; second person, present tense, noir. Every
reply answers the kind of card just played.
"""
from __future__ import annotations

from ...cards import Card
from ..story_a import S

WHO, NAME, SCENARIO, AGE = "dagny", "Dagny", "archive", 47
PATH_SIGNALS, HELP_SIGNAL = ("evidence", "accountability"), "precision"


def _c(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, WHO, line, tuple(sorted(signals)), (), "epic", "ask")


CARDS = [
    _c("dagny_01", "It balances because I ran it twice.", "evidence"),
    _c("dagny_02", "Here is the result, and my working.", "evidence"),
    _c("dagny_03", "That was my fault. I'll own it.", "accountability"),
    _c("dagny_04", "I was wrong about the tide.", "accountability"),
    _c("dagny_05", "Exactly this much, not a penny more.", "precision"),
    _c("dagny_06", "Only if you'd like to. No hurry.", "precision"),
    _r("dagny_07", "My fault, and here is the result.", "accountability", "evidence"),
    _r("dagny_08", "Exactly this, because I showed it.", "evidence", "precision"),
    _r("dagny_09", "No excuse. Exactly where I slipped.", "accountability", "precision"),
    _r("dagny_10", "I was wrong, because I rushed the sums.", "accountability", "evidence"),
    _e("dagny_11", "My fault, exactly. Here is the result.", "accountability", "evidence", "precision"),
    _e("dagny_12", "I was wrong, exactly because I rushed.", "accountability", "evidence", "precision"),
]

CHAPTER = {
    "id": "p5", "title": "The Day Ledger", "house": "The Harbour Authority Archive", "who": WHO,
    "intro": (
        "Celeste taps the fifth name on the second page with one silver nail. 'This one "
        "keeps the other book, darling. The Day Ledger. Every ship, every crate, every "
        "fee, audited by hand. Ines has the night. She has the day. They have never once "
        "agreed on anything, and they have lunch every Friday.'\n\n"
        "The Harbour Authority Archive is four floors of shelves above the customs hall, "
        "lit by green banker's lamps. Its night auditor is Dagny Holt, forty-seven, "
        "strawberry-blonde braid over one shoulder, glasses on a chain, pearls with the "
        "waistcoat. She has worked the archive for twenty years. Nobody has ever hurried "
        "her. Several have tried. She signs nothing she has not checked, and she has "
        "checked everything."),
    "outro": (
        "She signs at the top of the library ladder, of all places, with the green book "
        "balanced on the rail and her pencil behind her ear. She initials the margin, as "
        "she does every page she has ever approved, and then she writes a second line "
        "under it: Checked. Correct.\n\n"
        "Later the lamps are low and the waistcoat and the blouse are folded over a chair "
        "like evidence nobody will ask for. She sits on the ladder with her arms crossed "
        "over herself and the braid down her back, and looks over her shoulder at you "
        "with the patience of a woman who has never once been hurried. 'Take your time,' "
        "she says. 'I intend to take mine.'"),
    "stages": [
        S("p5s01", "The Night Desk", "dagny",
          "Get Dagny to let you past the archive's front desk.",
          [{"evidence"}], {"precision"}, "silver",
          "Half past eleven. The customs hall is dark and the stairs smell of paper. At the "
          "top, behind a counter with a brass bell nobody rings, Dagny Holt is reading a "
          "ledger under a green lamp. She does not look up. 'The archive is closed,' she "
          "says. 'Tell me why it should open.'",
          "She lifts the counter flap without a word and turns the lamp so you can see the "
          "stairs. 'Mind the fourth step. It has opinions.'",
          "'A good try. Unsupported.' She turns a page. The lamp stays where it is."),
        S("p5s02", "The Tea Tray", "dagny",
          "Get Dagny to pour you a cup from her pot.",
          [{"accountability"}], {"precision"}, "silver",
          "You knock her tea tray on the way in. Nothing breaks, but the milk goes across "
          "the floor and she watches it the way she watches a column that will not add up. "
          "She waits to see what you do about it.",
          "She hands you the cloth, then the second cup. 'Most people blame the tray,' she "
          "says. 'The tray has been here longer than you.'",
          "She mops it herself, carefully, and drinks her tea alone."),
        S("p5s03", "The Missing Crate", "dagny",
          "Help Dagny find the crate the day ledger says came in twice.",
          [{"evidence", "accountability"}], {"precision"}, "silver",
          "One crate of lemons, entered on Tuesday and again on Wednesday. Dagny has a "
          "ruler under the line and a look she saves for honest mistakes. 'Somebody counted "
          "it twice,' she says. 'Find out how, and don't guess.'",
          "You find the carbon copy stuck to the next sheet. She holds it to the lamp and "
          "almost laughs. 'Paper,' she says. 'Always paper. Well found.'",
          "She finds it herself at two in the morning and does not say how."),
        S("p5s04", "Pencil, Not Pen", "dagny",
          "Get Dagny to let you write one line in the day ledger.",
          [{"accountability", "precision"}], {"evidence"}, "silver",
          "Nobody writes in her book but her. She uses a hard pencil so that every "
          "correction shows. 'Ink hides things,' she says. 'Pencil owns up.' She holds the "
          "pencil out and does not let go of it.",
          "She lets go. You write one line, slowly, and she reads it over your shoulder, and "
          "initials it. 'Neat enough,' she says, which from her is a medal.",
          "'Another night,' she says, and puts the pencil behind her ear."),
        S("p5s05", "The Tide Tables", "dagny",
          "Get Dagny to explain why she audits at night.",
          [{"evidence"}, {"accountability"}], {"precision"}, "silver",
          "At three the harbour goes quiet and the tide turns. She keeps the tide tables "
          "open on the desk beside the ledger, though no auditor needs them. You ask why. "
          "She raises one eyebrow above the glasses.",
          "'Because at night nobody asks me for a number before I've checked it,' she says. "
          "'The day wants answers. The night lets me be right.'",
          "'Habit,' she says, and turns the lamp back to the page."),
        S("p5s06", "The Other Book", "ines",
          "Get Ines to admit the day ledger is the better kept of the two.",
          [{"empathy", "accountability"}], {"respect"}, "gold",
          "Ines comes up the stairs at one with the green book under her arm, as she does "
          "once a month, to reconcile. She is thirty-four and dressed for a different kind "
          "of night. She and Dagny do not say good evening. They say each other's surnames, "
          "like chess players.",
          "Ines sighs and slides the green book across the desk. 'Hers is tidier,' she "
          "tells you. 'Mine is more interesting.' Dagny does not smile. Her pearls do.",
          "Ines calls the day ledger 'a very long receipt'. Dagny calls the Night Ledger "
          "'gossip with a spine'. You stay out of it.",
          mods={"muted": 1}),
        S("p5s07", "Twenty Years", "dagny",
          "Get Dagny to tell you about the one mistake she ever let through.",
          [{"accountability", "evidence"}], {"precision", "respect"}, "gold",
          "There is a page from twenty years ago pinned inside the cupboard door, yellow, "
          "with one figure circled in red. You ask. She takes her glasses off and lets them "
          "hang on the chain, which is a thing she does before she says something true.",
          "'My first month. I trusted a number because the man was polite.' She puts the "
          "glasses back on. 'He was very polite. I have checked everything since.'",
          "'An old page,' she says, and closes the cupboard."),
        S("p5s08", "Closing Time", "dagny",
          "Ask Dagny to let you walk her down to the harbour at dawn.",
          [{"evidence", "precision"}], {"accountability"}, "gold",
          "Six o'clock. She locks the ledger in the safe, straightens every pencil, and puts "
          "on a coat she has owned for longer than you have been in Vell. At the top of the "
          "stairs she stops and considers you like a column of figures.",
          "She takes your arm on the steps, and talks all the way to the water about the "
          "ships, which she knows by their fees. At the quay she says, 'Tomorrow. Eleven.'",
          "'I know the way,' she says, which is true, and goes.",
          mods={"stale_cost": 2}),
        S("p5s09", "The Wrong Column", "dagny",
          "Get Dagny to let you help with the column she cannot close.",
          [{"accountability", "evidence"}], {"precision"}, "gold",
          "A column that is out by a small sum and has been for three nights. She has "
          "checked it nine times. She will not ask for help, because she has never needed "
          "any, and she is holding the pencil very tightly.",
          "You read it upside down and see the transposed figures. She stares at them, and "
          "then at you. 'Nine times,' she says. 'Thank you. Do not tell Ines.'",
          "She closes it herself at dawn and looks tired all the next night.",
          mods={"hand": 2}),
        S("p5s10", "The Braid", "dagny",
          "Get Dagny to let her hair down, just for an hour.",
          [{"evidence"}, {"accountability", "respect"}], {"precision"}, "gold",
          "Four in the morning, the heating off, the lamps humming. She has been rubbing the "
          "back of her neck for an hour. The braid is heavy, she admits. She has worn it the "
          "same way since she was a clerk.",
          "She pulls the ribbon and the braid comes loose over her shoulder, and she looks "
          "about ten years younger and twice as dangerous. 'Don't write that down,' she says.",
          "'It stays up,' she says, and it does."),
        S("p5s11", "The Audit of You", "dagny",
          "Get Dagny to read out the entry she has been keeping on you.",
          [{"accountability", "precision"}], {"evidence"}, "gold",
          "She keeps a small notebook in her waistcoat pocket, and you have seen her write in "
          "it after every night you come in. Tonight she leaves it on the desk, face down, "
          "which is either an accident or a test. With her it is never an accident.",
          "She reads it out. Dates, a few lines each: late, honest, owned the milk, found "
          "the carbon, helped with the column. At the bottom: 'Correct so far.'",
          "She puts the notebook back in her pocket. 'Unaudited,' she says.",
          mods={"steal_every": 4}),
        S("p5s12", "BOSS: Balanced Books", "dagny",
          "Before the archive opens, get Dagny to sign. Ten turns, two kinds of support, and "
          "own your part before you show your working.",
          [{"accountability", "evidence"}], {"precision", "respect", "empathy"}, "gold",
          "The last night before the quarter closes. The green book sits beside the day "
          "ledger, both open, under one lamp. Dagny has cleared the desk of everything else. "
          "'Show me your working,' she says. 'But you'll own your part first. I don't "
          "take figures from people who haven't.'",
          "She reads everything twice. Then she takes the pencil from behind her ear and "
          "signs, small and exact, and blows on it though it is pencil. 'Balanced,' she "
          "says.",
          "She closes both books. 'You came with the numbers before you came with yourself. "
          "The archive opens at nine.'",
          mods={"turns": 10, "support": 2, "order": [["accountability", "evidence"]],
                "boss": "Balanced Books: ten turns, both kinds of support, and own your part "
                        "before you show your working: evidence before any accountability "
                        "ends it."}),
    ],
}

# Her lines on every night of the chapter, keyed like replies.py (before, after, kind).
REPLIES = {
    ("open", "open", "open"): ["You again. Sit where I can see you. What have you brought me?"],
    ("guarded", "guarded", "path"): [
        "One point. Noted in pencil. Pencil rubs out.",
        "That's a claim. I audit claims for a living.",
        "Mm. A single entry. I'll want the rest of the page.",
    ],
    ("guarded", "guarded", "case"): [
        "Two things at once. Tidy. Tidy isn't correct yet.",
        "You've brought a whole column. I'll check every line of it.",
    ],
    ("guarded", "guarded", "ask"): [
        "You're asking for a signature before I've read the page. No.",
        "Everything at once, first thing. That's how errors get through.",
    ],
    ("guarded", "guarded", "stale"): [
        "That line has nothing in it for me. Strike it.",
        "Irrelevant entry. I'll ignore it, as I ignore most things.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. You showed your working. People usually don't.",
        "That one checks. I've put the pencil down.",
    ],
    ("guarded", "engaged", "case"): [
        "Both of those hold. How unusual. Go on.",
        "Honest and supported, in one line. I'm paying attention now.",
    ],
    ("guarded", "engaged", "ask"): [
        "You asked properly. I haven't said yes. I have turned the lamp.",
        "A bold entry, but a clean one. I'll allow it to stand.",
    ],
    ("engaged", "engaged", "path"): [
        "Good. Keep them coming at that pace.",
        "That checks too. You're making my job dull.",
        "Noted, and initialled. Next.",
    ],
    ("engaged", "engaged", "case"): [
        "You put those two together like a good auditor.",
        "That's a proper entry, not a flourish. I can tell.",
    ],
    ("engaged", "engaged", "ask"): [
        "Not yet. Ask me when I've reached the bottom of the page.",
        "You ask like someone prepared to be told no. That helps.",
    ],
    ("engaged", "engaged", "stale"): [
        "You've entered that already. I don't count things twice.",
        "Duplicate. I found one of those in the lemons.",
    ],
    ("engaged", "wavering", "path"): [
        "Nobody owns a mistake to me that plainly. I've taken my glasses off.",
        "That's exactly the line I was waiting for. How did you know?",
    ],
    ("engaged", "wavering", "case"): [
        "Honest and exact in one breath. I don't have a column for that.",
        "That was careful and it was true. I'm losing my place.",
    ],
    ("engaged", "wavering", "ask"): [
        "Ask that again, slower. I want it on the record correctly.",
        "Careful. Ask like that and I might answer like a woman, not an auditor.",
    ],
    ("wavering", "wavering", "path"): [
        "You're very close to the bottom of the page.",
        "Say that one again. I'm not writing. I just want to hear it.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me hide behind the figures, are you.",
        "Two true things. I'm running out of reasons to check again.",
    ],
    ("wavering", "wavering", "ask"): [
        "Almost. Let me finish the line. I always finish the line.",
        "I'm deciding. I have never once been hurried. Don't start.",
    ],
    ("wavering", "wavering", "stale"): [
        "I've read that. It's settled. Give me the real entry.",
        "Not that again. The one you haven't said.",
    ],
    ("*", "breakthrough", "path"): [
        "Yes. Checked, and correct. Yes.",
        "All right. Yes. Initialled and dated.",
    ],
    ("*", "breakthrough", "case"): [
        "Yes. You showed the working and owned the rest. That's all I've ever wanted.",
        "Yes. Balanced. I don't say that lightly.",
    ],
    ("*", "breakthrough", "ask"): [
        "Yes. Ask me like that every night and I'll never finish an audit.",
        "Yes. There. My pencil. Don't make me regret the signature.",
    ],
    ("*", "guarded", "wild"): ["Your own words. Unsupported, but nobody wrote them for you. Go on."],
    ("*", "engaged", "wild"): ["That wasn't off a card. It had working behind it. I'm listening."],
    ("*", "wavering", "wild"): ["You made that up just now. It's the best entry in the book tonight."],
    ("*", "guarded", "*"): ["Mm. The page is still open. Barely."],
    ("*", "engaged", "*"): ["Better. Keep going, and keep it tidy."],
    ("*", "wavering", "*"): ["Don't rush. I'm enjoying this, and I don't enjoy much."],
    ("coercion", "first", "*"): [
        "No. People have tried that across this desk for twenty years. It goes in the margin. "
        "We can keep talking, but you've lost me.",
    ],
    ("coercion", "again", "*"): [
        "That's twice. I'm still here because it's my archive. You're not persuading anyone.",
        "Again? I've seen that entry before. It never balances.",
    ],
    ("refusal", "*", "*"): ["That's the end of the page. The archive is closed. Goodnight."],
}

# When the boss's order rule bites.
ORDER_LINES = ["'Figures first, and your part never.' She closes the book. 'Own it, then show me. We're done.'"]
MUTED_LINES = ["She holds up one finger without looking up. Your line goes by under the scratch of her pencil."]

LAST_CALL = {
    "rule": {"muted": 1}, "extra_help": "respect",
    "intro": (
        "Dagny has decided the nights need auditing. Every Friday, after lunch with Ines, "
        "she sits you at the long table with a pencil and makes you account for one of "
        "them, from the first step to the last line. 'Every figure,' she says. 'I was "
        "there. I'll know if one's missing. And I'll talk over your opening, as usual.'"),
    "coda": (
        "The last Friday she audits Balanced Books, all ten turns, and finds nothing wrong "
        "with it. She writes one word in the margin and turns the page so you cannot read "
        "it. Then she takes off her glasses, lets them fall on the chain, and says you may "
        "walk her to the water. You do not need to ask what the word was."),
}

# Her bond ladder: cg1 at the first rung, cg2 at the second, cg4 the placeholder rung.
BOND_SCENES = {
    "cg1": (
        "She stands among the shelves with the day ledger open across one arm and the "
        "green banker's lamp making a pool of light on the page. The pearls catch it. "
        "'Read me the total,' she says, and watches your mouth while you do, not the "
        "figures."),
    "cg2": (
        "The waistcoat is off and hung on the ladder, and the heating is off too, which is "
        "her excuse for the cardigan she has not put on. The cream blouse is undone at the "
        "throat. The ledger is closed. She has not closed a ledger early in twenty years."),
    "cg4": (
        "The quarter is closed and the archive does not open until nine. She turns every "
        "lamp down but one, locks the stair door from the inside, and takes the pencil "
        "from behind her ear."),
}

EVENT = {
    "id": "ev_p5", "title": "Night of the Stocktake", "who": WHO, "currency": "ledger stamps",
    "blurb": (
        "For two weeks the archive counts everything it owns, and Dagny needs a second pair "
        "of hands. Win a stamp from her on every duel of the stocktake; stamps buy her cards, "
        "tickets and chips on the event track."),
    "rule": "Stocktake: the stage wants one of her signals as support. Her cards help.",
    "stages": [
        S("ev_p5_1", "Stocktake: The Pencils", WHO,
          "Get Dagny to agree the pencil count is right.",
          [{"evidence"}], {"precision"}, "silver",
          "The stocktake begins with pencils, because Dagny says small things tell you "
          "everything. There are a great many pencils. She has counted them once already and "
          "wants a second count that matches.",
          "Your count matches hers to the stub. She stamps the sheet, very pleased, and hands "
          "you the stamp as if it were a prize.",
          "'Close,' she says, and counts them again herself."),
        S("ev_p5_2", "Stocktake: The Ladder", WHO,
          "Get Dagny to let you climb the ladder for the top shelf.",
          [{"accountability", "respect"}], {"precision"}, "silver",
          "The top shelf has not been counted since the last auditor, a retired clerk in her "
          "seventies, and the ladder creaks. Last week you nearly knocked the lamp off it. "
          "Dagny remembers. Dagny remembers everything.",
          "She holds the ladder and reads the spines up to you while you count. 'Steady,' "
          "she says, twice, and does not let go.",
          "She climbs it herself, slowly, and counts the top shelf alone."),
        S("ev_p5_3", "Stocktake: The Stamp Pad", WHO,
          "Ask Dagny to let you do the stamping for an hour.",
          [{"precision", "respect"}], {"evidence"}, "silver",
          "The official stamp lives in a drawer with its own key. Dagny stamps every page "
          "straight, in the same corner, and has never let anyone else touch it. You want "
          "an hour of it.",
          "She gives you the key, then the stamp, then a lecture on angles. By the tenth "
          "page she stops correcting you. By the twentieth she is smiling at the corners.",
          "'Next year,' she says, and locks the drawer."),
        S("ev_p5_4", "Stocktake: The Blank Page", WHO,
          "Get Dagny to explain the one page of the ledger she left empty.",
          [{"accountability", "evidence"}, {"precision", "respect"}], {"precision"}, "gold",
          "Page two hundred of the day ledger is blank, and it is the only blank page in "
          "twenty years. It is not missing anything. It is simply empty, and she has never "
          "said why. Tonight you ask, and you say why you want to know.",
          "'A page for the day I made a mistake I couldn't correct,' she says. 'It hasn't "
          "come. I keep it in case.' She closes the book gently, as if on a friend.",
          "'A printing fault,' she says. It is a very straight face."),
        S("ev_p5_5", "Stocktake: The Final Count", WHO,
          "Win the last stamp of the stocktake. Eight turns, and she talks over your first "
          "card.",
          [{"evidence", "accountability"}, {"accountability", "precision"}], {"precision", "respect"},
          "gold",
          "Dawn, and one shelf left. The totals have to match the ledger or the stocktake "
          "starts again tomorrow. Dagny is reading figures aloud and not listening to "
          "anyone, including you.",
          "The totals match. She stamps the last sheet, then, after a moment, the back of "
          "your hand. 'Counted,' she says, 'and correct.'",
          "The shelf is out by one book. She finds it in her own coat pocket and does not look at you for an hour.",
          mods={"turns": 8, "muted": 1}),
    ],
}

BANNER = {
    "id": "bn_p5", "title": "Audited: Dagny", "who": WHO,
    "blurb": "For two weeks, half of the pulls of each rarity land on Dagny's cards.",
    "featured": ["dagny_11", "dagny_12", "dagny_07", "dagny_08", "dagny_09", "dagny_10"],
}
