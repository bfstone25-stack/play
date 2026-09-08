## 05_script_ch2.rpy — Chapter 2: The Incinerator List
##
## Picks up seconds after Chapter 1's dawn: footsteps on the stairs. The visitor is Cobb, the night
## porter, who reports to the Dean. The crate is scheduled for the incinerator at nine. Route memory:
##   control   - Vance has the ledger; Elena is bound to him and resents it
##   pact      - they are partners; his signature is on page fourteen
##   walk_away - Elena left with the photographs; she comes back on her own terms
## Assets: bg study_normal/dark, sprites, cg confrontation (Cobb scene), cg climax (route H-scene).

label chapter_2:
    $ tel_track("ch2_start", {"ending": chosen_ending})
    stop music fadeout 1.0
    play ambience rain_ambience fadein 2.0

    scene bg study_dark at night_deep
    with fade

    narrator "Chapter 2 — The Incinerator List"
    narrator "5:41 AM. The footsteps stop outside the vault door. A key tries the lock, finds it already open, and hesitates."

    if chosen_ending == "walk_away":
        narrator "You are alone with the ledger. You close it and put your hand flat on the cover, as if that hides anything."
    else:
        show elena neutral at center
        with dissolve
        narrator "Elena is on her feet before you are, blouse buttoned wrong, glasses on, the ledger already behind her back."
        elena "Cobb. The night porter. He does the vault round at a quarter to six."
        protagonist "He is fifteen minutes early."
        elena "He is never early."

    play sound click

    narrator "The door opens. Cobb is sixty, thin, in the grey coat the porters have worn since before you were hired. He carries a clipboard and a torch he does not need."
    narrator "He looks at the crate. At the ledger. At the two coffee cups on the desk, one of them yours from last night, one of them not."

    $ tel_track("ch2_cobb")
    show cobb neutral at center
    with dissolve

    narrator "\"Professor Vance,\" he says. \"You are on the deaccession sheet as the signing officer for lot forty-one. The van comes at nine.\""

    protagonist "I did not sign a deaccession sheet."

    narrator "\"No, sir. But your name is on it.\""
    narrator "He does not smile. He turns the clipboard so you can read it. Your name, typed. A signature that is a very good copy of yours. Dated yesterday."

    if chosen_ending == "walk_away":
        narrator "Under the signature, in pencil, in Elena's small hand: {i}Read page fourteen before nine. E.{/i}"
        narrator "Cobb watches you read it. He has already read it."
    else:
        narrator "Elena reads it over your shoulder. Her breath stops on the date."
        elena "Yesterday. Before I ever opened the crate."
        narrator "Cobb clears his throat. \"I only carry the sheet, miss.\""

    # Choice: how you handle a witness who reports to the Dean.
    menu:
        "\"Who gave you that sheet, Cobb?\"":
            $ elena_suspicion += 1
            $ tel_track("ch2_choice", {"choice": "ask_source"})
            narrator "\"The Dean's office, sir. Envelope under my door at ten. Same as always.\""
            protagonist "Always?"
            narrator "\"Lot forty-one is the fourth this year. The others went to the van. Nobody asked me who signed.\""

        "\"Take the sheet back. You never came down here.\"":
            $ elena_suspicion += 2
            $ tel_track("ch2_choice", {"choice": "bribe_silence"})
            narrator "You take out your wallet. Cobb looks at it the way a man looks at weather."
            narrator "\"I have been here thirty-one years, Professor. I would like to be here thirty-two.\""
            narrator "He does not take the money. He does not leave either."

        "Show him page fourteen.":
            $ elena_affection += 1
            $ tel_track("ch2_choice", {"choice": "show_page"})
            narrator "You open the ledger to fourteen and turn it toward the torch."
            narrator "Cobb reads slowly. When he reaches the crossed-out name his mouth goes tight."
            narrator "\"Ashcombe. I carried his boxes out. 1996. He shook my hand and did not say why.\""
            if chosen_ending != "walk_away":
                narrator "Elena makes a sound that is not a word."

    scene bg study_dark at night_deep
    with dissolve

    narrator "Cobb puts the clipboard under his arm. Whatever he decided, he decided while you were talking."
    narrator "\"The van comes at nine. The driver takes what is on the trolley and does not read the labels. That is all I know, sir.\""
    narrator "He goes back up the stairs. He does not close the door."

    if chosen_ending == "walk_away":
        narrator "6:02. Your phone lights up again. Same unknown number."
        show elena neutral at center
        with dissolve
        elena "Cobb has a sister in the bursar's office. Whatever he saw, she knows by lunch. Meet me at the loading dock at eight. Bring the ledger."
        narrator "You type {i}How do you know about Cobb{/i} and delete it, and type {i}Yes{/i}."
    elif chosen_ending == "control":
        show elena flustered at center
        with dissolve
        elena "He will tell the Dean. You know that."
        protagonist "He will tell the Dean that I was here. He did not see you."
        elena "He saw two cups."
        narrator "You look at the cups. She is right. She is usually right, which is going to be a problem."
        elena "Give me the ledger, Vance. I can be out of the building in four minutes. You cannot."
        protagonist "No."
        narrator "She does not argue this time. She picks up the second cup and pours it into the first, and puts the empty one in her bag."
    else:
        show elena neutral at center
        with dissolve
        elena "Four this year. Four crates, four signing officers, four names that did not sign."
        protagonist "And a van driver who does not read labels."
        elena "Then we do not stop the van. We change what is on the trolley."

    $ tel_track("ch2_plan")

    # The plan: swap the crate before nine. Route-flavoured, same beats.
    scene bg study_normal
    with fade

    narrator "7:50 AM. The loading dock behind the Blackwood wing. Rain again, thin and cold. The trolley is already out, three crates under a tarp."

    if chosen_ending == "walk_away":
        show elena neutral at center
        with dissolve
        narrator "Elena is there first, in a coat too big for her, hands in the pockets. She does not say good morning."
        elena "You brought it."
        protagonist "I read it."
        elena "And?"
        protagonist "And I countersigned your father's removal in 1995 and did not read it. I am not going to say sorry. Sorry is for something you meant."
        narrator "She looks at you for a long moment. Then she nods, once, like a woman closing a deal."
        elena "Good. I did not come for sorry."
    else:
        show elena neutral at center
        with dissolve
        narrator "Elena has the crate labels in her pocket, peeled off with a butter knife from the faculty kitchen."

    narrator "Three crates. Lot forty-one is the middle one. The other two are water-damaged journals that nobody will miss."

    menu:
        "Swap the labels. Let the van burn the journals.":
            $ elena_affection += 1
            $ tel_track("ch2_choice2", {"choice": "swap_labels"})
            narrator "Two labels, one knife, ninety seconds. Elena's hands do not shake. Yours do, a little."
            narrator "Lot forty-one goes into the disused coal store under the dock, behind a door that has not had a key since the war."
            $ secret_ledger_discovered = True

        "Empty the crate into your car. Let the van take an empty box.":
            $ elena_suspicion += 1
            $ tel_track("ch2_choice2", {"choice": "empty_crate"})
            narrator "Forty minutes of carrying. The ledger, two boxes of receipts, a roll of architectural drawings nobody has looked at since 1994."
            narrator "The crate goes back on the trolley with the lid nailed shut over nothing. It is lighter. The driver will not weigh it."
            $ secret_ledger_discovered = True

        "Let the van take it. Keep only the ledger and page fourteen.":
            $ elena_suspicion += 2
            $ tel_track("ch2_choice2", {"choice": "keep_page"})
            narrator "You cut the page out with a razor. It comes away clean. Elena watches you do it and says nothing."
            narrator "The crate goes to the van at nine. Whatever else was in it, you will never know."
            if chosen_ending != "walk_away":
                elena "That was my family's box."
                protagonist "This is your family's page. The rest was receipts."
                elena "You do not know that."
                narrator "You do not. You will think about that later, more than once."

    scene bg study_normal
    with dissolve

    narrator "9:04. The van leaves. Cobb, from the porter's window, watches it go and does not look at you."
    narrator "9:10. An email from the Dean's office to all faculty: {i}Lot 41 of the Blackwood deaccession has been destroyed per schedule. The Dean thanks Professor Vance for his diligence.{/i}"

    show elena flustered at center
    with dissolve

    elena "She thanked you."
    protagonist "She thinks it is done. That gives us until somebody opens the coal store."

    if chosen_ending == "walk_away":
        elena "Somebody will. Cobb's sister does the key audit in October."
        protagonist "Then we have until October."
        elena "We."
        protagonist "You brought a coat two sizes too big to a loading dock at eight in the morning. I assumed."
        narrator "She almost smiles. It is the first time you have seen it, and you understand at once why she does not do it often. It changes her whole face."
        $ elena_affection += 1

    # Route H-scene, chapter 2. Control and pact get the CG; walk_away gets a hand on a wrist and a door.
    $ tel_track("ch2_climax", {"ending": chosen_ending})

    if chosen_ending == "control":
        scene bg study_dark
        show elena submission at center
        with dissolve
        narrator "Your office, blinds down, the ledger locked in the drawer with the only key in your waistcoat."
        elena "You are going to keep it in there."
        protagonist "Until October."
        elena "And me?"
        protagonist "You know where the key is."
        narrator "She looks at the waistcoat pocket. Then she comes around the desk and puts her hand on it, flat, and leaves it there."
        elena "This is what you meant. Every evening. In here."
        protagonist "Only if you want it to be."
        elena "I have decided what I want. I decided at the loading dock, watching you shake."
        $ unlock_cg("cg_climax_control")
        scene cg climax_control at night_deep
        with dissolve
        narrator "She takes the key out of your pocket herself and puts it on the desk where you can both see it, and then she undoes your belt."
        narrator "No ledger this time. Nothing between you but the fact that she could pick the key up and leave, and does not."
        narrator "You take her against the locked drawer, her skirt around her waist, one of her shoes on the floor. She keeps her glasses on. She wants to see your face when you understand that she is the one holding the leash now."
        narrator "You understand. She makes sure of it, slowly, until you say her name the way she said yours."
        narrator "Afterwards the key is still on the desk. Neither of you picks it up."

    elif chosen_ending == "pact":
        scene bg study_dark
        show elena flustered at center
        with dissolve
        $ unlock_cg("cg_coal_store")
        scene cg coal_store at crypt_tint
        with dissolve
        narrator "The coal store, 9:30, the crate between you and the door propped with a brick. Cold enough to see your breath."
        elena "We have a receipt with your signature, a crate the Dean thinks is ash, and a porter who knows both."
        protagonist "And a second name we have not found yet."
        elena "And that."
        narrator "She sits on the crate. She is shivering. You give her your coat, and she pulls you in by the lapels instead of putting it on."
        elena "I have not slept. I have not eaten. I have committed two crimes before nine in the morning with a man whose handwriting ruined my father."
        protagonist "And?"
        elena "And I have never felt this awake in my life."
        $ unlock_cg("cg_climax_pact")
        scene cg climax_pact at crypt_tint
        with dissolve
        narrator "On the crate, in the coal dust, with the door propped open on a brick and the rain coming in sideways."
        narrator "She is quick and fierce about it, as if the cold were a clock. She pushes you back and climbs onto you and holds your wrists against the lid, and laughs when the crate creaks, and does not stop."
        narrator "You come together, badly timed and perfect, and she stays on top of you with her forehead on yours until the shivering starts again and is not from the cold."
        narrator "Her hair is full of coal dust. She looks like a chimney sweep who has just robbed a bank. You tell her so. She bites your ear."

    else:
        show elena neutral at center
        with dissolve
        narrator "At the dock gate she stops. Rain on her glasses. Your coat, which she has not given back."
        elena "Tonight. Your office. Bring the page. I will bring what I photographed."
        protagonist "Elena."
        elena "Not yet, Professor. You have to earn the first name."
        narrator "She walks off toward the postgraduate block. Halfway there she turns around, walking backwards, and holds up one hand with the fingers spread."
        narrator "Five. You have no idea what it means. You are going to spend the whole day finding out."

    scene bg study_normal
    with fade
    $ tel_track("ch2_end", {"ending": chosen_ending, "affection": elena_affection, "suspicion": elena_suspicion})
    $ tel_flush(True)

    narrator "Noon. You open the ledger to page fifteen for the first time, because fourteen has told you everything it can."
    narrator "Fifteen is a list of donors, 1995. Halfway down, in the same ink as the line through Ashcombe, one name is underlined twice."
    narrator "{i}Penhallow.{/i}"
    narrator "Aldous Penhallow gave the Academy the Blackwood wing. His portrait hangs in the Dean's annex. His grandson is on the board."
    narrator "And someone, thirty years ago, had wanted you to see his name and not the one they crossed out."

    $ chapter_cleared = max(chapter_cleared, 2)
    jump chapter_3
