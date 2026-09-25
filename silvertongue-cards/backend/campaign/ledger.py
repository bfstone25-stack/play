"""SUASION: THE NIGHT LEDGER -- the missing pages (Blaze's mystery thread, 2026-09-24).

Seven years ago Celeste won the title in a way nobody talks about. Every house that signs
the Ledger kept one page from that night, and each woman you win over gives you hers: a
chapter's boss, won for the first time, pays out the chapter's page after its outro, and
every page ends on the question the next one answers. The six base pages tell how Celeste
won (with a sentence that was not hers). The update packs' pages follow the old holder out
of the city. The last page is about you.

What the pages are not: nobody in them is threatened, bribed or held to a secret; the
old holder conceded because she heard the right sentence, and everything after is people
keeping a promise. Persuasion stays wit and attention. Everyone named is an adult. No
religion.

Marguerite Vane, sixties: the Silver Tongue for twenty years before Celeste. Left Vell at
dawn after the Long Night seven years ago, with the Ledger's last page folded in her hand.
"""
from __future__ import annotations

# Added to the end of the prologue, so the mystery is on the table from the first screen.
PROLOGUE_HOOK = (
    "Nobody in Vell will tell you how she won it. Seven years ago, on the Long Night, the "
    "old holder put the silver pen down after one sentence and left the city at dawn. "
    "Every house that signs the Ledger kept a page from that night. Win a house, and you "
    "read its page.")

