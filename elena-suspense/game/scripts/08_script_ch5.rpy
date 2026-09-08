## 08_script_ch5.rpy — Chapter 5: The Strongroom
##
## The cellar under the Blackwood wing. The real ledger. Penhallow and the Dean arrive because of
## course they do. Three endings chosen by the player, coloured by the route flags and by whether the
## player chose "tonight" or "Thursday" in Chapter 4 (ritual_interrupted reused as "went by the book").
##   rewrite - they take the ledger and use it to restore every erased name, including Ashcombe
##   expose  - they hand it to the two board members who are not Penhallow, and the press
##   abscond - they take it and leave; the Academy keeps its secret and loses its archivist

label chapter_5:
    $ tel_track("ch5_start", {"ending": chosen_ending, "by_the_book": ritual_interrupted})
    stop music fadeout 1.0
    play music suspense_theme fadein 2.0
    play ambience rain_ambience fadein 2.0

    scene bg study_dark at crypt_tint
    with fade

    narrator "Chapter 5 — The Strongroom"

    if ritual_interrupted:
        narrator "Thursday, 10 AM. The cellar under the Blackwood wing, with a man from Estates called Priddy who has a hard hat and no curiosity."
        narrator "The 1994 plan says the wall in front of you is a wall. Priddy's meter says it is a door."
    else:
        narrator "1:15 AM. The cellar under the Blackwood wing. No Estates man, no hard hat. A crowbar from the coal store and Elena's phone for light."
        narrator "The 1994 plan says the wall in front of you is a wall. It rings hollow when she knocks."

    show elena neutral at center
    with dissolve

    elena "Brick over a door. Same mortar as the coal store. Same month."
    protagonist "Penhallow's men."
    elena "Penhallow's money. The men were ours. Cobb probably carried the bricks."

    narrator "It takes twenty minutes. The bricks come out in a sheet, the way bricks do when the mortar was never meant to last."
    narrator "Behind them, a steel door with a wheel lock, and a brass plate: {i}Saint Jude Academy — Muniment Room — 1897.{/i}"
    narrator "The wheel turns. Nobody oiled it, and it turns anyway."

    $ tel_track("ch5_strongroom")
    $ unlock_cg("cg_muniment")
    scene cg muniment
    with fade

    narrator "The room is dry. That is the first surprise. Shelves, floor to ceiling, and on the shelves, ledgers. Not one. Sixty. Each spine a decade."
    narrator "The second surprise is the desk in the middle of the room, with a lamp on it that works, and a chair that has been sat in recently."

    show elena flustered at center
    with dissolve
    elena "Someone comes down here."
    protagonist "Someone keeps it up to date."

    narrator "You take down 1990 to 1999. It is heavier than the one upstairs. It is the one upstairs, with the lines filled in."
    narrator "Page fourteen. Ashcombe. The sum, the date, and under it, not a line through the name but a paragraph. Who paid. Why. What the man had found in the cellar in 1994, and how much it cost to make him forget he had found it."
    narrator "Elena reads it standing up. When she finishes she does not sit down. She turns the page."

    elena "It goes on. Every name. Every year. Right up to—"
    narrator "She stops."
    elena "Last month."
    narrator "The last entry is dated three weeks ago. {i}Lot 41 scheduled. Signing officer: Vance. Assistant: Ashcombe, E. Note: watch.{/i}"
    narrator "In the Dean's hand."

    play sound audio.heartbeat

    narrator "Above you, a door. Then the stair."

    if ritual_interrupted:
        narrator "Priddy looks up from his meter. \"That'll be the Dean, Professor. She said she might look in.\""
        narrator "She said. Of course she said. The survey was never a trap for you. It was an appointment."
    else:
        narrator "Two sets of footsteps. One in heels. One in the kind of shoes money walks in."

    scene bg study_dark at night_deep
    show dean neutral at left
    show penhallow neutral at right
    with dissolve

    narrator "Dean Holloway. And behind her, filling the door, Julian Penhallow, who looks around the muniment room the way a man looks around a house he has already sold."
    narrator "\"Professor,\" the Dean says. \"Miss Ashcombe. You found it faster than your father did. He needed a year.\""
    narrator "Penhallow: \"And a good deal more money to un-find it. Which is where we are now.\""

    narrator "Nobody moves. Elena's hand finds the 1990 ledger and does not let go."

    narrator "Penhallow: \"Here is what happens. The room is re-sealed on Monday. The 1990s volume goes upstairs into Professor Vance's keeping, as the new Dean's private archive. Miss Ashcombe's name is restored to the donor roll with a scholarship in her father's memory, generously endowed. Everybody goes home.\""
    narrator "Dean Holloway does not look at Penhallow while he says it. She looks at you. There is something in her face you have not seen there before, and it takes you a moment to name it. It is tiredness."

    $ tel_track("ch5_offer", {"ending": chosen_ending})

    # The final fork. Route flags flavour the text; the choice is the player's.
    menu:
        "\"No. Every name goes back. All sixty volumes. Publicly. Starting with hers.\"":
            $ elena_affection += 3
            $ tel_track("ch5_ending", {"ending": "rewrite", "route": chosen_ending})
            $ chosen_ending = "rewrite"
            jump ch5_ending_rewrite

        "\"The board has two members you do not own. They get the ledger tonight. So does the Guardian.\"":
            $ elena_suspicion += 1
            $ tel_track("ch5_ending", {"ending": "expose", "route": chosen_ending})
            $ chosen_ending = "expose"
            jump ch5_ending_expose

        "Take the 1990s volume. Take Elena. Walk past them and do not stop.":
            $ elena_affection += 2
            $ tel_track("ch5_ending", {"ending": "abscond", "route": chosen_ending})
            $ chosen_ending = "abscond"
            jump ch5_ending_abscond


