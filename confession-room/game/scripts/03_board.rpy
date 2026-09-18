## 03_board.rpy — the board, the accusation, and the endings.
##
## TELL's rule, kept: naming the suspect is not enough. You name the suspect AND the line
## that convicts them, so a lucky guess does not read as deduction. Here that second half
## is also what makes the case re-playable — the player who skipped every optional route
## can still win, because the decisive line comes out of pressure, not out of the routes.

screen evidence_board():
    tag menu
    modal True
    $ pool = heard_statements()
    frame:
        xalign 0.5 yalign 0.5 xsize 1240 ysize 760 padding (34, 26)
        background Solid("#07070bE8")
        vbox:
            spacing 8
            text "The Board" size 40 color "#e8d9b0"
            text "Everything you actually got them to say." size 22 color "#9aa3ad"
            null height 8
            hbox:
                spacing 30
                text "[questions_left] questions left" size 22 color "#d9b08a"
                text ("[len(pool)] statement" + ("" if len(pool) == 1 else "s")) size 22 color "#8fd6c2"
            null height 10

            ## Paged, not scrolled. A viewport in this frame rendered its children at zero
            ## size — the header counted the statements correctly above a blank panel —
            ## and neither an explicit xysize nor a separate vbar changed that. Six per
            ## page needs no size inference from Ren'Py at all.
            vbox:
                spacing 14
                xsize 1120
                ysize 420
                for st in pool[board_page * 6:board_page * 6 + 6]:
                    vbox:
                        xsize 1120
                        text (SUSPECTS[st[0]]["name"] + "  ·  on " + st[2]) size 20 color "#8fd6c2"
                        text st[4] size 22 color "#efe7dc"
                if not pool:
                    text "Nothing yet. Go and get something." size 24 color "#7f8fa0"

            if len(pool) > 6:
                hbox:
                    spacing 18
                    textbutton "< Earlier":
                        action SetVariable("board_page", max(0, board_page - 1))
                        sensitive board_page > 0
                        text_size 22
                    text ("page " + str(board_page + 1) + " of " + str((len(pool) + 5) // 6)) size 22 color "#9aa3ad"
                    textbutton "Later >":
                        action SetVariable("board_page", min((len(pool) - 1) // 6, board_page + 1))
                        sensitive (board_page + 1) * 6 < len(pool)
                        text_size 22
            null height 12
            hbox:
                spacing 20
                textbutton "The file" action Return("file") text_size 26
                textbutton "Back to the corridor" action Return("back") text_size 26
                textbutton "Name someone" action Return("accuse") text_size 26 text_color "#d96a5a"


label show_board:
    call screen evidence_board()
    if _return == "file":
        call case_file from _call_case_file_board
        jump show_board
    if _return == "accuse":
        jump accusation
    return


label case_file:
    scene bg precinct at cold_tint
    nar "[CASE['victim']]"
    python:
        _lines = "\n".join("· " + l for l in CASE["public"])
    nar "[_lines]"
    nar "Three keys. Three people. Twelve questions before the captain takes it off you."
    return


## ---------------------------------------------------------------- the accusation
screen accuse_who():
    tag menu
    modal True
    frame:
        xalign 0.5 yalign 0.5 xsize 900 padding (34, 28)
        background Solid("#07070bE8")
        vbox:
            spacing 14
            $ _who_died = CASE["victim"].split(",")[0]
            text "Who killed [_who_died]?" size 36 color "#e8d9b0"
            for sid in ("nikolai", "adaeze", "vee"):
                textbutton "[SUSPECTS[sid]['name']] — [SUSPECTS[sid]['role']]":
                    action Return(sid)
                    text_size 26
            null height 6
            textbutton "Not yet" action Return(None) text_size 24 text_color "#7f8fa0"


screen accuse_why(sid):
    tag menu
    modal True
    $ pool = [s for s in heard_statements() if s[0] == sid]
    frame:
        xalign 0.5 yalign 0.5 xsize 1180 padding (34, 28)
        background Solid("#07070bE8")
        vbox:
            spacing 12
            text "Which line convicts [SUSPECTS[sid]['name']]?" size 34 color "#e8d9b0"
            text "Pick the thing they could not have known unless they were there." size 22 color "#9aa3ad"
            null height 8
            for st in pool:
                textbutton "[st[4]]" action Return(st[1]) text_size 22
            if not pool:
                text "You never got them to say anything. That is not a case." size 24 color "#d96a5a"
            null height 6
            textbutton "Back" action Return(None) text_size 24 text_color "#7f8fa0"


label accusation:
    call screen accuse_who()
    if _return is None:
        jump corridor
    $ accused = _return

    call screen accuse_why(accused)
    if _return is None:
        jump accusation
    $ decisive = _return

    $ tel_track("accusation", {"case": CASE["id"], "who": accused, "why": decisive,
                               "correct": accused == CASE["solution"] and decisive == CASE["decisive"],
                               "q_left": questions_left, "route": route})

    if accused == CASE["solution"] and decisive == CASE["decisive"]:
        jump ending_clean
    elif accused == CASE["solution"]:
        jump ending_right_wrong_reason
    else:
        jump ending_wrong


## The clean ending is the only one written per case: it is the scene where the withheld
## detail is said out loud, and that detail is different every time. The two failure
## endings are deliberately generic — a case you got wrong does not earn a set piece.
label ending_clean:
    $ case_cleared = True
    $ cases_cleared.add(CASE["id"])
    scene bg locker at cold_tint
    with fade

    if CASE["id"] == "cold_room":
        you "Nobody told you he was in the cooler."
        vee "..."
        you "The file says the office. The press says the office. Your own statement says you never went past the bar. And then you told me it was cold in there."
        nar "Vee looks at their hands like the hands are the part that did it."
        vee "He was already going. I only moved him so she wouldn't be the one to find him."
        scene cg closing at sodium_tint
        with dissolve
        nar "They take the shoe out from under the bottom rack at 06:40. Left foot. Size ten."
        nar "You clear the case with [questions_left] questions still on the board, which nobody will notice, and one door you closed, which you will."

    elif CASE["id"] == "loading_bay":
        you "The bay water is rain and diesel. Iris had neither in her."
        ade "..."
        you "You told me the mop room sink is the only clean basin in the building. The file doesn't say clean. Nobody said clean but you."
        nar "She does not look away. She has never once looked away, and that is somehow the worst of it."
        ade "She was going to hand me to an auditor and call it a kindness. Six years, and she thought the kind thing was to warn me it was coming."
        you "So you carried her out to the car."
        ade "I put her somewhere she would be found by a stranger. That was the kindness I had left."
        scene cg closing at sodium_tint
        with dissolve
        nar "The bay light is on a timer. It has been off for three weeks and nobody has called it in, because nobody in this building calls anything in."
        nar "[questions_left] questions still on the board. She signs the statement herself, on every page, the way she has signed everything."

    else:
        you "You told me the inner drawer was the thing. The file says nothing was missing."
        nik "The file is wrong. You knew the file was wrong before I opened my mouth."
        you "I knew. I didn't know you knew."
        nar "He takes that the way he takes everything, as a line in a ledger he has already balanced."
        nik "Nine months of names, Reyes. Marek started it and Iris kept it and Bo was going to carry it out of here in a folder at nine in the morning."
        you "And the two of them before him?"
        nik "You already cleared those. That is the part I would like you to sit with."
        scene cg closing at sodium_tint
        with dissolve
        nar "He walks out ahead of the uniform, because he has done it before and knows the pace. The ledger turns up in a locker at the bus terminal on Thursday."
        nar "[questions_left] questions still on the board, and one you never asked in three nights: who was paying him to be patient."
    jump epilogue


label ending_right_wrong_reason:
    $ case_cleared = True
    $ cases_cleared.add(CASE["id"])
    scene bg room at cold_tint
    with fade
    nar "You get the name right and the reason wrong, and a lawyer gets to spend a year on the difference."
    nar "It holds. Barely. The captain signs it without looking at you."
    jump epilogue


label ending_wrong:
    scene bg precinct at cold_tint
    with fade
    nar "The name you said goes on the sheet. The thing nobody was told stays a thing nobody was told."
    dsp "Captain says that's the case, Reyes. Captain says go home."
    jump epilogue


label epilogue:
    $ tel_track("case_end", {"case": CASE["id"], "cleared": case_cleared, "route": route,
                             "q_left": questions_left, "who": accused})
    scene bg black
    with fade
    if case_cleared:
        nar "Case closed: {b}[CASE['title']]{/b}."
    else:
        nar "Case filed open: {b}[CASE['title']]{/b}."

    ## Next case, or the end of the run. The cases are chronological and the routes
    ## escalate across them, so they are played in order rather than picked from a menu.
    if case_index + 1 < CASE_COUNT:
        $ _next = CASES[case_index + 1]
        nar "Reyes catches the next one [_next['night']]. There is always a next one."
        call ad_checkpoint("case_" + _next["id"], _next["title"]) from _call_ck_case
        ## Between cases, after the gate has been paid: the offer of ten minutes of
        ## something lighter. Silent on the first crossing (see board_offer_break).
        $ board_offer_break()
        $ load_case(case_index + 1)
        $ case_cleared = False
        jump case_open

    nar "Three nights, three files, and a club that will be a phone shop by spring."
    if len(cases_cleared) == CASE_COUNT:
        nar "You got all three. Nobody hands you anything for that. You did not expect them to."
    else:
        nar "You got [len(cases_cleared)] of [CASE_COUNT]. The rest sit in a drawer with your name on the tab."
    nar "{b}Confession Room{/b} — end of run."
    ## End of the run: the rest of the adult catalogue, offered the same way the break is
    ## — asked, never forced. Defined in 09_dist.rpy; a no-op outside the web build.
    $ board_offer_more()
    return
