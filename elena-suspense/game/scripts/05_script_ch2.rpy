## 05_script_ch2.rpy — Chapter 2: The Crypt Vault

label chapter_2:
    $ tel_track("ch2_start")
    stop music fadeout 2.0
    play music suspense_theme fadein 2.0
    play ambience rain_ambience fadein 2.0

    scene bg study_dark at crypt_tint
    with fade

    narrator "Chapter 2 — The Crypt Vault"
    narrator "Forty-eight hours later. Saint Jude's sealed lower stacks smell of limestone and old iron."

    show elena neutral at center
    with dissolve

    elena "The ledger pointed here. Not to a book — to a door that isn't on any modern floor plan."
    protagonist "The Blackwood crypt was bricked over in 1994. Officially for structural safety."
    elena "Officially. The mortar is new. Someone opened it last month."

    play sound page_flip
    $ tel_track("ch2_crypt_map")

    narrator "Elena spreads a hand-copied sketch across a crate. Candlelight crawls over a spiral of vault numbers."

    menu:
        "Trust her map and force the sealed grate together.":
            $ elena_affection += 1
            $ tel_track("ch2_choice", {"choice": "force_grate"})
            show elena flustered
            elena "Together, then. If the grate screams, we stop. If it yields… we don't."
            narrator "Iron shrieks once, then gives. Cold air rises like a held breath finally released."

        "Mark the grate and demand campus security records first.":
            $ elena_suspicion += 1
            $ tel_track("ch2_choice", {"choice": "demand_records"})
            show elena flustered
            elena "Security answers to the Dean. The Dean signed the brick-up order."
            protagonist "Then we steal the order. Quietly."
            narrator "You photograph the work-order stamp before Elena's lighter dies. The authorizing initials match a name scrubbed from the ledger."

        "Send Elena up for watch while you enter alone.":
            $ elena_suspicion += 2
            $ elena_affection -= 1
            $ tel_track("ch2_choice", {"choice": "enter_alone"})
            show elena submission
            elena "Don't shut me out now. Not after what we… after last night."
            protagonist "If this is a trap, one of us walks out."
            narrator "She stays on the stair. You drop into black. Her whisper follows you down."

    scene bg study_dark at crypt_tint
    show elena flustered at center
    with dissolve

    narrator "Inside: rows of funerary niches. One niche is empty. In its place sits a lacquered box stamped with Elena's family crest — the same seal burned off her public records."

    $ secret_ledger_discovered = True
    $ tel_track("ch2_crest_box")

    elena "That's… that's my grandmother's mark. They didn't erase us. They buried us."

    play sound heartbeat

    menu:
        "Open the box with her. No secrets between you.":
            $ elena_affection += 2
            $ blood_pact_signed = True
            $ tel_track("ch2_open_together")
            show elena submission
            narrator "Inside: a second ledger page and a ribbon of crimson wax. Elena's fingers find yours before she reads."
            elena "A blood-pact clause. Saint Jude's founders swore the Blackwood line would keep the vault keys — forever."
            protagonist "And someone is rewriting the oath."

        "Seize the box and seal it for leverage against the Dean.":
            $ elena_suspicion += 2
            $ dean_blackmail = True
            $ tel_track("ch2_seize_box")
            show elena flustered
            elena "You're treating my bloodline like a bargaining chip."
            protagonist "I'm treating it like a weapon pointed at us. Better in our hands."
            narrator "She doesn't argue. Her silence is colder than the crypt."

    if elena_affection >= 3:
        play music ecchi_theme fadein 2.0
        $ unlock_cg("cg_climax")
        $ tel_track("ch2_intimacy")
        scene cg climax at crypt_tint
        with fade
        narrator "Against the damp stone, fear turns into heat. Elena's breath stutters against your collar."
        elena "If they buried my name here… then let them hear it when I stop whispering."
        protagonist "Say it. Louder than their seals."
        narrator "Her confession is soft, urgent, unfinished — interrupted by footsteps on the stair."

    stop music fadeout 2.0
    play music suspense_theme fadein 2.0
    scene bg study_dark at crypt_tint
    show elena flustered at center
    with dissolve

    narrator "A flashlight cuts the dark. A night watchman's radio crackles. You kill the lamp. Elena's hand clamps yours."
    elena "Chapter three starts if we leave alive."
    protagonist "Then we leave alive."

    $ chapter_cleared = max(chapter_cleared, 2)
    $ tel_track("ch2_complete")
    $ tel_flush(True)
    jump chapter_3
