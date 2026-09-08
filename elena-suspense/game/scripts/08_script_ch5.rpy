## 08_script_ch5.rpy — Chapter 5: Crimson Archives (Finale)

label chapter_5:
    $ tel_track("ch5_start")
    stop music fadeout 1.5
    play music suspense_theme fadein 2.0
    play ambience rain_ambience fadein 2.0

    scene bg study_dark at ritual_tint
    with fade

    narrator "Chapter 5 — Crimson Archives"
    narrator "The crypt is open. Buyers in anonymous masks. Lang. Dean Harlow. A circle of candles waiting for a Blackwood signature."

    show elena flustered at center
    with dissolve

    elena "They need my blood to transfer the vault keys. Without me, the sale is theater."
    protagonist "Then we decide whether this story ends as theft, as sacrifice, or as rewrite."

    play sound heartbeat
    $ tel_track("ch5_circle")

    menu:
        "Break the rite with Elena — rewrite the pact so her name cannot be sold.":
            $ elena_affection += 3
            $ blood_pact_signed = True
            $ chosen_ending = "rewrite"
            $ tel_track("ch5_ending", {"ending": "rewrite"})
            jump ch5_ending_rewrite

        "Expose everyone — livestream the sale to the board and press.":
            $ elena_suspicion += 1
            $ ritual_interrupted = True
            $ chosen_ending = "expose"
            $ tel_track("ch5_ending", {"ending": "expose"})
            jump ch5_ending_expose

        "Claim the vault keys together and vanish before dawn.":
            $ elena_affection += 2
            $ dean_blackmail = True
            $ chosen_ending = "abscond"
            $ tel_track("ch5_ending", {"ending": "abscond"})
            jump ch5_ending_abscond

label ch5_ending_rewrite:
    play music ecchi_theme fadein 2.0
    $ unlock_cg("cg_climax")
    scene cg climax at ritual_tint
    with fade

    narrator "You cut your palm beside hers. Not for the buyers — for a clause older than their contracts."
    elena "By blood freely given, the Blackwood key binds only to consent."
    narrator "The candles gutter white. Masks stumble. Harlow's tablet dies mid-transfer."
    protagonist "The archive keeps what love claims. Not what money orders."

    $ unlock_cg("cg_aftermath")
    scene cg aftermath at dawn_tint
    with fade
    narrator "Dawn. Elena sleeps against your shoulder in the upper stacks, ink still on her wrist."
    elena "We didn't just survive. We authored the ending."
    jump ch5_epilogue

label ch5_ending_expose:
    play music suspense_theme fadein 1.0
    $ unlock_cg("cg_confrontation")
    scene cg confrontation at night_deep
    with fade

    narrator "Your phone uplink hits alumni media before Lang can smash it. Sirens later. Lawyers sooner."
    elena "My name will trend next to scandal for months."
    protagonist "Better trending than buried."
    narrator "Harlow is walked out past her own portraits. The crypt is sealed under court tape — temporary, ugly, public."

    scene bg study_normal at dawn_tint
    show elena flustered at center
    with dissolve
    elena "We won the daylight. I'm still afraid of the dark."
    protagonist "Then we keep a light. Together."
    jump ch5_epilogue

label ch5_ending_abscond:
    play music ecchi_theme fadein 2.0
    $ unlock_cg("cg_climax")
    scene cg climax at crypt_tint
    with fade

    narrator "You take the keys. Elena takes the crest box. The buyers shout. You don't look back."
    elena "Run with me. Not from me."
    narrator "A service tunnel. Rain. A train south. Her mouth finds yours between heartbeats."

    $ unlock_cg("cg_aftermath")
    scene cg aftermath at dawn_tint
    with fade
    narrator "A rented room far from Saint Jude. Elena traces your name onto a blank ledger page."
    elena "New archive. New rules. Starting with us."
    jump ch5_epilogue

label ch5_epilogue:
    stop music fadeout 2.0
    play music suspense_theme fadein 2.0
    scene bg study_normal at dawn_tint
    show elena neutral at center
    with fade

    narrator "Epilogue — Free build complete."
    narrator "You have finished Chapters 1–5 of Elena: Crimson Archives (web slice)."

    if chosen_ending == "rewrite":
        narrator "Ending: Pact Rewrite — Elena's name cannot be sold."
    elif chosen_ending == "expose":
        narrator "Ending: Public Exposure — Saint Jude faces daylight."
    elif chosen_ending == "abscond":
        narrator "Ending: Abscond — new archives, new rules."
    else:
        narrator "Ending recorded."

    elena "If you want the deluxe CGs, voice, and side routes… that's the supporter track."
    protagonist "For now — this story stands on its own."

    $ chapter_cleared = max(chapter_cleared, 5)
    $ tel_track("ch5_complete", {"ending": chosen_ending})
    $ tel_flush(True)
    jump end_cta_screen
