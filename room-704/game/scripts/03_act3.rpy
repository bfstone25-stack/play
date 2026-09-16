## 03_act3.rpy — Act 3: six-forty. Endings, the store CTA, and the AI disclosure.

label act3:
    $ tel_track("act3_start", {"route": route, "trust": trust})
    scene bg room
    with fade
    play music theme fadein 2.0
    nar "At twenty past six the window is grey and the sign across the street has switched itself off, and the street looks like an ordinary street that owes nobody anything."

    scene cg morning at dawn_tint
    with dissolve
    nar "She dresses the way she walked in out of the rain: without hurrying."
    m "The car's gone."
    you "He'll have gone to the station."
    m "Yes. He will."
    nar "She sits on the edge of the bed with one stocking half on and thinks about that for a moment, and you watch her decide something."

    if trust >= 4:
        jump end_together
    elif trust >= 0:
        jump end_train
    else:
        jump end_alone

label end_train:
    $ tel_track("ending", {"ending": "train", "trust": trust})
    m "Then I won't go to the station."
    you "There's a bus from the corner at seven. It goes the wrong way for an hour and then it meets the same line four stops up."
    m "How do you know that?"
    you "Everyone who leaves this hotel at this hour needs to not be at the station."
    nar "She laughs, and puts the other stocking on, and takes the key off the bedside table and puts it in your hand rather than on the desk downstairs."
    m "Seven-oh-four."
    you "I'll put it back on the board."
    m "Don't write it in the book."
    nar "You don't."
    jump epilogue

label end_together:
    $ tel_track("ending", {"ending": "together", "trust": trust})
    m "Come with me to the corner, at least. Not the station. The corner."
    nar "You walk her down four flights and out through the doors you have watched all night from the wrong side."
    nar "The rain has stopped. The pavement is doing that thing where it steams slightly."
    m "If I write to the hotel, will it reach you?"
    you "The hotel gets three letters a year and I open all of them."
    m "Then I'll make it four."
    nar "She goes left at the corner, which is the wrong way for the station, which is the point."
    jump epilogue

label end_alone:
    $ tel_track("ending", {"ending": "alone", "trust": trust})
    m "I'll take the station. He'll have given up by now, or he won't, and either way it stops being a thing I plan around."
    nar "She puts the key on the bedside table, squarely, the way you leave a thing for someone you are not going to speak to again."
    m "Thanks for the room."
    nar "At the door she stops, and does not turn around."
    m "You could have told him nothing. It wasn't a hard thing to not do."
    nar "Then she is gone, and you are holding a tooth glass with two inches of somebody else's whisky in it at half past six in the morning."
    jump epilogue

label epilogue:
    scene bg lobby at dawn_tint
    with fade
    $ act_cleared = 3
    nar "The day porter comes on at seven and asks if anything happened."
    nar "You look at the register, where the fourth row of the fourth floor is a clean unbroken line, and you tell him it was a quiet night."
    $ tel_track("end_cta", {"ending": route, "trust": trust, "acts": act_cleared})
    $ tel_flush(True)
    call screen end_screen
    return

