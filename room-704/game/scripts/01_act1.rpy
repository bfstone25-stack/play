## 01_act1.rpy — Act 1: the front desk. Free on every track.

label start:
    call tel_boot from _call_tel_boot_r704
    $ tel_track("game_start", {"build": config.version})
    scene bg black
    with fade
    play music theme fadein 2.0
    play ambience rain fadein 2.0

    nar "The Marbeck Residential Hotel has forty rooms, eleven guests, and one person awake."
    nar "That is you. It is 2:14 in the morning and you are three columns into a ledger nobody has read in ten years except the owner's accountant, once a quarter, without interest."

    scene bg lobby
    with dissolve
    nar "Rain came in off the river around midnight and has not let up. The glass doors run with it. The neon from the noodle place across the street arrives on the floor tiles in long red smears."

    nar "You are the night auditor. The job is to be here. Occasionally the job is to hand someone a key."
    nar "Then the doors open."

    $ tel_track("act1_start")

    scene cg checkin
    with dissolve
    nar "She comes in out of the rain without hurrying, which is the first thing you notice. People run through weather like this. She walked."
    nar "Late twenties. Pale hair gone dark at the ends with water. A long coat over something that was not chosen for a night like this."
    nar "She puts a canvas bag on the counter. Then a folded stack of banknotes beside it. Then she looks at you."

    m "A room. Whatever you have."
    you "How many nights?"
    m "Let's say one and see how it goes."

    nar "You turn the register toward her. It is a paper register, because the Marbeck has never spent money it did not have to."

    m "I would rather not."
    you "Rather not what?"
    m "Be in the book."

    nar "She says it plainly. Not a wheedle, not a joke. A stated preference, the way you would say you would rather have a room away from the lift."
    nar "You look at the cash. It is more than a room costs. Not so much more that it is an insult."

    $ tel_track("choice_register_shown")

    menu:
        "She wants off the ledger. The cash is on the counter."

        "Ask her why before you decide.":
            $ trust += 2
            jump ask_why

        "Take the cash. Don't write anything.":
            $ trust += 1
            $ covered_for_her = True
            jump take_cash

        "Do it properly. Name in the book.":
            $ trust -= 1
            jump by_the_book

label ask_why:
    $ tel_track("choice_register", {"pick": "ask"})
    you "You're getting the room either way. I'd just like to know what I'm agreeing to."
    nar "Something in her face moves and settles. She had been braced for a different answer."
    m "Nothing you'd have to lie to the police about, if that's the worry."
    m "I have a card in my bag with my name on it. If I use it tonight, someone will know the name of this hotel before breakfast."
    you "A someone who is looking for you."
    m "Someone who pays for the account the card belongs to. He finds it restful, knowing where I spend money."

    nar "She says it flat, the way people say a thing they have said to themselves a hundred times and never once aloud."
    m "So. Cash. And not in the book. That's the whole of it."

    $ trust += 2
    $ covered_for_her = True
    jump gives_key

label take_cash:
    $ tel_track("choice_register", {"pick": "cash"})
    nar "You take the notes, count them without appearing to count them, and put them in the drawer under the tray."
    nar "The register stays where it is. You turn it back around."
    you "The book says the fourth floor is empty tonight. The book is often wrong."
    m "That's a good book."
    jump gives_key

label by_the_book:
    $ tel_track("choice_register", {"pick": "book"})
    you "I need a name. It's the one thing I can't skip."
    nar "She looks at you long enough for the rain to get loud."
    m "Of course you do."
    nar "She writes. The hand is steady, and the name is not the one on the card in her bag. You would put money on it."
    m "There. Now we're both honest."
    $ covered_for_her = False
    jump gives_key

label gives_key:
    scene bg lobby
    with dissolve
    nar "You take a key off the board. Seven-oh-four. Corner room, river side, the only one on that floor where the window still opens."
    you "Top of the stairs, left, all the way down. Take the stairs — the lift makes a noise you don't want to hear at this hour."
    m "Mira."
    you "I didn't ask."
    m "I know. That's why."

    m "Goodnight, night auditor."

    nar "She goes up. You listen to her not hurrying, all the way to the fourth floor."
    $ tel_track("act1_key_given", {"trust": trust, "covered": covered_for_her})

    scene bg lobby
    with fade
    nar "At twenty to four, the doors open again."

    man "Evening."
    nar "Wet overcoat, mid-forties, a build that used to be sport and is now maintenance. He does not shake the water off. He stands where it can run off him onto your tiles."
    man "I'm looking for someone. Woman, late twenties, pale hair. She'd have come in these last two hours."
    nar "He is not a policeman. A policeman would have led with being a policeman."

    $ tel_track("choice_visitor_shown", {"covered": covered_for_her})

    menu:
        "He is waiting. The register is on the counter between you."

        "Tell him nobody's checked in.":
            $ trust += 3
            $ route = "cover"
            jump lie_to_him

        "Slide the register at him and say nothing.":
            $ trust -= 2
            $ route = "sold"
            jump show_register

        "Tell him the hotel doesn't discuss guests.":
            $ trust += 1
            $ route = "stonewall"
            jump stonewall

label lie_to_him:
    $ tel_track("choice_visitor", {"pick": "lie"})
    you "Nobody's checked in since eleven. Quiet night."
    nar "You say it without effort. That surprises you."
    man "Quiet night."
    you "It's a quiet hotel."
    nar "He looks past you at the key board. Seven-oh-four's hook is empty. So are nineteen others, and he cannot tell which empty hook is the one."
    man "If she comes in. There's a number on this."
    nar "He puts a card on the counter. You leave it there."
    nar "He goes. The rain takes him."
    jump act1_end

label show_register:
    $ tel_track("choice_visitor", {"pick": "sell"})
    nar "You turn the register around. Whatever is written there, he can read it himself."
    nar "He reads. His face does not change, which is the worst version."
    man "Fourth floor?"
    you "I didn't say that."
    man "You didn't have to. There's one gap on the fourth row."
    nar "He taps the counter twice — a man confirming what he already knew — and goes back out into the rain."
    nar "You sit down. You have done something, and it is now four floors above you, in a room with one window."
    jump act1_end

label stonewall:
    $ tel_track("choice_visitor", {"pick": "stonewall"})
    you "The hotel doesn't discuss guests. With anyone."
    man "So there is a guest."
    you "The hotel doesn't discuss whether there are guests."
    nar "He almost smiles. He has met desks."
    man "Fair enough."
    nar "He leaves a card on the counter and goes. You give him ten minutes to be across the street in a car, watching the doors."
    jump act1_end

label act1_end:
    scene bg black
    with fade
    $ act_cleared = 1
    nar "At ten past four the desk phone rings. Internal line. Seven-oh-four."
    m "It's Mira. From the book you didn't write in."
    m "There's a car across the road that hasn't moved in twenty minutes, and I can't sleep, and I've decided I'd rather not be alone up here not sleeping."
    m "Bring the pass key. If I open the door myself, I have to stand in the corridor to do it."

    $ demo_cut = route
    call chapter_gate(2) from _call_chapter_gate_r704
    jump act2
