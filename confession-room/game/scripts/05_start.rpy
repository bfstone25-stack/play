## 05_start.rpy — the way in, the two disclosures, and the hub the case runs from.

label start:
    scene bg black
    with fade

    ## Disclosure one. This is an adults-only game and it says so before anything else,
    ## in the game rather than only on a store page a third of players never read.
    nar "{b}Confession Room{/b} is for adults. Every character in it is an adult, and is written as one."
    nar "It contains explicit sexual content, and a homicide investigation told without flinching. If that is not what you came for, close it here. No hard feelings, and no argument."
    menu:
        "I am over 18 and I want to play.":
            pass
        "Not for me.":
            $ tel_track("age_gate_declined", {})
            return

    ## Disclosure two. Same rule Room 704 set: say it inside the game.
    nar "The illustrations in this game were made with AI image generation, directed, culled and retouched by hand. The writing and the case are human-written."
    $ tel_track("disclosures_ack", {"dist": dist_track()})

    scene bg precinct at cold_tint
    with dissolve
    play music theme fadein 2.0
    play ambience room_tone fadein 3.0

    dsp "Reyes. Paloma nightclub, back office. One down, three keys, and the captain wants it closed before the morning shift reads about it."
    nar "You have twelve questions. Not by rule. By the hour the captain gets in."

    $ load_case(0)

label case_open:
    ## Re-entered from the epilogue for cases two and three, so everything that has to be
    ## true at the top of a case lives here rather than in `start`.
    scene bg precinct at cold_tint
    with dissolve
    nar "{b}[CASE['title']]{/b}"
    call case_file from _call_case_file_intro
    scene cg intake at cold_tint
    with dissolve
    nar "Three doors off one corridor, and behind each of them somebody who has had all night to decide what kind of person they are going to be for you."
    nar "Nobody has asked for a lawyer. That tells you something, and not enough."

    jump corridor


screen corridor_menu():
    tag menu
    modal True
    frame:
        xalign 0.5 yalign 0.5 xsize 980 padding (34, 28)
        background Solid("#07070bE8")
        vbox:
            spacing 12
            text "The corridor" size 40 color "#e8d9b0"
            text "[questions_left] questions left before the captain takes it off you." size 22 color "#9aa3ad"
            null height 10
            for sid in ("nikolai", "adaeze", "vee"):
                $ _p = pressure[sid]
                textbutton "[SUSPECTS[sid]['name']]  ·  pressure [_p]/3":
                    action Return(("go", sid))
                    text_size 27
            null height 10
            textbutton "The board" action Return(("board", None)) text_size 26 text_color "#8fd6c2"
            textbutton "The evidence locker" action Return(("locker", None)) text_size 26 text_color "#8fd6c2"
            null height 6
            textbutton "Name someone" action Return(("accuse", None)) text_size 26 text_color "#d96a5a"


label corridor:
    scene bg precinct at cold_tint
    call screen corridor_menu()
    $ _what, _who = _return

    if _what == "go":
        ## The free browser build gives away the first room. Past that it asks, once,
        ## the same way the paid download never does.
        if interrogations_done == 1:
            call chapter_gate(2) from _call_chapter_gate_cr
        $ sid = _who
        call interrogate(sid) from _call_interrogate_cr
        $ interrogations_done += 1
        jump corridor

    if _what == "board":
        call show_board from _call_show_board_cr
        jump corridor

    if _what == "locker":
        jump evidence_locker

    if _what == "accuse":
        jump accusation

    jump corridor


## The evidence locker. The plate is censored in the free run and the censoring is not
## decoration: the uncensored photograph IS the case's withheld detail. Unlocking it is a
## shortcut, never the only way in — every case's decisive line is reachable on pressure
## alone, which is what keeps the gate a trade rather than a toll.
label evidence_locker:
    $ _ev = {"cold_room": "evidence", "loading_bay": "evidence2"}.get(CASE["id"], "evidence3")
    scene bg locker at cold_tint
    with dissolve
    nar "Forensics left one photograph in the tray with a sticker over half of it — the way they do when the file is going to be read by people who talk."
    menu:
        "Look at the uncensored plate?"
        "Look at it.":
            pass
        "Leave it in the tray.":
            $ tel_track("evidence_declined", {"case": CASE["id"]})
            jump corridor

    call ad_checkpoint(_ev, "The evidence plate") from _call_ck_evidence
    call cg_gate(_ev) from _call_cg_gate_evidence
    scene expression cg_pick(_ev) at cold_tint
    with dissolve

    if is_ad_unlocked("cg_" + _ev) or dist_track() == "paid":
        $ unlock_cg(_ev)
        if CASE["id"] == "cold_room":
            nar "A shoe. Left foot, under the bottom rack of a walk-in cooler, with a yellow marker beside it."
            nar "Marek was found in the office. He did not get there by himself."
            you "So whoever moved him stood in that cold long enough to mind it."
        elif CASE["id"] == "loading_bay":
            nar "A utility sink, deep enough to lose an arm in, still full. The water in it is clear. The water in the loading bay is not."
            nar "Iris drowned. The file says the bay. The bay is rain and diesel, and she had neither in her."
            you "So she drowned indoors and somebody drove her outside afterwards."
        else:
            nar "A floor safe, open. The cash still banded and still in it. The inner drawer pulled out and empty, and a clean rectangle in the dust where something used to sit."
            nar "The file says nothing was missing. The file was counting money."
            you "Something the size of a book. Worth more than everything stacked under it."
    else:
        nar "Half a photograph and a sticker. Whatever forensics wanted you to see, you will have to take out of a person instead."
    jump corridor
