## 02_script_ch1.rpy - "Elena: Crimson Archives" - Chapter 1 (rewrite, v0.2)
##
## Two real routes. The first fork sets tone; the second fork commits the run.
##   CONTROL route  (suspicion)  - he keeps the leverage, she keeps her pride, the ledger stays dangerous
##   PACT route     (affection)  - they become co-conspirators, and the ledger names him
## Both routes reach the dawn scene with different text and a different ending flag,
## and both end on the same cliffhanger so Chapter 2 has a reason to exist.
##
## Assets reused as-is: bg study_normal / study_dark, elena neutral / flustered / submission,
## cg confrontation / climax / aftermath. New CGs can replace the shared climax CG per route later.
## Telemetry funnel names unchanged: game_start, vault_enter, choice_1, confrontation,
## branch_choice, climax_cg, dawn_resolution.

label start:
    $ elena_suspicion = 0
    $ elena_affection = 0
    $ secret_ledger_discovered = False
    $ chosen_ending = "none"
    $ tel_ensure_session()
    $ tel_track("game_start")

    play ambience rain_ambience fadein 2.0
    play music suspense_theme fadein 3.0

    scene bg study_normal
    with dissolve

    narrator "Saint Jude Academy. Department of Antiquities. 11:42 PM."
    narrator "Rain on the windows. A radiator ticking. The faculty archive smells of old glue and wet coats."
    narrator "You have marked forty-one essays tonight. The forty-second is open when the desk console chimes."

    protagonist "Vault alert. Blackwood wing."
    protagonist "The seal engaged at 11:37. Something is still moving inside it."

    play sound page_flip

    narrator "The Blackwood vault holds the things the Academy does not admit it owns. It locks itself at eleven. Nobody has a reason to be in it now."
    narrator "You take the override key from the drawer. It is heavier than it looks."
    narrator "Two flights down. The corridor lights are on their night setting, a dull orange that makes the doors look further away than they are."

    play sound click

    narrator "Behind the iron door, a phone camera clicks. Once. A pause. Again."
    narrator "You turn the key. The seal lets go with a hiss, and the lamplight inside spills across your shoes."
    narrator "Elena is on the floor beside an open crate, phone in one hand, a ledger the size of a paving stone open on her knees."
    narrator "She has photographed at least thirty pages. She does not stop until she hears the door."

    $ tel_track("vault_enter")

    show elena neutral at center
    with dissolve

    narrator "Elena Ashcombe. Twenty-two. Your postgraduate assistant, and the only person in this building who reads faster than you do."
    narrator "Her blazer is buttoned. Her hands are steady. It is her breathing that gives her away."

    elena "Professor Vance."
    elena "The seal closed on me. I was going to call you at midnight."

    protagonist "At midnight you would have had sixty pages instead of thirty."

    narrator "She does not deny it. She closes the ledger, carefully, the way you close a book you intend to open again."

    elena "This crate is on the deaccession list. Tomorrow it goes to the incinerator with the rest of the water-damaged lot."
    elena "It is not water-damaged. Somebody wants it gone."

    narrator "Gold leaf on the spine, half worn away. No catalogue number. The Academy does not keep books without catalogue numbers."

    # Choice 1: how you open. Sets the tone counter but does not lock the route yet.
    menu:
        "\"Put the phone on the crate. Then tell me what that is.\"":
            $ elena_suspicion += 1
            $ tel_track("choice_1", {"choice": "ask_folder"})
            show elena flustered
            with dissolve
            narrator "She sets the phone down without being asked twice. Screen up. Thirty-two photographs, the last one still uploading."
            elena "It is a donor ledger. 1994 to 1996. Names, sums, and what the sums bought."
            protagonist "That is not a book anyone photographs at midnight for a thesis."
            elena "No, Professor. It is not."

        "\"You're soaked. Come stand by the lamp before you ruin those pages.\"":
            $ elena_affection += 1
            $ tel_track("choice_1", {"choice": "warm_lamp"})
            show elena flustered
            with dissolve
            narrator "She looks at you as if the sentence were in a language she half remembers. Then she gets up and comes to the lamp."
            narrator "Rain has flattened her hair against one cheek. She pushes it back with the wrist that is not holding the ledger."
            elena "You are not going to ask what it is?"
            protagonist "I am going to ask. I would rather ask somebody who is not shivering."
            narrator "That gets a laugh out of her. Short, surprised, gone at once."

        "Say nothing. Close the vault door behind you and lean on it.":
            $ elena_suspicion += 2
            $ tel_track("choice_1", {"choice": "block_exit"})
            show elena flustered
            with dissolve
            narrator "The door meets the frame with a sound like a dropped book. You put your shoulders against it."
            narrator "Her eyes go to the door, to the key in your hand, to your face. In that order."
            elena "Professor. That door only opens from the outside after eleven."
            protagonist "I know. So now we are both in here until one of us explains something."

    narrator "The radiator ticks. Somewhere above, the wind finds a loose pane and worries it."

    play sound audio.heartbeat

    protagonist "Elena. The ledger. On the crate."

    show elena flustered
    with dissolve

    elena "If I give you this, it goes to the Dean's office by nine, and by ten it does not exist."
    elena "Do you know what it costs to have a name removed from a school like this one? I do. It is on page fourteen."

    protagonist "Then you admit you knew what it was before you opened it."

    narrator "She takes one step back. There is nowhere to take a second one. The shelves are at her spine."
    narrator "You are close enough now to see that her glasses are speckled with rain she has not wiped off."

    $ unlock_cg("cg_confrontation")
    $ tel_track("confrontation")

    scene cg confrontation
    with fade

    narrator "She holds the ledger against her chest with both arms, like a child holding a cat that wants to leave."

    elena "Ashcombe. My name. It is in there twice."
    elena "Once as a donor. Once, two years later, crossed out. Somebody drew a line through my family and the Academy stopped knowing us."
    elena "My father died thinking he had done something wrong. I wanted to know what it was."

    protagonist "And?"

    elena "He did nothing. He was paid to leave. The signature on the receipt is not the Dean's."

    narrator "She stops there. Whatever the signature says, she has decided you have not earned it yet."
    narrator "The phone on the crate lights up. Upload complete."

    # Choice 2: the fork. This one commits the route.
    menu:
        "Take the ledger out of her arms. Do not let her see you look at page fourteen.":
            $ elena_suspicion += 3
            $ tel_track("branch_choice", {"branch": "control"})
            jump route_control

        "Put your hand over hers on the cover. \"Show me the signature. Then we decide together.\"":
            $ elena_affection += 3
            $ secret_ledger_discovered = True
            $ tel_track("branch_choice", {"branch": "pact"})
            jump route_pact

        "Step back. Open the door. \"Go home, Elena. We never spoke.\"":
            $ elena_suspicion += 1
            $ tel_track("branch_choice", {"branch": "walk_away"})
            jump route_walk_away