PAGES = {
    # ---- the base campaign: how Celeste won ------------------------------------------------
    "c1": {"title": "Page One: Stool Four", "text": (
        "Mara keeps her bar books under the till, one a year. She finds the one from seven "
        "years ago and opens it at the Long Night. Her handwriting was rounder then.\n\n"
        "'Closed late. Stool four: the woman in grey, crying into a stout, which she does not "
        "drink. Says she is leaving Vell in the morning. A stranger sat down next to her at "
        "one and talked to her for an hour. By two she was laughing. By half past she went "
        "up the hill to the Aurel in a hurry. Stranger paid her tab and left. Didn't get a "
        "name.'\n\n"
        "Under it, in pencil, Mara has underlined one line twice: the stranger had one bag.")},
    "c2": {"title": "Page Two: The Doorway", "text": (
        "Yuen Ha was in the ballroom that night with a sketchbook, because the Kilns paint "
        "the Long Night every year and nobody else would stay awake for it. She tears the "
        "page out and gives it to you.\n\n"
        "Charcoal. The old holder, Marguerite Vane, sixty-one, silver hair, the pen in her "
        "hand. Celeste in front of her, twenty-eight, very straight, saying something. In "
        "the next drawing the pen is on the table and Marguerite is laughing with her hand "
        "over her eyes. In the corner of both, in the doorway, somebody with one bag, "
        "watching. The face is not finished.\n\n"
        "'I couldn't get it,' Yuen Ha says. She looks at you for a long time. 'I might now.'")},
    "c3": {"title": "Page Three: Frame Twenty-Four", "text": (
        "Sanne's contact sheets are filed by year in a steel cabinet. She pulls the strip "
        "from the morning after the Long Night: she was on the Aurel steps at dawn with a "
        "long lens, as she is every year.\n\n"
        "Frame twenty-three: Marguerite Vane coming down the steps with one suitcase and a "
        "folded page in her hand, smiling like someone let off school. Frame twenty-five: "
        "the empty steps.\n\n"
        "Frame twenty-four is not there. It has been cut out of the strip, carefully, with "
        "scissors. Sanne keeps her scissors locked in the darkroom. In seven years she has "
        "lent the key to one person. 'Celeste,' she says, 'the week after she won.'")},
    "c4": {"title": "Page Four: Room 409", "text": (
        "The Aurel's night books go back ninety years. Teodora takes down the one from seven "
        "years ago before she goes and opens it at dawn after the Long Night, in her own "
        "copperplate.\n\n"
        "'6:10. Mrs Vane checks out. Pays suite nine for one year in advance, for Miss "
        "Marrow. Also pays room 409, open date, open length. Instruction: for the stranger "
        "with one bag, whenever they come back. Do not tell them who paid.'\n\n"
        "A year ago you stayed in 409 for a month and left without paying and without a "
        "word. Teodora never mentioned the bill, and tore it in half the night you owned up "
        "to it. There was never anything to pay.")},
    "c5": {"title": "Page Five: Borrowed Words", "text": (
        "Ines opens the Ledger at the Long Night seven years ago. The keeper's record is two "
        "lines in her mother's hand; Ines was twenty-seven and holding the lamp.\n\n"
        "'Conceded at 4:40, after one sentence. The challenger's words were not her own; "
        "she said so, to the holder, before anyone else could. The holder accepted them for "
        "the one who first said them, and asked the keeper to record the title as held in "
        "trust.'\n\n"
        "Held in trust. For whom, it does not say. The page after it, the last page of that "
        "year, has been torn out. 'Celeste has it,' Ines says. 'Everyone thinks so. Ask her.'")},
    "c6": {"title": "Page Six: What Celeste Said", "text": (
        "At sunrise, on the balcony of suite nine, Celeste tells you herself.\n\n"
        "'I was leaving. I'd lost everything I came to Vell to win, and I was on stool four "
        "feeling sorry for myself, and a stranger sat down and said one sentence: nobody "
        "wants a door opened for them; they want somebody to knock.' She smiles. 'I went up the hill and said it to Marguerite, and told her it wasn't mine. "
        "She put the pen down. I've been keeping the seat warm ever since.'\n\n"
        "'I kept the photograph Sanne took of the doorway. I never had the last page. "
        "Marguerite took it with her. But she left a trail.' She "
        "hands you a folded list: the second page of the Ledger. 'Every house on it saw her "
        "go.'")},
    # ---- the update packs: where Marguerite went, and who the stranger was --------------------
    "p1": {"title": "Page Seven: The Request", "text": (
        "Odile finds the tape without being asked: The Small Hours, the Long Night, seven "
        "years ago. At twenty past two the request line rings.\n\n"
        "'Small Hours, you're on.' Traffic noise, the Low Tide's jukebox, and then a voice: "
        "'Could you play something for the woman in grey on stool four? She's staying. She "
        "doesn't know it yet.' Odile, younger, laughing: 'And who's asking?' A pause. "
        "'Nobody. I'm catching a train.'\n\n"
        "Odile stops the tape. She does not rewind it. 'I know that voice now,' she says. "
        "'I've been listening to it for a month.'")},
    "p2": {"title": "Page Eight: The Pilot Log", "text": (
        "The pilot log for the morning after the Long Night is in Hedda's first senior's "
        "square hand.\n\n"
        "'06:40. Pilot boat to the outbound freighter at the bar. One passenger, a woman in "
        "her sixties, one suitcase. Would not give her name. Asked me to take a message to "
        "the station, to be given to "
        "whoever came asking: Tell the one with one bag it was the right sentence. I have "
        "the page. Come and find me when you're ready to read it.'\n\n"
        "Hedda closes the log. 'Nobody came asking,' she says. 'Seven years. Until you.' The "
        "freighter's next port is written in the margin, and it is only across the bay.")},
    "p3": {"title": "Page Nine: One for Later", "text": (
        "Roz keeps her orders on a spike, and the old spikes in a biscuit tin. Marguerite "
        "Vane ate at the stall every Thursday for twenty years; Roz knows her order by heart.\n\n"
        "The last slip is from that dawn: two bowls, one to take away. 'One for later,' "
        "Marguerite said. 'For somebody who'll be hungry when they come back.' Under the "
        "slips are letters, one a year, with no return address, all in the same slanted "
        "hand, all asking Roz the same thing: has the one with one bag come back yet?\n\n"
        "The last letter came eleven months ago. The week you left Vell.")},
    "p4": {"title": "Page Ten: Berth Seven", "text": (
        "Mireille keeps the Owl's manifests in her locker, because nobody else checks them. "
        "Eleven months ago. Car four.\n\n"
        "'Berth six: one passenger, one bag, no luggage label, asleep by midnight. Berth "
        "seven: a woman in her sixties, silver hair, travelling alone. The two of them "
        "talked in the corridor until two. She got off at the halt before the coast, where "
        "the train does not usually stop. She asked me to. Left in berth seven: a silver "
        "pen.'\n\n"
        "Mireille gives it to you. It is warm from her pocket. The clip is engraved: M.V. "
        "You remember the corridor. You never asked her name.")},
    "p5": {"title": "Page Eleven: Fare Paid", "text": (
        "Dagny finds it in the day ledger in under a minute, because she filed it. The "
        "harbour authority records every ferry fare paid in advance.\n\n"
        "'Last Crossing, open return, one passenger with one bag. Paid seven years ago, "
        "cash, by M. Vane. Honoured this year, on the night of the ninth.' The ninth is the "
        "night you came back to Vell.\n\n"
        "'Somebody bought your ticket home seven years before you needed it,' Dagny says. "
        "'And the same somebody has paid a berth at Bay Pier every month since. The boat is "
        "small. It never leaves.' She takes her glasses off. 'Go and look.'")},
    "p6": {"title": "The Last Page", "text": (
        "Vesna gives it to you at the far pier, from inside her cap: a page of green cloth "
        "paper, torn along the stitching, folded in four. 'She gave it to me the first night "
        "she rode with me,' Vesna says. 'She said you'd come the long way round.'\n\n"
        "The Night Ledger. The Long Night, seven years ago. In Marguerite Vane's hand: "
        "'The Silver Tongue of Vell is the one who said it first: nobody wants a door opened; "
        "they want somebody to knock. They had one bag and a train to catch. When they come "
        "back, the page is theirs. Celeste will keep it warm.' Under it there is room for "
        "one more line, and it has been left blank for seven years.\n\n"
        "The last page was always about you. On the far pier, under the lamp, a woman in "
        "her sixties is waiting, with her hands in her coat, as if she has all the time in "
        "the world.")},
}

ORDER = ["c1", "c2", "c3", "c4", "c5", "c6", "p1", "p2", "p3", "p4", "p5", "p6"]


def audit() -> list[str]:
    probs = []
    banned = ("god", "church", "pray", "heaven", "hell ", "saint", "sin ", "confess", "bless",
              "blackmail", "or else", "your job", "leverage", "threat", "bribe")
    for cid in ORDER:
        pg = PAGES.get(cid)
        if not pg or not pg.get("title") or not pg.get("text"):
            probs.append(f"ledger page {cid} missing")
            continue
        words = len(pg["text"].split())
        if not 70 <= words <= 190:
            probs.append(f"ledger page {cid}: {words} words")
        for w in banned:
            if f" {w}" in f" {pg['text'].lower()} ":
                probs.append(f"ledger page {cid}: banned word {w!r}")
    return probs