## ---------------------------------------------------------------- ENDING A: REWRITE
label ch5_ending_rewrite:
    scene bg study_dark at ritual_tint
    show elena neutral at center
    with dissolve

    narrator "Penhallow laughs. The Dean does not."
    narrator "\"Publicly,\" she repeats. \"Do you know what is in volume one, Professor? 1897. The founders. Do you know what they were paid to forget?\""
    protagonist "No. Neither does anyone else. That is the point of a muniment room, Dean. It is not a secret. It is a record. You just stopped letting anyone read it."

    narrator "Elena puts the 1990s volume on the desk, under the lamp, open at page fourteen, and steps back from it."
    elena "Restore my name and I am a scholarship. Restore all of them and I am a footnote. I would rather be a footnote in a true book."

    narrator "Penhallow: \"You have no idea what that costs.\""
    elena "Four hundred pounds. 1971. I have the receipt."

    narrator "It is the Dean who moves. She crosses to the desk, takes the pen from her jacket, and under her own last entry, {i}Note: watch,{/i} she writes a second line."
    narrator "{i}Watched. Found. Recorded. M.H.{/i}"
    narrator "\"I am retiring in the spring,\" she says, to no one. \"I had wondered what I would do with the key.\""

    narrator "Penhallow leaves. He does not slam the door; men like him never do. The stair takes him up and out and, over the next eighteen months, out of the board, the wing, and the town."

    $ tel_track("ch5_climax", {"ending": "rewrite"})
    $ unlock_cg("cg_climax_pact")
    scene cg climax_pact at dawn_tint
    with dissolve

    narrator "The muniment room, later. The Dean gone up. The lamp still on. Sixty volumes and the two of you."
    narrator "Elena kisses you against the 1930s. It is not a victory kiss. It is the other kind, the one people have when the thing they were afraid of turns out to be finished."
    narrator "You take her on the desk in the middle of the room, on top of the open ledger, and she says {i}careful, that is the record{/i} and then {i}no, don't be careful{/i}, and you are not."
    narrator "She comes with her back arched over a hundred years of paid silence and her mouth open on your name, and the lamp does not go out, and nobody comes down the stair."

    $ unlock_cg("cg_aftermath")
    scene cg aftermath at dawn_tint
    with fade

    narrator "Spring. The muniment room has a reading desk now, and a sign-in book, and a postgraduate archivist on a proper salary who reads faster than the professor."
    narrator "Volume one is on the desk, open. Someone is always reading it."
    show elena neutral at center
    with dissolve
    elena "Page fourteen is the most requested page in the archive. Did you know?"
    protagonist "I signed the request form. Twice."
    elena "You sign everything."
    protagonist "I read it first now."
    narrator "She smiles, the real one, and goes back to work. Above the desk, where the portrait was, there is a plain typed card: {i}Ashcombe, R. 1965–1996. Archivist.{/i}"

    jump ch5_epilogue


