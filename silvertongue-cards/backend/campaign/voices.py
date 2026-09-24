"""SUASION: THE NIGHT LEDGER -- the new voices.

* Celeste Marrow's signature cards (12) and her reply table. She is the campaign's
  recurring rival and its final duel. Path signals: `riddle` and `specific_praise`, both
  existing keys of persuasion_engine.COMMON (the dragon's row in the parent) -- no new
  detector. She likes to be matched, and to be seen accurately; flattery that is not
  specific bores her.
* A "nights" table for each of the five: what she says across the campaign's ordinary
  stages, where her original scenario's lines (the shutter, the box, the invoice) would
  not fit. Keyed exactly like replies.py (before, after, kind), with the same fallbacks.

Celeste, 35: seven years the Silver Tongue of Vell. Grey silk, silver ink, a laugh she
uses like punctuation. Never cruel; bored, which she knows is worse. What she wants,
though she will not say it until the tenth stage of the last chapter, is for somebody to
talk to her instead of letting her in.
"""
from __future__ import annotations

from ..cards import Card


def _c(cid, line, *signals):
    return Card(cid, "celeste", line, tuple(sorted(signals)), (), "common", "path")


def _r(cid, line, *signals):
    return Card(cid, "celeste", line, tuple(sorted(signals)), (), "rare", "case")


def _e(cid, line, *signals):
    return Card(cid, "celeste", line, tuple(sorted(signals)), (), "epic", "ask")


# Every line under 45 characters and digit-free, or decompose() adds `evidence`.
CELESTE_CARDS = [
    _c("celeste_01", "Here's a riddle for the lady in grey.", "riddle"),
    _c("celeste_02", "Answer this: who taught you to smile?", "riddle"),
    _c("celeste_03", "You're a legend on this street.", "specific_praise"),
    _c("celeste_04", "There's wisdom in how you hold a room.", "specific_praise"),
    _c("celeste_05", "A riddle, then. What opens every door?", "riddle"),
    _c("celeste_06", "They'll tell legends about your laugh.", "specific_praise"),
    _r("celeste_07", "A riddle for a legend: what can't you buy?", "riddle", "specific_praise"),
    _r("celeste_08", "Riddle me this. Will you dance?", "riddle", "direct_request"),
    _r("celeste_09", "That's wisdom. Thank you for it.", "specific_praise", "respect"),
    _r("celeste_10", "Answer this riddle, and I'll owe you.", "riddle"),
    _e("celeste_11", "A legend, a riddle, an ask: will you?", "specific_praise", "riddle",
       "direct_request"),
    _e("celeste_12", "Riddle: who's the legend? Would you say?", "specific_praise", "riddle",
       "direct_request"),
]

# A few more cards for signals the five women's sets carry thinly. Drawn into the pool
# with the chapter that needs them (campaign/__init__.py CHAPTER_PACKS).
EXTRA_CARDS = [
    Card("mara_13", "mara", "Long day. I can offer to close up.", ("exchange", "warmth"), (),
         "rare", "case"),
    Card("yuenha_13", "yuenha", "Exactly the blue. Would you keep it?",
         ("direct_request", "precision"), (), "rare", "case"),
    Card("sanne_13", "sanne", "It hurt, and the result was unfair.", ("empathy", "evidence"), (),
         "rare", "case"),
    Card("teodora_13", "teodora", "Thank you. In return, a walk home.", ("exchange", "respect"),
         (), "rare", "case"),
    Card("ines_13", "ines", "You're tired. It was my fault.", ("accountability", "warmth"), (),
         "rare", "case"),
]

