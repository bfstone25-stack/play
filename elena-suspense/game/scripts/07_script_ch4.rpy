## 07_script_ch4.rpy — Chapter 4: The Dean's Ledger

label chapter_4:
    $ tel_track("ch4_start")
    stop music fadeout 1.5
    play music suspense_theme fadein 2.0
    play ambience rain_ambience fadein 1.5

    scene bg study_normal at night_deep
    with fade

    narrator "Chapter 4 — The Dean's Ledger"
    narrator "Dawn threatens the stained glass. You are inside the Dean's private annex with a stolen master key and six minutes."

    show elena neutral at center
    with dissolve

    elena "Cabinet C. Donor files. If Lang sells vault access, the invoices will be here."
    play sound click
    $ tel_track("ch4_annex")

    narrator "The lock yields. Inside: silk-lined folders and a modern tablet still warm."

    menu:
        "Copy the donor list and leave no trace.":
            $ elena_affection += 1
            $ tel_track("ch4_choice", {"choice": "copy_stealth"})
            show elena flustered
            narrator "Elena mirrors pages with her phone while you wipe prints. Professional. Intimate. Terrified."
            elena "These names fund half the scholarship wing. If we publish, Saint Jude burns."

        "Plant the crypt crest box as evidence and tip campus police.":
            $ dean_blackmail = True
            $ elena_suspicion += 1
            $ tel_track("ch4_choice", {"choice": "plant_evidence"})
            show elena flustered
            elena "Police belong to the board. But a scandal still slows them."
            narrator "You nest the crest box beneath the Dean's blotter. A breadcrumb with teeth."

        "Confront the Dean in person when she arrives early.":
            $ elena_suspicion += 2
            $ tel_track("ch4_choice", {"choice": "confront_dean"})
            show elena submission
            elena "She'll destroy us in a sentence."
            protagonist "Only if we arrive without proof. We have proof."
            narrator "Heels in the hall. You both freeze. The Dean's perfume arrives before she does."

    play sound heartbeat
    $ unlock_cg("cg_confrontation")
    scene cg confrontation at night_deep
    with fade
    $ tel_track("ch4_dean")

    narrator "Dean Harlow stands framed by oak and oil portraits, calm as a closed trial."
    narrator "\"Professor Vance. Miss Blackwood. You are either very brave or already obsolete.\""

    menu:
        "Reveal the blood-pact page and demand Elena's name restored.":
            $ elena_affection += 2
            $ tel_track("ch4_demand", {"choice": "restore_name"})
            protagonist "Restore the Blackwood line to the archive charter. Publicly. Or this pact page becomes tomorrow's headline."
            elena "I want my grandmother's mark back on the ledger — not as a rumor. As law."
            narrator "Harlow's eyes flick to Elena, then to you. Calculation, not remorse."

        "Trade silence for tenure and Elena's guaranteed doctorate.":
            $ elena_suspicion += 2
            $ dean_blackmail = True
            $ tel_track("ch4_demand", {"choice": "trade_silence"})
            show elena flustered
            elena "You're selling the truth for comfort."
            protagonist "I'm buying us time."
            narrator "Harlow smiles like a stamp of approval on a bad grant. \"Time is the one gift I can notarize.\""

        "Burn the modern forgeries in front of her.":
            $ ritual_interrupted = True
            $ elena_affection += 1
            $ tel_track("ch4_demand", {"choice": "burn_forgeries"})
            narrator "You feed the doctored pages to the annex hearth. Ink screams. Harlow does not."
            narrator "\"Theater,\" she says. \"The buyers already have scans.\""

    if elena_affection >= 5:
        play music ecchi_theme fadein 2.0
        $ unlock_cg("cg_aftermath")
        $ tel_track("ch4_intimacy")
        scene cg aftermath at night_deep
        with dissolve
        narrator "Later, in a locked reading room, Elena shakes apart in your arms — not from desire alone, from the cost of being seen."
        elena "If they take my name again, promise you'll say it anyway."
        protagonist "Elena Blackwood. As many times as it takes."

    stop music fadeout 2.0
    play music suspense_theme fadein 2.0
    scene bg study_normal
    show elena flustered at center
    with dissolve

    elena "She'll move the vault keys tonight. Final ritual. Final sale."
    protagonist "Then Chapter 5 is where we stop running."
    $ chapter_cleared = max(chapter_cleared, 4)
    $ tel_track("ch4_complete")
    $ tel_flush(True)
    jump chapter_5