## ---------------------------------------------------------------- ENDING B: EXPOSE
label ch5_ending_expose:
    scene bg study_dark at night_deep
    show elena flustered at center
    with dissolve

    narrator "Elena already has her phone out. She has had it out since the stair. Forty pages, photographed, uploading."
    narrator "Penhallow: \"That is theft.\""
    elena "That is a receipt. You should recognise one."

    narrator "The Dean says nothing at all. She sits down in the chair that has been sat in recently, and folds her hands, and waits for it to be over."

    narrator "It takes four months. The two board members who are not Penhallow are a retired judge and a woman who runs a hospice, and it turns out they had been waiting thirty years for someone to bring them a piece of paper."
    narrator "The Guardian runs it on a Saturday. The Academy runs an inquiry. Penhallow runs to a lawyer, and then to another one."
    narrator "The Dean retires early, in November, and writes you a letter you do not show anyone. It is two lines long. The second line is {i}Thank you.{/i}"

    $ tel_track("ch5_climax", {"ending": "expose"})
    $ unlock_cg("cg_climax_control")
    scene cg climax_control at night_deep
    with dissolve

    narrator "The night the story runs. Your flat. The phone finally off."
    narrator "Elena has been on the radio twice today and is more frightened of that than she was of the cellar. She says so, into your shoulder, and then stops talking."
    narrator "You make love slowly because she asks you to, and because it is the first slow thing either of you has done in four months. She keeps her glasses on until the last minute and then takes them off herself and puts them somewhere you will step on them later."
    narrator "She comes with your name and then, quieter, her father's. You hold her a long time after."

    $ unlock_cg("cg_aftermath")
    scene cg aftermath at dawn_tint
    with fade

    narrator "A year on. The muniment room is a museum now, which is not what either of you wanted, but it is open, and the names are on the wall."
    show elena neutral at center
    with dissolve
    elena "They spelled Ashcombe right. Second attempt."
    protagonist "I checked the proof."
    elena "You read it first."
    protagonist "I read everything first now. It is exhausting."
    narrator "She takes your arm. Behind you, a school party is being told about 1897, and none of them are listening, and that is fine. It is written down."

    jump ch5_epilogue


## ---------------------------------------------------------------- ENDING C: ABSCOND
label ch5_ending_abscond:
    scene bg study_dark at crypt_tint
    show elena flustered at center
    with dissolve

    narrator "You pick up the 1990s volume. Elena picks up the 1960s, because it is nearest, and because it has your father in it."
    narrator "Penhallow steps into the doorway. He is a big man. He has never in his life had to stop anyone with his body, and it shows."
    protagonist "Move."
    narrator "The Dean says, quietly, \"Julian. Let them.\""
    narrator "He looks at her. Then at you. Then at Elena, who is holding a ledger in both arms like a child holding a cat that wants to leave, and who does not look away."
    narrator "He moves."

    narrator "The stair. The wing. The rain. Cobb, at the porter's window, who sees you go and turns his light off."
    narrator "You are not archivists any more by the time you reach the car. You are two people with two books and nowhere in particular to be."

    $ tel_track("ch5_climax", {"ending": "abscond"})
    $ unlock_cg("cg_climax_pact")
    scene cg climax_pact at crypt_tint
    with dissolve

    narrator "A hotel outside the town, the kind with a car park and no questions. The ledgers on the chair. The rain on the window."
    narrator "She undresses you first this time, fast, laughing, high on it, and pushes you down on a bed that has seen worse, and rides you with her hair everywhere and the curtains open."
    narrator "She says the names as she goes, her father, yours, the Dean, Penhallow, each one thrown away, until there is only one name left and she says that one properly."
    narrator "You come together with the ledgers watching. Afterwards she lies on your chest and says, \"We are going to have to get jobs.\""

    $ unlock_cg("cg_aftermath")
    scene cg aftermath at dawn_tint
    with fade

    narrator "A flat by the sea, eight months later. Two desks. A kettle. Sixty volumes, because you went back for the rest, one night in March, with Cobb's key."
    show elena neutral at center
    with dissolve
    elena "The Academy reported them stolen. Then it stopped reporting anything."
    protagonist "Penhallow's lawyers found out what page two says."
    elena "You read it first?"
    protagonist "I read everything first now."
    narrator "She kisses your temple and goes back to the 1897 volume. She is transcribing it. All of it. She says the sea is the right place to do it, because nobody can burn the sea."

    jump ch5_epilogue


## ---------------------------------------------------------------- EPILOGUE
label ch5_epilogue:
    stop ambience fadeout 2.0
    scene bg study_normal at dawn_tint
    with fade

    $ tel_track("ch5_end", {"ending": chosen_ending, "affection": elena_affection, "suspicion": elena_suspicion})
    $ tel_flush(True)

    narrator "Saint Jude Academy. Department of Antiquities."
    if chosen_ending == "rewrite":
        narrator "Ending: The Record. Every name restored, including one in a Leeds chemistry department who never knew he had been a footnote."
    elif chosen_ending == "expose":
        narrator "Ending: Daylight. The room became a museum. The names became a wall. Elena Ashcombe became, briefly and against her will, famous."
    else:
        narrator "Ending: The Sea. Sixty volumes, two desks, one kettle. The Academy kept its wing and lost its memory."
    narrator "Thank you for reading to the end."

    $ chapter_cleared = max(chapter_cleared, 5)
    jump end_cta_screen