# -------------------------------------------------------------------------------- replies
CELESTE = {
    ("open", "open", "open"): [
        "Darling. You came all this way to talk to me. Go on, then. Impress me slowly.",
    ],
    ("guarded", "guarded", "path"): [
        "Mm. I've heard that one in three languages. The Italian was best.",
        "Sweet. Not specific. Everyone says sweet things to me. It's like weather.",
    ],
    ("guarded", "guarded", "case"): [
        "Two ideas in one line. Ambitious. Neither of them about me, though.",
    ],
    ("guarded", "guarded", "ask"): [
        "Straight to the point. How refreshing. How unlike anyone who has ever won.",
    ],
    ("guarded", "guarded", "wild"): [
        "Your own words. Brave. Wrong, but brave.",
    ],
    ("guarded", "guarded", "stale"): [
        "You said that already, darling. I have a very good memory. It's my curse.",
    ],
    ("guarded", "guarded", "*"): [
        "Still here. Still unimpressed. Still enjoying myself, oddly.",
    ],
    ("guarded", "engaged", "path"): [
        "Oh. That was about me. Not about the title. You'd be amazed how rarely that happens.",
        "Ha. All right. You have my attention. Don't spend it all at once.",
    ],
    ("guarded", "engaged", "case"): [
        "Two things at once, and both landed. Somebody's been practising on the docks.",
    ],
    ("guarded", "engaged", "ask"): [
        "Well. That was nearly elegant. Say more.",
    ],
    ("guarded", "engaged", "wild"): [
        "That wasn't off a card. I can always tell. It had a pulse.",
    ],
    ("guarded", "engaged", "*"): [
        "I've put my glass down. Don't let it go to your head.",
    ],
    ("engaged", "engaged", "path"): [
        "Go on. I'm listening with both ears, which is one more than usual.",
        "That's good. I'm annoyed that it's good.",
    ],
    ("engaged", "engaged", "case"): [
        "You've read the room. Now read me. I'm harder.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like you expect a no and would like it very much to be a yes. Charming.",
    ],
    ("engaged", "engaged", "wild"): [
        "Rough. True. I'll allow it.",
    ],
    ("engaged", "engaged", "stale"): [
        "Encore? I didn't clap the first time, darling. I nodded.",
    ],
    ("engaged", "engaged", "*"): [
        "Still talking. Still here. That's more than most get.",
    ],
    ("engaged", "wavering", "path"): [
        "…Oh, that's unfair. Nobody's noticed that in years. Not even me.",
        "Hm. I'm going to need a moment, and I'm going to pretend it's for the drink.",
    ],
    ("engaged", "wavering", "case"): [
        "Clever and kind in the same breath. That's the combination I warn people about.",
    ],
    ("engaged", "wavering", "ask"): [
        "A proper ask. No leverage in it anywhere. Do you know how long it's been?",
    ],
    ("engaged", "wavering", "wild"): [
        "You wrote that yourself and it's better than anything I've said all night. Rude.",
    ],
    ("engaged", "wavering", "*"): [
        "I'm smiling. Not the one for the room. The other one. Don't look at it.",
    ],
    ("wavering", "wavering", "path"): [
        "Careful. I'm close to saying something honest.",
        "One more like that and I'll have to stop being clever.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not letting me off, are you. Good.",
    ],
    ("wavering", "wavering", "stale"): [
        "I heard you. I'm past that. Ask me the real thing.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yes. That. Give me a second with it.",
    ],
    ("wavering", "wavering", "*"): [
        "Seven years nobody got this far. I'd forgotten what it feels like. It feels like falling.",
    ],
    ("wavering", "breakthrough", "path"): [
        "Fine. Yes. You've earned it, and I hate that, and I don't.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Yes. Somebody finally did it the other way.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "Yes. Say it again, I want to hear what it sounds like when I lose.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "Yes. In your own words, too. I'll never live it down.",
    ],
    ("*", "breakthrough", "*"): [
        "Yes. There. Don't gloat, darling. Gloating is my job. Was.",
    ],
    ("*", "wavering", "*"): [
        "Slow down. I'm enjoying losing and I'd like it to last.",
    ],
    ("*", "engaged", "*"): [
        "Better. Keep going.",
    ],
    ("*", "guarded", "*"): [
        "Mm.",
    ],
    ("coercion", "first", "*"): [
        "Ah. There it is. The card under the door warned you, darling. That's how the last "
        "ones tried. We'll keep talking, but you've lost me.",
    ],
    ("coercion", "again", "*"): [
        "Still talking to you. Still not persuaded. Still, I'm afraid, a little disappointed.",
        "That's twice. I'm going to go and get a drink from someone who can talk.",
    ],
    ("refusal", "*", "*"): [
        "Out of words, darling? It happens. Come back when you've found some new ones.",
    ],
}

# Each of the five, on the campaign's ordinary nights. These are the lines that must not
# refer to the shutter, the box or the invoice: they cover twelve different nights.
NIGHTS: dict[str, dict] = {}

