## 07_script_ch4.rpy — Chapter 4: The Dean's Annex
##
## The survey request is approved too fast. The Dean summons Vance. Elena goes into the annex alone
## while he keeps the Dean talking. What is under the chapel floor is not a body; it is a second ledger.
## Route memory continues. The dean_blackmail flag (set in ch3 if Penhallow dangled the board seat)
## changes how the Dean plays it.

label chapter_4:
    $ tel_track("ch4_start", {"ending": chosen_ending, "blackmail": dean_blackmail})
    stop music fadeout 1.0
    play music suspense_theme fadein 2.0

    scene bg study_normal
    with fade

    narrator "Chapter 4 — The Dean's Annex"
    narrator "The survey request is approved in eleven hours. No survey request in the history of the Academy has been approved in under a month."

    show elena neutral at center
    with dissolve
    elena "She wants you in the cellar with a clipboard where she can see you."
    protagonist "Or she wants me out of my office for an afternoon."
    elena "Both. She is the Dean. She does not do one thing at a time."

    narrator "The summons comes at nine. Dean Marguerite Holloway will see Professor Vance in the annex at two. Tea will be served."
    narrator "The annex is the old chapel vestry, panelled, portraits, Penhallow above the fireplace. Nobody goes in without an appointment. The Dean's own files are in the room behind it."

    elena "Two o'clock. Tea takes forty minutes if she likes you and twenty if she does not."
    protagonist "She does not."
    elena "Then I have twenty minutes in the file room while she watches you drink."
    protagonist "No."
    elena "Yes. You are the signing officer. I am the assistant. You keep saying it protects me. Let it."

    # Choice: what Vance carries into the room.
    menu:
        "Take page fourteen with you. Put it on her desk.":
            $ elena_suspicion += 2
            $ tel_track("ch4_choice", {"choice": "bring_page"})
            elena "You want to see her face."
            protagonist "I want her looking at me and not at the door."
            narrator "Elena does not like it. She does not say so. She puts the page in an envelope so it looks like a letter."

        "Take nothing. Let her think you know less than you do.":
            $ elena_affection += 1
            $ tel_track("ch4_choice", {"choice": "bring_nothing"})
            elena "She will ask about the crate."
            protagonist "And I will say per schedule, and thank her for her thanks."
            narrator "Elena almost smiles. \"You are learning.\""

        "Take the survey approval and ask her, in writing, who authorised it.":
            $ elena_suspicion += 1
            $ elena_affection += 1
            $ tel_track("ch4_choice", {"choice": "bring_survey"})
            narrator "It is a boring piece of paper. That is the point. Boring paper is what universities are made of, and the Dean has to answer it."
            elena "Twenty minutes, Vance. Do not enjoy yourself."

    $ tel_track("ch4_dean")
    scene bg study_dark at night_deep
    with fade

    narrator "2:00 PM. The annex. The Dean pours. She is sixty-one, silver, in a suit that costs more than your car, and she has never once raised her voice in your hearing."

    $ unlock_cg("cg_confrontation")
    scene cg confrontation at night_deep
    with dissolve

    narrator "\"Professor. Sit. The survey. I thought we should talk before you go poking at foundations.\""
    narrator "She says {i}poking{/i} the way other people say {i}sue{/i}."

    if dean_blackmail:
        narrator "\"Julian was impressed with you on Friday. He mentioned the board. I said I would sound you out.\""
        narrator "She does not sound you out. She looks at you over the cup and lets the offer sit on the table between you like a third person."
        protagonist "I am an archivist, Dean. I sign things."
        narrator "\"Yes. That is rather the qualification.\""
    else:
        narrator "\"Julian asked about your assistant. I told him she was a credit to the department. Is she?\""
        protagonist "She reads faster than I do."
        narrator "\"That is not what I asked.\" She sets the cup down. \"Be careful with that one, Vance. The Ashcombes were always clever. It did not help them.\""

    narrator "Somewhere behind the panelling a drawer closes. The Dean does not react. You do not either. It costs you a great deal."

    menu:
        "Ask her directly what is under the chapel floor.":
            $ elena_suspicion += 2
            $ tel_track("ch4_choice2", {"choice": "ask_floor"})
            narrator "She laughs. It is the first time you have heard it. It sounds like a cup on a saucer."
            narrator "\"Foundations, Professor. Roman, then Norman, then Victorian, then Penhallow. Every building stands on what it buried. Ours is just better documented.\""
            narrator "\"Documented\" is the word she chooses. She wants you to hear it."

        "Talk about the weather until the tea is gone.":
            $ elena_affection += 1
            $ tel_track("ch4_choice2", {"choice": "stall"})
            narrator "You are dull for twenty-two minutes. Rain. The boiler. Someone's festschrift. The Dean lets you, which means she is waiting for something too."
            narrator "At 2:24 her phone buzzes. She reads it and puts it face down."
            narrator "\"Thank you for coming, Professor. Enjoy your survey.\""

        "Tell her Cobb showed you the deaccession sheet.":
            $ elena_suspicion += 1
            $ dean_blackmail = True
            $ tel_track("ch4_choice2", {"choice": "cobb"})
            narrator "For the first time in eleven years her face does something you did not expect. It is not fear. It is arithmetic."
            narrator "\"Cobb retires in March,\" she says. \"I had thought of extending him. I shall think again.\""
            narrator "You have just cost an old man his thirty-second year. You will carry that."

    scene bg study_normal
    with fade

    narrator "2:31 PM. Your office. The door is unlocked, which it should not be."
    show elena flustered at center
    with dissolve
    narrator "Elena is sitting on the floor behind your desk with her back to the wall and a box file open on her knees. Her hands are black to the wrist."
    elena "It is not a chapel."
    protagonist "Elena—"
    elena "Under the floor. The survey from 1994. It is here, she kept it, she keeps everything. It is not a chapel, it is a strongroom, and it is not empty."

    narrator "She turns the file toward you. A plan of the cellar. A room drawn in red that does not appear on any floor plan since. And an inventory, typed, four pages."
    narrator "Not bodies. Not relics. Paper."

    elena "The other ledger, Vance. The real one."
    narrator "She taps the book on your desk without looking at it."
    elena "This one is the copy they kept upstairs for people like you to countersign. The one under the floor has the names of who was paid, and how much, and by whom, for thirty years."
    elena "My father is in it. So is yours."

    narrator "You sit down. You do not remember deciding to."

    protagonist "My father taught chemistry in Leeds."
    elena "Your father gave the Academy four hundred pounds in 1971 and his name is on page two. I do not know why yet. But Penhallow knew when he shook your hand."

    $ tel_track("ch4_strongroom")

    menu:
        "\"We open the strongroom tonight.\"":
            $ elena_affection += 2
            $ tel_track("ch4_choice3", {"choice": "tonight"})
            elena "The survey gives you the cellar on Thursday. With a witness from Estates."
            protagonist "Thursday is three days for her to empty it."
            elena "Yes."
            protagonist "Then tonight."
            narrator "She looks at your hands. They are not shaking this time. She notices that too."

        "\"We do it Thursday. Properly. With the witness.\"":
            $ elena_suspicion += 1
            $ ritual_interrupted = True
            $ tel_track("ch4_choice3", {"choice": "thursday"})
            elena "And if it is empty on Thursday?"
            protagonist "Then it is empty on the record, with a witness, and the Dean has to explain why a room on her own 1994 survey has nothing in it."
            narrator "She thinks about that for a long time. \"That is either very clever or very cowardly,\" she says. \"I will tell you which on Thursday.\""

        "\"Put the file back. We were never in the annex.\"":
            $ elena_suspicion += 2
            $ elena_affection -= 1
            $ tel_track("ch4_choice3", {"choice": "put_back"})
            elena "She already knows. Her phone buzzed at 2:24, you said so. That was the file room door."
            protagonist "Then putting it back costs nothing."
            elena "It costs the file."
            narrator "She closes the box very carefully. She does not look at you while she does it."

    # Route beat: the night before the strongroom.
    $ tel_track("ch4_climax", {"ending": chosen_ending})
    scene bg study_dark
    with fade

    if chosen_ending == "control":
        show elena submission at center
        with dissolve
        narrator "Eleven o'clock. She has washed the black off her hands. She has not gone home."
        elena "If we go down there tonight and it goes wrong, they will say you made me."
        protagonist "They will be right. On paper."
        elena "I want it on paper, then. Properly. Write it."
        narrator "She puts a sheet in front of you. You write it: {i}Miss Ashcombe acted on my instruction at all times.{/i} You sign it. Your own hand."
        narrator "She reads it twice, folds it into her blouse, and then takes the blouse off."
        $ unlock_cg("cg_climax")
        scene cg climax at night_deep
        with dissolve
        narrator "There is nothing slow about it tonight. She wants to be held down and she says so, and you do, wrists above her head on the desk, the folded paper somewhere under her shoulder."
        narrator "She keeps her eyes open the whole time. When you slow down she says {i}on my instruction{/i} in your own voice and laughs, and you stop being gentle, and she stops laughing."
        narrator "She comes hard and quiet, biting the inside of her own arm. You follow her. Afterwards she keeps your wrists, a long time, and says nothing at all."
    elif chosen_ending == "pact":
        show elena flustered at center
        with dissolve
        narrator "Eleven o'clock. Your flat, for the first time. She looks at the bookshelves the way other women look at photographs."
        elena "Your father. Four hundred pounds."
        protagonist "I will ask him. He is eighty-two. He will tell me it was a subscription."
        elena "Maybe it was."
        protagonist "Maybe. Everyone in that ledger thought they were paying a subscription."
        narrator "She takes off her glasses and puts them on a shelf between two books she has already decided she does not approve of."
        $ unlock_cg("cg_climax")
        scene cg climax
        with dissolve
        narrator "A bed, for once. Sheets. She finds it funny and then does not."
        narrator "She is different lying down, without a crate or a desk to fight. She lets you take your time. She lets you look. She talks, low, the whole way through, about nothing, about the shelf, about the rain, until the talking turns into your name and then into nothing at all."
        narrator "You come inside her with her ankles crossed at the small of your back and her hand flat over your heart as if checking it is still there."
        narrator "She falls asleep first. You lie awake and think about four hundred pounds in 1971."
    else:
        show elena neutral at center
        with dissolve
        narrator "Eleven o'clock. The postgraduate block, her room, which you have never seen. One bed, one desk, four hundred books and a kettle."
        elena "You are the first faculty member to stand in this room. If anyone sees you leave I lose my funding."
        protagonist "Then I will not leave."
        elena "That was the idea."
        $ unlock_cg("cg_climax")
        scene cg climax at crypt_tint
        with dissolve
        narrator "A single bed. Neither of you fits. You make it work, on your side, her back against your chest, your hand between her legs while she reads you the strongroom inventory from her phone in a whisper until she cannot."
        narrator "She turns over. What follows is careful because the walls are thin and fierce because they are, her mouth against your shoulder, yours in her hair, the bed complaining."
        narrator "She comes with her hand over your mouth this time. Fair is fair. You come with her name in your teeth."
        narrator "Afterwards she puts her glasses on and reads you the rest of the inventory. Page four. The last line. {i}Vance, H. 1971. 400. Chemistry. Withdrawn.{/i}"

    scene bg study_normal
    with fade
    $ tel_track("ch4_end", {"ending": chosen_ending, "affection": elena_affection, "suspicion": elena_suspicion})
    $ tel_flush(True)

    narrator "Withdrawn. Not crossed out. Withdrawn, in 1971, by a man who taught chemistry in Leeds and never came back."
    narrator "Your father got out. The Ashcombes did not. That is the whole difference, and you have been countersigning it for twenty years without reading it."

    $ chapter_cleared = max(chapter_cleared, 4)
    jump chapter_5