## ---------------------------------------------------------------- ROUTE A: CONTROL
## He keeps the ledger and therefore keeps her. She stays because she has to, then because she wants to.
label route_control:
    scene bg study_dark
    show elena submission at center
    with dissolve

    narrator "The ledger is heavier than the key. You tuck it under one arm and do not open it."

    elena "Give it back."

    protagonist "No."
    protagonist "You are a postgraduate who broke into a sealed vault and photographed restricted material. I am the man holding the only copy and the only key."
    protagonist "So we are going to talk about what happens next, and you are going to listen first."

    narrator "She does not cry. You had half expected it. She folds her arms and waits, chin up, which is worse."

    elena "Then talk."

    protagonist "The photographs get deleted. Tonight, in front of me."
    protagonist "The ledger stays with me. Not the Dean. Me."
    protagonist "And you keep working for me. Every evening. In here."

    elena "That is not a job. That is a leash."

    protagonist "It is the only arrangement where your name stays in that book and you stay in this school. Choose."

    narrator "She looks at the phone. Then at the door you closed. Then at you, and for a long moment she is doing arithmetic you cannot see."

    show elena flustered
    with dissolve

    elena "Delete them yourself. I am not doing it for you."

    narrator "You pick up the phone. Thirty-two photographs of a book you now own. You hold the button until the gallery is empty."
    narrator "When you look up she has taken off her glasses and is cleaning the rain off them with the hem of her blouse."
    narrator "It should not be the thing you notice. It is."

    # Route A internal choice: how the leash tightens. Both lead to the same CG with different text.
    menu:
        "\"Come here.\"":
            $ elena_suspicion += 1
            narrator "She comes. Slowly, so it is clear she is choosing each step."

        "Cross the room to her instead.":
            $ elena_affection += 1
            narrator "You go to her. It costs you something to be the one who moves, and she sees that, and files it away."

    stop music fadeout 2.0
    play music ecchi_theme fadein 2.0

    narrator "Close enough that the lamp is behind you and she is standing in your shadow."

    elena "Is this part of the arrangement, Professor?"

    protagonist "Only if you want it to be. The ledger does not care either way."

    narrator "She thinks about it. You watch her think about it. Then she puts her glasses in your breast pocket, deliberately, and does not take her hand back."

    elena "Then yes. But I want something."
    elena "Page fourteen. Not tonight. But before the end of term, you show me the signature."

    protagonist "Before the end of term."

    elena "Say it properly."

    protagonist "Before the end of term, I show you page fourteen."

    narrator "She nods once, like a woman closing a deal, and then she kisses you, and it is not like a woman closing anything."

    $ unlock_cg("cg_climax")
    $ tel_track("climax_cg", {"branch": "control"})

    scene cg climax
    with dissolve

    narrator "The blazer goes first, over the back of the reading chair. She undoes her own blouse because she does not want to be undone."
    narrator "You lift her onto the crate that held the ledger. The wood creaks. She laughs into your mouth at the sound and then stops laughing."
    narrator "Her thighs are cold from the rain and warm underneath. When you push her skirt up she puts her heels against the crate lid and lets you."
    narrator "She is wet before you touch her. She tells you so, quietly, as if it were a fact about the weather."
    narrator "You take her there, on the crate, with the door locked and the rain going on outside like nothing is happening."
    narrator "She holds on to your collar with both hands and does not close her eyes. Every time you slow down she says your name, not Professor, your name, until you stop slowing down."
    narrator "When she comes it is with her forehead against your shoulder and her teeth in your shirt, and afterwards she stays like that for a long time."
    narrator "You finish inside her because she tells you to, and because by then you would have done anything she told you to."
    narrator "The radiator ticks. Neither of you says anything clever."

    $ chosen_ending = "control"
    jump scene_dawn_resolution


