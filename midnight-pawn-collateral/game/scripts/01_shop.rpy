## 01_shop.rpy — Cold open and Appraisal 1: Tamsin Bell, the finial. Free on every track.

label start:
    call tel_boot from _call_tel_boot_mpc
    $ tel_track("game_start", {"build": config.version})
    $ new_run()
    scene bg black
    with fade
    play music theme fadein 2.0
    play ambience dust fadein 2.0

    nar "There are two prices on everything. What the living will offer, and what the dead will demand. Elsa Quill had that painted on the window in 1961 and it is still there, backwards, in gold, shedding a little more of itself every winter."
    nar "Nara has run the shop under it for three years."

    scene bg shop
    with dissolve

    nar "Eleven fifty-eight. The rain has been going since four and has settled into the kind that does not fall so much as stand in the air and wait."
    nar "She is closing out. Four columns, a stub of pencil, a drawer with two hundred and sixty in it, and a debt against the estate of two hundred that comes due tomorrow, which is a word that at this hour means in about six hours."

    nara "Two-sixty in. Two hundred out. Sixty to live on and a shop full of other people's decisions."

    nar "The shop restocks itself at midnight. Not metaphorically. She has stopped finding it remarkable, the way you stop hearing a fridge."
    nar "At 12:00 exactly, the shelves shuffle. A thing that has sat unclaimed for a decade goes quiet and dark and slides back, and a thing that somebody in this city is about to need a price for comes forward into the lamp."

    $ tel_track("cold_open")

    nar "She has never once caught it happening. She has watched the second hand for twenty minutes straight and it happens anyway, in the part of the minute where she blinked."

    shop "..."

    nar "And her hands. That is the other thing."
    nar "Put a palm flat on an object and it gives up the last thing it was used for. Not the history — the last use. The most recent hour that mattered to it."
    nar "Most nights that is a kettle. A coat on a hook. Somebody signing away a car in a kitchen with the radio on. Elsa called it the trade's one advantage and warned her it was not free."

    nara "It is not free. It costs the shop."

    nar "She has never got a straight answer about why. The reading takes money out of the drawer the way a lamp takes oil, and if the drawer is empty the object stays a lump of brass."
    nar "Elsa's theory was that you are paying for the attention of whatever files these things. Nara's theory is that it is a business and she is a customer."

    ## ---- teach the loop ---------------------------------------------------
    nar "The rules, because tonight is going to test all three."
    nar "Appraise. Read, or don't. Then price it — LOW, FAIR, or HIGH — and they either take the ticket or they don't."
    nar "Lowball a stranger and you are ahead by a few. Lowball someone whose worst hour you have just watched from the inside and you are a different kind of thing."

    nar "12:00. The lamp gutters and comes back."
    nar "There is a woman at the glass."

    $ act_cleared = 0
    jump act_finial


## ---------------------------------------------------------------------------
label act_finial:
    $ tel_track("act_finial_start")
    nar "She has come through the rain without a coat and she is not shivering, which usually means somebody has been sitting in a car in a car park deciding for a while."
    nar "Mid-thirties. Auburn, cut blunt at the jaw. Freckles right across the shoulders where the wet blouse has given up. She is holding something in both hands the way you hold a mug."

    show bg shop
    tam "Do you buy brass?"
    nara "I buy anything I can price."

    nar "She puts it on the counter. It is a finial — the knob off the corner post of a bed frame. Turned brass, about the size of a pear, with a flattened seam down one side where it was cast."
    nar "There are four of them on a bed. There is one of them here."

    nara "Where are the other three?"
    tam "On the bed."
    nara "And the bed?"
    tam "In the flat. For another two days."

    nar "She says it evenly. It is a sentence she has clearly said to a letting agent, twice, and got better at."

    nar "She makes a small circle with one hand, taking in the counter, the shop, the hour."
    tam "Tamsin Bell. I'm not being coy. I just don't want to do the whole thing where you ask and I explain and you say you're sorry."
    nara "I wasn't going to say I'm sorry."
    tam "No. You were going to say twelve."

    nar "Nara laughs before she decides whether to, which does not happen often."

    nara "I was going to say fourteen and let you get me to eighteen."
    tam "See, that's worse."

    nar "The thread inside the finial is bright. Scored, actually — the bright of metal that has been turned against a tool that slipped, recently, in a hurry, by somebody who did not have the right spanner and used a table knife."
    nar "You do not unscrew one finial off a bed slowly."

    $ tel_track("choice_read_shown", {"item": "finial"})

    menu:
        "You could put a hand on it."

        "Put a hand on it. (the shop is not charging for this one)":
            nar "This one is free, which she has learned means the shop wants her to see it. That is not a comfort."
            call reading_offer("finial") from _call_reading_finial
            jump finial_after_reading

        "Leave it. Price the brass and let her go home.":
            $ run.record_refusal("finial")
            $ tel_track("reading_declined", {"item": "finial", "why": "chose"})
            nar "She turns it over with the backs of her fingers. Brass is brass. Twenty-two of anything, no story attached."
            nara "It's a nice casting. Somebody paid for that bed."
            tam "Somebody did."
            jump finial_price