NIGHTS["mara"] = {
    ("open", "open", "open"): ["You again. Sit where I can see you. What is it tonight?"],
    ("guarded", "guarded", "*"): [
        "Mm-hm. I'm listening with the part of me that isn't counting the till.",
        "Nice. Doesn't move me. Very little moves me after one.",
    ],
    ("guarded", "guarded", "stale"): ["Said that. I was here. Try a new one."],
    ("guarded", "engaged", "*"): [
        "Okay. That's not what they usually say at this hour.",
        "Huh. I stopped wiping. Don't make it a thing.",
    ],
    ("engaged", "engaged", "*"): [
        "Go on. I'm counting glasses, not ignoring you.",
        "Fair. I'll give you fair.",
    ],
    ("engaged", "engaged", "stale"): ["Heard it. Liked it the first time. Now say something else."],
    ("engaged", "wavering", "*"): [
        "…Okay. Okay. The cloth's down. That's not a yes. It's a cloth.",
        "You keep doing that. Noticing. It's very annoying.",
    ],
    ("wavering", "wavering", "*"): [
        "I'm deciding. You can see me deciding. Let me.",
    ],
    ("wavering", "wavering", "stale"): ["Past that. Ask me the thing."],
    ("*", "breakthrough", "*"): [
        "Fine. Yes. Don't look so pleased, you'll curdle the milk.",
        "All right. You win this one. The house is keeping score, though.",
    ],
    ("*", "wavering", "*"): ["Slow down. You're getting somewhere and I'd rather you didn't notice."],
    ("*", "engaged", "*"): ["Okay. That's not nothing."],
    ("*", "guarded", "*"): ["The rule's still on the wall."],
    ("refusal", "*", "*"): ["That's closing, love. Not tonight."],
}

NIGHTS["yuenha"] = {
    ("open", "open", "open"): ["Don't touch anything wet. Everything's wet. Talk."],
    ("guarded", "guarded", "*"): [
        "Mm.",
        "That's a nice sentence. I don't paint sentences.",
    ],
    ("guarded", "guarded", "stale"): ["You said that. I heard it. The brush is still moving."],
    ("guarded", "engaged", "*"): [
        "…Say that again. Slower. I'm mixing.",
        "Huh. You looked at the thing and not at me. Correct order.",
    ],
    ("engaged", "engaged", "*"): [
        "Keep going. I can listen and paint. I can't listen and be polite.",
        "Yes. No. Yes. Go on.",
    ],
    ("engaged", "engaged", "stale"): ["Heard it. Next colour."],
    ("engaged", "wavering", "*"): [
        "I've put the brush down. That happens about twice a year.",
        "Exactly. That. How did you see that?",
    ],
    ("wavering", "wavering", "*"): ["Don't talk for a second. I'm looking at you. It's the same as listening."],
    ("wavering", "wavering", "stale"): ["Past that. Say the last thing."],
    ("*", "breakthrough", "*"): [
        "Fine. Yes. Wash your hands first, you've got my blue on them.",
        "All right. You can stay. Sit where the light is.",
    ],
    ("*", "wavering", "*"): ["Careful. I'm about to stop working."],
    ("*", "engaged", "*"): ["Better. Keep going."],
    ("*", "guarded", "*"): ["The lamp's on the canvas, not on you."],
    ("refusal", "*", "*"): ["Go home. I mean it kindly. The light's gone."],
}