## ---------------------------------------------------------------- ROUTE B: PACT
## He opens the book with her. The signature on page fourteen is his own. Now they are both in it.
label route_pact:
    stop music fadeout 2.0
    play music ecchi_theme fadein 2.0

    scene bg study_normal
    show elena flustered at center
    with dissolve

    narrator "Your hand on hers. The cover between you. She does not pull away, and she does not let go either."

    elena "If you look, you cannot unlook."

    protagonist "I have spent twenty years in rooms full of things I cannot unlook. Open it."

    narrator "She opens it to fourteen without checking the page number. She has looked at this page a great many times."
    narrator "Ashcombe. A sum with four zeros. A date. A line through all of it in a different ink."
    narrator "And under the line, where a receipt would be countersigned, a signature you have written ten thousand times."

    protagonist "That is my hand."

    elena "Yes."

    protagonist "I was twenty-six. I was the department's junior archivist. I countersigned whatever the Dean's office put on my desk."
    protagonist "I did not read them."

    elena "I know. I checked. You countersigned eleven that year. Nine are ordinary. Two are like mine."
    elena "I did not come here to ruin you, Professor. I came to find out whether you knew."

    narrator "She takes her hand out from under yours, and then, after a moment, puts it back on top."

    elena "You did not know. I can see it. That is the first good thing that has happened to me in this building in two years."

    show elena neutral
    with dissolve

    protagonist "Then here is what happens. The ledger does not go to the Dean, and it does not go to the incinerator."
    protagonist "We keep it. We find the other name. And when we know who wrote the line through your family, we decide together what it costs him."

    elena "That is conspiracy, Professor."

    protagonist "It is research. With a smaller reading group."

    narrator "She laughs properly this time, and takes her glasses off to wipe her eyes, and does not put them back on."

    # Route B internal choice: how the pact is sealed.
    menu:
        "\"Elena. Go home. We start tomorrow, in daylight.\"":
            $ elena_affection += 1
            narrator "She does not move."
            elena "I have been alone with this for two years, Vance. I am not going home tonight to be alone with it again."
            narrator "You do not argue. You are not sure you could."

        "Take her glasses out of her hand and set them on the ledger.":
            $ elena_affection += 2
            narrator "Her hand stays where the glasses were. Then it finds your wrist."
            elena "That is a very old-fashioned way to ask, Professor."
            protagonist "It is a very old-fashioned building."

    narrator "She kisses you first. It is careful for about two seconds."

    $ unlock_cg("cg_climax")
    $ tel_track("climax_cg", {"branch": "pact"})

    scene cg climax
    with fade

    narrator "You clear the desk with one arm. Forty-two essays go on the floor and neither of you looks at them."
    narrator "She sits on the edge of the desk and pulls you in by the belt, and undoes it while she is still kissing you, and swears softly when the buckle sticks."
    narrator "Her blouse comes off over her head instead of button by button. Her skin is warm and smells of rain and the cheap soap in the postgraduate bathrooms."
    narrator "You go down on your knees on the wet essays. She puts one hand in your hair and the other over her own mouth, and then takes it away because there is nobody to hear."
    narrator "She is loud. The rain is louder. When her legs start to shake she pulls you up by the collar and says now, and means it."
    narrator "You take her on the desk with her heels locked behind you and the ledger six inches from her head, and she watches your face the whole time as if she is reading it."
    narrator "She comes with your name in her mouth and her nails in your back. You follow her a minute later, inside her, because she holds you there and says stay."
    narrator "Afterwards she lies across the desk with her hair over page fourteen and says, to the ceiling, that she has wanted to do that since October."

    $ chosen_ending = "pact"
    jump scene_dawn_resolution