label finial_after_reading:
    ## The reading. Everything here is *Tamsin's*, seen from outside, in her flat, on a
    ## morning Nara was not present for. The POV character is not in this scene and cannot
    ## get into it. That is the frame the whole fork stands on.
    nar "The brass goes warm, which it does not do, and then Nara is not holding it any more. She is about four feet up and slightly behind, the way you are in someone else's memory — present, uninvited, unable to look away and unable to help."

    nar "Morning. Not this morning; a morning with a lot of light in it, coming through a curtain that is only half up because the other half of the rail has been unscrewed and put in a box."
    nar "The room is nearly empty. Cardboard along one wall, labelled in marker in a hand that started neat. The bed is stripped down to the mattress and the mattress is on the floor, because the frame is in pieces against the radiator."

    nar "Tamsin is sitting on it. Sheet pulled across her lap, shoulders bare, hair flat on one side from sleeping on a thing that is no longer a bed."
    nar "She is holding the finial. Turning it. She has clearly been sitting there a while doing exactly that and nothing else."

    nar "There is no one else in the room. That is the part that makes it hard to watch — not the bareness of her, which is simply what you look like at eight in the morning in a flat you are losing, but that the scene has been built by somebody and then everybody left."

    nar "She says something. It does not carry; readings do not carry sound, they carry the shape of it. It was four words and it was addressed to the room."
    nar "Then she puts the finial in the pocket of a coat and stands up, and the light goes.\n"

    nar "Nara is at her own counter with her hand flat on a piece of brass and eleven seconds gone off the clock."

    $ act_cleared = 1
    nara "..."
    tam "You've gone a bit grey."
    nara "The lamp does that."
    tam "The lamp's been on the whole time."

    jump finial_price


label finial_price:
    nar "Twenty-two is what it is worth. She could write fourteen and Tamsin would take fourteen, because people who have already decided to lose something will accept the terms of losing it."
    nar "She could write thirty-three, which is not generosity, it is the shop paying for her to have seen the room."

    call price_menu("finial") from _call_price_finial
    $ _paid = run.paid["finial"]
    $ _tier = run.prices["finial"]

    if _tier == "low":
        nar "She writes fourteen. Tamsin looks at it for exactly as long as it takes to decide not to argue, and that is the whole transaction."
        tam "Fine."
        nara "It's brass."
        tam "It's fourteen pounds of my bed. That's fine. That's — yeah."
        nar "She is gone before the bell has finished. Nara puts the finial on the shelf behind her and it sits there being worth twenty-two."
        nara "Eight up. Well done."
    elif _tier == "fair":
        nar "Twenty-two. She writes it, turns the ticket, and does not explain it."
        tam "That's more than it's worth."
        nara "That's exactly what it's worth. What's less than it's worth is fourteen, which is what you came in expecting, which is why you didn't bring the other three."
        nar "Tamsin takes the money and puts it in her back pocket without counting it, which is either trust or exhaustion."
        tam "If I bring the other three, will you do the same?"
        nara "If you bring the other three I'll do better, because four of anything is a set."
        tam "Right. Okay."
        nar "At the door she stops with her hand on the glass and says the thing people say when the transaction was not the reason they came."
        tam "It was a good bed."
        nara "It sounded like one."
        nar "Tamsin looks at her. Neither of them touches it."
    else:
        nar "Thirty-three. Tamsin looks at the ticket, then at her, and her face does something complicated and unwelcome."
        tam "Why."
        nara "Because I looked at it and now I know what it's worth to you, and that's a different number, and I'd rather be wrong in that direction."
        tam "You can't afford to be wrong in that direction. Look at this place."
        nara "I know what I can afford. Take the thirty-three."
        nar "She takes it. At the door she turns round."
        tam "You saw it. Didn't you. The room."
        nara "Yes."
        tam "Was I —"
        nara "You were sitting up. That's all. You were sitting up and it was a nice morning and the light was good."
        nar "Tamsin nods once, hard, the way you nod at a thing you needed to be told, and goes out into the rain without a coat."

    $ tel_track("act_finial_done", {"tier": _tier, "paid": _paid, "till": run.till, "read": "finial" in run.readings_taken})
    jump act_ring
