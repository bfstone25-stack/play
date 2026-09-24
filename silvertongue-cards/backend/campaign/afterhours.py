"""SUASION: THE NIGHT LEDGER -- after the story: Last Call, and the bond scenes.

LAST CALL. When a chapter's boss falls, the chapter opens again as Last Call: the same
twelve nights, remembered from the other side of the signature, harder. Every stage is at
the engine's gold rank, wants one more kind of support, carries the chapter's Last Call
rule, and her resolve is half again as high. The words of the nights are the story's
(they are the same nights); what is new is the frame below, which the player reads once,
and the coda, read when the whole Last Call is cleared.

BOND SCENES. Each woman's bond ladder (wins against her) unlocks her CGs; each rung also
unlocks a short scene -- the after-hours moment the plate is a picture of. They are the
reward for the replays, and they are written to be read beside the plate.

Same house rules as story_a.py.
"""
from __future__ import annotations

LAST_CALL = {
    "c1": {
        "rule": {"muted": 1}, "extra_help": "empathy",
        "intro": (
            "Mara keeps a second book under the till, a school exercise book with a harbour on "
            "the cover. In it, in pencil, every night she ever thought about breaking the rule. "
            "'You're in here a lot,' she says, and slides it across. 'Go on. Tell me how those "
            "nights really went. I'll know if you're lying. I was there.'"),
        "coda": (
            "She reads the last page back to you, the night of the jukebox, and laughs in the "
            "wrong place, and then does not laugh at all. 'I wrote down that you were trouble,' "
            "she says. 'Look. There. I underlined it twice.' She tears the page out and gives it "
            "to you. The rest of the book goes back under the till, where the rule can't see it."),
    },
    "c2": {
        "rule": {"hand": 2}, "extra_help": "warmth",
        "intro": (
            "Yuen Ha has started a new canvas: the Kilns at night, every window lit, and in "
            "each window a small scene she will not explain. 'I'm painting the nights you came "
            "up the stairs,' she says. 'I've got them wrong. Tell me them again. Properly. I "
            "need the colours.'"),
        "coda": (
            "Twelve windows, twelve nights, all of them right now. In the last window, very "
            "small, two people and a worklamp switched off. She signs the canvas at the bottom, "
            "then, after a moment, hands you the brush. 'Both names,' she says. 'It's that "
            "kind of painting.'"),
    },
    "c3": {
        "rule": {"stale_cost": 2}, "extra_help": "respect",
        "intro": (
            "Sanne is making a contact sheet of the whole year: every frame she shot after "
            "midnight, in order, six to a strip. Some of them have you in the corner. 'The "
            "record's incomplete,' she says, handing you the loupe. 'Walk me through them. "
            "Accurately. I'll know if you round up.'"),
        "coda": (
            "The contact sheet is complete. She marks one frame in red, the one of the studio "
            "lights going off, and prints it at the size of a door. It goes on the wall where "
            "the rule used to be. The rule is in a drawer now. It is still, she says, in force."),
    },
    "c4": {
        "rule": {"steal_every": 4}, "extra_help": "respect",
        "intro": (
            "A parcel arrives at the Aurel with a foreign stamp: Teodora's night book, the last "
            "volume, posted from wherever she went. A note in copperplate: 'Read it to the night "
            "porter. He needs to know how it is done.' He sits you down at the desk. 'From the "
            "beginning,' he says. 'Slowly.'"),
        "coda": (
            "The porter closes the book and puts his hand flat on the cover, exactly the way she "
            "did. 'Nine years,' he says, 'and I only ever saw the front of it.' He writes one line "
            "in the new book, his first, and turns it round for you to read: kind to the night "
            "desk. Then he pins the crossed keys she left him to his lapel."),
    },
    "c5": {
        "rule": {"muted": 1}, "extra_help": "warmth",
        "intro": (
            "The box in the hall is open. Ines has taken everything out and laid it along the "
            "floor, one object for every week you lived together. 'I'm deciding what to keep,' "
            "she says. 'You're going to help. Tell me what each one was. If you remember wrong, "
            "it goes in the bin.'"),
        "coda": (
            "Nothing goes in the bin. She puts every object back in the box, one at a time, in "
            "the order you remembered them, and then carries the box into the bedroom and puts "
            "it at the bottom of the wardrobe, which is where people keep the things they are "
            "not leaving with."),
    },
    "c6": {
        "rule": {"muted": 1, "hand": 2}, "extra_help": "exchange",
        "intro": (
            "A year after the Long Night, a card under your door. Heavy stock, silver ink. "
            "'Rematch. Same ballroom. Every round, again, and this time I have had a year to "
            "practise. -- C.' Under it, smaller: 'Bring the others. I want an audience.'"),
        "coda": (
            "She concedes again, at a quarter to five, and this time she does not laugh. She "
            "kisses you on the stairs in front of the entire after-hours city, which applauds, "
            "and then says, 'Same time next year,' and means it, and you both know that you "
            "will both be there."),
    },
}