## ---------------------------------------------------------------- ROUTE C: WALK AWAY (short)
## The coward's route. She leaves with the photographs. He is alone with the book he did not open.
label route_walk_away:
    scene bg study_dark
    show elena neutral at center
    with dissolve

    narrator "You open the door. The corridor is orange and empty."

    elena "That is it?"

    protagonist "That is it. Take your phone. Leave the book."

    narrator "She puts the ledger on the crate. She takes the phone. At the door she stops without turning around."

    elena "Page fourteen, Professor. Read it before the Dean does."
    elena "You will want to know what your handwriting was doing in 1995."

    narrator "Then she is gone, and it is 11:58, and the vault is very quiet."
    narrator "You do not read page fourteen. You go back upstairs and mark the forty-second essay, and it takes you an hour, and you cannot remember a word of it."

    $ chosen_ending = "walk_away"
    $ tel_track("climax_cg", {"branch": "walk_away", "skipped": True})
    jump scene_dawn_resolution


## ---------------------------------------------------------------- DAWN
label scene_dawn_resolution:
    stop music fadeout 3.0
    play music suspense_theme fadein 3.0

    $ unlock_cg("cg_aftermath")
    $ tel_track("dawn_resolution", {"ending": chosen_ending, "suspicion": elena_suspicion, "affection": elena_affection})
    $ tel_flush(True)

    scene cg aftermath
    with fade

    narrator "5:30 AM. The rain has stopped. The window is grey and then, slowly, gold."

    if chosen_ending == "control":
        narrator "Elena is asleep in the reading chair under your coat, glasses still in your pocket. The ledger is under your hand. You have not opened it."
        narrator "You are not sure any more which of you is holding the leash."
        elena "...Is it morning?"
        protagonist "Nearly. Go back to sleep."
        elena "Before the end of term, Vance. You said it properly."
        protagonist "I remember what I said."
        narrator "She goes back to sleep. You open the ledger to page fourteen, finally, alone, and read the signature under the line."
        narrator "It is yours."

    elif chosen_ending == "pact":
        narrator "Elena is asleep across the desk with your coat over her and her cheek on page fourteen. Your signature is under her ear."
        narrator "You have been awake for an hour, reading. There is a second crossed-out name. The line through it is in the same ink as hers."
        elena "...You are staring."
        protagonist "There is another one. 1996. Same ink."
        narrator "She is awake at once, glasses on, hair everywhere."
        elena "Who?"
        protagonist "I do not know yet. But I know who countersigned it."
        elena "Not you."
        protagonist "Not me."
        narrator "You turn the book so she can read it. She reads it twice. Then she looks at the door, the way she did last night, and this time you understand why."

    else:
        narrator "The reading chair is empty. Your coat is where you left it. The ledger is on the crate with a page turned down at the corner."
        narrator "You did not turn it down. Fourteen."
        narrator "At 6:10 your phone lights up. Unknown number. One line."
        elena "I sent the Dean nothing. Yet. Meet me before nine. E."
        narrator "You open the ledger, and read your own handwriting under a stranger's name, and understand that she has been protecting you for two years and you have never once asked her why."

    narrator "Upstairs, a door closes. Somebody is in the building early."
    narrator "The Dean's office does not open until nine."

    protagonist "Elena."
    protagonist "Somebody is coming down."

    # Chapter 2 picks up here.
    jump end_cta_screen
