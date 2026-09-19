## 02_act2.rpy — Act 2: room 704. Behind the gate on both web tracks.

label act2:
    $ tel_track("act2_start", {"route": route, "trust": trust})
    scene bg corridor
    with fade
    play music warm fadein 2.0
    nar "The fourth-floor corridor smells of old carpet and a cigarette somebody finished three hours ago. The sconce outside 702 has been dying for a year."
    nar "You knock once. The door opens before your hand is back at your side."

    scene cg door
    with dissolve
    nar "The coat is gone. The dress underneath was not chosen for the rain, and it was certainly not chosen for the Marbeck."
    m "You came up."
    you "You called the desk."
    m "People don't always come when you call the desk."

    scene bg room
    with dissolve
    nar "Seven-oh-four is eleven square metres of bed, one chair, and a window that looks straight down onto the street."
    nar "The car is still there. From up here you can make out the shape of a man in it, doing nothing, which takes a particular kind of patience."

    if route == "cover":
        m "He came in, didn't he."
        you "Around twenty to four."
        m "What did you say?"
        you "That it had been a quiet night."
        nar "She takes her time with that."
        m "You lied to a man you'd never met, for a woman you'd known eight minutes."
        you "It wasn't a hard decision."
        m "No. That's the part I'm turning over."
        $ trust += 2
    elif route == "sold":
        m "He came in."
        you "He did."
        m "And you showed him the book."
        nar "There is no point in the sentence where you could put a denial."
        you "I did."
        m "Right."
        nar "She looks at the window instead of at you."
        m "I'm not going to shout at you. You didn't owe me anything. I put money on a counter and asked a stranger to be on my side, and that was optimistic of me."
        m "But I'll be gone before it's light, and I'd rather not spend my last few hours angry at the only person who's spoken to me today."
        $ trust -= 1
    else:
        m "He came in and you gave him nothing."
        you "I gave him the house line."
        m "The house line is a gift, at four in the morning."
        $ trust += 1

    nar "She pours two inches of something into the bathroom tooth glass and hands it to you, then drinks hers from the bottle, which tells you what she thinks of the glass."

    m "Sit down. You've been on your feet behind that desk for six hours. I could hear it in how you came up the stairs."

    $ tel_track("choice_room_shown", {"route": route, "trust": trust})

    menu:
        "She has made room on the edge of the bed. The chair is also there."

        "Take the chair.":
            $ tel_track("choice_room", {"pick": "chair"})
            jump act2_chair

        "Sit next to her.":
            $ tel_track("choice_room", {"pick": "bed"})
            jump act2_bed

        "Stay standing. Watch the car.":
            $ tel_track("choice_room", {"pick": "window"})
            jump act2_window

label act2_chair:
    nar "You take the chair. She watches you do it, and her shoulders come down half an inch."
    m "Good."
    you "Good?"
    m "Most men would have sat on the bed."
    nar "You talk. It is four in the morning and neither of you is going to sleep, so you talk."
    nar "About the hotel, which has a ghost according to the day porter and a rat problem according to everyone else. About the account with her name on it, and the eleven months it took her to notice she had stopped buying anything she liked."
    nar "At some point the bottle is nearly empty and she is on the floor with her back to the bed, near enough that her shoulder rests against your knee."

    m "I'm going to ask you something and you can say no and it won't be strange afterwards."
    m "Stay up here. Not the chair."

    menu:
        "She has asked plainly. That deserves a plain answer."
        "Say yes.":
            $ route = route + "_yes"
            jump scene_bed
        "Say no, and stay in the chair until it's light.":
            $ route = route + "_no"
            jump act2_decline

label act2_bed:
    nar "You sit on the edge of the bed, close enough that the mattress puts you slightly off balance toward her."
    m "There we are."
    nar "She does not move away. She does not move closer. She lets it sit there being what it is, and drinks, and watches the window."
    m "Do you want to know the stupid part?"
    you "Tell me the stupid part."
    m "I booked a train. It leaves at six-forty. I've had the ticket for nine days and I kept not getting on it."
    m "Tonight I got as far as the station and couldn't make myself sit on a bench for four hours where anyone could see me. So I walked, and your doors were the first ones that were open."
    nar "She turns the bottle in her hands."
    m "So this is the bravest thing I've done in a year. A hotel lobby."
    you "You walked in out of the rain like you owned the place."
    m "Yes. I'm good at that."

    nar "She puts the bottle down on the floor, deliberately, out of the way."
    m "Ask me to stay awake with you, or tell me to go to sleep. Either one. Just decide, because I've been deciding nothing for eleven months and I'm tired of it."

    menu:
        "She has put it in your hands on purpose."
        "\"Stay awake with me.\"":
            $ route = route + "_yes"
            jump scene_bed
        "\"Get some sleep. I'll be downstairs.\"":
            $ route = route + "_no"
            jump act2_decline

label act2_window:
    nar "You stay by the window. The car does not move. Neither does the shape inside it."
    m "You can watch him all night. He'll still be there at six."
    you "Then at six you'll have a train and he'll have a parking ticket."
    nar "She laughs. Short, surprised, nothing performed about it — the first one tonight."
    m "How do you know about the train?"
    you "I don't. It was a guess. Everyone leaving somewhere at this hour has a train."
    m "Six-forty."

    nar "She comes and stands beside you at the glass. Close. The rain has taken the street apart into pieces."
    m "Nine days I've had that ticket."
    nar "Her reflection in the window is looking at yours."
    m "I don't want to spend the last four hours of it being watched."

    menu:
        "She is at the glass beside you. The street is a long way down."
        "Turn her away from the window.":
            $ route = route + "_yes"
            jump scene_window
        "Close the curtain and leave her to sleep.":
            $ route = route + "_no"
            jump act2_decline

label act2_decline:
    $ tel_track("route_decline", {"route": route})
    scene bg room
    with dissolve
    nar "You say the sensible thing. She takes it well, which is worse than if she had not."
    m "All right."
    nar "You sit in the chair by the door until the window goes from black to grey. She sleeps eventually, on top of the covers with her shoes on, the way people sleep when they mean to leave."
    jump act3

label scene_bed:
    $ tel_track("route_scene", {"scene": "bed", "route": route})
    stop music fadeout 1.0
    play music heartbeat fadein 1.5
    nar "The lamp stays on. She reaches past you and turns it to face the wall, so the light climbs the paper instead of crossing the bed — the last ordinary thing either of you does for a long while."

    call cg_gate("bed") from _call_cg_gate_bed
    scene expression cg_pick("bed") at neon_tint
    with dissolve

    nar "Rain on the window. Neon coming through it in long red bars that move across the sheets when the sign cycles."
    nar "She is not quiet, and she is not performing not being quiet, and you can hear the difference."
    m "Don't stop."
    nar "Four floors down a car door opens and shuts. Neither of you goes to the window."
    $ act_cleared = 2
    jump act3

label scene_window:
    $ tel_track("route_scene", {"scene": "window", "route": route})
    stop music fadeout 1.0
    play music heartbeat fadein 1.5
    nar "You turn her away from the street, which is what she asked for. She takes two handfuls of your shirt and walks you backwards until the bed stops you, and from there she decides everything, which is also what she asked for."

    call cg_gate("window") from _call_cg_gate_window
    scene expression cg_pick("window") at neon_tint
    with dissolve

    nar "Behind her the window is a sheet of moving water with the city broken up inside it. She does not look at it once."
    m "He can't see up here."
    you "No."
    m "Good."
    nar "Four floors down, a man in a car watches a door that nobody comes out of."
    $ act_cleared = 2
    jump act3