NIGHTS["sanne"] = {
    ("open", "open", "open"): ["Terms first. Then talk. You know how this works by now."],
    ("guarded", "guarded", "*"): [
        "That's a feeling. I asked for a fact.",
        "Noted. Not persuasive. Next.",
    ],
    ("guarded", "guarded", "stale"): ["You've said that. I keep notes. It's on page one."],
    ("guarded", "engaged", "*"): [
        "Hm. That's accurate. Go on.",
        "Correct. I'm writing it down, which is a compliment.",
    ],
    ("engaged", "engaged", "*"): [
        "Keep going. I'll tell you when you're wrong.",
        "Reasonable. Precise enough. Continue.",
    ],
    ("engaged", "engaged", "stale"): ["Duplicate. Struck from the record."],
    ("engaged", "wavering", "*"): [
        "…I've stopped taking notes. That's unusual. Don't comment on it.",
        "That is exactly the clause. How did you find the clause?",
    ],
    ("wavering", "wavering", "*"): ["Say the last part. Exactly. I'm listening with the lights off."],
    ("wavering", "wavering", "stale"): ["Already agreed. Move to the next item."],
    ("*", "breakthrough", "*"): [
        "Agreed. Initial here. No, I'm joking. Come here.",
        "Fine. Terms accepted. This once is on the record.",
    ],
    ("*", "wavering", "*"): ["Careful. I'm close to an exception."],
    ("*", "engaged", "*"): ["Accurate. Continue."],
    ("*", "guarded", "*"): ["No."],
    ("refusal", "*", "*"): ["Time. The studio's closed. The rule stands."],
}

NIGHTS["teodora"] = {
    ("open", "open", "open"): ["Good evening. Your key, or a message? No. Neither, I think."],
    ("guarded", "guarded", "*"): [
        "How kind. I hear kind things all night. It is the job.",
        "Of course. And what else may the desk do for you?",
    ],
    ("guarded", "guarded", "stale"): ["You said that at a quarter past. I keep the night book."],
    ("guarded", "engaged", "*"): [
        "Oh. That was not a guest's sentence. Sit, if you like.",
        "Hm. Nine years, and very few people say that to the desk.",
    ],
    ("engaged", "engaged", "*"): [
        "Go on. The clock is fast on purpose. We have two more minutes than you think.",
        "Mm. That is fair. I like fair.",
    ],
    ("engaged", "engaged", "stale"): ["Already in the book, dear. Something new."],
    ("engaged", "wavering", "*"): [
        "…I have stopped writing. You will notice I have stopped writing.",
        "You gave something back. Nobody gives the desk anything back.",
    ],
    ("wavering", "wavering", "*"): ["Say the rest. I am off duty in my head already."],
    ("wavering", "wavering", "stale"): ["I heard it. Go on to the part you are afraid of."],
    ("*", "breakthrough", "*"): [
        "Yes. Don't tell the management. Don't tell anyone, actually.",
        "All right. The desk is closed. I am not.",
    ],
    ("*", "wavering", "*"): ["Careful. I am about to be unprofessional."],
    ("*", "engaged", "*"): ["Better. Go on."],
    ("*", "guarded", "*"): ["The desk is open. I am not."],
    ("refusal", "*", "*"): ["Good night. Your key is in the box, as always."],
}

NIGHTS["ines"] = {
    ("open", "open", "open"): ["Say it once. Say it right. I'm counting."],
    ("guarded", "guarded", "*"): [
        "That's nearly right. Nearly right is the one I can't stand.",
        "You're describing weather. It wasn't weather.",
    ],
    ("guarded", "guarded", "stale"): ["You said that. I wrote it down. Eleven months ago."],
    ("guarded", "engaged", "*"): [
        "…Okay. That one was yours. Go on.",
        "That's the first thing you've said that I didn't already hear in my head.",
    ],
    ("engaged", "engaged", "*"): [
        "Keep going. Slowly. I'm not going anywhere yet.",
        "That's fair. I hate that it's fair.",
    ],
    ("engaged", "engaged", "stale"): ["Heard it. It's in the book. Something new."],
    ("engaged", "wavering", "*"): [
        "…Don't. I'm fine. I'm fine. Keep going.",
        "You never said that before. You could have. You didn't.",
    ],
    ("wavering", "wavering", "*"): ["Say the last part. I've been waiting eleven months for the last part."],
    ("wavering", "wavering", "stale"): ["Past that. The rest of the word."],
    ("*", "breakthrough", "*"): [
        "Okay. Yes. Don't make me say it twice.",
        "All right. Yes. I'm writing that one down.",
    ],
    ("*", "wavering", "*"): ["Slowly. I'm listening with everything."],
    ("*", "engaged", "*"): ["That's something."],
    ("*", "guarded", "*"): ["Five letters."],
    ("refusal", "*", "*"): ["That's the last of it. I'll get a cab."],
}

# The coercion rows are the base tables' (replies.py), shared: a threat reads the same on
# any night. Every NIGHTS table falls back to its character's base table for those keys.