screen end_screen():
    tag menu
    add "bg black"
    vbox:
        xalign 0.5
        yalign 0.32
        spacing 16
        text _("ROOM 704") size 58 color "#d9a86b" bold True xalign 0.5
        text _("One night. One floor. Nobody in the book.") size 26 color "#c8b8b0" xalign 0.5
        null height 10
        if ROOM704_WEB_DEMO and renpy.emscripten:
            frame:
                xsize 1100
                xalign 0.5
                background Transform("#161422", alpha=0.94)
                padding (34, 20, 34, 20)
                vbox:
                    spacing 8
                    xalign 0.5
                    text _("The full night, uncensored, DRM-free — $2.49") size 26 color "#ffffff" bold True xalign 0.5
                    text _("Windows / macOS / Linux. No ads, nothing blurred, every route open.") size 20 color "#f0e6dc" xalign 0.5
            null height 8
            hbox:
                xalign 0.5
                spacing 20
                textbutton _("★ Get the full game — $2.49"):
                    action [Function(tel_cta_click, "itch_buy_end"), OpenURL(ITCH_BUY_URL)]
                    text_size 26 text_color "#ffffff" text_hover_color "#ffe0a0"
                    background Transform("#c8503c", alpha=0.95)
                    hover_background Transform("#e8674f", alpha=1.0)
                    padding (26, 15, 26, 15)
                textbutton _("↺ Play the other route"):
                    action Start()
                    text_size 20 text_color "#d9a86b" text_hover_color "#ffe0a0"
                    background Transform("#24202e", alpha=0.92)
                    padding (18, 12, 18, 12)
        else:
            text _("Thanks for playing.") size 24 color "#f0e6dc" xalign 0.5
            null height 8
            textbutton _("↺ Play the other route"):
                action Start()
                text_size 20 text_color "#d9a86b" xalign 0.5
                background Transform("#24202e", alpha=0.92)
                padding (18, 12, 18, 12)
        null height 18
        use cross_promo
        null height 14
        text _("Artwork is AI-assisted. Writing is not. Both are disclosed on every store page.") size 17 color "#8d8f9b" xalign 0.5
        text _("Flat 404") size 17 color "#8d8f9b" xalign 0.5


## itch web track: act 1 is the free sample, the paid download is the whole night.
screen demo_paywall_screen():
    tag menu
    add "bg black"
    vbox:
        xalign 0.5
        yalign 0.30
        spacing 16
        text _("THE FREE PART ENDS HERE") size 46 color "#d9a86b" bold True xalign 0.5
        if demo_cut == "cover":
            text _("You told him it had been a quiet night. She is four floors up, and she has just called the desk.") size 24 color "#c8b8b0" xalign 0.5
        elif demo_cut == "sold":
            text _("You showed him the book. She is four floors up, and she has just called the desk anyway.") size 24 color "#c8b8b0" xalign 0.5
        else:
            text _("You gave him the house line. She is four floors up, and she has just called the desk.") size 24 color "#c8b8b0" xalign 0.5
        null height 8
        hbox:
            xalign 0.5
            spacing 12
            add "cg_locked_bed" zoom 0.34
            add "cg_locked_window" zoom 0.34
        null height 8
        frame:
            xsize 1100
            xalign 0.5
            background Transform("#161422", alpha=0.94)
            padding (34, 18, 34, 18)
            vbox:
                spacing 8
                xalign 0.5
                text _("Room 704 — the whole night, uncensored") size 24 color "#f0e6dc" xalign 0.5
                text _("Three routes, two uncensored scenes, three endings. Windows / macOS / Linux, DRM-free, no ads.") size 20 color "#f0e6dc" xalign 0.5
                text _("$2.49 once.") size 26 color "#ffffff" bold True xalign 0.5
        null height 10
        hbox:
            xalign 0.5
            spacing 20
            textbutton _("★ Unlock the full night — $2.49"):
                action [Function(tel_cta_click, "itch_buy"), OpenURL(ITCH_BUY_URL)]
                text_size 26 text_color "#ffffff" text_hover_color "#ffe0a0"
                background Transform("#c8503c", alpha=0.95)
                hover_background Transform("#e8674f", alpha=1.0)
                padding (26, 15, 26, 15)
            textbutton _("↺ Try the other choices"):
                action Start()
                text_size 20 text_color "#d9a86b" text_hover_color "#ffe0a0"
                background Transform("#24202e", alpha=0.92)
                padding (18, 12, 18, 12)
        null height 12
        text _("Prefer free? The ad-supported web edition unlocks everything with short sponsor clips.") size 18 color "#8d8f9b" xalign 0.5
        null height 16
        use cross_promo

label demo_paywall:
    stop music fadeout 2.0
    play music theme fadein 2.0
    $ tel_track("end_cta", {"acts": act_cleared, "route": route, "demo": True, "cut": demo_cut})
    $ tel_flush(True)
    call screen demo_paywall_screen
    return
