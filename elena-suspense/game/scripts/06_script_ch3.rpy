## 06_script_ch3.rpy — Chapter 3: Forbidden Rituals

label chapter_3:
    $ tel_track("ch3_start")
    stop music fadeout 1.5
    play music suspense_theme fadein 2.0
    play ambience rain_ambience fadein 2.0

    scene bg study_dark at ritual_tint
    with fade

    narrator "Chapter 3 — Forbidden Rituals"
    narrator "Midnight again. The crypt box's wax ribbon has softened in Elena's pocket, as if it remembers body heat."

    show elena flustered at center
    with dissolve

    elena "The pact page isn't a metaphor. There's a rite written in the margin — dates, blood measures, a circle under the chapel."
    protagonist "Saint Jude's chapel sits on Roman foundations. Perfect place to hide an older religion."

    play sound page_flip
    $ tel_track("ch3_rite_page")

    narrator "You translate the Latin together. Every third line is crossed out in a modern pen. Someone has been editing the gods."

    menu:
        "Perform a partial rite with Elena — enough to awaken the seal, not enough to finish it.":
            $ elena_affection += 2
            $ blood_pact_signed = True
            $ tel_track("ch3_choice", {"choice": "partial_rite"})
            show elena submission
            elena "If we stop mid-chant, the seal wakes hungry. Are you ready to be the thing it looks at?"
            protagonist "Better it looks at us than at the Dean's buyers."
            narrator "Candle smoke coils into a thin red ring. Elena's pulse hammers under your thumb as she speaks the half-name."

        "Refuse the rite. Photograph everything and threaten the Dean with exposure.":
            $ elena_suspicion += 1
            $ dean_blackmail = True
            $ ritual_interrupted = True
            $ tel_track("ch3_choice", {"choice": "refuse_expose"})
            show elena flustered
            elena "Exposure gets us expelled — or disappeared. But… maybe daylight is the only clean weapon left."
            narrator "You shoot every page. Flash after flash. The wax ribbon darkens as if bruised."

        "Interrupt mid-rite on purpose to trap whoever is watching.":
            $ elena_suspicion += 2
            $ ritual_interrupted = True
            $ tel_track("ch3_choice", {"choice": "bait_interrupt"})
            show elena flustered
            elena "You're using me as bait."
            protagonist "I'm using both of us. Stay close."
            narrator "The chant breaks. Something in the walls answers with a wet, patient knock."

    play sound heartbeat
    $ unlock_cg("cg_confrontation")
    $ tel_track("ch3_watcher")
    scene cg confrontation at ritual_tint
    with fade

    narrator "A silhouette in faculty robes stands beyond the candle ring — not a ghost. A living curator of erasures."
    narrator "Elena presses back into you. Her glasses flash red."

    elena "Professor Lang. You signed the brick-up order."
    narrator "Lang's smile is archival and thin."
    narrator "\"And you two signed yourselves into a story that was supposed to stay buried.\""

    menu:
        "Shield Elena and demand Lang's buyer list.":
            $ elena_affection += 1
            $ tel_track("ch3_lang", {"choice": "shield"})
            protagonist "Names. Now. Or the rite page goes to every donor on the board by morning."
            narrator "Lang hesitates — the first crack. Elena exhales against your sleeve."

        "Offer Lang a deal: silence for a cut of the vault keys.":
            $ elena_suspicion += 2
            $ dean_blackmail = True
            $ tel_track("ch3_lang", {"choice": "deal"})
            show elena flustered
            elena "Vance—?"
            protagonist "Temporary. We survive first."
            narrator "Lang laughs once. \"Temporary is how all betrayals introduce themselves.\""

    if elena_affection >= 4 and not ritual_interrupted:
        play music ecchi_theme fadein 2.0
        $ unlock_cg("cg_climax")
        $ tel_track("ch3_intimacy")
        scene cg climax at ritual_tint
        with dissolve
        narrator "After Lang withdraws, the candles still burn. Elena's fear turns molten."
        elena "Don't let the rite be the only thing that claims me tonight."
        narrator "You answer without Latin. The circle cools. Her name stays hers."

    stop music fadeout 2.0
    play music suspense_theme fadein 2.0
    scene bg study_dark at ritual_tint
    show elena flustered at center
    with dissolve

    elena "Lang will report to the Dean before sunrise."
    protagonist "Then Chapter 4 is a race."
    $ chapter_cleared = max(chapter_cleared, 3)
    $ tel_track("ch3_complete")
    $ tel_flush(True)
    jump chapter_4
