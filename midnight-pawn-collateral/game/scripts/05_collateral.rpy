## 05_collateral.rpy — Appraisal 5: the thing you pawned.
##
## The only CG with the POV character in it and the only one the player cannot refuse. The
## Reading Ledger is shown *before* it, with its greyed slots visible, which is the design's
## stated mitigation for the hoarding failure: refusal has to feel like a decision that was
## made, not an accident that happened.

label act_collateral:
    call chapter_gate(4) from _call_chapter_gate_4
    $ tel_track("act_collateral_start", {"till": run.till})
    scene bg shop
    with dissolve

    nar "Three forty. The shop has done its last shuffle of the night, and there is one object forward in the lamp that was not there when she went down."

    ## ---- the ledger, while there is still something to spend on ----------
    nar "Before she looks at it she does the thing Elsa did at the end of a night, which is to turn to the back of the book where the readings are kept."

    call show_ledger from _call_show_ledger_pre
    $ tel_track("ledger_pre_final", {"taken": len(run.readings_taken), "refused": len(run.readings_refused), "till": run.till})

    python:
        _taken = len(run.readings_taken)
        _refused = len(run.readings_refused)

    if _refused >= 2:
        nar "Two lines with nothing after them. Three, if you count the one the drawer refused."
        nara "Those stay blank. That's allowed. That's the whole point of a column — you're allowed to not fill it in."
        nar "It does not look like a principle in the book. In the book it looks like a gap."
    elif _taken >= 3:
        nar "Every line filled, in her own hand, in the ruled section she has never used."
        nara "Well. I've had a night."
        nar "The fourth column is full and the drawer is thin and those two facts are the same fact wearing different hats."
    else:
        nar "Some of it filled in and some of it not, which is what most nights look like and is somehow the hardest version to feel anything about."

    ## ---- the object -------------------------------------------------------
    nar "And now the counter."

    nar "It is a book. Black, quarter-bound, about the size of a hand, with a strap and no lock — Elsa never trusted a lock she could not pick, on the grounds that then she could not pick it."
    nar "It is the Black Ledger. It has been on the shop's shelves as stock since before Nara was born, priced at thirty, unsold, because nobody who has ever picked it up has wanted to own it once they have opened it."

    nar "Nara has opened it twice. Once at nineteen, on the day of the funeral, when it was a list of debtors in four hands going back to 1889 and the last entry was blank."
    nar "And once at twenty-five, on a bad night, when it was the same list and the last entry had a date in it and the date was six years out."

    nar "The strap is done up. The card tucked under it is not a card. It is a pawn ticket, the shop's own, the ones Elsa had printed in 1981 and never reordered because there were nine hundred of them."

    nara "You can't pawn this. You're the shop. I'm the shop. This is —"

    shop "..."

    nar "There is a ticket under it. Filled in, in her handwriting, in pencil, which she has not done."
    nar "{i}Item: N. Quill. Holder: the premises. Terms: thirty days from the date of first reading.{/i}"
    nar "{i}Date of first reading: tonight.{/i}"

    nara "No, that's — I've been reading things for three years."
    nar "{i}First reading of this item.{/i}"

    nara "..."

    nar "She works it out standing up, which she is proud of afterwards."
    nar "The fourth column was never a cost. It was a schedule of payments. Every time she spent the shop's money to look inside something, she was not buying a view — she was making an instalment on a thing that was being bought, on terms, by the premises, from the premises."
    nar "And the thing being bought is on the counter with a strap round it."

    if run.sold_reading:
        nar "And she sold one down there for ninety pounds, which she now understands was not a sale. It was a payment {i}accelerated{/i}. Calder is not a factor because he factors debts. He is a factor because he is the reason yours comes due early."
    elif run.fees_paid > 0:
        nar "[run.fees_paid] paid in tonight, out of a drawer she thought was hers."
    else:
        nar "Nothing paid in tonight. Zero instalments. The terms are still the terms, but the balance is where it was at midnight, and for the first time in three years the shop has got nothing off her."

    nar "She thinks, for about ninety seconds, about the door."

    nar "It is a real thought and she gives it a real hearing, because she is not a character in a story about a haunted shop, she is a woman with a coat on a hook and a sister in Sheffield and forty pounds in her own pocket that is hers and not the till's."
    nar "She could walk. The estate would take the building. Somebody would buy it, and the shelves would shuffle at midnight for whoever that was, and the fourth column would open an account in a new name."

    nara "..."
    nara "And then I'd spend the rest of my life not knowing what was in it."

    nar "That is the whole of it, said out loud in an empty shop at three forty in the morning, and she hears herself say it and understands that this was never a trap. A trap requires a mechanism. This required only a woman who wanted to know things."

    nar "There is no menu here. The shop has not offered her a choice, because the shop does not have to — she has had her hand on every other object in this building all night, and this is the one that has been waiting."

    nara "Fine."
    nara "Let's see what I've been using myself for."

    ## ---- the unrefusable reading -----------------------------------------
    $ run.charge_reading("collateral")
    $ run.record_reading("collateral")
    $ unlock_cg("collateral")
    call cg_gate("collateral") from _call_cg_gate_collateral
    scene expression cg_pick("collateral") at lamp_tint
    with dissolve
    $ tel_track("reading_shown", {"item": "collateral", "dist": dist_track(), "delivered": reading_delivered("collateral")})

    nar "It is this room. It is this hour. It is now, or near enough — the reading has caught up with itself, because the last use of Nara Quill was the last four hours and there is nothing else on the reel."

    nar "She is standing where she is standing, on the customer's side of her own counter, four feet up and slightly behind, looking at her own back and her own hands."
    nar "The waistcoat is open and off one shoulder because she has been reaching across a counter all night and nobody straightens their clothes at four in the morning in an empty shop."
    nar "The monocle on its chain. Ink on three fingers. The bun that went a while ago."

    nar "And the mirror behind the counter, which she has not looked into properly in about a year, which is doing what mirrors have been doing all night in every single one of these readings."
    nar "In the glass she is looking straight out. At the vantage point. At the place where the person watching a reading stands."

    nara "..."
    nar "That is not how a reading works. Nobody in a reading has ever once looked at her."

    nar "The Nara in the mirror is not startled and is not frightened and is not apologising. She looks like someone who has been waiting at a counter for a long time and has finally been served."
    nar "Then she says four words, and readings do not carry sound, so Nara gets the shape of it and the shape is unmistakable, because it is the shape of the thing painted backwards in gold on her own window."

    nar "{i}What the dead will demand.{/i}"

    nar "And then — because a reading runs to the end of the last use and this one has not finished — the Nara in the mirror reaches out of frame, and brings her hand back with a pencil in it, and writes on a ticket."
    nar "She is left-handed in the glass, which is what a mirror does, and Nara watches her own hand form her own name backwards with the ease of somebody who has done it nine hundred times."

    nar "She writes the item. She writes the holder. She writes the terms."
    nar "And at the bottom, in the space where the broker signs to say the goods were received in good order, she writes, in the same hand, the thing that is painted on the window."

    nar "Then she puts the pencil down and looks up, and for the first time in three years of doing this to other people, Nara finds out what it is like on the other side of a reading: to be the room, and to know somebody is standing in it, and to have no way at all of telling them to get out."

    nar "The light goes."

    $ act_cleared = 5
    scene bg shop
    with dissolve
    nar "Four twelve. The Black Ledger is on the counter with the strap done up and the ticket is gone."

    $ tel_track("act_collateral_done", {"till": run.till, "taken": len(run.readings_taken)})
    jump act_dawn