# Her bond ladder: rung -> the scene that comes with the plate. Keys follow the ladder in
# the server config (cg1 at the first rung, cg2 at the second, cg4 the placeholder rung:
# Blaze's own scene, text only until then).
BOND_SCENES = {
    "mara": {
        "cg1": (
            "After close, the chairs are up and the till is counted and she is leaning on the "
            "bar with both hands flat, sleeves rolled, deciding whether to tell you something. "
            "'The compass,' she says, turning her arm so you can see the tattoo. 'It points "
            "the wrong way. The artist was drunk. I kept it. Some things you keep.'"),
        "cg2": (
            "She has taken the apron off, which she never does before the shutter is fully "
            "down. The shirt is open at the collar. She pours without looking, two fingers "
            "each, the good bottle. 'Don't read into it,' she says. 'It's hot back here.' It is "
            "not hot. You do not read into it. You both know exactly what it means."),
        "cg4": (
            "The rule is still on the wall. She takes it down, reads it once more, and puts it "
            "face down on the bar. 'Just for tonight,' she says. 'Tomorrow it goes back up.' "
            "It does go back up. It just goes up a little crooked, and she never straightens it."),
    },
    "yuenha": {
        "cg1": (
            "She paints with her hand pressed flat on the canvas to steady it, the brush in "
            "the other hand, and she has let you watch for an hour without saying anything. "
            "'You breathe too loudly,' she says finally. 'Keep doing it. It's a good tempo.'"),
        "cg2": (
            "The shirt is open because of the heat from the lamp, she says, and her glasses are "
            "off because they fog, she says, and the palette is in her lap because there is "
            "nowhere else to put it. She looks at you the way she looks at the left third: as "
            "if you are nearly right, and she is going to fix it."),
        "cg4": (
            "She draws you by the worklamp until four, and then she turns the lamp around so it "
            "points at her. 'Your turn,' she says. 'Look properly. Not lovely. True.'"),
    },
    "sanne": {
        "cg1": (
            "She shoots you once, without asking, and then looks at the back of the camera with "
            "one eyebrow up. 'You blink on the count of three,' she says. 'Everyone does. I'll "
            "count to two.' She counts to two. It is the best photograph of you that exists."),
        "cg2": (
            "The jumpsuit is down around her waist because the studio is too warm, and the "
            "camera strap is still round her neck because she never takes it off, and she is "
            "not looking at you, which from Sanne is the loudest thing a person can do."),
        "cg4": (
            "Clause twelve. She fills it in at last, in the invoice pen: 'Exceptions: one.' She "
            "does not write the name. She hands you the pen to initial it."),
    },
    "teodora": {
        "cg1": (
            "The keys in her fist, the other hand flat on the night book, buttoned to the throat "
            "at two in the morning. 'Nine years I have handed people keys,' she says. 'Nobody "
            "ever asked for mine.' She does not hand them over. She does not put them away."),
        "cg2": (
            "Her hair is down. She has undone the top of the uniform, just the collar, just the "
            "first two buttons, with her eyes closed, the way you take off shoes after a long "
            "shift. 'Don't tell the management,' she says, without opening her eyes. 'Tell me "
            "something instead.'"),
        "cg4": (
            "A postcard, months later, from a city you have never been to: a hotel lobby, a "
            "desk, a woman who is not her at it. On the back, copperplate: 'I am a guest. It is "
            "unbearable. I love it. Which floor would you like?'"),
    },
    "ines": {
        "cg1": (
            "She stands in the doorway with the cardigan pulled shut and the box at her feet and "
            "her hand on the frame, exactly where she stood the night you left. 'I practised "
            "this,' she says. 'Standing here. So it wouldn't be the last time I stood here.'"),
        "cg2": (
            "On the floor of the hall, back against the wall, the cardigan off one shoulder. She "
            "is holding her own wrist, the way she does when she is making herself stay. 'Sit,' "
            "she says. You sit. It is a very small hall. That is, you both realise, the point."),
        "cg4": (
            "The Ledger, the keeper's line beside your name, in her small upright hand: DOES NOT "
            "STAY. YET. She crosses out the first three words and leaves the last one, which is "
            "the only word she was ever really writing."),
    },
    "celeste": {
        "cg1": (
            "At the top of the ballroom stairs, one hand on the banister, the silver pen between "
            "two fingers like a cigarette she gave up years ago. 'Everyone looks at the pen,' "
            "she says. 'You're looking at me. That's either very clever or very stupid.'"),
        "cg2": (
            "Dawn on the east balcony of suite nine, the jacket off her shoulders, the harbour "
            "going pink behind her. 'Seven years I watched this alone,' she says. 'It's much "
            "better with someone to be rude to about it.'"),
        "cg4": (
            "She tells you her real name, the one before Celeste Marrow, which nobody in Vell "
            "knows. It is very ordinary. She makes you promise never to use it, and then, much "
            "later that night, asks you to."),
    },
}
