## 06_script_ch3.rpy — Chapter 3: Penhallow
##
## The donor whose money bought the erasures. Vance and Elena work the archive by day and each other
## by night. A public event (the Penhallow lecture) forces them into the same room as the grandson.
## Route memory continues: control / pact / walk_away. The walk_away route catches up here: Elena
## and Vance become lovers on her terms, which is the point of that route.

label chapter_3:
    $ tel_track("ch3_start", {"ending": chosen_ending})
    stop music fadeout 1.0
    play music suspense_theme fadein 2.0

    scene bg study_normal
    with fade

    narrator "Chapter 3 — Penhallow"
    narrator "Three days later. Nobody has opened the coal store. The Dean has not mentioned lot forty-one again, which is worse than if she had."

    show elena neutral at center
    with dissolve

    narrator "Elena has moved a second chair into your office without asking. She works at it from four until the porters change, then goes home, then comes back."
    elena "Penhallow gave eleven gifts between 1993 and 1997. Every one of them is matched, within a month, by a name leaving the Academy."
    protagonist "Leaving how?"
    elena "Quietly. Resigned, retired, transferred. Two died. My father was the fourth."
    narrator "She turns the ledger toward you. She has drawn a table on a sheet of foolscap. Eleven gifts, eleven departures, eleven receipts you countersigned or someone like you did."
    elena "He was not buying a wing. He was buying a building with nobody left in it who remembered what it stood on."

    protagonist "The crypt."

    elena "There is no crypt, Vance. That is the story they tell the first-years. Under the Blackwood wing there is a cellar, and in the cellar there was a chapel, and in 1994 the chapel had a floor that somebody did not want dug up."
    narrator "She says this flatly, like a weather report. You have learned that this is how she says the things that frighten her."

    # Choice: how far to push before the lecture.
    menu:
        "\"Then we dig it up.\"":
            $ elena_affection += 1
            $ tel_track("ch3_choice", {"choice": "dig"})
            elena "With what? A trowel and a postgraduate?"
            protagonist "With a building survey. I am the signing officer for lot forty-one. Apparently I sign things. I can sign a survey request."
            narrator "She stares at you. Then she laughs, the real one, and puts her hand over her mouth as if it had escaped."

        "\"We go to the board with what we have.\"":
            $ elena_suspicion += 1
            $ tel_track("ch3_choice", {"choice": "board"})
            elena "The board chair is Penhallow's grandson."
            protagonist "Then we go to the two members who are not."
            elena "And if they are the two who died?"
            narrator "She has already checked. You can see it in her face. You stop suggesting things for a while."

        "\"We wait. Somebody will make a mistake at the lecture.\"":
            $ elena_suspicion += 1
            $ elena_affection += 1
            $ tel_track("ch3_choice", {"choice": "wait"})
            elena "You are very calm for a man whose signature is on eleven receipts."
            protagonist "Four. I checked."
            elena "Four, then."
            narrator "She puts her pen down and looks at you properly. It is not an unfriendly look. It is the look of someone re-reading a page she thought she had understood."

    $ tel_track("ch3_lecture")

    scene bg study_dark at night_deep
    with fade

    narrator "The Penhallow Lecture. Friday, seven o'clock, the main hall. Every faculty member who wants to keep an office attends."
    narrator "Julian Penhallow gives it himself this year. He is forty, handsome in the way money is handsome, and he thanks the Dean by her first name."
    narrator "Elena sits three rows behind you. You do not look at her. You have agreed not to look at her. It is the hardest thing you have done all week."

    narrator "Afterwards, sherry. Penhallow works the room like a man checking exits."
    narrator "He reaches you at the end. He has your name before you offer it."

    $ unlock_cg("cg_confrontation")
    scene cg confrontation at night_deep
    with dissolve

    narrator "\"Vance. Antiquities. My grandfather's wing.\" He shakes your hand and does not let go at once. \"I hear you lost a crate.\""
    protagonist "Deaccessioned. Per schedule."
    narrator "\"Of course. Per schedule.\" He smiles. \"Marguerite tells me you have taken on an assistant. An Ashcombe. Unusual name. I knew an Ashcombe once.\""
    narrator "The Dean is across the room, not looking at you, in the way that Elena is not looking at you. You are surrounded by people not looking at you."

    menu:
        "\"You knew her father. He carried your grandfather's money out of the building.\"":
            $ elena_suspicion += 2
            $ tel_track("ch3_choice2", {"choice": "confront"})
            narrator "Penhallow's smile does not move. His hand does. It lets go of yours."
            narrator "\"Careful, Professor. Old buildings have thin walls and long memories.\" He turns to the next hand."
            narrator "You have made an enemy on purpose. You are not sure yet whether that was clever."

        "\"She's a good researcher. Family is not my concern.\"":
            $ elena_affection += 1
            $ tel_track("ch3_choice2", {"choice": "deflect"})
            narrator "\"No,\" Penhallow agrees. \"It rarely is, until it is.\""
            narrator "He moves on. Behind him, the Dean finally looks at you, once, and then away, and you understand that whatever Penhallow wanted from that exchange, he got it."

        "Say nothing. Let him talk.":
            $ elena_affection += 1
            $ elena_suspicion += 1
            $ tel_track("ch3_choice2", {"choice": "listen"})
            narrator "Men like Penhallow cannot stand a silence. He fills it."
            narrator "\"Marguerite is retiring in the spring, you know. The board will want a safe pair of hands. Someone with a signature people trust.\""
            narrator "He looks at your hand when he says it. Then he is gone, and you are holding a sherry you do not remember taking."
            $ dean_blackmail = True

    scene bg study_normal
    with dissolve

    narrator "Ten o'clock. Your office. You did not turn the light on; the lamp from the corridor is enough."
    show elena flustered at center
    with dissolve
    narrator "Elena comes in without knocking and locks the door behind her, and stands with her back against it, breathing as if she had run."
    elena "He knows my name."
    protagonist "He knew it before you were born."
    elena "He said it to the Dean. Out loud. In front of the whole room. Like a man putting a glass down on a table so everyone hears it."

    if chosen_ending == "walk_away":
        narrator "She has not come closer. Her hands are behind her, on the door, holding it shut or holding herself up."
        elena "Five, I said. On the dock. You did not ask."
        protagonist "I thought you would tell me when you wanted to."
        elena "Five days. I gave myself five days to decide whether you were a coward or a careful man. It has been five days."
        protagonist "And?"
        narrator "She crosses the room. She takes your face in both hands, coat and all, and looks at it as if it were a page."
        elena "Careful. Unfortunately."
        $ elena_affection += 3
    elif chosen_ending == "control":
        narrator "She crosses the room and puts her hand in your waistcoat pocket, where the key is, and leaves it there."
        elena "He looked at my hands. He knows I have been in the crate."
        protagonist "He knows I have. You are the assistant. I am the signing officer."
        elena "You keep saying that as if it protects me."
        protagonist "It does. That is the whole point of you being mine on paper. On paper is where they fight."
        narrator "She takes the key out of your pocket, looks at it, and puts it back."
        elena "Then keep me on paper. Off paper, tonight, I would like to stop being frightened for an hour."
    else:
        narrator "She crosses the room and puts her forehead against your chest and stays there."
        elena "I want to burn his portrait."
        protagonist "It is on loan from the family."
        elena "Then I want to burn the family."
        protagonist "Elena."
        elena "I know. I know. Give me an hour where I am not the last Ashcombe, and then I will be reasonable."

    $ tel_track("ch3_climax", {"ending": chosen_ending})
    $ unlock_cg("cg_climax")
    scene cg climax at ritual_tint
    with dissolve

    if chosen_ending == "walk_away":
        narrator "She is not in a hurry, this first time. She takes your coat off you, and then her own, and folds both over the chair, and then undresses in the corridor light with her eyes on yours, one button at a time, as if daring you to look away."
        narrator "You do not look away."
        narrator "She takes you to the floor, on the coats, and moves on you slowly for a long time before either of you speaks, and when she does speak it is your first name, finally, said like a decision."
        narrator "You lose track of the order of things after that. Her mouth. Her hands pinning yours. The moment she stops being careful and you feel her come apart against you, and the way she laughs into your neck afterwards, as if surprised that it worked."
        narrator "When it is over she puts her glasses back on before anything else. Then she says, into the dark, \"That is what five meant.\""
    elif chosen_ending == "control":
        narrator "You undress her yourself tonight, because she asks you to, and because it takes longer. Blouse. Skirt. The stockings she wore for the lecture. She stands in the corridor light and lets you, and does not help."
        narrator "You lay her down on the desk with her head on the ledger, deliberately, and she notices, and does not object."
        narrator "You go slowly and she asks for faster and you refuse until she asks properly. She asks properly. Her name for you in that moment is not Professor and not Vance but something with no consonants in it."
        narrator "When she comes it is with her heels locked behind your back and her nails in the desk, and she pulls you down after her and holds you inside her with both legs until she is sure. Then she lets you go."
        narrator "You lie together on the desk with the ledger under her hair. She is not frightened. You gave her the hour. It cost you something to give it, and she knows the price, and she will collect."
    else:
        narrator "She is rough with you, and you let her. Coat. Waistcoat. She tears a button and swears at it and kisses the place it was. You lift her onto the desk and she pulls you in with her heels before your belt is off."
        narrator "It is fast and loud and she says his name once, Penhallow, in the middle of it, like spitting, and then yours, four times, each time softer."
        narrator "She comes with her teeth in your shoulder. You come with your hand over her mouth because the porters are changing, and she bites your palm, and afterwards you both look at the marks and do not say anything."
        narrator "Then she says, \"An hour. Thank you,\" and gets up and starts being reasonable, which is worse."

    scene bg study_normal
    with fade

    narrator "Midnight. Reasonable, for Elena, means a plan on a single sheet of paper."
    show elena neutral at center
    with dissolve
    elena "The Dean retires in the spring. Penhallow wants your signature on the board. That means he needs you clean."
    protagonist "Or compromised."
    elena "Or compromised. Either way, he needs you. So he does not need me."
    narrator "She lets that sit."
    elena "I am the loose end, Vance. Not you. Whatever happens next happens to me."

    $ tel_track("ch3_end", {"ending": chosen_ending, "affection": elena_affection, "suspicion": elena_suspicion})
    $ tel_flush(True)

    narrator "You want to tell her she is wrong. You have the ledger open in front of you, eleven receipts, eleven names. You do not tell her she is wrong."
    narrator "Instead you turn to the survey request form and sign it. Your own signature, for once. It looks strange on the page."

    $ chapter_cleared = max(chapter_cleared, 3)
    jump chapter_4
