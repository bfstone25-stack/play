## 04_market.rpy — The descent. One crypt room: the Ossuary Market.
##
## The base game had four crypt rooms and a combat loop; this keeps the one room with people
## in it (scene_crypt_2_ossuary_market) and throws the combat away. Calder buys readings.
## Selling him one is the Factor ending and it is a single, clearly-labelled choice.

label act_market:
    call chapter_gate(3) from _call_chapter_gate_3
    $ tel_track("act_market_start", {"till": run.till, "taken": len(run.readings_taken)})
    scene bg black
    with fade
    stop ambience fadeout 2.0
    play music crypt fadein 2.0

    nar "Two o'clock. The book is empty until five and the drawer has [run.till] in it against a debt of [core.DEBT], so she goes down."

    nar "Behind the stock room, under a rug that Elsa never bothered to nail: the Receipt Stair."
    nar "Forty-one steps cut into what the surveyor's report from 1974 calls {i}made ground{/i} and what everybody who has ever been down it calls the other thing. The treads are paper. Compressed, laminated, decades of pawn tickets pressed into something that takes a boot."
    nar "On the way down you can read them side-on if you want to. She does not want to."

    nar "She does anyway, about a third of the way, because the mind is a stupid animal that reads what is in front of it."
    nar "{i}Silver christening cup. Held 30 days. Unredeemed.{/i} {i}Trombone, case. Redeemed, 14 days, no interest charged, E.Q.{/i} {i}Overcoat, wool, good. Unredeemed.{/i}"

    nar "Nobody ever comes and gets the overcoats. Elsa had a theory about that too — that a coat is the thing you pawn when there is no longer a version of the winter in which you need it."

    nar "The air changes at about step twenty-five. Not colder; drier, and with the faint mineral smell of a cellar that has never had water in it, which in this city is not possible and is nonetheless the case."
    nar "The last sixteen steps she takes with her hand on the wall, and the wall is not stone, and she has known that for three years and still checks."

    scene bg market
    with dissolve
    nar "And then the Market."

    nar "A vaulted room the size of a swimming bath, walled floor to ceiling in bone — femurs stacked in courses like brick, skulls set in as a decorative band at head height, which whoever did it clearly thought was tasteful."
    nar "Between the pillars, stalls. Trestles, awnings, lanterns burning something that is not oil. Thirty or forty traders, none of whom are precisely present, all of whom are precisely busy."

    nar "They deal in unclaimed collateral. Everything down here defaulted on a ticket somewhere and came to the only market that will take it."
    nar "Nara comes down about once a fortnight with whatever the shop's thirty days have eaten, and comes back up with cash, and the whole arrangement is so ordinary that she has stopped bringing a light."

    nar "The stalls, in order, because she does the same circuit every time and the circuit is the only thing down here she controls."
    nar "Teeth. Not a metaphor and not a curiosity stall — a trestle of human teeth sorted by decade, which somebody buys, which she has never asked about."
    nar "Doors. Six of them, freestanding, none of them attached to anything, all of them locked. The trader sells the doors. He does not sell the keys and becomes unpleasant if you mention them."
    nar "Instruments, all of them unstrung. Bottles of things that are almost certainly water. A woman who will buy a name off you, cash, no questions, and who Nara crosses the aisle to avoid."
    nar "And at the end, past the pillar where the femurs give way to something longer than a femur, the factor's stall."

    nar "The traders are not solid in the way a person is solid. If you look directly at one they are a man in an apron weighing out charms. If you look at the next stall along and let him sit at the edge of your eye, he is a shape doing the motions of weighing, with no weights and no scale and no hands."
    nar "The first year, that stopped her sleeping. The second year she worked out the trick, which is simply to look at people when you are talking to them, the same as upstairs."

    ## --- the ordinary business -------------------------------------------
    $ run.earn(core.MARKET_HAUL)
    nar "Tonight's unclaimed: two bone charms, a moon coin with the ward still legible under the tarnish, and a cracked dueling pistol she is glad to see the back of."
    nar "The stalls take the lot for [core.MARKET_HAUL]. Till: [run.till]."

    nar "And then a man at the end stall says her name, which nobody down here does."

    cal "Quill."

    nar "Forty-five, heavy through the shoulders, an apron over good clothes. He is the only trader down here who is entirely solid and the only one who has ever been rude to her."
    nar "Calder. A factor — he does not sell, he buys, and then other people find they own what he bought."

    nara "Calder."
    cal "You've been up there three years and you still come down here with charms and coins."
    nara "That's the stock."
    cal "That's the {i}stock{/i}. That is not the inventory."

    nar "He taps the trestle twice with one knuckle."

    cal "You've got four columns in that book. You sell me the contents of three of them. Nobody has ever asked you about the fourth."

    $ tel_track("calder_pitch", {"taken": len(run.readings_taken)})

    nara "..."
    nara "The fourth column's not stock."
    cal "The fourth column is the only thing in that shop that isn't replaceable, and you're giving it away free with every purchase."

    nara "It's not mine to sell."
    cal "Neither's the ring. You sold me that man's pistol last month and his fingerprints were still on the grip and you didn't ask him."
    nara "A pistol is an object."
    cal "And a reading is a thing you have in your head that came out of an object. Where exactly is the line, and did you draw it before or after you found out what it was worth?"

    nara "I haven't found out what it's worth."
    cal "You're about to. That's the part people mind."

    nar "He wipes the trestle down with a cloth, which is a thing he does when he is about to be reasonable, and Nara has learned to mind that more than the rudeness."

    cal "Let me put the objection for you, so you don't have to. It's theirs. They didn't consent. They came in out of the rain with a problem and they left with a ticket and somewhere in the middle of that you went into a room they were in six years ago."
    nara "Yes. That's the objection."
    cal "It's a good one. It is also an objection to the {i}looking{/i}, Quill, not to the selling, and you did the looking upstairs half an hour ago for free."
    nara "Not for free. It cost the shop."
    cal "It cost the shop. It didn't cost you. Do you know what the difference is?"
    nara "I know what the difference is."
    cal "Then say it."
    nara "..."
    cal "No. I didn't think so."

    nar "Which is the closest Nara has come, in three years, to being genuinely got at, and the worst of it is that she does not know the answer and has not known it since about half past eleven."

    ## --- the demonstration CG --------------------------------------------
    python:
        _client_readings = [k for k in run.readings_taken if k in ("finial", "ring", "veil")]
    if len(_client_readings) >= 2:
        nar "He can tell. She does not know how — something about the hands, or the fourth column has a smell."
        cal "You're carrying two. Maybe three. Let me show you the shape of the trade before you decide you're above it."
        nara "I don't want —"
        cal "You do. Everybody does. It's free and it's not one of yours."

        nar "He puts a bone charm on the trestle and turns it over so the flat side is up, and it is not a charm, it is a plate — a reading fixed in something, bought off some other broker in some other city, wrapped and stacked like herring."

        $ unlock_cg("market")
        call cg_gate("market") from _call_cg_gate_market
        scene expression cg_pick("market") at crypt_tint
        with dissolve
        $ tel_track("reading_shown", {"item": "market", "dist": dist_track(), "delivered": reading_delivered("market")})

        nar "Two people, very small in the frame, a long way down the vault between the stalls. Holding on to each other and nothing else."
        nar "You cannot see their faces. There are no faces to see — whoever sold this took the reading and the reading came out with the people in it as light and mist and the suggestion of bare shoulders, and that is all anyone will ever get of them now."
        nar "They are somebody's worst or best hour, and they are for sale, at head height, between a stall selling teeth and a stall selling doors."

        nara "Who are they?"
        cal "No idea. That's the product. Nobody's ever going to know and that's why it's worth anything."
        nara "That's obscene."
        cal "That's inventory. You've got the same thing in your head about a woman and a bed frame, and the only difference is yours is doing nothing for anybody."
    else:
        nar "He watches her hands for a moment and then makes a small dismissive noise."
        cal "You've not got enough on you to be worth the demonstration. Come back when you've looked at something."
        nar "Which stings more than it should, and she files that."
        $ tel_track("calder_no_demo", {"taken": len(_client_readings)})

    ## --- the offer --------------------------------------------------------
    scene bg market
    with dissolve

    if not _client_readings:
        nar "Calder waits for her to offer something and she has nothing to offer, because she has not looked at anything tonight, and that is either integrity or an empty fourth column and she genuinely cannot tell which."
        cal "Then we're wasting each other's night."
        nara "Apparently."
        $ tel_track("calder_offer_skipped", {"reason": "no_readings"})
        jump market_leave

    $ _sellable = _client_readings[-1]
    $ _seller = core.ITEMS[_sellable]["client"]
    nar "He names a price without being asked, which is how you know he has been waiting to."
    cal "Ninety. For one. Your pick, and I'd take the newest, they come out cleaner."

    nar "[core.CALDER_READING_PRICE] would clear the estate on its own and leave her with change and a shop."
    nar "The newest one is [_seller]'s."

    $ tel_track("calder_offer_shown", {"item": _sellable, "price": core.CALDER_READING_PRICE, "till": run.till})

    menu:
        "Ninety pounds, for a thing that is already in your head."

        "Sell him [_seller]'s reading. ([core.CALDER_READING_PRICE])":
            $ run.sold_reading = _sellable
            $ run.earn(core.CALDER_READING_PRICE)
            $ tel_track("calder_sold", {"item": _sellable, "till": run.till})
            nar "It does not take long and it does not hurt, and both of those are the problem."
            nar "He puts a blank charm in her palm and closes her fingers on it and says something short, and the reading goes out of her the way a word goes when you have been trying to remember it and then stop trying."
            nar "She can still describe the room. She cannot see it. It has become a thing she knows rather than a thing she has."

            nara "That's it?"
            cal "That's it. You'll notice in about a week that you've stopped being able to picture it. Most people say that's an improvement."
            nara "And them?"
            cal "They'll never know. Nobody ever knows. That's the entire business, Quill, that's why it's worth ninety and not nine."

            nar "He counts it out in notes that are warm, which she decides not to think about."
            nar "Till: [run.till]."

        "Don't. Go back up the stairs.":
            $ tel_track("calder_refused", {"item": _sellable, "till": run.till})
            nara "No."
            cal "Say a number."
            nara "There isn't one. That's not me being noble, it's me telling you the column doesn't have prices in it."
            cal "Everything has prices in it. That's painted on your own window."
            nara "{i}What the living will offer, and what the dead will demand.{/i} You're neither. You're a man with an apron who found a gap."
            nar "Calder laughs, genuinely, for the first time in three years of doing business."
            cal "That's Elsa's line. Word for word, same flat delivery. She said no as well."
            nara "Then you've had your answer twice."
            cal "I've had it twice from the same shop. Come back in March."

    jump market_leave


label market_leave:
    scene bg black
    with fade
    stop music fadeout 2.0
    play music theme fadein 2.0
    play ambience dust fadein 2.0

    nar "Forty-one steps back up, and on the way up the tickets are readable the other way round, which she has never noticed before."
    nar "About two-thirds of the way she stops, because one of the treads near the top is newer than the others. Cleaner. Not yet walked flat."
    nar "It has a name on it and the name is hers and the date on it is tomorrow's."

    nara "..."
    nar "She steps on it, because the alternative is to stand in a stairwell until morning."

    $ act_cleared = 4
    $ tel_track("act_market_done", {"till": run.till, "sold": run.sold_reading, "taken": len(run.readings_taken)})
    jump act_collateral
